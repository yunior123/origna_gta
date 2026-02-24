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
    REVIEW_VOTES = "review_votes"  # subcollection of product_ratings/{ratingId}
    ALGOLIA_SYNC_FAILURES = "algolia_sync_failures"
    CRON_LOCKS = "_cron_locks"

    # Return tracking
    RETURN_REQUESTS = "return_requests"

    # Temporary pre-verification storage (cleared after user doc creation)
    PENDING_PROFILES = "pending_profiles"  # pending_profiles/{uid}

    # Subcollections
    WAREHOUSES = "warehouses"  # users/{sellerId}/warehouses
    CART = "cart"  # users/{userId}/cart
    FAVORITES = "favorites"  # users/{userId}/favorites
    NOTIFICATIONS = "notifications"  # users/{uid}/notifications
    FCM_TOKENS = "fcm_tokens"  # users/{uid}/fcm_tokens — multi-device push tokens
    LICENSES = "licenses"
    BOOK_ACCESS_TOKENS = "book_access_tokens"
    SOFTWARE_ACCESS_TOKENS = "software_access_tokens"
    ADDRESSES = "addresses"  # users/{userId}/addresses  (TASK 05: buyer address book)
    STOCK_NOTIFICATIONS = "stock_notifications"  # TASK 07: back-in-stock
    PRODUCT_QUESTIONS = "product_questions"  # TASK 09: product Q&A
    SELLER_METRICS = "seller_metrics"  # TASK 11: seller health metrics
    COUPONS = "coupons"  # N-07: coupon/promo code system
    INVENTORY_LEVELS = "inventoryLevels"  # products/{productId}/inventoryLevels/{warehouseId}
    ORDER_EVENTS = "events"  # Subcollection under orders/{orderId}/events/{eventId}
    COUPON_USES = "coupon_uses"  # Subcollection under coupons/{couponId} — replaces usedByUids array

    # Security (backend-only)
    USER_SECURITY = "user_security"  # Backend-only MFA secrets — allow read: if false
    SELLER_PROFILES = "seller_profiles"  # Seller-only profile data — buyers never have this doc

    # Premium & Chat
    SUBSCRIPTIONS = "subscriptions"  # top-level: subscriptions/{userId}
    CHATS = "chats"  # top-level: chats/{chatId}
    CHAT_MESSAGES = "messages"  # subcollection: chats/{chatId}/messages/{msgId}


class Documents:
    """Singleton document IDs within collections"""

    PAYMENT_PROVIDERS = "payment_providers"


# =============================================================================
# APPLICATION CONSTANTS
# =============================================================================

APP_NAME = "Origna Marketplace"
"""Canonical application name used in TOTP provisioning, emails, etc."""

COUNTRY_CANADA = "Canada"
"""Country name constant for Canada (enforced for buyers)"""


# =============================================================================
# EMAIL & APP CONFIGURATION CONSTANTS
# =============================================================================


class EmailConfig:
    """Email sending configuration constants."""

    SUPPORT_EMAIL = "support@orignaventures.ca"
    SENDER_NAME = "Origna GTA"
    SENDER_NAME_SECURITY = "Origna GTA Security"
    COPYRIGHT_TEXT = "\u00a9 2026 Origna Ventures Inc. All rights reserved."
    APP_TAGLINE = "Canada's Modern Marketplace"
    URL_PROD = "https://orignagta.ca"
    URL_STAGING = "https://orignagta-staging.web.app"
    URL_DEV = "https://orignagta-dev.web.app"
    URL_EMULATOR = "http://localhost:5005"
    MAILJET_API_VERSION = "v3.1"

    # === CASL COMPLIANCE (Canadian Anti-Spam Legislation) ===
    # Physical mailing address — REQUIRED by CASL in every commercial email
    PHYSICAL_ADDRESS = "Origna Ventures Inc., 136 Shaver Ave N, Toronto, ON M9B 4N8, Canada"
    # GST/HST Registration Number — REQUIRED on all receipts (Excise Tax Act)
    GST_HST_NUMBER = "708286364RC0001"
    # Unsubscribe URL — REQUIRED by CASL
    UNSUBSCRIBE_URL_PROD = "https://orignagta.ca/unsubscribe"
    UNSUBSCRIBE_URL_STAGING = "https://orignagta-staging.web.app/unsubscribe"
    UNSUBSCRIBE_URL_DEV = "https://orignagta-dev.web.app/unsubscribe"
    UNSUBSCRIBE_URL_EMULATOR = "http://localhost:5005/unsubscribe"
    # Privacy Officer contact — REQUIRED by Quebec Law 25 (since Sept 2022)
    # NOTE: Using support@ until dedicated privacy@ mailbox is provisioned
    PRIVACY_OFFICER_EMAIL = "support@orignaventures.ca"
    PRIVACY_OFFICER_NAME = "Yunior Rodriguez Osorio"


class AppConfig:
    """Application-wide configuration constants."""

    PLATFORM_NAME = "origna_gta"
    DEFAULT_COUNTRY_CODE = "CA"
    DEFAULT_COUNTRY_NAME = "Canada"
    API_TIMEOUT_SECONDS = 30
    GEOAPIFY_TIMEOUT_SECONDS = 5
    TOKEN_CACHE_MINUTES = 25
    ALGOLIA_MAX_RETRIES = 3
    ALGOLIA_HITS_PER_PAGE = 20
    PROD_WEB_URL = "https://orignagta.web.app"
    SITE_URL = "https://orignagta.ca"
    CHECKOUT_SUCCESS_PATH = "/payment-success"
    CHECKOUT_CANCEL_PATH = "/payment-cancel"
    SELLER_REFRESH_PATH = "/seller/refresh"
    SELLER_RETURN_PATH = "/seller/return"

    # Canonical CORS origins — use this list in all handlers
    CORS_ORIGINS: list[str] = [
        # Production
        "https://orignagta.ca",
        "https://www.orignagta.ca",
        "https://orignagta.web.app",
        "https://orignagta.firebaseapp.com",
        # Dev & Staging Firebase hosting
        "https://orignagta-dev.web.app",
        "https://orignagta-dev.firebaseapp.com",
        "https://orignagta-staging.web.app",
        "https://orignagta-staging.firebaseapp.com",
        # Local development (Firebase Emulator & Flutter Web)
        "http://localhost:5005",  # Firebase Emulator hosting / Flutter Web
        "http://localhost:5001",  # Firebase Functions (for preflight checks)
    ]


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
    SAVED_AT = "savedAt"  # N-05: Save for Later timestamp
    CREATED_AT = "createdAt"
    UPDATED_AT = "updatedAt"
    VERSION = "version"  # Optimistic concurrency version, starts at 1
    DELETED_AT = "deletedAt"
    DELETED_BY = "deletedBy"
    DELETED = "deleted"
    ANONYMIZED_AT = "anonymizedAt"
    ORIGINAL_USER_DELETED = "originalUserDeleted"

    # === USER FIELDS ===
    UID = "uid"
    EMAIL = "email"
    NAME = "name"
    ROLES = "roles"
    ADDRESS = "address"
    SELLER_PROFILE = "sellerProfile"
    BUSINESS_ADDRESS = "businessAddress"
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
    SUSPENDED = "suspended"
    SUSPENDED_AT = "suspendedAt"
    UNSUSPENDED_AT = "unsuspendedAt"
    UNSUSPENDED_BY = "unsuspendedBy"
    SUSPENDED_BY = "suspendedBy"
    SUSPENSION_REASON = "suspensionReason"
    COMMISSION_RATE = "commissionRate"  # DEPRECATED: use COMMISSION_RATE_BPS
    COMMISSION_RATE_BPS = "commissionRateBps"  # 250 = 2.50% (basis points — avoids float precision)
    VERIFIED = "verified"
    VERIFICATION_STATUS = "verificationStatus"
    PLATFORM = "platform"
    BUSINESS_NAME = "businessName"
    FULL_NAME = "fullName"
    IS_CORPORATE = "isCorporate"
    BANK_DETAILS = "bankDetails"
    PAYOUT_HOLD_DAYS = "payoutHoldDays"
    AVG_RATING = "avgRating"
    TOTAL_REVIEWS = "totalReviews"
    TOTAL_SALES = "totalSales"
    BANK_ACCOUNT_LAST4 = "bankAccountLast4"
    ACCEPTS_RETURNS = "acceptsReturns"
    RETURN_WINDOW_DAYS_FIELD = "returnWindowDays"  # seller-profile field; see BusinessRules.RETURN_WINDOW_DAYS for default value
    MFA_ENABLED = "mfaEnabled"
    MFA_SECRET = "mfaSecret"
    MFA_SECRET_TEMP = "mfaSecretTemp"
    MFA_BACKUP_CODES = "mfaBackupCodes"
    MFA_BACKUP_CODES_TEMP = "mfaBackupCodesTemp"
    MFA_BACKUP_CODES_SALT = "mfaBackupCodesSalt"
    MFA_FAILED_ATTEMPTS = "mfaFailedAttempts"
    MFA_LOCKOUT_UNTIL = "mfaLockoutUntil"
    MFA_ENROLLED_AT = "mfaEnrolledAt"
    LAST_MFA_VERIFY = "lastMfaVerify"
    LAST_ROLE_UPDATE = "lastRoleUpdate"
    LAST_ROLE_UPDATE_BY = "lastRoleUpdateBy"

    # === PRODUCT FIELDS ===
    PRODUCT_ID = "productId"
    PRICE = "price"
    COMPARE_AT_PRICE = "compareAtPrice"  # Original/crossed-out price for sale display
    COMPARE_AT_PRICE_HISTORY = "compareAtPriceHistory"
    DESCRIPTION = "description"
    NAME_F = "nameF"  # French product name (Quebec Bill 96)
    DESCRIPTION_F = "descriptionF"  # French product description
    IMAGE_URLS = "imageUrls"
    SELLER_ID = "sellerId"
    SELLER_ADDRESS = "sellerAddress"
    SELLER_SKU = "sellerSku"
    WAREHOUSE_IDS = "warehouseIds"
    WAREHOUSE_STOCK = "warehouseStock"
    WAREHOUSE_STOCK_MAP = "warehouseStockMap"  # per-warehouse stock allocation: {warehouseId: qty}
    FULFILLMENT_WAREHOUSE_ID = "fulfillmentWarehouseId"  # TASK 02: warehouse used to fulfill this order item
    SHIP_FROM_CITY = "shipFromCity"
    SHIP_FROM_PROVINCE = "shipFromProvince"
    SHIP_FROM_COUNTRY = "shipFromCountry"
    SHIP_FROM_COUNTRIES = "shipFromCountries"
    PRIMARY_WAREHOUSE_ID = "primaryWarehouseId"
    CATEGORY_ID = "categoryId"
    STOCK_QUANTITY = "stockQuantity"
    RATING = "rating"
    RATING_COUNT = "ratingCount"
    REVIEW = "review"
    KEYWORDS = "keywords"
    SEARCH_KEYWORDS = "searchKeywords"
    IS_ACTIVE = "isActive"  # DEPRECATED — use LIFECYCLE_STATUS
    APPROVAL_STATUS = "approvalStatus"  # DEPRECATED — use LIFECYCLE_STATUS
    APPROVAL_REJECTION_REASON = "approvalRejectionReason"
    LIFECYCLE_STATUS = "lifecycleStatus"
    IS_DIGITAL = "isDigital"
    # Digital product extended fields
    DIGITAL_TYPE = "digitalType"
    SLUG = "slug"
    DIGITAL_BUILDS = "digitalBuilds"
    BOOK_SOURCE_URL = "bookSourceUrl"
    DEVICE_LIMIT = "deviceLimit"
    LICENSE_KEY = "licenseKey"
    DIGITAL_UNLOCKED = "digitalUnlocked"
    SUPPORTED_PLATFORMS = "supportedPlatforms"
    ACTIVATIONS = "activations"
    DEVICE_ID = "deviceId"
    LAST_VERIFIED_AT = "lastVerifiedAt"
    ACCESS_TOKEN = "accessToken"
    BOOK_ACCESS_TOKEN = "bookAccessToken"
    PRODUCT_NAME = "productName"  # stored in license doc; denormalized from product
    WEIGHT_KG = "weightKg"
    LENGTH_CM = "lengthCm"
    WIDTH_CM = "widthCm"
    HEIGHT_CM = "heightCm"
    IS_LOCAL_DELIVERY_ONLY = "isLocalDeliveryOnly"
    IS_PERISHABLE = "isPerishable"
    ESTIMATED_SHIP_DAYS = "estimatedShipDays"
    DELIVERY_OPTIONS = "deliveryOptions"
    ESTIMATED_DAYS = "estimatedDays"
    COST = "cost"  # kept for shipping estimate dicts; for SellerDeliveryOption use COST_CENTS
    COST_CENTS = "costCents"
    MINIMUM_ORDER_QUANTITY = "minimumOrderQuantity"
    FREE_SHIPPING = "freeShipping"
    TAX_CODE = "taxCode"
    DEACTIVATION_REASON = "deactivationReason"

    # === TAX FIELDS (new) ===
    ITEM_TAXES = "itemTaxes"
    TAX_EXEMPT = "taxExempt"
    TAX_EXEMPTION = "taxExemption"
    GST_NUMBER = "gstNumber"

    # === CONSENT & COMPLIANCE FIELDS (CASL + PIPEDA + Quebec Law 25) ===
    EMAIL_CONSENT = "emailConsent"  # bool — user accepted transactional emails
    MARKETING_OPT_IN = "marketingOptIn"  # bool — explicit opt-in for marketing emails
    CONSENT_TIMESTAMP = "consentTimestamp"  # datetime — when consent was given
    CONSENT_METHOD = "consentMethod"  # str — how consent was obtained (signup, checkbox, etc.)
    PRIVACY_ACCEPTED_AT = "privacyAcceptedAt"  # datetime — when privacy policy was accepted
    TERMS_ACCEPTED_AT = "termsAcceptedAt"  # datetime — when ToS was accepted
    PRIVACY_POLICY_VERSION = "privacyPolicyVersion"  # str — version of privacy policy accepted
    TERMS_VERSION = "termsVersion"  # str — version of ToS accepted
    PREFERRED_LANGUAGE = "preferredLanguage"  # str — 'en' or 'fr' (for Quebec Bill 96 compliance)
    UNSUBSCRIBED_AT = "unsubscribedAt"  # datetime — when user unsubscribed from marketing
    DATA_PROCESSING_CONSENT = "dataProcessingConsent"  # bool — explicit consent for data processing

    # === PREMIUM SUBSCRIPTION FIELDS ===
    IS_PREMIUM = "isPremium"  # bool — cached premium status (authoritative: subscriptions/{uid})
    PREMIUM_SINCE = "premiumSince"  # datetime — when premium started
    PREMIUM_EXPIRES_AT = "premiumExpiresAt"  # datetime — current billing period end
    STRIPE_SUBSCRIPTION_ID = "stripeSubscriptionId"  # str — Stripe Subscription ID
    NOTIFY_NEW_PRODUCTS = "notifyNewProducts"  # bool — opt-in: notify on new products
    NOTIFY_TRENDING = "notifyTrending"  # bool — opt-in: notify on trending products
    FCM_TOKEN = "fcmToken"  # str — Firebase Cloud Messaging device token
    FCM_TOKEN_UPDATED_AT = "fcmTokenUpdatedAt"  # datetime — last FCM token update
    FCM_TOKEN_KEY = "token"  # Field name inside fcm_tokens subcollection docs

    # === TRENDING PRODUCT FIELDS ===
    TRENDING_SCORE = "trendingScore"  # int — computed trending score
    VIEW_COUNT = "viewCount"  # int — total product views
    IS_TRENDING = "isTrending"  # bool — currently in trending list
    TRENDING_AT = "trendingAt"  # datetime — when product last entered trending
    PURCHASE_COUNT = "purchaseCount"  # int — total purchases (for trending)

    # === SUBSCRIPTION DOCUMENT FIELDS ===
    CURRENT_PERIOD_START = "currentPeriodStart"  # datetime
    CURRENT_PERIOD_END = "currentPeriodEnd"  # datetime
    CANCEL_AT_PERIOD_END = "cancelAtPeriodEnd"  # bool

    # === CHAT FIELDS ===
    CHAT_ID = "chatId"
    BUYER_ID = "buyerId"
    PRODUCT_TITLE = "productTitle"
    PRODUCT_IMAGE_URL = "productImageUrl"
    LAST_MESSAGE = "lastMessage"  # str — text of last message
    LAST_MESSAGE_AT = "lastMessageAt"  # datetime
    SENDER_ID = "senderId"
    MESSAGE_TEXT = "text"
    IS_READ = "read"  # bool — message read by recipient
    BUYER_UNREAD_COUNT = "buyerUnreadCount"  # int — unread messages for buyer
    SELLER_UNREAD_COUNT = "sellerUnreadCount"  # int — unread messages for seller
    FIRST_BUYER_MESSAGE_AT = "firstBuyerMessageAt"  # datetime — when buyer sent first message
    FIRST_SELLER_REPLY_AT = "firstSellerReplyAt"  # datetime — when seller sent first reply
    FIRST_REPLY_HOURS = "firstReplyHours"  # float — hours from first buyer msg to seller first reply
    DELIVERY_INSTRUCTIONS = "deliveryInstructions"
    SHIPPING_DAYS = "shippingDays"
    HAS_TRACKING = "hasTracking"
    MAX_ITEMS_PER_SHIPMENT = "maxItemsPerShipment"
    ADDITIONAL_ITEM_COST = "additionalItemCost"  # kept for backward compat; for SellerDeliveryOption use ADDITIONAL_ITEM_COST_CENTS
    ADDITIONAL_ITEM_COST_CENTS = "additionalItemCostCents"
    QUANTITY_DISCOUNTS = "quantityDiscounts"
    DISCOUNT_TYPE = "discountType"
    DISCOUNT_VALUE = "discountValue"
    MIN_QUANTITY = "minQuantity"
    AVAILABLE_NATIONWIDE = "availableNationwide"

    SUPPLIER = "supplier"
    INVENTORY = "inventory"
    # === INVENTORY SUB-FIELDS (keys inside the `inventory` map) ===
    ALLOW_BACKORDER = "allowBackorder"
    LOW_STOCK_THRESHOLD = "lowStockThreshold"
    TRACK_QUANTITY = "trackQuantity"
    RESERVATION_HOLD_MINUTES = "reservationHoldMinutes"
    # === INVENTORY LEVELS SUBCOLLECTION FIELDS ===
    AVAILABLE_QUANTITY = "availableQuantity"
    RESERVED_QUANTITY = "reservedQuantity"
    LAST_SYNCED_AT = "lastSyncedAt"
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
    TAX_CENTS = "taxCents"  # Per-item tax in cents (inside itemTaxes array)
    TAX_RATE = "taxRate"  # Per-item tax rate (inside itemTaxes array)
    SHIPPING_COST_CENTS = "shippingCostCents"
    TOTAL_AMOUNT_CENTS = "totalAmountCents"
    CURRENCY = "currency"
    ORDER_STATUS = "orderStatus"
    PAYMENT_STATUS = "paymentStatus"
    SHIPPING_ADDRESS = "shippingAddress"
    STRIPE_SESSION_ID = "stripeSessionId"
    STRIPE_PAYMENT_INTENT_ID = "stripePaymentIntentId"
    CAPTURE_ATTEMPTS = "captureAttempts"
    FRAUD_SCORE = "fraudScore"
    SELLER_CAPTURES = "sellerCaptures"
    LAST_CAPTURE_ERROR = "lastCaptureError"
    CAPTURED_AT = "capturedAt"
    EXPIRES_AT = "expiresAt"
    CONFIRMED_BY_CLIENT = "confirmedByClient"
    CONFIRMED_AT = "confirmedAt"
    AUTO_CONFIRMED = "autoConfirmed"
    AUTO_CAPTURED = "autoCaptured"
    SELLER_PAYOUTS = "sellerPayouts"
    SELLER_STRIPE_ACCOUNTS = "sellerStripeAccounts"
    PLATFORM_FEE_TOTAL_CENTS = "platformFeeTotalCents"
    PLATFORM_FEE_RATIO = "platformFeeRatio"  # Stored at checkout for capture-time fee rate
    PAYOUT_STATUS = "payoutStatus"
    RATINGS = "ratings"
    REFUND_AMOUNT = "refundAmount"
    REFUNDED_AT = "refundedAt"
    # Refund/dispute tracking (cents-based for idempotency & audit)
    CUMULATIVE_REFUNDED_CENTS = "cumulativeRefundedCents"
    PARTIAL_REFUND_AMOUNT_CENTS = "partialRefundAmountCents"
    TRANSFERS_REVERSED = "transfersReversed"
    DISPUTED_AT = "disputedAt"
    SHIPPING_APPROVAL_STATUS = "shippingApprovalStatus"
    SHIPPING_APPROVAL_REQUIRED = "shippingApprovalRequired"
    ACTUAL_SHIPPING_CENTS = "actualShippingCents"
    PENDING_TOTAL_CENTS = "pendingTotalCents"
    SHIPPING_APPROVAL = "shippingApproval"
    STOCK_RESTORED = "stockRestored"
    LAST_LOW_STOCK_ALERT_AT = "lastLowStockAlertAt"
    ARCHIVED = "archived"
    ARCHIVED_AT = "archivedAt"
    CANCELLED_BY = "cancelledBy"
    CANCELLED_AT = "cancelledAt"
    UPDATED_BY = "updatedBy"
    CANCELLATION_REASON = "cancellationReason"
    RESPONDED_AT = "respondedAt"
    ACTUAL_COST = "actualCost"
    ORIGINAL_COST_CENTS = "originalCostCents"
    NEW_COST_CENTS = "newCostCents"
    REQUESTED_BY = "requestedBy"
    REQUESTED_AT = "requestedAt"
    REQUIRES_MANUAL_REVIEW = "requiresManualReview"
    BREACHES = "breaches"
    TOTAL_ORDERS = "totalOrders"
    MANUAL_REVIEW_REASON = "manualReviewReason"
    PAYOUT_ERRORS = "payoutErrors"
    ACTION = "action"
    OLD_ENABLED = "oldEnabled"
    NEW_ENABLED = "newEnabled"

    PAYMENT_COMPLETED_AT = "paymentCompletedAt"
    PAYMENT_ERROR = "paymentError"
    CUSTOMER_NAME = "customerName"

    # === RETURN REQUEST FIELDS ===
    RETURN_ID = "returnId"
    RETURN_STATUS = "returnStatus"
    RETURN_REASON = "returnReason"
    RETURN_TRACKING_NUMBER = "returnTrackingNumber"
    RETURN_REFUND_AMOUNT_CENTS = "returnRefundAmountCents"
    RETURN_ADMIN_NOTE = "returnAdminNote"

    # === ORDER ITEM FIELDS ===
    QUANTITY = "quantity"
    BUYER_NOTE = "buyerNote"
    CART_ITEM_ID = "cartItemId"
    PRICE_SNAPSHOT = "priceSnapshot"
    TRACKING_NUMBER = "trackingNumber"
    CARRIER = "carrier"
    CARRIER_NOTE = "carrierNote"  # Free-text override when carrier='other'
    SHIPPED_AT = "shippedAt"
    DELIVERED_AT = "deliveredAt"
    REFUND_REASON = "refundReason"
    REFUND_AMOUNT_CENTS = "refundAmountCents"
    REFUND_ID = "refundId"
    CONFIRMED_BY_BUYER = "confirmedByBuyer"
    DELIVERY_STATUS = "deliveryStatus"  # DEPRECATED — kept for reading existing documents only. Write 'status' field.

    # === STRIPE METADATA KEYS (used in transfer/alert metadata) ===
    SNAPSHOT_ACCOUNT_ID = "snapshotAccountId"
    LIVE_ACCOUNT_ID = "liveAccountId"
    METADATA_PLATFORM_FEE = "platformFee"

    # === PAYOUT FIELDS ===
    AMOUNT_CENTS = "amountCents"
    PLATFORM_FEE_CENTS = "platformFeeCents"
    NET_AMOUNT_CENTS = "netAmountCents"
    STRIPE_TRANSFER_ID = "stripeTransferId"
    REVERSAL_ID = "reversalId"
    PARTIAL_REVERSALS = "partialReversals"
    DISPUTE_ID = "disputeId"
    PRE_DISPUTE_STATUS = "preDisputeStatus"
    DISPUTE_STATUS = "disputeStatus"
    DISPUTE_RESOLVED_AT = "disputeResolvedAt"
    DISPUTE_RESOLUTION = "disputeResolution"
    DISPUTED_AT = "disputedAt"
    FAILURE_REASON = "failureReason"
    PAYOUT_DATE = "payoutDate"
    REVERSED_AT = "reversedAt"
    CUMULATIVE_REVERSED_CENTS = "cumulativeReversedCents"
    REVERSAL_REASON = "reversalReason"

    # === WEBHOOK FIELDS ===
    EVENT_ID = "eventId"
    EVENT_TYPE = "eventType"
    ACTOR = "actor"
    ACTOR_TYPE = "actorType"
    FROM_STATUS = "fromStatus"
    TO_STATUS = "toStatus"
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
    RETRIES = "retries"
    PAYMENT_ID = "paymentId"

    # === SECURITY ALERT FIELDS ===
    TYPE = "type"
    SEVERITY = "severity"
    RESOLVED = "resolved"
    RESOLVED_AT = "resolvedAt"

    # === NEW FEATURE FIELDS (TASKS 05-11) ===
    ADDRESS_ID = "addressId"
    ADDRESS_COUNT = "addressCount"
    REVIEW_IMAGE_URLS = "reviewImageUrls"
    REVIEW_TEXT = "reviewText"
    VERIFIED_PURCHASE = "verifiedPurchase"
    NOTIFIED_AT = "notifiedAt"
    SUBSCRIBED_AT = "subscribedAt"
    QUESTION_TEXT = "question"
    ANSWER_TEXT = "answer"
    ANSWERED_AT = "answeredAt"
    ANSWERED_BY = "answeredBy"
    IS_ANSWERED = "isAnswered"
    UPVOTES = "upvotes"
    ASKER_ID = "askerId"
    QUESTION_ID = "questionId"
    LAST_CART_ABANDON_EMAIL_AT = "lastCartAbandonEmailAt"
    DISPUTE_RATE = "disputeRate"
    REFUND_RATE = "refundRate"
    CANCELLATION_RATE = "cancellationRate"
    LATE_SHIPMENT_RATE = "lateShipmentRate"
    AVG_RESPONSE_TIME_HOURS = "avgResponseTimeHours"
    AVG_SHIP_DAYS = "avgShipDays"
    POSITIVE_RATE_PCT = "positiveRatePct"
    TOTAL_ORDERS_30D = "totalOrders30d"
    TOTAL_REVENUE_CENTS_30D = "totalRevenueCents30d"
    COMPUTED_AT = "computedAt"
    RESOLUTION = "resolution"
    TIMESTAMP = "timestamp"
    CHARGE_ID = "chargeId"
    ACCOUNT_ID = "accountId"
    REASON = "reason"
    PAYMENT_INTENT_ID = "paymentIntentId"
    DESTINATION = "destination"
    FAILURE_MESSAGE = "failureMessage"
    ADMIN_ID = "adminId"
    # Alert data fields
    FIRESTORE_COUNT = "firestoreCount"
    ALGOLIA_COUNT = "algoliaCount"
    MISMATCH_PERCENT = "mismatchPercent"
    REVERSAL_ERRORS = "reversalErrors"
    PAYOUT_ID = "payoutId"
    TRANSFER_ID = "transferId"
    ERROR_CODE = "errorCode"
    TARGET_USER_ID = "targetUserId"
    OLD_ROLES = "oldRoles"
    NEW_ROLES = "newRoles"
    PRODUCTS_DEACTIVATED = "productsDeactivated"
    ORDERS_CANCELLED = "ordersCancelled"

    # === WEBHOOK EVENT FIELDS ===
    CLIENT_IP = "clientIp"

    # === RATE LIMIT FIELDS ===
    COUNT = "count"
    FIRST_REQUEST = "first_request"
    LAST_REQUEST = "last_request"

    # === FAVORITES FIELDS ===
    DATE_FAVORITED = "dateFavorited"

    # === CRON LOCK FIELDS ===
    LOCKED_AT = "lockedAt"
    LOCKED_BY = "lockedBy"

    # === ALGOLIA SYNC FAILURE FIELDS ===
    RETRY_COUNT = "retryCount"
    MAX_RETRIES_EXCEEDED = "maxRetriesExceeded"
    LAST_RETRY_ERROR = "lastRetryError"

    # === ALTERNATE FIELD NAMES (used in Firestore deserialization fallbacks) ===
    BUYER_CONFIRMED = "buyerConfirmed"  # Alternate for CONFIRMED_BY_BUYER
    LOCAL_DELIVERY_ONLY = "localDeliveryOnly"  # Alternate for IS_LOCAL_DELIVERY_ONLY
    PERISHABLE = "perishable"  # Alternate for IS_PERISHABLE
    SUPPLIER_SHIPPING_DAYS = "supplierShippingDays"  # Alternate for ESTIMATED_SHIP_DAYS
    MIN_ORDER_QUANTITY = "minOrderQuantity"  # Alternate for MINIMUM_ORDER_QUANTITY

    # === LOWERCASE TAX KEYS (used in JSON API responses) ===
    GST_LOWER = "gst"
    PST_LOWER = "pst"
    HST_LOWER = "hst"
    QST_LOWER = "qst"

    # === TAX FIELDS / KEYS ===
    # Map keys used inside Fields.TAXES (order tax breakdown)
    GST = "GST"
    PST = "PST"
    HST = "HST"
    QST = "QST"

    # === REVIEW/RATING FIELDS ===
    COMMENT = "comment"
    SUBSCRIPTION_STATUS = "subscriptionStatus"
    PRODUCT_IDS = "productIds"


    # === N-09: Product variants ===
    HAS_VARIANTS = "hasVariants"
    VARIANTS = "variants"
    VARIANT_ID = "variantId"
    VARIANT_KEY = "variantKey"
    VARIANT_OPTIONS = "variantOptions"
    VARIANT_TITLE = "variantTitle"
    VARIANT_SKU = "variantSku"
    OPTION_VALUES = "optionValues"

    # === N-11: Subcategories ===
    SUBCATEGORY = "subcategory"
    CONDITION = "condition"  # Product condition: new|like_new|good|fair|for_parts

    # === N-03: Seller reply to reviews ===
    SELLER_REPLY = "sellerReply"
    SELLER_REPLY_AT = "sellerReplyAt"

    # === N-03/N-04: Product ratings ===
    RATING_ID = "ratingId"
    REVIEW_ID = "reviewId"  # alias used in admin operations

    # === N-04: Review helpfulness voting ===
    HELPFUL_COUNT = "helpfulCount"
    HELPFUL_VOTER_IDS = "helpfulVoterIds"

    # === N-06: Price history ===
    PRICE_HISTORY = "priceHistory"

    # === N-07: Coupon/promo code system ===
    COUPON_CODE = "couponCode"
    DISCOUNT_AMOUNT_CENTS = "discountAmountCents"
    MIN_ORDER_CENTS = "minOrderCents"
    MAX_USES_TOTAL = "maxUsesTotal"
    MAX_USES_PER_USER = "maxUsesPerUser"
    USED_COUNT = "usedCount"
    USED_BY_UIDS = "usedByUids"  # DEPRECATED — use coupon_uses subcollection
    PRICE_CENTS = "priceCents"  # Integer cents derived from price (9.99 → 999) — use for arithmetic
    SCHEMA_VERSION = "schemaVersion"  # Schema layout version for migration tracking
    SELLER_NAME = "sellerName"  # Seller display name snapshotted at purchase time

    # === NOTIFICATIONS / PUSH / ACTOR ===
    NOTIFICATIONS_SENT = "notificationsSent"  # ArrayUnion of status values already notified
    PUSH_ENABLED = "pushEnabled"  # bool — user opted into push notifications
    LAST_ACTOR_ID = "lastActorId"  # uid of last actor on order
    IS_SELLER = "isSeller"  # bool flag on users doc
    HAS_DISPUTE = "hasDispute"  # bool on order doc
    SELLER_AMOUNT_CENTS = "sellerAmountCents"  # per-payout cents
    ESCALATED_AT = "escalatedAt"  # timestamp when return was escalated
    ESCALATION_REASON = "escalationReason"  # reason for escalation

    # === API REQUEST/RESPONSE FIELDS ===
    FILE_NAME = "fileName"
    UPLOAD_URL = "uploadUrl"
    CONFIRMATION = "confirmation"


# =============================================================================
# ENUM VALUES - Valid values for enum fields
# =============================================================================


class OrderItemIdValues:
    """Special sentinel values for order item ID parameters."""

    ALL = "all"


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
    # DEPRECATED: REFUNDED / PARTIALLY_REFUNDED moved to PaymentStatusValues — kept for backward-compatible reads
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"
    DISPUTED = "disputed"

    ALL: frozenset[str] = frozenset(
        {
            PENDING,
            CONFIRMED,
            PROCESSING,
            SHIPPED,
            IN_TRANSIT,
            DELIVERED,
            CANCELLED,
            FAILED,
            EXPIRED,
            DISPUTED,
        }
    )

    # =========================================================================
    # CENTRALIZED STATE MACHINE — Single source of truth for order transitions
    # Used by: helpers.py, firestore.rules (must be manually kept in sync),
    #          orders.py update_order_status, cancel_order
    # =========================================================================
    VALID_TRANSITIONS: dict[str, list[str]] = {
        "pending": ["confirmed", "cancelled", "failed", "expired"],
        "confirmed": ["processing", "cancelled", "expired"],
        "processing": ["shipped", "cancelled"],
        "shipped": ["in_transit", "delivered"],
        "in_transit": ["delivered", "cancelled"],
        "delivered": ["disputed"],
        "cancelled": [],  # Terminal
        "failed": ["pending"],  # Retry
        "expired": ["pending"],  # Retry
        "disputed": [],  # Resolved via paymentStatus
    }

    # Terminal states — no further transitions allowed
    TERMINAL_STATES: frozenset[str] = frozenset(
        {
            "cancelled",
        }
    )


class DeliveryItemStatusTransitions:
    """Centralized per-item delivery status transitions.
    Used by: orders.py update_item_status (inside and outside transaction).
    """

    VALID_TRANSITIONS: dict[str, list[str]] = {
        "pending": ["shipped"],
        "shipped": ["delivered"],
        "delivered": ["refunded"],
        "refunded": [],  # Terminal
    }


class PaymentStatusValues:
    """Valid values for paymentStatus field"""

    AWAITING_PAYMENT = "awaiting_payment"
    PROCESSING = "processing"
    PAID = "paid"
    PAYMENT_FAILED = "payment_failed"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"
    SESSION_EXPIRED = "session_expired"
    AUTHORIZED = "authorized"
    CAPTURED = "captured"
    CANCELLED = "cancelled"
    AUTHORIZATION_EXPIRED = "authorization_expired"
    DISPUTED = "disputed"
    # Transitional states (internal use, not stored long-term)
    CAPTURING = "capturing"
    CANCELLING = "cancelling"
    EXPIRING = "expiring"

    ALL: frozenset[str] = frozenset(
        {
            AWAITING_PAYMENT,
            PROCESSING,
            PAID,
            PAYMENT_FAILED,
            REFUNDED,
            PARTIALLY_REFUNDED,
            SESSION_EXPIRED,
            AUTHORIZED,
            CAPTURED,
            CANCELLED,
            AUTHORIZATION_EXPIRED,
            DISPUTED,
            CAPTURING,
            CANCELLING,
            EXPIRING,
        }
    )


class DeliveryStatusValues:
    """Valid values for deliveryStatus/status field on order items"""

    PENDING = "pending"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    REFUNDED = "refunded"

    ALL: frozenset[str] = frozenset({PENDING, SHIPPED, DELIVERED, REFUNDED})


class PayoutStatusValues:
    """Valid values for payoutStatus field"""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    PARTIAL = "partial"
    FAILED = "failed"
    REVERSED = "reversed"
    PARTIALLY_REVERSED = "partially_reversed"
    REVERSED_DISPUTE = "reversed_dispute"

    ALL: frozenset[str] = frozenset(
        {PENDING, PROCESSING, COMPLETED, PARTIAL, FAILED, REVERSED, PARTIALLY_REVERSED, REVERSED_DISPUTE}
    )


class UserRoleValues:
    """Valid values for roles array"""

    ADMIN = "admin"
    SELLER = "seller"
    BUYER = "buyer"

    ALL: frozenset[str] = frozenset({ADMIN, SELLER, BUYER})


class ProductStatusValues:
    """DEPRECATED — use ProductLifecycleStatusValues"""

    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    ARCHIVED = "archived"
    OUT_OF_STOCK = "out_of_stock"

    ALL: frozenset[str] = frozenset({DRAFT, ACTIVE, PAUSED, ARCHIVED, OUT_OF_STOCK})


class ProductApprovalStatusValues:
    """DEPRECATED — use ProductLifecycleStatusValues"""

    UNDER_REVIEW = "under_review"
    APPROVED = "approved"
    REJECTED = "rejected"

    ALL: frozenset[str] = frozenset({UNDER_REVIEW, APPROVED, REJECTED})


class ProductLifecycleStatusValues:
    """Single lifecycle status replacing isActive + status + approvalStatus.

    State machine: draft → under_review → approved → active → paused | archived
    Rejection: under_review → rejected → draft (resubmit)
    """

    DRAFT = "draft"
    UNDER_REVIEW = "under_review"
    APPROVED = "approved"
    ACTIVE = "active"
    PAUSED = "paused"
    ARCHIVED = "archived"
    REJECTED = "rejected"

    ALL: frozenset[str] = frozenset({"draft", "under_review", "approved", "active", "paused", "archived", "rejected"})
    VALID_TRANSITIONS: dict = {
        "draft": {"under_review"},
        "under_review": {"approved", "rejected"},
        "approved": {"active"},
        "active": {"paused", "archived"},
        "paused": {"active", "archived"},
        "rejected": {"draft", "under_review"},
        "archived": frozenset(),
    }
    BUYER_VISIBLE: frozenset = frozenset({"active"})


class ReturnStatusValues:
    """Valid values for return request status — state machine for physical returns."""

    REQUESTED = "requested"
    APPROVED = "approved"
    LABEL_ISSUED = "label_issued"
    RECEIVED = "received"
    REFUNDED = "refunded"
    REJECTED = "rejected"
    ESCALATED = "escalated"  # Auto-escalated to admin after N days unresolved

    ALL: frozenset[str] = frozenset({"requested", "approved", "label_issued", "received", "refunded", "rejected", "escalated"})
    VALID_TRANSITIONS: dict = {
        "requested": {"approved", "rejected", "escalated"},
        "approved": {"label_issued", "rejected"},
        "label_issued": {"received"},
        "received": {"refunded"},
        "refunded": frozenset(),
        "rejected": frozenset(),
        "escalated": {"approved", "rejected"},  # Admin can resolve escalated requests
    }


class ShippingApprovalStatusValues:
    """Valid values for shipping approval status"""

    NOT_REQUIRED = "not_required"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

    ALL: frozenset[str] = frozenset({NOT_REQUIRED, PENDING, APPROVED, REJECTED})


class DeliveryTypeValues:
    """Valid values for delivery option types"""

    PICKUP = "pickup"
    STANDARD = "standard"
    EXPRESS = "express"
    SAME_DAY = "same_day"
    LOCAL_DELIVERY = "local_delivery"
    CUSTOM = "custom"

    ALL: frozenset[str] = frozenset({PICKUP, STANDARD, EXPRESS, SAME_DAY, LOCAL_DELIVERY, CUSTOM})


class WebhookStatusValues:
    """Valid values for webhook processing status"""

    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

    ALL: frozenset[str] = frozenset({PROCESSING, COMPLETED, FAILED})


class SecurityAlertTypes:
    """Security alert type values"""

    ALGOLIA_SYNC_ISSUE = "algolia_sync_issue"
    DISPUTE_CREATED = "dispute_created"
    DISPUTE_FUNDS_REINSTATED = "dispute_funds_reinstated"
    ROLE_CHANGE = "role_change"
    SELLER_SUSPENDED = "seller_suspended"
    SELLER_UNSUSPENDED = "seller_unsuspended"
    PAYMENT_PROVIDER_DISABLED = "payment_provider_disabled"
    REFUND_REVERSAL_FAILED = "refund_reversal_failed"
    PAYOUT_FAILED = "payout_failed"
    REFUND_FAILED = "refund_failed"
    SELLER_ACCOUNT_CHANGED = "seller_account_changed"
    PAYOUT_RECORD_INCOMPLETE = "payout_record_incomplete"
    MFA_LOW_BACKUP_CODES = "mfa_low_backup_codes"
    SELLER_KYC_FAILED = "seller_kyc_failed"
    # Tax exemption fraud prevention
    INVALID_GST_ATTEMPT = "invalid_gst_attempt"
    BLOCKED_GST_ATTEMPT = "blocked_gst_attempt"
    SHARED_GST_NUMBER = "shared_gst_number"
    TAX_EXEMPTION_PENDING_REVIEW = "tax_exemption_pending_review"
    SUSPICIOUS_TAX_EXEMPTION = "suspicious_tax_exemption"
    AUTH_DELETION_FAILED = "auth_deletion_failed"
    SELLER_METRICS_BREACH = "seller_metrics_breach"  # TASK 11


class SeverityLevels:
    """Security alert severity levels"""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class DiscountTypeValues:
    """Valid values for shipping discount types"""

    PERCENT = "percent"
    FIXED = "fixed"
    FLAT_RATE = "flat_rate"

    ALL: frozenset[str] = frozenset({PERCENT, FIXED, FLAT_RATE})


class CouponDiscountTypeValues:
    """Valid values for coupon discount types (N-07)"""

    PERCENT = "percent"
    FIXED_CENTS = "fixed_cents"

    ALL: frozenset[str] = frozenset({PERCENT, FIXED_CENTS})


class PaymentProviderValues:
    """Valid values for payment provider"""

    STRIPE = "stripe"

    ALL: frozenset[str] = frozenset({STRIPE})


class ConsentMethodValues:
    """Valid values for consentMethod field (CASL / PIPEDA)"""

    SIGNUP = "signup"
    CHECKBOX = "checkbox"
    DOUBLE_OPT_IN = "double_opt_in"
    IMPLIED = "implied"
    USER_PREFERENCE = "user_preference"  # User toggled consent in settings
    UNSUBSCRIBE = "unsubscribe"  # User clicked unsubscribe link

    ALL: frozenset[str] = frozenset({SIGNUP, CHECKBOX, DOUBLE_OPT_IN, IMPLIED, USER_PREFERENCE, UNSUBSCRIBE})


class PolicyVersionValues:
    """Current policy version strings"""

    DEFAULT = "1.0"


class LanguageValues:
    """Supported UI languages (Quebec Bill 96)"""

    ENGLISH = "en"
    FRENCH = "fr"

    ALL: frozenset[str] = frozenset({ENGLISH, FRENCH})


class SupplierCurrencyValues:
    """Valid currencies for supplier cost tracking (NOT selling price)"""

    CAD = "CAD"
    USD = "USD"
    EUR = "EUR"
    GBP = "GBP"
    CNY = "CNY"
    JPY = "JPY"
    KRW = "KRW"
    INR = "INR"
    AUD = "AUD"
    MXN = "MXN"
    BRL = "BRL"
    HKD = "HKD"
    SGD = "SGD"
    TWD = "TWD"

    DEFAULT = "USD"
    ALL: frozenset[str] = frozenset({CAD, USD, EUR, GBP, CNY, JPY, KRW, INR, AUD, MXN, BRL, HKD, SGD, TWD})


class CronLockStatusValues:
    """Valid values for cron lock status field."""

    RUNNING = "running"
    COMPLETED = "completed"


class AlgoliaActionValues:
    """Valid values for Algolia sync failure action field."""

    INDEX = "index"
    DELETE = "delete"


class AdminActionValues:
    """Valid values for admin log action field."""

    PAYMENT_PROVIDER_UPDATE = "payment_provider_update"
    STOCK_UPDATE = "stock_update"
    ORDER_REFUND = "order_refund"
    REVIEW_DELETE = "review_delete"
    REVIEW_FLAG = "review_flag"


class WebhookResponseStatus:
    """Internal webhook handler response status values."""

    PROCESSED = "processed"
    IGNORED = "ignored"
    ERROR = "error"


class WarehouseTypeValues:
    """Valid values for seller warehouse location type"""

    WAREHOUSE = "warehouse"
    PERSONAL = "personal"

    ALL: frozenset[str] = frozenset({WAREHOUSE, PERSONAL})


class ShippingSourceValues:
    """Source type for delivery estimate."""

    INTERNATIONAL_SUPPLIER = "international_supplier"
    INTERNATIONAL_GENERIC = "international_generic"
    DOMESTIC = "domestic"


class ProductConditionValues:
    """Valid product condition values (marketplace-style listings)."""

    NEW = "new"
    LIKE_NEW = "like_new"
    GOOD = "good"
    FAIR = "fair"
    FOR_PARTS = "for_parts"

    ALL: frozenset[str] = frozenset({NEW, LIKE_NEW, GOOD, FAIR, FOR_PARTS})


class CarrierValues:
    """Normalized shipping carrier identifiers."""

    UPS = "ups"
    FEDEX = "fedex"
    CANADA_POST = "canada_post"
    PUROLATOR = "purolator"
    DHL = "dhl"
    USPS = "usps"
    OTHER = "other"

    ALL: frozenset[str] = frozenset({UPS, FEDEX, CANADA_POST, PUROLATOR, DHL, USPS, OTHER})


class SupplierTypeValues:
    """Valid values for supplier type — mirrors Dart SupplierTypeValues"""

    ALIEXPRESS = "aliexpress"
    DHGATE = "dhgate"
    ALIBABA = "alibaba"
    S1688 = "1688"
    TEMU = "temu"
    CJDROPSHIPPING = "cjdropshipping"
    LOCAL = "local"
    OTHER = "other"
    # Extended supplier platforms
    SPOCKET = "spocket"
    OBERLO = "oberlo"
    PRINTFUL = "printful"
    PRINTIFY = "printify"
    MADE_IN_CHINA = "made_in_china"
    GLOBAL_SOURCES = "global_sources"
    GMARKET = "gmarket"
    COUPANG = "coupang"
    RAKUTEN = "rakuten"
    FAIRE = "faire"
    AMAZON_EUROPE = "amazon_europe"
    AMAZON_USA = "amazon_usa"
    AMAZON_JAPAN = "amazon_japan"
    WALMART = "walmart"
    COSTCO = "costco"
    ETSY_WHOLESALE = "etsy_wholesale"
    INDIAMART = "indiamart"
    TRADEINDIA = "tradeindia"
    CUSTOM = "custom"
    ALL: frozenset[str] = frozenset(
        {
            ALIEXPRESS, DHGATE, ALIBABA, S1688, TEMU, CJDROPSHIPPING, LOCAL, OTHER,
            SPOCKET, OBERLO, PRINTFUL, PRINTIFY, MADE_IN_CHINA, GLOBAL_SOURCES,
            GMARKET, COUPANG, RAKUTEN, FAIRE, AMAZON_EUROPE, AMAZON_USA, AMAZON_JAPAN,
            WALMART, COSTCO, ETSY_WHOLESALE, INDIAMART, TRADEINDIA, CUSTOM,
        }
    )


# =============================================================================
# SHIPPING TIERS — Single source of truth for all shipping pricing
# =============================================================================


class ShippingTiers:
    """Distance-based shipping cost tiers (CAD).
    Benchmarked against Instacart/DoorDash/PC Express.
    """

    NATIONAL_CEILING = 26.99
    DEFAULT_MIN_COST = 1.99  # Minimum shipping cost when coordinates unavailable

    # Distance thresholds (km) and base costs
    TIERS: list[tuple[float, float]] = [
        (15, 1.99),  # Hyper-local
        (50, 4.99),  # Local
        (150, 9.99),  # Regional
        (500, 14.99),  # Inter-city (Toronto-Ottawa corridor)
        (1200, 18.99),  # Inter-regional
        (2500, 22.99),  # Long-distance
    ]

    # Speed multipliers by distance range
    EXPRESS_MULTIPLIERS: dict[str, float] = {
        "hyper_local": 4.0,  # ≤15km
        "local": 1.6,  # ≤50km
        "regional": 1.5,  # ≤150km
        "default": 1.6,  # >150km
    }
    SAME_DAY_MULTIPLIERS: dict[str, float] = {
        "hyper_local": 4.5,  # ≤15km
        "local": 1.8,  # ≤50km
        "regional": 1.8,  # ≤150km
        "default": 2.5,  # >150km
    }

    # Surcharges
    WEIGHT_SURCHARGE_PER_KG = 1.5  # Per kg over threshold
    WEIGHT_SURCHARGE_THRESHOLD_KG = 2.0  # Free weight allowance
    ADDITIONAL_ITEM_RATE = 0.15  # 15% of base per extra item
    VOLUMETRIC_DIVISOR = 5000.0  # L*W*H / divisor
    DEFAULT_WEIGHT_KG = 0.5
    DEFAULT_DIMENSION_CM = 10

    # Perishable surcharges
    PERISHABLE_CROSS_PROVINCE = 50.0  # $50 flat
    PERISHABLE_LONG_DISTANCE = 75.0  # $75 for >100km
    PERISHABLE_DISTANCE_THRESHOLD_KM = 100

    # Fallback rates (province matrix)
    FALLBACK_SAME_PROVINCE = 12.99
    FALLBACK_ADJACENT = 18.99
    FALLBACK_SAME_REGION = 22.99

    # International weight surcharge
    INTL_WEIGHT_SURCHARGE_PER_KG = 3.0
    INTL_WEIGHT_THRESHOLD_KG = 1.0

    # Default seller estimated days
    DEFAULT_SELLER_SHIP_DAYS = 3
    DOMESTIC_BUFFER_DAYS = 3
    INTL_GENERIC_MIN_DAYS = 14
    INTL_GENERIC_MAX_DAYS = 30


# =============================================================================
# SCHEMA REGISTRY - For contract testing
# =============================================================================


class SchemaRegistry:
    """
    Registry of expected fields per collection.
    Used by contract tests to validate code matches schema.
    """

    # Required fields per collection (must exist in every document)
    REQUIRED_FIELDS: dict[str, set[str]] = {
        Collections.USERS: {Fields.UID, Fields.EMAIL, Fields.NAME, Fields.ROLES, Fields.CREATED_AT},
        Collections.PRODUCTS: {
            Fields.NAME,
            Fields.PRICE,
            Fields.DESCRIPTION,
            Fields.IMAGE_URLS,
            Fields.SELLER_ID,
            Fields.CATEGORY_ID,
            Fields.STOCK_QUANTITY,
            Fields.CREATED_AT,
        },
        Collections.ORDERS: {
            Fields.USER_ID,
            Fields.ITEMS,
            Fields.SUBTOTAL_CENTS,
            Fields.TAX_AMOUNT_CENTS,
            Fields.SHIPPING_COST_CENTS,
            Fields.TOTAL_AMOUNT_CENTS,
            Fields.ORDER_STATUS,
            Fields.PAYMENT_STATUS,
            Fields.SHIPPING_ADDRESS,
            Fields.CREATED_AT,
        },
        Collections.PAYOUTS: {
            Fields.ORDER_ID,
            Fields.SELLER_ID,
            Fields.AMOUNT_CENTS,
            Fields.PLATFORM_FEE_CENTS,
            Fields.NET_AMOUNT_CENTS,
            Fields.STATUS,
            Fields.CREATED_AT,
        },
    }

    # Timestamp field mapping (which field name each collection uses)
    TIMESTAMP_FIELD: dict[str, str] = {
        Collections.USERS: Fields.CREATED_AT,
        Collections.PRODUCTS: Fields.CREATED_AT,
        Collections.ORDERS: Fields.CREATED_AT,
        Collections.PAYOUTS: Fields.CREATED_AT,
        Collections.CART: Fields.CREATED_AT,
    }

    @classmethod
    def get_timestamp_field(cls, collection: str) -> str:
        """Get the correct timestamp field name for a collection."""
        return cls.TIMESTAMP_FIELD.get(collection, Fields.CREATED_AT)

    @classmethod
    def validate_field_name(cls, collection: str, field_name: str) -> bool:
        """Check if a field name is valid for a collection."""
        # Get all defined fields
        all_fields = {v for k, v in Fields.__dict__.items() if not k.startswith("_")}
        return field_name in all_fields


# =============================================================================
# VALIDATION LIMITS — Shared between frontend (schema_constants.dart) and backend
# =============================================================================


class ValidationLimits:
    """Centralized validation constraints. Must match frontend schema_constants.dart."""

    MAX_EMAIL_LENGTH = 254
    MAX_NAME_LENGTH = 60
    MIN_NAME_LENGTH = 2
    MAX_STREET_LENGTH = 100
    MAX_CITY_LENGTH = 50
    MAX_MESSAGE_LENGTH = 1000
    MIN_MESSAGE_LENGTH = 10
    MAX_ITEM_QUANTITY = 100
    MAX_PHONE_DIGITS = 15
    MIN_PHONE_DIGITS = 10


# =============================================================================
# BUSINESS CONSTANTS
# =============================================================================


class BusinessRules:
    """Business rule constants"""

    PLATFORM_FEE_PERCENT = 2.5
    PLATFORM_FEE_RATIO = 0.025  # PLATFORM_FEE_PERCENT / 100 — use this for calculations
    PREMIUM_MONTHLY_PRICE_CAD = 7.86  # Premium subscription monthly price in CAD
    PREMIUM_MONTHLY_PRICE_CENTS = 786  # Premium subscription monthly price in cents
    AUTO_CONFIRM_DAYS = 5  # Must be < AUTHORIZATION_EXPIRY_DAYS (2-day safety margin)
    AUTHORIZATION_EXPIRY_DAYS = 7
    RETURN_WINDOW_DAYS = 7  # No returns/refunds after 7 days post-delivery (Amazon-style policy)
    RETURN_ESCALATION_DAYS = 3  # Return requests auto-escalated after 3 days without seller action
    MAX_CAPTURE_ATTEMPTS = 3
    DEFAULT_CURRENCY = "cad"
    SUPPORTED_SELLING_CURRENCIES = frozenset({"cad"})  # All transactions in CAD
    ALLOWED_SHIPPING_COUNTRIES = frozenset({"Canada", "CA"})  # Buyers/delivery in Canada only
    # Sellers can be from any country — no country restriction on seller addresses
    MAX_ORDER_AMOUNT_CAD = 100000  # $100,000 CAD per order
    SHIPPING_APPROVAL_THRESHOLD = 0.20  # 20% ratio — shipping updates above this require buyer approval

    # Stripe integration limits
    STRIPE_MAX_NETWORK_RETRIES = 2
    WEBHOOK_RATE_LIMIT_PER_MINUTE = 100  # Per IP
    WEBHOOK_MAX_AGE_SECONDS = 300  # 5 minutes — reject stale webhooks
    ORDER_DEDUP_WINDOW_SECONDS = 60  # Prevent duplicate orders from retries
    MAX_DELIVERY_INSTRUCTIONS_LENGTH = 500
    CHECKOUT_RATE_LIMIT = 5  # Per minute per user
    CONNECT_ACCOUNT_RATE_LIMIT = 3  # Per hour per user

    # MFA security constants
    MFA_VERIFICATION_VALIDITY_MINUTES = 5
    MFA_MAX_ATTEMPTS = 5
    MFA_LOCKOUT_MINUTES = 15
    MFA_TOTP_VALID_WINDOW = 1  # ±30 seconds

    # Account management
    MIN_NAME_LENGTH = 2
    MAX_NAME_LENGTH = 60
    GST_NUMBER_REGEX = r"^\d{9}[A-Z]{2}\d{4}$"

    # Order archival
    ARCHIVE_AFTER_DAYS = 30
    FIRESTORE_BATCH_LIMIT = 500
    MAX_SHIPPING_COST_CAD = 500  # $500 CAD absolute maximum shipping cost

    # Seller health thresholds
    SELLER_DISPUTE_RATE_THRESHOLD = 0.05  # 5% dispute rate triggers seller health alert
    SELLER_REFUND_RATE_THRESHOLD = 0.10   # 10% refund rate threshold
    SELLER_CANCEL_RATE_THRESHOLD = 0.10   # 10% cancel rate threshold

    # Trending product constants
    TRENDING_TOP_N = 20              # Number of products to mark as trending
    TRENDING_WINDOW_HOURS = 24       # Rolling window for trending calculation
    TRENDING_PURCHASE_WEIGHT = 3     # Weight for purchase events
    TRENDING_FAVORITE_WEIGHT = 1     # Weight for favorite events
    FREE_SHIPPING_THRESHOLD_CENTS = 7500  # $75 CAD — subtotals at or above qualify for free standard shipping

    # Algolia monitoring
    ALGOLIA_SYNC_MISMATCH_THRESHOLD = 0.05  # 5%
    ALGOLIA_DLQ_MAX_RETRIES = 5  # Max retries for failed Algolia syncs in DLQ

    # Retention periods (cleanup cron jobs)
    WEBHOOK_EVENT_RETENTION_DAYS = 7  # Stripe won't replay events older than this
    SECURITY_ALERT_RETENTION_DAYS = 90  # Resolved alerts older than this are deleted

    # Tax rates by province
    TAX_RATES: dict[str, dict[str, float]] = {
        "AB": {"GST": 5.0},
        "BC": {"GST": 5.0, "PST": 7.0},
        "MB": {"GST": 5.0, "PST": 7.0},
        "NB": {"HST": 15.0},
        "NL": {"HST": 15.0},
        "NS": {"HST": 14.0},  # Changed from 15% to 14% on April 1, 2025 (CRA)
        "NT": {"GST": 5.0},
        "NU": {"GST": 5.0},
        "ON": {"HST": 13.0},
        "PE": {"HST": 15.0},
        "QC": {"GST": 5.0, "QST": 9.975},
        "SK": {"GST": 5.0, "PST": 6.0},
        "YT": {"GST": 5.0},
    }

    # Derived from TAX_RATES keys — single source of truth for valid provinces
    VALID_PROVINCES: frozenset[str] = frozenset(
        {"AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"}
    )

    # Stripe Tax Code constants (avoid magic strings in tax calculation)
    TAX_CODE_CHILDRENS_CLOTHING = "txcd_20030002"
    TAX_CODE_BASIC_GROCERIES = "txcd_30060005"
    TAX_CODE_GENERAL_GOODS = "txcd_99999999"
    TAX_CODE_SHIPPING = "txcd_92010001"
    TAX_CODE_VIDEO_GAMES = "txcd_10201000"
    TAX_CODE_BOOKS = "txcd_10302000"
    TAX_CODE_DIGITAL_SERVICES = "txcd_10000000"

    # Provinces where children's clothing is tax-exempt
    CHILDRENS_CLOTHING_EXEMPT_PROVINCES: frozenset[str] = frozenset({"ON", "BC", "MB", "SK"})

    # Stripe tax ID type for Canadian GST/HST
    STRIPE_TAX_TYPE_CA_GST_HST = "ca_gst_hst"

    # Default province for tax fallback
    DEFAULT_PROVINCE = "ON"


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

    ALL: frozenset[int] = frozenset({
        ELECTRONICS, COMPUTERS, GAMING, HOME_KITCHEN, FASHION,
        SHOES_ACCESSORIES, JEWELRY_WATCHES, BEAUTY_PERSONAL_CARE,
        HEALTH_WELLNESS, SPORTS_FITNESS, AUTOMOTIVE, TOOLS_HARDWARE,
        OFFICE_SUPPLIES, BOOKS, MUSIC_INSTRUMENTS, TOYS_GAMES,
        BABY_KIDS, PET_SUPPLIES, GROCERIES, ART_COLLECTIBLES, DIGITAL_PRODUCTS,
    })


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
    NEW_STATUS = "newStatus"
    APPROVED = "approved"
    NEW_SHIPPING_COST = "newShippingCost"
    SUBTOTAL = "subtotal"
    ITEM_IDS = "itemIds"
    IDEMPOTENCY_KEY = "idempotencyKey"

    # === RESPONSE KEYS (returned from Cloud Functions) ===
    SUCCESS = "success"
    ITEM_STATUS = "itemStatus"
    ALL_ITEMS_DELIVERED = "allItemsDelivered"
    ALL_ITEMS_SHIPPED = "allItemsShipped"
    PROVIDER_NAME = "providerName"
    CHECKOUT_URL = "checkoutUrl"
    SESSION_ID = "sessionId"
    URL = "url"
    SECRET = "secret"
    QR_CODE_URL = "qrCodeUrl"
    PROVISIONING_URI = "provisioning_uri"
    BACKUP_CODES = "backup_codes"
    MFA_VERIFIED = "mfaVerified"
    REMAINING_CODES = "remainingCodes"
    DETAILS_SUBMITTED = "detailsSubmitted"
    REQUIREMENTS_CURRENTLY_DUE = "requirementsCurrentlyDue"
    DUPLICATE = "duplicate"
    EMULATOR_MODE = "emulatorMode"
    CAPTURED = "captured"
    MESSAGE = "message"
    PAYMENT_INTENT_ID = "paymentIntentId"
    ACCOUNT_ID = "accountId"
    EXISTING = "existing"
    HAS_CHANGES = "hasChanges"
    PRICE_CHANGES = "priceChanges"
    STOCK_CHANGES = "stockChanges"
    REMOVED_PRODUCTS = "removedProducts"
    OLD_PRICE = "oldPrice"
    NEW_PRICE = "newPrice"
    REQUESTED = "requested"
    AVAILABLE = "available"
    PRODUCT_NAME = "productName"
    APPROVAL_REQUIRED = "approvalRequired"
    CART_SUBTOTAL_CENTS = "cartSubtotalCents"

    # === PAYMENT PROVIDER RESPONSE KEYS ===
    SUPPORTED_CURRENCIES = "supportedCurrencies"
    SUPPORTED_COUNTRIES = "supportedCountries"
    FEATURES = "features"
    PROVIDERS = "providers"
    PROVIDER_STATUS = "providerStatus"
    CONFIGURED = "configured"
    MISSING_KEYS = "missingKeys"
    ENABLED_PROVIDERS = "enabledProviders"
    ACTION = "action"
    APPROVE = "approve"
    MARK_RECEIVED = "mark_received"
    EXPECTED_COST_CENTS = "expectedCostCents"
    LICENSE_KEY = "licenseKey"
    PLATFORM = "platform"


class ErrorCodeValues:
    """Standardized error code values returned in HttpsError `details`."""

    PRICE_CHANGED = "PRICE_CHANGED"


class CartVerificationReasonValues:
    """Reason values returned by verify_cart_prices()."""

    DEACTIVATED = "deactivated"


class PlaceholderAddressValues:
    """Placeholder values used ONLY as last-resort fallbacks to prevent crashes."""

    UNKNOWN_TEXT = "N/A"
    DEFAULT_STATE = "ON"
    DEFAULT_POSTAL_CODE = "M5V 3A8"
    DEFAULT_COUNTRY = "Canada"


class DigitalTypeValues:
    SOFTWARE = "software"
    BOOK = "book"
    ALL = [SOFTWARE, BOOK]


class DigitalPlatformValues:
    MACOS = "macos"
    WINDOWS = "windows"
    LINUX = "linux"
    ALL = [MACOS, WINDOWS, LINUX]


class LicenseStatusValues:
    ACTIVE = "active"
    REVOKED = "revoked"
    ALL = [ACTIVE, REVOKED]


class SubscriptionStatusValues:
    """Stripe subscription status values"""

    ACTIVE = "active"
    CANCELED = "canceled"
    INACTIVE = "inactive"  # Internal status: no subscription doc exists
    PAST_DUE = "past_due"
    INCOMPLETE = "incomplete"
    INCOMPLETE_EXPIRED = "incomplete_expired"
    TRIALING = "trialing"
    UNPAID = "unpaid"
    ALL = [ACTIVE, CANCELED, INACTIVE, PAST_DUE, INCOMPLETE, INCOMPLETE_EXPIRED, TRIALING, UNPAID]
    # Statuses that grant premium access
    PREMIUM_ACTIVE = frozenset({ACTIVE, TRIALING})


# =============================================================================
# N-11: SUBCATEGORIES - Hierarchical subcategories per main category
# =============================================================================


class Subcategories:
    """Maps category name to list of subcategories. (N-11)"""

    MAP: dict[str, list[str]] = {
        "Fashion": ["Men's Clothing", "Women's Clothing", "Kids' Clothing", "Shoes", "Accessories", "Bags", "Jewelry"],
        "Electronics": ["Smartphones", "Laptops", "Tablets", "Cameras", "Audio", "Gaming", "Smart Home", "Wearables"],
        "Home & Garden": ["Furniture", "Decor", "Kitchen", "Bedding", "Lighting", "Garden & Outdoor", "Storage"],
        "Beauty & Personal Care": ["Skincare", "Haircare", "Makeup", "Fragrance", "Men's Grooming"],
        "Sports & Outdoors": ["Fitness", "Outdoor Recreation", "Team Sports", "Water Sports", "Winter Sports"],
        "Toys & Games": ["Puzzles & Board Games", "Building Toys", "Dolls & Playsets", "Video Games", "Outdoor Play"],
        "Food & Grocery": ["Snacks", "Beverages", "Health Foods", "Specialty Foods", "Baking"],
        "Books & Media": ["Books", "Music", "Movies & TV", "Magazines"],
        "Automotive": ["Car Accessories", "Motorcycle", "Tools & Equipment"],
        "Health": ["Vitamins & Supplements", "Medical Devices", "Personal Care"],
        "Art & Crafts": ["Drawing & Painting", "Yarn & Fiber Arts", "Paper Crafts", "Photography"],
        "Baby": ["Baby Clothing", "Feeding", "Nursery", "Strollers", "Toys"],
    }


# =============================================================================
# ORDER EVENT TYPES — tracks every status transition
# =============================================================================


class OrderEventTypes:
    """Valid event types for orders/{orderId}/events/{eventId}"""

    STATUS_CHANGED = "status_changed"
    PAYMENT_AUTHORIZED = "payment_authorized"
    PAYMENT_CAPTURED = "payment_captured"
    PAYMENT_FAILED = "payment_failed"
    REFUND_ISSUED = "refund_issued"
    ITEM_SHIPPED = "item_shipped"
    ITEM_DELIVERED = "item_delivered"
    CANCELLATION_CONFIRMED = "cancellation_confirmed"
    NOTE_ADDED = "note_added"
    AUTO_CONFIRMED = "auto_confirmed"
    ALL: frozenset = frozenset({
        "status_changed", "payment_authorized", "payment_captured", "payment_failed",
        "refund_issued", "item_shipped", "item_delivered", "cancellation_confirmed", "note_added",
        "auto_confirmed",
    })
