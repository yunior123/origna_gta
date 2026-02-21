// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InventoryConfig _$InventoryConfigFromJson(Map<String, dynamic> json) =>
    _InventoryConfig(
      managed: json['managed'] as bool? ?? true,
      trackQuantity: json['trackQuantity'] as bool? ?? true,
      allowBackorder: json['allowBackorder'] as bool? ?? false,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 5,
      lastLowStockAlertAt: json['lastLowStockAlertAt'] == null
          ? null
          : DateTime.parse(json['lastLowStockAlertAt'] as String),
      reservationHoldMinutes:
          (json['reservationHoldMinutes'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$InventoryConfigToJson(_InventoryConfig instance) =>
    <String, dynamic>{
      'managed': instance.managed,
      'trackQuantity': instance.trackQuantity,
      'allowBackorder': instance.allowBackorder,
      'lowStockThreshold': instance.lowStockThreshold,
      'lastLowStockAlertAt': instance.lastLowStockAlertAt?.toIso8601String(),
      'reservationHoldMinutes': instance.reservationHoldMinutes,
    };

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  productId: json['productId'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble() ?? null,
  description: json['description'] as String,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sellerId: json['sellerId'] as String,
  sellerAddress: json['sellerAddress'] == null
      ? null
      : Address.fromJson(json['sellerAddress'] as Map<String, dynamic>),
  categoryId: (json['categoryId'] as num).toInt(),
  stockQuantity: (json['stockQuantity'] as num).toInt(),
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
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
  isDigital: json['isDigital'] as bool? ?? false,
  digitalType: json['digitalType'] as String? ?? null,
  slug: json['slug'] as String? ?? null,
  digitalBuilds:
      (json['digitalBuilds'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      null,
  deviceLimit: (json['deviceLimit'] as num?)?.toInt() ?? null,
  taxCode: json['taxCode'] as String?,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  approvalStatus:
      json['approvalStatus'] as String? ??
      ProductApprovalStatusValues.underReview,
  approvalRejectionReason: json['approvalRejectionReason'] as String? ?? null,
  cost: (json['cost'] as num?)?.toDouble(),
  supplierSku: json['supplierSku'] as String?,
  supplierUrl: json['supplierUrl'] as String?,
  supplier: json['supplier'] == null
      ? null
      : SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
  inventory: json['inventory'] == null
      ? null
      : InventoryConfig.fromJson(json['inventory'] as Map<String, dynamic>),
  status: json['status'] as String? ?? ProductStatusValues.active,
  sellerSku: json['sellerSku'] as String?,
  warehouseIds:
      (json['warehouseIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      null,
  warehouseStock:
      (json['warehouseStock'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      null,
  shipFromCity: json['shipFromCity'] as String?,
  shipFromProvince: json['shipFromProvince'] as String?,
  shipFromCountry: json['shipFromCountry'] as String?,
  shipFromCountries:
      (json['shipFromCountries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      null,
  trendingScore: (json['trendingScore'] as num?)?.toInt() ?? 0,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
  isTrending: json['isTrending'] as bool? ?? false,
  trendingAt: json['trendingAt'] == null
      ? null
      : DateTime.parse(json['trendingAt'] as String),
  hasVariants: json['hasVariants'] as bool? ?? false,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  variantOptions:
      (json['variantOptions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  subcategory: json['subcategory'] as String? ?? null,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'productId': instance.productId,
  'name': instance.name,
  'price': instance.price,
  'compareAtPrice': instance.compareAtPrice,
  'description': instance.description,
  'imageUrls': instance.imageUrls,
  'sellerId': instance.sellerId,
  'sellerAddress': instance.sellerAddress,
  'categoryId': instance.categoryId,
  'stockQuantity': instance.stockQuantity,
  'rating': instance.rating,
  'ratingCount': instance.ratingCount,
  'createdAt': instance.createdAt.toIso8601String(),
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
  'isDigital': instance.isDigital,
  'digitalType': instance.digitalType,
  'slug': instance.slug,
  'digitalBuilds': instance.digitalBuilds,
  'deviceLimit': instance.deviceLimit,
  'taxCode': instance.taxCode,
  'keywords': instance.keywords,
  'approvalStatus': instance.approvalStatus,
  'approvalRejectionReason': instance.approvalRejectionReason,
  'cost': instance.cost,
  'supplierSku': instance.supplierSku,
  'supplierUrl': instance.supplierUrl,
  'supplier': instance.supplier,
  'inventory': instance.inventory,
  'status': instance.status,
  'sellerSku': instance.sellerSku,
  'warehouseIds': instance.warehouseIds,
  'warehouseStock': instance.warehouseStock,
  'shipFromCity': instance.shipFromCity,
  'shipFromProvince': instance.shipFromProvince,
  'shipFromCountry': instance.shipFromCountry,
  'shipFromCountries': instance.shipFromCountries,
  'trendingScore': instance.trendingScore,
  'viewCount': instance.viewCount,
  'purchaseCount': instance.purchaseCount,
  'isTrending': instance.isTrending,
  'trendingAt': instance.trendingAt?.toIso8601String(),
  'hasVariants': instance.hasVariants,
  'variants': instance.variants,
  'variantOptions': instance.variantOptions,
  'subcategory': instance.subcategory,
};

_ProductCreate _$ProductCreateFromJson(
  Map<String, dynamic> json,
) => _ProductCreate(
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble() ?? null,
  description: json['description'] as String,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sellerId: json['sellerId'] as String,
  sellerAddress: json['sellerAddress'] == null
      ? null
      : Address.fromJson(json['sellerAddress'] as Map<String, dynamic>),
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
  isDigital: json['isDigital'] as bool? ?? false,
  digitalType: json['digitalType'] as String? ?? null,
  slug: json['slug'] as String? ?? null,
  digitalBuilds:
      (json['digitalBuilds'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      null,
  deviceLimit: (json['deviceLimit'] as num?)?.toInt() ?? null,
  taxCode: json['taxCode'] as String?,
  keywords:
      (json['keywords'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  cost: (json['cost'] as num?)?.toDouble(),
  supplierSku: json['supplierSku'] as String?,
  supplierUrl: json['supplierUrl'] as String?,
  supplier: json['supplier'] == null
      ? null
      : SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
  inventory: json['inventory'] == null
      ? null
      : InventoryConfig.fromJson(json['inventory'] as Map<String, dynamic>),
  status: json['status'] as String? ?? ProductStatusValues.active,
  sellerSku: json['sellerSku'] as String?,
  warehouseIds:
      (json['warehouseIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      null,
  warehouseStock:
      (json['warehouseStock'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      null,
  shipFromCity: json['shipFromCity'] as String?,
  shipFromProvince: json['shipFromProvince'] as String?,
  shipFromCountry: json['shipFromCountry'] as String?,
  shipFromCountries:
      (json['shipFromCountries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      null,
  hasVariants: json['hasVariants'] as bool? ?? false,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  variantOptions:
      (json['variantOptions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  subcategory: json['subcategory'] as String? ?? null,
);

Map<String, dynamic> _$ProductCreateToJson(_ProductCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price': instance.price,
      'compareAtPrice': instance.compareAtPrice,
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
      'isDigital': instance.isDigital,
      'digitalType': instance.digitalType,
      'slug': instance.slug,
      'digitalBuilds': instance.digitalBuilds,
      'deviceLimit': instance.deviceLimit,
      'taxCode': instance.taxCode,
      'keywords': instance.keywords,
      'cost': instance.cost,
      'supplierSku': instance.supplierSku,
      'supplierUrl': instance.supplierUrl,
      'supplier': instance.supplier,
      'inventory': instance.inventory,
      'status': instance.status,
      'sellerSku': instance.sellerSku,
      'warehouseIds': instance.warehouseIds,
      'warehouseStock': instance.warehouseStock,
      'shipFromCity': instance.shipFromCity,
      'shipFromProvince': instance.shipFromProvince,
      'shipFromCountry': instance.shipFromCountry,
      'shipFromCountries': instance.shipFromCountries,
      'hasVariants': instance.hasVariants,
      'variants': instance.variants,
      'variantOptions': instance.variantOptions,
      'subcategory': instance.subcategory,
    };

_SellerDeliveryOption _$SellerDeliveryOptionFromJson(
  Map<String, dynamic> json,
) => _SellerDeliveryOption(
  type: json['type'] as String? ?? DeliveryTypeValues.standard,
  description: json['description'] as String? ?? '',
  cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
  estimatedDays: (json['estimatedDays'] as num?)?.toInt() ?? 3,
  quantityDiscounts:
      (json['quantityDiscounts'] as List<dynamic>?)
          ?.map(
            (e) => ShippingQuantityDiscount.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  maxItemsPerShipment: (json['maxItemsPerShipment'] as num?)?.toInt() ?? 0,
  additionalItemCost: (json['additionalItemCost'] as num?)?.toDouble() ?? 0.0,
  availableInternational: json['availableInternational'] as bool? ?? true,
);

Map<String, dynamic> _$SellerDeliveryOptionToJson(
  _SellerDeliveryOption instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'cost': instance.cost,
  'estimatedDays': instance.estimatedDays,
  'quantityDiscounts': instance.quantityDiscounts,
  'maxItemsPerShipment': instance.maxItemsPerShipment,
  'additionalItemCost': instance.additionalItemCost,
  'availableInternational': instance.availableInternational,
};

_SellerWarehouse _$SellerWarehouseFromJson(Map<String, dynamic> json) =>
    _SellerWarehouse(
      warehouseId: json['warehouseId'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'warehouse',
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SellerWarehouseToJson(_SellerWarehouse instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'label': instance.label,
      'type': instance.type,
      'address': instance.address,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_ShippingQuantityDiscount _$ShippingQuantityDiscountFromJson(
  Map<String, dynamic> json,
) => _ShippingQuantityDiscount(
  minQuantity: (json['minQuantity'] as num).toInt(),
  discountType: json['discountType'] as String? ?? DiscountTypeValues.percent,
  discountValue: (json['discountValue'] as num).toDouble(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$ShippingQuantityDiscountToJson(
  _ShippingQuantityDiscount instance,
) => <String, dynamic>{
  'minQuantity': instance.minQuantity,
  'discountType': instance.discountType,
  'discountValue': instance.discountValue,
  'label': instance.label,
};

_SupplierInfo _$SupplierInfoFromJson(Map<String, dynamic> json) =>
    _SupplierInfo(
      type: json['type'] as String,
      supplierSku: json['supplierSku'] as String?,
      supplierUrl: json['supplierUrl'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      shippingDays: json['shippingDays'] as String?,
      hasTracking: json['hasTracking'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SupplierInfoToJson(_SupplierInfo instance) =>
    <String, dynamic>{
      'type': instance.type,
      'supplierSku': instance.supplierSku,
      'supplierUrl': instance.supplierUrl,
      'cost': instance.cost,
      'currency': instance.currency,
      'shippingDays': instance.shippingDays,
      'hasTracking': instance.hasTracking,
      'notes': instance.notes,
    };

_ProductQuestion _$ProductQuestionFromJson(Map<String, dynamic> json) =>
    _ProductQuestion(
      questionId: json['questionId'] as String,
      productId: json['productId'] as String,
      sellerId: json['sellerId'] as String,
      askerId: json['askerId'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      answeredAt: json['answeredAt'] == null
          ? null
          : DateTime.parse(json['answeredAt'] as String),
      answeredBy: json['answeredBy'] as String?,
      isAnswered: json['isAnswered'] as bool? ?? false,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductQuestionToJson(_ProductQuestion instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'productId': instance.productId,
      'sellerId': instance.sellerId,
      'askerId': instance.askerId,
      'question': instance.question,
      'answer': instance.answer,
      'answeredAt': instance.answeredAt?.toIso8601String(),
      'answeredBy': instance.answeredBy,
      'isAnswered': instance.isAnswered,
      'upvotes': instance.upvotes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
