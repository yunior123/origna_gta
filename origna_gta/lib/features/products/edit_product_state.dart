import 'package:origna_gta/utils/utils.dart';


class EditProductState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool isSoldOut;
  final bool isLocalDeliveryOnly;
  final bool isPerishable;
  final List<String> existingImageUrls;
  final List<ImageModel> newImages;
  final List<Map<String, dynamic>> addressSuggestions;
  final bool showSuggestions;
  final String selectedProvince;
  final double? latitude;
  final double? longitude;
  final bool standardEnabled;
  final bool expressEnabled;
  final bool sameDayEnabled;

  EditProductState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.isSoldOut = false,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.existingImageUrls = const [],
    this.newImages = const [],
    this.addressSuggestions = const [],
    this.showSuggestions = false,
    this.selectedProvince = 'ON',
    this.latitude,
    this.longitude,
    this.standardEnabled = true,
    this.expressEnabled = false,
    this.sameDayEnabled = false,
  });

  EditProductState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? isSoldOut,
    bool? isLocalDeliveryOnly,
    bool? isPerishable,
    List<String>? existingImageUrls,
    List<ImageModel>? newImages,
    List<Map<String, dynamic>>? addressSuggestions,
    bool? showSuggestions,
    String? selectedProvince,
    double? latitude,
    double? longitude,
    bool? standardEnabled,
    bool? expressEnabled,
    bool? sameDayEnabled,
  }) {
    return EditProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // We want to be able to null it out
      isSuccess: isSuccess ?? this.isSuccess,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      isLocalDeliveryOnly: isLocalDeliveryOnly ?? this.isLocalDeliveryOnly,
      isPerishable: isPerishable ?? this.isPerishable,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
      newImages: newImages ?? this.newImages,
      addressSuggestions: addressSuggestions ?? this.addressSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      standardEnabled: standardEnabled ?? this.standardEnabled,
      expressEnabled: expressEnabled ?? this.expressEnabled,
      sameDayEnabled: sameDayEnabled ?? this.sameDayEnabled,
    );
  }
}
