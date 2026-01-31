import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'address_state.dart';

final addressViewModelProvider = StateNotifierProvider.autoDispose<AddressViewModel, AddressState>((ref) {
  return AddressViewModel(ref);
});

class AddressViewModel extends StateNotifier<AddressState> {
  final Ref _ref;

  AddressViewModel(this._ref) : super(AddressState());

  void setProvince(String province) => state = state.copyWith(selectedProvince: province);
  void setLabel(String label) => state = state.copyWith(selectedLabel: label);

  void setInitialData(Address? address) {
    if (address != null) {
      state = state.copyWith(
        selectedProvince: address.state,
        selectedLabel: address.label ?? 'Home',
        latitude: address.latitude,
        longitude: address.longitude,
      );
    }
  }

  Future<void> onStreetChanged(String value) async {
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    final suggestions = await _ref.read(locationRepositoryProvider).getAddressSuggestions(value);
    state = state.copyWith(addressSuggestions: suggestions, showSuggestions: suggestions.isNotEmpty);
  }

  void selectAddress(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);
    state = state.copyWith(selectedProvince: details.province, latitude: details.latitude, longitude: details.longitude, showSuggestions: false, addressSuggestions: []);
  }

  Future<void> saveAddress({
    required String street,
    required String apartment,
    required String city,
    required String postalCode,
    required String phoneNumber,
  }) async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final address = Address(
        street: street.trim(),
        apartment: apartment.trim(),
        city: city.trim(),
        state: state.selectedProvince!,
        postalCode: postalCode.trim().toUpperCase(),
        country: 'Canada',
        phoneNumber: phoneNumber.trim(),
        label: state.selectedLabel,
        isDefault: true,
        latitude: state.latitude,
        longitude: state.longitude,
      );

      await _ref.read(userRepositoryProvider).updateAddress(userId, address);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
