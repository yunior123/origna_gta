"""
Order Lifecycle Management Handlers
- Order receipt confirmation
- Order status updates
- Shipping approval workflow
- Order cancellation
"""

import hashlib
import logging
from datetime import UTC, datetime
from typing import Any

import stripe
from firebase_functions import firestore_fn, https_fn

from config import get_stripe_secret_key
from models.order_event import OrderEvent
from schema_constants import (
    ApiKeys,
    BusinessRules,
    Collections,
    DeliveryItemStatusTransitions,
    DeliveryStatusValues,
    DeliveryTypeValues,
    Fields,
    NotificationTypes,
    OrderEventTypes,
    OrderItemIdValues,
    OrderStatusValues,
    PaymentStatusValues,
    PayoutStatusValues,
    ReturnStatusValues,
    ShippingApprovalStatusValues,
    UserRoleValues,
)
from services.email_service import (
    _t as _email_t,
)
from services.email_service import (
    get_order_cancelled_email,
    get_order_confirmation_email,
    get_order_delivered_email,
    get_order_in_transit_email,
    get_order_item_delivered_email,
    get_order_item_shipped_email,
    get_order_partially_refunded_email,
    get_order_processing_email,
    get_order_refunded_email,
    get_order_shipped_email,
    get_return_received_email,
    get_return_refunded_email,
    get_return_request_approved_email,
    get_return_request_rejected_email,
    get_return_request_submitted_email,
    get_seller_notification_email,
)
from services.email_task import enqueue_email_task
from services.push_service import send_push_notification
from utils.db import get_db, get_firestore, get_server_timestamp
from utils.function_options import DEFAULT_OPTIONS, FIRESTORE_TRIGGER_OPTIONS
from utils.helpers import create_success_response, is_valid_order_status_transition

logger = logging.getLogger(__name__)


def _restore_stock_to_batch(batch, items: list) -> None:
    """Add stock restore operations for physical items to an existing Firestore batch."""
    for item in items:
        if item.get(Fields.IS_DIGITAL, False):
            continue
        product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
        stock_patch: dict = {
            Fields.STOCK_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY]),
            Fields.UPDATED_AT: get_server_timestamp(),
        }
        fulfillment_wh = item.get(Fields.FULFILLMENT_WAREHOUSE_ID)
        if fulfillment_wh:
            stock_patch[f"{Fields.WAREHOUSE_STOCK}.{fulfillment_wh}"] = get_firestore().Increment(item[Fields.QUANTITY])
            inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(fulfillment_wh)
            batch.set(inv_ref, {
                Fields.AVAILABLE_QUANTITY: get_firestore().Increment(item[Fields.QUANTITY]),
                Fields.LAST_SYNCED_AT: get_server_timestamp(),
            }, merge=True)
        batch.update(product_ref, stock_patch)



@https_fn.on_call(**DEFAULT_OPTIONS)
def confirm_item_receipt(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Buyer confirms receipt of a specific item in a multi-seller order.
    Sets item status to DELIVERED and triggers a partial payout for that seller.

    Request data:
        orderId: Order ID
        productId: Product ID to confirm
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    order_id = req.data.get(Fields.ORDER_ID)
    cart_item_id = req.data.get(Fields.CART_ITEM_ID)

    if not order_id or not cart_item_id:
        raise https_fn.HttpsError("invalid-argument", "orderId and cartItemId required")

    db = get_db()
    order_ref = db.collection(Collections.ORDERS).document(order_id)

    @get_firestore().transactional
    def _confirm_item_txn(transaction):
        order_doc = order_ref.get(transaction=transaction)
        if not order_doc.exists:
            raise https_fn.HttpsError("not-found", "Order not found")

        order_data = order_doc.to_dict()
        if order_data.get(Fields.USER_ID) != user_id:
            raise https_fn.HttpsError("permission-denied", "Only the order owner can confirm receipt")

        items = order_data.get(Fields.ITEMS, [])
        item_index = next((i for i, it in enumerate(items) if it.get(Fields.CART_ITEM_ID) == cart_item_id), None)

        if item_index is None:
            raise https_fn.HttpsError("not-found", "Item not found in order")

        item = items[item_index]

        # B4: Self-purchase check — sellers cannot confirm receipt of their own items
        if item.get(Fields.SELLER_ID) == user_id:
            raise https_fn.HttpsError("permission-denied", "Sellers cannot confirm receipt of their own items")

        current_item_status = item.get(Fields.STATUS)

        if current_item_status == DeliveryStatusValues.DELIVERED:
            return {"success": True, "message": "Item already marked as delivered"}

        # C1: Only SHIPPED items can be confirmed — PENDING items must not be confirmable
        if current_item_status != DeliveryStatusValues.SHIPPED:
            raise https_fn.HttpsError(
                "failed-precondition",
                f"Cannot confirm receipt: item must be shipped first (current: {current_item_status})"
            )

        # Update item status
        now_utc = datetime.now(UTC)
        items[item_index][Fields.STATUS] = DeliveryStatusValues.DELIVERED
        items[item_index][Fields.DELIVERED_AT] = now_utc
        items[item_index][Fields.CONFIRMED_BY_BUYER] = True

        all_delivered = all(it.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED for it in items)

        update_data = {
            Fields.ITEMS: items,
            Fields.UPDATED_AT: get_server_timestamp()
        }

        if all_delivered:
            update_data[Fields.ORDER_STATUS] = OrderStatusValues.DELIVERED
            update_data[Fields.CONFIRMED_AT] = now_utc
            update_data[Fields.CONFIRMED_BY_CLIENT] = True

        transaction.update(order_ref, update_data)
        return {"success": True, "allDelivered": all_delivered}

    result = _confirm_item_txn(db.transaction())

    # Trigger payout if payment is already captured (Auto-capture mode)
    # or if this was the last item and we're in manual capture mode.
    # For now, we delegate payout to the auto_capture cron or capture_payment handler
    # which already handles DELIVERED items.

    return result


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
    old_status = order_data.get(Fields.ORDER_STATUS, OrderStatusValues.PENDING)

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
    seller_items = [item for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.SELLER_ID) == user_id]
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
        all_seller_ids = set(item.get(Fields.SELLER_ID) for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.SELLER_ID))
        if len(all_seller_ids) > 1:
            raise https_fn.HttpsError(
                "failed-precondition",
                "Multi-seller order: use update_item_status to update per-item status instead of order-level status.",
            )

    # Block sellers from manually shipping digital orders (instant delivery on capture)
    if new_status == OrderStatusValues.SHIPPED:
        digital_items = [i for i in seller_items if i.get(Fields.IS_DIGITAL, False)]
        if digital_items:
            raise https_fn.HttpsError(
                "failed-precondition",
                "Digital products cannot be manually shipped — delivery is instant on payment capture.",
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

            update_data = {
                Fields.ITEMS: items,
                Fields.UPDATED_AT: get_server_timestamp(),
                # FIX-6 (MEDIUM): Stamp the actor so on_order_status_changed can skip
                # the self-notification push to the seller who triggered the shipment.
                Fields.LAST_ACTOR_ID: user_id,
            }

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

    # Admin-triggered DELIVERED: capture payment if still authorized
    if is_admin and new_status == OrderStatusValues.DELIVERED:
        payment_status = order_data.get(Fields.PAYMENT_STATUS)
        if payment_status in (PaymentStatusValues.AUTHORIZED, PaymentStatusValues.CAPTURING):
            pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
            if pi_id:
                try:
                    stripe.api_key = get_stripe_secret_key()
                    pi = stripe.PaymentIntent.retrieve(pi_id)
                    if pi.status == "requires_capture":
                        stripe.PaymentIntent.capture(pi_id, idempotency_key=f"admin_capture_{order_id}")
                except Exception as e:
                    logger.error(f"Admin-triggered capture failed for {order_id}: {e}")
                    raise https_fn.HttpsError("internal", "Could not capture payment before marking delivered.") from e

    order_ref.update(update_data)

    # Record order event
    OrderEvent.write(
        get_db(), order_id, OrderEventTypes.STATUS_CHANGED,
        actor=user_id, actor_type="seller" if (is_seller and not is_admin) else "admin",
        from_status=old_status, to_status=new_status,
    )

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

    # Handle 'all' sentinel — update every item belonging to this seller
    if product_id == OrderItemIdValues.ALL:
        seller_items = [
            (idx, item) for idx, item in enumerate(items) if item.get(Fields.SELLER_ID) == user_id
        ]
        if not seller_items and user_id not in (order_data.get(Fields.USER_ID, ""),):
            # Admin path: update ALL items regardless of seller
            is_admin_check = UserRoleValues.ADMIN in (
                (get_db().collection(Collections.USERS).document(user_id).get().to_dict() or {}).get(Fields.ROLES, [])
            )
            if is_admin_check:
                seller_items = list(enumerate(items))
        if not seller_items:
            raise https_fn.HttpsError("not-found", "No items found for this seller in the order")
        updated_items = list(items)
        for idx, item in seller_items:
            updated_item = dict(item)
            updated_item[Fields.STATUS] = new_status
            if tracking_number:
                updated_item[Fields.TRACKING_NUMBER] = tracking_number
            if carrier:
                updated_item[Fields.CARRIER] = carrier
            updated_items[idx] = updated_item
        order_ref.update({Fields.ITEMS: updated_items, Fields.UPDATED_AT: get_server_timestamp()})
        logger.info(f"Updated all {len(seller_items)} items for seller {user_id} in order {order_id} to {new_status}")
        return {"success": True, "itemStatus": new_status, "allItemsDelivered": False}

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
            # For pickup orders, tracking number is optional (serves as 'Ready for Pickup' signal)
            is_pickup = fresh_data.get(Fields.DELIVERY_SPEED) == DeliveryTypeValues.PICKUP
            if not tracking_number and not is_pickup:
                raise https_fn.HttpsError(
                    "invalid-argument",
                    "Tracking number is required when marking an item as shipped.",
                )
            fresh_items[fresh_item_index][Fields.SHIPPED_AT] = now_utc
            fresh_items[fresh_item_index][Fields.TRACKING_NUMBER] = tracking_number
            fresh_items[fresh_item_index][Fields.CARRIER] = carrier or ("Pickup" if is_pickup else "")
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
            if fresh_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.CAPTURED:
                update_data[Fields.ORDER_STATUS] = OrderStatusValues.DELIVERED
            # If payment not yet captured, leave order in current status (will be set DELIVERED after capture)
        elif (
            all_shipped
            and not all_delivered
            and current_order_status in [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING]
        ):
            update_data[Fields.ORDER_STATUS] = OrderStatusValues.SHIPPED

        transaction.update(order_ref, update_data)
        return all_delivered, all_shipped

    all_items_delivered, all_items_shipped = update_item_atomically(txn)

    # Record item status change event
    event_type = {
        DeliveryStatusValues.SHIPPED: OrderEventTypes.ITEM_SHIPPED,
        DeliveryStatusValues.DELIVERED: OrderEventTypes.ITEM_DELIVERED,
    }.get(new_status, OrderEventTypes.STATUS_CHANGED)
    OrderEvent.write(
        get_db(), order_id, event_type,
        actor=user_id, actor_type="seller",
        from_status=current_item_status, to_status=new_status,
        metadata={"productId": product_id, "itemIndex": item_index},
    )

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
    # H2: Safe ITEMS access — use .get() to avoid KeyError on malformed orders
    seller_items = [item for item in order_data.get(Fields.ITEMS, []) if item.get(Fields.SELLER_ID) == user_id]
    is_seller = len(seller_items) > 0

    if not (is_admin or is_buyer or is_seller):
        raise https_fn.HttpsError("permission-denied", "Only buyer, seller, or admin can cancel order")

    # AUDIT FIX (C2): Sellers can only cancel orders where they own ALL items.
    # In multi-seller orders, sellers must use item-level refund instead.
    if is_seller and not is_buyer and not is_admin:
        all_items = order_data.get(Fields.ITEMS, [])
        if len(seller_items) < len(all_items):
            raise https_fn.HttpsError(
                "permission-denied",
                "Cannot cancel a multi-seller order. Use item refund to cancel your items only.",
            )

    # SECURITY FIX: Use proper state machine validation instead of blocklist
    current_status = order_data.get(Fields.ORDER_STATUS)

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
    else:
        # No payment or payment in a non-refundable state — mark as cancelled
        new_payment_status = PaymentStatusValues.CANCELLED

    # AUDIT FIX: Atomic batch — stock restore + final cancel status in ONE commit
    # Prevents double-restore if process crashes between stock restore and status update
    cancel_batch = get_db().batch()

    if not order_data.get(Fields.STOCK_RESTORED, False):
        # Restore stock using the helper function
        _restore_stock_to_batch(cancel_batch, order_data.get(Fields.ITEMS, []))

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
    try:
        cancel_batch.commit()
    except Exception as batch_err:
        logger.error(f"cancel_order batch commit failed for {order_id}: {batch_err}")
        try:
            order_ref.update({
                Fields.PAYMENT_STATUS: payment_status,  # restore original
                Fields.REQUIRES_MANUAL_REVIEW: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            })
        except Exception as restore_err:
            logger.error(f"Failed to restore payment_status for {order_id}: {restore_err}")
        raise https_fn.HttpsError("internal", "Order state update failed. Please contact support.") from batch_err

    # Record cancellation event
    OrderEvent.write(
        get_db(), order_id, OrderEventTypes.CANCELLATION_CONFIRMED,
        actor=user_id, actor_type="buyer" if user_id == order_data.get(Fields.USER_ID) else ("seller" if is_seller else "admin"),
        from_status=current_status, to_status=OrderStatusValues.CANCELLED,
        metadata={"reason": reason, "refunded": refunded},
    )

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

    # Enforce 7-day return window post-delivery (bypassed for admins)
    if not is_admin and item_data.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED:
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

    # M3: Fail loudly on zero subtotal instead of silently under-refunding
    if order_subtotal_cents <= 0:
        raise https_fn.HttpsError(
            "failed-precondition",
            "Cannot calculate proportional refund: order subtotal is zero. Contact admin for manual refund."
        )
    proportion = item_subtotal_cents / order_subtotal_cents
    proportional_tax_cents = round(order_tax_cents * proportion)
    proportional_shipping_cents = round(order_shipping_cents * proportion)

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
        found_item = None
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
                found_item = it
                break
        if found_item is None:
            raise https_fn.HttpsError("not-found", f"Product {product_id} not found in fresh order")

        transaction.update(order_ref, {Fields.ITEMS: fresh_items, Fields.UPDATED_AT: get_server_timestamp()})
        # Digital products have unlimited stock — never decrement, never restore.
        # Physical products: restore immediately on refund here.
        # (Returns go through approve_return_request for stock restore instead.)
        is_digital = found_item.get(Fields.IS_DIGITAL, False)
        if not is_digital:
            product_updates = {
                Fields.STOCK_QUANTITY: get_firestore().Increment(item_quantity),
                Fields.UPDATED_AT: get_server_timestamp(),
            }

            fulfillment_wh = found_item.get(Fields.FULFILLMENT_WAREHOUSE_ID) if found_item else None
            if fulfillment_wh:
                product_updates[f"{Fields.WAREHOUSE_STOCK}.{fulfillment_wh}"] = get_firestore().Increment(item_quantity)

            transaction.update(product_ref, product_updates)

            if fulfillment_wh:
                inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(fulfillment_wh)
                transaction.set(inv_ref, {
                    Fields.AVAILABLE_QUANTITY: get_firestore().Increment(item_quantity),
                    Fields.UPDATED_AT: get_server_timestamp(),
                }, merge=True)
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

    # Record refund event
    OrderEvent.write(
        get_db(), order_id, OrderEventTypes.REFUND_ISSUED,
        actor=user_id, actor_type="seller" if is_item_seller else "admin",
        metadata={"productId": product_id, "refundAmountCents": refund_amount_cents, "refundId": refund.id},
    )

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

    # Permission check: Only the buyer (order owner) can confirm receipt
    if order_data.get(Fields.USER_ID) != user_id:
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
            # For free-shipping orders, use an absolute max cap (e.g. $500 CAD) instead of
            # percentage-of-zero which would always be 0, blocking all valid approvals.
            _ABSOLUTE_MAX_SHIPPING_CENTS = 50000  # $500 CAD hard cap
            if old_shipping_cost_cents == 0:
                max_allowed_cents = _ABSOLUTE_MAX_SHIPPING_CENTS
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
                try:
                    shipping_tax_rate = get_tax_rate(state_code)
                except ValueError:
                    shipping_tax_rate = get_tax_rate(BusinessRules.DEFAULT_PROVINCE)
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
                Fields.SHIPPING_APPROVAL_STATUS: ShippingApprovalStatusValues.APPROVED,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
            if updated_taxes:
                update_fields[Fields.TAXES] = updated_taxes

            # AUDIT FIX (H4): Call Stripe BEFORE Firestore commit
            # If Stripe fails, the transaction is not committed — consistent state preserved
            # AUTO-CAPTURE MODE: PaymentIntent is already captured — cannot modify its amount.
            # Skip PI modification for captured payments; Firestore is the source of truth for totals.
            # The shipping difference is absorbed by the platform and flagged for reconciliation.
            payment_status_at_approval = fresh_data.get(Fields.PAYMENT_STATUS)
            if (
                difference_cents + tax_difference_cents > 0
                and payment_status_at_approval != PaymentStatusValues.CAPTURED
            ):
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
            elif (
                difference_cents + tax_difference_cents > 0
                and payment_status_at_approval == PaymentStatusValues.CAPTURED
            ):
                # Auto-capture mode: payment already captured for original amount.
                # Log the discrepancy for manual reconciliation — seller absorbs the difference.
                logger.warning(
                    f"Shipping cost approved on already-captured order {order_id}: "
                    f"+{(difference_cents + tax_difference_cents) / 100:.2f} CAD difference flagged for reconciliation."
                )

            txn.update(order_ref, update_fields)
            return new_total_cents

        approve_with_tax_recalc(transaction)
    else:
        # Buyer rejected — re-read payment_status inside a transaction to avoid stale data
        from firebase_admin import firestore as fs

        reject_txn = get_db().transaction()

        @fs.transactional
        def _reject_shipping_transactional(txn):
            fresh_doc = order_ref.get(transaction=txn)
            if not fresh_doc.exists:
                raise https_fn.HttpsError("not-found", "Order not found")
            fresh_data = fresh_doc.to_dict()

            fresh_approval = fresh_data.get(Fields.SHIPPING_APPROVAL, {})
            if fresh_approval.get(Fields.STATUS) != ShippingApprovalStatusValues.PENDING:
                raise https_fn.HttpsError("failed-precondition", "No pending shipping approval")

            cancel_payment_status = fresh_data.get(Fields.PAYMENT_STATUS)
            payment_intent_id = fresh_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)

            # Release buyer funds depending on capture mode:
            # - AUTHORIZED (manual-capture): cancel the PaymentIntent
            # - CAPTURED (auto-capture): issue a full refund
            # Guard against double-refund if order was already refunded (idempotency)
            if cancel_payment_status in (PaymentStatusValues.REFUNDED, PaymentStatusValues.PARTIALLY_REFUNDED):
                raise https_fn.HttpsError("failed-precondition", "Order already refunded")

            if payment_intent_id and cancel_payment_status == PaymentStatusValues.AUTHORIZED:
                try:
                    stripe.PaymentIntent.cancel(
                        payment_intent_id,
                        cancellation_reason="requested_by_customer",
                    )
                    cancel_payment_status = PaymentStatusValues.CANCELLED
                except stripe.error.StripeError as e:
                    logger.error(f"PaymentIntent cancel failed on shipping rejection: {str(e)}")
            elif payment_intent_id and cancel_payment_status == PaymentStatusValues.CAPTURED:
                # Auto-capture mode: refund the full captured amount
                try:
                    stripe.Refund.create(
                        payment_intent=payment_intent_id,
                        reason="requested_by_customer",
                        metadata={Fields.ORDER_ID: order_id, "reason": "shipping_cost_rejected"},
                        idempotency_key=f"shipping_reject_refund_{order_id}",
                    )
                    cancel_payment_status = PaymentStatusValues.REFUNDED
                except stripe.error.StripeError as e:
                    logger.error(f"Refund failed on shipping rejection (captured order): {str(e)}")
                    txn.update(
                        order_ref,
                        {
                            Fields.REQUIRES_MANUAL_REVIEW: True,
                            Fields.MANUAL_REVIEW_REASON: (
                                f"Refund failed after shipping cost rejection: {type(e).__name__}. "
                                "Buyer funds remain captured. Manual refund required."
                            ),
                            Fields.UPDATED_AT: get_server_timestamp(),
                        },
                    )
                    raise https_fn.HttpsError(
                        "internal",
                        "Shipping rejected but refund failed. Flagged for manual review.",
                    ) from e

            txn.update(
                order_ref,
                {
                    f"{Fields.SHIPPING_APPROVAL}.{Fields.STATUS}": ShippingApprovalStatusValues.REJECTED,
                    f"{Fields.SHIPPING_APPROVAL}.{Fields.RESPONDED_AT}": get_server_timestamp(),
                    Fields.SHIPPING_APPROVAL_STATUS: ShippingApprovalStatusValues.REJECTED,
                    Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                    Fields.PAYMENT_STATUS: cancel_payment_status,
                    Fields.CANCELLATION_REASON: "Buyer rejected shipping cost",
                    Fields.UPDATED_AT: get_server_timestamp(),
                },
            )
            return fresh_data.get(Fields.ITEMS, [])

        items_to_restore = _reject_shipping_transactional(reject_txn)

        # Restore stock atomically with order cancellation in a batch
        reject_batch = get_db().batch()
        _restore_stock_to_batch(reject_batch, items_to_restore)
        reject_batch.commit()
        order_ref.update({Fields.STOCK_RESTORED: True, Fields.UPDATED_AT: get_server_timestamp()})

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

    # Allow shipping cost update for both authorized (manual-capture) and captured (auto-capture) payments.
    allowed_payment_statuses = [PaymentStatusValues.AUTHORIZED, PaymentStatusValues.CAPTURED]
    if order_data.get(Fields.PAYMENT_STATUS) not in allowed_payment_statuses:
        raise https_fn.HttpsError(
            "failed-precondition",
            f"Cannot update shipping cost: payment status is '{order_data.get(Fields.PAYMENT_STATUS)}'",
        )

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
            try:
                shipping_tax_rate = get_tax_rate(state_code)
            except ValueError:
                shipping_tax_rate = get_tax_rate(BusinessRules.DEFAULT_PROVINCE)
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
            Fields.ACTUAL_SHIPPING_CENTS: new_shipping_cents,
            Fields.UPDATED_AT: get_server_timestamp(),
        }

        # AUDIT FIX (H4): Only update totals if payment NOT yet captured.
        # Captured totals must remain fixed to reflect actual money taken.
        payment_status = order_data.get(Fields.PAYMENT_STATUS)
        if payment_status != PaymentStatusValues.CAPTURED:
            update_data[Fields.TAX_AMOUNT_CENTS] = new_tax_cents
            update_data[Fields.TOTAL_AMOUNT_CENTS] = new_total_cents
            if updated_taxes:
                update_data[Fields.TAXES] = updated_taxes
        else:
            # If captured, we still record the discrepancy
            update_data[Fields.SHIPPING_DIFF_CENTS] = difference_cents
            update_data[Fields.TAX_DIFF_CENTS] = tax_difference_cents

        # AUDIT FIX (H4): Update Stripe PaymentIntent BEFORE Firestore
        if difference_cents + tax_difference_cents != 0:
            payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
            payment_status = order_data.get(Fields.PAYMENT_STATUS)
            if payment_intent_id and payment_status == PaymentStatusValues.CAPTURED:
                # FIX-2: Captured PIs cannot be modified — log delta for reconciliation
                logger.warning(
                    f"Shipping delta {difference_cents} cents not applied to captured PI {order_id} — flagged for reconciliation"
                )
                order_ref.update({
                    Fields.REQUIRES_MANUAL_REVIEW: True,
                    Fields.MANUAL_REVIEW_REASON: (
                        f"Shipping delta {difference_cents} cents not synced to captured PI"
                    ),
                    Fields.UPDATED_AT: get_server_timestamp(),
                })
            elif payment_intent_id:
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


# ─────────────────────────────── RETURN REQUESTS ──────────────────────────────

def _assert_within_return_window(item_data: dict) -> None:
    """Shared helper — raises if the return window has expired."""
    delivered_at = item_data.get(Fields.DELIVERED_AT)
    if delivered_at:
        if isinstance(delivered_at, str):
            delivered_at = datetime.fromisoformat(delivered_at)
        if hasattr(delivered_at, "tzinfo") and delivered_at.tzinfo is None:
            delivered_at = delivered_at.replace(tzinfo=UTC)
        elapsed = (datetime.now(UTC) - delivered_at).days
        if elapsed > BusinessRules.RETURN_WINDOW_DAYS:
            raise https_fn.HttpsError(
                "failed-precondition",
                f"Return window expired. Returns must be requested within {BusinessRules.RETURN_WINDOW_DAYS} days of delivery.",
            )


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_return_request(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Creates a return request for a delivered physical order item.

    Request data:
        orderId: Order ID
        productId: Product ID being returned
        returnReason: Buyer's reason (required, max 1000 chars)

    Returns:
        {success: True, returnId: str}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="create_return_request", max_requests=5, window_minutes=10, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    from utils.helpers import sanitized_text

    buyer_id = req.auth.uid
    data = req.data
    order_id = data.get(Fields.ORDER_ID)
    product_id = data.get(Fields.PRODUCT_ID)
    return_reason = sanitized_text(data.get(Fields.RETURN_REASON, ""))[:1000]

    if not order_id or not product_id:
        raise https_fn.HttpsError("invalid-argument", "orderId and productId required")
    if not return_reason.strip():
        raise https_fn.HttpsError("invalid-argument", "returnReason is required")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    if order_data.get(Fields.USER_ID) != buyer_id:
        raise https_fn.HttpsError("permission-denied", "You can only return items from your own orders")

    # Find item
    item_data = None
    for item in order_data.get(Fields.ITEMS, []):
        if item.get(Fields.PRODUCT_ID) == product_id:
            item_data = item
            break
    if item_data is None:
        raise https_fn.HttpsError("not-found", "Item not found in this order")

    if item_data.get(Fields.IS_DIGITAL, False):
        raise https_fn.HttpsError("invalid-argument", "Digital products cannot be returned")

    item_status = item_data.get(Fields.STATUS)
    # H4: Return requires DELIVERED status explicitly — confirmed_by_buyer alone is not sufficient
    if item_status != DeliveryStatusValues.DELIVERED:
        raise https_fn.HttpsError("failed-precondition", "Item must be marked as delivered before requesting a return")

    _assert_within_return_window(item_data)

    # Check for existing active return request
    existing = (
        get_db()
        .collection(Collections.RETURN_REQUESTS)
        .where(Fields.ORDER_ID, "==", order_id)
        .where(Fields.PRODUCT_ID, "==", product_id)
        .where(Fields.BUYER_ID, "==", buyer_id)
        .limit(1)
        .get()
    )
    for doc in existing:
        ex_status = doc.to_dict().get(Fields.RETURN_STATUS)
        if ex_status not in (ReturnStatusValues.REJECTED, ReturnStatusValues.REFUNDED):
            raise https_fn.HttpsError("already-exists", "A return request already exists for this item")

    return_ref = get_db().collection(Collections.RETURN_REQUESTS).document()
    return_id = return_ref.id
    now_utc = datetime.now(UTC)

    return_doc = {
        Fields.RETURN_ID: return_id,
        Fields.ORDER_ID: order_id,
        Fields.CART_ITEM_ID: item_data.get(Fields.CART_ITEM_ID, ""),
        Fields.BUYER_ID: buyer_id,
        Fields.SELLER_ID: item_data.get(Fields.SELLER_ID, ""),
        Fields.PRODUCT_ID: product_id,
        Fields.PRODUCT_NAME: item_data.get(Fields.NAME, ""),
        Fields.QUANTITY: item_data.get(Fields.QUANTITY, 1),
        Fields.FULFILLMENT_WAREHOUSE_ID: item_data.get(Fields.FULFILLMENT_WAREHOUSE_ID, ""),
        Fields.RETURN_STATUS: ReturnStatusValues.REQUESTED,
        Fields.RETURN_REASON: return_reason,
        Fields.REQUESTED_AT: now_utc,
        Fields.UPDATED_AT: now_utc,
    }
    return_ref.set(return_doc)

    # Notify seller via push
    seller_id = item_data.get(Fields.SELLER_ID)
    if seller_id:
        send_push_notification(
            seller_id,
            "Return Request",
            f"A buyer has requested a return for order #{order_id[:8].upper()}",
            data={"type": "return_request", "orderId": order_id, "returnId": return_id},
        )

    return create_success_response({Fields.RETURN_ID: return_id})


def _process_return_refund(order_id: str, product_id: str, return_id: str, buyer_id: str) -> None:
    """Internal helper: execute Stripe refund for a return and transition statuses.

    Called from mark_received action in approve_return_request once item is physically received.
    Transitions: return_request → refunded, order item → refunded.
    Idempotent — skips if item already refunded.
    """
    from datetime import datetime as _dt

    import stripe as _stripe

    db = get_db()
    order_ref = db.collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    if not order_doc.exists:
        logger.error(f"_process_return_refund: order {order_id} not found")
        return

    order_data = order_doc.to_dict()
    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    if not payment_intent_id:
        logger.error(f"_process_return_refund: no payment intent on order {order_id}")
        return

    items = order_data.get(Fields.ITEMS, [])
    item_data = next((it for it in items if it.get(Fields.PRODUCT_ID) == product_id), None)
    if not item_data:
        logger.error(f"_process_return_refund: product {product_id} not in order {order_id}")
        return

    if item_data.get(Fields.STATUS) == DeliveryStatusValues.REFUNDED:
        logger.info(f"_process_return_refund: item {product_id} already refunded, skipping")
        _finalise_return_refunded(order_id, product_id, return_id)
        return

    # Calculate proportional refund amount (item + proportional tax + proportional shipping)
    item_price_cents = round(item_data.get(Fields.PRICE, 0) * 100)
    item_quantity = item_data.get(Fields.QUANTITY, 1)
    item_subtotal_cents = item_price_cents * item_quantity
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

    try:
        refund = _stripe.Refund.create(
            payment_intent=payment_intent_id,
            amount=refund_amount_cents,
            reason="requested_by_customer",
            metadata={
                Fields.ORDER_ID: order_id,
                Fields.PRODUCT_ID: product_id,
                Fields.RETURN_ID: return_id,
            },
            idempotency_key=f"return_refund_{return_id}_{product_id}",
        )
    except _stripe.error.StripeError as e:
        logger.error(f"_process_return_refund: Stripe refund failed for return {return_id}: {e}")
        return

    # Update order item status to refunded atomically
    now_utc = _dt.now(UTC)
    updated_items = list(items)
    for idx, it in enumerate(updated_items):
        if it.get(Fields.PRODUCT_ID) == product_id:
            updated_items[idx] = {
                **it,
                Fields.STATUS: DeliveryStatusValues.REFUNDED,
                Fields.REFUNDED_AT: now_utc,
                Fields.REFUND_REASON: "Return approved",
                Fields.REFUND_AMOUNT_CENTS: refund_amount_cents,
                Fields.REFUND_ID: refund.id,
            }
            break
    order_ref.update({Fields.ITEMS: updated_items, Fields.UPDATED_AT: now_utc})
    _finalise_return_refunded(order_id, product_id, return_id)
    logger.info(f"_process_return_refund: refund {refund.id} issued for return {return_id}")


def _finalise_return_refunded(order_id: str, product_id: str, return_id: str) -> None:
    """Mark the return request as refunded."""
    db = get_db()
    return_ref = db.collection(Collections.RETURN_REQUESTS).document(return_id)
    return_ref.update({
        Fields.RETURN_STATUS: ReturnStatusValues.REFUNDED,
        Fields.UPDATED_AT: get_server_timestamp(),
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def approve_return_request(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Seller or admin approves a return request.
    Transitions: requested → approved.
    Restores stock after physical item confirmed received (received → refunded).

    Request data:
        returnId: Return request ID
        action: 'approve' | 'mark_received'  (seller) or 'reject' (redirects to reject_return_request)
        returnTrackingNumber: Optional tracking number for label
        returnAdminNote: Optional note
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="approve_return_request", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_id = req.auth.uid
    data = req.data
    return_id = data.get(Fields.RETURN_ID)
    action = data.get("action", "approve")

    if not return_id:
        raise https_fn.HttpsError("invalid-argument", "returnId required")

    # Validate permissions — must be seller or admin
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in (user_data.get(Fields.ROLES) or [])

    return_ref = get_db().collection(Collections.RETURN_REQUESTS).document(return_id)
    return_doc = return_ref.get()
    if not return_doc.exists:
        raise https_fn.HttpsError("not-found", "Return request not found")

    return_data = return_doc.to_dict()
    seller_id = return_data.get(Fields.SELLER_ID)
    buyer_id = return_data.get(Fields.BUYER_ID)
    order_id = return_data.get(Fields.ORDER_ID)
    product_id = return_data.get(Fields.PRODUCT_ID)
    current_status = return_data.get(Fields.RETURN_STATUS)

    if not is_admin and user_id != seller_id:
        raise https_fn.HttpsError("permission-denied", "Only the seller or admin can approve return requests")

    # State machine
    if action == "approve":
        if current_status not in ReturnStatusValues.VALID_TRANSITIONS or "approved" not in ReturnStatusValues.VALID_TRANSITIONS.get(current_status, set()):
            raise https_fn.HttpsError("failed-precondition", f"Cannot approve return in status '{current_status}'")
        new_status = ReturnStatusValues.APPROVED
        tracking_number = data.get(Fields.RETURN_TRACKING_NUMBER)
        admin_note = data.get(Fields.RETURN_ADMIN_NOTE)
        patches: dict = {
            Fields.RETURN_STATUS: new_status,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
        if tracking_number:
            patches[Fields.RETURN_TRACKING_NUMBER] = tracking_number
        if admin_note:
            patches[Fields.RETURN_ADMIN_NOTE] = admin_note
        return_ref.update(patches)

        # Notify buyer
        send_push_notification(
            buyer_id,
            "Return Approved",
            "Your return request has been approved. Please ship the item back.",
            data={"type": NotificationTypes.RETURN_STATUS, "orderId": order_id, "returnId": return_id},
        )

    elif action == "issue_label":
        if "label_issued" not in ReturnStatusValues.VALID_TRANSITIONS.get(current_status, set()):
            raise https_fn.HttpsError("failed-precondition", f"Cannot issue label from status '{current_status}'")
        new_status = ReturnStatusValues.LABEL_ISSUED
        tracking_number = data.get(Fields.RETURN_TRACKING_NUMBER)
        patches_label: dict = {
            Fields.RETURN_STATUS: new_status,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
        if tracking_number:
            patches_label[Fields.RETURN_TRACKING_NUMBER] = tracking_number
        return_ref.update(patches_label)

        # Notify buyer that label is ready
        send_push_notification(
            buyer_id,
            "Return Label Issued",
            "Your return shipping label has been issued. Please use it to ship the item back.",
            data={"type": NotificationTypes.RETURN_STATUS, "orderId": order_id, "returnId": return_id},
        )

    elif action == "mark_received":
        fs = get_firestore()
        db = get_db()
        product_ref = db.collection(Collections.PRODUCTS).document(product_id)
        qty = return_data.get(Fields.QUANTITY, 1)

        @fs.transactional
        def _mark_received_txn(transaction):
            ret_snap = return_ref.get(transaction=transaction)
            if not ret_snap.exists:
                raise https_fn.HttpsError("not-found", "Return request not found")

            curr_status = ret_snap.to_dict().get(Fields.RETURN_STATUS)
            if "received" not in ReturnStatusValues.VALID_TRANSITIONS.get(curr_status, set()):
                raise https_fn.HttpsError("failed-precondition", f"Cannot mark received from status '{curr_status}'")

            new_status = ReturnStatusValues.RECEIVED

            transaction.update(return_ref, {
                Fields.RETURN_STATUS: new_status,
                Fields.UPDATED_AT: get_server_timestamp(),
            })

            stock_patch = {
                Fields.STOCK_QUANTITY: fs.Increment(qty),
                Fields.UPDATED_AT: get_server_timestamp(),
            }
            fulfillment_wh = return_data.get(Fields.FULFILLMENT_WAREHOUSE_ID, "")
            if fulfillment_wh:
                stock_patch[f"{Fields.WAREHOUSE_STOCK}.{fulfillment_wh}"] = fs.Increment(qty)
            transaction.update(product_ref, stock_patch)

            # Restore inventoryLevels subcollection (best-effort inside transaction)
            if fulfillment_wh:
                inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(fulfillment_wh)
                transaction.set(inv_ref, {
                    Fields.AVAILABLE_QUANTITY: fs.Increment(qty),
                    Fields.LAST_SYNCED_AT: get_server_timestamp(),
                }, merge=True)

            return new_status

        txn = get_db().transaction()
        new_status = _mark_received_txn(txn)

        # Initiate Stripe refund and transition return to 'refunded'
        try:
            _process_return_refund(order_id, product_id, return_id, buyer_id)
            new_status = ReturnStatusValues.REFUNDED  # Update for response
        except Exception as _refund_err:
            logger.error(f"mark_received: refund initiation failed for return {return_id}: {_refund_err}")

        # Notify buyer
        send_push_notification(
            buyer_id,
            "Return Received",
            "Seller has confirmed receipt of your returned item. Refund is being processed.",
            data={"type": NotificationTypes.RETURN_STATUS, "orderId": order_id, "returnId": return_id},
        )
    else:
        raise https_fn.HttpsError("invalid-argument", f"Invalid action '{action}'. Use 'approve', 'issue_label', or 'mark_received'")

    return create_success_response({Fields.RETURN_STATUS: new_status, Fields.RETURN_ID: return_id})


@https_fn.on_call(**DEFAULT_OPTIONS)
def reject_return_request(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Seller or admin rejects a return request.
    Transitions: requested → rejected OR approved → rejected.

    Request data:
        returnId: Return request ID
        returnAdminNote: Rejection reason (required)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=req.auth.uid, action="reject_return_request", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    from utils.helpers import sanitized_text

    user_id = req.auth.uid
    data = req.data
    return_id = data.get(Fields.RETURN_ID)
    rejection_note = sanitized_text(data.get(Fields.RETURN_ADMIN_NOTE, ""))[:1000]

    if not return_id:
        raise https_fn.HttpsError("invalid-argument", "returnId required")
    if not rejection_note.strip():
        raise https_fn.HttpsError("invalid-argument", "returnAdminNote (rejection reason) is required")

    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")
    user_data = user_doc.to_dict()
    is_admin = UserRoleValues.ADMIN in (user_data.get(Fields.ROLES) or [])

    return_ref = get_db().collection(Collections.RETURN_REQUESTS).document(return_id)
    return_doc = return_ref.get()
    if not return_doc.exists:
        raise https_fn.HttpsError("not-found", "Return request not found")

    return_data = return_doc.to_dict()
    seller_id = return_data.get(Fields.SELLER_ID)
    buyer_id = return_data.get(Fields.BUYER_ID)
    order_id = return_data.get(Fields.ORDER_ID)
    current_status = return_data.get(Fields.RETURN_STATUS)

    if not is_admin and user_id != seller_id:
        raise https_fn.HttpsError("permission-denied", "Only the seller or admin can reject return requests")

    if ReturnStatusValues.REJECTED not in ReturnStatusValues.VALID_TRANSITIONS.get(current_status, set()):
        raise https_fn.HttpsError("failed-precondition", f"Cannot reject return in status '{current_status}'")

    return_ref.update({
        Fields.RETURN_STATUS: ReturnStatusValues.REJECTED,
        Fields.RETURN_ADMIN_NOTE: rejection_note,
        Fields.RESOLVED_AT: get_server_timestamp(),
        Fields.UPDATED_AT: get_server_timestamp(),
    })

    # Notify buyer
    send_push_notification(
        buyer_id,
        "Return Rejected",
        "Your return request has been reviewed. Please contact support if you have questions.",
        data={"type": NotificationTypes.RETURN_STATUS, "orderId": order_id, "returnId": return_id},
    )

    return create_success_response({Fields.RETURN_STATUS: ReturnStatusValues.REJECTED, Fields.RETURN_ID: return_id})


def _handle_payment_status_email(order_id: str, after_data: dict, payment_status: str, buyer_email: str | None = None) -> None:
    """Send refund notification emails when paymentStatus changes."""
    if payment_status not in (PaymentStatusValues.REFUNDED, PaymentStatusValues.PARTIALLY_REFUNDED):
        return

    # Dedup guard: skip if email for this payment status was already sent
    dedup_key = f"payment_email:{payment_status}"
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    # B3: Use canonical get_firestore() for ArrayUnion instead of firebase_admin.firestore alias
    from google.cloud.firestore_v1 import transaction as _ps_txn_mod

    @_ps_txn_mod.transactional
    def _claim_payment_email_slot(txn):
        fresh = order_ref.get(transaction=txn)
        if not fresh.exists:
            return False
        sent = (fresh.to_dict() or {}).get(Fields.NOTIFICATIONS_SENT, [])
        if dedup_key in sent:
            return False
        txn.update(order_ref, {Fields.NOTIFICATIONS_SENT: get_firestore().ArrayUnion([dedup_key])})
        return True

    try:
        claimed = _claim_payment_email_slot(get_db().transaction())
    except Exception as flag_err:
        logger.warning(f"Failed to claim payment email slot for {order_id}/{payment_status}: {flag_err}")
        claimed = False
    if not claimed:
        logger.info(f"Payment status email already sent for order {order_id} status={payment_status}, skipping")
        return

    user_id = after_data.get(Fields.USER_ID)
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
        return
    lang = after_data.get(Fields.PREFERRED_LANGUAGE, "en")
    oid_short = order_id[:8]
    try:
        if payment_status == PaymentStatusValues.REFUNDED:
            refund_amount = after_data.get(Fields.CUMULATIVE_REFUNDED_CENTS, 0)
            refunded_html = get_order_refunded_email(after_data, order_id, refund_amount, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.refunded", lang).replace("{oid}", oid_short),
                html_content=refunded_html,
                event_type="order_refunded",
                order_id=order_id,
            )
        elif payment_status == PaymentStatusValues.PARTIALLY_REFUNDED:
            refund_amount = after_data.get(Fields.PARTIAL_REFUND_AMOUNT_CENTS, 0)
            partial_html = get_order_partially_refunded_email(after_data, order_id, refund_amount, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.partial", lang).replace("{oid}", oid_short),
                html_content=partial_html,
                event_type="order_partially_refunded",
                order_id=order_id,
            )
    except Exception as e:
        logger.error(f"🚨 Failed to send refund email for order {order_id}: {str(e)}")


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

    # Always check if paymentStatus changed (e.g. for refund emails)
    # This must happen even if orderStatus also changed
    old_payment_status = before_data.get(Fields.PAYMENT_STATUS)
    new_payment_status = after_data.get(Fields.PAYMENT_STATUS)
    if old_payment_status != new_payment_status:
        _handle_payment_status_email(order_id, after_data, new_payment_status, buyer_email=None)

    if old_status == new_status:
        return

    # Transactional dedup — claim slot atomically to prevent duplicate sends on retries
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    from firebase_admin import firestore as _fs_dedup
    from google.cloud.firestore_v1 import transaction as _txn_mod

    @_txn_mod.transactional
    def _claim_notification(txn):
        fresh = order_ref.get(transaction=txn)
        if not fresh.exists:
            return False
        sent = (fresh.to_dict() or {}).get(Fields.NOTIFICATIONS_SENT, [])
        if new_status in sent:
            return False
        txn.update(order_ref, {Fields.NOTIFICATIONS_SENT: _fs_dedup.ArrayUnion([new_status])})
        return True

    try:
        claimed = _claim_notification(get_db().transaction())
    except Exception as flag_err:
        logger.warning(f"Failed to claim notification slot for {order_id}/{new_status}: {flag_err}")
        claimed = False
    if not claimed:
        logger.info(f"Notification already sent for order {order_id} status={new_status}, skipping")
        return

    # Send notification emails based on status change
    user_id = after_data.get(Fields.USER_ID)

    # CRITICAL FIX: Fetch actual buyer email from user document (not user_id!)
    buyer_email = after_data.get(Fields.CUSTOMER_EMAIL)
    if not buyer_email:
        try:
            buyer_doc = get_db().collection(Collections.USERS).document(user_id).get()
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
        if new_status == OrderStatusValues.CONFIRMED:
            # Order confirmed — send confirmation email + push to buyer
            confirmed_html = get_order_confirmation_email(after_data, order_id, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.confirmed", lang).replace("{oid}", oid_short),
                html_content=confirmed_html,
                event_type="order_confirmed",
                order_id=order_id,
            )
            send_push_notification(
                user_id, "Order Confirmed!", f"Your order #{oid_short} has been confirmed",
                data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
            )

        elif new_status == OrderStatusValues.PROCESSING:
            processing_html = get_order_processing_email(after_data, order_id, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.processing", lang).replace("{oid}", oid_short),
                html_content=processing_html,
                event_type="order_processing",
                order_id=order_id,
            )
            send_push_notification(
                user_id, "Order Update", f"Your order #{oid_short} is being processed",
                data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
            )

        # Clean up stock_notifications only after a successful purchase
        # so the buyer is not re-notified about products they already purchased.
        # CANCELLED and FAILED orders must NOT clear subscriptions — no purchase happened.
        if new_status in {
            OrderStatusValues.CONFIRMED,
            OrderStatusValues.PROCESSING,
        }:
            try:
                batch = get_db().batch()
                for item in after_data.get(Fields.ITEMS, []):
                    pid = item.get(Fields.PRODUCT_ID)
                    if not pid:
                        continue
                    # Filter by variantKey so buying variantA doesn't clear the
                    # subscription the buyer has for a different variantB on the same product.
                    variant_key = item.get(Fields.VARIANT_KEY, "")
                    subs = list(
                        get_db()
                        .collection(Collections.STOCK_NOTIFICATIONS)
                        .where(Fields.PRODUCT_ID, "==", pid)
                        .where(Fields.USER_ID, "==", user_id)
                        .where(Fields.VARIANT_KEY, "==", variant_key)
                        .limit(10)
                        .stream()
                    )
                    for sub in subs:
                        batch.delete(sub.reference)
                batch.commit()
            except Exception as sub_err:
                logger.warning(f"Failed to cleanup stock_notifications after order {order_id}: {sub_err}")

        elif new_status == OrderStatusValues.SHIPPED:
            tracking_number = after_data.get(Fields.TRACKING_NUMBER, "N/A")
            carrier = after_data.get(Fields.CARRIER, "N/A")
            is_pickup = after_data.get(Fields.DELIVERY_SPEED) == DeliveryTypeValues.PICKUP

            # For pickup orders, on_order_item_shipped sends the "Ready for Pickup" email
            # synchronously (for fast E2E test visibility). Skip email here to avoid duplicate.
            if not is_pickup:
                shipped_html = get_order_shipped_email(after_data, order_id, tracking_number, carrier, lang=lang)
                enqueue_email_task(
                    to_email=buyer_email,
                    subject=_email_t("sub.shipped", lang).replace("{oid}", oid_short),
                    html_content=shipped_html,
                    event_type="order_shipped",
                    order_id=order_id,
                )
            push_body = (f"Order #{oid_short} is ready for pickup!" if is_pickup
                         else f"Order #{oid_short} is on its way via {carrier}")
            send_push_notification(
                user_id, "Order Shipped!", push_body,
                data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
            )

            # Also notify sellers that shipment confirmed — filtered to their items only
            # Skip the seller who triggered the transition (stored in lastActorId if set)
            last_actor_id = after_data.get(Fields.LAST_ACTOR_ID)
            seller_ids = set(item.get(Fields.SELLER_ID) for item in after_data.get(Fields.ITEMS, []))
            # Batch-read all seller docs in one RPC (avoids N sequential reads for multi-seller orders)
            seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
            seller_docs = {doc.id: doc for doc in get_db().get_all(seller_refs)}
            for sid in seller_ids:
                # Skip self-notification: if there's only one seller and they are the actor, skip email
                if last_actor_id and sid == last_actor_id:
                    continue
                try:
                    seller_doc = seller_docs.get(sid)
                    if seller_doc and seller_doc.exists:
                        seller_data = seller_doc.to_dict()
                        seller_email = seller_data.get(Fields.EMAIL)
                        if seller_email:
                            seller_lang = seller_data.get(Fields.PREFERRED_LANGUAGE, "en")
                            # Use seller notification with seller_id filter (multi-seller privacy)
                            seller_shipped_html = get_seller_notification_email(
                                after_data, order_id, sid, lang=seller_lang
                            )
                            enqueue_email_task(
                                to_email=seller_email,
                                subject=_email_t("sub.shipped_seller", seller_lang).replace("{oid}", oid_short),
                                html_content=seller_shipped_html,
                                event_type="order_shipped_seller",
                                order_id=order_id,
                            )
                        send_push_notification(
                            sid, "Shipment Confirmed", f"Order #{oid_short} has been marked as shipped",
                            data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
                        )
                except Exception as e:
                    logger.warning(f"⚠️ Failed to send shipped notification to seller {sid}: {str(e)}")

        elif new_status == OrderStatusValues.IN_TRANSIT:
            # Email buyer — in transit update with tracking info
            in_transit_html = get_order_in_transit_email(after_data, order_id, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.in_transit", lang).replace("{oid}", oid_short),
                html_content=in_transit_html,
                event_type="order_in_transit",
                order_id=order_id,
            )
            send_push_notification(
                user_id, "In Transit", f"Order #{oid_short} is in transit",
                data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
            )

        elif new_status == OrderStatusValues.DELIVERED:
            # FIX F5-1: Distinguish buyer-triggered DELIVERED (confirmed_by_client=True)
            # from admin/cron-triggered DELIVERED. If buyer confirmed or cron auto-confirmed,
            # don't re-ask them to confirm receipt — send an acknowledgement email instead.
            buyer_confirmed = after_data.get(Fields.CONFIRMED_BY_CLIENT, False)
            auto_confirmed = after_data.get(Fields.AUTO_CONFIRMED, False)

            if buyer_confirmed or auto_confirmed:
                # Buyer confirmed or cron auto-confirmed — send acknowledgement, not "please confirm"
                subj_en = f"Receipt Confirmed — Order #{oid_short}"
                subj_fr = f"Réception confirmée — Commande #{oid_short}"
                subj = subj_fr if lang == "fr" else subj_en
                body_en = (
                    f"<p>Your receipt confirmation for order <strong>#{oid_short}</strong> has been recorded. "
                    f"The seller will be paid out shortly. Thank you for shopping with Origna!</p>"
                )
                body_fr = (
                    f"<p>Votre confirmation de réception pour la commande <strong>#{oid_short}</strong> a été enregistrée. "
                    f"Le vendeur sera payé sous peu. Merci de faire confiance à Origna !</p>"
                )
                body = body_fr if lang == "fr" else body_en
                from services.email_service import _email_wrapper as _ew, _hero_header as _hh  # noqa: E402,I001
                receipt_content = _hh("✅", subj_en if lang == "en" else subj_fr,
                                       f"Order #{oid_short}", "rgba(16, 185, 129, 0.2)")
                receipt_content += f"<tr><td style='padding:28px 40px;font-size:14px;color:#333;line-height:1.6;'>{body}</td></tr>"
                receipt_html = _ew("Receipt Confirmed", receipt_content, include_gst=False, lang=lang, recipient_email=buyer_email)
                enqueue_email_task(
                    to_email=buyer_email,
                    subject=subj,
                    html_content=receipt_html,
                    event_type="receipt_confirmed",
                    order_id=order_id,
                )
                send_push_notification(
                    user_id, "Receipt Confirmed ✅", f"Your confirmation for order #{oid_short} is recorded",
                    data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
                )
            else:
                # Courier/admin delivered — ask buyer to confirm receipt
                delivered_html = get_order_delivered_email(after_data, order_id, lang=lang)
                enqueue_email_task(
                    to_email=buyer_email,
                    subject=_email_t("sub.delivered", lang).replace("{oid}", oid_short),
                    html_content=delivered_html,
                    event_type="order_delivered",
                    order_id=order_id,
                )
                send_push_notification(
                    user_id, "Package Delivered!", f"Order #{oid_short} has been delivered. Confirm receipt to release payment",
                    data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
                )

            # FIX F5-2: Email sellers that payout is now pending
            seller_ids = set(item.get(Fields.SELLER_ID) for item in after_data.get(Fields.ITEMS, []))
            seller_refs = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
            seller_docs_map = {doc.id: doc for doc in get_db().get_all(seller_refs)}
            for sid in seller_ids:
                try:
                    sdoc = seller_docs_map.get(sid)
                    if sdoc and sdoc.exists:
                        sdata = sdoc.to_dict()
                        seller_email_addr = sdata.get(Fields.EMAIL)
                        seller_lang = sdata.get(Fields.PREFERRED_LANGUAGE, "en")
                        if seller_email_addr:
                            # Email seller: receipt confirmed / payout pending
                            payout_subj_en = f"Order #{oid_short} — Receipt Confirmed, Payout Pending"
                            payout_subj_fr = f"Commande #{oid_short} — Réception confirmée, paiement en cours"
                            payout_subj = payout_subj_fr if seller_lang == "fr" else payout_subj_en
                            payout_body_en = (
                                f"<p>The buyer has confirmed receipt of order <strong>#{oid_short}</strong>. "
                                f"Your payout is now being processed and will appear in your account within 2-5 business days.</p>"
                            )
                            payout_body_fr = (
                                f"<p>L'acheteur a confirmé la réception de la commande <strong>#{oid_short}</strong>. "
                                f"Votre paiement est en cours de traitement et apparaîtra sur votre compte dans les 2 à 5 jours ouvrables.</p>"
                            )
                            payout_body = payout_body_fr if seller_lang == "fr" else payout_body_en
                            from services.email_service import _email_wrapper as _ew2, _hero_header as _hh2  # noqa: E402,I001
                            payout_content = _hh2("💰", payout_subj_en if seller_lang == "en" else payout_subj_fr,
                                                   f"Order #{oid_short}", "rgba(16, 185, 129, 0.2)")
                            payout_content += f"<tr><td style='padding:28px 40px;font-size:14px;color:#333;line-height:1.6;'>{payout_body}</td></tr>"
                            payout_html = _ew2("Payout Pending", payout_content, include_gst=False, lang=seller_lang, recipient_email=seller_email_addr)
                            enqueue_email_task(
                                to_email=seller_email_addr,
                                subject=payout_subj,
                                html_content=payout_html,
                                event_type="receipt_confirmed_seller",
                                order_id=order_id,
                            )
                    send_push_notification(
                        sid, "Receipt Confirmed" if not buyer_confirmed else "Receipt Confirmed",
                        f"Order #{oid_short} confirmed by buyer — payout pending",
                        data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
                    )
                except Exception as e:
                    logger.warning(f"⚠️ Failed to send delivered notification to seller {sid}: {str(e)}")

        elif new_status == OrderStatusValues.CANCELLED:
            reason = after_data.get(Fields.CANCELLATION_REASON, "Unknown")
            cancelled_html = get_order_cancelled_email(after_data, order_id, reason, lang=lang)
            enqueue_email_task(
                to_email=buyer_email,
                subject=_email_t("sub.cancelled", lang).replace("{oid}", oid_short),
                html_content=cancelled_html,
                event_type="order_cancelled",
                order_id=order_id,
            )
            send_push_notification(
                user_id, "Order Cancelled", f"Order #{oid_short} has been cancelled",
                data={"type": NotificationTypes.ORDER_STATUS, "orderId": order_id, "status": new_status},
            )

    except Exception as e:
        logger.error(f"🚨 Failed to send order status email for order {order_id}: {str(e)}")


def _send_return_email(return_data: dict, return_id: str, order_id: str, buyer_id: str, seller_id: str, status: str) -> None:
    """Fetch buyer/seller emails and send return request notification emails."""
    db = get_db()

    def _fetch_email(uid: str) -> tuple[str | None, str]:
        if not uid:
            return None, "en"
        try:
            doc = db.collection(Collections.USERS).document(uid).get()
            if doc.exists:
                d = doc.to_dict() or {}
                return d.get(Fields.EMAIL), d.get(Fields.PREFERRED_LANGUAGE, "en")
        except Exception as e:
            logger.warning(f"Could not fetch email for user {uid}: {e}")
        return None, "en"

    oid_short = order_id[:8]

    # FIX F6-4: All return emails now go through enqueue_email_task (non-blocking)
    # FIX F6-1/F6-2: Added RECEIVED and REFUNDED email cases
    if status == ReturnStatusValues.REQUESTED:
        # Email seller — new return request alert
        seller_email, seller_lang = _fetch_email(seller_id)
        if seller_email:
            html_body = get_return_request_submitted_email(return_data, return_id, order_id, recipient="seller", lang=seller_lang)
            subject = _email_t("sub.return_requested_seller", seller_lang).replace("{oid}", oid_short)
            enqueue_email_task(to_email=seller_email, subject=subject, html_content=html_body,
                               event_type="return_requested_seller", order_id=order_id)
        # Email buyer — request confirmation
        buyer_email, buyer_lang = _fetch_email(buyer_id)
        if buyer_email:
            html_body = get_return_request_submitted_email(return_data, return_id, order_id, recipient="buyer", lang=buyer_lang)
            subject = _email_t("sub.return_requested_buyer", buyer_lang).replace("{oid}", oid_short)
            enqueue_email_task(to_email=buyer_email, subject=subject, html_content=html_body,
                               event_type="return_requested_buyer", order_id=order_id)

    elif status == ReturnStatusValues.APPROVED:
        buyer_email, buyer_lang = _fetch_email(buyer_id)
        if buyer_email:
            html_body = get_return_request_approved_email(return_data, return_id, order_id, lang=buyer_lang)
            subject = _email_t("sub.return_approved", buyer_lang).replace("{oid}", oid_short)
            enqueue_email_task(to_email=buyer_email, subject=subject, html_content=html_body,
                               event_type="return_approved", order_id=order_id)

    elif status == ReturnStatusValues.REJECTED:
        buyer_email, buyer_lang = _fetch_email(buyer_id)
        if buyer_email:
            html_body = get_return_request_rejected_email(return_data, return_id, order_id, lang=buyer_lang)
            subject = _email_t("sub.return_rejected", buyer_lang).replace("{oid}", oid_short)
            enqueue_email_task(to_email=buyer_email, subject=subject, html_content=html_body,
                               event_type="return_rejected", order_id=order_id)

    elif status == ReturnStatusValues.RECEIVED:
        # FIX F6-1: Email buyer — returned item received, refund in progress
        buyer_email, buyer_lang = _fetch_email(buyer_id)
        if buyer_email:
            html_body = get_return_received_email(return_data, return_id, order_id, lang=buyer_lang)
            subject_en = f"Return Received - Order #{oid_short}"
            subject_fr = f"Retour reçu - Commande #{oid_short}"
            subject = subject_fr if buyer_lang == "fr" else subject_en
            enqueue_email_task(to_email=buyer_email, subject=subject, html_content=html_body,
                               event_type="return_received", order_id=order_id)

    elif status == ReturnStatusValues.REFUNDED:
        # FIX F6-2: Email buyer — return refund processed
        buyer_email, buyer_lang = _fetch_email(buyer_id)
        if buyer_email:
            html_body = get_return_refunded_email(return_data, return_id, order_id, lang=buyer_lang)
            subject_en = f"Your Return Refund Has Been Processed - Order #{oid_short}"
            subject_fr = f"Votre remboursement de retour a été traité - Commande #{oid_short}"
            subject = subject_fr if buyer_lang == "fr" else subject_en
            enqueue_email_task(to_email=buyer_email, subject=subject, html_content=html_body,
                               event_type="return_refunded", order_id=order_id)


@firestore_fn.on_document_updated(document="return_requests/{returnId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_return_request_status_changed(event: firestore_fn.Event) -> None:
    """
    Firestore trigger: Sends push + email notifications when a return request status changes.
    Covers status transitions that may happen outside the CF handlers (admin writes, cron).
    """
    return_id = event.params["returnId"]
    before_data = event.data.before.to_dict() if event.data.before else {}
    after_data = event.data.after.to_dict() if event.data.after else {}

    if not before_data or not after_data:
        return

    old_status = before_data.get(Fields.RETURN_STATUS)
    new_status = after_data.get(Fields.RETURN_STATUS)

    if old_status == new_status:
        return

    order_id = after_data.get(Fields.ORDER_ID, "")
    buyer_id = after_data.get(Fields.BUYER_ID, "")  # return_requests use buyerId not userId
    seller_id = after_data.get(Fields.SELLER_ID, "")
    oid_short = order_id[:8] if order_id else "?"

    # Atomically claim this notification slot (transactional dedup)
    return_ref = get_db().collection(Collections.RETURN_REQUESTS).document(return_id)
    from firebase_admin import firestore as _fs_rr_dedup
    from google.cloud.firestore_v1 import transaction as _rr_txn_mod

    @_rr_txn_mod.transactional
    def _claim_return_notification(txn):
        fresh = return_ref.get(transaction=txn)
        if not fresh.exists:
            return False
        sent = (fresh.to_dict() or {}).get(Fields.NOTIFICATIONS_SENT, [])
        if new_status in sent:
            return False
        txn.update(return_ref, {Fields.NOTIFICATIONS_SENT: _fs_rr_dedup.ArrayUnion([new_status])})
        return True

    try:
        claimed = _claim_return_notification(get_db().transaction())
    except Exception as e:
        logger.warning(f"Failed to claim notification slot for return {return_id}: {e}")
        claimed = False
    if not claimed:
        return

    try:
        if new_status == ReturnStatusValues.REQUESTED and seller_id:
            # New return request — notify seller
            send_push_notification(
                seller_id,
                "New Return Request",
                f"A buyer has requested a return for order #{oid_short}",
                data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
            )
            _send_return_email(after_data, return_id, order_id, buyer_id, seller_id, new_status)
        elif new_status == ReturnStatusValues.APPROVED and buyer_id:
            send_push_notification(
                buyer_id,
                "Return Approved",
                f"Your return request for order #{oid_short} has been approved",
                data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
            )
            _send_return_email(after_data, return_id, order_id, buyer_id, seller_id, new_status)
        elif new_status == ReturnStatusValues.REJECTED and buyer_id:
            send_push_notification(
                buyer_id,
                "Return Rejected",
                f"Your return request for order #{oid_short} has been rejected",
                data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
            )
            _send_return_email(after_data, return_id, order_id, buyer_id, seller_id, new_status)
        elif new_status == ReturnStatusValues.RECEIVED:
            if buyer_id:
                send_push_notification(
                    buyer_id,
                    "Return Received",
                    f"Your returned item for order #{oid_short} has been received — refund processing",
                    data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
                )
            if seller_id:
                send_push_notification(
                    seller_id,
                    "Return Received",
                    f"Returned item for order #{oid_short} marked as received",
                    data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
                )
        elif new_status == ReturnStatusValues.REFUNDED and buyer_id:
            send_push_notification(
                buyer_id,
                "Return Refunded",
                f"Your refund for return on order #{oid_short} has been processed",
                data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
            )
        elif new_status == ReturnStatusValues.ESCALATED and buyer_id:
            send_push_notification(
                buyer_id,
                "Return Escalated",
                f"Your return for order #{oid_short} has been escalated to our support team",
                data={"type": NotificationTypes.RETURN_REQUEST, "orderId": order_id, "returnId": return_id, "status": new_status},
            )
    except Exception as e:
        logger.error(f"🚨 Failed to send return request notification for {return_id}: {str(e)}")


@firestore_fn.on_document_updated(document="orders/{orderId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_order_item_shipped(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggered when an order document is updated.
    Detects when an individual item status changes to 'shipped' and notifies the buyer.
    This is essential for multi-seller orders where items ship at different times.
    """
    before = event.data.before.to_dict()
    after = event.data.after.to_dict()
    if not before or not after:
        return

    order_id = event.params["orderId"]
    before_items = before.get(Fields.ITEMS, [])
    after_items = after.get(Fields.ITEMS, [])

    # FIX-1 (CRITICAL): Guard against double notification.
    # When ALL items ship at once the Firestore transaction also sets orderStatus=SHIPPED,
    # which fires on_order_status_changed.  That trigger sends the canonical "Order Shipped!"
    # push + email.  This trigger handles PARTIAL shipments (multi-seller, first wave).
    # If the order-level status just transitioned to SHIPPED in this same write, bail out —
    # UNLESS it's a pickup order (Ready for Pickup notification must be sent immediately/sync).
    before_order_status = before.get(Fields.ORDER_STATUS)
    after_order_status = after.get(Fields.ORDER_STATUS)
    is_pickup_order = after.get(Fields.DELIVERY_SPEED) == DeliveryTypeValues.PICKUP
    if (before_order_status != OrderStatusValues.SHIPPED
            and after_order_status == OrderStatusValues.SHIPPED
            and not is_pickup_order):
        return  # on_order_status_changed will handle the full-order shipped notification

    # FIX-2 (HIGH): Use cartItemId as the unique item key.
    # productId + warehouseId collides when a buyer orders the same SKU twice in the same
    # warehouse (two separate line items share the same productId and warehouseId).
    # cartItemId is generated per line item at add-to-cart time and is always unique.
    def _item_key(item):
        cid = item.get(Fields.CART_ITEM_ID)
        if not cid:
            raise ValueError(f"OrderItem missing cartItemId — data integrity error for product {item.get(Fields.PRODUCT_ID)}")
        return cid

    before_map = {_item_key(item): item for item in before_items}

    shipped_this_update = []
    for item in after_items:
        key = _item_key(item)
        prev_item = before_map.get(key)

        # Detect transition to shipped for physical items
        if (item.get(Fields.STATUS) == DeliveryStatusValues.SHIPPED and
            (not prev_item or prev_item.get(Fields.STATUS) != DeliveryStatusValues.SHIPPED) and
            not item.get(Fields.IS_DIGITAL, False)):
            shipped_this_update.append(item)

    if not shipped_this_update:
        return

    db = get_db()
    user_id = after.get(Fields.USER_ID)
    customer_email = after.get(Fields.CUSTOMER_EMAIL)

    if not user_id or not customer_email:
        logger.warning(f"Order {order_id} missing user_id or customer_email, cannot notify")
        return

    # C5: Use cartItemId for dedup hash — cartItemId is mandatory, no fallback needed
    item_ids_str = ":".join(sorted([
        it.get(Fields.CART_ITEM_ID, "")
        for it in shipped_this_update
    ]))
    item_hash = hashlib.sha256(item_ids_str.encode()).hexdigest()[:12]
    claim_id = f"item_shipped_{order_id}_{item_hash}"

    claim_ref = db.collection(Collections.WEBHOOK_EVENTS).document(claim_id)
    try:
        claim_ref.create({
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.EVENT_TYPE: "item_shipped_notification",
            Fields.ORDER_ID: order_id
        })
    except Exception:
        logger.info(f"Notification already sent for these items in order {order_id}, skipping")
        return

    try:
        # Fetch user preferred language
        user_doc = db.collection(Collections.USERS).document(user_id).get()
        lang = (user_doc.to_dict() or {}).get(Fields.PREFERRED_LANGUAGE, "en") if user_doc.exists else "en"

        # FIX-3: Validate delivery_speed against known values
        delivery_speed = after.get(Fields.DELIVERY_SPEED)
        is_pickup = delivery_speed == DeliveryTypeValues.PICKUP
        if delivery_speed and delivery_speed not in DeliveryTypeValues.ALL:
            logger.warning(f"Unexpected deliverySpeed '{delivery_speed}' on order {order_id}")
        item_names = [it.get(Fields.NAME, "item") for it in shipped_this_update]

        # 1. Send Push Notification
        title = "Order Update" if lang == "en" else "Mise à jour de commande"
        if is_pickup:
            if len(shipped_this_update) == 1:
                body = f"Your item '{item_names[0]}' is ready for pickup!" if lang == "en" else f"Votre article '{item_names[0]}' est prêt à être récupéré !"
            else:
                body = f"{len(shipped_this_update)} items from your order are ready for pickup!" if lang == "en" else f"{len(shipped_this_update)} articles de votre commande sont prêts à être récupérés !"
        else:
            if len(shipped_this_update) == 1:
                body = f"Your item '{item_names[0]}' has been shipped!" if lang == "en" else f"Votre article '{item_names[0]}' a été expédié !"
            else:
                body = f"{len(shipped_this_update)} items from your order have been shipped!" if lang == "en" else f"{len(shipped_this_update)} articles de votre commande ont été expédiés !"

        send_push_notification(
            user_id,
            title,
            body,
            data={"type": NotificationTypes.ORDER_UPDATE, "orderId": order_id, "status": DeliveryStatusValues.SHIPPED}
        )

        # 2. Send Email Notification
        tracking = shipped_this_update[0].get(Fields.TRACKING_NUMBER, "N/A")
        carrier = shipped_this_update[0].get(Fields.CARRIER, "N/A")

        email_html = get_order_item_shipped_email(
            order_data=after,
            order_id=order_id,
            shipped_items=shipped_this_update,
            tracking_number=tracking,
            carrier=carrier,
            lang=lang
        )

        subject = f"Shipment Update - Order #{order_id[:8]}" if lang == "en" else f"Mise à jour de livraison - Commande #{order_id[:8]}"
        if is_pickup:
            subject = f"Ready for Pickup - Order #{order_id[:8]}" if lang == "en" else f"Prêt pour ramassage - Commande #{order_id[:8]}"

        from services.email_task import enqueue_email_task
        enqueue_email_task(
            to_email=customer_email,
            subject=subject,
            html_content=email_html,
            event_type="order_shipped_alert"
        )

        logger.info(f"✅ Notified buyer {user_id} for shipment of {len(shipped_this_update)} items in order {order_id}")

    except Exception as e:
        logger.error(f"🚨 Failed to notify buyer for item shipment in order {order_id}: {str(e)}")


@firestore_fn.on_document_updated(document="orders/{orderId}", **FIRESTORE_TRIGGER_OPTIONS)
def on_order_item_delivered(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Triggered when an order document is updated.
    Detects when an individual item status changes to 'delivered' and notifies the buyer.
    """
    before = event.data.before.to_dict()
    after = event.data.after.to_dict()
    if not before or not after:
        return

    order_id = event.params["orderId"]
    before_items = before.get(Fields.ITEMS, [])
    after_items = after.get(Fields.ITEMS, [])

    # C3: Align with shipped trigger — enforce cartItemId mandatory
    def _item_key(item):
        cid = item.get(Fields.CART_ITEM_ID)
        if not cid:
            raise ValueError(f"OrderItem missing cartItemId — data integrity error for product {item.get(Fields.PRODUCT_ID)}")
        return cid

    before_map = {_item_key(item): item for item in before_items}

    delivered_this_update = []
    for item in after_items:
        key = _item_key(item)
        prev_item = before_map.get(key)

        if (item.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED and
            (not prev_item or prev_item.get(Fields.STATUS) != DeliveryStatusValues.DELIVERED)):
            delivered_this_update.append(item)

    if not delivered_this_update:
        return

    db = get_db()
    user_id = after.get(Fields.USER_ID)
    if not user_id:
        return

    # Claim notification to avoid duplicates
    # C5: Use cartItemId for dedup hash + SHA256 instead of MD5
    item_ids_str = ":".join(sorted([
        it.get(Fields.CART_ITEM_ID, "")
        for it in delivered_this_update
    ]))
    item_hash = hashlib.sha256(item_ids_str.encode()).hexdigest()[:12]
    claim_id = f"item_delivered_{order_id}_{item_hash}"

    claim_ref = db.collection(Collections.WEBHOOK_EVENTS).document(claim_id)
    try:
        claim_ref.create({
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.EVENT_TYPE: "item_delivered_notification",
            Fields.ORDER_ID: order_id
        })
    except Exception:
        return

    try:
        user_doc = db.collection(Collections.USERS).document(user_id).get()
        lang = (user_doc.to_dict() or {}).get(Fields.PREFERRED_LANGUAGE, "en") if user_doc.exists else "en"

        item_names = [it.get(Fields.NAME, "item") for it in delivered_this_update]
        title = "Item Delivered" if lang == "en" else "Article livré"

        if len(delivered_this_update) == 1:
            body = f"Your item '{item_names[0]}' has been delivered!" if lang == "en" else f"Votre article '{item_names[0]}' a été livré !"
        else:
            body = f"{len(delivered_this_update)} items from your order have been delivered!" if lang == "en" else f"{len(delivered_this_update)} articles de votre commande ont été livrés !"

        # 1. Send Push Notification
        send_push_notification(
            user_id,
            title,
            body,
            data={"type": NotificationTypes.ORDER_UPDATE, "orderId": order_id, "status": DeliveryStatusValues.DELIVERED}
        )

        # 2. Send Email Notification
        customer_email = after.get(Fields.CUSTOMER_EMAIL)
        if not customer_email:
            customer_email = (user_doc.to_dict() or {}).get(Fields.EMAIL)

        if customer_email:
            email_html = get_order_item_delivered_email(
                order_data=after,
                order_id=order_id,
                delivered_items=delivered_this_update,
                lang=lang
            )
            subject = f"Delivery Update - Order #{order_id[:8]}" if lang == "en" else f"Mise à jour de livraison - Commande #{order_id[:8]}"
            from services.email_task import enqueue_email_task
            enqueue_email_task(
                to_email=customer_email,
                subject=subject,
                html_content=email_html,
                event_type="order_delivered_alert"
            )

        logger.info(f"✅ Notified buyer {user_id} for delivery of {len(delivered_this_update)} items in order {order_id}")
    except Exception as e:
        logger.error(f"🚨 Failed to send delivery notification: {str(e)}")
