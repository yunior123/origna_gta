// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mfa_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MfaState {

 bool get isLoading; String? get errorMessage; int get currentStep;// 0=idle, 1=scan QR, 2=verify code, 3=backup codes, 4=done
 String? get qrCodeBase64; String? get manualKey; String? get appleOtpauthUrl; List<String> get recoveryCodes; bool get mfaEnabled; bool get codesSaved;
/// Create a copy of MfaState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MfaStateCopyWith<MfaState> get copyWith => _$MfaStateCopyWithImpl<MfaState>(this as MfaState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MfaState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.qrCodeBase64, qrCodeBase64) || other.qrCodeBase64 == qrCodeBase64)&&(identical(other.manualKey, manualKey) || other.manualKey == manualKey)&&(identical(other.appleOtpauthUrl, appleOtpauthUrl) || other.appleOtpauthUrl == appleOtpauthUrl)&&const DeepCollectionEquality().equals(other.recoveryCodes, recoveryCodes)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled)&&(identical(other.codesSaved, codesSaved) || other.codesSaved == codesSaved));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,currentStep,qrCodeBase64,manualKey,appleOtpauthUrl,const DeepCollectionEquality().hash(recoveryCodes),mfaEnabled,codesSaved);

@override
String toString() {
  return 'MfaState(isLoading: $isLoading, errorMessage: $errorMessage, currentStep: $currentStep, qrCodeBase64: $qrCodeBase64, manualKey: $manualKey, appleOtpauthUrl: $appleOtpauthUrl, recoveryCodes: $recoveryCodes, mfaEnabled: $mfaEnabled, codesSaved: $codesSaved)';
}


}

/// @nodoc
abstract mixin class $MfaStateCopyWith<$Res>  {
  factory $MfaStateCopyWith(MfaState value, $Res Function(MfaState) _then) = _$MfaStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? errorMessage, int currentStep, String? qrCodeBase64, String? manualKey, String? appleOtpauthUrl, List<String> recoveryCodes, bool mfaEnabled, bool codesSaved
});




}
/// @nodoc
class _$MfaStateCopyWithImpl<$Res>
    implements $MfaStateCopyWith<$Res> {
  _$MfaStateCopyWithImpl(this._self, this._then);

  final MfaState _self;
  final $Res Function(MfaState) _then;

/// Create a copy of MfaState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? currentStep = null,Object? qrCodeBase64 = freezed,Object? manualKey = freezed,Object? appleOtpauthUrl = freezed,Object? recoveryCodes = null,Object? mfaEnabled = null,Object? codesSaved = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,qrCodeBase64: freezed == qrCodeBase64 ? _self.qrCodeBase64 : qrCodeBase64 // ignore: cast_nullable_to_non_nullable
as String?,manualKey: freezed == manualKey ? _self.manualKey : manualKey // ignore: cast_nullable_to_non_nullable
as String?,appleOtpauthUrl: freezed == appleOtpauthUrl ? _self.appleOtpauthUrl : appleOtpauthUrl // ignore: cast_nullable_to_non_nullable
as String?,recoveryCodes: null == recoveryCodes ? _self.recoveryCodes : recoveryCodes // ignore: cast_nullable_to_non_nullable
as List<String>,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,codesSaved: null == codesSaved ? _self.codesSaved : codesSaved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MfaState].
extension MfaStatePatterns on MfaState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MfaState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MfaState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MfaState value)  $default,){
final _that = this;
switch (_that) {
case _MfaState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MfaState value)?  $default,){
final _that = this;
switch (_that) {
case _MfaState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  int currentStep,  String? qrCodeBase64,  String? manualKey,  String? appleOtpauthUrl,  List<String> recoveryCodes,  bool mfaEnabled,  bool codesSaved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MfaState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.currentStep,_that.qrCodeBase64,_that.manualKey,_that.appleOtpauthUrl,_that.recoveryCodes,_that.mfaEnabled,_that.codesSaved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  int currentStep,  String? qrCodeBase64,  String? manualKey,  String? appleOtpauthUrl,  List<String> recoveryCodes,  bool mfaEnabled,  bool codesSaved)  $default,) {final _that = this;
switch (_that) {
case _MfaState():
return $default(_that.isLoading,_that.errorMessage,_that.currentStep,_that.qrCodeBase64,_that.manualKey,_that.appleOtpauthUrl,_that.recoveryCodes,_that.mfaEnabled,_that.codesSaved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? errorMessage,  int currentStep,  String? qrCodeBase64,  String? manualKey,  String? appleOtpauthUrl,  List<String> recoveryCodes,  bool mfaEnabled,  bool codesSaved)?  $default,) {final _that = this;
switch (_that) {
case _MfaState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.currentStep,_that.qrCodeBase64,_that.manualKey,_that.appleOtpauthUrl,_that.recoveryCodes,_that.mfaEnabled,_that.codesSaved);case _:
  return null;

}
}

}

/// @nodoc


class _MfaState implements MfaState {
  const _MfaState({this.isLoading = false, this.errorMessage, this.currentStep = 0, this.qrCodeBase64, this.manualKey, this.appleOtpauthUrl, final  List<String> recoveryCodes = const [], this.mfaEnabled = false, this.codesSaved = false}): _recoveryCodes = recoveryCodes;
  

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  int currentStep;
// 0=idle, 1=scan QR, 2=verify code, 3=backup codes, 4=done
@override final  String? qrCodeBase64;
@override final  String? manualKey;
@override final  String? appleOtpauthUrl;
 final  List<String> _recoveryCodes;
@override@JsonKey() List<String> get recoveryCodes {
  if (_recoveryCodes is EqualUnmodifiableListView) return _recoveryCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recoveryCodes);
}

@override@JsonKey() final  bool mfaEnabled;
@override@JsonKey() final  bool codesSaved;

/// Create a copy of MfaState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MfaStateCopyWith<_MfaState> get copyWith => __$MfaStateCopyWithImpl<_MfaState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MfaState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.qrCodeBase64, qrCodeBase64) || other.qrCodeBase64 == qrCodeBase64)&&(identical(other.manualKey, manualKey) || other.manualKey == manualKey)&&(identical(other.appleOtpauthUrl, appleOtpauthUrl) || other.appleOtpauthUrl == appleOtpauthUrl)&&const DeepCollectionEquality().equals(other._recoveryCodes, _recoveryCodes)&&(identical(other.mfaEnabled, mfaEnabled) || other.mfaEnabled == mfaEnabled)&&(identical(other.codesSaved, codesSaved) || other.codesSaved == codesSaved));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,currentStep,qrCodeBase64,manualKey,appleOtpauthUrl,const DeepCollectionEquality().hash(_recoveryCodes),mfaEnabled,codesSaved);

@override
String toString() {
  return 'MfaState(isLoading: $isLoading, errorMessage: $errorMessage, currentStep: $currentStep, qrCodeBase64: $qrCodeBase64, manualKey: $manualKey, appleOtpauthUrl: $appleOtpauthUrl, recoveryCodes: $recoveryCodes, mfaEnabled: $mfaEnabled, codesSaved: $codesSaved)';
}


}

/// @nodoc
abstract mixin class _$MfaStateCopyWith<$Res> implements $MfaStateCopyWith<$Res> {
  factory _$MfaStateCopyWith(_MfaState value, $Res Function(_MfaState) _then) = __$MfaStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? errorMessage, int currentStep, String? qrCodeBase64, String? manualKey, String? appleOtpauthUrl, List<String> recoveryCodes, bool mfaEnabled, bool codesSaved
});




}
/// @nodoc
class __$MfaStateCopyWithImpl<$Res>
    implements _$MfaStateCopyWith<$Res> {
  __$MfaStateCopyWithImpl(this._self, this._then);

  final _MfaState _self;
  final $Res Function(_MfaState) _then;

/// Create a copy of MfaState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? currentStep = null,Object? qrCodeBase64 = freezed,Object? manualKey = freezed,Object? appleOtpauthUrl = freezed,Object? recoveryCodes = null,Object? mfaEnabled = null,Object? codesSaved = null,}) {
  return _then(_MfaState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,qrCodeBase64: freezed == qrCodeBase64 ? _self.qrCodeBase64 : qrCodeBase64 // ignore: cast_nullable_to_non_nullable
as String?,manualKey: freezed == manualKey ? _self.manualKey : manualKey // ignore: cast_nullable_to_non_nullable
as String?,appleOtpauthUrl: freezed == appleOtpauthUrl ? _self.appleOtpauthUrl : appleOtpauthUrl // ignore: cast_nullable_to_non_nullable
as String?,recoveryCodes: null == recoveryCodes ? _self._recoveryCodes : recoveryCodes // ignore: cast_nullable_to_non_nullable
as List<String>,mfaEnabled: null == mfaEnabled ? _self.mfaEnabled : mfaEnabled // ignore: cast_nullable_to_non_nullable
as bool,codesSaved: null == codesSaved ? _self.codesSaved : codesSaved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
