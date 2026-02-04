"""
Origna GTA Cloud Functions - Entry Point
Refactored architecture with modular handlers

All Firebase Cloud Functions are organized by domain:
- payment_stripe: Stripe payment processing
- payment_airwallex: Airwallex payment processing  
- products: Product CRUD + Algolia sync
- orders: Order lifecycle management
- admin: User roles + MFA + GDPR
- cron_jobs: Scheduled background tasks
"""

# Firebase Admin SDK initialization
import firebase_admin
from firebase_admin import firestore

# Only initialize if not already initialized (for testing)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

# Stripe API key setup
import os
from google.cloud import secretmanager
import stripe

def get_secret(secret_id: str) -> str:
    """Retrieve secret from GCP Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    project_id = os.environ.get('GCP_PROJECT', 'origna-gta')
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')

# Lazy initialization of Stripe API key
def _init_stripe():
    """Initialize Stripe API key lazily"""
    if not stripe.api_key:
        stripe.api_key = get_secret('stripe-secret-key')

# Only initialize in production (not in test environment)
if os.environ.get('TESTING') != 'true':
    try:
        _init_stripe()
    except Exception:
        # If Secret Manager fails, Stripe will be initialized on first use
        pass

# ===============================================
# VALIDATION HELPERS
# ===============================================
def validate_postal_code(postal_code, country="Canada"):
    """
    Validate postal code format.
    
    Canadian postal code format: A1A 1A1 (letter-digit-letter space digit-letter-digit)
    """
    import re
    
    if country.lower() != "canada":
        return False
    
    # Canadian postal code pattern: A1A 1A1
    pattern = r'^[A-Z]\d[A-Z]\s?\d[A-Z]\d$'
    return bool(re.match(pattern, postal_code.upper()))

# ===============================================
# SHIPPING CALCULATION HELPER
# ===============================================
def calculate_shipping_cost(items, buyer_addr, speed="standard"):
    """
    Calculate shipping cost based on items and delivery address.
    
    Rules:
    1. If ALL items have freeShipping=True, return 0.0
    2. For items with fixed delivery options, use those prices
    3. For items without options, apply fallback rates based on province
    4. Sum costs per seller and item quantity
    """
    if not items:
        return 0.0
    
    # Check if all items are free shipping
    all_free_shipping = all(item.get('freeShipping', False) for item in items)
    if all_free_shipping:
        return 0.0
    
    total_cost = 0.0
    buyer_state = buyer_addr.get('state', '')
    
    for item in items:
        if item.get('freeShipping', False):
            continue
        
        quantity = item.get('quantity', 1)
        seller_state = item.get('sellerAddress', {}).get('state', '')
        
        # Check for fixed delivery options
        delivery_options = item.get('deliveryOptions', [])
        fixed_price = None
        
        for option in delivery_options:
            if option.get('speed') == speed and option.get('isEnabled', False):
                fixed_price = option.get('price', 0.0)
                break
        
        if fixed_price is not None:
            total_cost += quantity * fixed_price
        else:
            # Apply fallback rates based on province
            if buyer_state == seller_state:
                # Same province fallback: 12.99
                total_cost += quantity * 12.99
            else:
                # Different province fallback: 19.99
                total_cost += quantity * 19.99
    
    return round(total_cost, 2)

# ===============================================
# PAYMENT HANDLERS - STRIPE
# ===============================================
from handlers.payment_stripe import (
    create_checkout_session,
    stripe_webhook,
    capture_payment,
    create_connect_account,
    get_connect_account_status,
    create_account_link,
    process_charge_refunded,
    process_dispute_created,
    process_dispute_closed
)

# ===============================================
# PAYMENT HANDLERS - AIRWALLEX
# ===============================================
from handlers.payment_airwallex import (
    airwallex_create_seller_account,
    airwallex_process_payment,
    airwallex_capture_payment,
    airwallex_webhook
)

# ===============================================
# PRODUCT HANDLERS
# ===============================================
from handlers.products import (
    upload_product_images,
    delete_product,
    submit_product_rating,
    on_product_created,
    on_product_updated,
    on_product_deleted
)

# ===============================================
# ORDER HANDLERS
# ===============================================
from handlers.orders import (
    confirm_order_receipt,
    update_order_status,
    cancel_order,
    approve_shipping_cost,
    on_order_status_changed
)

# ===============================================
# ADMIN HANDLERS
# ===============================================
from handlers.admin import (
    update_user_roles,
    suspend_seller,
    admin_mfa_enroll,
    admin_mfa_verify,
    admin_mfa_disable,
    delete_account
)

# ===============================================
# PAYMENT PROVIDER MANAGEMENT
# ===============================================
from handlers.payment_providers import (
    get_payment_providers,
    update_payment_provider,
    get_provider_status
)

# ===============================================
# CRON JOB HANDLERS
# ===============================================
from handlers.cron_jobs import (
    auto_capture_confirmed_receipts,
    check_expired_authorizations,
    auto_archive_old_orders,
    monitor_algolia_sync,
    cleanup_stale_rate_limits
)

# Export all functions for Firebase deployment
__all__ = [
    # Validation
    'validate_postal_code',
    
    # Shipping
    'calculate_shipping_cost',
    
    # Stripe payments
    'create_checkout_session',
    'stripe_webhook',
    'capture_payment',
    'create_stripe_connect_account',
    'get_stripe_account_status',
    'create_stripe_connect_account_link',
    'transfer_to_seller',
    'process_charge_refunded',
    'process_dispute_created',
    'process_dispute_closed',
    
    # Airwallex payments
    'airwallex_create_seller_account',
    'airwallex_process_payment',
    'airwallex_capture_payment',
    'airwallex_webhook',
    
    # Products
    'upload_product_images',
    'delete_product',
    'submit_product_rating',
    'on_product_created',
    'on_product_updated',
    'on_product_deleted',
    
    # Orders
    'confirm_order_receipt',
    'update_order_status',
    'cancel_order',
    'approve_shipping_cost',
    'on_order_status_changed',
    
    # Admin
    'update_user_roles',
    'suspend_seller',
    'admin_mfa_enroll',
    'admin_mfa_verify',
    'admin_mfa_disable',
    'delete_account',
    
    # Payment Provider Management
    'get_payment_providers',
    'update_payment_provider',
    'get_provider_status',
    
    # Cron jobs
    'auto_capture_confirmed_receipts',
    'check_expired_authorizations',
    'auto_archive_old_orders',
    'monitor_algolia_sync',
    'cleanup_stale_rate_limits',
    'send_daily_metrics'
]

print(f"""
╔══════════════════════════════════════════════╗
║  Origna GTA Cloud Functions - Initialized   ║
║  Total Functions: {len(__all__)}                        ║
║  Architecture: Modular Handlers              ║
╚══════════════════════════════════════════════╝
""")


