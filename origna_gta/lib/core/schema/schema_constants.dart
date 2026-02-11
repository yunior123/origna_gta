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
  static const algoliaSyncFailures = 'algolia_sync_failures';

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
/// - IDs: Use {entity}Id pattern (e.g., userId, productId, orderId)
/// - Amounts: Use {name}Cents for money (e.g., subtotalCents, taxAmountCents)
abstract final class Fields {
  // === COMMON TIMESTAMPS (used across multiple collections) ===
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const String deletedAt = 'deletedAt';
  static const String deletedBy = 'deletedBy';
  static const String deleted = 'deleted';
  static const String anonymizedAt = 'anonymizedAt';
  static const String originalUserDeleted = 'originalUserDeleted';

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
  static const unsuspendedBy = 'unsuspendedBy';
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
  static const mfaBackupCodes = 'mfaBackupCodes';
  static const mfaBackupCodesTemp = 'mfaBackupCodesTemp';
  static const mfaBackupCodesSalt = 'mfaBackupCodesSalt';
  static const lastRoleUpdate = 'lastRoleUpdate';
  static const lastRoleUpdateBy = 'lastRoleUpdateBy';

  // === USER PROFILE FIELDS (missing, synced from Python) ===
  static const sellerProfile = 'sellerProfile';
  static const businessAddress = 'businessAddress';
  static const fullName = 'fullName';
  static const isCorporate = 'isCorporate';
  static const bankDetails = 'bankDetails';

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
  static const taxCents = 'taxCents';
  static const taxRate = 'taxRate';
  static const lastCaptureError = 'lastCaptureError';
  static const sellerStripeAccounts = 'sellerStripeAccounts';
  static const archivedAt = 'archivedAt';
  static const updatedBy = 'updatedBy';
  static const originalCostCents = 'originalCostCents';
  static const newCostCents = 'newCostCents';
  static const requestedBy = 'requestedBy';
  static const requestedAt = 'requestedAt';
  static const action = 'action';
  static const customerName = 'customerName';
  static const searchKeywords = 'searchKeywords';
  static const deactivationReason = 'deactivationReason';
  static const retries = 'retries';

  // === TAX FIELDS (new) ===
  static const itemTaxes = 'itemTaxes';
  static const taxExempt = 'taxExempt';
  static const taxExemption = 'taxExemption';
  static const gstNumber = 'gstNumber';

  // === CONSENT & COMPLIANCE FIELDS (CASL + PIPEDA + Quebec Law 25) ===
  static const emailConsent = 'emailConsent';
  static const marketingOptIn = 'marketingOptIn';
  static const consentTimestamp = 'consentTimestamp';
  static const consentMethod = 'consentMethod';
  static const privacyAcceptedAt = 'privacyAcceptedAt';
  static const termsAcceptedAt = 'termsAcceptedAt';
  static const privacyPolicyVersion = 'privacyPolicyVersion';
  static const termsVersion = 'termsVersion';
  static const preferredLanguage = 'preferredLanguage';
  static const unsubscribedAt = 'unsubscribedAt';
  static const dataProcessingConsent = 'dataProcessingConsent';

  // === DELIVERY FIELDS ===
  static const deliveryInstructions = 'deliveryInstructions';

  // === FIELDS missing from Dart (present in Python) ===
  static const archived = 'archived';

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

  /// Parallel status field alongside [status] (both are written for consistency)
  static const deliveryStatus = 'deliveryStatus';

  // === PAYOUT FIELDS ===
  static const amountCents = 'amountCents';
  static const platformFeeCents = 'platformFeeCents';
  static const netAmountCents = 'netAmountCents';
  static const stripeTransferId = 'stripeTransferId';
  static const reversalId = 'reversalId';
  static const partialReversals = 'partialReversals';
  static const disputeId = 'disputeId';
  static const preDisputeStatus = 'preDisputeStatus';
  static const disputeResolvedAt = 'disputeResolvedAt';
  static const disputeResolution = 'disputeResolution';
  static const failureReason = 'failureReason';
  static const payoutDate = 'payoutDate';
  static const reversedAt = 'reversedAt';
  static const cumulativeRefundedCents = 'cumulativeRefundedCents';
  static const partialRefundAmountCents = 'partialRefundAmountCents';
  static const transfersReversed = 'transfersReversed';
  static const disputedAt = 'disputedAt';
  static const cumulativeReversedCents = 'cumulativeReversedCents';
  static const reversalReason = 'reversalReason';
  static const paymentIntentId = 'paymentIntentId';
  static const transferId = 'transferId';

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

  // === CART & FAVORITES FIELDS ===
  static const dateFavorited = 'dateFavorited';

  // === ALTERNATE FIELD NAMES (used in Firestore deserialization fallbacks) ===
  /// Alternate name for [confirmedByBuyer]
  static const buyerConfirmed = 'buyerConfirmed';

  /// Alternate name for [isLocalDeliveryOnly]
  static const localDeliveryOnly = 'localDeliveryOnly';

  /// Alternate name for [isPerishable]
  static const perishable = 'perishable';

  /// Alternate name for [estimatedShipDays]
  static const supplierShippingDays = 'supplierShippingDays';

  /// Alternate name for [minimumOrderQuantity]
  static const minOrderQuantity = 'minOrderQuantity';

  // === LOWERCASE TAX KEYS (used in JSON API responses) ===
  /// Lowercase variant of [GST] for JSON responses
  static const gst = 'gst';

  /// Lowercase variant of [PST] for JSON responses
  static const pst = 'pst';

  /// Lowercase variant of [HST] for JSON responses
  static const hst = 'hst';

  /// Lowercase variant of [QST] for JSON responses
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
  static const disputed = 'disputed';

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
    disputed,
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
  static const partiallyReversed = 'partially_reversed';
  static const reversedDispute = 'reversed_dispute';

  static const all = {
    pending,
    processing,
    completed,
    partial,
    failed,
    reversed,
    partiallyReversed,
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
  static const sellerUnsuspended = 'seller_unsuspended';
  static const paymentProviderDisabled = 'payment_provider_disabled';
  static const refundReversalFailed = 'refund_reversal_failed';
  static const payoutFailed = 'payout_failed';
  static const refundFailed = 'refund_failed';
  static const sellerAccountChanged = 'seller_account_changed';
  static const payoutRecordIncomplete = 'payout_record_incomplete';
  static const mfaLowBackupCodes = 'mfa_low_backup_codes';
  static const sellerKycFailed = 'seller_kyc_failed';
  static const invalidGstAttempt = 'invalid_gst_attempt';
  static const blockedGstAttempt = 'blocked_gst_attempt';
  static const sharedGstNumber = 'shared_gst_number';
  static const taxExemptionPendingReview = 'tax_exemption_pending_review';
  static const suspiciousTaxExemption = 'suspicious_tax_exemption';
  static const authDeletionFailed = 'auth_deletion_failed';
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
  static const s1688 =
      '1688'; // Can't start with number, so use 's1688' as const name
  static const temu = 'temu';
  static const cjdropshipping = 'cjdropshipping';
  static const local = 'local';
  static const other = 'other';

  static const all = {
    aliexpress,
    dhgate,
    alibaba,
    s1688,
    temu,
    cjdropshipping,
    local,
    other,
  };

  /// International suppliers (non-local)
  static const international = {
    aliexpress,
    dhgate,
    alibaba,
    s1688,
    temu,
    cjdropshipping,
  };
}

/// Valid values for shipping discount types
abstract final class DiscountTypeValues {
  static const percent = 'percent';
  static const fixed = 'fixed';
  static const flatRate = 'flat_rate';

  static const all = {percent, fixed, flatRate};
}

// =============================================================================
// EMAIL & COMPLIANCE CONFIGURATION
// =============================================================================

/// Email and CASL compliance constants — Dart mirror of Python EmailConfig
abstract final class EmailConfig {
  static const supportEmail = 'support@orignaventures.ca';
  static const senderName = 'Origna GTA';
  static const copyrightText = '\u00a9 2026 Origna Ventures Inc. All rights reserved.';
  static const appTagline = "Canada's Modern Marketplace";
  static const prodUrl = 'https://orignagta.ca';

  // === CASL COMPLIANCE ===
  /// Physical mailing address — REQUIRED by CASL in every commercial email
  static const physicalAddress =
      'Origna Ventures Inc., 136 Shaver Ave N, Toronto, ON M9B 4N8, Canada';

  /// GST/HST Registration Number — REQUIRED on all receipts (Excise Tax Act)
  static const gstHstNumber = '708286364RC0001';

  /// Unsubscribe URL — REQUIRED by CASL
  static const unsubscribeUrl = 'https://orignagta.ca/unsubscribe';

  /// Privacy Officer contact — REQUIRED by Quebec Law 25
  static const privacyOfficerEmail = 'privacy@orignaventures.ca';
  static const privacyOfficerName = 'Yunior Rodriguez Osorio';
}

/// Consent method values for CASL compliance tracking
abstract final class ConsentMethodValues {
  static const signup = 'signup';
  static const checkbox = 'checkbox';
  static const doubleOptIn = 'double_opt_in';
  static const implied = 'implied';

  static const all = {signup, checkbox, doubleOptIn, implied};
}


/// Registry of expected fields per collection.
/// Used for validation and to get the correct timestamp field.
abstract final class SchemaRegistry {
  /// Timestamp field mapping (which field name each collection uses)
  static const timestampField = {
    Collections.users: Fields.createdAt,
    Collections.products: Fields.createdAt,
    Collections.orders: Fields.createdAt,
    Collections.payouts: Fields.createdAt,
    Collections.cart: Fields.createdAt,
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
  static const autoConfirmDays =
      5; // Must be < authorizationExpiryDays (2-day safety margin)
  static const authorizationExpiryDays = 7;
  static const returnWindowDays =
      7; // No returns/refunds after 7 days post-delivery
  static const maxCaptureAttempts = 3;
  static const defaultCurrency = 'cad';
  static const allowedShippingCountries = {'Canada', 'CA'};
  // Sellers can be from any country — no country restriction on seller addresses

  /// Tax rates by province
  static const taxRates = {
    'AB': {'GST': 5.0},
    'BC': {'GST': 5.0, 'PST': 7.0},
    'MB': {'GST': 5.0, 'PST': 7.0},
    'NB': {'HST': 15.0},
    'NL': {'HST': 15.0},
    'NS': {'HST': 14.0}, // Changed from 15% to 14% on April 1, 2025 (CRA)
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
  static const newStatus = 'newStatus';
  static const approved = 'approved';
  static const newShippingCost = 'newShippingCost';
  static const subtotal = 'subtotal';
  static const itemIds = 'itemIds';

  // === RESPONSE KEYS (returned from Cloud Functions) ===
  static const success = 'success';
  static const itemStatus = 'itemStatus';
  static const allItemsDelivered = 'allItemsDelivered';
  static const providerName = 'providerName';
  static const checkoutUrl = 'checkoutUrl';
  static const sessionId = 'sessionId';
  static const url = 'url';
  static const secret = 'secret';
  static const qrCodeUrl = 'qrCodeUrl';
  static const provisioningUri = 'provisioning_uri';
  static const backupCodes = 'backup_codes';
  static const mfaVerified = 'mfaVerified';
  static const remainingCodes = 'remainingCodes';
  static const detailsSubmitted = 'detailsSubmitted';
  static const requirementsCurrentlyDue = 'requirementsCurrentlyDue';
  static const duplicate = 'duplicate';
  static const emulatorMode = 'emulatorMode';
  static const captured = 'captured';
  static const message = 'message';
  static const paymentIntentId = 'paymentIntentId';
  static const accountId = 'accountId';
  static const existing = 'existing';
  static const hasChanges = 'hasChanges';
  static const priceChanges = 'priceChanges';
  static const stockChanges = 'stockChanges';
  static const removedProducts = 'removedProducts';
  static const oldPrice = 'oldPrice';
  static const newPrice = 'newPrice';
  static const requested = 'requested';
  static const available = 'available';
  static const productName = 'productName';

  // === PAYMENT PROVIDER RESPONSE KEYS ===
  static const supportedCurrencies = 'supportedCurrencies';
  static const supportedCountries = 'supportedCountries';
  static const features = 'features';
  static const providers = 'providers';
  static const providerStatus = 'providerStatus';
  static const configured = 'configured';
  static const missingKeys = 'missingKeys';
  static const enabledProviders = 'enabledProviders';

  // === SHIPPING RESPONSE KEYS ===
  static const allItemsShipped = 'allItemsShipped';
  static const approvalRequired = 'approvalRequired';
}
