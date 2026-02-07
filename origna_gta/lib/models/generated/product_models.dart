// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';

part 'product_models.freezed.dart';
part 'product_models.g.dart';

/// International supplier platform types
const _internationalSupplierTypes = {'aliexpress', 'dhgate', 'alibaba', '1688', 'temu', 'cjdropshipping'};

/// Default delivery ranges by supplier type
({int minDays, int maxDays}) _getDeliveryRangeForSupplier(String? supplierType) {
  return switch (supplierType) {
    'aliexpress' => (minDays: 15, maxDays: 30),
    'dhgate' => (minDays: 20, maxDays: 40),
    'alibaba' => (minDays: 25, maxDays: 45),
    '1688' => (minDays: 25, maxDays: 45),
    'temu' => (minDays: 7, maxDays: 15),
    'cjdropshipping' => (minDays: 10, maxDays: 20),
    'local' => (minDays: 1, maxDays: 5),
    _ => (minDays: 3, maxDays: 7), // Default for local/other
  };
}

/// Get supplier region for display
String? _getSupplierRegion(String? supplierType) {
  return switch (supplierType) {
    'aliexpress' || 'alibaba' || '1688' || 'temu' => 'China',
    'dhgate' => 'China/Asia',
    'cjdropshipping' => 'Various (dropship)',
    'local' => 'Canada',
    _ => null,
  };
}

/// Delivery information for product detail display
class DeliveryInfo {
  final int minDays;
  final int maxDays;
  final bool isInternational;
  final bool hasTracking;
  final String estimateText;
  final String? supplierRegion;

  const DeliveryInfo({
    required this.minDays,
    required this.maxDays,
    required this.isInternational,
    required this.hasTracking,
    required this.estimateText,
    this.supplierRegion,
  });
}

// ============================================================================
// INVENTORY CONFIG MODEL - For flexible inventory management
// ============================================================================

@freezed
class InventoryConfig with _$InventoryConfig {
  const factory InventoryConfig({
    /// Whether inventory is actively managed (false for dropship products)
    @Default(true) bool managed,

    /// Track stock quantity (false = unlimited)
    @Default(true) bool trackQuantity,

    /// Allow orders when out of stock
    @Default(false) bool allowBackorder,

    /// Alert threshold for low stock
    @Default(5) int lowStockThreshold,

    /// How long to hold inventory during checkout (minutes)
    @Default(30) int reservationHoldMinutes,
  }) = _InventoryConfig;

  factory InventoryConfig.fromJson(Map<String, dynamic> json) => _$InventoryConfigFromJson(json);
}

// ============================================================================
// PRODUCT MODEL
// ============================================================================

@Freezed(toJson: true, fromJson: true)
class Product with _$Product {
  const factory Product({
    required String productId,
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String sellerId,
    required Address sellerAddress,
    required int categoryId,
    required int stockQuantity,
    @Default(0.0) double rating,
    required DateTime dateCreated,
    @Default(true) bool isActive,
    // Optional shipping metadata
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    // Delivery options
    @Default(false) bool isLocalDeliveryOnly,
    @Default(false) bool isPerishable,
    @Default(3) int estimatedShipDays,
    @Default([]) List<SellerDeliveryOption> deliveryOptions,
    @Default(1) int minimumOrderQuantity,
    @Default(false) bool freeShipping,
    // Digital product flag
    @Default(false) bool isDigital,
    // Tax and metadata
    String? taxCode,
    @Default([]) List<String> keywords,
    // DEPRECATED: Legacy flat fields - use supplier object instead
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // NEW: Structured objects for scalability
    /// Supplier information for dropshipping/marketplace products
    SupplierInfo? supplier,

    /// Inventory management configuration
    InventoryConfig? inventory,

    /// Product status: draft, active, paused, archived, out_of_stock
    @Default('active') String status,
  }) = _Product;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawDateCreated = data['dateCreated'];
    final DateTime parsedDateCreated = switch (rawDateCreated) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    return Product.fromJson({...data, 'productId': doc.id, 'dateCreated': parsedDateCreated.toIso8601String()});
  }

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

// ============================================================================
// PRODUCT CREATE MODEL
// ============================================================================

@freezed
class ProductCreate with _$ProductCreate {
  const factory ProductCreate({
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String sellerId,
    required Address sellerAddress,
    required int categoryId,
    required int stockQuantity,
    @Default(0.0) double rating,
    @Default(true) bool isActive,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    @Default(false) bool isLocalDeliveryOnly,
    @Default(false) bool isPerishable,
    @Default(3) int estimatedShipDays,
    @Default([]) List<SellerDeliveryOption> deliveryOptions,
    @Default(1) int minimumOrderQuantity,
    @Default(false) bool freeShipping,
    @Default(false) bool isDigital,
    String? taxCode,
    @Default([]) List<String> keywords,
    // DEPRECATED: Legacy flat fields
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // NEW: Structured objects
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    @Default('active') String status,
  }) = _ProductCreate;

  factory ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);
}

// ============================================================================
// SELLER DELIVERY OPTION
// ============================================================================

@freezed
class SellerDeliveryOption with _$SellerDeliveryOption {
  const factory SellerDeliveryOption({
    required String type,
    required String description,
    required double cost,
    required int estimatedDays,

    /// Optional quantity-based discounts for this delivery option
    @Default([]) List<ShippingQuantityDiscount> quantityDiscounts,

    /// Maximum items before shipping cost increases (0 = no limit)
    @Default(0) int maxItemsPerShipment,

    /// Additional cost per item after maxItemsPerShipment (0 = free per-item)
    @Default(0.0) double additionalItemCost,

    /// Whether this option is available for international orders
    @Default(true) bool availableInternational,
  }) = _SellerDeliveryOption;

  factory SellerDeliveryOption.fromJson(Map<String, dynamic> json) => _$SellerDeliveryOptionFromJson(json);
}

// ============================================================================
// SHIPPING QUANTITY DISCOUNT - Volume-based shipping discounts
// ============================================================================

@freezed
class ShippingQuantityDiscount with _$ShippingQuantityDiscount {
  const factory ShippingQuantityDiscount({
    /// Minimum quantity to qualify for this discount
    required int minQuantity,

    /// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
    @Default('percent') String discountType,

    /// Discount value (interpretation depends on discountType)
    required double discountValue,

    /// Optional label for display (e.g., "Bulk Shipping Discount")
    String? label,
  }) = _ShippingQuantityDiscount;

  factory ShippingQuantityDiscount.fromJson(Map<String, dynamic> json) => _$ShippingQuantityDiscountFromJson(json);
}

// ============================================================================
// SUPPLIER INFO MODEL - For dropshipping/marketplace products
// ============================================================================

@freezed
class SupplierInfo with _$SupplierInfo {
  const factory SupplierInfo({
    /// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
    required String type,

    /// Supplier's SKU/Product ID
    String? supplierSku,

    /// Direct URL to supplier product page
    String? supplierUrl,

    /// Cost price from supplier
    double? cost,

    /// Currency of supplier cost price (supplier's currency, NOT selling currency).
    /// Selling price is always CAD. This tracks the supplier's original currency.
    @Default('USD') String currency,

    /// Estimated shipping days range (e.g., '7-15')
    String? shippingDays,

    /// Whether supplier provides tracking
    @Default(false) bool hasTracking,

    /// Internal notes about this supplier/product
    String? notes,
  }) = _SupplierInfo;

  factory SupplierInfo.fromJson(Map<String, dynamic> json) => _$SupplierInfoFromJson(json);
}

// ============================================================================
// PRODUCT EXTENSION - Helper getters for backward compatibility
// ============================================================================

extension ProductExtension on Product {
  /// Check if product allows backorders
  bool get allowsBackorder => inventory?.allowBackorder ?? false;

  /// Get human-readable delivery estimate string
  String get deliveryEstimateText {
    final range = estimatedDeliveryDays;
    if (isDigital) return 'Instant delivery';
    if (isLocalDeliveryOnly) return '1-3 business days (local)';
    return '${range.minDays}-${range.maxDays} business days';
  }

  /// Get delivery info for buyers
  DeliveryInfo get deliveryInfo {
    return DeliveryInfo(
      minDays: estimatedDeliveryDays.minDays,
      maxDays: estimatedDeliveryDays.maxDays,
      isInternational: isInternationalSupplier,
      hasTracking: supplier?.hasTracking ?? !isInternationalSupplier,
      estimateText: deliveryEstimateText,
      supplierRegion: _getSupplierRegion(supplier?.type),
    );
  }

  /// Get effective cost (from supplier object or legacy field)
  double? get effectiveCost => supplier?.cost ?? cost;

  /// Get effective supplier SKU (from supplier object or legacy field)
  String? get effectiveSupplierSku => supplier?.supplierSku ?? supplierSku;

  /// Get effective supplier URL (from supplier object or legacy field)
  String? get effectiveSupplierUrl => supplier?.supplierUrl ?? supplierUrl;

  /// Get estimated delivery days range for buyers
  /// Returns a record (minDays, maxDays) based on supplier type
  ({int minDays, int maxDays}) get estimatedDeliveryDays {
    final supplierType = supplier?.type;

    // If supplier has explicit shipping days, parse that
    final shippingDays = supplier?.shippingDays;
    if (shippingDays != null && shippingDays.contains('-')) {
      final parts = shippingDays.split('-');
      final min = int.tryParse(parts[0].trim()) ?? 7;
      final max = int.tryParse(parts[1].trim()) ?? 21;
      return (minDays: min, maxDays: max);
    }

    // Otherwise use supplier type defaults
    return _getDeliveryRangeForSupplier(supplierType);
  }

  /// Check if product is from international supplier
  bool get isInternationalSupplier {
    final type = supplier?.type;
    return type != null && _internationalSupplierTypes.contains(type);
  }

  /// Check if inventory tracking is active
  bool get isInventoryManaged => inventory?.managed ?? true;

  /// Check if stock is low
  bool get isLowStock {
    final threshold = inventory?.lowStockThreshold ?? 5;
    return stockQuantity <= threshold && stockQuantity > 0;
  }

  /// Calculate profit margin percentage
  double? get marginPercent {
    final c = effectiveCost;
    if (c == null || c <= 0) return null;
    return ((price - c) / price) * 100;
  }

  /// Calculate profit amount
  double? get profit {
    final c = effectiveCost;
    if (c == null) return null;
    return price - c;
  }
}

// ============================================================================
// DELIVERY INFO - Structured delivery information for UI display
// ============================================================================

/// Extension for calculating shipping cost with quantity discounts
extension SellerDeliveryOptionExtension on SellerDeliveryOption {
  /// Calculate the effective shipping cost for a given quantity
  double calculateCostForQuantity(int quantity) {
    if (quantity <= 0) return cost;

    // Find the best applicable discount
    ShippingQuantityDiscount? bestDiscount;
    for (final discount in quantityDiscounts) {
      if (quantity >= discount.minQuantity) {
        if (bestDiscount == null || discount.minQuantity > bestDiscount.minQuantity) {
          bestDiscount = discount;
        }
      }
    }

    double baseCost = cost;

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

  /// Get discount description for a given quantity
  String? getDiscountDescriptionForQuantity(int quantity) {
    for (final discount in quantityDiscounts) {
      if (quantity >= discount.minQuantity) {
        if (discount.label != null) return discount.label;
        switch (discount.discountType) {
          case 'percent':
            return '${discount.discountValue.toStringAsFixed(0)}% off shipping for ${discount.minQuantity}+ items';
          case 'fixed':
            return '\$${discount.discountValue.toStringAsFixed(2)} off shipping for ${discount.minQuantity}+ items';
          case 'flat_rate':
            return 'Flat \$${discount.discountValue.toStringAsFixed(2)} shipping for ${discount.minQuantity}+ items';
        }
      }
    }
    return null;
  }
}
