"""
Stripe Payment Handlers
- Checkout session creation
- Payment intent capture
- Webhook processing
- Connect account management
"""

import contextlib
import logging
import secrets
import string as _string
from datetime import UTC, datetime, timedelta
from typing import Any

import stripe
from firebase_functions import https_fn

# Initializing Stripe key lazily in handlers
from config import (
    AUTHORIZATION_VALID_DAYS,
    BASE_URL,
    CATEGORY_TAX_CODE_MAP,
    IS_EMULATOR,
    PLATFORM_FEE_PERCENT,
    STRIPE_TAX_CODE_BASIC_GROCERIES,
    STRIPE_TAX_CODE_CHILDRENS_CLOTHING,
    STRIPE_TAX_CODE_GENERAL,
    STRIPE_TAX_CODE_SHIPPING,
    STRIPE_TAX_ENABLED,
    STRIPE_TAX_EXEMPT_NONE,
    STRIPE_TAX_TYPE_CA_GST_HST,
    get_stripe_secret_key,
    get_stripe_webhook_secret,
)
from schema_constants import (
    ApiKeys,
    AppConfig,
    BusinessRules,
    CartVerificationReasonValues,
    Collections,
    DeliveryStatusValues,
    DeliveryTypeValues,
    DigitalTypeValues,
    ErrorCodeValues,
    Fields,
    LicenseStatusValues,
    OrderEventTypes,
    OrderStatusValues,
    PaymentProviderValues,
    PaymentStatusValues,
    PayoutStatusValues,
    PlaceholderAddressValues,
    ProductLifecycleStatusValues,
    SecurityAlertTypes,
    SeverityLevels,
    SubscriptionStatusValues,
    UserRoleValues,
    ValidationLimits,
    WebhookStatusValues,
)
from models.order_event import OrderEvent
from services.email_service import _t as _email_t
from services.email_service import get_order_confirmation_email, get_seller_notification_email, send_email
from services.pdf_invoice_service import generate_invoice_pdf
from services.rate_limiter import RateLimiter
from services.shipping_service import calculate_shipping_cost, get_tax_rate
from utils.function_options import DEFAULT_OPTIONS, WEBHOOK_OPTIONS

logger = logging.getLogger(__name__)

# stripe.api_key = STRIPE_SECRET_KEY  # Removed global assignment


def _check_premium_from_sub(uid: str) -> bool:
    """P-03 FIX: Check premium status from authoritative subscriptions doc, not cached user field."""
    from utils.premium_check import is_premium_authoritative
    return is_premium_authoritative(uid, db=get_db())


def get_tax_code_for_category(category_id):
    """Map product categories to Stripe tax codes"""
    return CATEGORY_TAX_CODE_MAP.get(category_id)


# Province tax breakdown — derived from BusinessRules.TAX_RATES (single source of truth)
# BusinessRules.TAX_RATES uses percentages (5.0), we convert to ratios (0.05) for math
_PROVINCE_TAX_BREAKDOWN = {
    province: {name: rate / 100.0 for name, rate in taxes.items()}
    for province, taxes in BusinessRules.TAX_RATES.items()
}

# CRITICAL: Set timeout to 30s to prevent Cloud Function timeout (default is 80s)
# Cloud Functions timeout at 60s, so we need Stripe to timeout before that
stripe.max_network_retries = BusinessRules.STRIPE_MAX_NETWORK_RETRIES
# Note: stripe.default_http_client requires stripe-python v3+
# For v2, timeout is set per-request via stripe.api_requestor.APIRequestor
_db = None
_rate_limiter = None
_firestore = None

# CORS is configured in DEFAULT_OPTIONS via function_options.py


def get_db():
    """Get Firestore client (lazy initialization)."""
    global _db, _firestore
    if _db is None:
        try:
            from firebase_admin import firestore as fs

            _firestore = fs
            _db = fs.client()
        except Exception as e:
            raise RuntimeError("Failed to initialize Firestore client") from e
    return _db


def get_rate_limiter():
    """Get RateLimiter instance (lazy initialization)."""
    global _rate_limiter
    if _rate_limiter is None:
        _rate_limiter = RateLimiter(get_db())
    return _rate_limiter


def get_firestore():
    """Get Firestore module (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore


def get_server_timestamp():
    """Get Firestore SERVER_TIMESTAMP (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore.SERVER_TIMESTAMP


def get_transactional():
    """Get Firestore transactional decorator (lazy initialization)."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs
    return _firestore.transactional


def _assert_seller_active(seller_id: str, require_approval: bool = True) -> dict[str, Any]:
    """
    Validates that a seller exists and is active (not suspended).

    Args:
        seller_id: The Firebase Auth UID of the seller
        require_approval: If True, also checks Stripe onboarding completion

    Returns:
        Dict containing seller data

    Raises:
        https_fn.HttpsError: If seller is suspended or not properly onboarded
    """
    seller_ref = get_db().collection(Collections.USERS).document(seller_id)
    seller_doc = seller_ref.get()

    if not seller_doc.exists:
        raise https_fn.HttpsError("not-found", "Seller not found")

    seller_data = seller_doc.to_dict()

    if seller_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("permission-denied", "Seller is suspended and cannot process orders")

    if require_approval:
        if not seller_data.get(Fields.ONBOARDING_COMPLETED, False):
            raise https_fn.HttpsError("failed-precondition", "Seller has not completed onboarding")

        if not seller_data.get(Fields.CHARGES_ENABLED, False):
            raise https_fn.HttpsError("failed-precondition", "Seller is not approved to receive payments")

        if not seller_data.get(Fields.PAYOUTS_ENABLED, False):
            raise https_fn.HttpsError("failed-precondition", "Seller payouts are not yet enabled")

    return seller_data


def _rollback_checkout(validated_items: list, order_ref) -> None:
    """Rollback stock reservation and mark order as failed on checkout failure."""
    try:

        @get_transactional()
        def rollback_stock(transaction):
            # Phase 1: Read ALL product snapshots first
            refs_and_snapshots = []
            for item in validated_items:
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                product_snapshot = product_ref.get(transaction=transaction)
                refs_and_snapshots.append((product_ref, product_snapshot, item[Fields.QUANTITY]))

            # Phase 2: Write ALL updates after all reads
            for ref, snapshot, qty in refs_and_snapshots:
                if snapshot.exists:
                    product_data = snapshot.to_dict()
                    current_stock = product_data.get(Fields.STOCK_QUANTITY, 0)
                    patch = {Fields.STOCK_QUANTITY: current_stock + qty}

                    # BUG-2 FIX: Restore warehouseStock in sync with stockQuantity.
                    # Reverse the drain: add back to the warehouse with the least stock first
                    # (mirrors the drain-fullest-first strategy in reserve_stock_transaction).
                    warehouse_stock: dict = product_data.get(Fields.WAREHOUSE_STOCK) or {}
                    if warehouse_stock:
                        sorted_warehouses = sorted(warehouse_stock.items(), key=lambda kv: kv[1])
                        remaining = qty
                        for wh_id, wh_stock in sorted_warehouses:
                            if remaining <= 0:
                                break
                            restore = min(qty, remaining)
                            patch[f"{Fields.WAREHOUSE_STOCK}.{wh_id}"] = wh_stock + restore
                            # Also restore inventoryLevels subcollection
                            inv_ref = ref.collection(Collections.INVENTORY_LEVELS).document(wh_id)
                            transaction.set(inv_ref, {
                                Fields.AVAILABLE_QUANTITY: wh_stock + restore,
                                Fields.LAST_SYNCED_AT: get_server_timestamp(),
                            }, merge=True)
                            remaining -= restore

                    transaction.update(ref, patch)

        transaction = get_db().transaction()
        rollback_stock(transaction)
    except Exception as rollback_err:
        logger.critical(f"🚨 CRITICAL: Stock rollback failed during checkout rollback: {rollback_err}")

    # Mark order as failed (keep for audit trail instead of deleting)
    try:
        order_ref.update(
            {
                Fields.ORDER_STATUS: OrderStatusValues.FAILED,
                Fields.PAYMENT_STATUS: PaymentStatusValues.PAYMENT_FAILED,
                Fields.CANCELLATION_REASON: "Checkout session creation failed",
                Fields.STOCK_RESTORED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )
    except Exception as order_err:
        logger.critical(f"🚨 CRITICAL: Order status rollback failed: {order_err}")


@https_fn.on_call(**DEFAULT_OPTIONS)
def verify_cart_prices(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    AUDIT FIX: Pre-checkout cart price verification.

    Checks if any cart item prices/stock/availability have changed since the
    user added them. Frontend should call this BEFORE initiating checkout to
    detect stale prices and update the cart UI.

    This prevents the critical bug where a user proceeds to checkout with
    outdated prices, only to get a hard error at payment time.

    Request data:
        items: List of {productId, price, quantity}

    Returns:
        {
            success: True,
            hasChanges: bool,
            priceChanges: [{productId, name, oldPrice, newPrice}],
            stockChanges: [{productId, name, requested, available}],
            removedProducts: [{productId}]
        }
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # Rate limit: 10/min (called before checkout)
    allowed, message = get_rate_limiter().check_rate_limit(
        identifier=req.auth.uid, action="verify_cart_prices", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", message)

    items = req.data.get(Fields.ITEMS, [])
    if not items:
        raise https_fn.HttpsError("invalid-argument", "No items to verify")

    price_changes = []
    stock_changes = []
    removed_products = []

    for item in items:
        product_id = item.get(Fields.PRODUCT_ID)
        client_price = item.get(Fields.PRICE, 0)
        requested_qty = item.get(Fields.QUANTITY, 1)

        if not product_id:
            continue

        product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
        product_doc = product_ref.get()

        if not product_doc.exists:
            removed_products.append({Fields.PRODUCT_ID: product_id})
            continue

        product_data = product_doc.to_dict()

        # Check if product is still active
        if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            removed_products.append(
                {
                    Fields.PRODUCT_ID: product_id,
                    Fields.NAME: product_data.get(Fields.NAME, ""),
                    Fields.REASON: CartVerificationReasonValues.DEACTIVATED,
                }
            )
            continue

        # Check price change (> 1 cent tolerance)
        db_price = product_data.get(Fields.PRICE, 0)
        if abs(db_price - client_price) > 0.01:
            price_changes.append(
                {
                    Fields.PRODUCT_ID: product_id,
                    Fields.NAME: product_data.get(Fields.NAME, ""),
                    ApiKeys.OLD_PRICE: client_price,
                    ApiKeys.NEW_PRICE: db_price,
                }
            )

        # Check stock availability
        stock_qty = product_data.get(Fields.STOCK_QUANTITY, 0)
        if stock_qty < requested_qty:
            stock_changes.append(
                {
                    Fields.PRODUCT_ID: product_id,
                    Fields.NAME: product_data.get(Fields.NAME, ""),
                    ApiKeys.REQUESTED: requested_qty,
                    ApiKeys.AVAILABLE: stock_qty,
                }
            )

    has_changes = len(price_changes) > 0 or len(stock_changes) > 0 or len(removed_products) > 0

    from utils.helpers import create_success_response

    return create_success_response(
        {
            ApiKeys.HAS_CHANGES: has_changes,
            ApiKeys.PRICE_CHANGES: price_changes,
            ApiKeys.STOCK_CHANGES: stock_changes,
            ApiKeys.REMOVED_PRODUCTS: removed_products,
        }
    )


def get_item_tax_rate(item, province):
    """Get tax rate for an item based on category and province"""
    tax_code = item.get(Fields.TAX_CODE)

    # Children's clothing exempt in some provinces
    if tax_code == STRIPE_TAX_CODE_CHILDRENS_CLOTHING and province in BusinessRules.CHILDRENS_CLOTHING_EXEMPT_PROVINCES:
        return 0.0

    # Basic groceries exempt in all provinces
    if tax_code == STRIPE_TAX_CODE_BASIC_GROCERIES:
        return 0.0

    # Default province tax rate
    return get_tax_rate(province)


def calculate_tax_with_stripe(validated_items, shipping_address, shipping_cost_cents, gst_number=None):
    """
    Calculate tax using Stripe Tax API.

    Args:
        gst_number: Canadian GST/HST number for B2B exemption (e.g., '123456789RT0001')

    Returns (tax_amount_cents, tax_breakdown, line_items_with_tax, is_reverse_charge)
    """
    try:
        line_items = []
        for item in validated_items:
            # Get tax code from category mapping
            category_id = item.get(Fields.CATEGORY_ID, 0)
            tax_code = CATEGORY_TAX_CODE_MAP.get(category_id, STRIPE_TAX_CODE_GENERAL)

            line_items.append(
                {
                    "amount": int(item[Fields.PRICE] * 100) * item[Fields.QUANTITY],
                    "reference": item[Fields.PRODUCT_ID],
                    "tax_code": tax_code,
                }
            )

        # Add shipping as line item
        if shipping_cost_cents > 0:
            line_items.append(
                {
                    "amount": shipping_cost_cents,
                    "reference": "shipping",
                    "tax_code": STRIPE_TAX_CODE_SHIPPING,  # Shipping tax code
                }
            )

        # Build customer details
        customer_details = {
            "address": {
                "line1": shipping_address.get(Fields.STREET, ""),
                "city": shipping_address.get(Fields.CITY, ""),
                "state": shipping_address.get(Fields.STATE, ""),
                "postal_code": shipping_address.get(Fields.POSTAL_CODE, ""),
                "country": AppConfig.DEFAULT_COUNTRY_CODE,
            },
            "address_source": "shipping",
        }

        # Add GST number for B2B validation (Stripe will validate and apply reverse charge if valid)
        if gst_number:
            customer_details["tax_id"] = {
                "type": STRIPE_TAX_TYPE_CA_GST_HST,  # Canadian GST/HST
                "value": gst_number,
            }
            customer_details["tax_exempt"] = STRIPE_TAX_EXEMPT_NONE  # Let Stripe determine based on tax_id

        # Call Stripe Tax API
        ensure_stripe_key()
        calculation = stripe.tax.Calculation.create(
            currency=BusinessRules.DEFAULT_CURRENCY,
            customer_details=customer_details,
            line_items=line_items,
        )

        tax_amount_cents = calculation.tax_amount_exclusive
        # Stripe Tax returns amounts in cents — convert to dollars for consistency with manual calc
        STRIPE_TAX_TYPE_MAP = {
            "gst_hst": "GST",
            "gst": "GST",
            "hst": "HST",
            "pst": "PST",
            "qst": "QST",
            "rst": "PST",
        }
        tax_breakdown = {
            STRIPE_TAX_TYPE_MAP.get(detail.tax_type, detail.tax_type.upper()): detail.amount / 100.0
            for detail in calculation.tax_breakdown
        }
        # Also convert tax_amount_cents from the Stripe response (already in cents, rename for clarity)
        tax_amount_cents = calculation.tax_amount_exclusive

        # Build item_taxes from Stripe calculation for consistency
        item_taxes = []
        for line_item in calculation.line_items.data:
            if line_item.reference != "shipping":
                item_taxes.append(
                    {
                        Fields.PRODUCT_ID: line_item.reference,
                        Fields.TAX_CENTS: line_item.amount_tax,
                        Fields.TAX_RATE: (line_item.amount_tax / line_item.amount) if line_item.amount > 0 else 0,
                    }
                )

        # Check if Stripe applied reverse charge (B2B exemption)
        is_reverse_charge = False
        try:
            customer_details = getattr(calculation, "customer_details", None)
            if customer_details:
                is_reverse_charge = getattr(customer_details, "tax_exempt", None) == "reverse_charge"
        except Exception:
            pass

        return tax_amount_cents, tax_breakdown, item_taxes, is_reverse_charge

    except Exception as e:
        logger.error(f"Stripe Tax API error: {e}")
        # Fall back to manual calculation
        return None, None, None, False


# Helper to ensure stripe key is set before operations
def ensure_stripe_key():
    if not stripe.api_key:
        stripe.api_key = get_stripe_secret_key()


# ---------------------------------------------------------------------------
# Coupon validation helpers (used inside create_checkout_session)
# ---------------------------------------------------------------------------

def _coupon_not_expired(coupon_data: dict) -> bool:
    expires_at = coupon_data.get(Fields.EXPIRES_AT)
    if expires_at is None:
        return True
    now_utc = datetime.now(UTC)
    if hasattr(expires_at, "ToDatetime"):
        expires_dt = expires_at.ToDatetime().replace(tzinfo=UTC)
    elif hasattr(expires_at, "astimezone"):
        expires_dt = expires_at.astimezone(UTC)
    else:
        return True
    return now_utc <= expires_dt


def _coupon_within_limits(coupon_data: dict, user_id: str) -> bool:
    max_uses_total = coupon_data.get(Fields.MAX_USES_TOTAL)
    used_count = int(coupon_data.get(Fields.USED_COUNT, 0))
    if max_uses_total is not None and used_count >= int(max_uses_total):
        return False
    coupon_code = coupon_data.get(Fields.COUPON_CODE, "")
    max_uses_per_user = int(coupon_data.get(Fields.MAX_USES_PER_USER, 1))
    if coupon_code:
        use_snap = (
            get_db()
            .collection(Collections.COUPONS)
            .document(coupon_code)
            .collection(Collections.COUPON_USES)
            .document(user_id)
            .get()
        )
        user_count = int(use_snap.to_dict().get("useCount", 0)) if use_snap.exists else 0
        if user_count >= max_uses_per_user:
            return False
    return True


def _coupon_seller_allowed(coupon_data: dict, sellers: set) -> bool:
    coupon_seller_id = coupon_data.get(Fields.SELLER_ID)
    if coupon_seller_id is None:
        return True  # Platform-wide coupon
    return coupon_seller_id in sellers


def _coupon_min_order_met(coupon_data: dict, actual_subtotal_cents: int) -> bool:
    min_order_cents = coupon_data.get(Fields.MIN_ORDER_CENTS)
    if min_order_cents is None:
        return True
    return actual_subtotal_cents >= int(min_order_cents)



    """
    Creates a Stripe Checkout session with server-side validation.

    Security features:
    - Price validation (server-side fetch from Firestore)
    - Stock availability check (atomic transactions)
    - Rate limiting (5 requests per minute per user)
    - Subtotal verification (1% tolerance)
    - Shipping/tax recalculation

    Request data:
        items: List of {productId, quantity, price, name, imageUrl, sellerId}
        shippingAddress: {street, city, province, postalCode, country}
        userId: Firebase Auth UID

    Returns:
        {
            sessionId: Stripe Checkout Session ID
            orderId: Firestore order document ID
            success: True
        }

    Raises:
        https_fn.HttpsError: For validation errors, insufficient stock, etc.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    ensure_stripe_key()

    # Check email verification (skip in emulator mode - tokens may not carry email_verified)
    if not IS_EMULATOR and not req.auth.token.get("email_verified", False):
        raise https_fn.HttpsError("permission-denied", "Please verify your email address before making a purchase.")

    user_id = req.auth.uid
    data = req.data

    # Security: Check if user is suspended
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_snapshot = user_ref.get()
    user_data = user_snapshot.to_dict() if user_snapshot.exists else {}
    if user_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("permission-denied", "Account suspended. Cannot proceed with checkout.")

    # Get GST number for B2B validation (Stripe Tax will validate it)
    tax_exemption = user_data.get(Fields.TAX_EXEMPTION)
    gst_number = tax_exemption.get(Fields.GST_NUMBER) if tax_exemption else None

    # Rate limiting: 5 requests per minute per user
    allowed, message = get_rate_limiter().check_rate_limit(
        identifier=user_id, action="create_checkout", max_requests=5, window_minutes=1, fail_closed=True
    )

    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", message)

    # Validate required fields
    items = data.get(Fields.ITEMS, [])
    shipping_address = data.get(Fields.SHIPPING_ADDRESS, {})
    # Note: 'subtotal' is not in Fields as it's an API parameter (dollars) vs Firestore field (cents)
    client_subtotal = data.get(ApiKeys.SUBTOTAL, 0)

    if not items or len(items) == 0:
        raise https_fn.HttpsError("invalid-argument", "No items in cart")

    # Detect all-digital cart early — bypasses physical shipping/address rules.
    # NOTE: isDigital is re-verified server-side per item during product validation below.
    all_digital = all(item.get(Fields.IS_DIGITAL, False) for item in items)

    if not all_digital:
        if not shipping_address:
            raise https_fn.HttpsError("invalid-argument", "Shipping address required")

        # NORMALIZE: Prefer canonical schema field `state` (province code),
        # but also accept `province` from older clients.
        if Fields.STATE not in shipping_address and "province" in shipping_address:
            shipping_address[Fields.STATE] = shipping_address["province"]

        # Validate shipping address fields
        required_address_fields = [Fields.STREET, Fields.CITY, Fields.POSTAL_CODE, Fields.STATE, Fields.COUNTRY]
        for field in required_address_fields:
            if field not in shipping_address or not shipping_address[field]:
                raise https_fn.HttpsError("invalid-argument", f"Missing required address field: {field}")

        # Validate address field lengths (prevent injection attacks)
        address_length_limits = {
            Fields.STREET: 100,
            Fields.CITY: 50,
            Fields.POSTAL_CODE: 20,
            Fields.STATE: 50,
            Fields.COUNTRY: 50,
        }
        for field, max_length in address_length_limits.items():
            if len(str(shipping_address.get(field, ""))) > max_length:
                raise https_fn.HttpsError("invalid-argument", f"Address field {field} exceeds maximum length")

        # Validate postal code format
        from utils.helpers import validate_postal_code

        postal_code = shipping_address.get(Fields.POSTAL_CODE, "")
        country = shipping_address.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME)

        if country.lower() != "canada":
            raise https_fn.HttpsError("invalid-argument", f"Shipping to {country} is not currently supported")

        try:
            validate_postal_code(postal_code)
        except ValueError as err:
            raise https_fn.HttpsError(
                "invalid-argument", f"Invalid Canadian postal code format: {postal_code}"
            ) from err
    else:
        # All-digital: no physical address needed (worldwide sales).
        # Normalize province from optional address if provided (for tax display only).
        if Fields.STATE not in shipping_address and "province" in shipping_address:
            shipping_address[Fields.STATE] = shipping_address["province"]

    # Validate subtotal is positive number
    if not isinstance(client_subtotal, (int, float)) or client_subtotal <= 0:
        raise https_fn.HttpsError("invalid-argument", "Invalid subtotal: must be positive number")

    # Validate subtotal is reasonable
    if client_subtotal > BusinessRules.MAX_ORDER_AMOUNT_CAD:
        raise https_fn.HttpsError(
            "invalid-argument", f"Subtotal exceeds maximum allowed (${BusinessRules.MAX_ORDER_AMOUNT_CAD:,} CAD)"
        )

    # Validate and calculate actual prices/shipping server-side
    validated_items = []
    actual_subtotal = 0
    sellers = set()
    seller_cache = {}  # Cache seller docs to avoid N+1 reads
    warehouse_cache: dict[str, dict] = {}  # key: "sellerId:warehouseId" → warehouse data

    for item in items:
        # Check quantity limits
        item_quantity = item.get(Fields.QUANTITY, 0)
        if not isinstance(item_quantity, int) or item_quantity <= 0:
            raise https_fn.HttpsError("invalid-argument", f"Item quantity must be a positive integer: {item_quantity}")
        if item_quantity > 100:
            raise https_fn.HttpsError(
                "invalid-argument",
                f"Item quantity exceeds maximum allowed ({ValidationLimits.MAX_ITEM_QUANTITY}): {item_quantity}",
            )

        # Fetch product from Firestore for server-side validation
        product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
        product_doc = product_ref.get()

        if not product_doc.exists:
            raise https_fn.HttpsError("not-found", f"Product {item[Fields.PRODUCT_ID]} not found")

        product_data = product_doc.to_dict()

        # SECURITY: Reject inactive/deactivated products
        if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            raise https_fn.HttpsError(
                "failed-precondition", f"Product {item[Fields.PRODUCT_ID]} is not active and cannot be purchased"
            )

        # SECURITY: Validate seller ID matches product owner
        # Prevents attack where buyer sends item.sellerId != product.sellerId
        # to redirect payments to wrong seller
        db_seller_id = product_data.get(Fields.SELLER_ID)
        client_seller_id = item.get(Fields.SELLER_ID)

        if db_seller_id != client_seller_id:
            raise https_fn.HttpsError(
                "invalid-argument",
                f"Seller ID mismatch for product {item[Fields.PRODUCT_ID]}: expected {db_seller_id}, got {client_seller_id}",
            )

        # Server-side price validation (prevent client tampering)
        db_price = product_data[Fields.PRICE]
        client_price = item[Fields.PRICE]

        # Allow 1 cent tolerance for floating point errors
        # AUDIT FIX: Return structured error with updated price so frontend can auto-refresh cart
        if abs(db_price - client_price) > 0.01:
            raise https_fn.HttpsError(
                "invalid-argument",
                f"Price changed for {product_data.get(Fields.NAME, item[Fields.PRODUCT_ID])}: "
                f"was ${client_price:.2f}, now ${db_price:.2f}. Please refresh your cart.",
                details={
                    ApiKeys.CODE: ErrorCodeValues.PRICE_CHANGED,
                    Fields.PRODUCT_ID: item[Fields.PRODUCT_ID],
                    ApiKeys.PRODUCT_NAME: product_data.get(Fields.NAME, ""),
                    ApiKeys.OLD_PRICE: client_price,
                    ApiKeys.NEW_PRICE: db_price,
                },
            )

        # Check stock availability (skip if seller allows backorders)
        stock_quantity = product_data.get(Fields.STOCK_QUANTITY, 0)
        allow_backorder = product_data.get(Fields.INVENTORY, {}).get(Fields.ALLOW_BACKORDER, False)
        if stock_quantity < item[Fields.QUANTITY] and not allow_backorder:
            raise https_fn.HttpsError(
                "resource-exhausted",
                f"Insufficient stock for product {item[Fields.PRODUCT_ID]} ({item[Fields.NAME]}): {stock_quantity} available, {item[Fields.QUANTITY]} requested",
            )

        # Check seller status (using cache to avoid N+1 reads)
        seller_id = item[Fields.SELLER_ID]
        sellers.add(seller_id)

        # Prevent sellers from buying their own products
        if seller_id == user_id:
            raise https_fn.HttpsError(
                "invalid-argument", f"You cannot purchase your own product: {product_data[Fields.NAME]}"
            )

        # Fetch seller profile (cached to avoid N+1)
        if seller_id not in seller_cache:
            seller_ref = get_db().collection(Collections.USERS).document(seller_id)
            seller_doc = seller_ref.get()
            seller_cache[seller_id] = seller_doc.to_dict() if seller_doc.exists else {}
        seller_data = seller_cache[seller_id]

        # Validate seller is active using cached data (avoids extra Firestore read)
        if not seller_data:
            raise https_fn.HttpsError("not-found", f"Seller {seller_id} not found")
        if seller_data.get(Fields.SUSPENDED, False):
            raise https_fn.HttpsError("permission-denied", f"Seller {seller_id} is suspended and cannot process orders")
        if not seller_data.get(Fields.ONBOARDING_COMPLETED, False):
            raise https_fn.HttpsError("failed-precondition", f"Seller {seller_id} has not completed onboarding")
        if not seller_data.get(Fields.CHARGES_ENABLED, False):
            raise https_fn.HttpsError("failed-precondition", f"Seller {seller_id} is not approved to receive payments")
        seller_profile = seller_data.get(Fields.SELLER_PROFILE, {})
        if not isinstance(seller_profile, dict):
            seller_profile = {}

        image_urls = product_data.get(Fields.IMAGE_URLS, [])
        if not isinstance(image_urls, list):
            image_urls = [str(image_urls)]

        # Address waterfall: warehouse → sellerAddress → businessAddress → user address → placeholder
        raw_seller_address = None

        # Step 1: Warehouse address (if product uses warehouses)
        p_warehouse_ids = product_data.get(Fields.WAREHOUSE_IDS) or []
        p_warehouse_stock = product_data.get(Fields.WAREHOUSE_STOCK) or {}
        if p_warehouse_ids and p_warehouse_stock:
            # Pick primary warehouse (most stock)
            primary_wh_id = max(p_warehouse_stock, key=lambda k: p_warehouse_stock.get(k, 0), default=None)
            if primary_wh_id:
                cache_key = f"{seller_id}:{primary_wh_id}"
                if cache_key not in warehouse_cache:
                    try:
                        wh_doc = (
                            get_db()
                            .collection(Collections.USERS)
                            .document(seller_id)
                            .collection(Collections.WAREHOUSES)
                            .document(primary_wh_id)
                            .get()
                        )
                        warehouse_cache[cache_key] = wh_doc.to_dict() if wh_doc.exists else {}
                    except Exception:
                        warehouse_cache[cache_key] = {}
                wh_data = warehouse_cache[cache_key]
                wh_addr = wh_data.get("address") or {} if wh_data else {}
                if wh_addr.get(Fields.CITY):
                    raw_seller_address = wh_addr

        # Step 2: Product's sellerAddress
        if not raw_seller_address or not raw_seller_address.get(Fields.STREET):
            candidate = product_data.get(Fields.SELLER_ADDRESS, {})
            if isinstance(candidate, dict) and candidate.get(Fields.STREET):
                raw_seller_address = candidate

        # Step 3: Seller profile businessAddress
        if not raw_seller_address or not raw_seller_address.get(Fields.STREET):
            candidate = seller_profile.get(Fields.BUSINESS_ADDRESS, {})
            if isinstance(candidate, dict) and candidate.get(Fields.STREET):
                raw_seller_address = candidate

        # Step 4: Seller user address
        if not raw_seller_address or not raw_seller_address.get(Fields.STREET):
            candidate = seller_data.get(Fields.ADDRESS, {})
            if isinstance(candidate, dict) and candidate.get(Fields.STREET):
                raw_seller_address = candidate

        # Step 5: Placeholder (last resort)
        if not raw_seller_address or not raw_seller_address.get(Fields.STREET):
            raw_seller_address = {
                Fields.STREET: PlaceholderAddressValues.UNKNOWN_TEXT,
                Fields.CITY: PlaceholderAddressValues.UNKNOWN_TEXT,
                Fields.STATE: PlaceholderAddressValues.DEFAULT_STATE,
                Fields.POSTAL_CODE: PlaceholderAddressValues.DEFAULT_POSTAL_CODE,
                Fields.COUNTRY: PlaceholderAddressValues.DEFAULT_COUNTRY,
            }

        validated_item = {
            Fields.PRODUCT_ID: item[Fields.PRODUCT_ID],
            Fields.NAME: product_data[Fields.NAME],
            Fields.DESCRIPTION: product_data.get(Fields.DESCRIPTION, ""),
            Fields.PRICE: db_price,
            Fields.QUANTITY: item[Fields.QUANTITY],
            Fields.SELLER_ID: seller_id,
            Fields.IMAGE_URLS: image_urls if image_urls else [""],
            Fields.IS_DIGITAL: product_data.get(Fields.IS_DIGITAL, False),
            Fields.CATEGORY_ID: product_data.get(Fields.CATEGORY_ID, 0),
            Fields.TAX_CODE: get_tax_code_for_category(product_data.get(Fields.CATEGORY_ID, 0)),
            Fields.STATUS: DeliveryStatusValues.PENDING,  # Per-item status: pending | shipped | delivered | refunded
            Fields.TRACKING_NUMBER: None,
            Fields.CARRIER: None,
            Fields.SHIPPED_AT: None,
            Fields.DELIVERED_AT: None,
            Fields.CONFIRMED_BY_BUYER: False,
            Fields.FREE_SHIPPING: product_data.get(Fields.FREE_SHIPPING, False),
            Fields.IS_LOCAL_DELIVERY_ONLY: product_data.get(Fields.IS_LOCAL_DELIVERY_ONLY, False),
            Fields.IS_PERISHABLE: product_data.get(Fields.IS_PERISHABLE, False),
            Fields.DELIVERY_OPTIONS: product_data.get(Fields.DELIVERY_OPTIONS, []),
            Fields.SELLER_ADDRESS: raw_seller_address,
            # Weight & dimensions for accurate shipping calculation (volumetric surcharge)
            Fields.WEIGHT_KG: product_data.get(Fields.WEIGHT_KG),
            Fields.LENGTH_CM: product_data.get(Fields.LENGTH_CM),
            Fields.WIDTH_CM: product_data.get(Fields.WIDTH_CM),
            Fields.HEIGHT_CM: product_data.get(Fields.HEIGHT_CM),
            # Supplier info for international shipping estimation (e.g., AliExpress/DHGate)
            Fields.SUPPLIER: product_data.get(Fields.SUPPLIER),
            Fields.BUYER_NOTE: item.get(Fields.BUYER_NOTE),
        }
        validated_items.append(validated_item)
        actual_subtotal += db_price * item[Fields.QUANTITY]

    # Verify subtotal (exact cent comparison — prices already validated per-item)
    actual_subtotal_cents = round(actual_subtotal * 100)
    client_subtotal_cents = round(client_subtotal * 100)
    if actual_subtotal_cents != client_subtotal_cents:
        raise https_fn.HttpsError(
            "invalid-argument", f"Subtotal mismatch: expected ${actual_subtotal:.2f}, got ${client_subtotal:.2f}"
        )

    # --- Coupon / promo code (N-07) ---
    # Re-validate and compute discount server-side against verified actual_subtotal_cents.
    # Client-supplied cartSubtotalCents is used only for UX preview in apply_coupon.
    coupon_code: str | None = None
    discount_amount_cents = 0
    coupon_code_raw = data.get(Fields.COUPON_CODE)
    if coupon_code_raw and isinstance(coupon_code_raw, str):
        from handlers.coupons import _compute_discount, _validate_coupon_code, redeem_coupon as _redeem_coupon  # noqa: E402

        code = coupon_code_raw.strip().upper()
        if _validate_coupon_code(code):
            coupon_snap = get_db().collection(Collections.COUPONS).document(code).get()
            if coupon_snap.exists:
                coupon_data = coupon_snap.to_dict() or {}
                _coupon_valid = (
                    coupon_data.get(Fields.IS_ACTIVE, False)
                    and _coupon_not_expired(coupon_data)
                    and _coupon_within_limits(coupon_data, user_id)
                    and _coupon_seller_allowed(coupon_data, sellers)
                    and _coupon_min_order_met(coupon_data, actual_subtotal_cents)
                )
                if _coupon_valid:
                    coupon_code = code
                    discount_amount_cents = _compute_discount(coupon_data, actual_subtotal_cents)
                else:
                    logger.warning(f"Coupon {code} re-validation failed at payment time for user {user_id}")
            else:
                logger.warning(f"Coupon {code} not found at payment time for user {user_id}")

    # Discounted subtotal is the taxable base (CRA: tax applies to amount actually paid)
    discounted_subtotal_cents = max(0, actual_subtotal_cents - discount_amount_cents)


    if all_digital:
        # Digital-only orders: worldwide delivery, zero shipping, zero Canadian tax
        delivery_speed = DeliveryTypeValues.STANDARD
        delivery_instructions = ""
        shipping_cost_cents = 0
        tax_amount_cents = 0
        taxes_breakdown = {}
        item_taxes = []
        state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)
        is_reverse_charge = False
    else:
        # Calculate shipping (server-side) - returns dollars
        # Bug #9: Read delivery speed from client request (express/same_day cost more)
        delivery_speed = data.get(Fields.DELIVERY_SPEED, DeliveryTypeValues.STANDARD)
        if delivery_speed not in (DeliveryTypeValues.STANDARD, DeliveryTypeValues.EXPRESS, DeliveryTypeValues.SAME_DAY):
            delivery_speed = DeliveryTypeValues.STANDARD  # Sanitize to prevent injection

        # Get delivery instructions from client (optional)
        delivery_instructions = data.get(Fields.DELIVERY_INSTRUCTIONS, "")
        if delivery_instructions and len(delivery_instructions) > BusinessRules.MAX_DELIVERY_INSTRUCTIONS_LENGTH:
            delivery_instructions = delivery_instructions[: BusinessRules.MAX_DELIVERY_INSTRUCTIONS_LENGTH]

        try:
            shipping_cost_dollars = calculate_shipping_cost(validated_items, shipping_address, speed=delivery_speed)
            shipping_cost_cents = round(shipping_cost_dollars * 100)
        except ValueError as e:
            # UX FIX: Return specific validation error (e.g., Same Day distance limit)
            logger.warning(f"Shipping validation error: {str(e)}")
            raise https_fn.HttpsError("invalid-argument", str(e)) from e
        except Exception as e:
            logger.error(f"Shipping calculation error: {str(e)}")
            raise https_fn.HttpsError("internal", "Shipping calculation failed. Please try again.") from e

        # Calculate taxes per-item (server-side) - all in cents to avoid rounding errors
        state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)

    if not all_digital:
        if STRIPE_TAX_ENABLED:
            # Use Stripe Tax API for automatic tax calculation
            # Stripe will validate GST number and apply B2B exemption if valid
            tax_result = calculate_tax_with_stripe(validated_items, shipping_address, shipping_cost_cents, gst_number)
            if tax_result[0] is not None:
                tax_amount_cents, taxes_breakdown, item_taxes, is_reverse_charge = tax_result

                # Log if Stripe applied reverse charge (B2B exemption)
                if is_reverse_charge:
                    logger.info(
                        f"✅ Stripe applied B2B reverse charge for user {user_id} with GST {gst_number[:6]}****"
                    )
            else:
                # SECURITY FIX: Fall back to manual calculation on Stripe Tax API error
                # IMPORTANT: Do NOT apply B2B exemption (GST-based) in fallback mode
                # because we cannot validate the GST number without Stripe
                logger.warning(f"⚠️ Stripe Tax API failed, falling back to manual calculation for user {user_id}")

                # CRA: tax applies to amount actually paid (post-discount subtotal)
                discount_ratio = discounted_subtotal_cents / actual_subtotal_cents if actual_subtotal_cents > 0 else 1.0
                tax_amount_cents = 0
                item_taxes = []
                for item in validated_items:
                    item_subtotal_cents = round(int(item[Fields.PRICE] * 100) * item[Fields.QUANTITY] * discount_ratio)
                    item_tax_rate = get_item_tax_rate(item, state_code)
                    item_tax_cents = round(item_subtotal_cents * item_tax_rate)
                    tax_amount_cents += item_tax_cents
                    item_taxes.append(
                        {
                            Fields.PRODUCT_ID: item[Fields.PRODUCT_ID],
                            Fields.TAX_CENTS: item_tax_cents,
                            Fields.TAX_RATE: item_tax_rate,
                        }
                    )

                # CRA COMPLIANCE: GST/HST applies to shipping charges in Canada
                if shipping_cost_cents > 0:
                    shipping_tax_rate = get_tax_rate(state_code)
                    shipping_tax_cents = round(shipping_cost_cents * shipping_tax_rate)
                    tax_amount_cents += shipping_tax_cents

                # Build tax breakdown dict (matches Flutter provinceTaxRates)
                # Tax base: post-discount subtotal + shipping (CRA requirement)
                taxable_total = (discounted_subtotal_cents / 100) + (shipping_cost_cents / 100)
                province_rates = _PROVINCE_TAX_BREAKDOWN.get(
                    state_code, _PROVINCE_TAX_BREAKDOWN.get(BusinessRules.DEFAULT_PROVINCE, {"GST": 0.05})
                )
                taxes_breakdown = {name: round(taxable_total * rate, 2) for name, rate in province_rates.items()}

                # SECURITY: Force is_reverse_charge to False in fallback mode
                is_reverse_charge = False
        else:
            # Calculate per-item tax (manual calculation)
            # CRA: tax applies to amount actually paid (post-discount subtotal)
            discount_ratio = discounted_subtotal_cents / actual_subtotal_cents if actual_subtotal_cents > 0 else 1.0
            tax_amount_cents = 0
            item_taxes = []  # Store for breakdown

            for item in validated_items:
                item_subtotal_cents = round(int(item[Fields.PRICE] * 100) * item[Fields.QUANTITY] * discount_ratio)
                item_tax_rate = get_item_tax_rate(item, state_code)
                item_tax_cents = round(item_subtotal_cents * item_tax_rate)
                tax_amount_cents += item_tax_cents
                item_taxes.append(
                    {
                        Fields.PRODUCT_ID: item[Fields.PRODUCT_ID],
                        Fields.TAX_CENTS: item_tax_cents,
                        Fields.TAX_RATE: item_tax_rate,
                    }
                )

            # CRA COMPLIANCE: GST/HST applies to shipping charges in Canada
            if shipping_cost_cents > 0:
                shipping_tax_rate = get_tax_rate(state_code)
                shipping_tax_cents = round(shipping_cost_cents * shipping_tax_rate)
                tax_amount_cents += shipping_tax_cents

            # Build tax breakdown dict (matches Flutter provinceTaxRates)
            # Tax base: post-discount subtotal + shipping (CRA requirement)
            taxable_total = (discounted_subtotal_cents / 100) + (shipping_cost_cents / 100)
            province_rates = _PROVINCE_TAX_BREAKDOWN.get(
                state_code, _PROVINCE_TAX_BREAKDOWN.get(BusinessRules.DEFAULT_PROVINCE, {"GST": 0.05})
            )
            taxes_breakdown = {name: round(taxable_total * rate, 2) for name, rate in province_rates.items()}

            # No Stripe Tax API available — B2B exemption not possible
            is_reverse_charge = False

    # Total in cents (discount reduces the subtotal component)
    total_amount_cents = discounted_subtotal_cents + shipping_cost_cents + tax_amount_cents

    # Reserve stock atomically using Firestore transactions
    # IMPORTANT: All reads MUST happen before any writes to avoid
    # "Attempted read after write in a transaction" errors
    fulfillment_warehouse_ids: list[str | None] = [None] * len(validated_items)  # TASK 02: track per-item

    # Pre-query inventoryLevels candidates per product (outside transaction for efficiency)
    inventory_candidates: dict[str, list[tuple[str, int]]] = {}
    for item in validated_items:
        p_id = item[Fields.PRODUCT_ID]
        if p_id not in inventory_candidates:
            try:
                inv_docs = (
                    get_db()
                    .collection(Collections.PRODUCTS)
                    .document(p_id)
                    .collection(Collections.INVENTORY_LEVELS)
                    .order_by(Fields.AVAILABLE_QUANTITY, direction="DESCENDING")
                    .limit(50)
                    .get()
                )
                inventory_candidates[p_id] = [
                    (d.id, (d.to_dict() or {}).get(Fields.AVAILABLE_QUANTITY, 0))
                    for d in inv_docs
                    if d.exists
                ]
            except Exception:
                inventory_candidates[p_id] = []  # Fallback to warehouseStock map inside tx

    @get_transactional()
    def reserve_stock_transaction(transaction):
        # Phase 1: Read ALL product snapshots + inventoryLevel docs first
        product_refs = []
        product_snapshots = []
        inv_refs_per_product: dict[str, list] = {}
        inv_snaps_per_product: dict[str, list] = {}

        for item in validated_items:
            p_id = item[Fields.PRODUCT_ID]
            product_ref = get_db().collection(Collections.PRODUCTS).document(p_id)
            product_snapshot = product_ref.get(transaction=transaction)
            product_refs.append(product_ref)
            product_snapshots.append(product_snapshot)

            # Read inventoryLevel docs inside transaction for consistency
            if p_id not in inv_refs_per_product:
                candidates = inventory_candidates.get(p_id, [])
                refs = []
                snaps = []
                for wh_id, _ in candidates:
                    inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(wh_id)
                    inv_snap = inv_ref.get(transaction=transaction)
                    refs.append(inv_ref)
                    snaps.append(inv_snap)
                inv_refs_per_product[p_id] = refs
                inv_snaps_per_product[p_id] = snaps

        # Phase 2: Validate ALL stock levels and compute warehouse decrements
        updates = []
        inv_level_writes: list[list[tuple]] = []  # per-item: [(inv_ref, new_qty), ...]
        for i, item in enumerate(validated_items):
            snapshot = product_snapshots[i]
            if not snapshot.exists:
                raise https_fn.HttpsError("not-found", f"Product {item[Fields.PRODUCT_ID]} not found")

            product_data = snapshot.to_dict()
            current_stock = product_data.get(Fields.STOCK_QUANTITY, 0)
            allow_backorder = product_data.get(Fields.INVENTORY, {}).get(Fields.ALLOW_BACKORDER, False)

            # N-09: Variant stock checking
            variant_id = item.get(Fields.VARIANT_ID)
            if product_data.get(Fields.HAS_VARIANTS, False):
                if not variant_id:
                    raise https_fn.HttpsError(
                        "invalid-argument",
                        f"Product {product_data[Fields.NAME]} has variants — you must select a variant before adding to cart",
                    )
                variants = product_data.get(Fields.VARIANTS, [])
                variant = next((v for v in variants if v.get(Fields.VARIANT_ID) == variant_id), None)
                if variant is None:
                    raise https_fn.HttpsError("not-found", f"Variant {variant_id} not found")
                if not variant.get("isActive", True):
                    raise https_fn.HttpsError("failed-precondition", f"Selected variant is no longer available")
                variant_stock = variant.get(Fields.STOCK_QUANTITY, 0)
                if variant_stock < item[Fields.QUANTITY] and not allow_backorder:
                    raise https_fn.HttpsError(
                        "resource-exhausted",
                        f"Stock changed: {product_data[Fields.NAME]} variant now has {variant_stock} available",
                    )
                item[Fields.VARIANT_ID] = variant_id
                if Fields.VARIANT_OPTIONS in variant:
                    item[Fields.VARIANT_OPTIONS] = variant[Fields.OPTION_VALUES]
            elif current_stock < item[Fields.QUANTITY] and not allow_backorder:
                raise https_fn.HttpsError(
                    "resource-exhausted",
                    f"Stock changed: {product_data[Fields.NAME]} now has {current_stock} available",
                )

            qty = item[Fields.QUANTITY]
            new_total_stock = current_stock - qty
            p_id = item[Fields.PRODUCT_ID]

            # Drain warehouse stock — use inventoryLevels if available, fallback to warehouseStock map
            warehouse_patches: dict = {}
            item_inv_writes: list[tuple] = []

            inv_snaps = inv_snaps_per_product.get(p_id, [])
            inv_refs = inv_refs_per_product.get(p_id, [])

            if inv_snaps:
                # Use inventoryLevels subcollection (authoritative)
                sorted_wh = [
                    (inv_refs[j], inv_refs[j].id, (inv_snaps[j].to_dict() or {}).get(Fields.AVAILABLE_QUANTITY, 0))
                    for j in range(len(inv_snaps))
                    if inv_snaps[j].exists
                ]
                sorted_wh.sort(key=lambda kv: kv[2], reverse=True)
                remaining = qty
                for inv_ref, wh_id, wh_avail in sorted_wh:
                    if remaining <= 0:
                        break
                    drain = min(wh_avail, remaining)
                    new_avail = wh_avail - drain
                    warehouse_patches[f"{Fields.WAREHOUSE_STOCK}.{wh_id}"] = new_avail
                    item_inv_writes.append((inv_ref, new_avail))
                    if fulfillment_warehouse_ids[i] is None:
                        fulfillment_warehouse_ids[i] = wh_id
                    remaining -= drain
                if remaining > 0 and sorted_wh:
                    # Backorder: last warehouse goes negative
                    last_ref, last_wh_id, _ = sorted_wh[-1]
                    key = f"{Fields.WAREHOUSE_STOCK}.{last_wh_id}"
                    new_val = warehouse_patches.get(key, 0) - remaining
                    warehouse_patches[key] = new_val
                    # Update the last inv_write entry
                    item_inv_writes = [(r, q) for r, q in item_inv_writes if r.id != last_wh_id]
                    item_inv_writes.append((last_ref, new_val))
            else:
                # Fallback: warehouseStock map on product doc
                warehouse_stock: dict = product_data.get(Fields.WAREHOUSE_STOCK) or {}
                if warehouse_stock:
                    sorted_warehouses = sorted(warehouse_stock.items(), key=lambda kv: kv[1], reverse=True)
                    remaining = qty
                    for wh_id, wh_stock in sorted_warehouses:
                        if remaining <= 0:
                            break
                        drain = min(wh_stock, remaining)
                        warehouse_patches[f"{Fields.WAREHOUSE_STOCK}.{wh_id}"] = wh_stock - drain
                        if fulfillment_warehouse_ids[i] is None:
                            fulfillment_warehouse_ids[i] = wh_id
                        remaining -= drain
                    if remaining > 0 and sorted_warehouses:
                        last_wh_id = sorted_warehouses[-1][0]
                        key = f"{Fields.WAREHOUSE_STOCK}.{last_wh_id}"
                        warehouse_patches[key] = warehouse_patches.get(key, sorted_warehouses[-1][1]) - remaining

            updates.append((product_refs[i], new_total_stock, warehouse_patches))
            inv_level_writes.append(item_inv_writes)

        # Phase 3: Write ALL updates after all reads are done
        for i, (ref, new_stock, warehouse_patches) in enumerate(updates):
            item = validated_items[i]
            variant_id = item.get(Fields.VARIANT_ID)
            patch = {Fields.STOCK_QUANTITY: new_stock}
            patch.update(warehouse_patches)

            # N-09: For variant products, also decrement the variant's stockQuantity in the array
            if variant_id:
                product_snapshot = product_snapshots[i]
                variants = list(product_snapshot.to_dict().get(Fields.VARIANTS, []))
                variant_idx = next((idx for idx, v in enumerate(variants) if v.get(Fields.VARIANT_ID) == variant_id), None)
                if variant_idx is not None:
                    variants[variant_idx][Fields.STOCK_QUANTITY] -= item[Fields.QUANTITY]
                    patch[Fields.VARIANTS] = variants

            transaction.update(ref, patch)

            # Write inventoryLevels subcollection docs
            for inv_ref, new_avail in inv_level_writes[i]:
                transaction.set(
                    inv_ref,
                    {
                        Fields.AVAILABLE_QUANTITY: new_avail,
                        Fields.LAST_SYNCED_AT: get_server_timestamp(),
                    },
                    merge=True,
                )

    transaction = get_db().transaction()
    try:
        reserve_stock_transaction(transaction)
    except https_fn.HttpsError:
        raise  # Re-raise HttpsErrors (already safe messages)
    except Exception as e:
        logger.error(f"Stock reservation error: {str(e)}")
        raise https_fn.HttpsError("internal", "Could not reserve stock. Please try again.") from e

    # TASK 02: stamp fulfillmentWarehouseId onto each item before order creation
    for i, wh_id in enumerate(fulfillment_warehouse_ids):
        if wh_id is not None:
            validated_items[i][Fields.FULFILLMENT_WAREHOUSE_ID] = wh_id

    # Create order in Firestore — all amounts in cents
    # IDEMPOTENCY: Check if user already has a recent pending order with same subtotal
    # to prevent duplicate orders from client retries
    recent_orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.USER_ID, "==", user_id)
        .where(Fields.ORDER_STATUS, "==", OrderStatusValues.PENDING)
        .where(Fields.PAYMENT_STATUS, "==", PaymentStatusValues.AWAITING_PAYMENT)
        .order_by(Fields.CREATED_AT, direction="DESCENDING")
        .limit(1)
        .get()
    )

    for recent_doc in recent_orders:
        recent_data = recent_doc.to_dict()
        # If same user created same-value order in last 60 seconds, return existing
        recent_created = recent_data.get(Fields.CREATED_AT)
        if recent_created and hasattr(recent_created, "timestamp"):
            # Ensure timezone-aware comparison (emulator may return naive datetimes)
            if hasattr(recent_created, "tzinfo") and recent_created.tzinfo is None:
                recent_created = recent_created.replace(tzinfo=UTC)
            age_seconds = (datetime.now(UTC) - recent_created).total_seconds()
            if (
                age_seconds < BusinessRules.ORDER_DEDUP_WINDOW_SECONDS
                and recent_data.get(Fields.SUBTOTAL_CENTS) == actual_subtotal_cents
            ):
                existing_session_id = recent_data.get(Fields.STRIPE_SESSION_ID)
                if existing_session_id:
                    # Retrieve session URL so frontend can redirect
                    try:
                        existing_session = stripe.checkout.Session.retrieve(existing_session_id)
                        checkout_url = existing_session.url
                    except Exception:
                        checkout_url = None

                    if checkout_url:
                        return {
                            ApiKeys.SUCCESS: True,
                            ApiKeys.SESSION_ID: existing_session_id,
                            Fields.ORDER_ID: recent_doc.id,
                            ApiKeys.CHECKOUT_URL: checkout_url,
                            ApiKeys.DUPLICATE: True,
                        }
                    # Session expired/no URL — fall through to create new one

    order_ref = get_db().collection(Collections.ORDERS).document()
    order_id = order_ref.id

    # Fetch buyer email for order record (avoids extra DB read in webhook)
    buyer_email = None
    if user_snapshot.exists:
        buyer_email = user_snapshot.to_dict().get(Fields.EMAIL)

    from handlers.payment_providers import PaymentProvider

    # Determine if B2B exemption was applied (Stripe validated GST and applied reverse charge)
    # is_reverse_charge is now always defined in all tax calculation branches
    is_tax_exempt = is_reverse_charge

    order_data = {
        Fields.ORDER_ID: order_id,
        Fields.USER_ID: user_id,
        Fields.CUSTOMER_EMAIL: buyer_email,
        Fields.SELLER_IDS: sorted(list(sellers)),
        Fields.ITEMS: validated_items,
        Fields.SUBTOTAL_CENTS: actual_subtotal_cents,
        Fields.DISCOUNT_AMOUNT_CENTS: discount_amount_cents,
        Fields.COUPON_CODE: coupon_code,
        Fields.SHIPPING_COST_CENTS: shipping_cost_cents,
        Fields.TAX_AMOUNT_CENTS: tax_amount_cents,
        Fields.TOTAL_AMOUNT_CENTS: total_amount_cents,
        Fields.TAXES: taxes_breakdown,
        Fields.ORDER_STATUS: OrderStatusValues.PENDING,
        Fields.PAYMENT_STATUS: PaymentStatusValues.AWAITING_PAYMENT,
        Fields.SHIPPING_ADDRESS: shipping_address,
        Fields.DELIVERY_INSTRUCTIONS: delivery_instructions,
        Fields.CREATED_AT: get_server_timestamp(),
        Fields.UPDATED_AT: get_server_timestamp(),
        Fields.CAPTURE_ATTEMPTS: 0,
        Fields.EXPIRES_AT: datetime.now(UTC) + timedelta(days=AUTHORIZATION_VALID_DAYS),
        Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
        Fields.PAYMENT_PROVIDER: PaymentProvider.STRIPE,
        Fields.DELIVERY_SPEED: delivery_speed,
        # Platform fee on post-discount subtotal (platform earns only on amount actually collected)
        # P-03 FIX: Read from subscriptions/{uid} instead of cached isPremium to prevent race condition
        Fields.PLATFORM_FEE_TOTAL_CENTS: 0
        if _check_premium_from_sub(user_id)
        else round(discounted_subtotal_cents * PLATFORM_FEE_PERCENT),
        Fields.ARCHIVED: False,
        Fields.STOCK_RESTORED: False,
        Fields.TAX_EXEMPTION: tax_exemption if gst_number else None,
        Fields.TAX_EXEMPT: is_tax_exempt,
        Fields.ITEM_TAXES: item_taxes,
        Fields.PREFERRED_LANGUAGE: user_data.get(Fields.PREFERRED_LANGUAGE, "en"),
    }

    # SECURITY FIX (CRITICAL-014): Snapshot seller Stripe account IDs at checkout.
    # Prevents seller from swapping their Stripe account between checkout and capture.
    seller_account_snapshot = {}
    for sid in sellers:
        if sid in seller_cache:
            s_data = seller_cache[sid]
            acct_id = s_data.get(Fields.STRIPE_ACCOUNT_ID)
            if acct_id:
                seller_account_snapshot[sid] = acct_id
    if seller_account_snapshot:
        order_data[Fields.SELLER_STRIPE_ACCOUNTS] = seller_account_snapshot

    order_ref.set(order_data)

    # Create Stripe Checkout Session
    try:
        line_items = []
        for item in validated_items:
            product_data = {Fields.NAME: item[Fields.NAME], "images": item.get(Fields.IMAGE_URLS, [])[:1]}

            # Add tax code if available
            tax_code = CATEGORY_TAX_CODE_MAP.get(item.get(Fields.CATEGORY_ID, 0))
            if tax_code:
                product_data["tax_code"] = tax_code

            line_items.append(
                {
                    "price_data": {
                        Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
                        "product_data": product_data,
                        "unit_amount": int(item[Fields.PRICE] * 100),  # Convert to cents
                    },
                    Fields.QUANTITY: item[Fields.QUANTITY],
                }
            )

        # Add shipping as line item (already in cents)
        if shipping_cost_cents > 0:
            line_items.append(
                {
                    "price_data": {
                        Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
                        "product_data": {Fields.NAME: "Shipping"},
                        "unit_amount": shipping_cost_cents,
                    },
                    Fields.QUANTITY: 1,
                }
            )

        # Add tax as line item (already in cents)
        # NOTE: We calculate tax manually server-side
        # Stripe automatic_tax is DISABLED to avoid double taxation
        # TODO consider this automatic_tax
        if tax_amount_cents > 0:
            line_items.append(
                {
                    "price_data": {
                        Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
                        "product_data": {Fields.NAME: f"Tax ({state_code})"},
                        "unit_amount": tax_amount_cents,
                    },
                    Fields.QUANTITY: 1,
                }
            )

        session = stripe.checkout.Session.create(
            line_items=line_items,
            mode="payment",
            # No payment_method_types — uses Stripe Dashboard settings
            # Enables Apple Pay, Google Pay, Interac (popular in Canada), etc.
            success_url=f"{BASE_URL}{AppConfig.CHECKOUT_SUCCESS_PATH}?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{BASE_URL}{AppConfig.CHECKOUT_CANCEL_PATH}",
            client_reference_id=user_id,
            metadata={Fields.ORDER_ID: order_id, Fields.USER_ID: user_id},
            payment_intent_data={
                "capture_method": "manual",
                "metadata": {Fields.ORDER_ID: order_id},
            },
            # NOTE: automatic_tax disabled - we calculate tax server-side to avoid double taxation
            # AUDIT FIX (CRITICAL-001): Idempotency key prevents duplicate sessions on retry
            idempotency_key=f"checkout_{order_id}",
        )

        # Update order with session ID
        order_ref.update(
            {
                Fields.STRIPE_SESSION_ID: session.id,
                Fields.STRIPE_PAYMENT_INTENT_ID: session.payment_intent if hasattr(session, "payment_intent") else None,
            }
        )

        # Return dict directly for on_call functions
        return {
            ApiKeys.SUCCESS: True,
            ApiKeys.SESSION_ID: session.id,
            Fields.ORDER_ID: order_id,
            ApiKeys.CHECKOUT_URL: session.url,
        }

    except stripe.error.CardError as e:
        # Card declined — rollback and return user-friendly message
        _rollback_checkout(validated_items, order_ref)
        raise https_fn.HttpsError(
            "failed-precondition", e.user_message or "Your card was declined. Please try a different payment method."
        ) from e
    except stripe.error.RateLimitError:
        _rollback_checkout(validated_items, order_ref)
        raise https_fn.HttpsError("unavailable", "Payment service is busy. Please try again in a moment.") from None
    except stripe.error.APIConnectionError:
        _rollback_checkout(validated_items, order_ref)
        raise https_fn.HttpsError(
            "unavailable", "Could not connect to payment service. Please check your connection and try again."
        ) from None
    except stripe.error.StripeError as e:
        _rollback_checkout(validated_items, order_ref)
        logger.error(f"Stripe error in checkout: {str(e)}")
        raise https_fn.HttpsError("internal", "Payment processing failed. Please try again.") from e
    except https_fn.HttpsError:
        # Re-raise already-safe HttpsErrors (from validation, stock checks, etc.)
        raise
    except Exception as e:
        _rollback_checkout(validated_items, order_ref)
        logger.error(f"Unexpected checkout error: {str(e)}")
        raise https_fn.HttpsError("internal", "An unexpected error occurred. Please try again.") from e


@https_fn.on_request(**WEBHOOK_OPTIONS)
def stripe_webhook(req: https_fn.Request) -> https_fn.Response:
    """
    Handles Stripe webhook events with strict security:
    1. Rate limiting by IP (FIRST)
    2. Signature verification (BEFORE processing)
    3. Idempotency check
    4. Event processing
    5. Sanitized error logging

    Supported events:
    - checkout.session.completed: Payment authorized
    - checkout.session.async_payment_succeeded: Async payment completed
    - checkout.session.async_payment_failed: Async payment failed
    - checkout.session.expired: Session expired
    - payment_intent.succeeded: Payment succeeded
    - payment_intent.payment_failed: Payment failed
    - payment_intent.canceled: Payment intent canceled
    - charge.refunded: Refund issued
    - charge.dispute.created: Dispute opened
    - charge.dispute.updated: Dispute updated (evidence/status change)
    - charge.dispute.closed: Dispute resolved
    - charge.dispute.funds_reinstated: Dispute funds reinstated to seller
    - transfer.reversed: Payout reversed
    - payout.failed: Payout failed
    - refund.failed: Refund failed
    - account.updated: Connect account status changed (enables sellers after onboarding)

    Security:
    - Rate limiting by IP (DDoS protection)
    - Signature verification (HMAC with timing-safe comparison)
    - Idempotency (Firestore webhook_events collection)
    - Sanitized error logging

    Returns:
        200 OK: Event processed successfully
        400 Bad Request: Invalid signature/payload
        429 Too Many Requests: Rate limit exceeded
        500 Internal Error: Processing failed
    """
    # Reject non-POST requests immediately (browser health checks, emulator UI)
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    # SECURITY FIX #1: Rate limiting by IP FIRST (prevent DDoS)
    # Skip rate limiting in emulator mode to avoid Firestore transaction issues
    client_ip = req.headers.get("X-Forwarded-For", req.headers.get("X-Real-IP", "unknown")).split(",")[0].strip()

    if not IS_EMULATOR:
        allowed, message = get_rate_limiter().check_rate_limit(
            identifier=f"ip_{client_ip}",
            action="stripe_webhook",
            max_requests=BusinessRules.WEBHOOK_RATE_LIMIT_PER_MINUTE,
            window_minutes=1,
            fail_closed=True,  # Block on error for security
        )

        if not allowed:
            logger.warning(f"⚠️ Stripe webhook rate limit exceeded for IP: {client_ip[:10]}...")  # Sanitized log
            return https_fn.Response("Rate limit exceeded", status=429)

    # SECURITY FIX #2: Get payload and signature
    payload = req.data
    sig_header = req.headers.get("Stripe-Signature")

    if not sig_header:
        logger.warning(f"⚠️ Stripe webhook missing signature from IP: {client_ip[:10]}...")
        return https_fn.Response("Missing signature", status=400)

    try:
        # SECURITY FIX #3: Verify webhook signature (HMAC with timing-safe comparison)
        event = stripe.Webhook.construct_event(payload, sig_header, get_stripe_webhook_secret())
    except ValueError:
        logger.warning(f"⚠️ Stripe webhook invalid payload from IP: {client_ip[:10]}...")  # Sanitized
        return https_fn.Response("Invalid payload", status=400)
    except Exception as e:
        # Handle SignatureVerificationError and other exceptions
        if "SignatureVerificationError" in str(type(e).__name__):
            logger.warning(f"⚠️ Stripe webhook invalid signature from IP: {client_ip[:10]}...")  # Sanitized
            return https_fn.Response("Invalid signature", status=400)
        logger.warning(f"⚠️ Stripe webhook verification error: {type(e).__name__}")  # Sanitized (no details)
        return https_fn.Response("Signature verification error", status=500)

    event_id = event["id"]
    event_type = event[Fields.TYPE]

    # SECURITY FIX #3b: Reject stale webhooks (replay attack prevention)
    # Stripe events have a 'created' timestamp (Unix epoch seconds).
    # Reject events older than 5 minutes to prevent replay attacks.
    import time as _time

    event_created = event.get("created", 0)
    current_time = int(_time.time())
    event_age_seconds = current_time - event_created
    if not IS_EMULATOR and event_age_seconds > BusinessRules.WEBHOOK_MAX_AGE_SECONDS:
        logger.warning(f"⚠️ Rejecting stale webhook: {event_type} age={event_age_seconds}s (event: {event_id[:16]}...)")
        return https_fn.Response("Event too old", status=400)

    # SECURITY FIX #4: Atomic idempotency check using create() to prevent race conditions.
    # If two webhook deliveries arrive simultaneously, only one create() will succeed.
    webhook_ref = get_db().collection(Collections.WEBHOOK_EVENTS).document(event_id)
    order_id = event.get("data", {}).get("object", {}).get("metadata", {}).get(Fields.ORDER_ID, "N/A")

    try:
        webhook_ref.create(
            {
                Fields.PROVIDER: PaymentProviderValues.STRIPE,
                Fields.TYPE: event_type,
                Fields.STATUS: WebhookStatusValues.PROCESSING,
                Fields.TIMESTAMP: get_server_timestamp(),
                Fields.CLIENT_IP: client_ip,
                Fields.EVENT_ID: event_id,
                Fields.ORDER_ID: order_id,
            }
        )
    except Exception:
        # Document already exists — check if completed or failed
        try:
            webhook_doc = webhook_ref.get()
            if webhook_doc.exists:
                existing_status = webhook_doc.to_dict().get(Fields.STATUS, WebhookStatusValues.COMPLETED)
                if existing_status == WebhookStatusValues.COMPLETED:
                    logger.info(f"✓ Stripe webhook already processed: {event_type} (event: {event_id[:16]}...)")
                    return https_fn.Response("Event already processed", status=200)
                # Allow retry of failed events
                logger.error(f"♻️ Retrying failed webhook: {event_type} (event: {event_id[:16]}...)")
                webhook_ref.update(
                    {
                        Fields.STATUS: WebhookStatusValues.PROCESSING,
                        Fields.TIMESTAMP: get_server_timestamp(),
                    }
                )
        except Exception as e:
            logger.warning(f"⚠️ Idempotency check error: {type(e).__name__}")

    # Route event to appropriate handler
    try:
        ensure_stripe_key()
        if event_type == "checkout.session.completed":
            process_checkout_session_completed(event["data"]["object"])
        elif event_type == "checkout.session.async_payment_succeeded":
            process_async_payment_succeeded(event["data"]["object"])
        elif event_type == "checkout.session.async_payment_failed":
            process_async_payment_failed(event["data"]["object"])
        elif event_type == "checkout.session.expired":
            process_session_expired(event["data"]["object"])
        elif event_type == "payment_intent.succeeded":
            process_payment_intent_succeeded(event["data"]["object"])
        elif event_type == "payment_intent.payment_failed":
            process_payment_intent_failed(event["data"]["object"])
        elif event_type == "charge.refunded":
            process_charge_refunded(event["data"]["object"])
        elif event_type == "charge.dispute.created":
            process_dispute_created(event["data"]["object"])
        elif event_type == "charge.dispute.updated":
            process_dispute_updated(event["data"]["object"])
        elif event_type == "charge.dispute.closed":
            process_dispute_closed(event["data"]["object"])
        elif event_type == "charge.dispute.funds_reinstated":
            process_dispute_funds_reinstated(event["data"]["object"])
        elif event_type == "transfer.reversed":
            process_transfer_reversed(event["data"]["object"])
        elif event_type == "payout.failed":
            process_payout_failed(event["data"]["object"])
        elif event_type == "refund.failed":
            process_refund_failed(event["data"]["object"])
        elif event_type == "payment_intent.canceled":
            process_payment_intent_canceled(event["data"]["object"])
        elif event_type == "account.updated":
            process_account_updated(event["data"]["object"])
        elif event_type == "customer.subscription.created":
            from handlers.subscriptions import handle_subscription_created

            handle_subscription_created(event)
        elif event_type == "customer.subscription.updated":
            from handlers.subscriptions import handle_subscription_updated

            handle_subscription_updated(event)
        elif event_type == "customer.subscription.deleted":
            from handlers.subscriptions import handle_subscription_deleted

            handle_subscription_deleted(event)
        elif event_type == "invoice.payment_failed":
            from handlers.subscriptions import handle_invoice_payment_failed

            handle_invoice_payment_failed(event)
        else:
            logger.info(f"ℹ️ Unhandled Stripe event type: {event_type}")

        # Mark as completed
        with contextlib.suppress(Exception):
            webhook_ref.update({Fields.STATUS: WebhookStatusValues.COMPLETED})

        logger.info(f"✓ Stripe webhook processed successfully: {event_type}")
        return https_fn.Response("Success", status=200)

    except Exception as e:
        # Mark as failed so Stripe can retry
        with contextlib.suppress(Exception):
            webhook_ref.update({Fields.STATUS: WebhookStatusValues.FAILED, Fields.ERROR: type(e).__name__})

        # SECURITY FIX #6: Sanitized error logging (no sensitive data exposure)
        error_type = type(e).__name__
        logger.error(f"❌ Error processing Stripe webhook: {error_type} for event_type: {event_type}")
        # Don't expose internal error details to webhook caller
        return https_fn.Response("Internal processing error", status=500)


def _generate_license_key() -> str:
    """Generate a XXXX-XXXX-XXXX-XXXX format license key using crypto-random characters."""
    alphabet = _string.ascii_uppercase + _string.digits
    segments = ["".join(secrets.choice(alphabet) for _ in range(4)) for _ in range(4)]
    return "-".join(segments)


def _generate_digital_licenses(order_id: str, order_data: dict) -> None:
    """Generate license keys for all digital items in an order.
    Idempotent: skips items where digitalUnlocked=True.
    Called immediately after order is confirmed on payment capture.
    """
    from datetime import datetime

    db = get_db()
    items = order_data.get(Fields.ITEMS, [])
    buyer_id = order_data.get(Fields.USER_ID, "")
    updated_items = list(items)
    any_generated = False

    for idx, item in enumerate(items):
        if not item.get(Fields.IS_DIGITAL, False):
            continue
        if item.get(Fields.DIGITAL_UNLOCKED, False):
            logger.info(f"Digital item {item.get(Fields.PRODUCT_ID)} already unlocked, skipping")
            continue

        product_id = item.get(Fields.PRODUCT_ID)
        product_doc = db.collection(Collections.PRODUCTS).document(product_id).get()
        if not product_doc.exists:
            logger.warning(f"Product {product_id} not found for digital license generation")
            continue

        product_data = product_doc.to_dict()
        digital_type = product_data.get(Fields.DIGITAL_TYPE)
        if not digital_type:
            logger.warning(f"Product {product_id} has isDigital=True but no digitalType")
            continue

        # Generate unique license key — doc ID = key for O(1) lookup
        license_key = None
        for _ in range(5):
            candidate = _generate_license_key()
            existing = db.collection(Collections.LICENSES).document(candidate).get()
            if not existing.exists:
                license_key = candidate
                break
        if not license_key:
            logger.error(f"Could not generate unique license key for product {product_id}")
            continue

        now = datetime.now(UTC)

        if digital_type == DigitalTypeValues.SOFTWARE:
            builds = product_data.get(Fields.DIGITAL_BUILDS, {})
            supported_platforms = list(builds.keys())
            license_doc = {
                Fields.LICENSE_KEY: license_key,
                Fields.PRODUCT_ID: product_id,
                Fields.ORDER_ID: order_id,
                Fields.USER_ID: buyer_id,
                Fields.DIGITAL_TYPE: DigitalTypeValues.SOFTWARE,
                Fields.STATUS: LicenseStatusValues.ACTIVE,
                Fields.SUPPORTED_PLATFORMS: supported_platforms,
                Fields.DEVICE_LIMIT: product_data.get(Fields.DEVICE_LIMIT),
                Fields.ACTIVATIONS: [],
                Fields.DIGITAL_BUILDS: builds,
                Fields.PRODUCT_NAME: product_data.get(Fields.NAME, ""),
                Fields.CREATED_AT: now,
            }
            db.collection(Collections.LICENSES).document(license_key).set(license_doc)

        elif digital_type == DigitalTypeValues.BOOK:
            book_source_url = product_data.get(Fields.BOOK_SOURCE_URL, "")
            license_doc = {
                Fields.LICENSE_KEY: license_key,
                Fields.PRODUCT_ID: product_id,
                Fields.ORDER_ID: order_id,
                Fields.USER_ID: buyer_id,
                Fields.DIGITAL_TYPE: DigitalTypeValues.BOOK,
                Fields.STATUS: LicenseStatusValues.ACTIVE,
                Fields.BOOK_SOURCE_URL: book_source_url,
                Fields.PRODUCT_NAME: product_data.get(Fields.NAME, ""),
                Fields.CREATED_AT: now,
            }
            db.collection(Collections.LICENSES).document(license_key).set(license_doc)

        # Update item in order — write platform availability without real URLs
        updated_item = dict(updated_items[idx])
        updated_item[Fields.LICENSE_KEY] = license_key
        updated_item[Fields.DIGITAL_UNLOCKED] = True
        updated_item[Fields.STATUS] = DeliveryStatusValues.DELIVERED  # Digital: instant delivery
        if digital_type == DigitalTypeValues.SOFTWARE:
            # Store platform keys only (no URLs) so the client can show download buttons
            # without exposing the seller's actual download URL.
            updated_item[Fields.DIGITAL_BUILDS] = {p: "" for p in supported_platforms}
        updated_items[idx] = updated_item
        any_generated = True
        logger.info(f"License {license_key} generated for product {product_id} (type={digital_type})")

    if any_generated:
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_ref.update({Fields.ITEMS: updated_items, Fields.UPDATED_AT: datetime.now(UTC)})


def process_checkout_session_completed(session: dict) -> str | None:
    """
    Processes checkout.session.completed event.
    Updates order status to confirmed and sends confirmation emails.
    """
    # SECURITY: For async payment methods (bank transfers, Interac), the session
    # completes before payment arrives. Defer to async_payment_succeeded webhook.
    if session.get("payment_status") != "paid":
        logger.info(
            f"Session {session.get('id')} payment_status={session.get('payment_status')}, deferring to async_payment webhook"
        )
        return None

    order_id = session.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        logger.info("No orderId in session metadata")
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        logger.info(f"Order {order_id} not found")
        return None

    order_data = order_doc.to_dict()

    # SECURITY: Verify current order state — don't overwrite cancelled/expired orders
    current_status = order_data.get(Fields.ORDER_STATUS)
    if current_status != OrderStatusValues.PENDING:
        logger.info(f"Order {order_id} status is {current_status}, not PENDING — skipping")
        return f"Order {order_id} skipped (status: {current_status})"

    # SECURITY: Verify payment amount matches order amount
    session_amount = session.get("amount_total", 0)
    expected_amount = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0)
    if session_amount != expected_amount:
        logger.info(f"AMOUNT MISMATCH: session={session_amount}, expected={expected_amount} for {order_id}")
        _restore_stock_and_cancel_order(
            order_id, order_data, f"Amount mismatch: paid {session_amount} expected {expected_amount}"
        )
        return f"Order {order_id} cancelled - amount mismatch"

    # Fix 4: Address Injection Protection
    # Verify that the address used in Stripe matches the one in Firestore.
    # Prevents users from getting cheap shipping quote for Address A, then swapping to Address B in Stripe.
    # NOTE: Only applies when Stripe collects shipping address (shipping_address_collection enabled).
    # If shipping_details is empty, we don't collect address in Stripe — skip check.
    session_shipping = session.get("shipping_details", {}) or {}
    stripe_address = session_shipping.get("address", {}) or {}

    # Only compare if Stripe actually collected a shipping address
    if stripe_address and any(stripe_address.get(k) for k in ("country", "state", "postal_code")):
        order_address = order_data.get(Fields.SHIPPING_ADDRESS, {})

        def normalize(val):
            return str(val).strip().lower() if val else ""

        # Compare critical fields that affect shipping/tax: Country, State, Postal Code
        # precise street match is skipped to allow minor typo corrections by user
        mismatches = []
        if normalize(stripe_address.get("country")) != normalize(order_address.get(Fields.COUNTRY)):
            mismatches.append("country")
        if normalize(stripe_address.get("state")) != normalize(order_address.get(Fields.STATE)):
            mismatches.append("state")
        # Fuzzy match postal code (remove spaces)
        stripe_zip = normalize(stripe_address.get("postal_code")).replace(" ", "")
        order_zip = normalize(order_address.get(Fields.POSTAL_CODE)).replace(" ", "")
        if stripe_zip != order_zip:
            mismatches.append(f"postal_code ({stripe_zip} vs {order_zip})")

        if mismatches:
            logger.warning(f"⚠️ Address mismatch for order {order_id}: {mismatches}. Cancelling.")
            _restore_stock_and_cancel_order(order_id, order_data, f"Shipping address mismatch: {', '.join(mismatches)}")
            return f"Order {order_id} cancelled - address mismatch"

    # SECURITY FIX: Re-validate products before confirming order
    # Products could be deactivated or sellers suspended between checkout and payment
    items = order_data.get(Fields.ITEMS, [])
    for item in items:
        product_id = item.get(Fields.PRODUCT_ID)
        seller_id = item.get(Fields.SELLER_ID)

        # Check product still exists and is active
        product_ref = get_db().collection(Collections.PRODUCTS).document(product_id)
        product_doc = product_ref.get()

        if not product_doc.exists:
            logger.warning(f"⚠️ Product {product_id} no longer exists, cancelling order {order_id}")
            _restore_stock_and_cancel_order(order_id, order_data, f"Product {product_id} removed")
            return f"Order {order_id} cancelled - product removed"

        product_data = product_doc.to_dict()
        if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            logger.warning(f"⚠️ Product {product_id} deactivated, cancelling order {order_id}")
            _restore_stock_and_cancel_order(order_id, order_data, f"Product {product_id} deactivated")
            return f"Order {order_id} cancelled - product deactivated"

        # Check seller not suspended
        seller_ref = get_db().collection(Collections.USERS).document(seller_id)
        seller_doc = seller_ref.get()
        if seller_doc.exists and seller_doc.to_dict().get(Fields.SUSPENDED, False):
            logger.warning(f"⚠️ Seller {seller_id} suspended, cancelling order {order_id}")
            _restore_stock_and_cancel_order(order_id, order_data, f"Seller {seller_id} suspended")
            return f"Order {order_id} cancelled - seller suspended"

    # Update order status
    # AUDIT FIX (CRITICAL-001): Correctly reflect manual capture status.
    # We mark as AUTHORIZED instead of CAPTURED because capture_method is manual.
    # The actual capture happens in capture_payment (on delivery) or auto-capture cron.
    pi_id = session.get("payment_intent")

    # Initialize update data
    update_data = {
        Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
        Fields.STRIPE_PAYMENT_INTENT_ID: pi_id,
        Fields.UPDATED_AT: get_server_timestamp(),
    }

    # Verify PI status to be robust: if it's already captured (unlikely here but possible on retries),
    # reflect that accurately. Otherwise, mark as AUTHORIZED.
    if pi_id:
        try:
            # We fetch the PI to know its actual state (authorized vs captured)
            pi = stripe.PaymentIntent.retrieve(pi_id)
            if pi.status == "requires_capture":
                update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.AUTHORIZED
            elif pi.status in ["succeeded", "processing"]:
                update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.CAPTURED
                update_data[Fields.CAPTURED_AT] = get_server_timestamp()
            else:
                # Fallback to AUTHORIZED if state is ambiguous but not failed
                update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.AUTHORIZED
        except Exception as e:
            logger.warning(f"⚠️ Failed to check PI status for order {order_id}: {e}")
            update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.AUTHORIZED
    else:
        # No PI ID present (e.g. zero-amount order)
        update_data[Fields.PAYMENT_STATUS] = PaymentStatusValues.CAPTURED
        update_data[Fields.CAPTURED_AT] = get_server_timestamp()

    order_ref.update(update_data)

    # Record payment event
    payment_event_type = OrderEventTypes.PAYMENT_CAPTURED if update_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.CAPTURED else OrderEventTypes.PAYMENT_AUTHORIZED
    try:
        OrderEvent.write(
            db, order_id, payment_event_type,
            actor="stripe_webhook", actor_type="system",
            to_status=update_data.get(Fields.PAYMENT_STATUS),
            metadata={"paymentIntentId": pi_id or ""},
        )
    except Exception as e:
        logger.warning(f"Failed to write order event for {order_id}: {e}")

    # Send confirmation emails
    try:
        # Get buyer email from order data or user document
        buyer_email = order_data.get(Fields.CUSTOMER_EMAIL)
        if not buyer_email:
            buyer_doc = get_db().collection(Collections.USERS).document(order_data[Fields.USER_ID]).get()
            if buyer_doc.exists:
                buyer_email = buyer_doc.to_dict().get(Fields.EMAIL)

        buyer_lang = order_data.get(Fields.PREFERRED_LANGUAGE, "en")
        if buyer_email:
            buyer_email_html = get_order_confirmation_email(order_data, order_id, lang=buyer_lang)

            # Generate PDF invoice attachment
            pdf_attachments = None
            try:
                import base64

                pdf_bytes = generate_invoice_pdf(order_data, order_id)
                if pdf_bytes:
                    short_oid = order_id[:8] if len(order_id) > 8 else order_id
                    pdf_attachments = [
                        {
                            "ContentType": "application/pdf",
                            "Filename": f"Origna_Invoice_{short_oid}.pdf",
                            "Base64Content": base64.b64encode(pdf_bytes).decode("utf-8"),
                        }
                    ]
            except Exception as e:
                logger.warning(f"PDF invoice generation failed (non-critical): {str(e)}")

            send_email(
                to_email=buyer_email,
                subject=_email_t("sub.confirmed", buyer_lang),
                html_content=buyer_email_html,
                attachments=pdf_attachments,
            )

        # Email to sellers — filter items per seller (multi-seller privacy)
        sellers = set(item[Fields.SELLER_ID] for item in order_data[Fields.ITEMS])
        for seller_id in sellers:
            # Get seller email from user document
            seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
            if seller_doc.exists:
                seller_data = seller_doc.to_dict()
                seller_email = seller_data.get(Fields.EMAIL)
                if seller_email:
                    seller_lang = seller_data.get(Fields.PREFERRED_LANGUAGE, "en")
                    seller_email_html = get_seller_notification_email(order_data, order_id, seller_id, lang=seller_lang)
                    send_email(
                        to_email=seller_email,
                        subject=_email_t("sub.new_order", seller_lang),
                        html_content=seller_email_html,
                    )
    except Exception as e:
        logger.error(f"Failed to send confirmation emails: {str(e)}")

    # Generate digital licenses for any digital items
    try:
        _generate_digital_licenses(order_id, order_data)
    except Exception as e:
        logger.error(f"Digital license generation failed for order {order_id}: {str(e)}")
        # Non-fatal: order is confirmed, license can be re-generated by admin

    # Redeem coupon if one was applied (N-07)
    try:
        applied_coupon_code = order_data.get(Fields.COUPON_CODE)
        if applied_coupon_code:
            from handlers.coupons import redeem_coupon as _redeem_coupon
            _redeem_coupon(applied_coupon_code, order_data[Fields.USER_ID], order_id=order_id)
    except Exception as e:
        logger.error(f"Failed to redeem coupon for order {order_id}: {str(e)}")

    # Clear user's cart
    try:
        _clear_user_cart(order_data[Fields.USER_ID])
    except Exception as e:
        logger.error(f"Failed to clear cart: {str(e)}")

    return f"Order {order_id} confirmed"


def _clear_user_cart(user_id: str) -> None:
    """Deletes all items from user's cart subcollection"""
    cart_ref = get_db().collection(Collections.USERS).document(user_id).collection(Collections.CART)
    cart_docs = cart_ref.stream()

    for doc in cart_docs:
        doc.reference.delete()


def process_async_payment_succeeded(session: dict) -> str | None:
    """Handles async payment success (e.g., bank transfers)"""
    order_id = session.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_ref.update({Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED, Fields.UPDATED_AT: get_server_timestamp()})

    try:
        OrderEvent.write(
            get_db(), order_id, OrderEventTypes.PAYMENT_CAPTURED,
            actor="stripe_webhook", actor_type="system",
            to_status=PaymentStatusValues.CAPTURED,
        )
    except Exception as e:
        logger.warning(f"Failed to write order event for {order_id}: {e}")

    return f"Order {order_id} payment captured"


def process_async_payment_failed(session: dict) -> str | None:
    """Handles async payment failure"""
    order_id = session.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if order_doc.exists:
        order_data = order_doc.to_dict()

        # Atomic: restore stock + mark order cancelled in a single batch
        batch = get_db().batch()

        if not order_data.get(Fields.STOCK_RESTORED, False):
            _add_stock_restore_to_batch(batch, order_data)

        batch.update(
            order_ref,
            {
                Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                Fields.PAYMENT_STATUS: PaymentStatusValues.PAYMENT_FAILED,
                Fields.STOCK_RESTORED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        batch.commit()

        try:
            OrderEvent.write(
                get_db(), order_id, OrderEventTypes.PAYMENT_FAILED,
                actor="stripe_webhook", actor_type="system",
                to_status=PaymentStatusValues.PAYMENT_FAILED,
            )
        except Exception as e:
            logger.warning(f"Failed to write order event for {order_id}: {e}")

    return f"Order {order_id} cancelled due to payment failure"


def _add_stock_restore_to_batch(batch, order_data: dict) -> None:
    """Adds stock increment operations to an existing batch."""
    global _firestore
    if _firestore is None:
        from firebase_admin import firestore as fs

        _firestore = fs

    for item in order_data.get(Fields.ITEMS, []):
        product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
        qty = item[Fields.QUANTITY]
        patch = {Fields.STOCK_QUANTITY: _firestore.Increment(qty)}

        fulfillment_wh = item.get(Fields.FULFILLMENT_WAREHOUSE_ID)
        if fulfillment_wh:
            patch[f"{Fields.WAREHOUSE_STOCK}.{fulfillment_wh}"] = _firestore.Increment(qty)
            # Also restore inventoryLevels subcollection (safe if doc doesn't exist yet — merge=True)
            inv_ref = product_ref.collection(Collections.INVENTORY_LEVELS).document(fulfillment_wh)
            batch.set(inv_ref, {
                Fields.AVAILABLE_QUANTITY: _firestore.Increment(qty),
                Fields.LAST_SYNCED_AT: get_server_timestamp(),
            }, merge=True)

        batch.update(product_ref, patch)


def _restore_stock_for_order(order_data: dict) -> None:
    """Restores product stock after order cancellation using batch write for atomicity."""
    batch = get_db().batch()
    _add_stock_restore_to_batch(batch, order_data)
    batch.commit()


def _restore_stock_and_cancel_order(order_id: str, order_data: dict, reason: str) -> None:
    """
    Restores stock and cancels order when validation fails post-payment.
    Uses batch write for atomicity — stock restore + order cancel in one commit.
    """
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)

    # Atomic: restore stock + cancel order in a single batch
    batch = get_db().batch()

    if not order_data.get(Fields.STOCK_RESTORED, False):
        _add_stock_restore_to_batch(batch, order_data)

    batch.update(
        order_ref,
        {
            Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
            Fields.PAYMENT_STATUS: PaymentStatusValues.CANCELLED,
            Fields.CANCELLATION_REASON: reason,
            Fields.STOCK_RESTORED: True,
            Fields.CANCELLED_AT: get_server_timestamp(),
            Fields.UPDATED_AT: get_server_timestamp(),
        },
    )
    batch.commit()

    # Refund/cancel the PaymentIntent to release buyer funds
    # With auto-capture, PI is in 'succeeded' state — must use refund, not cancel
    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    if payment_intent_id:
        refund_succeeded = False
        try:
            # Try to retrieve PI to check its current state
            ensure_stripe_key()
            pi = stripe.PaymentIntent.retrieve(payment_intent_id)
            if pi.status == "succeeded":
                # Auto-captured: must refund (cannot cancel a succeeded PI)
                stripe.Refund.create(
                    payment_intent=payment_intent_id,
                    reason="requested_by_customer",
                    metadata={Fields.ORDER_ID: order_id, Fields.REASON: reason[:500]},
                    idempotency_key=f"refund_invalidated_{order_id}",
                )
                refund_succeeded = True
            elif pi.status == "requires_capture":
                # Manual capture mode: cancel releases the authorization
                stripe.PaymentIntent.cancel(
                    payment_intent_id,
                    cancellation_reason="abandoned",
                )
                refund_succeeded = True
            elif pi.status in ("requires_payment_method", "requires_confirmation", "requires_action"):
                # Not yet charged: safe to cancel
                stripe.PaymentIntent.cancel(
                    payment_intent_id,
                    cancellation_reason="abandoned",
                )
                refund_succeeded = True
            else:
                logger.warning(f"⚠️ PI {payment_intent_id} in unexpected state: {pi.status}, skipping refund/cancel")
        except stripe.error.StripeError as e:
            logger.critical(f"🚨 CRITICAL: Failed to refund/cancel PI for invalidated order {order_id}: {str(e)}")
            # SECURITY FIX: If refund fails, flag for manual review — buyer must not lose money
            get_db().collection(Collections.SECURITY_ALERTS).add(
                {
                    Fields.TYPE: SecurityAlertTypes.REFUND_FAILED,
                    Fields.SEVERITY: SeverityLevels.CRITICAL,
                    Fields.ORDER_ID: order_id,
                    Fields.PAYMENT_INTENT_ID: payment_intent_id,
                    Fields.REASON: f"Refund/cancel failed during post-payment validation ({type(e).__name__}). Check logs.",
                    Fields.TIMESTAMP: get_server_timestamp(),
                    Fields.RESOLVED: False,
                }
            )

        # If refund failed, mark order for manual review instead of silently closing
        if not refund_succeeded:
            order_ref = get_db().collection(Collections.ORDERS).document(order_id)
            order_ref.update(
                {
                    Fields.REQUIRES_MANUAL_REVIEW: True,
                    Fields.MANUAL_REVIEW_REASON: f"Refund/cancel failed for invalidated order: {reason}",
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )


def process_session_expired(session: dict) -> str | None:
    """Handles expired checkout sessions"""
    order_id = session.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)

    @get_transactional()
    def _expire_in_transaction(transaction):
        order_doc = order_ref.get(transaction=transaction)
        if not order_doc.exists:
            return False

        order_data = order_doc.to_dict()

        # IDEMPOTENCY FIX: Only restore stock once per order (atomic via transaction)
        if not order_data.get(Fields.STOCK_RESTORED, False):
            global _firestore
            if _firestore is None:
                from firebase_admin import firestore as fs

                _firestore = fs
            for item in order_data.get(Fields.ITEMS, []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                transaction.update(product_ref, {Fields.STOCK_QUANTITY: _firestore.Increment(item[Fields.QUANTITY])})

        transaction.update(
            order_ref,
            {
                Fields.ORDER_STATUS: OrderStatusValues.EXPIRED,
                Fields.PAYMENT_STATUS: PaymentStatusValues.SESSION_EXPIRED,
                Fields.STOCK_RESTORED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return True

    _expire_in_transaction(get_db().transaction())

    return f"Order {order_id} expired"


def process_payment_intent_succeeded(payment_intent: dict) -> str | None:
    """Handles successful payment intents.

    SECURITY FIX (CRITICAL-024): Only update if payment is in a state that
    should transition to CAPTURED. Prevents overwriting 'authorized' set by
    checkout.session.completed (which uses manual capture mode).
    For manual capture mode orders, the capture_payment function handles the
    AUTHORIZED → CAPTURING → CAPTURED transition. This webhook fires when
    capture succeeds, so we only update if still in 'capturing' state.
    """
    order_id = payment_intent.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        return None

    order_data = order_doc.to_dict()
    current_status = order_data.get(Fields.PAYMENT_STATUS)

    # Only update to CAPTURED if order is in a transitional state.
    # If already CAPTURED, REFUNDED, etc., do not overwrite.
    capturable_states = {PaymentStatusValues.CAPTURING, PaymentStatusValues.AWAITING_PAYMENT}
    if current_status in capturable_states:
        order_ref.update(
            {Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED, Fields.UPDATED_AT: get_server_timestamp()}
        )
        return f"Payment captured for order {order_id}"

    if current_status == PaymentStatusValues.CAPTURED:
        return f"Payment already captured for order {order_id} (idempotent)"

    # For manual capture mode (authorized state), do NOT overwrite to captured.
    # The capture_payment function handles this transition properly.
    logger.info(f"ℹ️ payment_intent.succeeded for order {order_id} skipped: current status={current_status}")
    return f"Order {order_id} status unchanged (current: {current_status})"


def process_payment_intent_failed(payment_intent: dict) -> str | None:
    """Handles failed payment intents"""
    order_id = payment_intent.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)

    @get_transactional()
    def _fail_in_transaction(transaction):
        order_doc = order_ref.get(transaction=transaction)
        if not order_doc.exists:
            return False

        order_data = order_doc.to_dict()

        # CRITICAL FIX: Restore stock on payment failure (atomic via transaction)
        if not order_data.get(Fields.STOCK_RESTORED, False):
            global _firestore
            if _firestore is None:
                from firebase_admin import firestore as fs

                _firestore = fs
            for item in order_data.get(Fields.ITEMS, []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                transaction.update(product_ref, {Fields.STOCK_QUANTITY: _firestore.Increment(item[Fields.QUANTITY])})

        transaction.update(
            order_ref,
            {
                Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                Fields.PAYMENT_STATUS: PaymentStatusValues.PAYMENT_FAILED,
                Fields.STOCK_RESTORED: True,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return True

    _fail_in_transaction(get_db().transaction())

    return f"Payment failed for order {order_id}"


def process_payment_intent_canceled(payment_intent: dict) -> str | None:
    """
    Handles canceled payment intents.
    Restores stock and cancels the order when a PI is canceled
    (e.g., session expired, user abandon, or admin cancellation).
    """
    order_id = payment_intent.get("metadata", {}).get(Fields.ORDER_ID)

    if not order_id:
        return None

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)

    @get_transactional()
    def _cancel_in_transaction(transaction):
        order_doc = order_ref.get(transaction=transaction)
        if not order_doc.exists:
            return None

        order_data = order_doc.to_dict()

        # Skip if already in terminal state
        current_status = order_data.get(Fields.ORDER_STATUS)
        terminal_states = {OrderStatusValues.CANCELLED, OrderStatusValues.EXPIRED}
        if current_status in terminal_states:
            return f"already_terminal:{current_status}"

        # Restore stock idempotently (atomic via transaction)
        if not order_data.get(Fields.STOCK_RESTORED, False):
            global _firestore
            if _firestore is None:
                from firebase_admin import firestore as fs

                _firestore = fs
            for item in order_data.get(Fields.ITEMS, []):
                product_ref = get_db().collection(Collections.PRODUCTS).document(item[Fields.PRODUCT_ID])
                transaction.update(product_ref, {Fields.STOCK_QUANTITY: _firestore.Increment(item[Fields.QUANTITY])})

        transaction.update(
            order_ref,
            {
                Fields.ORDER_STATUS: OrderStatusValues.CANCELLED,
                Fields.PAYMENT_STATUS: PaymentStatusValues.CANCELLED,
                Fields.STOCK_RESTORED: True,
                Fields.CANCELLED_AT: get_server_timestamp(),
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return "cancelled"

    result = _cancel_in_transaction(get_db().transaction())
    if result and result.startswith("already_terminal:"):
        status = result.split(":")[1]
        return f"Order {order_id} already in terminal state: {status} (idempotent)"

    return f"Payment canceled for order {order_id}"


def process_charge_refunded(charge: dict) -> str | None:
    """
    Handles charge refunds — distinguishes full vs partial refunds.
    AUDIT FIX (CRITICAL-019): Automatically reverses transfers to sellers
    when a refund is processed, preventing platform financial loss.
    """
    payment_intent_id = charge.get("payment_intent")

    if not payment_intent_id:
        return None

    # Determine if full or partial refund
    amount_refunded = charge.get("amount_refunded", 0)
    amount_total = charge.get(Fields.AMOUNT, 0)
    is_full_refund = (amount_refunded >= amount_total) if amount_total > 0 else True

    # Find order by payment intent
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.STRIPE_PAYMENT_INTENT_ID, "==", payment_intent_id)
        .limit(1)
        .stream()
    )

    for order_doc in orders:
        order_ref = order_doc.reference
        order_id = order_doc.id
        order_data = order_doc.to_dict()

        # AUDIT FIX (CRITICAL-018): Block refund processing if capture or cancel is in progress.
        # This prevents the race condition where refund + capture execute simultaneously.
        current_payment_status = order_data.get(Fields.PAYMENT_STATUS, "")
        if current_payment_status in (PaymentStatusValues.CAPTURING, PaymentStatusValues.CANCELLING):
            logger.warning(
                f"⚠️ Refund webhook for order {order_id} blocked — payment status is {current_payment_status}"
            )
            # Return 500-equivalent to trigger Stripe retry (status will resolve by then)
            raise Exception(f"Order {order_id} has transitional payment status: {current_payment_status}. Retry later.")

        # SECURITY FIX (CRITICAL-017): Idempotency — check if this refund amount
        # was already processed to prevent duplicate reversals on webhook retry.
        previously_refunded = order_data.get(Fields.CUMULATIVE_REFUNDED_CENTS, 0)
        if previously_refunded >= amount_refunded:
            logger.info(
                f"ℹ️ Refund for order {order_id} already processed (cumulative={previously_refunded}, current={amount_refunded})"
            )
            return f"Order {order_id} refund already processed (idempotent)"

        # AUDIT FIX (CRITICAL-019): Reverse transfers to sellers on refund.
        # Without this, the platform refunds the buyer but sellers keep their payout.
        reversed_count = 0
        reversal_errors = []

        payouts = (
            get_db()
            .collection(Collections.PAYOUTS)
            .where(Fields.ORDER_ID, "==", order_id)
            .where(Fields.STATUS, "in", [PayoutStatusValues.COMPLETED, PayoutStatusValues.PARTIALLY_REVERSED])
            .stream()
        )

        for payout_doc in payouts:
            payout_data = payout_doc.to_dict()
            transfer_id = payout_data.get(Fields.STRIPE_TRANSFER_ID)

            if not transfer_id:
                continue

            # SECURITY FIX (HIGH-019): Calculate remaining reversible amount
            # to prevent over-reversal on multiple partial refunds.
            already_reversed_cents = payout_data.get(Fields.CUMULATIVE_REVERSED_CENTS, 0)
            payout_net = payout_data.get(Fields.NET_AMOUNT_CENTS, 0)
            max_reversible = payout_net - already_reversed_cents

            if max_reversible <= 0:
                logger.info(f"ℹ️ Payout {payout_doc.id} fully reversed already, skipping")
                continue

            try:
                reversal_kwargs = {
                    "metadata": {
                        Fields.REASON: "refund",
                        Fields.ORDER_ID: order_id,
                        "refundType": "full" if is_full_refund else "partial",
                    }
                }
                # For partial refunds, only reverse proportional amount
                # but cap at max_reversible to prevent over-reversal
                if not is_full_refund and amount_total > 0:
                    reversal_amount = round(payout_net * amount_refunded / amount_total)
                    reversal_amount = min(reversal_amount, max_reversible)
                    if reversal_amount > 0:
                        reversal_kwargs[Fields.AMOUNT] = reversal_amount
                else:
                    # Full refund: reverse remaining (not already reversed)
                    if already_reversed_cents > 0:
                        reversal_kwargs[Fields.AMOUNT] = max_reversible

                reversal = stripe.Transfer.create_reversal(transfer_id, **reversal_kwargs)

                # Calculate actual reversed amount for tracking
                actual_reversed = reversal_kwargs.get(Fields.AMOUNT, payout_net)
                new_cumulative = already_reversed_cents + actual_reversed
                new_status = (
                    PayoutStatusValues.REVERSED
                    if new_cumulative >= payout_net
                    else PayoutStatusValues.PARTIALLY_REVERSED
                )

                payout_doc.reference.update(
                    {
                        Fields.STATUS: new_status,
                        Fields.REVERSAL_ID: reversal.id,
                        Fields.REVERSED_AT: get_server_timestamp(),
                        Fields.REVERSAL_REASON: "refund",
                        Fields.CUMULATIVE_REVERSED_CENTS: new_cumulative,
                    }
                )
                reversed_count += 1
                logger.info(
                    f"✓ Reversed transfer {transfer_id} for refund on order {order_id} (amount={actual_reversed})"
                )

            except Exception as e:
                logger.warning(f"⚠️ Failed to reverse transfer {transfer_id} on refund: {str(e)}")
                reversal_errors.append({Fields.TRANSFER_ID: transfer_id, Fields.ERROR: type(e).__name__})

        # Log security alert and auto-suspend sellers if any reversals failed
        if reversal_errors:
            get_db().collection(Collections.SECURITY_ALERTS).add(
                {
                    Fields.TYPE: SecurityAlertTypes.REFUND_REVERSAL_FAILED,
                    Fields.SEVERITY: SeverityLevels.CRITICAL,
                    Fields.ORDER_ID: order_id,
                    Fields.REVERSAL_ERRORS: reversal_errors,
                    Fields.TIMESTAMP: get_server_timestamp(),
                    Fields.RESOLVED: False,
                }
            )

            # AUDIT FIX (CRITICAL-014): Auto-suspend sellers whose transfer reversals
            # failed (likely insufficient funds — seller withdrew). This prevents
            # further payouts until the platform recovers the funds.
            for err in reversal_errors:
                failed_transfer_id = err.get(Fields.TRANSFER_ID, "")
                if not failed_transfer_id:
                    continue
                # Find the seller for this failed transfer
                failed_payout = (
                    get_db()
                    .collection(Collections.PAYOUTS)
                    .where(Fields.STRIPE_TRANSFER_ID, "==", failed_transfer_id)
                    .limit(1)
                    .get()
                )
                for fp_doc in failed_payout:
                    fp_seller_id = fp_doc.to_dict().get(Fields.SELLER_ID)
                    if fp_seller_id:
                        try:
                            get_db().collection(Collections.USERS).document(fp_seller_id).update(
                                {
                                    Fields.SUSPENDED: True,
                                    Fields.SUSPENSION_REASON: f"Transfer reversal failed for order {order_id}. Manual review required.",
                                    Fields.SUSPENDED_AT: get_server_timestamp(),
                                }
                            )
                            logger.error(f"🚫 Auto-suspended seller {fp_seller_id} due to failed transfer reversal")
                        except Exception as suspend_err:
                            logger.critical(
                                f"🚨 CRITICAL: Failed to suspend seller {fp_seller_id} after transfer reversal failure: {type(suspend_err).__name__}"
                            )

        # Revoke digital licenses on any refund (lifetime license model — any refund invalidates)
        try:
            from handlers.digital import _revoke_digital_licenses_for_order

            revoked_count = _revoke_digital_licenses_for_order(order_id)
            if revoked_count:
                logger.info(f"Revoked {revoked_count} digital license(s) for refunded order {order_id}")
        except Exception as revoke_err:
            # Non-fatal: log but do not fail the refund webhook
            logger.error(f"License revocation failed for order {order_id}: {revoke_err}")

        if is_full_refund:
            order_ref.update(
                {
                    Fields.PAYMENT_STATUS: PaymentStatusValues.REFUNDED,
                    Fields.TRANSFERS_REVERSED: reversed_count,
                    Fields.CUMULATIVE_REFUNDED_CENTS: amount_refunded,
                    Fields.REFUNDED_AT: get_server_timestamp(),
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            return f"Order {order_id} fully refunded, reversed {reversed_count} transfers"
        else:
            order_ref.update(
                {
                    Fields.PAYMENT_STATUS: PaymentStatusValues.PARTIALLY_REFUNDED,
                    Fields.PARTIAL_REFUND_AMOUNT_CENTS: amount_refunded,
                    Fields.CUMULATIVE_REFUNDED_CENTS: amount_refunded,
                    Fields.TRANSFERS_REVERSED: reversed_count,
                    Fields.REFUNDED_AT: get_server_timestamp(),
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
            return f"Order {order_id} partially refunded ({amount_refunded} cents), reversed {reversed_count} transfers"

    return None


def process_dispute_created(dispute: dict) -> str | None:
    """
    Handles dispute creation - CRITICAL PAYMENT INTEGRITY
    When a buyer disputes a charge, we must immediately reverse transfers to sellers
    to prevent double-loss (platform refunds buyer + already paid seller).
    """
    charge_id = dispute.get("charge")
    # CRITICAL FIX: Use payment_intent from dispute (not charge_id!)
    # charge_id is 'ch_xxx' but orders store 'pi_xxx' as stripePaymentIntentId
    payment_intent_id = dispute.get("payment_intent")
    dispute_amount = dispute.get(Fields.AMOUNT, 0)

    # Log security alert (ORDER_ID added after lookup below)
    alert_ref = (
        get_db()
        .collection(Collections.SECURITY_ALERTS)
        .add(
            {
                Fields.TYPE: SecurityAlertTypes.DISPUTE_CREATED,
                Fields.SEVERITY: SeverityLevels.HIGH,
                Fields.CHARGE_ID: charge_id,
                Fields.PAYMENT_INTENT_ID: payment_intent_id,
                Fields.AMOUNT: dispute_amount,
                Fields.REASON: dispute.get(Fields.REASON),
                Fields.TIMESTAMP: get_server_timestamp(),
                Fields.RESOLVED: False,
            }
        )
    )

    if not payment_intent_id:
        logger.warning(f"⚠️ Dispute {dispute.get('id')} has no payment_intent, cannot find order")
        return f"Dispute logged for charge {charge_id}, no payment_intent to look up order"

    # CRITICAL: Auto-reverse all transfers linked to this payment intent
    orders = (
        get_db()
        .collection(Collections.ORDERS)
        .where(Fields.STRIPE_PAYMENT_INTENT_ID, "==", payment_intent_id)
        .limit(1)
        .stream()
    )

    reversed_count = 0
    for order_doc in orders:
        order_id = order_doc.id

        # CRITICAL FIX: Add ORDER_ID to security alert for capture-block query
        alert_ref[1].update({Fields.ORDER_ID: order_id})

        # Find all completed payouts for this order
        payouts = (
            get_db()
            .collection(Collections.PAYOUTS)
            .where(Fields.ORDER_ID, "==", order_id)
            .where(Fields.STATUS, "==", PayoutStatusValues.COMPLETED)
            .stream()
        )

        order_data_for_dispute = order_doc.to_dict()
        order_total = order_data_for_dispute.get(Fields.TOTAL_AMOUNT_CENTS, 0)

        for payout_doc in payouts:
            payout_data = payout_doc.to_dict()
            transfer_id = payout_data.get(Fields.STRIPE_TRANSFER_ID)

            if not transfer_id:
                # AUDIT FIX (D1-1): Alert on missing transfer ID instead of silent skip
                logger.error(f"🚨 DISPUTE: Payout {payout_doc.id} has no stripeTransferId — cannot reverse")
                # NOTE: Use datetime.now() inside ArrayUnion — Firestore SDK
                # cannot serialize SERVER_TIMESTAMP sentinels inside arrays.
                alert_ref[1].update(
                    {
                        Fields.REVERSAL_ERRORS: get_firestore().ArrayUnion(
                            [
                                {
                                    Fields.PAYOUT_ID: payout_doc.id,
                                    Fields.ERROR: "Missing stripeTransferId — manual reversal required",
                                    Fields.TIMESTAMP: datetime.now(UTC),
                                }
                            ]
                        )
                    }
                )
                continue

            try:
                # AUDIT FIX (MEDIUM-025): For partial disputes, reverse proportional
                # amount instead of full transfer to avoid penalizing uninvolved sellers.
                reversal_kwargs = {
                    "metadata": {
                        Fields.REASON: "dispute",
                        Fields.DISPUTE_ID: dispute.get("id"),
                        Fields.ORDER_ID: order_id,
                    }
                }
                payout_net = payout_data.get(Fields.NET_AMOUNT_CENTS, 0)

                # AUDIT FIX (D1-5): Track cumulative reversed cents to prevent double-reversal
                already_reversed_cents = payout_data.get(Fields.CUMULATIVE_REVERSED_CENTS, 0)
                max_reversible = payout_net - already_reversed_cents
                if max_reversible <= 0:
                    logger.info(f"✓ Transfer {transfer_id} already fully reversed (idempotent skip)")
                    continue

                if dispute_amount and order_total and dispute_amount < order_total:
                    proportional_reversal = round(payout_net * dispute_amount / order_total)
                    proportional_reversal = min(proportional_reversal, max_reversible)
                    if proportional_reversal > 0:
                        reversal_kwargs[Fields.AMOUNT] = proportional_reversal
                else:
                    # Full reversal — cap at max reversible
                    if max_reversible < payout_net:
                        reversal_kwargs[Fields.AMOUNT] = max_reversible

                reversal = stripe.Transfer.create_reversal(transfer_id, **reversal_kwargs)

                # Mark payout as reversed with cumulative tracking
                reversal_amount = reversal_kwargs.get(Fields.AMOUNT, payout_net)
                new_cumulative = already_reversed_cents + reversal_amount
                new_status = (
                    PayoutStatusValues.REVERSED
                    if new_cumulative >= payout_net
                    else PayoutStatusValues.PARTIALLY_REVERSED
                )
                payout_doc.reference.update(
                    {
                        Fields.STATUS: new_status,
                        Fields.REVERSAL_ID: reversal.id,
                        Fields.REVERSED_AT: get_server_timestamp(),
                        Fields.REVERSAL_REASON: "dispute",
                        Fields.CUMULATIVE_REVERSED_CENTS: new_cumulative,
                    }
                )

                reversed_count += 1
                logger.info(f"✓ Reversed transfer {transfer_id} due to dispute ({reversal_amount}¢)")

            except stripe.error.InvalidRequestError as e:
                # AUDIT FIX (D1-2): Handle specific Stripe errors (already reversed, insufficient funds)
                error_code = getattr(e, "code", "unknown")
                logger.warning(f"⚠️ Stripe error reversing transfer {transfer_id}: {error_code} - {str(e)}")
                is_insufficient = "insufficient" in str(e).lower()
                alert_ref[1].update(
                    {
                        Fields.REVERSAL_ERRORS: get_firestore().ArrayUnion(
                            [
                                {
                                    Fields.TRANSFER_ID: transfer_id,
                                    Fields.ERROR: f"{type(e).__name__}: {error_code}",
                                    Fields.ERROR_CODE: error_code,
                                    Fields.SEVERITY: SeverityLevels.CRITICAL
                                    if is_insufficient
                                    else SeverityLevels.HIGH,
                                    Fields.TIMESTAMP: datetime.now(UTC),
                                }
                            ]
                        )
                    }
                )

                # AUDIT FIX (CRITICAL-016): Auto-suspend seller on insufficient funds
                # This means the seller withdrew funds — block further payouts
                if is_insufficient:
                    seller_id_from_payout = payout_data.get(Fields.SELLER_ID)
                    if seller_id_from_payout:
                        try:
                            get_db().collection(Collections.USERS).document(seller_id_from_payout).update(
                                {
                                    Fields.SUSPENDED: True,
                                    Fields.SUSPENSION_REASON: f"Dispute reversal failed (insufficient funds) for dispute {dispute.get('id')}. Manual review required.",
                                    Fields.SUSPENDED_AT: get_server_timestamp(),
                                }
                            )
                            logger.info(
                                f"🚫 Auto-suspended seller {seller_id_from_payout} due to insufficient funds during dispute reversal"
                            )
                        except Exception as suspend_err:
                            logger.critical(
                                f"🚨 CRITICAL: Failed to suspend seller {seller_id_from_payout} after dispute reversal failure: {type(suspend_err).__name__}"
                            )

            except Exception as e:
                # Log failure but continue processing other transfers
                logger.warning(f"⚠️ Failed to reverse transfer {transfer_id}: {str(e)}")
                alert_ref[1].update(
                    {
                        Fields.REVERSAL_ERRORS: get_firestore().ArrayUnion(
                            [
                                {
                                    Fields.TRANSFER_ID: transfer_id,
                                    Fields.ERROR: type(e).__name__,
                                    Fields.TIMESTAMP: datetime.now(UTC),
                                }
                            ]
                        )
                    }
                )

        # AUDIT FIX (D1-3): Update order status to reflect dispute
        # Store pre-dispute status for restoration if dispute is won
        current_status = order_doc.to_dict().get(Fields.ORDER_STATUS, OrderStatusValues.PENDING)
        order_doc.reference.update(
            {
                Fields.ORDER_STATUS: OrderStatusValues.DISPUTED,
                Fields.PRE_DISPUTE_STATUS: current_status,
                Fields.DISPUTE_ID: dispute.get("id"),
                Fields.DISPUTED_AT: get_server_timestamp(),
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )

    # AUDIT FIX #32: Send dispute notification emails to affected sellers
    try:
        if order_doc and order_doc.exists:
            order_data = order_doc.to_dict()
            seller_ids = set(item.get(Fields.SELLER_ID) for item in order_data.get(Fields.ITEMS, []))
            for seller_id in seller_ids:
                if not seller_id:
                    continue
                seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
                if seller_doc.exists:
                    seller_email = seller_doc.to_dict().get(Fields.EMAIL)
                    if seller_email:
                        send_email(
                            to_email=seller_email,
                            subject="⚠️ Payment Dispute Received - Origna",
                            html_content=f"""
                            <h2>A payment dispute has been filed</h2>
                            <p>A buyer has filed a dispute for an order containing your products.</p>
                            <p><strong>Order ID:</strong> {order_id}</p>
                            <p><strong>Dispute reason:</strong> {dispute.get("reason", "Not specified")}</p>
                            <p><strong>Amount:</strong> ${dispute.get("amount", 0) / 100:.2f} {dispute.get("currency", "CAD").upper()}</p>
                            <p>Your seller transfers for this order have been reversed pending dispute resolution.</p>
                            <p>Please review your order records and prepare any evidence (shipping confirmation, delivery proof, communication) that may help resolve this dispute.</p>
                            <p>— Origna Team</p>
                            """,
                        )
    except Exception as e:
        logger.error(f"Failed to send dispute notification emails: {type(e).__name__}")

    return f"Dispute logged for charge {charge_id}, reversed {reversed_count} transfers"


def process_dispute_updated(dispute: dict) -> str | None:
    """
    Handles charge.dispute.updated — logs evidence updates and status changes.

    Stripe sends this when:
    - Evidence is submitted
    - Dispute status changes (e.g., needs_response → under_review)
    - Evidence due date changes
    """
    dispute_id = dispute.get("id")
    charge_id = dispute.get("charge")
    payment_intent_id = dispute.get("payment_intent")
    status = dispute.get(Fields.STATUS)
    reason = dispute.get(Fields.REASON)

    logger.info(f"Dispute updated: {dispute_id} status={status} reason={reason}")

    # Update security alert with latest dispute status
    if charge_id:
        alerts = (
            get_db()
            .collection(Collections.SECURITY_ALERTS)
            .where(Fields.CHARGE_ID, "==", charge_id)
            .where(Fields.TYPE, "==", SecurityAlertTypes.DISPUTE_CREATED)
            .limit(1)
            .stream()
        )

        for alert_doc in alerts:
            alert_doc.reference.update(
                {
                    Fields.STATUS: status,
                    Fields.REASON: reason,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )

    # Update order dispute status
    if payment_intent_id:
        orders = (
            get_db()
            .collection(Collections.ORDERS)
            .where(Fields.STRIPE_PAYMENT_INTENT_ID, "==", payment_intent_id)
            .limit(1)
            .stream()
        )

        for order_doc in orders:
            order_doc.reference.update(
                {
                    Fields.DISPUTE_STATUS: status,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )

    return f"Dispute updated: {dispute_id} → {status}"


def process_dispute_funds_reinstated(dispute: dict) -> str | None:
    """
    Handles charge.dispute.funds_reinstated — funds returned after dispute won.

    This is sent when Stripe returns funds to the platform after a won dispute.
    We log it and ensure the order/payout state is correct.
    """
    dispute_id = dispute.get("id")
    charge_id = dispute.get("charge")
    payment_intent_id = dispute.get("payment_intent")
    amount_reinstated = dispute.get(Fields.AMOUNT, 0)

    logger.info(f"Dispute funds reinstated: {dispute_id} amount={amount_reinstated}")

    # Log security alert for audit trail
    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.DISPUTE_CREATED,
            Fields.SEVERITY: SeverityLevels.LOW if amount_reinstated > 0 else SeverityLevels.HIGH,
            Fields.CHARGE_ID: charge_id,
            Fields.PAYMENT_INTENT_ID: payment_intent_id,
            Fields.AMOUNT: amount_reinstated,
            "event": "funds_reinstated",
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: True,
        }
    )

    return f"Funds reinstated for dispute {dispute_id}: {amount_reinstated} cents"


def process_dispute_closed(dispute: dict) -> str | None:
    """Handles dispute resolution — updates security alert AND order status."""
    charge_id = dispute.get("charge")
    status = dispute.get(Fields.STATUS)

    # Update security alert
    alerts = (
        get_db()
        .collection(Collections.SECURITY_ALERTS)
        .where(Fields.CHARGE_ID, "==", charge_id)
        .where(Fields.TYPE, "==", SecurityAlertTypes.DISPUTE_CREATED)
        .limit(1)
        .stream()
    )

    for alert_doc in alerts:
        alert_doc.reference.update(
            {Fields.RESOLVED: True, Fields.RESOLUTION: status, Fields.RESOLVED_AT: get_server_timestamp()}
        )

    # Update order status based on dispute outcome
    payment_intent_id = dispute.get("payment_intent")
    if payment_intent_id:
        orders = (
            get_db()
            .collection(Collections.ORDERS)
            .where(Fields.STRIPE_PAYMENT_INTENT_ID, "==", payment_intent_id)
            .limit(1)
            .stream()
        )

        for order_doc in orders:
            order_data = order_doc.to_dict()
            update_data = {
                Fields.DISPUTE_RESOLVED_AT: get_server_timestamp(),
                Fields.DISPUTE_RESOLUTION: status,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
            if status == "lost":
                update_data[Fields.ORDER_STATUS] = OrderStatusValues.CANCELLED
                update_data[Fields.CANCELLATION_REASON] = "Dispute lost"
            elif status == "won":
                # CRITICAL FIX: Restore pre-dispute status (not current 'disputed' status)
                pre_dispute_status = order_data.get(Fields.PRE_DISPUTE_STATUS, OrderStatusValues.CONFIRMED)
                update_data[Fields.ORDER_STATUS] = pre_dispute_status

                # CRITICAL FIX: Re-create seller transfers on won dispute
                # The transfers were reversed in process_dispute_created
                order_id = order_doc.id
                payouts = (
                    get_db()
                    .collection(Collections.PAYOUTS)
                    .where(Fields.ORDER_ID, "==", order_id)
                    .where(Fields.STATUS, "in", [PayoutStatusValues.REVERSED, PayoutStatusValues.PARTIALLY_REVERSED])
                    .stream()
                )

                re_transferred = 0
                for payout_doc in payouts:
                    payout_data = payout_doc.to_dict()
                    seller_stripe_id = payout_data.get(Fields.STRIPE_ACCOUNT_ID)
                    reversed_cents = payout_data.get(Fields.CUMULATIVE_REVERSED_CENTS, 0)

                    if not seller_stripe_id or reversed_cents <= 0:
                        continue

                    try:
                        new_transfer = stripe.Transfer.create(
                            amount=reversed_cents,
                            currency="cad",
                            destination=seller_stripe_id,
                            metadata={
                                Fields.ORDER_ID: order_id,
                                Fields.REASON: "dispute_won_re_transfer",
                                Fields.DISPUTE_ID: dispute.get("id", ""),
                            },
                            idempotency_key=f"dispute_won_retransfer_{order_id}_{payout_doc.id}",
                        )
                        payout_doc.reference.update(
                            {
                                Fields.STATUS: PayoutStatusValues.COMPLETED,
                                Fields.STRIPE_TRANSFER_ID: new_transfer.id,
                                Fields.CUMULATIVE_REVERSED_CENTS: 0,
                                Fields.UPDATED_AT: get_server_timestamp(),
                            }
                        )
                        re_transferred += 1
                        logger.info(f"\u2713 Re-transferred {reversed_cents}\u00a2 to seller after dispute won")
                    except Exception as e:
                        logger.error(f"\u26a0\ufe0f Failed to re-transfer to seller: {e}")
                        # AUDIT FIX: Sanitize exception before storing in Firestore
                        error_type = type(e).__name__
                        get_db().collection(Collections.SECURITY_ALERTS).add(
                            {
                                Fields.TYPE: SecurityAlertTypes.DISPUTE_CREATED,
                                Fields.SEVERITY: SeverityLevels.CRITICAL,
                                Fields.ORDER_ID: order_id,
                                Fields.ERROR_MESSAGE: f"Re-transfer failed after dispute won ({error_type}). Check logs.",
                                Fields.TIMESTAMP: get_server_timestamp(),
                                Fields.RESOLVED: False,
                            }
                        )

                if re_transferred > 0:
                    logger.info(f"Dispute won: re-transferred {re_transferred} payouts for order {order_id}")

            order_doc.reference.update(update_data)

            # AUDIT FIX #33: Send dispute resolution notification to sellers
            try:
                seller_ids = set(item.get(Fields.SELLER_ID) for item in order_data.get(Fields.ITEMS, []))
                outcome = "won (funds restored)" if status == "won" else "lost (order cancelled)"
                for seller_id in seller_ids:
                    if not seller_id:
                        continue
                    seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
                    if seller_doc.exists:
                        seller_email = seller_doc.to_dict().get(Fields.EMAIL)
                        if seller_email:
                            send_email(
                                to_email=seller_email,
                                subject=f"Dispute Resolved ({status.title()}) - Origna",
                                html_content=f"""
                                <h2>Dispute Resolution Update</h2>
                                <p>The dispute for order <strong>{order_doc.id}</strong> has been <strong>{outcome}</strong>.</p>
                                {"<p>Your seller transfers have been restored.</p>" if status == "won" else "<p>The order has been cancelled and no further action is needed.</p>"}
                                <p>— Origna Team</p>
                                """,
                            )
            except Exception as e:
                logger.error(f"Failed to send dispute resolution emails: {type(e).__name__}")

    return f"Dispute closed: {status}"


def process_transfer_reversed(transfer: dict) -> str | None:
    """Handles reversed payouts"""
    transfer_id = transfer.get("id")

    # Find payout by transfer ID
    payouts = (
        get_db().collection(Collections.PAYOUTS).where(Fields.STRIPE_TRANSFER_ID, "==", transfer_id).limit(1).stream()
    )

    for payout_doc in payouts:
        payout_doc.reference.update(
            {Fields.STATUS: PayoutStatusValues.REVERSED, Fields.UPDATED_AT: get_server_timestamp()}
        )

        return f"Payout {payout_doc.id} reversed"

    return None


def process_payout_failed(payout: dict) -> None:
    """Handles failed payouts — creates security alert AND updates payout records."""
    destination = payout.get(Fields.DESTINATION)
    _payout_id = payout.get("id")

    # Create security alert
    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.PAYOUT_FAILED,
            Fields.SEVERITY: SeverityLevels.HIGH,
            Fields.DESTINATION: destination,
            Fields.AMOUNT: payout.get(Fields.AMOUNT),
            Fields.FAILURE_MESSAGE: payout.get("failure_message"),
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: False,
        }
    )

    # Update payout record if it exists
    if destination:
        payout_docs = (
            get_db()
            .collection(Collections.PAYOUTS)
            .where(Fields.STRIPE_ACCOUNT_ID, "==", destination)
            .where(Fields.STATUS, "==", PayoutStatusValues.PENDING)
            .limit(5)
            .stream()
        )

        for payout_doc in payout_docs:
            payout_doc.reference.update(
                {
                    Fields.STATUS: PayoutStatusValues.FAILED,
                    Fields.FAILURE_MESSAGE: payout.get("failure_message", "Unknown failure"),
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )


def process_refund_failed(refund: dict) -> None:
    """Handles failed refunds"""
    charge_id = refund.get("charge")

    get_db().collection(Collections.SECURITY_ALERTS).add(
        {
            Fields.TYPE: SecurityAlertTypes.REFUND_FAILED,
            Fields.SEVERITY: SeverityLevels.CRITICAL,
            Fields.CHARGE_ID: charge_id,
            Fields.AMOUNT: refund.get(Fields.AMOUNT),
            Fields.FAILURE_REASON: refund.get("failure_reason"),
            Fields.TIMESTAMP: get_server_timestamp(),
            Fields.RESOLVED: False,
        }
    )


def process_account_updated(account: dict) -> None:
    """
    Process account.updated event from Stripe Connect.
    Updates the user's Firestore document when their Stripe account status changes.
    This is critical for enabling sellers after they complete onboarding.
    """
    logger.info("\n🏪 Processing: account.updated")

    account_id = account.get("id")
    if not account_id:
        logger.warning("  ⚠️ No account ID in event")
        return

    logger.info(f"  Account ID: {account_id}")
    logger.info(f"  Charges Enabled: {account.get('charges_enabled')}")
    logger.info(f"  Payouts Enabled: {account.get('payouts_enabled')}")
    logger.info(f"  Details Submitted: {account.get('details_submitted')}")
    requirements = account.get("requirements", {})
    currently_due = requirements.get("currently_due", []) or []
    if currently_due:
        logger.info(f"  Requirements Due: {currently_due}")

    # Find user with this Stripe account
    users = get_db().collection(Collections.USERS).where(Fields.STRIPE_ACCOUNT_ID, "==", account_id).limit(1).get()

    if not users:
        logger.warning(f"  ⚠️ No user found with Stripe account {account_id}")
        return

    user_ref = users[0].reference
    user_id = user_ref.id
    user_data = users[0].to_dict()

    logger.info(f"  User ID: {user_id}")

    # Pending requirements already extracted above for logging
    eventually_due = requirements.get("eventually_due", []) or []
    pending_requirements = list(set(currently_due + eventually_due))

    # Update user document with current account status
    update_data = {
        Fields.CHARGES_ENABLED: account.get("charges_enabled", False),
        Fields.PAYOUTS_ENABLED: account.get("payouts_enabled", False),
        Fields.ONBOARDING_COMPLETED: account.get("details_submitted", False),
        Fields.PENDING_REQUIREMENTS: pending_requirements,
        Fields.UPDATED_AT: get_server_timestamp(),
    }

    # Grant SELLER role only when FULLY approved: details submitted + charges enabled
    # This ensures KYC is complete before any seller privileges are granted
    if account.get("details_submitted", False) and account.get("charges_enabled", False):
        from firebase_admin import firestore as admin_firestore

        current_roles = user_data.get(Fields.ROLES, [])
        if UserRoleValues.SELLER not in current_roles:
            update_data[Fields.ROLES] = admin_firestore.ArrayUnion([UserRoleValues.SELLER])
            logger.info(f"  ✅ Adding seller role to user {user_id} (KYC fully approved)")

    user_ref.update(update_data)
    logger.info(f"  ✅ Updated user {user_id} Stripe account status")


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_connect_account(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Creates Stripe Connect account for seller onboarding"""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid
    data = req.data or {}

    # AUDIT FIX: Rate limit account creation
    allowed, message = get_rate_limiter().check_rate_limit(
        identifier=user_id, action="create_connect_account", max_requests=3, window_minutes=60, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", message)

    # Import validation functions
    from utils.helpers import sanitize_email

    # Get user data from Firestore to get email if not provided
    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User profile not found")

    user_data = user_doc.to_dict()

    # Block suspended users from creating Stripe accounts
    if user_data.get(Fields.SUSPENDED, False):
        raise https_fn.HttpsError("permission-denied", "Your account is suspended. You cannot register as a seller.")

    # Check if user already has a Stripe account
    existing_account_id = user_data.get(Fields.STRIPE_ACCOUNT_ID)
    if existing_account_id:
        # Return existing account instead of creating new one
        return {ApiKeys.SUCCESS: True, ApiKeys.ACCOUNT_ID: existing_account_id, ApiKeys.EXISTING: True}

    # Get email from request or user profile
    email_raw = data.get(Fields.EMAIL) or user_data.get(Fields.EMAIL)
    country = data.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_CODE)

    if not email_raw:
        raise https_fn.HttpsError(
            "invalid-argument", "Email is required. Please update your profile with a valid email."
        )

    # Validate and sanitize email
    try:
        email = sanitize_email(email_raw)
    except ValueError:
        raise https_fn.HttpsError(
            "invalid-argument", "Invalid email format. Please provide a valid email address."
        ) from None

    # Validate country code (ISO 3166-1 alpha-2)
    # Sellers can be from any Stripe-supported country — no CA-only restriction
    if not country or len(country) != 2 or not country.isalpha():
        raise https_fn.HttpsError(
            "invalid-argument", f"Invalid country code: {country}. Must be a 2-letter ISO country code."
        )

    try:
        account = stripe.Account.create(
            type="express",
            country=country,
            email=email,
            capabilities={"card_payments": {"requested": True}, "transfers": {"requested": True}},
            business_type="individual",
            metadata={Fields.USER_ID: user_id},
        )

        # Save account ID to Firestore — SELLER role granted only after full KYC approval
        # (via process_account_updated webhook or get_connect_account_status)
        user_ref.update(
            {
                Fields.STRIPE_ACCOUNT_ID: account.id,
                Fields.ONBOARDING_COMPLETED: False,
                Fields.CHARGES_ENABLED: False,
                Fields.PAYOUTS_ENABLED: False,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )

        return {ApiKeys.SUCCESS: True, ApiKeys.ACCOUNT_ID: account.id}

    except stripe.error.InvalidRequestError as e:
        logger.error(f"Stripe InvalidRequestError creating account: {e}")
        raise https_fn.HttpsError(
            "invalid-argument", "Invalid request. Please check your information and try again."
        ) from e
    except stripe.error.AuthenticationError:
        raise https_fn.HttpsError("internal", "Payment service configuration error. Please contact support.") from None
    except stripe.error.APIConnectionError:
        raise https_fn.HttpsError(
            "unavailable", "Could not connect to payment service. Please try again later."
        ) from None
    except stripe.error.StripeError as e:
        # Log the full error for debugging
        logger.error(f"Stripe error creating account: {str(e)}")
        raise https_fn.HttpsError("internal", "Could not create seller account. Please try again later.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def create_account_link(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Creates Stripe Connect onboarding link"""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # Rate limit: 5/min — each call creates a Stripe AccountLink (API cost)
    _limiter = get_rate_limiter()
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="create_account_link", max_requests=5, window_minutes=1, fail_closed=True
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    # Build URLs from server-side config only — never trust client URLs
    # This prevents open redirect attacks via malicious refreshUrl/returnUrl
    refresh_url = f"{BASE_URL}{AppConfig.SELLER_REFRESH_PATH}"
    return_url = f"{BASE_URL}{AppConfig.SELLER_RETURN_PATH}"

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    account_id = user_data.get(Fields.STRIPE_ACCOUNT_ID)

    if not account_id:
        raise https_fn.HttpsError(
            "failed-precondition",
            'You need to create an account first to become a seller. Please tap "Create Seller Account" to get started.',
        )

    try:
        # For Express accounts, always use account_onboarding
        # Stripe automatically shows any pending requirements
        account_link = stripe.AccountLink.create(
            account=account_id, refresh_url=refresh_url, return_url=return_url, type="account_onboarding"
        )

        return {ApiKeys.SUCCESS: True, ApiKeys.URL: account_link.url}

    except stripe.error.InvalidRequestError as e:
        raise https_fn.HttpsError("invalid-argument", "Invalid account configuration. Please contact support.") from e
    except stripe.error.APIConnectionError:
        raise https_fn.HttpsError(
            "unavailable", "Could not connect to payment service. Please try again later."
        ) from None
    except Exception as e:
        logger.error(f"Account link creation error: {e}")
        raise https_fn.HttpsError("internal", "Could not create onboarding link. Please try again later.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def get_connect_account_status(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Gets Stripe Connect account status"""
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    user_id = req.auth.uid

    # Rate limit: 10/min — each call hits Stripe API + Firestore write
    _limiter = get_rate_limiter()
    allowed, msg = _limiter.check_rate_limit(
        identifier=user_id, action="get_connect_account_status", max_requests=10, window_minutes=1, fail_closed=False
    )
    if not allowed:
        raise https_fn.HttpsError("resource-exhausted", msg)

    user_ref = get_db().collection(Collections.USERS).document(user_id)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise https_fn.HttpsError("not-found", "User not found")

    user_data = user_doc.to_dict()
    account_id = user_data.get(Fields.STRIPE_ACCOUNT_ID)

    if not account_id:
        raise https_fn.HttpsError(
            "failed-precondition",
            "You need to create an account first to become a seller. Please complete your seller registration.",
        )

    try:
        account = stripe.Account.retrieve(account_id)

        # Update Firestore with latest status
        from firebase_admin import firestore as admin_firestore

        requirements = account.requirements
        currently_due = list(requirements.currently_due or [])
        eventually_due = list(requirements.eventually_due or [])
        pending_requirements = list(set(currently_due + eventually_due))

        update_data = {
            Fields.CHARGES_ENABLED: account.charges_enabled,
            Fields.PAYOUTS_ENABLED: account.payouts_enabled,
            Fields.ONBOARDING_COMPLETED: account.details_submitted,
            Fields.PENDING_REQUIREMENTS: pending_requirements,
            Fields.UPDATED_AT: get_server_timestamp(),
        }

        # Only grant seller role if fully approved: onboarding + charges enabled + not suspended
        is_suspended = user_data.get(Fields.SUSPENDED, False)
        if account.details_submitted and account.charges_enabled and not is_suspended:
            update_data[Fields.ROLES] = admin_firestore.ArrayUnion([UserRoleValues.SELLER])

        user_ref.update(update_data)

        # Return dict directly for on_call functions
        return {
            ApiKeys.SUCCESS: True,
            Fields.CHARGES_ENABLED: account.charges_enabled,
            Fields.PAYOUTS_ENABLED: account.payouts_enabled,
            ApiKeys.DETAILS_SUBMITTED: account.details_submitted,
            ApiKeys.REQUIREMENTS_CURRENTLY_DUE: account.requirements.currently_due,
        }

    except stripe.error.InvalidRequestError as e:
        raise https_fn.HttpsError("invalid-argument", "Invalid account. Please contact support.") from e
    except stripe.error.APIConnectionError:
        raise https_fn.HttpsError(
            "unavailable", "Could not connect to payment service. Please try again later."
        ) from None
    except Exception as e:
        logger.error(f"Account status error: {str(e)}")
        raise https_fn.HttpsError("internal", "Could not retrieve account status. Please try again later.") from e


def _capture_payment_impl(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Internal implementation of capture_payment logic.
    Called by both the decorated capture_payment endpoint and confirm_order_receipt.
    """
    # Check if Stripe is enabled
    from handlers.payment_providers import PaymentProvider, require_provider_enabled

    require_provider_enabled(PaymentProvider.STRIPE)
    ensure_stripe_key()

    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    caller_uid = req.auth.uid
    order_id = req.data.get(Fields.ORDER_ID)

    if not order_id:
        raise https_fn.HttpsError("invalid-argument", "orderId required")

    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()

    if not order_doc.exists:
        raise https_fn.HttpsError("not-found", "Order not found")

    order_data = order_doc.to_dict()

    # CRITICAL SECURITY CHECK: Only order owner or admin can capture
    order_user_id = order_data.get(Fields.USER_ID)
    # FIX: Custom claims are set as {'admin': True/False}, not {Fields.ROLES: [...]}
    is_admin = req.auth.token.get(UserRoleValues.ADMIN, False)

    if caller_uid != order_user_id and not is_admin:
        raise https_fn.HttpsError("permission-denied", "Only the order owner or admin can capture this payment")

    # Verify order is in valid state for capture
    payment_status = order_data.get(Fields.PAYMENT_STATUS)
    order_status = order_data.get(Fields.ORDER_STATUS)

    # Idempotency: if already captured, return success
    if payment_status == PaymentStatusValues.CAPTURED:
        # Ensure buyer receipt confirmation is persisted (best-effort)
        if not order_data.get(Fields.CONFIRMED_BY_CLIENT):
            try:
                order_ref.update(
                    {
                        Fields.CONFIRMED_BY_CLIENT: True,
                        Fields.CONFIRMED_AT: get_server_timestamp(),
                        Fields.UPDATED_AT: get_server_timestamp(),
                    }
                )
            except Exception as confirm_err:
                logger.warning(f"⚠️ Failed to persist confirmed_by_client: {type(confirm_err).__name__}")

        # AUTO-CAPTURE MODE: Create seller payout records if none exist yet.
        # With automatic capture, payment is captured at checkout (not at delivery).
        # Seller payouts must still be recorded when buyer confirms receipt.
        try:
            existing_payouts = (
                get_db().collection(Collections.PAYOUTS).where(Fields.ORDER_ID, "==", order_id).limit(1).get()
            )
            if len(existing_payouts) == 0:
                items = order_data.get(Fields.ITEMS, [])
                stored_fee_total = order_data.get(Fields.PLATFORM_FEE_TOTAL_CENTS)
                subtotal_cents = order_data.get(Fields.SUBTOTAL_CENTS, 1)
                fee_rate = (
                    (stored_fee_total / subtotal_cents) if stored_fee_total and subtotal_cents else PLATFORM_FEE_PERCENT
                )

                sellers_total = {}
                for item in items:
                    item_status = item.get(Fields.STATUS, DeliveryStatusValues.PENDING)
                    if item_status in (DeliveryStatusValues.DELIVERED, DeliveryStatusValues.SHIPPED):
                        sid = item.get(Fields.SELLER_ID)
                        if sid:
                            amt = round(item.get(Fields.PRICE, 0) * 100) * item.get(Fields.QUANTITY, 1)
                            sellers_total[sid] = sellers_total.get(sid, 0) + amt

                # Retrieve charge_id for Stripe Transfers
                pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
                charge_id = None
                if pi_id:
                    try:
                        pi_obj = stripe.PaymentIntent.retrieve(pi_id)
                        charge_id = pi_obj.latest_charge
                    except Exception as pi_err:
                        logger.error(f"\u26a0\ufe0f Failed to retrieve PaymentIntent for charge_id: {pi_err}")

                for seller_id, amount_cents in sellers_total.items():
                    platform_fee_cents = round(amount_cents * fee_rate)
                    net_amount_cents = amount_cents - platform_fee_cents
                    payout_ref = get_db().collection(Collections.PAYOUTS).document(f"{order_id}_{seller_id}")
                    payout_data = {
                        Fields.ORDER_ID: order_id,
                        Fields.SELLER_ID: seller_id,
                        Fields.AMOUNT_CENTS: amount_cents,
                        Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                        Fields.NET_AMOUNT_CENTS: net_amount_cents,
                        Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
                        Fields.STATUS: PayoutStatusValues.PENDING,
                        Fields.CREATED_AT: get_server_timestamp(),
                    }
                    payout_ref.set(payout_data, merge=True)

                    # Attempt Stripe Transfer (may fail in emulator with fake accounts)
                    if charge_id:
                        seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
                        if seller_doc.exists:
                            acct_id = seller_doc.to_dict().get(Fields.STRIPE_ACCOUNT_ID)
                            if acct_id:
                                try:
                                    transfer = stripe.Transfer.create(
                                        amount=net_amount_cents,
                                        currency=BusinessRules.DEFAULT_CURRENCY,
                                        destination=acct_id,
                                        source_transaction=charge_id,
                                        transfer_group=order_id,
                                        metadata={Fields.ORDER_ID: order_id, Fields.SELLER_ID: seller_id},
                                        idempotency_key=f"transfer_{order_id}_{seller_id}",
                                    )
                                    payout_ref.update(
                                        {
                                            Fields.STRIPE_TRANSFER_ID: transfer.id,
                                            Fields.STATUS: PayoutStatusValues.COMPLETED,
                                        }
                                    )
                                except Exception as transfer_err:
                                    logger.warning(f"⚠️ Transfer to seller {seller_id} failed: {transfer_err}")
                                    payout_ref.update(
                                        {
                                            Fields.STATUS: PayoutStatusValues.FAILED,
                                            Fields.FAILURE_REASON: str(transfer_err),
                                        }
                                    )
        except Exception as payout_err:
            logger.warning(f"⚠️ Failed to create payout records for already-captured order {order_id}: {payout_err}")

        return {
            ApiKeys.SUCCESS: True,
            ApiKeys.CAPTURED: True,
            ApiKeys.MESSAGE: "Payment already captured",
            ApiKeys.PAYMENT_INTENT_ID: order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID),
        }

    # Verify order is in correct state (should be authorized/shipped)
    if payment_status != PaymentStatusValues.AUTHORIZED:
        raise https_fn.HttpsError("failed-precondition", f"Order payment not authorized (status: {payment_status})")

    if order_status not in [OrderStatusValues.SHIPPED, OrderStatusValues.IN_TRANSIT, OrderStatusValues.DELIVERED]:
        raise https_fn.HttpsError("failed-precondition", f"Order not shipped yet (status: {order_status})")

    # SECURITY: Check for active disputes before capturing
    dispute_alerts = (
        get_db()
        .collection(Collections.SECURITY_ALERTS)
        .where(Fields.TYPE, "==", SecurityAlertTypes.DISPUTE_CREATED)
        .where(Fields.RESOLVED, "==", False)
        .where(Fields.ORDER_ID, "==", order_id)
        .limit(1)
        .get()
    )

    if len(dispute_alerts) > 0:
        raise https_fn.HttpsError(
            "failed-precondition", "Cannot capture payment: active dispute on this order. Contact support."
        )

    payment_intent_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)

    if not payment_intent_id:
        raise https_fn.HttpsError("failed-precondition", "No payment intent found")

    # Track capture attempts to prevent infinite retries
    capture_attempts = order_data.get(Fields.CAPTURE_ATTEMPTS, 0)
    if capture_attempts >= BusinessRules.MAX_CAPTURE_ATTEMPTS:
        raise https_fn.HttpsError("failed-precondition", "Maximum capture attempts exceeded")

    # RACE CONDITION FIX: Atomically transition paymentStatus from AUTHORIZED → CAPTURING
    # This prevents two concurrent capture_payment calls from both proceeding.
    @get_transactional()
    def lock_for_capture(transaction):
        fresh_doc = order_ref.get(transaction=transaction)
        if not fresh_doc.exists:
            raise https_fn.HttpsError("not-found", "Order not found")
        fresh_data = fresh_doc.to_dict()
        if fresh_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.CAPTURED:
            return "already_captured"
        if fresh_data.get(Fields.PAYMENT_STATUS) != PaymentStatusValues.AUTHORIZED:
            raise https_fn.HttpsError(
                "failed-precondition",
                f"Order payment status changed concurrently (status: {fresh_data.get(Fields.PAYMENT_STATUS)})",
            )
        # Mark as "capturing" to block concurrent calls
        transaction.update(
            order_ref,
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURING,
                Fields.CAPTURE_ATTEMPTS: fresh_data.get(Fields.CAPTURE_ATTEMPTS, 0) + 1,
                Fields.UPDATED_AT: get_server_timestamp(),
            },
        )
        return "locked"

    lock_result = lock_for_capture(get_db().transaction())
    if lock_result == "already_captured":
        return {
            ApiKeys.SUCCESS: True,
            ApiKeys.CAPTURED: True,
            ApiKeys.MESSAGE: "Payment already captured (concurrent request)",
            ApiKeys.PAYMENT_INTENT_ID: payment_intent_id,
        }

    # Emulator mode: skip real Stripe capture for fake payment intents
    if IS_EMULATOR and payment_intent_id and not payment_intent_id.startswith("pi_3"):
        items = order_data.get(Fields.ITEMS, [])
        all_items_delivered = all(item.get(Fields.STATUS) == DeliveryStatusValues.DELIVERED for item in items)
        order_ref.update(
            {
                Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
                Fields.ORDER_STATUS: OrderStatusValues.DELIVERED if all_items_delivered else order_status,
                Fields.CONFIRMED_BY_CLIENT: True,
                Fields.CONFIRMED_AT: get_server_timestamp(),
                Fields.CAPTURED_AT: get_server_timestamp(),
                Fields.CAPTURE_ATTEMPTS: capture_attempts + 1,
                Fields.UPDATED_AT: get_server_timestamp(),
            }
        )
        return {
            ApiKeys.SUCCESS: True,
            ApiKeys.CAPTURED: True,
            ApiKeys.NEW_STATUS: OrderStatusValues.DELIVERED if all_items_delivered else order_status,
            ApiKeys.EMULATOR_MODE: True,
            Fields.PAYOUT_ERRORS: False,
        }

    try:
        # Validate PI is in capturable state
        payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        if payment_intent.status != "requires_capture":
            raise https_fn.HttpsError(
                "failed-precondition", f"Payment cannot be captured (status: {payment_intent.status})"
            )

        # Validate capture amount matches order total (both in cents)
        expected_amount_cents = order_data.get(Fields.TOTAL_AMOUNT_CENTS, 0)

        if payment_intent.amount != expected_amount_cents:
            raise https_fn.HttpsError(
                "failed-precondition",
                f"Payment amount mismatch: expected {expected_amount_cents} cents, got {payment_intent.amount} cents",
            )

        # SECURITY FIX: Calculate payouts first to detect issues BEFORE identifying as captured
        items = order_data.get(Fields.ITEMS, [])
        all_items_delivered = all(
            item.get(Fields.STATUS, DeliveryStatusValues.PENDING) == DeliveryStatusValues.DELIVERED for item in items
        )

        # Create payouts ONLY for sellers whose items are DELIVERED
        # SECURITY FIX: Removed PENDING fallback — only pay for confirmed deliveries
        sellers_total_cents = {}
        for item in items:
            item_status = item.get(Fields.STATUS, DeliveryStatusValues.PENDING)
            if item_status == DeliveryStatusValues.DELIVERED:
                seller_id = item[Fields.SELLER_ID]
                # Price is in dollars, convert to cents
                item_price_cents = round(item[Fields.PRICE] * 100)
                item_total_cents = item_price_cents * item[Fields.QUANTITY]
                sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total_cents

        # Capture the payment (with idempotency key to prevent duplicate captures)
        # Note: we might only want to capture a partial amount if this was partial fulfillment,
        # but for now we capture the full amount (downstream refund logic handles the rest if needed).
        payment_intent = stripe.PaymentIntent.capture(
            payment_intent_id, idempotency_key=f"capture_{order_id}_{payment_intent_id}"
        )

        # CRITICAL FIX: Resolve Charge ID from captured PaymentIntent.
        # Stripe Transfer.create requires a Charge ID (ch_xxx), NOT a PaymentIntent ID (pi_xxx).
        charge_id = payment_intent.latest_charge
        if not charge_id:
            raise https_fn.HttpsError(
                "internal", f"No charge found after capturing PI {payment_intent_id}. Cannot create transfers."
            )

        # SECURITY FIX (CRITICAL-003): Capture-Dispute Race Window
        # Check if a dispute was filed exactly as we captured
        charge = stripe.Charge.retrieve(charge_id)
        if charge.dispute:
            logger.error(f"🚨 CRITICAL: Charge {charge_id} for order {order_id} is already disputed! Aborting payouts.")
            # Update order status to reflect dispute, skipping payouts
            get_db().collection(Collections.ORDERS).document(order_id).update(
                {Fields.PAYMENT_STATUS: PaymentStatusValues.DISPUTED, Fields.UPDATED_AT: get_server_timestamp()}
            )
            raise https_fn.HttpsError(
                "failed-precondition", "Payment is currently disputed and cannot be processed for payout."
            )

        # Execute Transfers / Payouts
        transfer_errors = []

        # AUDIT FIX (CRITICAL-001): Use fee rate stored at checkout, not current config.
        # Prevents config manipulation between checkout and capture.
        stored_fee_total = order_data.get(Fields.PLATFORM_FEE_TOTAL_CENTS)
        stored_fee_rate = (
            (stored_fee_total / order_data.get(Fields.SUBTOTAL_CENTS, 1)) if stored_fee_total else PLATFORM_FEE_PERCENT
        )

        for seller_id, amount_cents in sellers_total_cents.items():
            # Platform fee in cents — use stored rate from checkout, fallback to config
            platform_fee_cents = round(amount_cents * stored_fee_rate)
            net_amount_cents = amount_cents - platform_fee_cents

            # SECURITY FIX (CRITICAL-014): Use snapshotted stripeAccountId from checkout.
            # Falls back to live lookup if snapshot not available (old orders).
            seller_account_snapshot = order_data.get(Fields.SELLER_STRIPE_ACCOUNTS, {})
            snapshot_account_id = seller_account_snapshot.get(seller_id)

            # Get seller's current data for suspension/charges checks
            seller_ref = get_db().collection(Collections.USERS).document(seller_id)
            seller_doc = seller_ref.get()

            if seller_doc.exists:
                seller_data = seller_doc.to_dict()
                # Prefer snapshot (immutable at checkout), fall back to live
                stripe_account_id = snapshot_account_id or seller_data.get(Fields.STRIPE_ACCOUNT_ID)

                # SECURITY: Warn if account changed since checkout (potential fraud)
                live_account_id = seller_data.get(Fields.STRIPE_ACCOUNT_ID)
                if snapshot_account_id and live_account_id and snapshot_account_id != live_account_id:
                    logger.error(
                        f"🚨 SECURITY: Seller {seller_id} Stripe account changed since checkout! "
                        f"Using snapshot: {snapshot_account_id[:12]}..., live: {live_account_id[:12]}..."
                    )
                    get_db().collection(Collections.SECURITY_ALERTS).add(
                        {
                            Fields.TYPE: SecurityAlertTypes.SELLER_ACCOUNT_CHANGED,
                            Fields.SEVERITY: SeverityLevels.HIGH,
                            Fields.ORDER_ID: order_id,
                            Fields.SELLER_ID: seller_id,
                            Fields.SNAPSHOT_ACCOUNT_ID: snapshot_account_id,
                            Fields.LIVE_ACCOUNT_ID: live_account_id,
                            Fields.TIMESTAMP: get_server_timestamp(),
                            Fields.RESOLVED: False,
                        }
                    )

                # CRITICAL SECURITY: Re-verify seller is not suspended at capture time
                # Prevents race condition where seller suspended after checkout but before capture
                if seller_data.get(Fields.SUSPENDED, False):
                    logger.warning(f"⚠️ Skipping payout to suspended seller {seller_id} for order {order_id}")
                    # Mark for manual review
                    order_ref.update(
                        {
                            Fields.REQUIRES_MANUAL_REVIEW: True,
                            Fields.MANUAL_REVIEW_REASON: f"Seller {seller_id} suspended at capture time",
                        }
                    )
                    continue

                # Verify seller has valid Stripe account
                if not stripe_account_id:
                    logger.warning(f"⚠️ Seller {seller_id} has no Stripe account for order {order_id}")
                    continue

                # Verify seller account is enabled for charges
                if not seller_data.get(Fields.CHARGES_ENABLED, False):
                    logger.warning(f"⚠️ Seller {seller_id} account not enabled for charges for order {order_id}")
                    order_ref.update(
                        {
                            Fields.REQUIRES_MANUAL_REVIEW: True,
                            Fields.MANUAL_REVIEW_REASON: f"Seller {seller_id} account not charges_enabled",
                        }
                    )
                    continue

                if stripe_account_id:
                    # Check for existing transfer (idempotency)
                    existing_payout = (
                        get_db()
                        .collection(Collections.PAYOUTS)
                        .where(Fields.ORDER_ID, "==", order_id)
                        .where(Fields.SELLER_ID, "==", seller_id)
                        .where(Fields.STATUS, "==", PayoutStatusValues.COMPLETED)
                        .limit(1)
                        .get()
                    )

                    if len(existing_payout) > 0:
                        # Transfer already completed for this seller, skip
                        continue

                    try:
                        # AUDIT FIX (CRITICAL-011): Create PENDING payout record BEFORE Stripe transfer.
                        # This ensures we always have a record even if transfer succeeds but Firestore update fails.
                        payout_ref = (
                            get_db()
                            .collection(Collections.PAYOUTS)
                            .document(
                                f"{order_id}_{seller_id}"  # Deterministic ID for idempotency
                            )
                        )
                        payout_data = {
                            Fields.ORDER_ID: order_id,
                            Fields.SELLER_ID: seller_id,
                            Fields.AMOUNT_CENTS: amount_cents,
                            Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
                            Fields.NET_AMOUNT_CENTS: net_amount_cents,
                            Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
                            Fields.STRIPE_ACCOUNT_ID: stripe_account_id,
                            Fields.STATUS: PayoutStatusValues.PENDING,
                            Fields.CREATED_AT: get_server_timestamp(),
                        }
                        payout_ref.set(payout_data, merge=True)

                        # Create transfer to seller (amount already in cents)
                        # SECURITY: idempotency_key prevents double-payouts at Stripe API level
                        # CRITICAL: source_transaction requires Charge ID (ch_xxx), not PI ID
                        transfer = stripe.Transfer.create(
                            amount=net_amount_cents,
                            currency=BusinessRules.DEFAULT_CURRENCY,
                            destination=stripe_account_id,
                            source_transaction=charge_id,
                            transfer_group=order_id,
                            metadata={
                                Fields.ORDER_ID: order_id,
                                Fields.SELLER_ID: seller_id,
                                Fields.METADATA_PLATFORM_FEE: platform_fee_cents,
                            },
                            idempotency_key=f"transfer_{order_id}_{seller_id}",
                        )

                        # Update payout record to COMPLETED with transfer ID (retry up to 3 times)
                        payout_recorded = False
                        for payout_attempt in range(3):
                            try:
                                payout_ref.update(
                                    {
                                        Fields.STRIPE_TRANSFER_ID: transfer.id,
                                        Fields.STATUS: PayoutStatusValues.COMPLETED,
                                    }
                                )
                                payout_recorded = True
                                break
                            except Exception as fs_err:
                                import time as _time

                                logger.warning(
                                    f"⚠️ Payout record update attempt {payout_attempt + 1}/3 failed for order {order_id}, seller {seller_id}: {str(fs_err)}"
                                )
                                if payout_attempt < 2:
                                    _time.sleep(2**payout_attempt)
                        if not payout_recorded:
                            # Transfer succeeded but COMPLETED status not recorded.
                            # PENDING record still exists with seller/order info for reconciliation.
                            logger.critical(
                                f"🚨 CRITICAL: Payout record stuck in PENDING for order {order_id}, seller {seller_id}, transfer {transfer.id}"
                            )
                            try:
                                get_db().collection(Collections.SECURITY_ALERTS).add(
                                    {
                                        Fields.TYPE: SecurityAlertTypes.PAYOUT_RECORD_INCOMPLETE,
                                        Fields.SEVERITY: SeverityLevels.CRITICAL,
                                        Fields.ORDER_ID: order_id,
                                        Fields.SELLER_ID: seller_id,
                                        Fields.STRIPE_TRANSFER_ID: transfer.id,
                                        Fields.AMOUNT_CENTS: net_amount_cents,
                                        "note": "PENDING payout record exists — update to COMPLETED manually",
                                        Fields.TIMESTAMP: get_server_timestamp(),
                                        Fields.RESOLVED: False,
                                    }
                                )
                            except Exception as alert_err:
                                logger.critical(
                                    f"🚨 Failed to create security alert for stuck payout: {type(alert_err).__name__}"
                                )
                    except Exception as e:
                        logger.error(f"Transfer error to seller {seller_id}: {str(e)}")
                        transfer_errors.append({Fields.SELLER_ID: seller_id, Fields.ERROR: type(e).__name__})

        # Update order status AFTER transfers to ensure consistency
        update_data = {
            Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
            Fields.ORDER_STATUS: OrderStatusValues.DELIVERED if all_items_delivered else order_status,
            Fields.CAPTURED_AT: get_server_timestamp(),
            Fields.CONFIRMED_BY_CLIENT: True,
            Fields.CONFIRMED_AT: get_server_timestamp(),
            Fields.CAPTURE_ATTEMPTS: capture_attempts + 1,
            Fields.UPDATED_AT: get_server_timestamp(),
        }

        if transfer_errors:
            # Log errors but still mark captured (since money was taken), but add flag
            update_data[Fields.PAYOUT_ERRORS] = transfer_errors
            update_data[Fields.REQUIRES_MANUAL_REVIEW] = True
            logger.error(f"Payout errors for order {order_id}: {transfer_errors}")

        order_ref.update(update_data)

        return {
            ApiKeys.SUCCESS: True,
            ApiKeys.CAPTURED: True,
            ApiKeys.NEW_STATUS: update_data[Fields.ORDER_STATUS],
            Fields.PAYOUT_ERRORS: len(transfer_errors) > 0,
        }

    except https_fn.HttpsError:
        # Rollback 'capturing' state to 'authorized' so the order isn't stuck
        try:
            order_ref.update(
                {
                    Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
        except Exception as rollback_err:
            logger.critical(f"🚨 CRITICAL: Failed to rollback capture state for order: {type(rollback_err).__name__}")
        raise
    except Exception as e:
        # Rollback 'capturing' state to 'authorized' so the order isn't stuck
        try:
            order_ref.update(
                {
                    Fields.PAYMENT_STATUS: PaymentStatusValues.AUTHORIZED,
                    Fields.UPDATED_AT: get_server_timestamp(),
                }
            )
        except Exception as rollback_err:
            logger.critical(f"🚨 CRITICAL: Failed to rollback capture state for order: {type(rollback_err).__name__}")
        error_msg = str(e).lower()
        logger.error(f"Capture payment error: {str(e)}")

        # Handle Stripe-specific errors by checking exception type name
        exc_type_name = type(e).__name__

        # Handle expired authorization (InvalidRequestError with 'expired' in message)
        if "expired" in error_msg:
            raise https_fn.HttpsError(
                "failed-precondition", "Payment authorization has expired. Please create a new order."
            ) from e

        # Handle card errors (3DS required, card declined, etc.)
        if exc_type_name == "CardError":
            # Handle 3DS required at capture time (rare edge case for manual captures)
            if getattr(e, "code", None) == "authentication_required":
                raise https_fn.HttpsError(
                    "failed-precondition",
                    "Payment requires additional verification. Please contact support to complete this payment.",
                ) from e
            user_message = (
                getattr(e, "user_message", None) or "Your card was declined. Please try a different payment method."
            )
            raise https_fn.HttpsError("failed-precondition", user_message) from e

        # Handle other Stripe API errors
        if exc_type_name in ("InvalidRequestError", "StripeError"):
            logger.error(f"Stripe error during capture: {e}")
            raise https_fn.HttpsError("failed-precondition", "Payment capture failed. Please contact support.") from e

        raise https_fn.HttpsError("internal", "Could not capture payment. Please try again.") from e


@https_fn.on_call(**DEFAULT_OPTIONS)
def capture_payment(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    Manually captures authorized payment and initiates seller payouts.
    Called when buyer confirms order receipt.
    Thin wrapper around _capture_payment_impl for HTTP callable endpoint.
    """
    return _capture_payment_impl(req)


def sanitize_metadata(metadata: dict[str, Any]) -> dict[str, Any]:
    """
    Sanitize metadata fields before storing in Stripe or Firestore.
    Firestore handles NoSQL injection, but we validate inputs for safety.

    Args:
        metadata: Dictionary of metadata to sanitize

    Returns:
        Sanitized metadata dictionary
    """
    if not isinstance(metadata, dict):
        return {}

    # For Firestore NoSQL, metadata is stored as-is, no SQL injection risk
    # But we validate field types to ensure data integrity
    sanitized = {}
    for key, value in metadata.items():
        # Allow strings, numbers, booleans, None
        if isinstance(value, (str, int, float, bool, type(None))):
            sanitized[key] = value
        # Convert other types to strings
        else:
            sanitized[key] = str(value)

    return sanitized
