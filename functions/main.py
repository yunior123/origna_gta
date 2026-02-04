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
# PAYMENT HANDLERS - STRIPE
# ===============================================
from handlers.payment_stripe import (
    create_checkout_session,
    stripe_webhook,
    capture_payment,
    create_connect_account,
    get_connect_account_status,
    create_account_link
    # transfer_to_seller n'existe pas dans le module
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
    # Stripe payments
    'create_checkout_session',
    'stripe_webhook',
    'capture_payment',
    'create_stripe_connect_account',
    'get_stripe_account_status',
    'create_stripe_connect_account_link',
    'transfer_to_seller',
    
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


