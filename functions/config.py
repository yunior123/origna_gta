"""
Configuration Management for OrignaGTA Firebase Functions
==========================================================

ENVIRONMENT MODES:
- EMULATOR (Micro-Staging): Firebase Emulator only. External services (R2, Stripe, Algolia) are REAL.
- PRODUCTION: Firebase Cloud. All services are production.

WHAT'S EMULATED (Local):
- Firebase Auth (port 9099)
- Firestore (port 8080)
- Firebase Functions (port 5001)
- Firebase Storage (port 9199)

WHAT'S REAL (Even in Emulator Mode):
- Cloudflare R2 → Uses emulator/ folder prefix to separate test data
- Stripe → Uses test keys (sk_test_*) - real API, test mode
- Algolia → Uses products_emulator index to separate test data
- Mailjet, Geoapify → Real APIs

DETECTION:
- Emulator: FUNCTIONS_EMULATOR='true' (set by Firebase emulator automatically)
- Production: FUNCTIONS_EMULATOR='false' or not set (default in cloud deployment)

USAGE:
- Local dev: Run `firebase emulators:start` - Firebase is emulated, external APIs are real
- Production: Deployed via GitHub Actions after tests pass
"""
import os
from firebase_functions import params
from enum import Enum

# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

class Environment(Enum):
    EMULATOR = "emulator"       # Local development with Firebase emulators (micro-staging)
    PRODUCTION = "production"   # Deployed to Firebase Cloud

# Auto-detect environment
# Firebase emulator sets FUNCTIONS_EMULATOR='true' automatically
IS_EMULATOR = os.environ.get('FUNCTIONS_EMULATOR', 'false').lower() == 'true'
CURRENT_ENV = Environment.EMULATOR if IS_EMULATOR else Environment.PRODUCTION

def get_environment() -> Environment:
    """Get current environment."""
    return CURRENT_ENV

def is_emulator() -> bool:
    """Check if running in emulator mode."""
    return IS_EMULATOR

# ============================================================================
# CONSTANTS - Must match Flutter constants.dart
# ============================================================================

class OrderStatus:
    PENDING = 'pending'
    CONFIRMED = 'confirmed'
    PROCESSING = 'processing'
    SHIPPED = 'shipped'
    IN_TRANSIT = 'in_transit'
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
    AUTHORIZED = 'authorized'
    CAPTURED = 'captured'

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
    PAYOUTS = 'payouts'
    REFUNDS = 'refunds'
    WEBHOOK_LOGS = 'webhook_logs'
    WEBHOOK_EVENTS = 'webhook_events'
    SECURITY_ALERTS = 'security_alerts'
    RATE_LIMITS = 'rate_limits'
    CONFIG = 'config'
    ADMIN_LOGS = 'admin_logs'
    PRODUCT_RATINGS = 'product_ratings'

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

# ============================================================================
# PLATFORM CONFIGURATION
# ============================================================================

PLATFORM_FEE_PERCENT = 0.025  # 2.5% platform fee
AUTO_CONFIRM_DAYS = 7  # Auto-confirm must be <= AUTHORIZATION_VALID_DAYS (Stripe limit)
AUTHORIZATION_VALID_DAYS = 7  # Stripe authorization valid for 7 days
SHIPPING_APPROVAL_THRESHOLD = 0.20  # 20%

# ============================================================================
# R2 STORAGE CONFIGURATION - REAL service, environment-aware paths
# R2 is always real (not emulated). We use folder prefixes to separate data.
# ============================================================================

class R2Config:
    """Cloudflare R2 Storage Configuration.
    
    NOTE: R2 is a REAL service even in emulator mode.
    We use 'emulator/' folder prefix to separate test uploads from production.
    """
    
    BUCKET_NAME = "orignagta-images"
    
    @staticmethod
    def get_products_folder() -> str:
        """Get folder path for product images based on environment."""
        return "emulator/products" if IS_EMULATOR else "products"
    
    @staticmethod
    def get_users_folder() -> str:
        """Get folder path for user images based on environment."""
        return "emulator/users" if IS_EMULATOR else "users"
    
    @staticmethod
    def get_image_path(category: str, filename: str) -> str:
        """Build full image path based on environment.
        
        Args:
            category: 'products' or 'users'
            filename: The image filename
        Returns:
            Full path like 'emulator/products/img.jpg' or 'products/img.jpg'
        """
        if category == "products":
            return f"{R2Config.get_products_folder()}/{filename}"
        elif category == "users":
            return f"{R2Config.get_users_folder()}/{filename}"
        else:
            prefix = "emulator/" if IS_EMULATOR else ""
            return f"{prefix}{category}/{filename}"

# ============================================================================
# ALGOLIA CONFIGURATION - REAL service, separate index per environment
# Algolia is always real (not emulated). We use separate indexes.
# ============================================================================

class AlgoliaConfig:
    """Algolia search configuration.
    
    NOTE: Algolia is a REAL service even in emulator mode.
    We use 'products_emulator' index to separate test data from production.
    """
    
    @staticmethod
    def get_index_name() -> str:
        """Get Algolia index name based on environment."""
        return "products_emulator" if IS_EMULATOR else "products"

# ============================================================================
# SECRETS MANAGEMENT
# ============================================================================

def _load_secret(key: str, required: bool = True) -> str:
    """
    Load secret safely based on environment.
    
    EMULATOR: Reads from environment variables (.env file via dotenv)
    PRODUCTION: Reads from Google Secret Manager via params.SecretParam
    """
    if IS_EMULATOR:
        value = os.environ.get(key)
        if not value and required:
            raise ValueError(f"❌ {key} required in emulator mode. Add to .env or export {key}=...")
        return value or ""
    else:
        try:
            return params.SecretParam(key).value
        except Exception as e:
            if required:
                raise RuntimeError(f"❌ Failed to load {key} from Secret Manager: {e}")
            return ""

# ============================================================================
# STRIPE CONFIGURATION
# ============================================================================

class StripeConfig:
    """Stripe payment configuration."""
    
    @staticmethod
    def is_test_mode() -> bool:
        """Check if using Stripe test keys (sk_test_*)."""
        return STRIPE_SECRET_KEY.startswith("sk_test_") if STRIPE_SECRET_KEY else True

# Load Stripe keys
try:
    STRIPE_SECRET_KEY = _load_secret("STRIPE_SECRET_KEY", required=True)
    STRIPE_WEBHOOK_SECRET = _load_secret("STRIPE_WEBHOOK_SECRET", required=True)
except (ValueError, RuntimeError) as e:
    if IS_EMULATOR:
        # Allow partial testing in emulator without all secrets
        print(f"⚠️ Stripe not configured: {e}")
        STRIPE_SECRET_KEY = ""
        STRIPE_WEBHOOK_SECRET = ""
    else:
        print(f"FATAL: {e}")
        raise

# ============================================================================
# MAILJET CONFIGURATION
# ============================================================================

try:
    MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_API_KEY", required=True)
    MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED("MAILJET_SECRET_KEY", required=True)
except (ValueError, RuntimeError) as e:
    if IS_EMULATOR:
        print(f"⚠️ Mailjet not configured: {e}")
        MAILJET_API_KEY = ""
        MAILJET_SECRET_KEY = ""
    else:
        print(f"FATAL: {e}")
        raise

# ============================================================================
# GEOAPIFY CONFIGURATION
# ============================================================================

try:
    GEOAPIFY_API_KEY = _load_secret("GEOAPIFY_API_KEY", required=True)
except (ValueError, RuntimeError) as e:
    if IS_EMULATOR:
        print(f"⚠️ Geoapify not configured: {e}")
        GEOAPIFY_API_KEY = ""
    else:
        print(f"FATAL: {e}")
        raise

# ============================================================================
# ALGOLIA SECRETS
# ============================================================================

try:
    ALGOLIA_APP_ID = _load_secret("ALGOLIA_APP_ID", required=True)
    ALGOLIA_WRITE_API_KEY = _load_secret("ALGOLIA_WRITE_API_KEY", required=True)
except (ValueError, RuntimeError) as e:
    if IS_EMULATOR:
        print(f"⚠️ Algolia not configured: {e}")
        ALGOLIA_APP_ID = ""
        ALGOLIA_WRITE_API_KEY = ""
    else:
        print(f"FATAL: {e}")
        raise

# ============================================================================
# CLOUDFLARE R2 SECRETS
# ============================================================================

# These are params.SecretParam for Firebase deployment (resolved at runtime in prod)
R2_ACCESS_KEY_NEW = params.SecretParam("R2_ACCESS_KEY")
R2_SECRET_KEY_NEW = params.SecretParam("R2_SECRET_KEY")
R2_ACCOUNT_ID_NEW = params.SecretParam("R2_ACCOUNT_ID")

def get_r2_credentials() -> dict:
    """Get R2 credentials based on environment."""
    if IS_EMULATOR:
        return {
            "access_key": os.environ.get("R2_ACCESS_KEY", ""),
            "secret_key": os.environ.get("R2_SECRET_KEY", ""),
            "account_id": os.environ.get("R2_ACCOUNT_ID", ""),
        }
    else:
        return {
            "access_key": R2_ACCESS_KEY_NEW.value if hasattr(R2_ACCESS_KEY_NEW, 'value') else "",
            "secret_key": R2_SECRET_KEY_NEW.value if hasattr(R2_SECRET_KEY_NEW, 'value') else "",
            "account_id": R2_ACCOUNT_ID_NEW.value if hasattr(R2_ACCOUNT_ID_NEW, 'value') else "",
        }

# ============================================================================
# AIRWALLEX CONFIGURATION (OPTIONAL)
# ============================================================================

AIRWALLEX_API_KEY = _load_secret("AIRWALLEX_API_KEY", required=False)
AIRWALLEX_CLIENT_ID = _load_secret("AIRWALLEX_CLIENT_ID", required=False)
AIRWALLEX_WEBHOOK_SECRET = _load_secret("AIRWALLEX_WEBHOOK_SECRET", required=False)
AIRWALLEX_BASE_URL = os.environ.get("AIRWALLEX_BASE_URL", "https://api.airwallex.com/api/v1")

# ============================================================================
# OTHER CONFIGURATION
# ============================================================================

SELLER_EMAIL = os.environ.get("SELLER_EMAIL", "support@orignaventures.ca")

# Stripe Tax Code Mapping
CATEGORY_TAX_CODE_MAP = {
    14: "txcd_10000000",
    17: "txcd_20030002",
    19: "txcd_30060005",
    21: "txcd_10000001",
}

# ============================================================================
# DEBUG & LOGGING
# ============================================================================

def print_env_info():
    """Print current environment info for debugging."""
    print("=" * 60)
    print(f"🔧 ENVIRONMENT: {CURRENT_ENV.value.upper()}")
    print(f"   IS_EMULATOR: {IS_EMULATOR}")
    print(f"   R2 Products Folder: {R2Config.get_products_folder()}")
    print(f"   R2 Users Folder: {R2Config.get_users_folder()}")
    print(f"   Algolia Index: {AlgoliaConfig.get_index_name()}")
    print(f"   Stripe Test Mode: {StripeConfig.is_test_mode()}")
    print("=" * 60)

# Print environment info on module load in emulator mode
if IS_EMULATOR:
    print_env_info()
