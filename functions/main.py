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
# Stripe API key setup
import os

import firebase_admin
import stripe
from google.cloud import secretmanager

# ===============================================
# PAYMENT HANDLERS - STRIPE
# ===============================================
# ===============================================
# ADMIN HANDLERS
# ===============================================
from handlers.admin import (  # noqa: E402
    admin_mfa_disable,
    admin_mfa_enroll,
    admin_mfa_verify,
    delete_account,
    suspend_seller,
    update_user_roles,
)

# ===============================================
# CRON JOB HANDLERS
# ===============================================
from handlers.cron_jobs import (  # noqa: E402
    auto_archive_old_orders,
    auto_capture_confirmed_receipts,
    check_expired_authorizations,
    cleanup_stale_rate_limits,
    monitor_algolia_sync,
)

# ===============================================
# ORDER HANDLERS
# ===============================================
from handlers.orders import (  # noqa: E402
    approve_shipping_cost,
    cancel_order,
    confirm_order_receipt,
    on_order_status_changed,
    refund_order_item,
    update_item_status,
    update_order_status,
    update_shipping_cost,
)

# ===============================================
# PAYMENT HANDLERS - AIRWALLEX
# ===============================================
from handlers.payment_airwallex import (  # noqa: E402
    airwallex_capture_payment,
    airwallex_create_seller_account,
    airwallex_process_payment,
    airwallex_webhook,
)

# ===============================================
# PAYMENT PROVIDER MANAGEMENT
# ===============================================
from handlers.payment_providers import get_payment_providers, get_provider_status, update_payment_provider  # noqa: E402
from handlers.payment_stripe import (  # noqa: E402
    capture_payment,
    create_account_link,
    create_checkout_session,
    create_connect_account,
    get_connect_account_status,
    process_charge_refunded,
    process_dispute_closed,
    process_dispute_created,
    stripe_webhook,
    verify_cart_prices,
)
from handlers.products import (  # noqa: E402
    delete_product,
    on_product_created,
    on_product_deleted,
    on_product_updated,
    submit_product_rating,
    upload_product_images,
)
from handlers.users import (  # noqa: E402
    get_user_profile,
    update_user_profile,
)

# ===============================================
# PRODUCT HANDLERS
# ===============================================
from schema_constants import Fields  # noqa: E402

# ===============================================
# SHIPPING CALCULATION — Canonical source is services/shipping_service.py
# This wrapper re-exports calculate_shipping_cost for external HTTP callers.
# The checkout flow (payment_stripe.py) imports directly from services.shipping_service.
# ===============================================
from services.shipping_service import calculate_shipping_cost  # noqa: E402, F811

# Only initialize if not already initialized (for testing)
if not firebase_admin._apps:
    firebase_admin.initialize_app()


def get_secret(secret_id: str) -> str:
    """Retrieve secret from GCP Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    project_id = os.environ.get('GCP_PROJECT', 'origna-gta')
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={Fields.NAME: name})
    return response.payload.data.decode('UTF-8')

# Lazy initialization of Stripe API key
def _init_stripe():
    """Initialize Stripe API key lazily"""
    if not stripe.api_key:
        stripe.api_key = get_secret('stripe-secret-key')

# Only initialize in production (not in test environment)
if os.environ.get('TESTING') != 'true':
    import contextlib
    with contextlib.suppress(Exception):
        _init_stripe()

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


# Export all functions for Firebase deployment
__all__ = [
    # Validation
    'validate_postal_code',

    # Shipping
    'calculate_shipping_cost',

    # Stripe payments
    'create_checkout_session',
    'verify_cart_prices',
    'stripe_webhook',
    'capture_payment',
    'create_connect_account',
    'get_connect_account_status',
    'create_account_link',
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
    'update_item_status',
    'refund_order_item',
    'cancel_order',
    'approve_shipping_cost',
    'update_shipping_cost',
    'on_order_status_changed',

    # Admin
    'update_user_roles',
    'suspend_seller',
    'admin_mfa_enroll',
    'admin_mfa_verify',
    'admin_mfa_disable',
    'delete_account',

    # User Profile
    'update_user_profile',
    'get_user_profile',

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
]

print(f"""
╔══════════════════════════════════════════════╗
║  Origna GTA Cloud Functions - Initialized   ║
║  Total Functions: {len(__all__)}                        ║
║  Architecture: Modular Handlers              ║
╚══════════════════════════════════════════════╝
""")


