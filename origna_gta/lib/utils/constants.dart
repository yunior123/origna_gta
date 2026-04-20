// Application-wide constants for OrignaGTA
// Eliminates magic strings and provides type-safe status handling

import 'package:easy_localization/easy_localization.dart';
export 'package:easy_localization/easy_localization.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

// Re-export schema constants so existing imports keep working
export 'package:origna_gta/core/schema/schema_constants.dart'
    show
        Collections,
        Fields,
        OrderStatusValues,
        PaymentStatusValues,
        DeliveryStatusValues,
        PayoutStatusValues,
        ShippingApprovalStatusValues,
        UserRoleValues,
        ProductLifecycleStatusValues,
        SchemaRegistry,
        BusinessRules,
        CategoryIds,
        ApiKeys,
        ProvinceCodeValues,
        EmailConfig,
        FeatureFlags;

// ============================================================================
// APP CONFIGURATION
// ============================================================================

/// Application configuration constants
class AppConfig {
  static const String appName = 'Origna GTA';
  static const String appVersion = '1.1.0';
  static const String supportEmail = 'support@orignagta.ca';
  static const String websiteUrl = 'https://www.orignaventures.ca';
  static const String currency = 'cad';
  static const String currencySymbol = '\$';
  static const int autoConfirmDays =
      5; // Auto-confirm orders after 5 days (2-day safety margin before Stripe 7-day auth expires)
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
    return CaptureMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CaptureMethod.automatic,
    );
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
  final bool isInternational;
  final String? supplierType;

  const DeliveryItemCheck({
    required this.estimatedShipDays,
    this.isPerishable = false,
    this.isLocalOnly = false,
    this.isInternational = false,
    this.supplierType,
  });
}

/// Delivery speed options for checkout
enum DeliverySpeed {
  standard('standard', 'Free Delivery', '3-5 business days', 0),
  express('express', 'Express', '1-2 business days', 999),
  sameDay('same_day', 'Same Day', 'Delivered today', 1499),
  international(
    'international',
    'International Standard',
    '15-30 business days',
    0,
  ),
  internationalExpress(
    'international_express',
    'International Express',
    '7-15 business days',
    1999,
  ),
  maritime('maritime', 'Maritime Shipping', '21-45 business days', 0);

  final String value;
  final String displayName;
  final String estimatedTime;

  /// Surcharge in integer cents added to base shipping cost.
  final int baseSurchargeCents;

  const DeliverySpeed(
    this.value,
    this.displayName,
    this.estimatedTime,
    this.baseSurchargeCents,
  );

  /// Surcharge in dollars for display/legacy calculations.
  double get baseSurcharge => baseSurchargeCents / 100.0;

  /// Translation helpers
  String get translatedName => 'checkout.delivery_speed.$value.name'.tr();
  String get translatedTime => 'checkout.delivery_speed.$value.time'.tr();

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
      case DeliverySpeed.international:
        return now.add(const Duration(days: 30));
      case DeliverySpeed.internationalExpress:
        return now.add(const Duration(days: 15));
      case DeliverySpeed.maritime:
        return now.add(const Duration(days: 45)); // 21-45 days, show max
    }
  }

  /// Check if this delivery speed is available for given items
  /// Same-day only available for local/perishable items within delivery radius
  bool isAvailableForItems(
    List<DeliveryItemCheck> items,
    bool isLocalDelivery,
  ) {
    final hasInternational = items.any((item) => item.isInternational);

    switch (this) {
      case DeliverySpeed.standard:
      case DeliverySpeed.express:
      case DeliverySpeed.sameDay:
        // Domestic speeds only available if NO international items in cart
        if (hasInternational) return false;

        if (this == DeliverySpeed.standard) return true;
        if (this == DeliverySpeed.express) {
          return items.any((item) => item.estimatedShipDays <= 2);
        }

        // sameDay logic
        if (!isLocalDelivery) return false;
        return items.every(
          (item) => item.estimatedShipDays <= 1 || item.isPerishable,
        );

      case DeliverySpeed.international:
      case DeliverySpeed.internationalExpress:
        // International speeds only available if cart contains international items
        return hasInternational;
      case DeliverySpeed.maritime:
        // Maritime available for Cuba-bound shipments
        return true;
    }
  }

  static DeliverySpeed fromValue(String value) {
    return DeliverySpeed.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeliverySpeed.standard,
    );
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
        return 'orders.status.processing'.tr();
      case DeliveryStatus.shipped:
        return 'orders.status.shipped'.tr();
      case DeliveryStatus.delivered:
        return 'orders.status.delivered'.tr();
      case DeliveryStatus.refunded:
        return 'orders.status.refunded'.tr();
    }
  }

  /// Parse from string value
  static DeliveryStatus fromValue(String value) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeliveryStatus.pending,
    );
  }
}

// ============================================================================
// ORDER STATUS — canonical enum is in base_models.dart
// ============================================================================

// OrderStatus lives in lib/models/generated/base_models.dart (single source of truth).
// Extensions (displayText, value, fromValue) are in lib/models/enum_extensions.dart.
// Do NOT define OrderStatus here — use the canonical enum from base_models.dart.

// ============================================================================
// DELIVERY OPTIONS
// ============================================================================

/// Seller-defined delivery option for a product
/// Stored in database under [Fields.deliveryOptions].
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

/// Seller-defined shipping option with speed, price in cents, and enabled state.
class SellerDeliveryOption {
  final String type; // pickup | standard | express | same_day | custom
  final String description;
  final int costCents; // Base cost in cents (CAD)
  final int estimatedDays;
  final List<ShippingQuantityDiscount> quantityDiscounts;
  final int maxItemsPerShipment; // 0 = no limit
  final int additionalItemCostCents;
  final bool availableNationwide;

  const SellerDeliveryOption({
    required this.type,
    required this.description,
    required this.costCents,
    required this.estimatedDays,
    this.quantityDiscounts = const [],
    this.maxItemsPerShipment = 0,
    this.additionalItemCostCents = 0,
    this.availableNationwide = true,
  });

  static SellerDeliveryOption? fromMap(Map<String, dynamic> map) {
    // New schema (costCents)
    if (map.containsKey(Fields.type) || map.containsKey(Fields.costCents)) {
      final rawDiscounts = map[Fields.quantityDiscounts];
      final discounts = rawDiscounts is List
          ? rawDiscounts
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (d) => ShippingQuantityDiscount.fromMap(
                    d.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const <ShippingQuantityDiscount>[];

      return SellerDeliveryOption(
        type: map[Fields.type] as String? ?? '',
        description: map[Fields.description] as String? ?? '',
        costCents: (map[Fields.costCents] as num?)?.toInt() ?? 0,
        estimatedDays: (map[Fields.estimatedDays] as num?)?.toInt() ?? 0,
        quantityDiscounts: discounts,
        maxItemsPerShipment:
            (map[Fields.maxItemsPerShipment] as num?)?.toInt() ?? 0,
        additionalItemCostCents:
            (map[Fields.additionalItemCostCents] as num?)?.toInt() ?? 0,
        availableNationwide: map[Fields.availableNationwide] as bool? ?? true,
      );
    }

    // Alternate schema (speed/isEnabled/price)
    final isEnabled = map['isEnabled'] as bool? ?? false;
    if (!isEnabled) return null;

    final altSpeed = map['speed'] as String? ?? DeliverySpeed.standard.value;
    final altDays = (map['estimatedDays'] as num?)?.toInt() ?? 5;
    final altPriceCents = map.containsKey('priceCents')
        ? (map['priceCents'] as num?)?.toInt() ?? 0
        : (((map['price'] as num?)?.toDouble() ?? 0.0) * 100).round();

    final displayName = DeliverySpeed.fromValue(altSpeed).displayName;
    return SellerDeliveryOption(
      type: altSpeed,
      description: '$displayName Delivery',
      costCents: altPriceCents,
      estimatedDays: altDays,
    );
  }

  /// Get display text for delivery time
  String get deliveryTimeText {
    if (estimatedDays == 0) return 'Same day';
    if (estimatedDays == 1) return '1 day';
    return '$estimatedDays days';
  }

  double get costDollars => costCents / 100.0;
  double get additionalItemCostDollars => additionalItemCostCents / 100.0;

  /// Get price display text
  String get priceText =>
      costCents == 0 ? 'Free' : '\$${costDollars.toStringAsFixed(2)}';

  /// Calculate effective shipping cost for a given quantity.
  /// Mirrors backend `ShippingQuantityDiscount` logic.
  double calculateCostForQuantity(int quantity) {
    if (quantity <= 0) return costDollars;

    ShippingQuantityDiscount? bestDiscount;
    for (final discount in quantityDiscounts) {
      if (quantity >= discount.minQuantity) {
        if (bestDiscount == null ||
            discount.minQuantity > bestDiscount.minQuantity) {
          bestDiscount = discount;
        }
      }
    }

    var baseCost = costDollars;

    // Apply per-item costs if applicable
    if (maxItemsPerShipment > 0 && quantity > maxItemsPerShipment) {
      final extraItems = quantity - maxItemsPerShipment;
      baseCost += extraItems * additionalItemCostDollars;
    }

    // Apply quantity discount
    if (bestDiscount != null) {
      switch (bestDiscount.discountType) {
        case DiscountTypeValues.percent:
          return baseCost * (1 - bestDiscount.discountValue / 100);
        case DiscountTypeValues.fixed:
          return (baseCost - bestDiscount.discountValue).clamp(
            0,
            double.infinity,
          );
        case DiscountTypeValues.flatRate:
          return bestDiscount.discountValue;
        default:
          return baseCost;
      }
    }

    return baseCost;
  }

  Map<String, dynamic> toMap() => {
    Fields.type: type,
    Fields.description: description,
    Fields.costCents: costCents,
    Fields.estimatedDays: estimatedDays,
    if (quantityDiscounts.isNotEmpty)
      Fields.quantityDiscounts: quantityDiscounts
          .map((d) => d.toMap())
          .toList(),
    if (maxItemsPerShipment != 0)
      Fields.maxItemsPerShipment: maxItemsPerShipment,
    if (additionalItemCostCents != 0)
      Fields.additionalItemCostCents: additionalItemCostCents,
    if (!availableNationwide) Fields.availableNationwide: availableNationwide,
  };

  /// Create default options for a new product
  static List<SellerDeliveryOption> defaultOptions() => [
    const SellerDeliveryOption(
      type: DeliveryTypeValues.standard,
      description: 'Standard Delivery',
      costCents: 0,
      estimatedDays: 5,
    ),
    const SellerDeliveryOption(
      type: DeliveryTypeValues.express,
      description: 'Express Delivery',
      costCents: 999,
      estimatedDays: 2,
    ),
    const SellerDeliveryOption(
      type: DeliveryTypeValues.sameDay,
      description: 'Same Day Delivery',
      costCents: 1499,
      estimatedDays: 0,
    ),
  ];
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
