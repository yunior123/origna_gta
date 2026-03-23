// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CheckoutState {

 Address? get address; double get baseShippingCost;// Base shipping before delivery speed surcharge
 Map<String, double> get sellerShippingCosts;// Breakdown per seller
 Map<String, String> get sellerNames;// Seller names for display
 DeliverySpeed get deliverySpeed; List<DeliverySpeed> get availableDeliverySpeeds; bool get isLocalDelivery;// Within ~50km of seller
 Map<String, double> get taxBreakdown; bool get isCalculatingShipping; String? get shippingError; bool get isProcessing; String? get idempotencyKey; String? get checkoutError; String get paymentProvider; String? get couponCode; int get couponDiscountCents; bool get isCouponLoading; String? get couponError;/// F-77: Server-calculated tax amount in cents returned from create_checkout_session.
/// Use this for display in the review screen instead of client-side estimates.
 int get serverTaxAmountCents;/// F-74: Indicates if any item in the cart is shipped from outside Canada.
 bool get hasInternationalItems;
/// Create a copy of CheckoutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutStateCopyWith<CheckoutState> get copyWith => _$CheckoutStateCopyWithImpl<CheckoutState>(this as CheckoutState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutState&&(identical(other.address, address) || other.address == address)&&(identical(other.baseShippingCost, baseShippingCost) || other.baseShippingCost == baseShippingCost)&&const DeepCollectionEquality().equals(other.sellerShippingCosts, sellerShippingCosts)&&const DeepCollectionEquality().equals(other.sellerNames, sellerNames)&&(identical(other.deliverySpeed, deliverySpeed) || other.deliverySpeed == deliverySpeed)&&const DeepCollectionEquality().equals(other.availableDeliverySpeeds, availableDeliverySpeeds)&&(identical(other.isLocalDelivery, isLocalDelivery) || other.isLocalDelivery == isLocalDelivery)&&const DeepCollectionEquality().equals(other.taxBreakdown, taxBreakdown)&&(identical(other.isCalculatingShipping, isCalculatingShipping) || other.isCalculatingShipping == isCalculatingShipping)&&(identical(other.shippingError, shippingError) || other.shippingError == shippingError)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.checkoutError, checkoutError) || other.checkoutError == checkoutError)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.couponCode, couponCode) || other.couponCode == couponCode)&&(identical(other.couponDiscountCents, couponDiscountCents) || other.couponDiscountCents == couponDiscountCents)&&(identical(other.isCouponLoading, isCouponLoading) || other.isCouponLoading == isCouponLoading)&&(identical(other.couponError, couponError) || other.couponError == couponError)&&(identical(other.serverTaxAmountCents, serverTaxAmountCents) || other.serverTaxAmountCents == serverTaxAmountCents)&&(identical(other.hasInternationalItems, hasInternationalItems) || other.hasInternationalItems == hasInternationalItems));
}


@override
int get hashCode => Object.hashAll([runtimeType,address,baseShippingCost,const DeepCollectionEquality().hash(sellerShippingCosts),const DeepCollectionEquality().hash(sellerNames),deliverySpeed,const DeepCollectionEquality().hash(availableDeliverySpeeds),isLocalDelivery,const DeepCollectionEquality().hash(taxBreakdown),isCalculatingShipping,shippingError,isProcessing,idempotencyKey,checkoutError,paymentProvider,couponCode,couponDiscountCents,isCouponLoading,couponError,serverTaxAmountCents,hasInternationalItems]);

@override
String toString() {
  return 'CheckoutState(address: $address, baseShippingCost: $baseShippingCost, sellerShippingCosts: $sellerShippingCosts, sellerNames: $sellerNames, deliverySpeed: $deliverySpeed, availableDeliverySpeeds: $availableDeliverySpeeds, isLocalDelivery: $isLocalDelivery, taxBreakdown: $taxBreakdown, isCalculatingShipping: $isCalculatingShipping, shippingError: $shippingError, isProcessing: $isProcessing, idempotencyKey: $idempotencyKey, checkoutError: $checkoutError, paymentProvider: $paymentProvider, couponCode: $couponCode, couponDiscountCents: $couponDiscountCents, isCouponLoading: $isCouponLoading, couponError: $couponError, serverTaxAmountCents: $serverTaxAmountCents, hasInternationalItems: $hasInternationalItems)';
}


}

/// @nodoc
abstract mixin class $CheckoutStateCopyWith<$Res>  {
  factory $CheckoutStateCopyWith(CheckoutState value, $Res Function(CheckoutState) _then) = _$CheckoutStateCopyWithImpl;
@useResult
$Res call({
 Address? address, double baseShippingCost, Map<String, double> sellerShippingCosts, Map<String, String> sellerNames, DeliverySpeed deliverySpeed, List<DeliverySpeed> availableDeliverySpeeds, bool isLocalDelivery, Map<String, double> taxBreakdown, bool isCalculatingShipping, String? shippingError, bool isProcessing, String? idempotencyKey, String? checkoutError, String paymentProvider, String? couponCode, int couponDiscountCents, bool isCouponLoading, String? couponError, int serverTaxAmountCents, bool hasInternationalItems
});




}
/// @nodoc
class _$CheckoutStateCopyWithImpl<$Res>
    implements $CheckoutStateCopyWith<$Res> {
  _$CheckoutStateCopyWithImpl(this._self, this._then);

  final CheckoutState _self;
  final $Res Function(CheckoutState) _then;

/// Create a copy of CheckoutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? address = freezed,Object? baseShippingCost = null,Object? sellerShippingCosts = null,Object? sellerNames = null,Object? deliverySpeed = null,Object? availableDeliverySpeeds = null,Object? isLocalDelivery = null,Object? taxBreakdown = null,Object? isCalculatingShipping = null,Object? shippingError = freezed,Object? isProcessing = null,Object? idempotencyKey = freezed,Object? checkoutError = freezed,Object? paymentProvider = null,Object? couponCode = freezed,Object? couponDiscountCents = null,Object? isCouponLoading = null,Object? couponError = freezed,Object? serverTaxAmountCents = null,Object? hasInternationalItems = null,}) {
  return _then(_self.copyWith(
address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,baseShippingCost: null == baseShippingCost ? _self.baseShippingCost : baseShippingCost // ignore: cast_nullable_to_non_nullable
as double,sellerShippingCosts: null == sellerShippingCosts ? _self.sellerShippingCosts : sellerShippingCosts // ignore: cast_nullable_to_non_nullable
as Map<String, double>,sellerNames: null == sellerNames ? _self.sellerNames : sellerNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,deliverySpeed: null == deliverySpeed ? _self.deliverySpeed : deliverySpeed // ignore: cast_nullable_to_non_nullable
as DeliverySpeed,availableDeliverySpeeds: null == availableDeliverySpeeds ? _self.availableDeliverySpeeds : availableDeliverySpeeds // ignore: cast_nullable_to_non_nullable
as List<DeliverySpeed>,isLocalDelivery: null == isLocalDelivery ? _self.isLocalDelivery : isLocalDelivery // ignore: cast_nullable_to_non_nullable
as bool,taxBreakdown: null == taxBreakdown ? _self.taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,isCalculatingShipping: null == isCalculatingShipping ? _self.isCalculatingShipping : isCalculatingShipping // ignore: cast_nullable_to_non_nullable
as bool,shippingError: freezed == shippingError ? _self.shippingError : shippingError // ignore: cast_nullable_to_non_nullable
as String?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,checkoutError: freezed == checkoutError ? _self.checkoutError : checkoutError // ignore: cast_nullable_to_non_nullable
as String?,paymentProvider: null == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String,couponCode: freezed == couponCode ? _self.couponCode : couponCode // ignore: cast_nullable_to_non_nullable
as String?,couponDiscountCents: null == couponDiscountCents ? _self.couponDiscountCents : couponDiscountCents // ignore: cast_nullable_to_non_nullable
as int,isCouponLoading: null == isCouponLoading ? _self.isCouponLoading : isCouponLoading // ignore: cast_nullable_to_non_nullable
as bool,couponError: freezed == couponError ? _self.couponError : couponError // ignore: cast_nullable_to_non_nullable
as String?,serverTaxAmountCents: null == serverTaxAmountCents ? _self.serverTaxAmountCents : serverTaxAmountCents // ignore: cast_nullable_to_non_nullable
as int,hasInternationalItems: null == hasInternationalItems ? _self.hasInternationalItems : hasInternationalItems // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutState].
extension CheckoutStatePatterns on CheckoutState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutState value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutState value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Address? address,  double baseShippingCost,  Map<String, double> sellerShippingCosts,  Map<String, String> sellerNames,  DeliverySpeed deliverySpeed,  List<DeliverySpeed> availableDeliverySpeeds,  bool isLocalDelivery,  Map<String, double> taxBreakdown,  bool isCalculatingShipping,  String? shippingError,  bool isProcessing,  String? idempotencyKey,  String? checkoutError,  String paymentProvider,  String? couponCode,  int couponDiscountCents,  bool isCouponLoading,  String? couponError,  int serverTaxAmountCents,  bool hasInternationalItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutState() when $default != null:
return $default(_that.address,_that.baseShippingCost,_that.sellerShippingCosts,_that.sellerNames,_that.deliverySpeed,_that.availableDeliverySpeeds,_that.isLocalDelivery,_that.taxBreakdown,_that.isCalculatingShipping,_that.shippingError,_that.isProcessing,_that.idempotencyKey,_that.checkoutError,_that.paymentProvider,_that.couponCode,_that.couponDiscountCents,_that.isCouponLoading,_that.couponError,_that.serverTaxAmountCents,_that.hasInternationalItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Address? address,  double baseShippingCost,  Map<String, double> sellerShippingCosts,  Map<String, String> sellerNames,  DeliverySpeed deliverySpeed,  List<DeliverySpeed> availableDeliverySpeeds,  bool isLocalDelivery,  Map<String, double> taxBreakdown,  bool isCalculatingShipping,  String? shippingError,  bool isProcessing,  String? idempotencyKey,  String? checkoutError,  String paymentProvider,  String? couponCode,  int couponDiscountCents,  bool isCouponLoading,  String? couponError,  int serverTaxAmountCents,  bool hasInternationalItems)  $default,) {final _that = this;
switch (_that) {
case _CheckoutState():
return $default(_that.address,_that.baseShippingCost,_that.sellerShippingCosts,_that.sellerNames,_that.deliverySpeed,_that.availableDeliverySpeeds,_that.isLocalDelivery,_that.taxBreakdown,_that.isCalculatingShipping,_that.shippingError,_that.isProcessing,_that.idempotencyKey,_that.checkoutError,_that.paymentProvider,_that.couponCode,_that.couponDiscountCents,_that.isCouponLoading,_that.couponError,_that.serverTaxAmountCents,_that.hasInternationalItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Address? address,  double baseShippingCost,  Map<String, double> sellerShippingCosts,  Map<String, String> sellerNames,  DeliverySpeed deliverySpeed,  List<DeliverySpeed> availableDeliverySpeeds,  bool isLocalDelivery,  Map<String, double> taxBreakdown,  bool isCalculatingShipping,  String? shippingError,  bool isProcessing,  String? idempotencyKey,  String? checkoutError,  String paymentProvider,  String? couponCode,  int couponDiscountCents,  bool isCouponLoading,  String? couponError,  int serverTaxAmountCents,  bool hasInternationalItems)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutState() when $default != null:
return $default(_that.address,_that.baseShippingCost,_that.sellerShippingCosts,_that.sellerNames,_that.deliverySpeed,_that.availableDeliverySpeeds,_that.isLocalDelivery,_that.taxBreakdown,_that.isCalculatingShipping,_that.shippingError,_that.isProcessing,_that.idempotencyKey,_that.checkoutError,_that.paymentProvider,_that.couponCode,_that.couponDiscountCents,_that.isCouponLoading,_that.couponError,_that.serverTaxAmountCents,_that.hasInternationalItems);case _:
  return null;

}
}

}

/// @nodoc


class _CheckoutState extends CheckoutState {
  const _CheckoutState({this.address, this.baseShippingCost = 0.0, final  Map<String, double> sellerShippingCosts = const {}, final  Map<String, String> sellerNames = const {}, this.deliverySpeed = DeliverySpeed.standard, final  List<DeliverySpeed> availableDeliverySpeeds = const [DeliverySpeed.standard], this.isLocalDelivery = false, final  Map<String, double> taxBreakdown = const {}, this.isCalculatingShipping = false, this.shippingError, this.isProcessing = false, this.idempotencyKey, this.checkoutError, this.paymentProvider = PaymentProviderValues.stripe, this.couponCode, this.couponDiscountCents = 0, this.isCouponLoading = false, this.couponError, this.serverTaxAmountCents = 0, this.hasInternationalItems = false}): _sellerShippingCosts = sellerShippingCosts,_sellerNames = sellerNames,_availableDeliverySpeeds = availableDeliverySpeeds,_taxBreakdown = taxBreakdown,super._();
  

@override final  Address? address;
@override@JsonKey() final  double baseShippingCost;
// Base shipping before delivery speed surcharge
 final  Map<String, double> _sellerShippingCosts;
// Base shipping before delivery speed surcharge
@override@JsonKey() Map<String, double> get sellerShippingCosts {
  if (_sellerShippingCosts is EqualUnmodifiableMapView) return _sellerShippingCosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sellerShippingCosts);
}

// Breakdown per seller
 final  Map<String, String> _sellerNames;
// Breakdown per seller
@override@JsonKey() Map<String, String> get sellerNames {
  if (_sellerNames is EqualUnmodifiableMapView) return _sellerNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sellerNames);
}

// Seller names for display
@override@JsonKey() final  DeliverySpeed deliverySpeed;
 final  List<DeliverySpeed> _availableDeliverySpeeds;
@override@JsonKey() List<DeliverySpeed> get availableDeliverySpeeds {
  if (_availableDeliverySpeeds is EqualUnmodifiableListView) return _availableDeliverySpeeds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableDeliverySpeeds);
}

@override@JsonKey() final  bool isLocalDelivery;
// Within ~50km of seller
 final  Map<String, double> _taxBreakdown;
// Within ~50km of seller
@override@JsonKey() Map<String, double> get taxBreakdown {
  if (_taxBreakdown is EqualUnmodifiableMapView) return _taxBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_taxBreakdown);
}

@override@JsonKey() final  bool isCalculatingShipping;
@override final  String? shippingError;
@override@JsonKey() final  bool isProcessing;
@override final  String? idempotencyKey;
@override final  String? checkoutError;
@override@JsonKey() final  String paymentProvider;
@override final  String? couponCode;
@override@JsonKey() final  int couponDiscountCents;
@override@JsonKey() final  bool isCouponLoading;
@override final  String? couponError;
/// F-77: Server-calculated tax amount in cents returned from create_checkout_session.
/// Use this for display in the review screen instead of client-side estimates.
@override@JsonKey() final  int serverTaxAmountCents;
/// F-74: Indicates if any item in the cart is shipped from outside Canada.
@override@JsonKey() final  bool hasInternationalItems;

/// Create a copy of CheckoutState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutStateCopyWith<_CheckoutState> get copyWith => __$CheckoutStateCopyWithImpl<_CheckoutState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutState&&(identical(other.address, address) || other.address == address)&&(identical(other.baseShippingCost, baseShippingCost) || other.baseShippingCost == baseShippingCost)&&const DeepCollectionEquality().equals(other._sellerShippingCosts, _sellerShippingCosts)&&const DeepCollectionEquality().equals(other._sellerNames, _sellerNames)&&(identical(other.deliverySpeed, deliverySpeed) || other.deliverySpeed == deliverySpeed)&&const DeepCollectionEquality().equals(other._availableDeliverySpeeds, _availableDeliverySpeeds)&&(identical(other.isLocalDelivery, isLocalDelivery) || other.isLocalDelivery == isLocalDelivery)&&const DeepCollectionEquality().equals(other._taxBreakdown, _taxBreakdown)&&(identical(other.isCalculatingShipping, isCalculatingShipping) || other.isCalculatingShipping == isCalculatingShipping)&&(identical(other.shippingError, shippingError) || other.shippingError == shippingError)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.checkoutError, checkoutError) || other.checkoutError == checkoutError)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider)&&(identical(other.couponCode, couponCode) || other.couponCode == couponCode)&&(identical(other.couponDiscountCents, couponDiscountCents) || other.couponDiscountCents == couponDiscountCents)&&(identical(other.isCouponLoading, isCouponLoading) || other.isCouponLoading == isCouponLoading)&&(identical(other.couponError, couponError) || other.couponError == couponError)&&(identical(other.serverTaxAmountCents, serverTaxAmountCents) || other.serverTaxAmountCents == serverTaxAmountCents)&&(identical(other.hasInternationalItems, hasInternationalItems) || other.hasInternationalItems == hasInternationalItems));
}


@override
int get hashCode => Object.hashAll([runtimeType,address,baseShippingCost,const DeepCollectionEquality().hash(_sellerShippingCosts),const DeepCollectionEquality().hash(_sellerNames),deliverySpeed,const DeepCollectionEquality().hash(_availableDeliverySpeeds),isLocalDelivery,const DeepCollectionEquality().hash(_taxBreakdown),isCalculatingShipping,shippingError,isProcessing,idempotencyKey,checkoutError,paymentProvider,couponCode,couponDiscountCents,isCouponLoading,couponError,serverTaxAmountCents,hasInternationalItems]);

@override
String toString() {
  return 'CheckoutState(address: $address, baseShippingCost: $baseShippingCost, sellerShippingCosts: $sellerShippingCosts, sellerNames: $sellerNames, deliverySpeed: $deliverySpeed, availableDeliverySpeeds: $availableDeliverySpeeds, isLocalDelivery: $isLocalDelivery, taxBreakdown: $taxBreakdown, isCalculatingShipping: $isCalculatingShipping, shippingError: $shippingError, isProcessing: $isProcessing, idempotencyKey: $idempotencyKey, checkoutError: $checkoutError, paymentProvider: $paymentProvider, couponCode: $couponCode, couponDiscountCents: $couponDiscountCents, isCouponLoading: $isCouponLoading, couponError: $couponError, serverTaxAmountCents: $serverTaxAmountCents, hasInternationalItems: $hasInternationalItems)';
}


}

/// @nodoc
abstract mixin class _$CheckoutStateCopyWith<$Res> implements $CheckoutStateCopyWith<$Res> {
  factory _$CheckoutStateCopyWith(_CheckoutState value, $Res Function(_CheckoutState) _then) = __$CheckoutStateCopyWithImpl;
@override @useResult
$Res call({
 Address? address, double baseShippingCost, Map<String, double> sellerShippingCosts, Map<String, String> sellerNames, DeliverySpeed deliverySpeed, List<DeliverySpeed> availableDeliverySpeeds, bool isLocalDelivery, Map<String, double> taxBreakdown, bool isCalculatingShipping, String? shippingError, bool isProcessing, String? idempotencyKey, String? checkoutError, String paymentProvider, String? couponCode, int couponDiscountCents, bool isCouponLoading, String? couponError, int serverTaxAmountCents, bool hasInternationalItems
});




}
/// @nodoc
class __$CheckoutStateCopyWithImpl<$Res>
    implements _$CheckoutStateCopyWith<$Res> {
  __$CheckoutStateCopyWithImpl(this._self, this._then);

  final _CheckoutState _self;
  final $Res Function(_CheckoutState) _then;

/// Create a copy of CheckoutState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? address = freezed,Object? baseShippingCost = null,Object? sellerShippingCosts = null,Object? sellerNames = null,Object? deliverySpeed = null,Object? availableDeliverySpeeds = null,Object? isLocalDelivery = null,Object? taxBreakdown = null,Object? isCalculatingShipping = null,Object? shippingError = freezed,Object? isProcessing = null,Object? idempotencyKey = freezed,Object? checkoutError = freezed,Object? paymentProvider = null,Object? couponCode = freezed,Object? couponDiscountCents = null,Object? isCouponLoading = null,Object? couponError = freezed,Object? serverTaxAmountCents = null,Object? hasInternationalItems = null,}) {
  return _then(_CheckoutState(
address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,baseShippingCost: null == baseShippingCost ? _self.baseShippingCost : baseShippingCost // ignore: cast_nullable_to_non_nullable
as double,sellerShippingCosts: null == sellerShippingCosts ? _self._sellerShippingCosts : sellerShippingCosts // ignore: cast_nullable_to_non_nullable
as Map<String, double>,sellerNames: null == sellerNames ? _self._sellerNames : sellerNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,deliverySpeed: null == deliverySpeed ? _self.deliverySpeed : deliverySpeed // ignore: cast_nullable_to_non_nullable
as DeliverySpeed,availableDeliverySpeeds: null == availableDeliverySpeeds ? _self._availableDeliverySpeeds : availableDeliverySpeeds // ignore: cast_nullable_to_non_nullable
as List<DeliverySpeed>,isLocalDelivery: null == isLocalDelivery ? _self.isLocalDelivery : isLocalDelivery // ignore: cast_nullable_to_non_nullable
as bool,taxBreakdown: null == taxBreakdown ? _self._taxBreakdown : taxBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, double>,isCalculatingShipping: null == isCalculatingShipping ? _self.isCalculatingShipping : isCalculatingShipping // ignore: cast_nullable_to_non_nullable
as bool,shippingError: freezed == shippingError ? _self.shippingError : shippingError // ignore: cast_nullable_to_non_nullable
as String?,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,checkoutError: freezed == checkoutError ? _self.checkoutError : checkoutError // ignore: cast_nullable_to_non_nullable
as String?,paymentProvider: null == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String,couponCode: freezed == couponCode ? _self.couponCode : couponCode // ignore: cast_nullable_to_non_nullable
as String?,couponDiscountCents: null == couponDiscountCents ? _self.couponDiscountCents : couponDiscountCents // ignore: cast_nullable_to_non_nullable
as int,isCouponLoading: null == isCouponLoading ? _self.isCouponLoading : isCouponLoading // ignore: cast_nullable_to_non_nullable
as bool,couponError: freezed == couponError ? _self.couponError : couponError // ignore: cast_nullable_to_non_nullable
as String?,serverTaxAmountCents: null == serverTaxAmountCents ? _self.serverTaxAmountCents : serverTaxAmountCents // ignore: cast_nullable_to_non_nullable
as int,hasInternationalItems: null == hasInternationalItems ? _self.hasInternationalItems : hasInternationalItems // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
