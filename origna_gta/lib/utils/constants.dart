// Application-wide constants for OrignaGTA
// Eliminates magic strings and provides type-safe status handling

import 'package:origna_gta/core/schema/schema_constants.dart';

// Re-export schema constants so existing imports keep working
export 'package:origna_gta/core/schema/schema_constants.dart' show Collections, Fields, OrderStatusValues, PaymentStatusValues, DeliveryStatusValues, PayoutStatusValues, ShippingApprovalStatusValues, UserRoleValues, ProductStatusValues, SchemaRegistry, BusinessRules, CategoryIds, ApiKeys;

// ============================================================================
// APP CONFIGURATION
// ============================================================================

/// Application configuration constants
class AppConfig {
  static const String appName = 'Origna GTA';
  static const String supportEmail = 'support@orignagta.ca';
  static const String websiteUrl = 'https://www.orignaventures.ca';
  static const String currency = 'cad';
  static const String currencySymbol = '\$';
  static const double platformFeePercent = 0.025; // 2.5% platform fee
  static const int autoConfirmDays = 5; // Auto-confirm orders after 5 days (2-day safety margin before Stripe 7-day auth expires)
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

// Collections class is now defined in schema_constants.dart (re-exported above)

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
  pending(DeliveryStatusValues.pending),
  shipped(DeliveryStatusValues.shipped),
  delivered(DeliveryStatusValues.delivered),
  refunded(DeliveryStatusValues.refunded);

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
      case DeliveryStatus.refunded:
        return 'Refunded';
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
  pending(OrderStatusValues.pending),
  confirmed(OrderStatusValues.confirmed),
  processing(OrderStatusValues.processing),
  shipped(OrderStatusValues.shipped),
  inTransit(OrderStatusValues.inTransit),
  delivered(OrderStatusValues.delivered),
  cancelled(OrderStatusValues.cancelled),
  failed(OrderStatusValues.failed),
  expired(OrderStatusValues.expired),
  refunded(OrderStatusValues.refunded),
  partiallyRefunded(OrderStatusValues.partiallyRefunded),
  disputed(OrderStatusValues.disputed);

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
      case OrderStatus.disputed:
        return 'Disputed';
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
  awaitingPayment(PaymentStatusValues.awaitingPayment),
  processing(PaymentStatusValues.processing),
  authorized(PaymentStatusValues.authorized),
  paid(PaymentStatusValues.paid),
  captured(PaymentStatusValues.captured),
  paymentFailed(PaymentStatusValues.paymentFailed),
  refunded(PaymentStatusValues.refunded),
  sessionExpired(PaymentStatusValues.sessionExpired),
  cancelled(PaymentStatusValues.cancelled),
  authorizationExpired(PaymentStatusValues.authorizationExpired),
  capturing(PaymentStatusValues.capturing),
  cancelling(PaymentStatusValues.cancelling),
  expiring(PaymentStatusValues.expiring);

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
      case PaymentStatus.capturing:
        return 'Capturing Payment';
      case PaymentStatus.cancelling:
        return 'Cancelling';
      case PaymentStatus.expiring:
        return 'Expiring';
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
  pending(PayoutStatusValues.pending),
  processing(PayoutStatusValues.processing),
  completed(PayoutStatusValues.completed),
  partial(PayoutStatusValues.partial),
  failed(PayoutStatusValues.failed);

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
/// Stored in Firestore under [Fields.deliveryOptions].
///
/// Canonical schema uses: type/description/cost/estimatedDays (+ optional volume discounts).
/// Alternate schema uses: speed/isEnabled/price/maxRadiusKm.
class ShippingQuantityDiscount {
  final int minQuantity;

  /// 'percent' | 'fixed' | 'flat_rate'
  final String discountType;

  final double discountValue;
  final String? label;

  const ShippingQuantityDiscount({
    required this.minQuantity,
    this.discountType = 'percent',
    required this.discountValue,
    this.label,
  });

  factory ShippingQuantityDiscount.fromMap(Map<String, dynamic> map) {
    return ShippingQuantityDiscount(
      minQuantity: (map['minQuantity'] as num?)?.toInt() ?? 0,
      discountType: map['discountType'] as String? ?? 'percent',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'minQuantity': minQuantity,
    'discountType': discountType,
    'discountValue': discountValue,
    if (label != null) 'label': label,
  };
}

class SellerDeliveryOption {
  final String type; // pickup | standard | express | same_day | custom
  final String description;
  final double cost; // Base cost in CAD
  final int estimatedDays;
  final List<ShippingQuantityDiscount> quantityDiscounts;
  final int maxItemsPerShipment; // 0 = no limit
  final double additionalItemCost;
  final bool availableInternational;

  const SellerDeliveryOption({
    required this.type,
    required this.description,
    required this.cost,
    required this.estimatedDays,
    this.quantityDiscounts = const [],
    this.maxItemsPerShipment = 0,
    this.additionalItemCost = 0.0,
    this.availableInternational = true,
  });

  static SellerDeliveryOption? fromMap(Map<String, dynamic> map) {
    // New schema
    if (map.containsKey('type') || map.containsKey('cost')) {
      final rawDiscounts = map['quantityDiscounts'];
      final discounts = rawDiscounts is List
          ? rawDiscounts.whereType<Map>().map((d) => ShippingQuantityDiscount.fromMap(d.cast<String, dynamic>())).toList()
          : const <ShippingQuantityDiscount>[];

      return SellerDeliveryOption(
        type: map['type'] as String? ?? '',
        description: map['description'] as String? ?? '',
        cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
        estimatedDays: (map['estimatedDays'] as num?)?.toInt() ?? 0,
        quantityDiscounts: discounts,
        maxItemsPerShipment: (map['maxItemsPerShipment'] as num?)?.toInt() ?? 0,
        additionalItemCost: (map['additionalItemCost'] as num?)?.toDouble() ?? 0.0,
        availableInternational: map['availableInternational'] as bool? ?? true,
      );
    }

    // Alternate schema (speed/isEnabled/price)
    final isEnabled = map['isEnabled'] as bool? ?? false;
    if (!isEnabled) return null;

    final altSpeed = map['speed'] as String? ?? DeliverySpeed.standard.value;
    final altDays = (map['estimatedDays'] as num?)?.toInt() ?? 5;
    final altPrice = (map['price'] as num?)?.toDouble() ?? 0.0;

    final displayName = DeliverySpeed.fromValue(altSpeed).displayName;
    return SellerDeliveryOption(
      type: altSpeed,
      description: '$displayName Delivery',
      cost: altPrice,
      estimatedDays: altDays,
    );
  }

  /// Get display text for delivery time
  String get deliveryTimeText {
    if (estimatedDays == 0) return 'Same day';
    if (estimatedDays == 1) return '1 day';
    return '$estimatedDays days';
  }

  /// Get price display text
  String get priceText => cost == 0 ? 'Free' : '\$${cost.toStringAsFixed(2)}';

  /// Calculate effective shipping cost for a given quantity.
  /// Mirrors backend `ShippingQuantityDiscount` logic.
  double calculateCostForQuantity(int quantity) {
    if (quantity <= 0) return cost;

    ShippingQuantityDiscount? bestDiscount;
    for (final discount in quantityDiscounts) {
      if (quantity >= discount.minQuantity) {
        if (bestDiscount == null || discount.minQuantity > bestDiscount.minQuantity) {
          bestDiscount = discount;
        }
      }
    }

    var baseCost = cost;

    // Apply per-item costs if applicable
    if (maxItemsPerShipment > 0 && quantity > maxItemsPerShipment) {
      final extraItems = quantity - maxItemsPerShipment;
      baseCost += extraItems * additionalItemCost;
    }

    // Apply quantity discount
    if (bestDiscount != null) {
      switch (bestDiscount.discountType) {
        case 'percent':
          return baseCost * (1 - bestDiscount.discountValue / 100);
        case 'fixed':
          return (baseCost - bestDiscount.discountValue).clamp(0, double.infinity);
        case 'flat_rate':
          return bestDiscount.discountValue;
        default:
          return baseCost;
      }
    }

    return baseCost;
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'description': description,
    'cost': cost,
    'estimatedDays': estimatedDays,
    if (quantityDiscounts.isNotEmpty) 'quantityDiscounts': quantityDiscounts.map((d) => d.toMap()).toList(),
    if (maxItemsPerShipment != 0) 'maxItemsPerShipment': maxItemsPerShipment,
    if (additionalItemCost != 0.0) 'additionalItemCost': additionalItemCost,
    if (!availableInternational) 'availableInternational': availableInternational,
  };

  /// Create default options for a new product
  static List<SellerDeliveryOption> defaultOptions() => [
    const SellerDeliveryOption(type: 'standard', description: 'Standard Delivery', cost: 0.0, estimatedDays: 5),
    const SellerDeliveryOption(type: 'express', description: 'Express Delivery', cost: 9.99, estimatedDays: 2),
    const SellerDeliveryOption(type: 'same_day', description: 'Same Day Delivery', cost: 14.99, estimatedDays: 0),
  ];
}

/// Shipping approval status for manual capture orders
enum ShippingApprovalStatus {
  notRequired(ShippingApprovalStatusValues.notRequired),
  pending(ShippingApprovalStatusValues.pending),
  approved(ShippingApprovalStatusValues.approved),
  rejected(ShippingApprovalStatusValues.rejected);

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
  static const admin = UserRoleValues.admin;
  static const seller = UserRoleValues.seller;
  static const buyer = UserRoleValues.buyer;
}
