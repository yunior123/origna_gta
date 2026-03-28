import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/services/orignabase_analytics_service.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Riverpod provider for [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Lightweight model representing a single item in an analytics event.
///
/// Used to decouple the app's analytics call sites from platform-specific
/// analytics SDK types. Converts to a GA4-compatible JSON map via [toJson].
class AnalyticsEventItem {
  /// The product/item ID.
  final String itemId;

  /// The product/item name.
  final String itemName;

  /// The unit price (optional).
  final double? price;

  /// The quantity (optional).
  final int? quantity;

  /// Creates an analytics event item.
  const AnalyticsEventItem({
    required this.itemId,
    required this.itemName,
    this.price,
    this.quantity,
  });

  /// Converts to a GA4-compatible JSON map.
  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_name': itemName,
    if (price != null) 'price': price,
    if (quantity != null) 'quantity': quantity,
  };
}

/// Backward-compatible analytics facade backed by OrignaBase.
///
/// Wraps [OrignaBaseAnalyticsService] to provide the same API surface that
/// existing call sites expect. Lazily initializes the OrignaBase client on
/// first use. In production, events are sent to the server; in dev/staging,
/// all methods are no-ops.
class AnalyticsService {
  OrignaBaseAnalyticsService? _analytics;

  /// Whether to initialize a real OrignaBase client (production or emulator).
  bool get _shouldInitializeClient =>
      envConfig.isProduction || envConfig.shouldUseEmulators;

  /// Lazily creates and returns the analytics client.
  OrignaBaseAnalyticsService get _client {
    return _analytics ??= OrignaBaseAnalyticsService(
      OrignaBase.initialize(
        url: _shouldInitializeClient
            ? envConfig.orignabaseUrl
            : 'http://127.0.0.1:0',
      ),
    );
  }

  /// Tracks a user sign-up event. [method] is 'email', 'google', or 'apple'.
  Future<void> logSignUp({required String method}) =>
      _client.logSignUp(method: method);

  /// Tracks a user login event. [method] is 'email', 'google', or 'apple'.
  Future<void> logLogin({required String method}) =>
      _client.logLogin(method: method);

  /// Tracks viewing a list of items (category page, search results).
  ///
  /// [listName]: the list identifier (e.g., 'search_results').
  /// [items]: the displayed items as [AnalyticsEventItem] models.
  Future<void> logViewItemList({
    required String listName,
    required List<AnalyticsEventItem> items,
  }) => _client.logViewItemList(
    listName: listName,
    items: items.map((item) => item.toJson()).toList(),
  );

  /// Tracks selecting an item from a list.
  ///
  /// [productId]: the selected product ID.
  /// [productName]: the product name.
  /// [priceCad]: the price in CAD.
  /// [listName]: the list the item was selected from.
  Future<void> logSelectItem({
    required String productId,
    required String productName,
    required double priceCad,
    String listName = '',
  }) => _client.logSelectItem(
    productId: productId,
    productName: productName,
    priceCad: priceCad,
    listName: listName,
  );

  /// Tracks viewing a product detail page.
  Future<void> logViewItem({
    required String productId,
    required String productName,
    required double priceCad,
  }) => _client.logViewItem(
    productId: productId,
    productName: productName,
    priceCad: priceCad,
  );

  /// Tracks a search event. PII-containing terms are automatically redacted.
  Future<void> logSearch({required String searchTerm}) =>
      _client.logSearch(searchTerm: searchTerm);

  /// Tracks adding a product to the cart.
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
  }) => _client.logAddToCart(
    productId: productId,
    productName: productName,
    priceCad: priceCad,
    quantity: quantity,
  );

  /// Tracks removing a product from the cart.
  Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) => _client.logRemoveFromCart(
    productId: productId,
    productName: productName,
    priceCad: priceCad,
    quantity: quantity,
  );

  /// Tracks adding a product to the wishlist.
  Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required double priceCad,
  }) => _client.logAddToWishlist(
    productId: productId,
    productName: productName,
    priceCad: priceCad,
  );

  /// Tracks removing a product from the wishlist.
  Future<void> logRemoveFromWishlist({
    required String productId,
    required String productName,
  }) => _client.logRemoveFromWishlist(
    productId: productId,
    productName: productName,
  );

  /// Tracks beginning the checkout process.
  Future<void> logBeginCheckout({
    required double valueCad,
    required int itemCount,
  }) => _client.logBeginCheckout(valueCad: valueCad, itemCount: itemCount);

  /// Tracks adding shipping info during checkout.
  Future<void> logAddShippingInfo({
    required double valueCad,
    required double shippingCostCad,
    required String shippingTier,
  }) => _client.logAddShippingInfo(
    valueCad: valueCad,
    shippingCostCad: shippingCostCad,
    shippingTier: shippingTier,
  );

  /// Tracks adding payment info during checkout.
  Future<void> logAddPaymentInfo({
    required double valueCad,
    required String paymentType,
  }) => _client.logAddPaymentInfo(valueCad: valueCad, paymentType: paymentType);

  /// Tracks a completed purchase. [orderId] is the transaction ID.
  Future<void> logPurchase({
    required String orderId,
    required double valueCad,
    required int itemCount,
  }) => _client.logPurchase(
    orderId: orderId,
    valueCad: valueCad,
    itemCount: itemCount,
  );

  /// Tracks a refund. [orderId] is the original transaction ID.
  Future<void> logRefund({required String orderId, required double valueCad}) =>
      _client.logRefund(orderId: orderId, valueCad: valueCad);

  /// Tracks starting a subscription. [priceCad] is the monthly price.
  Future<void> logSubscriptionStarted({required double priceCad}) =>
      _client.logSubscriptionStarted(priceCad: priceCad);

  /// Tracks cancelling a subscription.
  Future<void> logSubscriptionCancelled() => _client.logSubscriptionCancelled();

  /// Tracks submitting a product review. [rating] is 1-5 stars.
  Future<void> logReviewSubmitted({
    required String productId,
    required double rating,
  }) => _client.logReviewSubmitted(productId: productId, rating: rating);

  /// Tracks a screen view for navigation analytics.
  Future<void> logScreenView({required String screenName}) =>
      _client.logScreenView(screenName: screenName);
}
