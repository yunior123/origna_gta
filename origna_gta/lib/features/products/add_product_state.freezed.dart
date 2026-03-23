// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_product_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddProductState {

 bool get isLoading;// PROD-C4: true only during the R2 video upload step inside addProduct()
 bool get isUploadingVideo; bool get isLocalDeliveryOnly; String get selectedProvince; double? get latitude; double? get longitude; List<ImageModel> get imageModels; XFile? get videoFile; int? get videoDurationSeconds; List<Map<String, dynamic>> get addressSuggestions; bool get showSuggestions; bool get addressVerified;// true when address selected from Geoapify
 bool get isPerishable; bool get isDigital; bool get isAgeRestricted; String? get digitalType;// 'software' | 'book' | null
 String? get macosDownloadUrl; String? get windowsDownloadUrl; String? get linuxDownloadUrl; String? get bookSourceUrl; int? get deviceLimit; bool get standardEnabled; bool get expressEnabled; bool get sameDayEnabled; int get minimumOrderQuantity; bool get freeShipping;// H-03: freeShippingAt10Plus removed - never stored/used on backend
 bool get savedExpressEnabled;// Saved state when free shipping toggled on
 bool get savedSameDayEnabled;// Saved state when free shipping toggled on
 bool get savedStandardEnabled;// Saved state when digital mode toggled on
 String? get errorMessage; String? get skuError;// PROD-H2: Inline error for SKU collisions
 bool get isSuccess;// C-03: Business logic state moved from Screen to ViewModel/State
 String get selectedSupplierType; String get selectedSupplierCurrency; bool get hasTracking; bool get inventoryManaged; bool get trackQuantity; bool get allowBackorder; bool get lowStockAlertEnabled; int get activeStep; String? get selectedCategoryId; String? get selectedSubcategory; bool get hasAttemptedSubmit; bool get discountTierError;// Multi-warehouse fields
 String? get sellerSku; List<String> get selectedWarehouseIds; Map<String, int> get warehouseStockMap;// warehouseId → stock qty
// N-09: Variant builder fields
 bool get hasVariants; List<VariantOption> get variantOptions; List<ProductVariantEntry> get variants; String? get condition;// ProductConditionValues: new|like_new|good|fair|for_parts
// Bill 96: French translation fields (optional, recommended for Quebec market)
 String? get nameF; String? get descriptionF;
/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddProductStateCopyWith<AddProductState> get copyWith => _$AddProductStateCopyWithImpl<AddProductState>(this as AddProductState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isUploadingVideo, isUploadingVideo) || other.isUploadingVideo == isUploadingVideo)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other.imageModels, imageModels)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&const DeepCollectionEquality().equals(other.addressSuggestions, addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.addressVerified, addressVerified) || other.addressVerified == addressVerified)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.macosDownloadUrl, macosDownloadUrl) || other.macosDownloadUrl == macosDownloadUrl)&&(identical(other.windowsDownloadUrl, windowsDownloadUrl) || other.windowsDownloadUrl == windowsDownloadUrl)&&(identical(other.linuxDownloadUrl, linuxDownloadUrl) || other.linuxDownloadUrl == linuxDownloadUrl)&&(identical(other.bookSourceUrl, bookSourceUrl) || other.bookSourceUrl == bookSourceUrl)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.standardEnabled, standardEnabled) || other.standardEnabled == standardEnabled)&&(identical(other.expressEnabled, expressEnabled) || other.expressEnabled == expressEnabled)&&(identical(other.sameDayEnabled, sameDayEnabled) || other.sameDayEnabled == sameDayEnabled)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.savedExpressEnabled, savedExpressEnabled) || other.savedExpressEnabled == savedExpressEnabled)&&(identical(other.savedSameDayEnabled, savedSameDayEnabled) || other.savedSameDayEnabled == savedSameDayEnabled)&&(identical(other.savedStandardEnabled, savedStandardEnabled) || other.savedStandardEnabled == savedStandardEnabled)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.skuError, skuError) || other.skuError == skuError)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.selectedSupplierType, selectedSupplierType) || other.selectedSupplierType == selectedSupplierType)&&(identical(other.selectedSupplierCurrency, selectedSupplierCurrency) || other.selectedSupplierCurrency == selectedSupplierCurrency)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.inventoryManaged, inventoryManaged) || other.inventoryManaged == inventoryManaged)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockAlertEnabled, lowStockAlertEnabled) || other.lowStockAlertEnabled == lowStockAlertEnabled)&&(identical(other.activeStep, activeStep) || other.activeStep == activeStep)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.selectedSubcategory, selectedSubcategory) || other.selectedSubcategory == selectedSubcategory)&&(identical(other.hasAttemptedSubmit, hasAttemptedSubmit) || other.hasAttemptedSubmit == hasAttemptedSubmit)&&(identical(other.discountTierError, discountTierError) || other.discountTierError == discountTierError)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other.selectedWarehouseIds, selectedWarehouseIds)&&const DeepCollectionEquality().equals(other.warehouseStockMap, warehouseStockMap)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other.variantOptions, variantOptions)&&const DeepCollectionEquality().equals(other.variants, variants)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,isUploadingVideo,isLocalDeliveryOnly,selectedProvince,latitude,longitude,const DeepCollectionEquality().hash(imageModels),videoFile,videoDurationSeconds,const DeepCollectionEquality().hash(addressSuggestions),showSuggestions,addressVerified,isPerishable,isDigital,isAgeRestricted,digitalType,macosDownloadUrl,windowsDownloadUrl,linuxDownloadUrl,bookSourceUrl,deviceLimit,standardEnabled,expressEnabled,sameDayEnabled,minimumOrderQuantity,freeShipping,savedExpressEnabled,savedSameDayEnabled,savedStandardEnabled,errorMessage,skuError,isSuccess,selectedSupplierType,selectedSupplierCurrency,hasTracking,inventoryManaged,trackQuantity,allowBackorder,lowStockAlertEnabled,activeStep,selectedCategoryId,selectedSubcategory,hasAttemptedSubmit,discountTierError,sellerSku,const DeepCollectionEquality().hash(selectedWarehouseIds),const DeepCollectionEquality().hash(warehouseStockMap),hasVariants,const DeepCollectionEquality().hash(variantOptions),const DeepCollectionEquality().hash(variants),condition,nameF,descriptionF]);

@override
String toString() {
  return 'AddProductState(isLoading: $isLoading, isUploadingVideo: $isUploadingVideo, isLocalDeliveryOnly: $isLocalDeliveryOnly, selectedProvince: $selectedProvince, latitude: $latitude, longitude: $longitude, imageModels: $imageModels, videoFile: $videoFile, videoDurationSeconds: $videoDurationSeconds, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, addressVerified: $addressVerified, isPerishable: $isPerishable, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, macosDownloadUrl: $macosDownloadUrl, windowsDownloadUrl: $windowsDownloadUrl, linuxDownloadUrl: $linuxDownloadUrl, bookSourceUrl: $bookSourceUrl, deviceLimit: $deviceLimit, standardEnabled: $standardEnabled, expressEnabled: $expressEnabled, sameDayEnabled: $sameDayEnabled, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, savedExpressEnabled: $savedExpressEnabled, savedSameDayEnabled: $savedSameDayEnabled, savedStandardEnabled: $savedStandardEnabled, errorMessage: $errorMessage, skuError: $skuError, isSuccess: $isSuccess, selectedSupplierType: $selectedSupplierType, selectedSupplierCurrency: $selectedSupplierCurrency, hasTracking: $hasTracking, inventoryManaged: $inventoryManaged, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockAlertEnabled: $lowStockAlertEnabled, activeStep: $activeStep, selectedCategoryId: $selectedCategoryId, selectedSubcategory: $selectedSubcategory, hasAttemptedSubmit: $hasAttemptedSubmit, discountTierError: $discountTierError, sellerSku: $sellerSku, selectedWarehouseIds: $selectedWarehouseIds, warehouseStockMap: $warehouseStockMap, hasVariants: $hasVariants, variantOptions: $variantOptions, variants: $variants, condition: $condition, nameF: $nameF, descriptionF: $descriptionF)';
}


}

/// @nodoc
abstract mixin class $AddProductStateCopyWith<$Res>  {
  factory $AddProductStateCopyWith(AddProductState value, $Res Function(AddProductState) _then) = _$AddProductStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isUploadingVideo, bool isLocalDeliveryOnly, String selectedProvince, double? latitude, double? longitude, List<ImageModel> imageModels, XFile? videoFile, int? videoDurationSeconds, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, bool addressVerified, bool isPerishable, bool isDigital, bool isAgeRestricted, String? digitalType, String? macosDownloadUrl, String? windowsDownloadUrl, String? linuxDownloadUrl, String? bookSourceUrl, int? deviceLimit, bool standardEnabled, bool expressEnabled, bool sameDayEnabled, int minimumOrderQuantity, bool freeShipping, bool savedExpressEnabled, bool savedSameDayEnabled, bool savedStandardEnabled, String? errorMessage, String? skuError, bool isSuccess, String selectedSupplierType, String selectedSupplierCurrency, bool hasTracking, bool inventoryManaged, bool trackQuantity, bool allowBackorder, bool lowStockAlertEnabled, int activeStep, String? selectedCategoryId, String? selectedSubcategory, bool hasAttemptedSubmit, bool discountTierError, String? sellerSku, List<String> selectedWarehouseIds, Map<String, int> warehouseStockMap, bool hasVariants, List<VariantOption> variantOptions, List<ProductVariantEntry> variants, String? condition, String? nameF, String? descriptionF
});




}
/// @nodoc
class _$AddProductStateCopyWithImpl<$Res>
    implements $AddProductStateCopyWith<$Res> {
  _$AddProductStateCopyWithImpl(this._self, this._then);

  final AddProductState _self;
  final $Res Function(AddProductState) _then;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isUploadingVideo = null,Object? isLocalDeliveryOnly = null,Object? selectedProvince = null,Object? latitude = freezed,Object? longitude = freezed,Object? imageModels = null,Object? videoFile = freezed,Object? videoDurationSeconds = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? addressVerified = null,Object? isPerishable = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? macosDownloadUrl = freezed,Object? windowsDownloadUrl = freezed,Object? linuxDownloadUrl = freezed,Object? bookSourceUrl = freezed,Object? deviceLimit = freezed,Object? standardEnabled = null,Object? expressEnabled = null,Object? sameDayEnabled = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? savedExpressEnabled = null,Object? savedSameDayEnabled = null,Object? savedStandardEnabled = null,Object? errorMessage = freezed,Object? skuError = freezed,Object? isSuccess = null,Object? selectedSupplierType = null,Object? selectedSupplierCurrency = null,Object? hasTracking = null,Object? inventoryManaged = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockAlertEnabled = null,Object? activeStep = null,Object? selectedCategoryId = freezed,Object? selectedSubcategory = freezed,Object? hasAttemptedSubmit = null,Object? discountTierError = null,Object? sellerSku = freezed,Object? selectedWarehouseIds = null,Object? warehouseStockMap = null,Object? hasVariants = null,Object? variantOptions = null,Object? variants = null,Object? condition = freezed,Object? nameF = freezed,Object? descriptionF = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isUploadingVideo: null == isUploadingVideo ? _self.isUploadingVideo : isUploadingVideo // ignore: cast_nullable_to_non_nullable
as bool,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: null == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,imageModels: null == imageModels ? _self.imageModels : imageModels // ignore: cast_nullable_to_non_nullable
as List<ImageModel>,videoFile: freezed == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as XFile?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,addressSuggestions: null == addressSuggestions ? _self.addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,addressVerified: null == addressVerified ? _self.addressVerified : addressVerified // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,macosDownloadUrl: freezed == macosDownloadUrl ? _self.macosDownloadUrl : macosDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,windowsDownloadUrl: freezed == windowsDownloadUrl ? _self.windowsDownloadUrl : windowsDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,linuxDownloadUrl: freezed == linuxDownloadUrl ? _self.linuxDownloadUrl : linuxDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,bookSourceUrl: freezed == bookSourceUrl ? _self.bookSourceUrl : bookSourceUrl // ignore: cast_nullable_to_non_nullable
as String?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,standardEnabled: null == standardEnabled ? _self.standardEnabled : standardEnabled // ignore: cast_nullable_to_non_nullable
as bool,expressEnabled: null == expressEnabled ? _self.expressEnabled : expressEnabled // ignore: cast_nullable_to_non_nullable
as bool,sameDayEnabled: null == sameDayEnabled ? _self.sameDayEnabled : sameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,savedExpressEnabled: null == savedExpressEnabled ? _self.savedExpressEnabled : savedExpressEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedSameDayEnabled: null == savedSameDayEnabled ? _self.savedSameDayEnabled : savedSameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedStandardEnabled: null == savedStandardEnabled ? _self.savedStandardEnabled : savedStandardEnabled // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,skuError: freezed == skuError ? _self.skuError : skuError // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,selectedSupplierType: null == selectedSupplierType ? _self.selectedSupplierType : selectedSupplierType // ignore: cast_nullable_to_non_nullable
as String,selectedSupplierCurrency: null == selectedSupplierCurrency ? _self.selectedSupplierCurrency : selectedSupplierCurrency // ignore: cast_nullable_to_non_nullable
as String,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,inventoryManaged: null == inventoryManaged ? _self.inventoryManaged : inventoryManaged // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockAlertEnabled: null == lowStockAlertEnabled ? _self.lowStockAlertEnabled : lowStockAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,activeStep: null == activeStep ? _self.activeStep : activeStep // ignore: cast_nullable_to_non_nullable
as int,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as String?,selectedSubcategory: freezed == selectedSubcategory ? _self.selectedSubcategory : selectedSubcategory // ignore: cast_nullable_to_non_nullable
as String?,hasAttemptedSubmit: null == hasAttemptedSubmit ? _self.hasAttemptedSubmit : hasAttemptedSubmit // ignore: cast_nullable_to_non_nullable
as bool,discountTierError: null == discountTierError ? _self.discountTierError : discountTierError // ignore: cast_nullable_to_non_nullable
as bool,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,selectedWarehouseIds: null == selectedWarehouseIds ? _self.selectedWarehouseIds : selectedWarehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>,warehouseStockMap: null == warehouseStockMap ? _self.warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variantOptions: null == variantOptions ? _self.variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariantEntry>,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddProductState].
extension AddProductStatePatterns on AddProductState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddProductState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddProductState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddProductState value)  $default,){
final _that = this;
switch (_that) {
case _AddProductState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddProductState value)?  $default,){
final _that = this;
switch (_that) {
case _AddProductState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isUploadingVideo,  bool isLocalDeliveryOnly,  String selectedProvince,  double? latitude,  double? longitude,  List<ImageModel> imageModels,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  bool addressVerified,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  bool standardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  bool savedExpressEnabled,  bool savedSameDayEnabled,  bool savedStandardEnabled,  String? errorMessage,  String? skuError,  bool isSuccess,  String selectedSupplierType,  String selectedSupplierCurrency,  bool hasTracking,  bool inventoryManaged,  bool trackQuantity,  bool allowBackorder,  bool lowStockAlertEnabled,  int activeStep,  String? selectedCategoryId,  String? selectedSubcategory,  bool hasAttemptedSubmit,  bool discountTierError,  String? sellerSku,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  String? nameF,  String? descriptionF)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddProductState() when $default != null:
return $default(_that.isLoading,_that.isUploadingVideo,_that.isLocalDeliveryOnly,_that.selectedProvince,_that.latitude,_that.longitude,_that.imageModels,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.addressVerified,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.standardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.savedExpressEnabled,_that.savedSameDayEnabled,_that.savedStandardEnabled,_that.errorMessage,_that.skuError,_that.isSuccess,_that.selectedSupplierType,_that.selectedSupplierCurrency,_that.hasTracking,_that.inventoryManaged,_that.trackQuantity,_that.allowBackorder,_that.lowStockAlertEnabled,_that.activeStep,_that.selectedCategoryId,_that.selectedSubcategory,_that.hasAttemptedSubmit,_that.discountTierError,_that.sellerSku,_that.selectedWarehouseIds,_that.warehouseStockMap,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.nameF,_that.descriptionF);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isUploadingVideo,  bool isLocalDeliveryOnly,  String selectedProvince,  double? latitude,  double? longitude,  List<ImageModel> imageModels,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  bool addressVerified,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  bool standardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  bool savedExpressEnabled,  bool savedSameDayEnabled,  bool savedStandardEnabled,  String? errorMessage,  String? skuError,  bool isSuccess,  String selectedSupplierType,  String selectedSupplierCurrency,  bool hasTracking,  bool inventoryManaged,  bool trackQuantity,  bool allowBackorder,  bool lowStockAlertEnabled,  int activeStep,  String? selectedCategoryId,  String? selectedSubcategory,  bool hasAttemptedSubmit,  bool discountTierError,  String? sellerSku,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  String? nameF,  String? descriptionF)  $default,) {final _that = this;
switch (_that) {
case _AddProductState():
return $default(_that.isLoading,_that.isUploadingVideo,_that.isLocalDeliveryOnly,_that.selectedProvince,_that.latitude,_that.longitude,_that.imageModels,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.addressVerified,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.standardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.savedExpressEnabled,_that.savedSameDayEnabled,_that.savedStandardEnabled,_that.errorMessage,_that.skuError,_that.isSuccess,_that.selectedSupplierType,_that.selectedSupplierCurrency,_that.hasTracking,_that.inventoryManaged,_that.trackQuantity,_that.allowBackorder,_that.lowStockAlertEnabled,_that.activeStep,_that.selectedCategoryId,_that.selectedSubcategory,_that.hasAttemptedSubmit,_that.discountTierError,_that.sellerSku,_that.selectedWarehouseIds,_that.warehouseStockMap,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.nameF,_that.descriptionF);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isUploadingVideo,  bool isLocalDeliveryOnly,  String selectedProvince,  double? latitude,  double? longitude,  List<ImageModel> imageModels,  XFile? videoFile,  int? videoDurationSeconds,  List<Map<String, dynamic>> addressSuggestions,  bool showSuggestions,  bool addressVerified,  bool isPerishable,  bool isDigital,  bool isAgeRestricted,  String? digitalType,  String? macosDownloadUrl,  String? windowsDownloadUrl,  String? linuxDownloadUrl,  String? bookSourceUrl,  int? deviceLimit,  bool standardEnabled,  bool expressEnabled,  bool sameDayEnabled,  int minimumOrderQuantity,  bool freeShipping,  bool savedExpressEnabled,  bool savedSameDayEnabled,  bool savedStandardEnabled,  String? errorMessage,  String? skuError,  bool isSuccess,  String selectedSupplierType,  String selectedSupplierCurrency,  bool hasTracking,  bool inventoryManaged,  bool trackQuantity,  bool allowBackorder,  bool lowStockAlertEnabled,  int activeStep,  String? selectedCategoryId,  String? selectedSubcategory,  bool hasAttemptedSubmit,  bool discountTierError,  String? sellerSku,  List<String> selectedWarehouseIds,  Map<String, int> warehouseStockMap,  bool hasVariants,  List<VariantOption> variantOptions,  List<ProductVariantEntry> variants,  String? condition,  String? nameF,  String? descriptionF)?  $default,) {final _that = this;
switch (_that) {
case _AddProductState() when $default != null:
return $default(_that.isLoading,_that.isUploadingVideo,_that.isLocalDeliveryOnly,_that.selectedProvince,_that.latitude,_that.longitude,_that.imageModels,_that.videoFile,_that.videoDurationSeconds,_that.addressSuggestions,_that.showSuggestions,_that.addressVerified,_that.isPerishable,_that.isDigital,_that.isAgeRestricted,_that.digitalType,_that.macosDownloadUrl,_that.windowsDownloadUrl,_that.linuxDownloadUrl,_that.bookSourceUrl,_that.deviceLimit,_that.standardEnabled,_that.expressEnabled,_that.sameDayEnabled,_that.minimumOrderQuantity,_that.freeShipping,_that.savedExpressEnabled,_that.savedSameDayEnabled,_that.savedStandardEnabled,_that.errorMessage,_that.skuError,_that.isSuccess,_that.selectedSupplierType,_that.selectedSupplierCurrency,_that.hasTracking,_that.inventoryManaged,_that.trackQuantity,_that.allowBackorder,_that.lowStockAlertEnabled,_that.activeStep,_that.selectedCategoryId,_that.selectedSubcategory,_that.hasAttemptedSubmit,_that.discountTierError,_that.sellerSku,_that.selectedWarehouseIds,_that.warehouseStockMap,_that.hasVariants,_that.variantOptions,_that.variants,_that.condition,_that.nameF,_that.descriptionF);case _:
  return null;

}
}

}

/// @nodoc


class _AddProductState implements AddProductState {
  const _AddProductState({this.isLoading = false, this.isUploadingVideo = false, this.isLocalDeliveryOnly = false, this.selectedProvince = ProvinceCodeValues.ontario, this.latitude, this.longitude, final  List<ImageModel> imageModels = const [], this.videoFile, this.videoDurationSeconds, final  List<Map<String, dynamic>> addressSuggestions = const [], this.showSuggestions = false, this.addressVerified = false, this.isPerishable = false, this.isDigital = false, this.isAgeRestricted = false, this.digitalType, this.macosDownloadUrl, this.windowsDownloadUrl, this.linuxDownloadUrl, this.bookSourceUrl, this.deviceLimit, this.standardEnabled = true, this.expressEnabled = false, this.sameDayEnabled = false, this.minimumOrderQuantity = 1, this.freeShipping = false, this.savedExpressEnabled = false, this.savedSameDayEnabled = false, this.savedStandardEnabled = true, this.errorMessage, this.skuError, this.isSuccess = false, this.selectedSupplierType = SupplierTypeValues.aliexpress, this.selectedSupplierCurrency = SupplierCurrencyValues.usd, this.hasTracking = false, this.inventoryManaged = true, this.trackQuantity = true, this.allowBackorder = false, this.lowStockAlertEnabled = false, this.activeStep = 0, this.selectedCategoryId, this.selectedSubcategory, this.hasAttemptedSubmit = false, this.discountTierError = false, this.sellerSku, final  List<String> selectedWarehouseIds = const [], final  Map<String, int> warehouseStockMap = const {}, this.hasVariants = false, final  List<VariantOption> variantOptions = const [], final  List<ProductVariantEntry> variants = const [], this.condition, this.nameF, this.descriptionF}): _imageModels = imageModels,_addressSuggestions = addressSuggestions,_selectedWarehouseIds = selectedWarehouseIds,_warehouseStockMap = warehouseStockMap,_variantOptions = variantOptions,_variants = variants;
  

@override@JsonKey() final  bool isLoading;
// PROD-C4: true only during the R2 video upload step inside addProduct()
@override@JsonKey() final  bool isUploadingVideo;
@override@JsonKey() final  bool isLocalDeliveryOnly;
@override@JsonKey() final  String selectedProvince;
@override final  double? latitude;
@override final  double? longitude;
 final  List<ImageModel> _imageModels;
@override@JsonKey() List<ImageModel> get imageModels {
  if (_imageModels is EqualUnmodifiableListView) return _imageModels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageModels);
}

@override final  XFile? videoFile;
@override final  int? videoDurationSeconds;
 final  List<Map<String, dynamic>> _addressSuggestions;
@override@JsonKey() List<Map<String, dynamic>> get addressSuggestions {
  if (_addressSuggestions is EqualUnmodifiableListView) return _addressSuggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addressSuggestions);
}

@override@JsonKey() final  bool showSuggestions;
@override@JsonKey() final  bool addressVerified;
// true when address selected from Geoapify
@override@JsonKey() final  bool isPerishable;
@override@JsonKey() final  bool isDigital;
@override@JsonKey() final  bool isAgeRestricted;
@override final  String? digitalType;
// 'software' | 'book' | null
@override final  String? macosDownloadUrl;
@override final  String? windowsDownloadUrl;
@override final  String? linuxDownloadUrl;
@override final  String? bookSourceUrl;
@override final  int? deviceLimit;
@override@JsonKey() final  bool standardEnabled;
@override@JsonKey() final  bool expressEnabled;
@override@JsonKey() final  bool sameDayEnabled;
@override@JsonKey() final  int minimumOrderQuantity;
@override@JsonKey() final  bool freeShipping;
// H-03: freeShippingAt10Plus removed - never stored/used on backend
@override@JsonKey() final  bool savedExpressEnabled;
// Saved state when free shipping toggled on
@override@JsonKey() final  bool savedSameDayEnabled;
// Saved state when free shipping toggled on
@override@JsonKey() final  bool savedStandardEnabled;
// Saved state when digital mode toggled on
@override final  String? errorMessage;
@override final  String? skuError;
// PROD-H2: Inline error for SKU collisions
@override@JsonKey() final  bool isSuccess;
// C-03: Business logic state moved from Screen to ViewModel/State
@override@JsonKey() final  String selectedSupplierType;
@override@JsonKey() final  String selectedSupplierCurrency;
@override@JsonKey() final  bool hasTracking;
@override@JsonKey() final  bool inventoryManaged;
@override@JsonKey() final  bool trackQuantity;
@override@JsonKey() final  bool allowBackorder;
@override@JsonKey() final  bool lowStockAlertEnabled;
@override@JsonKey() final  int activeStep;
@override final  String? selectedCategoryId;
@override final  String? selectedSubcategory;
@override@JsonKey() final  bool hasAttemptedSubmit;
@override@JsonKey() final  bool discountTierError;
// Multi-warehouse fields
@override final  String? sellerSku;
 final  List<String> _selectedWarehouseIds;
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

// warehouseId → stock qty
// N-09: Variant builder fields
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
// ProductConditionValues: new|like_new|good|fair|for_parts
// Bill 96: French translation fields (optional, recommended for Quebec market)
@override final  String? nameF;
@override final  String? descriptionF;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddProductStateCopyWith<_AddProductState> get copyWith => __$AddProductStateCopyWithImpl<_AddProductState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddProductState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isUploadingVideo, isUploadingVideo) || other.isUploadingVideo == isUploadingVideo)&&(identical(other.isLocalDeliveryOnly, isLocalDeliveryOnly) || other.isLocalDeliveryOnly == isLocalDeliveryOnly)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other._imageModels, _imageModels)&&(identical(other.videoFile, videoFile) || other.videoFile == videoFile)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&const DeepCollectionEquality().equals(other._addressSuggestions, _addressSuggestions)&&(identical(other.showSuggestions, showSuggestions) || other.showSuggestions == showSuggestions)&&(identical(other.addressVerified, addressVerified) || other.addressVerified == addressVerified)&&(identical(other.isPerishable, isPerishable) || other.isPerishable == isPerishable)&&(identical(other.isDigital, isDigital) || other.isDigital == isDigital)&&(identical(other.isAgeRestricted, isAgeRestricted) || other.isAgeRestricted == isAgeRestricted)&&(identical(other.digitalType, digitalType) || other.digitalType == digitalType)&&(identical(other.macosDownloadUrl, macosDownloadUrl) || other.macosDownloadUrl == macosDownloadUrl)&&(identical(other.windowsDownloadUrl, windowsDownloadUrl) || other.windowsDownloadUrl == windowsDownloadUrl)&&(identical(other.linuxDownloadUrl, linuxDownloadUrl) || other.linuxDownloadUrl == linuxDownloadUrl)&&(identical(other.bookSourceUrl, bookSourceUrl) || other.bookSourceUrl == bookSourceUrl)&&(identical(other.deviceLimit, deviceLimit) || other.deviceLimit == deviceLimit)&&(identical(other.standardEnabled, standardEnabled) || other.standardEnabled == standardEnabled)&&(identical(other.expressEnabled, expressEnabled) || other.expressEnabled == expressEnabled)&&(identical(other.sameDayEnabled, sameDayEnabled) || other.sameDayEnabled == sameDayEnabled)&&(identical(other.minimumOrderQuantity, minimumOrderQuantity) || other.minimumOrderQuantity == minimumOrderQuantity)&&(identical(other.freeShipping, freeShipping) || other.freeShipping == freeShipping)&&(identical(other.savedExpressEnabled, savedExpressEnabled) || other.savedExpressEnabled == savedExpressEnabled)&&(identical(other.savedSameDayEnabled, savedSameDayEnabled) || other.savedSameDayEnabled == savedSameDayEnabled)&&(identical(other.savedStandardEnabled, savedStandardEnabled) || other.savedStandardEnabled == savedStandardEnabled)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.skuError, skuError) || other.skuError == skuError)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.selectedSupplierType, selectedSupplierType) || other.selectedSupplierType == selectedSupplierType)&&(identical(other.selectedSupplierCurrency, selectedSupplierCurrency) || other.selectedSupplierCurrency == selectedSupplierCurrency)&&(identical(other.hasTracking, hasTracking) || other.hasTracking == hasTracking)&&(identical(other.inventoryManaged, inventoryManaged) || other.inventoryManaged == inventoryManaged)&&(identical(other.trackQuantity, trackQuantity) || other.trackQuantity == trackQuantity)&&(identical(other.allowBackorder, allowBackorder) || other.allowBackorder == allowBackorder)&&(identical(other.lowStockAlertEnabled, lowStockAlertEnabled) || other.lowStockAlertEnabled == lowStockAlertEnabled)&&(identical(other.activeStep, activeStep) || other.activeStep == activeStep)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.selectedSubcategory, selectedSubcategory) || other.selectedSubcategory == selectedSubcategory)&&(identical(other.hasAttemptedSubmit, hasAttemptedSubmit) || other.hasAttemptedSubmit == hasAttemptedSubmit)&&(identical(other.discountTierError, discountTierError) || other.discountTierError == discountTierError)&&(identical(other.sellerSku, sellerSku) || other.sellerSku == sellerSku)&&const DeepCollectionEquality().equals(other._selectedWarehouseIds, _selectedWarehouseIds)&&const DeepCollectionEquality().equals(other._warehouseStockMap, _warehouseStockMap)&&(identical(other.hasVariants, hasVariants) || other.hasVariants == hasVariants)&&const DeepCollectionEquality().equals(other._variantOptions, _variantOptions)&&const DeepCollectionEquality().equals(other._variants, _variants)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.nameF, nameF) || other.nameF == nameF)&&(identical(other.descriptionF, descriptionF) || other.descriptionF == descriptionF));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,isUploadingVideo,isLocalDeliveryOnly,selectedProvince,latitude,longitude,const DeepCollectionEquality().hash(_imageModels),videoFile,videoDurationSeconds,const DeepCollectionEquality().hash(_addressSuggestions),showSuggestions,addressVerified,isPerishable,isDigital,isAgeRestricted,digitalType,macosDownloadUrl,windowsDownloadUrl,linuxDownloadUrl,bookSourceUrl,deviceLimit,standardEnabled,expressEnabled,sameDayEnabled,minimumOrderQuantity,freeShipping,savedExpressEnabled,savedSameDayEnabled,savedStandardEnabled,errorMessage,skuError,isSuccess,selectedSupplierType,selectedSupplierCurrency,hasTracking,inventoryManaged,trackQuantity,allowBackorder,lowStockAlertEnabled,activeStep,selectedCategoryId,selectedSubcategory,hasAttemptedSubmit,discountTierError,sellerSku,const DeepCollectionEquality().hash(_selectedWarehouseIds),const DeepCollectionEquality().hash(_warehouseStockMap),hasVariants,const DeepCollectionEquality().hash(_variantOptions),const DeepCollectionEquality().hash(_variants),condition,nameF,descriptionF]);

@override
String toString() {
  return 'AddProductState(isLoading: $isLoading, isUploadingVideo: $isUploadingVideo, isLocalDeliveryOnly: $isLocalDeliveryOnly, selectedProvince: $selectedProvince, latitude: $latitude, longitude: $longitude, imageModels: $imageModels, videoFile: $videoFile, videoDurationSeconds: $videoDurationSeconds, addressSuggestions: $addressSuggestions, showSuggestions: $showSuggestions, addressVerified: $addressVerified, isPerishable: $isPerishable, isDigital: $isDigital, isAgeRestricted: $isAgeRestricted, digitalType: $digitalType, macosDownloadUrl: $macosDownloadUrl, windowsDownloadUrl: $windowsDownloadUrl, linuxDownloadUrl: $linuxDownloadUrl, bookSourceUrl: $bookSourceUrl, deviceLimit: $deviceLimit, standardEnabled: $standardEnabled, expressEnabled: $expressEnabled, sameDayEnabled: $sameDayEnabled, minimumOrderQuantity: $minimumOrderQuantity, freeShipping: $freeShipping, savedExpressEnabled: $savedExpressEnabled, savedSameDayEnabled: $savedSameDayEnabled, savedStandardEnabled: $savedStandardEnabled, errorMessage: $errorMessage, skuError: $skuError, isSuccess: $isSuccess, selectedSupplierType: $selectedSupplierType, selectedSupplierCurrency: $selectedSupplierCurrency, hasTracking: $hasTracking, inventoryManaged: $inventoryManaged, trackQuantity: $trackQuantity, allowBackorder: $allowBackorder, lowStockAlertEnabled: $lowStockAlertEnabled, activeStep: $activeStep, selectedCategoryId: $selectedCategoryId, selectedSubcategory: $selectedSubcategory, hasAttemptedSubmit: $hasAttemptedSubmit, discountTierError: $discountTierError, sellerSku: $sellerSku, selectedWarehouseIds: $selectedWarehouseIds, warehouseStockMap: $warehouseStockMap, hasVariants: $hasVariants, variantOptions: $variantOptions, variants: $variants, condition: $condition, nameF: $nameF, descriptionF: $descriptionF)';
}


}

/// @nodoc
abstract mixin class _$AddProductStateCopyWith<$Res> implements $AddProductStateCopyWith<$Res> {
  factory _$AddProductStateCopyWith(_AddProductState value, $Res Function(_AddProductState) _then) = __$AddProductStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isUploadingVideo, bool isLocalDeliveryOnly, String selectedProvince, double? latitude, double? longitude, List<ImageModel> imageModels, XFile? videoFile, int? videoDurationSeconds, List<Map<String, dynamic>> addressSuggestions, bool showSuggestions, bool addressVerified, bool isPerishable, bool isDigital, bool isAgeRestricted, String? digitalType, String? macosDownloadUrl, String? windowsDownloadUrl, String? linuxDownloadUrl, String? bookSourceUrl, int? deviceLimit, bool standardEnabled, bool expressEnabled, bool sameDayEnabled, int minimumOrderQuantity, bool freeShipping, bool savedExpressEnabled, bool savedSameDayEnabled, bool savedStandardEnabled, String? errorMessage, String? skuError, bool isSuccess, String selectedSupplierType, String selectedSupplierCurrency, bool hasTracking, bool inventoryManaged, bool trackQuantity, bool allowBackorder, bool lowStockAlertEnabled, int activeStep, String? selectedCategoryId, String? selectedSubcategory, bool hasAttemptedSubmit, bool discountTierError, String? sellerSku, List<String> selectedWarehouseIds, Map<String, int> warehouseStockMap, bool hasVariants, List<VariantOption> variantOptions, List<ProductVariantEntry> variants, String? condition, String? nameF, String? descriptionF
});




}
/// @nodoc
class __$AddProductStateCopyWithImpl<$Res>
    implements _$AddProductStateCopyWith<$Res> {
  __$AddProductStateCopyWithImpl(this._self, this._then);

  final _AddProductState _self;
  final $Res Function(_AddProductState) _then;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isUploadingVideo = null,Object? isLocalDeliveryOnly = null,Object? selectedProvince = null,Object? latitude = freezed,Object? longitude = freezed,Object? imageModels = null,Object? videoFile = freezed,Object? videoDurationSeconds = freezed,Object? addressSuggestions = null,Object? showSuggestions = null,Object? addressVerified = null,Object? isPerishable = null,Object? isDigital = null,Object? isAgeRestricted = null,Object? digitalType = freezed,Object? macosDownloadUrl = freezed,Object? windowsDownloadUrl = freezed,Object? linuxDownloadUrl = freezed,Object? bookSourceUrl = freezed,Object? deviceLimit = freezed,Object? standardEnabled = null,Object? expressEnabled = null,Object? sameDayEnabled = null,Object? minimumOrderQuantity = null,Object? freeShipping = null,Object? savedExpressEnabled = null,Object? savedSameDayEnabled = null,Object? savedStandardEnabled = null,Object? errorMessage = freezed,Object? skuError = freezed,Object? isSuccess = null,Object? selectedSupplierType = null,Object? selectedSupplierCurrency = null,Object? hasTracking = null,Object? inventoryManaged = null,Object? trackQuantity = null,Object? allowBackorder = null,Object? lowStockAlertEnabled = null,Object? activeStep = null,Object? selectedCategoryId = freezed,Object? selectedSubcategory = freezed,Object? hasAttemptedSubmit = null,Object? discountTierError = null,Object? sellerSku = freezed,Object? selectedWarehouseIds = null,Object? warehouseStockMap = null,Object? hasVariants = null,Object? variantOptions = null,Object? variants = null,Object? condition = freezed,Object? nameF = freezed,Object? descriptionF = freezed,}) {
  return _then(_AddProductState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isUploadingVideo: null == isUploadingVideo ? _self.isUploadingVideo : isUploadingVideo // ignore: cast_nullable_to_non_nullable
as bool,isLocalDeliveryOnly: null == isLocalDeliveryOnly ? _self.isLocalDeliveryOnly : isLocalDeliveryOnly // ignore: cast_nullable_to_non_nullable
as bool,selectedProvince: null == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as String,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,imageModels: null == imageModels ? _self._imageModels : imageModels // ignore: cast_nullable_to_non_nullable
as List<ImageModel>,videoFile: freezed == videoFile ? _self.videoFile : videoFile // ignore: cast_nullable_to_non_nullable
as XFile?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,addressSuggestions: null == addressSuggestions ? _self._addressSuggestions : addressSuggestions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,showSuggestions: null == showSuggestions ? _self.showSuggestions : showSuggestions // ignore: cast_nullable_to_non_nullable
as bool,addressVerified: null == addressVerified ? _self.addressVerified : addressVerified // ignore: cast_nullable_to_non_nullable
as bool,isPerishable: null == isPerishable ? _self.isPerishable : isPerishable // ignore: cast_nullable_to_non_nullable
as bool,isDigital: null == isDigital ? _self.isDigital : isDigital // ignore: cast_nullable_to_non_nullable
as bool,isAgeRestricted: null == isAgeRestricted ? _self.isAgeRestricted : isAgeRestricted // ignore: cast_nullable_to_non_nullable
as bool,digitalType: freezed == digitalType ? _self.digitalType : digitalType // ignore: cast_nullable_to_non_nullable
as String?,macosDownloadUrl: freezed == macosDownloadUrl ? _self.macosDownloadUrl : macosDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,windowsDownloadUrl: freezed == windowsDownloadUrl ? _self.windowsDownloadUrl : windowsDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,linuxDownloadUrl: freezed == linuxDownloadUrl ? _self.linuxDownloadUrl : linuxDownloadUrl // ignore: cast_nullable_to_non_nullable
as String?,bookSourceUrl: freezed == bookSourceUrl ? _self.bookSourceUrl : bookSourceUrl // ignore: cast_nullable_to_non_nullable
as String?,deviceLimit: freezed == deviceLimit ? _self.deviceLimit : deviceLimit // ignore: cast_nullable_to_non_nullable
as int?,standardEnabled: null == standardEnabled ? _self.standardEnabled : standardEnabled // ignore: cast_nullable_to_non_nullable
as bool,expressEnabled: null == expressEnabled ? _self.expressEnabled : expressEnabled // ignore: cast_nullable_to_non_nullable
as bool,sameDayEnabled: null == sameDayEnabled ? _self.sameDayEnabled : sameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,minimumOrderQuantity: null == minimumOrderQuantity ? _self.minimumOrderQuantity : minimumOrderQuantity // ignore: cast_nullable_to_non_nullable
as int,freeShipping: null == freeShipping ? _self.freeShipping : freeShipping // ignore: cast_nullable_to_non_nullable
as bool,savedExpressEnabled: null == savedExpressEnabled ? _self.savedExpressEnabled : savedExpressEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedSameDayEnabled: null == savedSameDayEnabled ? _self.savedSameDayEnabled : savedSameDayEnabled // ignore: cast_nullable_to_non_nullable
as bool,savedStandardEnabled: null == savedStandardEnabled ? _self.savedStandardEnabled : savedStandardEnabled // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,skuError: freezed == skuError ? _self.skuError : skuError // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,selectedSupplierType: null == selectedSupplierType ? _self.selectedSupplierType : selectedSupplierType // ignore: cast_nullable_to_non_nullable
as String,selectedSupplierCurrency: null == selectedSupplierCurrency ? _self.selectedSupplierCurrency : selectedSupplierCurrency // ignore: cast_nullable_to_non_nullable
as String,hasTracking: null == hasTracking ? _self.hasTracking : hasTracking // ignore: cast_nullable_to_non_nullable
as bool,inventoryManaged: null == inventoryManaged ? _self.inventoryManaged : inventoryManaged // ignore: cast_nullable_to_non_nullable
as bool,trackQuantity: null == trackQuantity ? _self.trackQuantity : trackQuantity // ignore: cast_nullable_to_non_nullable
as bool,allowBackorder: null == allowBackorder ? _self.allowBackorder : allowBackorder // ignore: cast_nullable_to_non_nullable
as bool,lowStockAlertEnabled: null == lowStockAlertEnabled ? _self.lowStockAlertEnabled : lowStockAlertEnabled // ignore: cast_nullable_to_non_nullable
as bool,activeStep: null == activeStep ? _self.activeStep : activeStep // ignore: cast_nullable_to_non_nullable
as int,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as String?,selectedSubcategory: freezed == selectedSubcategory ? _self.selectedSubcategory : selectedSubcategory // ignore: cast_nullable_to_non_nullable
as String?,hasAttemptedSubmit: null == hasAttemptedSubmit ? _self.hasAttemptedSubmit : hasAttemptedSubmit // ignore: cast_nullable_to_non_nullable
as bool,discountTierError: null == discountTierError ? _self.discountTierError : discountTierError // ignore: cast_nullable_to_non_nullable
as bool,sellerSku: freezed == sellerSku ? _self.sellerSku : sellerSku // ignore: cast_nullable_to_non_nullable
as String?,selectedWarehouseIds: null == selectedWarehouseIds ? _self._selectedWarehouseIds : selectedWarehouseIds // ignore: cast_nullable_to_non_nullable
as List<String>,warehouseStockMap: null == warehouseStockMap ? _self._warehouseStockMap : warehouseStockMap // ignore: cast_nullable_to_non_nullable
as Map<String, int>,hasVariants: null == hasVariants ? _self.hasVariants : hasVariants // ignore: cast_nullable_to_non_nullable
as bool,variantOptions: null == variantOptions ? _self._variantOptions : variantOptions // ignore: cast_nullable_to_non_nullable
as List<VariantOption>,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariantEntry>,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,nameF: freezed == nameF ? _self.nameF : nameF // ignore: cast_nullable_to_non_nullable
as String?,descriptionF: freezed == descriptionF ? _self.descriptionF : descriptionF // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
