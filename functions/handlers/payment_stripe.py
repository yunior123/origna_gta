"""
Stripe Payment Handlers
- Checkout session creation
- Payment intent capture
- Webhook processing
- Connect account management
"""

from firebase_functions import https_fn, options
import stripe
import os
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
from function_options import DEFAULT_OPTIONS, WEBHOOK_OPTIONS

stripe.api_key = STRIPE_SECRET_KEY
_db = None
_rate_limiter = None
_firestore = None

# Check if running in emulator mode
IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR', 'false').lower() == 'true'

# CORS configuration for production
CORS_CONFIG = options.CorsOptions(
    cors_origins=[
        "https://orignagta.ca",
        "https://www.orignagta.ca",
        "https://orignagta.web.app",
        "https://orignagta.firebaseapp.com",
    ],
    cors_methods=["POST", "OPTIONS"],
)

def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        try:
            from firebase_admin import firestore as fs
            _firestore = fs
            _db = fs.client()
        except Exception as e:
            raise RuntimeError("Failed to initialize Firestore client") from e
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
    seller_ref = get_db().collection(Collections.USERS).document(seller_id)
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


@https_fn.on_call(**DEFAULT_OPTIONS, cors=CORS_CONFIG)
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
    
    # Validate shipping address fields
    required_address_fields = ['street', 'city', 'postalCode', 'province', 'country']
    for field in required_address_fields:
        if field not in shipping_address or not shipping_address[field]:
            raise https_fn.HttpsError('invalid-argument', f'Missing required address field: {field}')
    
    # Validate address field lengths (prevent injection attacks)
    address_length_limits = {
        'street': 100,
        'city': 50,
        'postalCode': 20,
        'province': 50,
        'country': 50
    }
    for field, max_length in address_length_limits.items():
        if len(str(shipping_address.get(field, ''))) > max_length:
            raise https_fn.HttpsError('invalid-argument', f'Address field {field} exceeds maximum length')
    
    # Validate postal code format
    from main import validate_postal_code
    postal_code = shipping_address.get('postalCode', '')
    if not validate_postal_code(postal_code, shipping_address.get('country', 'Canada')):
        raise https_fn.HttpsError('invalid-argument', f'Invalid postal code format: {postal_code}')
    
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
        # Check quantity limits
        item_quantity = item.get('quantity', 0)
        if not isinstance(item_quantity, int) or item_quantity <= 0:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'Item quantity must be a positive integer: {item_quantity}'
            )
        if item_quantity > 100:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'Item quantity exceeds maximum allowed (100): {item_quantity}'
            )
        
        # Fetch product from Firestore for server-side validation
        product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
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
                f"Price mismatch for product {item['productId']}: expected ${db_price:.2f}, got ${client_price:.2f}"
            )
        
        # Check stock availability
        stock_quantity = product_data.get('stockQuantity', 0)
        if stock_quantity < item['quantity']:
            raise https_fn.HttpsError(
                'resource-exhausted',
                f"Insufficient stock for product {item['productId']} ({item['name']}): {stock_quantity} available, {item['quantity']} requested"
            )
        
        # Check seller status
        seller_id = item['sellerId']
        _assert_seller_active(seller_id, require_approval=True)
        sellers.add(seller_id)
        
        # Prevent sellers from buying their own products
        if seller_id == user_id:
            raise https_fn.HttpsError(
                'invalid-argument',
                f"You cannot purchase your own product: {product_data['name']}"
            )
        
        # Fetch seller profile for shipping calculation
        seller_ref = get_db().collection(Collections.USERS).document(seller_id)
        seller_doc = seller_ref.get()
        seller_data = seller_doc.to_dict() if seller_doc.exists else {}
        seller_profile = seller_data.get('sellerProfile', {})
        
        image_urls = product_data.get('imageUrls', [])
        if not isinstance(image_urls, list):
            image_urls = [str(image_urls)]

        primary_image_url = image_urls[0] if image_urls else ''

        # Build sellerAddress - must have required Address fields for Flutter parsing
        raw_seller_address = seller_profile.get('businessAddress', {})
        if not raw_seller_address or not raw_seller_address.get('street'):
            # Fallback: use seller's main address or a minimal valid stub
            raw_seller_address = seller_data.get('address', {})
        if not raw_seller_address or not raw_seller_address.get('street'):
            raw_seller_address = {
                'street': 'N/A',
                'city': 'N/A',
                'state': 'ON',
                'postalCode': 'M5V 3A8',
                'country': 'Canada',
            }

        validated_item = {
            'productId': item['productId'],
            'name': product_data['name'],
            'description': product_data.get('description', ''),
            'price': db_price,
            'quantity': item['quantity'],
            'sellerId': seller_id,
            'imageUrls': image_urls if image_urls else [''],
            'isDigital': product_data.get('isDigital', False),
            'categoryId': product_data.get('categoryId', 0),
            'status': 'pending',  # Per-item status: pending | shipped | delivered | refunded
            'deliveryStatus': 'pending',  # Legacy field (kept for backwards compatibility)
            'trackingNumber': None,
            'carrier': None,
            'shippedAt': None,
            'deliveredAt': None,
            'confirmedByBuyer': False,
            'freeShipping': product_data.get('freeShipping', False),
            'isLocalDeliveryOnly': product_data.get('isLocalDeliveryOnly', False),
            'isPerishable': product_data.get('isPerishable', False),
            'deliveryOptions': product_data.get('deliveryOptions', []),
            'sellerAddress': raw_seller_address,
        }
        validated_items.append(validated_item)
        actual_subtotal += db_price * item['quantity']
    
    # Verify subtotal (exact cent comparison — prices already validated per-item)
    actual_subtotal_cents = round(actual_subtotal * 100)
    client_subtotal_cents = round(client_subtotal * 100)
    if actual_subtotal_cents != client_subtotal_cents:
        raise https_fn.HttpsError(
            'invalid-argument',
            f'Subtotal mismatch: expected ${actual_subtotal:.2f}, got ${client_subtotal:.2f}'
        )
    
    # Calculate shipping (server-side) - returns dollars
    try:
        shipping_cost_dollars = calculate_shipping_cost(validated_items, shipping_address)
        shipping_cost_cents = round(shipping_cost_dollars * 100)
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Shipping calculation failed: {str(e)}')
    
    # Calculate taxes (server-side) - all in cents to avoid rounding errors
    province = shipping_address.get('province', 'ON')
    tax_rate = get_tax_rate(province)
    tax_amount_cents = round(actual_subtotal_cents * tax_rate)

    # Build tax breakdown dict (matches Flutter provinceTaxRates)
    _PROVINCE_TAX_BREAKDOWN = {
        'AB': {'GST': 0.05}, 'BC': {'GST': 0.05, 'PST': 0.07},
        'MB': {'GST': 0.05, 'PST': 0.07}, 'NB': {'HST': 0.15},
        'NL': {'HST': 0.15}, 'NS': {'HST': 0.15}, 'NT': {'GST': 0.05},
        'NU': {'GST': 0.05}, 'ON': {'HST': 0.13}, 'PE': {'HST': 0.15},
        'QC': {'GST': 0.05, 'QST': 0.09975}, 'SK': {'GST': 0.05, 'PST': 0.06},
        'YT': {'GST': 0.05},
    }
    province_rates = _PROVINCE_TAX_BREAKDOWN.get(province, {'GST': 0.05})
    taxes_breakdown = {
        name: round(actual_subtotal * rate, 2)
        for name, rate in province_rates.items()
    }

    # Total in cents
    total_amount_cents = actual_subtotal_cents + shipping_cost_cents + tax_amount_cents
    
    # Reserve stock atomically using Firestore transactions
    @get_transactional()
    def reserve_stock_transaction(transaction):
        for item in validated_items:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
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
    
    # Create order in Firestore — all amounts in cents
    order_ref = get_db().collection(Collections.ORDERS).document()
    order_id = order_ref.id

    order_data = {
        'orderId': order_id,
        'userId': user_id,
        'sellerIds': sorted(list(sellers)),
        'items': validated_items,
        'subtotalCents': actual_subtotal_cents,
        'shippingCostCents': shipping_cost_cents,
        'taxAmountCents': tax_amount_cents,
        'totalAmountCents': total_amount_cents,
        'taxes': taxes_breakdown,
        'orderStatus': OrderStatus.PENDING,
        'paymentStatus': PaymentStatus.AWAITING_PAYMENT,
        'shippingAddress': shipping_address,
        'createdAt': get_server_timestamp(),
        'updatedAt': get_server_timestamp(),
        'captureAttempts': 0,
        'expiresAt': datetime.now() + timedelta(days=AUTHORIZATION_VALID_DAYS),
        'currency': 'cad',
        'paymentProvider': 'stripe',
    }
    
    order_ref.set(order_data)
    
    # Create Stripe Checkout Session
    try:
        # Helper function to get tax code based on category
        def get_tax_code_for_category(category_id):
            """Map product categories to Stripe tax codes"""
            tax_code_map = {
                17: "txcd_20030002",  # Children's Clothing
                19: "txcd_30060005",  # Basic Groceries
            }
            return tax_code_map.get(category_id, None)
        
        line_items = []
        for item in validated_items:
            product_data = {
                'name': item['name'],
                'images': item.get('imageUrls', [])[:1]
            }
            
            # Add tax code if available
            tax_code = get_tax_code_for_category(item.get('categoryId', 0))
            if tax_code:
                product_data['tax_code'] = tax_code
            
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': product_data,
                    'unit_amount': int(item['price'] * 100)  # Convert to cents
                },
                'quantity': item['quantity']
            })
        
        # Add shipping as line item (already in cents)
        if shipping_cost_cents > 0:
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': {
                        'name': 'Shipping'
                    },
                    'unit_amount': shipping_cost_cents
                },
                'quantity': 1
            })
        
        # Add tax as line item (already in cents)
        # NOTE: We calculate tax manually server-side
        # Stripe automatic_tax is DISABLED to avoid double taxation
        if tax_amount_cents > 0:
            line_items.append({
                'price_data': {
                    'currency': 'cad',
                    'product_data': {
                        'name': f'Tax ({province})'
                    },
                    'unit_amount': tax_amount_cents
                },
                'quantity': 1
            })
        
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=line_items,
            mode='payment',
            success_url=f'https://orignagta.ca/order-success?session_id={{CHECKOUT_SESSION_ID}}',
            cancel_url='https://orignagta.ca/cart',
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
            # NOTE: automatic_tax disabled - we calculate tax server-side to avoid double taxation
        )
        
        # Update order with session ID
        order_ref.update({
            'stripeSessionId': session.id,
            'stripePaymentIntentId': session.payment_intent if hasattr(session, 'payment_intent') else None
        })
        
        # Return dict directly for on_call functions
        return {
            'success': True,
            'sessionId': session.id,
            'orderId': order_id,
            'checkoutUrl': session.url
        }
        
    except Exception as e:
        # Rollback stock reservation
        @get_transactional()
        def rollback_stock(transaction):
            for item in validated_items:
                product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
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


@https_fn.on_request(**WEBHOOK_OPTIONS)
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
    - account.updated: Connect account status changed (enables sellers after onboarding)
    
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
    # Reject non-POST requests immediately (browser health checks, emulator UI)
    if req.method != 'POST':
        return https_fn.Response('Method not allowed', status=405)

    # SECURITY FIX #1: Rate limiting by IP FIRST (prevent DDoS)
    # Skip rate limiting in emulator mode to avoid Firestore transaction issues
    client_ip = req.headers.get('X-Forwarded-For', req.headers.get('X-Real-IP', 'unknown')).split(',')[0].strip()

    if not IS_EMULATOR:
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
    except Exception as e:
        # Handle SignatureVerificationError and other exceptions
        if 'SignatureVerificationError' in str(type(e).__name__):
            print(f'⚠️ Stripe webhook invalid signature from IP: {client_ip[:10]}...')  # Sanitized
            return https_fn.Response('Invalid signature', status=400)
        print(f'⚠️ Stripe webhook verification error: {type(e).__name__}')  # Sanitized (no details)
        return https_fn.Response('Signature verification error', status=500)
    
    event_id = event['id']
    event_type = event['type']
    
    # SECURITY FIX #4: Idempotency check (prevent duplicate processing)
    webhook_ref = get_db().collection('webhook_events').document(event_id)
    webhook_doc = webhook_ref.get()

    if webhook_doc.exists:
        existing_status = webhook_doc.to_dict().get('status', 'completed')
        if existing_status == 'completed':
            print(f'✓ Stripe webhook already processed: {event_type} (event: {event_id[:16]}...)')
            return https_fn.Response('Event already processed', status=200)
        # Allow retry of failed events
        print(f'♻️ Retrying failed webhook: {event_type} (event: {event_id[:16]}...)')

    # SECURITY FIX #5: Log webhook event with audit trail (status: processing)
    try:
        order_id = event.get('data', {}).get('object', {}).get('metadata', {}).get('orderId', 'N/A')
        webhook_ref.set({
            'provider': 'stripe',
            'type': event_type,
            'status': 'processing',
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
        elif event_type == 'account.updated':
            process_account_updated(event['data']['object'])
            result = None
        else:
            print(f'ℹ️ Unhandled Stripe event type: {event_type}')
            result = None
        
        # Mark as completed
        try:
            webhook_ref.update({'status': 'completed'})
        except Exception:
            pass

        print(f'✓ Stripe webhook processed successfully: {event_type}')
        return https_fn.Response('Success', status=200)

    except Exception as e:
        # Mark as failed so Stripe can retry
        try:
            webhook_ref.update({'status': 'failed', 'error': type(e).__name__})
        except Exception:
            pass

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
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        print(f'Order {order_id} not found')
        return None
    
    order_data = order_doc.to_dict()
    
    # Update order status
    order_ref.update({
        'orderStatus': OrderStatus.CONFIRMED,
        'paymentStatus': PaymentStatus.AUTHORIZED,
        'stripePaymentIntentId': session.get('payment_intent'),
        'updatedAt': get_server_timestamp()
    })
    
    # Send confirmation emails
    try:
        # Get buyer email from order data or user document
        buyer_email = order_data.get('customerEmail')
        if not buyer_email:
            buyer_doc = get_db().collection(Collections.USERS).document(order_data['userId']).get()
            if buyer_doc.exists:
                buyer_email = buyer_doc.to_dict().get('email')
        
        if buyer_email:
            buyer_email_html = get_order_confirmation_email(order_data, order_id)
            send_email(
                to_email=buyer_email,
                subject='Order Confirmation - Origna',
                html_content=buyer_email_html
            )
        
        # Email to sellers
        sellers = set(item['sellerId'] for item in order_data['items'])
        for seller_id in sellers:
            # Get seller email from user document
            seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
            if seller_doc.exists:
                seller_data = seller_doc.to_dict()
                seller_email = seller_data.get('email')
                if seller_email:
                    seller_email_html = get_seller_notification_email(order_data, order_id, seller_id)
                    send_email(
                        to_email=seller_email,
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
    cart_ref = get_db().collection(Collections.USERS).document(user_id).collection('cart')
    cart_docs = cart_ref.stream()
    
    for doc in cart_docs:
        doc.reference.delete()


def process_async_payment_succeeded(session: Dict) -> Optional[str]:
    """Handles async payment success (e.g., bank transfers)"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.CAPTURED,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Order {order_id} payment captured'


def process_async_payment_failed(session: Dict) -> Optional[str]:
    """Handles async payment failure"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if order_doc.exists:
        order_data = order_doc.to_dict()
        
        # Restore stock
        _restore_stock_for_order(order_data)
        
        # Update order
        order_ref.update({
            'orderStatus': OrderStatus.CANCELLED,
            'paymentStatus': PaymentStatus.PAYMENT_FAILED,
            'updatedAt': get_server_timestamp()
        })
    
    return f'Order {order_id} cancelled due to payment failure'


def _restore_stock_for_order(order_data: Dict) -> None:
    """Restores product stock after order cancellation using atomic increment."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs

    for item in order_data.get('items', []):
        product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
        product_ref.update({
            'stockQuantity': _firestore.Increment(item['quantity'])
        })


def process_session_expired(session: Dict) -> Optional[str]:
    """Handles expired checkout sessions"""
    order_id = session.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if order_doc.exists:
        order_data = order_doc.to_dict()
        _restore_stock_for_order(order_data)
        
        order_ref.update({
            'orderStatus': OrderStatus.EXPIRED,
            'paymentStatus': PaymentStatus.SESSION_EXPIRED,
            'updatedAt': get_server_timestamp()
        })
    
    return f'Order {order_id} expired'


def process_payment_intent_succeeded(payment_intent: Dict) -> Optional[str]:
    """Handles successful payment intents"""
    order_id = payment_intent.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.CAPTURED,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Payment captured for order {order_id}'


def process_payment_intent_failed(payment_intent: Dict) -> Optional[str]:
    """Handles failed payment intents"""
    order_id = payment_intent.get('metadata', {}).get('orderId')
    
    if not order_id:
        return None
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_ref.update({
        'paymentStatus': PaymentStatus.PAYMENT_FAILED,
        'updatedAt': get_server_timestamp()
    })
    
    return f'Payment failed for order {order_id}'


def process_charge_refunded(charge: Dict) -> Optional[str]:
    """Handles charge refunds"""
    payment_intent_id = charge.get('payment_intent')
    
    if not payment_intent_id:
        return None
    
    # Find order by payment intent
    orders = get_db().collection(Collections.ORDERS)\
        .where('stripePaymentIntentId', '==', payment_intent_id)\
        .limit(1)\
        .stream()
    
    for order_doc in orders:
        order_ref = order_doc.reference
        order_ref.update({
            'orderStatus': OrderStatus.REFUNDED,
            'paymentStatus': PaymentStatus.REFUNDED,
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
    payouts = get_db().collection(Collections.PAYOUTS)\
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


def process_account_updated(account: Dict) -> None:
    """
    Process account.updated event from Stripe Connect.
    Updates the user's Firestore document when their Stripe account status changes.
    This is critical for enabling sellers after they complete onboarding.
    """
    print("\n🏪 Processing: account.updated")

    account_id = account.get('id')
    if not account_id:
        print("  ⚠️ No account ID in event")
        return

    print(f"  Account ID: {account_id}")
    print(f"  Charges Enabled: {account.get('charges_enabled')}")
    print(f"  Payouts Enabled: {account.get('payouts_enabled')}")
    print(f"  Details Submitted: {account.get('details_submitted')}")
    requirements = account.get('requirements', {})
    currently_due = requirements.get('currently_due', []) or []
    if currently_due:
        print(f"  Requirements Due: {currently_due}")

    # Find user with this Stripe account
    users = get_db().collection(Collections.USERS).where(
        'stripeAccountId', '==', account_id
    ).limit(1).get()

    if not users:
        print(f"  ⚠️ No user found with Stripe account {account_id}")
        return

    user_ref = users[0].reference
    user_id = user_ref.id
    user_data = users[0].to_dict()

    print(f"  User ID: {user_id}")

    # Pending requirements already extracted above for logging
    eventually_due = requirements.get('eventually_due', []) or []
    pending_requirements = list(set(currently_due + eventually_due))

    # Update user document with current account status
    update_data = {
        'chargesEnabled': account.get('charges_enabled', False),
        'payoutsEnabled': account.get('payouts_enabled', False),
        'onboardingCompleted': account.get('details_submitted', False),
        'pendingRequirements': pending_requirements,
        'updatedAt': get_server_timestamp(),
    }
    
    # If onboarding is completed, ensure seller role is set
    if account.get('details_submitted', False):
        current_roles = user_data.get('roles', [])
        if 'seller' not in current_roles:
            update_data['roles'] = current_roles + ['seller']
            print(f"  ✅ Adding seller role to user {user_id}")
    
    user_ref.update(update_data)
    print(f"  ✅ Updated user {user_id} Stripe account status")


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_connect_account(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Creates Stripe Connect account for seller onboarding"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data or {}
    
    # Import validation functions
    from utils import sanitize_email
    
    # Get user data from Firestore to get email if not provided
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User profile not found')
    
    user_data = user_doc.to_dict()
    
    # Check if user already has a Stripe account
    existing_account_id = user_data.get('stripeAccountId')
    if existing_account_id:
        # Return existing account instead of creating new one
        return {
            'success': True,
            'accountId': existing_account_id,
            'existing': True
        }
    
    # Get email from request or user profile
    email_raw = data.get('email') or user_data.get('email')
    country = data.get('country', 'CA')
    
    if not email_raw:
        raise https_fn.HttpsError('invalid-argument', 'Email is required. Please update your profile with a valid email.')
    
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
        
        # Save account ID to Firestore and add seller role
        from firebase_admin import firestore as admin_firestore
        user_ref.update({
            'stripeAccountId': account.id,
            'roles': admin_firestore.ArrayUnion(['seller']),
            'updatedAt': get_server_timestamp()
        })
        
        return {'success': True, 'accountId': account.id}
        
    except stripe.error.InvalidRequestError as e:
        raise https_fn.HttpsError('invalid-argument', f'Invalid request: {e.user_message or str(e)}')
    except stripe.error.AuthenticationError:
        raise https_fn.HttpsError('internal', 'Payment service configuration error. Please contact support.')
    except stripe.error.APIConnectionError:
        raise https_fn.HttpsError('unavailable', 'Could not connect to payment service. Please try again later.')
    except stripe.error.StripeError as e:
        # Log the full error for debugging
        print(f'Stripe error creating account: {str(e)}')
        raise https_fn.HttpsError('internal', f'Could not create seller account: {e.user_message or "Please try again later."}')


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_account_link(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Creates Stripe Connect onboarding link"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    
    # Get URLs from request data (passed from frontend)
    data = req.data or {}
    refresh_url = data.get('refreshUrl', 'https://orignagta.ca/seller/refresh')
    return_url = data.get('returnUrl', 'https://orignagta.ca/seller/return')
    
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    account_id = user_data.get('stripeAccountId')
    
    if not account_id:
        raise https_fn.HttpsError(
            'failed-precondition', 
            'You need to create an account first to become a seller. Please tap "Create Seller Account" to get started.'
        )
    
    try:
        # For Express accounts, always use account_onboarding
        # Stripe automatically shows any pending requirements
        account_link = stripe.AccountLink.create(
            account=account_id,
            refresh_url=refresh_url,
            return_url=return_url,
            type='account_onboarding'
        )

        return {'success': True, 'url': account_link.url}

    except Exception as e:
        raise https_fn.HttpsError('internal', f'Could not create onboarding link: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_connect_account_status(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """Gets Stripe Connect account status"""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    account_id = user_data.get('stripeAccountId')
    
    if not account_id:
        raise https_fn.HttpsError(
            'failed-precondition', 
            'You need to create an account first to become a seller. Please complete your seller registration.'
        )
    
    try:
        account = stripe.Account.retrieve(account_id)
        
        # Update Firestore with latest status
        from firebase_admin import firestore as admin_firestore
        update_data = {
            'chargesEnabled': account.charges_enabled,
            'payoutsEnabled': account.payouts_enabled,
            'onboardingCompleted': account.details_submitted,
            'updatedAt': get_server_timestamp()
        }
        
        # If onboarding is complete, ensure seller role is added
        if account.details_submitted:
            update_data['roles'] = admin_firestore.ArrayUnion(['seller'])
        
        user_ref.update(update_data)
        
        # Return dict directly for on_call functions
        return {
            'success': True,
            'chargesEnabled': account.charges_enabled,
            'payoutsEnabled': account.payouts_enabled,
            'detailsSubmitted': account.details_submitted,
            'requirementsCurrentlyDue': account.requirements.currently_due
        }
        
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Could not get account status: {str(e)}')


@https_fn.on_call(**DEFAULT_OPTIONS)
def capture_payment(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Manually captures authorized payment and initiates seller payouts.
    Called when buyer confirms order receipt.
    
    Security:
    - Only order owner (buyer) or admin can capture
    - Order must be in valid state for capture
    - Idempotency: prevents duplicate captures/transfers
    """
    # Check if Stripe is enabled
    from handlers.payment_providers import require_provider_enabled, PaymentProvider
    require_provider_enabled(PaymentProvider.STRIPE)
    
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    caller_uid = req.auth.uid
    order_id = req.data.get('orderId')
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    
    # CRITICAL SECURITY CHECK: Only order owner or admin can capture
    order_user_id = order_data.get('userId')
    is_admin = 'admin' in req.auth.token.get('roles', [])
    
    if caller_uid != order_user_id and not is_admin:
        raise https_fn.HttpsError(
            'permission-denied',
            'Only the order owner can capture this payment'
        )
    
    # Verify order is in valid state for capture
    payment_status = order_data.get('paymentStatus')
    order_status = order_data.get('orderStatus')
    
    # Idempotency: if already captured, return success
    if payment_status == PaymentStatus.CAPTURED:
        # Ensure buyer receipt confirmation is persisted (best-effort)
        if not order_data.get('confirmedByClient'):
            try:
                order_ref.update({
                    'confirmedByClient': True,
                    'confirmedAt': get_server_timestamp(),
                    'updatedAt': get_server_timestamp(),
                })
            except Exception:
                pass
        return {
            'success': True,
            'captured': True,
            'message': 'Payment already captured',
            'paymentIntentId': order_data.get('stripePaymentIntentId')
        }
    
    # Verify order is in correct state (should be authorized/shipped)
    if payment_status != PaymentStatus.AUTHORIZED:
        raise https_fn.HttpsError(
            'failed-precondition',
            f'Order payment not authorized (status: {payment_status})'
        )
    
    if order_status not in [OrderStatus.SHIPPED, OrderStatus.IN_TRANSIT, OrderStatus.DELIVERED]:
        raise https_fn.HttpsError(
            'failed-precondition',
            f'Order not shipped yet (status: {order_status})'
        )
    
    payment_intent_id = order_data.get('stripePaymentIntentId')
    
    if not payment_intent_id:
        raise https_fn.HttpsError('failed-precondition', 'No payment intent found')
    
    # Track capture attempts to prevent infinite retries
    capture_attempts = order_data.get('captureAttempts', 0)
    if capture_attempts >= 3:
        raise https_fn.HttpsError(
            'failed-precondition',
            'Maximum capture attempts exceeded'
        )
    
    try:
        # Validate PI is in capturable state
        payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        if payment_intent.status != 'requires_capture':
            raise https_fn.HttpsError(
                'failed-precondition',
                f'Payment cannot be captured (status: {payment_intent.status})'
            )

        # Validate capture amount matches order total (both in cents)
        expected_amount_cents = order_data.get('totalAmountCents', 0)

        if payment_intent.amount != expected_amount_cents:
            raise https_fn.HttpsError(
                'failed-precondition',
                f'Payment amount mismatch: expected {expected_amount_cents} cents, got {payment_intent.amount} cents'
            )

        # Capture the payment
        payment_intent = stripe.PaymentIntent.capture(payment_intent_id)

        # Check if all items are delivered before capturing
        items = order_data.get('items', [])
        all_items_delivered = all(item.get('status') == 'delivered' for item in items)
        
        # Update order
        order_ref.update({
            'paymentStatus': PaymentStatus.CAPTURED,
            'orderStatus': OrderStatus.DELIVERED if all_items_delivered else order_status,
            'capturedAt': get_server_timestamp(),
            'confirmedByClient': True,
            'confirmedAt': get_server_timestamp(),
            'captureAttempts': capture_attempts + 1,
            'updatedAt': get_server_timestamp()
        })
        
        # Create payouts ONLY for sellers whose items are delivered
        sellers_total_cents = {}
        for item in items:
            # Only include delivered items (or all items if no per-item status tracking)
            item_status = item.get('status', 'pending')
            if item_status in ['delivered', 'pending']:  # 'pending' for backwards compatibility
                seller_id = item['sellerId']
                # Price is in dollars, convert to cents
                item_price_cents = round(item['price'] * 100)
                item_total_cents = item_price_cents * item['quantity']
                sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents
        
        for seller_id, amount_cents in sellers_total_cents.items():
            # Platform fee in cents (rounded)
            platform_fee_cents = round(amount_cents * PLATFORM_FEE_PERCENT)
            net_amount_cents = amount_cents - platform_fee_cents
            
            # Get seller's Stripe account
            seller_ref = get_db().collection(Collections.USERS).document(seller_id)
            seller_doc = seller_ref.get()
            
            if seller_doc.exists:
                seller_data = seller_doc.to_dict()
                stripe_account_id = seller_data.get('stripeAccountId')
                
                if stripe_account_id:
                    # Check for existing transfer (idempotency)
                    existing_payout = get_db().collection(Collections.PAYOUTS).where(
                        'orderId', '==', order_id
                    ).where(
                        'sellerId', '==', seller_id
                    ).where(
                        'status', '==', 'completed'
                    ).limit(1).get()
                    
                    if len(existing_payout) > 0:
                        # Transfer already completed for this seller, skip
                        continue
                    
                    # Create transfer to seller (amount already in cents)
                    transfer = stripe.Transfer.create(
                        amount=net_amount_cents,
                        currency='cad',
                        destination=stripe_account_id,
                        source_transaction=payment_intent_id,
                        transfer_group=order_id,
                        metadata={
                            'orderId': order_id,
                            'sellerId': seller_id
                        }
                    )
                    
                    # Log payout (store in cents for consistency)
                    get_db().collection(Collections.PAYOUTS).add({
                        'orderId': order_id,
                        'sellerId': seller_id,
                        'amountCents': amount_cents,
                        'platformFeeCents': platform_fee_cents,
                        'netAmountCents': net_amount_cents,
                        'status': 'completed',
                        'stripeTransferId': transfer.id,
                        'payoutDate': get_server_timestamp(),
                        'createdAt': get_server_timestamp()
                    })
        
        # Return dict directly for on_call functions
        return {'success': True, 'captured': True, 'paymentIntentId': payment_intent_id}
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        raise https_fn.HttpsError('internal', f'Could not capture payment: {str(e)}')



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
