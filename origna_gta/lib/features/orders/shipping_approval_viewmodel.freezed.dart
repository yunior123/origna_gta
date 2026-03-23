// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipping_approval_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShippingApprovalState {

 bool get isLoading; bool get isSuccess; String? get errorMessage;
/// Create a copy of ShippingApprovalState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShippingApprovalStateCopyWith<ShippingApprovalState> get copyWith => _$ShippingApprovalStateCopyWithImpl<ShippingApprovalState>(this as ShippingApprovalState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShippingApprovalState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'ShippingApprovalState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ShippingApprovalStateCopyWith<$Res>  {
  factory $ShippingApprovalStateCopyWith(ShippingApprovalState value, $Res Function(ShippingApprovalState) _then) = _$ShippingApprovalStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class _$ShippingApprovalStateCopyWithImpl<$Res>
    implements $ShippingApprovalStateCopyWith<$Res> {
  _$ShippingApprovalStateCopyWithImpl(this._self, this._then);

  final ShippingApprovalState _self;
  final $Res Function(ShippingApprovalState) _then;

/// Create a copy of ShippingApprovalState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShippingApprovalState].
extension ShippingApprovalStatePatterns on ShippingApprovalState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShippingApprovalState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShippingApprovalState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShippingApprovalState value)  $default,){
final _that = this;
switch (_that) {
case _ShippingApprovalState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShippingApprovalState value)?  $default,){
final _that = this;
switch (_that) {
case _ShippingApprovalState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShippingApprovalState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ShippingApprovalState():
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSuccess,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ShippingApprovalState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ShippingApprovalState implements ShippingApprovalState {
  const _ShippingApprovalState({this.isLoading = false, this.isSuccess = false, this.errorMessage});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;

/// Create a copy of ShippingApprovalState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShippingApprovalStateCopyWith<_ShippingApprovalState> get copyWith => __$ShippingApprovalStateCopyWithImpl<_ShippingApprovalState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShippingApprovalState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'ShippingApprovalState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ShippingApprovalStateCopyWith<$Res> implements $ShippingApprovalStateCopyWith<$Res> {
  factory _$ShippingApprovalStateCopyWith(_ShippingApprovalState value, $Res Function(_ShippingApprovalState) _then) = __$ShippingApprovalStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class __$ShippingApprovalStateCopyWithImpl<$Res>
    implements _$ShippingApprovalStateCopyWith<$Res> {
  __$ShippingApprovalStateCopyWithImpl(this._self, this._then);

  final _ShippingApprovalState _self;
  final $Res Function(_ShippingApprovalState) _then;

/// Create a copy of ShippingApprovalState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_ShippingApprovalState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
