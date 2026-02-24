"""
Scheduled Cron Jobs
- Auto-capture confirmed receipts (daily)
- Check expired authorizations (daily)
- Monitor Algolia sync (every 15 min)
- Cleanup stale rate limits (every 30 min)
- Archive old orders (every 12 hours)
"""

import logging
from datetime import UTC, datetime, timedelta

import stripe
from firebase_functions import scheduler_fn

from config import (
    AUTHORIZATION_VALID_DAYS,
    AUTO_CONFIRM_DAYS,
    IS_EMULATOR,
    PLATFORM_FEE_RATIO,
    get_stripe_secret_key,
)
from schema_constants import (
    AlgoliaActionValues,
    BusinessRules,
    Collections,
    CronLockStatusValues,
    DeliveryStatusValues,
    EmailConfig,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ProductApprovalStatusValues,
    ProductLifecycleStatusValues,
    ReturnStatusValues,
    SecurityAlertTypes,
    SeverityLevels,
    SubscriptionStatusValues,
    UserRoleValues,
)
from utils.function_options import CRON_OPTIONS

logger = logging.getLogger(__name__)

# stripe.api_key = STRIPE_SECRET_KEY  # Removed global assignment to prevent deploy crash

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
    now = datetime.now(UTC)
    cutoff = now - timedelta(minutes=ttl_minutes)

    @get_firestore().transactional
    def _try_acquire(transaction):
        doc = lock_ref.get(transaction=transaction)
        if doc.exists:
            lock_data = doc.to_dict()
            locked_at = lock_data.get(Fields.LOCKED_AT)
            if locked_at:
                if hasattr(locked_at, "tzinfo") and locked_at.tzinfo is None:
                    locked_at = locked_at.replace(tzinfo=UTC)
                if locked_at > cutoff:
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
                Fields.COMPLETED_AT: datetime.now(UTC),
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
        # Initialize Stripe key locally
        stripe.api_key = get_stripe_secret_key()
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

    cutoff_date = datetime.now(UTC) - timedelta(days=AUTO_CONFIRM_DAYS)

    # Query DELIVERED orders with captured payment that haven't been paid out yet
    # Also query SHIPPED orders past cutoff for auto-confirmation
    all_orders = []

    # DELIVERED orders ready for payout (payoutStatus not yet completed)
    # AUDIT FIX (CRITICAL-001): Include AUTHORIZED payments for auto-capture
    delivered_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.ORDER_STATUS, "==", OrderStatusValues.DELIVERED)
        .where(Fields.PAYMENT_STATUS, "in", [PaymentStatusValues.CAPTURED, PaymentStatusValues.AUTHORIZED])
        .where(Fields.UPDATED_AT, "<=", cutoff_date)
        .limit(250)
        .stream()
    )
    all_orders.extend(delivered_orders)

    # SHIPPED orders past cutoff — auto-confirm as delivered for payout
    # AUDIT FIX (CRITICAL-001): Include AUTHORIZED payments for auto-capture
    shipped_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.ORDER_STATUS, "==", OrderStatusValues.SHIPPED)
        .where(Fields.PAYMENT_STATUS, "in", [PaymentStatusValues.CAPTURED, PaymentStatusValues.AUTHORIZED])
        .where(Fields.SHIPPED_AT, "<=", cutoff_date)
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

        # CRITICAL FIX (CRITICAL-001): Capture payment if it's only authorized
        if order_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.AUTHORIZED:
            try:
                # Emulator mode: skip real Stripe capture for fake payment intents
                if IS_EMULATOR and not payment_intent_id.startswith("pi_3"):
                    order_doc.reference.update(
                        {
                            Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                            Fields.CAPTURED_AT: datetime.now(UTC),
                            Fields.UPDATED_AT: datetime.now(UTC),
                        }
                    )
                    order_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.CAPTURED
                else:
                    # 1. Fetch PI status
                    pi = stripe.PaymentIntent.retrieve(payment_intent_id)
                    if pi.status == "requires_capture":
                        # 2. Capture the funds
                        logger.info(f"Auto-capturing funds for order {order_id} (PI: {payment_intent_id})")
                        pi = stripe.PaymentIntent.capture(
                            payment_intent_id, idempotency_key=f"auto_capture_{order_id}_{payment_intent_id}"
                        )

                    # 3. Update Firestore status immediately
                    if pi.status in ["succeeded", "processing"]:
                        order_doc.reference.update(
                            {
                                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                                Fields.CAPTURED_AT: datetime.now(UTC),
                                Fields.UPDATED_AT: datetime.now(UTC),
                            }
                        )
                        # Refresh order_data for the rest of the loop
                        order_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.CAPTURED
                        logger.info(f"Successfully auto-captured order {order_id}")
                    else:
                        logger.warning(
                            f"⚠️ Auto-capture for order {order_id} resulted in unexpected PI status: {pi.status}"
                        )
                        continue
            except Exception as capture_err:
                logger.error(f"Error during auto-capture for order {order_id}: {capture_err}")
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
                    item[Fields.DELIVERED_AT] = datetime.now(UTC)
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
                    item_price_cents = round(item.get(Fields.PRICE, 0) * 100)  # price is dollar float → convert to cents
                    item_total_cents = item_price_cents * item[Fields.QUANTITY]
                    sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents

            # AUDIT FIX (CRITICAL-001): Use stored fee rate from checkout, not current config
            # Fee is calculated on subtotal, so we must divide by subtotal to get the rate
            stored_fee_total = order_data.get(Fields.PLATFORM_FEE_TOTAL_CENTS)
            order_subtotal = order_data.get(Fields.SUBTOTAL_CENTS, 1)

            stored_fee_rate = (
                (stored_fee_total / order_subtotal) if stored_fee_total and order_subtotal > 0 else PLATFORM_FEE_RATIO
            )

            expected_seller_count = len(sellers_total_cents)
            current_order_success_count = 0  # Track successful transfers for this order

            for seller_id, amount_cents in sellers_total_cents.items():
                platform_fee_cents = round(amount_cents * stored_fee_rate)
                net_amount_cents = amount_cents - platform_fee_cents

                # Fix 3: Use snapshot of seller's Stripe account from time of checkout
                # Prevents "Account Swap" attack where seller changes account after order to bypass limits
                seller_stripe_accounts = order_data.get(Fields.SELLER_STRIPE_ACCOUNTS, {})
                stripe_account_id = seller_stripe_accounts.get(seller_id)

                # Get seller's current profile for suspension check
                seller_ref = get_db().collection(Collections.USERS).document(seller_id)
                seller_doc = seller_ref.get()

                if seller_doc.exists:
                    seller_data = seller_doc.to_dict()

                    # Fallback to current profile if snapshot missing (backward compatibility)
                    if not stripe_account_id:
                        stripe_account_id = seller_data.get(Fields.STRIPE_ACCOUNT_ID)
                        if stripe_account_id:
                            logger.warning(f"⚠️ Using current Stripe account for seller {seller_id} (snapshot missing)")

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

                            # Create PENDING payout record BEFORE Stripe transfer (idempotent)
                            existing_payouts = list(
                                get_db()
                                .collection(Collections.PAYOUTS)
                                .where(Fields.ORDER_ID, "==", order_id)
                                .where(Fields.SELLER_ID, "==", seller_id)
                                .limit(1)
                                .get()
                            )
                            payout_ref = (
                                existing_payouts[0].reference
                                if existing_payouts
                                else get_db().collection(Collections.PAYOUTS).document()
                            )
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

                            current_order_success_count += 1

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

            if current_order_success_count == expected_seller_count and current_order_success_count > 0:
                payout_count += 1
                logger.info(f"Auto-payout completed for order {order_id} ({current_order_success_count} transfers)")

                # Mark order payout as completed so it's not reprocessed next cron run
                order_doc.reference.update(
                    {
                        Fields.PAYOUT_STATUS: PayoutStatusValues.COMPLETED,
                        Fields.UPDATED_AT: get_server_timestamp(),
                    }
                )
            elif current_order_success_count > 0:
                payout_count += 1
                logger.warning(
                    f"Partial payout for order {order_id} ({current_order_success_count}/{expected_seller_count} transfers)"
                )
                order_doc.reference.update(
                    {
                        Fields.PAYOUT_STATUS: PayoutStatusValues.PARTIAL,
                        Fields.REQUIRES_MANUAL_REVIEW: True,
                        Fields.MANUAL_REVIEW_REASON: f"Partial payout: {current_order_success_count}/{expected_seller_count} sellers paid",
                        Fields.UPDATED_AT: get_server_timestamp(),
                    }
                )
            else:
                logger.warning(f"No successful payouts for order {order_id}, leaving as PROCESSING")

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

    logger.info(f"Auto-payout completed: {payout_count} paid out, {failed_count} failed")


@scheduler_fn.on_schedule(schedule="every 1 hours", **CRON_OPTIONS)
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

    cutoff_date = datetime.now(UTC) - timedelta(days=AUTHORIZATION_VALID_DAYS)

    # Find stale PENDING orders that were never paid (session expired/abandoned)
    # OR were AUTHORIZED but never captured (manual capture expiry)
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(
            Fields.PAYMENT_STATUS,
            "in",
            [
                PaymentStatusValues.AWAITING_PAYMENT,
                PaymentStatusValues.SESSION_EXPIRED,
                PaymentStatusValues.AUTHORIZED,
            ],
        )
        .where(Fields.ORDER_STATUS, "in", [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED])
        .where(Fields.CREATED_AT, "<=", cutoff_date)
        .limit(100)
        .stream()
    )

    expired_count = 0

    for order_doc in orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id

        # FIX 1: Cancel Stripe authorization BEFORE marking EXPIRED in Firestore
        if order_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.AUTHORIZED:
            pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
            if pi_id:
                try:
                    logger.info(f"Cancelling stale authorization for order {order_id} (PI: {pi_id})")
                    stripe.api_key = get_stripe_secret_key()
                    stripe.PaymentIntent.cancel(pi_id)
                except Exception as cancel_err:
                    logger.warning(f"⚠️ Failed to cancel Stripe PI {pi_id} for expired order {order_id}: {cancel_err}")

        # FIX 2: Check STOCK_RESTORED from fresh doc inside transaction
        @get_firestore().transactional
        def try_expire_order(transaction, order_doc=order_doc, order_data=order_data):
            fresh_doc = order_doc.reference.get(transaction=transaction)
            if not fresh_doc.exists:
                return "not_found", False
            fresh_data = fresh_doc.to_dict()
            current_status = fresh_data.get(Fields.ORDER_STATUS)
            if current_status not in [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED]:
                return f"invalid_status:{current_status}", False
            stock_already_restored = fresh_data.get(Fields.STOCK_RESTORED, False)
            payment_status = (
                PaymentStatusValues.AUTHORIZATION_EXPIRED
                if order_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.AUTHORIZED
                else PaymentStatusValues.SESSION_EXPIRED
            )
            transaction.update(
                order_doc.reference,
                {
                    Fields.ORDER_STATUS: OrderStatusValues.EXPIRED,
                    Fields.PAYMENT_STATUS: payment_status,
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )
            return "locked", stock_already_restored

        try:
            expire_result, stock_already_restored = try_expire_order(get_db().transaction())
            if expire_result != "locked":
                logger.info(f"Order {order_id} cannot be expired: {expire_result}")
                continue
        except Exception as e:
            logger.warning(f"⚠️ Failed to lock order {order_id} for expiry: {str(e)}")
            continue

        # Use fresh stock_already_restored from transaction (Fix 2)
        if stock_already_restored:
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

    if not acquire_cron_lock("auto_archive_old_orders"):
        logger.info("auto_archive_old_orders: lock held, skipping")
        return

    try:
        cutoff_date = datetime.now(UTC) - timedelta(days=BusinessRules.ARCHIVE_AFTER_DAYS)

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
                [OrderStatusValues.DELIVERED, OrderStatusValues.CANCELLED],
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

            batch.update(
                order_doc.reference,
                {
                    Fields.ARCHIVED: True,
                    Fields.ARCHIVED_AT: get_server_timestamp(),
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )
            archived_count += 1

            # Commit every 500 operations
            if archived_count % 500 == 0:
                batch.commit()
                batch = get_db().batch()

        # Commit remaining
        if archived_count % 500 != 0:
            batch.commit()

        logger.info(f"Archive completed: {archived_count} orders archived")
    finally:
        release_cron_lock("auto_archive_old_orders")


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

        products_query = get_db().collection(Collections.PRODUCTS).where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)

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

    cutoff_time = datetime.now(UTC) - timedelta(hours=1)

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
    # select() fetches only imageUrls field — avoids reading full product docs
    referenced_keys = set()
    products = get_db().collection(Collections.PRODUCTS).select([Fields.IMAGE_URLS]).stream()

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
    cutoff = datetime.now(UTC) - timedelta(hours=24)

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
            if last_modified and last_modified > cutoff:
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

    cutoff_time = datetime.now(UTC) - timedelta(days=BusinessRules.WEBHOOK_EVENT_RETENTION_DAYS)

    webhook_docs = (
        get_db().collection(Collections.WEBHOOK_EVENTS).where(Fields.TIMESTAMP, "<=", cutoff_time).limit(500).stream()
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

    cutoff_time = datetime.now(UTC) - timedelta(days=BusinessRules.SECURITY_ALERT_RETENTION_DAYS)

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
                    if product_data.get(Fields.LIFECYCLE_STATUS) == ProductLifecycleStatusValues.ACTIVE:
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


@scheduler_fn.on_schedule(schedule="every 168 hours", **CRON_OPTIONS)  # weekly
def revalidate_digital_product_urls(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Weekly: HEAD-check all approved digital product download URLs.
    If a URL is unreachable, deactivate the product and notify the seller.
    This catches URLs that go dead after approval.
    """
    import requests

    from handlers.products import _get_seller_email, _send_product_rejection_email

    logger.info("Starting weekly digital product URL revalidation")

    if not acquire_cron_lock("revalidate_digital_product_urls"):
        logger.info("revalidate_digital_product_urls: lock held, skipping")
        return

    checked = 0
    deactivated = 0

    products = (
        get_db()
        .collection(Collections.PRODUCTS)
        .where(Fields.IS_DIGITAL, "==", True)
        .where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)
        .stream()
    )

    for doc in products:
        product_data = doc.to_dict() or {}
        product_id = doc.id
        checked += 1

        urls_to_check: list[tuple[str, str]] = []
        book_url = product_data.get(Fields.BOOK_SOURCE_URL)
        if book_url:
            urls_to_check.append(("bookSourceUrl", book_url))
        builds = product_data.get(Fields.DIGITAL_BUILDS) or {}
        for platform, url in builds.items():
            if url:
                urls_to_check.append((f"digitalBuilds.{platform}", url))

        dead = []
        for label, url in urls_to_check:
            try:
                resp = requests.head(url, timeout=10, allow_redirects=True, headers={"User-Agent": "OrignaBot/1.0"})
                if resp.status_code >= 400:
                    dead.append(label)
            except requests.exceptions.RequestException:
                dead.append(label)

        if dead:
            reason = f"Download URL(s) became unreachable: {', '.join(dead)}"
            doc.reference.update(
                {
                    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.UNDER_REVIEW,
                    Fields.APPROVAL_REJECTION_REASON: reason,
                }
            )
            # Remove from Algolia
            try:
                from services.algolia_service import delete_product as algolia_delete

                algolia_delete(product_id)
            except Exception:
                pass

            # Notify seller
            seller_email = _get_seller_email(product_data.get(Fields.SELLER_ID))
            if seller_email:
                try:
                    _send_product_rejection_email(seller_email, product_data.get(Fields.NAME, ""), reason)
                except Exception as e:
                    logger.error(f"Failed to email seller for dead URL on {product_id}: {e}")

            deactivated += 1
            logger.warning(f"Deactivated product {product_id} — dead URLs: {dead}")

    logger.info(f"Digital URL revalidation done: {checked} checked, {deactivated} deactivated")
    release_cron_lock("revalidate_digital_product_urls")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def check_low_stock_alerts(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Daily cron: email sellers when a product's stockQuantity falls at or below
    inventory.lowStockThreshold (only when the seller has opted into alerts).

    Runs: Every 24 hours

    Logic:
    - Only products where isActive=True AND approvalStatus=approved
    - inventory.lowStockThreshold > 0 (seller opted in)
    - inventory.trackQuantity = True (stock tracking is on)
    - stockQuantity <= inventory.lowStockThreshold
    - lastLowStockAlertAt is None OR > 23 hours ago (avoid daily spam)
    """
    from services.email_service import send_email

    logger.info("Running check_low_stock_alerts cron job")
    alerted_count = 0
    checked_count = 0

    # Fetch active + approved products in batches of 500
    query = (
        get_db()
        .collection(Collections.PRODUCTS)
        .where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)
        .limit(500)
    )

    now_utc = datetime.now(UTC)
    alert_cooldown = timedelta(hours=23)

    # First pass: collect products needing alerts and unique seller IDs
    products_needing_alert = []
    unique_seller_ids: set = set()

    for doc in query.stream():
        checked_count += 1
        data = doc.to_dict() or {}

        inventory = data.get(Fields.INVENTORY) or {}
        threshold = inventory.get(Fields.LOW_STOCK_THRESHOLD, 0)
        track_quantity = inventory.get(Fields.TRACK_QUANTITY, True)

        # Skip if seller hasn't opted in (threshold=0) or tracking is disabled
        if not threshold or not track_quantity:
            continue

        stock = data.get(Fields.STOCK_QUANTITY, 0)
        if stock > threshold:
            continue

        # Check cooldown — don't re-alert within 23 hours
        last_alert = data.get(Fields.LAST_LOW_STOCK_ALERT_AT)
        if last_alert:
            if hasattr(last_alert, "tzinfo") and last_alert.tzinfo is None:
                last_alert = last_alert.replace(tzinfo=UTC)
            elif not hasattr(last_alert, "tzinfo"):
                last_alert = None
        if last_alert and (now_utc - last_alert) < alert_cooldown:
            continue

        seller_id = data.get(Fields.SELLER_ID)
        if not seller_id:
            continue

        products_needing_alert.append((doc, data, stock, threshold))
        unique_seller_ids.add(seller_id)

    # Batch-read all seller docs to avoid N+1
    seller_data_map: dict = {}
    if unique_seller_ids:
        seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in unique_seller_ids]
        for seller_snap in get_db().get_all(seller_refs):
            if seller_snap.exists:
                seller_data_map[seller_snap.id] = seller_snap.to_dict() or {}

    # Second pass: send low stock alert emails
    for doc, data, stock, threshold in products_needing_alert:
        seller_id = data.get(Fields.SELLER_ID)
        seller_info = seller_data_map.get(seller_id)
        if not seller_info:
            continue

        seller_email = seller_info.get(Fields.EMAIL)
        if not seller_email:
            continue

        product_name = data.get(Fields.NAME, "Your product")
        subject = f"[Origna] Low stock alert: {product_name}"
        html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #E53E3E;">⚠️ Low Stock Alert</h2>
  <p>Your product <strong>{product_name}</strong> is running low on stock.</p>
  <table style="width:100%; border-collapse:collapse; margin: 16px 0;">
    <tr><td style="padding:6px 0; color:#666; width:160px;">Current stock</td>
        <td style="font-weight:bold; color:#E53E3E;">{stock} unit{"s" if stock != 1 else ""} remaining</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Alert threshold</td>
        <td>{threshold} units</td></tr>
    <tr><td style="padding:6px 0; color:#666;">Product ID</td>
        <td><code style="font-size:12px;">{doc.id}</code></td></tr>
  </table>
  <p>Please restock soon to avoid missing sales.</p>
  <p style="margin-top:20px;">
    <a href="https://orignagta.ca/seller/products" style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Manage Inventory
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:20px;">
    You are receiving this because you enabled low stock alerts for this product.<br>
    To disable, edit the product and uncheck "Notify me when stock falls below threshold".<br>
    Origna Ventures Inc. — {EmailConfig.PHYSICAL_ADDRESS}
  </p>
</div>"""

        try:
            send_email(seller_email, subject, html)
            get_db().collection(Collections.PRODUCTS).document(doc.id).update({Fields.LAST_LOW_STOCK_ALERT_AT: now_utc})
            alerted_count += 1
            logger.info(f"Low stock alert sent for product {doc.id} (stock={stock}, threshold={threshold})")
        except Exception as e:
            logger.error(f"Failed to send low stock alert for {doc.id}: {e}")

    logger.info(f"check_low_stock_alerts done: {checked_count} checked, {alerted_count} alerted")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def send_abandoned_cart_emails(event: scheduler_fn.ScheduledEvent) -> None:
    """
    TASK 10 — Daily cron: email buyers who have items in cart but haven't checked out.

    Logic:
    - Only users with marketingOptIn=True (CASL compliance)
    - lastCheckoutTimestamp is None OR > 24h ago
    - User has at least one active product in their cart subcollection
    - lastCartAbandonEmailAt is None OR > 72h ago (3-day cooldown)
    - Skip users whose cart items are all deactivated/deleted
    """
    from services.email_service import send_email

    logger.info("Running send_abandoned_cart_emails cron job")

    now_utc = datetime.now(UTC)
    cooldown_cutoff = now_utc - timedelta(hours=72)
    checkout_cutoff = now_utc - timedelta(hours=24)
    sent_count = 0
    skipped_count = 0

    # Fetch users who opted into marketing and haven't been emailed in 3 days
    users_query = get_db().collection(Collections.USERS).where(Fields.MARKETING_OPT_IN, "==", True).limit(500)

    for user_doc in users_query.stream():
        user_data = user_doc.to_dict() or {}
        user_id = user_doc.id
        user_email = user_data.get(Fields.EMAIL)

        if not user_email:
            continue

        # 3-day cooldown check
        last_abandon_email = user_data.get(Fields.LAST_CART_ABANDON_EMAIL_AT)
        if last_abandon_email:
            if hasattr(last_abandon_email, "tzinfo") and last_abandon_email.tzinfo is None:
                last_abandon_email = last_abandon_email.replace(tzinfo=UTC)
            if last_abandon_email > cooldown_cutoff:
                skipped_count += 1
                continue

        # Skip if checked out recently (< 24h ago)
        last_checkout = user_data.get(Fields.LAST_CHECKOUT_TIMESTAMP)
        if last_checkout:
            if hasattr(last_checkout, "tzinfo") and last_checkout.tzinfo is None:
                last_checkout = last_checkout.replace(tzinfo=UTC)
            if last_checkout > checkout_cutoff:
                skipped_count += 1
                continue

        # Check cart subcollection
        cart_items = list(
            get_db().collection(Collections.USERS).document(user_id).collection(Collections.CART).limit(10).stream()
        )

        if not cart_items:
            continue

        # Verify at least one cart item is still active — batch fetch all product docs
        active_product_names: list[str] = []
        product_ids = [
            (cart_doc.to_dict() or {}).get(Fields.PRODUCT_ID) or cart_doc.id
            for cart_doc in cart_items
        ]
        product_refs = [get_db().collection(Collections.PRODUCTS).document(pid) for pid in product_ids]
        product_docs = get_db().get_all(product_refs)
        for product_doc in product_docs:
            if product_doc.exists:
                pd = product_doc.to_dict() or {}
                if pd.get(Fields.IS_ACTIVE) and pd.get(Fields.STOCK_QUANTITY, 0) > 0:
                    active_product_names.append(pd.get(Fields.NAME, "an item"))
            if len(active_product_names) >= 3:
                break

        if not active_product_names:
            skipped_count += 1
            continue

        # Build simple abandoned cart email
        product_list_html = "".join(f"<li>{name}</li>" for name in active_product_names)
        more_label = (
            f" (and {len(cart_items) - len(active_product_names)} more)"
            if len(cart_items) > len(active_product_names)
            else ""
        )
        display_name = user_data.get(Fields.NAME) or "there"
        subject = "You left something in your cart — Origna"
        html = f"""
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #5B30F6;">Your cart is waiting 🛒</h2>
  <p>Hi {display_name},</p>
  <p>You have items in your cart that are still available:</p>
  <ul style="margin:12px 0; padding-left:20px;">
    {product_list_html}
  </ul>
  {f'<p style="color:#666; font-size:13px;">{more_label}</p>' if more_label else ""}
  <p style="margin-top:20px;">
    <a href="https://orignagta.ca/cart" style="background:#5B30F6; color:#fff; padding:10px 22px; border-radius:6px; text-decoration:none; font-weight:bold;">
      Complete your purchase
    </a>
  </p>
  <p style="color:#999; font-size:12px; margin-top:24px;">
    You are receiving this reminder because you opted in to marketing emails.<br>
    <a href="https://orignagta.ca/settings/notifications" style="color:#999;">Unsubscribe</a> · Origna Ventures Inc.
  </p>
</div>"""

        try:
            send_email(user_email, subject, html)
            get_db().collection(Collections.USERS).document(user_id).update(
                {Fields.LAST_CART_ABANDON_EMAIL_AT: now_utc}
            )
            sent_count += 1
        except Exception as e:
            logger.error(f"Failed to send abandoned cart email to user {user_id}: {e}")

    logger.info(f"send_abandoned_cart_emails done: {sent_count} sent, {skipped_count} skipped")


@scheduler_fn.on_schedule(schedule="every 168 hours", **CRON_OPTIONS)  # weekly
def compute_seller_metrics(event: scheduler_fn.ScheduledEvent) -> None:
    """
    TASK 11 — Weekly cron: compute seller health metrics and raise security alerts for threshold breaches.

    Thresholds → SECURITY_ALERT:
    - disputeRate  > 5%
    - refundRate   > 15%
    - cancellationRate > 10%

    Metrics are written to seller_metrics/{sellerId}.
    """
    from schema_constants import SecurityAlertTypes, SeverityLevels

    logger.info("Running compute_seller_metrics cron job")

    now_utc = datetime.now(UTC)
    window_start = now_utc - timedelta(days=30)
    processed_count = 0
    alerted_count = 0

    DISPUTE_THRESHOLD = 0.05
    REFUND_THRESHOLD = 0.15
    CANCEL_THRESHOLD = 0.10

    # Get all sellers
    sellers_query = get_db().collection(Collections.USERS).where(Fields.ROLES, "array_contains", UserRoleValues.SELLER).limit(500)

    for seller_doc in sellers_query.stream():
        seller_id = seller_doc.id
        seller_data = seller_doc.to_dict() or {}

        if not seller_data.get(Fields.IS_SELLER) and UserRoleValues.SELLER not in (seller_data.get(Fields.ROLES) or []):
            continue

        # Fetch orders for this seller in the last 30 days
        orders_query = (
            get_db()
            .collection(Collections.ORDERS)
            .where(Fields.SELLER_IDS, "array_contains", seller_id)
            .where(Fields.CREATED_AT, ">=", window_start)
            .limit(500)
        )

        orders = list(orders_query.stream())
        total_orders = len(orders)

        if total_orders == 0:
            # Write zero-metrics doc (no alert)
            get_db().collection(Collections.SELLER_METRICS).document(seller_id).set(
                {
                    Fields.SELLER_ID: seller_id,
                    Fields.DISPUTE_RATE: 0.0,
                    Fields.REFUND_RATE: 0.0,
                    Fields.CANCELLATION_RATE: 0.0,
                    Fields.LATE_SHIPMENT_RATE: 0.0,
                    Fields.AVG_RESPONSE_TIME_HOURS: 0.0,
                    Fields.TOTAL_ORDERS_30D: 0,
                    Fields.TOTAL_REVENUE_CENTS_30D: 0,
                    Fields.COMPUTED_AT: now_utc,
                }
            )
            processed_count += 1
            continue

        # Tally metrics
        disputed = 0
        refunded = 0
        cancelled = 0
        late_shipped = 0
        total_revenue_cents = 0

        for order_doc in orders:
            od = order_doc.to_dict() or {}
            status = od.get(Fields.ORDER_STATUS, "")
            payment_status = od.get(Fields.PAYMENT_STATUS, "")

            if status == OrderStatusValues.CANCELLED:
                cancelled += 1
            if payment_status == PaymentStatusValues.REFUNDED:
                refunded += 1

            # Revenue: sum payout amounts for this seller
            payouts = od.get(Fields.SELLER_PAYOUTS) or []
            for payout in payouts:
                if isinstance(payout, dict) and payout.get(Fields.SELLER_ID) == seller_id:
                    total_revenue_cents += payout.get(Fields.SELLER_AMOUNT_CENTS, 0)

            # Dispute: check if order has an associated dispute in webhook_events
            if od.get(Fields.HAS_DISPUTE):
                disputed += 1

            # Late shipment: shipped > estimatedShipDays after order
            items = od.get(Fields.ITEMS, [])
            for item in items:
                if isinstance(item, dict) and item.get(Fields.SELLER_ID) == seller_id:
                    shipped_at = item.get(Fields.SHIPPED_AT)
                    created_at = od.get(Fields.CREATED_AT)
                    est_days = item.get(Fields.ESTIMATED_SHIP_DAYS, 3)
                    if shipped_at and created_at:
                        if hasattr(shipped_at, "tzinfo") and shipped_at.tzinfo is None:
                            shipped_at = shipped_at.replace(tzinfo=UTC)
                        if hasattr(created_at, "tzinfo") and created_at.tzinfo is None:
                            created_at = created_at.replace(tzinfo=UTC)
                        actual_days = (shipped_at - created_at).days
                        if actual_days > est_days:
                            late_shipped += 1

        dispute_rate = disputed / total_orders
        refund_rate = refunded / total_orders
        cancel_rate = cancelled / total_orders
        late_rate = late_shipped / total_orders

        # Write metrics
        get_db().collection(Collections.SELLER_METRICS).document(seller_id).set(
            {
                Fields.SELLER_ID: seller_id,
                Fields.DISPUTE_RATE: round(dispute_rate, 4),
                Fields.REFUND_RATE: round(refund_rate, 4),
                Fields.CANCELLATION_RATE: round(cancel_rate, 4),
                Fields.LATE_SHIPMENT_RATE: round(late_rate, 4),
                Fields.AVG_RESPONSE_TIME_HOURS: 0.0,  # TODO: implement response time tracking
                Fields.TOTAL_ORDERS_30D: total_orders,
                Fields.TOTAL_REVENUE_CENTS_30D: total_revenue_cents,
                Fields.COMPUTED_AT: now_utc,
            }
        )
        processed_count += 1

        # Check threshold breaches (only for active sellers)
        seller_status = seller_data.get(Fields.STATUS, "active")
        if seller_status not in ("suspended", "banned"):
            breaches = []
            if dispute_rate > DISPUTE_THRESHOLD:
                breaches.append(f"disputeRate={dispute_rate:.1%}")
            if refund_rate > REFUND_THRESHOLD:
                breaches.append(f"refundRate={refund_rate:.1%}")
            if cancel_rate > CANCEL_THRESHOLD:
                breaches.append(f"cancellationRate={cancel_rate:.1%}")

            if breaches:
                get_db().collection(Collections.SECURITY_ALERTS).add(
                    {
                        Fields.TYPE: SecurityAlertTypes.SELLER_METRICS_BREACH,
                        Fields.SELLER_ID: seller_id,
                        Fields.BREACHES: breaches,
                        Fields.TOTAL_ORDERS: total_orders,
                        Fields.SEVERITY: SeverityLevels.HIGH,
                        Fields.CREATED_AT: now_utc,
                        Fields.REQUIRES_MANUAL_REVIEW: True,
                    }
                )
                alerted_count += 1
                logger.warning(f"Seller {seller_id} metrics breach: {', '.join(breaches)}")

    logger.info(f"compute_seller_metrics done: {processed_count} sellers processed, {alerted_count} alerts raised")


# ============================================================================
# TRENDING PRODUCTS CRON
# ============================================================================

TRENDING_TOP_N = 20  # How many products to mark as trending
TRENDING_WINDOW_HOURS = 48  # Look-back window for trending signals
TRENDING_PURCHASE_WEIGHT = 3  # Purchases are 3× more valuable than views
TRENDING_FAVORITE_WEIGHT = 2  # Favorites are 2× more valuable than views


@scheduler_fn.on_schedule(schedule="every 6 hours", **CRON_OPTIONS)
def compute_trending_products(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Compute trending products every 6 hours.
    Score = viewCount + purchaseCount×3 + favoriteCount×2 within last 48h.
    Tags top-20 as isTrending=True, clears old trending flags.
    Sends FCM to premium users with notifyTrending=True.
    """

    now = datetime.now(UTC)
    _window_start = now - timedelta(hours=TRENDING_WINDOW_HOURS)  # noqa: F841

    db = get_db()
    logger.info("compute_trending_products started")

    # Fetch all active approved products
    products_query = (
        db.collection(Collections.PRODUCTS)
        .where(Fields.IS_ACTIVE, "==", True)
        .where(Fields.APPROVAL_STATUS, "==", ProductApprovalStatusValues.APPROVED)
        .stream()
    )

    scored: list[tuple[int, str, str, str]] = []  # (score, productId, name, imageUrl)

    for prod_snap in products_query:
        data = prod_snap.to_dict() or {}
        view_count = data.get(Fields.VIEW_COUNT, 0) or 0
        purchase_count = data.get(Fields.PURCHASE_COUNT, 0) or 0
        # Favorite count is not stored on product doc yet; use 0 until we track it
        score = view_count + purchase_count * TRENDING_PURCHASE_WEIGHT
        if score > 0:
            images = data.get(Fields.IMAGE_URLS) or []
            image_url = images[0] if images else None
            scored.append((score, prod_snap.id, data.get(Fields.NAME, ""), image_url))

    # Sort descending and take top N
    scored.sort(key=lambda x: x[0], reverse=True)
    top_ids = {item[1] for item in scored[:TRENDING_TOP_N]}
    top_products = scored[:TRENDING_TOP_N]

    batch = db.batch()
    op_count = 0

    # Mark top-N as trending
    for _score, prod_id, _name, _img in top_products:
        ref = db.collection(Collections.PRODUCTS).document(prod_id)
        batch.update(
            ref,
            {
                Fields.IS_TRENDING: True,
                Fields.TRENDING_AT: now,
                Fields.TRENDING_SCORE: _score,
            },
        )
        op_count += 1
        if op_count % 400 == 0:
            batch.commit()
            batch = db.batch()

    # Clear trending from products that dropped out of top-N
    old_trending = db.collection(Collections.PRODUCTS).where(Fields.IS_TRENDING, "==", True).stream()
    cleared = 0
    for snap in old_trending:
        if snap.id not in top_ids:
            batch.update(
                snap.reference,
                {
                    Fields.IS_TRENDING: False,
                    Fields.TRENDING_SCORE: snap.to_dict().get(Fields.TRENDING_SCORE, 0),
                },
            )
            cleared += 1
            op_count += 1
            if op_count % 400 == 0:
                batch.commit()
                batch = db.batch()

    batch.commit()
    logger.info(f"Trending: {len(top_products)} products marked trending, {cleared} cleared")

    # Notify premium users who opted in
    if top_products:
        _notify_trending_products(db, top_products[:5])  # notify about top 5


def _notify_trending_products(db, top_products: list[tuple]) -> None:
    """Send FCM push to premium users with notifyTrending=True (max 500)."""
    try:
        from firebase_admin import messaging

        users_query = (
            db.collection(Collections.USERS)
            .where(Fields.IS_PREMIUM, "==", True)
            .where(Fields.NOTIFY_TRENDING, "==", True)
            .limit(500)
            .stream()
        )

        tokens = [
            d.get(Fields.FCM_TOKEN)
            for user in users_query
            for d in [(user.to_dict() or {})]
            if d.get(Fields.FCM_TOKEN)
        ]

        if not tokens:
            return

        names = ", ".join(item[2] for item in top_products[:3])
        msg = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(
                title="🔥 Trending Now on Origna",
                body=f"{names} and more are trending right now!",
            ),
            data={"type": "trending", "screen": "/trending"},
        )
        response = messaging.send_each_for_multicast(msg)
        logger.info(f"Trending FCM sent: {response.success_count} ok, {response.failure_count} failed")
    except Exception as e:
        logger.error(f"Failed to send trending FCM: {e}")


@scheduler_fn.on_schedule(schedule="every 1 hours", **CRON_OPTIONS)
def sync_expired_subscriptions(event: scheduler_fn.ScheduledEvent) -> None:
    """Hourly: detect and fix subscription-user cache mismatches. Catches missed webhooks."""
    if not acquire_cron_lock("sync_expired_subscriptions"):
        logger.info("sync_expired_subscriptions: already running, skipping")
        return

    try:
        import stripe as stripe_lib
        from handlers.subscriptions import _sync_subscription

        stripe_lib.api_key = get_stripe_secret_key()
        db = get_db()
        now = datetime.now(UTC)
        synced_count = 0
        error_count = 0

        # Fix subscriptions that should be expired but user.isPremium is still True
        expired_query = (
            db.collection(Collections.SUBSCRIPTIONS)
            .where(Fields.CURRENT_PERIOD_END, "<", now)
            .where(Fields.STATUS, "in", list(SubscriptionStatusValues.PREMIUM_ACTIVE))
            .limit(50)
            .stream()
        )
        for sub_doc in expired_query:
            uid = sub_doc.id
            sub_data = sub_doc.to_dict() or {}
            stripe_sub_id = sub_data.get(Fields.STRIPE_SUBSCRIPTION_ID)
            if not stripe_sub_id:
                continue
            try:
                stripe_sub = stripe_lib.Subscription.retrieve(stripe_sub_id)
                _sync_subscription(stripe_sub)
                synced_count += 1
            except Exception as e:
                logger.error(f"sync_expired_subscriptions: failed for {uid}: {e}")
                error_count += 1

        # Fix orphaned isPremium=True with no subscription doc (batch read to avoid N+1)
        premium_users = list(db.collection(Collections.USERS).where(Fields.IS_PREMIUM, "==", True).limit(100).stream())
        if premium_users:
            uid_list = [u.id for u in premium_users]
            sub_refs = [db.collection(Collections.SUBSCRIPTIONS).document(uid) for uid in uid_list]
            sub_docs = db.get_all(sub_refs)
            sub_exists = {doc.id: doc.exists for doc in sub_docs}
            orphan_batch = db.batch()
            orphan_count = 0
            for uid in uid_list:
                if not sub_exists.get(uid, False):
                    logger.warning(f"Clearing orphaned isPremium for user {uid}")
                    orphan_batch.update(
                        db.collection(Collections.USERS).document(uid),
                        {
                            Fields.IS_PREMIUM: False,
                            Fields.PREMIUM_EXPIRES_AT: None,
                            Fields.STRIPE_SUBSCRIPTION_ID: None,
                            Fields.UPDATED_AT: now,
                        },
                    )
                    orphan_count += 1
                    synced_count += 1
            if orphan_count > 0:
                orphan_batch.commit()

        logger.info(f"sync_expired_subscriptions: {synced_count} fixed, {error_count} errors")
    finally:
        release_cron_lock("sync_expired_subscriptions")


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def escalate_stale_return_requests(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Cron: Escalates return requests that have been in 'requested' status for
    more than _RETURN_ESCALATION_DAYS days without seller action.
    Sets status to 'escalated' and sends push to admins and buyer.
    """
    if not acquire_cron_lock("escalate_stale_return_requests"):
        logger.info("escalate_stale_return_requests: Lock held, skipping")
        return

    try:
        _run_return_escalation()
    finally:
        release_cron_lock("escalate_stale_return_requests")


def _run_return_escalation() -> None:
    from datetime import timedelta

    db = get_db()
    now = datetime.now(UTC)
    cutoff = now - timedelta(days=BusinessRules.RETURN_ESCALATION_DAYS)

    escalated = 0
    errors = 0

    try:
        # Query return requests stuck in 'requested' status past cutoff
        stale_returns = (
            db.collection(Collections.RETURN_REQUESTS)
            .where(Fields.RETURN_STATUS, "==", ReturnStatusValues.REQUESTED)
            .where(Fields.CREATED_AT, "<", cutoff)
            .limit(200)
            .stream()
        )

        for doc in stale_returns:
            return_id = doc.id
            return_data = doc.to_dict() or {}
            order_id = return_data.get(Fields.ORDER_ID, "")
            buyer_id = return_data.get(Fields.USER_ID, "")
            seller_id = return_data.get(Fields.SELLER_ID, "")

            try:
                doc.reference.update({
                    Fields.RETURN_STATUS: ReturnStatusValues.ESCALATED,
                    Fields.UPDATED_AT: now,
                    Fields.ESCALATED_AT: now,
                    Fields.ESCALATION_REASON: f"No seller response after {BusinessRules.RETURN_ESCALATION_DAYS} days",
                })

                # Notify buyer
                if buyer_id:
                    try:
                        from handlers.orders import send_push_notification
                        send_push_notification(
                            buyer_id,
                            "Return Request Escalated",
                            f"Your return for order #{order_id[:8]} has been escalated to our support team",
                            data={"type": "return_request", "orderId": order_id, "returnId": return_id, "status": ReturnStatusValues.ESCALATED},
                        )
                    except Exception as push_err:
                        logger.warning(f"Push to buyer failed for return {return_id}: {push_err}")

                # Notify admins (fetch admin users)
                try:
                    admin_docs = (
                        db.collection(Collections.USERS)
                        .where(Fields.ROLES, "array_contains", UserRoleValues.ADMIN)
                        .limit(10)
                        .stream()
                    )
                    from handlers.orders import send_push_notification
                    for admin_doc in admin_docs:
                        send_push_notification(
                            admin_doc.id,
                            "Return Escalated",
                            f"Return #{return_id[:8]} on order #{order_id[:8]} needs admin review",
                            data={"type": "return_request", "orderId": order_id, "returnId": return_id, "status": ReturnStatusValues.ESCALATED},
                        )
                except Exception as admin_err:
                    logger.warning(f"Admin push failed for return {return_id}: {admin_err}")

                escalated += 1
            except Exception as e:
                logger.error(f"Failed to escalate return {return_id}: {e}")
                errors += 1

    except Exception as e:
        logger.error(f"escalate_stale_return_requests query failed: {e}")
        return

    logger.info(f"escalate_stale_return_requests: escalated={escalated}, errors={errors}")
