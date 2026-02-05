"""
Airwallex Payment Handlers
- Alternative payment provider (3DS support)
- Connected account creation
- Payment intent processing
- Webhook handling
"""

from function_options import DEFAULT_OPTIONS, WEBHOOK_OPTIONS, CORS_CONFIG, CRON_OPTIONS
from firebase_functions import https_fn
from typing import Dict, Any

# Lazy-loaded globals
_db = None
_firestore = None
_airwallex_service = None
_collections = None
_utils = None

def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs
        _firestore = fs
        _db = fs.client()
    return _db

def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs
    return _firestore.SERVER_TIMESTAMP

def get_airwallex_service():
    """Get Airwallex service (lazy initialization)."""
    global _airwallex_service
    if _airwallex_service is None:
        from airwallex_service import AirwallexService
        _airwallex_service = AirwallexService()
    return _airwallex_service

def get_collections():
    """Get Collections config (lazy initialization)."""
    global _collections
    if _collections is None:
        from config import Collections
        _collections = Collections
    return _collections

def get_utils():
    """Get utility functions (lazy initialization)."""
    global _utils
    if _utils is None:
        import utils
        _utils = utils
    return _utils


@https_fn.on_call(**DEFAULT_OPTIONS._asdict())
def airwallex_create_seller_account(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Creates Airwallex connected account for seller.
    
    Request data:
        email: Seller email
        businessInfo: Business details
    
    Returns:
        {success: True, accountId: "..."}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data
    
    try:
        airwallex_service = get_airwallex_service()
        account_id = airwallex_service.create_connected_account(
            user_id=user_id,
            email=data.get('email'),
            business_info=data.get('businessInfo', {})
        )
        
        # Save account ID to Firestore
        Collections = get_collections()
        user_ref = get_db().collection(Collections.USERS).document(user_id)
        user_ref.update({
            'airwallexAccountId': account_id,
            'updatedAt': get_server_timestamp()
        })
        
        utils = get_utils()
        return utils.create_success_response({'accountId': account_id})
        
    except Exception as e:
        print(f'Airwallex create_seller_account error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Failed to create seller account')


@https_fn.on_call(**DEFAULT_OPTIONS._asdict())
def airwallex_process_payment(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Creates Airwallex payment intent.
    
    Request data:
        orderId: Order document ID
        returnUrl: URL to return after 3DS
    
    Returns:
        {
            success: True,
            paymentIntentId: "...",
            clientSecret: "...",
            nextAction: {...}
        }
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    data = req.data
    
    order_id = data.get('orderId')
    return_url = data.get('returnUrl', 'https://origna.ca/order-success')
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    # Get order
    Collections = get_collections()
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    
    if order_data['userId'] != user_id:
        raise https_fn.HttpsError('permission-denied', 'Not your order')
    
    try:
        airwallex_service = get_airwallex_service()
        result = airwallex_service.create_payment_intent(
            amount=order_data['totalAmount'],
            currency='CAD',
            order_id=order_id,
            return_url=return_url
        )
        
        # Update order with Airwallex payment intent
        order_ref.update({
            'airwallexPaymentIntentId': result['id'],
            'paymentProvider': 'airwallex',
            'updatedAt': get_server_timestamp()
        })
        
        utils = get_utils()
        return utils.create_success_response(result)
        
    except Exception as e:
        print(f'Airwallex process_payment error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Payment processing failed')


@https_fn.on_call(**DEFAULT_OPTIONS._asdict())
def airwallex_capture_payment(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Captures Airwallex payment after authorization.
    
    Request data:
        orderId: Order document ID
    
    Returns:
        {success: True, captured: True}
    """
    # Check if Airwallex is enabled
    from handlers.payment_providers import require_provider_enabled, PaymentProvider
    require_provider_enabled(PaymentProvider.AIRWALLEX)
    
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    order_id = req.data.get('orderId')
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    Collections = get_collections()
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    payment_intent_id = order_data.get('airwallexPaymentIntentId')
    
    if not payment_intent_id:
        raise https_fn.HttpsError('failed-precondition', 'No Airwallex payment intent found')
    
    try:
        airwallex_service = get_airwallex_service()
        airwallex_service.capture_payment(payment_intent_id)
        
        order_ref.update({
            'paymentStatus': 'captured',
            'updatedAt': get_server_timestamp()
        })
        
        utils = get_utils()
        return utils.create_success_response({'captured': True})
        
    except Exception as e:
        print(f'Airwallex capture_payment error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Payment capture failed')


@https_fn.on_request(timeout_sec=60)
def airwallex_webhook(req: https_fn.Request) -> https_fn.Response:
    """
    Handles Airwallex webhook events with strict security:
    1. Rate limiting by IP (FIRST)
    2. Signature verification (BEFORE processing)
    3. Idempotency check
    4. Event processing
    5. Sanitized error logging
    
    Returns:
        200 OK: Event processed
        400 Bad Request: Invalid signature
        429 Too Many Requests: Rate limit exceeded
        500 Internal Error: Processing failed
    """
    import json
    from rate_limiter import RateLimiter
    
    # SECURITY FIX #1: Rate limiting by IP FIRST (prevent DDoS)
    rate_limiter = RateLimiter(get_db())
    client_ip = req.headers.get('X-Forwarded-For', req.headers.get('X-Real-IP', 'unknown')).split(',')[0].strip()
    
    allowed, message = rate_limiter.check_rate_limit(
        identifier=f"ip_{client_ip}",
        action='airwallex_webhook',
        max_requests=100,  # 100 webhooks per minute per IP
        window_minutes=1,
        fail_closed=True  # Block on error for security
    )
    
    if not allowed:
        print(f'⚠️ Airwallex webhook rate limit exceeded for IP: {client_ip[:10]}...')  # Sanitized log
        return https_fn.Response('Rate limit exceeded', status=429)
    
    # SECURITY FIX #2: Get raw payload for signature verification
    payload = req.data
    sig_header = req.headers.get('X-Signature')
    
    if not sig_header:
        print(f'⚠️ Airwallex webhook missing signature from IP: {client_ip[:10]}...')
        return https_fn.Response('Missing signature', status=400)
    
    # SECURITY FIX #3: Verify signature BEFORE parsing JSON
    try:
        airwallex_service = get_airwallex_service()
        is_valid = airwallex_service.verify_webhook_signature(payload, sig_header)
        if not is_valid:
            print(f'⚠️ Airwallex webhook invalid signature from IP: {client_ip[:10]}...')
            return https_fn.Response('Invalid signature', status=400)
    except ValueError as e:
        print(f'⚠️ Airwallex webhook signature verification failed: {str(e)[:50]}...')  # Sanitized
        return https_fn.Response('Signature verification failed', status=400)
    except Exception as e:
        print(f'⚠️ Airwallex webhook signature error: {type(e).__name__}')  # Sanitized (no details)
        return https_fn.Response('Signature verification error', status=500)
    
    # SECURITY FIX #4: Parse JSON only AFTER signature verification
    try:
        event = json.loads(payload)
    except json.JSONDecodeError:
        print(f'⚠️ Airwallex webhook invalid JSON from IP: {client_ip[:10]}...')
        return https_fn.Response('Invalid JSON', status=400)
    
    event_id = event.get('id')
    event_type = event.get('name')
    
    # SECURITY FIX #5: Validate event_id exists
    if not event_id or not event_type:
        print(f'⚠️ Airwallex webhook missing event_id or event_type')
        return https_fn.Response('Invalid event format', status=400)
    
    # SECURITY FIX #6: Idempotency check (prevent duplicate processing)
    webhook_ref = get_db().collection('webhook_events').document(event_id)
    webhook_doc = webhook_ref.get()
    
    if webhook_doc.exists:
        print(f'✓ Airwallex webhook already processed: {event_type} (event: {event_id[:16]}...)')  # Sanitized
        return https_fn.Response('Already processed', status=200)
    
    # SECURITY FIX #7: Log webhook with client IP for audit trail
    try:
        webhook_ref.set({
            'provider': 'airwallex',
            'type': event_type,
            'processed': True,
            'timestamp': get_server_timestamp(),
            'client_ip': client_ip,  # Audit trail
            'event_id': event_id
        })
    except Exception as e:
        print(f'⚠️ Failed to log webhook: {type(e).__name__}')  # Sanitized (no sensitive data)
    
    # Process event
    try:
        data = event.get('data', {}).get('object', {})
        
        Collections = get_collections()
        
        if event_type == 'payment_intent.succeeded':
            order_id = data.get('merchant_order_id')
            if order_id:
                order_ref = get_db().collection(Collections.ORDERS).document(order_id)
                order_ref.update({
                    'paymentStatus': 'authorized',
                    'orderStatus': 'confirmed',
                    'updatedAt': get_server_timestamp()
                })
        
        elif event_type == 'payment_intent.payment_failed':
            order_id = data.get('merchant_order_id')
            if order_id:
                order_ref = get_db().collection(Collections.ORDERS).document(order_id)
                order_ref.update({
                    'paymentStatus': 'failed',
                    'orderStatus': 'cancelled',
                    'updatedAt': get_server_timestamp()
                })
        
        print(f'✓ Airwallex webhook processed successfully: {event_type}')
        return https_fn.Response('Success', status=200)
        
    except Exception as e:
        # SECURITY FIX #8: Sanitized error logging (no sensitive data exposure)
        error_type = type(e).__name__
        print(f'❌ Error processing Airwallex webhook: {error_type} for event_type: {event_type}')
        # Don't expose internal error details to webhook caller
        return https_fn.Response('Internal processing error', status=500)
