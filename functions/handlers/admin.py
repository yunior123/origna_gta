"""
Admin & User Management Handlers
- User role management (admin only)
- Seller suspension
- MFA enrollment/verification
- Account deletion
"""

import hashlib
import hmac
import logging
import secrets
import string
import time
from datetime import UTC, datetime, timedelta
from typing import Any

import pyotp
import stripe
from firebase_admin import auth
from firebase_functions import https_fn

from schema_constants import (
    APP_NAME,
    ApiKeys,
    BusinessRules,
    Collections,
    Fields,
    OrderStatusValues,
    PayoutStatusValues,
    SecurityAlertTypes,
    SeverityLevels,
    UserRoleValues,
)
from services.rate_limiter import RateLimiter
from utils.function_options import DEFAULT_OPTIONS
from utils.helpers import create_success_response

logger = logging.getLogger(__name__)

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


def get_firestore():
    """Get Firestore module (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore


def get_delete_field():
    """Get Firestore DELETE_FIELD (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore.DELETE_FIELD


def _require_recent_admin_mfa(admin_data: dict[str, Any]) -> None:
    """
    Requires admin to have verified MFA within the last 5 minutes.

    Args:
        admin_data: Admin user document data

    Raises:
        https_fn.HttpsError: If MFA not verified or expired
    """
    if not admin_data.get(Fields.MFA_ENABLED, False):
        raise https_fn.HttpsError(
            "failed-precondition", "Admin MFA is not enabled. Please enable MFA before performing sensitive operations."
        )

    last_mfa_verify = admin_data.get(Fields.LAST_MFA_VERIFY)

    if not last_mfa_verify:
        raise https_fn.HttpsError("permission-denied", "MFA verification required. Please verify your MFA code first.")

    # Check if MFA was verified within allowed window
    now = datetime.now(UTC)
    # Firestore timestamps are UTC — compare in UTC
    last_mfa_utc = last_mfa_verify.replace(tzinfo=UTC) if last_mfa_verify.tzinfo is None else last_mfa_verify
    time_diff = now - last_mfa_utc

    if time_diff > timedelta(minutes=BusinessRules.MFA_VERIFICATION_VALIDITY_MINUTES):
        raise https_fn.HttpsError("permission-denied", "MFA verification expired. Please verify again.")


@https_fn.on_call(**DEFAULT_OPTIONS)
def update_user_roles(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Updates user roles (admin only with MFA).

    Security:
    - Admin only
    - Requires recent MFA verification (< 5 min)
    - Cannot modify own roles
    - Logs all role changes in security_alerts

    Request data:
        targetUserId (or userId): User ID to modify
        add: Array of roles to add (optional)
        remove: Array of roles to remove (optional)
        reason: Reason for change (optional)

    Returns:
        {success: True, newRoles: [...]}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    admin_id = req.auth.uid

    # AUDIT FIX #39: Rate limit role changes to prevent abuse
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=admin_id, action="update_user_roles", max_requests=10, window_minutes=5, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    data = req.data

    # Accept both 'targetUserId' and 'userId' as parameter names
    target_user_id_raw = data.get(Fields.TARGET_USER_ID) or data.get(Fields.USER_ID)
    # Support both patterns: full 'roles' list OR incremental 'add'/'remove'
    roles_to_add = data.get(ApiKeys.ADD, [])
    roles_to_remove = data.get(ApiKeys.REMOVE, [])
    reason = data.get(ApiKeys.REASON, "No reason provided")

    # Import validation functions
    from utils.helpers import sanitized_text

    # Sanitize targetUserId (should be alphanumeric)
    target_user_id = sanitized_text(target_user_id_raw) if target_user_id_raw else None

    if not target_user_id:
        raise https_fn.HttpsError("invalid-argument", "targetUserId required")

    if not isinstance(roles_to_add, list) or not isinstance(roles_to_remove, list):
        raise https_fn.HttpsError("invalid-argument", "add and remove must be arrays")

    # Validate roles
    for role in roles_to_add + roles_to_remove:
        if role not in UserRoleValues.ALL:
            raise https_fn.HttpsError("invalid-argument", f"Invalid role: {role}")

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError("not-found", "Admin user not found")

    admin_data = admin_doc.to_dict()

    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    # Require recent MFA verification for sensitive operation
    _require_recent_admin_mfa(admin_data)

    # Cannot modify own roles
    if admin_id == target_user_id:
        raise https_fn.HttpsError("permission-denied", "Cannot modify your own roles")

    # Get target user
    target_user_ref = get_db().collection(Collections.USERS).document(target_user_id)
    target_user_doc = target_user_ref.get()

    if not target_user_doc.exists:
        raise https_fn.HttpsError("not-found", "Target user not found")

    target_user_data = target_user_doc.to_dict()
    old_roles = target_user_data.get(Fields.ROLES, [])

    # Compute new roles via add/remove delta
    new_roles = list((set(old_roles) | set(roles_to_add)) - set(roles_to_remove))
    # Ensure at least 'buyer' role is always present
    if UserRoleValues.BUYER not in new_roles:
        new_roles.append(UserRoleValues.BUYER)

    # Update roles
    target_user_ref.update(
        {
            Fields.ROLES: new_roles,
            Fields.UPDATED_AT: get_server_timestamp(),
            Fields.LAST_ROLE_UPDATE: get_server_timestamp(),
            Fields.LAST_ROLE_UPDATE_BY: admin_id,
        }
    )

    # Update custom claims in Firebase Auth
    try:
        custom_claims = {role: role in new_roles for role in UserRoleValues.ALL}
        auth.set_custom_user_claims(target_user_id, custom_claims)
    except Exception as e:
        logger.error(f"Failed to set custom claims: {str(e)}")

    # Log security alert
    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.ROLE_CHANGE,
            Fields.SEVERITY: SeverityLevels.MEDIUM,
            Fields.ADMIN_ID: admin_id,
            Fields.TARGET_USER_ID: target_user_id,
            Fields.OLD_ROLES: old_roles,
            Fields.NEW_ROLES: new_roles,
            Fields.REASON: reason,
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: True,
        }
    )

    return create_success_response({Fields.NEW_ROLES: new_roles})


@https_fn.on_call(**DEFAULT_OPTIONS)
def suspend_seller(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Suspends a seller account (admin only with MFA).

    Actions:
    - Marks user as suspended
    - Deactivates all seller's products
    - Cancels all pending/confirmed orders
    - Creates security alert

    Request data:
        sellerId: User ID to suspend
        reason: Suspension reason

    Returns:
        {success: True, message: "Seller suspended"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    admin_id = req.auth.uid
    data = req.data

    # AUDIT FIX: Rate limit seller suspension
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=admin_id, action="suspend_seller", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Import validation functions
    from utils.helpers import sanitized_text

    seller_id_raw = data.get(Fields.SELLER_ID)
    reason_raw = data.get(ApiKeys.REASON, "Policy violation")

    # Sanitize inputs
    seller_id = sanitized_text(seller_id_raw) if seller_id_raw else None
    reason = sanitized_text(reason_raw)[:500]  # Max 500 chars

    if not seller_id:
        raise https_fn.HttpsError("invalid-argument", "sellerId required")

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError("not-found", "Admin user not found")

    admin_data = admin_doc.to_dict()

    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    # Require recent MFA verification
    _require_recent_admin_mfa(admin_data)

    # Cannot suspend admin
    if admin_id == seller_id:
        raise https_fn.HttpsError("permission-denied", "Cannot suspend yourself")

    # Get seller
    seller_ref = get_db().collection(Collections.USERS).document(seller_id)
    seller_doc = seller_ref.get()

    if not seller_doc.exists:
        raise https_fn.HttpsError("not-found", "Seller not found")

    seller_data = seller_doc.to_dict()

    # Verify user has seller role
    if UserRoleValues.SELLER not in seller_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("failed-precondition", "User is not a seller")

    # Suspend seller
    seller_ref.update(
        {
            Fields.SUSPENDED: True,
            Fields.SUSPENDED_AT: get_server_timestamp(),
            Fields.SUSPENDED_BY: admin_id,
            Fields.SUSPENSION_REASON: reason,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    # Deactivate all seller's products (with safety limit)
    products = (
        get_db()
        .collection(Collections.PRODUCTS)
        .where(Fields.SELLER_ID, "==", seller_id)
        .where(Fields.IS_ACTIVE, "==", True)
        .limit(500)
        .stream()
    )

    product_count = 0
    batch = get_db().batch()
    batch_count = 0

    for product_doc in products:
        batch.update(product_doc.reference, {Fields.IS_ACTIVE: False, Fields.SUSPENDED_AT: get_server_timestamp()})
        product_count += 1
        batch_count += 1

        # Commit batch every 500 operations (Firestore limit)
        if batch_count >= 500:
            batch.commit()
            batch = get_db().batch()
            batch_count = 0

    # Commit remaining operations
    if batch_count > 0:
        batch.commit()

    # Cancel all pending/confirmed orders (with safety limit)
    # NOTE: Use denormalized sellerIds field (not nested items.sellerId which Firestore doesn't support)
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.SELLER_IDS, "array_contains", seller_id)
        .where(
            Fields.ORDER_STATUS,
            "in",
            [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING],
        )
        .limit(200)
        .stream()
    )

    order_count = 0
    # Collect product IDs to update in batch
    product_updates = {}  # {productId: quantity_to_restore}

    order_batch = get_db().batch()
    order_batch_count = 0

    for order_doc in orders:
        order_data = order_doc.to_dict()

        # Accumulate stock restorations
        for item in order_data[Fields.ITEMS]:
            if item[Fields.SELLER_ID] == seller_id:
                product_id = item[Fields.PRODUCT_ID]
                quantity = item[Fields.QUANTITY]
                product_updates[product_id] = product_updates.get(product_id, 0) + quantity

        order_batch.update(
            order_doc.reference,
            {
                Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                Fields.CANCELLATION_REASON: f"Seller suspended: {reason}",
                Fields.CANCELLED_BY: admin_id,
                Fields.CANCELLED_AT: get_server_timestamp(),
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        order_count += 1
        order_batch_count += 1

        # Commit every 500 operations
        if order_batch_count >= 500:
            order_batch.commit()
            order_batch = get_db().batch()
            order_batch_count = 0

    # Commit remaining order updates
    if order_batch_count > 0:
        order_batch.commit()

    # Restore stock in batch (avoid N+1 queries)
    if product_updates:
        # Use transaction for stock updates to avoid race conditions
        @get_firestore().transactional
        def restore_stock_batch(transaction):
            product_refs = [get_db().collection(Collections.PRODUCTS).document(pid) for pid in product_updates]
            product_snapshots = [transaction.get(ref) for ref in product_refs]

            for ref, snapshot in zip(product_refs, product_snapshots, strict=False):
                if snapshot.exists:
                    product_data = snapshot.to_dict()
                    current_stock = product_data.get(Fields.STOCK_QUANTITY, 0)
                    quantity_to_restore = product_updates[snapshot.id]
                    transaction.update(ref, {Fields.STOCK_QUANTITY: current_stock + quantity_to_restore})

        # Execute transaction
        transaction = get_db().transaction()
        restore_stock_batch(transaction)

    # Log security alert
    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.SELLER_SUSPENDED,
            Fields.SEVERITY: SeverityLevels.CRITICAL,
            Fields.ADMIN_ID: admin_id,
            Fields.SELLER_ID: seller_id,
            Fields.REASON: reason,
            Fields.PRODUCTS_DEACTIVATED: product_count,
            Fields.ORDERS_CANCELLED: order_count,
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: True,
        }
    )

    return create_success_response(
        {
            ApiKeys.MESSAGE: "Seller suspended",
            Fields.PRODUCTS_DEACTIVATED: product_count,
            Fields.ORDERS_CANCELLED: order_count,
        }
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def unsuspend_seller(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Unsuspends a seller account (admin only with MFA).

    Actions:
    - Marks user as not suspended
    - Reactivates all seller's products that were suspended
    - Creates security alert

    Request data:
        sellerId: User ID to unsuspend
        reason: Unsuspension reason

    Returns:
        {success: True, message: "Seller unsuspended"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    admin_id = req.auth.uid
    data = req.data

    # Rate limit
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=admin_id, action="unsuspend_seller", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    from utils.helpers import sanitized_text

    seller_id_raw = data.get(Fields.SELLER_ID)
    reason_raw = data.get(ApiKeys.REASON, "Admin decision")

    seller_id = sanitized_text(seller_id_raw) if seller_id_raw else None
    reason = sanitized_text(reason_raw)[:500]

    if not seller_id:
        raise https_fn.HttpsError("invalid-argument", "sellerId required")

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError("not-found", "Admin user not found")

    admin_data = admin_doc.to_dict()

    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    # Require recent MFA verification
    _require_recent_admin_mfa(admin_data)

    # Get seller
    seller_ref = get_db().collection(Collections.USERS).document(seller_id)
    seller_doc = seller_ref.get()

    if not seller_doc.exists:
        raise https_fn.HttpsError("not-found", "Seller not found")

    seller_data = seller_doc.to_dict()

    if not seller_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("failed-precondition", "Seller is not currently suspended")

    # Unsuspend seller
    seller_ref.update(
        {
            Fields.SUSPENDED: False,
            Fields.UNSUSPENDED_AT: get_server_timestamp(),
            Fields.UNSUSPENDED_BY: admin_id,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    # Reactivate seller's products that were suspended (not manually deleted)
    # Paginate in batches of 500 (Firestore batch write limit)
    product_count = 0
    max_iterations = 20  # Safety limit to prevent infinite loops (max 10k products)
    iteration_count = 0

    while True:
        iteration_count += 1
        if iteration_count > max_iterations:
            logger.warning(
                f"⚠️ unsuspend_seller hit max iterations ({max_iterations}) for seller {seller_id}, "
                "stopping to prevent infinite loop."
            )
            break

        products = list(
            get_db()
            .collection(Collections.PRODUCTS)
            .where(Fields.SELLER_ID, "==", seller_id)
            .where(Fields.IS_ACTIVE, "==", False)
            .limit(500)
            .stream()
        )

        if not products:
            break

        batch = get_db().batch()
        batch_count = 0

        for product_doc in products:
            product_data = product_doc.to_dict()
            # Only reactivate products that were suspended (not explicitly deleted)
            if product_data.get(Fields.SUSPENDED_AT) and not product_data.get(Fields.DELETED_AT):
                batch.update(
                    product_doc.reference,
                    {
                        Fields.IS_ACTIVE: True,
                        Fields.SUSPENDED_AT: get_delete_field(),
                        Fields.UPDATED_AT: get_server_timestamp(),
                    },
                )
                product_count += 1
                batch_count += 1

        if batch_count > 0:
            batch.commit()
        else:
            # No eligible products in this batch — all were deleted, not suspended
            # If we fetched products but didn't reactivate any, we might get the same 500 again
            # if we don't have a way to filter them out in the query.
            # Currently query is: where(IS_ACTIVE == False).
            # If they are DELETED_AT set, they are still IS_ACTIVE=False.
            # So if we don't update them, we will find them again.
            # We MUST break here to avoid infinite loop if we didn't process any.
            logger.info("No reactivatable products found in batch, stopping loop.")
            break

    # Log security alert
    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.SELLER_UNSUSPENDED,
            Fields.SEVERITY: SeverityLevels.CRITICAL,
            Fields.ADMIN_ID: admin_id,
            Fields.SELLER_ID: seller_id,
            Fields.REASON: reason,
            Fields.PRODUCTS_DEACTIVATED: product_count,
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: True,
        }
    )

    return create_success_response({ApiKeys.MESSAGE: "Seller unsuspended", "productsReactivated": product_count})


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_update_product_stock(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Updates product stock quantity (admin only with MFA).

    Security:
    - Requires admin role + recent MFA
    - Validates quantity is non-negative
    - Logs stock change for audit trail

    Request data:
        productId: Product document ID
        quantity: New stock quantity (0+)
        reason: Reason for stock update

    Returns:
        {success: True, message: "Stock updated"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    admin_id = req.auth.uid
    data = req.data

    # Rate limit
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=admin_id, action="admin_update_stock", max_requests=30, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    product_id = data.get(Fields.PRODUCT_ID)
    quantity = data.get(Fields.STOCK_QUANTITY)
    reason = data.get(ApiKeys.REASON, "Admin stock adjustment")

    if not product_id:
        raise https_fn.HttpsError("invalid-argument", "productId required")

    if quantity is None or not isinstance(quantity, int) or quantity < 0:
        raise https_fn.HttpsError("invalid-argument", "quantity must be a non-negative integer")

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError("not-found", "Admin user not found")

    admin_data = admin_doc.to_dict()

    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    # Require recent MFA verification
    _require_recent_admin_mfa(admin_data)

    # Get product
    product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
    product_doc = product_ref.get()

    if not product_doc.exists:
        raise https_fn.HttpsError("not-found", "Product not found")

    product_data = product_doc.to_dict()
    old_quantity = product_data.get(Fields.STOCK_QUANTITY, 0)

    # Update stock
    product_ref.update({Fields.STOCK_QUANTITY: quantity, Fields.UPDATED_AT: get_server_timestamp()})

    logger.info(
        f"Admin {admin_id} updated stock for product {product_id}: {old_quantity} -> {quantity}. Reason: {reason}"
    )

    return create_success_response(
        {ApiKeys.MESSAGE: "Stock updated", "oldQuantity": old_quantity, "newQuantity": quantity}
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_mfa_enroll(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Enrolls admin in MFA (TOTP).

    Returns:
        {
            success: True,
            secret: "BASE32_SECRET",
            qrCodeUrl: "otpauth://..."
        }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # AUDIT FIX: Rate limit MFA enrollment
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="mfa_enroll", max_requests=3, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Check admin role
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()

    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    # Generate TOTP secret
    secret = pyotp.random_base32()

    # Generate one-time backup codes (8 codes, 8 chars each)
    alphabet = string.ascii_uppercase + string.digits
    backup_codes = ["".join(secrets.choice(alphabet) for _ in range(8)) for _ in range(8)]

    # SECURITY: Hash backup codes with salt before storing (show plaintext only once)
    # Generate unique salt for this user's backup codes
    backup_codes_salt = secrets.token_hex(32)
    hashed_backup_codes = [hashlib.sha256((code + backup_codes_salt).encode()).hexdigest() for code in backup_codes]

    # AUDIT FIX: Encrypt MFA secret before storing in Firestore
    from utils.crypto_utils import encrypt_mfa_secret

    encrypted_secret = encrypt_mfa_secret(secret, associated_data=user_id)

    # AUDIT FIX: Race condition — check if enrollment already in progress or MFA already enabled
    existing_mfa = user_data.get(Fields.MFA_ENABLED, False)
    if existing_mfa:
        raise https_fn.HttpsError("failed-precondition", "MFA is already enabled. Disable it first to re-enroll.")

    # Save to Firestore (temporary, until verified)
    user_ref.update(
        {
            Fields.MFA_SECRET_TEMP: encrypted_secret,
            Fields.MFA_BACKUP_CODES_TEMP: hashed_backup_codes,
            Fields.MFA_BACKUP_CODES_SALT: backup_codes_salt,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    # Generate QR code URL
    totp = pyotp.TOTP(secret)
    email = user_data.get(Fields.EMAIL, user_id)
    qr_code_url = totp.provisioning_uri(name=email, issuer_name=APP_NAME)

    return create_success_response(
        {
            ApiKeys.SECRET: secret,
            ApiKeys.QR_CODE_URL: qr_code_url,
            ApiKeys.PROVISIONING_URI: qr_code_url,
            ApiKeys.BACKUP_CODES: backup_codes,
        }
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_mfa_verify(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Verifies MFA code and enables MFA.

    Request data:
        code: 6-digit TOTP code

    Returns:
        {success: True, mfaEnabled: True}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    code = req.data.get(ApiKeys.CODE)

    if not code:
        raise https_fn.HttpsError("invalid-argument", "code required")

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    raw_secret = user_data.get(Fields.MFA_SECRET_TEMP) or user_data.get(Fields.MFA_SECRET)

    if not raw_secret:
        raise https_fn.HttpsError("failed-precondition", "MFA not enrolled. Call admin_mfa_enroll first.")

    # Decrypt MFA secret (rejects unencrypted plaintext)
    from utils.crypto_utils import decrypt_mfa_secret, encrypt_mfa_secret

    secret = decrypt_mfa_secret(raw_secret, associated_data=user_id)

    # SECURITY: Check MFA attempt limiting (max 5 attempts per 15 min)
    mfa_attempts = user_data.get(Fields.MFA_FAILED_ATTEMPTS, 0)
    mfa_lockout_until = user_data.get(Fields.MFA_LOCKOUT_UNTIL)
    if mfa_lockout_until:
        # Ensure timezone-aware comparison (Firestore timestamps are UTC)
        if hasattr(mfa_lockout_until, "tzinfo") and mfa_lockout_until.tzinfo is None:
            mfa_lockout_until = mfa_lockout_until.replace(tzinfo=UTC)
        if datetime.now(UTC) < mfa_lockout_until:
            raise https_fn.HttpsError("permission-denied", "Too many failed MFA attempts. Try again later.")

    # Verify code with constant-time comparison protection
    totp = pyotp.TOTP(secret)
    start_time = time.monotonic()

    code_valid = totp.verify(code, valid_window=1)

    # SECURITY: Constant-time response to prevent timing attacks
    elapsed = time.monotonic() - start_time
    min_response_time = 0.1  # 100ms minimum
    if elapsed < min_response_time:
        time.sleep(min_response_time - elapsed)

    if not code_valid:
        # Increment failed attempts
        attempt_update = {Fields.MFA_FAILED_ATTEMPTS: mfa_attempts + 1}
        if mfa_attempts + 1 >= BusinessRules.MFA_MAX_ATTEMPTS:
            # Lock out after max failures
            attempt_update[Fields.MFA_LOCKOUT_UNTIL] = datetime.now(UTC) + timedelta(
                minutes=BusinessRules.MFA_LOCKOUT_MINUTES
            )
            attempt_update[Fields.MFA_FAILED_ATTEMPTS] = 0
            logger.info(f"SECURITY: MFA lockout triggered for user {user_id}")
        user_ref.update(attempt_update)
        raise https_fn.HttpsError("unauthenticated", "Invalid MFA code")

    # Reset failed attempts on success
    if mfa_attempts > 0:
        user_ref.update({Fields.MFA_FAILED_ATTEMPTS: 0})

    # Enable MFA — AUDIT FIX: re-encrypt secret for permanent storage with user AAD
    update_data = {
        Fields.MFA_ENABLED: True,
        Fields.MFA_SECRET: encrypt_mfa_secret(secret, associated_data=user_id),
        Fields.LAST_MFA_VERIFY: get_server_timestamp(),
        Fields.UPDATED_AT: get_server_timestamp(),
    }

    # Persist backup codes from temp storage
    temp_backup_codes = user_data.get(Fields.MFA_BACKUP_CODES_TEMP)
    backup_codes_salt = user_data.get(Fields.MFA_BACKUP_CODES_SALT)
    if temp_backup_codes:
        update_data[Fields.MFA_BACKUP_CODES] = temp_backup_codes
        update_data[Fields.MFA_BACKUP_CODES_TEMP] = get_delete_field()
        if backup_codes_salt:
            update_data[Fields.MFA_BACKUP_CODES_SALT] = backup_codes_salt

    # Remove temporary secret
    if Fields.MFA_SECRET_TEMP in user_data:
        update_data[Fields.MFA_SECRET_TEMP] = get_delete_field()

    user_ref.update(update_data)

    return create_success_response({Fields.MFA_ENABLED: True})


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_mfa_disable(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Disables MFA (requires current MFA verification).

    Request data:
        code: 6-digit TOTP code

    Returns:
        {success: True, mfaEnabled: False}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    code = req.data.get(ApiKeys.CODE)

    if not code:
        raise https_fn.HttpsError("invalid-argument", "code required")

    # Rate limit MFA disable attempts (same protection as admin_mfa_verify)
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="mfa_disable", max_requests=3, window_minutes=15, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()

    # Verify caller has admin role
    if UserRoleValues.ADMIN not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError("permission-denied", "Admin role required")

    raw_secret = user_data.get(Fields.MFA_SECRET)

    if not raw_secret:
        raise https_fn.HttpsError("failed-precondition", "MFA not enabled")

    # Decrypt MFA secret (rejects unencrypted plaintext)
    from utils.crypto_utils import decrypt_mfa_secret

    secret = decrypt_mfa_secret(raw_secret, associated_data=user_id)

    # Verify code before disabling with timing protection
    totp = pyotp.TOTP(secret)

    start_time = time.monotonic()
    code_valid = totp.verify(code, valid_window=1)

    # SECURITY: Constant-time response to prevent timing attacks
    elapsed = time.monotonic() - start_time
    min_response_time = 0.1  # 100ms minimum
    if elapsed < min_response_time:
        time.sleep(min_response_time - elapsed)

    if not code_valid:
        raise https_fn.HttpsError("unauthenticated", "Invalid MFA code")

    # Disable MFA
    user_ref.update(
        {
            Fields.MFA_ENABLED: False,
            Fields.MFA_SECRET: get_delete_field(),
            Fields.LAST_MFA_VERIFY: get_delete_field(),
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    return create_success_response({Fields.MFA_ENABLED: False})


@https_fn.on_call(**DEFAULT_OPTIONS)
def admin_mfa_verify_backup(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Verifies MFA backup code (one-time use).
    Used when admin loses access to TOTP device.

    Request data:
        code: 8-character backup code

    Returns:
        {success: True, mfaVerified: True, remainingCodes: 7}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    code = req.data.get(ApiKeys.CODE)

    if not code:
        raise https_fn.HttpsError("invalid-argument", "code required")

    # AUDIT FIX: Rate limit backup code verification attempts
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="mfa_backup_verify", max_requests=3, window_minutes=60, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()

    # Check if MFA is enabled
    if not user_data.get(Fields.MFA_ENABLED, False):
        raise https_fn.HttpsError("failed-precondition", "MFA not enabled")

    # Get stored backup codes and salt
    stored_hashed_codes = user_data.get(Fields.MFA_BACKUP_CODES, [])
    backup_codes_salt = user_data.get(Fields.MFA_BACKUP_CODES_SALT, "")

    if not stored_hashed_codes:
        raise https_fn.HttpsError("failed-precondition", "No backup codes available")

    # Hash the provided code with salt
    hashed_input = hashlib.sha256((code + backup_codes_salt).encode()).hexdigest()

    # Check if code matches using constant-time comparison
    code_found = False
    for _idx, stored_hash in enumerate(stored_hashed_codes):
        if hmac.compare_digest(hashed_input, stored_hash):
            code_found = True

    if not code_found:
        # Log failed attempt
        logger.info(f"SECURITY: Invalid backup code attempt for user {user_id}")
        raise https_fn.HttpsError("invalid-argument", "Invalid backup code")

    # Remove used code (one-time use)
    remaining_codes = [c for c in stored_hashed_codes if not hmac.compare_digest(c, hashed_input)]

    # Update last MFA verify time
    user_ref.update(
        {
            Fields.LAST_MFA_VERIFY: get_server_timestamp(),
            Fields.MFA_BACKUP_CODES: remaining_codes,
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    # Log security alert if low on codes
    if len(remaining_codes) <= 2:
        get_db().collection(Collections.SECURITY_ALERTS).add(
            {
                Fields.TYPE: SecurityAlertTypes.MFA_LOW_BACKUP_CODES,
                Fields.SEVERITY: SeverityLevels.MEDIUM,
                Fields.USER_ID: user_id,
                ApiKeys.REMAINING_CODES: len(remaining_codes),
                Fields.TIMESTAMP: get_server_timestamp(),
                Fields.RESOLVED: False,
            }
        )

    return create_success_response({ApiKeys.MFA_VERIFIED: True, ApiKeys.REMAINING_CODES: len(remaining_codes)})


@https_fn.on_call(**DEFAULT_OPTIONS)
def delete_account(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Deletes user account (GDPR compliance).

    Actions:
    - Deletes Firebase Auth user
    - Anonymizes Firestore data
    - Keeps orders/payouts for accounting (anonymized)

    Returns:
        {success: True, message: "Account deleted"}
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # AUDIT FIX: Rate limit account deletion
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="delete_account", max_requests=1, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Check if user has pending orders or payouts (with limit)
    pending_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.USER_ID, "==", user_id)
        .where(
            Fields.ORDER_STATUS,
            "in",
            [
                OrderStatusValues.PENDING,
                OrderStatusValues.CONFIRMED,
                OrderStatusValues.PROCESSING,
                OrderStatusValues.SHIPPED,
            ],
        )
        .limit(1)
        .stream()
    )

    # Convert to list with safety check
    pending_orders_list = list(pending_orders)
    if pending_orders_list:
        raise https_fn.HttpsError(
            "failed-precondition", "Cannot delete account with pending orders. Please wait for orders to complete."
        )

    # Check if user is a seller with active orders to fulfill
    active_sales = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.SELLER_IDS, "array_contains", user_id)
        .where(
            Fields.ORDER_STATUS,
            "in",
            [
                OrderStatusValues.PENDING,
                OrderStatusValues.CONFIRMED,
                OrderStatusValues.PROCESSING,
                OrderStatusValues.SHIPPED,
            ],
        )
        .limit(1)
        .stream()
    )

    if any(active_sales):
        raise https_fn.HttpsError(
            "failed-precondition",
            "Cannot delete account with active sales to fulfill. Please complete your orders first.",
        )

    pending_payouts = (
        get_db()
        .collection(Collections.PAYOUTS)
        .where(Fields.SELLER_ID, "==", user_id)
        .where(Fields.STATUS, "==", PayoutStatusValues.PENDING)
        .limit(1)
        .stream()
    )

    if any(pending_payouts):
        raise https_fn.HttpsError(
            "failed-precondition", "Cannot delete account with pending payouts. Please contact support."
        )

    # Anonymize user data
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()
    user_data = user_doc.to_dict() if user_doc.exists else {}

    # GDPR: Delete Stripe Connect account before anonymizing Firestore
    stripe_account_id = user_data.get(Fields.STRIPE_ACCOUNT_ID)
    if stripe_account_id:
        try:
            stripe.Account.delete(stripe_account_id)
            logger.info(f"GDPR: Deleted Stripe Connect account {stripe_account_id} for user {user_id}")
        except Exception as stripe_err:
            # Log but don't block — Stripe cleanup is best-effort, flag for manual review
            get_db().collection(Collections.SECURITY_ALERTS).add(
                {
                    Fields.TYPE: SecurityAlertTypes.AUTH_DELETION_FAILED,
                    Fields.SEVERITY: SeverityLevels.HIGH,
                    Fields.USER_ID: user_id,
                    Fields.ERROR_MESSAGE: f"Stripe account deletion failed: {stripe_err}",
                    Fields.TIMESTAMP: get_server_timestamp(),
                    Fields.RESOLVED: False,
                }
            )
            logger.error(f"WARNING: Failed to delete Stripe account {stripe_account_id}: {stripe_err}")

    # GDPR: Delete user files from Firebase Storage
    try:
        from firebase_admin import storage as fb_storage

        bucket = fb_storage.bucket()
        for prefix in [f"products/{user_id}/", f"users/{user_id}/", f"verification/{user_id}/"]:
            blobs = list(bucket.list_blobs(prefix=prefix, max_results=500))
            for blob in blobs:
                blob.delete()
            if blobs:
                logger.info(f"GDPR: Deleted {len(blobs)} files from {prefix}")
    except Exception as storage_err:
        logger.error(f"WARNING: Storage cleanup failed for user {user_id}: {storage_err}")

    user_ref.update(
        {
            Fields.EMAIL: f"deleted_{user_id}@anonymized.local",
            Fields.NAME: "[Deleted User]",
            Fields.ADDRESS: get_delete_field(),
            Fields.STRIPE_ACCOUNT_ID: get_delete_field(),
            Fields.SELLER_PROFILE: get_delete_field(),
            Fields.BUSINESS_ADDRESS: get_delete_field(),
            Fields.BUSINESS_NAME: get_delete_field(),
            Fields.FULL_NAME: get_delete_field(),
            Fields.CUSTOMER_ID: get_delete_field(),
            Fields.AIRWALLEX_ACCOUNT_ID: get_delete_field(),
            Fields.AIRWALLEX_CUSTOMER_ID: get_delete_field(),
            Fields.BANK_DETAILS: get_delete_field(),
            Fields.PHONE_NUMBER: get_delete_field(),
            Fields.MFA_SECRET: get_delete_field(),
            Fields.MFA_SECRET_TEMP: get_delete_field(),
            Fields.MFA_BACKUP_CODES: get_delete_field(),
            Fields.MFA_BACKUP_CODES_TEMP: get_delete_field(),
            Fields.MFA_BACKUP_CODES_SALT: get_delete_field(),
            Fields.DELETED: True,
            Fields.DELETED_AT: get_server_timestamp(),
        }
    )

    # GDPR FIX: Anonymize orders collection (unlink from user but keep for accounting)
    # Create anonymized identifier that can't be reversed
    anonymized_id = f"deleted_{hashlib.sha256(user_id.encode()).hexdigest()[:16]}"

    # Anonymize all orders (paginated — Firestore batch limit is 500)
    # Each iteration changes userId, so query converges naturally
    orders_count = 0
    while True:
        user_orders = list(
            get_db().collection(Collections.ORDERS).where(Fields.USER_ID, "==", user_id).limit(500).stream()
        )

        if not user_orders:
            break

        orders_batch = get_db().batch()
        for order_doc in user_orders:
            orders_batch.update(
                order_doc.reference,
                {
                    Fields.USER_ID: anonymized_id,
                    Fields.CUSTOMER_EMAIL: get_delete_field(),
                    Fields.SHIPPING_ADDRESS: get_delete_field(),
                    Fields.ANONYMIZED_AT: get_server_timestamp(),
                    Fields.ORIGINAL_USER_DELETED: True,
                },
            )
            orders_count += 1

        orders_batch.commit()

    if orders_count > 0:
        logger.info(f"GDPR: Anonymized {orders_count} orders for deleted user {user_id}")

    # Deactivate and anonymize products (GDPR: remove seller PII)
    product_ids_to_remove = []
    while True:
        products = list(
            get_db().collection(Collections.PRODUCTS).where(Fields.SELLER_ID, "==", user_id).limit(500).stream()
        )

        if not products:
            break

        product_batch = get_db().batch()
        for product_doc in products:
            product_batch.update(
                product_doc.reference,
                {
                    Fields.IS_ACTIVE: False,
                    Fields.SELLER_ID: anonymized_id,
                    Fields.SELLER_NAME: "[Deleted Seller]",
                    Fields.SELLER_ADDRESS: get_delete_field(),
                    Fields.DELETED_AT: get_server_timestamp(),
                },
            )
            product_ids_to_remove.append(product_doc.id)

        product_batch.commit()

    # GDPR: Remove products from Algolia search index
    if product_ids_to_remove:
        try:
            from services.algolia_service import delete_products_from_algolia

            delete_products_from_algolia(product_ids_to_remove)
            logger.info(f"GDPR: Removed {len(product_ids_to_remove)} products from Algolia")
        except Exception as algolia_err:
            logger.error(f"WARNING: Algolia cleanup failed: {algolia_err}")

    # GDPR: Anonymize payout records (keep for accounting, remove PII)
    payout_count = 0
    while True:
        user_payouts = list(
            get_db().collection(Collections.PAYOUTS).where(Fields.SELLER_ID, "==", user_id).limit(500).stream()
        )

        if not user_payouts:
            break

        payout_batch = get_db().batch()
        for payout_doc in user_payouts:
            payout_batch.update(
                payout_doc.reference,
                {
                    Fields.SELLER_ID: anonymized_id,
                    Fields.ANONYMIZED_AT: get_server_timestamp(),
                },
            )
            payout_count += 1

        payout_batch.commit()

    if payout_count > 0:
        logger.info(f"GDPR: Anonymized {payout_count} payout records for deleted user {user_id}")

    # Delete cart and favorites (subcollections, paginated)
    while True:
        cart_docs = list(
            get_db().collection(Collections.USERS).document(user_id).collection(Collections.CART).limit(500).stream()
        )
        if not cart_docs:
            break
        cart_batch = get_db().batch()
        for doc in cart_docs:
            cart_batch.delete(doc.reference)
        cart_batch.commit()

    while True:
        favorites_docs = list(
            get_db()
            .collection(Collections.USERS)
            .document(user_id)
            .collection(Collections.FAVORITES)
            .limit(500)
            .stream()
        )
        if not favorites_docs:
            break
        fav_batch = get_db().batch()
        for doc in favorites_docs:
            fav_batch.delete(doc.reference)
        fav_batch.commit()

    # Delete Firebase Auth user
    try:
        auth.delete_user(user_id)
    except Exception as e:
        # CRITICAL: If Auth deletion fails, user can still sign in
        # Mark for manual review but still return success for Firestore anonymization
        get_db().collection(Collections.SECURITY_ALERTS).add(
            {
                Fields.TYPE: SecurityAlertTypes.AUTH_DELETION_FAILED,
                Fields.SEVERITY: SeverityLevels.HIGH,
                Fields.USER_ID: user_id,
                Fields.ERROR_MESSAGE: f"{type(e).__name__}: Auth deletion failed. Check logs.",
                Fields.TIMESTAMP: get_server_timestamp(),
                Fields.RESOLVED: False,
            }
        )
        logger.critical(f"CRITICAL: Failed to delete Auth user {user_id}: {str(e)}")
        raise https_fn.HttpsError(
            "internal", "Account data anonymized but auth deletion failed. Contact support."
        ) from e

    return create_success_response({ApiKeys.MESSAGE: "Account deleted successfully"})


@https_fn.on_call(**DEFAULT_OPTIONS)
def export_my_data(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    PIPEDA compliance: Export all user data.

    Returns all personal data stored about the requesting user,
    including profile, orders, favorites, and consent history.
    Required by PIPEDA for data subject access requests (DSAR).
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required")

    user_id = req.auth.uid

    # Rate limit to prevent abuse
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="export_data", max_requests=3, window_minutes=60, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Collect all user data
    user_doc = get_db().collection(Collections.USERS).document(user_id).get()
    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    # Remove internal fields
    for internal_field in [
        Fields.MFA_SECRET,
        Fields.MFA_SECRET_TEMP,
        Fields.MFA_BACKUP_CODES,
        Fields.MFA_BACKUP_CODES_SALT,
        Fields.MFA_BACKUP_CODES_TEMP,
    ]:
        user_data.pop(internal_field, None)

    # Collect orders
    orders = []
    order_docs = get_db().collection(Collections.ORDERS).where(Fields.USER_ID, "==", user_id).limit(500).stream()
    for order_doc in order_docs:
        order_data = order_doc.to_dict()
        order_data["orderId"] = order_doc.id
        # Serialize datetime objects
        for key, val in order_data.items():
            if hasattr(val, "isoformat"):
                order_data[key] = val.isoformat()
        orders.append(order_data)

    # Collect favorites
    favorites = []
    fav_docs = get_db().collection(Collections.USERS).document(user_id).collection(Collections.FAVORITES).stream()
    for fav_doc in fav_docs:
        favorites.append(fav_doc.id)

    # Serialize user data datetime fields
    for key, val in user_data.items():
        if hasattr(val, "isoformat"):
            user_data[key] = val.isoformat()

    return create_success_response(
        {
            "profile": user_data,
            "orders": orders,
            "favorites": favorites,
            "exportedAt": datetime.now(UTC).isoformat(),
        }
    )


@https_fn.on_call(**DEFAULT_OPTIONS)
def unsubscribe_email(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    CASL compliance: Unsubscribe from all marketing emails.

    Updates user document to set marketingOptIn=false and emailConsent=false.
    Records the unsubscription timestamp for CASL audit trail.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Authentication required")

    user_id = req.auth.uid

    # Rate limit unsubscribe to prevent abuse
    from services.rate_limiter import RateLimiter

    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="unsubscribe_email", max_requests=5, window_minutes=10, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_ref.update(
        {
            Fields.MARKETING_OPT_IN: False,
            Fields.EMAIL_CONSENT: False,
            Fields.UNSUBSCRIBED_AT: get_server_timestamp(),
            Fields.UPDATED_AT: get_server_timestamp(),
        }
    )

    logger.info(f"User {user_id} unsubscribed from marketing emails (CASL)")

    return create_success_response({ApiKeys.MESSAGE: "Successfully unsubscribed from marketing emails"})
