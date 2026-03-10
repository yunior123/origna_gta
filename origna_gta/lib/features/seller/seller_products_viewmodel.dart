// coverage:ignore-file
// Migrated: delegates to OrignaBase seller products viewmodel.
// Screens continue using sellerProductsViewModelProvider, sellerProductsProvider.

export 'orignabase_seller_products_viewmodel.dart';

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/utils.dart';

import 'orignabase_seller_products_viewmodel.dart';

/// Streams the current seller's products via OrignaBase.
final sellerProductsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final userId = ref.watch(obUserIdProvider);
  if (userId == null) return const Stream.empty();

  final ob = ref.watch(orignabaseProvider);
  final controller = StreamController<List<Product>>();

  Future<void> fetch() async {
    try {
      final snap = await ob
          .collection(Collections.products)
          .where(Fields.sellerId, isEqualTo: userId)
          .orderBy(Fields.createdAt, descending: true)
          .limit(BusinessRules.sellerProductsPageSize)
          .get();

      final products = snap.docs.map((doc) {
        try {
          final data = Map<String, dynamic>.from(doc.data);
          return Product.fromJson({...data, 'productId': doc.id});
        } catch (e) {
          AppError.log(e, context: 'sellerProductsProvider: skipping malformed doc ${doc.id}');
          return null;
        }
      }).whereType<Product>().toList();

      if (!controller.isClosed) controller.add(products);
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'sellerProductsProvider');
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Initial fetch
  fetch();

  // Realtime updates
  final realtime = RealtimeClient(ob);
  realtime.connect();
  final sub = realtime.subscribe(Collections.products).listen(
    (change) {
      final sellerId = change.document.data[Fields.sellerId] as String?;
      if (sellerId == userId) fetch();
    },
    onError: (Object e, StackTrace st) {
      AppError.log(e, stackTrace: st, context: 'sellerProductsProvider.realtime');
    },
  );

  ref.onDispose(() {
    sub.cancel();
    realtime.disconnect();
    controller.close();
  });

  return controller.stream;
});

/// State for the seller products viewmodel.
class SellerProductsState {
  final Set<String> selectedIds;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const SellerProductsState({this.selectedIds = const {}, this.isLoading = false, this.errorMessage, this.successMessage});

  SellerProductsState copyWith({Set<String>? selectedIds, bool? isLoading, String? errorMessage, String? successMessage}) {
    return SellerProductsState(
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Backward-compatible alias — screens use this name.
final sellerProductsViewModelProvider = obSellerProductsViewModelProvider;

/// Backward-compatible typedef.
typedef SellerProductsViewModel = OrignaBaseSellerProductsViewModel;
