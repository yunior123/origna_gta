import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

part 'address_state.freezed.dart';

@freezed
abstract class AddressState with _$AddressState {
  const factory AddressState({
    @Default(false) bool isLoading,
    @Default(ProvinceCodeValues.ontario) String? selectedProvince,
    @Default(AddressLabelValues.home) String? selectedLabel,
    @Default([]) List<Map<String, dynamic>> addressSuggestions,
    @Default(false) bool showSuggestions,
    double? latitude,
    double? longitude,
    String? addressId,
    String? errorMessage,
    @Default(false) bool isSuccess,
    @Default(false) bool isDefault,
  }) = _AddressState;
}
