import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/variant_models.dart';
import 'package:origna_gta/utils/utils.dart';

part 'edit_product_state.freezed.dart';

@freezed
abstract class EditProductState with _$EditProductState {
  const factory EditProductState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(false) bool isSuccess,
    @Default(false) bool isSoldOut,
    @Default(false) bool isLocalDeliveryOnly,
    @Default(false) bool isPerishable,
    @Default(false) bool isDigital,
    @Default(false) bool isAgeRestricted,
    String? digitalType,
    String? macosDownloadUrl,
    String? windowsDownloadUrl,
    String? linuxDownloadUrl,
    String? bookSourceUrl,
    int? deviceLimit,
    @Default([]) List<String> existingImageUrls,
    @Default([]) List<ImageModel> newImages,
    String? existingVideoUrl,
    XFile? videoFile,
    int? videoDurationSeconds,
    @Default([]) List<Map<String, dynamic>> addressSuggestions,
    @Default(false) bool showSuggestions,
    @Default(ProvinceCodeValues.ontario) String selectedProvince,
    double? latitude,
    double? longitude,
    @Default(true) bool standardEnabled,
    @Default(true)
    bool savedStandardEnabled, // Saved state when digital mode toggled on
    @Default(false) bool expressEnabled,
    @Default(false) bool sameDayEnabled,
    @Default(1) int minimumOrderQuantity,
    @Default(false) bool freeShipping,
    String? taxCode,
    // Variant fields — parity with AddProductState
    @Default(false) bool hasVariants,
    @Default([]) List<VariantOption> variantOptions,
    @Default([]) List<ProductVariantEntry> variants,
    String? condition,
    // Warehouse fields — parity with AddProductState
    @Default([]) List<String> selectedWarehouseIds,
    @Default({}) Map<String, int> warehouseStockMap,
  }) = _EditProductState;
}
