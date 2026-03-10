// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// OrignaBase stock notification notifier.
/// Tracks local subscription state for back-in-stock notifications.
final obStockNotificationNotifierProvider = StateNotifierProvider.autoDispose
    .family<
      OrignaBaseStockNotificationNotifier,
      AsyncValue<bool>,
      ({String productId, String? variantKey})
    >(
      (ref, args) => OrignaBaseStockNotificationNotifier(
        ref,
        args.productId,
        args.variantKey,
      ),
    );

/// Documentation for OrignaBaseStockNotificationNotifier
class OrignaBaseStockNotificationNotifier
    extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  final String productId;
  final String? variantKey;

  OrignaBaseStockNotificationNotifier(
    this._ref,
    this.productId,
    this.variantKey,
  ) : super(const AsyncValue.loading()) {
    _ref.listen<AsyncValue<AuthState>>(obAuthStateProvider, (previous, next) {
      final prevUid = previous?.valueOrNull?.userId;
      final nextUid = next.valueOrNull?.userId;
      if (prevUid != nextUid) init();
    });
    init();
  }

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  /// Checks OrignaBase for an existing subscription.
  Future<void> init() async {
    try {
      final uid = _ref.read(obUserIdProvider);
      if (uid == null) {
        state = const AsyncValue.data(false);
        return;
      }
      var query = _ob
          .collection(Collections.stockNotifications)
          .where(Fields.userId, isEqualTo: uid)
          .where(Fields.productId, isEqualTo: productId);
      if (variantKey != null) {
        query = query.where(Fields.variantKey, isEqualTo: variantKey);
      } else {
        query = query.where(Fields.variantKey, isEqualTo: '');
      }
      final snap = await query.limit(1).get();
      state = AsyncValue.data(snap.docs.isNotEmpty);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> subscribe() async {
    state = const AsyncValue.loading();
    try {
      final payload = <String, dynamic>{Fields.productId: productId};
      if (variantKey != null) payload[Fields.variantKey] = variantKey!;
      await _ob.request(
        'POST',
        '/api/products/stock-notify/subscribe',
        body: payload,
      );
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unsubscribe() async {
    state = const AsyncValue.loading();
    try {
      final payload = <String, dynamic>{Fields.productId: productId};
      if (variantKey != null) payload[Fields.variantKey] = variantKey!;
      await _ob.request(
        'POST',
        '/api/products/stock-notify/unsubscribe',
        body: payload,
      );
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
