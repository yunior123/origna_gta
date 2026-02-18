"""
Order Lifecycle Management Handlers
- Order receipt confirmation
- Order status updates
- Shipping approval workflow
- Order cancellation
"""

import logging
from datetime import UTC, datetime
from typing import Any

import stripe
from firebase_functions import firestore_fn, https_fn

from config import get_stripe_secret_key
from schema_constants import (
    ApiKeys,
    BusinessRules,
    Collections,
    DeliveryItemStatusTransitions,
    DeliveryStatusValues,
    Fields,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ShippingApprovalStatusValues,
    UserRoleValues,
)
from services.email_service import (
    _t as _email_t,
)
from services.email_service import (
    get_order_cancelled_email,
    get_order_delivered_email,
    get_order_in_transit_email,
    get_order_partially_refunded_email,
    get_order_processing_email,
    get_order_refunded_email,
    get_order_shipped_email,
    get_seller_notification_email,
    send_email,
)
from utils.function_options import DEFAULT_OPTIONS, FIRESTORE_TRIGGER_OPTIONS
from utils.helpers import create_success_response, is_valid_order_status_transition

logger = logging.getLogger(__name__)

# stripe.api_key = STRIPE_SECRET_KEY  # Removed global assignment
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
    # NOTE: Import the undecorated _capture_payment_impl to avoid calling the
    # @on_call wrapper (which expects a Flask Request, not a CallableRequest).
    from handlers.payment_stripe import _capture_payment_impl

    return _capture_payment_impl(req)


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils.helpers import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    new_status = data.get(ApiKeys.NEW_STATUS)
    tracking_number_raw = data.get(Fields.TRACKING_NUMBER)
    carrier_raw = data.get(Fields.CARRIER)

    # Sanitize tracking number and carrier inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None

    if not order_id or not new_status:
        raise https_fn.HttpsError("invalid-argument", "orderId and newStatus required")

    # AUDIT FIX: Rate limit order status updates (after input validation)
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="update_order_status", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()
    old_status = order_data[Fields.ORDER_STATUS]

    # Block updates on archived orders
    if order_data.get(Fields.ARCHIVED, False):
        raise https_fn.HttpsError("failed-precondition", "Cannot update archived order")

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])

    # Check if user is seller for any item in order
    seller_items = [item for item in order_data[Fields.ITEMS] if item[Fields.SELLER_ID] == user_id]
    is_seller = len(seller_items) > 0

    if not (is_admin or is_seller):
        raise https_fn.HttpsError("permission-denied", "Only seller or admin can update order status")

    # MULTI-SELLER ISOLATION: Sellers can only update to SHIPPED if ALL their items
    # are ready. They cannot set DELIVERED (only buyer confirm or auto-capture can).
    if is_seller and not is_admin:
        if new_status == OrderStatusValues.DELIVERED:
            raise https_fn.HttpsError(
                "permission-denied",
                "Sellers cannot mark orders as delivered. Use per-item status updates or wait for buyer confirmation.",
            )

        # For multi-seller orders, a seller can only affect status if they own ALL items
        # or they should use update_item_status instead
        all_seller_ids = set(item[Fields.SELLER_ID] for item in order_data[Fields.ITEMS])
        if len(all_seller_ids) > 1:
            raise https_fn.HttpsError(
                "failed-precondition",
                "Multi-seller order: use update_item_status to update per-item status instead of order-level status.",
            )

    # SHIPPING APPROVAL GATE: Block shipping if approval is pending
    if new_status == OrderStatusValues.SHIPPED:
        shipping_approval = order_data.get(Fields.SHIPPING_APPROVAL, {})
        approval_status = shipping_approval.get(Fields.STATUS) if isinstance(shipping_approval, dict) else None
        if approval_status == ShippingApprovalStatusValues.PENDING:
            raise https_fn.HttpsError(
                "failed-precondition", "Cannot ship: shipping cost approval is pending from buyer."
            )
        if approval_status == ShippingApprovalStatusValues.REJECTED:
            raise https_fn.HttpsError("failed-precondition", "Cannot ship: buyer rejected the shipping cost.")

    # Validate state transition
    if not is_valid_order_status_transition(old_status, new_status):
        raise https_fn.HttpsError("failed-precondition", f"Invalid transition from {old_status} to {new_status}")

    # SECURITY FIX: Scope seller actions to their own items only
    if is_seller and not is_admin and new_status == OrderStatusValues.SHIPPED:
        # Use Firestore transaction to prevent concurrent seller updates from
        # overwriting each other's item status changes
        @get_firestore().transactional
        def _update_seller_items(transaction):
            fresh_doc = order_ref.get(transaction=transaction)
            if not fresh_doc.exists:
                return None, "Order not found"
            fresh_data = fresh_doc.to_dict()

            items = fresh_data.get(Fields.ITEMS, [])
            seller_items_updated = False
            # NOTE: Use actual datetime instead of SERVER_TIMESTAMP sentinel inside arrays.
            # Firestore SDK cannot serialize SERVER_TIMESTAMP sentinels nested in arrays.
            now_utc = datetime.now(UTC)

            for idx, item in enumerate(items):
                if item.get(Fields.SELLER_ID) == user_id:
                    items[idx][Fields.STATUS] = DeliveryStatusValues.SHIPPED
                    items[idx][Fields.SHIPPED_AT] = now_utc
                    if tracking_number:
                        items[idx][Fields.TRACKING_NUMBER] = tracking_number
                        items[idx][Fields.CARRIER] = carrier or ""
                    seller_items_updated = True

            if not seller_items_updated:
                return None, "No items belong to this seller"

            # Only update order-level status if ALL items from ALL sellers are shipped/delivered
            all_shipped = all(
                item.get(Fields.STATUS) in [DeliveryStatusValues.SHIPPED, DeliveryStatusValues.DELIVERED]
                for item in items
            )

            update_data = {Fields.ITEMS: items, Fields.UPDATED_AT: get_server_timestamp()}

            if all_shipped:
                update_data[Fields.ORDER_STATUS] = OrderStatusValues.SHIPPED
                update_data[Fields.SHIPPED_AT] = get_server_timestamp()
                if tracking_number:
                    update_data[Fields.TRACKING_NUMBER] = tracking_number
                    update_data[Fields.CARRIER] = carrier or ""

            transaction.update(order_ref, update_data)
            return all_shipped, None

        all_items_shipped, error_msg = _update_seller_items(get_db().transaction())
        if error_msg:
            raise https_fn.HttpsError("permission-denied", error_msg)

        return create_success_response(
            {
                ApiKeys.NEW_STATUS: OrderStatusValues.SHIPPED if all_items_shipped else old_status,
                ApiKeys.ALL_ITEMS_SHIPPED: all_items_shipped,
            }
        )

    # Admin path: update order-level status directly
    update_data = {Fields.ORDER_STATUS: new_status, Fields.UPDATED_AT: get_server_timestamp()}

    if new_status == OrderStatusValues.SHIPPED and tracking_number:
        update_data[Fields.TRACKING_NUMBER] = tracking_number
        update_data[Fields.CARRIER] = carrier or ""
        update_data[Fields.SHIPPED_AT] = get_server_timestamp()

    order_ref.update(update_data)

    return create_success_response({ApiKeys.NEW_STATUS: new_status})


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils.helpers import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    new_status = data.get(ApiKeys.NEW_STATUS)
    tracking_number_raw = data.get(Fields.TRACKING_NUMBER)
    carrier_raw = data.get(Fields.CARRIER)

    # Sanitize inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None

    if not order_id or not product_id or not new_status:
        raise https_fn.HttpsError("invalid-argument", "orderId, productId, and newStatus required")

    # AUDIT FIX: Rate limit item status updates (after input validation)
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="update_item_status", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Validate status value — sellers can only set PENDING or SHIPPED.
    # DELIVERED is set by buyer confirmation or auto-capture cron only.
    # REFUNDED is set by refund_order_item handler only.
    # NOTE: Item statuses use DeliveryStatusValues, NOT OrderStatusValues.
    valid_statuses = [
        DeliveryStatusValues.PENDING,
        DeliveryStatusValues.SHIPPED,
        DeliveryStatusValues.DELIVERED,
        DeliveryStatusValues.REFUNDED,
    ]
    if new_status not in valid_statuses:
        raise https_fn.HttpsError("invalid-argument", f"Status must be one of: {valid_statuses}")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # Block updates on archived orders
    if order_data.get(Fields.ARCHIVED, False):
        raise https_fn.HttpsError("failed-precondition", "Cannot update archived order")

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
        raise https_fn.HttpsError("not-found", f"Product {product_id} not found in order")

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_item_seller = item_seller_id == user_id

    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError("permission-denied", "Only the item seller or admin can update item status")

    # Block suspended sellers from updating order status
    if not is_admin and user_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("permission-denied", "Suspended sellers cannot update order status")

    # SELLER SELF-DELIVERY PREVENTION: Sellers cannot mark their own items as DELIVERED.
    # Only buyer confirmation (capture_payment) or auto-capture cron can set DELIVERED.
    if is_item_seller and not is_admin and new_status == DeliveryStatusValues.DELIVERED:
        raise https_fn.HttpsError(
            "permission-denied", "Sellers cannot mark items as delivered. Buyer must confirm receipt."
        )

    # Per-item state machine validation (centralized in schema_constants.py)
    current_item_status = items[item_index].get(Fields.STATUS, DeliveryStatusValues.PENDING)
    allowed_next = DeliveryItemStatusTransitions.VALID_TRANSITIONS.get(current_item_status, [])
    # Admins can bypass state machine for edge cases
    if not is_admin and new_status not in allowed_next:
        raise https_fn.HttpsError(
            "failed-precondition", f"Invalid item status transition from {current_item_status} to {new_status}"
        )

    # Update the item atomically using a Firestore transaction to prevent lost updates
    # when multiple sellers update different items in the same order concurrently.
    from firebase_admin import firestore as fs

    txn = get_db().transaction()

    @fs.transactional
    def update_item_atomically(transaction):
        fresh_doc = order_ref.get(transaction=transaction)
        if not fresh_doc.exists:
            raise https_fn.HttpsError("not-found", "Order not found")

        fresh_data = fresh_doc.to_dict()
        fresh_items = fresh_data.get(Fields.ITEMS, [])

        # Re-find the item index in fresh data (may have shifted)
        fresh_item_index = None
        for idx, item in enumerate(fresh_items):
            if item[Fields.PRODUCT_ID] == product_id:
                fresh_item_index = idx
                break

        if fresh_item_index is None:
            raise https_fn.HttpsError("not-found", f"Product {product_id} not found in order")

        # Re-validate state transition against fresh data (centralized)
        fresh_item_status = fresh_items[fresh_item_index].get(Fields.STATUS, DeliveryStatusValues.PENDING)
        allowed_next = DeliveryItemStatusTransitions.VALID_TRANSITIONS.get(fresh_item_status, [])
        if not is_admin and new_status not in allowed_next:
            raise https_fn.HttpsError(
                "failed-precondition", f"Invalid item status transition from {fresh_item_status} to {new_status}"
            )

        # Apply the update
        fresh_items[fresh_item_index][Fields.STATUS] = new_status
        now_utc = datetime.now(UTC)

        if new_status == DeliveryStatusValues.SHIPPED:
            fresh_items[fresh_item_index][Fields.SHIPPED_AT] = now_utc
            if tracking_number:
                fresh_items[fresh_item_index][Fields.TRACKING_NUMBER] = tracking_number
                fresh_items[fresh_item_index][Fields.CARRIER] = carrier or ""
        elif new_status == DeliveryStatusValues.DELIVERED:
            fresh_items[fresh_item_index][Fields.DELIVERED_AT] = now_utc

        # Check aggregate statuses
        all_delivered = all(it.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED for it in fresh_items)
        all_shipped = all(
            it.get(Fields.STATUS) in [DeliveryStatusValues.SHIPPED, DeliveryStatusValues.DELIVERED]
            for it in fresh_items
        )

        update_data = {Fields.ITEMS: fresh_items, Fields.UPDATED_AT: get_server_timestamp()}

        current_order_status = fresh_data.get(Fields.ORDER_STATUS)

        if all_delivered and current_order_status != OrderStatusValues.DELIVERED:
            update_data[Fields.ORDER_STATUS] = OrderStatusValues.DELIVERED
        elif (
            all_shipped
            and not all_delivered
            and current_order_status in [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED]
        ):
            update_data[Fields.ORDER_STATUS] = OrderStatusValues.SHIPPED

        transaction.update(order_ref, update_data)
        return all_delivered, all_shipped

    all_items_delivered, all_items_shipped = update_item_atomically(txn)

    return create_success_response(
        {
            ApiKeys.ITEM_STATUS: new_status,
            ApiKeys.ALL_ITEMS_DELIVERED: all_items_delivered,
            ApiKeys.ALL_ITEMS_SHIPPED: all_items_shipped,
        }
    )


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # AUDIT FIX: Rate limit order cancellations (security-critical)
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="cancel_order", max_requests=5, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    reason_raw = data.get(ApiKeys.REASON, "User requested cancellation")

    # Import validation functions
    from utils.helpers import sanitized_text

    # Sanitize reason input to prevent XSS
    reason = sanitized_text(reason_raw)[:500]  # Max 500 chars

    if not order_id:
        raise https_fn.HttpsError("invalid-argument", "orderId required")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # Block updates on archived orders
    if order_data.get(Fields.ARCHIVED, False):
        raise https_fn.HttpsError("failed-precondition", "Cannot cancel archived order")

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    is_buyer = order_data.get(Fields.USER_ID) == user_id

    # Check if user is seller for any item
    seller_items = [item for item in order_data[Fields.ITEMS] if item[Fields.SELLER_ID] == user_id]
    is_seller = len(seller_items) > 0

    if not (is_admin or is_buyer or is_seller):
        raise https_fn.HttpsError("permission-denied", "Only buyer, seller, or admin can cancel order")

    # AUDIT FIX (C2): Sellers can only cancel orders where they own ALL items.
    # In multi-seller orders, sellers must use item-level refund instead.
    if is_seller and not is_buyer and not is_admin:
        all_items = order_data[Fields.ITEMS]
        if len(seller_items) < len(all_items):
            raise https_fn.HttpsError(
                "permission-denied",
                "Cannot cancel a multi-seller order. Use item refund to cancel your items only.",
            )

    # SECURITY FIX: Use proper state machine validation instead of blocklist
    current_status = order_data[Fields.ORDER_STATUS]

    if not is_valid_order_status_transition(current_status, OrderStatusValues.CANCELLED):
        raise https_fn.HttpsError("failed-precondition", f"Cannot cancel order with status: {current_status}")

    # AUDIT FIX (RC1): Use Firestore transaction to atomically check payment_status
    # and set a 'cancelling' lock — prevents race condition with capture_payment
    from firebase_admin import firestore as fs

    transaction = get_db().transaction()

    @fs.transactional
    def lock_for_cancel(txn):
        fresh_doc = order_ref.get(transaction=txn)
        fresh_data = fresh_doc.to_dict()
        fresh_payment_status = fresh_data.get(Fields.PAYMENT_STATUS)

        # Block cancel if capture or another cancel is already in progress
        if fresh_payment_status in (PaymentStatusValues.CAPTURING, PaymentStatusValues.CANCELLING):
            raise https_fn.HttpsError("failed-precondition", "Cannot cancel order — operation already in progress")

        # Re-validate order status hasn't changed concurrently
        if fresh_data.get(Fields.ORDER_STATUS) != current_status:
            raise https_fn.HttpsError(
                "failed-precondition", f"Order status changed concurrently (now: {fresh_data.get(Fields.ORDER_STATUS)})"
            )

        # Set cancelling lock to block concurrent captures
        txn.update(
            order_ref,
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CANCELLING,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return fresh_payment_status

    payment_status = lock_for_cancel(transaction)

    # Initialize Stripe key
    stripe.api_key = get_stripe_secret_key()

    # Handle payment based on current payment status
    refunded = False
    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    new_payment_status = payment_status

    if payment_status == PaymentStatusValues.CAPTURED and payment_intent_id:
        # Payment was captured — issue refund
        try:
            stripe.Refund.create(
                payment_intent=payment_intent_id,
                reason="requested_by_customer",
                metadata={Fields.ORDER_ID: order_id},
                idempotency_key=f"refund_{order_id}",
            )
            refunded = True
            new_payment_status = PaymentStatusValues.REFUNDED
        except stripe.error.StripeError as e:
            # CRITICAL: Refund failed — mark for manual review, do NOT silently continue
            order_ref.update(
                {
                    Fields.REQUIRES_MANUAL_REVIEW: True,
                    Fields.MANUAL_REVIEW_REASON: f"Refund failed during cancellation ({type(e).__name__}). Check logs.",
                    Fields.PAYMENT_STATUS: payment_status,  # Restore original payment status
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            raise https_fn.HttpsError(
                "internal", "Order cancellation failed: refund could not be processed. Flagged for manual review."
            ) from e

    elif payment_status == PaymentStatusValues.AUTHORIZED and payment_intent_id:
        # CRITICAL FIX: Payment was authorized but not captured — cancel the PI to release buyer funds
        try:
            stripe.PaymentIntent.cancel(
                payment_intent_id,
                cancellation_reason="requested_by_customer",
            )
            new_payment_status = PaymentStatusValues.CANCELLED
        except stripe.error.StripeError as e:
            # AUDIT FIX: PI cancel failed — buyer funds remain held!
            # Flag for manual review and block cancellation to prevent orphaned authorization
            logger.error(f"PaymentIntent cancel failed: {str(e)}")
            order_ref.update(
                {
                    Fields.REQUIRES_MANUAL_REVIEW: True,
                    Fields.MANUAL_REVIEW_REASON: f"PI cancel failed during cancellation: {type(e).__name__}. Buyer funds may still be held.",
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            raise https_fn.HttpsError(
                "internal", "Order cancellation failed: payment release unsuccessful. Flagged for manual review."
            ) from e

    # AUDIT FIX: Atomic batch — stock restore + final cancel status in ONE commit
    # Prevents double-restore if process crashes between stock restore and status update
    cancel_batch = get_db().batch()

    if not order_data.get(Fields.STOCK_RESTORED, False):
        for item in order_data[Fields.ITEMS]:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
            cancel_batch.update(
                product_ref,
                {
                    Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY]),
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )

    cancel_batch.update(
        order_ref,
        {
            Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
            Fields.PAYMENT_STATUS: new_payment_status,
            Fields.CANCELLED_BY: user_id,
            Fields.CANCELLED_AT: get_server_timestamp(),
            Fields.CANCELLATION_REASON: reason,
            Fields.STOCK_RESTORED: True,
            Fields.UPDATED_AT: get_server_timestamp(),
        },
    )
    cancel_batch.commit()

    return create_success_response({"refunded": refunded})


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # AUDIT FIX: Rate limit refund requests (security-critical)
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="refund_order_item", max_requests=5, window_minutes=1, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    reason_raw = data.get(ApiKeys.REASON, "Item refund requested")

    # Import validation functions
    from utils.helpers import sanitized_text

    # Sanitize reason input
    reason = sanitized_text(reason_raw)[:500]

    if not order_id or not product_id:
        raise https_fn.HttpsError("invalid-argument", "orderId and productId required")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in user_data.get(Fields.ROLES, [])
    # is_buyer = (order_data.get(Fields.USER_ID) == user_id)  # REMOVED: Buyers cannot self-refund directly

    # Check if user is seller for the specific item
    item_seller_id = None
    for item in order_data.get(Fields.ITEMS, []):
        if item[Fields.PRODUCT_ID] == product_id:
            item_seller_id = item[Fields.SELLER_ID]
            break

    is_item_seller = item_seller_id == user_id

    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError("permission-denied", "Only seller of the item or admin can issue refunds")

    # Check if payment was captured
    payment_status = order_data.get(Fields.PAYMENT_STATUS)
    if payment_status != PaymentStatusValues.CAPTURED:
        raise https_fn.HttpsError("failed-precondition", "Cannot refund uncaptured payment")

    # Fix 5: Race Condition Protection
    # Check if a payout is currently in progress (cron job running)
    # Prevents "double spending" race where Payout + Refund happen simultaneously
    payout_status = order_data.get(Fields.PAYOUT_STATUS)
    if payout_status == PayoutStatusValues.PROCESSING:
        raise https_fn.HttpsError(
            "unavailable", "Payout calculation is currently in progress. Please try again in 5 minutes."
        )

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
        raise https_fn.HttpsError("not-found", f"Product {product_id} not found in order")

    # Check if item already refunded
    if item_data.get(Fields.STATUS) == DeliveryStatusValues.REFUNDED:
        raise https_fn.HttpsError("failed-precondition", "Item already refunded")

    # Enforce 7-day return window post-delivery
    if item_data.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED:
        delivered_at = item_data.get(Fields.DELIVERED_AT) or order_data.get(Fields.DELIVERED_AT)
        if delivered_at:
            if hasattr(delivered_at, "timestamp"):
                # Firestore Timestamp object
                delivered_dt = (
                    delivered_at
                    if hasattr(delivered_at, "tzinfo") and delivered_at.tzinfo
                    else delivered_at.replace(tzinfo=UTC)
                )
            elif isinstance(delivered_at, datetime):
                delivered_dt = delivered_at if delivered_at.tzinfo else delivered_at.replace(tzinfo=UTC)
            else:
                delivered_dt = None

            if delivered_dt:
                days_since_delivery = (datetime.now(UTC) - delivered_dt).days
                if days_since_delivery > BusinessRules.RETURN_WINDOW_DAYS:
                    raise https_fn.HttpsError(
                        "failed-precondition",
                        f"Return window expired. Returns and refunds are not accepted after "
                        f"{BusinessRules.RETURN_WINDOW_DAYS} days post-delivery.",
                    )

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
    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    if not payment_intent_id:
        raise https_fn.HttpsError("failed-precondition", "No payment intent found")

    # SECURITY FIX #15: Pre-check refund status BEFORE calling Stripe
    # Prevents issuing a Stripe refund only to discover item is already refunded in Firestore.
    # The idempotency key f'refund_{order_id}_{product_id}' also protects against double-refund
    # but this check avoids unnecessary Stripe API calls.
    for pre_item in order_data.get(Fields.ITEMS, []):
        if pre_item.get(Fields.PRODUCT_ID) == product_id:
            if pre_item.get(Fields.STATUS) == DeliveryStatusValues.REFUNDED:
                logger.info(f"Item {product_id} in order {order_id} already refunded (pre-check)")
                return create_success_response({"alreadyRefunded": True, Fields.ORDER_ID: order_id})
            break

    try:
        refund = stripe.Refund.create(
            payment_intent=payment_intent_id,
            amount=refund_amount_cents,
            reason="requested_by_customer",
            metadata={
                Fields.ORDER_ID: order_id,
                Fields.PRODUCT_ID: product_id,
                "itemSubtotal": item_subtotal_cents,
                "proportionalTax": proportional_tax_cents,
                "proportionalShipping": proportional_shipping_cents,
            },
            idempotency_key=f"refund_{order_id}_{product_id}",
        )
    except stripe.error.StripeError as e:
        logger.error(f"ERROR: Refund failed for order {order_id}, product {product_id}: {e}")
        raise https_fn.HttpsError("internal", "Refund failed. Please try again or contact support.") from e

    # Restore stock for this item
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)

    # AUDIT FIX: Use transaction to prevent race condition (double refund / double stock restore)
    @get_firestore().transactional
    def _apply_refund_atomically(transaction):
        """Atomically verify item not yet refunded + update item status + restore stock."""
        fresh_order_doc = order_ref.get(transaction=transaction)
        if not fresh_order_doc.exists:
            raise https_fn.HttpsError("not-found", "Order not found")

        fresh_data = fresh_order_doc.to_dict()
        fresh_items = fresh_data.get(Fields.ITEMS, [])

        # Re-verify item not already refunded (protect against concurrent requests)
        for idx, it in enumerate(fresh_items):
            if it[Fields.PRODUCT_ID] == product_id:
                if it.get(Fields.STATUS) == DeliveryStatusValues.REFUNDED:
                    return "already_refunded"

                # Update item status atomically
                # NOTE: Use datetime.now() instead of get_server_timestamp() for
                # fields inside array elements — Firestore SDK cannot serialize
                # SERVER_TIMESTAMP sentinels nested inside arrays.
                now_utc = datetime.now(UTC)
                fresh_items[idx][Fields.STATUS] = DeliveryStatusValues.REFUNDED
                fresh_items[idx][Fields.REFUNDED_AT] = now_utc
                fresh_items[idx][Fields.REFUND_REASON] = reason
                fresh_items[idx][Fields.REFUND_AMOUNT_CENTS] = refund_amount_cents
                fresh_items[idx][Fields.REFUND_ID] = refund.id
                break

        transaction.update(order_ref, {Fields.ITEMS: fresh_items, Fields.UPDATED_AT: get_server_timestamp()})
        transaction.update(
            product_ref,
            {
                Fields.STOCK_QUANTITY: get_firestore().Increment(item_quantity),
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return "refunded"

    txn_result = _apply_refund_atomically(get_db().transaction())
    if txn_result == "already_refunded":
        return create_success_response(
            {
                Fields.REFUND_AMOUNT_CENTS: refund_amount_cents,
                Fields.REFUND_ID: refund.id,
                "message": "Item was already refunded",
            }
        )

    # Reverse seller transfer if payout exists
    seller_id = item_data[Fields.SELLER_ID]
    payout_query = (
        get_db()
        .collection(Collections.PAYOUTS)
        .where(Fields.ORDER_ID, "==", order_id)
        .where(Fields.SELLER_ID, "==", seller_id)
        .where(Fields.STATUS, "==", PayoutStatusValues.COMPLETED)
        .limit(1)
        .get()
    )

    if len(payout_query) > 0:
        payout_doc = payout_query[0]
        payout_data = payout_doc.to_dict()

        # Calculate proportional reversal amount
        seller_total_cents = payout_data.get(Fields.AMOUNT_CENTS, 0)
        # platform_fee_cents tracked for audit trail but not used in reversal calculation
        _platform_fee_cents = payout_data.get(Fields.PLATFORM_FEE_CENTS, 0)  # noqa: F841

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
                            Fields.ORDER_ID: order_id,
                            Fields.PRODUCT_ID: product_id,
                            Fields.REASON: "item_refund",
                        },
                        idempotency_key=f"reversal_{order_id}_{product_id}_{seller_id}",
                    )

                    # Log partial reversal
                    # NOTE: Use datetime.now() inside ArrayUnion — Firestore SDK
                    # cannot serialize SERVER_TIMESTAMP sentinels inside arrays.
                    payout_doc.reference.update(
                        {
                            Fields.PARTIAL_REVERSALS: get_firestore().ArrayUnion(
                                [
                                    {
                                        Fields.REVERSAL_ID: reversal.id,
                                        Fields.AMOUNT_CENTS: reversal_amount_cents,
                                        Fields.PRODUCT_ID: product_id,
                                        Fields.CREATED_AT: datetime.now(UTC),
                                    }
                                ]
                            ),
                            Fields.UPDATED_AT: get_server_timestamp(),
                        }
                    )
            except stripe.error.StripeError as e:
                # Log failed reversal but don't fail the refund
                logger.error(f"Transfer reversal failed for {seller_id}: {str(e)}")

    # Order items already updated atomically in _apply_refund_atomically transaction

    return create_success_response(
        {
            Fields.REFUND_AMOUNT_CENTS: refund_amount_cents,
            Fields.REFUND_ID: refund.id,
        }
    )


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # AUDIT FIX: Rate limit shipping approval to prevent abuse
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="approve_shipping_cost", max_requests=10, window_minutes=1
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data

    order_id = data.get(Fields.ORDER_ID)
    approved = data.get(ApiKeys.APPROVED, False)
    expected_cost_cents = data.get("expectedCostCents")  # Fix 1: Phantom Shipping protection

    if not order_id:
        raise https_fn.HttpsError("invalid-argument", "orderId required")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # Verify buyer
    if order_data[Fields.USER_ID] != user_id:
        raise https_fn.HttpsError("permission-denied", "Not your order")

    shipping_approval = order_data.get(Fields.SHIPPING_APPROVAL, {})

    if shipping_approval.get(Fields.STATUS) != ShippingApprovalStatusValues.PENDING:
        raise https_fn.HttpsError("failed-precondition", "No pending shipping approval")

    if approved:
        # AUDIT FIX (C3): Use Firestore transaction to prevent race conditions
        # AUDIT FIX (C1): Recalculate taxes when shipping cost changes (CRA requirement)
        # AUDIT FIX (H4): Call Stripe BEFORE Firestore commit; fail loudly on error
        from firebase_admin import firestore as fs

        from config import SHIPPING_APPROVAL_THRESHOLD
        from services.shipping_service import get_tax_rate

        transaction = get_db().transaction()

        @fs.transactional
        def approve_with_tax_recalc(txn):
            # Re-read order inside transaction for consistency
            fresh_doc = order_ref.get(transaction=txn)
            if not fresh_doc.exists:
                raise https_fn.HttpsError("not-found", "Order not found")
            fresh_data = fresh_doc.to_dict()

            fresh_approval = fresh_data.get(Fields.SHIPPING_APPROVAL, {})
            if fresh_approval.get(Fields.STATUS) != ShippingApprovalStatusValues.PENDING:
                raise https_fn.HttpsError("failed-precondition", "No pending shipping approval")

            # Fix 1: Verify the cost user is approving matches the current database state
            # Prevents bait-and-switch where cost changes while user is viewing the approval screen
            actual_new_cost_cents = fresh_approval.get(Fields.NEW_COST_CENTS)
            if expected_cost_cents is not None and actual_new_cost_cents != expected_cost_cents:
                raise https_fn.HttpsError(
                    "failed-precondition",
                    f"Shipping cost has changed (was ${expected_cost_cents / 100:.2f}, now ${actual_new_cost_cents / 100:.2f}). Please review the new cost.",
                )

            new_shipping_cost_cents = round(fresh_approval.get(Fields.ACTUAL_COST, 0) * 100)
            old_shipping_cost_cents = fresh_data.get(Fields.SHIPPING_COST_CENTS, 0)

            # SECURITY: Validate shipping cost bounds
            if old_shipping_cost_cents == 0:
                max_allowed_cents = 0
            else:
                max_allowed_cents = round(old_shipping_cost_cents * (1 + SHIPPING_APPROVAL_THRESHOLD))
            if new_shipping_cost_cents > max_allowed_cents:
                raise https_fn.HttpsError(
                    "invalid-argument",
                    f"Shipping cost ${new_shipping_cost_cents / 100:.2f} exceeds maximum allowed "
                    f"(+{int(SHIPPING_APPROVAL_THRESHOLD * 100)}% of original ${old_shipping_cost_cents / 100:.2f}). "
                    f"Contact admin for manual approval.",
                )

            # Validate authorization is still valid before modifying payment
            expires_at = fresh_data.get(Fields.EXPIRES_AT)
            if expires_at and isinstance(expires_at, datetime) and expires_at < datetime.now(UTC):
                raise https_fn.HttpsError(
                    "failed-precondition", "Payment authorization has expired. Order must be re-created."
                )

            difference_cents = new_shipping_cost_cents - old_shipping_cost_cents

            # AUDIT FIX (C1): Recalculate tax on shipping delta
            # In Canada, GST/HST/PST apply to shipping charges (CRA requirement)
            tax_difference_cents = 0
            updated_taxes = {}
            if difference_cents != 0:
                shipping_address = fresh_data.get(Fields.SHIPPING_ADDRESS, {})
                state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)
                shipping_tax_rate = get_tax_rate(state_code)
                tax_difference_cents = round(difference_cents * shipping_tax_rate)

                # Update tax breakdown with shipping tax adjustment
                existing_taxes = fresh_data.get(Fields.TAXES, {})
                updated_taxes = dict(existing_taxes) if existing_taxes else {}

                # Distribute tax delta across applicable tax types for this province
                from handlers.payment_stripe import _PROVINCE_TAX_BREAKDOWN

                province_rates = _PROVINCE_TAX_BREAKDOWN.get(
                    state_code,
                    _PROVINCE_TAX_BREAKDOWN.get(BusinessRules.DEFAULT_PROVINCE, {"GST": 0.05}),
                )
                shipping_diff_dollars = difference_cents / 100.0
                for tax_name, rate in province_rates.items():
                    current_amount = updated_taxes.get(tax_name, 0.0)
                    updated_taxes[tax_name] = round(current_amount + (shipping_diff_dollars * rate), 2)

            old_tax_cents = fresh_data.get(Fields.TAX_AMOUNT_CENTS, 0)
            new_tax_cents = old_tax_cents + tax_difference_cents
            new_total_cents = fresh_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) + difference_cents + tax_difference_cents

            update_fields = {
                Fields.SHIPPING_COST_CENTS: new_shipping_cost_cents,
                Fields.TAX_AMOUNT_CENTS: new_tax_cents,
                Fields.TOTAL_AMOUNT_CENTS: new_total_cents,
                f"{Fields.SHIPPING_APPROVAL}.{Fields.STATUS}": ShippingApprovalStatusValues.APPROVED,
                f"{Fields.SHIPPING_APPROVAL}.{Fields.RESPONDED_AT}": get_server_timestamp(),
                Fields.UPDATED_AT: get_server_timestamp(),
            }
            if updated_taxes:
                update_fields[Fields.TAXES] = updated_taxes

            # AUDIT FIX (H4): Call Stripe BEFORE Firestore commit
            # If Stripe fails, the transaction is not committed — consistent state preserved
            if difference_cents + tax_difference_cents > 0:
                payment_intent_id = fresh_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
                if payment_intent_id:
                    try:
                        stripe.PaymentIntent.modify(payment_intent_id, amount=new_total_cents)
                    except stripe.error.StripeError as e:
                        logger.error(f"Failed to update Stripe payment amount: {str(e)}")
                        # Flag for manual review — do NOT silently swallow the error
                        txn.update(
                            order_ref,
                            {
                                Fields.REQUIRES_MANUAL_REVIEW: True,
                                Fields.MANUAL_REVIEW_REASON: (
                                    f"Stripe PI modify failed during shipping approval: {type(e).__name__}. "
                                    f"Firestore shows old amount. Stripe may be out of sync."
                                ),
                                Fields.UPDATED_AT: get_server_timestamp(),
                            },
                        )
                        raise https_fn.HttpsError(
                            "internal",
                            "Shipping approved but payment update failed. Flagged for manual review.",
                        ) from e

            txn.update(order_ref, update_fields)
            return new_total_cents

        approve_with_tax_recalc(transaction)
    else:
        # Buyer rejected, cancel order
        cancel_payment_status = order_data.get(Fields.PAYMENT_STATUS)

        # CRITICAL FIX: Cancel PaymentIntent to release buyer funds
        payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
        if payment_intent_id and cancel_payment_status == PaymentStatusValues.AUTHORIZED:
            try:
                stripe.PaymentIntent.cancel(
                    payment_intent_id,
                    cancellation_reason="requested_by_customer",
                )
                cancel_payment_status = PaymentStatusValues.CANCELLED
            except stripe.error.StripeError as e:
                logger.error(f"PaymentIntent cancel failed on shipping rejection: {str(e)}")

        # AUDIT FIX: Use atomic batch for order cancel + stock restore
        # Prevents stock leakage if process crashes between order update and stock restore
        reject_batch = get_db().batch()

        reject_batch.update(
            order_ref,
            {
                f"{Fields.SHIPPING_APPROVAL}.{Fields.STATUS}": ShippingApprovalStatusValues.REJECTED,
                f"{Fields.SHIPPING_APPROVAL}.{Fields.RESPONDED_AT}": get_server_timestamp(),
                Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                Fields.PAYMENT_STATUS: cancel_payment_status,
                Fields.CANCELLATION_REASON: "Buyer rejected shipping cost",
                Fields.STOCK_RESTORED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )

        # Restore stock atomically with order cancellation
        for item in order_data[Fields.ITEMS]:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
            reject_batch.update(
                product_ref,
                {
                    Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY]),
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )

        reject_batch.commit()

    return create_success_response({ApiKeys.APPROVED: approved})


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
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # AUDIT FIX: Rate limit shipping cost updates
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="update_shipping_cost", max_requests=10, window_minutes=1, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data

    from config import SHIPPING_APPROVAL_THRESHOLD
    from utils.helpers import sanitized_text

    order_id = data.get(Fields.ORDER_ID)
    new_shipping_cost = data.get(ApiKeys.NEW_SHIPPING_COST)
    reason_raw = data.get(ApiKeys.REASON, "Actual shipping cost differs from estimate")
    reason = sanitized_text(reason_raw)[:500] if reason_raw else "Actual shipping cost differs from estimate"

    if not order_id:
        raise https_fn.HttpsError("invalid-argument", "orderId required")
    if new_shipping_cost is None or not isinstance(new_shipping_cost, (int, float)) or new_shipping_cost < 0:
        raise https_fn.HttpsError("invalid-argument", "newShippingCost must be a non-negative number")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # Verify seller owns at least one item in the order
    seller_items = [item for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.SELLER_ID) == user_id]
    if not seller_items:
        raise https_fn.HttpsError("permission-denied", "You do not have items in this order")

    # Only allow update on confirmed/processing orders
    if order_data.get(Fields.ORDER_STATUS) not in [OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING]:
        raise https_fn.HttpsError("failed-precondition", "Can only update shipping on confirmed/processing orders")

    # Only allow update on authorized payment (not yet captured)
    if order_data.get(Fields.PAYMENT_STATUS) != PaymentStatusValues.AUTHORIZED:
        raise https_fn.HttpsError("failed-precondition", "Payment must be in authorized state")

    original_shipping_cents = order_data.get(Fields.SHIPPING_COST_CENTS, 0)
    new_shipping_cents = round(new_shipping_cost * 100)

    # Check if increase exceeds threshold (20%)
    approval_required = False
    if original_shipping_cents > 0:
        increase_ratio = (new_shipping_cents - original_shipping_cents) / original_shipping_cents
        if increase_ratio > SHIPPING_APPROVAL_THRESHOLD:
            approval_required = True
    elif original_shipping_cents == 0 and new_shipping_cents > 0:
        # AUDIT FIX: Free shipping orders — ANY cost addition requires buyer approval
        # Prevents seller from adding arbitrary shipping charges without consent
        approval_required = True

    if approval_required:
        # Set pending approval — buyer must approve before shipping can proceed
        order_ref.update(
            {
                Fields.SHIPPING_APPROVAL: {
                    Fields.STATUS: ShippingApprovalStatusValues.PENDING,
                    Fields.ACTUAL_COST: new_shipping_cost,
                    Fields.ORIGINAL_COST_CENTS: original_shipping_cents,
                    Fields.NEW_COST_CENTS: new_shipping_cents,
                    Fields.REASON: reason,
                    Fields.REQUESTED_BY: user_id,
                    Fields.REQUESTED_AT: get_server_timestamp(),
                },
                Fields.SHIPPING_APPROVAL_STATUS: ShippingApprovalStatusValues.PENDING,
                Fields.SHIPPING_APPROVAL_REQUIRED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )
    else:
        # Auto-approve small changes — update shipping cost directly
        # AUDIT FIX (C1): Recalculate taxes when shipping changes (CRA requirement)
        from services.shipping_service import get_tax_rate

        difference_cents = new_shipping_cents - original_shipping_cents

        # Calculate tax on shipping delta
        tax_difference_cents = 0
        updated_taxes = {}
        if difference_cents != 0:
            shipping_address = order_data.get(Fields.SHIPPING_ADDRESS, {})
            state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)
            shipping_tax_rate = get_tax_rate(state_code)
            tax_difference_cents = round(difference_cents * shipping_tax_rate)

            # Update tax breakdown with shipping tax adjustment
            existing_taxes = order_data.get(Fields.TAXES, {})
            updated_taxes = dict(existing_taxes) if existing_taxes else {}

            from handlers.payment_stripe import _PROVINCE_TAX_BREAKDOWN

            province_rates = _PROVINCE_TAX_BREAKDOWN.get(
                state_code,
                _PROVINCE_TAX_BREAKDOWN.get(BusinessRules.DEFAULT_PROVINCE, {"GST": 0.05}),
            )
            shipping_diff_dollars = difference_cents / 100.0
            for tax_name, rate in province_rates.items():
                current_amount = updated_taxes.get(tax_name, 0.0)
                updated_taxes[tax_name] = round(current_amount + (shipping_diff_dollars * rate), 2)

        old_tax_cents = order_data.get(Fields.TAX_AMOUNT_CENTS, 0)
        new_tax_cents = old_tax_cents + tax_difference_cents
        new_total_cents = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0) + difference_cents + tax_difference_cents

        update_data = {
            Fields.SHIPPING_COST_CENTS: new_shipping_cents,
            Fields.TAX_AMOUNT_CENTS: new_tax_cents,
            Fields.TOTAL_AMOUNT_CENTS: new_total_cents,
            Fields.ACTUAL_SHIPPING_CENTS: new_shipping_cents,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
        if updated_taxes:
            update_data[Fields.TAXES] = updated_taxes

        # AUDIT FIX (H4): Update Stripe PaymentIntent BEFORE Firestore
        if difference_cents + tax_difference_cents != 0:
            payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
            if payment_intent_id:
                try:
                    stripe.PaymentIntent.modify(payment_intent_id, amount=new_total_cents)
                except stripe.error.StripeError as e:
                    logger.error(f"Failed to update Stripe PI amount: {str(e)}")
                    order_ref.update(
                        {
                            Fields.REQUIRES_MANUAL_REVIEW: True,
                            Fields.MANUAL_REVIEW_REASON: (
                                f"Stripe PI modify failed during auto shipping update: {type(e).__name__}."
                            ),
                            Fields.UPDATED_AT: get_server_timestamp(),
                        }
                    )
                    raise https_fn.HttpsError(
                        "internal", "Shipping update failed: payment could not be updated. Flagged for review."
                    ) from e

        order_ref.update(update_data)

    return create_success_response({ApiKeys.APPROVAL_REQUIRED: approval_required})


@firestore_fn.on_document_updated(document="orders/{orderId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_order_status_changed(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Sends email notifications when order status changes.
    """
    order_id = event.params[Fields.ORDER_ID]
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
            logger.error(f"Failed to fetch buyer email for order {order_id}: {str(e)}")

    if not buyer_email:
        logger.warning(f"⚠️ No email found for user {user_id}, skipping notification for order {order_id}")
        return

    lang = after_data.get(Fields.PREFERRED_LANGUAGE, "en")
    oid_short = order_id[:8]

    try:
        if new_status == OrderStatusValues.PROCESSING:
            processing_html = get_order_processing_email(after_data, order_id, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.processing", lang).replace("{oid}", oid_short),
                html_content=processing_html,
            )

        elif new_status == OrderStatusValues.SHIPPED:
            tracking_number = after_data.get(Fields.TRACKING_NUMBER, "N/A")
            carrier = after_data.get(Fields.CARRIER, "N/A")

            # Email buyer — branded template with receipt
            shipped_html = get_order_shipped_email(after_data, order_id, tracking_number, carrier, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.shipped", lang).replace("{oid}", oid_short),
                html_content=shipped_html,
            )

            # Also notify sellers that shipment confirmed — filtered to their items only
            seller_ids = set(item.get(Fields.SELLER_ID) for item in after_data.get(Fields.ITEMS, []))
            # Batch-read all seller docs in one RPC (avoids N sequential reads for multi-seller orders)
            seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
            seller_docs = {doc.id: doc for doc in get_db().get_all(seller_refs)}
            for sid in seller_ids:
                try:
                    seller_doc = seller_docs.get(sid)
                    if seller_doc and seller_doc.exists:
                        seller_data = seller_doc.to_dict()
                        seller_email = seller_data.get(Fields.EMAIL)
                        if seller_email:
                            seller_lang = seller_data.get(Fields.PREFERRED_LANGUAGE, "en")
                            # Use seller notification with seller_id filter (multi-seller privacy)
                            seller_shipped_html = get_seller_notification_email(after_data, order_id, sid, lang=seller_lang)
                            send_email(
                                to_email=seller_email,
                                subject=_email_t("sub.shipped_seller", seller_lang).replace("{oid}", oid_short),
                                html_content=seller_shipped_html,
                            )
                except Exception as e:
                    logger.warning(f"⚠️ Failed to send shipped notification to seller {sid}: {str(e)}")

        elif new_status == OrderStatusValues.IN_TRANSIT:
            # Email buyer — in transit update with tracking info
            in_transit_html = get_order_in_transit_email(after_data, order_id, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.in_transit", lang).replace("{oid}", oid_short),
                html_content=in_transit_html,
            )

        elif new_status == OrderStatusValues.DELIVERED:
            # Email buyer — branded template with receipt + confirm receipt CTA
            delivered_html = get_order_delivered_email(after_data, order_id, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.delivered", lang).replace("{oid}", oid_short),
                html_content=delivered_html,
            )

        elif new_status == OrderStatusValues.CANCELLED:
            reason = after_data.get(Fields.CANCELLATION_REASON, "Unknown")
            cancelled_html = get_order_cancelled_email(after_data, order_id, reason, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.cancelled", lang).replace("{oid}", oid_short),
                html_content=cancelled_html,
            )

        elif new_status == OrderStatusValues.REFUNDED:
            refund_amount = after_data.get(Fields.CUMULATIVE_REFUNDED_CENTS, 0)
            refunded_html = get_order_refunded_email(after_data, order_id, refund_amount, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.refunded", lang).replace("{oid}", oid_short),
                html_content=refunded_html,
            )

        elif new_status == OrderStatusValues.PARTIALLY_REFUNDED:
            refund_amount = after_data.get(Fields.PARTIAL_REFUND_AMOUNT_CENTS, 0)
            partial_html = get_order_partially_refunded_email(after_data, order_id, refund_amount, lang=lang)
            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.partial", lang).replace("{oid}", oid_short),
                html_content=partial_html,
            )

    except Exception as e:
        logger.error(f"🚨 Failed to send order status email for order {order_id}: {str(e)}")
