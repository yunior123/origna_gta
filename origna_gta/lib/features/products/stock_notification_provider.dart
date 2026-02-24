import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Tracks local subscription state for back-in-stock notifications.
/// On first use, fetches the real subscription state from Firestore.
final stockNotificationNotifierProvider =
    StateNotifierProvider.family<StockNotificationNotifier, AsyncValue<bool>, String>(
  (ref, productId) => StockNotificationNotifier(productId)..init(),
);

class StockNotificationNotifier extends StateNotifier<AsyncValue<bool>> {
  final String productId;

  StockNotificationNotifier(this.productId) : super(const AsyncValue.loading());

  /// Checks Firestore for an existing subscription so the UI reflects the
  /// real state even if the user subscribed in a previous session.
  Future<void> init() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        state = const AsyncValue.data(false);
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection(Collections.stockNotifications)
          .where(Fields.userId, isEqualTo: uid)
          .where(Fields.productId, isEqualTo: productId)
          .limit(1)
          .get();
      state = AsyncValue.data(snap.docs.isNotEmpty);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

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
