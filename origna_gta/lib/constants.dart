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
  paid('paid'),
  paymentFailed('payment_failed'),
  refunded('refunded'),
  sessionExpired('session_expired');

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
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.paymentFailed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.sessionExpired:
        return 'Session Expired';
    }
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
  static const String supportEmail = 'support@orignagta.com';
  static const String websiteUrl = 'https://orignagta.ca';
  static const String currency = 'cad';
  static const String currencySymbol = '\$';
}
