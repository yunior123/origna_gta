class AddressState {
  final bool isLoading;
  final String? selectedProvince;
  final String? selectedLabel;
  final List<Map<String, dynamic>> addressSuggestions;
  final bool showSuggestions;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
  final bool isSuccess;

  AddressState({
    this.isLoading = false,
    this.selectedProvince = 'ON',
    this.selectedLabel = 'Home',
    this.addressSuggestions = const [],
    this.showSuggestions = false,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.isSuccess = false,
  });

  AddressState copyWith({
    bool? isLoading,
    String? selectedProvince,
    String? selectedLabel,
    List<Map<String, dynamic>>? addressSuggestions,
    bool? showSuggestions,
    double? latitude,
    double? longitude,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AddressState(
      isLoading: isLoading ?? this.isLoading,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      addressSuggestions: addressSuggestions ?? this.addressSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
