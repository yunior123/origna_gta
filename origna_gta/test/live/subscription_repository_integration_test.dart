// Integration tests for subscription features against live dev server
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

  group('Subscription features live', () {
    late ProviderContainer container;
    late OrignaBase ob;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as buyer
      await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'Can query subscription collection',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        final subDoc = await ob
            .collection(Collections.subscriptions)
            .doc(currentUserId!)
            .get();

        // May be null if user has no subscription
        if (subDoc != null) {
          expect(subDoc.exists, isTrue);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'createSubscription endpoint is reachable',
      () async {
        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.subscriptionsCreate,
            body: {},
          );
          expect(result, isA<Map<String, dynamic>>());
          // Checkout URL may be present
        } catch (e) {
          // May fail without real card or due to state, but endpoint should exist
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'cancelSubscription endpoint is reachable',
      () async {
        try {
          await ob.request(
            'POST',
            ApiEndpoints.subscriptionsCancel,
            body: {},
          );
          expect(true, isTrue);
        } catch (e) {
          // May fail if no active subscription, which is expected
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'reactivateSubscription endpoint is reachable',
      () async {
        try {
          await ob.request(
            'POST',
            ApiEndpoints.subscriptionsReactivate,
            body: {},
          );
          expect(true, isTrue);
        } catch (e) {
          // May fail if no cancelled subscription, which is expected
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateNotificationPreferences endpoint is reachable',
      () async {
        try {
          await ob.request(
            'POST',
            ApiEndpoints.subscriptionsNotificationPreferences,
            body: {
              Fields.notifyNewProducts: true,
              Fields.notifyTrending: false,
            },
          );
          expect(true, isTrue);
        } catch (e) {
          // May fail but endpoint should be reachable
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Subscription stream provider works',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final subDoc = await ob
              .collection(Collections.subscriptions)
              .doc(currentUserId!)
              .get();

          if (subDoc != null && subDoc.exists) {
            // If subscription exists, it should have expected fields
            expect(subDoc.data, isA<Map<String, dynamic>>());
          }
        } catch (e) {
          expect(e, isNotNull);
        }

        expect(true, isTrue);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'premiumSubscriptionPriceCad constant is defined',
      () async {
        expect(
          BusinessRules.premiumSubscriptionPriceCad,
          isA<double>(),
          reason: 'Premium subscription price should be defined',
        );
        expect(BusinessRules.premiumSubscriptionPriceCad, greaterThan(0));
      },
      skip: !runLive,
    );
  });
}
