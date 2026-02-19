// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth
// ignore_for_file: non_abstract_class_inherits_abstract_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import '../../core/schema/schema_constants.dart';

part 'product_models.freezed.dart';
part 'product_models.g.dart';

/// International supplier platform types
const _internationalSupplierTypes = SupplierTypeValues.international;

/// Default delivery ranges by supplier type
({int minDays, int maxDays}) _getDeliveryRangeForSupplier(String? supplierType) {
  return switch (supplierType) {
    SupplierTypeValues.aliexpress => (minDays: 15, maxDays: 30),
    SupplierTypeValues.dhgate => (minDays: 20, maxDays: 40),
    SupplierTypeValues.alibaba => (minDays: 25, maxDays: 45),
    SupplierTypeValues.s1688 => (minDays: 25, maxDays: 45),
    SupplierTypeValues.temu => (minDays: 7, maxDays: 15),
    SupplierTypeValues.cjdropshipping => (minDays: 10, maxDays: 20),
    SupplierTypeValues.local => (minDays: 1, maxDays: 5),
    _ => (minDays: 3, maxDays: 7), // Default for local/other
  };
}

/// Get supplier region for display
String? _getSupplierRegion(String? supplierType) {
  return switch (supplierType) {
    SupplierTypeValues.aliexpress || SupplierTypeValues.alibaba || SupplierTypeValues.s1688 || SupplierTypeValues.temu => 'China',
    SupplierTypeValues.dhgate => 'China/Asia',
    SupplierTypeValues.cjdropshipping => 'Various (dropship)',
    SupplierTypeValues.local => 'Canada',
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
abstract class InventoryConfig with _$InventoryConfig {
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
// SELLER WAREHOUSE MODEL
// ============================================================================

@Freezed(toJson: true, fromJson: true)
abstract class SellerWarehouse with _$SellerWarehouse {
  const factory SellerWarehouse({
    required String warehouseId,

    /// Display name, e.g. 'Toronto Warehouse' or 'Home Office'
    required String label,

    /// Location type: 'warehouse' | 'personal'
    @Default('warehouse') String type,

    /// Physical address of this location
    required Address address,

    /// Whether this is the seller's default shipping origin
    @Default(false) bool isDefault,

    DateTime? createdAt,
  }) = _SellerWarehouse;

  factory SellerWarehouse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerWarehouse.fromJson({...data, 'warehouseId': doc.id});
  }

  factory SellerWarehouse.fromJson(Map<String, dynamic> json) => _$SellerWarehouseFromJson(json);
}

extension SellerWarehouseExtension on SellerWarehouse {
  bool get isWarehouse => type == 'warehouse';
  bool get isPersonal => type == 'personal';
  String get typeLabel => isWarehouse ? 'Warehouse' : 'Personal Address';
  String get cityProvince => '${address.city}, ${address.state}';
}

// ============================================================================
// PRODUCT MODEL
// ============================================================================

@Freezed(toJson: true, fromJson: true)
abstract class Product with _$Product {
  const factory Product({
    required String productId,
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String sellerId,
    // sellerAddress is optional — products with warehouses use warehouseIds instead
    Address? sellerAddress,
    required int categoryId,
    required int stockQuantity,
    @Default(0.0) double rating,
    @Default(0) int ratingCount,
    required DateTime createdAt,
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
    @Default(null) String? digitalType,
    @Default(null) String? slug,
    @Default(null) Map<String, String>? digitalBuilds,
    // bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
    @Default(null) int? deviceLimit,
    // Tax and metadata
    String? taxCode,
    @Default([]) List<String> keywords,
    // Admin approval — all products start under_review, go live only when approved
    @Default(ProductApprovalStatusValues.underReview) String approvalStatus,
    @Default(null) String? approvalRejectionReason,
    // Flat supplier fields (used when supplier object is not provided)
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // Structured objects for scalability
    /// Supplier information for dropshipping/marketplace products
    SupplierInfo? supplier,

    /// Inventory management configuration
    InventoryConfig? inventory,

    /// Product status: draft, active, paused, archived, out_of_stock
    @Default(ProductStatusValues.active) String status,

    // Multi-warehouse support
    /// Seller's unique product identifier — enforced unique per seller at write time
    String? sellerSku,

    /// IDs of seller warehouses this product ships from
    @Default(null) List<String>? warehouseIds,

    /// Stock per warehouse: {warehouseId: quantity}
    @Default(null) Map<String, int>? warehouseStock,

    /// City of primary shipping warehouse (denormalized for O(1) card rendering)
    String? shipFromCity,

    /// Province code of primary warehouse (denormalized for O(1) card rendering)
    String? shipFromProvince,
  }) = _Product;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreatedAt = data[Fields.createdAt];
    final DateTime parsedCreatedAt = switch (rawCreatedAt) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    return Product.fromJson({...data, 'productId': doc.id, 'createdAt': parsedCreatedAt.toIso8601String()});
  }

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

// ============================================================================
// PRODUCT CREATE MODEL
// ============================================================================

@freezed
abstract class ProductCreate with _$ProductCreate {
  const factory ProductCreate({
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String sellerId,
    // sellerAddress is optional — required only when warehouseIds is not provided
    Address? sellerAddress,
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
    @Default(null) String? digitalType,
    @Default(null) String? slug,
    @Default(null) Map<String, String>? digitalBuilds,
    // bookSourceUrl intentionally NOT included — buyer-protected: written by seller, never returned to client
    @Default(null) int? deviceLimit,
    String? taxCode,
    @Default([]) List<String> keywords,
    // approvalStatus intentionally not in ProductCreate — backend sets it to under_review on creation
    // Flat supplier fields (used when supplier object is not provided)
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // Structured objects
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    @Default(ProductStatusValues.active) String status,
    // Multi-warehouse support
    String? sellerSku,
    @Default(null) List<String>? warehouseIds,
    @Default(null) Map<String, int>? warehouseStock,
    String? shipFromCity,
    String? shipFromProvince,
  }) = _ProductCreate;

  factory ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);
}

// ============================================================================
// SELLER DELIVERY OPTION
// ============================================================================

@freezed
abstract class SellerDeliveryOption with _$SellerDeliveryOption {
  const factory SellerDeliveryOption({
    /// Delivery type: 'standard', 'express', 'same_day', etc.
    @Default(DeliveryTypeValues.standard) String type,

    /// Human-readable description
    @Default('') String description,

    /// Shipping cost in dollars
    @Default(0.0) double cost,

    /// Estimated delivery days
    @Default(3) int estimatedDays,

    /// Optional quantity-based discounts for this delivery option
    @Default([]) List<ShippingQuantityDiscount> quantityDiscounts,

    /// Maximum items before shipping cost increases (0 = no limit)
    @Default(0) int maxItemsPerShipment,

    /// Additional cost per item after maxItemsPerShipment (0 = free per-item)
    @Default(0.0) double additionalItemCost,

    /// Whether this option is available for international orders
    @Default(true) bool availableInternational,
  }) = _SellerDeliveryOption;

  factory SellerDeliveryOption.fromJson(Map<String, dynamic> json) =>
      _$SellerDeliveryOptionFromJson(json);
}

// ============================================================================
// SHIPPING QUANTITY DISCOUNT - Volume-based shipping discounts
// ============================================================================

@freezed
abstract class ShippingQuantityDiscount with _$ShippingQuantityDiscount {
  const factory ShippingQuantityDiscount({
    /// Minimum quantity to qualify for this discount
    required int minQuantity,

    /// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
    @Default(DiscountTypeValues.percent) String discountType,

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
abstract class SupplierInfo with _$SupplierInfo {
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
// PRODUCT EXTENSION - Helper getters
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
      supplierRegion: isInternationalSupplier 
          ? _getSupplierRegion(supplier?.type) 
          : '${sellerAddress?.city ?? shipFromCity ?? 'Unknown'}, ${sellerAddress?.state ?? shipFromProvince ?? ''}',
    );
  }

  /// Get effective cost (from supplier object or flat field)
  double? get effectiveCost => supplier?.cost ?? cost;

  /// Get effective supplier SKU (from supplier object or flat field)
  String? get effectiveSupplierSku => supplier?.supplierSku ?? supplierSku;

  /// Get effective supplier URL (from supplier object or flat field)
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
        case DiscountTypeValues.percent:
          return baseCost * (1 - bestDiscount.discountValue / 100);
        case DiscountTypeValues.fixed:
          return (baseCost - bestDiscount.discountValue).clamp(0, double.infinity);
        case DiscountTypeValues.flatRate:
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
          case DiscountTypeValues.percent:
            return '${discount.discountValue.toStringAsFixed(0)}% off shipping for ${discount.minQuantity}+ items';
          case DiscountTypeValues.fixed:
            return '\$${discount.discountValue.toStringAsFixed(2)} off shipping for ${discount.minQuantity}+ items';
          case DiscountTypeValues.flatRate:
            return 'Flat \$${discount.discountValue.toStringAsFixed(2)} shipping for ${discount.minQuantity}+ items';
        }
      }
    }
    return null;
  }
}
