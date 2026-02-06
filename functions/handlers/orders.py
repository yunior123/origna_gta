"""
Order Lifecycle Management Handlers
- Order receipt confirmation
- Order status updates
- Shipping approval workflow
- Order cancellation
"""

from function_options import DEFAULT_OPTIONS, WEBHOOK_OPTIONS, CRON_OPTIONS
from firebase_functions import https_fn, firestore_fn
import stripe
from typing import Dict, Any
from datetime import datetime

from config import (
    OrderStatus, PaymentStatus, DeliveryStatus, Collections,
    PLATFORM_FEE_PERCENT, STRIPE_SECRET_KEY
)
from utils import create_success_response, create_error_response, is_valid_order_status_transition
from email_service import send_email

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
def confirm_order_receipt(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
def update_order_status(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    order_id = data.get('orderId')
    new_status = data.get('newStatus')
    tracking_number_raw = data.get('trackingNumber')
    carrier_raw = data.get('carrier')
    
    # Sanitize tracking number and carrier inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None
    
    if not order_id or not new_status:
        raise https_fn.HttpsError('invalid-argument', 'orderId and newStatus required')
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    old_status = order_data['orderStatus']
    
    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    is_admin = 'admin' in user_data.get('roles', [])
    
    # Check if user is seller for any item in order
    is_seller = any(item['sellerId'] == user_id for item in order_data['items'])
    
    if not (is_admin or is_seller):
        raise https_fn.HttpsError('permission-denied', 'Only seller or admin can update order status')
    
    # Validate state transition
    if not is_valid_order_status_transition(old_status, new_status):
        raise https_fn.HttpsError(
            'failed-precondition',
            f'Invalid transition from {old_status} to {new_status}'
        )
    
    # Update order
    update_data = {
        'orderStatus': new_status,
        'updatedAt': get_server_timestamp()
    }
    
    if new_status == 'shipped' and tracking_number:
        update_data['trackingNumber'] = tracking_number
        update_data['carrier'] = carrier or ''
        update_data['deliveryStatus'] = DeliveryStatus.SHIPPED
        update_data['shippedAt'] = get_server_timestamp()
    
    order_ref.update(update_data)
    
    return create_success_response({'newStatus': new_status})


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_item_status(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    order_id = data.get('orderId')
    product_id = data.get('productId')
    new_status = data.get('newStatus')
    tracking_number_raw = data.get('trackingNumber')
    carrier_raw = data.get('carrier')
    
    # Sanitize inputs
    tracking_number = sanitized_text(tracking_number_raw)[:100] if tracking_number_raw else None
    carrier = sanitized_text(carrier_raw)[:50] if carrier_raw else None
    
    if not order_id or not product_id or not new_status:
        raise https_fn.HttpsError('invalid-argument', 'orderId, productId, and newStatus required')
    
    # Validate status value
    valid_statuses = ['pending', 'shipped', 'delivered', 'refunded']
    if new_status not in valid_statuses:
        raise https_fn.HttpsError('invalid-argument', f'Status must be one of: {valid_statuses}')
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    items = order_data.get('items', [])
    
    # Find the item to update
    item_index = None
    item_seller_id = None
    for idx, item in enumerate(items):
        if item['productId'] == product_id:
            item_index = idx
            item_seller_id = item['sellerId']
            break
    
    if item_index is None:
        raise https_fn.HttpsError('not-found', f'Product {product_id} not found in order')
    
    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    is_admin = 'admin' in user_data.get('roles', [])
    is_item_seller = (item_seller_id == user_id)
    
    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError('permission-denied', 'Only the item seller or admin can update item status')
    
    # Update the item
    items[item_index]['status'] = new_status
    
    if new_status == 'shipped':
        items[item_index]['shippedAt'] = get_server_timestamp()
        if tracking_number:
            items[item_index]['trackingNumber'] = tracking_number
            items[item_index]['carrier'] = carrier or ''
    
    elif new_status == 'delivered':
        items[item_index]['deliveredAt'] = get_server_timestamp()
        items[item_index]['confirmedByBuyer'] = True
    
    # Check if all items are delivered
    all_items_delivered = all(item.get('status') == 'delivered' for item in items)
    
    # Update order
    update_data = {
        'items': items,
        'updatedAt': get_server_timestamp()
    }
    
    # If all items delivered, update order status
    if all_items_delivered and order_data.get('orderStatus') != OrderStatus.DELIVERED:
        update_data['orderStatus'] = OrderStatus.DELIVERED
        update_data['deliveryStatus'] = DeliveryStatus.DELIVERED
    
    order_ref.update(update_data)
    
    return create_success_response({
        'itemStatus': new_status,
        'allItemsDelivered': all_items_delivered
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def cancel_order(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    user_id = req.auth.uid
    data = req.data
    
    order_id = data.get('orderId')
    reason_raw = data.get('reason', 'User requested cancellation')
    
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
    
    # Check permissions
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    is_admin = 'admin' in user_data.get('roles', [])
    is_buyer = (order_data.get('userId') == user_id)
    
    # Check if user is seller for any item
    is_seller = any(item['sellerId'] == user_id for item in order_data['items'])
    
    if not (is_admin or is_buyer or is_seller):
        raise https_fn.HttpsError('permission-denied', 'Only buyer, seller, or admin can cancel order')
    
    # Check if order can be cancelled
    current_status = order_data['orderStatus']
    payment_status = order_data.get('paymentStatus')
    
    # FIXED: Added shipped and in_transit to forbidden states to prevent post-shipment cancellation
    forbidden_states = [OrderStatus.DELIVERED, OrderStatus.REFUNDED, 'shipped', 'in_transit']
    if current_status in forbidden_states:
        raise https_fn.HttpsError('failed-precondition', f'Cannot cancel order with status: {current_status}')
    
    # Restore stock atomically (idempotency handled by stockRestored flag)
    if not order_data.get('stockRestored', False):
        for item in order_data['items']:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
            product_ref.update({
                'stockQuantity': get_firestore().Increment(item['quantity']),
                'updatedAt': get_server_timestamp()
            })
    
    # Issue refund if payment was captured
    refunded = False
    if payment_status == PaymentStatus.CAPTURED:
        payment_intent_id = order_data.get('stripePaymentIntentId')
        if payment_intent_id:
            try:
                stripe.Refund.create(
                    payment_intent=payment_intent_id,
                    reason='requested_by_customer',
                    metadata={'orderId': order_id},
                    idempotency_key=f'refund_{order_id}'
                )
                refunded = True
            except stripe.error.StripeError as e:
                print(f'Refund failed: {str(e)}')
    
    # Update order
    order_ref.update({
        'orderStatus': OrderStatus.CANCELLED,
        'paymentStatus': PaymentStatus.REFUNDED if refunded else payment_status,
        'cancelledBy': user_id,
        'cancelledAt': get_server_timestamp(),
        'cancellationReason': reason,
        'stockRestored': True,
        'updatedAt': get_server_timestamp()
    })
    
    return create_success_response({'refunded': refunded})


@https_fn.on_call(**DEFAULT_OPTIONS)
def refund_order_item(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    user_id = req.auth.uid
    data = req.data
    
    order_id = data.get('orderId')
    product_id = data.get('productId')
    reason_raw = data.get('reason', 'Item refund requested')
    
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
    is_admin = 'admin' in user_data.get('roles', [])
    # is_buyer = (order_data.get('userId') == user_id)  # REMOVED: Buyers cannot self-refund directly
    
    # Check if user is seller for the specific item
    item_seller_id = None
    for item in order_data.get('items', []):
        if item['productId'] == product_id:
            item_seller_id = item['sellerId']
            break
            
    is_item_seller = (item_seller_id == user_id)

    if not (is_admin or is_item_seller):
        raise https_fn.HttpsError('permission-denied', 'Only seller of the item or admin can issue refunds')
    
    # Check if payment was captured
    payment_status = order_data.get('paymentStatus')
    if payment_status != PaymentStatus.CAPTURED:
        raise https_fn.HttpsError('failed-precondition', 'Cannot refund uncaptured payment')
    
    # Find the item
    items = order_data.get('items', [])
    item_index = None
    item_data = None
    
    for idx, item in enumerate(items):
        if item['productId'] == product_id:
            item_index = idx
            item_data = item
            break
    
    if item_index is None:
        raise https_fn.HttpsError('not-found', f'Product {product_id} not found in order')
    
    # Check if item already refunded
    if item_data.get('status') == 'refunded':
        raise https_fn.HttpsError('failed-precondition', 'Item already refunded')
    
    # Calculate refund amount (all in cents to avoid float errors)
    item_price_cents = round(item_data['price'] * 100)
    item_quantity = item_data['quantity']
    item_subtotal_cents = item_price_cents * item_quantity
    
    # Calculate proportional tax and shipping
    # CRITICAL FIX: Field name is 'subtotalCents' not 'subtotalAmountCents'
    order_subtotal_cents = order_data.get('subtotalCents', 0)
    order_tax_cents = order_data.get('taxAmountCents', 0)
    order_shipping_cents = order_data.get('shippingCostCents', 0)
    
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
        raise https_fn.HttpsError('internal', f'Refund failed: {str(e)}')
    
    # Restore stock for this item
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_ref.update({
        'stockQuantity': get_firestore().Increment(item_quantity),
        'updatedAt': get_server_timestamp()
    })
    
    # Update item status
    items[item_index]['status'] = 'refunded'
    items[item_index]['refundedAt'] = get_server_timestamp()
    items[item_index]['refundReason'] = reason
    items[item_index]['refundAmountCents'] = refund_amount_cents
    items[item_index]['refundId'] = refund.id
    
    # Reverse seller transfer if payout exists
    seller_id = item_data['sellerId']
    payout_query = get_db().collection(Collections.PAYOUTS).where(
        'orderId', '==', order_id
    ).where(
        'sellerId', '==', seller_id
    ).where(
        'status', '==', 'completed'
    ).limit(1).get()
    
    if len(payout_query) > 0:
        payout_doc = payout_query[0]
        payout_data = payout_doc.to_dict()
        
        # Calculate proportional reversal amount
        seller_total_cents = payout_data.get('amountCents', 0)
        platform_fee_cents = payout_data.get('platformFeeCents', 0)
        
        if seller_total_cents > 0:
            seller_proportion = item_subtotal_cents / seller_total_cents
            reversal_amount_cents = round(payout_data.get('netAmountCents', 0) * seller_proportion)
            
            try:
                stripe_transfer_id = payout_data.get('stripeTransferId')
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
                        'partialReversals': get_firestore().ArrayUnion([{
                            'reversalId': reversal.id,
                            'amountCents': reversal_amount_cents,
                            'productId': product_id,
                            'createdAt': get_server_timestamp()
                        }]),
                        'updatedAt': get_server_timestamp()
                    })
            except stripe.error.StripeError as e:
                # Log failed reversal but don't fail the refund
                print(f'Transfer reversal failed for {seller_id}: {str(e)}')
    
    # Update order
    order_ref.update({
        'items': items,
        'updatedAt': get_server_timestamp()
    })
    
    return create_success_response({
        'refundAmount': refund_amount_cents / 100,  # Return in dollars
        'refundId': refund.id
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def approve_shipping_cost(req: https_fn.CallableRequest) -> Dict[str, Any]:
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
    
    order_id = data.get('orderId')
    approved = data.get('approved', False)
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    
    # Verify buyer
    if order_data['userId'] != user_id:
        raise https_fn.HttpsError('permission-denied', 'Not your order')
    
    shipping_approval = order_data.get('shippingApproval', {})
    
    if shipping_approval.get('status') != 'pending':
        raise https_fn.HttpsError('failed-precondition', 'No pending shipping approval')
    
    if approved:
        # Update order with new shipping cost (all amounts in cents)
        new_shipping_cost_cents = round(shipping_approval.get('actualCost', 0) * 100)
        old_shipping_cost_cents = order_data.get('shippingCostCents', 0)
        difference_cents = new_shipping_cost_cents - old_shipping_cost_cents
        new_total_cents = order_data.get('totalAmountCents', 0) + difference_cents
        
        order_ref.update({
            'shippingCostCents': new_shipping_cost_cents,
            'totalAmountCents': new_total_cents,
            'shippingApproval.status': 'approved',
            'shippingApproval.respondedAt': get_server_timestamp(),
            'updatedAt': get_server_timestamp()
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
        order_ref.update({
            'shippingApproval.status': 'rejected',
            'shippingApproval.respondedAt': get_server_timestamp(),
            'orderStatus': OrderStatus.CANCELLED,
            'cancellationReason': 'Buyer rejected shipping cost',
            'stockRestored': True,
            'updatedAt': get_server_timestamp()
        })
        
        # Restore stock using atomic Increment (prevents race conditions)
        for item in order_data['items']:
            product_ref = get_db().collection(Collections.PRODUCTS).document(item['productId'])
            product_ref.update({
                'stockQuantity': get_firestore().Increment(item['quantity'])
            })
    
    return create_success_response({'approved': approved})


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
    
    old_status = before_data.get('orderStatus')
    new_status = after_data.get('orderStatus')
    
    if old_status == new_status:
        return
    
    # Send notification emails based on status change
    user_id = after_data.get('userId')
    
    # CRITICAL FIX: Fetch actual buyer email from user document (not user_id!)
    buyer_email = after_data.get('customerEmail')
    if not buyer_email:
        try:
            from firebase_admin import firestore as _fs
            _db = _fs.client()
            buyer_doc = _db.collection('users').document(user_id).get()
            if buyer_doc.exists:
                buyer_email = buyer_doc.to_dict().get('email')
        except Exception as e:
            print(f'Failed to fetch buyer email for order {order_id}: {str(e)}')
    
    if not buyer_email:
        print(f'⚠️ No email found for user {user_id}, skipping notification for order {order_id}')
        return
    
    try:
        if new_status == 'shipped':
            tracking_number = after_data.get('trackingNumber', 'N/A')
            carrier = after_data.get('carrier', 'N/A')
            
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
            
            # Also notify sellers that shipment was confirmed
            seller_ids = set(item.get('sellerId') for item in after_data.get('items', []))
            for sid in seller_ids:
                try:
                    seller_doc = _db.collection('users').document(sid).get()
                    if seller_doc.exists:
                        seller_email = seller_doc.to_dict().get('email')
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
        
        elif new_status == 'delivered':
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
        
        elif new_status == 'cancelled':
            reason = after_data.get('cancellationReason', 'Unknown')
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
