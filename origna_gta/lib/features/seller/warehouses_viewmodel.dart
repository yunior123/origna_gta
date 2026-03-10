// coverage:ignore-file
// Migrated: delegates to OrignaBase warehouses viewmodel.
// Screens continue using warehousesViewModelProvider, sellerWarehousesStreamProvider, WarehousesViewModel.

export 'orignabase_warehouses_viewmodel.dart';

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/utils.dart';

import 'orignabase_warehouses_viewmodel.dart';

// ---------------------------------------------------------------------------
// State (kept here — orignabase counterpart imports it)
// ---------------------------------------------------------------------------

/// State for the warehouses viewmodel.
class WarehousesState {
  final List<SellerWarehouse> warehouses;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const WarehousesState({
    this.warehouses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  WarehousesState copyWith({
    List<SellerWarehouse>? warehouses,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? isSuccess,
  }) {
    return WarehousesState(
      warehouses: warehouses ?? this.warehouses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Stream of the seller's warehouses via OrignaBase.
/// Uses polling via the viewmodel's success state to trigger refreshes.
final sellerWarehousesStreamProvider = StreamProvider.autoDispose<List<SellerWarehouse>>((ref) {
  final uid = ref.watch(obUserIdProvider);
  if (uid == null) return const Stream.empty();

  final ob = ref.watch(orignabaseProvider);
  final controller = StreamController<List<SellerWarehouse>>();

  Future<void> fetch() async {
    try {
      final snap = await ob
          .collection(Collections.users)
          .doc(uid)
          .subcollection(Collections.warehouses)
          .orderBy(Fields.isDefault, descending: true)
          .orderBy(Fields.createdAt, descending: false)
          .get();

      final warehouses = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data);
        // Convert createdAt to ISO string for Freezed/fromJson compatibility
        final rawCreatedAt = data[Fields.createdAt];
        if (rawCreatedAt is String) {
          data[Fields.createdAt] = rawCreatedAt;
        } else if (rawCreatedAt is int) {
          data[Fields.createdAt] = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt).toIso8601String();
        }
        return SellerWarehouse.fromJson({...data, 'warehouseId': doc.id});
      }).toList();

      if (!controller.isClosed) controller.add(warehouses);
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'sellerWarehousesStreamProvider');
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Initial fetch
  fetch();

  // Subscribe to realtime changes on the warehouses subcollection
  final realtime = RealtimeClient(ob);
  realtime.connect();
  final subName = '${Collections.users}__${Collections.warehouses}';
  final sub = realtime.subscribe(subName).listen(
    (change) {
      // Re-fetch the full list on any change to keep ordering consistent
      fetch();
    },
    onError: (Object e, StackTrace st) {
      AppError.log(e, stackTrace: st, context: 'sellerWarehousesStreamProvider.realtime');
    },
  );

  ref.onDispose(() {
    sub.cancel();
    realtime.disconnect();
    controller.close();
  });

  return controller.stream;
});

/// Backward-compatible alias — screens use this name.
final warehousesViewModelProvider = obWarehousesViewModelProvider;

/// Backward-compatible typedef.
typedef WarehousesViewModel = OrignaBaseWarehousesViewModel;
