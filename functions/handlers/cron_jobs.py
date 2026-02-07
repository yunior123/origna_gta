"""
Scheduled Cron Jobs
- Auto-capture confirmed receipts (daily)
- Check expired authorizations (daily)
- Monitor Algolia sync (every 15 min)
- Cleanup stale rate limits (every 30 min)
- Archive old orders (every 12 hours)
"""

from datetime import datetime, timedelta

import stripe
from firebase_functions import scheduler_fn

from config import AUTHORIZATION_VALID_DAYS, AUTO_CONFIRM_DAYS, PLATFORM_FEE_PERCENT, STRIPE_SECRET_KEY, Collections
from function_options import CRON_OPTIONS
from schema_constants import DeliveryStatusValues, Fields, OrderStatusValues, PaymentStatusValues, PayoutStatusValues

# Aliases for backward compatibility — canonical source is schema_constants
OrderStatus = OrderStatusValues
PaymentStatus = PaymentStatusValues

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


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def auto_capture_confirmed_receipts(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Auto-captures payments for orders delivered 7+ days ago.

    Runs: Daily at 01:00 UTC

    Logic:
    - Check if Stripe provider is enabled
    - Find orders with status=delivered, paymentStatus=authorized
    - Delivered 7+ days ago
    - Capture payment and initiate payouts
    """
    print('Running auto_capture_confirmed_receipts cron job')

    # Check if Stripe is enabled before processing
    from handlers.payment_providers import PaymentProvider, is_provider_enabled
    if not is_provider_enabled(PaymentProvider.STRIPE):
        print('Stripe payments are disabled, skipping auto-capture')
        return

    cutoff_date = datetime.now() - timedelta(days=AUTO_CONFIRM_DAYS)

    # Query both DELIVERED and SHIPPED orders past cutoff
    # SHIPPED orders auto-complete after AUTO_CONFIRM_DAYS if buyer doesn't confirm
    # FIX S23: Use UPDATED_AT only as initial filter; verify actual delivery/ship
    # timestamps per-order to avoid capturing too early on edited orders.
    all_orders = []
    for target_status in [OrderStatusValues.DELIVERED, OrderStatusValues.SHIPPED]:
        status_orders = get_db().collection(Collections.ORDERS)\
            .where(Fields.ORDER_STATUS, '==', target_status)\
            .where(Fields.PAYMENT_STATUS, '==', PaymentStatus.AUTHORIZED)\
            .where(Fields.UPDATED_AT, '<=', cutoff_date)\
            .limit(250)\
            .stream()
        all_orders.extend(status_orders)

    captured_count = 0
    failed_count = 0

    for order_doc in all_orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id
        payment_intent_id = order_data.get('stripePaymentIntentId')

        if not payment_intent_id:
            print(f'Order {order_id} has no payment intent, skipping')
            continue

        # FIX S23: Verify actual delivery/ship time before capture.
        # updatedAt can be bumped by unrelated edits; use item-level timestamps.
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
            print(f'Order {order_id} item-level timestamp too recent ({latest_event_time}), skipping')
            continue
        if order_data.get(Fields.ORDER_STATUS) == OrderStatusValues.SHIPPED:
            items = order_data.get(Fields.ITEMS, [])
            for item in items:
                if item.get(Fields.STATUS) == DeliveryStatusValues.SHIPPED:
                    item[Fields.STATUS] = DeliveryStatusValues.DELIVERED
                    item[Fields.DELIVERED_AT] = datetime.now().isoformat()
            order_doc.reference.update({
                Fields.ITEMS: items,
                Fields.ORDER_STATUS: OrderStatusValues.DELIVERED,
                Fields.AUTO_CONFIRMED: True,
            })
            order_data[Fields.ORDER_STATUS] = OrderStatusValues.DELIVERED
            print(f'Auto-marked order {order_id} as delivered (was shipped, {AUTO_CONFIRM_DAYS}+ days)')

        try:
            # Capture payment (with idempotency key)
            stripe.PaymentIntent.capture(
                payment_intent_id,
                idempotency_key=f'auto_capture_{order_id}_{payment_intent_id}'
            )

            # Update order
            order_doc.reference.update({
                Fields.PAYMENT_STATUS: PaymentStatus.CAPTURED,
                Fields.CAPTURED_AT: get_server_timestamp(),
                Fields.AUTO_CAPTURED: True,
                Fields.UPDATED_AT: get_server_timestamp()
            })

            # Create payouts ONLY for sellers whose items are DELIVERED
            # SECURITY FIX: Removed PENDING fallback — only pay for confirmed deliveries
            items = order_data.get(Fields.ITEMS, [])
            sellers_total_cents = {}
            for item in items:
                item_status = item.get(Fields.STATUS, OrderStatusValues.PENDING)
                if item_status == OrderStatusValues.DELIVERED:
                    seller_id = item[Fields.SELLER_ID]
                    item_price_cents = round(item[Fields.PRICE] * 100)
                    item_total_cents = item_price_cents * item[Fields.QUANTITY]
                    sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents

            for seller_id, amount_cents in sellers_total_cents.items():
                platform_fee_cents = round(amount_cents * PLATFORM_FEE_PERCENT)
                net_amount_cents = amount_cents - platform_fee_cents

                # Get seller's Stripe account
                seller_ref = get_db().collection(Collections.USERS).document(seller_id)
                seller_doc = seller_ref.get()

                if seller_doc.exists:
                    seller_data = seller_doc.to_dict()
                    stripe_account_id = seller_data.get(Fields.STRIPE_ACCOUNT_ID)

                    if stripe_account_id and seller_data.get(Fields.PAYOUTS_ENABLED, False):
                        try:
                            transfer = stripe.Transfer.create(
                                amount=net_amount_cents,
                                currency='cad',
                                destination=stripe_account_id,
                                source_transaction=payment_intent_id,
                                transfer_group=order_id,
                                metadata={
                                    'orderId': order_id,
                                    'sellerId': seller_id,
                                    'autoCaptured': True
                                },
                                idempotency_key=f'auto_transfer_{order_id}_{seller_id}',
                            )

                            get_db().collection(Collections.PAYOUTS).add({
                                Fields.ORDER_ID: order_id,
                                Fields.SELLER_ID: seller_id,
                                Fields.AMOUNT_CENTS: amount_cents,
                                Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                                Fields.NET_AMOUNT_CENTS: net_amount_cents,
                                Fields.STATUS: PayoutStatusValues.COMPLETED,
                                Fields.STRIPE_TRANSFER_ID: transfer.id,
                                Fields.PAYOUT_DATE: get_server_timestamp(),
                                Fields.AUTO_CAPTURED: True,
                                Fields.CREATED_AT: get_server_timestamp()
                            })

                        except stripe.error.StripeError as e:
                            print(f'Payout failed for seller {seller_id}: {str(e)}')

                            get_db().collection(Collections.PAYOUTS).add({
                                Fields.ORDER_ID: order_id,
                                Fields.SELLER_ID: seller_id,
                                Fields.AMOUNT_CENTS: amount_cents,
                                Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                                Fields.NET_AMOUNT_CENTS: net_amount_cents,
                                Fields.STATUS: PayoutStatusValues.FAILED,
                                Fields.FAILURE_REASON: str(e),
                                Fields.AUTO_CAPTURED: True,
                                Fields.CREATED_AT: get_server_timestamp()
                            })

            captured_count += 1
            print(f'Auto-captured order {order_id}')

        except stripe.error.StripeError as e:
            failed_count += 1
            print(f'Failed to capture order {order_id}: {str(e)}')

            order_doc.reference.update({
                Fields.CAPTURE_ATTEMPTS: order_data.get(Fields.CAPTURE_ATTEMPTS, 0) + 1,
                'lastCaptureError': str(e),
                Fields.UPDATED_AT: get_server_timestamp()
            })

    print(f'Auto-capture completed: {captured_count} captured, {failed_count} failed')


@scheduler_fn.on_schedule(schedule="every 24 hours", **CRON_OPTIONS)
def check_expired_authorizations(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Expires orders with authorizations older than 7 days.

    Runs: Daily at 02:00 UTC

    Logic:
    - Find orders with paymentStatus=authorized
    - Created 7+ days ago
    - Cancel and restore stock
    """
    print('Running check_expired_authorizations cron job')

    cutoff_date = datetime.now() - timedelta(days=AUTHORIZATION_VALID_DAYS)

    # Limit to 100 orders per run to avoid timeout
    # Use Fields.CREATED_AT constant to prevent field name typos (orders use 'createdAt')
    orders = get_db().collection(Collections.ORDERS)\
        .where(Fields.PAYMENT_STATUS, '==', PaymentStatus.AUTHORIZED)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatus.PENDING, OrderStatus.CONFIRMED])\
        .where(Fields.CREATED_AT, '<=', cutoff_date)\
        .limit(100)\
        .stream()

    expired_count = 0

    for order_doc in orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id

        # Skip if stock already restored (idempotency)
        if order_data.get(Fields.STOCK_RESTORED, False):
            print(f'Stock already restored for expired order {order_id}')
        else:
            # CRITICAL FIX: Use atomic Increment instead of read-then-write
            for item in order_data.get(Fields.ITEMS, []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                try:
                    product_ref.update({
                        Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY])
                    })
                except Exception as e:
                    print(f'Failed to restore stock for product {item["productId"]}: {str(e)}')

        # Cancel the PaymentIntent to release buyer funds
        payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
        if payment_intent_id:
            try:
                stripe.PaymentIntent.cancel(
                    payment_intent_id,
                    cancellation_reason='abandoned',
                )
            except stripe.error.StripeError as e:
                print(f'Failed to cancel PI for expired order {order_id}: {str(e)}')

        # Update order
        order_doc.reference.update({
            Fields.ORDER_STATUS: OrderStatus.EXPIRED,
            Fields.PAYMENT_STATUS: PaymentStatus.AUTHORIZATION_EXPIRED,
            Fields.STOCK_RESTORED: True,
            Fields.EXPIRES_AT: get_server_timestamp(),
            Fields.UPDATED_AT: get_server_timestamp()
        })

        expired_count += 1
        print(f'Expired order {order_id}')

    print(f'Authorization check completed: {expired_count} orders expired')


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
    print('Running auto_archive_old_orders cron job')

    cutoff_date = datetime.now() - timedelta(days=30)

    # Limit to 200 orders per run and use batch
    # NOTE: We cannot filter 'archived == False' because Firestore doesn't match
    # documents where the field doesn't exist. Instead, we query without the filter
    # and skip already-archived orders in the loop.
    orders = get_db().collection(Collections.ORDERS)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatus.DELIVERED, OrderStatus.CANCELLED, OrderStatus.REFUNDED])\
        .where(Fields.UPDATED_AT, '<=', cutoff_date)\
        .limit(200)\
        .stream()

    archived_count = 0
    batch = get_db().batch()

    for order_doc in orders:
        # Skip already-archived orders (field may not exist on old orders)
        if order_doc.to_dict().get('archived', False):
            continue

        batch.update(order_doc.reference, {
            'archived': True,
            'archivedAt': get_server_timestamp()
        })
        archived_count += 1

        # Commit every 500 operations
        if archived_count % 500 == 0:
            batch.commit()
            batch = get_db().batch()

    # Commit remaining
    if archived_count % 500 != 0:
        batch.commit()

    print(f'Archive completed: {archived_count} orders archived')


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
    print('Running monitor_algolia_sync cron job')

    try:
        # Count active products in Firestore using count aggregation

        products_query = get_db().collection(Collections.PRODUCTS)\
            .where(Fields.IS_ACTIVE, '==', True)

        # Use count aggregation (more efficient than streaming)
        count_query = products_query.count()
        firestore_count = count_query.get()[0][0].value

        # Count products in Algolia
        from algolia_service import get_index_stats
        algolia_count = get_index_stats()

        # Check for significant mismatch
        if firestore_count == 0:
            print('No products in Firestore')
            return

        mismatch_percent = abs(firestore_count - algolia_count) / firestore_count

        if mismatch_percent > 0.05:  # > 5% mismatch
            get_db().collection(Collections.SECURITY_ALERTS).add({
                'type': 'algolia_sync_issue',
                'severity': 'medium',
                'firestoreCount': firestore_count,
                'algoliaCount': algolia_count,
                'mismatchPercent': mismatch_percent * 100,
                'timestamp': get_server_timestamp(),
                'resolved': False
            })

            print(f'ALERT: Algolia sync mismatch: Firestore={firestore_count}, Algolia={algolia_count}')
        else:
            print(f'Algolia sync healthy: Firestore={firestore_count}, Algolia={algolia_count}')

    except Exception as e:
        print(f'Failed to monitor Algolia sync: {str(e)}')


@scheduler_fn.on_schedule(schedule="every 30 minutes", **CRON_OPTIONS)
def cleanup_stale_rate_limits(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Removes rate limit documents older than 1 hour.

    Runs: Every 30 minutes

    Logic:
    - Find rate_limits with lastRequest > 1 hour ago
    - Delete documents
    """
    print('Running cleanup_stale_rate_limits cron job')

    cutoff_time = datetime.now() - timedelta(hours=1)

    # Limit and batch delete
    rate_limits = get_db().collection(Collections.RATE_LIMITS)\
        .where('lastRequest', '<=', cutoff_time)\
        .limit(500)\
        .stream()

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

    print(f'Rate limit cleanup completed: {deleted_count} documents deleted')


@scheduler_fn.on_schedule(schedule="0 2 * * *", **CRON_OPTIONS)  # Daily at 02:00 UTC
def check_expired_authorizations_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Wrapper for check_expired_authorizations to run at specific time.
    Uses helper function from check_expired_authorizations.py
    """
    print('Running scheduled check_expired_authorizations')

    try:
        from check_expired_authorizations import check_and_expire_orders
        result = check_and_expire_orders()
        print(f'Expired authorizations check completed: {result}')
    except Exception as e:
        print(f'Failed to check expired authorizations: {str(e)}')
