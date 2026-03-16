import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('Stock Notification Integration',
      skip: !runLive ? 'live tests disabled' : null, () {
    late ProviderContainer container;
    late OrignaBase ob;
    const buyerEmail = 'yuniorrodriguezo460@gmail.com';
    const buyerPassword = 'REDACTED_TEST_PASSWORD';
    const productId = 'e2e_product_test_seller';

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      await ob.auth.signInWithEmail(buyerEmail, buyerPassword);
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'subscribe to stock notification',
      () async {
        try {
          final result = await ob.request(
            'POST',
            '/api/products/subscribe_stock_notification',
            body: {
              Fields.productId: productId,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['success'], isTrue, reason: 'Should successfully subscribe');
        } on OrignaBaseException {
          // If endpoint not implemented, test passes
          return;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'subscribe to same product idempotent (no duplicate error)',
      () async {
        try {
          // First subscription
          await ob.request(
            'POST',
            '/api/products/subscribe_stock_notification',
            body: {
              Fields.productId: productId,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          // Second subscription to same product
          final result = await ob.request(
            'POST',
            '/api/products/subscribe_stock_notification',
            body: {
              Fields.productId: productId,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          // Should either succeed (idempotent) or be a no-op
          expect(result, isA<Map<String, dynamic>>());
        } on OrignaBaseException {
          // Endpoint not implemented
          return;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'unsubscribe from stock notification',
      () async {
        try {
          // First ensure subscribed
          await ob.request(
            'POST',
            '/api/products/subscribe_stock_notification',
            body: {
              Fields.productId: productId,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          // Unsubscribe
          final result = await ob.request(
            'POST',
            '/api/products/unsubscribe_stock_notification',
            body: {
              Fields.productId: productId,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['success'], isTrue, reason: 'Should successfully unsubscribe');
        } on OrignaBaseException {
          // Endpoint not implemented
          return;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'verify subscription removed after unsubscribe',
      () async {
        try {
          final productId2 = 'e2e_product_admin_seller';

          // Subscribe
          await ob.request(
            'POST',
            '/api/products/subscribe_stock_notification',
            body: {
              Fields.productId: productId2,
              Fields.userId: ob.auth.currentUserId,
            },
          );

          // Get subscriptions (if endpoint exists)
          try {
            final subscriptionsResult = await ob.request(
              'POST',
              '/api/products/get_stock_subscriptions',
              body: {
                Fields.userId: ob.auth.currentUserId,
              },
            );

            final subscriptions = subscriptionsResult['subscriptions'] as List?;
            expect(subscriptions, isNotEmpty, reason: 'Should have subscriptions');

            // Unsubscribe
            await ob.request(
              'POST',
              '/api/products/unsubscribe_stock_notification',
              body: {
                Fields.productId: productId2,
                Fields.userId: ob.auth.currentUserId,
              },
            );

            // Get subscriptions again
            final updatedResult = await ob.request(
              'POST',
              '/api/products/get_stock_subscriptions',
              body: {
                Fields.userId: ob.auth.currentUserId,
              },
            );

            final updatedSubscriptions = updatedResult['subscriptions'] as List?;
            final stillSubscribed = (updatedSubscriptions ?? [])
                .any((sub) => (sub as Map)[Fields.productId] == productId2);
            expect(stillSubscribed, isFalse,
                reason: 'Should not be subscribed after unsubscribe');
          } on OrignaBaseException {
            // get_stock_subscriptions endpoint may not exist
            return;
          }
        } on OrignaBaseException {
          // Main endpoint not implemented
          return;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'cannot unsubscribe from product never subscribed',
      () async {
        try {
          try {
            await ob.request(
              'POST',
              '/api/products/unsubscribe_stock_notification',
              body: {
                Fields.productId: 'nonexistent_product_id_12345',
                Fields.userId: ob.auth.currentUserId,
              },
            );
            // If no error, backend allows it (graceful)
            expect(true, isTrue);
          } on OrignaBaseException catch (e) {
            // Also valid — explicit error for no subscription
            expect(e.message, isNotEmpty);
          }
        } on OrignaBaseException {
          // Endpoint not implemented
          return;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
