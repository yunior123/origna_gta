"""
Order Lifecycle Management Handlers
- Order receipt confirmation
- Order status updates
- Shipping approval workflow
- Order cancellation
"""

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


@https_fn.on_call()
def confirm_order_receipt(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Buyer confirms order receipt, triggering payment capture and seller payouts.
    
    Flow:
    1. Capture Stripe Payment Intent
    2. Update order status to delivered
    3. Create payout records for each seller
    4. Transfer funds to sellers (minus 2.5% platform fee)
    
    Request data:
        orderId: Order document ID
    
    Returns:
        {success: True, captured: True}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')
    
    user_id = req.auth.uid
    order_id = req.data.get('orderId')
    
    if not order_id:
        raise https_fn.HttpsError('invalid-argument', 'orderId required')
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    
    # Verify user owns this order
    if order_data['userId'] != user_id:
        raise https_fn.HttpsError('permission-denied', 'This is not your order')
    
    # Verify order status
    if order_data['orderStatus'] not in ['shipped', 'delivered']:
        raise https_fn.HttpsError(
            'failed-precondition',
            f"Cannot confirm receipt for order with status: {order_data['orderStatus']}"
        )
    
    # Check if already captured
    if order_data.get('paymentStatus') == PaymentStatus.CAPTURED.value:
        return create_success_response({'captured': True, 'message': 'Already captured'})
    
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
            'deliveryStatus': DeliveryStatus.DELIVERED.value,
            'confirmedAt': get_server_timestamp(),
            'updatedAt': get_server_timestamp()
        })
        
        # Calculate and transfer payouts to sellers
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
                
                if stripe_account_id and seller_data.get('payoutsEnabled', False):
                    try:
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
                        
                        print(f'Payout created for seller {seller_id}: ${net_amount}')
                        
                    except stripe.error.StripeError as e:
                        # Log failed payout
                        get_db().collection(Collections.PAYOUTS.value).add({
                            'orderId': order_id,
                            'sellerId': seller_id,
                            'amount': amount,
                            'platformFee': platform_fee,
                            'netAmount': net_amount,
                            'status': 'failed',
                            'failureReason': str(e),
                            'createdAt': get_server_timestamp()
                        })
                        
                        print(f'Payout failed for seller {seller_id}: {str(e)}')
                else:
                    # Seller not ready for payouts
                    get_db().collection(Collections.PAYOUTS.value).add({
                        'orderId': order_id,
                        'sellerId': seller_id,
                        'amount': amount,
                        'platformFee': platform_fee,
                        'netAmount': net_amount,
                        'status': 'pending',
                        'note': 'Seller account not configured for payouts',
                        'createdAt': get_server_timestamp()
                    })
        
        return create_success_response({'captured': True})
        
    except stripe.error.StripeError as e:
        raise https_fn.HttpsError('internal', f'Stripe error: {str(e)}')


@https_fn.on_call()
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
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    old_status = order_data['orderStatus']
    
    # Check permissions
    user_ref = get_db().collection(Collections.USERS.value).document(user_id)
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
        update_data['deliveryStatus'] = DeliveryStatus.SHIPPED.value
        update_data['shippedAt'] = get_server_timestamp()
    
    if new_status == 'processing':
        update_data['deliveryStatus'] = DeliveryStatus.PREPARING.value
    
    order_ref.update(update_data)
    
    return create_success_response({'newStatus': new_status})


@https_fn.on_call()
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
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
    order_doc = order_ref.get()
    
    if not order_doc.exists:
        raise https_fn.HttpsError('not-found', 'Order not found')
    
    order_data = order_doc.to_dict()
    
    # Check permissions
    user_ref = get_db().collection(Collections.USERS.value).document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')
    
    user_data = user_doc.to_dict()
    is_admin = 'admin' in user_data.get('roles', [])
    is_buyer = order_data['userId'] == user_id
    is_seller = any(item['sellerId'] == user_id for item in order_data['items'])
    
    if not (is_admin or is_buyer or is_seller):
        raise https_fn.HttpsError('permission-denied', 'Not authorized to cancel this order')
    
    # Cannot cancel delivered orders
    if order_data['orderStatus'] in ['delivered', 'refunded']:
        raise https_fn.HttpsError('failed-precondition', 'Cannot cancel delivered or refunded orders')
    
    # Restore stock
    for item in order_data['items']:
        product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
        product_doc = product_ref.get()
        
        if product_doc.exists:
            product_data = product_doc.to_dict()
            current_stock = product_data.get('stockQuantity', 0)
            product_ref.update({
                'stockQuantity': current_stock + item['quantity']
            })
    
    refunded = False
    
    # Issue refund if payment was captured
    if order_data.get('paymentStatus') == PaymentStatus.CAPTURED.value:
        payment_intent_id = order_data.get('stripePaymentIntentId')
        
        if payment_intent_id:
            try:
                refund = stripe.Refund.create(
                    payment_intent=payment_intent_id,
                    reason='requested_by_customer'
                )
                refunded = True
            except stripe.error.StripeError as e:
                print(f'Refund failed: {str(e)}')
    
    # Update order
    order_ref.update({
        'orderStatus': OrderStatus.CANCELLED.value,
        'paymentStatus': PaymentStatus.REFUNDED.value if refunded else order_data['paymentStatus'],
        'cancellationReason': reason,
        'cancelledBy': user_id,
        'cancelledAt': get_server_timestamp(),
        'updatedAt': get_server_timestamp()
    })
    
    return create_success_response({'refunded': refunded})


@https_fn.on_call()
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
    
    order_ref = get_db().collection(Collections.ORDERS.value).document(order_id)
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
        # Update order with new shipping cost
        new_shipping_cost = shipping_approval.get('actualCost', 0)
        old_shipping_cost = order_data.get('shippingCost', 0)
        difference = new_shipping_cost - old_shipping_cost
        
        order_ref.update({
            'shippingCost': new_shipping_cost,
            'totalAmount': order_data['totalAmount'] + difference,
            'shippingApproval.status': 'approved',
            'shippingApproval.respondedAt': get_server_timestamp(),
            'updatedAt': get_server_timestamp()
        })
        
        # Charge additional amount if needed
        if difference > 0:
            payment_intent_id = order_data.get('stripePaymentIntentId')
            if payment_intent_id:
                try:
                    # Update payment intent amount
                    stripe.PaymentIntent.modify(
                        payment_intent_id,
                        amount=int((order_data['totalAmount'] + difference) * 100)
                    )
                except stripe.error.StripeError as e:
                    print(f'Failed to update payment amount: {str(e)}')
    else:
        # Buyer rejected, cancel order
        order_ref.update({
            'shippingApproval.status': 'rejected',
            'shippingApproval.respondedAt': get_server_timestamp(),
            'orderStatus': OrderStatus.CANCELLED.value,
            'cancellationReason': 'Buyer rejected shipping cost',
            'updatedAt': get_server_timestamp()
        })
        
        # Restore stock
        for item in order_data['items']:
            product_ref = get_db().collection(Collections.PRODUCTS.value).document(item['productId'])
            product_doc = product_ref.get()
            
            if product_doc.exists:
                product_data = product_doc.to_dict()
                current_stock = product_data.get('stockQuantity', 0)
                product_ref.update({
                    'stockQuantity': current_stock + item['quantity']
                })
    
    return create_success_response({'approved': approved})


@firestore_fn.on_document_updated(document="orders/{orderId}")
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
    
    try:
        if new_status == 'shipped':
            tracking_number = after_data.get('trackingNumber', 'N/A')
            carrier = after_data.get('carrier', 'N/A')
            
            # Email buyer
            send_email(
                to_email=user_id,
                subject='Your Order Has Shipped - Origna',
                html_content=f'''
                <h2>Your order has been shipped!</h2>
                <p>Order ID: {order_id}</p>
                <p>Tracking Number: {tracking_number}</p>
                <p>Carrier: {carrier}</p>
                <p>You can track your order at: https://origna.ca/orders/{order_id}</p>
                '''
            )
        
        elif new_status == 'delivered':
            # Email buyer to confirm receipt
            send_email(
                to_email=user_id,
                subject='Order Delivered - Please Confirm Receipt',
                html_content=f'''
                <h2>Your order has been delivered!</h2>
                <p>Order ID: {order_id}</p>
                <p>Please confirm receipt to release payment to sellers:</p>
                <a href="https://origna.ca/orders/{order_id}">Confirm Receipt</a>
                '''
            )
        
        elif new_status == 'cancelled':
            reason = after_data.get('cancellationReason', 'Unknown')
            send_email(
                to_email=user_id,
                subject='Order Cancelled - Origna',
                html_content=f'''
                <h2>Your order has been cancelled</h2>
                <p>Order ID: {order_id}</p>
                <p>Reason: {reason}</p>
                <p>If payment was captured, a refund will be issued within 5-10 business days.</p>
                '''
            )
    
    except Exception as e:
        print(f'Failed to send order status email: {str(e)}')
