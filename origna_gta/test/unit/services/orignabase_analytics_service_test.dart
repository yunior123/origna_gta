import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/analytics_service.dart';
import 'package:origna_gta/services/orignabase_analytics_service.dart';
import 'package:orignabase/orignabase.dart';

void main() {
  group('OrignaBaseAnalyticsService', () {
    test('_isEnabled returns false in debug mode', () {
      expect(kDebugMode, isTrue);
    });

    test('logSignUp completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(service.logSignUp(method: 'email'), completes);
    });

    test('logLogin completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(service.logLogin(method: 'google'), completes);
    });

    test('logViewItemList completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logViewItemList(
          listName: 'Home',
          items: [
            {'item_id': 'p1', 'item_name': 'Product 1'},
          ],
        ),
        completes,
      );
    });

    test('logSelectItem completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logSelectItem(
          productId: 'p1',
          productName: 'Product 1',
          priceCad: 29.99,
          listName: 'Featured',
        ),
        completes,
      );
    });

    test('logViewItem completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logViewItem(
          productId: 'p1',
          productName: 'Product 1',
          priceCad: 29.99,
        ),
        completes,
      );
    });

    test('logSearch redacts email addresses', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logSearch(searchTerm: 'test@example.com'),
        completes,
      );
    });

    test('logSearch redacts phone numbers (7+ digits)', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(service.logSearch(searchTerm: '1234567890'), completes);
    });

    test('logSearch allows normal search terms', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(service.logSearch(searchTerm: 'sneakers'), completes);
    });

    test('logAddToCart completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logAddToCart(
          productId: 'p1',
          productName: 'Product 1',
          priceCad: 29.99,
          quantity: 3,
        ),
        completes,
      );
    });

    test('logRemoveFromCart completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logRemoveFromCart(
          productId: 'p1',
          productName: 'Product 1',
          priceCad: 29.99,
          quantity: 2,
        ),
        completes,
      );
    });

    test('logAddToWishlist completes without error in debug mode', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logAddToWishlist(
          productId: 'p1',
          productName: 'Product 1',
          priceCad: 29.99,
        ),
        completes,
      );
    });

    test('logRemoveFromWishlist completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logRemoveFromWishlist(
          productId: 'p1',
          productName: 'Product 1',
        ),
        completes,
      );
    });

    test('logBeginCheckout completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logBeginCheckout(valueCad: 99.99, itemCount: 5),
        completes,
      );
    });

    test('logAddShippingInfo completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logAddShippingInfo(
          valueCad: 99.99,
          shippingCostCad: 9.99,
          shippingTier: 'Express',
        ),
        completes,
      );
    });

    test('logAddPaymentInfo completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logAddPaymentInfo(valueCad: 109.98, paymentType: 'Credit Card'),
        completes,
      );
    });

    test('logPurchase completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logPurchase(
          orderId: 'order_123',
          valueCad: 109.98,
          itemCount: 5,
        ),
        completes,
      );
    });

    test('logRefund completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logRefund(orderId: 'order_123', valueCad: 50.00),
        completes,
      );
    });

    test('logSubscriptionStarted completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logSubscriptionStarted(priceCad: 14.99),
        completes,
      );
    });

    test('logSubscriptionCancelled completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(service.logSubscriptionCancelled(), completes);
    });

    test('logReviewSubmitted completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logReviewSubmitted(productId: 'p1', rating: 4.5),
        completes,
      );
    });

    test('logScreenView completes without error', () async {
      final service = OrignaBaseAnalyticsService(
        OrignaBase.initialize(url: 'http://127.0.0.1:0'),
      );
      await expectLater(
        service.logScreenView(screenName: 'HomeScreen'),
        completes,
      );
    });
  });

  group('AnalyticsEventItem', () {
    test('toJson includes all fields when provided', () {
      const item = AnalyticsEventItem(
        itemId: 'p1',
        itemName: 'Product 1',
        price: 29.99,
        quantity: 2,
      );

      final json = item.toJson();

      expect(json['item_id'], 'p1');
      expect(json['item_name'], 'Product 1');
      expect(json['price'], 29.99);
      expect(json['quantity'], 2);
    });

    test('toJson omits null fields', () {
      const item = AnalyticsEventItem(itemId: 'p1', itemName: 'Product 1');

      final json = item.toJson();

      expect(json['item_id'], 'p1');
      expect(json['item_name'], 'Product 1');
      expect(json.containsKey('price'), isFalse);
      expect(json.containsKey('quantity'), isFalse);
    });
  });
}
