// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductDetailState {

 int get quantity; int get currentImageIndex; Map<String, String> get selectedOptions; String? get selectedVariantId; SellerMetrics? get sellerMetrics; bool get sellerMetricsLoading;
/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDetailStateCopyWith<ProductDetailState> get copyWith => _$ProductDetailStateCopyWithImpl<ProductDetailState>(this as ProductDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetailState&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currentImageIndex, currentImageIndex) || other.currentImageIndex == currentImageIndex)&&const DeepCollectionEquality().equals(other.selectedOptions, selectedOptions)&&(identical(other.selectedVariantId, selectedVariantId) || other.selectedVariantId == selectedVariantId)&&(identical(other.sellerMetrics, sellerMetrics) || other.sellerMetrics == sellerMetrics)&&(identical(other.sellerMetricsLoading, sellerMetricsLoading) || other.sellerMetricsLoading == sellerMetricsLoading));
}


@override
int get hashCode => Object.hash(runtimeType,quantity,currentImageIndex,const DeepCollectionEquality().hash(selectedOptions),selectedVariantId,sellerMetrics,sellerMetricsLoading);

@override
String toString() {
  return 'ProductDetailState(quantity: $quantity, currentImageIndex: $currentImageIndex, selectedOptions: $selectedOptions, selectedVariantId: $selectedVariantId, sellerMetrics: $sellerMetrics, sellerMetricsLoading: $sellerMetricsLoading)';
}


}

/// @nodoc
abstract mixin class $ProductDetailStateCopyWith<$Res>  {
  factory $ProductDetailStateCopyWith(ProductDetailState value, $Res Function(ProductDetailState) _then) = _$ProductDetailStateCopyWithImpl;
@useResult
$Res call({
 int quantity, int currentImageIndex, Map<String, String> selectedOptions, String? selectedVariantId, SellerMetrics? sellerMetrics, bool sellerMetricsLoading
});




}
/// @nodoc
class _$ProductDetailStateCopyWithImpl<$Res>
    implements $ProductDetailStateCopyWith<$Res> {
  _$ProductDetailStateCopyWithImpl(this._self, this._then);

  final ProductDetailState _self;
  final $Res Function(ProductDetailState) _then;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quantity = null,Object? currentImageIndex = null,Object? selectedOptions = null,Object? selectedVariantId = freezed,Object? sellerMetrics = freezed,Object? sellerMetricsLoading = null,}) {
  return _then(_self.copyWith(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,currentImageIndex: null == currentImageIndex ? _self.currentImageIndex : currentImageIndex // ignore: cast_nullable_to_non_nullable
as int,selectedOptions: null == selectedOptions ? _self.selectedOptions : selectedOptions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,selectedVariantId: freezed == selectedVariantId ? _self.selectedVariantId : selectedVariantId // ignore: cast_nullable_to_non_nullable
as String?,sellerMetrics: freezed == sellerMetrics ? _self.sellerMetrics : sellerMetrics // ignore: cast_nullable_to_non_nullable
as SellerMetrics?,sellerMetricsLoading: null == sellerMetricsLoading ? _self.sellerMetricsLoading : sellerMetricsLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductDetailState].
extension ProductDetailStatePatterns on ProductDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductDetailState value)  $default,){
final _that = this;
switch (_that) {
case _ProductDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _ProductDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int quantity,  int currentImageIndex,  Map<String, String> selectedOptions,  String? selectedVariantId,  SellerMetrics? sellerMetrics,  bool sellerMetricsLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductDetailState() when $default != null:
return $default(_that.quantity,_that.currentImageIndex,_that.selectedOptions,_that.selectedVariantId,_that.sellerMetrics,_that.sellerMetricsLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int quantity,  int currentImageIndex,  Map<String, String> selectedOptions,  String? selectedVariantId,  SellerMetrics? sellerMetrics,  bool sellerMetricsLoading)  $default,) {final _that = this;
switch (_that) {
case _ProductDetailState():
return $default(_that.quantity,_that.currentImageIndex,_that.selectedOptions,_that.selectedVariantId,_that.sellerMetrics,_that.sellerMetricsLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int quantity,  int currentImageIndex,  Map<String, String> selectedOptions,  String? selectedVariantId,  SellerMetrics? sellerMetrics,  bool sellerMetricsLoading)?  $default,) {final _that = this;
switch (_that) {
case _ProductDetailState() when $default != null:
return $default(_that.quantity,_that.currentImageIndex,_that.selectedOptions,_that.selectedVariantId,_that.sellerMetrics,_that.sellerMetricsLoading);case _:
  return null;

}
}

}

/// @nodoc


class _ProductDetailState implements ProductDetailState {
  const _ProductDetailState({this.quantity = 1, this.currentImageIndex = 0, final  Map<String, String> selectedOptions = const {}, this.selectedVariantId, this.sellerMetrics, this.sellerMetricsLoading = false}): _selectedOptions = selectedOptions;
  

@override@JsonKey() final  int quantity;
@override@JsonKey() final  int currentImageIndex;
 final  Map<String, String> _selectedOptions;
@override@JsonKey() Map<String, String> get selectedOptions {
  if (_selectedOptions is EqualUnmodifiableMapView) return _selectedOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectedOptions);
}

@override final  String? selectedVariantId;
@override final  SellerMetrics? sellerMetrics;
@override@JsonKey() final  bool sellerMetricsLoading;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductDetailStateCopyWith<_ProductDetailState> get copyWith => __$ProductDetailStateCopyWithImpl<_ProductDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductDetailState&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currentImageIndex, currentImageIndex) || other.currentImageIndex == currentImageIndex)&&const DeepCollectionEquality().equals(other._selectedOptions, _selectedOptions)&&(identical(other.selectedVariantId, selectedVariantId) || other.selectedVariantId == selectedVariantId)&&(identical(other.sellerMetrics, sellerMetrics) || other.sellerMetrics == sellerMetrics)&&(identical(other.sellerMetricsLoading, sellerMetricsLoading) || other.sellerMetricsLoading == sellerMetricsLoading));
}


@override
int get hashCode => Object.hash(runtimeType,quantity,currentImageIndex,const DeepCollectionEquality().hash(_selectedOptions),selectedVariantId,sellerMetrics,sellerMetricsLoading);

@override
String toString() {
  return 'ProductDetailState(quantity: $quantity, currentImageIndex: $currentImageIndex, selectedOptions: $selectedOptions, selectedVariantId: $selectedVariantId, sellerMetrics: $sellerMetrics, sellerMetricsLoading: $sellerMetricsLoading)';
}


}

/// @nodoc
abstract mixin class _$ProductDetailStateCopyWith<$Res> implements $ProductDetailStateCopyWith<$Res> {
  factory _$ProductDetailStateCopyWith(_ProductDetailState value, $Res Function(_ProductDetailState) _then) = __$ProductDetailStateCopyWithImpl;
@override @useResult
$Res call({
 int quantity, int currentImageIndex, Map<String, String> selectedOptions, String? selectedVariantId, SellerMetrics? sellerMetrics, bool sellerMetricsLoading
});




}
/// @nodoc
class __$ProductDetailStateCopyWithImpl<$Res>
    implements _$ProductDetailStateCopyWith<$Res> {
  __$ProductDetailStateCopyWithImpl(this._self, this._then);

  final _ProductDetailState _self;
  final $Res Function(_ProductDetailState) _then;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quantity = null,Object? currentImageIndex = null,Object? selectedOptions = null,Object? selectedVariantId = freezed,Object? sellerMetrics = freezed,Object? sellerMetricsLoading = null,}) {
  return _then(_ProductDetailState(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,currentImageIndex: null == currentImageIndex ? _self.currentImageIndex : currentImageIndex // ignore: cast_nullable_to_non_nullable
as int,selectedOptions: null == selectedOptions ? _self._selectedOptions : selectedOptions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,selectedVariantId: freezed == selectedVariantId ? _self.selectedVariantId : selectedVariantId // ignore: cast_nullable_to_non_nullable
as String?,sellerMetrics: freezed == sellerMetrics ? _self.sellerMetrics : sellerMetrics // ignore: cast_nullable_to_non_nullable
as SellerMetrics?,sellerMetricsLoading: null == sellerMetricsLoading ? _self.sellerMetricsLoading : sellerMetricsLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
