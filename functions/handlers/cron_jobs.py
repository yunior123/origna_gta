"""
Scheduled Cron Jobs
- Auto-capture confirmed receipts (daily)
- Check expired authorizations (daily)
- Monitor Algolia sync (every 15 min)
- Cleanup stale rate limits (every 30 min)
- Archive old orders (every 12 hours)
"""

from firebase_functions import scheduler_fn, options
import stripe
from datetime import datetime, timedelta

from config import (
    OrderStatus, PaymentStatus, Collections,
    AUTO_CONFIRM_DAYS, AUTHORIZATION_VALID_DAYS,
    PLATFORM_FEE_PERCENT, STRIPE_SECRET_KEY
)
from schema_constants import Fields  # Field name constants to prevent typos
from function_options import CRON_OPTIONS

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
    from handlers.payment_providers import is_provider_enabled, PaymentProvider
    if not is_provider_enabled(PaymentProvider.STRIPE):
        print('Stripe payments are disabled, skipping auto-capture')
        return
    
    cutoff_date = datetime.now() - timedelta(days=AUTO_CONFIRM_DAYS)
    
    # Limit to 500 orders per run to handle higher volume
    orders = get_db().collection(Collections.ORDERS)\
        .where('orderStatus', '==', OrderStatus.DELIVERED)\
        .where('paymentStatus', '==', PaymentStatus.AUTHORIZED)\
        .where(Fields.UPDATED_AT, '<=', cutoff_date)\
        .limit(500)\
        .stream()
    
    captured_count = 0
    failed_count = 0
    
    for order_doc in orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id
        payment_intent_id = order_data.get('stripePaymentIntentId')
        
        if not payment_intent_id:
            print(f'Order {order_id} has no payment intent, skipping')
            continue
        
        try:
            # Capture payment
            payment_intent = stripe.PaymentIntent.capture(payment_intent_id)
            
            # Update order
            order_doc.reference.update({
                'paymentStatus': PaymentStatus.CAPTURED,
                'capturedAt': get_server_timestamp(),
                'autoCaptured': True,
                'updatedAt': get_server_timestamp()
            })
            
            # Create payouts ONLY for sellers whose items are delivered
            items = order_data.get('items', [])
            sellers_total_cents = {}
            for item in items:
                # Only include delivered items (or all items if no per-item status tracking)
                item_status = item.get('status', 'pending')
                if item_status in ['delivered', 'pending']:  # 'pending' for backwards compatibility
                    seller_id = item['sellerId']
                    item_price_cents = round(item['price'] * 100)
                    item_total_cents = item_price_cents * item['quantity']
                    sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents
            
            for seller_id, amount_cents in sellers_total_cents.items():
                platform_fee_cents = round(amount_cents * PLATFORM_FEE_PERCENT)
                net_amount_cents = amount_cents - platform_fee_cents
                
                # Get seller's Stripe account
                seller_ref = get_db().collection(Collections.USERS).document(seller_id)
                seller_doc = seller_ref.get()
                
                if seller_doc.exists:
                    seller_data = seller_doc.to_dict()
                    stripe_account_id = seller_data.get('stripeAccountId')
                    
                    if stripe_account_id and seller_data.get('payoutsEnabled', False):
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
                                }
                            )
                            
                            get_db().collection(Collections.PAYOUTS).add({
                                'orderId': order_id,
                                'sellerId': seller_id,
                                'amountCents': amount_cents,
                                'platformFeeCents': platform_fee_cents,
                                'netAmountCents': net_amount_cents,
                                'status': 'completed',
                                'stripeTransferId': transfer.id,
                                'payoutDate': get_server_timestamp(),
                                'autoCaptured': True,
                                'createdAt': get_server_timestamp()
                            })
                            
                        except stripe.error.StripeError as e:
                            print(f'Payout failed for seller {seller_id}: {str(e)}')

                            get_db().collection(Collections.PAYOUTS).add({
                                'orderId': order_id,
                                'sellerId': seller_id,
                                'amountCents': amount_cents,
                                'platformFeeCents': platform_fee_cents,
                                'netAmountCents': net_amount_cents,
                                'status': 'failed',
                                'failureReason': str(e),
                                'autoCaptured': True,
                                'createdAt': get_server_timestamp()
                            })
            
            captured_count += 1
            print(f'Auto-captured order {order_id}')
            
        except stripe.error.StripeError as e:
            failed_count += 1
            print(f'Failed to capture order {order_id}: {str(e)}')
            
            order_doc.reference.update({
                'captureAttempts': order_data.get('captureAttempts', 0) + 1,
                'lastCaptureError': str(e),
                'updatedAt': get_server_timestamp()
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
        .where('paymentStatus', '==', PaymentStatus.AUTHORIZED)\
        .where('orderStatus', 'in', [OrderStatus.PENDING, OrderStatus.CONFIRMED])\
        .where(Fields.CREATED_AT, '<=', cutoff_date)\
        .limit(100)\
        .stream()
    
    expired_count = 0
    
    for order_doc in orders:
        order_data = order_doc.to_dict()
        order_id = order_doc.id
        
        # Skip if stock already restored (idempotency)
        if order_data.get('stockRestored', False):
            print(f'Stock already restored for expired order {order_id}')
        else:
            # CRITICAL FIX: Use atomic Increment instead of read-then-write
            for item in order_data.get('items', []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
                try:
                    product_ref.update({
                        'stockQuantity': get_firestore().Increment(item['quantity'])
                    })
                except Exception as e:
                    print(f'Failed to restore stock for product {item["productId"]}: {str(e)}')
        
        # Update order
        order_doc.reference.update({
            'orderStatus': OrderStatus.EXPIRED,
            'paymentStatus': PaymentStatus.SESSION_EXPIRED,
            'stockRestored': True,
            'expiredAt': get_server_timestamp(),
            'updatedAt': get_server_timestamp()
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
        .where('orderStatus', 'in', [OrderStatus.DELIVERED, OrderStatus.CANCELLED, OrderStatus.REFUNDED])\
        .where('updatedAt', '<=', cutoff_date)\
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
        from google.cloud.firestore_v1.aggregation import CountAggregation
        
        products_query = get_db().collection(Collections.PRODUCTS)\
            .where('isActive', '==', True)
        
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
            get_db().collection('security_alerts').add({
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
    rate_limits = get_db().collection('rate_limits')\
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
