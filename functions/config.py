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

# Environment - CRITICAL: Auto-detects based on deployment context
# In CI/CD (GitHub Actions): FUNCTIONS_EMULATOR='false' (production secrets)
# In local dev: FUNCTIONS_EMULATOR='true' (reads from .env file)
# NEVER commit .env files - they are in .gitignore
IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR', 'false') == 'true'

# ============================================================================
# SECRETS MANAGEMENT - SECURE VERSION (NO FALLBACKS)
# CRITICAL: All secrets MUST be set explicitly. No fallbacks to prevent leaks.
# ============================================================================

def _load_secret(key: str, required: bool = True) -> str:
    """Load secret safely with no fallbacks."""
    if IS_EMULATOR:
        value = os.environ.get(key)
        if not value and required:
            raise ValueError(f"❌ {key} required even in emulator mode. Set it in .env or export {key}=...")
        return value or ""
    else:
        try:
            return params.SecretParam(key).value
        except Exception as e:
            if required:
                raise RuntimeError(f"❌ Failed to load {key} from Secret Manager: {e}")
            return ""

# Stripe keys & Secrets (REQUIRED)
try:
    STRIPE_SECRET_KEY = _load_secret("STRIPE_SECRET_KEY", required=True)
    STRIPE_WEBHOOK_SECRET = _load_secret("STRIPE_WEBHOOK_SECRET", required=True)
except (ValueError, RuntimeError) as e:
    print(f"FATAL: {e}")
    raise

# Mailjet (REQUIRED for order confirmations)
try:
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY", required=True)
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY", required=True)
except (ValueError, RuntimeError) as e:
    print(f"FATAL: {e}")
    raise

# Geoapify (REQUIRED for shipping)
try:
    GEOAPIFY_API_KEY = _load_secret("GEOAPIFY_API_KEY", required=True)
except (ValueError, RuntimeError) as e:
    print(f"FATAL: {e}")
    raise

# Algolia (REQUIRED for search)
try:
    ALGOLIA_APP_ID = _load_secret("ALGOLIA_APP_ID", required=True)
    ALGOLIA_WRITE_API_KEY = _load_secret("ALGOLIA_WRITE_API_KEY", required=True)
except (ValueError, RuntimeError) as e:
    print(f"FATAL: {e}")
    raise

# Cloudflare R2 (REQUIRED for image storage)
try:
    if IS_EMULATOR:
        # In emulator mode, load from environment
        R2_ACCESS_KEY_NEW = type('obj', (object,), {'key': 'R2_ACCESS_KEY'})()
        R2_SECRET_KEY_NEW = type('obj', (object,), {'key': 'R2_SECRET_KEY'})()
        R2_ACCOUNT_ID_NEW = type('obj', (object,), {'key': 'R2_ACCOUNT_ID'})()
    else:
        # In production, use SecretParam
        R2_ACCESS_KEY_NEW = params.SecretParam("R2_ACCESS_KEY")
        R2_SECRET_KEY_NEW = params.SecretParam("R2_SECRET_KEY")
        R2_ACCOUNT_ID_NEW = params.SecretParam("R2_ACCOUNT_ID")
except Exception as e:
    print(f"WARNING: R2 secrets not configured: {e}")
    R2_ACCESS_KEY_NEW = None
    R2_SECRET_KEY_NEW = None
    R2_ACCOUNT_ID_NEW = None

# Airwallex (OPTIONAL - for alternative payment provider)
AIRWALLEX_API_KEY = _load_secret("AIRWALLEX_API_KEY", required=False)
AIRWALLEX_CLIENT_ID = _load_secret("AIRWALLEX_CLIENT_ID", required=False)
AIRWALLEX_WEBHOOK_SECRET = _load_secret("AIRWALLEX_WEBHOOK_SECRET", required=False)
AIRWALLEX_BASE_URL = os.environ.get("AIRWALLEX_BASE_URL", "https://api.airwallex.com/api/v1")

# Seller email (not secret, can have default)
SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "seller@orignagta.com")

# Stripe Tax Code Mapping
CATEGORY_TAX_CODE_MAP = {
    14: "txcd_10000000",
    17: "txcd_20030002",
    19: "txcd_30060005",
    21: "txcd_10000001",
}
