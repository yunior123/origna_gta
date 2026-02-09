// Schema Constants - Single Source of Truth for Field Names
//
// This file defines all Firestore field names as constants to:
// 1. Eliminate magic strings throughout the codebase
// 2. Enable IDE autocomplete and refactoring
// 3. Catch typos at compile time rather than runtime
// 4. Provide a single place to update field names
//
// USAGE:
//   // Instead of: doc.get('createdAt')
//   // Use: doc.get(Fields.createdAt)
//
//   // Instead of: FirebaseFirestore.instance.collection('orders')
//   // Use: FirebaseFirestore.instance.collection(Collections.orders)
//
// NAMING CONVENTION:
// - Dart constants: camelCase (e.g., createdAt)
// - Firestore fields: camelCase (e.g., 'createdAt')
// - Values match the actual Firestore field names
//
// See: docs/database_schema.json for full schema documentation

// =============================================================================
// COLLECTIONS - Top-level Firestore collection names
// =============================================================================

/// Firestore collection names
abstract final class Collections {
  static const users = 'users';
  static const products = 'products';
  static const orders = 'orders';
  static const payouts = 'payouts';
  static const refunds = 'refunds';
  static const webhookLogs = 'webhook_logs';
  static const webhookEvents = 'webhook_events';
  static const securityAlerts = 'security_alerts';
  static const rateLimits = 'rate_limits';
  static const config = 'config';
  static const adminLogs = 'admin_logs';
  static const productRatings = 'product_ratings';

  // Subcollections
  static const cart = 'cart'; // users/{userId}/cart
  static const favorites = 'favorites'; // users/{userId}/favorites
}

// =============================================================================
// FIELD NAMES - All Firestore document field names
// =============================================================================

/// Firestore document field names.
///
/// IMPORTANT: These are the canonical field names. All code MUST use these
/// constants instead of string literals to prevent drift.
///
/// Convention:
/// - Timestamps: Use [createdAt] for creation time across ALL collections
///   (except products which use [dateCreated] for legacy reasons)
/// - IDs: Use {entity}Id pattern (e.g., userId, productId, orderId)
/// - Amounts: Use {name}Cents for money (e.g., subtotalCents, taxAmountCents)
abstract final class Fields {
  // === COMMON TIMESTAMPS (used across multiple collections) ===
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const String deletedAt = 'deletedAt';
  static const String deletedBy = 'deletedBy';

  // === USER FIELDS ===
  static const uid = 'uid';
  static const email = 'email';
  static const name = 'name';
  static const roles = 'roles';
  static const address = 'address';
  static const customerId = 'customerId';
  static const lastCheckoutSession = 'lastCheckoutSession';
  static const lastOrderId = 'lastOrderId';
  static const lastCheckoutTimestamp = 'lastCheckoutTimestamp';
  static const stripeAccountId = 'stripeAccountId';
  static const payoutsEnabled = 'payoutsEnabled';
  static const chargesEnabled = 'chargesEnabled';
  static const onboardingCompleted = 'onboardingCompleted';
  static const pendingRequirements = 'pendingRequirements';
  static const paymentProvider = 'paymentProvider';
  static const airwallexAccountId = 'airwallexAccountId';
  static const airwallexCustomerId = 'airwallexCustomerId';
  static const airwallexStatus = 'airwallexStatus';
  static const suspended = 'suspended';
  static const suspendedAt = 'suspendedAt';
  static const unsuspendedAt = 'unsuspendedAt';
  static const suspendedBy = 'suspendedBy';
  static const suspensionReason = 'suspensionReason';
  static const commissionRate = 'commissionRate';
  static const verified = 'verified';
  static const verificationStatus = 'verificationStatus';
  static const platform = 'platform';
  static const businessName = 'businessName';
  static const payoutHoldDays = 'payoutHoldDays';

  // === USER MFA FIELDS (admin only) ===
  static const mfaEnabled = 'mfaEnabled';
  static const mfaSecret = 'mfaSecret';
  static const mfaSecretTemp = 'mfaSecretTemp';
  static const mfaFailedAttempts = 'mfaFailedAttempts';
  static const mfaLockoutUntil = 'mfaLockoutUntil';
  static const lastMfaVerify = 'lastMfaVerify';
  static const lastRoleUpdate = 'lastRoleUpdate';
  static const lastRoleUpdateBy = 'lastRoleUpdateBy';

  // === PRODUCT FIELDS ===
  static const productId = 'productId';
  static const price = 'price';
  static const description = 'description';
  static const imageUrls = 'imageUrls';
  static const sellerId = 'sellerId';
  static const sellerAddress = 'sellerAddress';
  static const categoryId = 'categoryId';
  static const stockQuantity = 'stockQuantity';
  static const rating = 'rating';
  static const ratingCount = 'ratingCount';
  static const keywords = 'keywords';
  static const isActive = 'isActive';

  /// NOTE: Products use dateCreated (legacy naming)
  static const dateCreated = 'dateCreated';
  static const isDigital = 'isDigital';
  static const weightKg = 'weightKg';
  static const lengthCm = 'lengthCm';
  static const widthCm = 'widthCm';
  static const heightCm = 'heightCm';
  static const isLocalDeliveryOnly = 'isLocalDeliveryOnly';
  static const isPerishable = 'isPerishable';
  static const estimatedShipDays = 'estimatedShipDays';
  static const deliveryOptions = 'deliveryOptions';
  static const estimatedDays = 'estimatedDays';
  static const cost = 'cost';
  static const minimumOrderQuantity = 'minimumOrderQuantity';
  static const freeShipping = 'freeShipping';
  static const taxCode = 'taxCode';
  static const supplier = 'supplier';
  static const inventory = 'inventory';
  static const status = 'status';
  static const deliverySpeed = 'deliverySpeed';

  // === ORDER FIELDS ===
  static const orderId = 'orderId';
  static const userId = 'userId';
  static const customerEmail = 'customerEmail';
  static const items = 'items';
  static const sellerIds = 'sellerIds';
  static const subtotalCents = 'subtotalCents';
  static const taxes = 'taxes';
  static const taxAmountCents = 'taxAmountCents';
  static const shippingCostCents = 'shippingCostCents';
  static const totalAmountCents = 'totalAmountCents';
  static const currency = 'currency';
  static const orderStatus = 'orderStatus';
  static const paymentStatus = 'paymentStatus';
  static const shippingAddress = 'shippingAddress';
  static const stripeSessionId = 'stripeSessionId';
  static const stripePaymentIntentId = 'stripePaymentIntentId';
  static const captureAttempts = 'captureAttempts';
  static const capturedAt = 'capturedAt';
  static const expiresAt = 'expiresAt';
  static const confirmedByClient = 'confirmedByClient';
  static const confirmedAt = 'confirmedAt';
  static const autoConfirmed = 'autoConfirmed';
  static const autoCaptured = 'autoCaptured';
  static const sellerPayouts = 'sellerPayouts';
  static const platformFeeTotal = 'platformFeeTotal';
  static const payoutStatus = 'payoutStatus';
  static const ratings = 'ratings';
  static const refundAmount = 'refundAmount';
  static const refundedAt = 'refundedAt';
  static const shippingApprovalStatus = 'shippingApprovalStatus';
  static const shippingApprovalRequired = 'shippingApprovalRequired';
  static const actualShipping = 'actualShipping';
  static const pendingTotal = 'pendingTotal';
  static const requiresManualReview = 'requiresManualReview';
  static const manualReviewReason = 'manualReviewReason';
  static const payoutErrors = 'payoutErrors';

  // === AIRWALLEX-SPECIFIC FIELDS ===
  static const airwallexPaymentId = 'airwallexPaymentId';
  static const paymentCompletedAt = 'paymentCompletedAt';
  static const paymentError = 'paymentError';
  static const requires3ds = 'requires3ds';
  static const authenticationUrl = 'authenticationUrl';

  // === ORDER FIELDS (missing from Dart, present in Python) ===
  static const shippingApproval = 'shippingApproval';
  static const stockRestored = 'stockRestored';
  static const cancelledBy = 'cancelledBy';
  static const cancelledAt = 'cancelledAt';
  static const cancellationReason = 'cancellationReason';
  static const respondedAt = 'respondedAt';
  static const actualCost = 'actualCost';

  // === ORDER ITEM FIELDS ===
  static const quantity = 'quantity';
  static const trackingNumber = 'trackingNumber';
  static const carrier = 'carrier';
  static const shippedAt = 'shippedAt';
  static const deliveredAt = 'deliveredAt';
  static const refundReason = 'refundReason';
  static const refundAmountCents = 'refundAmountCents';
  static const refundId = 'refundId';
  static const confirmedByBuyer = 'confirmedByBuyer';

  /// DEPRECATED: Use [status] instead
  static const deliveryStatus = 'deliveryStatus';

  // === PAYOUT FIELDS ===
  static const amountCents = 'amountCents';
  static const platformFeeCents = 'platformFeeCents';
  static const netAmountCents = 'netAmountCents';
  static const stripeTransferId = 'stripeTransferId';
  static const reversalId = 'reversalId';
  static const partialReversals = 'partialReversals';
  static const disputeId = 'disputeId';
  static const failureReason = 'failureReason';
  static const payoutDate = 'payoutDate';
  static const reversedAt = 'reversedAt';

  // === WEBHOOK FIELDS ===
  static const eventId = 'eventId';
  static const eventType = 'eventType';
  static const payloadSize = 'payloadSize';
  static const signatureVerified = 'signatureVerified';
  static const processingStatus = 'processingStatus';
  static const errorMessage = 'errorMessage';
  static const receivedAt = 'receivedAt';
  static const processed = 'processed';
  static const processedAt = 'processedAt';
  static const livemode = 'livemode';

  // === ADDRESS FIELDS ===
  static const formattedAddress = 'formattedAddress';
  static const street = 'street';
  static const apartment = 'apartment';
  static const city = 'city';
  static const state = 'state';
  static const postalCode = 'postalCode';
  static const country = 'country';
  static const phoneNumber = 'phoneNumber';
  static const isDefault = 'isDefault';
  static const label = 'label';
  static const latitude = 'latitude';
  static const longitude = 'longitude';

  // === PAYOUT/REFUND COMMON FIELDS ===
  static const provider = 'provider';
  static const amount = 'amount';
  static const completedAt = 'completedAt';
  static const failedAt = 'failedAt';
  static const error = 'error';
  static const paymentId = 'paymentId';

  // === SECURITY ALERT FIELDS ===
  static const type = 'type';
  static const severity = 'severity';
  static const resolved = 'resolved';
  static const resolvedAt = 'resolvedAt';
  static const resolution = 'resolution';
  static const timestamp = 'timestamp';
  static const chargeId = 'chargeId';
  static const accountId = 'accountId';
  static const reason = 'reason';
  static const destination = 'destination';
  static const failureMessage = 'failureMessage';
  static const adminId = 'adminId';
  // Alert data fields
  static const firestoreCount = 'firestoreCount';
  static const algoliaCount = 'algoliaCount';
  static const mismatchPercent = 'mismatchPercent';
  static const reversalErrors = 'reversalErrors';
  static const payoutId = 'payoutId';
  static const errorCode = 'errorCode';
  static const targetUserId = 'targetUserId';
  static const oldRoles = 'oldRoles';
  static const newRoles = 'newRoles';
  static const productsDeactivated = 'productsDeactivated';
  static const ordersCancelled = 'ordersCancelled';

  // === RATE LIMIT FIELDS ===
  static const count = 'count';
  static const firstRequest = 'first_request';
  static const lastRequest = 'last_request';

  // === WEBHOOK EVENT FIELDS ===
  static const clientIp = 'clientIp';

  // === CART FIELDS (subcollection uses dateCreated for legacy reasons) ===
  // NOTE: Cart items use [dateCreated], not [createdAt]
  static const dateFavorited = 'dateFavorited';

  // === LEGACY/DEPRECATED FIELDS (for backward compatibility) ===
  /// Legacy: use [confirmedByBuyer] instead
  static const buyerConfirmed = 'buyerConfirmed';

  /// Legacy: use [isLocalDeliveryOnly] instead
  static const localDeliveryOnly = 'localDeliveryOnly';

  /// Legacy: use [isPerishable] instead
  static const perishable = 'perishable';

  /// Legacy: use [estimatedShipDays] instead
  static const supplierShippingDays = 'supplierShippingDays';

  /// Legacy: use [minimumOrderQuantity] instead
  static const minOrderQuantity = 'minOrderQuantity';

  // === LEGACY JSON KEYS (lowercase variants for JSON API compatibility) ===
  /// Legacy lowercase: use [GST] instead
  static const gst = 'gst';

  /// Legacy lowercase: use [PST] instead
  static const pst = 'pst';

  /// Legacy lowercase: use [HST] instead
  static const hst = 'hst';

  /// Legacy lowercase: use [QST] instead
  static const qst = 'qst';

  // === REVIEW/RATING FIELDS ===
  static const review = 'review';
  static const comment = 'comment';

  // === TAX FIELDS ===
  // ignore: constant_identifier_names
  static const GST = 'GST';
  // ignore: constant_identifier_names
  static const PST = 'PST';
  // ignore: constant_identifier_names
  static const HST = 'HST';
  // ignore: constant_identifier_names
  static const QST = 'QST';
}

// =============================================================================
// ENUM VALUES - Valid values for enum fields
// =============================================================================

/// Valid values for orderStatus field
abstract final class OrderStatusValues {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const processing = 'processing';
  static const shipped = 'shipped';
  static const inTransit = 'in_transit';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const failed = 'failed';
  static const expired = 'expired';
  static const refunded = 'refunded';
  static const partiallyRefunded = 'partially_refunded';

  static const all = {
    pending,
    confirmed,
    processing,
    shipped,
    inTransit,
    delivered,
    cancelled,
    failed,
    expired,
    refunded,
    partiallyRefunded,
  };
}

/// Valid values for paymentStatus field
abstract final class PaymentStatusValues {
  static const awaitingPayment = 'awaiting_payment';
  static const processing = 'processing';
  static const paid = 'paid';
  static const paymentFailed = 'payment_failed';
  static const refunded = 'refunded';
  static const sessionExpired = 'session_expired';
  static const authorized = 'authorized';
  static const captured = 'captured';
  static const cancelled = 'cancelled';
  static const authorizationExpired = 'authorization_expired';
  // Transitional states (internal use, not stored long-term)
  static const capturing = 'capturing';
  static const cancelling = 'cancelling';
  static const expiring = 'expiring';

  static const all = {
    awaitingPayment,
    processing,
    paid,
    paymentFailed,
    refunded,
    sessionExpired,
    authorized,
    captured,
    cancelled,
    authorizationExpired,
    capturing,
    cancelling,
    expiring,
  };
}

/// Valid values for deliveryStatus/status field on order items
abstract final class DeliveryStatusValues {
  static const pending = 'pending';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const refunded = 'refunded';

  static const all = {pending, shipped, delivered, refunded};
}

/// Valid values for payoutStatus field
abstract final class PayoutStatusValues {
  static const pending = 'pending';
  static const processing = 'processing';
  static const completed = 'completed';
  static const partial = 'partial';
  static const failed = 'failed';
  static const reversed = 'reversed';
  static const reversedDispute = 'reversed_dispute';

  static const all = {
    pending,
    processing,
    completed,
    partial,
    failed,
    reversed,
    reversedDispute,
  };
}

/// Valid values for webhook processing status
abstract final class WebhookStatusValues {
  static const processing = 'processing';
  static const completed = 'completed';
  static const failed = 'failed';

  static const all = {processing, completed, failed};
}

/// Valid values for shippingApprovalStatus field
abstract final class ShippingApprovalStatusValues {
  static const notRequired = 'not_required';
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static const all = {notRequired, pending, approved, rejected};
}

/// Valid values for delivery option types
abstract final class DeliveryTypeValues {
  static const pickup = 'pickup';
  static const standard = 'standard';
  static const express = 'express';
  static const sameDay = 'same_day';
  static const localDelivery = 'local_delivery';
  static const custom = 'custom';
}

/// Security alert type values
abstract final class SecurityAlertTypes {
  static const algoliaSyncIssue = 'algolia_sync_issue';
  static const disputeCreated = 'dispute_created';
  static const roleChange = 'role_change';
  static const sellerSuspended = 'seller_suspended';
  static const paymentProviderDisabled = 'payment_provider_disabled';
  static const refundReversalFailed = 'refund_reversal_failed';
  static const payoutFailed = 'payout_failed';
  static const refundFailed = 'refund_failed';
  static const sellerAccountChanged = 'seller_account_changed';
  static const payoutRecordIncomplete = 'payout_record_incomplete';
}

/// Security alert severity levels
abstract final class SeverityLevels {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const critical = 'critical';
}

/// Valid values for roles array
abstract final class UserRoleValues {
  static const admin = 'admin';
  static const seller = 'seller';
  static const buyer = 'buyer';

  static const all = {admin, seller, buyer};
}

/// Valid values for product status field
abstract final class ProductStatusValues {
  static const draft = 'draft';
  static const active = 'active';
  static const paused = 'paused';
  static const archived = 'archived';
  static const outOfStock = 'out_of_stock';

  static const all = {draft, active, paused, archived, outOfStock};
}

/// Valid values for supplier platform types
abstract final class SupplierTypeValues {
  static const aliexpress = 'aliexpress';
  static const dhgate = 'dhgate';
  static const alibaba = 'alibaba';
  static const s1688 = '1688'; // Can't start with number, so use 's1688' as const name
  static const temu = 'temu';
  static const cjdropshipping = 'cjdropshipping';
  static const local = 'local';
  static const other = 'other';

  static const all = {aliexpress, dhgate, alibaba, s1688, temu, cjdropshipping, local, other};

  /// International suppliers (non-local)
  static const international = {aliexpress, dhgate, alibaba, s1688, temu, cjdropshipping};
}

/// Valid values for shipping discount types
abstract final class DiscountTypeValues {
  static const percent = 'percent';
  static const fixed = 'fixed';
  static const flatRate = 'flat_rate';

  static const all = {percent, fixed, flatRate};
}

/// Valid values for seller delivery option types
abstract final class DeliveryTypeValues {
  static const pickup = 'pickup';
  static const standard = 'standard';
  static const express = 'express';
  static const sameDay = 'same_day';
  static const custom = 'custom';

  static const all = {pickup, standard, express, sameDay, custom};
}

// =============================================================================
// SCHEMA REGISTRY - For runtime validation
// =============================================================================

/// Registry of expected fields per collection.
/// Used for validation and to get the correct timestamp field.
abstract final class SchemaRegistry {
  /// Timestamp field mapping (which field name each collection uses)
  static const timestampField = {
    Collections.users: Fields.createdAt,
    Collections.products: Fields.dateCreated, // Legacy: uses dateCreated
    Collections.orders: Fields.createdAt,
    Collections.payouts: Fields.createdAt,
    Collections.cart: Fields.dateCreated, // Subcollection: uses dateCreated
  };

  /// Get the correct timestamp field name for a collection.
  static String getTimestampField(String collection) {
    return timestampField[collection] ?? Fields.createdAt;
  }
}

// =============================================================================
// BUSINESS CONSTANTS
// =============================================================================

/// Business rule constants
abstract final class BusinessRules {
  static const platformFeePercent = 2.5;
  static const autoConfirmDays = 5;  // Must be < authorizationExpiryDays (2-day safety margin)
  static const authorizationExpiryDays = 7;
  static const maxCaptureAttempts = 3;
  static const defaultCurrency = 'cad';
  static const allowedCountries = {'Canada', 'CA'};

  /// Tax rates by province
  static const taxRates = {
    'AB': {'GST': 5.0},
    'BC': {'GST': 5.0, 'PST': 7.0},
    'MB': {'GST': 5.0, 'PST': 7.0},
    'NB': {'HST': 15.0},
    'NL': {'HST': 15.0},
    'NS': {'HST': 15.0},
    'NT': {'GST': 5.0},
    'NU': {'GST': 5.0},
    'ON': {'HST': 13.0},
    'PE': {'HST': 15.0},
    'QC': {'GST': 5.0, 'QST': 9.975},
    'SK': {'GST': 5.0, 'PST': 6.0},
    'YT': {'GST': 5.0},
  };
}

// =============================================================================
// CATEGORY IDS
// =============================================================================

/// Product category IDs
abstract final class CategoryIds {
  static const electronics = 1;
  static const computers = 2;
  static const gaming = 3;
  static const homeKitchen = 4;
  static const fashion = 5;
  static const shoesAccessories = 6;
  static const jewelryWatches = 7;
  static const beautyPersonalCare = 8;
  static const healthWellness = 9;
  static const sportsFitness = 10;
  static const automotive = 11;
  static const toolsHardware = 12;
  static const officeSupplies = 13;
  static const books = 14;
  static const musicInstruments = 15;
  static const toysGames = 16;
  static const babyKids = 17;
  static const petSupplies = 18;
  static const groceries = 19;
  static const artCollectibles = 20;
  static const digitalProducts = 21;

  static const min = 1;
  static const max = 21;
}

// =============================================================================
// API KEYS - Cloud Function request/response parameter names
// =============================================================================

/// Cloud Function API parameter and response keys.
/// These are NOT Firestore fields — they are the contract between
/// Flutter and Cloud Functions (request params + response keys).
abstract final class ApiKeys {
  // === REQUEST PARAMS (sent to Cloud Functions) ===
  static const add = 'add';
  static const remove = 'remove';
  static const reason = 'reason';
  static const code = 'code';
  static const provider = 'provider';
  static const enabled = 'enabled';
  static const refreshUrl = 'refreshUrl';
  static const returnUrl = 'returnUrl';

  // === RESPONSE KEYS (returned from Cloud Functions) ===
  static const checkoutUrl = 'checkoutUrl';
  static const sessionId = 'sessionId';
  static const url = 'url';
  static const secret = 'secret';
  static const qrCodeUrl = 'qrCodeUrl';
  static const provisioningUri = 'provisioning_uri';
  static const backupCodes = 'backup_codes';
  static const detailsSubmitted = 'detailsSubmitted';
  static const requirementsCurrentlyDue = 'requirementsCurrentlyDue';

  // === PAYMENT PROVIDER RESPONSE KEYS ===
  static const providers = 'providers';
  static const configured = 'configured';
  static const missingKeys = 'missingKeys';
  static const enabledProviders = 'enabledProviders';
}

