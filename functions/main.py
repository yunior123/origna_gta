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
from mailjet_rest import Client
import re

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
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY", "")
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY", "")
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    print("🧪 Running in EMULATOR mode")
else:
    from firebase_functions import params

    STRIPE_SECRET_KEY = params.SecretParam("STRIPE_SECRET_KEY").value
    STRIPE_WEBHOOK_SECRET = params.SecretParam("STRIPE_WEBHOOK_SECRET").value
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY").value
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY").value
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    print("🚀 Running in PRODUCTION mode")


stripe.api_key = STRIPE_SECRET_KEY

cors_config = options.CorsOptions(
    cors_origins=[
        "https://orignagta.ca",
        "https://www.orignagta.ca",
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
                <a href="https://orignagta.ca/orders" style="background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Track Your Order</a>
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

def send_email(
    to_email: str,
    subject: str,
    html_content: str,
    from_email: str = "orders@orignagta.com"
) -> bool:
    """Send email using Mailjet"""
    try:
        if IS_EMULATOR or not MAILJET_API_KEY:
            print(f"📧 [EMULATOR] Would send email to {to_email}: {subject}")
            return True

        mailjet = Client(
            auth=(MAILJET_API_KEY, MAILJET_SECRET_KEY),
            version='v3.1'
        )

        data = {
            'Messages': [
                {
                    "From": {
                        "Email": from_email,
                        "Name": "Origna GTA"
                    },
                    "To": [
                        {
                            "Email": to_email
                        }
                    ],
                    "Subject": subject,
                    "HTMLPart": html_content
                }
            ]
        }

        result = mailjet.send.create(data=data)

        status = result.status_code
        if status == 200:
            print(f"✉️ Mailjet email sent to {to_email}")
            return True
        else:
            print(f"❌ Mailjet failed: {result.json()}")
            return False

    except Exception as e:
        print(f"❌ Mailjet error: {str(e)}")
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

def sanitize_email(email: str) -> str:
    """Sanitize and validate email address"""
    email = email.strip().lower()
    if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email):
        raise ValueError("Invalid email format")
    return email

def validate_item(item: Dict) -> tuple[bool, str]:
    """Validate individual item data"""
    if not item.get('sellerId'):
        return False, "sellerId required for all items"
    if not item.get('productId'):
        return False, "productId required for all items"
    if item.get('quantity', 0) <= 0:
        return False, "quantity must be positive"
    if item.get('price', 0) < 0:
        return False, "price cannot be negative"
    if not item.get('name'):
        return False, "name required for all items"
    return True, ""

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
    
    # Validate email format
    try:
        sanitize_email(data['customerEmail'])
    except ValueError:
        return False, "Invalid email address format"
    
    # Validate each item
    for idx, item in enumerate(data['items']):
        is_valid, error_msg = validate_item(item)
        if not is_valid:
            return False, f"Item {idx}: {error_msg}"
    
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
        customer_email = sanitize_email(data['customerEmail'])
        amount = int(data['amount'])
        currency = data.get('currency', 'cad').lower()
        items = data['items']
        delivery_info = data['deliveryInfo']
        customer_id = data.get('customerId', '')
        
        order_ref = db.collection('orders').document()
        order_id = order_ref.id

        seller_ids = list(set([item.get('sellerId') for item in items if item.get('sellerId')]))
        
        line_items = []
        for item in items:
            # Get first image from imageUrls array if available
            images = []
            if item.get('imageUrls') and len(item.get('imageUrls', [])) > 0:
                images = [item['imageUrls'][0]]
            
            line_items.append({
                "price_data": {
                    "currency": currency,
                    "product_data": {
                        "name": item.get('name', 'Product'),
                        "images": images
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

        # Enrich items with delivery status and tracking
        enriched_items = []
        for item in items:
            item_copy = item.copy()
            item_copy['deliveryStatus'] = 'pending'  # Fixed: was 'status'
            item_copy['trackingNumber'] = None
            enriched_items.append(item_copy)

        base_url = "https://orignagta.ca"
         
        if IS_EMULATOR:
            base_url = "http://localhost:5000"
        success_url = f"{base_url}/payment-success?session_id={{CHECKOUT_SESSION_ID}}&order_id={order_id}"
        cancel_url = f"{base_url}/payment-cancel"
        
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
            "customerId": customer_id,  # Fixed: Added customerId
            "customerEmail": customer_email,
            "items": enriched_items,
            "sellerIds": seller_ids,
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
    except ValueError as e:
        print(f"❌ Validation Error: {str(e)}")
        return create_error_response(str(e), 400)
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        print(traceback.format_exc())
        return create_error_response(
            "Internal server error",
            500,
            str(e) if IS_EMULATOR else None
        )

"""
Enhanced Stripe Webhook Handler with Comprehensive Logging
Add this to your main.py file, replacing the existing stripe_webhook function
"""

@https_fn.on_request(timeout_sec=60)
def stripe_webhook(req: https_fn.Request) -> https_fn.Response:
    """Handle Stripe webhook events with detailed logging"""
    try:
        # ====================================================================
        # STEP 1: LOG INCOMING REQUEST DETAILS
        # ====================================================================
        print("=" * 80)
        print("📥 WEBHOOK REQUEST RECEIVED")
        print(f"Timestamp: {datetime.utcnow().isoformat()}")
        print(f"Method: {req.method}")
        print(f"Content-Type: {req.headers.get('content-type')}")
        print(f"Content-Length: {req.headers.get('content-length')}")
        print(f"User-Agent: {req.headers.get('user-agent', 'N/A')}")
        
        # ====================================================================
        # STEP 2: EXTRACT AND VALIDATE PAYLOAD
        # ====================================================================
        payload = req.data
        sig_header = req.headers.get('stripe-signature')
        
        print(f"\nPayload Info:")
        print(f"  - Size: {len(payload)} bytes")
        print(f"  - Type: {type(payload)}")
        print(f"  - First 100 chars: {payload[:100]}")
        
        print(f"\nSignature Info:")
        print(f"  - Header present: {bool(sig_header)}")
        
        if sig_header:
            # Parse signature components (don't log actual values for security)
            sig_parts = sig_header.split(',')
            print(f"  - Components count: {len(sig_parts)}")
            for part in sig_parts:
                if '=' in part:
                    key, _ = part.split('=', 1)
                    print(f"    • {key}: [PRESENT]")
        else:
            print("  - ❌ NO SIGNATURE HEADER FOUND")
        
        # ====================================================================
        # STEP 3: CHECK WEBHOOK SECRET CONFIGURATION
        # ====================================================================
        print(f"\nWebhook Secret Config:")
        print(f"  - Secret configured: {bool(STRIPE_WEBHOOK_SECRET)}")
        if STRIPE_WEBHOOK_SECRET:
            print(f"  - Secret prefix: {STRIPE_WEBHOOK_SECRET[:10]}...")
            print(f"  - Secret length: {len(STRIPE_WEBHOOK_SECRET)}")
            print(f"  - Starts with 'whsec_': {STRIPE_WEBHOOK_SECRET.startswith('whsec_')}")
        else:
            print("  - ❌ SECRET NOT CONFIGURED")
        
        print(f"  - Environment: {'EMULATOR' if IS_EMULATOR else 'PRODUCTION'}")
        
        if not sig_header:
            print("\n❌ FATAL: Missing Stripe signature header")
            print("=" * 80)
            return create_error_response("Missing Stripe signature", 400)
        
        # ====================================================================
        # STEP 4: ATTEMPT SIGNATURE VERIFICATION
        # ====================================================================
        print("\n🔐 Attempting signature verification...")
        
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, STRIPE_WEBHOOK_SECRET
            )
            print("✅ Signature verification SUCCESSFUL")
            
        except stripe.error.SignatureVerificationError as e:
            print("\n❌ SIGNATURE VERIFICATION FAILED")
            print(f"Error type: {type(e).__name__}")
            print(f"Error message: {str(e)}")
            
            # Additional debugging info
            print("\nDebug Information:")
            print(f"  - Payload is bytes: {isinstance(payload, bytes)}")
            print(f"  - Payload encoding test: {payload.decode('utf-8')[:200] if isinstance(payload, bytes) else 'Not bytes'}")
            
            # Test if the secret can compute signatures at all
            try:
                from stripe.webhook import WebhookSignature
                test_sig = WebhookSignature._compute_signature(payload, STRIPE_WEBHOOK_SECRET)
                print(f"  - Secret can compute signatures: ✓ (format OK)")
                print(f"  - Computed signature prefix: {test_sig[:20]}...")
            except Exception as sig_test_error:
                print(f"  - Secret computation test: ✗ ({sig_test_error})")
            
            # Check if webhook secret matches expected format
            if not STRIPE_WEBHOOK_SECRET.startswith('whsec_'):
                print("  - ⚠️  WARNING: Webhook secret doesn't start with 'whsec_'")
                print("  - This might be a test secret or incorrect secret type")
            
            print("\nPossible Issues:")
            print("  1. Wrong webhook secret (test vs production mismatch)")
            print("  2. Webhook endpoint URL mismatch in Stripe Dashboard")
            print("  3. Request body modified by middleware before reaching webhook")
            print("  4. Stripe signature version mismatch")
            
            print("=" * 80)
            return create_error_response("Invalid signature", 400)
        
        # ====================================================================
        # STEP 5: PROCESS WEBHOOK EVENT
        # ====================================================================
        event_type = event['type']
        event_data = event['data']['object']
        event_id = event.get('id', 'unknown')
        
        print(f"\n📨 Processing webhook event:")
        print(f"  - Event ID: {event_id}")
        print(f"  - Event Type: {event_type}")
        print(f"  - Created: {datetime.fromtimestamp(event.get('created', 0)).isoformat()}")
        print(f"  - Livemode: {event.get('livemode', False)}")
        
        # ====================================================================
        # CHECKOUT SESSION EVENTS
        # ====================================================================
        if event_type == 'checkout.session.completed':
            print("\n✅ Processing: checkout.session.completed")
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            print(f"  - Session ID: {session.get('id')}")
            print(f"  - Order ID: {order_id}")
            print(f"  - Payment Status: {session.get('payment_status')}")
            print(f"  - Amount Total: ${session.get('amount_total', 0) / 100}")
            
            if not order_id:
                print("  - ⚠️  No order ID found in session")
                return create_error_response("Order ID not found", 400)
            
            order_ref = db.collection('orders').document(order_id)
            order_doc = order_ref.get()
            
            if not order_doc.exists:
                print(f"  - ❌ Order {order_id} not found in database")
                return create_error_response("Order not found", 404)
            
            print(f"  - ✓ Order found in database")
            
            # Check payment status - some payments are async
            payment_status = session.get('payment_status')
            
            update_data = {
                "stripePaymentIntentId": session.get('payment_intent'),
                "stripeCustomerId": session.get('customer'),
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "paymentMethod": session.get('payment_method_types', [])[0] if session.get('payment_method_types') else None,
                "amountTotal": session.get('amount_total', 0) / 100,
            }
            
            if payment_status == 'paid':
                # Immediate payment success
                update_data.update({
                    "status": "confirmed",
                    "paymentStatus": "paid",
                    "paidAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"  - ✅ Marking order as PAID (immediate)")
                
                # Clear user's cart
                user_id = session['metadata'].get('userId')
                if user_id:
                    print(f"  - 🛒 Clearing cart for user {user_id}")
                    db.collection('users').document(user_id).update({
                        "cart": [],
                        "updatedAt": firestore.SERVER_TIMESTAMP
                    })
            elif payment_status == 'unpaid':
                # Async payment pending
                update_data.update({
                    "status": "processing",
                    "paymentStatus": "processing",
                })
                print(f"  - ⏳ Payment processing (async)")
            
            order_ref.update(update_data)
            print(f"  - ✓ Order updated in database")
        
        elif event_type == 'checkout.session.async_payment_succeeded':
            print("\n✅ Processing: checkout.session.async_payment_succeeded")
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            print(f"  - Order ID: {order_id}")
            
            if order_id:
                order_ref = db.collection('orders').document(order_id)
                if order_ref.get().exists:
                    order_ref.update({
                        "status": "confirmed",
                        "paymentStatus": "paid",
                        "paidAt": firestore.SERVER_TIMESTAMP,
                        "updatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    
                    # Clear user's cart
                    user_id = session['metadata'].get('userId')
                    if user_id:
                        print(f"  - 🛒 Clearing cart for user {user_id}")
                        db.collection('users').document(user_id).update({
                            "cart": [],
                            "updatedAt": firestore.SERVER_TIMESTAMP
                        })
                    
                    print(f"  - ✅ Async payment succeeded for order {order_id}")
                else:
                    print(f"  - ⚠️  Order {order_id} not found")
        
        elif event_type == 'checkout.session.async_payment_failed':
            print("\n❌ Processing: checkout.session.async_payment_failed")
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            print(f"  - Order ID: {order_id}")
            
            if order_id:
                order_ref = db.collection('orders').document(order_id)
                if order_ref.get().exists:
                    order_ref.update({
                        "status": "failed",
                        "paymentStatus": "payment_failed",
                        "paymentError": "Async payment failed",
                        "updatedAt": firestore.SERVER_TIMESTAMP,
                    })
                    print(f"  - ❌ Async payment failed for order {order_id}")
        
        elif event_type == 'checkout.session.expired':
            print("\n⏰ Processing: checkout.session.expired")
            session = event_data
            order_id = session.get('client_reference_id') or session['metadata'].get('orderId')
            
            print(f"  - Order ID: {order_id}")
            
            if order_id:
                order_ref = db.collection('orders').document(order_id)
                if order_ref.get().exists:
                    order_ref.update({
                        "status": "expired",
                        "paymentStatus": "session_expired",
                        "updatedAt": firestore.SERVER_TIMESTAMP
                    })
                    print(f"  - ⏰ Session expired for order {order_id}")
        
        # ====================================================================
        # PAYMENT INTENT EVENTS
        # ====================================================================
        elif event_type == 'payment_intent.succeeded':
            print("\n💰 Processing: payment_intent.succeeded")
            payment_intent = event_data
            print(f"  - Payment Intent ID: {payment_intent['id']}")
            
            orders = db.collection('orders').where(
                'stripePaymentIntentId', '==', payment_intent['id']
            ).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                order_data = orders[0].to_dict()
                
                print(f"  - Found order: {order_ref.id}")
                
                # Only update if not already paid
                if order_data.get('paymentStatus') != 'paid':
                    order_ref.update({
                        "status": "confirmed",
                        "paymentStatus": "paid",
                        "paidAt": firestore.SERVER_TIMESTAMP,
                        "updatedAt": firestore.SERVER_TIMESTAMP,
                        "amountReceived": payment_intent.get('amount_received', 0) / 100,
                    })
                    
                    # Clear user's cart
                    user_id = order_data.get('userId')
                    if user_id:
                        print(f"  - 🛒 Clearing cart for user {user_id}")
                        db.collection('users').document(user_id).update({
                            "cart": [],
                            "updatedAt": firestore.SERVER_TIMESTAMP
                        })
                    
                    print(f"  - ✅ Payment intent succeeded")
                else:
                    print(f"  - ℹ️  Order already marked as paid")
            else:
                print(f"  - ⚠️  No order found for payment intent")
        
        elif event_type == 'payment_intent.payment_failed':
            print("\n❌ Processing: payment_intent.payment_failed")
            payment_intent = event_data
            orders = db.collection('orders').where(
                'stripePaymentIntentId', '==', payment_intent['id']
            ).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                last_error = payment_intent.get('last_payment_error', {})
                
                print(f"  - Order: {order_ref.id}")
                print(f"  - Error: {last_error.get('message', 'Unknown error')}")
                
                order_ref.update({
                    "status": "failed",
                    "paymentStatus": "payment_failed",
                    "paymentError": last_error.get('message', 'Payment failed'),
                    "paymentErrorCode": last_error.get('code'),
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"  - ❌ Payment failed")
        
        # ====================================================================
        # REFUND EVENTS
        # ====================================================================
        elif event_type == 'refund.created':
            print("\n💰 Processing: refund.created")
            refund = event_data
            refund_id = refund['id']
            amount = refund.get('amount', 0) / 100
            reason = refund.get('reason', 'requested_by_customer')
            
            print(f"  - Refund ID: {refund_id}")
            print(f"  - Amount: ${amount}")
            print(f"  - Reason: {reason}")
            
            # Find order by payment intent
            payment_intent_id = refund.get('payment_intent')
            orders = db.collection('orders').where(
                'stripePaymentIntentId', '==', payment_intent_id
            ).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                order_data = orders[0].to_dict()
                
                print(f"  - Order: {order_ref.id}")
                
                # Initialize refunds array if it doesn't exist
                refunds = order_data.get('refunds', [])
                refunds.append({
                    "refundId": refund_id,
                    "amount": amount,
                    "status": "pending",
                    "reason": reason,
                    "createdAt": firestore.SERVER_TIMESTAMP,
                })
                
                order_ref.update({
                    "refunds": refunds,
                    "refundStatus": "processing",
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"  - ✓ Refund recorded")
        
        elif event_type == 'refund.updated':
            print("\n💰 Processing: refund.updated")
            refund = event_data
            refund_id = refund['id']
            refund_status = refund.get('status')
            payment_intent_id = refund.get('payment_intent')
            
            print(f"  - Refund ID: {refund_id}")
            print(f"  - Status: {refund_status}")
            
            orders = db.collection('orders').where(
                'stripePaymentIntentId', '==', payment_intent_id
            ).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                order_data = orders[0].to_dict()
                refunds = order_data.get('refunds', [])
                
                # Update the specific refund
                for r in refunds:
                    if r.get('refundId') == refund_id:
                        r['status'] = refund_status
                        r['updatedAt'] = firestore.SERVER_TIMESTAMP
                        break
                
                # Determine overall refund status
                all_succeeded = all(r.get('status') == 'succeeded' for r in refunds)
                any_failed = any(r.get('status') == 'failed' for r in refunds)
                
                overall_status = 'refunded' if all_succeeded else 'partially_refunded' if any_failed else 'processing'
                
                order_ref.update({
                    "refunds": refunds,
                    "refundStatus": overall_status,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"  - ✓ Refund updated to: {overall_status}")
        
        elif event_type == 'refund.failed':
            print("\n❌ Processing: refund.failed")
            refund = event_data
            refund_id = refund['id']
            failure_reason = refund.get('failure_reason', 'Unknown')
            payment_intent_id = refund.get('payment_intent')
            
            print(f"  - Refund ID: {refund_id}")
            print(f"  - Failure Reason: {failure_reason}")
            
            orders = db.collection('orders').where(
                'stripePaymentIntentId', '==', payment_intent_id
            ).limit(1).get()
            
            if orders:
                order_ref = orders[0].reference
                order_data = orders[0].to_dict()
                refunds = order_data.get('refunds', [])
                
                # Update the specific refund
                for r in refunds:
                    if r.get('refundId') == refund_id:
                        r['status'] = 'failed'
                        r['failureReason'] = failure_reason
                        r['updatedAt'] = firestore.SERVER_TIMESTAMP
                        break
                
                order_ref.update({
                    "refunds": refunds,
                    "refundStatus": "failed",
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                print(f"  - ✓ Refund marked as failed")
        
        # ====================================================================
        # INVOICE EVENTS
        # ====================================================================
        elif event_type == 'invoice.paid':
            print("\n📄 Processing: invoice.paid")
            invoice = event_data
            invoice_id = invoice['id']
            amount_paid = invoice.get('amount_paid', 0) / 100
            
            print(f"  - Invoice ID: {invoice_id}")
            print(f"  - Amount Paid: ${amount_paid}")
        
        elif event_type == 'invoice.payment_failed':
            print("\n❌ Processing: invoice.payment_failed")
            invoice = event_data
            invoice_id = invoice['id']
            
            print(f"  - Invoice ID: {invoice_id}")
        
        # ====================================================================
        # UNKNOWN EVENT TYPE
        # ====================================================================
        else:
            print(f"\n⚠️  Unhandled webhook event type: {event_type}")
        
        print("\n✅ Webhook processed successfully")
        print("=" * 80)
        return create_success_response({"received": True})
        
    except Exception as e:
        print("\n" + "=" * 80)
        print("❌ WEBHOOK ERROR")
        print(f"Error Type: {type(e).__name__}")
        print(f"Error Message: {str(e)}")
        print(f"Traceback:")
        print(traceback.format_exc())
        print("=" * 80)
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
    2. If Item deliveryStatus -> 'shipped'/'delivered': Email Customer with updates.
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
                                        <a href="https://orignagta.ca/seller/orders" style="background: #FF6B35; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Manage Order</a>
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
        # Fixed: Match items by productId instead of assuming same order
        # ====================================================================
        before_items = before_data.get('items', [])
        after_items = after_data.get('items', [])
        
        # Create dict of before items keyed by productId
        before_items_dict = {item.get('productId'): item for item in before_items if item.get('productId')}
        
        # Compare items to find status changes
        for new_item in after_items:
            product_id = new_item.get('productId')
            if not product_id:
                continue
                
            old_item = before_items_dict.get(product_id, {})
            
            # Fixed: Use 'deliveryStatus' instead of 'status'
            old_status = old_item.get('deliveryStatus', 'pending')
            new_status = new_item.get('deliveryStatus', 'pending')
            
            # 2a. Item Shipped
            if old_status != 'shipped' and new_status == 'shipped':
                if customer_email:
                    tracking = new_item.get('trackingNumber', 'N/A')
                    item_name = new_item.get('name', 'Item')
                    
                    html_content = f"""
                    <!DOCTYPE html>
                    <html>
                    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <div style="padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                            <h2 style="color: #2196F3;">✈️ Item Shipped!</h2>
                            <p><strong>{item_name}</strong> (x{new_item.get('quantity')}) from Order #{order_id[:8]} is on its way.</p>
                            <p style="background: #f5f5f5; padding: 10px; border-radius: 5px;"><strong>Tracking Number:</strong> {tracking}</p>
                            <p style="text-align: center; margin-top: 20px;">
                                <a href="https://orignagta.ca/orders/{order_id}" style="background: #2196F3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Track Order</a>
                            </p>
                        </div>
                    </body>
                    </html>
                    """
                    send_email(customer_email, f"Item Shipped: {item_name}", html_content)
                    print(f"📧 Sent 'shipped' email to customer for {item_name}")
            
            # 2b. Item Delivered
            elif old_status != 'delivered' and new_status == 'delivered':
                if customer_email:
                    item_name = new_item.get('name', 'Item')
                    
                    html_content = f"""
                    <!DOCTYPE html>
                    <html>
                    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <div style="padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                            <h2 style="color: #4CAF50;">🎉 Item Delivered!</h2>
                            <p><strong>{item_name}</strong> (x{new_item.get('quantity')}) from Order #{order_id[:8]} has been delivered.</p>
                            <p>We hope you love your purchase! Please consider leaving a review.</p>
                            <p style="text-align: center; margin-top: 20px;">
                                <a href="https://orignagta.ca/products/{new_item.get('productId')}" style="background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Leave a Review</a>
                            </p>
                        </div>
                    </body>
                    </html>
                    """
                    send_email(customer_email, f"Delivered: {item_name}", html_content)
                    print(f"📧 Sent 'delivered' email to customer for {item_name}")

    except Exception as e:
        print(f"❌ Error in order trigger: {str(e)}")
        print(traceback.format_exc())


# ============================================================================
# R2 CLOUDFLARE STORAGE FUNCTIONS
# ============================================================================

from firebase_functions.params import SecretParam
import boto3
from botocore.config import Config

R2_ACCESS_KEY_NEW = SecretParam("R2_ACCESS_KEY")
R2_SECRET_KEY_NEW = SecretParam("R2_SECRET_KEY")
R2_ACCOUNT_ID_NEW = SecretParam("R2_ACCOUNT_ID")

@https_fn.on_call(secrets=[R2_ACCESS_KEY_NEW, R2_SECRET_KEY_NEW, R2_ACCOUNT_ID_NEW])
def get_r2_presigned_url(req: https_fn.CallableRequest) -> Any:
    """Generate presigned URL for uploading to Cloudflare R2"""
    file_name = req.data.get("fileName")
    
    if not file_name:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="fileName is required"
        )
    
    try:
        # Use .value to access the secret content safely
        r2 = boto3.client(
            's3',
            endpoint_url=f"https://{R2_ACCOUNT_ID_NEW.value}.r2.cloudflarestorage.com",
            aws_access_key_id=R2_ACCESS_KEY_NEW.value,
            aws_secret_access_key=R2_SECRET_KEY_NEW.value,
            config=Config(signature_version='s3v4'),
        )

        url = r2.generate_presigned_url(
            ClientMethod='put_object',
            Params={'Bucket': 'orignagta', 'Key': f"products/{file_name}"},
            ExpiresIn=3600 
        )
        
        return {"uploadUrl": url}
    
    except Exception as e:
        print(f"❌ Error generating R2 presigned URL: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Failed to generate upload URL"
        )