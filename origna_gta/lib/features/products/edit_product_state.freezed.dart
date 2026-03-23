// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_product_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditProductState {

 bool get isLoading; String? get errorMessage; bool get isSuccess; bool get isSoldOut; bool get isLocalDeliveryOnly; bool get isPerishable; bool get isDigital; bool get isAgeRestricted; String? get digitalType; String? get macosDownloadUrl; String? get windowsDownloadUrl; String? get linuxDownloadUrl; String? get bookSourceUrl; int? get deviceLimit; List<String> get existingImageUrls; List<ImageModel> get newImages; String? get existingVideoUrl; XFile? get videoFile; int? get videoDurationSeconds; List<Map<String, dynamic>> get addressSuggestions; bool get showSuggestions; String get selectedProvince; double? get latitude; double? get longitude; bool get standardEnabled; bool get savedStandardEnabled;// Saved state when digital mode toggled on
 bool get expressEnabled; bool get sameDayEnabled; int get minimumOrderQuantity; bool get freeShipping; String? get taxCode;// Variant fields — parity with AddProductState
 bool get hasVariants; List<VariantOption> get variantOptions; List<ProductVariantEntry> get variants; String? get condition;// Warehouse fields — parity with AddProductState
 List<String> get selectedWarehouseIds; Map<String, int> get warehouseStockMap;
/// Create a copy of EditProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditProductStateCopyWith<EditProductState> get copyWith => _$EditProductStateCopyWithImpl<EditProductState>(this as EditProductState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProductState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isSoldOut, isSoldOut) || other.isSoldOut == isSoldOut)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.macosDownloadUrl, macosDownloadUrl) || other.macosDownloadUrl == macosDownloadUrl)&&(identical(other.windowsDownloadUrl, windowsDownloadUrl) || other.windowsDownloadUrl == windowsDownloadUrl)&&(identical(other.linuxDownloadUrl, linuxDownloadUrl) || other.linuxDownloadUrl == linuxDownloadUrl)&&(identical(other.bookSourceUrl, bookSourceUrl) || other.bookSourceUrl == bookSourceUrl)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&const DeepCollectionEquality().equals(other.existingImageUrls, existingImageUrls)&&const DeepCollectionEquality().equals(other.newImages, newImages)&&(identical(other.existingVideoUrl, existingVideoUrl) || other.existingVideoUrl == existingVideoUrl)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&const DeepCollectionEquality().equals(other.addressSuggestions, addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.standardEnabled, standardEnabled) || other.standardEnabled == standardEnabled)&&(identical(other.savedStandardEnabled, savedStandardEnabled) || other.savedStandardEnabled == savedStandardEnabled)&&(identical(other.expressEnabled, expressEnabled) || other.expressEnabled == expressEnabled)&&(identical(other.sameDayEnabled, sameDayEnabled) || other.sameDayEnabled == sameDayEnabled)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other.variantOptions, variantOptions)&&const DeepCollectionEquality().equals(other.variants, variants)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other.selectedWarehouseIds, selectedWarehouseIds)&&const DeepCollectionEquality().equals(other.warehouseStockMap, warehouseStockMap));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,errorMessage,isSuccess,isSoldOut,isLocalDeliveryOnly,isPerishable,isDigital,isAgeRestricted,digitalType,macosDownloadUrl,windowsDownloadUrl,linuxDownloadUrl,bookSourceUrl,deviceLimit,const DeepCollectionEquality().hash(existingImageUrls),const DeepCollectionEquality().hash(newImages),existingVideoUrl,videoFile,videoDurationSeconds,const DeepCollectionEquality().hash(addressSuggestions),showSuggestions,selectedProvince,latitude,longitude,standardEnabled,savedStandardEnabled,expressEnabled,sameDayEnabled,minimumOrderQuantity,freeShipping,taxCode,hasVariants,const DeepCollectionEquality().hash(variantOptions),const DeepCollectionEquality().hash(variants),condition,const DeepCollectionEquality().hash(selectedWarehouseIds),const DeepCollectionEquality().hash(warehouseStockMap)]);

@override
String toString() {
  return 'EditProductState(isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess, isSoldOut: $isSoldOut, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, macosDownloadUrl: $macosDownloadUrl, windowsDownloadUrl: $windowsDownloadUrl, linuxDownloadUrl: $linuxDownloadUrl, bookSourceUrl: $bookSourceUrl, deviceLimit: $deviceLimit, existingImageUrls: $existingImageUrls, newImages: $newImages, existingVideoUrl: $existingVideoUrl, videoFile: $videoFile, videoDurationSeconds: $videoDurationSeconds, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, selectedProvince: $selectedProvince, latitude: $latitude, longitude: $longitude, standardEnabled: $standardEnabled, savedStandardEnabled: $savedStandardEnabled, expressEnabled: $expressEnabled, sameDayEnabled: $sameDayEnabled, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, taxCode: $taxCode, hasVariants: $hasVariants, variantOptions: $variantOptions, variants: $variants, condition: $condition, selectedWarehouseIds: $selectedWarehouseIds, warehouseStockMap: $warehouseStockMap)';
}


}

/// @nodoc
abstract mixin class $EditProductStateCopyWith<$Res>  {
  factory $EditProductStateCopyWith(EditProductState value, $Res Function(EditProductState) _then) = _$EditProductStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? errorMessage, bool isSuccess, bool isSoldOut, bool isLocalDeliveryOnly, bool isPerishable, bool isDigital, bool isAgeRestricted, String? digitalType, String? macosDownloadUrl, String? windowsDownloadUrl, String? linuxDownloadUrl, String? bookSourceUrl, int? deviceLimit, List<String> existingImageUrls, List<ImageModel> newImages, String? existingVideoUrl, XFile? videoFile, int? videoDurationSeconds, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, String selectedProvince, double? latitude, double? longitude, bool standardEnabled, bool savedStandardEnabled, bool expressEnabled, bool sameDayEnabled, int minimumOrderQuantity, bool freeShipping, String? taxCode, bool hasVariants, List<VariantOption> variantOptions, List<ProductVariantEntry> variants, String? condition, List<String> selectedWarehouseIds, Map<String, int> warehouseStockMap
});




}
/// @nodoc
class _$EditProductStateCopyWithImpl<$Res>
    implements $EditProductStateCopyWith<$Res> {
  _$EditProductStateCopyWithImpl(this._self, this._then);

  final EditProductState _self;
  final $Res Function(EditProductState) _then;

/// Create a copy of EditProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,Object? isSoldOut = null,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? macosDownloadUrl = freezed,Object? windowsDownloadUrl = freezed,Object? linuxDownloadUrl = freezed,Object? bookSourceUrl = freezed,Object? deviceLimit = freezed,Object? existingImageUrls = null,Object? newImages = null,Object? existingVideoUrl = freezed,Object? videoFile = freezed,Object? videoDurationSeconds = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? selectedProvince = null,Object? latitude = freezed,Object? longitude = freezed,Object? standardEnabled = null,Object? savedStandardEnabled = null,Object? expressEnabled = null,Object? sameDayEnabled = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? taxCode = freezed,Object? hasVariants = null,Object? variantOptions = null,Object? variants = null,Object? condition = freezed,Object? selectedWarehouseIds = null,Object? warehouseStockMap = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isSoldOut: null == isSoldOut ? _self.isSoldOut : isSoldOut // ignore: cast_nullable_to_non_nullable
as bool,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,macosDownloadUrl: freezed == macosDownloadUrl ? _self.macosDownloadUrl : macosDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,windowsDownloadUrl: freezed == windowsDownloadUrl ? _self.windowsDownloadUrl : windowsDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,linuxDownloadUrl: freezed == linuxDownloadUrl ? _self.linuxDownloadUrl : linuxDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,bookSourceUrl: freezed == bookSourceUrl ? _self.bookSourceUrl : bookSourceUrl // ignore: cast_nullable_to_non_nullable
as String?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,existingImageUrls: null == existingImageUrls ? _self.existingImageUrls : existingImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,newImages: null == newImages ? _self.newImages : newImages // ignore: cast_nullable_to_non_nullable
as List<ImageModel>,existingVideoUrl: freezed == existingVideoUrl ? _self.existingVideoUrl : existingVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoFile: freezed == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as XFile?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,addressSuggestions: null == addressSuggestions ? _self.addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: null == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,standardEnabled: null == standardEnabled ? _self.standardEnabled : standardEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedStandardEnabled: null == savedStandardEnabled ? _self.savedStandardEnabled : savedStandardEnabled // ignore: cast_nullable_to_non_nullable
as bool,expressEnabled: null == expressEnabled ? _self.expressEnabled : expressEnabled // ignore: cast_nullable_to_non_nullable
as bool,sameDayEnabled: null == sameDayEnabled ? _self.sameDayEnabled : sameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variantOptions: null == variantOptions ? _self.variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariantEntry>,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,selectedWarehouseIds: null == selectedWarehouseIds ? _self.selectedWarehouseIds : selectedWarehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>,warehouseStockMap: null == warehouseStockMap ? _self.warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [EditProductState].
extension EditProductStatePatterns on EditProductState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditProductState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditProductState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditProductState value)  $default,){
final _that = this;
switch (_that) {
case _EditProductState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditProductState value)?  $default,){
final _that = this;
switch (_that) {
case _EditProductState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  bool isSuccess,  bool isSoldOut,  bool isLocalDeliveryOnly,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  List<String> existingImageUrls,  List<ImageModel> newImages,  String? existingVideoUrl,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  String selectedProvince,  double? latitude,  double? longitude,  bool standardEnabled,  bool savedStandardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  String? taxCode,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditProductState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess,_that.isSoldOut,_that.isLocalDeliveryOnly,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.existingImageUrls,_that.newImages,_that.existingVideoUrl,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.selectedProvince,_that.latitude,_that.longitude,_that.standardEnabled,_that.savedStandardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.taxCode,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.selectedWarehouseIds,_that.warehouseStockMap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? errorMessage,  bool isSuccess,  bool isSoldOut,  bool isLocalDeliveryOnly,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  List<String> existingImageUrls,  List<ImageModel> newImages,  String? existingVideoUrl,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  String selectedProvince,  double? latitude,  double? longitude,  bool standardEnabled,  bool savedStandardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  String? taxCode,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap)  $default,) {final _that = this;
switch (_that) {
case _EditProductState():
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess,_that.isSoldOut,_that.isLocalDeliveryOnly,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.existingImageUrls,_that.newImages,_that.existingVideoUrl,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.selectedProvince,_that.latitude,_that.longitude,_that.standardEnabled,_that.savedStandardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.taxCode,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.selectedWarehouseIds,_that.warehouseStockMap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? errorMessage,  bool isSuccess,  bool isSoldOut,  bool isLocalDeliveryOnly,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  List<String> existingImageUrls,  List<ImageModel> newImages,  String? existingVideoUrl,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  String selectedProvince,  double? latitude,  double? longitude,  bool standardEnabled,  bool savedStandardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  String? taxCode,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap)?  $default,) {final _that = this;
switch (_that) {
case _EditProductState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.isSuccess,_that.isSoldOut,_that.isLocalDeliveryOnly,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.existingImageUrls,_that.newImages,_that.existingVideoUrl,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.selectedProvince,_that.latitude,_that.longitude,_that.standardEnabled,_that.savedStandardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.taxCode,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.selectedWarehouseIds,_that.warehouseStockMap);case _:
  return null;

}
}

}

/// @nodoc


class _EditProductState implements EditProductState {
  const _EditProductState({this.isLoading = false, this.errorMessage, this.isSuccess = false, this.isSoldOut = false, this.isLocalDeliveryOnly = false, this.isPerishable = false, this.isDigital = false, this.isAgeRestricted = false, this.digitalType, this.macosDownloadUrl, this.windowsDownloadUrl, this.linuxDownloadUrl, this.bookSourceUrl, this.deviceLimit, final  List<String> existingImageUrls = const [], final  List<ImageModel> newImages = const [], this.existingVideoUrl, this.videoFile, this.videoDurationSeconds, final  List<Map<String, dynamic>> addressSuggestions = const [], this.showSuggestions = false, this.selectedProvince = ProvinceCodeValues.ontario, this.latitude, this.longitude, this.standardEnabled = true, this.savedStandardEnabled = true, this.expressEnabled = false, this.sameDayEnabled = false, this.minimumOrderQuantity = 1, this.freeShipping = false, this.taxCode, this.hasVariants = false, final  List<VariantOption> variantOptions = const [], final  List<ProductVariantEntry> variants = const [], this.condition, final  List<String> selectedWarehouseIds = const [], final  Map<String, int> warehouseStockMap = const {}}): _existingImageUrls = existingImageUrls,_newImages = newImages,_addressSuggestions = addressSuggestions,_variantOptions = variantOptions,_variants = variants,_selectedWarehouseIds = selectedWarehouseIds,_warehouseStockMap = warehouseStockMap;
  

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool isSoldOut;
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  bool isDigital;
@override@JsonKey() final  bool isAgeRestricted;
@override final  String? digitalType;
@override final  String? macosDownloadUrl;
@override final  String? windowsDownloadUrl;
@override final  String? linuxDownloadUrl;
@override final  String? bookSourceUrl;
@override final  int? deviceLimit;
 final  List<String> _existingImageUrls;
@override@JsonKey() List<String> get existingImageUrls {
  if (_existingImageUrls is EqualUnmodifiableListView) return _existingImageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_existingImageUrls);
}

 final  List<ImageModel> _newImages;
@override@JsonKey() List<ImageModel> get newImages {
  if (_newImages is EqualUnmodifiableListView) return _newImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newImages);
}

@override final  String? existingVideoUrl;
@override final  XFile? videoFile;
@override final  int? videoDurationSeconds;
 final  List<Map<String, dynamic>> _addressSuggestions;
@override@JsonKey() List<Map<String, dynamic>> get addressSuggestions {
  if (_addressSuggestions is EqualUnmodifiableListView) return _addressSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addressSuggestions);
}

@override@JsonKey() final  bool showSuggestions;
@override@JsonKey() final  String selectedProvince;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  bool standardEnabled;
@override@JsonKey() final  bool savedStandardEnabled;
// Saved state when digital mode toggled on
@override@JsonKey() final  bool expressEnabled;
@override@JsonKey() final  bool sameDayEnabled;
@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
@override final  String? taxCode;
// Variant fields — parity with AddProductState
@override@JsonKey() final  bool hasVariants;
 final  List<VariantOption> _variantOptions;
@override@JsonKey() List<VariantOption> get variantOptions {
  if (_variantOptions is EqualUnmodifiableListView) return _variantOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variantOptions);
}

 final  List<ProductVariantEntry> _variants;
@override@JsonKey() List<ProductVariantEntry> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

@override final  String? condition;
// Warehouse fields — parity with AddProductState
 final  List<String> _selectedWarehouseIds;
// Warehouse fields — parity with AddProductState
@override@JsonKey() List<String> get selectedWarehouseIds {
  if (_selectedWarehouseIds is EqualUnmodifiableListView) return _selectedWarehouseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedWarehouseIds);
}

 final  Map<String, int> _warehouseStockMap;
@override@JsonKey() Map<String, int> get warehouseStockMap {
  if (_warehouseStockMap is EqualUnmodifiableMapView) return _warehouseStockMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_warehouseStockMap);
}


/// Create a copy of EditProductState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditProductStateCopyWith<_EditProductState> get copyWith => __$EditProductStateCopyWithImpl<_EditProductState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditProductState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isSoldOut, isSoldOut) || other.isSoldOut == isSoldOut)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.macosDownloadUrl, macosDownloadUrl) || other.macosDownloadUrl == macosDownloadUrl)&&(identical(other.windowsDownloadUrl, windowsDownloadUrl) || other.windowsDownloadUrl == windowsDownloadUrl)&&(identical(other.linuxDownloadUrl, linuxDownloadUrl) || other.linuxDownloadUrl == linuxDownloadUrl)&&(identical(other.bookSourceUrl, bookSourceUrl) || other.bookSourceUrl == bookSourceUrl)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&const DeepCollectionEquality().equals(other._existingImageUrls, _existingImageUrls)&&const DeepCollectionEquality().equals(other._newImages, _newImages)&&(identical(other.existingVideoUrl, existingVideoUrl) || other.existingVideoUrl == existingVideoUrl)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&const DeepCollectionEquality().equals(other._addressSuggestions, _addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.standardEnabled, standardEnabled) || other.standardEnabled == standardEnabled)&&(identical(other.savedStandardEnabled, savedStandardEnabled) || other.savedStandardEnabled == savedStandardEnabled)&&(identical(other.expressEnabled, expressEnabled) || other.expressEnabled == expressEnabled)&&(identical(other.sameDayEnabled, sameDayEnabled) || other.sameDayEnabled == sameDayEnabled)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.taxCode, taxCode) || other.taxCode == taxCode)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other._variantOptions, _variantOptions)&&const DeepCollectionEquality().equals(other._variants, _variants)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other._selectedWarehouseIds, _selectedWarehouseIds)&&const DeepCollectionEquality().equals(other._warehouseStockMap, _warehouseStockMap));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,errorMessage,isSuccess,isSoldOut,isLocalDeliveryOnly,isPerishable,isDigital,isAgeRestricted,digitalType,macosDownloadUrl,windowsDownloadUrl,linuxDownloadUrl,bookSourceUrl,deviceLimit,const DeepCollectionEquality().hash(_existingImageUrls),const DeepCollectionEquality().hash(_newImages),existingVideoUrl,videoFile,videoDurationSeconds,const DeepCollectionEquality().hash(_addressSuggestions),showSuggestions,selectedProvince,latitude,longitude,standardEnabled,savedStandardEnabled,expressEnabled,sameDayEnabled,minimumOrderQuantity,freeShipping,taxCode,hasVariants,const DeepCollectionEquality().hash(_variantOptions),const DeepCollectionEquality().hash(_variants),condition,const DeepCollectionEquality().hash(_selectedWarehouseIds),const DeepCollectionEquality().hash(_warehouseStockMap)]);

@override
String toString() {
  return 'EditProductState(isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess, isSoldOut: $isSoldOut, isLocalDeliveryOnly: $isLocalDeliveryOnly, isPerishable: $isPerishable, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, macosDownloadUrl: $macosDownloadUrl, windowsDownloadUrl: $windowsDownloadUrl, linuxDownloadUrl: $linuxDownloadUrl, bookSourceUrl: $bookSourceUrl, deviceLimit: $deviceLimit, existingImageUrls: $existingImageUrls, newImages: $newImages, existingVideoUrl: $existingVideoUrl, videoFile: $videoFile, videoDurationSeconds: $videoDurationSeconds, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, selectedProvince: $selectedProvince, latitude: $latitude, longitude: $longitude, standardEnabled: $standardEnabled, savedStandardEnabled: $savedStandardEnabled, expressEnabled: $expressEnabled, sameDayEnabled: $sameDayEnabled, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, taxCode: $taxCode, hasVariants: $hasVariants, variantOptions: $variantOptions, variants: $variants, condition: $condition, selectedWarehouseIds: $selectedWarehouseIds, warehouseStockMap: $warehouseStockMap)';
}


}

/// @nodoc
abstract mixin class _$EditProductStateCopyWith<$Res> implements $EditProductStateCopyWith<$Res> {
  factory _$EditProductStateCopyWith(_EditProductState value, $Res Function(_EditProductState) _then) = __$EditProductStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? errorMessage, bool isSuccess, bool isSoldOut, bool isLocalDeliveryOnly, bool isPerishable, bool isDigital, bool isAgeRestricted, String? digitalType, String? macosDownloadUrl, String? windowsDownloadUrl, String? linuxDownloadUrl, String? bookSourceUrl, int? deviceLimit, List<String> existingImageUrls, List<ImageModel> newImages, String? existingVideoUrl, XFile? videoFile, int? videoDurationSeconds, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, String selectedProvince, double? latitude, double? longitude, bool standardEnabled, bool savedStandardEnabled, bool expressEnabled, bool sameDayEnabled, int minimumOrderQuantity, bool freeShipping, String? taxCode, bool hasVariants, List<VariantOption> variantOptions, List<ProductVariantEntry> variants, String? condition, List<String> selectedWarehouseIds, Map<String, int> warehouseStockMap
});




}
/// @nodoc
class __$EditProductStateCopyWithImpl<$Res>
    implements _$EditProductStateCopyWith<$Res> {
  __$EditProductStateCopyWithImpl(this._self, this._then);

  final _EditProductState _self;
  final $Res Function(_EditProductState) _then;

/// Create a copy of EditProductState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,Object? isSoldOut = null,Object? isLocalDeliveryOnly = null,Object? isPerishable = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? macosDownloadUrl = freezed,Object? windowsDownloadUrl = freezed,Object? linuxDownloadUrl = freezed,Object? bookSourceUrl = freezed,Object? deviceLimit = freezed,Object? existingImageUrls = null,Object? newImages = null,Object? existingVideoUrl = freezed,Object? videoFile = freezed,Object? videoDurationSeconds = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? selectedProvince = null,Object? latitude = freezed,Object? longitude = freezed,Object? standardEnabled = null,Object? savedStandardEnabled = null,Object? expressEnabled = null,Object? sameDayEnabled = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? taxCode = freezed,Object? hasVariants = null,Object? variantOptions = null,Object? variants = null,Object? condition = freezed,Object? selectedWarehouseIds = null,Object? warehouseStockMap = null,}) {
  return _then(_EditProductState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isSoldOut: null == isSoldOut ? _self.isSoldOut : isSoldOut // ignore: cast_nullable_to_non_nullable
as bool,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,macosDownloadUrl: freezed == macosDownloadUrl ? _self.macosDownloadUrl : macosDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,windowsDownloadUrl: freezed == windowsDownloadUrl ? _self.windowsDownloadUrl : windowsDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,linuxDownloadUrl: freezed == linuxDownloadUrl ? _self.linuxDownloadUrl : linuxDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,bookSourceUrl: freezed == bookSourceUrl ? _self.bookSourceUrl : bookSourceUrl // ignore: cast_nullable_to_non_nullable
as String?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,existingImageUrls: null == existingImageUrls ? _self._existingImageUrls : existingImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,newImages: null == newImages ? _self._newImages : newImages // ignore: cast_nullable_to_non_nullable
as List<ImageModel>,existingVideoUrl: freezed == existingVideoUrl ? _self.existingVideoUrl : existingVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoFile: freezed == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as XFile?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,addressSuggestions: null == addressSuggestions ? _self._addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: null == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,standardEnabled: null == standardEnabled ? _self.standardEnabled : standardEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedStandardEnabled: null == savedStandardEnabled ? _self.savedStandardEnabled : savedStandardEnabled // ignore: cast_nullable_to_non_nullable
as bool,expressEnabled: null == expressEnabled ? _self.expressEnabled : expressEnabled // ignore: cast_nullable_to_non_nullable
as bool,sameDayEnabled: null == sameDayEnabled ? _self.sameDayEnabled : sameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,taxCode: freezed == taxCode ? _self.taxCode : taxCode // ignore: cast_nullable_to_non_nullable
as String?,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variantOptions: null == variantOptions ? _self._variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariantEntry>,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,selectedWarehouseIds: null == selectedWarehouseIds ? _self._selectedWarehouseIds : selectedWarehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>,warehouseStockMap: null == warehouseStockMap ? _self._warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
