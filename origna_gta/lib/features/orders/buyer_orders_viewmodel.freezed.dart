// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buyer_orders_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BuyerOrdersState {

 bool get isLoading; bool get isSuccess; String? get errorMessage;/// The unique key (orderId_productId) of the item whose receipt is currently being confirmed.
 String? get confirmingItemId;
/// Create a copy of BuyerOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuyerOrdersStateCopyWith<BuyerOrdersState> get copyWith => _$BuyerOrdersStateCopyWithImpl<BuyerOrdersState>(this as BuyerOrdersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuyerOrdersState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.confirmingItemId, confirmingItemId) || other.confirmingItemId == confirmingItemId));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage,confirmingItemId);

@override
String toString() {
  return 'BuyerOrdersState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage, confirmingItemId: $confirmingItemId)';
}


}

/// @nodoc
abstract mixin class $BuyerOrdersStateCopyWith<$Res>  {
  factory $BuyerOrdersStateCopyWith(BuyerOrdersState value, $Res Function(BuyerOrdersState) _then) = _$BuyerOrdersStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage, String? confirmingItemId
});




}
/// @nodoc
class _$BuyerOrdersStateCopyWithImpl<$Res>
    implements $BuyerOrdersStateCopyWith<$Res> {
  _$BuyerOrdersStateCopyWithImpl(this._self, this._then);

  final BuyerOrdersState _self;
  final $Res Function(BuyerOrdersState) _then;

/// Create a copy of BuyerOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,Object? confirmingItemId = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,confirmingItemId: freezed == confirmingItemId ? _self.confirmingItemId : confirmingItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuyerOrdersState].
extension BuyerOrdersStatePatterns on BuyerOrdersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuyerOrdersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuyerOrdersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuyerOrdersState value)  $default,){
final _that = this;
switch (_that) {
case _BuyerOrdersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuyerOrdersState value)?  $default,){
final _that = this;
switch (_that) {
case _BuyerOrdersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? confirmingItemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuyerOrdersState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.confirmingItemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? confirmingItemId)  $default,) {final _that = this;
switch (_that) {
case _BuyerOrdersState():
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.confirmingItemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSuccess,  String? errorMessage,  String? confirmingItemId)?  $default,) {final _that = this;
switch (_that) {
case _BuyerOrdersState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage,_that.confirmingItemId);case _:
  return null;

}
}

}

/// @nodoc


class _BuyerOrdersState implements BuyerOrdersState {
  const _BuyerOrdersState({this.isLoading = false, this.isSuccess = false, this.errorMessage, this.confirmingItemId});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;
/// The unique key (orderId_productId) of the item whose receipt is currently being confirmed.
@override final  String? confirmingItemId;

/// Create a copy of BuyerOrdersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuyerOrdersStateCopyWith<_BuyerOrdersState> get copyWith => __$BuyerOrdersStateCopyWithImpl<_BuyerOrdersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuyerOrdersState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.confirmingItemId, confirmingItemId) || other.confirmingItemId == confirmingItemId));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage,confirmingItemId);

@override
String toString() {
  return 'BuyerOrdersState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage, confirmingItemId: $confirmingItemId)';
}


}

/// @nodoc
abstract mixin class _$BuyerOrdersStateCopyWith<$Res> implements $BuyerOrdersStateCopyWith<$Res> {
  factory _$BuyerOrdersStateCopyWith(_BuyerOrdersState value, $Res Function(_BuyerOrdersState) _then) = __$BuyerOrdersStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage, String? confirmingItemId
});




}
/// @nodoc
class __$BuyerOrdersStateCopyWithImpl<$Res>
    implements _$BuyerOrdersStateCopyWith<$Res> {
  __$BuyerOrdersStateCopyWithImpl(this._self, this._then);

  final _BuyerOrdersState _self;
  final $Res Function(_BuyerOrdersState) _then;

/// Create a copy of BuyerOrdersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,Object? confirmingItemId = freezed,}) {
  return _then(_BuyerOrdersState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,confirmingItemId: freezed == confirmingItemId ? _self.confirmingItemId : confirmingItemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
