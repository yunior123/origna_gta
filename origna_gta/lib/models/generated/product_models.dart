// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';

part 'product_models.freezed.dart';
part 'product_models.g.dart';

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
    // Tax and metadata
    String? taxCode,
    @Default([]) List<String> keywords,
  }) = _Product;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromJson({
      ...data,
      'productId': doc.id,
      'dateCreated': (data['dateCreated'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
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
    String? taxCode,
    @Default([]) List<String> keywords,
  }) = _ProductCreate;

  factory ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);
}

// ============================================================================
// SELLER DELIVERY OPTION
// ============================================================================

@freezed
class SellerDeliveryOption with _$SellerDeliveryOption {
  const factory SellerDeliveryOption({required String type, required String description, required double cost, required int estimatedDays}) =
      _SellerDeliveryOption;

  factory SellerDeliveryOption.fromJson(Map<String, dynamic> json) => _$SellerDeliveryOptionFromJson(json);
}
