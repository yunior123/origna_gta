"""
Airwallex Payment Handlers
- Alternative payment provider (3DS support)
- Connected account creation
- Payment intent processing
- Webhook handling
"""

from typing import Any

from firebase_functions import https_fn

from function_options import DEFAULT_OPTIONS

# Lazy-loaded globals
_db = None
_firestore = None
_airwallex_service = None
_airwallex_service = None
_collections = None
_utils = None
_fields = None

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
        from schema_constants import Collections
        _collections = Collections
    return _collections

def get_order_status_values():
    """Get OrderStatusValues config (lazy initialization)."""
    from schema_constants import OrderStatusValues
    return OrderStatusValues

def get_fields():
    """Get Fields config (lazy initialization)."""
    global _fields
    if _fields is None:
        from schema_constants import Fields
        _fields = Fields
    return _fields

def get_utils():
    """Get utility functions (lazy initialization)."""
    global _utils
    if _utils is None:
        import utils
        _utils = utils
    return _utils


@https_fn.on_call(**DEFAULT_OPTIONS)
def airwallex_create_seller_account(req: https_fn.CallableRequest) -> dict[str, Any]:
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
        Fields = get_fields()
        user_ref = get_db().collection(Collections.USERS).document(user_id)
        user_ref.update({
            Fields.AIRWALLEX_ACCOUNT_ID: account_id,
            Fields.UPDATED_AT: get_server_timestamp()
        })

        utils = get_utils()
        return utils.create_success_response({'accountId': account_id})

    except Exception as e:
        print(f'Airwallex create_seller_account error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Failed to create seller account') from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def airwallex_process_payment(req: https_fn.CallableRequest) -> dict[str, Any]:
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

    # Check if Airwallex is enabled
    from handlers.payment_providers import PaymentProvider, require_provider_enabled
    require_provider_enabled(PaymentProvider.AIRWALLEX)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get('orderId')
    return_url = data.get('returnUrl', 'https://origna.ca/order-success')

    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')

    # Get order
    Collections = get_collections()
    Fields = get_fields()
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()
    Fields = get_fields()

    if order_data[Fields.USER_ID] != user_id:
        raise https_fn.HttpsError('permission-denied', 'Not your order')

    try:
        airwallex_service = get_airwallex_service()

        amount_cents = order_data.get(Fields.TOTAL_AMOUNT_CENTS)
        if amount_cents is None or not isinstance(amount_cents, int) or amount_cents < 0:
            raise https_fn.HttpsError('failed-precondition', 'Order total not available')

        result = airwallex_service.create_payment_intent_for_checkout(
            amount_cents=int(amount_cents),
            currency='CAD',
            order_id=order_id,
            return_url=return_url,
            capture=False,
            metadata={'user_id': user_id},
        )

        # Update order with Airwallex payment intent
        order_ref.update({
            'airwallexPaymentIntentId': result['id'],
            Fields.PAYMENT_PROVIDER: 'airwallex',
            Fields.UPDATED_AT: get_server_timestamp()
        })

        utils = get_utils()
        return utils.create_success_response(result)

    except Exception as e:
        print(f'Airwallex process_payment error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Payment processing failed') from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def airwallex_capture_payment(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Captures Airwallex payment after authorization.

    Request data:
        orderId: Order document ID

    Returns:
        {success: True, captured: True}
    """
    # Check if Airwallex is enabled
    from handlers.payment_providers import PaymentProvider, require_provider_enabled
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

        Fields = get_fields()
        order_ref.update({
            Fields.PAYMENT_STATUS: 'captured',
            Fields.UPDATED_AT: get_server_timestamp()
        })

        utils = get_utils()
        return utils.create_success_response({'captured': True})

    except Exception as e:
        print(f'Airwallex capture_payment error: {type(e).__name__}: {str(e)}')
        raise https_fn.HttpsError('internal', 'Payment capture failed') from e


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
    sig_header = req.headers.get('x-signature') or req.headers.get('X-Signature')
    ts_header = req.headers.get('x-timestamp') or req.headers.get('X-Timestamp')

    if not sig_header or not ts_header:
        print(f'⚠️ Airwallex webhook missing signature/timestamp from IP: {client_ip[:10]}...')
        return https_fn.Response('Missing signature', status=400)

    # SECURITY: Verify signature BEFORE parsing JSON. Never accept signing secrets from request headers.
    try:
        airwallex_service = get_airwallex_service()
        is_valid = airwallex_service.verify_webhook_signature(
            payload,
            sig_header,
            timestamp=ts_header,
        )
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
        print('⚠️ Airwallex webhook missing event_id or event_type')
        return https_fn.Response('Invalid event format', status=400)

    # SECURITY FIX #6: Idempotency check (prevent duplicate processing)
    Collections = get_collections()
    webhook_ref = get_db().collection(Collections.WEBHOOK_EVENTS).document(event_id)
    webhook_doc = webhook_ref.get()

    if webhook_doc.exists:
        print(f'✓ Airwallex webhook already processed: {event_type} (event: {event_id[:16]}...)')  # Sanitized
        return https_fn.Response('Already processed', status=200)

    # SECURITY FIX #7: Log webhook with client IP for audit trail
    try:
        Fields = get_fields()
        webhook_ref.set({
            Fields.PROVIDER: 'airwallex',
            Fields.TYPE: event_type,
            Fields.PROCESSED: True,
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.CLIENT_IP: client_ip,  # Audit trail
            Fields.EVENT_ID: event_id
        })
    except Exception as e:
        print(f'⚠️ Failed to log webhook: {type(e).__name__}')  # Sanitized (no sensitive data)

    # Process event
    try:
        data = event.get('data', {}) if isinstance(event.get('data'), dict) else {}

        Collections = get_collections()

        def _extract_order_id(payload: dict[str, Any]) -> str:
            val = payload.get('orderId') or payload.get('merchant_order_id', '')
            if isinstance(val, str) and val.strip():
                return val.strip()
            metadata = payload.get('metadata', {})
            if isinstance(metadata, dict):
                val = metadata.get('orderId') or metadata.get('merchant_order_id', '')
                if isinstance(val, str) and val.strip():
                    return val.strip()
            return ""

        if event_type == 'payment_intent.requires_capture':
            # Manual capture: payment authorized, awaiting capture
            order_id = _extract_order_id(data)
            if order_id:
                Fields = get_fields()
                order_ref = get_db().collection(Collections.ORDERS).document(order_id)
                order_ref.update({
                    Fields.PAYMENT_STATUS: 'authorized',
                    Fields.ORDER_STATUS: get_order_status_values().CONFIRMED,
                    Fields.UPDATED_AT: get_server_timestamp()
                })

        elif event_type == 'payment_intent.succeeded':
            # Payment fully captured/completed
            order_id = _extract_order_id(data)
            if order_id:
                Fields = get_fields()
                order_ref = get_db().collection(Collections.ORDERS).document(order_id)
                order_ref.update({
                    Fields.PAYMENT_STATUS: 'captured',
                    Fields.UPDATED_AT: get_server_timestamp()
                })

        elif event_type in ('payment_attempt.authorization_failed', 'payment_intent.cancelled'):
            order_id = _extract_order_id(data)
            if order_id:
                Fields = get_fields()
                order_ref = get_db().collection(Collections.ORDERS).document(order_id)
                order_ref.update({
                    Fields.PAYMENT_STATUS: 'payment_failed',
                    Fields.ORDER_STATUS: get_order_status_values().FAILED,
                    Fields.UPDATED_AT: get_server_timestamp()
                })

        print(f'✓ Airwallex webhook processed successfully: {event_type}')
        return https_fn.Response('Success', status=200)

    except Exception as e:
        # SECURITY FIX #8: Sanitized error logging (no sensitive data exposure)
        error_type = type(e).__name__
        print(f'❌ Error processing Airwallex webhook: {error_type} for event_type: {event_type}')
        # Don't expose internal error details to webhook caller
        return https_fn.Response('Internal processing error', status=500)
