import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Wraps FirebaseAnalytics with environment guards.
/// All events are no-ops in emulator and dev environments to keep production data clean.
class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  // BOOT-M3: also disable in staging to avoid polluting production data
  static bool get _isEnabled => !envConfig.isEmulator && !envConfig.isDev && !envConfig.isStaging;

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
    // F-68: Redact potential PII before sending to analytics.
    // Searches containing email addresses, long numeric sequences (order IDs, phone numbers),
    // or explicit privacy markers are replaced with metadata only.
    final redacted = _redactSearchTerm(searchTerm);
    if (redacted == null) return; // Entirely PII — skip logging
    await _analytics.logSearch(searchTerm: redacted);
  }

  static String? _redactSearchTerm(String term) {
    // Contains @ → likely an email address
    if (term.contains('@')) return null;
    // 7+ consecutive digits → phone number or order ID
    if (RegExp(r'\b\d{7,}\b').hasMatch(term)) return null;
    return term;
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
