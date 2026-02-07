"""
Schema Constants - Single Source of Truth for Field Names

This module defines all Firestore field names as constants to:
1. Eliminate magic strings throughout the codebase
2. Enable IDE autocomplete and refactoring
3. Catch typos at import time rather than runtime
4. Provide a single place to update field names

USAGE:
    from schema_constants import Fields, Collections, Enums

    # Instead of: doc.get('createdAt')
    # Use: doc.get(Fields.CREATED_AT)

    # Instead of: db.collection('orders')
    # Use: db.collection(Collections.ORDERS)

NAMING CONVENTION:
    - Python constants: UPPER_SNAKE_CASE (e.g., CREATED_AT)
    - Firestore fields: camelCase (e.g., 'createdAt')
    - The value is the actual Firestore field name

See: docs/database_schema.json for full schema documentation
"""

from enum import Enum
from typing import Dict, Set, FrozenSet


# =============================================================================
# COLLECTIONS - Top-level Firestore collection names
# =============================================================================

class Collections:
    """Firestore collection names"""
    USERS = "users"
    PRODUCTS = "products"
    ORDERS = "orders"
    PAYOUTS = "payouts"
    REFUNDS = "refunds"
    WEBHOOK_LOGS = "webhook_logs"
    WEBHOOK_EVENTS = "webhook_events"
    SECURITY_ALERTS = "security_alerts"
    RATE_LIMITS = "rate_limits"
    CONFIG = "config"
    ADMIN_LOGS = "admin_logs"
    PRODUCT_RATINGS = "product_ratings"

    # Subcollections
    CART = "cart"  # users/{userId}/cart
    FAVORITES = "favorites"  # users/{userId}/favorites


# =============================================================================
# FIELD NAMES - All Firestore document field names
# =============================================================================

class Fields:
    """
    Firestore document field names.

    IMPORTANT: These are the canonical field names. All code MUST use these
    constants instead of string literals to prevent drift.

    Convention:
    - Timestamps: Use CREATED_AT for creation time across ALL collections
    - IDs: Use {entity}Id pattern (e.g., userId, productId, orderId)
    - Amounts: Use {name}Cents for money (e.g., subtotalCents, taxAmountCents)
    """

    # === COMMON TIMESTAMPS (used across multiple collections) ===
    CREATED_AT = "createdAt"
    UPDATED_AT = "updatedAt"
    DELETED_AT = "deletedAt"
    DELETED_BY = "deletedBy"

    # === USER FIELDS ===
    UID = "uid"
    EMAIL = "email"
    NAME = "name"
    ROLES = "roles"
    ADDRESS = "address"
    CUSTOMER_ID = "customerId"
    LAST_CHECKOUT_SESSION = "lastCheckoutSession"
    LAST_ORDER_ID = "lastOrderId"
    LAST_CHECKOUT_TIMESTAMP = "lastCheckoutTimestamp"
    STRIPE_ACCOUNT_ID = "stripeAccountId"
    PAYOUTS_ENABLED = "payoutsEnabled"
    CHARGES_ENABLED = "chargesEnabled"
    ONBOARDING_COMPLETED = "onboardingCompleted"
    PENDING_REQUIREMENTS = "pendingRequirements"
    PAYMENT_PROVIDER = "paymentProvider"
    AIRWALLEX_ACCOUNT_ID = "airwallexAccountId"
    AIRWALLEX_CUSTOMER_ID = "airwallexCustomerId"
    AIRWALLEX_STATUS = "airwallexStatus"
    SUSPENDED = "suspended"
    SUSPENDED_AT = "suspendedAt"
    UNSUSPENDED_AT = "unsuspendedAt"
    SUSPENDED_BY = "suspendedBy"
    SUSPENSION_REASON = "suspensionReason"
    COMMISSION_RATE = "commissionRate"
    VERIFIED = "verified"
    VERIFICATION_STATUS = "verificationStatus"
    PLATFORM = "platform"
    BUSINESS_NAME = "businessName"
    PAYOUT_HOLD_DAYS = "payoutHoldDays"
    MFA_ENABLED = "mfaEnabled"
    MFA_SECRET = "mfaSecret"
    MFA_SECRET_TEMP = "mfaSecretTemp"
    LAST_MFA_VERIFY = "lastMfaVerify"
    LAST_ROLE_UPDATE = "lastRoleUpdate"
    LAST_ROLE_UPDATE_BY = "lastRoleUpdateBy"

    # === PRODUCT FIELDS ===
    PRODUCT_ID = "productId"
    PRICE = "price"
    DESCRIPTION = "description"
    IMAGE_URLS = "imageUrls"
    SELLER_ID = "sellerId"
    SELLER_ADDRESS = "sellerAddress"
    CATEGORY_ID = "categoryId"
    STOCK_QUANTITY = "stockQuantity"
    RATING = "rating"
    RATING_COUNT = "ratingCount"
    KEYWORDS = "keywords"
    IS_ACTIVE = "isActive"
    DATE_CREATED = "dateCreated"  # NOTE: Products use dateCreated (legacy)
    IS_DIGITAL = "isDigital"
    WEIGHT_KG = "weightKg"
    LENGTH_CM = "lengthCm"
    WIDTH_CM = "widthCm"
    HEIGHT_CM = "heightCm"
    IS_LOCAL_DELIVERY_ONLY = "isLocalDeliveryOnly"
    IS_PERISHABLE = "isPerishable"
    ESTIMATED_SHIP_DAYS = "estimatedShipDays"
    DELIVERY_OPTIONS = "deliveryOptions"
    MINIMUM_ORDER_QUANTITY = "minimumOrderQuantity"
    FREE_SHIPPING = "freeShipping"
    TAX_CODE = "taxCode"
    SUPPLIER = "supplier"
    INVENTORY = "inventory"
    STATUS = "status"
    DELIVERY_SPEED = "deliverySpeed"

    # === ORDER FIELDS ===
    ORDER_ID = "orderId"
    USER_ID = "userId"
    CUSTOMER_EMAIL = "customerEmail"
    ITEMS = "items"
    SELLER_IDS = "sellerIds"
    SUBTOTAL_CENTS = "subtotalCents"
    TAXES = "taxes"
    TAX_AMOUNT_CENTS = "taxAmountCents"
    SHIPPING_COST_CENTS = "shippingCostCents"
    TOTAL_AMOUNT_CENTS = "totalAmountCents"
    CURRENCY = "currency"
    ORDER_STATUS = "orderStatus"
    PAYMENT_STATUS = "paymentStatus"
    SHIPPING_ADDRESS = "shippingAddress"
    STRIPE_SESSION_ID = "stripeSessionId"
    STRIPE_PAYMENT_INTENT_ID = "stripePaymentIntentId"
    CAPTURE_ATTEMPTS = "captureAttempts"
    CAPTURED_AT = "capturedAt"
    EXPIRES_AT = "expiresAt"
    CONFIRMED_BY_CLIENT = "confirmedByClient"
    CONFIRMED_AT = "confirmedAt"
    AUTO_CONFIRMED = "autoConfirmed"
    AUTO_CAPTURED = "autoCaptured"
    SELLER_PAYOUTS = "sellerPayouts"
    PLATFORM_FEE_TOTAL = "platformFeeTotal"
    PAYOUT_STATUS = "payoutStatus"
    RATINGS = "ratings"
    REFUND_AMOUNT = "refundAmount"
    REFUNDED_AT = "refundedAt"
    SHIPPING_APPROVAL_STATUS = "shippingApprovalStatus"
    SHIPPING_APPROVAL_REQUIRED = "shippingApprovalRequired"
    ACTUAL_SHIPPING = "actualShipping"
    PENDING_TOTAL = "pendingTotal"
    SHIPPING_APPROVAL = "shippingApproval"
    STOCK_RESTORED = "stockRestored"
    CANCELLED_BY = "cancelledBy"
    CANCELLED_AT = "cancelledAt"
    CANCELLATION_REASON = "cancellationReason"
    RESPONDED_AT = "respondedAt"
    ACTUAL_COST = "actualCost"
    REQUIRES_MANUAL_REVIEW = "requiresManualReview"
    MANUAL_REVIEW_REASON = "manualReviewReason"
    PAYOUT_ERRORS = "payoutErrors"

    # === ORDER ITEM FIELDS ===
    QUANTITY = "quantity"
    TRACKING_NUMBER = "trackingNumber"
    CARRIER = "carrier"
    SHIPPED_AT = "shippedAt"
    DELIVERED_AT = "deliveredAt"
    REFUND_REASON = "refundReason"
    REFUND_AMOUNT_CENTS = "refundAmountCents"
    REFUND_ID = "refundId"
    CONFIRMED_BY_BUYER = "confirmedByBuyer"
    DELIVERY_STATUS = "deliveryStatus"  # DEPRECATED: Use STATUS

    # === PAYOUT FIELDS ===
    AMOUNT_CENTS = "amountCents"
    PLATFORM_FEE_CENTS = "platformFeeCents"
    NET_AMOUNT_CENTS = "netAmountCents"
    STRIPE_TRANSFER_ID = "stripeTransferId"
    REVERSAL_ID = "reversalId"
    PARTIAL_REVERSALS = "partialReversals"
    DISPUTE_ID = "disputeId"
    FAILURE_REASON = "failureReason"
    PAYOUT_DATE = "payoutDate"
    REVERSED_AT = "reversedAt"

    # === WEBHOOK FIELDS ===
    EVENT_ID = "eventId"
    EVENT_TYPE = "eventType"
    PAYLOAD_SIZE = "payloadSize"
    SIGNATURE_VERIFIED = "signatureVerified"
    PROCESSING_STATUS = "processingStatus"
    ERROR_MESSAGE = "errorMessage"
    RECEIVED_AT = "receivedAt"
    PROCESSED = "processed"
    PROCESSED_AT = "processedAt"
    LIVEMODE = "livemode"

    # === ADDRESS FIELDS ===
    FORMATTED_ADDRESS = "formattedAddress"
    STREET = "street"
    APARTMENT = "apartment"
    CITY = "city"
    STATE = "state"
    POSTAL_CODE = "postalCode"
    COUNTRY = "country"
    PHONE_NUMBER = "phoneNumber"
    IS_DEFAULT = "isDefault"
    LABEL = "label"
    LATITUDE = "latitude"
    LONGITUDE = "longitude"

    # === PAYOUT/REFUND COMMON FIELDS ===
    PROVIDER = "provider"
    AMOUNT = "amount"
    COMPLETED_AT = "completedAt"
    FAILED_AT = "failedAt"
    ERROR = "error"
    PAYMENT_ID = "paymentId"

    # === SECURITY ALERT FIELDS ===
    TYPE = "type"
    SEVERITY = "severity"
    RESOLVED = "resolved"
    RESOLVED_AT = "resolvedAt"
    RESOLUTION = "resolution"
    TIMESTAMP = "timestamp"
    CHARGE_ID = "chargeId"
    ACCOUNT_ID = "accountId"
    REASON = "reason"
    DESTINATION = "destination"
    FAILURE_MESSAGE = "failureMessage"
    ADMIN_ID = "adminId"

    # === WEBHOOK EVENT FIELDS ===
    CLIENT_IP = "clientIp"

    # === FAVORITES FIELDS ===
    DATE_FAVORITED = 'dateFavorited'
    # NOTE: Cart items use DATE_CREATED, not CREATED_AT


# =============================================================================
# ENUM VALUES - Valid values for enum fields
# =============================================================================

class OrderStatusValues:
    """Valid values for orderStatus field"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    FAILED = "failed"
    EXPIRED = "expired"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"

    ALL: FrozenSet[str] = frozenset({
        PENDING, CONFIRMED, PROCESSING, SHIPPED, IN_TRANSIT,
        DELIVERED, CANCELLED, FAILED, EXPIRED, REFUNDED, PARTIALLY_REFUNDED
    })


class PaymentStatusValues:
    """Valid values for paymentStatus field"""
    AWAITING_PAYMENT = "awaiting_payment"
    PROCESSING = "processing"
    PAID = "paid"
    PAYMENT_FAILED = "payment_failed"
    REFUNDED = "refunded"
    SESSION_EXPIRED = "session_expired"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    CANCELLED = "cancelled"
    AUTHORIZATION_EXPIRED = "authorization_expired"

    ALL: FrozenSet[str] = frozenset({
        AWAITING_PAYMENT, PROCESSING, PAID, PAYMENT_FAILED,
        REFUNDED, SESSION_EXPIRED, AUTHORIZED, CAPTURED,
        CANCELLED, AUTHORIZATION_EXPIRED
    })


class DeliveryStatusValues:
    """Valid values for deliveryStatus/status field on order items"""
    PENDING = "pending"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    REFUNDED = "refunded"

    ALL: FrozenSet[str] = frozenset({PENDING, SHIPPED, DELIVERED, REFUNDED})


class PayoutStatusValues:
    """Valid values for payoutStatus field"""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    PARTIAL = "partial"
    FAILED = "failed"
    REVERSED = "reversed"
    REVERSED_DISPUTE = "reversed_dispute"

    ALL: FrozenSet[str] = frozenset({
        PENDING, PROCESSING, COMPLETED, PARTIAL, FAILED, REVERSED, REVERSED_DISPUTE
    })


class UserRoleValues:
    """Valid values for roles array"""
    ADMIN = "admin"
    SELLER = "seller"
    BUYER = "buyer"

    ALL: FrozenSet[str] = frozenset({ADMIN, SELLER, BUYER})


class ProductStatusValues:
    """Valid values for product status field"""
    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    ARCHIVED = "archived"
    OUT_OF_STOCK = "out_of_stock"

    ALL: FrozenSet[str] = frozenset({DRAFT, ACTIVE, PAUSED, ARCHIVED, OUT_OF_STOCK})


class ShippingApprovalStatusValues:
    """Valid values for shipping approval status"""
    NOT_REQUIRED = "not_required"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

    ALL: FrozenSet[str] = frozenset({NOT_REQUIRED, PENDING, APPROVED, REJECTED})


class WebhookStatusValues:
    """Valid values for webhook processing status"""
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

    ALL: FrozenSet[str] = frozenset({PROCESSING, COMPLETED, FAILED})


# =============================================================================
# SCHEMA REGISTRY - For contract testing
# =============================================================================

class SchemaRegistry:
    """
    Registry of expected fields per collection.
    Used by contract tests to validate code matches schema.
    """

    # Required fields per collection (must exist in every document)
    REQUIRED_FIELDS: Dict[str, Set[str]] = {
        Collections.USERS: {
            Fields.UID, Fields.EMAIL, Fields.NAME, Fields.ROLES, Fields.CREATED_AT
        },
        Collections.PRODUCTS: {
            Fields.NAME, Fields.PRICE, Fields.DESCRIPTION, Fields.IMAGE_URLS,
            Fields.SELLER_ID, Fields.SELLER_ADDRESS, Fields.CATEGORY_ID,
            Fields.STOCK_QUANTITY, Fields.DATE_CREATED  # Products use dateCreated
        },
        Collections.ORDERS: {
            Fields.USER_ID, Fields.ITEMS, Fields.SUBTOTAL_CENTS, Fields.TAX_AMOUNT_CENTS,
            Fields.SHIPPING_COST_CENTS, Fields.TOTAL_AMOUNT_CENTS, Fields.ORDER_STATUS,
            Fields.PAYMENT_STATUS, Fields.SHIPPING_ADDRESS, Fields.CREATED_AT
        },
        Collections.PAYOUTS: {
            Fields.ORDER_ID, Fields.SELLER_ID, Fields.AMOUNT_CENTS,
            Fields.PLATFORM_FEE_CENTS, Fields.NET_AMOUNT_CENTS, Fields.STATUS,
            Fields.CREATED_AT
        },
    }

    # Timestamp field mapping (which field name each collection uses)
    TIMESTAMP_FIELD: Dict[str, str] = {
        Collections.USERS: Fields.CREATED_AT,
        Collections.PRODUCTS: Fields.DATE_CREATED,  # Legacy: uses dateCreated
        Collections.ORDERS: Fields.CREATED_AT,
        Collections.PAYOUTS: Fields.CREATED_AT,
        Collections.CART: Fields.DATE_CREATED,  # Subcollection: uses dateCreated
    }

    @classmethod
    def get_timestamp_field(cls, collection: str) -> str:
        """Get the correct timestamp field name for a collection."""
        return cls.TIMESTAMP_FIELD.get(collection, Fields.CREATED_AT)

    @classmethod
    def validate_field_name(cls, collection: str, field_name: str) -> bool:
        """Check if a field name is valid for a collection."""
        # Get all defined fields
        all_fields = {v for k, v in Fields.__dict__.items() if not k.startswith('_')}
        return field_name in all_fields


# =============================================================================
# BUSINESS CONSTANTS
# =============================================================================

class BusinessRules:
    """Business rule constants"""
    PLATFORM_FEE_PERCENT = 2.5
    AUTO_CONFIRM_DAYS = 5  # Must be < AUTHORIZATION_EXPIRY_DAYS (2-day safety margin)
    AUTHORIZATION_EXPIRY_DAYS = 7
    MAX_CAPTURE_ATTEMPTS = 3
    DEFAULT_CURRENCY = "cad"
    ALLOWED_COUNTRIES = frozenset({"Canada", "CA"})

    # Tax rates by province
    TAX_RATES: Dict[str, Dict[str, float]] = {
        "AB": {"GST": 5.0},
        "BC": {"GST": 5.0, "PST": 7.0},
        "MB": {"GST": 5.0, "PST": 7.0},
        "NB": {"HST": 15.0},
        "NL": {"HST": 15.0},
        "NS": {"HST": 15.0},
        "NT": {"GST": 5.0},
        "NU": {"GST": 5.0},
        "ON": {"HST": 13.0},
        "PE": {"HST": 15.0},
        "QC": {"GST": 5.0, "QST": 9.975},
        "SK": {"GST": 5.0, "PST": 6.0},
        "YT": {"GST": 5.0},
    }


# =============================================================================
# CATEGORY IDS
# =============================================================================

class CategoryIds:
    """Product category IDs"""
    ELECTRONICS = 1
    COMPUTERS = 2
    GAMING = 3
    HOME_KITCHEN = 4
    FASHION = 5
    SHOES_ACCESSORIES = 6
    JEWELRY_WATCHES = 7
    BEAUTY_PERSONAL_CARE = 8
    HEALTH_WELLNESS = 9
    SPORTS_FITNESS = 10
    AUTOMOTIVE = 11
    TOOLS_HARDWARE = 12
    OFFICE_SUPPLIES = 13
    BOOKS = 14
    MUSIC_INSTRUMENTS = 15
    TOYS_GAMES = 16
    BABY_KIDS = 17
    PET_SUPPLIES = 18
    GROCERIES = 19
    ART_COLLECTIBLES = 20
    DIGITAL_PRODUCTS = 21

    MIN = 1
    MAX = 21


class ApiKeys:
    """Cloud Function API parameter and response keys.
    These are NOT Firestore fields — they are the contract between
    Flutter and Cloud Functions (request params + response keys).
    """
    # === REQUEST PARAMS (sent to Cloud Functions) ===
    ADD = "add"
    REMOVE = "remove"
    REASON = "reason"
    CODE = "code"
    PROVIDER = "provider"
    ENABLED = "enabled"
    REFRESH_URL = "refreshUrl"
    RETURN_URL = "returnUrl"

    # === RESPONSE KEYS (returned from Cloud Functions) ===
    CHECKOUT_URL = "checkoutUrl"
    SESSION_ID = "sessionId"
    URL = "url"
    SECRET = "secret"
    QR_CODE_URL = "qrCodeUrl"
    DETAILS_SUBMITTED = "detailsSubmitted"
    REQUIREMENTS_CURRENTLY_DUE = "requirementsCurrentlyDue"

    # === PAYMENT PROVIDER RESPONSE KEYS ===
    PROVIDERS = "providers"
    CONFIGURED = "configured"
    MISSING_KEYS = "missingKeys"
    ENABLED_PROVIDERS = "enabledProviders"
