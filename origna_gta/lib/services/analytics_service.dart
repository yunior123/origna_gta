import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/services/orignabase_analytics_service.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Lightweight event item model preserved so existing app/test call sites do not
/// depend on platform analytics SDK types.
class AnalyticsEventItem {
  final String itemId;
  final String itemName;
  final double? price;
  final int? quantity;

  const AnalyticsEventItem({
    required this.itemId,
    required this.itemName,
    this.price,
    this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_name': itemName,
        if (price != null) 'price': price,
        if (quantity != null) 'quantity': quantity,
      };
}

/// Backward-compatible analytics facade now backed by OrignaBase.
class AnalyticsService {
  static final OrignaBaseAnalyticsService _analytics =
      OrignaBaseAnalyticsService(
    OrignaBase.initialize(url: envConfig.orignabaseUrl),
  );

  static Future<void> logSignUp({required String method}) =>
      _analytics.logSignUp(method: method);

  static Future<void> logLogin({required String method}) =>
      _analytics.logLogin(method: method);

  static Future<void> logViewItemList({
    required String listName,
    required List<AnalyticsEventItem> items,
  }) =>
      _analytics.logViewItemList(
        listName: listName,
        items: items.map((item) => item.toJson()).toList(),
      );

  static Future<void> logSelectItem({
    required String productId,
    required String productName,
    required double priceCad,
    String listName = '',
  }) =>
      _analytics.logSelectItem(
        productId: productId,
        productName: productName,
        priceCad: priceCad,
        listName: listName,
      );

  static Future<void> logViewItem({
    required String productId,
    required String productName,
    required double priceCad,
  }) =>
      _analytics.logViewItem(
        productId: productId,
        productName: productName,
        priceCad: priceCad,
      );

  static Future<void> logSearch({required String searchTerm}) =>
      _analytics.logSearch(searchTerm: searchTerm);

  static Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) =>
      _analytics.logAddToCart(
        productId: productId,
        productName: productName,
        priceCad: priceCad,
        quantity: quantity,
      );

  static Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) =>
      _analytics.logRemoveFromCart(
        productId: productId,
        productName: productName,
        priceCad: priceCad,
        quantity: quantity,
      );

  static Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required double priceCad,
  }) =>
      _analytics.logAddToWishlist(
        productId: productId,
        productName: productName,
        priceCad: priceCad,
      );

  static Future<void> logRemoveFromWishlist({
    required String productId,
    required String productName,
  }) =>
      _analytics.logRemoveFromWishlist(
        productId: productId,
        productName: productName,
      );

  static Future<void> logBeginCheckout({
    required double valueCad,
    required int itemCount,
  }) =>
      _analytics.logBeginCheckout(valueCad: valueCad, itemCount: itemCount);

  static Future<void> logAddShippingInfo({
    required double valueCad,
    required double shippingCostCad,
    required String shippingTier,
  }) =>
      _analytics.logAddShippingInfo(
        valueCad: valueCad,
        shippingCostCad: shippingCostCad,
        shippingTier: shippingTier,
      );

  static Future<void> logAddPaymentInfo({
    required double valueCad,
    required String paymentType,
  }) =>
      _analytics.logAddPaymentInfo(
        valueCad: valueCad,
        paymentType: paymentType,
      );

  static Future<void> logPurchase({
    required String orderId,
    required double valueCad,
    required int itemCount,
  }) =>
      _analytics.logPurchase(
        orderId: orderId,
        valueCad: valueCad,
        itemCount: itemCount,
      );

  static Future<void> logRefund({
    required String orderId,
    required double valueCad,
  }) =>
      _analytics.logRefund(orderId: orderId, valueCad: valueCad);

  static Future<void> logSubscriptionStarted({required double priceCad}) =>
      _analytics.logSubscriptionStarted(priceCad: priceCad);

  static Future<void> logSubscriptionCancelled() =>
      _analytics.logSubscriptionCancelled();

  static Future<void> logReviewSubmitted({
    required String productId,
    required double rating,
  }) =>
      _analytics.logReviewSubmitted(productId: productId, rating: rating);

  static Future<void> logScreenView({required String screenName}) =>
      _analytics.logScreenView(screenName: screenName);
}
