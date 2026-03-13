// coverage:ignore-file
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/orignabase_analytics_service.dart';

import 'subscription_state.dart';

/// OrignaBase subscription viewmodel provider.
final obSubscriptionViewModelProvider =
    StateNotifierProvider.autoDispose<
      OrignaBaseSubscriptionViewModel,
      SubscriptionState
    >((ref) {
      return OrignaBaseSubscriptionViewModel(ref);
    });

/// Streams the current user's subscription doc from OrignaBase for real-time updates.
final obSubscriptionStreamProvider =
    StreamProvider.autoDispose<SubscriptionInfo?>((ref) {
      final uid = ref.watch(obUserIdProvider);
      if (uid == null) return Stream.value(null);

      final ob = ref.watch(orignabaseProvider);
      final controller = StreamController<SubscriptionInfo?>();

      // Initial fetch
      ob
          .collection(Collections.subscriptions)
          .doc(uid)
          .get()
          .then((doc) {
            if (doc == null) {
              controller.add(null);
              return;
            }
            controller.add(SubscriptionInfo.fromMap(doc.data));
          })
          .catchError((Object e) {
            controller.addError(e);
          });

      // Realtime updates
      final sub = ob
          .collection(Collections.subscriptions)
          .doc(uid)
          .snapshots()
          .listen((change) {
            controller.add(SubscriptionInfo.fromMap(change.document.data));
          }, onError: controller.addError);

      ref.onDispose(() {
        sub.cancel();
        controller.close();
      });

      return controller.stream;
    });

/// OrignaBase subscription viewmodel.
class OrignaBaseSubscriptionViewModel extends StateNotifier<SubscriptionState> {
  final Ref _ref;

  OrignaBaseSubscriptionViewModel(this._ref) : super(const SubscriptionState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);
  String? get _userId => _ref.read(obUserIdProvider);

  Future<void> createSubscription() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCheckoutUrl: true,
    );
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      final result = await _ob.request(
        'POST',
        '/api/subscriptions/create',
        body: {},
      );
      final url = result[ApiKeys.checkoutUrl] as String?;

      final analytics = OrignaBaseAnalyticsService(_ob);
      unawaited(
        analytics.logSubscriptionStarted(
          priceCad: BusinessRules.premiumSubscriptionPriceCad,
        ),
      );

      state = state.copyWith(isLoading: false, checkoutUrl: url);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> cancelSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      await _ob.request('POST', '/api/subscriptions/cancel', body: {});

      final analytics = OrignaBaseAnalyticsService(_ob);
      unawaited(analytics.logSubscriptionCancelled());

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> reactivateSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      await _ob.request('POST', '/api/subscriptions/reactivate', body: {});
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  /// Update premium notification preferences (new products, trending, etc.)
  Future<void> updateNotificationPreferences({
    bool? notifyNewProducts,
    bool? notifyTrending,
  }) async {
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required.');
      }
      await _ob.request('POST', '/api/subscriptions/notification-preferences', body: {
        Fields.notifyNewProducts: notifyNewProducts,
        Fields.notifyTrending: notifyTrending,
      });
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
    }
  }

  void clearCheckoutUrl() => state = state.copyWith(clearCheckoutUrl: true);

  String _parseError(Object e) {
    final str = e.toString();
    if (str.contains('] ')) return str.split('] ').last;
    return str;
  }
}
