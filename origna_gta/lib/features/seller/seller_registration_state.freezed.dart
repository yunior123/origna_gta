// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seller_registration_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SellerRegistrationState {

 bool get isLoading; String? get error; String? get successMessage; String get paymentProvider;
/// Create a copy of SellerRegistrationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerRegistrationStateCopyWith<SellerRegistrationState> get copyWith => _$SellerRegistrationStateCopyWithImpl<SellerRegistrationState>(this as SellerRegistrationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerRegistrationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,successMessage,paymentProvider);

@override
String toString() {
  return 'SellerRegistrationState(isLoading: $isLoading, error: $error, successMessage: $successMessage, paymentProvider: $paymentProvider)';
}


}

/// @nodoc
abstract mixin class $SellerRegistrationStateCopyWith<$Res>  {
  factory $SellerRegistrationStateCopyWith(SellerRegistrationState value, $Res Function(SellerRegistrationState) _then) = _$SellerRegistrationStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? error, String? successMessage, String paymentProvider
});




}
/// @nodoc
class _$SellerRegistrationStateCopyWithImpl<$Res>
    implements $SellerRegistrationStateCopyWith<$Res> {
  _$SellerRegistrationStateCopyWithImpl(this._self, this._then);

  final SellerRegistrationState _self;
  final $Res Function(SellerRegistrationState) _then;

/// Create a copy of SellerRegistrationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? error = freezed,Object? successMessage = freezed,Object? paymentProvider = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,paymentProvider: null == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerRegistrationState].
extension SellerRegistrationStatePatterns on SellerRegistrationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerRegistrationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerRegistrationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerRegistrationState value)  $default,){
final _that = this;
switch (_that) {
case _SellerRegistrationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerRegistrationState value)?  $default,){
final _that = this;
switch (_that) {
case _SellerRegistrationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  String? successMessage,  String paymentProvider)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerRegistrationState() when $default != null:
return $default(_that.isLoading,_that.error,_that.successMessage,_that.paymentProvider);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  String? successMessage,  String paymentProvider)  $default,) {final _that = this;
switch (_that) {
case _SellerRegistrationState():
return $default(_that.isLoading,_that.error,_that.successMessage,_that.paymentProvider);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? error,  String? successMessage,  String paymentProvider)?  $default,) {final _that = this;
switch (_that) {
case _SellerRegistrationState() when $default != null:
return $default(_that.isLoading,_that.error,_that.successMessage,_that.paymentProvider);case _:
  return null;

}
}

}

/// @nodoc


class _SellerRegistrationState implements SellerRegistrationState {
  const _SellerRegistrationState({this.isLoading = false, this.error, this.successMessage, this.paymentProvider = PaymentProviderValues.stripe});
  

@override@JsonKey() final  bool isLoading;
@override final  String? error;
@override final  String? successMessage;
@override@JsonKey() final  String paymentProvider;

/// Create a copy of SellerRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerRegistrationStateCopyWith<_SellerRegistrationState> get copyWith => __$SellerRegistrationStateCopyWithImpl<_SellerRegistrationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerRegistrationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.paymentProvider, paymentProvider) || other.paymentProvider == paymentProvider));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,successMessage,paymentProvider);

@override
String toString() {
  return 'SellerRegistrationState(isLoading: $isLoading, error: $error, successMessage: $successMessage, paymentProvider: $paymentProvider)';
}


}

/// @nodoc
abstract mixin class _$SellerRegistrationStateCopyWith<$Res> implements $SellerRegistrationStateCopyWith<$Res> {
  factory _$SellerRegistrationStateCopyWith(_SellerRegistrationState value, $Res Function(_SellerRegistrationState) _then) = __$SellerRegistrationStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? error, String? successMessage, String paymentProvider
});




}
/// @nodoc
class __$SellerRegistrationStateCopyWithImpl<$Res>
    implements _$SellerRegistrationStateCopyWith<$Res> {
  __$SellerRegistrationStateCopyWithImpl(this._self, this._then);

  final _SellerRegistrationState _self;
  final $Res Function(_SellerRegistrationState) _then;

/// Create a copy of SellerRegistrationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? error = freezed,Object? successMessage = freezed,Object? paymentProvider = null,}) {
  return _then(_SellerRegistrationState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,paymentProvider: null == paymentProvider ? _self.paymentProvider : paymentProvider // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
