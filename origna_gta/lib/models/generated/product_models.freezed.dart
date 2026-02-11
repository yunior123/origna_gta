// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryConfig {

/// Whether inventory is actively managed (false for dropship products)
 bool get managed;/// Track stock quantity (false = unlimited)
 bool get trackQuantity;/// Allow orders when out of stock
 bool get allowBackorder;/// Alert threshold for low stock
 int get lowStockThreshold;/// How long to hold inventory during checkout (minutes)
 int get reservationHoldMinutes;
/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<InventoryConfig> get copyWith => _$InventoryConfigCopyWithImpl<InventoryConfig>(this as InventoryConfig, _$identity);

  /// Serializes this InventoryConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryConfig&&(identical(other.managed, managed) || other.managed == managed)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.reservationHoldMinutes, reservationHoldMinutes) || other.reservationHoldMinutes == reservationHoldMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managed,trackQuantity,allowBackorder,lowStockThreshold,reservationHoldMinutes);

@override
String toString() {
  return 'InventoryConfig(managed: $managed, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockThreshold: $lowStockThreshold, reservationHoldMinutes: $reservationHoldMinutes)';
}


}

/// @nodoc
abstract mixin class $InventoryConfigCopyWith<$Res>  {
  factory $InventoryConfigCopyWith(InventoryConfig value, $Res Function(InventoryConfig) _then) = _$InventoryConfigCopyWithImpl;
@useResult
$Res call({
 bool managed, bool trackQuantity, bool allowBackorder, int lowStockThreshold, int reservationHoldMinutes
});




}
/// @nodoc
class _$InventoryConfigCopyWithImpl<$Res>
    implements $InventoryConfigCopyWith<$Res> {
  _$InventoryConfigCopyWithImpl(this._self, this._then);

  final InventoryConfig _self;
  final $Res Function(InventoryConfig) _then;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? managed = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockThreshold = null,Object? reservationHoldMinutes = null,}) {
  return _then(_self.copyWith(
managed: null == managed ? _self.managed : managed // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,reservationHoldMinutes: null == reservationHoldMinutes ? _self.reservationHoldMinutes : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InventoryConfig].
extension InventoryConfigPatterns on InventoryConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InventoryConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InventoryConfig value)  $default,){
final _that = this;
switch (_that) {
case _InventoryConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InventoryConfig value)?  $default,){
final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  int reservationHoldMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.reservationHoldMinutes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  int reservationHoldMinutes)  $default,) {final _that = this;
switch (_that) {
case _InventoryConfig():
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.reservationHoldMinutes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool managed,  bool trackQuantity,  bool allowBackorder,  int lowStockThreshold,  int reservationHoldMinutes)?  $default,) {final _that = this;
switch (_that) {
case _InventoryConfig() when $default != null:
return $default(_that.managed,_that.trackQuantity,_that.allowBackorder,_that.lowStockThreshold,_that.reservationHoldMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InventoryConfig implements InventoryConfig {
  const _InventoryConfig({this.managed = true, this.trackQuantity = true, this.allowBackorder = false, this.lowStockThreshold = 5, this.reservationHoldMinutes = 30});
  factory _InventoryConfig.fromJson(Map<String, dynamic> json) => _$InventoryConfigFromJson(json);

/// Whether inventory is actively managed (false for dropship products)
@override@JsonKey() final  bool managed;
/// Track stock quantity (false = unlimited)
@override@JsonKey() final  bool trackQuantity;
/// Allow orders when out of stock
@override@JsonKey() final  bool allowBackorder;
/// Alert threshold for low stock
@override@JsonKey() final  int lowStockThreshold;
/// How long to hold inventory during checkout (minutes)
@override@JsonKey() final  int reservationHoldMinutes;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryConfigCopyWith<_InventoryConfig> get copyWith => __$InventoryConfigCopyWithImpl<_InventoryConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InventoryConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryConfig&&(identical(other.managed, managed) || other.managed == managed)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockThreshold, lowStockThreshold) || other.lowStockThreshold == lowStockThreshold)&&(identical(other.reservationHoldMinutes, reservationHoldMinutes) || other.reservationHoldMinutes == reservationHoldMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,managed,trackQuantity,allowBackorder,lowStockThreshold,reservationHoldMinutes);

@override
String toString() {
  return 'InventoryConfig(managed: $managed, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockThreshold: $lowStockThreshold, reservationHoldMinutes: $reservationHoldMinutes)';
}


}

/// @nodoc
abstract mixin class _$InventoryConfigCopyWith<$Res> implements $InventoryConfigCopyWith<$Res> {
  factory _$InventoryConfigCopyWith(_InventoryConfig value, $Res Function(_InventoryConfig) _then) = __$InventoryConfigCopyWithImpl;
@override @useResult
$Res call({
 bool managed, bool trackQuantity, bool allowBackorder, int lowStockThreshold, int reservationHoldMinutes
});




}
/// @nodoc
class __$InventoryConfigCopyWithImpl<$Res>
    implements _$InventoryConfigCopyWith<$Res> {
  __$InventoryConfigCopyWithImpl(this._self, this._then);

  final _InventoryConfig _self;
  final $Res Function(_InventoryConfig) _then;

/// Create a copy of InventoryConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? managed = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockThreshold = null,Object? reservationHoldMinutes = null,}) {
  return _then(_InventoryConfig(
managed: null == managed ? _self.managed : managed // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockThreshold: null == lowStockThreshold ? _self.lowStockThreshold : lowStockThreshold // ignore: cast_nullable_to_non_nullable
as int,reservationHoldMinutes: null == reservationHoldMinutes ? _self.reservationHoldMinutes : reservationHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Product {

 String get productId; String get name; double get price; String get description; List<String> get imageUrls; String get sellerId; Address get sellerAddress; int get categoryId; int get stockQuantity; double get rating; int get ratingCount; DateTime get createdAt; bool get isActive;// Optional shipping metadata
 double? get weightKg; double? get lengthCm; double? get widthCm; double? get heightCm;// Delivery options
 bool get isLocalDeliveryOnly; bool get isPerishable; int get estimatedShipDays; List<SellerDeliveryOption> get deliveryOptions; int get minimumOrderQuantity; bool get freeShipping;// Digital product flag
 bool get isDigital;// Tax and metadata
 String? get taxCode; List<String> get keywords;// Flat supplier fields (used when supplier object is not provided)
 double? get cost; String? get supplierSku; String? get supplierUrl;// Structured objects for scalability
/// Supplier information for dropshipping/marketplace products
 SupplierInfo? get supplier;/// Inventory management configuration
 InventoryConfig? get inventory;/// Product status: draft, active, paused, archived, out_of_stock
 String get status;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other.deliveryOptions, deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,productId,name,price,description,const DeepCollectionEquality().hash(imageUrls),sellerId,sellerAddress,categoryId,stockQuantity,rating,ratingCount,createdAt,isActive,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,taxCode,const DeepCollectionEquality().hash(keywords),cost,supplierSku,supplierUrl,supplier,inventory,status]);

@override
String toString() {
  return 'Product(productId: $productId, name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, ratingCount: $ratingCount, createdAt: $createdAt, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String productId, String name, double price, String description, List<String> imageUrls, String sellerId, Address sellerAddress, int categoryId, int stockQuantity, double rating, int ratingCount, DateTime createdAt, bool isActive, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? taxCode, List<String> keywords, double? cost, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String status
});


$AddressCopyWith<$Res> get sellerAddress;$SupplierInfoCopyWith<$Res>? get supplier;$InventoryConfigCopyWith<$Res>? get inventory;

}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? name = null,Object? price = null,Object? description = null,Object? imageUrls = null,Object? sellerId = null,Object? sellerAddress = null,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? ratingCount = null,Object? createdAt = null,Object? isActive = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? taxCode = freezed,Object? keywords = null,Object? cost = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self.deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get sellerAddress {
  
  return $AddressCopyWith<$Res>(_self.sellerAddress, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.productId,_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.productId,_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  int ratingCount,  DateTime createdAt,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.productId,_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.ratingCount,_that.createdAt,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.productId, required this.name, required this.price, required this.description, required final  List<String> imageUrls, required this.sellerId, required this.sellerAddress, required this.categoryId, required this.stockQuantity, this.rating = 0.0, this.ratingCount = 0, required this.createdAt, this.isActive = true, this.weightKg, this.lengthCm, this.widthCm, this.heightCm, this.isLocalDeliveryOnly = false, this.isPerishable = false, this.estimatedShipDays = 3, final  List<SellerDeliveryOption> deliveryOptions = const [], this.minimumOrderQuantity = 1, this.freeShipping = false, this.isDigital = false, this.taxCode, final  List<String> keywords = const [], this.cost, this.supplierSku, this.supplierUrl, this.supplier, this.inventory, this.status = ProductStatusValues.active}): _imageUrls = imageUrls,_deliveryOptions = deliveryOptions,_keywords = keywords;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String productId;
@override final  String name;
@override final  double price;
@override final  String description;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  String sellerId;
@override final  Address sellerAddress;
@override final  int categoryId;
@override final  int stockQuantity;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int ratingCount;
@override final  DateTime createdAt;
@override@JsonKey() final  bool isActive;
// Optional shipping metadata
@override final  double? weightKg;
@override final  double? lengthCm;
@override final  double? widthCm;
@override final  double? heightCm;
// Delivery options
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  int estimatedShipDays;
 final  List<SellerDeliveryOption> _deliveryOptions;
@override@JsonKey() List<SellerDeliveryOption> get deliveryOptions {
  if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryOptions);
}

@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
// Digital product flag
@override@JsonKey() final  bool isDigital;
// Tax and metadata
@override final  String? taxCode;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

// Flat supplier fields (used when supplier object is not provided)
@override final  double? cost;
@override final  String? supplierSku;
@override final  String? supplierUrl;
// Structured objects for scalability
/// Supplier information for dropshipping/marketplace products
@override final  SupplierInfo? supplier;
/// Inventory management configuration
@override final  InventoryConfig? inventory;
/// Product status: draft, active, paused, archived, out_of_stock
@override@JsonKey() final  String status;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other._deliveryOptions, _deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,productId,name,price,description,const DeepCollectionEquality().hash(_imageUrls),sellerId,sellerAddress,categoryId,stockQuantity,rating,ratingCount,createdAt,isActive,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(_deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,taxCode,const DeepCollectionEquality().hash(_keywords),cost,supplierSku,supplierUrl,supplier,inventory,status]);

@override
String toString() {
  return 'Product(productId: $productId, name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, ratingCount: $ratingCount, createdAt: $createdAt, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String productId, String name, double price, String description, List<String> imageUrls, String sellerId, Address sellerAddress, int categoryId, int stockQuantity, double rating, int ratingCount, DateTime createdAt, bool isActive, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? taxCode, List<String> keywords, double? cost, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String status
});


@override $AddressCopyWith<$Res> get sellerAddress;@override $SupplierInfoCopyWith<$Res>? get supplier;@override $InventoryConfigCopyWith<$Res>? get inventory;

}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? name = null,Object? price = null,Object? description = null,Object? imageUrls = null,Object? sellerId = null,Object? sellerAddress = null,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? ratingCount = null,Object? createdAt = null,Object? isActive = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? taxCode = freezed,Object? keywords = null,Object? cost = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? status = null,}) {
  return _then(_Product(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self._deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get sellerAddress {
  
  return $AddressCopyWith<$Res>(_self.sellerAddress, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// @nodoc
mixin _$ProductCreate {

 String get name; double get price; String get description; List<String> get imageUrls; String get sellerId; Address get sellerAddress; int get categoryId; int get stockQuantity; double get rating; bool get isActive; double? get weightKg; double? get lengthCm; double? get widthCm; double? get heightCm; bool get isLocalDeliveryOnly; bool get isPerishable; int get estimatedShipDays; List<SellerDeliveryOption> get deliveryOptions; int get minimumOrderQuantity; bool get freeShipping; bool get isDigital; String? get taxCode; List<String> get keywords;// Flat supplier fields (used when supplier object is not provided)
 double? get cost; String? get supplierSku; String? get supplierUrl;// Structured objects
 SupplierInfo? get supplier; InventoryConfig? get inventory; String get status;
/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCreateCopyWith<ProductCreate> get copyWith => _$ProductCreateCopyWithImpl<ProductCreate>(this as ProductCreate, _$identity);

  /// Serializes this ProductCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other.deliveryOptions, deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other.keywords, keywords)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,price,description,const DeepCollectionEquality().hash(imageUrls),sellerId,sellerAddress,categoryId,stockQuantity,rating,isActive,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,taxCode,const DeepCollectionEquality().hash(keywords),cost,supplierSku,supplierUrl,supplier,inventory,status]);

@override
String toString() {
  return 'ProductCreate(name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
}


}

/// @nodoc
abstract mixin class $ProductCreateCopyWith<$Res>  {
  factory $ProductCreateCopyWith(ProductCreate value, $Res Function(ProductCreate) _then) = _$ProductCreateCopyWithImpl;
@useResult
$Res call({
 String name, double price, String description, List<String> imageUrls, String sellerId, Address sellerAddress, int categoryId, int stockQuantity, double rating, bool isActive, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? taxCode, List<String> keywords, double? cost, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String status
});


$AddressCopyWith<$Res> get sellerAddress;$SupplierInfoCopyWith<$Res>? get supplier;$InventoryConfigCopyWith<$Res>? get inventory;

}
/// @nodoc
class _$ProductCreateCopyWithImpl<$Res>
    implements $ProductCreateCopyWith<$Res> {
  _$ProductCreateCopyWithImpl(this._self, this._then);

  final ProductCreate _self;
  final $Res Function(ProductCreate) _then;

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? price = null,Object? description = null,Object? imageUrls = null,Object? sellerId = null,Object? sellerAddress = null,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? isActive = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? taxCode = freezed,Object? keywords = null,Object? cost = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self.deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self.keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get sellerAddress {
  
  return $AddressCopyWith<$Res>(_self.sellerAddress, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductCreate].
extension ProductCreatePatterns on ProductCreate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCreate value)  $default,){
final _that = this;
switch (_that) {
case _ProductCreate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCreate value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)  $default,) {final _that = this;
switch (_that) {
case _ProductCreate():
return $default(_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double price,  String description,  List<String> imageUrls,  String sellerId,  Address sellerAddress,  int categoryId,  int stockQuantity,  double rating,  bool isActive,  double? weightKg,  double? lengthCm,  double? widthCm,  double? heightCm,  bool isLocalDeliveryOnly,  bool isPerishable,  int estimatedShipDays,  List<SellerDeliveryOption> deliveryOptions,  int minimumOrderQuantity,  bool freeShipping,  bool isDigital,  String? taxCode,  List<String> keywords,  double? cost,  String? supplierSku,  String? supplierUrl,  SupplierInfo? supplier,  InventoryConfig? inventory,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ProductCreate() when $default != null:
return $default(_that.name,_that.price,_that.description,_that.imageUrls,_that.sellerId,_that.sellerAddress,_that.categoryId,_that.stockQuantity,_that.rating,_that.isActive,_that.weightKg,_that.lengthCm,_that.widthCm,_that.heightCm,_that.isLocalDeliveryOnly,_that.isPerishable,_that.estimatedShipDays,_that.deliveryOptions,_that.minimumOrderQuantity,_that.freeShipping,_that.isDigital,_that.taxCode,_that.keywords,_that.cost,_that.supplierSku,_that.supplierUrl,_that.supplier,_that.inventory,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductCreate implements ProductCreate {
  const _ProductCreate({required this.name, required this.price, required this.description, required final  List<String> imageUrls, required this.sellerId, required this.sellerAddress, required this.categoryId, required this.stockQuantity, this.rating = 0.0, this.isActive = true, this.weightKg, this.lengthCm, this.widthCm, this.heightCm, this.isLocalDeliveryOnly = false, this.isPerishable = false, this.estimatedShipDays = 3, final  List<SellerDeliveryOption> deliveryOptions = const [], this.minimumOrderQuantity = 1, this.freeShipping = false, this.isDigital = false, this.taxCode, final  List<String> keywords = const [], this.cost, this.supplierSku, this.supplierUrl, this.supplier, this.inventory, this.status = ProductStatusValues.active}): _imageUrls = imageUrls,_deliveryOptions = deliveryOptions,_keywords = keywords;
  factory _ProductCreate.fromJson(Map<String, dynamic> json) => _$ProductCreateFromJson(json);

@override final  String name;
@override final  double price;
@override final  String description;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  String sellerId;
@override final  Address sellerAddress;
@override final  int categoryId;
@override final  int stockQuantity;
@override@JsonKey() final  double rating;
@override@JsonKey() final  bool isActive;
@override final  double? weightKg;
@override final  double? lengthCm;
@override final  double? widthCm;
@override final  double? heightCm;
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  int estimatedShipDays;
 final  List<SellerDeliveryOption> _deliveryOptions;
@override@JsonKey() List<SellerDeliveryOption> get deliveryOptions {
  if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryOptions);
}

@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
@override@JsonKey() final  bool isDigital;
@override final  String? taxCode;
 final  List<String> _keywords;
@override@JsonKey() List<String> get keywords {
  if (_keywords is EqualUnmodifiableListView) return _keywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywords);
}

// Flat supplier fields (used when supplier object is not provided)
@override final  double? cost;
@override final  String? supplierSku;
@override final  String? supplierUrl;
// Structured objects
@override final  SupplierInfo? supplier;
@override final  InventoryConfig? inventory;
@override@JsonKey() final  String status;

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCreateCopyWith<_ProductCreate> get copyWith => __$ProductCreateCopyWithImpl<_ProductCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.lengthCm, lengthCm) || other.lengthCm == lengthCm)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.estimatedShipDays, estimatedShipDays) || other.estimatedShipDays == estimatedShipDays)&&const DeepCollectionEquality().equals(other._deliveryOptions, _deliveryOptions)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&const DeepCollectionEquality().equals(other._keywords, _keywords)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,price,description,const DeepCollectionEquality().hash(_imageUrls),sellerId,sellerAddress,categoryId,stockQuantity,rating,isActive,weightKg,lengthCm,widthCm,heightCm,isLocalDeliveryOnly,isPerishable,estimatedShipDays,const DeepCollectionEquality().hash(_deliveryOptions),minimumOrderQuantity,freeShipping,isDigital,taxCode,const DeepCollectionEquality().hash(_keywords),cost,supplierSku,supplierUrl,supplier,inventory,status]);

@override
String toString() {
  return 'ProductCreate(name: $name, price: $price, description: $description, imageUrls: $imageUrls, sellerId: $sellerId, sellerAddress: $sellerAddress, categoryId: $categoryId, stockQuantity: $stockQuantity, rating: $rating, isActive: $isActive, weightKg: $weightKg, lengthCm: $lengthCm, widthCm: $widthCm, heightCm: $heightCm, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, estimatedShipDays: $estimatedShipDays, deliveryOptions: $deliveryOptions, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, isDigital: $isDigital, taxCode: $taxCode, keywords: $keywords, cost: $cost, supplierSku: $supplierSku, supplierUrl: $supplierUrl, supplier: $supplier, inventory: $inventory, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ProductCreateCopyWith<$Res> implements $ProductCreateCopyWith<$Res> {
  factory _$ProductCreateCopyWith(_ProductCreate value, $Res Function(_ProductCreate) _then) = __$ProductCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, double price, String description, List<String> imageUrls, String sellerId, Address sellerAddress, int categoryId, int stockQuantity, double rating, bool isActive, double? weightKg, double? lengthCm, double? widthCm, double? heightCm, bool isLocalDeliveryOnly, bool isPerishable, int estimatedShipDays, List<SellerDeliveryOption> deliveryOptions, int minimumOrderQuantity, bool freeShipping, bool isDigital, String? taxCode, List<String> keywords, double? cost, String? supplierSku, String? supplierUrl, SupplierInfo? supplier, InventoryConfig? inventory, String status
});


@override $AddressCopyWith<$Res> get sellerAddress;@override $SupplierInfoCopyWith<$Res>? get supplier;@override $InventoryConfigCopyWith<$Res>? get inventory;

}
/// @nodoc
class __$ProductCreateCopyWithImpl<$Res>
    implements _$ProductCreateCopyWith<$Res> {
  __$ProductCreateCopyWithImpl(this._self, this._then);

  final _ProductCreate _self;
  final $Res Function(_ProductCreate) _then;

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? price = null,Object? description = null,Object? imageUrls = null,Object? sellerId = null,Object? sellerAddress = null,Object? categoryId = null,Object? stockQuantity = null,Object? rating = null,Object? isActive = null,Object? weightKg = freezed,Object? lengthCm = freezed,Object? widthCm = freezed,Object? heightCm = freezed,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? estimatedShipDays = null,Object? deliveryOptions = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? isDigital = null,Object? taxCode = freezed,Object? keywords = null,Object? cost = freezed,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? supplier = freezed,Object? inventory = freezed,Object? status = null,}) {
  return _then(_ProductCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as Address,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,lengthCm: freezed == lengthCm ? _self.lengthCm : lengthCm // ignore: cast_nullable_to_non_nullable
as double?,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as double?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,estimatedShipDays: null == estimatedShipDays ? _self.estimatedShipDays : estimatedShipDays // ignore: cast_nullable_to_non_nullable
as int,deliveryOptions: null == deliveryOptions ? _self._deliveryOptions : deliveryOptions // ignore: cast_nullable_to_non_nullable
as List<SellerDeliveryOption>,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,keywords: null == keywords ? _self._keywords : keywords // ignore: cast_nullable_to_non_nullable
as List<String>,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,supplier: freezed == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as SupplierInfo?,inventory: freezed == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as InventoryConfig?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res> get sellerAddress {
  
  return $AddressCopyWith<$Res>(_self.sellerAddress, (value) {
    return _then(_self.copyWith(sellerAddress: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<$Res>? get supplier {
    if (_self.supplier == null) {
    return null;
  }

  return $SupplierInfoCopyWith<$Res>(_self.supplier!, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of ProductCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InventoryConfigCopyWith<$Res>? get inventory {
    if (_self.inventory == null) {
    return null;
  }

  return $InventoryConfigCopyWith<$Res>(_self.inventory!, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// @nodoc
mixin _$SellerDeliveryOption {

/// Delivery type: 'standard', 'express', 'same_day', etc.
 String get type;/// Human-readable description
 String get description;/// Shipping cost in dollars
 double get cost;/// Estimated delivery days
 int get estimatedDays;/// Optional quantity-based discounts for this delivery option
 List<ShippingQuantityDiscount> get quantityDiscounts;/// Maximum items before shipping cost increases (0 = no limit)
 int get maxItemsPerShipment;/// Additional cost per item after maxItemsPerShipment (0 = free per-item)
 double get additionalItemCost;/// Whether this option is available for international orders
 bool get availableInternational;
/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerDeliveryOptionCopyWith<SellerDeliveryOption> get copyWith => _$SellerDeliveryOptionCopyWithImpl<SellerDeliveryOption>(this as SellerDeliveryOption, _$identity);

  /// Serializes this SellerDeliveryOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerDeliveryOption&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.estimatedDays, estimatedDays) || other.estimatedDays == estimatedDays)&&const DeepCollectionEquality().equals(other.quantityDiscounts, quantityDiscounts)&&(identical(other.maxItemsPerShipment, maxItemsPerShipment) || other.maxItemsPerShipment == maxItemsPerShipment)&&(identical(other.additionalItemCost, additionalItemCost) || other.additionalItemCost == additionalItemCost)&&(identical(other.availableInternational, availableInternational) || other.availableInternational == availableInternational));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,cost,estimatedDays,const DeepCollectionEquality().hash(quantityDiscounts),maxItemsPerShipment,additionalItemCost,availableInternational);

@override
String toString() {
  return 'SellerDeliveryOption(type: $type, description: $description, cost: $cost, estimatedDays: $estimatedDays, quantityDiscounts: $quantityDiscounts, maxItemsPerShipment: $maxItemsPerShipment, additionalItemCost: $additionalItemCost, availableInternational: $availableInternational)';
}


}

/// @nodoc
abstract mixin class $SellerDeliveryOptionCopyWith<$Res>  {
  factory $SellerDeliveryOptionCopyWith(SellerDeliveryOption value, $Res Function(SellerDeliveryOption) _then) = _$SellerDeliveryOptionCopyWithImpl;
@useResult
$Res call({
 String type, String description, double cost, int estimatedDays, List<ShippingQuantityDiscount> quantityDiscounts, int maxItemsPerShipment, double additionalItemCost, bool availableInternational
});




}
/// @nodoc
class _$SellerDeliveryOptionCopyWithImpl<$Res>
    implements $SellerDeliveryOptionCopyWith<$Res> {
  _$SellerDeliveryOptionCopyWithImpl(this._self, this._then);

  final SellerDeliveryOption _self;
  final $Res Function(SellerDeliveryOption) _then;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? description = null,Object? cost = null,Object? estimatedDays = null,Object? quantityDiscounts = null,Object? maxItemsPerShipment = null,Object? additionalItemCost = null,Object? availableInternational = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double,estimatedDays: null == estimatedDays ? _self.estimatedDays : estimatedDays // ignore: cast_nullable_to_non_nullable
as int,quantityDiscounts: null == quantityDiscounts ? _self.quantityDiscounts : quantityDiscounts // ignore: cast_nullable_to_non_nullable
as List<ShippingQuantityDiscount>,maxItemsPerShipment: null == maxItemsPerShipment ? _self.maxItemsPerShipment : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
as int,additionalItemCost: null == additionalItemCost ? _self.additionalItemCost : additionalItemCost // ignore: cast_nullable_to_non_nullable
as double,availableInternational: null == availableInternational ? _self.availableInternational : availableInternational // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerDeliveryOption].
extension SellerDeliveryOptionPatterns on SellerDeliveryOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerDeliveryOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerDeliveryOption value)  $default,){
final _that = this;
switch (_that) {
case _SellerDeliveryOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerDeliveryOption value)?  $default,){
final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String description,  double cost,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  double additionalItemCost,  bool availableInternational)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that.type,_that.description,_that.cost,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCost,_that.availableInternational);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String description,  double cost,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  double additionalItemCost,  bool availableInternational)  $default,) {final _that = this;
switch (_that) {
case _SellerDeliveryOption():
return $default(_that.type,_that.description,_that.cost,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCost,_that.availableInternational);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String description,  double cost,  int estimatedDays,  List<ShippingQuantityDiscount> quantityDiscounts,  int maxItemsPerShipment,  double additionalItemCost,  bool availableInternational)?  $default,) {final _that = this;
switch (_that) {
case _SellerDeliveryOption() when $default != null:
return $default(_that.type,_that.description,_that.cost,_that.estimatedDays,_that.quantityDiscounts,_that.maxItemsPerShipment,_that.additionalItemCost,_that.availableInternational);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SellerDeliveryOption implements SellerDeliveryOption {
  const _SellerDeliveryOption({this.type = DeliveryTypeValues.standard, this.description = '', this.cost = 0.0, this.estimatedDays = 3, final  List<ShippingQuantityDiscount> quantityDiscounts = const [], this.maxItemsPerShipment = 0, this.additionalItemCost = 0.0, this.availableInternational = true}): _quantityDiscounts = quantityDiscounts;
  factory _SellerDeliveryOption.fromJson(Map<String, dynamic> json) => _$SellerDeliveryOptionFromJson(json);

/// Delivery type: 'standard', 'express', 'same_day', etc.
@override@JsonKey() final  String type;
/// Human-readable description
@override@JsonKey() final  String description;
/// Shipping cost in dollars
@override@JsonKey() final  double cost;
/// Estimated delivery days
@override@JsonKey() final  int estimatedDays;
/// Optional quantity-based discounts for this delivery option
 final  List<ShippingQuantityDiscount> _quantityDiscounts;
/// Optional quantity-based discounts for this delivery option
@override@JsonKey() List<ShippingQuantityDiscount> get quantityDiscounts {
  if (_quantityDiscounts is EqualUnmodifiableListView) return _quantityDiscounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quantityDiscounts);
}

/// Maximum items before shipping cost increases (0 = no limit)
@override@JsonKey() final  int maxItemsPerShipment;
/// Additional cost per item after maxItemsPerShipment (0 = free per-item)
@override@JsonKey() final  double additionalItemCost;
/// Whether this option is available for international orders
@override@JsonKey() final  bool availableInternational;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerDeliveryOptionCopyWith<_SellerDeliveryOption> get copyWith => __$SellerDeliveryOptionCopyWithImpl<_SellerDeliveryOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SellerDeliveryOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerDeliveryOption&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.estimatedDays, estimatedDays) || other.estimatedDays == estimatedDays)&&const DeepCollectionEquality().equals(other._quantityDiscounts, _quantityDiscounts)&&(identical(other.maxItemsPerShipment, maxItemsPerShipment) || other.maxItemsPerShipment == maxItemsPerShipment)&&(identical(other.additionalItemCost, additionalItemCost) || other.additionalItemCost == additionalItemCost)&&(identical(other.availableInternational, availableInternational) || other.availableInternational == availableInternational));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,description,cost,estimatedDays,const DeepCollectionEquality().hash(_quantityDiscounts),maxItemsPerShipment,additionalItemCost,availableInternational);

@override
String toString() {
  return 'SellerDeliveryOption(type: $type, description: $description, cost: $cost, estimatedDays: $estimatedDays, quantityDiscounts: $quantityDiscounts, maxItemsPerShipment: $maxItemsPerShipment, additionalItemCost: $additionalItemCost, availableInternational: $availableInternational)';
}


}

/// @nodoc
abstract mixin class _$SellerDeliveryOptionCopyWith<$Res> implements $SellerDeliveryOptionCopyWith<$Res> {
  factory _$SellerDeliveryOptionCopyWith(_SellerDeliveryOption value, $Res Function(_SellerDeliveryOption) _then) = __$SellerDeliveryOptionCopyWithImpl;
@override @useResult
$Res call({
 String type, String description, double cost, int estimatedDays, List<ShippingQuantityDiscount> quantityDiscounts, int maxItemsPerShipment, double additionalItemCost, bool availableInternational
});




}
/// @nodoc
class __$SellerDeliveryOptionCopyWithImpl<$Res>
    implements _$SellerDeliveryOptionCopyWith<$Res> {
  __$SellerDeliveryOptionCopyWithImpl(this._self, this._then);

  final _SellerDeliveryOption _self;
  final $Res Function(_SellerDeliveryOption) _then;

/// Create a copy of SellerDeliveryOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? description = null,Object? cost = null,Object? estimatedDays = null,Object? quantityDiscounts = null,Object? maxItemsPerShipment = null,Object? additionalItemCost = null,Object? availableInternational = null,}) {
  return _then(_SellerDeliveryOption(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double,estimatedDays: null == estimatedDays ? _self.estimatedDays : estimatedDays // ignore: cast_nullable_to_non_nullable
as int,quantityDiscounts: null == quantityDiscounts ? _self._quantityDiscounts : quantityDiscounts // ignore: cast_nullable_to_non_nullable
as List<ShippingQuantityDiscount>,maxItemsPerShipment: null == maxItemsPerShipment ? _self.maxItemsPerShipment : maxItemsPerShipment // ignore: cast_nullable_to_non_nullable
as int,additionalItemCost: null == additionalItemCost ? _self.additionalItemCost : additionalItemCost // ignore: cast_nullable_to_non_nullable
as double,availableInternational: null == availableInternational ? _self.availableInternational : availableInternational // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ShippingQuantityDiscount {

/// Minimum quantity to qualify for this discount
 int get minQuantity;/// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
 String get discountType;/// Discount value (interpretation depends on discountType)
 double get discountValue;/// Optional label for display (e.g., "Bulk Shipping Discount")
 String? get label;
/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShippingQuantityDiscountCopyWith<ShippingQuantityDiscount> get copyWith => _$ShippingQuantityDiscountCopyWithImpl<ShippingQuantityDiscount>(this as ShippingQuantityDiscount, _$identity);

  /// Serializes this ShippingQuantityDiscount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShippingQuantityDiscount&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,discountType,discountValue,label);

@override
String toString() {
  return 'ShippingQuantityDiscount(minQuantity: $minQuantity, discountType: $discountType, discountValue: $discountValue, label: $label)';
}


}

/// @nodoc
abstract mixin class $ShippingQuantityDiscountCopyWith<$Res>  {
  factory $ShippingQuantityDiscountCopyWith(ShippingQuantityDiscount value, $Res Function(ShippingQuantityDiscount) _then) = _$ShippingQuantityDiscountCopyWithImpl;
@useResult
$Res call({
 int minQuantity, String discountType, double discountValue, String? label
});




}
/// @nodoc
class _$ShippingQuantityDiscountCopyWithImpl<$Res>
    implements $ShippingQuantityDiscountCopyWith<$Res> {
  _$ShippingQuantityDiscountCopyWithImpl(this._self, this._then);

  final ShippingQuantityDiscount _self;
  final $Res Function(ShippingQuantityDiscount) _then;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQuantity = null,Object? discountType = null,Object? discountValue = null,Object? label = freezed,}) {
  return _then(_self.copyWith(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShippingQuantityDiscount].
extension ShippingQuantityDiscountPatterns on ShippingQuantityDiscount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShippingQuantityDiscount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShippingQuantityDiscount value)  $default,){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShippingQuantityDiscount value)?  $default,){
final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minQuantity,  String discountType,  double discountValue,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minQuantity,  String discountType,  double discountValue,  String? label)  $default,) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount():
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minQuantity,  String discountType,  double discountValue,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _ShippingQuantityDiscount() when $default != null:
return $default(_that.minQuantity,_that.discountType,_that.discountValue,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShippingQuantityDiscount implements ShippingQuantityDiscount {
  const _ShippingQuantityDiscount({required this.minQuantity, this.discountType = DiscountTypeValues.percent, required this.discountValue, this.label});
  factory _ShippingQuantityDiscount.fromJson(Map<String, dynamic> json) => _$ShippingQuantityDiscountFromJson(json);

/// Minimum quantity to qualify for this discount
@override final  int minQuantity;
/// Discount type: 'percent' (e.g., 10% off), 'fixed' (e.g., $2 off), 'flat_rate' (e.g., $5 flat)
@override@JsonKey() final  String discountType;
/// Discount value (interpretation depends on discountType)
@override final  double discountValue;
/// Optional label for display (e.g., "Bulk Shipping Discount")
@override final  String? label;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShippingQuantityDiscountCopyWith<_ShippingQuantityDiscount> get copyWith => __$ShippingQuantityDiscountCopyWithImpl<_ShippingQuantityDiscount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShippingQuantityDiscountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShippingQuantityDiscount&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.discountValue, discountValue) || other.discountValue == discountValue)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,discountType,discountValue,label);

@override
String toString() {
  return 'ShippingQuantityDiscount(minQuantity: $minQuantity, discountType: $discountType, discountValue: $discountValue, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ShippingQuantityDiscountCopyWith<$Res> implements $ShippingQuantityDiscountCopyWith<$Res> {
  factory _$ShippingQuantityDiscountCopyWith(_ShippingQuantityDiscount value, $Res Function(_ShippingQuantityDiscount) _then) = __$ShippingQuantityDiscountCopyWithImpl;
@override @useResult
$Res call({
 int minQuantity, String discountType, double discountValue, String? label
});




}
/// @nodoc
class __$ShippingQuantityDiscountCopyWithImpl<$Res>
    implements _$ShippingQuantityDiscountCopyWith<$Res> {
  __$ShippingQuantityDiscountCopyWithImpl(this._self, this._then);

  final _ShippingQuantityDiscount _self;
  final $Res Function(_ShippingQuantityDiscount) _then;

/// Create a copy of ShippingQuantityDiscount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQuantity = null,Object? discountType = null,Object? discountValue = null,Object? label = freezed,}) {
  return _then(_ShippingQuantityDiscount(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as String,discountValue: null == discountValue ? _self.discountValue : discountValue // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SupplierInfo {

/// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
 String get type;/// Supplier's SKU/Product ID
 String? get supplierSku;/// Direct URL to supplier product page
 String? get supplierUrl;/// Cost price from supplier
 double? get cost;/// Currency of supplier cost price (supplier's currency, NOT selling currency).
/// Selling price is always CAD. This tracks the supplier's original currency.
 String get currency;/// Estimated shipping days range (e.g., '7-15')
 String? get shippingDays;/// Whether supplier provides tracking
 bool get hasTracking;/// Internal notes about this supplier/product
 String? get notes;
/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupplierInfoCopyWith<SupplierInfo> get copyWith => _$SupplierInfoCopyWithImpl<SupplierInfo>(this as SupplierInfo, _$identity);

  /// Serializes this SupplierInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupplierInfo&&(identical(other.type, type) || other.type == type)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.shippingDays, shippingDays) || other.shippingDays == shippingDays)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,supplierSku,supplierUrl,cost,currency,shippingDays,hasTracking,notes);

@override
String toString() {
  return 'SupplierInfo(type: $type, supplierSku: $supplierSku, supplierUrl: $supplierUrl, cost: $cost, currency: $currency, shippingDays: $shippingDays, hasTracking: $hasTracking, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SupplierInfoCopyWith<$Res>  {
  factory $SupplierInfoCopyWith(SupplierInfo value, $Res Function(SupplierInfo) _then) = _$SupplierInfoCopyWithImpl;
@useResult
$Res call({
 String type, String? supplierSku, String? supplierUrl, double? cost, String currency, String? shippingDays, bool hasTracking, String? notes
});




}
/// @nodoc
class _$SupplierInfoCopyWithImpl<$Res>
    implements $SupplierInfoCopyWith<$Res> {
  _$SupplierInfoCopyWithImpl(this._self, this._then);

  final SupplierInfo _self;
  final $Res Function(SupplierInfo) _then;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? cost = freezed,Object? currency = null,Object? shippingDays = freezed,Object? hasTracking = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,shippingDays: freezed == shippingDays ? _self.shippingDays : shippingDays // ignore: cast_nullable_to_non_nullable
as String?,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SupplierInfo].
extension SupplierInfoPatterns on SupplierInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupplierInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupplierInfo value)  $default,){
final _that = this;
switch (_that) {
case _SupplierInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupplierInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String? supplierSku,  String? supplierUrl,  double? cost,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.cost,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String? supplierSku,  String? supplierUrl,  double? cost,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SupplierInfo():
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.cost,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String? supplierSku,  String? supplierUrl,  double? cost,  String currency,  String? shippingDays,  bool hasTracking,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SupplierInfo() when $default != null:
return $default(_that.type,_that.supplierSku,_that.supplierUrl,_that.cost,_that.currency,_that.shippingDays,_that.hasTracking,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupplierInfo implements SupplierInfo {
  const _SupplierInfo({required this.type, this.supplierSku, this.supplierUrl, this.cost, this.currency = 'USD', this.shippingDays, this.hasTracking = false, this.notes});
  factory _SupplierInfo.fromJson(Map<String, dynamic> json) => _$SupplierInfoFromJson(json);

/// Supplier platform type: aliexpress, dhgate, alibaba, 1688, temu, cjdropshipping, other
@override final  String type;
/// Supplier's SKU/Product ID
@override final  String? supplierSku;
/// Direct URL to supplier product page
@override final  String? supplierUrl;
/// Cost price from supplier
@override final  double? cost;
/// Currency of supplier cost price (supplier's currency, NOT selling currency).
/// Selling price is always CAD. This tracks the supplier's original currency.
@override@JsonKey() final  String currency;
/// Estimated shipping days range (e.g., '7-15')
@override final  String? shippingDays;
/// Whether supplier provides tracking
@override@JsonKey() final  bool hasTracking;
/// Internal notes about this supplier/product
@override final  String? notes;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupplierInfoCopyWith<_SupplierInfo> get copyWith => __$SupplierInfoCopyWithImpl<_SupplierInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupplierInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupplierInfo&&(identical(other.type, type) || other.type == type)&&(identical(other.supplierSku, supplierSku) || other.supplierSku == supplierSku)&&(identical(other.supplierUrl, supplierUrl) || other.supplierUrl == supplierUrl)&&(identical(other.cost, cost) || other.cost == cost)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.shippingDays, shippingDays) || other.shippingDays == shippingDays)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,supplierSku,supplierUrl,cost,currency,shippingDays,hasTracking,notes);

@override
String toString() {
  return 'SupplierInfo(type: $type, supplierSku: $supplierSku, supplierUrl: $supplierUrl, cost: $cost, currency: $currency, shippingDays: $shippingDays, hasTracking: $hasTracking, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SupplierInfoCopyWith<$Res> implements $SupplierInfoCopyWith<$Res> {
  factory _$SupplierInfoCopyWith(_SupplierInfo value, $Res Function(_SupplierInfo) _then) = __$SupplierInfoCopyWithImpl;
@override @useResult
$Res call({
 String type, String? supplierSku, String? supplierUrl, double? cost, String currency, String? shippingDays, bool hasTracking, String? notes
});




}
/// @nodoc
class __$SupplierInfoCopyWithImpl<$Res>
    implements _$SupplierInfoCopyWith<$Res> {
  __$SupplierInfoCopyWithImpl(this._self, this._then);

  final _SupplierInfo _self;
  final $Res Function(_SupplierInfo) _then;

/// Create a copy of SupplierInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? supplierSku = freezed,Object? supplierUrl = freezed,Object? cost = freezed,Object? currency = null,Object? shippingDays = freezed,Object? hasTracking = null,Object? notes = freezed,}) {
  return _then(_SupplierInfo(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,supplierSku: freezed == supplierSku ? _self.supplierSku : supplierSku // ignore: cast_nullable_to_non_nullable
as String?,supplierUrl: freezed == supplierUrl ? _self.supplierUrl : supplierUrl // ignore: cast_nullable_to_non_nullable
as String?,cost: freezed == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,shippingDays: freezed == shippingDays ? _self.shippingDays : shippingDays // ignore: cast_nullable_to_non_nullable
as String?,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
