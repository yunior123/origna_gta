import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'variant_models.dart';

part 'add_product_state.freezed.dart';

@freezed
abstract class AddProductState with _$AddProductState {
  const factory AddProductState({
    @Default(false) bool isLoading,
    // PROD-C4: true only during the R2 video upload step inside addProduct()
    @Default(false) bool isUploadingVideo,
    @Default(false) bool isLocalDeliveryOnly,
    @Default(ProvinceCodeValues.ontario) String selectedProvince,
    double? latitude,
    double? longitude,
    @Default([]) List<ImageModel> imageModels,
    XFile? videoFile,
    int? videoDurationSeconds,
    @Default([]) List<Map<String, dynamic>> addressSuggestions,
    @Default(false) bool showSuggestions,
    @Default(false)
    bool addressVerified, // true when address selected from Geoapify
    @Default(false) bool isPerishable,
    @Default(false) bool isDigital,
    @Default(false) bool isAgeRestricted,
    String? digitalType, // 'software' | 'book' | null
    String? macosDownloadUrl,
    String? windowsDownloadUrl,
    String? linuxDownloadUrl,
    String? bookSourceUrl,
    int? deviceLimit,
    @Default(true) bool standardEnabled,
    @Default(false) bool expressEnabled,
    @Default(false) bool sameDayEnabled,
    @Default(1) int minimumOrderQuantity,
    @Default(false) bool freeShipping,
    // H-03: freeShippingAt10Plus removed - never stored/used on backend
    @Default(false)
    bool savedExpressEnabled, // Saved state when free shipping toggled on
    @Default(false)
    bool savedSameDayEnabled, // Saved state when free shipping toggled on
    @Default(true)
    bool savedStandardEnabled, // Saved state when digital mode toggled on
    String? errorMessage,
    String? skuError, // PROD-H2: Inline error for SKU collisions
    @Default(false) bool isSuccess,

    // C-03: Business logic state moved from Screen to ViewModel/State
    @Default(SupplierTypeValues.aliexpress) String selectedSupplierType,
    @Default(SupplierCurrencyValues.usd) String selectedSupplierCurrency,
    @Default(false) bool hasTracking,
    @Default(true) bool inventoryManaged,
    @Default(true) bool trackQuantity,
    @Default(false) bool allowBackorder,
    @Default(false) bool lowStockAlertEnabled,
    @Default(0) int activeStep,
    String? selectedCategoryId,
    String? selectedSubcategory,
    @Default(false) bool hasAttemptedSubmit,
    @Default(false) bool discountTierError,

    // Multi-warehouse fields
    String? sellerSku,
    @Default([]) List<String> selectedWarehouseIds,
    @Default({}) Map<String, int> warehouseStockMap, // warehouseId → stock qty
    // N-09: Variant builder fields
    @Default(false) bool hasVariants,
    @Default([]) List<VariantOption> variantOptions,
    @Default([]) List<ProductVariantEntry> variants,
    String?
    condition, // ProductConditionValues: new|like_new|good|fair|for_parts
    // Bill 96: French translation fields (optional, recommended for Quebec market)
    String? nameF,
    String? descriptionF,
  }) = _AddProductState;
}
