// Application-wide constants for OrignaGTA
// Eliminates magic strings and provides type-safe status handling

// ============================================================================
// COLLECTION NAMES
// ============================================================================

/// Firestore collection names
class Collections {
  static const String users = 'users';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String cart = 'cart';
  static const String favorites = 'favorites';
  static const String webhookLogs = 'webhook_logs';
  static const String webhookEvents = 'webhook_events';
}

// ============================================================================
// USER ROLES
// ============================================================================

/// User role constants
class UserRoles {
  static const String admin = 'admin';
  static const String seller = 'seller';
}

// ============================================================================
// ORDER STATUS
// ============================================================================

/// Order status enum with string value conversion
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  cancelled('cancelled'),
  failed('failed'),
  expired('expired'),
  refunded('refunded'),
  partiallyRefunded('partially_refunded');

  final String value;
  const OrderStatus(this.value);

  /// Parse from string value
  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Get display text for UI
  String get displayText {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }
}

// ============================================================================
// PAYMENT STATUS
// ============================================================================

/// Payment status enum with string value conversion
enum PaymentStatus {
  awaitingPayment('awaiting_payment'),
  processing('processing'),
  authorized('authorized'),
  paid('paid'),
  paymentFailed('payment_failed'),
  refunded('refunded'),
  sessionExpired('session_expired'),
  cancelled('cancelled'),
  authorizationExpired('authorization_expired');

  final String value;
  const PaymentStatus(this.value);

  /// Parse from string value
  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.awaitingPayment,
    );
  }

  /// Get display text for UI
  String get displayText {
    switch (this) {
      case PaymentStatus.awaitingPayment:
        return 'Awaiting Payment';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.authorized:
        return 'Payment Authorized';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.paymentFailed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.sessionExpired:
        return 'Session Expired';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.authorizationExpired:
        return 'Authorization Expired';
    }
  }
}

/// Shipping approval status for manual capture orders
enum ShippingApprovalStatus {
  notRequired('not_required'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const ShippingApprovalStatus(this.value);

  static ShippingApprovalStatus fromValue(String value) {
    return ShippingApprovalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ShippingApprovalStatus.notRequired,
    );
  }

  String get displayText {
    switch (this) {
      case ShippingApprovalStatus.notRequired:
        return 'Not Required';
      case ShippingApprovalStatus.pending:
        return 'Awaiting Approval';
      case ShippingApprovalStatus.approved:
        return 'Approved';
      case ShippingApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Capture method for payments
enum CaptureMethod {
  manual('manual'),
  automatic('automatic');

  final String value;
  const CaptureMethod(this.value);

  static CaptureMethod fromValue(String value) {
    return CaptureMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CaptureMethod.automatic,
    );
  }
}

// ============================================================================
// DELIVERY STATUS (Per-Item)
// ============================================================================

/// Delivery status enum for individual order items
enum DeliveryStatus {
  pending('pending'),
  shipped('shipped'),
  delivered('delivered');

  final String value;
  const DeliveryStatus(this.value);

  /// Parse from string value
  static DeliveryStatus fromValue(String value) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeliveryStatus.pending,
    );
  }

  /// Get display text for UI
  String get displayText {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Processing';
      case DeliveryStatus.shipped:
        return 'Shipped';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }
}

// ============================================================================
// APP CONFIGURATION
// ============================================================================

/// Application configuration constants
class AppConfig {
  static const String appName = 'OrignaGta';
  static const String supportEmail = 'support@orignagta.ca';
  static const String websiteUrl = 'https://www.orignaventures.ca';
  static const String currency = 'cad';
  static const String currencySymbol = '\$';
  static const double platformFeePercent = 0.025; // 2.5% platform fee
  static const int autoConfirmDays = 14; // Auto-confirm orders after 14 days
}

// ============================================================================
// PAYOUT STATUS
// ============================================================================

/// Payout status for seller transfers
enum PayoutStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  partial('partial'),
  failed('failed');

  final String value;
  const PayoutStatus(this.value);

  static PayoutStatus fromValue(String value) {
    return PayoutStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PayoutStatus.pending,
    );
  }

  String get displayText {
    switch (this) {
      case PayoutStatus.pending:
        return 'Awaiting Confirmation';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Paid';
      case PayoutStatus.partial:
        return 'Partially Paid';
      case PayoutStatus.failed:
        return 'Failed';
    }
  }
}
