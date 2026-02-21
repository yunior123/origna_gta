import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Tracks local subscription state for back-in-stock notifications.
/// The source of truth for "are we subscribed?" is the backend; this
/// provider manages the optimistic local state after subscribe/unsubscribe.
final stockNotificationNotifierProvider =
    StateNotifierProvider.autoDispose.family<StockNotificationNotifier, AsyncValue<bool>, String>(
  (ref, productId) => StockNotificationNotifier(productId),
);

class StockNotificationNotifier extends StateNotifier<AsyncValue<bool>> {
  final String productId;

  StockNotificationNotifier(this.productId) : super(const AsyncValue.data(false));

  Future<void> subscribe() async {
    state = const AsyncValue.loading();
    try {
      final functions = FirebaseFunctions.instance;
      await functions
          .httpsCallable(CloudFunctionEndpoints.subscribeStockNotification)
          .call({Fields.productId: productId});
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unsubscribe() async {
    state = const AsyncValue.loading();
    try {
      final functions = FirebaseFunctions.instance;
      await functions
          .httpsCallable(CloudFunctionEndpoints.unsubscribeStockNotification)
          .call({Fields.productId: productId});
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
