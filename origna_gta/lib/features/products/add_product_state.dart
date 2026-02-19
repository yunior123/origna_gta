import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Sentinel to explicitly clear nullable fields in copyWith.
const _sentinel = Object();

class AddProductState {
  final bool isLoading;
  final bool isLocalDeliveryOnly;
  final String selectedProvince;
  final double? latitude;
  final double? longitude;
  final List<ImageModel> imageModels;
  final List<Map<String, dynamic>> addressSuggestions;
  final bool showSuggestions;
  final bool addressVerified; // true when address selected from Geoapify
  final bool isPerishable;
  final bool isDigital;
  final String? digitalType;          // 'software' | 'book' | null
  final String? macosDownloadUrl;
  final String? windowsDownloadUrl;
  final String? linuxDownloadUrl;
  final String? bookSourceUrl;
  final int? deviceLimit;
  final bool standardEnabled;
  final bool expressEnabled;
  final bool sameDayEnabled;
  final int minimumOrderQuantity;
  final bool freeShipping;
  final bool freeShippingAt10Plus; // Free shipping for 10+ item orders
  final bool savedExpressEnabled; // Saved state when free shipping toggled on
  final bool savedSameDayEnabled; // Saved state when free shipping toggled on
  final String? errorMessage;
  final bool isSuccess;
  // Multi-warehouse fields
  final String? sellerSku;
  final List<String> selectedWarehouseIds;
  final Map<String, int> warehouseStockMap; // warehouseId → stock qty

  AddProductState({
    this.isLoading = false,
    this.isLocalDeliveryOnly = false,
    this.selectedProvince = ProvinceCodeValues.ontario,
    this.latitude,
    this.longitude,
    this.imageModels = const [],
    this.addressSuggestions = const [],
    this.showSuggestions = false,
    this.addressVerified = false,
    this.isPerishable = false,
    this.isDigital = false,
    this.digitalType,
    this.macosDownloadUrl,
    this.windowsDownloadUrl,
    this.linuxDownloadUrl,
    this.bookSourceUrl,
    this.deviceLimit,
    this.standardEnabled = true,
    this.expressEnabled = false,
    this.sameDayEnabled = false,
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.freeShippingAt10Plus = false,
    this.savedExpressEnabled = false,
    this.savedSameDayEnabled = false,
    this.errorMessage,
    this.isSuccess = false,
    this.sellerSku,
    this.selectedWarehouseIds = const [],
    this.warehouseStockMap = const {},
  });

  /// Use `clearError()` to explicitly set errorMessage to null.
  /// Without it, `copyWith()` preserves the current errorMessage.
  AddProductState copyWith({
    bool? isLoading,
    bool? isLocalDeliveryOnly,
    String? selectedProvince,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    List<ImageModel>? imageModels,
    List<Map<String, dynamic>>? addressSuggestions,
    bool? showSuggestions,
    bool? addressVerified,
    bool? isPerishable,
    bool? isDigital,
    Object? digitalType = _sentinel,
    Object? macosDownloadUrl = _sentinel,
    Object? windowsDownloadUrl = _sentinel,
    Object? linuxDownloadUrl = _sentinel,
    Object? bookSourceUrl = _sentinel,
    Object? deviceLimit = _sentinel,
    bool? standardEnabled,
    bool? expressEnabled,
    bool? sameDayEnabled,
    int? minimumOrderQuantity,
    bool? freeShipping,
    bool? freeShippingAt10Plus,
    bool? savedExpressEnabled,
    bool? savedSameDayEnabled,
    Object? errorMessage = _sentinel,
    bool? isSuccess,
    Object? sellerSku = _sentinel,
    List<String>? selectedWarehouseIds,
    Map<String, int>? warehouseStockMap,
  }) {
    return AddProductState(
      isLoading: isLoading ?? this.isLoading,
      isLocalDeliveryOnly: isLocalDeliveryOnly ?? this.isLocalDeliveryOnly,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      latitude: latitude == _sentinel ? this.latitude : latitude as double?,
      longitude: longitude == _sentinel ? this.longitude : longitude as double?,
      imageModels: imageModels ?? this.imageModels,
      addressSuggestions: addressSuggestions ?? this.addressSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      addressVerified: addressVerified ?? this.addressVerified,
      isPerishable: isPerishable ?? this.isPerishable,
      isDigital: isDigital ?? this.isDigital,
      digitalType: digitalType == _sentinel ? this.digitalType : digitalType as String?,
      macosDownloadUrl: macosDownloadUrl == _sentinel ? this.macosDownloadUrl : macosDownloadUrl as String?,
      windowsDownloadUrl: windowsDownloadUrl == _sentinel ? this.windowsDownloadUrl : windowsDownloadUrl as String?,
      linuxDownloadUrl: linuxDownloadUrl == _sentinel ? this.linuxDownloadUrl : linuxDownloadUrl as String?,
      bookSourceUrl: bookSourceUrl == _sentinel ? this.bookSourceUrl : bookSourceUrl as String?,
      deviceLimit: deviceLimit == _sentinel ? this.deviceLimit : deviceLimit as int?,
      standardEnabled: standardEnabled ?? this.standardEnabled,
      expressEnabled: expressEnabled ?? this.expressEnabled,
      sameDayEnabled: sameDayEnabled ?? this.sameDayEnabled,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      freeShipping: freeShipping ?? this.freeShipping,
      freeShippingAt10Plus: freeShippingAt10Plus ?? this.freeShippingAt10Plus,
      savedExpressEnabled: savedExpressEnabled ?? this.savedExpressEnabled,
      savedSameDayEnabled: savedSameDayEnabled ?? this.savedSameDayEnabled,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      sellerSku: sellerSku == _sentinel ? this.sellerSku : sellerSku as String?,
      selectedWarehouseIds: selectedWarehouseIds ?? this.selectedWarehouseIds,
      warehouseStockMap: warehouseStockMap ?? this.warehouseStockMap,
    );
  }
}
