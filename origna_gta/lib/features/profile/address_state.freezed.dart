// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddressState {

 bool get isLoading; String? get selectedProvince; String? get selectedLabel; List<Map<String, dynamic>> get addressSuggestions; bool get showSuggestions; double? get latitude; double? get longitude; String? get addressId; String? get errorMessage; bool get isSuccess; bool get isDefault;
/// Create a copy of AddressState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressStateCopyWith<AddressState> get copyWith => _$AddressStateCopyWithImpl<AddressState>(this as AddressState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddressState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.selectedLabel, selectedLabel) || other.selectedLabel == selectedLabel)&&const DeepCollectionEquality().equals(other.addressSuggestions, addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,selectedProvince,selectedLabel,const DeepCollectionEquality().hash(addressSuggestions),showSuggestions,latitude,longitude,addressId,errorMessage,isSuccess,isDefault);

@override
String toString() {
  return 'AddressState(isLoading: $isLoading, selectedProvince: $selectedProvince, selectedLabel: $selectedLabel, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, latitude: $latitude, longitude: $longitude, addressId: $addressId, errorMessage: $errorMessage, isSuccess: $isSuccess, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $AddressStateCopyWith<$Res>  {
  factory $AddressStateCopyWith(AddressState value, $Res Function(AddressState) _then) = _$AddressStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? selectedProvince, String? selectedLabel, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, double? latitude, double? longitude, String? addressId, String? errorMessage, bool isSuccess, bool isDefault
});




}
/// @nodoc
class _$AddressStateCopyWithImpl<$Res>
    implements $AddressStateCopyWith<$Res> {
  _$AddressStateCopyWithImpl(this._self, this._then);

  final AddressState _self;
  final $Res Function(AddressState) _then;

/// Create a copy of AddressState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? selectedProvince = freezed,Object? selectedLabel = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? latitude = freezed,Object? longitude = freezed,Object? addressId = freezed,Object? errorMessage = freezed,Object? isSuccess = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: freezed == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String?,selectedLabel: freezed == selectedLabel ? _self.selectedLabel : selectedLabel // ignore: cast_nullable_to_non_nullable
as String?,addressSuggestions: null == addressSuggestions ? _self.addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,addressId: freezed == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AddressState].
extension AddressStatePatterns on AddressState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddressState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddressState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddressState value)  $default,){
final _that = this;
switch (_that) {
case _AddressState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddressState value)?  $default,){
final _that = this;
switch (_that) {
case _AddressState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? selectedProvince,  String? selectedLabel,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  double? latitude,  double? longitude,  String? addressId,  String? errorMessage,  bool isSuccess,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddressState() when $default != null:
return $default(_that.isLoading,_that.selectedProvince,_that.selectedLabel,_that.addressSuggestions,_that.showSuggestions,_that.latitude,_that.longitude,_that.addressId,_that.errorMessage,_that.isSuccess,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? selectedProvince,  String? selectedLabel,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  double? latitude,  double? longitude,  String? addressId,  String? errorMessage,  bool isSuccess,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _AddressState():
return $default(_that.isLoading,_that.selectedProvince,_that.selectedLabel,_that.addressSuggestions,_that.showSuggestions,_that.latitude,_that.longitude,_that.addressId,_that.errorMessage,_that.isSuccess,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? selectedProvince,  String? selectedLabel,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  double? latitude,  double? longitude,  String? addressId,  String? errorMessage,  bool isSuccess,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _AddressState() when $default != null:
return $default(_that.isLoading,_that.selectedProvince,_that.selectedLabel,_that.addressSuggestions,_that.showSuggestions,_that.latitude,_that.longitude,_that.addressId,_that.errorMessage,_that.isSuccess,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc


class _AddressState implements AddressState {
  const _AddressState({this.isLoading = false, this.selectedProvince = ProvinceCodeValues.ontario, this.selectedLabel = AddressLabelValues.home, final  List<Map<String, dynamic>> addressSuggestions = const [], this.showSuggestions = false, this.latitude, this.longitude, this.addressId, this.errorMessage, this.isSuccess = false, this.isDefault = false}): _addressSuggestions = addressSuggestions;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  String? selectedProvince;
@override@JsonKey() final  String? selectedLabel;
 final  List<Map<String, dynamic>> _addressSuggestions;
@override@JsonKey() List<Map<String, dynamic>> get addressSuggestions {
  if (_addressSuggestions is EqualUnmodifiableListView) return _addressSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addressSuggestions);
}

@override@JsonKey() final  bool showSuggestions;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? addressId;
@override final  String? errorMessage;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool isDefault;

/// Create a copy of AddressState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddressStateCopyWith<_AddressState> get copyWith => __$AddressStateCopyWithImpl<_AddressState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddressState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.selectedLabel, selectedLabel) || other.selectedLabel == selectedLabel)&&const DeepCollectionEquality().equals(other._addressSuggestions, _addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,selectedProvince,selectedLabel,const DeepCollectionEquality().hash(_addressSuggestions),showSuggestions,latitude,longitude,addressId,errorMessage,isSuccess,isDefault);

@override
String toString() {
  return 'AddressState(isLoading: $isLoading, selectedProvince: $selectedProvince, selectedLabel: $selectedLabel, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, latitude: $latitude, longitude: $longitude, addressId: $addressId, errorMessage: $errorMessage, isSuccess: $isSuccess, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$AddressStateCopyWith<$Res> implements $AddressStateCopyWith<$Res> {
  factory _$AddressStateCopyWith(_AddressState value, $Res Function(_AddressState) _then) = __$AddressStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? selectedProvince, String? selectedLabel, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, double? latitude, double? longitude, String? addressId, String? errorMessage, bool isSuccess, bool isDefault
});




}
/// @nodoc
class __$AddressStateCopyWithImpl<$Res>
    implements _$AddressStateCopyWith<$Res> {
  __$AddressStateCopyWithImpl(this._self, this._then);

  final _AddressState _self;
  final $Res Function(_AddressState) _then;

/// Create a copy of AddressState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? selectedProvince = freezed,Object? selectedLabel = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? latitude = freezed,Object? longitude = freezed,Object? addressId = freezed,Object? errorMessage = freezed,Object? isSuccess = null,Object? isDefault = null,}) {
  return _then(_AddressState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: freezed == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String?,selectedLabel: freezed == selectedLabel ? _self.selectedLabel : selectedLabel // ignore: cast_nullable_to_non_nullable
as String?,addressSuggestions: null == addressSuggestions ? _self._addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,addressId: freezed == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
