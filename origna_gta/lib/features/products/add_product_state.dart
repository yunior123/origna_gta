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
    );
  }
}
