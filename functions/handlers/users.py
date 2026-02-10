"""
User Management Handlers
- User profile updates
- Tax exemption management

NOTE: Stripe Tax handles GST validation and B2B exemption automatically.
We only store the GST number - Stripe validates it during checkout.
"""

from typing import Any

from firebase_functions import https_fn

from utils.function_options import DEFAULT_OPTIONS
from schema_constants import BusinessRules, Collections, Fields, UserRoleValues, ValidationLimits
from utils.helpers import create_success_response, sanitized_text

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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

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
            action='update_tax_exemption',
            max_requests=3,
            window_minutes=1440,  # 24 hours
            fail_closed=True
        )
        if not allowed:
            raise https_fn.HttpsError('resource-exhausted',
                'Too many tax exemption updates. Please try again tomorrow.')

        tax_exemption = data[Fields.TAX_EXEMPTION]

        if tax_exemption is None:
            # Remove tax exemption
            update_data[Fields.TAX_EXEMPTION] = None
        else:
            gst_number = tax_exemption.get(Fields.GST_NUMBER, '').strip().upper()

            # Basic format validation only
            # Stripe Tax will do full validation during checkout
            import re
            if gst_number and not re.match(BusinessRules.GST_NUMBER_REGEX, gst_number):
                raise https_fn.HttpsError(
                    'invalid-argument',
                    'Invalid GST number format. Expected: 123456789RT0001'
                )

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
            raise https_fn.HttpsError('invalid-argument', f'Invalid address: {str(e)}') from e

    # Handle name update
    if Fields.NAME in data:
        name_raw = data.get(Fields.NAME)
        if not isinstance(name_raw, str):
            raise https_fn.HttpsError('invalid-argument', 'Name must be a string')
        name = sanitized_text(name_raw.strip())[:ValidationLimits.MAX_NAME_LENGTH]
        if len(name) < ValidationLimits.MIN_NAME_LENGTH or len(name) > ValidationLimits.MAX_NAME_LENGTH:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'Name must be between {ValidationLimits.MIN_NAME_LENGTH} and {ValidationLimits.MAX_NAME_LENGTH} characters'
            )
        update_data[Fields.NAME] = name

    # Update user document
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_ref.update(update_data)

    return create_success_response({
        'updated': True,
        'fields': list(update_data.keys()),
    })


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_user_profile(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Get current user's profile including tax exemption status."""
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()

    return create_success_response({
        Fields.UID: user_id,
        Fields.EMAIL: user_data.get(Fields.EMAIL),
        Fields.NAME: user_data.get(Fields.NAME),
        Fields.ADDRESS: user_data.get(Fields.ADDRESS),
        Fields.TAX_EXEMPTION: user_data.get(Fields.TAX_EXEMPTION),
        Fields.ROLES: user_data.get(Fields.ROLES, [UserRoleValues.BUYER]),
        Fields.CREATED_AT: user_data.get(Fields.CREATED_AT),
        Fields.UPDATED_AT: user_data.get(Fields.UPDATED_AT),
    })
