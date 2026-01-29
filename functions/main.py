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

from firebase_functions import https_fn, options, firestore_fn, scheduler_fn
from firebase_admin import initialize_app, firestore, credentials, auth
import stripe
import json
import os
from typing import Any, Dict, Optional, List
from datetime import datetime, timedelta
import traceback
from mailjet_rest import Client
import re
from enum import Enum
import requests

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

class PayoutStatus:
    PENDING = 'pending'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    PARTIAL = 'partial'
    FAILED = 'failed'

class CaptureMethod:
    MANUAL = 'manual'
    AUTOMATIC = 'automatic'

class ShippingApprovalStatus:
    NOT_REQUIRED = 'not_required'
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'

# Platform configuration
PLATFORM_FEE_PERCENT = 0.025  # 2.5% platform fee
AUTO_CONFIRM_DAYS = 14  # Auto-confirm orders after 14 days
AUTHORIZATION_VALID_DAYS = 7  # Stripe authorization valid for 7 days
SHIPPING_APPROVAL_THRESHOLD = 0.20  # 20% - require buyer approval if actual shipping exceeds estimate by this much

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
    GEOAPIFY_API_KEY = os.environ.get("GEOAPIFY_API_KEY", "")
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    print("🧪 Running in EMULATOR mode")
else:
    from firebase_functions import params
    
    STRIPE_SECRET_KEY = params.SecretParam("STRIPE_SECRET_KEY").value
    STRIPE_WEBHOOK_SECRET = params.SecretParam("STRIPE_WEBHOOK_SECRET").value
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY").value
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY").value
    GEOAPIFY_API_KEY = params.SecretParam("GEOAPIFY_API_KEY").value
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
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.now().strftime('%B %d, %Y')}</p>
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
                <p style="margin: 5px 0;"><strong>Order Date:</strong> {datetime.now().strftime('%B %d, %Y at %I:%M %p UTC')}</p>
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
        "timestamp": datetime.now().isoformat()
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


# ============================================================================
# SHIPPING & TAX CALCULATION HELPER FUNCTIONS
# ============================================================================

def get_tax_rate(province: str) -> float:
    """Get tax rate for a Canadian province"""
    tax_rates = {
        'AB': 0.05,
        'BC': 0.12,
        'MB': 0.12,
        'NB': 0.15,
        'NL': 0.15,
        'NT': 0.05,
        'NS': 0.15,
        'NU': 0.05,
        'ON': 0.13,
        'PE': 0.15,
        'QC': 0.14975,
        'SK': 0.11,
        'YT': 0.05,
    }
    return tax_rates.get(province, 0.13)


def _are_adjacent_provinces(p1: str, p2: str) -> bool:
    """Check if two provinces are adjacent"""
    adjacency = {
        'BC': ['AB', 'YT', 'NT'],
        'AB': ['BC', 'SK', 'NT'],
        'SK': ['AB', 'MB', 'NT', 'NU'],
        'MB': ['SK', 'ON', 'NU'],
        'ON': ['MB', 'QC'],
        'QC': ['ON', 'NB', 'NL'],
        'NB': ['QC', 'NS', 'PE'],
        'NS': ['NB', 'PE'],
        'PE': ['NB', 'NS'],
        'NL': ['QC'],
        'YT': ['BC', 'NT'],
        'NT': ['BC', 'AB', 'SK', 'YT', 'NU'],
        'NU': ['SK', 'MB', 'NT'],
    }
    return p2 in adjacency.get(p1, [])


def _are_same_region(p1: str, p2: str) -> bool:
    """Check if two provinces are in the same region"""
    regions = {
        'West': ['BC', 'AB'],
        'Prairies': ['SK', 'MB'],
        'Central': ['ON', 'QC'],
        'Atlantic': ['NB', 'NS', 'PE', 'NL'],
        'North': ['YT', 'NT', 'NU'],
    }
    for region_provinces in regions.values():
        if p1 in region_provinces and p2 in region_provinces:
            return True
    return False


def _calculate_tiered_shipping(distance_km: float, item_count: int) -> float:
    """Calculate shipping cost based on distance and item count"""
    base_cost = 34.99  # Default high

    if distance_km <= 50:
        base_cost = 5.99
    elif distance_km <= 150:
        base_cost = 8.99
    elif distance_km <= 500:
        base_cost = 12.99
    elif distance_km <= 1000:
        base_cost = 16.99
    elif distance_km <= 2000:
        base_cost = 22.99
    elif distance_km <= 4000:
        base_cost = 28.99
    
    # Additional items cost
    additional_items_cost = (item_count - 1) * (base_cost * 0.2)
    
    # Cap additional cost at 50% of base
    capped_additional = min(additional_items_cost, base_cost * 0.5)
    
    return base_cost + capped_additional


def _calculate_fallback_shipping(item_count: int, seller_province: str, buyer_province: str) -> float:
    """Fallback shipping calculation using province matrix"""
    base_cost = 29.99  # Default Cross-country

    if seller_province == buyer_province:
        base_cost = 12.99
    elif _are_adjacent_provinces(seller_province, buyer_province):
        base_cost = 18.99
    elif _are_same_region(seller_province, buyer_province):
        base_cost = 24.99
    
    additional_cost = (item_count - 1) * (base_cost * 0.2)
    capped_additional = min(additional_cost, base_cost * 0.5)
    
    return base_cost + capped_additional


def calculate_shipping_cost(items: List[Dict], buyer_address: Dict) -> float:
    """
    Server-side shipping calculation.
    Fetches distances via Geoapify or falls back to province rules.
    """
    if not buyer_address or not buyer_address.get('latitude') or not buyer_address.get('longitude'):
        print("⚠️ Buyer address missing coordinates")
        return 0.0

    total_shipping = 0.0
    
    # Group items by seller
    items_by_seller = {}
    for item in items:
        seller_id = item.get('sellerId')
        if seller_id:
            if seller_id not in items_by_seller:
                items_by_seller[seller_id] = []
            items_by_seller[seller_id].append(item)
    
    for seller_id, seller_items in items_by_seller.items():
        # Get seller address from first item (enriched by main function)
        seller_address = seller_items[0].get('sellerAddress', {})
        
        seller_lat = seller_address.get('latitude')
        seller_lon = seller_address.get('longitude')
        seller_state = seller_address.get('state', 'ON')
        buyer_state = buyer_address.get('state', 'ON')
        
        item_count = sum(item.get('quantity', 1) for item in seller_items)
        
        if seller_lat and seller_lon and GEOAPIFY_API_KEY:
            try:
                # Call Geoapify Route Matrix
                url = f"https://api.geoapify.com/v1/routematrix?apiKey={GEOAPIFY_API_KEY}"
                payload = {
                    "mode": "drive",
                    "sources": [{"location": [seller_lon, seller_lat]}],
                    "targets": [{"location": [buyer_address['longitude'], buyer_address['latitude']]}]
                }
                
                response = requests.post(url, json=payload, timeout=5)
                
                if response.status_code == 200:
                    data = response.json()
                    distance_km = data['sources_to_targets'][0][0]['distance'] / 1000.0
                    cost = _calculate_tiered_shipping(distance_km, item_count)
                    total_shipping += cost
                    continue
            except Exception as e:
                print(f"⚠️ Geoapify error: {str(e)}")
        
        # Fallback
        cost = _calculate_fallback_shipping(item_count, seller_state, buyer_state)
        total_shipping += cost
        
    return total_shipping

# Stripe Tax Code Mapping
# Maps internal categoryId to Stripe Tax Codes (TXCD)
# https://stripe.com/docs/tax/tax-categories
CATEGORY_TAX_CODE_MAP = {
    14: "txcd_10000000", # Books
    17: "txcd_20030002", # Baby & Kids -> Mapping to Children's Clothing to handle rebates
    19: "txcd_30060005", # Groceries -> Basic Groceries (Zero-rated)
    21: "txcd_10000001", # Digital Products
    # Defaults to txcd_99999999 (General Merchandise) for others
}

# ... (Previous imports and setup)

@https_fn.on_call(cors=cors_config)
def create_checkout_session(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Create Stripe Checkout Session - Callable Function
    SECURE VERSION: Server-side validation + Stripe Tax
    """
    try:
        data = req.data
        
        if not data:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Request body is required"
            )
        
        # Validate order data structure (keys existence)
        is_valid, error_msg = validate_order_data(data)
        if not is_valid:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=error_msg
            )
        
        # Extract user ID from auth context
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated"
            )
        
        auth_user_id = req.auth.uid
        user_id = data.get('userId', auth_user_id)
        
        if user_id != auth_user_id:
            print(f"⚠️ User ID mismatch: claimed={user_id}, auth={auth_user_id}")
            user_id = auth_user_id

        customer_email = sanitize_email(data['customerEmail'])
        customer_id = data.get('customerId', '')
        currency = data.get('currency', 'cad').lower()
        delivery_info = data['deliveryInfo']
        requested_items = data['items']

        # ================================================================
        # CANADA-ONLY SHIPPING VALIDATION
        # ================================================================
        CANADIAN_PROVINCES = ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT']
        delivery_state = delivery_info.get('state', '').upper()
        delivery_country = delivery_info.get('country', 'Canada')

        if delivery_state not in CANADIAN_PROVINCES:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Shipping is only available within Canada. Invalid province: {delivery_state}"
            )

        if delivery_country.lower() not in ['canada', 'ca']:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Shipping is only available within Canada"
            )

        print(f"✓ Delivery address validated: {delivery_state}")

        # ================================================================
        # ATOMIC VALIDATION: STOCK & PRICE FETCHING
        # ================================================================
        print("🔒 Validating stock and fetching trusted prices...")

        @firestore.transactional
        def validate_reserve_and_fetch(transaction):
            """
            Atomically:
            1. Fetch product docs to get REAL prices and seller info
            2. Validate stock
            3. Decrement stock
            4. Return trusted item list
            """
            stock_updates = []
            trusted_items = []

            for req_item in requested_items:
                product_id = req_item.get('productId')
                quantity = req_item.get('quantity', 1)

                if not product_id:
                    raise ValueError(f"Missing productId in item")

                product_ref = db.collection(Collections.PRODUCTS).document(product_id)
                product_doc = product_ref.get(transaction=transaction)

                if not product_doc.exists:
                    raise ValueError(f"Product {product_id} not found")

                product_data = product_doc.to_dict()
                current_stock = product_data.get('stockQuantity', 0)
                product_name = product_data.get('name', 'Unknown')
                
                # TRUSTED DATA
                price = product_data.get('price', 0.0)
                seller_id = product_data.get('sellerId')
                seller_address = product_data.get('sellerAddress', {})
                image_urls = product_data.get('imageUrls', [])
                category_id = product_data.get('categoryId', 0)
                product_tax_code = product_data.get('taxCode') # Optional override
                
                # Check stock
                if current_stock < quantity:
                    raise ValueError(f"Insufficient stock for '{product_name}'. Available: {current_stock}, Requested: {quantity}")

                stock_updates.append((product_ref, current_stock - quantity))
                
                # Build trusted item
                trusted_items.append({
                    'productId': product_id,
                    'name': product_name,
                    'description': product_data.get('description', ''),
                    'price': float(price), # Server price
                    'quantity': int(quantity),
                    'imageUrls': image_urls,
                    'sellerId': seller_id,
                    'sellerAddress': seller_address,
                    'categoryId': category_id,
                    'taxCode': product_tax_code, # Explicit tax code from product
                    'deliveryStatus': DeliveryStatus.PENDING,
                    'trackingNumber': None,
                    'confirmedByBuyer': False
                })

            # Commit stock updates
            for product_ref, new_stock in stock_updates:
                transaction.update(product_ref, {'stockQuantity': new_stock})

            return trusted_items

        try:
            transaction = db.transaction()
            trusted_items = validate_reserve_and_fetch(transaction)
            print("✅ Stock reserved and prices fetched successfully")
        except ValueError as e:
            print(f"❌ Validation failed: {str(e)}")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message=str(e)
            )

        # ================================================================
        # SERVER-SIDE CALCULATIONS (SUBTOTAL & SHIPPING)
        # ================================================================
        
        # 1. Subtotal
        subtotal = sum(item['price'] * item['quantity'] for item in trusted_items)
        
        # 2. Shipping Cost
        shipping_cost = calculate_shipping_cost(trusted_items, delivery_info)
        
        # 3. Taxes - DELEGATED TO STRIPE
        # We no longer calculate taxes here. Stripe Tax handles it.
            
        # ================================================================
        # CREATE STRIPE SESSION WITH AUTOMATIC TAX
        # ================================================================
        
        # Create new order with auto-generated ID
        order_ref = db.collection(Collections.ORDERS).document()
        order_id = order_ref.id
        
        seller_ids = list(set([item.get('sellerId') for item in trusted_items if item.get('sellerId')]))
        
        # Build Stripe line items
        line_items = []
        for item in trusted_items:
            images = []
            if item.get('imageUrls') and len(item.get('imageUrls')) > 0:
                images = [item['imageUrls'][0]]
            
            # Determine Tax Code
            # 1. Product specific override
            # 2. Category mapping
            # 3. General merchandise fallback
            tax_code = item.get('taxCode')
            if not tax_code:
                cat_id = item.get('categoryId', 0)
                tax_code = CATEGORY_TAX_CODE_MAP.get(cat_id, "txcd_99999999")
            
            line_items.append({
                "price_data": {
                    "currency": currency,
                    "product_data": {
                        "name": item.get('name', 'Product'),
                        "images": images,
                        "tax_code": tax_code, # STRIPE TAX KEY
                    },
                    "unit_amount": int(item['price'] * 100),
                    "tax_behavior": "exclusive" # Price does not include tax
                },
                "quantity": item.get('quantity', 1)
            })
        
        # Add Shipping
        if shipping_cost > 0:
            line_items.append({
                "price_data": {
                    "currency": currency,
                    "product_data": {
                        "name": "Shipping",
                        "description": f"Delivery to {delivery_state}",
                        "tax_code": "txcd_92010001" # Shipping tax code
                    },
                    "unit_amount": int(shipping_cost * 100),
                    "tax_behavior": "exclusive"
                },
                "quantity": 1
            })

        # Base URL
        base_url = "https://orignagta.ca"
        if IS_EMULATOR:
            base_url = "http://localhost:5000"
            
        success_url = f"{base_url}/payment-success?session_id={{CHECKOUT_SESSION_ID}}&order_id={order_id}"
        cancel_url = f"{base_url}/payment-cancel"
        
        print(f"💳 Creating Stripe session for order {order_id} (Stripe Tax Enabled)")
        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            customer_email=customer_email,
            line_items=line_items,
            success_url=success_url,
            cancel_url=cancel_url,
            automatic_tax={"enabled": True}, # STRIPE TAX ENABLED
            payment_intent_data={
                "capture_method": "manual",
                "metadata": {
                    "orderId": order_id,
                    "userId": user_id,
                }
            },
            metadata={
                "userId": user_id,
                "orderId": order_id,
                "environment": "test" if IS_EMULATOR else "production"
            },
            client_reference_id=order_id,
            billing_address_collection="auto",
            shipping_address_collection={
                 "allowed_countries": ["CA"]
            },
            expires_at=int((datetime.now().timestamp() + 1800))
        )
        
        auth_expires_at = datetime.now() + timedelta(days=AUTHORIZATION_VALID_DAYS)
        
        # NOTE: We don't know the exact taxes yet. Stripe calculates them.
        # We will update the order with the FINAL tax amounts via Webhook (checkout.session.completed)
        # For now, we save "calculated" taxes as None or Estimate.
        # But to allow the frontend to proceed, we can just save 0/Empty and rely on the UI using the Stripe Hosted Page values?
        # OR: We store the subtotal/shipping and mark status PENDING.
        
        # Save order to Firestore
        order_data = {
            "orderId": order_id,
            "userId": user_id,
            "customerId": customer_id,
            "customerEmail": customer_email,
            "items": trusted_items,
            "sellerIds": seller_ids,
            "deliveryInfo": delivery_info,
            "subtotal": subtotal,
            "taxes": {}, # Will be populated by Webhook
            "shippingCost": shipping_cost,
            "total": None, # Will be populated by Webhook or Session result
            "currency": currency,
            "amount": None, # Will be populated by Webhook
            "status": OrderStatus.PENDING,
            "paymentStatus": PaymentStatus.AWAITING_PAYMENT,
            "stripeSessionId": session.id,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "captureMethod": CaptureMethod.MANUAL,
            "authorizedAmount": None,
            "capturedAmount": None,
            "capturedAt": None,
            "estimatedShipping": shipping_cost,
            "actualShipping": None,
            "shippingApprovalStatus": ShippingApprovalStatus.NOT_REQUIRED,
            "shippingApprovalRequired": False,
            "authorizationExpiresAt": auth_expires_at,
        }
        
        order_ref.set(order_data)
        print(f"✅ Order {order_id} created successfully. Taxes will be calculated by Stripe.")
        
        return {
            "url": session.url,
            "sessionId": session.id,
            "orderId": order_id
        }
        
    except https_fn.HttpsError:
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
        print(f"Timestamp: {datetime.now().isoformat()}")
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

            elif event_type == 'account.updated':
                process_account_updated(event_data)

            # Dispute events
            elif event_type == 'charge.dispute.created':
                order_id = process_dispute_created(event_data)

            elif event_type == 'charge.dispute.closed':
                order_id = process_dispute_closed(event_data)

            # Transfer events (for logging/monitoring)
            elif event_type == 'transfer.created':
                print(f"ℹ️ Transfer created: {event_data.get('id')}")
                processing_status = "logged"

            elif event_type == 'transfer.reversed':
                order_id = process_transfer_reversed(event_data)

            # Payout events (seller bank payouts)
            elif event_type == 'payout.paid':
                print(f"ℹ️ Payout completed: {event_data.get('id')}")
                processing_status = "logged"

            elif event_type == 'payout.failed':
                process_payout_failed(event_data)

            # Refund events
            elif event_type == 'refund.created':
                print(f"ℹ️ Refund created: {event_data.get('id')}")
                processing_status = "logged"

            elif event_type == 'refund.failed':
                process_refund_failed(event_data)

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
    capture_method = order_data.get('captureMethod', CaptureMethod.AUTOMATIC)

    update_data = {
        "stripePaymentIntentId": session.get('payment_intent'),
        "stripeCustomerId": session.get('customer'),
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "paymentMethod": session.get('payment_method_types', [])[0] if session.get('payment_method_types') else None,
        "amountTotal": session.get('amount_total', 0) / 100,
    }

    if payment_status == 'paid':
        # Check if this is manual capture or automatic
        if capture_method == CaptureMethod.MANUAL:
            # For manual capture, 'paid' means authorized (not captured yet)
            # The payment_intent has requires_capture status
            update_data.update({
                "status": OrderStatus.CONFIRMED,
                "paymentStatus": "authorized",  # Custom status for manual capture
                "authorizedAt": firestore.SERVER_TIMESTAMP,
            })
            print(f"  ✅ Payment AUTHORIZED (manual capture - awaiting seller shipping confirmation)")
        else:
            # Automatic capture - immediate payment success
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
    """Process charge.refunded event - restore stock on full refunds"""
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
        order_data = orders[0].to_dict()

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

        # Restore stock on full refunds
        if is_fully_refunded:
            _restore_stock_for_order(order_data)
            print(f"  📦 Stock restored for fully refunded order")

        print(f"  💸 {'Fully' if is_fully_refunded else 'Partially'} refunded")

        return order_id

    return None


def process_dispute_created(dispute: Dict) -> Optional[str]:
    """Process charge.dispute.created - freeze payouts for disputed orders"""
    print("\n⚠️ Processing: charge.dispute.created")

    charge_id = dispute.get('charge')
    if not charge_id:
        print("  ⚠️ No charge ID in dispute")
        return None

    # Get the charge to find the payment intent
    try:
        charge = stripe.Charge.retrieve(charge_id)
        payment_intent_id = charge.payment_intent
    except Exception as e:
        print(f"  ❌ Failed to retrieve charge: {e}")
        return None

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
        print(f"  Dispute ID: {dispute.get('id')}")
        print(f"  Reason: {dispute.get('reason')}")
        print(f"  Amount: ${dispute.get('amount', 0) / 100}")

        # Update order with dispute info - freeze payouts
        order_ref.update({
            "hasDispute": True,
            "disputeId": dispute.get('id'),
            "disputeReason": dispute.get('reason'),
            "disputeStatus": dispute.get('status'),
            "disputeAmount": dispute.get('amount', 0) / 100,
            "disputeCreatedAt": firestore.SERVER_TIMESTAMP,
            "payoutStatus": PayoutStatus.PENDING,  # Freeze payouts
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        print(f"  ⚠️ Dispute created - payouts frozen")
        return order_id

    return None


def process_dispute_closed(dispute: Dict) -> Optional[str]:
    """Process charge.dispute.closed - handle dispute resolution"""
    print("\n⚖️ Processing: charge.dispute.closed")

    charge_id = dispute.get('charge')
    if not charge_id:
        return None

    try:
        charge = stripe.Charge.retrieve(charge_id)
        payment_intent_id = charge.payment_intent
    except Exception:
        return None

    if not payment_intent_id:
        return None

    orders = db.collection(Collections.ORDERS).where(
        'stripePaymentIntentId', '==', payment_intent_id
    ).limit(1).get()

    if orders:
        order_ref = orders[0].reference
        order_id = order_ref.id
        dispute_status = dispute.get('status')

        print(f"  Order: {order_id}")
        print(f"  Dispute Status: {dispute_status}")

        update_data = {
            "disputeStatus": dispute_status,
            "disputeClosedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }

        # If dispute won (in seller's favor), unfreeze payouts
        if dispute_status == 'won':
            update_data["hasDispute"] = False
            print(f"  ✅ Dispute won - payouts unfrozen")
        else:
            # Dispute lost - mark order appropriately
            update_data["status"] = OrderStatus.REFUNDED
            print(f"  ❌ Dispute lost - order refunded")

        order_ref.update(update_data)
        return order_id

    return None


def process_transfer_reversed(transfer: Dict) -> Optional[str]:
    """Process transfer.reversed - update payout records"""
    print("\n🔄 Processing: transfer.reversed")

    order_id = transfer.get('metadata', {}).get('orderId')
    seller_id = transfer.get('metadata', {}).get('sellerId')

    if not order_id:
        print("  ⚠️ No order ID in transfer metadata")
        return None

    print(f"  Order: {order_id}")
    print(f"  Seller: {seller_id}")
    print(f"  Reversed Amount: ${transfer.get('amount_reversed', 0) / 100}")

    order_ref = db.collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if order_doc.exists:
        order_data = order_doc.to_dict()
        seller_payouts = order_data.get('sellerPayouts', [])

        # Update the specific seller's payout record
        for payout in seller_payouts:
            if payout.get('sellerId') == seller_id:
                payout['reversed'] = True
                payout['reversedAt'] = firestore.SERVER_TIMESTAMP
                break

        order_ref.update({
            'sellerPayouts': seller_payouts,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })

        print(f"  🔄 Transfer reversed for seller {seller_id}")
        return order_id

    return None


def process_payout_failed(payout: Dict) -> None:
    """Process payout.failed - log failed bank payouts"""
    print("\n❌ Processing: payout.failed")
    print(f"  Payout ID: {payout.get('id')}")
    print(f"  Amount: ${payout.get('amount', 0) / 100}")
    print(f"  Failure Code: {payout.get('failure_code')}")
    print(f"  Failure Message: {payout.get('failure_message')}")

    # Log to webhook_logs for monitoring
    db.collection('webhook_logs').add({
        'eventType': 'payout.failed',
        'payoutId': payout.get('id'),
        'amount': payout.get('amount', 0) / 100,
        'failureCode': payout.get('failure_code'),
        'failureMessage': payout.get('failure_message'),
        'destination': payout.get('destination'),
        'createdAt': firestore.SERVER_TIMESTAMP,
    })


def process_refund_failed(refund: Dict) -> None:
    """Process refund.failed - log failed refunds for manual review"""
    print("\n❌ Processing: refund.failed")
    print(f"  Refund ID: {refund.get('id')}")
    print(f"  Amount: ${refund.get('amount', 0) / 100}")
    print(f"  Failure Reason: {refund.get('failure_reason')}")

    # Log for manual review
    db.collection('webhook_logs').add({
        'eventType': 'refund.failed',
        'refundId': refund.get('id'),
        'amount': refund.get('amount', 0) / 100,
        'failureReason': refund.get('failure_reason'),
        'chargeId': refund.get('charge'),
        'createdAt': firestore.SERVER_TIMESTAMP,
        'requiresManualReview': True,
    })


def process_account_updated(account: Dict) -> None:
    """
    Process account.updated event from Stripe Connect.
    Updates the user's Firestore document when their Stripe account status changes.
    """
    print("\n🏪 Processing: account.updated")

    account_id = account.get('id')
    if not account_id:
        print("  ⚠️ No account ID in event")
        return

    print(f"  Account ID: {account_id}")
    print(f"  Charges Enabled: {account.get('charges_enabled')}")
    print(f"  Payouts Enabled: {account.get('payouts_enabled')}")
    print(f"  Details Submitted: {account.get('details_submitted')}")

    # Find user with this Stripe account
    users = db.collection(Collections.USERS).where(
        'stripeAccountId', '==', account_id
    ).limit(1).get()

    if not users:
        print(f"  ⚠️ No user found with Stripe account {account_id}")
        return

    user_ref = users[0].reference
    user_id = user_ref.id

    print(f"  User ID: {user_id}")

    # Update user document with current account status
    user_ref.update({
        'chargesEnabled': account.get('charges_enabled', False),
        'payoutsEnabled': account.get('payouts_enabled', False),
        'onboardingCompleted': account.get('details_submitted', False),
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })

    print(f"  ✅ Updated user {user_id} Stripe account status")

    # If onboarding is completed, ensure seller role is set
    if account.get('details_submitted', False):
        user_data = users[0].to_dict()
        current_roles = user_data.get('roles', [])
        if UserRoles.SELLER not in current_roles:
            user_ref.update({
                'roles': current_roles + [UserRoles.SELLER],
            })
            print(f"  ✅ Added seller role to user {user_id}")


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


# ============================================================================
# ACCOUNT MANAGEMENT - DELETE ACCOUNT (GDPR/PIPEDA COMPLIANCE)
# ============================================================================

@https_fn.on_call()
def delete_account(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Delete a user account and all associated data for GDPR/PIPEDA compliance.
    This function:
    1. Deletes user's cart items
    2. Deletes user's favorites
    3. Deletes or anonymizes user's products (if seller)
    4. Anonymizes user data in orders
    5. Deletes Stripe Connect account (if seller)
    6. Deletes Firestore user document
    7. Deletes Firebase Auth account
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in to delete account"
        )

    user_id = req.auth.uid
    confirmation = req.data.get("confirmation")

    # Require explicit confirmation
    if confirmation != "DELETE_MY_ACCOUNT":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Must provide confirmation string 'DELETE_MY_ACCOUNT'"
        )

    print(f"🗑️ Account deletion requested for user: {user_id}")

    try:
        user_ref = db.collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="User not found"
            )

        user_data = user_doc.to_dict()
        user_email = user_data.get('email', 'deleted')
        stripe_account_id = user_data.get('stripeAccountId')

        # 1. Delete cart subcollection
        print("  🛒 Deleting cart items...")
        cart_ref = user_ref.collection(Collections.CART)
        cart_docs = cart_ref.get()
        cart_count = 0
        for doc in cart_docs:
            doc.reference.delete()
            cart_count += 1
        print(f"    ✓ Deleted {cart_count} cart items")

        # 2. Delete favorites subcollection
        print("  ❤️ Deleting favorites...")
        fav_ref = user_ref.collection(Collections.FAVORITES)
        fav_docs = fav_ref.get()
        fav_count = 0
        for doc in fav_docs:
            doc.reference.delete()
            fav_count += 1
        print(f"    ✓ Deleted {fav_count} favorites")

        # 3. Handle seller's products - anonymize instead of delete (for order history)
        print("  📦 Anonymizing seller products...")
        products = db.collection(Collections.PRODUCTS).where('sellerId', '==', user_id).get()
        product_count = 0
        for product_doc in products:
            # Mark as deleted and remove from search, but keep for order references
            product_doc.reference.update({
                'sellerId': 'deleted_user',
                'sellerAddress': {
                    'street': 'Deleted',
                    'city': 'Deleted',
                    'state': 'ON',
                    'postalCode': 'A0A 0A0',
                    'country': 'Canada',
                },
                'stockQuantity': 0,  # Mark as sold out
                'searchKeywords': [],  # Remove from search
            })
            product_count += 1
        print(f"    ✓ Anonymized {product_count} products")

        # 4. Anonymize user data in orders (keep order for records)
        print("  📋 Anonymizing order data...")
        orders = db.collection(Collections.ORDERS).where('userId', '==', user_id).get()
        order_count = 0
        for order_doc in orders:
            order_doc.reference.update({
                'customerEmail': 'deleted@account.com',
                'deliveryInfo': {
                    'street': 'Deleted',
                    'city': 'Deleted',
                    'state': 'ON',
                    'postalCode': 'A0A 0A0',
                    'country': 'Canada',
                    'formattedAddress': 'Account Deleted',
                },
            })
            order_count += 1
        print(f"    ✓ Anonymized {order_count} orders")

        # 5. Delete Stripe Connect account if exists
        if stripe_account_id:
            print(f"  💳 Deleting Stripe Connect account: {stripe_account_id}")
            try:
                stripe.Account.delete(stripe_account_id)
                print("    ✓ Stripe account deleted")
            except stripe.error.StripeError as e:
                print(f"    ⚠️ Failed to delete Stripe account: {str(e)}")
                # Continue with deletion even if Stripe fails

        # 6. Delete Firestore user document
        print("  👤 Deleting Firestore user document...")
        user_ref.delete()
        print("    ✓ User document deleted")

        # 7. Delete Firebase Auth account
        print("  🔐 Deleting Firebase Auth account...")
        try:
            auth.delete_user(user_id)
            print("    ✓ Auth account deleted")
        except auth.UserNotFoundError:
            print("    ⚠️ Auth user not found (may have been deleted already)")

        print(f"✅ Account deletion complete for user: {user_id}")

        return {
            "success": True,
            "message": "Account deleted successfully",
            "deletedItems": {
                "cartItems": cart_count,
                "favorites": fav_count,
                "productsAnonymized": product_count,
                "ordersAnonymized": order_count,
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error deleting account: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to delete account: {str(e)}"
        )


# ============================================================================
# STRIPE CONNECT - SELLER ONBOARDING & PAYOUTS
# ============================================================================

@https_fn.on_call()
def create_connect_account(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Create a Stripe Connect Express account for a seller.
    Called when a user wants to become a seller.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    user_id = req.auth.uid
    print(f"🏪 Creating Stripe Connect account for user: {user_id}")

    try:
        # Get user data
        user_ref = db.collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="User not found"
            )

        user_data = user_doc.to_dict()

        # Check if user already has a Stripe account
        existing_account_id = user_data.get('stripeAccountId')
        if existing_account_id:
            print(f"  User already has Stripe account: {existing_account_id}")
            # Return existing account info
            account = stripe.Account.retrieve(existing_account_id)
            return {
                "accountId": existing_account_id,
                "chargesEnabled": account.charges_enabled,
                "payoutsEnabled": account.payouts_enabled,
                "onboardingCompleted": account.details_submitted,
                "alreadyExists": True,
            }

        # Create new Stripe Connect Express account
        account = stripe.Account.create(
            type="express",
            country="CA",
            email=user_data.get('email'),
            capabilities={
                "card_payments": {"requested": True},
                "transfers": {"requested": True},
            },
            business_type="individual",
            metadata={
                "userId": user_id,
                "platform": "orignagta",
            },
        )

        print(f"  ✅ Created Stripe account: {account.id}")

        # Update user document with Stripe account ID
        user_ref.update({
            "stripeAccountId": account.id,
            "payoutsEnabled": False,
            "chargesEnabled": False,
            "onboardingCompleted": False,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        # Add seller role if not already present
        current_roles = user_data.get('roles', [])
        if UserRoles.SELLER not in current_roles:
            user_ref.update({
                "roles": current_roles + [UserRoles.SELLER],
            })

        return {
            "accountId": account.id,
            "chargesEnabled": False,
            "payoutsEnabled": False,
            "onboardingCompleted": False,
            "alreadyExists": False,
        }

    except stripe.error.StripeError as e:
        print(f"❌ Stripe error: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Stripe error: {str(e)}"
        )
    except Exception as e:
        print(f"❌ Error creating Connect account: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to create seller account: {str(e)}"
        )


@https_fn.on_call()
def create_account_link(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Generate Stripe onboarding link for a seller.
    Called to start or resume the onboarding process.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    user_id = req.auth.uid
    refresh_url = req.data.get('refreshUrl', 'https://orignagta.ca/seller/onboarding/refresh')
    return_url = req.data.get('returnUrl', 'https://orignagta.ca/seller/onboarding/complete')

    print(f"🔗 Creating account link for user: {user_id}")

    try:
        # Get user's Stripe account ID
        user_ref = db.collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="User not found"
            )

        user_data = user_doc.to_dict()
        account_id = user_data.get('stripeAccountId')

        if not account_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="No Stripe account found. Create one first."
            )

        # Create account link
        account_link = stripe.AccountLink.create(
            account=account_id,
            refresh_url=refresh_url,
            return_url=return_url,
            type="account_onboarding",
        )

        print(f"  ✅ Created account link: {account_link.url[:50]}...")

        return {
            "url": account_link.url,
            "expiresAt": account_link.expires_at,
        }

    except stripe.error.StripeError as e:
        print(f"❌ Stripe error: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Stripe error: {str(e)}"
        )
    except Exception as e:
        print(f"❌ Error creating account link: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to create onboarding link: {str(e)}"
        )


@https_fn.on_call()
def get_connect_account_status(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Get the current status of a seller's Stripe Connect account.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    user_id = req.auth.uid
    print(f"📊 Getting Connect account status for: {user_id}")

    try:
        user_ref = db.collection(Collections.USERS).document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="User not found"
            )

        user_data = user_doc.to_dict()
        account_id = user_data.get('stripeAccountId')

        if not account_id:
            return {
                "hasAccount": False,
                "chargesEnabled": False,
                "payoutsEnabled": False,
                "onboardingCompleted": False,
            }

        # Get account status from Stripe
        account = stripe.Account.retrieve(account_id)

        # Update user document if status changed
        if (account.charges_enabled != user_data.get('chargesEnabled') or
            account.payouts_enabled != user_data.get('payoutsEnabled') or
            account.details_submitted != user_data.get('onboardingCompleted')):

            user_ref.update({
                "chargesEnabled": account.charges_enabled,
                "payoutsEnabled": account.payouts_enabled,
                "onboardingCompleted": account.details_submitted,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            print(f"  ✅ Updated user account status")

        return {
            "hasAccount": True,
            "accountId": account_id,
            "chargesEnabled": account.charges_enabled,
            "payoutsEnabled": account.payouts_enabled,
            "onboardingCompleted": account.details_submitted,
            "requiresAction": not account.details_submitted,
        }

    except stripe.error.StripeError as e:
        print(f"❌ Stripe error: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Stripe error: {str(e)}"
        )
    except Exception as e:
        print(f"❌ Error getting account status: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=str(e)
        )


@https_fn.on_call()
def confirm_order_receipt(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Called when buyer confirms receipt of delivered items.
    Triggers seller payouts.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    user_id = req.auth.uid
    order_id = req.data.get('orderId')
    item_ids = req.data.get('itemIds', [])  # Optional: specific items to confirm

    if not order_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="orderId is required"
        )

    print(f"✅ Confirming order receipt: {order_id} by user: {user_id}")

    try:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()

        if not order_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="Order not found"
            )

        order_data = order_doc.to_dict()

        # Verify user owns this order
        if order_data.get('userId') != user_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="Not authorized to confirm this order"
            )

        # Verify order is paid
        if order_data.get('paymentStatus') != PaymentStatus.PAID:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="Order is not paid"
            )

        # Update items as confirmed by buyer
        items = order_data.get('items', [])
        confirmed_count = 0

        for i, item in enumerate(items):
            # Only confirm delivered items
            if item.get('deliveryStatus') == DeliveryStatus.DELIVERED:
                # If specific items provided, only confirm those
                if not item_ids or item.get('productId') in item_ids:
                    if not item.get('confirmedByBuyer', False):
                        items[i]['confirmedByBuyer'] = True
                        confirmed_count += 1

        # Check if all delivered items are now confirmed
        delivered_items = [i for i in items if i.get('deliveryStatus') == DeliveryStatus.DELIVERED]
        all_confirmed = all(i.get('confirmedByBuyer', False) for i in delivered_items)

        # Update order
        update_data = {
            'items': items,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        if all_confirmed and delivered_items:
            update_data['confirmedByClient'] = True
            update_data['confirmedAt'] = firestore.SERVER_TIMESTAMP

        order_ref.update(update_data)

        print(f"  ✅ Confirmed {confirmed_count} items")

        # If all confirmed, trigger seller payouts
        if all_confirmed and delivered_items:
            print(f"  💰 All items confirmed, triggering payouts...")
            _process_seller_payouts(order_id, order_data)

        return {
            "success": True,
            "confirmedItems": confirmed_count,
            "allConfirmed": all_confirmed,
            "payoutsTriggered": all_confirmed and len(delivered_items) > 0,
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error confirming order: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to confirm order: {str(e)}"
        )


def _process_seller_payouts(order_id: str, order_data: Dict) -> None:
    """
    Process payouts to all sellers in an order.
    Called when buyer confirms receipt or auto-release triggers.
    """
    print(f"💰 Processing seller payouts for order: {order_id}")

    try:
        payment_intent_id = order_data.get('stripePaymentIntentId')
        if not payment_intent_id:
            print(f"  ⚠️ No payment intent ID found")
            return

        # Group items by seller and calculate amounts
        seller_totals = {}
        items = order_data.get('items', [])

        for item in items:
            seller_id = item.get('sellerId')
            if not seller_id:
                continue

            item_total = item.get('price', 0) * item.get('quantity', 1)

            if seller_id not in seller_totals:
                seller_totals[seller_id] = 0.0
            seller_totals[seller_id] += item_total

        print(f"  📊 Seller breakdown: {seller_totals}")

        # Process transfers for each seller
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        seller_payouts = []
        total_platform_fee = 0.0

        for seller_id, gross_amount in seller_totals.items():
            try:
                # Get seller's Stripe account
                seller_ref = db.collection(Collections.USERS).document(seller_id)
                seller_doc = seller_ref.get()

                if not seller_doc.exists:
                    print(f"  ⚠️ Seller {seller_id} not found")
                    seller_payouts.append({
                        'sellerId': seller_id,
                        'gross': gross_amount,
                        'platformFee': 0,
                        'net': 0,
                        'paid': False,
                        'error': 'Seller not found',
                    })
                    continue

                seller_data = seller_doc.to_dict()
                stripe_account_id = seller_data.get('stripeAccountId')

                if not stripe_account_id:
                    print(f"  ⚠️ Seller {seller_id} has no Stripe account")
                    seller_payouts.append({
                        'sellerId': seller_id,
                        'stripeAccountId': None,
                        'gross': gross_amount,
                        'platformFee': 0,
                        'net': 0,
                        'paid': False,
                        'error': 'No Stripe account',
                    })
                    continue

                if not seller_data.get('payoutsEnabled', False):
                    print(f"  ⚠️ Seller {seller_id} payouts not enabled")
                    seller_payouts.append({
                        'sellerId': seller_id,
                        'stripeAccountId': stripe_account_id,
                        'gross': gross_amount,
                        'platformFee': 0,
                        'net': 0,
                        'paid': False,
                        'error': 'Payouts not enabled',
                    })
                    continue

                # Calculate platform fee and net amount
                platform_fee = round(gross_amount * PLATFORM_FEE_PERCENT, 2)
                net_amount = gross_amount - platform_fee
                total_platform_fee += platform_fee

                # Create transfer to seller with idempotency key to prevent duplicates
                idempotency_key = f"transfer_{order_id}_{seller_id}"
                transfer = stripe.Transfer.create(
                    amount=int(net_amount * 100),  # Convert to cents
                    currency='cad',
                    destination=stripe_account_id,
                    source_transaction=payment_intent_id,
                    metadata={
                        'orderId': order_id,
                        'sellerId': seller_id,
                        'platformFee': str(platform_fee),
                    },
                    idempotency_key=idempotency_key,
                )

                print(f"  ✅ Transferred ${net_amount:.2f} to seller {seller_id} (transfer: {transfer.id})")

                seller_payouts.append({
                    'sellerId': seller_id,
                    'stripeAccountId': stripe_account_id,
                    'gross': gross_amount,
                    'platformFee': platform_fee,
                    'net': net_amount,
                    'paid': True,
                    'transferId': transfer.id,
                    'paidAt': firestore.SERVER_TIMESTAMP,
                })

            except stripe.error.StripeError as e:
                print(f"  ❌ Transfer failed for seller {seller_id}: {str(e)}")
                seller_payouts.append({
                    'sellerId': seller_id,
                    'stripeAccountId': stripe_account_id if 'stripe_account_id' in dir() else None,
                    'gross': gross_amount,
                    'platformFee': 0,
                    'net': 0,
                    'paid': False,
                    'error': str(e),
                })

        # Determine overall payout status
        all_paid = all(p.get('paid', False) for p in seller_payouts)
        any_paid = any(p.get('paid', False) for p in seller_payouts)

        if all_paid:
            payout_status = PayoutStatus.COMPLETED
        elif any_paid:
            payout_status = PayoutStatus.PARTIAL
        else:
            payout_status = PayoutStatus.FAILED

        # Update order with payout info
        order_ref.update({
            'sellerPayouts': seller_payouts,
            'platformFeeTotal': total_platform_fee,
            'payoutStatus': payout_status,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })

        print(f"  ✅ Payout status: {payout_status}, Platform fee: ${total_platform_fee:.2f}")

    except Exception as e:
        print(f"❌ Error processing payouts: {str(e)}")
        print(traceback.format_exc())


# ============================================================================
# SCHEDULED FUNCTION - AUTO-RELEASE PAYOUTS
# ============================================================================

@scheduler_fn.on_schedule(schedule="every 24 hours")
def auto_release_payouts(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to auto-release payouts for orders where:
    - All items are delivered
    - Buyer hasn't confirmed receipt
    - More than AUTO_CONFIRM_DAYS have passed since the last item was delivered

    This protects sellers by ensuring they get paid even if buyers don't confirm.
    """
    print("=" * 80)
    print("🕐 AUTO-RELEASE PAYOUTS - Scheduled Job Started")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Auto-confirm threshold: {AUTO_CONFIRM_DAYS} days")
    print("=" * 80)

    try:
        # Calculate the cutoff date
        cutoff_date = datetime.now() - timedelta(days=AUTO_CONFIRM_DAYS)
        print(f"📅 Looking for orders delivered before: {cutoff_date.isoformat()}")

        # Query for paid orders that haven't been confirmed yet
        orders_query = db.collection(Collections.ORDERS).where(
            'paymentStatus', '==', PaymentStatus.PAID
        ).where(
            'confirmedByClient', '==', False
        ).where(
            'payoutStatus', 'in', [PayoutStatus.PENDING, None]
        ).stream()

        processed_count = 0
        payout_count = 0

        for order_doc in orders_query:
            order_id = order_doc.id
            order_data = order_doc.to_dict()

            try:
                print(f"\n📦 Checking order: {order_id}")

                items = order_data.get('items', [])
                if not items:
                    print(f"  ⚠️ No items in order")
                    continue

                # Check if all items are delivered
                all_delivered = all(
                    item.get('deliveryStatus') == DeliveryStatus.DELIVERED
                    for item in items
                )

                if not all_delivered:
                    print(f"  ⏳ Not all items delivered yet")
                    continue

                # Find the last delivery date (we'll use updatedAt as proxy)
                order_updated_at = order_data.get('updatedAt')
                if order_updated_at:
                    # Convert Firestore Timestamp to datetime
                    if hasattr(order_updated_at, 'timestamp'):
                        order_datetime = datetime.fromtimestamp(order_updated_at.timestamp())
                    else:
                        order_datetime = order_updated_at

                    if order_datetime > cutoff_date:
                        days_remaining = (order_datetime - cutoff_date).days + AUTO_CONFIRM_DAYS
                        print(f"  ⏳ Order still within grace period ({days_remaining} days remaining)")
                        continue

                # Check if order was created before cutoff (fallback check)
                created_at = order_data.get('createdAt')
                if created_at:
                    if hasattr(created_at, 'timestamp'):
                        created_datetime = datetime.fromtimestamp(created_at.timestamp())
                    else:
                        created_datetime = created_at

                    # Give at least AUTO_CONFIRM_DAYS from creation
                    if created_datetime > cutoff_date:
                        print(f"  ⏳ Order too recent (created: {created_datetime.isoformat()})")
                        continue

                print(f"  ✅ Order qualifies for auto-release")

                # Auto-confirm the order
                order_ref = db.collection(Collections.ORDERS).document(order_id)

                # Mark all delivered items as confirmed
                updated_items = []
                for item in items:
                    if item.get('deliveryStatus') == DeliveryStatus.DELIVERED:
                        item['confirmedByBuyer'] = True
                    updated_items.append(item)

                order_ref.update({
                    'items': updated_items,
                    'confirmedByClient': True,
                    'confirmedAt': firestore.SERVER_TIMESTAMP,
                    'autoConfirmed': True,  # Flag to indicate auto-confirmation
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })

                print(f"  ✅ Order auto-confirmed")

                # Process payouts
                _process_seller_payouts(order_id, order_data)
                payout_count += 1

                processed_count += 1

            except Exception as order_error:
                print(f"  ❌ Error processing order {order_id}: {str(order_error)}")
                print(traceback.format_exc())
                continue

        print("\n" + "=" * 80)
        print(f"✅ AUTO-RELEASE PAYOUTS - Job Complete")
        print(f"  Orders processed: {processed_count}")
        print(f"  Payouts triggered: {payout_count}")
        print("=" * 80)

    except Exception as e:
        print(f"❌ Error in auto-release job: {str(e)}")
        print(traceback.format_exc())


@scheduler_fn.on_schedule(schedule="every 24 hours")
def check_expired_authorizations(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to check for expired Stripe authorizations.
    Authorizations typically expire after 7 days.
    If expired:
    1. Mark order as cancelled
    2. Restore stock
    3. Log the expiry
    """
    print("=" * 80)
    print("⏰ CHECK EXPIRED AUTHORIZATIONS - Scheduled Job Started")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print("=" * 80)

    try:
        # Query for authorized orders where expiration date < now
        now = datetime.now()
        
        # Note: In a real production app with many orders, you might need pagination
        # or a composite index on [paymentStatus, authorizationExpiresAt]
        orders_query = db.collection(Collections.ORDERS).where(
            'paymentStatus', '==', 'authorized'
        ).where(
            'authorizationExpiresAt', '<', now
        ).stream()

        expired_count = 0

        for order_doc in orders_query:
            order_id = order_doc.id
            order_data = order_doc.to_dict()

            print(f"\n⚠️ Found expired authorization: {order_id}")
            print(f"  Expires At: {order_data.get('authorizationExpiresAt')}")

            try:
                # 1. Update order status
                db.collection(Collections.ORDERS).document(order_id).update({
                    "status": OrderStatus.CANCELLED,
                    "paymentStatus": PaymentStatus.SESSION_EXPIRED,
                    "cancellationReason": "Payment authorization expired (auto-cancelled)",
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })

                # 2. Restore stock
                _restore_stock_for_order(order_data)
                
                # 3. Cancel Stripe PaymentIntent if possible (best effort)
                payment_intent_id = order_data.get('stripePaymentIntentId')
                if payment_intent_id:
                   try:
                       stripe.PaymentIntent.cancel(payment_intent_id)
                       print(f"  ✓ Stripe PaymentIntent cancelled")
                   except Exception as stripe_error:
                       print(f"  ⚠️ Could not cancel Stripe intent (likely already expired): {stripe_error}")

                expired_count += 1
                print(f"  ✅ Order {order_id} cancelled and stock restored")

            except Exception as e:
                print(f"  ❌ Failed to process expired order {order_id}: {str(e)}")
        
        print("\n" + "=" * 80)
        print(f"✅ EXPIRED CHECK COMPLETE")
        print(f"  Orders cancelled: {expired_count}")
        print("=" * 80)

    except Exception as e:
        print(f"❌ Error in expired authorizations job: {str(e)}")
        print(traceback.format_exc())


# ============================================================================
# MANUAL CAPTURE PAYMENT FUNCTIONS
# ============================================================================

@https_fn.on_call()
def update_shipping_cost(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Called by seller to update the actual shipping cost.
    If the actual cost exceeds the estimate by more than SHIPPING_APPROVAL_THRESHOLD,
    buyer approval is required before capture.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    seller_id = req.auth.uid
    order_id = req.data.get('orderId')
    actual_shipping = req.data.get('actualShipping')

    if not order_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="orderId is required"
        )

    if actual_shipping is None or actual_shipping < 0:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="actualShipping must be a non-negative number"
        )

    print(f"📦 Updating shipping cost for order {order_id} by seller {seller_id}")

    try:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()

        if not order_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="Order not found"
            )

        order_data = order_doc.to_dict()

        # Verify seller has items in this order
        seller_items = [i for i in order_data.get('items', []) if i.get('sellerId') == seller_id]
        if not seller_items:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="You don't have items in this order"
            )

        # Verify order is in authorized state
        if order_data.get('paymentStatus') != 'authorized':
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message=f"Order payment is not in authorized state (current: {order_data.get('paymentStatus')})"
            )

        estimated_shipping = order_data.get('estimatedShipping', 0)

        # Calculate if approval is required
        approval_required = False
        if estimated_shipping > 0:
            shipping_increase = (actual_shipping - estimated_shipping) / estimated_shipping
            if shipping_increase > SHIPPING_APPROVAL_THRESHOLD:
                approval_required = True
                print(f"  ⚠️ Shipping increase {shipping_increase:.1%} exceeds threshold, buyer approval required")

        # Calculate new total
        subtotal = order_data.get('subtotal', 0)
        taxes = sum(order_data.get('taxes', {}).values())
        new_total = subtotal + taxes + actual_shipping
        new_amount_cents = int(new_total * 100)

        update_data = {
            'actualShipping': actual_shipping,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        if approval_required:
            update_data['shippingApprovalRequired'] = True
            update_data['shippingApprovalStatus'] = ShippingApprovalStatus.PENDING
            update_data['pendingTotal'] = new_total
            update_data['pendingAmount'] = new_amount_cents
            print(f"  📧 Buyer approval required for new shipping cost")
        else:
            # No approval needed, can proceed to capture
            update_data['shippingApprovalStatus'] = ShippingApprovalStatus.NOT_REQUIRED
            update_data['total'] = new_total
            update_data['amount'] = new_amount_cents

        order_ref.update(update_data)

        return {
            "success": True,
            "approvalRequired": approval_required,
            "estimatedShipping": estimated_shipping,
            "actualShipping": actual_shipping,
            "newTotal": new_total,
            "message": "Shipping cost updated. Buyer approval required." if approval_required else "Shipping cost updated. Ready to capture."
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error updating shipping cost: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to update shipping cost: {str(e)}"
        )


@https_fn.on_call()
def approve_shipping_cost(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Called by buyer to approve or reject the updated shipping cost.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    user_id = req.auth.uid
    order_id = req.data.get('orderId')
    approved = req.data.get('approved', False)

    if not order_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="orderId is required"
        )

    print(f"📋 {'Approving' if approved else 'Rejecting'} shipping cost for order {order_id}")

    try:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()

        if not order_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="Order not found"
            )

        order_data = order_doc.to_dict()

        # Verify user owns this order
        if order_data.get('userId') != user_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="Not authorized to approve this order"
            )

        # Verify approval is pending
        if order_data.get('shippingApprovalStatus') != ShippingApprovalStatus.PENDING:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="No shipping approval pending for this order"
            )

        if approved:
            # Buyer approved the new shipping cost
            pending_total = order_data.get('pendingTotal')
            pending_amount = order_data.get('pendingAmount')

            order_ref.update({
                'shippingApprovalStatus': ShippingApprovalStatus.APPROVED,
                'shippingApprovedAt': firestore.SERVER_TIMESTAMP,
                'total': pending_total,
                'amount': pending_amount,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            print(f"  ✅ Buyer approved shipping cost")

            return {
                "success": True,
                "status": "approved",
                "newTotal": pending_total,
                "message": "Shipping cost approved. Payment will be captured when seller confirms shipment."
            }
        else:
            # Buyer rejected - cancel the authorization
            payment_intent_id = order_data.get('stripePaymentIntentId')

            if payment_intent_id:
                try:
                    stripe.PaymentIntent.cancel(payment_intent_id)
                    print(f"  ❌ Authorization cancelled")
                except stripe.error.StripeError as e:
                    print(f"  ⚠️ Failed to cancel authorization: {str(e)}")

            # Restore stock
            _restore_stock_for_order(order_data)

            order_ref.update({
                'shippingApprovalStatus': ShippingApprovalStatus.REJECTED,
                'shippingRejectedAt': firestore.SERVER_TIMESTAMP,
                'status': OrderStatus.CANCELLED,
                'paymentStatus': 'cancelled',
                'cancellationReason': 'Buyer rejected shipping cost',
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            print(f"  ❌ Buyer rejected shipping cost - order cancelled")

            return {
                "success": True,
                "status": "rejected",
                "message": "Shipping cost rejected. Order has been cancelled and you will not be charged."
            }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error processing shipping approval: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to process approval: {str(e)}"
        )


@https_fn.on_call()
def capture_payment(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Called when seller confirms shipping to capture the authorized payment.
    For manual capture orders, this is when the actual charge happens.
    """
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )

    seller_id = req.auth.uid
    order_id = req.data.get('orderId')
    tracking_number = req.data.get('trackingNumber')

    if not order_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="orderId is required"
        )

    print(f"💳 Capturing payment for order {order_id} by seller {seller_id}")

    try:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_doc = order_ref.get()

        if not order_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="Order not found"
            )

        order_data = order_doc.to_dict()

        # Verify seller has items in this order
        seller_items = [i for i in order_data.get('items', []) if i.get('sellerId') == seller_id]
        if not seller_items:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="You don't have items in this order"
            )

        # Verify order is in authorized OR paid state (for multi-seller support)
        # If one seller already captured, status is PAID, but other sellers still need to ship
        payment_status = order_data.get('paymentStatus')
        if payment_status not in ['authorized', PaymentStatus.PAID]:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message=f"Payment cannot be captured (current status: {payment_status})"
            )

        # Check if shipping approval is required and approved
        if order_data.get('shippingApprovalRequired', False):
            approval_status = order_data.get('shippingApprovalStatus')
            if approval_status == ShippingApprovalStatus.PENDING:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                    message="Waiting for buyer to approve shipping cost"
                )
            elif approval_status == ShippingApprovalStatus.REJECTED:
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                    message="Buyer rejected the shipping cost. Order is cancelled."
                )

        payment_intent_id = order_data.get('stripePaymentIntentId')
        if not payment_intent_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="No payment intent found for this order"
            )

        # Get the capture amount (may have been updated with actual shipping)
        capture_amount = order_data.get('amount')  # In cents
        is_already_paid = payment_status == PaymentStatus.PAID

        # Capture the payment ONLY if not already paid
        if not is_already_paid:
            print(f"  💰 Capturing ${capture_amount / 100:.2f} CAD")
            try:
                payment_intent = stripe.PaymentIntent.capture(
                    payment_intent_id,
                    amount_to_capture=capture_amount,
                )
                print(f"  ✅ Payment captured successfully")
            except stripe.error.StripeError as e:
                print(f"  ❌ Stripe capture failed: {str(e)}")
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.INTERNAL,
                    message=f"Payment capture failed: {str(e)}"
                )
        else:
             print(f"  ℹ️ Order already PAID. Skipping Stripe capture, updating shipment info only.")

        # Update items with shipped status and tracking
        items = order_data.get('items', [])
        for item in items:
            if item.get('sellerId') == seller_id:
                item['deliveryStatus'] = DeliveryStatus.SHIPPED
                if tracking_number:
                    item['trackingNumber'] = tracking_number

        # Update order
        update_data = {
            'items': items,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        # Only update payment fields if we actually performed the capture
        if not is_already_paid:
            update_data.update({
                'paymentStatus': PaymentStatus.PAID,
                'capturedAmount': capture_amount,
                'capturedAt': firestore.SERVER_TIMESTAMP,
            })

        order_ref.update(update_data)

        print(f"  ✅ Order updated with captured payment")

        return {
            "success": True,
            "capturedAmount": capture_amount / 100,
            "message": "Payment captured and items marked as shipped"
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"❌ Error capturing payment: {str(e)}")
        print(traceback.format_exc())
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to capture payment: {str(e)}"
        )


@scheduler_fn.on_schedule(schedule="every 12 hours")
def check_expiring_authorizations(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to handle expiring payment authorizations.
    Stripe card authorizations typically expire after 7 days.

    This job:
    1. Warns about authorizations expiring in 24-48 hours
    2. Auto-captures or cancels orders where authorization is about to expire
    """
    print("=" * 80)
    print("🕐 CHECK EXPIRING AUTHORIZATIONS - Scheduled Job Started")
    print(f"Timestamp: {datetime.now().isoformat()}")
    print("=" * 80)

    try:
        # Calculate warning threshold (48 hours from now)
        warning_threshold = datetime.now() + timedelta(hours=48)

        # Calculate expiry threshold (orders that have expired)
        expiry_threshold = datetime.now()

        # Query for authorized orders
        orders_query = db.collection(Collections.ORDERS).where(
            'paymentStatus', '==', 'authorized'
        ).where(
            'captureMethod', '==', CaptureMethod.MANUAL
        ).stream()

        warned_count = 0
        expired_count = 0

        for order_doc in orders_query:
            order_id = order_doc.id
            order_data = order_doc.to_dict()

            try:
                auth_expires = order_data.get('authorizationExpiresAt')
                if not auth_expires:
                    continue

                # Convert to datetime if needed
                if hasattr(auth_expires, 'timestamp'):
                    auth_expires_dt = datetime.fromtimestamp(auth_expires.timestamp())
                else:
                    auth_expires_dt = auth_expires

                print(f"\n📦 Checking order: {order_id}")
                print(f"  Authorization expires: {auth_expires_dt.isoformat()}")

                if auth_expires_dt < expiry_threshold:
                    # Authorization has expired
                    print(f"  ⚠️ Authorization EXPIRED")

                    # Cancel the order
                    order_ref = db.collection(Collections.ORDERS).document(order_id)

                    # Try to cancel the payment intent
                    payment_intent_id = order_data.get('stripePaymentIntentId')
                    if payment_intent_id:
                        try:
                            stripe.PaymentIntent.cancel(payment_intent_id)
                        except stripe.error.StripeError:
                            pass  # May already be cancelled

                    # Restore stock
                    _restore_stock_for_order(order_data)

                    order_ref.update({
                        'status': OrderStatus.EXPIRED,
                        'paymentStatus': 'authorization_expired',
                        'expiredAt': firestore.SERVER_TIMESTAMP,
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })

                    # Notify customer
                    customer_email = order_data.get('customerEmail')
                    if customer_email:
                        send_email(
                            to_email=customer_email,
                            subject=f"Order #{order_id[:8]} Expired",
                            html_content=f"""
                            <html>
                            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                                <div style="padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                                    <h2 style="color: #e53935;">Order Expired</h2>
                                    <p>Unfortunately, your order #{order_id[:8]} has expired because the seller did not ship it within the required timeframe.</p>
                                    <p>Your payment authorization has been released and you will not be charged.</p>
                                    <p style="text-align: center; margin-top: 20px;">
                                        <a href="https://orignagta.ca" style="background: #FF6B35; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Continue Shopping</a>
                                    </p>
                                </div>
                            </body>
                            </html>
                            """
                        )

                    expired_count += 1

                elif auth_expires_dt < warning_threshold:
                    # Authorization expiring soon - warn seller
                    print(f"  ⚠️ Authorization expiring soon (within 48 hours)")

                    # Get seller info and notify
                    seller_ids = order_data.get('sellerIds', [])
                    for sid in seller_ids:
                        seller_doc = db.collection(Collections.USERS).document(sid).get()
                        if seller_doc.exists:
                            seller_email = seller_doc.to_dict().get('email')
                            if seller_email:
                                hours_remaining = int((auth_expires_dt - datetime.now()).total_seconds() / 3600)
                                send_email(
                                    to_email=seller_email,
                                    subject=f"⚠️ Action Required: Order #{order_id[:8]} Authorization Expiring",
                                    html_content=f"""
                                    <html>
                                    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                                        <div style="padding: 20px; border: 1px solid #ffc107; border-radius: 8px; background: #fff9e6;">
                                            <h2 style="color: #ff9800;">⚠️ Authorization Expiring</h2>
                                            <p>Order <strong>#{order_id[:8]}</strong> has a payment authorization expiring in <strong>{hours_remaining} hours</strong>.</p>
                                            <p>Please confirm the actual shipping cost and ship the order, or the authorization will expire and the order will be cancelled.</p>
                                            <p style="text-align: center; margin-top: 20px;">
                                                <a href="https://orignagta.ca/seller/orders" style="background: #FF6B35; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">View Order</a>
                                            </p>
                                        </div>
                                    </body>
                                    </html>
                                    """
                                )

                    warned_count += 1

            except Exception as order_error:
                print(f"  ❌ Error processing order {order_id}: {str(order_error)}")
                continue

        print("\n" + "=" * 80)
        print(f"✅ CHECK EXPIRING AUTHORIZATIONS - Job Complete")
        print(f"  Orders warned: {warned_count}")
        print(f"  Orders expired: {expired_count}")
        print("=" * 80)

    except Exception as e:
        print(f"❌ Error in expiring authorizations job: {str(e)}")
        print(traceback.format_exc())