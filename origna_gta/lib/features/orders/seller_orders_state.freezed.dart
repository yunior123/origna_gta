// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seller_orders_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SellerOrdersState {

 bool get isLoading; String? get errorMessage; bool get isSuccess;
/// Create a copy of SellerOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerOrdersStateCopyWith<SellerOrdersState> get copyWith => _$SellerOrdersStateCopyWithImpl<SellerOrdersState>(this as SellerOrdersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerOrdersState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'SellerOrdersState(isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class $SellerOrdersStateCopyWith<$Res>  {
  factory $SellerOrdersStateCopyWith(SellerOrdersState value, $Res Function(SellerOrdersState) _then) = _$SellerOrdersStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? errorMessage, bool isSuccess
});




}
/// @nodoc
class _$SellerOrdersStateCopyWithImpl<$Res>
    implements $SellerOrdersStateCopyWith<$Res> {
  _$SellerOrdersStateCopyWithImpl(this._self, this._then);

  final SellerOrdersState _self;
  final $Res Function(SellerOrdersState) _then;

/// Create a copy of SellerOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerOrdersState].
extension SellerOrdersStatePatterns on SellerOrdersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerOrdersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerOrdersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerOrdersState value)  $default,){
final _that = this;
switch (_that) {
case _SellerOrdersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerOrdersState value)?  $default,){
final _that = this;
switch (_that) {
case _SellerOrdersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerOrdersState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  bool isSuccess)  $default,) {final _that = this;
switch (_that) {
case _SellerOrdersState():
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,) {final _that = this;
switch (_that) {
case _SellerOrdersState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _SellerOrdersState implements SellerOrdersState {
  const _SellerOrdersState({this.isLoading = false, this.errorMessage, this.isSuccess = false});
  

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  bool isSuccess;

/// Create a copy of SellerOrdersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerOrdersStateCopyWith<_SellerOrdersState> get copyWith => __$SellerOrdersStateCopyWithImpl<_SellerOrdersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerOrdersState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'SellerOrdersState(isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class _$SellerOrdersStateCopyWith<$Res> implements $SellerOrdersStateCopyWith<$Res> {
  factory _$SellerOrdersStateCopyWith(_SellerOrdersState value, $Res Function(_SellerOrdersState) _then) = __$SellerOrdersStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? errorMessage, bool isSuccess
});




}
/// @nodoc
class __$SellerOrdersStateCopyWithImpl<$Res>
    implements _$SellerOrdersStateCopyWith<$Res> {
  __$SellerOrdersStateCopyWithImpl(this._self, this._then);

  final _SellerOrdersState _self;
  final $Res Function(_SellerOrdersState) _then;

/// Create a copy of SellerOrdersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_SellerOrdersState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
