"""
Stripe Payment Handlers
- Checkout session creation
- Payment intent capture
- Webhook processing
- Connect account management
"""

from firebase_functions import https_fn, options
import stripe
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

from config import (
    OrderStatus, PaymentStatus, Collections, PLATFORM_FEE_PERCENT,
    STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, AUTO_CONFIRM_DAYS,
    AUTHORIZATION_VALID_DAYS
)
from email_service import send_email, get_order_confirmation_email, get_seller_notification_email
from utils import (
    create_success_response, create_error_response, validate_item,
    validate_order_data, log_webhook_to_database, is_valid_order_status_transition
)
from rate_limiter import RateLimiter
from shipping_service import calculate_shipping_cost, get_tax_rate

stripe.api_key = STRIPE_SECRET_KEY
_db = None
_rate_limiter = None
_firestore = None

def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs
        _firestore = fs
        _db = fs.client()
    return _db

def get_rate_limiter():
    """Get RateLimiter instance (lazy initialization)."""
    global _rate_limiter
    if _rate_limiter is None:
        _rate_limiter = RateLimiter(get_db())
    return _rate_limiter

def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs
    return _firestore.SERVER_TIMESTAMP

def get_transactional():
    """Get Firestore transactional decorator (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs
    return _firestore.transactional

cors_config = options.CorsOptions(
    cors_origins="*",
    cors_methods=["get", "post", "options"],
)


def _assert_seller_active(seller_id: str, require_approval: bool = True) -> Dict[str, Any]:
    """
    Validates that a seller exists and is active (not suspended).
    
    Args:
        seller_id: The Firebase Auth UID of the seller
        require_approval: If True, also checks Stripe onboarding completion
    
    Returns:
        Dict containing seller data
    
    Raises:
        https_fn.HttpsError: If seller is suspended or not properly onboarded
    """
    seller_ref = get_db().collection(Collections.USERS.value).document(seller_id)
    seller_doc = seller_ref.get()
    
    if not seller_doc.exists:
        raise https_fn.HttpsError(
            'not-found',
            f'Seller {seller_id} not found'
        )
    
    seller_data = seller_doc.to_dict()
    
    if seller_data.get('suspended', False):
        raise https_fn.HttpsError(
            'permission-denied',
            f'Seller {seller_id} is suspended and cannot process orders'
        )
    
    if require_approval:
        if not seller_data.get('onboardingCompleted', False):
            raise https_fn.HttpsError(
                'failed-precondition',
                f'Seller {seller_id} has not completed onboarding'
            )
        
        if not seller_data.get('chargesEnabled', False):
            raise https_fn.HttpsError(
                'failed-precondition',
                f'Seller {seller_id} is not approved to receive payments'
            )
    
    return seller_data


@https_fn.on_call(cors=cors_config)
def create_checkout_session(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Creates a Stripe Checkout session with server-side validation.
    
    Security features:
    - Price validation (server-side fetch from Firestore)
    - Stock availability check (atomic transactions)
    - Rate limiting (5 requests per minute per user)
    - Subtotal verification (1% tolerance)
    - Shipping/tax recalculation
    
    Request data:
        items: List of {productId, quantity, price, name, imageUrl, sellerId}
        shippingAddress: {street, city, province, postalCode, country}
        userId: Firebase Auth UID
    
    Returns:
        {
            sessionId: Stripe Checkout Session ID
            orderId: Firestore order document ID
            success: True
        }
    
    Raises:
        https_fn.HttpsError: For validation errors, insufficient stock, etc.
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data
    
    # Rate limiting: 5 requests per minute per user
    allowed, message = get_rate_limiter().check_rate_limit(
        identifier=user_id,
        action='create_checkout',
        max_requests=5,
        window_minutes=1,
        fail_closed=True
    )
    
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', message)
    
    # Validate required fields
    items = data.get('items', [])
    shipping_address = data.get('shippingAddress', {})
    client_subtotal = data.get('subtotal', 0)
    
    if not items or len(items) == 0:
        raise https_fn.HttpsError('invalid-argument', 'No items in cart')
    
    if not shipping_address:
        raise https_fn.HttpsError('invalid-argument', 'Shipping address required')
    
    # Validate subtotal is positive number
    if not isinstance(client_subtotal, (int, float)) or client_subtotal <= 0:
        raise https_fn.HttpsError('invalid-argument', 'Invalid subtotal: must be positive number')
    
    # Validate subtotal is reasonable (max $100,000 CAD per order)
    if client_subtotal > 100000:
        raise https_fn.HttpsError('invalid-argument', 'Subtotal exceeds maximum allowed ($100,000 CAD)')
    
    # Validate and calculate actual prices/shipping server-side
    validated_items = []
    actual_subtotal = 0
    sellers = set()
    
    for item in items:
        # Fetch product from Firestore for server-side validation
        product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
        product_doc = product_ref.get()
        
        if not product_doc.exists:
            raise https_fn.HttpsError(
                'not-found',
                f"Product {item['productId']} not found"
            )
        
        product_data = product_doc.to_dict()
        
        # Server-side price validation (prevent client tampering)
        db_price = product_data['price']
        client_price = item['price']
        
        # Allow 1 cent tolerance for floating point errors
        if abs(db_price - client_price) > 0.01:
            raise https_fn.HttpsError(
                'invalid-argument',
                f"Price mismatch for {item['productId']}: expected ${db_price}, got ${client_price}"
            )
        
        # Check stock availability
        stock_quantity = product_data.get('stockQuantity', 0)
        if stock_quantity < item['quantity']:
            raise https_fn.HttpsError(
                'resource-exhausted',
                f"Insufficient stock for {item['name']}: {stock_quantity} available, {item['quantity']} requested"
            )
        
        # Check seller status
        seller_id = item['sellerId']
        _assert_seller_active(seller_id, require_approval=True)
        sellers.add(seller_id)
        
        validated_item = {
            'productId': item['productId'],
            'name': product_data['name'],
            'price': db_price,
            'quantity': item['quantity'],
            'sellerId': seller_id,
            'imageUrl': product_data.get('imageUrls', [''])[0],
            'isDigital': product_data.get('isDigital', False)
        }
        validated_items.append(validated_item)
        actual_subtotal += db_price * item['quantity']
    
    # Verify subtotal (allow 1% tolerance for rounding)
    subtotal_diff = abs(actual_subtotal - client_subtotal)
    if subtotal_diff > (actual_subtotal * 0.01):
        raise https_fn.HttpsError(
            'invalid-argument',
            f'Subtotal mismatch: expected ${actual_subtotal}, got ${client_subtotal}'
        )
    
    # Calculate shipping (server-side)
    try:
        shipping_cost = calculate_shipping_cost(validated_items, shipping_address)
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Shipping calculation failed: {str(e)}')
    
    # Calculate taxes (server-side)
    province = shipping_address.get('province', 'ON')
    tax_rate = get_tax_rate(province)
    tax_amount = int(actual_subtotal * tax_rate)
    
    total_amount = int(actual_subtotal + shipping_cost + tax_amount)
    
    # Reserve stock atomically using Firestore transactions
    @get_transactional()
    def reserve_stock_transaction(transaction):
        for item in validated_items:
            product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
            product_snapshot = product_ref.get(transaction=transaction)
            
            if not product_snapshot.exists:
                raise https_fn.HttpsError('not-found', f"Product {item['productId']} not found")
            
            product_data = product_snapshot.to_dict()
            current_stock = product_data.get('stockQuantity', 0)
            
            if current_stock < item['quantity']:
                raise https_fn.HttpsError(
                    'resource-exhausted',
                    f"Stock changed: {product_data['name']} now has {current_stock} available"
                )
            
            transaction.update(product_ref, {
                'stockQuantity': current_stock - item['quantity']
            })
    
    transaction = get_db().transaction()
    try:
        reserve_stock_transaction(transaction)
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Stock reservation failed: {str(e)}')
    
    # Create order in Firestore
    order_ref = get_db().collection(Collections.ORDERS.value).document()
    order_data = {
        'userId': user_id,
        'items': validated_items,
        'subtotal': int(actual_subtotal),
        'shippingCost': shipping_cost,
        'taxAmount': tax_amount,
        'totalAmount': total_amount,
        'orderStatus': OrderStatus.PENDING.value,
        'paymentStatus': PaymentStatus.PENDING.value,
        'shippingAddress': shipping_address,
        'dateCreated': get_server_timestamp(),
        'captureAttempts': 0,
        'expiresAt': datetime.now() + timedelta(days=AUTHORIZATION_VALID_DAYS)
    }
    
    order_ref.set(order_data)
    order_id = order_ref.id
    
    # Create Stripe Checkout Session
    try:
        line_items = []
        for item in validated_items:
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': {
                        'name': item['name'],
                        'images': [item['imageUrl']] if item['imageUrl'] else []
                    },
                    'unit_amount': int(item['price'] * 100)  # Convert to cents
                },
                'quantity': item['quantity']
            })
        
        # Add shipping as line item
        if shipping_cost > 0:
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': {
                        'name': 'Shipping'
                    },
                    'unit_amount': int(shipping_cost * 100)
                },
                'quantity': 1
            })
        
        # Add tax as line item
        if tax_amount > 0:
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': {
                        'name': f'Tax ({province})'
                    },
                    'unit_amount': int(tax_amount * 100)
                },
                'quantity': 1
            })
        
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=line_items,
            mode='payment',
            success_url=f'https://origna.ca/order-success?session_id={{CHECKOUT_SESSION_ID}}',
            cancel_url='https://origna.ca/cart',
            client_reference_id=user_id,
            metadata={
                'orderId': order_id,
                'userId': user_id
            },
            payment_intent_data={
                'capture_method': 'manual',  # Manual capture for order confirmation flow
                'metadata': {
                    'orderId': order_id
                }
            }
        )
        
        # Update order with session ID
        order_ref.update({
            'stripeSessionId': session.id,
            'stripePaymentIntentId': session.payment_intent if hasattr(session, 'payment_intent') else None
        })
        
        return create_success_response({
            'sessionId': session.id,
            'orderId': order_id,
            'checkoutUrl': session.url
        })
        
    except stripe.error.StripeError as e:
        # Rollback stock reservation
        @get_transactional()
        def rollback_stock(transaction):
            for item in validated_items:
                product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
                product_snapshot = product_ref.get(transaction=transaction)
                if product_snapshot.exists:
                    product_data = product_snapshot.to_dict()
                    current_stock = product_data.get('stockQuantity', 0)
                    transaction.update(product_ref, {
                        'stockQuantity': current_stock + item['quantity']
                    })
        
        transaction = get_db().transaction()
        rollback_stock(transaction)
        
        # Delete order
        order_ref.delete()
        
        raise https_fn.HttpsError('internal', f'Stripe error: {str(e)}')


@https_fn.on_request(timeout_sec=60)
def stripe_webhook(req: https_fn.Request) -> https_fn.Response:
    """
    Handles Stripe webhook events with strict security:
    1. Rate limiting by IP (FIRST)
    2. Signature verification (BEFORE processing)
    3. Idempotency check
    4. Event processing
    5. Sanitized error logging
    
    Supported events:
    - checkout.session.completed: Payment authorized
    - checkout.session.async_payment_succeeded: Async payment completed
    - checkout.session.async_payment_failed: Async payment failed
    - checkout.session.expired: Session expired
    - payment_intent.succeeded: Payment succeeded
    - payment_intent.payment_failed: Payment failed
    - charge.refunded: Refund issued
    - charge.dispute.created: Dispute opened
    - charge.dispute.closed: Dispute resolved
    - transfer.reversed: Payout reversed
    - payout.failed: Payout failed
    - refund.failed: Refund failed
    
    Security:
    - Rate limiting by IP (DDoS protection)
    - Signature verification (HMAC with timing-safe comparison)
    - Idempotency (Firestore webhook_events collection)
    - Sanitized error logging
    
    Returns:
        200 OK: Event processed successfully
        400 Bad Request: Invalid signature/payload
        429 Too Many Requests: Rate limit exceeded
        500 Internal Error: Processing failed
    """
    # SECURITY FIX #1: Rate limiting by IP FIRST (prevent DDoS)
    client_ip = req.headers.get('X-Forwarded-For', req.headers.get('X-Real-IP', 'unknown')).split(',')[0].strip()
    
    allowed, message = get_rate_limiter().check_rate_limit(
        identifier=f"ip_{client_ip}",
        action='stripe_webhook',
        max_requests=100,  # 100 webhooks per minute per IP
        window_minutes=1,
        fail_closed=True  # Block on error for security
    )
    
    if not allowed:
        print(f'⚠️ Stripe webhook rate limit exceeded for IP: {client_ip[:10]}...')  # Sanitized log
        return https_fn.Response('Rate limit exceeded', status=429)
    
    # SECURITY FIX #2: Get payload and signature
    payload = req.data
    sig_header = req.headers.get('Stripe-Signature')
    
    if not sig_header:
        print(f'⚠️ Stripe webhook missing signature from IP: {client_ip[:10]}...')
        return https_fn.Response('Missing signature', status=400)
    
    try:
        # SECURITY FIX #3: Verify webhook signature (HMAC with timing-safe comparison)
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError as e:
        print(f'⚠️ Stripe webhook invalid payload from IP: {client_ip[:10]}...')  # Sanitized
        return https_fn.Response('Invalid payload', status=400)
    except stripe.error.SignatureVerificationError as e:
        print(f'⚠️ Stripe webhook invalid signature from IP: {client_ip[:10]}...')  # Sanitized
        return https_fn.Response('Invalid signature', status=400)
    except Exception as e:
        print(f'⚠️ Stripe webhook verification error: {type(e).__name__}')  # Sanitized (no details)
        return https_fn.Response('Signature verification error', status=500)
    
    event_id = event['id']
    event_type = event['type']
    
    # SECURITY FIX #4: Idempotency check (prevent duplicate processing)
    webhook_ref = get_db().collection('webhook_events').document(event_id)
    webhook_doc = webhook_ref.get()
    
    if webhook_doc.exists:
        print(f'✓ Stripe webhook already processed: {event_type} (event: {event_id[:16]}...)')  # Sanitized
        return https_fn.Response('Event already processed', status=200)
    
    # SECURITY FIX #5: Log webhook event with audit trail
    try:
        order_id = event.get('data', {}).get('object', {}).get('metadata', {}).get('orderId', 'N/A')
        webhook_ref.set({
            'provider': 'stripe',
            'type': event_type,
            'processed': True,
            'timestamp': get_server_timestamp(),
            'client_ip': client_ip,  # Audit trail
            'event_id': event_id,
            'order_id': order_id  # For troubleshooting
        })
    except Exception as e:
        print(f'⚠️ Failed to log webhook: {type(e).__name__}')  # Sanitized (no sensitive data)
        # Continue processing even if logging fails
    
    # Route event to appropriate handler
    try:
        if event_type == 'checkout.session.completed':
            result = process_checkout_session_completed(event['data']['object'])
        elif event_type == 'checkout.session.async_payment_succeeded':
            result = process_async_payment_succeeded(event['data']['object'])
        elif event_type == 'checkout.session.async_payment_failed':
            result = process_async_payment_failed(event['data']['object'])
        elif event_type == 'checkout.session.expired':
            result = process_session_expired(event['data']['object'])
        elif event_type == 'payment_intent.succeeded':
            result = process_payment_intent_succeeded(event['data']['object'])
        elif event_type == 'payment_intent.payment_failed':
            result = process_payment_intent_failed(event['data']['object'])
        elif event_type == 'charge.refunded':
            result = process_charge_refunded(event['data']['object'])
        elif event_type == 'charge.dispute.created':
            result = process_dispute_created(event['data']['object'])
        elif event_type == 'charge.dispute.closed':
            result = process_dispute_closed(event['data']['object'])
        elif event_type == 'transfer.reversed':
            result = process_transfer_reversed(event['data']['object'])
        elif event_type == 'payout.failed':
            process_payout_failed(event['data']['object'])
            result = None
        elif event_type == 'refund.failed':
            process_refund_failed(event['data']['object'])
            result = None
        else:
            print(f'ℹ️ Unhandled Stripe event type: {event_type}')
            result = None
        
        print(f'✓ Stripe webhook processed successfully: {event_type}')
        return https_fn.Response('Success', status=200)
        
    except Exception as e:
        # SECURITY FIX #6: Sanitized error logging (no sensitive data exposure)
        error_type = type(e).__name__
        print(f'❌ Error processing Stripe webhook: {error_type} for event_type: {event_type}')
        # Don't expose internal error details to webhook caller
        return https_fn.Response('Internal processing error', status=500)


def process_checkout_session_completed(session: Dict) -> Optional[str]:
    """
    Processes checkout.session.completed event.
    Updates order status to confirmed and sends confirmation emails.
    """
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        print('No orderId in session metadata')
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        print(f'Order {order_id} not found')
        return None
    
    order_data = order_doc.to_dict()
    
    # Update order status
    order_ref.update({
        'orderStatus': OrderStatus.CONFIRMED.value,
        'paymentStatus': PaymentStatus.AUTHORIZED.value,
        'stripePaymentIntentId': session.get('payment_intent'),
        'updatedAt': get_server_timestamp()
    })
    
    # Send confirmation emails
    try:
        # Email to buyer
        buyer_email_html = get_order_confirmation_email(order_id, order_data)
        send_email(
            to_email=order_data.get('userId'),  # Will be resolved to email
            subject='Order Confirmation - Origna',
            html_content=buyer_email_html
        )
        
        # Email to sellers
        sellers = set(item['sellerId'] for item in order_data['items'])
        for seller_id in sellers:
            seller_email_html = get_seller_notification_email(order_id, order_data, seller_id)
            send_email(
                to_email=seller_id,  # Will be resolved to email
                subject='New Order Received - Origna',
                html_content=seller_email_html
            )
    except Exception as e:
        print(f'Failed to send confirmation emails: {str(e)}')
    
    # Clear user's cart
    try:
        _clear_user_cart(order_data['userId'])
    except Exception as e:
        print(f'Failed to clear cart: {str(e)}')
    
    return f'Order {order_id} confirmed'


def _clear_user_cart(user_id: str) -> None:
    """Deletes all items from user's cart subcollection"""
    cart_ref = get_db().collection(Collections.USERS.value).document(user_id).collection('cart')
    cart_docs = cart_ref.stream()
    
    for doc in cart_docs:
        doc.reference.delete()


def process_async_payment_succeeded(session: Dict) -> Optional[str]:
    """Handles async payment success (e.g., bank transfers)"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.CAPTURED.value,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Order {order_id} payment captured'


def process_async_payment_failed(session: Dict) -> Optional[str]:
    """Handles async payment failure"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if order_doc.exists:
        order_data = order_doc.to_dict()
        
        # Restore stock
        _restore_stock_for_order(order_data)
        
        # Update order
        order_ref.update({
            'orderStatus': OrderStatus.CANCELLED.value,
            'paymentStatus': PaymentStatus.FAILED.value,
            'updatedAt': get_server_timestamp()
        })
    
    return f'Order {order_id} cancelled due to payment failure'


def _restore_stock_for_order(order_data: Dict) -> None:
    """Restores product stock after order cancellation"""
    for item in order_data.get('items', []):
        product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
        product_doc = product_ref.get()
        
        if product_doc.exists:
            product_data = product_doc.to_dict()
            current_stock = product_data.get('stockQuantity', 0)
            product_ref.update({
                'stockQuantity': current_stock + item['quantity']
            })


def process_session_expired(session: Dict) -> Optional[str]:
    """Handles expired checkout sessions"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if order_doc.exists:
        order_data = order_doc.to_dict()
        _restore_stock_for_order(order_data)
        
        order_ref.update({
            'orderStatus': OrderStatus.EXPIRED.value,
            'updatedAt': get_server_timestamp()
        })
    
    return f'Order {order_id} expired'


def process_payment_intent_succeeded(payment_intent: Dict) -> Optional[str]:
    """Handles successful payment intents"""
    order_id = payment_intent.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.CAPTURED.value,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Payment captured for order {order_id}'


def process_payment_intent_failed(payment_intent: Dict) -> Optional[str]:
    """Handles failed payment intents"""
    order_id = payment_intent.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.FAILED.value,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Payment failed for order {order_id}'


def process_charge_refunded(charge: Dict) -> Optional[str]:
    """Handles charge refunds"""
    payment_intent_id = charge.get('payment_intent')
    
    if not payment_intent_id:
        return None
    
    # Find order by payment intent
    orders = get_db().collection(Collections.ORDERS.value)\
        .where('stripePaymentIntentId', '==', payment_intent_id)\
        .limit(1)\
        .stream()
    
    for order_doc in orders:
        order_ref = order_doc.reference
        order_ref.update({
            'orderStatus': OrderStatus.REFUNDED.value,
            'paymentStatus': PaymentStatus.REFUNDED.value,
            'updatedAt': get_server_timestamp()
        })
        
        return f'Order {order_doc.id} refunded'
    
    return None


def process_dispute_created(dispute: Dict) -> Optional[str]:
    """Handles dispute creation"""
    charge_id = dispute.get('charge')
    
    # Log security alert
    get_db().collection('security_alerts').add({
        'type': 'dispute_created',
        'severity': 'high',
        'chargeId': charge_id,
        'amount': dispute.get('amount'),
        'reason': dispute.get('reason'),
        'timestamp': get_server_timestamp(),
        'resolved': False
    })
    
    return f'Dispute logged for charge {charge_id}'


def process_dispute_closed(dispute: Dict) -> Optional[str]:
    """Handles dispute resolution"""
    charge_id = dispute.get('charge')
    status = dispute.get('status')
    
    # Update security alert
    alerts = get_db().collection('security_alerts')\
        .where('chargeId', '==', charge_id)\
        .where('type', '==', 'dispute_created')\
        .limit(1)\
        .stream()
    
    for alert_doc in alerts:
        alert_doc.reference.update({
            'resolved': True,
            'resolution': status,
            'resolvedAt': get_server_timestamp()
        })
    
    return f'Dispute closed: {status}'


def process_transfer_reversed(transfer: Dict) -> Optional[str]:
    """Handles reversed payouts"""
    transfer_id = transfer.get('id')
    
    # Find payout by transfer ID
    payouts = get_db().collection(Collections.PAYOUTS.value)\
        .where('stripeTransferId', '==', transfer_id)\
        .limit(1)\
        .stream()
    
    for payout_doc in payouts:
        payout_doc.reference.update({
            'status': 'reversed',
            'updatedAt': get_server_timestamp()
        })
        
        return f'Payout {payout_doc.id} reversed'
    
    return None


def process_payout_failed(payout: Dict) -> None:
    """Handles failed payouts"""
    destination = payout.get('destination')
    
    get_db().collection('security_alerts').add({
        'type': 'payout_failed',
        'severity': 'high',
        'destination': destination,
        'amount': payout.get('amount'),
        'failureMessage': payout.get('failure_message'),
        'timestamp': get_server_timestamp(),
        'resolved': False
    })


def process_refund_failed(refund: Dict) -> None:
    """Handles failed refunds"""
    charge_id = refund.get('charge')
    
    get_db().collection('security_alerts').add({
        'type': 'refund_failed',
        'severity': 'critical',
        'chargeId': charge_id,
        'amount': refund.get('amount'),
        'failureReason': refund.get('failure_reason'),
        'timestamp': get_server_timestamp(),
        'resolved': False
    })


@https_fn.on_call()
def create_connect_account(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Creates Stripe Connect account for seller onboarding"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data
    
    # Import validation functions
    from utils import sanitize_email
    
    email_raw = data.get('email')
    country = data.get('country', 'CA')
    
    if not email_raw:
        raise https_fn.HttpsError('invalid-argument', 'Email required')
    
    # Validate and sanitize email
    try:
        email = sanitize_email(email_raw)
    except ValueError as e:
        raise https_fn.HttpsError('invalid-argument', str(e))
    
    # Validate country code (ISO 3166-1 alpha-2)
    valid_countries = ['CA', 'US', 'GB', 'FR', 'DE', 'IT', 'ES', 'NL', 'BE', 'CH', 'AT', 'SE', 'NO', 'DK', 'FI', 'IE', 'PT', 'PL', 'CZ', 'HU', 'RO', 'BG', 'GR', 'HR', 'SI', 'SK', 'LT', 'LV', 'EE', 'LU', 'MT', 'CY']
    if country not in valid_countries:
        raise https_fn.HttpsError('invalid-argument', f'Invalid country code: {country}')
    
    try:
        account = stripe.Account.create(
            type='express',
            country=country,
            email=email,
            capabilities={
                'card_payments': {'requested': True},
                'transfers': {'requested': True}
            },
            business_type='individual',
            metadata={'userId': user_id}
        )
        
        # Save account ID to Firestore
        user_ref = get_db().collection(Collections.USERS.value).document(user_id)
        user_ref.update({
            'stripeAccountId': account.id,
            'updatedAt': get_server_timestamp()
        })
        
        return create_success_response({'accountId': account.id})
        
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', str(e))


@https_fn.on_call()
def create_account_link(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Creates Stripe Connect onboarding link"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    
    user_ref = get_db().collection(Collections.USERS.value).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    account_id = user_data.get('stripeAccountId')
    
    if not account_id:
        raise https_fn.HttpsError('failed-precondition', 'No Stripe account found')
    
    try:
        account_link = stripe.AccountLink.create(
            account=account_id,
            refresh_url='https://origna.ca/seller/onboarding',
            return_url='https://origna.ca/seller/dashboard',
            type='account_onboarding'
        )
        
        return create_success_response({'url': account_link.url})
        
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', str(e))


@https_fn.on_call()
def get_connect_account_status(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Gets Stripe Connect account status"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    
    user_ref = get_db().collection(Collections.USERS.value).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    account_id = user_data.get('stripeAccountId')
    
    if not account_id:
        raise https_fn.HttpsError('failed-precondition', 'No Stripe account found')
    
    try:
        account = stripe.Account.retrieve(account_id)
        
        # Update Firestore with latest status
        user_ref.update({
            'chargesEnabled': account.charges_enabled,
            'payoutsEnabled': account.payouts_enabled,
            'onboardingCompleted': account.details_submitted,
            'updatedAt': get_server_timestamp()
        })
        
        return create_success_response({
            'chargesEnabled': account.charges_enabled,
            'payoutsEnabled': account.payouts_enabled,
            'detailsSubmitted': account.details_submitted,
            'requirementsCurrentlyDue': account.requirements.currently_due
        })
        
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', str(e))


@https_fn.on_call()
def capture_payment(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Manually captures authorized payment and initiates seller payouts.
    Called when buyer confirms order receipt.
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    order_id = req.data.get('orderId')
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    payment_intent_id = order_data.get('stripePaymentIntentId')
    
    if not payment_intent_id:
        raise https_fn.HttpsError('failed-precondition', 'No payment intent found')
    
    try:
        # Capture the payment
        payment_intent = stripe.PaymentIntent.capture(payment_intent_id)
        
        # Update order
        order_ref.update({
            'paymentStatus': PaymentStatus.CAPTURED.value,
            'orderStatus': OrderStatus.DELIVERED.value,
            'updatedAt': get_server_timestamp()
        })
        
        # Create payouts for sellers
        sellers_total = {}
        for item in order_data['items']:
            seller_id = item['sellerId']
            item_total = item['price'] * item['quantity']
            sellers_total[seller_id] = sellers_total.get(seller_id, 0) + item_total
        
        for seller_id, amount in sellers_total.items():
            platform_fee = int(amount * PLATFORM_FEE_PERCENT)
            net_amount = amount - platform_fee
            
            # Get seller's Stripe account
            seller_ref = get_db().collection(Collections.USERS.value).document(seller_id)
            seller_doc = seller_ref.get()
            
            if seller_doc.exists:
                seller_data = seller_doc.to_dict()
                stripe_account_id = seller_data.get('stripeAccountId')
                
                if stripe_account_id:
                    # Create transfer to seller
                    transfer = stripe.Transfer.create(
                        amount=int(net_amount * 100),  # Convert to cents
                        currency='cad',
                        destination=stripe_account_id,
                        metadata={
                            'orderId': order_id,
                            'sellerId': seller_id
                        }
                    )
                    
                    # Log payout
                    get_db().collection(Collections.PAYOUTS.value).add({
                        'orderId': order_id,
                        'sellerId': seller_id,
                        'amount': amount,
                        'platformFee': platform_fee,
                        'netAmount': net_amount,
                        'status': 'completed',
                        'stripeTransferId': transfer.id,
                        'payoutDate': get_server_timestamp(),
                        'createdAt': get_server_timestamp()
                    })
        
        return create_success_response({'captured': True, 'paymentIntentId': payment_intent_id})
        
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', str(e))


# Aliases for backward compatibility and naming conventions
create_stripe_connect_account = create_connect_account
create_stripe_connect_account_link = create_account_link


def sanitize_metadata(metadata: Dict[str, Any]) -> Dict[str, Any]:
    """
    Sanitize metadata fields before storing in Stripe or Firestore.
    Firestore handles NoSQL injection, but we validate inputs for safety.
    
    Args:
        metadata: Dictionary of metadata to sanitize
    
    Returns:
        Sanitized metadata dictionary
    """
    if not isinstance(metadata, dict):
        return {}
    
    # For Firestore NoSQL, metadata is stored as-is, no SQL injection risk
    # But we validate field types to ensure data integrity
    sanitized = {}
    for key, value in metadata.items():
        # Allow strings, numbers, booleans, None
        if isinstance(value, (str, int, float, bool, type(None))):
            sanitized[key] = value
        # Convert other types to strings
        else:
            sanitized[key] = str(value)
    
    return sanitized
