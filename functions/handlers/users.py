"""
User Management Handlers
- User profile updates
- Tax exemption management

NOTE: Stripe Tax handles GST validation and B2B exemption automatically.
We only store the GST number - Stripe validates it during checkout.
"""

import logging
from typing import Any

from firebase_functions import https_fn

from schema_constants import (
    COUNTRY_CANADA,
    BusinessRules,
    Collections,
    ConsentMethodValues,
    Fields,
    LanguageValues,
    PolicyVersionValues,
    UserRoleValues,
    ValidationLimits,
)
from utils.function_options import DEFAULT_OPTIONS
from utils.helpers import create_success_response, sanitized_text

logger = logging.getLogger(__name__)

_db = None


def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db
    if _db is None:
        from firebase_admin import firestore

        _db = firestore.client()
    return _db


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP."""
    from firebase_admin import firestore

    return firestore.SERVER_TIMESTAMP


def _get_firestore_increment(n: int):
    """Return a Firestore Increment sentinel for atomic counter updates."""
    from firebase_admin import firestore

    return firestore.Increment(n)


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Create the Firestore user document server-side after Firebase Auth sign-in/sign-up.

    Server controls all legal-compliance fields (CASL / PIPEDA / Law 25):
      dataProcessingConsent, emailConsent, consentTimestamp, termsAcceptedAt,
      privacyAcceptedAt, consentMethod, privacyPolicyVersion, termsVersion.

    Idempotent: safe to call on every login — no-ops if doc already exists.

    Request data:
        - name: string (required — display name)
        - preferredLanguage: 'en' | 'fr' (optional, defaults to 'en')
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    email = req.auth.token.get("email", "")
    data = req.data or {}

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    doc = user_ref.get()
    if doc.exists:
        return create_success_response({"created": False, "existing": True})

    # Validate and sanitize name
    name_raw = data.get(Fields.NAME, "").strip()
    if not name_raw:
        # Fall back to email prefix as display name
        name_raw = email.split("@")[0] if email else "User"
    name = sanitized_text(name_raw)[: ValidationLimits.MAX_NAME_LENGTH]
    if len(name) < ValidationLimits.MIN_NAME_LENGTH:
        name = "User"

    # Validate preferredLanguage
    lang = data.get(Fields.PREFERRED_LANGUAGE, LanguageValues.ENGLISH)
    if lang not in LanguageValues.ALL:
        lang = LanguageValues.ENGLISH

    server_ts = get_server_timestamp()

    user_ref.set({
        Fields.UID: user_id,
        Fields.EMAIL: email,
        Fields.NAME: name,
        Fields.ROLES: [UserRoleValues.BUYER],
        Fields.CREATED_AT: server_ts,
        Fields.PREFERRED_LANGUAGE: lang,
        # === LEGAL COMPLIANCE — server-only (CASL / PIPEDA / Law 25) ===
        Fields.DATA_PROCESSING_CONSENT: True,
        Fields.EMAIL_CONSENT: True,
    Fields.MARKETING_OPT_IN: bool(data.get(Fields.MARKETING_OPT_IN, False)),  # CASL: explicit opt-in required
        Fields.CONSENT_TIMESTAMP: server_ts,
        Fields.TERMS_ACCEPTED_AT: server_ts,
        Fields.PRIVACY_ACCEPTED_AT: server_ts,
        Fields.CONSENT_METHOD: ConsentMethodValues.SIGNUP,
        Fields.PRIVACY_POLICY_VERSION: PolicyVersionValues.DEFAULT,
        Fields.TERMS_VERSION: PolicyVersionValues.DEFAULT,
    })

    logger.info("Created user profile server-side for uid=%s", user_id)
    return create_success_response({"created": True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Update user profile fields including tax exemption.

    NOTE: Stripe Tax will validate the GST number during checkout.
    We only do basic format validation here.

    Request data:
        - taxExemption: {gstNumber: "123456789RT0001"} | null (optional)
        - address: Address object (optional)
        - name: string (optional)
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data

    # Build update data
    update_data = {
        Fields.UPDATED_AT: get_server_timestamp(),
    }

    # Handle tax exemption update
    if Fields.TAX_EXEMPTION in data:
        # Rate limiting: 3 tax exemption changes per day per user
        from services.rate_limiter import RateLimiter

        _limiter = RateLimiter(get_db())
        allowed, msg = _limiter.check_rate_limit(
            identifier=f"{user_id}_tax_exemption",
            action="update_tax_exemption",
            max_requests=3,
            window_minutes=1440,  # 24 hours
            fail_closed=True,
        )
        if not allowed:
            raise https_fn.HttpsError(
                "resource-exhausted", "Too many tax exemption updates. Please try again tomorrow."
            )

        tax_exemption = data[Fields.TAX_EXEMPTION]

        if tax_exemption is None:
            # Remove tax exemption
            update_data[Fields.TAX_EXEMPTION] = None
        else:
            gst_number = tax_exemption.get(Fields.GST_NUMBER, "").strip().upper()

            # Basic format validation only
            # Stripe Tax will do full validation during checkout
            import re

            if gst_number and not re.match(BusinessRules.GST_NUMBER_REGEX, gst_number):
                raise https_fn.HttpsError("invalid-argument", "Invalid GST number format. Expected: 123456789RT0001")

            # Store the GST number - Stripe will validate it
            update_data[Fields.TAX_EXEMPTION] = {
                Fields.GST_NUMBER: gst_number,
                Fields.UPDATED_AT: get_server_timestamp(),
            }

    # Handle address update
    if Fields.ADDRESS in data:
        from models.base import Address

        try:
            address = Address(**data[Fields.ADDRESS])
            update_data[Fields.ADDRESS] = address.model_dump()
        except Exception as e:
            logger.error(f"Address validation error: {e}")
            raise https_fn.HttpsError(
                "invalid-argument", "Invalid address. Please check all fields and try again."
            ) from e

    # Handle name update
    if Fields.NAME in data:
        name_raw = data.get(Fields.NAME)
        if not isinstance(name_raw, str):
            raise https_fn.HttpsError("invalid-argument", "Name must be a string")
        name = sanitized_text(name_raw.strip())[: ValidationLimits.MAX_NAME_LENGTH]
        if len(name) < ValidationLimits.MIN_NAME_LENGTH or len(name) > ValidationLimits.MAX_NAME_LENGTH:
            raise https_fn.HttpsError(
                "invalid-argument",
                f"Name must be between {ValidationLimits.MIN_NAME_LENGTH} and {ValidationLimits.MAX_NAME_LENGTH} characters",
            )
        update_data[Fields.NAME] = name

    # Handle preferredLanguage update (Quebec Bill 96 / CASL compliance)
    if Fields.PREFERRED_LANGUAGE in data:
        lang = data[Fields.PREFERRED_LANGUAGE]
        if lang not in LanguageValues.ALL:
            raise https_fn.HttpsError("invalid-argument", f"Invalid language. Must be one of: {list(LanguageValues.ALL)}")
        update_data[Fields.PREFERRED_LANGUAGE] = lang

    # Update user document
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_ref.update(update_data)

    return create_success_response(
        {
            "updated": True,
            "fields": list(update_data.keys()),
        }
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Get current user's profile including tax exemption status."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()

    return create_success_response(
        {
            Fields.UID: user_id,
            Fields.EMAIL: user_data.get(Fields.EMAIL),
            Fields.NAME: user_data.get(Fields.NAME),
            Fields.ADDRESS: user_data.get(Fields.ADDRESS),
            Fields.TAX_EXEMPTION: user_data.get(Fields.TAX_EXEMPTION),
            Fields.ROLES: user_data.get(Fields.ROLES, [UserRoleValues.BUYER]),
            Fields.CREATED_AT: user_data.get(Fields.CREATED_AT),
            Fields.UPDATED_AT: user_data.get(Fields.UPDATED_AT),
        }
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_email_consent(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    CASL compliance: Update user's email marketing consent.

    Canada's Anti-Spam Legislation (CASL) requires:
    - Express consent for commercial electronic messages (CEMs)
    - One-click unsubscribe mechanism
    - Record of consent timestamp and method

    Transactional emails (order confirmations, security alerts) are
    exempt from CASL and are always sent regardless of this setting.

    Request data:
        emailConsent: bool — opt-in (true) or opt-out (false)

    Returns:
        {success: True, emailConsent: bool}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data

    email_consent = data.get(Fields.EMAIL_CONSENT)
    if not isinstance(email_consent, bool):
        raise https_fn.HttpsError("invalid-argument", "emailConsent must be a boolean")

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_ref.update(
        {
            Fields.EMAIL_CONSENT: email_consent,
            Fields.CONSENT_TIMESTAMP: get_server_timestamp(),
            Fields.CONSENT_METHOD: ConsentMethodValues.USER_PREFERENCE if email_consent else ConsentMethodValues.UNSUBSCRIBE,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    return create_success_response(
        {
            Fields.EMAIL_CONSENT: email_consent,
        }
    )


# ============================================================================
# BUYER ADDRESS BOOK MANAGEMENT
# ============================================================================


@https_fn.on_call(**DEFAULT_OPTIONS)
def add_buyer_address(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Add a new address to the buyer's address book."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data

    from models.base import Address

    try:
        address = Address(**data)
    except Exception as e:
        raise https_fn.HttpsError("invalid-argument", f"Invalid address: {e}") from e

    if address.country != COUNTRY_CANADA:
        raise https_fn.HttpsError("invalid-argument", "Shipping addresses must be in Canada")

    address_dict = address.model_dump()

    db = get_db()
    user_ref = db.collection(Collections.USERS).document(user_id)
    addresses_ref = user_ref.collection(Collections.ADDRESSES)

    # Check limit using the cached counter (O(1) instead of O(n) reads)
    user_snap = user_ref.get()
    user_data = user_snap.to_dict() or {}
    address_count = int(user_data.get(Fields.ADDRESS_COUNT, 0))
    if address_count >= 10:
        raise https_fn.HttpsError("resource-exhausted", "Maximum of 10 addresses allowed.")

    # First address is automatically default
    if address_count == 0:
        address_dict[Fields.IS_DEFAULT] = True

    batch = db.batch()

    # If new address is default, unset the current default
    if address_dict.get(Fields.IS_DEFAULT) and address_count > 0:
        existing_defaults = list(addresses_ref.where(Fields.IS_DEFAULT, "==", True).get())
        for doc in existing_defaults:
            batch.update(doc.reference, {Fields.IS_DEFAULT: False})

    new_ref = addresses_ref.document()
    batch.set(new_ref, address_dict)
    # Atomically increment addressCount
    batch.update(user_ref, {Fields.ADDRESS_COUNT: _get_firestore_increment(1)})
    batch.commit()
    address_id = new_ref.id

    return create_success_response({Fields.ADDRESS_ID: address_id})


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_buyer_address(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Update an existing address in the buyer's address book."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    address_id = data.get(Fields.ADDRESS_ID)

    if not address_id:
        raise https_fn.HttpsError("invalid-argument", "addressId is required")

    # Validate syntax by passing through Pydantic
    from models.base import Address

    try:
        address = Address(**data)
    except Exception as e:
        raise https_fn.HttpsError("invalid-argument", f"Invalid address: {e}") from e

    if address.country != COUNTRY_CANADA:
        raise https_fn.HttpsError("invalid-argument", "Shipping addresses must be in Canada")

    address_dict = address.model_dump()

    db = get_db()
    address_ref = (
        db.collection(Collections.USERS).document(user_id).collection(Collections.ADDRESSES).document(address_id)
    )
    doc = address_ref.get()

    if not doc.exists:
        raise https_fn.HttpsError("not-found", "Address not found")

    # Fetch existing addresses once — used in both default-change branches
    existing_addresses = list(db.collection(Collections.USERS).document(user_id).collection(Collections.ADDRESSES).get())

    # If this one is set to default and wasn't before, we must unset others
    if address_dict.get(Fields.IS_DEFAULT) and not doc.to_dict().get(Fields.IS_DEFAULT):
        batch = db.batch()
        for existing_doc in existing_addresses:
            if existing_doc.id != address_id and existing_doc.to_dict().get(Fields.IS_DEFAULT):
                batch.update(existing_doc.reference, {Fields.IS_DEFAULT: False})
        batch.update(address_ref, address_dict)
        batch.commit()
    elif not address_dict.get(Fields.IS_DEFAULT) and doc.to_dict().get(Fields.IS_DEFAULT):
        # Prevent unsetting default if it's the only one
        if len(existing_addresses) > 1:
            # We enforce that AT LEAST one must be default
            # Auto-promote the first non-matching address
            batch = db.batch()
            promoted = False
            for existing_doc in existing_addresses:
                if existing_doc.id != address_id and not promoted:
                    batch.update(existing_doc.reference, {Fields.IS_DEFAULT: True})
                    promoted = True
            batch.update(address_ref, address_dict)
            batch.commit()
        else:
            # Cannot unset default if it's the only one
            address_dict[Fields.IS_DEFAULT] = True
            address_ref.update(address_dict)
    else:
        address_ref.update(address_dict)

    return create_success_response({"updated": True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def delete_buyer_address(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Delete an address from the buyer's address book."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    address_id = data.get(Fields.ADDRESS_ID)

    if not address_id:
        raise https_fn.HttpsError("invalid-argument", "addressId is required")

    db = get_db()
    addresses_ref = db.collection(Collections.USERS).document(user_id).collection(Collections.ADDRESSES)
    address_ref = addresses_ref.document(address_id)
    doc = address_ref.get()

    if not doc.exists:
        raise https_fn.HttpsError("not-found", "Address not found")

    was_default = doc.to_dict().get(Fields.IS_DEFAULT)
    user_ref = db.collection(Collections.USERS).document(user_id)

    # Always use a batch so we atomically decrement addressCount
    batch = db.batch()
    batch.delete(address_ref)
    batch.update(user_ref, {Fields.ADDRESS_COUNT: _get_firestore_increment(-1)})

    # If it was default, promote another address
    if was_default:
        existing_addresses = list(addresses_ref.get())
        promoted = False
        for existing_doc in existing_addresses:
            if existing_doc.id != address_id and not promoted:
                batch.update(existing_doc.reference, {Fields.IS_DEFAULT: True})
                promoted = True

    batch.commit()
    return create_success_response({"deleted": True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def set_default_buyer_address(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Set an address as the default buyer address."""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data
    address_id = data.get(Fields.ADDRESS_ID)

    if not address_id:
        raise https_fn.HttpsError("invalid-argument", "addressId is required")

    db = get_db()
    addresses_ref = db.collection(Collections.USERS).document(user_id).collection(Collections.ADDRESSES)
    address_ref = addresses_ref.document(address_id)
    doc = address_ref.get()

    if not doc.exists:
        raise https_fn.HttpsError("not-found", "Address not found")

    batch = db.batch()
    existing_addresses = addresses_ref.get()
    for existing_doc in existing_addresses:
        if existing_doc.id == address_id:
            batch.update(existing_doc.reference, {Fields.IS_DEFAULT: True})
        elif existing_doc.to_dict().get(Fields.IS_DEFAULT):
            batch.update(existing_doc.reference, {Fields.IS_DEFAULT: False})

    batch.commit()

    return create_success_response({"updated": True})
