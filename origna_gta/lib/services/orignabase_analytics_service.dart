// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/env_config.dart';

/// OrignaBase analytics service.
/// All events are no-ops in emulator, dev, and staging environments.
/// Covers the full GA4 e-commerce funnel + auth + marketplace-specific events.
class OrignaBaseAnalyticsService {
  final OrignaBase _ob;

  OrignaBaseAnalyticsService(this._ob);

  bool get _isEnabled =>
      !kDebugMode &&
      !envConfig.isEmulator &&
      !envConfig.isDev &&
      !envConfig.isStaging;

  Future<void> _track(String eventName, [Map<String, dynamic>? properties]) async {
    if (!_isEnabled) return;
    try {
      await _ob.request('POST', '/analytics/event', body: {
        'event_name': eventName,
        'properties': properties,
      });
    } catch (e) {
      AppLogger.w('Failed to track "$eventName": $e', tag: 'analytics');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> logSignUp({required String method}) =>
      _track('sign_up', {'method': method});

  Future<void> logLogin({required String method}) =>
      _track('login', {'method': method});

  // ── Browse / Discovery ────────────────────────────────────────────────────

  Future<void> logViewItemList({
    required String listName,
    required List<Map<String, dynamic>> items,
  }) =>
      _track('view_item_list', {'item_list_name': listName, 'items': items});

  Future<void> logSelectItem({
    required String productId,
    required String productName,
    required double priceCad,
    String listName = '',
  }) =>
      _track('select_item', {
        'item_list_name': listName,
        'items': [
          {'item_id': productId, 'item_name': productName, 'price': priceCad},
        ],
      });

  Future<void> logViewItem({
    required String productId,
    required String productName,
    required double priceCad,
  }) =>
      _track('view_item', {
        'currency': 'CAD',
        'value': priceCad,
        'items': [
          {'item_id': productId, 'item_name': productName, 'price': priceCad},
        ],
      });

  Future<void> logSearch({required String searchTerm}) {
    final redacted = _redactSearchTerm(searchTerm);
    if (redacted == null) return Future.value();
    return _track('search', {'search_term': redacted});
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) =>
      _track('add_to_cart', {
        'currency': 'CAD',
        'value': priceCad * quantity,
        'items': [
          {
            'item_id': productId,
            'item_name': productName,
            'price': priceCad,
            'quantity': quantity,
          },
        ],
      });

  Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) =>
      _track('remove_from_cart', {
        'currency': 'CAD',
        'value': priceCad * quantity,
        'items': [
          {
            'item_id': productId,
            'item_name': productName,
            'price': priceCad,
            'quantity': quantity,
          },
        ],
      });

  // ── Wishlist ──────────────────────────────────────────────────────────────

  Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required double priceCad,
  }) =>
      _track('add_to_wishlist', {
        'currency': 'CAD',
        'value': priceCad,
        'items': [
          {'item_id': productId, 'item_name': productName, 'price': priceCad},
        ],
      });

  Future<void> logRemoveFromWishlist({
    required String productId,
    required String productName,
  }) =>
      _track('remove_from_wishlist', {
        'item_id': productId,
        'item_name': productName,
      });

  // ── Checkout funnel ───────────────────────────────────────────────────────

  Future<void> logBeginCheckout({
    required double valueCad,
    required int itemCount,
  }) =>
      _track('begin_checkout', {
        'currency': 'CAD',
        'value': valueCad,
        'item_count': itemCount,
      });

  Future<void> logAddShippingInfo({
    required double valueCad,
    required double shippingCostCad,
    required String shippingTier,
  }) =>
      _track('add_shipping_info', {
        'currency': 'CAD',
        'value': valueCad,
        'shipping_cost': shippingCostCad,
        'shipping_tier': shippingTier,
      });

  Future<void> logAddPaymentInfo({
    required double valueCad,
    required String paymentType,
  }) =>
      _track('add_payment_info', {
        'currency': 'CAD',
        'value': valueCad,
        'payment_type': paymentType,
      });

  Future<void> logPurchase({
    required String orderId,
    required double valueCad,
    required int itemCount,
  }) =>
      _track('purchase', {
        'currency': 'CAD',
        'value': valueCad,
        'transaction_id': orderId,
        'item_count': itemCount,
      });

  Future<void> logRefund({
    required String orderId,
    required double valueCad,
  }) =>
      _track('refund', {
        'currency': 'CAD',
        'value': valueCad,
        'transaction_id': orderId,
      });

  // ── Subscription ──────────────────────────────────────────────────────────

  Future<void> logSubscriptionStarted({required double priceCad}) =>
      _track('subscription_started', {'currency': 'CAD', 'value': priceCad});

  Future<void> logSubscriptionCancelled() =>
      _track('subscription_cancelled');

  // ── Reviews ───────────────────────────────────────────────────────────────

  Future<void> logReviewSubmitted({
    required String productId,
    required double rating,
  }) =>
      _track('review_submitted', {'item_id': productId, 'rating': rating});

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> logScreenView({required String screenName}) =>
      _track('screen_view', {'screen_name': screenName});

  // ── PII redaction ─────────────────────────────────────────────────────────

  static String? _redactSearchTerm(String term) {
    if (term.contains('@')) return null;
    if (RegExp(r'\b\d{7,}\b').hasMatch(term)) return null;
    return term;
  }
}
