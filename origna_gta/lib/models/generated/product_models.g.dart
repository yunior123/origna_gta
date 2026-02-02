// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(
  Map<String, dynamic> json,
) => _$ProductImpl(
  productId: json['productId'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sellerId: json['sellerId'] as String,
  sellerAddress: Address.fromJson(
    json['sellerAddress'] as Map<String, dynamic>,
  ),
  categoryId: (json['categoryId'] as num).toInt(),
  stockQuantity: (json['stockQuantity'] as num).toInt(),
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  dateCreated: DateTime.parse(json['dateCreated'] as String),
  isActive: json['isActive'] as bool? ?? true,
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  lengthCm: (json['lengthCm'] as num?)?.toDouble(),
  widthCm: (json['widthCm'] as num?)?.toDouble(),
  heightCm: (json['heightCm'] as num?)?.toDouble(),
  isLocalDeliveryOnly: json['isLocalDeliveryOnly'] as bool? ?? false,
  isPerishable: json['isPerishable'] as bool? ?? false,
  estimatedShipDays: (json['estimatedShipDays'] as num?)?.toInt() ?? 3,
  deliveryOptions:
      (json['deliveryOptions'] as List<dynamic>?)
          ?.map((e) => SellerDeliveryOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
  freeShipping: json['freeShipping'] as bool? ?? false,
  taxCode: json['taxCode'] as String?,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'imageUrls': instance.imageUrls,
      'sellerId': instance.sellerId,
      'sellerAddress': instance.sellerAddress,
      'categoryId': instance.categoryId,
      'stockQuantity': instance.stockQuantity,
      'rating': instance.rating,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'isActive': instance.isActive,
      'weightKg': instance.weightKg,
      'lengthCm': instance.lengthCm,
      'widthCm': instance.widthCm,
      'heightCm': instance.heightCm,
      'isLocalDeliveryOnly': instance.isLocalDeliveryOnly,
      'isPerishable': instance.isPerishable,
      'estimatedShipDays': instance.estimatedShipDays,
      'deliveryOptions': instance.deliveryOptions,
      'minimumOrderQuantity': instance.minimumOrderQuantity,
      'freeShipping': instance.freeShipping,
      'taxCode': instance.taxCode,
      'keywords': instance.keywords,
    };

_$ProductCreateImpl _$$ProductCreateImplFromJson(
  Map<String, dynamic> json,
) => _$ProductCreateImpl(
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sellerId: json['sellerId'] as String,
  sellerAddress: Address.fromJson(
    json['sellerAddress'] as Map<String, dynamic>,
  ),
  categoryId: (json['categoryId'] as num).toInt(),
  stockQuantity: (json['stockQuantity'] as num).toInt(),
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  isActive: json['isActive'] as bool? ?? true,
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  lengthCm: (json['lengthCm'] as num?)?.toDouble(),
  widthCm: (json['widthCm'] as num?)?.toDouble(),
  heightCm: (json['heightCm'] as num?)?.toDouble(),
  isLocalDeliveryOnly: json['isLocalDeliveryOnly'] as bool? ?? false,
  isPerishable: json['isPerishable'] as bool? ?? false,
  estimatedShipDays: (json['estimatedShipDays'] as num?)?.toInt() ?? 3,
  deliveryOptions:
      (json['deliveryOptions'] as List<dynamic>?)
          ?.map((e) => SellerDeliveryOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
  freeShipping: json['freeShipping'] as bool? ?? false,
  taxCode: json['taxCode'] as String?,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$ProductCreateImplToJson(_$ProductCreateImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price': instance.price,
      'description': instance.description,
      'imageUrls': instance.imageUrls,
      'sellerId': instance.sellerId,
      'sellerAddress': instance.sellerAddress,
      'categoryId': instance.categoryId,
      'stockQuantity': instance.stockQuantity,
      'rating': instance.rating,
      'isActive': instance.isActive,
      'weightKg': instance.weightKg,
      'lengthCm': instance.lengthCm,
      'widthCm': instance.widthCm,
      'heightCm': instance.heightCm,
      'isLocalDeliveryOnly': instance.isLocalDeliveryOnly,
      'isPerishable': instance.isPerishable,
      'estimatedShipDays': instance.estimatedShipDays,
      'deliveryOptions': instance.deliveryOptions,
      'minimumOrderQuantity': instance.minimumOrderQuantity,
      'freeShipping': instance.freeShipping,
      'taxCode': instance.taxCode,
      'keywords': instance.keywords,
    };

_$SellerDeliveryOptionImpl _$$SellerDeliveryOptionImplFromJson(
  Map<String, dynamic> json,
) => _$SellerDeliveryOptionImpl(
  type: json['type'] as String,
  description: json['description'] as String,
  cost: (json['cost'] as num).toDouble(),
  estimatedDays: (json['estimatedDays'] as num).toInt(),
);

Map<String, dynamic> _$$SellerDeliveryOptionImplToJson(
  _$SellerDeliveryOptionImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'cost': instance.cost,
  'estimatedDays': instance.estimatedDays,
};
