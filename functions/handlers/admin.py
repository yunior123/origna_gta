"""
Admin & User Management Handlers
- User role management (admin only)
- Seller suspension
- MFA enrollment/verification
- Account deletion
"""

import hashlib
import hmac
import secrets
import string
import time
from datetime import datetime, timedelta
from typing import Any

import pyotp
from firebase_admin import auth
from firebase_functions import https_fn

from config import Collections
from function_options import DEFAULT_OPTIONS
from schema_constants import ApiKeys, Fields, OrderStatusValues, PayoutStatusValues, UserRoleValues
from utils import create_success_response

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
            'failed-precondition',
            'Admin MFA is not enabled. Please enable MFA before performing sensitive operations.'
        )

    last_mfa_verify = admin_data.get(Fields.LAST_MFA_VERIFY)

    if not last_mfa_verify:
        raise https_fn.HttpsError(
            'permission-denied',
            'MFA verification required. Please verify your MFA code first.'
        )

    # Check if MFA was verified within last 5 minutes
    now = datetime.now()
    time_diff = now - last_mfa_verify.replace(tzinfo=None)

    if time_diff > timedelta(minutes=5):
        raise https_fn.HttpsError(
            'permission-denied',
            'MFA verification expired. Please verify again.'
        )


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
        targetUserId: User ID to modify
        roles: Array of roles ["buyer", "seller", "admin"]

    Returns:
        {success: True, newRoles: [...]}
    """
    if not req.auth:
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    admin_id = req.auth.uid
    data = req.data

    target_user_id_raw = data.get('targetUserId')
    new_roles = data.get(Fields.ROLES, [])

    # Import validation functions
    from utils import sanitized_text

    # Sanitize targetUserId (should be alphanumeric)
    target_user_id = sanitized_text(target_user_id_raw) if target_user_id_raw else None

    if not target_user_id:
        raise https_fn.HttpsError('invalid-argument', 'targetUserId required')

    if not isinstance(new_roles, list):
        raise https_fn.HttpsError('invalid-argument', 'roles must be an array')

    # Validate roles
    valid_roles = ['buyer', 'seller', 'admin']
    for role in new_roles:
        if role not in valid_roles:
            raise https_fn.HttpsError('invalid-argument', f'Invalid role: {role}')

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError('not-found', 'Admin user not found')

    admin_data = admin_doc.to_dict()


    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('permission-denied', 'Admin role required')

    # Require recent MFA verification for sensitive operation
    _require_recent_admin_mfa(admin_data)

    # Cannot modify own roles
    if admin_id == target_user_id:
        raise https_fn.HttpsError('permission-denied', 'Cannot modify your own roles')

    # Get target user
    target_user_ref = get_db().collection(Collections.USERS).document(target_user_id)
    target_user_doc = target_user_ref.get()

    if not target_user_doc.exists:
        raise https_fn.HttpsError('not-found', 'Target user not found')

    target_user_data = target_user_doc.to_dict()
    old_roles = target_user_data.get('roles', [])

    # Update roles
    target_user_ref.update({
        Fields.ROLES: new_roles,
        Fields.UPDATED_AT: get_server_timestamp(),
        Fields.LAST_ROLE_UPDATE: get_server_timestamp(),
        Fields.LAST_ROLE_UPDATE_BY: admin_id
    })

    # Update custom claims in Firebase Auth
    try:
        custom_claims = {
            'admin': 'admin' in new_roles,
            'seller': 'seller' in new_roles,
            'buyer': 'buyer' in new_roles
        }
        auth.set_custom_user_claims(target_user_id, custom_claims)
    except Exception as e:
        print(f'Failed to set custom claims: {str(e)}')

    # Log security alert
    get_db().collection(Collections.SECURITY_ALERTS).add({
        'type': 'role_change',
        'severity': 'medium',
        'adminId': admin_id,
        'targetUserId': target_user_id,
        'oldRoles': old_roles,
        'newRoles': new_roles,
        'timestamp': get_server_timestamp(),
        'resolved': True
    })

    return create_success_response({'newRoles': new_roles})


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    admin_id = req.auth.uid
    data = req.data

    # Import validation functions
    from utils import sanitized_text

    seller_id_raw = data.get(Fields.SELLER_ID)
    reason_raw = data.get(ApiKeys.REASON, 'Policy violation')

    # Sanitize inputs
    seller_id = sanitized_text(seller_id_raw) if seller_id_raw else None
    reason = sanitized_text(reason_raw)[:500]  # Max 500 chars

    if not seller_id:
        raise https_fn.HttpsError('invalid-argument', 'sellerId required')

    # Check admin permissions
    admin_ref = get_db().collection(Collections.USERS).document(admin_id)
    admin_doc = admin_ref.get()

    if not admin_doc.exists:
        raise https_fn.HttpsError('not-found', 'Admin user not found')

    admin_data = admin_doc.to_dict()


    if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('permission-denied', 'Admin role required')

    # Require recent MFA verification
    _require_recent_admin_mfa(admin_data)

    # Cannot suspend admin
    if admin_id == seller_id:
        raise https_fn.HttpsError('permission-denied', 'Cannot suspend yourself')

    # Get seller
    seller_ref = get_db().collection(Collections.USERS).document(seller_id)
    seller_doc = seller_ref.get()

    if not seller_doc.exists:
        raise https_fn.HttpsError('not-found', 'Seller not found')

    seller_doc.to_dict()

    # Suspend seller
    seller_ref.update({
        Fields.SUSPENDED: True,
        Fields.SUSPENDED_AT: get_server_timestamp(),
        Fields.SUSPENDED_BY: admin_id,
        Fields.SUSPENSION_REASON: reason,
        Fields.UPDATED_AT: get_server_timestamp()
    })

    # Deactivate all seller's products (with safety limit)
    products = get_db().collection(Collections.PRODUCTS)\
        .where(Fields.SELLER_ID, '==', seller_id)\
        .where(Fields.IS_ACTIVE, '==', True)\
        .limit(500)\
        .stream()

    product_count = 0
    batch = get_db().batch()
    batch_count = 0

    for product_doc in products:
        batch.update(product_doc.reference, {
            Fields.IS_ACTIVE: False,
            Fields.SUSPENDED_AT: get_server_timestamp()
        })
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
    orders = get_db().collection(Collections.ORDERS)\
        .where(Fields.SELLER_IDS, 'array_contains', seller_id)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING])\
        .limit(200)\
        .stream()

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

        order_batch.update(order_doc.reference, {
            Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
            Fields.CANCELLATION_REASON: f'Seller suspended: {reason}',
            Fields.CANCELLED_BY: admin_id,
            Fields.CANCELLED_AT: get_server_timestamp(),
            Fields.UPDATED_AT: get_server_timestamp()
        })
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
    get_db().collection(Collections.SECURITY_ALERTS).add({
        'type': 'seller_suspended',
        'severity': 'critical',
        'adminId': admin_id,
        Fields.SELLER_ID: seller_id,
        'reason': reason,
        'productsDeactivated': product_count,
        'ordersCancelled': order_count,
        'timestamp': get_server_timestamp(),
        'resolved': True
    })

    return create_success_response({
        'message': 'Seller suspended',
        'productsDeactivated': product_count,
        'ordersCancelled': order_count
    })


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid

    # AUDIT FIX: Rate limit MFA enrollment
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action='mfa_enroll',
        max_requests=3, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    # Check admin role
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()

    if 'admin' not in user_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError('permission-denied', 'Admin role required')

    # Generate TOTP secret
    secret = pyotp.random_base32()

    # Generate one-time backup codes (8 codes, 8 chars each)
    alphabet = string.ascii_uppercase + string.digits
    backup_codes = [
        ''.join(secrets.choice(alphabet) for _ in range(8))
        for _ in range(8)
    ]

    # SECURITY: Hash backup codes before storing (show plaintext only once)
    hashed_backup_codes = [
        hashlib.sha256(code.encode()).hexdigest() for code in backup_codes
    ]

    # AUDIT FIX: Encrypt MFA secret before storing in Firestore
    from crypto_utils import encrypt_mfa_secret
    encrypted_secret = encrypt_mfa_secret(secret)

    # Save to Firestore (temporary, until verified)
    user_ref.update({
        Fields.MFA_SECRET_TEMP: encrypted_secret,
        'mfaBackupCodesTemp': hashed_backup_codes,
        Fields.UPDATED_AT: get_server_timestamp()
    })

    # Generate QR code URL
    totp = pyotp.TOTP(secret)
    email = user_data.get(Fields.EMAIL, user_id)
    qr_code_url = totp.provisioning_uri(
        name=email,
        issuer_name='Origna Marketplace'
    )

    return create_success_response({
        ApiKeys.SECRET: secret,
        ApiKeys.QR_CODE_URL: qr_code_url,
        ApiKeys.PROVISIONING_URI: qr_code_url,
        ApiKeys.BACKUP_CODES: backup_codes,
    })


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    code = req.data.get(ApiKeys.CODE)

    if not code:
        raise https_fn.HttpsError('invalid-argument', 'code required')

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    raw_secret = user_data.get(Fields.MFA_SECRET_TEMP) or user_data.get(Fields.MFA_SECRET)

    if not raw_secret:
        raise https_fn.HttpsError('failed-precondition', 'MFA not enrolled. Call admin_mfa_enroll first.')

    # AUDIT FIX: Decrypt MFA secret (handles legacy plaintext via fallback)
    from crypto_utils import decrypt_mfa_secret, encrypt_mfa_secret
    secret = decrypt_mfa_secret(raw_secret)

    # SECURITY: Check MFA attempt limiting (max 5 attempts per 15 min)
    mfa_attempts = user_data.get('mfaFailedAttempts', 0)
    mfa_lockout_until = user_data.get('mfaLockoutUntil')
    if mfa_lockout_until:
        lockout_time = mfa_lockout_until.replace(tzinfo=None) if hasattr(mfa_lockout_until, 'replace') else mfa_lockout_until
        if datetime.now() < lockout_time:
            raise https_fn.HttpsError('permission-denied', 'Too many failed MFA attempts. Try again later.')

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
        attempt_update = {'mfaFailedAttempts': mfa_attempts + 1}
        if mfa_attempts + 1 >= 5:
            # Lock out for 15 minutes after 5 failures
            attempt_update['mfaLockoutUntil'] = datetime.now() + timedelta(minutes=15)
            attempt_update['mfaFailedAttempts'] = 0
            print(f'SECURITY: MFA lockout triggered for user {user_id}')
        user_ref.update(attempt_update)
        raise https_fn.HttpsError('invalid-argument', 'Invalid MFA code')

    # Reset failed attempts on success
    if mfa_attempts > 0:
        user_ref.update({'mfaFailedAttempts': 0})

    # Enable MFA — AUDIT FIX: re-encrypt secret for permanent storage
    update_data = {
        Fields.MFA_ENABLED: True,
        Fields.MFA_SECRET: encrypt_mfa_secret(secret),
        Fields.LAST_MFA_VERIFY: get_server_timestamp(),
        Fields.UPDATED_AT: get_server_timestamp()
    }

    # Persist backup codes from temp storage
    temp_backup_codes = user_data.get('mfaBackupCodesTemp')
    if temp_backup_codes:
        update_data['mfaBackupCodes'] = temp_backup_codes
        update_data['mfaBackupCodesTemp'] = get_delete_field()

    # Remove temporary secret
    if Fields.MFA_SECRET_TEMP in user_data:
        update_data[Fields.MFA_SECRET_TEMP] = get_delete_field()

    user_ref.update(update_data)

    return create_success_response({'mfaEnabled': True})


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid
    code = req.data.get(ApiKeys.CODE)

    if not code:
        raise https_fn.HttpsError('invalid-argument', 'code required')

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError('not-found', 'User not found')

    user_data = user_doc.to_dict()
    raw_secret = user_data.get(Fields.MFA_SECRET)

    if not raw_secret:
        raise https_fn.HttpsError('failed-precondition', 'MFA not enabled')

    # AUDIT FIX: Decrypt MFA secret (handles legacy plaintext via fallback)
    from crypto_utils import decrypt_mfa_secret
    secret = decrypt_mfa_secret(raw_secret)

    # Verify code before disabling
    totp = pyotp.TOTP(secret)

    if not totp.verify(code, valid_window=1):
        raise https_fn.HttpsError('invalid-argument', 'Invalid MFA code')

    # Disable MFA
    user_ref.update({
        Fields.MFA_ENABLED: False,
        Fields.MFA_SECRET: get_delete_field(),
        Fields.LAST_MFA_VERIFY: get_delete_field(),
        Fields.UPDATED_AT: get_server_timestamp()
    })

    return create_success_response({'mfaEnabled': False})


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
        raise https_fn.HttpsError('unauthenticated', 'User must be authenticated')

    user_id = req.auth.uid

    # AUDIT FIX: Rate limit account deletion
    from rate_limiter import RateLimiter
    _limiter = RateLimiter(get_db())
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action='delete_account',
        max_requests=1, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError('resource-exhausted', msg)

    # Check if user has pending orders or payouts (with limit)
    pending_orders = get_db().collection(Collections.ORDERS)\
        .where(Fields.USER_ID, '==', user_id)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING, OrderStatusValues.SHIPPED])\
        .limit(1)\
        .stream()

    # Convert to list with safety check
    pending_orders_list = list(pending_orders)
    if pending_orders_list:
        raise https_fn.HttpsError(
            'failed-precondition',
            'Cannot delete account with pending orders. Please wait for orders to complete.'
        )

    # Check if user is a seller with active orders to fulfill
    active_sales = get_db().collection(Collections.ORDERS)\
        .where(Fields.SELLER_IDS, 'array-contains', user_id)\
        .where(Fields.ORDER_STATUS, 'in', [OrderStatusValues.PENDING, OrderStatusValues.CONFIRMED, OrderStatusValues.PROCESSING, OrderStatusValues.SHIPPED])\
        .limit(1)\
        .stream()

    if any(active_sales):
        raise https_fn.HttpsError(
            'failed-precondition',
            'Cannot delete account with active sales to fulfill. Please complete your orders first.'
        )

    pending_payouts = get_db().collection(Collections.PAYOUTS)\
        .where(Fields.SELLER_ID, '==', user_id)\
        .where(Fields.STATUS, '==', PayoutStatusValues.PENDING)\
        .limit(1)\
        .stream()

    if any(pending_payouts):
        raise https_fn.HttpsError(
            'failed-precondition',
            'Cannot delete account with pending payouts. Please contact support.'
        )

    # Anonymize user data
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_ref.update({
        Fields.EMAIL: f'deleted_{user_id}@anonymized.local',
        Fields.NAME: '[Deleted User]',
        Fields.ADDRESS: get_delete_field(),
        Fields.STRIPE_ACCOUNT_ID: get_delete_field(),
        'deleted': True,
        Fields.DELETED_AT: get_server_timestamp()
    })

    # Deactivate products (with limit and batch)
    products = get_db().collection(Collections.PRODUCTS)\
        .where(Fields.SELLER_ID, '==', user_id)\
        .limit(500)\
        .stream()

    product_batch = get_db().batch()
    product_batch_count = 0

    for product_doc in products:
        product_batch.update(product_doc.reference, {
            Fields.IS_ACTIVE: False,
            Fields.DELETED_AT: get_server_timestamp()
        })
        product_batch_count += 1

        if product_batch_count >= 500:
            product_batch.commit()
            product_batch = get_db().batch()
            product_batch_count = 0

    if product_batch_count > 0:
        product_batch.commit()

    # Delete cart and favorites (with limits)
    cart_docs = get_db().collection(Collections.USERS).document(user_id).collection(Collections.CART).limit(500).stream()
    cart_batch = get_db().batch()
    cart_count = 0

    for doc in cart_docs:
        cart_batch.delete(doc.reference)
        cart_count += 1
        if cart_count >= 500:
            cart_batch.commit()
            cart_batch = get_db().batch()
            cart_count = 0

    if cart_count > 0:
        cart_batch.commit()

    favorites_docs = get_db().collection(Collections.USERS).document(user_id).collection(Collections.FAVORITES).limit(500).stream()
    fav_batch = get_db().batch()
    fav_count = 0

    for doc in favorites_docs:
        fav_batch.delete(doc.reference)
        fav_count += 1
        if fav_count >= 500:
            fav_batch.commit()
            fav_batch = get_db().batch()
            fav_count = 0

    if fav_count > 0:
        fav_batch.commit()

    # Delete Firebase Auth user
    try:
        auth.delete_user(user_id)
    except Exception as e:
        print(f'Failed to delete Auth user: {str(e)}')

    return create_success_response({'message': 'Account deleted successfully'})
