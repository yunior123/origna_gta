// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginState {

 bool get isLoading; bool get isLogin; bool get obscurePassword; bool get acceptedTerms; bool get marketingOptIn;// CASL/Loi 25: separate marketing consent
 String? get errorMessage; String? get successMessage; bool get isSuccess; bool get mfaRequired; String? get challengeToken;
/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginStateCopyWith<LoginState> get copyWith => _$LoginStateCopyWithImpl<LoginState>(this as LoginState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLogin, isLogin) || other.isLogin == isLogin)&&(identical(other.obscurePassword, obscurePassword) || other.obscurePassword == obscurePassword)&&(identical(other.acceptedTerms, acceptedTerms) || other.acceptedTerms == acceptedTerms)&&(identical(other.marketingOptIn, marketingOptIn) || other.marketingOptIn == marketingOptIn)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.mfaRequired, mfaRequired) || other.mfaRequired == mfaRequired)&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLogin,obscurePassword,acceptedTerms,marketingOptIn,errorMessage,successMessage,isSuccess,mfaRequired,challengeToken);

@override
String toString() {
  return 'LoginState(isLoading: $isLoading, isLogin: $isLogin, obscurePassword: $obscurePassword, acceptedTerms: $acceptedTerms, marketingOptIn: $marketingOptIn, errorMessage: $errorMessage, successMessage: $successMessage, isSuccess: $isSuccess, mfaRequired: $mfaRequired, challengeToken: $challengeToken)';
}


}

/// @nodoc
abstract mixin class $LoginStateCopyWith<$Res>  {
  factory $LoginStateCopyWith(LoginState value, $Res Function(LoginState) _then) = _$LoginStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLogin, bool obscurePassword, bool acceptedTerms, bool marketingOptIn, String? errorMessage, String? successMessage, bool isSuccess, bool mfaRequired, String? challengeToken
});




}
/// @nodoc
class _$LoginStateCopyWithImpl<$Res>
    implements $LoginStateCopyWith<$Res> {
  _$LoginStateCopyWithImpl(this._self, this._then);

  final LoginState _self;
  final $Res Function(LoginState) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLogin = null,Object? obscurePassword = null,Object? acceptedTerms = null,Object? marketingOptIn = null,Object? errorMessage = freezed,Object? successMessage = freezed,Object? isSuccess = null,Object? mfaRequired = null,Object? challengeToken = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLogin: null == isLogin ? _self.isLogin : isLogin // ignore: cast_nullable_to_non_nullable
as bool,obscurePassword: null == obscurePassword ? _self.obscurePassword : obscurePassword // ignore: cast_nullable_to_non_nullable
as bool,acceptedTerms: null == acceptedTerms ? _self.acceptedTerms : acceptedTerms // ignore: cast_nullable_to_non_nullable
as bool,marketingOptIn: null == marketingOptIn ? _self.marketingOptIn : marketingOptIn // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,mfaRequired: null == mfaRequired ? _self.mfaRequired : mfaRequired // ignore: cast_nullable_to_non_nullable
as bool,challengeToken: freezed == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginState].
extension LoginStatePatterns on LoginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginState value)  $default,){
final _that = this;
switch (_that) {
case _LoginState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginState value)?  $default,){
final _that = this;
switch (_that) {
case _LoginState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLogin,  bool obscurePassword,  bool acceptedTerms,  bool marketingOptIn,  String? errorMessage,  String? successMessage,  bool isSuccess,  bool mfaRequired,  String? challengeToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginState() when $default != null:
return $default(_that.isLoading,_that.isLogin,_that.obscurePassword,_that.acceptedTerms,_that.marketingOptIn,_that.errorMessage,_that.successMessage,_that.isSuccess,_that.mfaRequired,_that.challengeToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLogin,  bool obscurePassword,  bool acceptedTerms,  bool marketingOptIn,  String? errorMessage,  String? successMessage,  bool isSuccess,  bool mfaRequired,  String? challengeToken)  $default,) {final _that = this;
switch (_that) {
case _LoginState():
return $default(_that.isLoading,_that.isLogin,_that.obscurePassword,_that.acceptedTerms,_that.marketingOptIn,_that.errorMessage,_that.successMessage,_that.isSuccess,_that.mfaRequired,_that.challengeToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLogin,  bool obscurePassword,  bool acceptedTerms,  bool marketingOptIn,  String? errorMessage,  String? successMessage,  bool isSuccess,  bool mfaRequired,  String? challengeToken)?  $default,) {final _that = this;
switch (_that) {
case _LoginState() when $default != null:
return $default(_that.isLoading,_that.isLogin,_that.obscurePassword,_that.acceptedTerms,_that.marketingOptIn,_that.errorMessage,_that.successMessage,_that.isSuccess,_that.mfaRequired,_that.challengeToken);case _:
  return null;

}
}

}

/// @nodoc


class _LoginState implements LoginState {
  const _LoginState({this.isLoading = false, this.isLogin = true, this.obscurePassword = true, this.acceptedTerms = false, this.marketingOptIn = false, this.errorMessage, this.successMessage, this.isSuccess = false, this.mfaRequired = false, this.challengeToken});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLogin;
@override@JsonKey() final  bool obscurePassword;
@override@JsonKey() final  bool acceptedTerms;
@override@JsonKey() final  bool marketingOptIn;
// CASL/Loi 25: separate marketing consent
@override final  String? errorMessage;
@override final  String? successMessage;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool mfaRequired;
@override final  String? challengeToken;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginStateCopyWith<_LoginState> get copyWith => __$LoginStateCopyWithImpl<_LoginState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLogin, isLogin) || other.isLogin == isLogin)&&(identical(other.obscurePassword, obscurePassword) || other.obscurePassword == obscurePassword)&&(identical(other.acceptedTerms, acceptedTerms) || other.acceptedTerms == acceptedTerms)&&(identical(other.marketingOptIn, marketingOptIn) || other.marketingOptIn == marketingOptIn)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.mfaRequired, mfaRequired) || other.mfaRequired == mfaRequired)&&(identical(other.challengeToken, challengeToken) || other.challengeToken == challengeToken));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLogin,obscurePassword,acceptedTerms,marketingOptIn,errorMessage,successMessage,isSuccess,mfaRequired,challengeToken);

@override
String toString() {
  return 'LoginState(isLoading: $isLoading, isLogin: $isLogin, obscurePassword: $obscurePassword, acceptedTerms: $acceptedTerms, marketingOptIn: $marketingOptIn, errorMessage: $errorMessage, successMessage: $successMessage, isSuccess: $isSuccess, mfaRequired: $mfaRequired, challengeToken: $challengeToken)';
}


}

/// @nodoc
abstract mixin class _$LoginStateCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory _$LoginStateCopyWith(_LoginState value, $Res Function(_LoginState) _then) = __$LoginStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLogin, bool obscurePassword, bool acceptedTerms, bool marketingOptIn, String? errorMessage, String? successMessage, bool isSuccess, bool mfaRequired, String? challengeToken
});




}
/// @nodoc
class __$LoginStateCopyWithImpl<$Res>
    implements _$LoginStateCopyWith<$Res> {
  __$LoginStateCopyWithImpl(this._self, this._then);

  final _LoginState _self;
  final $Res Function(_LoginState) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLogin = null,Object? obscurePassword = null,Object? acceptedTerms = null,Object? marketingOptIn = null,Object? errorMessage = freezed,Object? successMessage = freezed,Object? isSuccess = null,Object? mfaRequired = null,Object? challengeToken = freezed,}) {
  return _then(_LoginState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLogin: null == isLogin ? _self.isLogin : isLogin // ignore: cast_nullable_to_non_nullable
as bool,obscurePassword: null == obscurePassword ? _self.obscurePassword : obscurePassword // ignore: cast_nullable_to_non_nullable
as bool,acceptedTerms: null == acceptedTerms ? _self.acceptedTerms : acceptedTerms // ignore: cast_nullable_to_non_nullable
as bool,marketingOptIn: null == marketingOptIn ? _self.marketingOptIn : marketingOptIn // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,mfaRequired: null == mfaRequired ? _self.mfaRequired : mfaRequired // ignore: cast_nullable_to_non_nullable
as bool,challengeToken: freezed == challengeToken ? _self.challengeToken : challengeToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
