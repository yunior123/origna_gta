import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:easy_localization/easy_localization.dart';

import 'warehouses_viewmodel.dart' show WarehousesState;

final obWarehousesViewModelProvider =
    StateNotifierProvider.autoDispose<
      OrignaBaseWarehousesViewModel,
      WarehousesState
    >((ref) => OrignaBaseWarehousesViewModel(ref));

/// OrignaBase warehouses viewmodel.
class OrignaBaseWarehousesViewModel extends StateNotifier<WarehousesState> {
  final Ref _ref;

  OrignaBaseWarehousesViewModel(this._ref) : super(const WarehousesState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);
  String? get _userId => _ref.read(userIdProvider);

  Future<void> createWarehouse({
    required String label,
    required String type,
    required Address address,
    bool isDefault = false,
  }) async {
    if (state.isLoading) return;

    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty || trimmedLabel.length > 100) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'seller.warehouse_label_required'.tr(),
      );
      return;
    }
    if (address.city.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'seller.warehouse_city_required'.tr(),
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      await _ob.request(
        'POST',
        ApiEndpoints.warehousesCreate,
        body: {
          Fields.label: trimmedLabel,
          Fields.type: type,
          Fields.address: _addressToMap(address),
          Fields.isDefault: isDefault,
        },
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> updateWarehouse({
    required String warehouseId,
    String? label,
    String? type,
    Address? address,
    bool? isDefault,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      final payload = <String, dynamic>{Fields.warehouseId: warehouseId};
      if (label != null) payload[Fields.label] = label.trim();
      if (type != null) payload[Fields.type] = type;
      if (address != null) payload[Fields.address] = _addressToMap(address);
      if (isDefault != null) payload[Fields.isDefault] = isDefault;
      await _ob.request('POST', ApiEndpoints.warehousesUpdate, body: payload);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      await _ob.request(
        'POST',
        ApiEndpoints.warehousesDelete,
        body: {Fields.warehouseId: warehouseId},
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  /// Submit a warehouse form (create or update).
  ///
  /// If [warehouseId] is null, creates a new warehouse; otherwise updates.
  /// Accepts raw form field values so screens don't perform data transformation.
  Future<void> submitWarehouseForm({
    String? warehouseId,
    required String label,
    required String type,
    required Map<String, dynamic> addressMap,
    required bool isDefault,
  }) async {
    final address = _mapToAddress(addressMap);
    if (warehouseId == null) {
      await createWarehouse(
        label: label,
        type: type,
        address: address,
        isDefault: isDefault,
      );
    } else {
      await updateWarehouse(
        warehouseId: warehouseId,
        label: label,
        type: type,
        address: address,
        isDefault: isDefault,
      );
    }
  }

  /// Convert a raw form map to an [Address] object.
  Address _mapToAddress(Map<String, dynamic> m) => Address(
    street: m[Fields.street] as String? ?? '',
    apartment: m[Fields.apartment] as String? ?? '',
    city: m[Fields.city] as String? ?? '',
    state: m[Fields.state] as String? ?? '',
    postalCode: m[Fields.postalCode] as String? ?? '',
    country: m[Fields.country] as String? ?? '',
    latitude: m[Fields.latitude] as double?,
    longitude: m[Fields.longitude] as double?,
    label: m[Fields.label] as String?,
  );

  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }

  Map<String, dynamic> _addressToMap(Address address) => {
    Fields.street: address.street,
    if (address.apartment.isNotEmpty) Fields.apartment: address.apartment,
    Fields.city: address.city,
    Fields.state: address.state,
    Fields.postalCode: address.postalCode,
    Fields.country: address.country,
    if (address.phoneNumber != null) Fields.phoneNumber: address.phoneNumber,
    if (address.latitude != null) Fields.latitude: address.latitude,
    if (address.longitude != null) Fields.longitude: address.longitude,
    if (address.label != null) Fields.label: address.label,
  };

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('unauthenticated')) {
      return 'seller.warehouse_error_login'.tr();
    }
    if (msg.contains('not-found')) {
      return 'seller.warehouse_error_not_found'.tr();
    }
    if (msg.contains('invalid-argument')) {
      final start = msg.indexOf('] ');
      return start >= 0
          ? msg.substring(start + 2)
          : 'seller.warehouse_error_invalid_input'.tr();
    }
    return 'Something went wrong. Please try again.';
  }
}
