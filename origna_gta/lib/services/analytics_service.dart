import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Wraps FirebaseAnalytics with environment guards.
/// All events are no-ops in emulator and dev environments to keep production data clean.
class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static bool get _isEnabled => !envConfig.isEmulator && !envConfig.isDev;

  static Future<void> logPurchase({
    required String orderId,
    required double valueCad,
    required int itemCount,
  }) async {
    if (!_isEnabled) return;
    await _analytics.logPurchase(
      currency: 'CAD',
      value: valueCad,
      transactionId: orderId,
      items: [],
    );
  }

  static Future<void> logViewItem({
    required String productId,
    required String productName,
    required double priceCad,
  }) async {
    if (!_isEnabled) return;
    await _analytics.logViewItem(
      currency: 'CAD',
      value: priceCad,
      items: [
        AnalyticsEventItem(itemId: productId, itemName: productName, price: priceCad),
      ],
    );
  }

  static Future<void> logSearch({required String searchTerm}) async {
    if (!_isEnabled) return;
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  static Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double priceCad,
    int quantity = 1,
  }) async {
    if (!_isEnabled) return;
    await _analytics.logAddToCart(
      currency: 'CAD',
      value: priceCad * quantity,
      items: [
        AnalyticsEventItem(itemId: productId, itemName: productName, price: priceCad, quantity: quantity),
      ],
    );
  }

  static Future<void> logBeginCheckout({
    required double valueCad,
    required int itemCount,
  }) async {
    if (!_isEnabled) return;
    await _analytics.logBeginCheckout(currency: 'CAD', value: valueCad);
  }

  static Future<void> logScreenView({required String screenName}) async {
    if (!_isEnabled) return;
    await _analytics.logScreenView(screenName: screenName);
  }
}
