// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_actions_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdminActionsState {

 bool get isLoading; bool get isSuccess; String? get errorMessage;
/// Create a copy of AdminActionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminActionsStateCopyWith<AdminActionsState> get copyWith => _$AdminActionsStateCopyWithImpl<AdminActionsState>(this as AdminActionsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminActionsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'AdminActionsState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AdminActionsStateCopyWith<$Res>  {
  factory $AdminActionsStateCopyWith(AdminActionsState value, $Res Function(AdminActionsState) _then) = _$AdminActionsStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class _$AdminActionsStateCopyWithImpl<$Res>
    implements $AdminActionsStateCopyWith<$Res> {
  _$AdminActionsStateCopyWithImpl(this._self, this._then);

  final AdminActionsState _self;
  final $Res Function(AdminActionsState) _then;

/// Create a copy of AdminActionsState
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


/// Adds pattern-matching-related methods to [AdminActionsState].
extension AdminActionsStatePatterns on AdminActionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminActionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminActionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminActionsState value)  $default,){
final _that = this;
switch (_that) {
case _AdminActionsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminActionsState value)?  $default,){
final _that = this;
switch (_that) {
case _AdminActionsState() when $default != null:
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
case _AdminActionsState() when $default != null:
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
case _AdminActionsState():
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
case _AdminActionsState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AdminActionsState implements AdminActionsState {
  const _AdminActionsState({this.isLoading = false, this.isSuccess = false, this.errorMessage});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;

/// Create a copy of AdminActionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminActionsStateCopyWith<_AdminActionsState> get copyWith => __$AdminActionsStateCopyWithImpl<_AdminActionsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminActionsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,errorMessage);

@override
String toString() {
  return 'AdminActionsState(isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AdminActionsStateCopyWith<$Res> implements $AdminActionsStateCopyWith<$Res> {
  factory _$AdminActionsStateCopyWith(_AdminActionsState value, $Res Function(_AdminActionsState) _then) = __$AdminActionsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class __$AdminActionsStateCopyWithImpl<$Res>
    implements _$AdminActionsStateCopyWith<$Res> {
  __$AdminActionsStateCopyWithImpl(this._self, this._then);

  final _AdminActionsState _self;
  final $Res Function(_AdminActionsState) _then;

/// Create a copy of AdminActionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_AdminActionsState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
