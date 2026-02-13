"""
Scheduled Cron Jobs
- Auto-capture confirmed receipts (daily)
- Check expired authorizations (daily)
- Monitor Algolia sync (every 15 min)
- Cleanup stale rate limits (every 30 min)
- Archive old orders (every 12 hours)
"""

import logging
from datetime import datetime, timedelta

import stripe
from firebase_functions import scheduler_fn

from config import AUTHORIZATION_VALID_DAYS, AUTO_CONFIRM_DAYS, PLATFORM_FEE_PERCENT, STRIPE_SECRET_KEY
from schema_constants import (
    AlgoliaActionValues,
    BusinessRules,
    Collections,
    CronLockStatusValues,
    DeliveryStatusValues,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    SecurityAlertTypes,
    SeverityLevels,
)
from utils.function_options import CRON_OPTIONS

logger = logging.getLogger(__name__)

stripe.api_key = STRIPE_SECRET_KEY

# Lazy-loaded Firestore client and module
_db = None
_firestore_module = None


def get_db():
    """Get Firestore client with lazy initialization."""
    global _db, _firestore_module
    if _db is None:
        from firebase_admin import firestore

        _firestore_module = firestore
        _db = firestore.client()
    return _db


def get_firestore():
    """Get Firestore module with lazy initialization."""
    global _firestore_module
    if _firestore_module is None:
        from firebase_admin import firestore

        _firestore_module = firestore
    return _firestore_module


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP with lazy initialization."""
    return get_firestore().SERVER_TIMESTAMP


def acquire_cron_lock(job_name: str, ttl_minutes: int = 30) -> bool:
    """
    Distributed lock using Firestore document.
    Prevents concurrent execution of cron jobs across Cloud Function instances.

    Returns True if lock acquired, False if another instance is running.
    """
    lock_ref = get_db().collection(Collections.CRON_LOCKS).document(job_name)
    now = datetime.now()
    cutoff = now - timedelta(minutes=ttl_minutes)

    @get_firestore().transactional
    def _try_acquire(transaction):
        doc = lock_ref.get(transaction=transaction)
        if doc.exists:
            lock_data = doc.to_dict()
            locked_at = lock_data.get(Fields.LOCKED_AT)
            if locked_at and locked_at > cutoff:
                return False  # Lock is still held by another instance
        transaction.set(
            lock_ref,
            {
                Fields.LOCKED_AT: now,
                Fields.LOCKED_BY: f"cron_{job_name}",
                Fields.STATUS: CronLockStatusValues.RUNNING,
            },
        )
        return True

    try:
        return _try_acquire(get_db().transaction())
    except Exception as e:
        logger.warning(f"⚠️ Failed to acquire cron lock for {job_name}: {type(e).__name__}")
        return False


def release_cron_lock(job_name: str) -> None:
    """Release a distributed cron lock."""
    try:
        get_db().collection(Collections.CRON_LOCKS).document(job_name).update(
            {
                Fields.STATUS: CronLockStatusValues.COMPLETED,
                Fields.COMPLETED_AT: datetime.now(),
            }
        )
    except Exception as e:
        logger.warning(f"⚠️ Failed to release cron lock for {job_name}: {type(e).__name__}")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def auto_capture_confirmed_receipts(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Auto-payout for delivered orders (payment already captured at checkout).

    Runs: Daily at 01:00 UTC

    Flow (post-automatic-capture migration):
    - Payment is captured immediately at Stripe Checkout — no manual capture needed.
    - This cron creates Transfers (payouts) to sellers for DELIVERED orders
      that have been delivered for AUTO_CONFIRM_DAYS without dispute.
    - Also auto-confirms SHIPPED orders after AUTO_CONFIRM_DAYS if buyer
      doesn't manually confirm receipt (marks as DELIVERED for payout).
    """
    logger.info("Running auto_capture_confirmed_receipts cron job (auto-payout mode)")

    # SECURITY FIX #16: Distributed lock prevents concurrent execution
    if not acquire_cron_lock("auto_capture_confirmed_receipts"):
        logger.info("auto_capture_confirmed_receipts: Lock held by another instance, skipping")
        return

    try:
        _run_auto_capture()
    finally:
        release_cron_lock("auto_capture_confirmed_receipts")


def _run_auto_capture() -> None:
    """Inner implementation of auto-capture (extracted for lock management)."""

    # Check if Stripe is enabled before processing
    from handlers.payment_providers import PaymentProvider, is_provider_enabled

    if not is_provider_enabled(PaymentProvider.STRIPE):
        logger.info("Stripe payments are disabled, skipping auto-payout")
        return

    cutoff_date = datetime.now() - timedelta(days=AUTO_CONFIRM_DAYS)

    # Query DELIVERED orders with captured payment that haven't been paid out yet
    # Also query SHIPPED orders past cutoff for auto-confirmation
    all_orders = []

    # DELIVERED orders ready for payout (payoutStatus not yet completed)
    delivered_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.ORDER_STATUS, "==", OrderStatusValues.DELIVERED)
        .where(Fields.PAYMENT_STATUS, "==", PaymentStatusValues.CAPTURED)
        .where(Fields.UPDATED_AT, "<=", cutoff_date)
        .limit(250)
        .stream()
    )
    all_orders.extend(delivered_orders)

    # SHIPPED orders past cutoff — auto-confirm as delivered for payout
    shipped_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.ORDER_STATUS, "==", OrderStatusValues.SHIPPED)
        .where(Fields.PAYMENT_STATUS, "==", PaymentStatusValues.CAPTURED)
        .where(Fields.UPDATED_AT, "<=", cutoff_date)
        .limit(250)
        .stream()
    )
    all_orders.extend(shipped_orders)

    payout_count = 0
    failed_count = 0

    for order_doc in all_orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id
        payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)

        if not payment_intent_id:
            logger.info(f"Order {order_id} has no payment intent, skipping")
            continue

        # Skip orders that already have completed payouts
        payout_status = order_data.get(Fields.PAYOUT_STATUS)
        if payout_status == PayoutStatusValues.COMPLETED:
            continue

        # AUDIT FIX (HIGH-024): Check for active disputes before auto-payout.
        try:
            dispute_alerts = (
                get_db()
                .collection(Collections.SECURITY_ALERTS)
                .where(Fields.TYPE, "==", SecurityAlertTypes.DISPUTE_CREATED)
                .where(Fields.RESOLVED, "==", False)
                .where(Fields.ORDER_ID, "==", order_id)
                .limit(1)
                .get()
            )

            if len(dispute_alerts) > 0:
                logger.warning(f"⚠️ Order {order_id} has active dispute, skipping auto-payout")
                continue
        except Exception as e:
            logger.warning(f"⚠️ Failed to check disputes for order {order_id}: {str(e)}, skipping for safety")
            continue

        # FIX S23: Verify actual delivery/ship time before payout.
        items = order_data.get(Fields.ITEMS, [])
        latest_event_time = None
        for item in items:
            ts = item.get(Fields.DELIVERED_AT) or item.get(Fields.SHIPPED_AT)
            if ts:
                if isinstance(ts, str):
                    try:
                        ts = datetime.fromisoformat(ts)
                    except ValueError:
                        continue
                if latest_event_time is None or ts > latest_event_time:
                    latest_event_time = ts

        if latest_event_time and latest_event_time > cutoff_date:
            logger.info(f"Order {order_id} item-level timestamp too recent ({latest_event_time}), skipping")
            continue

        # Auto-confirm SHIPPED orders as DELIVERED after cutoff
        if order_data.get(Fields.ORDER_STATUS) == OrderStatusValues.SHIPPED:
            items = order_data.get(Fields.ITEMS, [])
            for item in items:
                if item.get(Fields.STATUS) == DeliveryStatusValues.SHIPPED:
                    item[Fields.STATUS] = DeliveryStatusValues.DELIVERED
                    item[Fields.DELIVERED_AT] = datetime.now().isoformat()
            order_doc.reference.update(
                {
                    Fields.ITEMS: items,
                    Fields.ORDER_STATUS: OrderStatusValues.DELIVERED,
                    Fields.AUTO_CONFIRMED: True,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            order_data[Fields.ORDER_STATUS] = OrderStatusValues.DELIVERED
            logger.info(f"Auto-confirmed order {order_id} as delivered (was shipped, {AUTO_CONFIRM_DAYS}+ days)")

        try:
            # Payment is already captured — just mark payout in progress
            order_doc.reference.update(
                {
                    Fields.PAYOUT_STATUS: PayoutStatusValues.PROCESSING,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )

            # Create payouts ONLY for sellers whose items are DELIVERED
            # SECURITY FIX: Removed PENDING fallback — only pay for confirmed deliveries
            items = order_data.get(Fields.ITEMS, [])
            sellers_total_cents = {}
            for item in items:
                item_status = item.get(Fields.STATUS, DeliveryStatusValues.PENDING)
                if item_status == DeliveryStatusValues.DELIVERED:
                    seller_id = item[Fields.SELLER_ID]
                    item_price_cents = round(item[Fields.PRICE] * 100)
                    item_total_cents = item_price_cents * item[Fields.QUANTITY]
                    sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents

            # AUDIT FIX (CRITICAL-001): Use stored fee rate from checkout, not current config
            stored_fee_total = order_data.get(Fields.PLATFORM_FEE_CENTS)
            stored_fee_rate = (
                (stored_fee_total / order_data.get(Fields.TOTAL_AMOUNT_CENTS, 1))
                if stored_fee_total
                else PLATFORM_FEE_PERCENT
            )

            for seller_id, amount_cents in sellers_total_cents.items():
                platform_fee_cents = round(amount_cents * stored_fee_rate)
                net_amount_cents = amount_cents - platform_fee_cents

                # Get seller's Stripe account
                seller_ref = get_db().collection(Collections.USERS).document(seller_id)
                seller_doc = seller_ref.get()

                if seller_doc.exists:
                    seller_data = seller_doc.to_dict()
                    stripe_account_id = seller_data.get(Fields.STRIPE_ACCOUNT_ID)

                    # SECURITY FIX: Check chargesEnabled (not payoutsEnabled) for consistency
                    # with capture_payment. Also check seller is not suspended.
                    seller_suspended = seller_data.get(Fields.SUSPENDED, False)
                    seller_charges_ok = seller_data.get(Fields.CHARGES_ENABLED, False)

                    if seller_suspended:
                        logger.warning(f"⚠️ Skipping auto-payout to suspended seller {seller_id} for order {order_id}")
                        order_doc.reference.update(
                            {
                                Fields.REQUIRES_MANUAL_REVIEW: True,
                                Fields.MANUAL_REVIEW_REASON: f"Seller {seller_id} suspended at auto-capture",
                            }
                        )
                        continue

                    if stripe_account_id and seller_charges_ok:
                        try:
                            # CRITICAL FIX: Stripe Transfer requires a Charge ID (ch_xxx),
                            # not a PaymentIntent ID (pi_xxx). Retrieve the charge from the PI.
                            charge_id = None
                            try:
                                pi = stripe.PaymentIntent.retrieve(payment_intent_id)
                                charge_id = pi.latest_charge
                            except stripe.error.StripeError as pi_err:
                                logger.error(f"Failed to retrieve charge for PI {payment_intent_id}: {str(pi_err)}")

                            if not charge_id:
                                logger.warning(
                                    f"⚠️ No charge found for PI {payment_intent_id}, skipping transfer for seller {seller_id}"
                                )
                                order_doc.reference.update(
                                    {
                                        Fields.REQUIRES_MANUAL_REVIEW: True,
                                        Fields.MANUAL_REVIEW_REASON: f"No charge ID found for auto-payout to seller {seller_id}",
                                    }
                                )
                                continue

                            # Create PENDING payout record BEFORE Stripe transfer
                            payout_ref = get_db().collection(Collections.PAYOUTS).document()
                            payout_ref.set(
                                {
                                    Fields.ORDER_ID: order_id,
                                    Fields.SELLER_ID: seller_id,
                                    Fields.AMOUNT_CENTS: amount_cents,
                                    Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                                    Fields.NET_AMOUNT_CENTS: net_amount_cents,
                                    Fields.STATUS: PayoutStatusValues.PENDING,
                                    Fields.AUTO_CAPTURED: True,
                                    Fields.CREATED_AT: get_server_timestamp(),
                                }
                            )

                            transfer = stripe.Transfer.create(
                                amount=net_amount_cents,
                                currency=BusinessRules.DEFAULT_CURRENCY,
                                destination=stripe_account_id,
                                source_transaction=charge_id,
                                transfer_group=order_id,
                                metadata={
                                    Fields.ORDER_ID: order_id,
                                    Fields.SELLER_ID: seller_id,
                                    Fields.AUTO_CAPTURED: True,
                                },
                                idempotency_key=f"auto_transfer_{order_id}_{seller_id}",
                            )

                            # Update payout record with transfer details
                            payout_ref.update(
                                {
                                    Fields.STATUS: PayoutStatusValues.COMPLETED,
                                    Fields.STRIPE_TRANSFER_ID: transfer.id,
                                    Fields.PAYOUT_DATE: get_server_timestamp(),
                                }
                            )

                        except stripe.error.StripeError as e:
                            logger.error(f"Payout failed for seller {seller_id}: {str(e)}")

                            # AUDIT FIX: Sanitize Stripe error before storing in Firestore
                            safe_error = f"{type(e).__name__}: {getattr(e, 'code', 'unknown')}"

                            # Update existing payout record to FAILED
                            try:
                                payout_ref.update(
                                    {
                                        Fields.STATUS: PayoutStatusValues.FAILED,
                                        Fields.FAILURE_REASON: safe_error,
                                    }
                                )
                            except Exception:
                                # Fallback: create a new failure record if payout_ref wasn't set
                                get_db().collection(Collections.PAYOUTS).add(
                                    {
                                        Fields.ORDER_ID: order_id,
                                        Fields.SELLER_ID: seller_id,
                                        Fields.AMOUNT_CENTS: amount_cents,
                                        Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                                        Fields.NET_AMOUNT_CENTS: net_amount_cents,
                                        Fields.STATUS: PayoutStatusValues.FAILED,
                                        Fields.FAILURE_REASON: safe_error,
                                        Fields.AUTO_CAPTURED: True,
                                        Fields.CREATED_AT: get_server_timestamp(),
                                    }
                                )

            payout_count += 1
            logger.info(f"Auto-payout completed for order {order_id}")

            # Mark order payout as completed so it's not reprocessed next cron run
            order_doc.reference.update(
                {
                    Fields.PAYOUT_STATUS: PayoutStatusValues.COMPLETED,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )

        except stripe.error.StripeError as e:
            failed_count += 1
            logger.error(f"Failed to process payout for order {order_id}: {str(e)}")

            order_doc.reference.update(
                {
                    Fields.PAYOUT_STATUS: PayoutStatusValues.FAILED,
                    Fields.LAST_CAPTURE_ERROR: f"{type(e).__name__}: {getattr(e, 'code', 'unknown')}",
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )

    logger.error(f"Auto-payout completed: {payout_count} paid out, {failed_count} failed")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def check_expired_authorizations(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Expires orders with authorizations older than 7 days.

    Runs: Daily at 02:00 UTC

    Logic:
    - With automatic capture, there are no authorization holds to expire.
    - This cron now cleans up stale PENDING orders (checkout abandoned)
      that were never paid and are older than AUTHORIZATION_VALID_DAYS.
    - Restores stock for these abandoned orders.
    """
    logger.info("Running check_expired_authorizations cron job (stale order cleanup)")

    # SECURITY FIX #16: Distributed lock prevents concurrent execution
    if not acquire_cron_lock("check_expired_authorizations"):
        logger.info("check_expired_authorizations: Lock held by another instance, skipping")
        return

    try:
        _run_expired_authorizations()
    finally:
        release_cron_lock("check_expired_authorizations")


def _run_expired_authorizations() -> None:
    """Inner implementation of expired authorization cleanup."""

    cutoff_date = datetime.now() - timedelta(days=AUTHORIZATION_VALID_DAYS)

    # Find stale PENDING orders that were never paid (session expired/abandoned)
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(
            Fields.PAYMENT_STATUS,
            "in",
            [
                PaymentStatusValues.AWAITING_PAYMENT,
                PaymentStatusValues.SESSION_EXPIRED,
            ],
        )
        .where(Fields.ORDER_STATUS, "in", [OrderStatusValues.PENDING])
        .where(Fields.CREATED_AT, "<=", cutoff_date)
        .limit(100)
        .stream()
    )

    expired_count = 0

    for order_doc in orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id

        # For stale unpaid orders, simply mark as expired and restore stock
        @get_firestore().transactional
        def try_expire_order(transaction, order_doc=order_doc):
            fresh_doc = order_doc.reference.get(transaction=transaction)
            if not fresh_doc.exists:
                return "not_found"
            fresh_data = fresh_doc.to_dict()
            current_status = fresh_data.get(Fields.ORDER_STATUS)
            if current_status != OrderStatusValues.PENDING:
                return f"invalid_status:{current_status}"
            transaction.update(
                order_doc.reference,
                {
                    Fields.ORDER_STATUS: OrderStatusValues.EXPIRED,
                    Fields.PAYMENT_STATUS: PaymentStatusValues.SESSION_EXPIRED,
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )
            return "locked"

        try:
            expire_result = try_expire_order(get_db().transaction())
        except Exception as e:
            logger.warning(f"⚠️ Failed to lock order {order_id} for expiry: {str(e)}")
            continue

        if expire_result != "locked":
            logger.info(f"Order {order_id} cannot be expired: {expire_result}")
            continue

        # Skip if stock already restored (idempotency)
        if order_data.get(Fields.STOCK_RESTORED, False):
            logger.info(f"Stock already restored for expired order {order_id}")
        else:
            # Use batch write for atomicity across multiple product stock updates
            stock_batch = get_db().batch()
            for item in order_data.get(Fields.ITEMS, []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                stock_batch.update(
                    product_ref, {Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY])}
                )
            try:
                stock_batch.commit()
            except Exception as e:
                logger.error(f"Failed to restore stock batch for order {order_id}: {str(e)}")

        # Update order with remaining fields NOT set in the transaction
        # NOTE: ORDER_STATUS and PAYMENT_STATUS are already set in the transaction.
        # Only set STOCK_RESTORED, EXPIRES_AT here to avoid duplicating writes.
        order_doc.reference.update(
            {
                Fields.STOCK_RESTORED: True,
                Fields.EXPIRES_AT: get_server_timestamp(),
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )

        expired_count += 1
        logger.info(f"Expired order {order_id}")

    logger.info(f"Stale order cleanup completed: {expired_count} orders expired")


@scheduler_fn.on_schedule(schedule="every 12 hours", **CRON_OPTIONS)
def auto_archive_old_orders(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Archives orders delivered/cancelled 30+ days ago.

    Runs: Every 12 hours

    Logic:
    - Find orders with status=delivered/cancelled
    - Updated 30+ days ago
    - Mark as archived
    """
    logger.info("Running auto_archive_old_orders cron job")

    cutoff_date = datetime.now() - timedelta(days=BusinessRules.ARCHIVE_AFTER_DAYS)

    # Limit to 200 orders per run and use batch
    # NOTE: We cannot filter 'archived == False' because Firestore doesn't match
    # documents where the field doesn't exist. Instead, we query without the filter
    # and skip already-archived orders in the loop.
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(
            Fields.ORDER_STATUS,
            "in",
            [OrderStatusValues.DELIVERED, OrderStatusValues.CANCELLED, OrderStatusValues.REFUNDED],
        )
        .where(Fields.UPDATED_AT, "<=", cutoff_date)
        .limit(200)
        .stream()
    )

    archived_count = 0
    batch = get_db().batch()

    for order_doc in orders:
        if order_doc.to_dict().get(Fields.ARCHIVED, False):
            continue

        batch.update(order_doc.reference, {Fields.ARCHIVED: True, Fields.ARCHIVED_AT: get_server_timestamp()})
        archived_count += 1

        # Commit every 500 operations
        if archived_count % 500 == 0:
            batch.commit()
            batch = get_db().batch()

    # Commit remaining
    if archived_count % 500 != 0:
        batch.commit()

    logger.info(f"Archive completed: {archived_count} orders archived")


@scheduler_fn.on_schedule(schedule="every 15 minutes", **CRON_OPTIONS)
def monitor_algolia_sync(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Monitors Firestore-Algolia sync health.

    Runs: Every 15 minutes

    Logic:
    - Count active products in Firestore
    - Count products in Algolia
    - Alert if mismatch > 5%
    """
    logger.info("Running monitor_algolia_sync cron job")

    try:
        # Count active products in Firestore using count aggregation

        products_query = get_db().collection(Collections.PRODUCTS).where(Fields.IS_ACTIVE, "==", True)

        # Use count aggregation (more efficient than streaming)
        count_query = products_query.count()
        firestore_count = count_query.get()[0][0].value

        # Count products in Algolia
        from services.algolia_service import get_index_stats

        algolia_count = get_index_stats()

        # Check for significant mismatch
        if firestore_count == 0:
            logger.info("No products in Firestore")
            return

        mismatch_percent = abs(firestore_count - algolia_count) / firestore_count

        if mismatch_percent > BusinessRules.ALGOLIA_SYNC_MISMATCH_THRESHOLD:  # > 5% mismatch
            get_db().collection(Collections.SECURITY_ALERTS).add(
                {
                    Fields.TYPE: SecurityAlertTypes.ALGOLIA_SYNC_ISSUE,
                    Fields.SEVERITY: SeverityLevels.MEDIUM,
                    Fields.FIRESTORE_COUNT: firestore_count,
                    Fields.ALGOLIA_COUNT: algolia_count,
                    Fields.MISMATCH_PERCENT: mismatch_percent * 100,
                    Fields.TIMESTAMP: get_server_timestamp(),
                    Fields.RESOLVED: False,
                }
            )

            logger.info(f"ALERT: Algolia sync mismatch: Firestore={firestore_count}, Algolia={algolia_count}")
        else:
            logger.info(f"Algolia sync healthy: Firestore={firestore_count}, Algolia={algolia_count}")

    except Exception as e:
        logger.error(f"Failed to monitor Algolia sync: {str(e)}")


@scheduler_fn.on_schedule(schedule="every 30 minutes", **CRON_OPTIONS)
def cleanup_stale_rate_limits(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Removes rate limit documents older than 1 hour.

    Runs: Every 30 minutes

    Logic:
    - Find rate_limits with last_request > 1 hour ago
    - Delete documents
    """
    logger.info("Running cleanup_stale_rate_limits cron job")

    cutoff_time = datetime.now() - timedelta(hours=1)

    # Limit and batch delete
    rate_limits = (
        get_db().collection(Collections.RATE_LIMITS).where(Fields.LAST_REQUEST, "<=", cutoff_time).limit(500).stream()
    )

    deleted_count = 0
    batch = get_db().batch()

    for doc in rate_limits:
        batch.delete(doc.reference)
        deleted_count += 1

        # Commit every 500 deletes
        if deleted_count % 500 == 0:
            batch.commit()
            batch = get_db().batch()

    # Commit remaining
    if deleted_count % 500 != 0:
        batch.commit()

    logger.info(f"Rate limit cleanup completed: {deleted_count} documents deleted")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def cleanup_orphaned_r2_images(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Removes orphaned images from Cloudflare R2 storage.

    Runs: Daily

    Logic:
    - Collect all imageUrls from active products
    - List R2 objects in products/ prefix
    - Delete objects not referenced by any product
    - Safety: Only deletes images older than 24 hours (avoids race with uploads)
    """
    import boto3
    from botocore.config import Config

    from config import R2Config, get_r2_credentials

    logger.info("Running cleanup_orphaned_r2_images cron job")

    # Collect all image URLs currently referenced by products
    referenced_keys = set()
    products = get_db().collection(Collections.PRODUCTS).stream()

    for product_doc in products:
        product_data = product_doc.to_dict()
        image_urls = product_data.get(Fields.IMAGE_URLS, [])
        for url in image_urls:
            # Extract R2 key from CDN URL
            # URL format: https://cdn.origna.ca/products/uuid.ext
            if isinstance(url, str) and "/" in url:
                # Get path after domain
                path_parts = url.split("/")
                # Reconstruct key: e.g. "products/uuid.ext" or "dev/products/uuid.ext"
                for i, part in enumerate(path_parts):
                    if part in ("products", "dev"):
                        key = "/".join(path_parts[i:])
                        referenced_keys.add(key)
                        break

    logger.info(f"  Found {len(referenced_keys)} referenced image keys")

    # List R2 objects
    r2_creds = get_r2_credentials()
    r2_access_key = r2_creds.get("access_key")
    r2_secret_key = r2_creds.get("secret_key")
    r2_account_id = r2_creds.get("account_id")

    if not all([r2_access_key, r2_secret_key, r2_account_id]):
        logger.warning("  ⚠️ R2 credentials not configured, skipping cleanup")
        return

    s3_client = boto3.client(
        "s3",
        endpoint_url=f"https://{r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=r2_access_key,
        aws_secret_access_key=r2_secret_key,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )

    bucket_name = R2Config.BUCKET_NAME
    prefix = R2Config.get_image_path("products", "").rsplit("/", 1)[0] + "/"

    # List objects in products/ prefix
    orphaned_keys = []
    continuation_token = None
    cutoff = datetime.now() - timedelta(hours=24)

    while True:
        list_kwargs = {
            "Bucket": bucket_name,
            "Prefix": prefix,
            "MaxKeys": 1000,
        }
        if continuation_token:
            list_kwargs["ContinuationToken"] = continuation_token

        try:
            response = s3_client.list_objects_v2(**list_kwargs)
        except Exception as e:
            logger.warning(f"  ⚠️ R2 list error: {e}")
            return

        for obj in response.get("Contents", []):
            key = obj["Key"]
            last_modified = obj.get("LastModified")

            # Safety: skip recently uploaded files (race condition with active uploads)
            if last_modified and last_modified.replace(tzinfo=None) > cutoff:
                continue

            if key not in referenced_keys:
                orphaned_keys.append(key)

        if not response.get("IsTruncated"):
            break
        continuation_token = response.get("NextContinuationToken")

    logger.info(f"  Found {len(orphaned_keys)} orphaned images to delete")

    # Delete orphaned objects in batches of 100
    deleted_count = 0
    for i in range(0, len(orphaned_keys), 100):
        batch_keys = orphaned_keys[i : i + 100]
        try:
            s3_client.delete_objects(Bucket=bucket_name, Delete={"Objects": [{"Key": k} for k in batch_keys]})
            deleted_count += len(batch_keys)
        except Exception as e:
            logger.warning(f"  ⚠️ R2 delete error for batch {i}: {e}")

    logger.info(f"  R2 orphan cleanup completed: {deleted_count} files deleted")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def cleanup_stale_webhook_events(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Removes processed webhook event records older than 7 days.

    Runs: Daily

    Logic:
    - The webhook_events collection stores event IDs for deduplication
    - Old records (>7 days) are no longer needed — Stripe won't replay them
    - Clean up to prevent unbounded collection growth
    """
    logger.info("Running cleanup_stale_webhook_events cron job")

    cutoff_time = datetime.now() - timedelta(days=BusinessRules.WEBHOOK_EVENT_RETENTION_DAYS)

    webhook_docs = (
        get_db().collection(Collections.WEBHOOK_EVENTS).where(Fields.CREATED_AT, "<=", cutoff_time).limit(500).stream()
    )

    deleted_count = 0
    batch = get_db().batch()

    for doc in webhook_docs:
        batch.delete(doc.reference)
        deleted_count += 1

        if deleted_count % 500 == 0:
            batch.commit()
            batch = get_db().batch()

    if deleted_count % 500 != 0:
        batch.commit()

    logger.info(f"Webhook event cleanup completed: {deleted_count} documents deleted")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def cleanup_stale_security_alerts(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Archives resolved security alerts older than 90 days.

    Runs: Daily

    Logic:
    - Resolved alerts older than 90 days are deleted to prevent unbounded growth
    - Unresolved alerts are NEVER cleaned up (require manual resolution)
    """
    logger.info("Running cleanup_stale_security_alerts cron job")

    cutoff_time = datetime.now() - timedelta(days=BusinessRules.SECURITY_ALERT_RETENTION_DAYS)

    alert_docs = (
        get_db()
        .collection(Collections.SECURITY_ALERTS)
        .where(Fields.RESOLVED, "==", True)
        .where(Fields.TIMESTAMP, "<=", cutoff_time)
        .limit(500)
        .stream()
    )

    deleted_count = 0
    batch = get_db().batch()

    for doc in alert_docs:
        batch.delete(doc.reference)
        deleted_count += 1

        if deleted_count % 500 == 0:
            batch.commit()
            batch = get_db().batch()

    if deleted_count % 500 != 0:
        batch.commit()

    logger.info(f"Security alert cleanup completed: {deleted_count} resolved alerts deleted")


@scheduler_fn.on_schedule(schedule="every 1 hours", **CRON_OPTIONS)
def retry_failed_algolia_syncs(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Retries failed Algolia sync operations from the Dead Letter Queue.

    Runs: Every hour

    Logic:
    - Reads unresolved entries from algolia_sync_failures collection
    - Retries up to 3 times with exponential backoff tracking
    - Marks as resolved after successful retry or max attempts
    - Prevents unbounded DLQ growth
    """
    logger.info("Running retry_failed_algolia_syncs cron job")

    from services.algolia_service import delete_product as algolia_delete_product
    from services.algolia_service import index_product as algolia_index_product

    # Fetch unresolved sync failures (max 50 per run)
    failures = (
        get_db().collection(Collections.ALGOLIA_SYNC_FAILURES).where(Fields.RESOLVED, "==", False).limit(50).stream()
    )

    retried = 0
    resolved = 0
    max_retries = BusinessRules.ALGOLIA_DLQ_MAX_RETRIES

    for failure_doc in failures:
        failure_data = failure_doc.to_dict()
        product_id = failure_data.get(Fields.PRODUCT_ID)
        action = failure_data.get(Fields.ACTION, AlgoliaActionValues.INDEX)
        retry_count = failure_data.get(Fields.RETRY_COUNT, 0)

        if not product_id:
            failure_doc.reference.update({Fields.RESOLVED: True})
            resolved += 1
            continue

        # Max retries exceeded — mark as resolved (needs manual intervention)
        if retry_count >= max_retries:
            failure_doc.reference.update(
                {
                    Fields.RESOLVED: True,
                    Fields.MAX_RETRIES_EXCEEDED: True,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            resolved += 1
            logger.warning(f"Algolia sync for {product_id} exceeded max retries — marking as resolved")
            continue

        try:
            if action == AlgoliaActionValues.DELETE:
                algolia_delete_product(product_id)
            else:
                # Re-fetch product data from Firestore
                product_doc = get_db().collection(Collections.PRODUCTS).document(product_id).get()
                if not product_doc.exists:
                    # Product was deleted — try to delete from Algolia instead
                    algolia_delete_product(product_id)
                else:
                    product_data = product_doc.to_dict()
                    if product_data.get(Fields.IS_ACTIVE, True):
                        algolia_index_product(product_id, product_data)
                    else:
                        algolia_delete_product(product_id)

            # Success — resolve the failure
            failure_doc.reference.update(
                {
                    Fields.RESOLVED: True,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            resolved += 1
            retried += 1
        except Exception as e:
            # Increment retry count
            failure_doc.reference.update(
                {
                    Fields.RETRY_COUNT: retry_count + 1,
                    Fields.LAST_RETRY_ERROR: type(e).__name__,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            logger.warning(f"Algolia retry failed for {product_id}: {type(e).__name__}")

    logger.info(f"Algolia DLQ retry completed: {retried} retried, {resolved} resolved")
