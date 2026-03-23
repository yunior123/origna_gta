// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'return_request_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReturnRequestState {

 bool get isLoading; bool get isSuccess; String? get errorMessage;
/// Create a copy of ReturnRequestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReturnRequestStateCopyWith<ReturnRequestState> get copyWith => _$ReturnRequestStateCopyWithImpl<ReturnRequestState>(this as ReturnRequestState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReturnRequestState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'ReturnRequestState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ReturnRequestStateCopyWith<$Res>  {
  factory $ReturnRequestStateCopyWith(ReturnRequestState value, $Res Function(ReturnRequestState) _then) = _$ReturnRequestStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class _$ReturnRequestStateCopyWithImpl<$Res>
    implements $ReturnRequestStateCopyWith<$Res> {
  _$ReturnRequestStateCopyWithImpl(this._self, this._then);

  final ReturnRequestState _self;
  final $Res Function(ReturnRequestState) _then;

/// Create a copy of ReturnRequestState
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


/// Adds pattern-matching-related methods to [ReturnRequestState].
extension ReturnRequestStatePatterns on ReturnRequestState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReturnRequestState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReturnRequestState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReturnRequestState value)  $default,){
final _that = this;
switch (_that) {
case _ReturnRequestState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReturnRequestState value)?  $default,){
final _that = this;
switch (_that) {
case _ReturnRequestState() when $default != null:
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
case _ReturnRequestState() when $default != null:
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
case _ReturnRequestState():
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
case _ReturnRequestState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ReturnRequestState implements ReturnRequestState {
  const _ReturnRequestState({this.isLoading = false, this.isSuccess = false, this.errorMessage});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;

/// Create a copy of ReturnRequestState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReturnRequestStateCopyWith<_ReturnRequestState> get copyWith => __$ReturnRequestStateCopyWithImpl<_ReturnRequestState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReturnRequestState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'ReturnRequestState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ReturnRequestStateCopyWith<$Res> implements $ReturnRequestStateCopyWith<$Res> {
  factory _$ReturnRequestStateCopyWith(_ReturnRequestState value, $Res Function(_ReturnRequestState) _then) = __$ReturnRequestStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class __$ReturnRequestStateCopyWithImpl<$Res>
    implements _$ReturnRequestStateCopyWith<$Res> {
  __$ReturnRequestStateCopyWithImpl(this._self, this._then);

  final _ReturnRequestState _self;
  final $Res Function(_ReturnRequestState) _then;

/// Create a copy of ReturnRequestState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_ReturnRequestState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
