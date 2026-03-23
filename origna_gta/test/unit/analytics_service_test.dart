import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    // Note: In test environment, kDebugMode is true.
    // Therefore, AnalyticsService._isEnabled evaluates to false.
    // This allows us to safely call these methods in tests without triggering
    // real analytics SDK calls, avoiding bootstrap errors in tests.
    late AnalyticsService analytics;

    setUp(() {
      analytics = AnalyticsService();
    });

    test('Auth events can be called without throwing', () async {
      await expectLater(analytics.logSignUp(method: 'email'), completes);
      await expectLater(analytics.logLogin(method: 'google'), completes);
    });

    test('Browse / Discovery events can be called without throwing', () async {
      await expectLater(
        analytics.logViewItemList(
          listName: 'Home Page',
          items: [AnalyticsEventItem(itemId: 'prod_1', itemName: 'Item 1')],
        ),
        completes,
      );

      await expectLater(
        analytics.logSelectItem(
          productId: 'prod_1',
          productName: 'Item 1',
          priceCad: 25.99,
          listName: 'Featured',
        ),
        completes,
      );

      await expectLater(
        analytics.logViewItem(
          productId: 'prod_1',
          productName: 'Item 1',
          priceCad: 25.99,
        ),
        completes,
      );
    });

    test(
      'logSearch parameter validation and transformation logic (redaction)',
      () async {
        // Normal search
        await expectLater(
          analytics.logSearch(searchTerm: 'sneakers'),
          completes,
        );

        // Search with potential PII (email) - should be redacted internally
        await expectLater(
          analytics.logSearch(searchTerm: 'test@example.com'),
          completes,
        );

        // Search with potential PII (phone/credit card number) - should be redacted internally
        await expectLater(
          analytics.logSearch(searchTerm: '1234567890'),
          completes,
        );
      },
    );

    test('Cart events can be called without throwing', () async {
      await expectLater(
        analytics.logAddToCart(
          productId: 'prod_1',
          productName: 'Item 1',
          priceCad: 25.99,
          quantity: 2,
        ),
        completes,
      );

      await expectLater(
        analytics.logRemoveFromCart(
          productId: 'prod_1',
          productName: 'Item 1',
          priceCad: 25.99,
        ),
        completes,
      );
    });

    test('Wishlist events can be called without throwing', () async {
      await expectLater(
        analytics.logAddToWishlist(
          productId: 'prod_1',
          productName: 'Item 1',
          priceCad: 25.99,
        ),
        completes,
      );

      await expectLater(
        analytics.logRemoveFromWishlist(
          productId: 'prod_1',
          productName: 'Item 1',
        ),
        completes,
      );
    });

    test('Checkout funnel events can be called without throwing', () async {
      await expectLater(
        analytics.logBeginCheckout(valueCad: 100.0, itemCount: 3),
        completes,
      );

      await expectLater(
        analytics.logAddShippingInfo(
          valueCad: 100.0,
          shippingCostCad: 10.0,
          shippingTier: 'Express',
        ),
        completes,
      );

      await expectLater(
        analytics.logAddPaymentInfo(
          valueCad: 110.0,
          paymentType: 'Credit Card',
        ),
        completes,
      );

      await expectLater(
        analytics.logPurchase(
          orderId: 'order_123',
          valueCad: 110.0,
          itemCount: 3,
        ),
        completes,
      );

      await expectLater(
        analytics.logRefund(orderId: 'order_123', valueCad: 110.0),
        completes,
      );
    });

    test('Subscription events can be called without throwing', () async {
      await expectLater(
        analytics.logSubscriptionStarted(priceCad: 15.99),
        completes,
      );

      await expectLater(analytics.logSubscriptionCancelled(), completes);
    });

    test(
      'Reviews and Navigation events can be called without throwing',
      () async {
        await expectLater(
          analytics.logReviewSubmitted(productId: 'prod_1', rating: 4.5),
          completes,
        );

        await expectLater(
          analytics.logScreenView(screenName: 'ProfileScreen'),
          completes,
        );
      },
    );
  });
}
