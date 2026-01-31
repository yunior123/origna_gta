import 'package:origna_gta/utils/utils.dart';

class AddProductState {
  final bool isLoading;
  final bool isLocalDeliveryOnly;
  final String selectedProvince;
  final double? latitude;
  final double? longitude;
  final List<ImageModel> imageModels;
  final List<Map<String, dynamic>> addressSuggestions;
  final bool showSuggestions;
  final bool isPerishable;
  final bool standardEnabled;
  final bool expressEnabled;
  final bool sameDayEnabled;
  final String? errorMessage;
  final bool isSuccess;

  AddProductState({
    this.isLoading = false,
    this.isLocalDeliveryOnly = false,
    this.selectedProvince = 'ON',
    this.latitude,
    this.longitude,
    this.imageModels = const [],
    this.addressSuggestions = const [],
    this.showSuggestions = false,
    this.isPerishable = false,
    this.standardEnabled = true,
    this.expressEnabled = false,
    this.sameDayEnabled = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AddProductState copyWith({
    bool? isLoading,
    bool? isLocalDeliveryOnly,
    String? selectedProvince,
    double? latitude,
    double? longitude,
    List<ImageModel>? imageModels,
    List<Map<String, dynamic>>? addressSuggestions,
    bool? showSuggestions,
    bool? isPerishable,
    bool? standardEnabled,
    bool? expressEnabled,
    bool? sameDayEnabled,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AddProductState(
      isLoading: isLoading ?? this.isLoading,
      isLocalDeliveryOnly: isLocalDeliveryOnly ?? this.isLocalDeliveryOnly,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageModels: imageModels ?? this.imageModels,
      addressSuggestions: addressSuggestions ?? this.addressSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      isPerishable: isPerishable ?? this.isPerishable,
      standardEnabled: standardEnabled ?? this.standardEnabled,
      expressEnabled: expressEnabled ?? this.expressEnabled,
      sameDayEnabled: sameDayEnabled ?? this.sameDayEnabled,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
