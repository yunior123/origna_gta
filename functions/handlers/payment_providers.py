"""
Payment Provider Management
============================
Admin controls for enabling/disabling payment providers.
Prevents payment operations when provider is disabled.

Collections:
- config/payment_providers: Global payment provider settings

Providers Supported:
- stripe: Stripe payment processing
- airwallex: Airwallex payment processing (international)
"""

from typing import Any, ClassVar

from firebase_functions import https_fn

from config import Collections
from function_options import DEFAULT_OPTIONS
from schema_constants import ApiKeys, Fields, UserRoleValues

# ============================================================================
# LAZY INITIALIZATION
# ============================================================================

_db = None
_firestore = None

def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        from firebase_admin import firestore as fs
        _firestore = fs
        _db = fs.client()
    return _db

def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs
        _firestore = fs
    return _firestore.SERVER_TIMESTAMP


def _is_provider_configured(provider: str) -> tuple:
    """
    Check if a payment provider has API keys configured.

    Returns:
        Tuple of (is_configured: bool, missing_keys: list)
    """
    if provider == "stripe":
        from config import STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET
        missing = []
        if not STRIPE_SECRET_KEY:
            missing.append("STRIPE_SECRET_KEY")
        if not STRIPE_WEBHOOK_SECRET:
            missing.append("STRIPE_WEBHOOK_SECRET")
        return (len(missing) == 0, missing)

    elif provider == "airwallex":
        from config import AIRWALLEX_API_KEY, AIRWALLEX_CLIENT_ID
        missing = []
        if not AIRWALLEX_API_KEY:
            missing.append("AIRWALLEX_API_KEY")
        if not AIRWALLEX_CLIENT_ID:
            missing.append("AIRWALLEX_CLIENT_ID")
        return (len(missing) == 0, missing)

    return (False, ["Unknown provider"])


# ============================================================================
# PAYMENT PROVIDER CONSTANTS
# ============================================================================

class PaymentProvider:
    """Supported payment providers."""

    STRIPE: str = "stripe"
    AIRWALLEX: str = "airwallex"
    ALL: ClassVar[list[str]] = [STRIPE, AIRWALLEX]


# Default provider settings
DEFAULT_PROVIDER_CONFIG = {
    PaymentProvider.STRIPE: {
        "enabled": True,
        Fields.NAME: "Stripe",
        Fields.DESCRIPTION: "Primary payment processor",
        "supportedCurrencies": ["CAD", "USD"],
        "supportedCountries": ["CA", "US"],
        "features": ["cards", "apple_pay", "google_pay"],
    },
    PaymentProvider.AIRWALLEX: {
        "enabled": False,  # Disabled by default, requires full KYC setup
        Fields.NAME: "Airwallex",
        Fields.DESCRIPTION: "International payment processor",
        "supportedCurrencies": ["CAD", "USD", "EUR", "GBP", "CNY"],
        "supportedCountries": ["CA", "US", "CN", "GB", "EU"],
        "features": ["cards", "alipay", "wechat_pay"],
    },
}


# ============================================================================
# UTILITY FUNCTIONS (Used by other handlers)
# ============================================================================

def is_provider_enabled(provider: str) -> bool:
    """
    Check if a payment provider is enabled.

    Args:
        provider: Provider name ("stripe" or "airwallex")

    Returns:
        True if provider is enabled, False otherwise

    Usage:
        from handlers.payment_providers import is_provider_enabled, PaymentProvider

        if not is_provider_enabled(PaymentProvider.STRIPE):
            raise https_fn.HttpsError("failed-precondition", "Stripe payments are currently disabled")
    """
    if provider not in PaymentProvider.ALL:
        return False

    try:
        config_ref = get_db().collection(Collections.CONFIG).document("payment_providers")
        config_doc = config_ref.get()

        if not config_doc.exists:
            # Return default value
            return DEFAULT_PROVIDER_CONFIG.get(provider, {}).get("enabled", False)

        config_data = config_doc.to_dict()
        provider_config = config_data.get(provider, {})

        return provider_config.get("enabled", DEFAULT_PROVIDER_CONFIG.get(provider, {}).get("enabled", False))

    except Exception as e:
        print(f"Error checking provider status: {str(e)}")
        # Fail open for stripe (essential), closed for others
        return provider == PaymentProvider.STRIPE


def get_enabled_providers() -> list:
    """
    Get list of all enabled payment providers.

    Returns:
        List of enabled provider names
    """
    enabled = []

    try:
        config_ref = get_db().collection(Collections.CONFIG).document("payment_providers")
        config_doc = config_ref.get()

        if not config_doc.exists:
            # Return defaults
            for provider, config in DEFAULT_PROVIDER_CONFIG.items():
                if config.get("enabled", False):
                    enabled.append(provider)
            return enabled

        config_data = config_doc.to_dict()

        for provider in PaymentProvider.ALL:
            provider_config = config_data.get(provider, DEFAULT_PROVIDER_CONFIG.get(provider, {}))
            if provider_config.get("enabled", False):
                enabled.append(provider)

        return enabled

    except Exception as e:
        print(f"Error getting enabled providers: {str(e)}")
        # Default to stripe only
        return [PaymentProvider.STRIPE]


def require_provider_enabled(provider: str) -> None:
    """
    Raises an HttpsError if the provider is disabled.
    Use this at the start of payment functions.

    Args:
        provider: Provider name to check

    Raises:
        https_fn.HttpsError: If provider is disabled
    """
    if not is_provider_enabled(provider):
        provider_name = DEFAULT_PROVIDER_CONFIG.get(provider, {}).get(Fields.NAME, provider)
        raise https_fn.HttpsError(
            "failed-precondition",
            f"{provider_name} payments are currently disabled by administrator"
        )


# ============================================================================
# ADMIN HELPER
# ============================================================================

def _require_admin(req: https_fn.CallableRequest) -> tuple:
    """
    Validates admin permissions.

    Returns:
        Tuple of (admin_id, admin_data)

    Raises:
        https_fn.HttpsError: If not authenticated or not admin
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    admin_id = req.auth.uid
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    admin_data = admin_doc.to_dict()

    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    return admin_id, admin_data


# ============================================================================
# ADMIN FUNCTIONS
# ============================================================================

@https_fn.on_call(**DEFAULT_OPTIONS)
def get_payment_providers(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Get all payment provider configurations (admin only).

    Returns:
        {
            success: True,
            providers: {
                stripe: { enabled: true, name: "Stripe", configured: true, ... },
                airwallex: { enabled: false, name: "Airwallex", configured: false, ... }
            },
            enabledProviders: ["stripe"]
        }
    """
    admin_id, _ = _require_admin(req)

    try:
        config_ref = get_db().collection(Collections.CONFIG).document("payment_providers")
        config_doc = config_ref.get()

        config_data = {} if not config_doc.exists else config_doc.to_dict()

        # Merge with defaults for any missing providers
        providers = {}
        for provider in PaymentProvider.ALL:
            default = DEFAULT_PROVIDER_CONFIG.get(provider, {})
            stored = config_data.get(provider, {})
            is_configured, missing_keys = _is_provider_configured(provider)
            providers[provider] = {
                **default,
                **stored,
                ApiKeys.CONFIGURED: is_configured,
                ApiKeys.MISSING_KEYS: missing_keys if not is_configured else []
            }

        # Return dict directly for on_call functions (not Response object)
        return {
            "success": True,
            ApiKeys.PROVIDERS: providers,
            ApiKeys.ENABLED_PROVIDERS: get_enabled_providers()
        }

    except Exception as e:
        print(f"get_payment_providers error: {str(e)}")
        raise https_fn.HttpsError("internal", "Failed to get provider config") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_payment_provider(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Enable or disable a payment provider (admin only).

    Request data:
        provider: Provider name ("stripe" or "airwallex")
        enabled: Boolean - whether to enable the provider
        reason: Optional string - reason for the change (logged)

    Returns:
        {success: True, provider: "stripe", enabled: true}
    """
    admin_id, _ = _require_admin(req)

    provider = req.data.get(ApiKeys.PROVIDER)
    enabled = req.data.get(ApiKeys.ENABLED)
    reason = req.data.get(ApiKeys.REASON, "")

    # Validate inputs
    if provider not in PaymentProvider.ALL:
        raise https_fn.HttpsError(
            "invalid-argument",
            f"Invalid provider. Must be one of: {', '.join(PaymentProvider.ALL)}"
        )

    if not isinstance(enabled, bool):
        raise https_fn.HttpsError("invalid-argument", "enabled must be a boolean")

    # If enabling, check that API keys are configured
    if enabled:
        is_configured, missing_keys = _is_provider_configured(provider)
        if not is_configured:
            provider_name = DEFAULT_PROVIDER_CONFIG.get(provider, {}).get(Fields.NAME, provider)
            raise https_fn.HttpsError(
                "failed-precondition",
                f"{provider_name} is not configured. Missing API keys: {', '.join(missing_keys)}. "
                f"Please configure the {provider_name} account first."
            )

    # Safety check: don't allow disabling all providers
    if not enabled:
        current_enabled = get_enabled_providers()
        remaining = [p for p in current_enabled if p != provider]

        if len(remaining) == 0:
            raise https_fn.HttpsError(
                "failed-precondition",
                "Cannot disable all payment providers. At least one must remain enabled."
            )

        # AUDIT FIX (MEDIUM-030): Block disabling a provider with active authorized orders.
        # Without this, orders paid but not yet captured would be stranded because
        # capture_payment() checks require_provider_enabled() first.
        from schema_constants import PaymentStatusValues as PSV
        active_orders = get_db().collection("orders")\
            .where("paymentProvider", "==", provider)\
            .where("paymentStatus", "in", [PSV.AUTHORIZED, "capturing"])\
            .limit(1).get()

        if len(active_orders) > 0:
            raise https_fn.HttpsError(
                "failed-precondition",
                f"Cannot disable {provider}: there are orders with active authorizations. "
                f"Wait for all pending orders to be captured or expired before disabling."
            )

    try:
        config_ref = get_db().collection(Collections.CONFIG).document("payment_providers")

        # Get current config or use defaults
        config_doc = config_ref.get()

        config_data = dict(DEFAULT_PROVIDER_CONFIG) if not config_doc.exists else config_doc.to_dict()

        # Update the provider
        if provider not in config_data:
            config_data[provider] = dict(DEFAULT_PROVIDER_CONFIG.get(provider, {}))

        old_enabled = config_data[provider].get("enabled", False)
        config_data[provider]["enabled"] = enabled
        config_data[provider][Fields.UPDATED_AT] = get_server_timestamp()
        config_data[provider]["updatedBy"] = admin_id

        # Save config
        config_ref.set(config_data, merge=True)

        # Log the change
        get_db().collection(Collections.ADMIN_LOGS).add({
            "action": "payment_provider_update",
            Fields.ADMIN_ID: admin_id,
            Fields.PROVIDER: provider,
            "oldEnabled": old_enabled,
            "newEnabled": enabled,
            Fields.REASON: reason[:500] if reason else "",  # Limit reason length
            Fields.TIMESTAMP: get_server_timestamp()
        })

        # Log security alert if disabling
        if old_enabled and not enabled:
            get_db().collection(Collections.SECURITY_ALERTS).add({
                Fields.TYPE: "payment_provider_disabled",
                Fields.SEVERITY: "high",
                Fields.ADMIN_ID: admin_id,
                Fields.PROVIDER: provider,
                Fields.REASON: reason[:500] if reason else "",
                Fields.TIMESTAMP: get_server_timestamp(),
                Fields.RESOLVED: True
            })

        # Return dict directly for on_call functions (not Response object)
        return {
            "success": True,
            ApiKeys.PROVIDER: provider,
            ApiKeys.ENABLED: enabled,
            "providerName": DEFAULT_PROVIDER_CONFIG.get(provider, {}).get(Fields.NAME, provider)
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"update_payment_provider error: {str(e)}")
        raise https_fn.HttpsError("internal", "Failed to update provider") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_provider_status(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Get status of enabled payment providers (public - for payment UI).
    Only returns enabled/disabled status, not full config.

    Returns:
        {
            success: True,
            providers: {
                stripe: { enabled: true, name: "Stripe" },
                airwallex: { enabled: false, name: "Airwallex" }
            }
        }
    """
    # This can be called by any authenticated user
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    try:
        providers = {}

        for provider in PaymentProvider.ALL:
            default = DEFAULT_PROVIDER_CONFIG.get(provider, {})
            is_configured, _ = _is_provider_configured(provider)
            providers[provider] = {
                ApiKeys.ENABLED: is_provider_enabled(provider),
                ApiKeys.CONFIGURED: is_configured,
                Fields.NAME: default.get(Fields.NAME, provider),
                "features": default.get("features", [])
            }

        # Return dict directly for on_call functions (not Response object)
        return {
            "success": True,
            "providers": providers
        }

    except Exception as e:
        print(f"get_provider_status error: {str(e)}")
        raise https_fn.HttpsError("internal", "Failed to get provider status") from e
