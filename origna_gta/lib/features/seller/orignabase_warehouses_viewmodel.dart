// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/base_models.dart';

import 'warehouses_viewmodel.dart' show WarehousesState;

final obWarehousesViewModelProvider =
    StateNotifierProvider.autoDispose<OrignaBaseWarehousesViewModel,
        WarehousesState>(
  (ref) => OrignaBaseWarehousesViewModel(ref),
);

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
          errorMessage: 'Warehouse label must be 1-100 characters');
      return;
    }
    if (address.city.trim().isEmpty) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'City is required for a warehouse address');
      return;
    }

    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      await _ob.request('POST', ApiEndpoints.warehousesCreate, body: {
        'label': trimmedLabel,
        Fields.type: type,
        'address': _addressToMap(address),
        'isDefault': isDefault,
      });
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
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      final payload = <String, dynamic>{
        'warehouseId': warehouseId,
      };
      if (label != null) payload['label'] = label.trim();
      if (type != null) payload[Fields.type] = type;
      if (address != null) payload['address'] = _addressToMap(address);
      if (isDefault != null) payload['isDefault'] = isDefault;
      await _ob.request('POST', ApiEndpoints.warehousesUpdate, body: payload);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    if (state.isLoading) return;
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final userId = _userId;
      if (userId == null) {
        throw StateError('unauthenticated');
      }
      await _ob.request('POST', ApiEndpoints.warehousesDelete, body: {
        'warehouseId': warehouseId,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

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
        if (address.phoneNumber != null)
          Fields.phoneNumber: address.phoneNumber,
        if (address.latitude != null) Fields.latitude: address.latitude,
        if (address.longitude != null) Fields.longitude: address.longitude,
        if (address.label != null) Fields.label: address.label,
      };

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('unauthenticated')) {
      return 'Please log in to manage warehouses.';
    }
    if (msg.contains('not-found')) return 'Warehouse not found.';
    if (msg.contains('invalid-argument')) {
      final start = msg.indexOf('] ');
      return start >= 0
          ? msg.substring(start + 2)
          : 'Invalid input. Please check the form.';
    }
    return 'Something went wrong. Please try again.';
  }
}
