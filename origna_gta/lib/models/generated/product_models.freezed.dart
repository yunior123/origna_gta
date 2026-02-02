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
      throw _privateConstructorUsedError; // Tax and metadata
  String? get taxCode => throw _privateConstructorUsedError;
  List<String> get keywords => throw _privateConstructorUsedError;

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
    String? taxCode,
    List<String> keywords,
  });

  $AddressCopyWith<$Res> get sellerAddress;
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
    Object? taxCode = freezed,
    Object? keywords = null,
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
            taxCode: freezed == taxCode
                ? _value.taxCode
                : taxCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            keywords: null == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
    String? taxCode,
    List<String> keywords,
  });

  @override
  $AddressCopyWith<$Res> get sellerAddress;
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
    Object? taxCode = freezed,
    Object? keywords = null,
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
        taxCode: freezed == taxCode
            ? _value.taxCode
            : taxCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywords: null == keywords
            ? _value._keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
    this.taxCode,
    final List<String> keywords = const [],
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

  @override
  String toString() {
    return 'Product(productId: $productId, name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, dateCreated: $dateCreated, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, taxCode: $taxCode, keywords: $keywords)';
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
            (identical(other.taxCode, taxCode) || other.taxCode == taxCode) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords));
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
    taxCode,
    const DeepCollectionEquality().hash(_keywords),
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
    final String? taxCode,
    final List<String> keywords,
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
  bool get freeShipping; // Tax and metadata
  @override
  String? get taxCode;
  @override
  List<String> get keywords;

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
  String? get taxCode => throw _privateConstructorUsedError;
  List<String> get keywords => throw _privateConstructorUsedError;

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
    String? taxCode,
    List<String> keywords,
  });

  $AddressCopyWith<$Res> get sellerAddress;
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
    Object? taxCode = freezed,
    Object? keywords = null,
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
            taxCode: freezed == taxCode
                ? _value.taxCode
                : taxCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            keywords: null == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
    String? taxCode,
    List<String> keywords,
  });

  @override
  $AddressCopyWith<$Res> get sellerAddress;
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
    Object? taxCode = freezed,
    Object? keywords = null,
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
        taxCode: freezed == taxCode
            ? _value.taxCode
            : taxCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywords: null == keywords
            ? _value._keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
    this.taxCode,
    final List<String> keywords = const [],
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
  final String? taxCode;
  final List<String> _keywords;
  @override
  @JsonKey()
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  @override
  String toString() {
    return 'ProductCreate(name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, taxCode: $taxCode, keywords: $keywords)';
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
            (identical(other.taxCode, taxCode) || other.taxCode == taxCode) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords));
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
    taxCode,
    const DeepCollectionEquality().hash(_keywords),
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
    final String? taxCode,
    final List<String> keywords,
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
  String? get taxCode;
  @override
  List<String> get keywords;

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
  $Res call({String type, String description, double cost, int estimatedDays});
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
  $Res call({String type, String description, double cost, int estimatedDays});
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
  });

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

  @override
  String toString() {
    return 'SellerDeliveryOption(type: $type, description: $description, cost: $cost, estimatedDays: $estimatedDays)';
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
                other.estimatedDays == estimatedDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, description, cost, estimatedDays);

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

  /// Create a copy of SellerDeliveryOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SellerDeliveryOptionImplCopyWith<_$SellerDeliveryOptionImpl>
  get copyWith => throw _privateConstructorUsedError;
}
