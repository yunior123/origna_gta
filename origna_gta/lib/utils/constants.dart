// Application-wide constants for OrignaGTA
// Eliminates magic strings and provides type-safe status handling

// ============================================================================
// COLLECTION NAMES
// ============================================================================

/// Application configuration constants
class AppConfig {
  static const String appName = 'OrignaGta';
  static const String supportEmail = 'support@orignagta.ca';
  static const String websiteUrl = 'https://www.orignaventures.ca';
  static const String currency = 'cad';
  static const String currencySymbol = '\$';
  static const double platformFeePercent = 0.025; // 2.5% platform fee
  static const int autoConfirmDays = 7; // Auto-confirm orders after 7 days (Stripe authorization limit)
}

// ============================================================================
// USER ROLES
// ============================================================================

/// Capture method for payments
enum CaptureMethod {
  manual('manual'),
  automatic('automatic');

  final String value;
  const CaptureMethod(this.value);

  static CaptureMethod fromValue(String value) {
    return CaptureMethod.values.firstWhere((e) => e.value == value, orElse: () => CaptureMethod.automatic);
  }
}

// ============================================================================
// ORDER STATUS
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
// PAYMENT STATUS
// ============================================================================

/// Helper class for checking delivery availability
class DeliveryItemCheck {
  final int estimatedShipDays;
  final bool isPerishable; // Food, flowers, etc.
  final bool isLocalOnly;

  const DeliveryItemCheck({required this.estimatedShipDays, this.isPerishable = false, this.isLocalOnly = false});
}

/// Delivery speed options for checkout
enum DeliverySpeed {
  standard('standard', 'Free Delivery', '3-5 business days', 0.0),
  express('express', 'Express', '1-2 business days', 9.99),
  sameDay('same_day', 'Same Day', 'Delivered today', 14.99);

  final String value;
  final String displayName;
  final String estimatedTime;
  final double baseSurcharge; // Added to base shipping cost

  const DeliverySpeed(this.value, this.displayName, this.estimatedTime, this.baseSurcharge);

  /// Get delivery date estimate
  DateTime getEstimatedDeliveryDate() {
    final now = DateTime.now();
    switch (this) {
      case DeliverySpeed.standard:
        return now.add(const Duration(days: 5)); // 3-5 days, show max
      case DeliverySpeed.express:
        return now.add(const Duration(days: 2)); // 1-2 days
      case DeliverySpeed.sameDay:
        return now; // Same day
    }
  }

  /// Check if this delivery speed is available for given items
  /// Same-day only available for local/perishable items within delivery radius
  bool isAvailableForItems(List<DeliveryItemCheck> items, bool isLocalDelivery) {
    switch (this) {
      case DeliverySpeed.standard:
        return true; // Always available
      case DeliverySpeed.express:
        // Express available if any seller ships within 2 days
        return items.any((item) => item.estimatedShipDays <= 2);
      case DeliverySpeed.sameDay:
        // Same-day only for local delivery (within ~50km)
        // and if seller supports same-day (estimatedShipDays == 0 or isPerishable)
        if (!isLocalDelivery) return false;
        return items.every((item) => item.estimatedShipDays <= 1 || item.isPerishable);
    }
  }

  static DeliverySpeed fromValue(String value) {
    return DeliverySpeed.values.firstWhere((e) => e.value == value, orElse: () => DeliverySpeed.standard);
  }
}

/// Delivery status enum for individual order items
enum DeliveryStatus {
  pending('pending'),
  shipped('shipped'),
  delivered('delivered');

  final String value;
  const DeliveryStatus(this.value);

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

  /// Parse from string value
  static DeliveryStatus fromValue(String value) {
    return DeliveryStatus.values.firstWhere((e) => e.value == value, orElse: () => DeliveryStatus.pending);
  }
}

// ============================================================================
// DELIVERY STATUS (Per-Item)
// ============================================================================

/// Order status enum with string value conversion
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  processing('processing'),
  shipped('shipped'),
  inTransit('in_transit'),
  delivered('delivered'),
  cancelled('cancelled'),
  failed('failed'),
  expired('expired'),
  refunded('refunded'),
  partiallyRefunded('partially_refunded');

  final String value;
  const OrderStatus(this.value);

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
      case OrderStatus.inTransit:
        return 'In Transit';
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

  /// Parse from string value
  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere((e) => e.value == value, orElse: () => OrderStatus.pending);
  }
}

// ============================================================================
// APP CONFIGURATION
// ============================================================================

/// Payment status enum with string value conversion
enum PaymentStatus {
  awaitingPayment('awaiting_payment'),
  processing('processing'),
  authorized('authorized'),
  paid('paid'),
  captured('captured'),
  paymentFailed('payment_failed'),
  refunded('refunded'),
  sessionExpired('session_expired'),
  cancelled('cancelled'),
  authorizationExpired('authorization_expired');

  final String value;
  const PaymentStatus(this.value);

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
      case PaymentStatus.captured:
        return 'Payment Captured';
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

  /// Parse from string value
  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere((e) => e.value == value, orElse: () => PaymentStatus.awaitingPayment);
  }
}

// ============================================================================
// PAYOUT STATUS
// ============================================================================

// ============================================================================
// DELIVERY OPTIONS
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

  static PayoutStatus fromValue(String value) {
    return PayoutStatus.values.firstWhere((e) => e.value == value, orElse: () => PayoutStatus.pending);
  }
}

/// Seller-defined delivery option for a product
/// Allows sellers to configure delivery speeds, times (1-60 days), and prices
class SellerDeliveryOption {
  final DeliverySpeed speed;
  final bool isEnabled;
  final int estimatedDays; // 0 for same-day, 1-60 for others
  final double price; // 0.0 for free
  final int? maxRadiusKm; // Only for same-day (local delivery radius)

  const SellerDeliveryOption({required this.speed, this.isEnabled = false, required this.estimatedDays, this.price = 0.0, this.maxRadiusKm});

  factory SellerDeliveryOption.fromMap(Map<String, dynamic> map) {
    return SellerDeliveryOption(
      speed: DeliverySpeed.fromValue(map['speed'] ?? 'standard'),
      isEnabled: map['isEnabled'] ?? false,
      estimatedDays: map['estimatedDays'] ?? 5,
      price: (map['price'] ?? 0.0).toDouble(),
      maxRadiusKm: map['maxRadiusKm'],
    );
  }

  /// Get display text for delivery time
  String get deliveryTimeText {
    if (estimatedDays == 0) return 'Same day';
    if (estimatedDays == 1) return '1 day';
    return '$estimatedDays days';
  }

  /// Get price display text
  String get priceText => price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}';

  SellerDeliveryOption copyWith({DeliverySpeed? speed, bool? isEnabled, int? estimatedDays, double? price, int? maxRadiusKm}) => SellerDeliveryOption(
    speed: speed ?? this.speed,
    isEnabled: isEnabled ?? this.isEnabled,
    estimatedDays: estimatedDays ?? this.estimatedDays,
    price: price ?? this.price,
    maxRadiusKm: maxRadiusKm ?? this.maxRadiusKm,
  );

  Map<String, dynamic> toMap() => {
    'speed': speed.value,
    'isEnabled': isEnabled,
    'estimatedDays': estimatedDays,
    'price': price,
    if (maxRadiusKm != null) 'maxRadiusKm': maxRadiusKm,
  };

  /// Create default options for a new product
  static List<SellerDeliveryOption> defaultOptions() => [
    const SellerDeliveryOption(
      speed: DeliverySpeed.standard,
      isEnabled: true,
      estimatedDays: 5,
      price: 0.0, // Free standard shipping
    ),
    const SellerDeliveryOption(speed: DeliverySpeed.express, isEnabled: false, estimatedDays: 2, price: 9.99),
    const SellerDeliveryOption(
      speed: DeliverySpeed.sameDay,
      isEnabled: false,
      estimatedDays: 0,
      price: 14.99,
      maxRadiusKm: 50, // Default 50km radius
    ),
  ];
}

/// Shipping approval status for manual capture orders
enum ShippingApprovalStatus {
  notRequired('not_required'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const ShippingApprovalStatus(this.value);

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

  static ShippingApprovalStatus fromValue(String value) {
    return ShippingApprovalStatus.values.firstWhere((e) => e.value == value, orElse: () => ShippingApprovalStatus.notRequired);
  }
}

// ============================================================================
// PAYOUT STATUS
// ============================================================================

/// User role constants
class UserRoles {
  static const String admin = 'admin';
  static const String seller = 'seller';
  static const String buyer = 'buyer';
}
