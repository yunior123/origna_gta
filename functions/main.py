"""
Firebase Cloud Functions for Stripe Payment Integration
Production-ready implementation with comprehensive logging and security

Setup Instructions:
1. Install dependencies: pip install -r requirements.txt
2. Set environment variables or Firebase secrets:
   - STRIPE_SECRET_KEY
   - STRIPE_WEBHOOK_SECRET
   - MAILJET_API_KEY
   - MAILJET_SECRET_KEY
   - R2_ACCESS_KEY (optional)
   - R2_SECRET_KEY (optional)
   - R2_ACCOUNT_ID (optional)
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
from enum import Enum

# ============================================================================
# CONSTANTS - Must match Flutter constants.dart
# ============================================================================

class OrderStatus:
    PENDING = 'pending'
    CONFIRMED = 'confirmed'
    PROCESSING = 'processing'
    SHIPPED = 'shipped'
    DELIVERED = 'delivered'
    CANCELLED = 'cancelled'
    FAILED = 'failed'
    EXPIRED = 'expired'
    REFUNDED = 'refunded'
    PARTIALLY_REFUNDED = 'partially_refunded'

class PaymentStatus:
    AWAITING_PAYMENT = 'awaiting_payment'
    PROCESSING = 'processing'
    PAID = 'paid'
    PAYMENT_FAILED = 'payment_failed'
    REFUNDED = 'refunded'
    SESSION_EXPIRED = 'session_expired'

class DeliveryStatus:
    PENDING = 'pending'
    SHIPPED = 'shipped'
    DELIVERED = 'delivered'

class UserRoles:
    ADMIN = 'admin'
    SELLER = 'seller'

class Collections:
    USERS = 'users'
    PRODUCTS = 'products'
    ORDERS = 'orders'
    CART = 'cart'
    FAVORITES = 'favorites'

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

def get_order_confirmation_email(order_data: Dict[str, Any]) -> str:
    """Generate HTML email for customer order confirmation"""
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
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🎉 Order Confirmed!</h1>
            <p style="color: white; margin: 10px 0 0 0;">Thank you for your purchase</p>
        </div>
        
        <div style="background: #ffffff; padding: 30px; border: 1px solid #eee; border-top: none;">
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h2 style="margin: 0 0 10px 0; color: #FF6B35;">Order Details</h2>
                <p style="margin: 5px 0;"><strong>Order ID:</strong> {order_data.get('orderId', 'N/A')}</p>
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.utcnow().strftime('%B %d, %Y')}</p>
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
                    <tr style="font-weight: bold; background: #f8f9fa;">
                        <td colspan="2" style="padding: 12px; text-align: right; border-top: 2px solid #ddd;">Total:</td>
                        <td style="padding: 12px; text-align: right; color: #FF6B35; font-size: 18px; border-top: 2px solid #ddd;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </tbody>
            </table>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                <h3 style="margin: 0 0 10px 0; color: #333;">Delivery Address</h3>
                <p style="margin: 0; line-height: 1.8;">
                    {delivery_info.get('formattedAddress', 'N/A')}<br>
                    {f"Phone: {delivery_info.get('phoneNumber', 'N/A')}" if delivery_info.get('phoneNumber') else ''}
                </p>
            </div>
            
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
                        <td style="padding: 10px 0 5px 0;">Total:</td>
                        <td style="text-align: right; padding: 10px 0 5px 0; color: #FF6B35;">${order_data.get('total', 0):.2f} CAD</td>
                    </tr>
                </table>
            </div>
            
            <div style="text-align: center; margin-top: 30px;">
                <a href="https://orignagta.ca/seller/orders" style="background: #FF6B35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Manage Orders</a>
            </div>
        </div>
        
        <div style="text-align: center; padding: 20px; color: #999; font-size: 12px;">
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


def log_webhook_to_database(
    event_id: str,
    event_type: str,
    payload_size: int,
    signature_verified: bool,
    processing_status: str,
    order_id: Optional[str] = None,
    error_message: Optional[str] = None,
    raw_event_data: Optional[Dict] = None
) -> None:
    """
    Log all webhook calls to database for audit trail and debugging
    
    Args:
        event_id: Stripe event ID
        event_type: Type of Stripe event
        payload_size: Size of payload in bytes
        signature_verified: Whether signature verification passed
        processing_status: success, failed, skipped, etc.
        order_id: Associated order ID if found
        error_message: Error message if processing failed
        raw_event_data: Complete event data for debugging
    """
    try:
        log_data = {
            "eventId": event_id,
            "eventType": event_type,
            "payloadSize": payload_size,
            "signatureVerified": signature_verified,
            "processingStatus": processing_status,
            "orderId": order_id,
            "errorMessage": error_message,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "environment": "emulator" if IS_EMULATOR else "production",
        }
        
        # Store limited event data to avoid bloat
        if raw_event_data:
            log_data["eventData"] = {
                "id": raw_event_data.get("id"),
                "type": raw_event_data.get("type"),
                "created": raw_event_data.get("created"),
                "livemode": raw_event_data.get("livemode"),
                "object_id": raw_event_data.get("data", {}).get("object", {}).get("id"),
            }
        
        db.collection('webhook_logs').document(event_id).set(log_data)
        print(f"✅ Logged webhook {event_id} to database")
        
    except Exception as e:
        print(f"⚠️ Failed to log webhook to database: {str(e)}")


# ============================================================================
# STRIPE CHECKOUT FUNCTIONS
# ============================================================================

"""
CORRECTED create_checkout_session function for main.py
Replace the existing function with this version

This version uses @https_fn.on_call which is compatible with
Dart's FirebaseFunctions.instance.httpsCallable()
"""

@https_fn.on_call(cors=cors_config)
def create_checkout_session(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Create Stripe Checkout Session - Callable Function
    
    Compatible with Dart: FirebaseFunctions.instance.httpsCallable('create_checkout_session')
    
    Args:
        req.data: Order data from frontend
        
    Returns:
        {
            "url": Stripe checkout URL,
            "sessionId": Stripe session ID,
            "orderId": Firebase order ID
        }
        
    Raises:
        https_fn.HttpsError: On validation or processing errors
    """
    try:
        data = req.data
        
        if not data:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Request body is required"
            )
        
        # Validate order data
        is_valid, error_msg = validate_order_data(data)
        if not is_valid:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=error_msg
            )
        
        # Extract user ID from auth context (more secure than trusting client)
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated"
            )
        
        auth_user_id = req.auth.uid
        
        # Get data from request
        user_id = data.get('userId', auth_user_id)  # Use auth UID as fallback
        customer_email = sanitize_email(data['customerEmail'])
        amount = int(data['amount'])
        currency = data.get('currency', 'cad').lower()
        items = data['items']
        delivery_info = data['deliveryInfo']
        customer_id = data.get('customerId', '')
        
        # Validate user ID matches authenticated user (security)
        if user_id != auth_user_id:
            print(f"⚠️ User ID mismatch: claimed={user_id}, auth={auth_user_id}")
            user_id = auth_user_id  # Use authenticated ID

        # ================================================================
        # ATOMIC STOCK VALIDATION AND RESERVATION
        # ================================================================
        print("🔒 Validating and reserving stock...")

        @firestore.transactional
        def validate_and_reserve_stock(transaction):
            """Atomically validate and decrement stock for all items"""
            stock_updates = []

            for item in items:
                product_id = item.get('productId')
                quantity = item.get('quantity', 1)

                if not product_id:
                    raise ValueError(f"Missing productId in item")

                product_ref = db.collection(Collections.PRODUCTS).document(product_id)
                product_doc = product_ref.get(transaction=transaction)

                if not product_doc.exists:
                    raise ValueError(f"Product {product_id} not found")

                product_data = product_doc.to_dict()
                current_stock = product_data.get('stockQuantity', 0)
                product_name = product_data.get('name', 'Unknown')

                if current_stock < quantity:
                    raise ValueError(f"Insufficient stock for '{product_name}'. Available: {current_stock}, Requested: {quantity}")

                stock_updates.append((product_ref, current_stock - quantity))

            # All validations passed, now decrement stock
            for product_ref, new_stock in stock_updates:
                transaction.update(product_ref, {'stockQuantity': new_stock})

            return True

        try:
            transaction = db.transaction()
            validate_and_reserve_stock(transaction)
            print("✅ Stock reserved successfully")
        except ValueError as e:
            print(f"❌ Stock validation failed: {str(e)}")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message=str(e)
            )

        # Create new order with auto-generated ID
        order_ref = db.collection(Collections.ORDERS).document()
        order_id = order_ref.id
        print(f"📝 Creating order: {order_id}")

        # Extract unique seller IDs
        seller_ids = list(set([item.get('sellerId') for item in items if item.get('sellerId')]))
        
        # Build Stripe line items
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
                    "unit_amount": int(item['price'] * 100),  # Convert to cents
                },
                "quantity": item.get('quantity', 1)
            })
        
        # Add shipping if present
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
        
        # Add taxes as separate line items
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
            item_copy['deliveryStatus'] = DeliveryStatus.PENDING
            item_copy['trackingNumber'] = None
            enriched_items.append(item_copy)

        # Build success/cancel URLs
        base_url = "https://orignagta.ca"
        if IS_EMULATOR:
            base_url = "http://localhost:5000"
            
        success_url = f"{base_url}/payment-success?session_id={{CHECKOUT_SESSION_ID}}&order_id={order_id}"
        cancel_url = f"{base_url}/payment-cancel"
        
        # Create Stripe checkout session
        print(f"💳 Creating Stripe session for order {order_id}")
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
            client_reference_id=order_id,  # Critical for webhook to find order
            billing_address_collection="auto",
            expires_at=int((datetime.utcnow().timestamp() + 1800))  # 30 minutes
        )
        
        # Save order to Firestore
        order_data = {
            "orderId": order_id,
            "userId": user_id,
            "customerId": customer_id,
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
            "status": OrderStatus.PENDING,
            "paymentStatus": PaymentStatus.AWAITING_PAYMENT,
            "stripeSessionId": session.id,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        
        order_ref.set(order_data)
        print(f"✅ Order {order_id} created successfully")
        
        # Return response (no need for create_success_response wrapper)
        return {
            "url": session.url,
            "sessionId": session.id,
            "orderId": order_id
        }
        
    except https_fn.HttpsError:
        # Re-raise HttpsError as-is
        raise
        
    except stripe.error.StripeError as e:
        print(f"❌ Stripe Error: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Payment processing error",
            details=str(e) if IS_EMULATOR else None
        )
        
    except ValueError as e:
        print(f"❌ Validation Error: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=str(e)
        )
        
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Internal server error",
            details=str(e) if IS_EMULATOR else None
        )


# ============================================================================
# STRIPE WEBHOOK HANDLER - PRODUCTION READY WITH COMPREHENSIVE LOGGING
# ============================================================================

@https_fn.on_request(timeout_sec=60)
def stripe_webhook(req: https_fn.Request) -> https_fn.Response:
    """
    Handle Stripe webhook events with comprehensive logging and security
    
    This function:
    1. Verifies webhook signature according to Stripe best practices
    2. Logs all webhook events to database for audit trail
    3. Implements idempotency to prevent duplicate processing
    4. Processes payment events and updates orders
    5. Sends confirmation emails
    """
    
    event_id = "unknown"
    payload_size = 0
    
    try:
        # ====================================================================
        # STEP 1: EXTRACT RAW PAYLOAD - CRITICAL FOR SIGNATURE VERIFICATION
        # ====================================================================
        # IMPORTANT: We must use req.data (raw bytes) not req.get_json()
        # Parsing JSON before signature verification will cause verification to fail
        payload = req.data
        sig_header = req.headers.get('stripe-signature')
        payload_size = len(payload)
        
        print("=" * 80)
        print("📥 WEBHOOK REQUEST RECEIVED")
        print(f"Timestamp: {datetime.utcnow().isoformat()}")
        print(f"Payload Size: {payload_size} bytes")
        print(f"Signature Present: {bool(sig_header)}")
        
        if not sig_header:
            error_msg = "Missing Stripe signature header"
            print(f"❌ {error_msg}")
            log_webhook_to_database(
                event_id="missing_signature",
                event_type="unknown",
                payload_size=payload_size,
                signature_verified=False,
                processing_status="failed",
                error_message=error_msg
            )
            return create_error_response(error_msg, 400)
        
        # ====================================================================
        # STEP 2: VERIFY SIGNATURE - ACCORDING TO STRIPE DOCUMENTATION
        # ====================================================================
        # Reference: https://docs.stripe.com/webhooks/signature
        print("🔐 Verifying webhook signature...")
        
        try:
            # Use stripe.Webhook.construct_event() which:
            # 1. Verifies the signature using HMAC-SHA256
            # 2. Checks the timestamp is within tolerance (default 5 minutes)
            # 3. Returns the parsed event object if valid
            event = stripe.Webhook.construct_event(
                payload,  # Raw bytes - never parsed JSON
                sig_header,
                STRIPE_WEBHOOK_SECRET
            )
            print("✅ Signature verification SUCCESSFUL")
            
        except ValueError as e:
            # Invalid payload (not valid JSON)
            error_msg = f"Invalid payload: {str(e)}"
            print(f"❌ {error_msg}")
            log_webhook_to_database(
                event_id="invalid_payload",
                event_type="unknown",
                payload_size=payload_size,
                signature_verified=False,
                processing_status="failed",
                error_message=error_msg
            )
            return create_error_response("Invalid payload", 400)
            
        except stripe.error.SignatureVerificationError as e:
            # Invalid signature
            error_msg = f"Signature verification failed: {str(e)}"
            print(f"❌ {error_msg}")
            print(f"Webhook secret prefix: {STRIPE_WEBHOOK_SECRET[:10]}...")
            print(f"Webhook secret length: {len(STRIPE_WEBHOOK_SECRET)}")
            
            log_webhook_to_database(
                event_id="invalid_signature",
                event_type="unknown",
                payload_size=payload_size,
                signature_verified=False,
                processing_status="failed",
                error_message=error_msg
            )
            return create_error_response("Invalid signature", 400)
        
        # ====================================================================
        # STEP 3: EXTRACT EVENT DATA
        # ====================================================================
        event_id = event.get('id', 'unknown')
        event_type = event['type']
        event_data = event['data']['object']
        
        print(f"\n📨 Event Details:")
        print(f"  Event ID: {event_id}")
        print(f"  Event Type: {event_type}")
        print(f"  Created: {datetime.fromtimestamp(event.get('created', 0)).isoformat()}")
        print(f"  Livemode: {event.get('livemode', False)}")
        
        # ====================================================================
        # STEP 4: IDEMPOTENCY CHECK - PREVENT DUPLICATE PROCESSING
        # ====================================================================
        # Stripe may send the same event multiple times
        # We must ensure we only process each event once
        event_log_ref = db.collection('webhook_events').document(event_id)
        event_log = event_log_ref.get()
        
        if event_log.exists:
            print(f"ℹ️ Event {event_id} already processed - skipping")
            log_webhook_to_database(
                event_id=event_id,
                event_type=event_type,
                payload_size=payload_size,
                signature_verified=True,
                processing_status="skipped_duplicate",
                raw_event_data=event
            )
            return create_success_response({
                "received": True,
                "status": "already_processed"
            })
        
        # Mark event as received (before processing)
        event_log_ref.set({
            "eventId": event_id,
            "eventType": event_type,
            "receivedAt": firestore.SERVER_TIMESTAMP,
            "processed": False,
            "livemode": event.get('livemode', False)
        })
        
        # ====================================================================
        # STEP 5: PROCESS EVENT BY TYPE
        # ====================================================================
        order_id = None
        processing_status = "success"
        error_message = None
        
        try:
            if event_type == 'checkout.session.completed':
                order_id = process_checkout_session_completed(event_data)
                
            elif event_type == 'checkout.session.async_payment_succeeded':
                order_id = process_async_payment_succeeded(event_data)
                
            elif event_type == 'checkout.session.async_payment_failed':
                order_id = process_async_payment_failed(event_data)
                
            elif event_type == 'checkout.session.expired':
                order_id = process_session_expired(event_data)
                
            elif event_type == 'payment_intent.succeeded':
                order_id = process_payment_intent_succeeded(event_data)
                
            elif event_type == 'payment_intent.payment_failed':
                order_id = process_payment_intent_failed(event_data)
                
            elif event_type == 'charge.refunded':
                order_id = process_charge_refunded(event_data)
                
            else:
                print(f"ℹ️ Unhandled event type: {event_type}")
                processing_status = "unhandled"
        
        except Exception as process_error:
            processing_status = "failed"
            error_message = str(process_error)
            print(f"❌ Error processing event: {error_message}")
            print(traceback.format_exc())
        
        # ====================================================================
        # STEP 6: UPDATE EVENT LOG AS PROCESSED
        # ====================================================================
        event_log_ref.update({
            "processed": True,
            "processedAt": firestore.SERVER_TIMESTAMP,
            "processingStatus": processing_status,
            "orderId": order_id,
            "errorMessage": error_message
        })
        
        # ====================================================================
        # STEP 7: LOG TO DATABASE FOR AUDIT TRAIL
        # ====================================================================
        log_webhook_to_database(
            event_id=event_id,
            event_type=event_type,
            payload_size=payload_size,
            signature_verified=True,
            processing_status=processing_status,
            order_id=order_id,
            error_message=error_message,
            raw_event_data=event
        )
        
        print("✅ Webhook processed successfully")
        print("=" * 80)
        
        return create_success_response({"received": True})
        
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(f"❌ {error_msg}")
        print(traceback.format_exc())
        
        log_webhook_to_database(
            event_id=event_id,
            event_type="unknown",
            payload_size=payload_size,
            signature_verified=False,
            processing_status="failed",
            error_message=error_msg
        )
        
        return create_error_response("Internal error", 500)


# ============================================================================
# WEBHOOK EVENT PROCESSORS
# ============================================================================

def process_checkout_session_completed(session: Dict) -> Optional[str]:
    """Process checkout.session.completed event"""
    print("\n✅ Processing: checkout.session.completed")

    # Extract order ID - use defensive programming
    order_id = (
        session.get('client_reference_id') or
        session.get('metadata', {}).get('orderId')
    )

    print(f"  Session ID: {session.get('id')}")
    print(f"  Order ID: {order_id}")
    print(f"  Payment Status: {session.get('payment_status')}")
    print(f"  Amount Total: ${session.get('amount_total', 0) / 100}")

    if not order_id:
        print("  ⚠️ No order ID found in session")
        raise ValueError("Order ID not found in session")

    order_ref = db.collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        print(f"  ❌ Order {order_id} not found in database")
        raise ValueError(f"Order {order_id} not found")

    print(f"  ✓ Order found in database")

    order_data = order_doc.to_dict()

    # ================================================================
    # AMOUNT VERIFICATION - Fraud Protection
    # ================================================================
    stripe_amount = session.get('amount_total', 0)  # In cents
    stored_amount = order_data.get('amount', 0)  # In cents

    # Allow small tolerance for rounding (1 cent)
    if abs(stripe_amount - stored_amount) > 1:
        print(f"  🚨 FRAUD ALERT: Amount mismatch!")
        print(f"     Stripe amount: {stripe_amount} cents")
        print(f"     Stored amount: {stored_amount} cents")

        # Flag the order as potentially fraudulent
        order_ref.update({
            "status": OrderStatus.FAILED,
            "paymentStatus": PaymentStatus.PAYMENT_FAILED,
            "fraudAlert": True,
            "fraudReason": f"Amount mismatch: Stripe={stripe_amount}, Order={stored_amount}",
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        # Restore stock since payment is rejected
        _restore_stock_for_order(order_data)

        raise ValueError(f"Amount verification failed: mismatch detected")
    
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
            "status": OrderStatus.CONFIRMED,
            "paymentStatus": PaymentStatus.PAID,
            "paidAt": firestore.SERVER_TIMESTAMP,
        })
        print(f"  ✅ Marking order as PAID")

        # Clear user's cart
        user_id = session.get('metadata', {}).get('userId')
        if user_id:
            _clear_user_cart(user_id)

        # Send confirmation emails
        send_order_confirmation_emails(order_id, order_data)

    elif payment_status == 'unpaid':
        # Async payment pending
        update_data.update({
            "status": OrderStatus.PROCESSING,
            "paymentStatus": PaymentStatus.PROCESSING,
        })
        print(f"  ⏳ Payment processing (async)")

    order_ref.update(update_data)
    print(f"  ✓ Order updated")

    return order_id


def _clear_user_cart(user_id: str) -> None:
    """Clear user's cart subcollection"""
    print(f"  🛒 Clearing cart for user {user_id}")
    try:
        cart_ref = db.collection(Collections.USERS).document(user_id).collection(Collections.CART)
        cart_docs = cart_ref.stream()
        for doc in cart_docs:
            doc.reference.delete()
        print(f"  ✓ Cart cleared")
    except Exception as e:
        print(f"  ⚠️ Failed to clear cart: {str(e)}")


def _restore_stock_for_order(order_data: Dict) -> None:
    """Restore stock for all items in an order (used when payment fails/expires)"""
    print("  📦 Restoring stock for order items...")
    try:
        items = order_data.get('items', [])
        for item in items:
            product_id = item.get('productId')
            quantity = item.get('quantity', 1)

            if product_id:
                product_ref = db.collection(Collections.PRODUCTS).document(product_id)
                product_ref.update({
                    'stockQuantity': firestore.Increment(quantity)
                })
                print(f"    ✓ Restored {quantity} units for product {product_id}")
    except Exception as e:
        print(f"  ⚠️ Failed to restore stock: {str(e)}")


def process_async_payment_succeeded(session: Dict) -> Optional[str]:
    """Process checkout.session.async_payment_succeeded event"""
    print("\n✅ Processing: checkout.session.async_payment_succeeded")

    order_id = (
        session.get('client_reference_id') or
        session.get('metadata', {}).get('orderId')
    )

    print(f"  Order ID: {order_id}")

    if not order_id:
        print("  ⚠️ No order ID found")
        return None

    order_ref = db.collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if order_doc.exists:
        order_ref.update({
            "status": OrderStatus.CONFIRMED,
            "paymentStatus": PaymentStatus.PAID,
            "paidAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        # Clear user's cart
        user_id = session.get('metadata', {}).get('userId')
        if user_id:
            _clear_user_cart(user_id)

        # Send confirmation emails
        send_order_confirmation_emails(order_id, order_doc.to_dict())

        print(f"  ✅ Async payment succeeded")
    else:
        print(f"  ⚠️ Order {order_id} not found")

    return order_id


def process_async_payment_failed(session: Dict) -> Optional[str]:
    """Process checkout.session.async_payment_failed event"""
    print("\n❌ Processing: checkout.session.async_payment_failed")

    order_id = (
        session.get('client_reference_id') or
        session.get('metadata', {}).get('orderId')
    )

    print(f"  Order ID: {order_id}")

    if order_id:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()
        if order_doc.exists:
            order_data = order_doc.to_dict()
            order_ref.update({
                "status": OrderStatus.FAILED,
                "paymentStatus": PaymentStatus.PAYMENT_FAILED,
                "paymentError": "Async payment failed",
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            # Restore stock for failed payment
            _restore_stock_for_order(order_data)
            print(f"  ❌ Async payment failed - stock restored")

    return order_id


def process_session_expired(session: Dict) -> Optional[str]:
    """Process checkout.session.expired event"""
    print("\n⏰ Processing: checkout.session.expired")

    order_id = (
        session.get('client_reference_id') or
        session.get('metadata', {}).get('orderId')
    )

    print(f"  Order ID: {order_id}")

    if order_id:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()
        if order_doc.exists:
            order_data = order_doc.to_dict()
            order_ref.update({
                "status": OrderStatus.EXPIRED,
                "paymentStatus": PaymentStatus.SESSION_EXPIRED,
                "updatedAt": firestore.SERVER_TIMESTAMP
            })
            # Restore stock for expired session
            _restore_stock_for_order(order_data)
            print(f"  ⏰ Session expired - stock restored")

    return order_id


def process_payment_intent_succeeded(payment_intent: Dict) -> Optional[str]:
    """Process payment_intent.succeeded event"""
    print("\n💰 Processing: payment_intent.succeeded")
    print(f"  Payment Intent ID: {payment_intent['id']}")

    # Find order by payment intent ID
    orders = db.collection(Collections.ORDERS).where(
        'stripePaymentIntentId', '==', payment_intent['id']
    ).limit(1).get()

    if orders:
        order_ref = orders[0].reference
        order_data = orders[0].to_dict()
        order_id = order_ref.id

        print(f"  Found order: {order_id}")

        # Only update if not already paid
        if order_data.get('paymentStatus') != PaymentStatus.PAID:
            order_ref.update({
                "status": OrderStatus.CONFIRMED,
                "paymentStatus": PaymentStatus.PAID,
                "paidAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "amountReceived": payment_intent.get('amount_received', 0) / 100,
            })

            # Clear user's cart
            user_id = order_data.get('userId')
            if user_id:
                _clear_user_cart(user_id)

            # Send confirmation emails
            send_order_confirmation_emails(order_id, order_data)

            print(f"  ✅ Payment intent succeeded")
        else:
            print(f"  ℹ️ Order already marked as paid")

        return order_id
    else:
        print(f"  ⚠️ No order found for payment intent")
        return None


def process_payment_intent_failed(payment_intent: Dict) -> Optional[str]:
    """Process payment_intent.payment_failed event"""
    print("\n❌ Processing: payment_intent.payment_failed")

    orders = db.collection(Collections.ORDERS).where(
        'stripePaymentIntentId', '==', payment_intent['id']
    ).limit(1).get()

    if orders:
        order_ref = orders[0].reference
        order_data = orders[0].to_dict()
        order_id = order_ref.id
        last_error = payment_intent.get('last_payment_error', {})

        print(f"  Order: {order_id}")
        print(f"  Error: {last_error.get('message', 'Unknown error')}")

        order_ref.update({
            "status": OrderStatus.FAILED,
            "paymentStatus": PaymentStatus.PAYMENT_FAILED,
            "paymentError": last_error.get('message', 'Payment failed'),
            "paymentErrorCode": last_error.get('code'),
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        # Restore stock for failed payment
        _restore_stock_for_order(order_data)
        print(f"  ❌ Payment failed - stock restored")

        return order_id

    return None


def process_charge_refunded(charge: Dict) -> Optional[str]:
    """Process charge.refunded event"""
    print("\n💸 Processing: charge.refunded")

    payment_intent_id = charge.get('payment_intent')
    if not payment_intent_id:
        print("  ⚠️ No payment intent ID in charge")
        return None

    orders = db.collection(Collections.ORDERS).where(
        'stripePaymentIntentId', '==', payment_intent_id
    ).limit(1).get()

    if orders:
        order_ref = orders[0].reference
        order_id = order_ref.id

        print(f"  Order: {order_id}")
        print(f"  Refund Amount: ${charge.get('amount_refunded', 0) / 100}")

        # Check if fully or partially refunded
        is_fully_refunded = charge.get('refunded', False)

        order_ref.update({
            "status": OrderStatus.REFUNDED if is_fully_refunded else OrderStatus.PARTIALLY_REFUNDED,
            "paymentStatus": PaymentStatus.REFUNDED,
            "refundAmount": charge.get('amount_refunded', 0) / 100,
            "refundedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        print(f"  💸 {'Fully' if is_fully_refunded else 'Partially'} refunded")

        return order_id

    return None


def send_order_confirmation_emails(order_id: str, order_data: Dict) -> None:
    """Send confirmation emails to customer and sellers"""
    try:
        # Send customer confirmation
        customer_email = order_data.get('customerEmail')
        if customer_email:
            try:
                confirmation_html = get_order_confirmation_email(order_data)
                send_email(
                    to_email=customer_email,
                    subject=f"Order Confirmation #{order_id[:8]}",
                    html_content=confirmation_html
                )
                print(f"  ✅ Sent confirmation to customer: {customer_email}")
            except Exception as e:
                print(f"  ⚠️ Failed to send customer email: {str(e)}")
        
        # Send seller notification
        try:
            seller_html = get_seller_notification_email(order_data)
            send_email(
                to_email=SELLER_EMAIL,
                subject=f"🎉 New Order #{order_id[:8]}",
                html_content=seller_html
            )
            print(f"  ✅ Sent notification to seller: {SELLER_EMAIL}")
        except Exception as e:
            print(f"  ⚠️ Failed to send seller email: {str(e)}")
            
    except Exception as e:
        print(f"  ⚠️ Error sending emails: {str(e)}")


# ============================================================================
# FIRESTORE TRIGGERS - ORDER STATUS CHANGES
# ============================================================================

@firestore_fn.on_document_updated(document="orders/{orderId}")
def on_order_updated(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Trigger when order is updated - send notifications for status changes
    """
    try:
        order_id = event.params["orderId"]
        before_data = event.data.before.to_dict() if event.data.before else {}
        after_data = event.data.after.to_dict() if event.data.after else {}
        
        customer_email = after_data.get('customerEmail')
        
        # ====================================================================
        # SCENARIO 1: NEW ORDER CONFIRMED (Notify Sellers per Item)
        # ====================================================================
        old_status = before_data.get('status', 'pending')
        new_status = after_data.get('status', 'pending')
        
        if old_status != 'confirmed' and new_status == 'confirmed':
            print(f"📧 Order {order_id} confirmed - notifying sellers")
            
            # Group items by seller
            items_by_seller = {}
            for item in after_data.get('items', []):
                seller_id = item.get('sellerId')
                if seller_id:
                    if seller_id not in items_by_seller:
                        items_by_seller[seller_id] = []
                    items_by_seller[seller_id].append(item)
            
            # Notify each seller
            for seller_id, seller_items in items_by_seller.items():
                try:
                    # Get seller email from database
                    seller_doc = db.collection('sellers').document(seller_id).get()
                    if not seller_doc.exists:
                        print(f"⚠️ Seller {seller_id} not found")
                        continue
                    
                    seller_data = seller_doc.to_dict()
                    seller_email = seller_data.get('email')
                    
                    if not seller_email:
                        print(f"⚠️ No email for seller {seller_id}")
                        continue
                    
                    # Build items HTML for this seller
                    items_html = ""
                    for item in seller_items:
                        items_html += f"""
                        <tr>
                            <td style="padding: 10px; border-bottom: 1px solid #eee;">{item.get('name', 'Product')}</td>
                            <td style="text-align: center; padding: 10px; border-bottom: 1px solid #eee;">{item.get('quantity', 1)}</td>
                            <td style="text-align: right; padding: 10px; border-bottom: 1px solid #eee;">${(item.get('price', 0) * item.get('quantity', 1)):.2f}</td>
                        </tr>
                        """
                    
                    email_html = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                    </head>
                    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                        <div style="background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%); padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                            <h1 style="color: white; margin: 0;">📦 New Order!</h1>
                        </div>
                        <div style="padding: 20px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
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
            old_status = old_item.get('deliveryStatus', 'pending')
            new_status = new_item.get('deliveryStatus', 'pending')
            
            # Item Shipped
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
            
            # Item Delivered
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


# ============================================================================
# PRODUCT MANAGEMENT FUNCTIONS
# ============================================================================

@https_fn.on_call()
def delete_product(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Delete a product and clean up from all carts and favorites.
    Only the product owner or an admin can delete.
    """
    # Verify authentication
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in to delete products"
        )

    product_id = req.data.get("productId")
    if not product_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="productId is required"
        )

    user_id = req.auth.uid
    print(f"🗑️ Delete product request: {product_id} by user {user_id}")

    try:
        # Get product document
        product_ref = db.collection(Collections.PRODUCTS).document(product_id)
        product_doc = product_ref.get()

        if not product_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="Product not found"
            )

        product_data = product_doc.to_dict()
        seller_id = product_data.get('sellerId')

        # Check if user is admin
        user_ref = db.collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()
        user_data = user_doc.to_dict() if user_doc.exists else {}
        user_roles = user_data.get('roles', [])
        is_admin = UserRoles.ADMIN in user_roles

        # Verify ownership or admin status
        if seller_id != user_id and not is_admin:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="You don't have permission to delete this product"
            )

        print(f"  ✓ Authorization verified (admin={is_admin}, owner={seller_id == user_id})")

        # 1. Remove from all carts using collectionGroup query
        print(f"  🛒 Removing from carts...")
        cart_items = db.collection_group(Collections.CART).where('productId', '==', product_id).get()
        cart_count = 0
        for cart_item in cart_items:
            cart_item.reference.delete()
            cart_count += 1
        print(f"    ✓ Removed from {cart_count} carts")

        # 2. Remove from all favorites using collectionGroup query
        print(f"  ❤️ Removing from favorites...")
        fav_items = db.collection_group(Collections.FAVORITES).where('productId', '==', product_id).get()
        fav_count = 0
        for fav_item in fav_items:
            fav_item.reference.delete()
            fav_count += 1
        print(f"    ✓ Removed from {fav_count} favorites")

        # 3. Delete the product document
        print(f"  📦 Deleting product document...")
        product_ref.delete()
        print(f"  ✓ Product deleted successfully")

        return {
            "success": True,
            "message": "Product deleted successfully",
            "cleanedCarts": cart_count,
            "cleanedFavorites": fav_count,
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error deleting product: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to delete product: {str(e)}"
        )