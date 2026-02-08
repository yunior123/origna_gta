"""
Order Lifecycle Management Handlers
- Order receipt confirmation
- Order status updates
- Shipping approval workflow
- Order cancellation
"""

from datetime import datetime
from typing import Any

import stripe
from firebase_functions import firestore_fn, https_fn

from config import STRIPE_SECRET_KEY, Collections
from email_service import send_email
from function_options import DEFAULT_OPTIONS
from schema_constants import (
    ApiKeys,
    DeliveryStatusValues,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ShippingApprovalStatusValues,
    UserRoleValues,
)
from utils import create_success_response, is_valid_order_status_transition

# Aliases for backward compatibility — canonical source is schema_constants
OrderStatus = OrderStatusValues
PaymentStatus = PaymentStatusValues
DeliveryStatus = DeliveryStatusValues

stripe.api_key = STRIPE_SECRET_KEY
_db = None
_firestore = None

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

def get_firestore():
    """Get Firestore module (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs
    return _firestore


@https_fn.on_call(**DEFAULT_OPTIONS)
def confirm_order_receipt(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Buyer confirms order receipt, triggering payment capture and seller payouts.

    Flow:
    1. Check if payment provider is enabled
    2. Capture Stripe Payment Intent
    3. Update order status to delivered
    4. Create payout records for each seller
    5. Transfer funds to sellers (minus 2.5% platform fee)

    Request data:
        orderId: Order document ID

    Returns:
        {success: True, captured: True}
    """
    # Backward-compatible wrapper around the canonical capture flow.
    # Flutter calls `confirm_order_receipt`; newer code calls `capture_payment` directly.
    from handlers.payment_stripe import capture_payment
    return capture_payment(req)


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_order_status(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Updates order status (seller or admin only).
    Validates state machine transitions.

    Request data:
        orderId: Order ID
        newStatus: Target status
        trackingNumber: Optional (for shipped status)
        carrier: Optional (for shipped status)

    Returns:
        {success: True, newStatus: "shipped"}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    new_status = data.get('newStatus')
    tracking_number_raw = data.get(Fields.TRACKING_NUMBER)
    carrier_raw = data.get(Fields.CARRIER)

    # Sanitize tracking number and carrier inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None

    if not order_id or not new_status:
        raise https_fn.HttpsError('invalid-argument', 'orderId and newStatus required')

    # AUDIT FIX: Rate limit order status updates (after input validation)
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action='update_order_status',
        max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()
    old_status = order_data[Fields.ORDER_STATUS]

    # Block updates on archived orders
    if order_data.get('archived', False):
        raise https_fn.HttpsError('failed-precondition', 'Cannot update archived order')

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])

    # Check if user is seller for any item in order
    seller_items = [item for item in order_data[Fields.ITEMS] if item[Fields.SELLER_ID] == user_id]
    is_seller = len(seller_items) > 0

    if not (is_admin or is_seller):
        raise https_fn.HttpsError('permission-denied', 'Only seller or admin can update order status')

    # MULTI-SELLER ISOLATION: Sellers can only update to SHIPPED if ALL their items
    # are ready. They cannot set DELIVERED (only buyer confirm or auto-capture can).
    if is_seller and not is_admin:
        if new_status == OrderStatusValues.DELIVERED:
            raise https_fn.HttpsError(
                'permission-denied',
                'Sellers cannot mark orders as delivered. Use per-item status updates or wait for buyer confirmation.'
            )

        # For multi-seller orders, a seller can only affect status if they own ALL items
        # or they should use update_item_status instead
        all_seller_ids = set(item[Fields.SELLER_ID] for item in order_data[Fields.ITEMS])
        if len(all_seller_ids) > 1:
            raise https_fn.HttpsError(
                'failed-precondition',
                'Multi-seller order: use update_item_status to update per-item status instead of order-level status.'
            )

    # SHIPPING APPROVAL GATE: Block shipping if approval is pending
    if new_status == OrderStatusValues.SHIPPED:
        shipping_approval = order_data.get(Fields.SHIPPING_APPROVAL, {})
        approval_status = shipping_approval.get(Fields.STATUS) if isinstance(shipping_approval, dict) else None
        if approval_status == ShippingApprovalStatusValues.PENDING:
            raise https_fn.HttpsError(
                'failed-precondition',
                'Cannot ship: shipping cost approval is pending from buyer.'
            )
        if approval_status == ShippingApprovalStatusValues.REJECTED:
            raise https_fn.HttpsError(
                'failed-precondition',
                'Cannot ship: buyer rejected the shipping cost.'
            )

    # Validate state transition
    if not is_valid_order_status_transition(old_status, new_status):
        raise https_fn.HttpsError(
            'failed-precondition',
            f'Invalid transition from {old_status} to {new_status}'
        )

    # SECURITY FIX: Scope seller actions to their own items only
    if is_seller and not is_admin and new_status == OrderStatusValues.SHIPPED:
        items = order_data.get(Fields.ITEMS, [])
        seller_items_updated = False

        for idx, item in enumerate(items):
            if item.get(Fields.SELLER_ID) == user_id:
                items[idx][Fields.STATUS] = DeliveryStatusValues.SHIPPED
                items[idx][Fields.SHIPPED_AT] = get_server_timestamp()
                if tracking_number:
                    items[idx][Fields.TRACKING_NUMBER] = tracking_number
                    items[idx][Fields.CARRIER] = carrier or ''
                seller_items_updated = True

        if not seller_items_updated:
            raise https_fn.HttpsError('permission-denied', 'No items belong to this seller')

        # Only update order-level status if ALL items from ALL sellers are shipped/delivered
        all_items_shipped = all(
            item.get(Fields.STATUS) in [DeliveryStatusValues.SHIPPED, DeliveryStatusValues.DELIVERED]
            for item in items
        )

        update_data = {
            Fields.ITEMS: items,
            Fields.UPDATED_AT: get_server_timestamp()
        }

        if all_items_shipped:
            update_data[Fields.ORDER_STATUS] = OrderStatusValues.SHIPPED
            update_data[Fields.DELIVERY_STATUS] = DeliveryStatusValues.SHIPPED
            update_data[Fields.SHIPPED_AT] = get_server_timestamp()
            if tracking_number:
                update_data[Fields.TRACKING_NUMBER] = tracking_number
                update_data[Fields.CARRIER] = carrier or ''

        order_ref.update(update_data)

        return create_success_response({
            'newStatus': OrderStatusValues.SHIPPED if all_items_shipped else old_status,
            'allItemsShipped': all_items_shipped
        })

    # Admin path: update order-level status directly
    update_data = {
        Fields.ORDER_STATUS: new_status,
        Fields.UPDATED_AT: get_server_timestamp()
    }

    if new_status == OrderStatusValues.SHIPPED and tracking_number:
        update_data[Fields.TRACKING_NUMBER] = tracking_number
        update_data[Fields.CARRIER] = carrier or ''
        update_data[Fields.DELIVERY_STATUS] = DeliveryStatusValues.SHIPPED
        update_data[Fields.SHIPPED_AT] = get_server_timestamp()

    order_ref.update(update_data)

    return create_success_response({'newStatus': new_status})


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_item_status(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Updates per-item status for multi-product orders (seller or admin only).
    Enables tracking individual items in multi-seller orders.

    Request data:
        orderId: Order ID
        productId: Product ID to update
        newStatus: Target status ('pending' | 'shipped' | 'delivered' | 'refunded')
        trackingNumber: Optional (for shipped status)
        carrier: Optional (for shipped status)

    Returns:
        {success: True, itemStatus: "shipped", allItemsDelivered: bool}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    new_status = data.get('newStatus')
    tracking_number_raw = data.get(Fields.TRACKING_NUMBER)
    carrier_raw = data.get(Fields.CARRIER)

    # Sanitize inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None

    if not order_id or not product_id or not new_status:
        raise https_fn.HttpsError('invalid-argument', 'orderId, productId, and newStatus required')

    # AUDIT FIX: Rate limit item status updates (after input validation)
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action='update_item_status',
        max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    # Validate status value — sellers can only set PENDING or SHIPPED.
    # DELIVERED is set by buyer confirmation or auto-capture cron only.
    # REFUNDED is set by refund_order_item handler only.
    valid_statuses = [OrderStatusValues.PENDING, OrderStatusValues.SHIPPED, OrderStatusValues.DELIVERED, OrderStatusValues.REFUNDED]
    if new_status not in valid_statuses:
        raise https_fn.HttpsError('invalid-argument', f'Status must be one of: {valid_statuses}')

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    # Block updates on archived orders
    if order_data.get('archived', False):
        raise https_fn.HttpsError('failed-precondition', 'Cannot update archived order')

    items = order_data.get(Fields.ITEMS, [])

    # Find the item to update
    item_index = None
    item_seller_id = None
    for idx, item in enumerate(items):
        if item[Fields.PRODUCT_ID] == product_id:
            item_index = idx
            item_seller_id = item[Fields.SELLER_ID]
            break

    if item_index is None:
        raise https_fn.HttpsError('not-found', f'Product {product_id} not found in order')

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_item_seller = (item_seller_id == user_id)

    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError('permission-denied', 'Only the item seller or admin can update item status')

    # SELLER SELF-DELIVERY PREVENTION: Sellers cannot mark their own items as DELIVERED.
    # Only buyer confirmation (capture_payment) or auto-capture cron can set DELIVERED.
    if is_item_seller and not is_admin and new_status == DeliveryStatusValues.DELIVERED:
        raise https_fn.HttpsError(
            'permission-denied',
            'Sellers cannot mark items as delivered. Buyer must confirm receipt.'
        )

    # Per-item state machine validation
    current_item_status = items[item_index].get(Fields.STATUS, DeliveryStatusValues.PENDING)
    valid_item_transitions = {
        DeliveryStatusValues.PENDING: [DeliveryStatusValues.SHIPPED],
        DeliveryStatusValues.SHIPPED: [DeliveryStatusValues.DELIVERED],
        DeliveryStatusValues.DELIVERED: [DeliveryStatusValues.REFUNDED],
        DeliveryStatusValues.REFUNDED: [],  # Terminal
    }
    allowed_next = valid_item_transitions.get(current_item_status, [])
    # Admins can bypass state machine for edge cases
    if not is_admin and new_status not in allowed_next:
        raise https_fn.HttpsError(
            'failed-precondition',
            f'Invalid item status transition from {current_item_status} to {new_status}'
        )

    # Update the item
    items[item_index][Fields.STATUS] = new_status

    if new_status == DeliveryStatusValues.SHIPPED:
        items[item_index][Fields.SHIPPED_AT] = get_server_timestamp()
        if tracking_number:
            items[item_index][Fields.TRACKING_NUMBER] = tracking_number
            items[item_index][Fields.CARRIER] = carrier or ''

    elif new_status == DeliveryStatusValues.DELIVERED:
        items[item_index][Fields.DELIVERED_AT] = get_server_timestamp()
        # Note: confirmedByBuyer is NOT set here; it's only set via capture_payment (buyer action)

    # Check if all items are delivered
    all_items_delivered = all(item.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED for item in items)

    # Update order
    update_data = {
        Fields.ITEMS: items,
        Fields.UPDATED_AT: get_server_timestamp()
    }

    # If all items delivered, update order status
    if all_items_delivered and order_data.get(Fields.ORDER_STATUS) != OrderStatus.DELIVERED:
        update_data[Fields.ORDER_STATUS] = OrderStatus.DELIVERED
        update_data[Fields.DELIVERY_STATUS] = DeliveryStatus.DELIVERED

    order_ref.update(update_data)

    return create_success_response({
        'itemStatus': new_status,
        'allItemsDelivered': all_items_delivered
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def cancel_order(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Cancels an order and issues refund if payment was captured.

    Request data:
        orderId: Order ID
        reason: Cancellation reason

    Returns:
        {success: True, refunded: bool}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    # AUDIT FIX: Rate limit order cancellations (security-critical)
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action='cancel_order',
        max_requests=5, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    reason_raw = data.get(ApiKeys.REASON, 'User requested cancellation')

    # Import validation functions
    from utils import sanitized_text

    # Sanitize reason input to prevent XSS
    reason = sanitized_text(reason_raw)[:500]  # Max 500 chars

    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    # Block updates on archived orders\n    if order_data.get('archived', False):\n        raise https_fn.HttpsError('failed-precondition', 'Cannot cancel archived order')

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_buyer = (order_data.get(Fields.USER_ID) == user_id)

    # Check if user is seller for any item
    is_seller = any(item[Fields.SELLER_ID] == user_id for item in order_data[Fields.ITEMS])

    if not (is_admin or is_buyer or is_seller):
        raise https_fn.HttpsError('permission-denied', 'Only buyer, seller, or admin can cancel order')

    # SECURITY FIX: Use proper state machine validation instead of blocklist
    current_status = order_data[Fields.ORDER_STATUS]

    if not is_valid_order_status_transition(current_status, OrderStatusValues.CANCELLED):
        raise https_fn.HttpsError('failed-precondition', f'Cannot cancel order with status: {current_status}')

    # AUDIT FIX (RC1): Use Firestore transaction to atomically check payment_status
    # and set a 'cancelling' lock — prevents race condition with capture_payment
    from firebase_admin import firestore as fs
    transaction = get_db().transaction()

    @fs.transactional
    def lock_for_cancel(txn):
        fresh_doc = order_ref.get(transaction=txn)
        fresh_data = fresh_doc.to_dict()
        fresh_payment_status = fresh_data.get(Fields.PAYMENT_STATUS)

        # Block cancel if capture is already in progress
        if fresh_payment_status == 'capturing':
            raise https_fn.HttpsError(
                'failed-precondition',
                'Cannot cancel order — payment capture in progress'
            )

        # Re-validate order status hasn't changed concurrently
        if fresh_data.get(Fields.ORDER_STATUS) != current_status:
            raise https_fn.HttpsError(
                'failed-precondition',
                f'Order status changed concurrently (now: {fresh_data.get(Fields.ORDER_STATUS)})'
            )

        # Set cancelling lock to block concurrent captures
        txn.update(order_ref, {
            Fields.PAYMENT_STATUS: 'cancelling',
            Fields.UPDATED_AT: get_server_timestamp(),
        })
        return fresh_payment_status

    payment_status = lock_for_cancel(transaction)

    # Handle payment based on current payment status
    refunded = False
    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    new_payment_status = payment_status

    if payment_status == PaymentStatusValues.CAPTURED and payment_intent_id:
        # Payment was captured — issue refund
        try:
            stripe.Refund.create(
                payment_intent=payment_intent_id,
                reason='requested_by_customer',
                metadata={'orderId': order_id},
                idempotency_key=f'refund_{order_id}'
            )
            refunded = True
            new_payment_status = PaymentStatusValues.REFUNDED
        except stripe.error.StripeError as e:
            print(f'Refund failed: {str(e)}')

    elif payment_status == PaymentStatusValues.AUTHORIZED and payment_intent_id:
        # CRITICAL FIX: Payment was authorized but not captured — cancel the PI to release buyer funds
        try:
            stripe.PaymentIntent.cancel(
                payment_intent_id,
                cancellation_reason='requested_by_customer',
            )
            new_payment_status = PaymentStatusValues.CANCELLED
        except stripe.error.StripeError as e:
            print(f'PaymentIntent cancel failed: {str(e)}')

    # AUDIT FIX: Atomic batch — stock restore + final cancel status in ONE commit
    # Prevents double-restore if process crashes between stock restore and status update
    cancel_batch = get_db().batch()

    if not order_data.get(Fields.STOCK_RESTORED, False):
        for item in order_data[Fields.ITEMS]:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
            cancel_batch.update(product_ref, {
                Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY]),
                Fields.UPDATED_AT: get_server_timestamp()
            })

    cancel_batch.update(order_ref, {
        Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
        Fields.PAYMENT_STATUS: new_payment_status,
        Fields.CANCELLED_BY: user_id,
        Fields.CANCELLED_AT: get_server_timestamp(),
        Fields.CANCELLATION_REASON: reason,
        Fields.STOCK_RESTORED: True,
        Fields.UPDATED_AT: get_server_timestamp()
    })
    cancel_batch.commit()

    return create_success_response({'refunded': refunded})


@https_fn.on_call(**DEFAULT_OPTIONS)
def refund_order_item(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Refunds a specific item from a multi-item order (partial refund).

    Features:
    - Calculates proportional refund amount (item + proportional tax/shipping)
    - Restores stock for refunded item
    - Updates item status to 'refunded'
    - Reverses seller transfer if payout already completed

    Request data:
        orderId: Order ID
        productId: Product ID to refund
        reason: Refund reason (optional)

    Returns:
        {success: True, refundAmount: float, refundId: str}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    # AUDIT FIX: Rate limit refund requests (security-critical)
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action='refund_order_item',
        max_requests=5, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    reason_raw = data.get(ApiKeys.REASON, 'Item refund requested')

    # Import validation functions
    from utils import sanitized_text

    # Sanitize reason input
    reason = sanitized_text(reason_raw)[:500]

    if not order_id or not product_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId and productId required')

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    # is_buyer = (order_data.get(Fields.USER_ID) == user_id)  # REMOVED: Buyers cannot self-refund directly

    # Check if user is seller for the specific item
    item_seller_id = None
    for item in order_data.get(Fields.ITEMS, []):
        if item[Fields.PRODUCT_ID] == product_id:
            item_seller_id = item[Fields.SELLER_ID]
            break

    is_item_seller = (item_seller_id == user_id)

    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError('permission-denied', 'Only seller of the item or admin can issue refunds')

    # Check if payment was captured
    payment_status = order_data.get(Fields.PAYMENT_STATUS)
    if payment_status != PaymentStatusValues.CAPTURED:
        raise https_fn.HttpsError('failed-precondition', 'Cannot refund uncaptured payment')

    # Find the item
    items = order_data.get(Fields.ITEMS, [])
    item_index = None
    item_data = None

    for idx, item in enumerate(items):
        if item[Fields.PRODUCT_ID] == product_id:
            item_index = idx
            item_data = item
            break

    if item_index is None:
        raise https_fn.HttpsError('not-found', f'Product {product_id} not found in order')

    # Check if item already refunded
    if item_data.get(Fields.STATUS) == DeliveryStatusValues.REFUNDED:
        raise https_fn.HttpsError('failed-precondition', 'Item already refunded')

    # Calculate refund amount (all in cents to avoid float errors)
    item_price_cents = round(item_data[Fields.PRICE] * 100)
    item_quantity = item_data[Fields.QUANTITY]
    item_subtotal_cents = item_price_cents * item_quantity

    # Calculate proportional tax and shipping
    # CRITICAL FIX: Field name is 'subtotalCents' not 'subtotalAmountCents'
    order_subtotal_cents = order_data.get(Fields.SUBTOTAL_CENTS, 0)
    order_tax_cents = order_data.get(Fields.TAX_AMOUNT_CENTS, 0)
    order_shipping_cents = order_data.get(Fields.SHIPPING_COST_CENTS, 0)

    if order_subtotal_cents > 0:
        proportion = item_subtotal_cents / order_subtotal_cents
        proportional_tax_cents = round(order_tax_cents * proportion)
        proportional_shipping_cents = round(order_shipping_cents * proportion)
    else:
        proportional_tax_cents = 0
        proportional_shipping_cents = 0

    refund_amount_cents = item_subtotal_cents + proportional_tax_cents + proportional_shipping_cents

    # Create Stripe refund
    payment_intent_id = order_data.get('stripePaymentIntentId')
    if not payment_intent_id:
        raise https_fn.HttpsError('failed-precondition', 'No payment intent found')

    try:
        refund = stripe.Refund.create(
            payment_intent=payment_intent_id,
            amount=refund_amount_cents,
            reason='requested_by_customer',
            metadata={
                'orderId': order_id,
                'productId': product_id,
                'itemSubtotal': item_subtotal_cents,
                'proportionalTax': proportional_tax_cents,
                'proportionalShipping': proportional_shipping_cents
            },
            idempotency_key=f'refund_{order_id}_{product_id}'
        )
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', f'Refund failed: {str(e)}') from e

    # Restore stock for this item
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_ref.update({
        Fields.STOCK_QUANTITY: get_firestore().Increment(item_quantity),
        Fields.UPDATED_AT: get_server_timestamp()
    })

    # Update item status
    items[item_index][Fields.STATUS] = DeliveryStatusValues.REFUNDED
    items[item_index][Fields.REFUNDED_AT] = get_server_timestamp()
    items[item_index][Fields.REFUND_REASON] = reason
    items[item_index][Fields.REFUND_AMOUNT_CENTS] = refund_amount_cents
    items[item_index][Fields.REFUND_ID] = refund.id

    # Reverse seller transfer if payout exists
    seller_id = item_data[Fields.SELLER_ID]
    payout_query = get_db().collection(Collections.PAYOUTS).where(
        Fields.ORDER_ID, '==', order_id
    ).where(
        Fields.SELLER_ID, '==', seller_id
    ).where(
        Fields.STATUS, '==', PayoutStatusValues.COMPLETED
    ).limit(1).get()

    if len(payout_query) > 0:
        payout_doc = payout_query[0]
        payout_data = payout_doc.to_dict()

        # Calculate proportional reversal amount
        seller_total_cents = payout_data.get(Fields.AMOUNT_CENTS, 0)
        payout_data.get(Fields.PLATFORM_FEE_CENTS, 0)

        if seller_total_cents > 0:
            seller_proportion = item_subtotal_cents / seller_total_cents
            reversal_amount_cents = round(payout_data.get(Fields.NET_AMOUNT_CENTS, 0) * seller_proportion)

            try:
                stripe_transfer_id = payout_data.get(Fields.STRIPE_TRANSFER_ID)
                if stripe_transfer_id:
                    reversal = stripe.Transfer.create_reversal(
                        stripe_transfer_id,
                        amount=reversal_amount_cents,
                        metadata={
                            'orderId': order_id,
                            'productId': product_id,
                            'reason': 'item_refund'
                        }
                    )

                    # Log partial reversal
                    payout_doc.reference.update({
                        Fields.PARTIAL_REVERSALS: get_firestore().ArrayUnion([{
                            Fields.REVERSAL_ID: reversal.id,
                            Fields.AMOUNT_CENTS: reversal_amount_cents,
                            Fields.PRODUCT_ID: product_id,
                            Fields.CREATED_AT: get_server_timestamp()
                        }]),
                        Fields.UPDATED_AT: get_server_timestamp()
                    })
            except stripe.error.StripeError as e:
                # Log failed reversal but don't fail the refund
                print(f'Transfer reversal failed for {seller_id}: {str(e)}')

    # Update order
    order_ref.update({
        Fields.ITEMS: items,
        Fields.UPDATED_AT: get_server_timestamp()
    })

    return create_success_response({
        'refundAmount': refund_amount_cents / 100,  # Return in dollars
        'refundId': refund.id
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def approve_shipping_cost(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Buyer approves updated shipping cost.

    Request data:
        orderId: Order ID
        approved: boolean

    Returns:
        {success: True}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    approved = data.get('approved', False)

    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    # Verify buyer
    if order_data[Fields.USER_ID] != user_id:
        raise https_fn.HttpsError('permission-denied', 'Not your order')

    shipping_approval = order_data.get(Fields.SHIPPING_APPROVAL, {})

    if shipping_approval.get(Fields.STATUS) != ShippingApprovalStatusValues.PENDING:
        raise https_fn.HttpsError('failed-precondition', 'No pending shipping approval')

    if approved:
        # Update order with new shipping cost (all amounts in cents)
        new_shipping_cost_cents = round(shipping_approval.get('actualCost', 0) * 100)
        old_shipping_cost_cents = order_data.get(Fields.SHIPPING_COST_CENTS, 0)

        # SECURITY: Validate shipping cost bounds (max +20% of original estimate)
        from config import SHIPPING_APPROVAL_THRESHOLD
        max_allowed_cents = round(old_shipping_cost_cents * (1 + SHIPPING_APPROVAL_THRESHOLD))
        if old_shipping_cost_cents > 0 and new_shipping_cost_cents > max_allowed_cents:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'Shipping cost ${new_shipping_cost_cents / 100:.2f} exceeds maximum allowed '
                f'(+{int(SHIPPING_APPROVAL_THRESHOLD * 100)}% of original ${old_shipping_cost_cents / 100:.2f}). '
                f'Contact admin for manual approval.'
            )

        # Validate authorization is still valid before modifying payment
        expires_at = order_data.get(Fields.EXPIRES_AT)
        if expires_at and isinstance(expires_at, datetime) and expires_at < datetime.now():
            raise https_fn.HttpsError(
                'failed-precondition',
                'Payment authorization has expired. Order must be re-created.'
            )

        difference_cents = new_shipping_cost_cents - old_shipping_cost_cents
        new_total_cents = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) + difference_cents

        order_ref.update({
            Fields.SHIPPING_COST_CENTS: new_shipping_cost_cents,
            Fields.TOTAL_AMOUNT_CENTS: new_total_cents,
            f'{Fields.SHIPPING_APPROVAL}.{Fields.STATUS}': ShippingApprovalStatusValues.APPROVED,
            f'{Fields.SHIPPING_APPROVAL}.{Fields.RESPONDED_AT}': get_server_timestamp(),
            Fields.UPDATED_AT: get_server_timestamp()
        })

        # Charge additional amount if needed
        if difference_cents > 0:
            payment_intent_id = order_data.get('stripePaymentIntentId')
            if payment_intent_id:
                try:
                    # Update payment intent amount (already in cents)
                    stripe.PaymentIntent.modify(
                        payment_intent_id,
                        amount=new_total_cents
                    )
                except stripe.error.StripeError as e:
                    print(f'Failed to update payment amount: {str(e)}')
    else:
        # Buyer rejected, cancel order
        cancel_payment_status = order_data.get(Fields.PAYMENT_STATUS)

        # CRITICAL FIX: Cancel PaymentIntent to release buyer funds
        payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
        if payment_intent_id and cancel_payment_status == PaymentStatusValues.AUTHORIZED:
            try:
                stripe.PaymentIntent.cancel(
                    payment_intent_id,
                    cancellation_reason='requested_by_customer',
                )
                cancel_payment_status = PaymentStatusValues.CANCELLED
            except stripe.error.StripeError as e:
                print(f'PaymentIntent cancel failed on shipping rejection: {str(e)}')

        order_ref.update({
            f'{Fields.SHIPPING_APPROVAL}.{Fields.STATUS}': ShippingApprovalStatusValues.REJECTED,
            f'{Fields.SHIPPING_APPROVAL}.{Fields.RESPONDED_AT}': get_server_timestamp(),
            Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
            Fields.PAYMENT_STATUS: cancel_payment_status,
            Fields.CANCELLATION_REASON: 'Buyer rejected shipping cost',
            Fields.STOCK_RESTORED: True,
            Fields.UPDATED_AT: get_server_timestamp()
        })

        # Restore stock using atomic Increment (prevents race conditions)
        for item in order_data[Fields.ITEMS]:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
            product_ref.update({
                Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY])
            })

    return create_success_response({'approved': approved})


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_shipping_cost(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Seller updates actual shipping cost after dispatch.
    Triggers buyer approval if increase > 20% of original estimate.

    Migrated from main_old.py.backup to modular handler.

    Request data:
        orderId: Order ID
        newShippingCost: Actual shipping cost in dollars
        reason: Explanation for cost change

    Returns:
        {success: True, approvalRequired: bool}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    # AUDIT FIX: Rate limit shipping cost updates
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action='update_shipping_cost',
        max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    user_id = req.auth.uid
    data = req.data

    from config import SHIPPING_APPROVAL_THRESHOLD
    from utils import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    new_shipping_cost = data.get('newShippingCost')
    reason_raw = data.get(ApiKeys.REASON, 'Actual shipping cost differs from estimate')
    reason = sanitized_text(reason_raw)[:500] if reason_raw else 'Actual shipping cost differs from estimate'

    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    if new_shipping_cost is None or not isinstance(new_shipping_cost, (int, float)) or new_shipping_cost < 0:
        raise https_fn.HttpsError('invalid-argument', 'newShippingCost must be a non-negative number')

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')

    order_data = order_doc.to_dict()

    # Verify seller owns at least one item in the order
    seller_items = [item for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.SELLER_ID) == user_id]
    if not seller_items:
        raise https_fn.HttpsError('permission-denied', 'You do not have items in this order')

    # Only allow update on confirmed/processing orders
    if order_data.get(Fields.ORDER_STATUS) not in [OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING]:
        raise https_fn.HttpsError('failed-precondition', 'Can only update shipping on confirmed/processing orders')

    # Only allow update on authorized payment (not yet captured)
    if order_data.get(Fields.PAYMENT_STATUS) != PaymentStatusValues.AUTHORIZED:
        raise https_fn.HttpsError('failed-precondition', 'Payment must be in authorized state')

    original_shipping_cents = order_data.get(Fields.SHIPPING_COST_CENTS, 0)
    new_shipping_cents = round(new_shipping_cost * 100)

    # Check if increase exceeds threshold (20%)
    approval_required = False
    if original_shipping_cents > 0:
        increase_ratio = (new_shipping_cents - original_shipping_cents) / original_shipping_cents
        if increase_ratio > SHIPPING_APPROVAL_THRESHOLD:
            approval_required = True

    if approval_required:
        # Set pending approval — buyer must approve before shipping can proceed
        order_ref.update({
            Fields.SHIPPING_APPROVAL: {
                Fields.STATUS: ShippingApprovalStatusValues.PENDING,
                Fields.ACTUAL_COST: new_shipping_cost,
                'originalCostCents': original_shipping_cents,
                'newCostCents': new_shipping_cents,
                'reason': reason,
                'requestedBy': user_id,
                'requestedAt': get_server_timestamp(),
            },
            Fields.SHIPPING_APPROVAL_STATUS: ShippingApprovalStatusValues.PENDING,
            Fields.SHIPPING_APPROVAL_REQUIRED: True,
            Fields.UPDATED_AT: get_server_timestamp(),
        })
    else:
        # Auto-approve small changes — update shipping cost directly
        difference_cents = new_shipping_cents - original_shipping_cents
        new_total_cents = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) + difference_cents

        update_data = {
            Fields.SHIPPING_COST_CENTS: new_shipping_cents,
            Fields.TOTAL_AMOUNT_CENTS: new_total_cents,
            Fields.ACTUAL_SHIPPING: new_shipping_cost,
            Fields.UPDATED_AT: get_server_timestamp(),
        }

        # Update Stripe PaymentIntent amount if cost changed
        if difference_cents != 0:
            payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
            if payment_intent_id:
                try:
                    import stripe as _stripe
                    _stripe.PaymentIntent.modify(payment_intent_id, amount=new_total_cents)
                except Exception as e:
                    print(f'Failed to update Stripe PI amount: {str(e)}')

        order_ref.update(update_data)

    return create_success_response({'approvalRequired': approval_required})


@firestore_fn.on_document_updated(document="orders/{orderId}", **DEFAULT_OPTIONS)
def on_order_status_changed(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Sends email notifications when order status changes.
    """
    order_id = event.params['orderId']
    before_data = event.data.before.to_dict()
    after_data = event.data.after.to_dict()

    if not before_data or not after_data:
        return

    old_status = before_data.get(Fields.ORDER_STATUS)
    new_status = after_data.get(Fields.ORDER_STATUS)

    if old_status == new_status:
        return

    # Send notification emails based on status change
    user_id = after_data.get(Fields.USER_ID)

    # CRITICAL FIX: Fetch actual buyer email from user document (not user_id!)
    buyer_email = after_data.get(Fields.CUSTOMER_EMAIL)
    if not buyer_email:
        try:
            from firebase_admin import firestore as _fs
            _db = _fs.client()
            buyer_doc = _db.collection(Collections.USERS).document(user_id).get()
            if buyer_doc.exists:
                buyer_email = buyer_doc.to_dict().get(Fields.EMAIL)
        except Exception as e:
            print(f'Failed to fetch buyer email for order {order_id}: {str(e)}')

    if not buyer_email:
        print(f'⚠️ No email found for user {user_id}, skipping notification for order {order_id}')
        return

    try:
        if new_status == OrderStatusValues.SHIPPED:
            tracking_number = after_data.get(Fields.TRACKING_NUMBER, 'N/A')
            carrier = after_data.get(Fields.CARRIER, 'N/A')

            # Email buyer
            send_email(
                to_email=buyer_email,
                subject='Your Order Has Shipped - Origna',
                html_content=f'''
                <h2>Your order has been shipped!</h2>
                <p>Order ID: {order_id}</p>
                <p>Tracking Number: {tracking_number}</p>
                <p>Carrier: {carrier}</p>
                <p>You can track your order at: https://orignagta.ca/orders/{order_id}</p>
                '''
            )

            # Also notify sellers that shipment confirmed
            seller_ids = set(item.get(Fields.SELLER_ID) for item in after_data.get(Fields.ITEMS, []))
            for sid in seller_ids:
                try:
                    seller_doc = _db.collection(Collections.USERS).document(sid).get()
                    if seller_doc.exists:
                        seller_email = seller_doc.to_dict().get(Fields.EMAIL)
                        if seller_email:
                            send_email(
                                to_email=seller_email,
                                subject=f'Order {order_id[:8]} Shipped Successfully',
                                html_content=f'''
                                <h2>Shipment Confirmed</h2>
                                <p>Order ID: {order_id}</p>
                                <p>Tracking: {tracking_number}</p>
                                <p>Carrier: {carrier}</p>
                                '''
                            )
                except Exception:
                    pass

        elif new_status == OrderStatusValues.DELIVERED:
            # Email buyer to confirm receipt
            send_email(
                to_email=buyer_email,
                subject='Order Delivered - Please Confirm Receipt',
                html_content=f'''
                <h2>Your order has been delivered!</h2>
                <p>Order ID: {order_id}</p>
                <p>Please confirm receipt to release payment to sellers:</p>
                <a href="https://orignagta.ca/orders/{order_id}">Confirm Receipt</a>
                <p><strong>Note:</strong> Payment will be auto-released after 7 days if not confirmed.</p>
                '''
            )

        elif new_status == OrderStatusValues.CANCELLED:
            reason = after_data.get(Fields.CANCELLATION_REASON, 'Unknown')
            send_email(
                to_email=buyer_email,
                subject='Order Cancelled - Origna',
                html_content=f'''
                <h2>Your order has been cancelled</h2>
                <p>Order ID: {order_id}</p>
                <p>Reason: {reason}</p>
                <p>If payment was captured, a refund will be issued within 5-10 business days.</p>
                '''
            )

    except Exception as e:
        print(f'Failed to send order status email for order {order_id}: {str(e)}')
