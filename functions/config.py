import os
from firebase_functions import params

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
    BUYER = 'buyer'

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
AUTO_CONFIRM_DAYS = 7  # Auto-confirm must be <= AUTHORIZATION_VALID_DAYS (Stripe limit)
AUTHORIZATION_VALID_DAYS = 7  # Stripe authorization valid for 7 days
SHIPPING_APPROVAL_THRESHOLD = 0.20  # 20%

# Environment
IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR') == 'true'

# Stripe keys & Secrets
if IS_EMULATOR:
    STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY", "sk_test_...")
    STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET", "STRIPE_WEBHOOK_SECRET_REDACTED...")
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY", "")
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY", "")
    GEOAPIFY_API_KEY = os.environ.get("GEOAPIFY_API_KEY", "")
    ALGOLIA_APP_ID = os.environ.get("ALGOLIA_APP_ID", "")
    ALGOLIA_WRITE_API_KEY = os.environ.get("ALGOLIA_WRITE_API_KEY", "")
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    AIRWALLEX_API_KEY = os.environ.get("AIRWALLEX_API_KEY", "")
    AIRWALLEX_CLIENT_ID = os.environ.get("AIRWALLEX_CLIENT_ID", "")
    AIRWALLEX_WEBHOOK_SECRET = os.environ.get("AIRWALLEX_WEBHOOK_SECRET", "")
    AIRWALLEX_BASE_URL = os.environ.get("AIRWALLEX_BASE_URL", "https://api.airwallex.com/api/v1")
else:
    STRIPE_SECRET_KEY = params.SecretParam("STRIPE_SECRET_KEY").value
    STRIPE_WEBHOOK_SECRET = params.SecretParam("STRIPE_WEBHOOK_SECRET").value
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY").value
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY").value
    GEOAPIFY_API_KEY = params.SecretParam("GEOAPIFY_API_KEY").value
    ALGOLIA_APP_ID = params.SecretParam("ALGOLIA_APP_ID").value
    ALGOLIA_WRITE_API_KEY = params.SecretParam("ALGOLIA_WRITE_API_KEY").value
    SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")
    AIRWALLEX_API_KEY = params.SecretParam("AIRWALLEX_API_KEY").value
    AIRWALLEX_CLIENT_ID = params.SecretParam("AIRWALLEX_CLIENT_ID").value
    AIRWALLEX_WEBHOOK_SECRET = params.SecretParam("AIRWALLEX_WEBHOOK_SECRET").value
    AIRWALLEX_BASE_URL = os.environ.get("AIRWALLEX_BASE_URL", "https://api.airwallex.com/api/v1")

# Stripe Tax Code Mapping
CATEGORY_TAX_CODE_MAP = {
    14: "txcd_10000000",
    17: "txcd_20030002",
    19: "txcd_30060005",
    21: "txcd_10000001",
}
