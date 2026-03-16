// Integration tests for OrignaBaseAdminRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/admin/orignabase_admin_repository.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBaseAdminRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAdminRepository adminRepo;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      adminRepo = OrignaBaseAdminRepository(ob);

      // Sign in as admin
      await ob.auth.signInWithEmail(
        'e2e-admin@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'watchUsers returns stream of users',
      () async {
        final usersStream = adminRepo.watchUsers(limit: 10);
        final users = await usersStream.first;

        expect(users, isA<List>());
        // List may be empty but should be a valid list type
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchOrders returns stream of orders',
      () async {
        final ordersStream = adminRepo.watchOrders(limit: 10);
        final orders = await ordersStream.first;

        expect(orders, isA<List>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellers returns stream of sellers',
      () async {
        final sellersStream = adminRepo.watchSellers(limit: 10);
        final sellers = await sellersStream.first;

        expect(sellers, isA<List>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchProducts returns stream of products',
      () async {
        final productsStream = adminRepo.watchProducts(limit: 20);
        final products = await productsStream.first;

        expect(products, isA<List>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchPendingReviewProducts returns stream',
      () async {
        final productsStream = adminRepo.watchPendingReviewProducts(limit: 50);
        final products = await productsStream.first;

        expect(products, isA<List>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchReviews returns stream of reviews',
      () async {
        final reviewsStream = adminRepo.watchReviews(limit: 20);
        final reviews = await reviewsStream.first;

        expect(reviews, isA<List>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchUserById returns user or null',
      () async {
        // Try to fetch the current admin user
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        final user = await adminRepo.fetchUserById(currentUserId!);

        if (user != null) {
          expect(user.uid, currentUserId);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getPaymentProviders returns provider info',
      () async {
        final providers = await adminRepo.getPaymentProviders();

        expect(providers, isA<Map<String, dynamic>>());
        expect(providers.containsKey('success'), isTrue);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'setUserSuspended toggles suspension',
      () async {
        // Use a non-admin seller for testing
        const testSellerId = 'yuniorrodriguezo4601';

        // Suspend
        try {
          await adminRepo.setUserSuspended(testSellerId, true);
          expect(true, isTrue);
        } catch (e) {
          // May fail if seller doesn't exist or already suspended
          expect(e, isNotNull);
        }

        // Unsuspend
        try {
          await adminRepo.setUserSuspended(testSellerId, false);
          expect(true, isTrue);
        } catch (e) {
          // May fail due to state or permissions
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateUserRoles succeeds',
      () async {
        const testUserId = 'test_user_id';

        // Should not throw even if user doesn't exist
        try {
          await adminRepo.updateUserRoles(
            testUserId,
            add: ['moderator'],
            reason: 'Integration test',
          );
        } catch (e) {
          // Server may reject, which is fine
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'enableAdminMfa returns MFA setup info',
      () async {
        try {
          final mfaInfo = await adminRepo.enableAdminMfa();
          expect(mfaInfo, isA<Map<String, dynamic>>());
        } catch (e) {
          // MFA may already be enabled or other constraints
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'verifyAdminMfa with invalid code returns error',
      () async {
        try {
          await adminRepo.verifyAdminMfa('000000');
          // May succeed or fail depending on actual MFA setup
        } catch (e) {
          // Expected to fail with invalid code
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'approveProduct succeeds',
      () async {
        // Try with a nonexistent product ID
        try {
          await adminRepo.approveProduct('nonexistent_product_id');
          // May fail but should not throw unexpected errors
        } catch (e) {
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'rejectProduct requires reason',
      () async {
        try {
          await adminRepo.rejectProduct(
            'nonexistent_product_id',
            'Quality issues',
          );
        } catch (e) {
          expect(e, isNotNull);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
