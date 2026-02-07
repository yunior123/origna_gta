// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InventoryConfig _$InventoryConfigFromJson(Map<String, dynamic> json) {
  return _InventoryConfig.fromJson(json);
}

/// @nodoc
mixin _$InventoryConfig {
  /// Whether inventory is actively managed (false for dropship products)
  bool get managed => throw _privateConstructorUsedError;

  /// Track stock quantity (false = unlimited)
  bool get trackQuantity => throw _privateConstructorUsedError;

  /// Allow orders when out of stock
  bool get allowBackorder => throw _privateConstructorUsedError;

  /// Alert threshold for low stock
  int get lowStockThreshold => throw _privateConstructorUsedError;

  /// How long to hold inventory during checkout (minutes)
  int get reservationHoldMinutes => throw _privateConstructorUsedError;

  /// Serializes this InventoryConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryConfigCopyWith<InventoryConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryConfigCopyWith<$Res> {
  factory $InventoryConfigCopyWith(
    InventoryConfig value,
    $Res Function(InventoryConfig) then,
  ) = _$InventoryConfigCopyWithImpl<$Res, InventoryConfig>;
  @useResult
  $Res call({
    bool managed,
    bool trackQuantity,
    bool allowBackorder,
    int lowStockThreshold,
    int reservationHoldMinutes,
  });
}

/// @nodoc
class _$InventoryConfigCopyWithImpl<$Res, $Val extends InventoryConfig>
    implements $InventoryConfigCopyWith<$Res> {
  _$InventoryConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? managed = null,
    Object? trackQuantity = null,
    Object? allowBackorder = null,
    Object? lowStockThreshold = null,
    Object? reservationHoldMinutes = null,
  }) {
    return _then(
      _value.copyWith(
            managed: null == managed
                ? _value.managed
                : managed // ignore: cast_nullable_to_non_nullable
                      as bool,
            trackQuantity: null == trackQuantity
                ? _value.trackQuantity
                : trackQuantity // ignore: cast_nullable_to_non_nullable
                      as bool,
            allowBackorder: null == allowBackorder
                ? _value.allowBackorder
                : allowBackorder // ignore: cast_nullable_to_non_nullable
                      as bool,
            lowStockThreshold: null == lowStockThreshold
                ? _value.lowStockThreshold
                : lowStockThreshold // ignore: cast_nullable_to_non_nullable
                      as int,
            reservationHoldMinutes: null == reservationHoldMinutes
                ? _value.reservationHoldMinutes
                : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InventoryConfigImplCopyWith<$Res>
    implements $InventoryConfigCopyWith<$Res> {
  factory _$$InventoryConfigImplCopyWith(
    _$InventoryConfigImpl value,
    $Res Function(_$InventoryConfigImpl) then,
  ) = __$$InventoryConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool managed,
    bool trackQuantity,
    bool allowBackorder,
    int lowStockThreshold,
    int reservationHoldMinutes,
  });
}

/// @nodoc
class __$$InventoryConfigImplCopyWithImpl<$Res>
    extends _$InventoryConfigCopyWithImpl<$Res, _$InventoryConfigImpl>
    implements _$$InventoryConfigImplCopyWith<$Res> {
  __$$InventoryConfigImplCopyWithImpl(
    _$InventoryConfigImpl _value,
    $Res Function(_$InventoryConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InventoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? managed = null,
    Object? trackQuantity = null,
    Object? allowBackorder = null,
    Object? lowStockThreshold = null,
    Object? reservationHoldMinutes = null,
  }) {
    return _then(
      _$InventoryConfigImpl(
        managed: null == managed
            ? _value.managed
            : managed // ignore: cast_nullable_to_non_nullable
                  as bool,
        trackQuantity: null == trackQuantity
            ? _value.trackQuantity
            : trackQuantity // ignore: cast_nullable_to_non_nullable
                  as bool,
        allowBackorder: null == allowBackorder
            ? _value.allowBackorder
            : allowBackorder // ignore: cast_nullable_to_non_nullable
                  as bool,
        lowStockThreshold: null == lowStockThreshold
            ? _value.lowStockThreshold
            : lowStockThreshold // ignore: cast_nullable_to_non_nullable
                  as int,
        reservationHoldMinutes: null == reservationHoldMinutes
            ? _value.reservationHoldMinutes
            : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryConfigImpl implements _InventoryConfig {
  const _$InventoryConfigImpl({
    this.managed = true,
    this.trackQuantity = true,
    this.allowBackorder = false,
    this.lowStockThreshold = 5,
    this.reservationHoldMinutes = 30,
  });

  factory _$InventoryConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryConfigImplFromJson(json);

  /// Whether inventory is actively managed (false for dropship products)
  @override
  @JsonKey()
  final bool managed;

  /// Track stock quantity (false = unlimited)
  @override
  @JsonKey()
  final bool trackQuantity;

  /// Allow orders when out of stock
  @override
  @JsonKey()
  final bool allowBackorder;

  /// Alert threshold for low stock
  @override
  @JsonKey()
  final int lowStockThreshold;

  /// How long to hold inventory during checkout (minutes)
  @override
  @JsonKey()
  final int reservationHoldMinutes;

  @override
  String toString() {
    return 'InventoryConfig(managed: $managed, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockThreshold: $lowStockThreshold, reservationHoldMinutes: $reservationHoldMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryConfigImpl &&
            (identical(other.managed, managed) || other.managed == managed) &&
            (identical(other.trackQuantity, trackQuantity) ||
                other.trackQuantity == trackQuantity) &&
            (identical(other.allowBackorder, allowBackorder) ||
                other.allowBackorder == allowBackorder) &&
            (identical(other.lowStockThreshold, lowStockThreshold) ||
                other.lowStockThreshold == lowStockThreshold) &&
            (identical(other.reservationHoldMinutes, reservationHoldMinutes) ||
                other.reservationHoldMinutes == reservationHoldMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    managed,
    trackQuantity,
    allowBackorder,
    lowStockThreshold,
    reservationHoldMinutes,
  );

  /// Create a copy of InventoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryConfigImplCopyWith<_$InventoryConfigImpl> get copyWith =>
      __$$InventoryConfigImplCopyWithImpl<_$InventoryConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryConfigImplToJson(this);
  }
}

abstract class _InventoryConfig implements InventoryConfig {
  const factory _InventoryConfig({
    final bool managed,
    final bool trackQuantity,
    final bool allowBackorder,
    final int lowStockThreshold,
    final int reservationHoldMinutes,
  }) = _$InventoryConfigImpl;

  factory _InventoryConfig.fromJson(Map<String, dynamic> json) =
      _$InventoryConfigImpl.fromJson;

  /// Whether inventory is actively managed (false for dropship products)
  @override
  bool get managed;

  /// Track stock quantity (false = unlimited)
  @override
  bool get trackQuantity;

  /// Allow orders when out of stock
  @override
  bool get allowBackorder;

  /// Alert threshold for low stock
  @override
  int get lowStockThreshold;

  /// How long to hold inventory during checkout (minutes)
  @override
  int get reservationHoldMinutes;

  /// Create a copy of InventoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryConfigImplCopyWith<_$InventoryConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get productId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  Address get sellerAddress => throw _privateConstructorUsedError;
  int get categoryId => throw _privateConstructorUsedError;
  int get stockQuantity => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  DateTime get dateCreated => throw _privateConstructorUsedError;
  bool get isActive =>
      throw _privateConstructorUsedError; // Optional shipping metadata
  double? get weightKg => throw _privateConstructorUsedError;
  double? get lengthCm => throw _privateConstructorUsedError;
  double? get widthCm => throw _privateConstructorUsedError;
  double? get heightCm =>
      throw _privateConstructorUsedError; // Delivery options
  bool get isLocalDeliveryOnly => throw _privateConstructorUsedError;
  bool get isPerishable => throw _privateConstructorUsedError;
  int get estimatedShipDays => throw _privateConstructorUsedError;
  List<SellerDeliveryOption> get deliveryOptions =>
      throw _privateConstructorUsedError;
  int get minimumOrderQuantity => throw _privateConstructorUsedError;
  bool get freeShipping =>
      throw _privateConstructorUsedError; // Digital product flag
  bool get isDigital => throw _privateConstructorUsedError; // Tax and metadata
  String? get taxCode => throw _privateConstructorUsedError;
  List<String> get keywords =>
      throw _privateConstructorUsedError; // DEPRECATED: Legacy flat fields - use supplier object instead
  double? get cost => throw _privateConstructorUsedError;
  String? get supplierSku => throw _privateConstructorUsedError;
  String? get supplierUrl =>
      throw _privateConstructorUsedError; // NEW: Structured objects for scalability
  /// Supplier information for dropshipping/marketplace products
  SupplierInfo? get supplier => throw _privateConstructorUsedError;

  /// Inventory management configuration
  InventoryConfig? get inventory => throw _privateConstructorUsedError;

  /// Product status: draft, active, paused, archived, out_of_stock
  String get status => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    String productId,
    String name,
    double price,
    String description,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    int categoryId,
    int stockQuantity,
    double rating,
    DateTime dateCreated,
    bool isActive,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
    String? taxCode,
    List<String> keywords,
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    String status,
  });

  $AddressCopyWith<$Res> get sellerAddress;
  $SupplierInfoCopyWith<$Res>? get supplier;
  $InventoryConfigCopyWith<$Res>? get inventory;
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? name = null,
    Object? price = null,
    Object? description = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? categoryId = null,
    Object? stockQuantity = null,
    Object? rating = null,
    Object? dateCreated = null,
    Object? isActive = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
    Object? taxCode = freezed,
    Object? keywords = null,
    Object? cost = freezed,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? supplier = freezed,
    Object? inventory = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrls: null == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sellerId: null == sellerId
                ? _value.sellerId
                : sellerId // ignore: cast_nullable_to_non_nullable
                      as String,
            sellerAddress: null == sellerAddress
                ? _value.sellerAddress
                : sellerAddress // ignore: cast_nullable_to_non_nullable
                      as Address,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int,
            stockQuantity: null == stockQuantity
                ? _value.stockQuantity
                : stockQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            dateCreated: null == dateCreated
                ? _value.dateCreated
                : dateCreated // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            lengthCm: freezed == lengthCm
                ? _value.lengthCm
                : lengthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            widthCm: freezed == widthCm
                ? _value.widthCm
                : widthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            heightCm: freezed == heightCm
                ? _value.heightCm
                : heightCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            isLocalDeliveryOnly: null == isLocalDeliveryOnly
                ? _value.isLocalDeliveryOnly
                : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPerishable: null == isPerishable
                ? _value.isPerishable
                : isPerishable // ignore: cast_nullable_to_non_nullable
                      as bool,
            estimatedShipDays: null == estimatedShipDays
                ? _value.estimatedShipDays
                : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                      as int,
            deliveryOptions: null == deliveryOptions
                ? _value.deliveryOptions
                : deliveryOptions // ignore: cast_nullable_to_non_nullable
                      as List<SellerDeliveryOption>,
            minimumOrderQuantity: null == minimumOrderQuantity
                ? _value.minimumOrderQuantity
                : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            freeShipping: null == freeShipping
                ? _value.freeShipping
                : freeShipping // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDigital: null == isDigital
                ? _value.isDigital
                : isDigital // ignore: cast_nullable_to_non_nullable
                      as bool,
            taxCode: freezed == taxCode
                ? _value.taxCode
                : taxCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            keywords: null == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            supplierSku: freezed == supplierSku
                ? _value.supplierSku
                : supplierSku // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplierUrl: freezed == supplierUrl
                ? _value.supplierUrl
                : supplierUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplier: freezed == supplier
                ? _value.supplier
                : supplier // ignore: cast_nullable_to_non_nullable
                      as SupplierInfo?,
            inventory: freezed == inventory
                ? _value.inventory
                : inventory // ignore: cast_nullable_to_non_nullable
                      as InventoryConfig?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get sellerAddress {
    return $AddressCopyWith<$Res>(_value.sellerAddress, (value) {
      return _then(_value.copyWith(sellerAddress: value) as $Val);
    });
  }

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SupplierInfoCopyWith<$Res>? get supplier {
    if (_value.supplier == null) {
      return null;
    }

    return $SupplierInfoCopyWith<$Res>(_value.supplier!, (value) {
      return _then(_value.copyWith(supplier: value) as $Val);
    });
  }

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InventoryConfigCopyWith<$Res>? get inventory {
    if (_value.inventory == null) {
      return null;
    }

    return $InventoryConfigCopyWith<$Res>(_value.inventory!, (value) {
      return _then(_value.copyWith(inventory: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productId,
    String name,
    double price,
    String description,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    int categoryId,
    int stockQuantity,
    double rating,
    DateTime dateCreated,
    bool isActive,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
    String? taxCode,
    List<String> keywords,
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    String status,
  });

  @override
  $AddressCopyWith<$Res> get sellerAddress;
  @override
  $SupplierInfoCopyWith<$Res>? get supplier;
  @override
  $InventoryConfigCopyWith<$Res>? get inventory;
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? name = null,
    Object? price = null,
    Object? description = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? categoryId = null,
    Object? stockQuantity = null,
    Object? rating = null,
    Object? dateCreated = null,
    Object? isActive = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
    Object? taxCode = freezed,
    Object? keywords = null,
    Object? cost = freezed,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? supplier = freezed,
    Object? inventory = freezed,
    Object? status = null,
  }) {
    return _then(
      _$ProductImpl(
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sellerId: null == sellerId
            ? _value.sellerId
            : sellerId // ignore: cast_nullable_to_non_nullable
                  as String,
        sellerAddress: null == sellerAddress
            ? _value.sellerAddress
            : sellerAddress // ignore: cast_nullable_to_non_nullable
                  as Address,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int,
        stockQuantity: null == stockQuantity
            ? _value.stockQuantity
            : stockQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        dateCreated: null == dateCreated
            ? _value.dateCreated
            : dateCreated // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        lengthCm: freezed == lengthCm
            ? _value.lengthCm
            : lengthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        widthCm: freezed == widthCm
            ? _value.widthCm
            : widthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        heightCm: freezed == heightCm
            ? _value.heightCm
            : heightCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        isLocalDeliveryOnly: null == isLocalDeliveryOnly
            ? _value.isLocalDeliveryOnly
            : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPerishable: null == isPerishable
            ? _value.isPerishable
            : isPerishable // ignore: cast_nullable_to_non_nullable
                  as bool,
        estimatedShipDays: null == estimatedShipDays
            ? _value.estimatedShipDays
            : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                  as int,
        deliveryOptions: null == deliveryOptions
            ? _value._deliveryOptions
            : deliveryOptions // ignore: cast_nullable_to_non_nullable
                  as List<SellerDeliveryOption>,
        minimumOrderQuantity: null == minimumOrderQuantity
            ? _value.minimumOrderQuantity
            : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        freeShipping: null == freeShipping
            ? _value.freeShipping
            : freeShipping // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDigital: null == isDigital
            ? _value.isDigital
            : isDigital // ignore: cast_nullable_to_non_nullable
                  as bool,
        taxCode: freezed == taxCode
            ? _value.taxCode
            : taxCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywords: null == keywords
            ? _value._keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        supplierSku: freezed == supplierSku
            ? _value.supplierSku
            : supplierSku // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplierUrl: freezed == supplierUrl
            ? _value.supplierUrl
            : supplierUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplier: freezed == supplier
            ? _value.supplier
            : supplier // ignore: cast_nullable_to_non_nullable
                  as SupplierInfo?,
        inventory: freezed == inventory
            ? _value.inventory
            : inventory // ignore: cast_nullable_to_non_nullable
                  as InventoryConfig?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl({
    required this.productId,
    required this.name,
    required this.price,
    required this.description,
    required final List<String> imageUrls,
    required this.sellerId,
    required this.sellerAddress,
    required this.categoryId,
    required this.stockQuantity,
    this.rating = 0.0,
    required this.dateCreated,
    this.isActive = true,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.estimatedShipDays = 3,
    final List<SellerDeliveryOption> deliveryOptions = const [],
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.isDigital = false,
    this.taxCode,
    final List<String> keywords = const [],
    this.cost,
    this.supplierSku,
    this.supplierUrl,
    this.supplier,
    this.inventory,
    this.status = 'active',
  }) : _imageUrls = imageUrls,
       _deliveryOptions = deliveryOptions,
       _keywords = keywords;

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String productId;
  @override
  final String name;
  @override
  final double price;
  @override
  final String description;
  final List<String> _imageUrls;
  @override
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  final String sellerId;
  @override
  final Address sellerAddress;
  @override
  final int categoryId;
  @override
  final int stockQuantity;
  @override
  @JsonKey()
  final double rating;
  @override
  final DateTime dateCreated;
  @override
  @JsonKey()
  final bool isActive;
  // Optional shipping metadata
  @override
  final double? weightKg;
  @override
  final double? lengthCm;
  @override
  final double? widthCm;
  @override
  final double? heightCm;
  // Delivery options
  @override
  @JsonKey()
  final bool isLocalDeliveryOnly;
  @override
  @JsonKey()
  final bool isPerishable;
  @override
  @JsonKey()
  final int estimatedShipDays;
  final List<SellerDeliveryOption> _deliveryOptions;
  @override
  @JsonKey()
  List<SellerDeliveryOption> get deliveryOptions {
    if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveryOptions);
  }

  @override
  @JsonKey()
  final int minimumOrderQuantity;
  @override
  @JsonKey()
  final bool freeShipping;
  // Digital product flag
  @override
  @JsonKey()
  final bool isDigital;
  // Tax and metadata
  @override
  final String? taxCode;
  final List<String> _keywords;
  @override
  @JsonKey()
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  // DEPRECATED: Legacy flat fields - use supplier object instead
  @override
  final double? cost;
  @override
  final String? supplierSku;
  @override
  final String? supplierUrl;
  // NEW: Structured objects for scalability
  /// Supplier information for dropshipping/marketplace products
  @override
  final SupplierInfo? supplier;

  /// Inventory management configuration
  @override
  final InventoryConfig? inventory;

  /// Product status: draft, active, paused, archived, out_of_stock
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'Product(productId: $productId, name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, dateCreated: $dateCreated, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.sellerAddress, sellerAddress) ||
                other.sellerAddress == sellerAddress) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.lengthCm, lengthCm) ||
                other.lengthCm == lengthCm) &&
            (identical(other.widthCm, widthCm) || other.widthCm == widthCm) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) ||
                other.isLocalDeliveryOnly == isLocalDeliveryOnly) &&
            (identical(other.isPerishable, isPerishable) ||
                other.isPerishable == isPerishable) &&
            (identical(other.estimatedShipDays, estimatedShipDays) ||
                other.estimatedShipDays == estimatedShipDays) &&
            const DeepCollectionEquality().equals(
              other._deliveryOptions,
              _deliveryOptions,
            ) &&
            (identical(other.minimumOrderQuantity, minimumOrderQuantity) ||
                other.minimumOrderQuantity == minimumOrderQuantity) &&
            (identical(other.freeShipping, freeShipping) ||
                other.freeShipping == freeShipping) &&
            (identical(other.isDigital, isDigital) ||
                other.isDigital == isDigital) &&
            (identical(other.taxCode, taxCode) || other.taxCode == taxCode) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.supplierSku, supplierSku) ||
                other.supplierSku == supplierSku) &&
            (identical(other.supplierUrl, supplierUrl) ||
                other.supplierUrl == supplierUrl) &&
            (identical(other.supplier, supplier) ||
                other.supplier == supplier) &&
            (identical(other.inventory, inventory) ||
                other.inventory == inventory) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    productId,
    name,
    price,
    description,
    const DeepCollectionEquality().hash(_imageUrls),
    sellerId,
    sellerAddress,
    categoryId,
    stockQuantity,
    rating,
    dateCreated,
    isActive,
    weightKg,
    lengthCm,
    widthCm,
    heightCm,
    isLocalDeliveryOnly,
    isPerishable,
    estimatedShipDays,
    const DeepCollectionEquality().hash(_deliveryOptions),
    minimumOrderQuantity,
    freeShipping,
    isDigital,
    taxCode,
    const DeepCollectionEquality().hash(_keywords),
    cost,
    supplierSku,
    supplierUrl,
    supplier,
    inventory,
    status,
  ]);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(this);
  }
}

abstract class _Product implements Product {
  const factory _Product({
    required final String productId,
    required final String name,
    required final double price,
    required final String description,
    required final List<String> imageUrls,
    required final String sellerId,
    required final Address sellerAddress,
    required final int categoryId,
    required final int stockQuantity,
    final double rating,
    required final DateTime dateCreated,
    final bool isActive,
    final double? weightKg,
    final double? lengthCm,
    final double? widthCm,
    final double? heightCm,
    final bool isLocalDeliveryOnly,
    final bool isPerishable,
    final int estimatedShipDays,
    final List<SellerDeliveryOption> deliveryOptions,
    final int minimumOrderQuantity,
    final bool freeShipping,
    final bool isDigital,
    final String? taxCode,
    final List<String> keywords,
    final double? cost,
    final String? supplierSku,
    final String? supplierUrl,
    final SupplierInfo? supplier,
    final InventoryConfig? inventory,
    final String status,
  }) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get productId;
  @override
  String get name;
  @override
  double get price;
  @override
  String get description;
  @override
  List<String> get imageUrls;
  @override
  String get sellerId;
  @override
  Address get sellerAddress;
  @override
  int get categoryId;
  @override
  int get stockQuantity;
  @override
  double get rating;
  @override
  DateTime get dateCreated;
  @override
  bool get isActive; // Optional shipping metadata
  @override
  double? get weightKg;
  @override
  double? get lengthCm;
  @override
  double? get widthCm;
  @override
  double? get heightCm; // Delivery options
  @override
  bool get isLocalDeliveryOnly;
  @override
  bool get isPerishable;
  @override
  int get estimatedShipDays;
  @override
  List<SellerDeliveryOption> get deliveryOptions;
  @override
  int get minimumOrderQuantity;
  @override
  bool get freeShipping; // Digital product flag
  @override
  bool get isDigital; // Tax and metadata
  @override
  String? get taxCode;
  @override
  List<String> get keywords; // DEPRECATED: Legacy flat fields - use supplier object instead
  @override
  double? get cost;
  @override
  String? get supplierSku;
  @override
  String? get supplierUrl; // NEW: Structured objects for scalability
  /// Supplier information for dropshipping/marketplace products
  @override
  SupplierInfo? get supplier;

  /// Inventory management configuration
  @override
  InventoryConfig? get inventory;

  /// Product status: draft, active, paused, archived, out_of_stock
  @override
  String get status;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProductCreate _$ProductCreateFromJson(Map<String, dynamic> json) {
  return _ProductCreate.fromJson(json);
}

/// @nodoc
mixin _$ProductCreate {
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get imageUrls => throw _privateConstructorUsedError;
  String get sellerId => throw _privateConstructorUsedError;
  Address get sellerAddress => throw _privateConstructorUsedError;
  int get categoryId => throw _privateConstructorUsedError;
  int get stockQuantity => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  double? get lengthCm => throw _privateConstructorUsedError;
  double? get widthCm => throw _privateConstructorUsedError;
  double? get heightCm => throw _privateConstructorUsedError;
  bool get isLocalDeliveryOnly => throw _privateConstructorUsedError;
  bool get isPerishable => throw _privateConstructorUsedError;
  int get estimatedShipDays => throw _privateConstructorUsedError;
  List<SellerDeliveryOption> get deliveryOptions =>
      throw _privateConstructorUsedError;
  int get minimumOrderQuantity => throw _privateConstructorUsedError;
  bool get freeShipping => throw _privateConstructorUsedError;
  bool get isDigital => throw _privateConstructorUsedError;
  String? get taxCode => throw _privateConstructorUsedError;
  List<String> get keywords =>
      throw _privateConstructorUsedError; // DEPRECATED: Legacy flat fields
  double? get cost => throw _privateConstructorUsedError;
  String? get supplierSku => throw _privateConstructorUsedError;
  String? get supplierUrl =>
      throw _privateConstructorUsedError; // NEW: Structured objects
  SupplierInfo? get supplier => throw _privateConstructorUsedError;
  InventoryConfig? get inventory => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this ProductCreate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCreateCopyWith<ProductCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCreateCopyWith<$Res> {
  factory $ProductCreateCopyWith(
    ProductCreate value,
    $Res Function(ProductCreate) then,
  ) = _$ProductCreateCopyWithImpl<$Res, ProductCreate>;
  @useResult
  $Res call({
    String name,
    double price,
    String description,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    int categoryId,
    int stockQuantity,
    double rating,
    bool isActive,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
    String? taxCode,
    List<String> keywords,
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    String status,
  });

  $AddressCopyWith<$Res> get sellerAddress;
  $SupplierInfoCopyWith<$Res>? get supplier;
  $InventoryConfigCopyWith<$Res>? get inventory;
}

/// @nodoc
class _$ProductCreateCopyWithImpl<$Res, $Val extends ProductCreate>
    implements $ProductCreateCopyWith<$Res> {
  _$ProductCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = null,
    Object? description = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? categoryId = null,
    Object? stockQuantity = null,
    Object? rating = null,
    Object? isActive = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
    Object? taxCode = freezed,
    Object? keywords = null,
    Object? cost = freezed,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? supplier = freezed,
    Object? inventory = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrls: null == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sellerId: null == sellerId
                ? _value.sellerId
                : sellerId // ignore: cast_nullable_to_non_nullable
                      as String,
            sellerAddress: null == sellerAddress
                ? _value.sellerAddress
                : sellerAddress // ignore: cast_nullable_to_non_nullable
                      as Address,
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int,
            stockQuantity: null == stockQuantity
                ? _value.stockQuantity
                : stockQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            lengthCm: freezed == lengthCm
                ? _value.lengthCm
                : lengthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            widthCm: freezed == widthCm
                ? _value.widthCm
                : widthCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            heightCm: freezed == heightCm
                ? _value.heightCm
                : heightCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            isLocalDeliveryOnly: null == isLocalDeliveryOnly
                ? _value.isLocalDeliveryOnly
                : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPerishable: null == isPerishable
                ? _value.isPerishable
                : isPerishable // ignore: cast_nullable_to_non_nullable
                      as bool,
            estimatedShipDays: null == estimatedShipDays
                ? _value.estimatedShipDays
                : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                      as int,
            deliveryOptions: null == deliveryOptions
                ? _value.deliveryOptions
                : deliveryOptions // ignore: cast_nullable_to_non_nullable
                      as List<SellerDeliveryOption>,
            minimumOrderQuantity: null == minimumOrderQuantity
                ? _value.minimumOrderQuantity
                : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            freeShipping: null == freeShipping
                ? _value.freeShipping
                : freeShipping // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDigital: null == isDigital
                ? _value.isDigital
                : isDigital // ignore: cast_nullable_to_non_nullable
                      as bool,
            taxCode: freezed == taxCode
                ? _value.taxCode
                : taxCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            keywords: null == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            supplierSku: freezed == supplierSku
                ? _value.supplierSku
                : supplierSku // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplierUrl: freezed == supplierUrl
                ? _value.supplierUrl
                : supplierUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplier: freezed == supplier
                ? _value.supplier
                : supplier // ignore: cast_nullable_to_non_nullable
                      as SupplierInfo?,
            inventory: freezed == inventory
                ? _value.inventory
                : inventory // ignore: cast_nullable_to_non_nullable
                      as InventoryConfig?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressCopyWith<$Res> get sellerAddress {
    return $AddressCopyWith<$Res>(_value.sellerAddress, (value) {
      return _then(_value.copyWith(sellerAddress: value) as $Val);
    });
  }

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SupplierInfoCopyWith<$Res>? get supplier {
    if (_value.supplier == null) {
      return null;
    }

    return $SupplierInfoCopyWith<$Res>(_value.supplier!, (value) {
      return _then(_value.copyWith(supplier: value) as $Val);
    });
  }

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InventoryConfigCopyWith<$Res>? get inventory {
    if (_value.inventory == null) {
      return null;
    }

    return $InventoryConfigCopyWith<$Res>(_value.inventory!, (value) {
      return _then(_value.copyWith(inventory: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProductCreateImplCopyWith<$Res>
    implements $ProductCreateCopyWith<$Res> {
  factory _$$ProductCreateImplCopyWith(
    _$ProductCreateImpl value,
    $Res Function(_$ProductCreateImpl) then,
  ) = __$$ProductCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    double price,
    String description,
    List<String> imageUrls,
    String sellerId,
    Address sellerAddress,
    int categoryId,
    int stockQuantity,
    double rating,
    bool isActive,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool isLocalDeliveryOnly,
    bool isPerishable,
    int estimatedShipDays,
    List<SellerDeliveryOption> deliveryOptions,
    int minimumOrderQuantity,
    bool freeShipping,
    bool isDigital,
    String? taxCode,
    List<String> keywords,
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    SupplierInfo? supplier,
    InventoryConfig? inventory,
    String status,
  });

  @override
  $AddressCopyWith<$Res> get sellerAddress;
  @override
  $SupplierInfoCopyWith<$Res>? get supplier;
  @override
  $InventoryConfigCopyWith<$Res>? get inventory;
}

/// @nodoc
class __$$ProductCreateImplCopyWithImpl<$Res>
    extends _$ProductCreateCopyWithImpl<$Res, _$ProductCreateImpl>
    implements _$$ProductCreateImplCopyWith<$Res> {
  __$$ProductCreateImplCopyWithImpl(
    _$ProductCreateImpl _value,
    $Res Function(_$ProductCreateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = null,
    Object? description = null,
    Object? imageUrls = null,
    Object? sellerId = null,
    Object? sellerAddress = null,
    Object? categoryId = null,
    Object? stockQuantity = null,
    Object? rating = null,
    Object? isActive = null,
    Object? weightKg = freezed,
    Object? lengthCm = freezed,
    Object? widthCm = freezed,
    Object? heightCm = freezed,
    Object? isLocalDeliveryOnly = null,
    Object? isPerishable = null,
    Object? estimatedShipDays = null,
    Object? deliveryOptions = null,
    Object? minimumOrderQuantity = null,
    Object? freeShipping = null,
    Object? isDigital = null,
    Object? taxCode = freezed,
    Object? keywords = null,
    Object? cost = freezed,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? supplier = freezed,
    Object? inventory = freezed,
    Object? status = null,
  }) {
    return _then(
      _$ProductCreateImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sellerId: null == sellerId
            ? _value.sellerId
            : sellerId // ignore: cast_nullable_to_non_nullable
                  as String,
        sellerAddress: null == sellerAddress
            ? _value.sellerAddress
            : sellerAddress // ignore: cast_nullable_to_non_nullable
                  as Address,
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int,
        stockQuantity: null == stockQuantity
            ? _value.stockQuantity
            : stockQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        lengthCm: freezed == lengthCm
            ? _value.lengthCm
            : lengthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        widthCm: freezed == widthCm
            ? _value.widthCm
            : widthCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        heightCm: freezed == heightCm
            ? _value.heightCm
            : heightCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        isLocalDeliveryOnly: null == isLocalDeliveryOnly
            ? _value.isLocalDeliveryOnly
            : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPerishable: null == isPerishable
            ? _value.isPerishable
            : isPerishable // ignore: cast_nullable_to_non_nullable
                  as bool,
        estimatedShipDays: null == estimatedShipDays
            ? _value.estimatedShipDays
            : estimatedShipDays // ignore: cast_nullable_to_non_nullable
                  as int,
        deliveryOptions: null == deliveryOptions
            ? _value._deliveryOptions
            : deliveryOptions // ignore: cast_nullable_to_non_nullable
                  as List<SellerDeliveryOption>,
        minimumOrderQuantity: null == minimumOrderQuantity
            ? _value.minimumOrderQuantity
            : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        freeShipping: null == freeShipping
            ? _value.freeShipping
            : freeShipping // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDigital: null == isDigital
            ? _value.isDigital
            : isDigital // ignore: cast_nullable_to_non_nullable
                  as bool,
        taxCode: freezed == taxCode
            ? _value.taxCode
            : taxCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywords: null == keywords
            ? _value._keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        supplierSku: freezed == supplierSku
            ? _value.supplierSku
            : supplierSku // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplierUrl: freezed == supplierUrl
            ? _value.supplierUrl
            : supplierUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplier: freezed == supplier
            ? _value.supplier
            : supplier // ignore: cast_nullable_to_non_nullable
                  as SupplierInfo?,
        inventory: freezed == inventory
            ? _value.inventory
            : inventory // ignore: cast_nullable_to_non_nullable
                  as InventoryConfig?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductCreateImpl implements _ProductCreate {
  const _$ProductCreateImpl({
    required this.name,
    required this.price,
    required this.description,
    required final List<String> imageUrls,
    required this.sellerId,
    required this.sellerAddress,
    required this.categoryId,
    required this.stockQuantity,
    this.rating = 0.0,
    this.isActive = true,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.estimatedShipDays = 3,
    final List<SellerDeliveryOption> deliveryOptions = const [],
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.isDigital = false,
    this.taxCode,
    final List<String> keywords = const [],
    this.cost,
    this.supplierSku,
    this.supplierUrl,
    this.supplier,
    this.inventory,
    this.status = 'active',
  }) : _imageUrls = imageUrls,
       _deliveryOptions = deliveryOptions,
       _keywords = keywords;

  factory _$ProductCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductCreateImplFromJson(json);

  @override
  final String name;
  @override
  final double price;
  @override
  final String description;
  final List<String> _imageUrls;
  @override
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  @override
  final String sellerId;
  @override
  final Address sellerAddress;
  @override
  final int categoryId;
  @override
  final int stockQuantity;
  @override
  @JsonKey()
  final double rating;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final double? weightKg;
  @override
  final double? lengthCm;
  @override
  final double? widthCm;
  @override
  final double? heightCm;
  @override
  @JsonKey()
  final bool isLocalDeliveryOnly;
  @override
  @JsonKey()
  final bool isPerishable;
  @override
  @JsonKey()
  final int estimatedShipDays;
  final List<SellerDeliveryOption> _deliveryOptions;
  @override
  @JsonKey()
  List<SellerDeliveryOption> get deliveryOptions {
    if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveryOptions);
  }

  @override
  @JsonKey()
  final int minimumOrderQuantity;
  @override
  @JsonKey()
  final bool freeShipping;
  @override
  @JsonKey()
  final bool isDigital;
  @override
  final String? taxCode;
  final List<String> _keywords;
  @override
  @JsonKey()
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  // DEPRECATED: Legacy flat fields
  @override
  final double? cost;
  @override
  final String? supplierSku;
  @override
  final String? supplierUrl;
  // NEW: Structured objects
  @override
  final SupplierInfo? supplier;
  @override
  final InventoryConfig? inventory;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'ProductCreate(name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductCreateImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.sellerId, sellerId) ||
                other.sellerId == sellerId) &&
            (identical(other.sellerAddress, sellerAddress) ||
                other.sellerAddress == sellerAddress) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.lengthCm, lengthCm) ||
                other.lengthCm == lengthCm) &&
            (identical(other.widthCm, widthCm) || other.widthCm == widthCm) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) ||
                other.isLocalDeliveryOnly == isLocalDeliveryOnly) &&
            (identical(other.isPerishable, isPerishable) ||
                other.isPerishable == isPerishable) &&
            (identical(other.estimatedShipDays, estimatedShipDays) ||
                other.estimatedShipDays == estimatedShipDays) &&
            const DeepCollectionEquality().equals(
              other._deliveryOptions,
              _deliveryOptions,
            ) &&
            (identical(other.minimumOrderQuantity, minimumOrderQuantity) ||
                other.minimumOrderQuantity == minimumOrderQuantity) &&
            (identical(other.freeShipping, freeShipping) ||
                other.freeShipping == freeShipping) &&
            (identical(other.isDigital, isDigital) ||
                other.isDigital == isDigital) &&
            (identical(other.taxCode, taxCode) || other.taxCode == taxCode) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.supplierSku, supplierSku) ||
                other.supplierSku == supplierSku) &&
            (identical(other.supplierUrl, supplierUrl) ||
                other.supplierUrl == supplierUrl) &&
            (identical(other.supplier, supplier) ||
                other.supplier == supplier) &&
            (identical(other.inventory, inventory) ||
                other.inventory == inventory) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    name,
    price,
    description,
    const DeepCollectionEquality().hash(_imageUrls),
    sellerId,
    sellerAddress,
    categoryId,
    stockQuantity,
    rating,
    isActive,
    weightKg,
    lengthCm,
    widthCm,
    heightCm,
    isLocalDeliveryOnly,
    isPerishable,
    estimatedShipDays,
    const DeepCollectionEquality().hash(_deliveryOptions),
    minimumOrderQuantity,
    freeShipping,
    isDigital,
    taxCode,
    const DeepCollectionEquality().hash(_keywords),
    cost,
    supplierSku,
    supplierUrl,
    supplier,
    inventory,
    status,
  ]);

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductCreateImplCopyWith<_$ProductCreateImpl> get copyWith =>
      __$$ProductCreateImplCopyWithImpl<_$ProductCreateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductCreateImplToJson(this);
  }
}

abstract class _ProductCreate implements ProductCreate {
  const factory _ProductCreate({
    required final String name,
    required final double price,
    required final String description,
    required final List<String> imageUrls,
    required final String sellerId,
    required final Address sellerAddress,
    required final int categoryId,
    required final int stockQuantity,
    final double rating,
    final bool isActive,
    final double? weightKg,
    final double? lengthCm,
    final double? widthCm,
    final double? heightCm,
    final bool isLocalDeliveryOnly,
    final bool isPerishable,
    final int estimatedShipDays,
    final List<SellerDeliveryOption> deliveryOptions,
    final int minimumOrderQuantity,
    final bool freeShipping,
    final bool isDigital,
    final String? taxCode,
    final List<String> keywords,
    final double? cost,
    final String? supplierSku,
    final String? supplierUrl,
    final SupplierInfo? supplier,
    final InventoryConfig? inventory,
    final String status,
  }) = _$ProductCreateImpl;

  factory _ProductCreate.fromJson(Map<String, dynamic> json) =
      _$ProductCreateImpl.fromJson;

  @override
  String get name;
  @override
  double get price;
  @override
  String get description;
  @override
  List<String> get imageUrls;
  @override
  String get sellerId;
  @override
  Address get sellerAddress;
  @override
  int get categoryId;
  @override
  int get stockQuantity;
  @override
  double get rating;
  @override
  bool get isActive;
  @override
  double? get weightKg;
  @override
  double? get lengthCm;
  @override
  double? get widthCm;
  @override
  double? get heightCm;
  @override
  bool get isLocalDeliveryOnly;
  @override
  bool get isPerishable;
  @override
  int get estimatedShipDays;
  @override
  List<SellerDeliveryOption> get deliveryOptions;
  @override
  int get minimumOrderQuantity;
  @override
  bool get freeShipping;
  @override
  bool get isDigital;
  @override
  String? get taxCode;
  @override
  List<String> get keywords; // DEPRECATED: Legacy flat fields
  @override
  double? get cost;
  @override
  String? get supplierSku;
  @override
  String? get supplierUrl; // NEW: Structured objects
  @override
  SupplierInfo? get supplier;
  @override
  InventoryConfig? get inventory;
  @override
  String get status;

  /// Create a copy of ProductCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductCreateImplCopyWith<_$ProductCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SellerDeliveryOption _$SellerDeliveryOptionFromJson(Map<String, dynamic> json) {
  return _SellerDeliveryOption.fromJson(json);
}

/// @nodoc
mixin _$SellerDeliveryOption {
  String get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get cost => throw _privateConstructorUsedError;
  int get estimatedDays => throw _privateConstructorUsedError;

  /// Optional quantity-based discounts for this delivery option
  List<ShippingQuantityDiscount> get quantityDiscounts =>
      throw _privateConstructorUsedError;

  /// Maximum items before shipping cost increases (0 = no limit)
  int get maxItemsPerShipment => throw _privateConstructorUsedError;

  /// Additional cost per item after maxItemsPerShipment (0 = free per-item)
  double get additionalItemCost => throw _privateConstructorUsedError;

  /// Whether this option is available for international orders
  bool get availableInternational => throw _privateConstructorUsedError;

  /// Serializes this SellerDeliveryOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SellerDeliveryOptionCopyWith<SellerDeliveryOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SellerDeliveryOptionCopyWith<$Res> {
  factory $SellerDeliveryOptionCopyWith(
    SellerDeliveryOption value,
    $Res Function(SellerDeliveryOption) then,
  ) = _$SellerDeliveryOptionCopyWithImpl<$Res, SellerDeliveryOption>;
  @useResult
  $Res call({
    String type,
    String description,
    double cost,
    int estimatedDays,
    List<ShippingQuantityDiscount> quantityDiscounts,
    int maxItemsPerShipment,
    double additionalItemCost,
    bool availableInternational,
  });
}

/// @nodoc
class _$SellerDeliveryOptionCopyWithImpl<
  $Res,
  $Val extends SellerDeliveryOption
>
    implements $SellerDeliveryOptionCopyWith<$Res> {
  _$SellerDeliveryOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? description = null,
    Object? cost = null,
    Object? estimatedDays = null,
    Object? quantityDiscounts = null,
    Object? maxItemsPerShipment = null,
    Object? additionalItemCost = null,
    Object? availableInternational = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            cost: null == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double,
            estimatedDays: null == estimatedDays
                ? _value.estimatedDays
                : estimatedDays // ignore: cast_nullable_to_non_nullable
                      as int,
            quantityDiscounts: null == quantityDiscounts
                ? _value.quantityDiscounts
                : quantityDiscounts // ignore: cast_nullable_to_non_nullable
                      as List<ShippingQuantityDiscount>,
            maxItemsPerShipment: null == maxItemsPerShipment
                ? _value.maxItemsPerShipment
                : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
                      as int,
            additionalItemCost: null == additionalItemCost
                ? _value.additionalItemCost
                : additionalItemCost // ignore: cast_nullable_to_non_nullable
                      as double,
            availableInternational: null == availableInternational
                ? _value.availableInternational
                : availableInternational // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SellerDeliveryOptionImplCopyWith<$Res>
    implements $SellerDeliveryOptionCopyWith<$Res> {
  factory _$$SellerDeliveryOptionImplCopyWith(
    _$SellerDeliveryOptionImpl value,
    $Res Function(_$SellerDeliveryOptionImpl) then,
  ) = __$$SellerDeliveryOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    String description,
    double cost,
    int estimatedDays,
    List<ShippingQuantityDiscount> quantityDiscounts,
    int maxItemsPerShipment,
    double additionalItemCost,
    bool availableInternational,
  });
}

/// @nodoc
class __$$SellerDeliveryOptionImplCopyWithImpl<$Res>
    extends _$SellerDeliveryOptionCopyWithImpl<$Res, _$SellerDeliveryOptionImpl>
    implements _$$SellerDeliveryOptionImplCopyWith<$Res> {
  __$$SellerDeliveryOptionImplCopyWithImpl(
    _$SellerDeliveryOptionImpl _value,
    $Res Function(_$SellerDeliveryOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? description = null,
    Object? cost = null,
    Object? estimatedDays = null,
    Object? quantityDiscounts = null,
    Object? maxItemsPerShipment = null,
    Object? additionalItemCost = null,
    Object? availableInternational = null,
  }) {
    return _then(
      _$SellerDeliveryOptionImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        cost: null == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double,
        estimatedDays: null == estimatedDays
            ? _value.estimatedDays
            : estimatedDays // ignore: cast_nullable_to_non_nullable
                  as int,
        quantityDiscounts: null == quantityDiscounts
            ? _value._quantityDiscounts
            : quantityDiscounts // ignore: cast_nullable_to_non_nullable
                  as List<ShippingQuantityDiscount>,
        maxItemsPerShipment: null == maxItemsPerShipment
            ? _value.maxItemsPerShipment
            : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
                  as int,
        additionalItemCost: null == additionalItemCost
            ? _value.additionalItemCost
            : additionalItemCost // ignore: cast_nullable_to_non_nullable
                  as double,
        availableInternational: null == availableInternational
            ? _value.availableInternational
            : availableInternational // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SellerDeliveryOptionImpl implements _SellerDeliveryOption {
  const _$SellerDeliveryOptionImpl({
    required this.type,
    required this.description,
    required this.cost,
    required this.estimatedDays,
    final List<ShippingQuantityDiscount> quantityDiscounts = const [],
    this.maxItemsPerShipment = 0,
    this.additionalItemCost = 0.0,
    this.availableInternational = true,
  }) : _quantityDiscounts = quantityDiscounts;

  factory _$SellerDeliveryOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SellerDeliveryOptionImplFromJson(json);

  @override
  final String type;
  @override
  final String description;
  @override
  final double cost;
  @override
  final int estimatedDays;

  /// Optional quantity-based discounts for this delivery option
  final List<ShippingQuantityDiscount> _quantityDiscounts;

  /// Optional quantity-based discounts for this delivery option
  @override
  @JsonKey()
  List<ShippingQuantityDiscount> get quantityDiscounts {
    if (_quantityDiscounts is EqualUnmodifiableListView)
      return _quantityDiscounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quantityDiscounts);
  }

  /// Maximum items before shipping cost increases (0 = no limit)
  @override
  @JsonKey()
  final int maxItemsPerShipment;

  /// Additional cost per item after maxItemsPerShipment (0 = free per-item)
  @override
  @JsonKey()
  final double additionalItemCost;

  /// Whether this option is available for international orders
  @override
  @JsonKey()
  final bool availableInternational;

  @override
  String toString() {
    return 'SellerDeliveryOption(type: $type, description: $description, cost: $cost, estimatedDays: $estimatedDays, quantityDiscounts: $quantityDiscounts, maxItemsPerShipment: $maxItemsPerShipment, additionalItemCost: $additionalItemCost, availableInternational: $availableInternational)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SellerDeliveryOptionImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.estimatedDays, estimatedDays) ||
                other.estimatedDays == estimatedDays) &&
            const DeepCollectionEquality().equals(
              other._quantityDiscounts,
              _quantityDiscounts,
            ) &&
            (identical(other.maxItemsPerShipment, maxItemsPerShipment) ||
                other.maxItemsPerShipment == maxItemsPerShipment) &&
            (identical(other.additionalItemCost, additionalItemCost) ||
                other.additionalItemCost == additionalItemCost) &&
            (identical(other.availableInternational, availableInternational) ||
                other.availableInternational == availableInternational));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    description,
    cost,
    estimatedDays,
    const DeepCollectionEquality().hash(_quantityDiscounts),
    maxItemsPerShipment,
    additionalItemCost,
    availableInternational,
  );

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SellerDeliveryOptionImplCopyWith<_$SellerDeliveryOptionImpl>
  get copyWith =>
      __$$SellerDeliveryOptionImplCopyWithImpl<_$SellerDeliveryOptionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SellerDeliveryOptionImplToJson(this);
  }
}

abstract class _SellerDeliveryOption implements SellerDeliveryOption {
  const factory _SellerDeliveryOption({
    required final String type,
    required final String description,
    required final double cost,
    required final int estimatedDays,
    final List<ShippingQuantityDiscount> quantityDiscounts,
    final int maxItemsPerShipment,
    final double additionalItemCost,
    final bool availableInternational,
  }) = _$SellerDeliveryOptionImpl;

  factory _SellerDeliveryOption.fromJson(Map<String, dynamic> json) =
      _$SellerDeliveryOptionImpl.fromJson;

  @override
  String get type;
  @override
  String get description;
  @override
  double get cost;
  @override
  int get estimatedDays;

  /// Optional quantity-based discounts for this delivery option
  @override
  List<ShippingQuantityDiscount> get quantityDiscounts;

  /// Maximum items before shipping cost increases (0 = no limit)
  @override
  int get maxItemsPerShipment;

  /// Additional cost per item after maxItemsPerShipment (0 = free per-item)
  @override
  double get additionalItemCost;

  /// Whether this option is available for international orders
  @override
  bool get availableInternational;

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SellerDeliveryOptionImplCopyWith<_$SellerDeliveryOptionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ShippingQuantityDiscount _$ShippingQuantityDiscountFromJson(
  Map<String, dynamic> json,
) {
  return _ShippingQuantityDiscount.fromJson(json);
}

/// @nodoc
mixin _$ShippingQuantityDiscount {
  /// Minimum quantity to qualify for this discount
  int get minQuantity => throw _privateConstructorUsedError;

  /// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
  String get discountType => throw _privateConstructorUsedError;

  /// Discount value (interpretation depends on discountType)
  double get discountValue => throw _privateConstructorUsedError;

  /// Optional label for display (e.g., "Bulk Shipping Discount")
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this ShippingQuantityDiscount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShippingQuantityDiscount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShippingQuantityDiscountCopyWith<ShippingQuantityDiscount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShippingQuantityDiscountCopyWith<$Res> {
  factory $ShippingQuantityDiscountCopyWith(
    ShippingQuantityDiscount value,
    $Res Function(ShippingQuantityDiscount) then,
  ) = _$ShippingQuantityDiscountCopyWithImpl<$Res, ShippingQuantityDiscount>;
  @useResult
  $Res call({
    int minQuantity,
    String discountType,
    double discountValue,
    String? label,
  });
}

/// @nodoc
class _$ShippingQuantityDiscountCopyWithImpl<
  $Res,
  $Val extends ShippingQuantityDiscount
>
    implements $ShippingQuantityDiscountCopyWith<$Res> {
  _$ShippingQuantityDiscountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShippingQuantityDiscount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minQuantity = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? label = freezed,
  }) {
    return _then(
      _value.copyWith(
            minQuantity: null == minQuantity
                ? _value.minQuantity
                : minQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            discountType: null == discountType
                ? _value.discountType
                : discountType // ignore: cast_nullable_to_non_nullable
                      as String,
            discountValue: null == discountValue
                ? _value.discountValue
                : discountValue // ignore: cast_nullable_to_non_nullable
                      as double,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShippingQuantityDiscountImplCopyWith<$Res>
    implements $ShippingQuantityDiscountCopyWith<$Res> {
  factory _$$ShippingQuantityDiscountImplCopyWith(
    _$ShippingQuantityDiscountImpl value,
    $Res Function(_$ShippingQuantityDiscountImpl) then,
  ) = __$$ShippingQuantityDiscountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int minQuantity,
    String discountType,
    double discountValue,
    String? label,
  });
}

/// @nodoc
class __$$ShippingQuantityDiscountImplCopyWithImpl<$Res>
    extends
        _$ShippingQuantityDiscountCopyWithImpl<
          $Res,
          _$ShippingQuantityDiscountImpl
        >
    implements _$$ShippingQuantityDiscountImplCopyWith<$Res> {
  __$$ShippingQuantityDiscountImplCopyWithImpl(
    _$ShippingQuantityDiscountImpl _value,
    $Res Function(_$ShippingQuantityDiscountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShippingQuantityDiscount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minQuantity = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? label = freezed,
  }) {
    return _then(
      _$ShippingQuantityDiscountImpl(
        minQuantity: null == minQuantity
            ? _value.minQuantity
            : minQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        discountType: null == discountType
            ? _value.discountType
            : discountType // ignore: cast_nullable_to_non_nullable
                  as String,
        discountValue: null == discountValue
            ? _value.discountValue
            : discountValue // ignore: cast_nullable_to_non_nullable
                  as double,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShippingQuantityDiscountImpl implements _ShippingQuantityDiscount {
  const _$ShippingQuantityDiscountImpl({
    required this.minQuantity,
    this.discountType = 'percent',
    required this.discountValue,
    this.label,
  });

  factory _$ShippingQuantityDiscountImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShippingQuantityDiscountImplFromJson(json);

  /// Minimum quantity to qualify for this discount
  @override
  final int minQuantity;

  /// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
  @override
  @JsonKey()
  final String discountType;

  /// Discount value (interpretation depends on discountType)
  @override
  final double discountValue;

  /// Optional label for display (e.g., "Bulk Shipping Discount")
  @override
  final String? label;

  @override
  String toString() {
    return 'ShippingQuantityDiscount(minQuantity: $minQuantity, discountType: $discountType, discountValue: $discountValue, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShippingQuantityDiscountImpl &&
            (identical(other.minQuantity, minQuantity) ||
                other.minQuantity == minQuantity) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, minQuantity, discountType, discountValue, label);

  /// Create a copy of ShippingQuantityDiscount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShippingQuantityDiscountImplCopyWith<_$ShippingQuantityDiscountImpl>
  get copyWith =>
      __$$ShippingQuantityDiscountImplCopyWithImpl<
        _$ShippingQuantityDiscountImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShippingQuantityDiscountImplToJson(this);
  }
}

abstract class _ShippingQuantityDiscount implements ShippingQuantityDiscount {
  const factory _ShippingQuantityDiscount({
    required final int minQuantity,
    final String discountType,
    required final double discountValue,
    final String? label,
  }) = _$ShippingQuantityDiscountImpl;

  factory _ShippingQuantityDiscount.fromJson(Map<String, dynamic> json) =
      _$ShippingQuantityDiscountImpl.fromJson;

  /// Minimum quantity to qualify for this discount
  @override
  int get minQuantity;

  /// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
  @override
  String get discountType;

  /// Discount value (interpretation depends on discountType)
  @override
  double get discountValue;

  /// Optional label for display (e.g., "Bulk Shipping Discount")
  @override
  String? get label;

  /// Create a copy of ShippingQuantityDiscount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShippingQuantityDiscountImplCopyWith<_$ShippingQuantityDiscountImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SupplierInfo _$SupplierInfoFromJson(Map<String, dynamic> json) {
  return _SupplierInfo.fromJson(json);
}

/// @nodoc
mixin _$SupplierInfo {
  /// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
  String get type => throw _privateConstructorUsedError;

  /// Supplier's SKU/Product ID
  String? get supplierSku => throw _privateConstructorUsedError;

  /// Direct URL to supplier product page
  String? get supplierUrl => throw _privateConstructorUsedError;

  /// Cost price from supplier
  double? get cost => throw _privateConstructorUsedError;

  /// Currency of supplier cost price (supplier's currency, NOT selling currency).
  /// Selling price is always CAD. This tracks the supplier's original currency.
  String get currency => throw _privateConstructorUsedError;

  /// Estimated shipping days range (e.g., '7-15')
  String? get shippingDays => throw _privateConstructorUsedError;

  /// Whether supplier provides tracking
  bool get hasTracking => throw _privateConstructorUsedError;

  /// Internal notes about this supplier/product
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this SupplierInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SupplierInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SupplierInfoCopyWith<SupplierInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupplierInfoCopyWith<$Res> {
  factory $SupplierInfoCopyWith(
    SupplierInfo value,
    $Res Function(SupplierInfo) then,
  ) = _$SupplierInfoCopyWithImpl<$Res, SupplierInfo>;
  @useResult
  $Res call({
    String type,
    String? supplierSku,
    String? supplierUrl,
    double? cost,
    String currency,
    String? shippingDays,
    bool hasTracking,
    String? notes,
  });
}

/// @nodoc
class _$SupplierInfoCopyWithImpl<$Res, $Val extends SupplierInfo>
    implements $SupplierInfoCopyWith<$Res> {
  _$SupplierInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SupplierInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? shippingDays = freezed,
    Object? hasTracking = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            supplierSku: freezed == supplierSku
                ? _value.supplierSku
                : supplierSku // ignore: cast_nullable_to_non_nullable
                      as String?,
            supplierUrl: freezed == supplierUrl
                ? _value.supplierUrl
                : supplierUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            shippingDays: freezed == shippingDays
                ? _value.shippingDays
                : shippingDays // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasTracking: null == hasTracking
                ? _value.hasTracking
                : hasTracking // ignore: cast_nullable_to_non_nullable
                      as bool,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SupplierInfoImplCopyWith<$Res>
    implements $SupplierInfoCopyWith<$Res> {
  factory _$$SupplierInfoImplCopyWith(
    _$SupplierInfoImpl value,
    $Res Function(_$SupplierInfoImpl) then,
  ) = __$$SupplierInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    String? supplierSku,
    String? supplierUrl,
    double? cost,
    String currency,
    String? shippingDays,
    bool hasTracking,
    String? notes,
  });
}

/// @nodoc
class __$$SupplierInfoImplCopyWithImpl<$Res>
    extends _$SupplierInfoCopyWithImpl<$Res, _$SupplierInfoImpl>
    implements _$$SupplierInfoImplCopyWith<$Res> {
  __$$SupplierInfoImplCopyWithImpl(
    _$SupplierInfoImpl _value,
    $Res Function(_$SupplierInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SupplierInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? supplierSku = freezed,
    Object? supplierUrl = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? shippingDays = freezed,
    Object? hasTracking = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$SupplierInfoImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        supplierSku: freezed == supplierSku
            ? _value.supplierSku
            : supplierSku // ignore: cast_nullable_to_non_nullable
                  as String?,
        supplierUrl: freezed == supplierUrl
            ? _value.supplierUrl
            : supplierUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        shippingDays: freezed == shippingDays
            ? _value.shippingDays
            : shippingDays // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasTracking: null == hasTracking
            ? _value.hasTracking
            : hasTracking // ignore: cast_nullable_to_non_nullable
                  as bool,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SupplierInfoImpl implements _SupplierInfo {
  const _$SupplierInfoImpl({
    required this.type,
    this.supplierSku,
    this.supplierUrl,
    this.cost,
    this.currency = 'USD',
    this.shippingDays,
    this.hasTracking = false,
    this.notes,
  });

  factory _$SupplierInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupplierInfoImplFromJson(json);

  /// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
  @override
  final String type;

  /// Supplier's SKU/Product ID
  @override
  final String? supplierSku;

  /// Direct URL to supplier product page
  @override
  final String? supplierUrl;

  /// Cost price from supplier
  @override
  final double? cost;

  /// Currency of supplier cost price (supplier's currency, NOT selling currency).
  /// Selling price is always CAD. This tracks the supplier's original currency.
  @override
  @JsonKey()
  final String currency;

  /// Estimated shipping days range (e.g., '7-15')
  @override
  final String? shippingDays;

  /// Whether supplier provides tracking
  @override
  @JsonKey()
  final bool hasTracking;

  /// Internal notes about this supplier/product
  @override
  final String? notes;

  @override
  String toString() {
    return 'SupplierInfo(type: $type, supplierSku: $supplierSku, supplierUrl: $supplierUrl, cost: $cost, currency: $currency, shippingDays: $shippingDays, hasTracking: $hasTracking, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupplierInfoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.supplierSku, supplierSku) ||
                other.supplierSku == supplierSku) &&
            (identical(other.supplierUrl, supplierUrl) ||
                other.supplierUrl == supplierUrl) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.shippingDays, shippingDays) ||
                other.shippingDays == shippingDays) &&
            (identical(other.hasTracking, hasTracking) ||
                other.hasTracking == hasTracking) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    supplierSku,
    supplierUrl,
    cost,
    currency,
    shippingDays,
    hasTracking,
    notes,
  );

  /// Create a copy of SupplierInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SupplierInfoImplCopyWith<_$SupplierInfoImpl> get copyWith =>
      __$$SupplierInfoImplCopyWithImpl<_$SupplierInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SupplierInfoImplToJson(this);
  }
}

abstract class _SupplierInfo implements SupplierInfo {
  const factory _SupplierInfo({
    required final String type,
    final String? supplierSku,
    final String? supplierUrl,
    final double? cost,
    final String currency,
    final String? shippingDays,
    final bool hasTracking,
    final String? notes,
  }) = _$SupplierInfoImpl;

  factory _SupplierInfo.fromJson(Map<String, dynamic> json) =
      _$SupplierInfoImpl.fromJson;

  /// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
  @override
  String get type;

  /// Supplier's SKU/Product ID
  @override
  String? get supplierSku;

  /// Direct URL to supplier product page
  @override
  String? get supplierUrl;

  /// Cost price from supplier
  @override
  double? get cost;

  /// Currency of supplier cost price (supplier's currency, NOT selling currency).
  /// Selling price is always CAD. This tracks the supplier's original currency.
  @override
  String get currency;

  /// Estimated shipping days range (e.g., '7-15')
  @override
  String? get shippingDays;

  /// Whether supplier provides tracking
  @override
  bool get hasTracking;

  /// Internal notes about this supplier/product
  @override
  String? get notes;

  /// Create a copy of SupplierInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SupplierInfoImplCopyWith<_$SupplierInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
