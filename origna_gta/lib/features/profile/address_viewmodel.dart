import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'address_state.dart';

/// Riverpod provider for [AddressViewModel].
///
/// Auto-disposed — fresh state per address form instance prevents stale geolocation data.
final addressViewModelProvider =
    StateNotifierProvider.autoDispose<AddressViewModel, AddressState>((ref) {
      return AddressViewModel(ref);
    });

/// Manages single address form: validation, geocoding, save/update.
///
/// ## State Flow
/// ```
/// Empty → User types street → Suggestions fetched → User selects → lat/lng set → Save
/// ```
///
/// ## Key Decisions
/// - Address suggestions are debounced (300ms) to avoid hammering the geocoding API.
/// - Coordinates must come from a suggestion selection ([selectAddress]); manual typing
///   invalidates lat/lng to prevent stale geolocation data (Bug #16).
/// - Supports both create and update — when [AddressState.addressId] is non-null,
///   [saveAddress] performs an update instead of create.
///
/// See also:
/// - [AddressState] for the state shape
class AddressViewModel extends StateNotifier<AddressState> {
  final Ref _ref;
  Timer? _debounce;

  AddressViewModel(this._ref) : super(const AddressState());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Handles street input changes — triggers debounced address autocomplete.
  ///
  /// Parameters:
  /// - [value]: current street text from the form field.
  ///
  /// Resets lat/lng on every keystroke to prevent stale coordinates.
  /// Queries are debounced at 300ms and skipped when [value] < 3 characters.
  void onStreetChanged(String value) {
    // Reset coordinates when user types manually
    state = state.copyWith(latitude: null, longitude: null);

    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final suggestions = await _ref
          .read(locationRepositoryProvider)
          .getAddressSuggestions(value);
      if (mounted) {
        state = state.copyWith(
          addressSuggestions: suggestions,
          showSuggestions: suggestions.isNotEmpty,
        );
      }
    });
  }

  /// Validates and saves the address (create or update).
  ///
  /// Parameters:
  /// - [street], [apartment], [city], [postalCode], [phoneNumber]: address fields from the form.
  ///
  /// Requires [AddressState.latitude] and [AddressState.longitude] to be set
  /// (i.e., user must have selected from suggestions). Sets [AddressState.isSuccess] on success.
  ///
  /// Gotchas:
  /// - Fails with an error if coordinates are missing — user must select from suggestions.
  /// - When [AddressState.addressId] is non-null, performs an update instead of create.
  Future<void> saveAddress({
    required String street,
    required String apartment,
    required String city,
    required String postalCode,
    required String phoneNumber,
  }) async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) return;

    if (state.latitude == null || state.longitude == null) {
      state = state.copyWith(
        errorMessage: 'Please select a valid address from the suggestions',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final address = Address(
        street: street.trim(),
        apartment: apartment.trim(),
        city: city.trim(),
        state: state.selectedProvince!,
        postalCode: postalCode.trim().toUpperCase(),
        country: GeoValues.countryCanada,
        phoneNumber: phoneNumber.trim(),
        label: state.selectedLabel,
        isDefault: state.isDefault,
        latitude: state.latitude,
        longitude: state.longitude,
        addressId: state.addressId,
      );

      if (state.addressId != null) {
        await _ref
            .read(userRepositoryProvider)
            .updateBuyerAddress(state.addressId!, address);
      } else {
        await _ref.read(userRepositoryProvider).addBuyerAddress(address);
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to save address'),
      );
    }
  }

  /// Populates state with province, lat/lng from a Geoapify suggestion selection.
  ///
  /// Parameters:
  /// - [suggestion]: raw feature map from the Geoapify autocomplete API.
  ///
  /// Clears the suggestion list and hides the dropdown after selection.
  void selectAddress(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);
    state = state.copyWith(
      selectedProvince: details.state,
      latitude: details.latitude,
      longitude: details.longitude,
      showSuggestions: false,
      addressSuggestions: [],
    );
  }

  /// Pre-fills the form state from an existing [Address] for editing.
  ///
  /// Parameters:
  /// - [address]: existing address to edit, or null for a new address form.
  ///
  /// Sets province, label, coordinates, addressId, and isDefault from the model.
  void setInitialData(Address? address) {
    if (address != null) {
      state = state.copyWith(
        selectedProvince: address.state,
        selectedLabel: address.label ?? AddressLabelValues.home,
        latitude: address.latitude,
        longitude: address.longitude,
        addressId: address.addressId,
        isDefault: address.isDefault,
      );
    }
  }

  /// Sets whether this address is the default shipping address.
  void setDefault(bool value) => state = state.copyWith(isDefault: value);

  /// Sets the address label (e.g., 'home', 'work', 'other').
  void setLabel(String label) => state = state.copyWith(selectedLabel: label);

  /// Sets the province code for the address form.
  void setProvince(String province) =>
      state = state.copyWith(selectedProvince: province);
}
