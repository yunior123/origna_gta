"""
Firebase Cloud Functions for Stripe Payment Integration
Complete production-ready implementation with email notifications and order management

Setup Instructions:
1. Install dependencies: pip install -r requirements.txt
2. Set environment variables:
   - Production: firebase functions:config:set stripe.secret_key="sk_live_..." stripe.webhook_secret="whsec_..." sendgrid.api_key="SG.xxx"
   - Local: Set in .env file
3. Deploy: firebase deploy --only functions
"""

from firebase_functions import https_fn, options, firestore_fn
from firebase_admin import initialize_app, firestore, credentials
import stripe
import json
import os
from typing import Any, Dict, Optional, List
from datetime import datetime
import traceback
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content

# ============================================================================
# FIREBASE INITIALIZATION
# ============================================================================

try:
    app = initialize_app()
except Exception as e:
    cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        app = initialize_app(cred)
    else:
        print("WARNING: Firebase credentials not found.")
        app = initialize_app()

db = firestore.client()

# ============================================================================
# CONFIGURATION
# ============================================================================

IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR') == 'true'

# Stripe keys
if IS_EMULATOR:
    STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "sk_test_...")
    STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET", "STRIPE_WEBHOOK_SECRET_REDACTED...")
    SENDGRID_API_KEY = os.environ.get("SENDGRID_API_KEY", "")
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    print("🧪 Running in EMULATOR mode")
else:
    from firebase_functions import params
    STRIPE_SECRET_KEY = params.SecretParam("STRIPE_SECRET_KEY").value
    STRIPE_WEBHOOK_SECRET = params.SecretParam("STRIPE_WEBHOOK_SECRET").value
    SENDGRID_API_KEY = params.SecretParam("SENDGRID_API_KEY").value
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    print("🚀 Running in PRODUCTION mode")

stripe.api_key = STRIPE_SECRET_KEY

cors_config = options.CorsOptions(
    cors_origins=[
        "https://orignagta.com",
        "https://www.orignagta.com",
        "http://localhost:*",
        "http://127.0.0.1:*"
    ],
    cors_methods=["get", "post", "options"],
)

# ============================================================================
# EMAIL TEMPLATES
# ============================================================================

def get_seller_notification_email(order_data: Dict[str, Any]) -> str:
    """Generate HTML email for seller notification"""
    items_html = ""
    for item in order_data.get('items', []):
        items_html += f"""
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #eee;">
                {item.get('name', 'Product')}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
                {item.get('quantity', 1)}
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">
                ${(item.get('price', 0) * item.get('quantity', 1)):.2f}
            </td>
        </tr>
        """
    
    delivery_info = order_data.get('deliveryInfo', {})
    address_html = f"""
        {delivery_info.get('formattedAddress', 'N/A')}<br>
        {f"Phone: {delivery_info.get('phoneNumber', 'N/A')}" if delivery_info.get('phoneNumber') else ''}
    """
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 New Order Received!</h1>
        </div>
        
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-top: none; border-radius: 0 0 10px 10px;">
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h2 style="margin: 0 0 10px 0; color: #FF6B35;">Order Details</h2>
                <p style="margin: 5px 0;"><strong>Order ID:</strong> {order_data.get('orderId', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Customer Email:</strong> {order_data.get('customerEmail', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.utcnow().strftime('%B %d, %Y at %I:%M %p UTC')}</p>
            </div>
            
            <h3 style="color: #333; border-bottom: 2px solid #FF6B35; padding-bottom: 10px;">Items Ordered</h3>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
                <thead>
                    <tr style="background: #f8f9fa;">
                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Item</th>
                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                        <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                </tbody>
            </table>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #333;">Delivery Address</h3>
                <p style="margin: 0; line-height: 1.8;">{address_html}</p>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #856404;">Order Summary</h3>
                <table style="width: 100%;">
                    <tr>
                        <td style="padding: 5px 0;">Subtotal:</td>
                        <td style="text-align: right; padding: 5px 0;">${order_data.get('subtotal', 0):.2f}</td>
                    </tr>
                    <tr>
                        <td style="padding: 5px 0;">Shipping:</td>
                        <td style="text-align: right; padding: 5px 0;">${order_data.get('shippingCost', 0):.2f}</td>
                    </tr>
                    <tr>
                        <td style="padding: 5px 0;">Taxes:</td>
                        <td style="text-align: right; padding: 5px 0;">${sum(order_data.get('taxes', {}).values()):.2f}</td>
                    </tr>
                    <tr style="font-size: 18px; font-weight: bold; border-top: 2px solid #856404;">
                        <td style="padding: 10px 0;">Total:</td>
                        <td style="text-align: right; padding: 10px 0; color: #FF6B35;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </table>
            </div>
            
            <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
                <p style="color: #666; font-size: 14px;">Please process this order and update the shipping status in your admin panel.</p>
            </div>
        </div>
        
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
            <p>This is an automated notification from Origna GTA</p>
        </div>
    </body>
    </html>
    """

def get_customer_confirmation_email(order_data: Dict[str, Any]) -> str:
    """Generate HTML email for customer confirmation"""
    items_html = ""
    for item in order_data.get('items', []):
        items_html += f"""
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #eee;">{item.get('name', 'Product')}</td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">{item.get('quantity', 1)}</td>
            <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">${(item.get('price', 0) * item.get('quantity', 1)):.2f}</td>
        </tr>
        """
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">✅ Order Confirmed!</h1>
            <p style="color: white; margin: 10px 0 0 0;">Thank you for your purchase</p>
        </div>
        
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-top: none; border-radius: 0 0 10px 10px;">
            <p style="font-size: 16px; margin-bottom: 20px;">Hi there,</p>
            <p style="font-size: 16px; margin-bottom: 20px;">We've received your order and will begin processing it shortly. You'll receive another email when your order ships.</p>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <p style="margin: 5px 0;"><strong>Order ID:</strong> {order_data.get('orderId', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.utcnow().strftime('%B %d, %Y')}</p>
            </div>
            
            <h3 style="color: #333; border-bottom: 2px solid #FF6B35; padding-bottom: 10px;">Order Summary</h3>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
                <thead>
                    <tr style="background: #f8f9fa;">
                        <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Item</th>
                        <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                        <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Price</th>
                    </tr>
                </thead>
                <tbody>
                    {items_html}
                    <tr style="font-weight: bold; background: #f8f9fa;">
                        <td colspan="2" style="padding: 12px; text-align: right; border-top: 2px solid #ddd;">Total:</td>
                        <td style="padding: 12px; text-align: right; color: #FF6B35; font-size: 18px; border-top: 2px solid #ddd;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </tbody>
            </table>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="https://orignagta.com/orders" style="background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Track Your Order</a>
            </div>
        </div>
        
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
            <p>Questions? Contact us at support@orignagta.com</p>
            <p>© 2025 Origna GTA. All rights reserved.</p>
        </div>
    </body>
    </html>
    """

# ============================================================================
# EMAIL FUNCTIONS
# ============================================================================

def send_email(to_email: str, subject: str, html_content: str, from_email: str = "orders@orignagta.com") -> bool:
    """Send email using SendGrid"""
    try:
        if not SENDGRID_API_KEY or IS_EMULATOR:
            print(f"📧 [EMULATOR] Would send email to {to_email}: {subject}")
            return True
        
        message = Mail(
            from_email=Email(from_email, "Origna GTA"),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content("text/html", html_content)
        )
        
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"✉️ Email sent to {to_email}: Status {response.status_code}")
        return response.status_code in [200, 202]
        
    except Exception as e:
        print(f"❌ Email error: {str(e)}")
        return False

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_success_response(data: Dict[str, Any], status_code: int = 200) -> https_fn.Response:
    """Create standardized success response"""
    response_data = {"success": True, **data}
    return https_fn.Response(
        json.dumps(response_data),
        status=status_code,
        headers={"Content-Type": "application/json"}
    )

def create_error_response(error: str, status_code: int = 400, details: Optional[str] = None) -> https_fn.Response:
    """Create standardized error response"""
    response_data = {
        "success": False,
        "error": error,
        "details": details,
        "timestamp": datetime.utcnow().isoformat()
    }
    return https_fn.Response(
        json.dumps(response_data),
        status=status_code,
        headers={"Content-Type": "application/json"}
    )

def validate_order_data(data: Dict[str, Any]) -> tuple[bool, Optional[str]]:
    """Validate order data structure"""
    required_fields = ['userId', 'customerEmail', 'amount', 'items', 'deliveryInfo']
    
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
    
    if not isinstance(data['amount'], (int, float)) or data['amount'] <= 0:
        return False, "Invalid amount: must be positive number"
    
    if not isinstance(data['items'], list) or len(data['items']) == 0:
        return False, "Invalid items: must be non-empty array"
    
    if '@' not in data.get('customerEmail', ''):
        return False, "Invalid email address"
    
    return True, None

# ============================================================================
# STRIPE CHECKOUT FUNCTIONS
# ============================================================================

@https_fn.on_request(cors=cors_config, timeout_sec=60)
def create_checkout_session(req: https_fn.Request) -> https_fn.Response:
    """Create Stripe Checkout Session"""
    try:
        data = req.get_json()
        if not data:
            return create_error_response("Request body is required", 400)
        
        is_valid, error_msg = validate_order_data(data)
        if not is_valid:
            return create_error_response(error_msg, 400)
        
        user_id = data['userId']
        customer_email = data['customerEmail']
        amount = int(data['amount'])
        currency = data.get('currency', 'cad').lower()
        items = data['items']
        delivery_info = data['deliveryInfo']
        
        order_ref = db.collection('orders').document()
        order_id = order_ref.id

        seller_ids = list(set([item.get('sellerId') for item in items if item.get('sellerId')]))
        
        line_items = []
        for item in items:
            line_items.append({
                "price_data": {
                    "currency": currency,
                    "product_data": {
                        "name": item.get('name', 'Product'),
                        "description": item.get('description', ''),
                        "images": [item['imageUrl']] if item.get('imageUrl') else []
                    },
                    "unit_amount": int(item['price'] * 100),
                },
                "quantity": item.get('quantity', 1)
            })
        
        shipping_cost = data.get('shippingCost', 0)
        if shipping_cost > 0:
            line_items.append({
                "price_data": {
                    "currency": currency,
                    "product_data": {
                        "name": "Shipping",
                        "description": f"Delivery to {delivery_info.get('state', '')}"
                    },
                    "unit_amount": int(shipping_cost * 100)
                },
                "quantity": 1
            })
        
        taxes = data.get('taxes', {})
        for tax_name, tax_amount in taxes.items():
            if tax_amount > 0:
                line_items.append({
                    "price_data": {
                        "currency": currency,
                        "product_data": {
                            "name": tax_name,
                            "description": "Tax"
                        },
                        "unit_amount": int(tax_amount * 100)
                    },
                    "quantity": 1
                })

        enriched_items = []
        for item in items:
            item_copy = item.copy()
            item_copy['status'] = 'pending' # Initial status
            item_copy['trackingNumber'] = None
            enriched_items.append(item_copy)
        
        base_url = "http://localhost:5000" if IS_EMULATOR else "https://orignagta.com"
        success_url = f"{base_url}/order-success?session_id={{CHECKOUT_SESSION_ID}}&order_id={order_id}"
        cancel_url = f"{base_url}/checkout?canceled=true"
        
        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            customer_email=customer_email,
            line_items=line_items,
            success_url=success_url,
            cancel_url=cancel_url,
            metadata={
                "userId": user_id,
                "orderId": order_id,
                "environment": "test" if IS_EMULATOR else "production"
            },
            client_reference_id=order_id,
            billing_address_collection="auto",
            expires_at=int((datetime.utcnow().timestamp() + 1800))
        )
        
        order_data = {
            "orderId": order_id,
            "userId": user_id,
            "customerEmail": customer_email,
            "items": enriched_items, # Use enriched items
            "sellerIds": seller_ids, # NEW: Array for queries
            "deliveryInfo": delivery_info,
            "subtotal": data.get('subtotal', 0),
            "taxes": taxes,
            "shippingCost": shipping_cost,
            "total": data.get('total', 0),
            "currency": currency,
            "amount": amount,
            "status": "pending",
            "paymentStatus": "awaiting_payment",
            "stripeSessionId": session.id,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        
        order_ref.set(order_data)
        
        return create_success_response({
            "url": session.url,
            "sessionId": session.id,
            "orderId": order_id
        })
        
    except stripe.error.StripeError as e:
        print(f"❌ Stripe Error: {str(e)}")
        return create_error_response(
            "Payment processing error",
            500,
            str(e) if IS_EMULATOR else None
        )
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        print(traceback.format_exc())
        return create_error_response(
            "Internal server error",
            500,
            str(e) if IS_EMULATOR else None
        )

@https_fn.on_request(timeout_sec=60)
def stripe_webhook(req: https_fn.Request) -> https_fn.Response:
    """Handle Stripe webhook events"""
    try:
        payload = req.data
        sig_header = req.headers.get('stripe-signature')
        
        if not sig_header:
            return create_error_response("Missing Stripe signature", 400)
        
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, STRIPE_WEBHOOK_SECRET
            )
        except stripe.error.SignatureVerificationError as e:
            print(f"❌ Webhook signature verification failed: {str(e)}")
            return create_error_response("Invalid signature", 400)
        
        event_type = event['type']
        event_data = event['data']['object']
        
        print(f"📨 Received webhook: {event_type}")
        
        if event_type == 'checkout.session.completed':
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            if not order_id:
                print("⚠️ No order ID found in session")
                return create_error_response("Order ID not found", 400)
            
            order_ref = db.collection('orders').document(order_id)
            order_doc = order_ref.get()
            
            if not order_doc.exists:
                print(f"⚠️ Order {order_id} not found")
                return create_error_response("Order not found", 404)
            
            # Update order status to confirmed
            order_ref.update({
                "status": "confirmed",
                "paymentStatus": "paid",
                "stripePaymentIntentId": session.get('payment_intent'),
                "stripeCustomerId": session.get('customer'),
                "paidAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "paymentMethod": session.get('payment_method_types', [])[0] if session.get('payment_method_types') else None,
                "amountTotal": session.get('amount_total', 0) / 100,
            })
            
            # Clear user's cart
            user_id = session['metadata'].get('userId')
            if user_id:
                db.collection('users').document(user_id).update({
                    "cart": [],
                    "updatedAt": firestore.SERVER_TIMESTAMP
                })
            
            print(f"✅ Order {order_id} marked as paid")
            
            # Trigger will handle email notifications automatically
        
        elif event_type == 'checkout.session.expired':
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            if order_id:
                order_ref = db.collection('orders').document(order_id)
                if order_ref.get().exists:
                    order_ref.update({
                        "status": "expired",
                        "paymentStatus": "session_expired",
                        "updatedAt": firestore.SERVER_TIMESTAMP
                    })
                    print(f"⏰ Order {order_id} marked as expired")
        
        elif event_type == 'payment_intent.payment_failed':
            payment_intent = event_data
            orders = db.collection('orders').where('stripePaymentIntentId', '==', payment_intent['id']).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                order_ref.update({
                    "status": "failed",
                    "paymentStatus": "payment_failed",
                    "paymentError": payment_intent.get('last_payment_error', {}).get('message'),
                    "updatedAt": firestore.SERVER_TIMESTAMP
                })
                print(f"❌ Payment failed for order")
        
        return create_success_response({"received": True})
        
    except Exception as e:
        print(f"❌ Webhook Error: {str(e)}")
        print(traceback.format_exc())
        return create_error_response(
            "Webhook processing error",
            500,
            str(e) if IS_EMULATOR else None
        )

# ============================================================================
# FIRESTORE TRIGGERS - EMAIL NOTIFICATIONS
# ============================================================================

@firestore_fn.on_document_updated(document="orders/{orderId}")
def on_order_status_change(event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]) -> None:
    """
    Handles order status changes:
    1. If Payment Status -> 'paid': Email EACH seller their specific items to ship.
    2. If Item Status -> 'shipped'/'delivered': Email Customer with updates.
    """
    try:
        before_data = event.data.before.to_dict() if event.data.before else {}
        after_data = event.data.after.to_dict() if event.data.after else {}
        
        if not after_data:
            return

        order_id = event.params['orderId']
        customer_email = after_data.get('customerEmail')
        
        # ====================================================================
        # SCENARIO 1: NEW PAID ORDER (Notify Sellers)
        # ====================================================================
        old_pay_status = before_data.get('paymentStatus', '')
        new_pay_status = after_data.get('paymentStatus', '')
        
        if old_pay_status != 'paid' and new_pay_status == 'paid':
            print(f"💰 Order {order_id} paid. Processing seller notifications...")
            
            # Group items by Seller ID
            items = after_data.get('items', [])
            seller_groups = {}
            
            for item in items:
                seller_id = item.get('sellerId')
                if seller_id:
                    if seller_id not in seller_groups:
                        seller_groups[seller_id] = []
                    seller_groups[seller_id].append(item)
            
            # Iterate through each seller group and send specific emails
            for seller_id, seller_items in seller_groups.items():
                try:
                    # Fetch seller's email from 'users' collection
                    seller_doc = db.collection('users').document(seller_id).get()
                    if seller_doc.exists:
                        seller_data = seller_doc.to_dict()
                        seller_email = seller_data.get('email')
                        
                        if seller_email:
                            # Generate HTML for this seller's items only
                            items_html = ""
                            for item in seller_items:
                                items_html += f"""
                                <tr>
                                    <td style="padding: 12px; border-bottom: 1px solid #eee;">
                                        <strong>{item.get('name', 'Product')}</strong>
                                        <br><span style="font-size: 12px; color: #666;">ID: {item.get('productId', 'N/A')}</span>
                                    </td>
                                    <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
                                        {item.get('quantity', 1)}
                                    </td>
                                    <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">
                                        ${item.get('price', 0):.2f}
                                    </td>
                                </tr>
                                """

                            email_html = f"""
                            <!DOCTYPE html>
                            <html>
                            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto;">
                                <div style="background: #FF6B35; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                                    <h2 style="color: white; margin: 0;">📦 New Order to Ship!</h2>
                                </div>
                                <div style="border: 1px solid #eee; border-top: none; padding: 20px; border-radius: 0 0 8px 8px;">
                                    <p>Hello {seller_data.get('name', 'Seller')},</p>
                                    <p>You have sold items in Order <strong>#{order_id[:8]}</strong>.</p>
                                    
                                    <h3 style="border-bottom: 2px solid #FF6B35; padding-bottom: 10px;">Items to Ship</h3>
                                    <table style="width: 100%; border-collapse: collapse;">
                                        <thead>
                                            <tr style="background: #f8f9fa;">
                                                <th style="text-align: left; padding: 10px;">Item</th>
                                                <th style="text-align: center; padding: 10px;">Qty</th>
                                                <th style="text-align: right; padding: 10px;">Price</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {items_html}
                                        </tbody>
                                    </table>
                                    
                                    <div style="background: #f8f9fa; padding: 15px; margin-top: 20px; border-radius: 5px;">
                                        <strong>Shipping Address:</strong><br>
                                        {after_data.get('deliveryInfo', {}).get('formattedAddress', 'Address not provided')}
                                    </div>
                                    
                                    <p style="text-align: center; margin-top: 25px;">
                                        <a href="https://orignagta.com/seller/orders" style="background: #FF6B35; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Manage Order</a>
                                    </p>
                                </div>
                            </body>
                            </html>
                            """
                            
                            send_email(
                                to_email=seller_email,
                                subject=f"✅ Ship Now: New Order #{order_id[:8]}",
                                html_content=email_html
                            )
                            print(f"📧 Sent notification to seller {seller_id} ({seller_email})")
                except Exception as e:
                    print(f"❌ Failed to notify seller {seller_id}: {str(e)}")

        # ====================================================================
        # SCENARIO 2: ITEM STATUS UPDATE (Notify Customer)
        # ====================================================================
        before_items = before_data.get('items', [])
        after_items = after_data.get('items', [])
        
        # Compare items to find status changes
        for i, new_item in enumerate(after_items):
            if i >= len(before_items): break # Safety check
            old_item = before_items[i]
            
            old_status = old_item.get('status', 'pending')
            new_status = new_item.get('status', 'pending')
            
            # 2a. Item Shipped
            if old_status != 'shipped' and new_status == 'shipped':
                if customer_email:
                    tracking = new_item.get('trackingNumber', 'N/A')
                    item_name = new_item.get('name', 'Item')
                    
                    html_content = f"""
                    <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                        <h2 style="color: #2196F3;">✈️ Item Shipped!</h2>
                        <p><strong>{item_name}</strong> (x{new_item.get('quantity')}) from Order #{order_id[:8]} is on its way.</p>
                        <p style="background: #f5f5f5; padding: 10px;"><strong>Tracking Number:</strong> {tracking}</p>
                    </div>
                    """
                    send_email(customer_email, f"Item Shipped: {item_name}", html_content)
            
            # 2b. Item Delivered
            elif old_status != 'delivered' and new_status == 'delivered':
                if customer_email:
                    item_name = new_item.get('name', 'Item')
                    
                    html_content = f"""
                    <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                        <h2 style="color: #4CAF50;">🎉 Item Delivered!</h2>
                        <p><strong>{item_name}</strong> (x{new_item.get('quantity')}) from Order #{order_id[:8]} has been delivered.</p>
                        <p>Please log in to rate your product.</p>
                    </div>
                    """
                    send_email(customer_email, f"Delivered: {item_name}", html_content)

    except Exception as e:
        print(f"❌ Error in order trigger: {str(e)}")
        import traceback
        print(traceback.format_exc())