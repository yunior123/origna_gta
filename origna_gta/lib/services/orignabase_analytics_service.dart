import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Server-side analytics service backed by OrignaBase.
///
/// Sends GA4-style e-commerce events to OrignaBase's `/analytics/event`
/// endpoint. All tracking methods are no-ops in emulator, dev, staging,
/// and debug environments to avoid polluting production analytics.
///
/// Covers the full GA4 e-commerce funnel:
/// - Auth events (sign up, login)
/// - Browse/discovery (view item list, select item, view item, search)
/// - Cart (add to cart, remove from cart)
/// - Wishlist (add/remove)
/// - Checkout funnel (begin checkout, add shipping/payment info)
/// - Purchase and refund
/// - Subscription lifecycle
/// - Reviews and screen views
class OrignaBaseAnalyticsService {
  final OrignaBase _ob;

  /// Creates an analytics service with the given OrignaBase [client].
  OrignaBaseAnalyticsService(this._ob);

  /// Whether analytics tracking is enabled.
  ///
  /// Disabled in debug mode, emulator, dev, and staging to prevent
  /// polluting production analytics data.
  bool get _isEnabled =>
      !kDebugMode &&
      !envConfig.isEmulator &&
      !envConfig.isDev &&
      !envConfig.isStaging;

  /// Internal method that sends an event to the analytics endpoint.
  ///
  /// Parameters:
  /// - [eventName]: the GA4 event name (e.g., 'purchase', 'add_to_cart').
  /// - [properties]: optional event parameters sent alongside the event.
  ///
  /// Errors are caught and logged — analytics failures must never block UX.
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

  /// Tracks a user sign-up event.
  ///
  /// [method]: the sign-up method (e.g., 'email', 'google', 'apple').
  Future<void> logSignUp({required String method}) =>
      _track('sign_up', {'method': method});

  /// Tracks a user login event.
  ///
  /// [method]: the login method (e.g., 'email', 'google', 'apple').
  Future<void> logLogin({required String method}) =>
      _track('login', {'method': method});

  // ── Browse / Discovery ────────────────────────────────────────────────────

  /// Tracks when a user views a list of items (e.g., category page, search results).
  ///
  /// [listName]: the name of the list (e.g., 'search_results', 'category:fruits').
  /// [items]: the items displayed in the list as GA4 item maps.
  Future<void> logViewItemList({
    required String listName,
    required List<Map<String, dynamic>> items,
  }) =>
      _track('view_item_list', {'item_list_name': listName, 'items': items});

  /// Tracks when a user selects an item from a list.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  /// [priceCad]: the price in CAD.
  /// [listName]: the list the item was selected from.
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

  /// Tracks when a user views a product detail page.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  /// [priceCad]: the price in CAD.
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

  /// Tracks a search event with PII redaction.
  ///
  /// [searchTerm]: the raw search query. Terms containing '@' or 7+ consecutive
  /// digits are silently dropped to prevent PII leakage.
  Future<void> logSearch({required String searchTerm}) {
    final redacted = _redactSearchTerm(searchTerm);
    if (redacted == null) return Future.value();
    return _track('search', {'search_term': redacted});
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  /// Tracks when a user adds a product to the cart.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  /// [priceCad]: the unit price in CAD.
  /// [quantity]: number of units added (default 1).
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

  /// Tracks when a user removes a product from the cart.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  /// [priceCad]: the unit price in CAD.
  /// [quantity]: number of units removed (default 1).
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

  /// Tracks when a user adds a product to their wishlist.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  /// [priceCad]: the price in CAD.
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

  /// Tracks when a user removes a product from their wishlist.
  ///
  /// [productId]: the product ID.
  /// [productName]: the product name.
  Future<void> logRemoveFromWishlist({
    required String productId,
    required String productName,
  }) =>
      _track('remove_from_wishlist', {
        'item_id': productId,
        'item_name': productName,
      });

  // ── Checkout funnel ───────────────────────────────────────────────────────

  /// Tracks when a user begins the checkout process.
  ///
  /// [valueCad]: the total cart value in CAD.
  /// [itemCount]: the number of items in the cart.
  Future<void> logBeginCheckout({
    required double valueCad,
    required int itemCount,
  }) =>
      _track('begin_checkout', {
        'currency': 'CAD',
        'value': valueCad,
        'item_count': itemCount,
      });

  /// Tracks when a user adds shipping information during checkout.
  ///
  /// [valueCad]: the total order value in CAD.
  /// [shippingCostCad]: the shipping cost in CAD.
  /// [shippingTier]: the shipping method (e.g., 'standard', 'express').
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

  /// Tracks when a user adds payment information during checkout.
  ///
  /// [valueCad]: the total order value in CAD.
  /// [paymentType]: the payment method (e.g., 'card', 'apple_pay').
  Future<void> logAddPaymentInfo({
    required double valueCad,
    required String paymentType,
  }) =>
      _track('add_payment_info', {
        'currency': 'CAD',
        'value': valueCad,
        'payment_type': paymentType,
      });

  /// Tracks a completed purchase.
  ///
  /// [orderId]: the unique order/transaction ID.
  /// [valueCad]: the total purchase value in CAD.
  /// [itemCount]: the number of items purchased.
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

  /// Tracks a refund for a previous purchase.
  ///
  /// [orderId]: the original order/transaction ID.
  /// [valueCad]: the refunded amount in CAD.
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

  /// Tracks when a user starts a subscription.
  ///
  /// [priceCad]: the subscription price in CAD.
  Future<void> logSubscriptionStarted({required double priceCad}) =>
      _track('subscription_started', {'currency': 'CAD', 'value': priceCad});

  /// Tracks when a user cancels their subscription.
  Future<void> logSubscriptionCancelled() =>
      _track('subscription_cancelled');

  // ── Reviews ───────────────────────────────────────────────────────────────

  /// Tracks when a user submits a product review.
  ///
  /// [productId]: the reviewed product's ID.
  /// [rating]: the star rating (1-5).
  Future<void> logReviewSubmitted({
    required String productId,
    required double rating,
  }) =>
      _track('review_submitted', {'item_id': productId, 'rating': rating});

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Tracks a screen view for navigation analytics.
  ///
  /// [screenName]: the name of the screen (e.g., 'home', 'product_detail').
  Future<void> logScreenView({required String screenName}) =>
      _track('screen_view', {'screen_name': screenName});

  // ── PII redaction ─────────────────────────────────────────────────────────

  /// Redacts search terms that may contain PII.
  ///
  /// Returns `null` (drop event) if the term contains:
  /// - An '@' sign (likely an email address)
  /// - 7+ consecutive digits (likely a phone number or ID)
  ///
  /// Returns the original term otherwise.
  static String? _redactSearchTerm(String term) {
    if (term.contains('@')) return null;
    if (RegExp(r'\b\d{7,}\b').hasMatch(term)) return null;
    return term;
  }
}
