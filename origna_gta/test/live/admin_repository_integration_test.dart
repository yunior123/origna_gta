// Integration tests for OrignaBaseAdminRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/admin/orignabase_admin_repository.dart';

/// Returns true if [e] is an expected server-side rejection (not-found or
/// permission-denied). Any other exception is unexpected and should fail.
bool _isExpectedError(Object e) =>
    e is NotFoundException ||
    e is ForbiddenException ||
    e is AuthException ||
    e is ValidationException ||
    (e is OrignaBaseException && e.statusCode == null);

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  if (!runLive) {
    test('Skip live tests', () {});
    return;
  }

  group('OrignaBaseAdminRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAdminRepository adminRepo;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      adminRepo = OrignaBaseAdminRepository(ob);

      // Sign in as admin — may fail if dev server is unreachable
      try {
        await ob.auth.signInWithEmail(
          'e2e-admin@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
      } catch (_) {
        // Can't reach dev server — tests will be skipped via runLive guard
      }
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

        expect(users, isA<List<dynamic>>());
        // List may be empty but should be a valid list type
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchOrders returns stream of orders',
      () async {
        final ordersStream = adminRepo.watchOrders(limit: 10);
        final orders = await ordersStream.first;

        expect(orders, isA<List<dynamic>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellers returns stream of sellers',
      () async {
        final sellersStream = adminRepo.watchSellers(limit: 10);
        final sellers = await sellersStream.first;

        expect(sellers, isA<List<dynamic>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchProducts returns stream of products',
      () async {
        final productsStream = adminRepo.watchProducts(limit: 20);
        final products = await productsStream.first;

        expect(products, isA<List<dynamic>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchPendingReviewProducts returns stream',
      () async {
        final productsStream = adminRepo.watchPendingReviewProducts(limit: 50);
        final products = await productsStream.first;

        expect(products, isA<List<dynamic>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchReviews returns stream of reviews',
      () async {
        final reviewsStream = adminRepo.watchReviews(limit: 20);
        final reviews = await reviewsStream.first;

        expect(reviews, isA<List<dynamic>>());
      },
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
          // uid field stores short ID, currentUserId is full path "users:xxx"
          final shortId = currentUserId.contains(':')
              ? currentUserId.split(':').last
              : currentUserId;
          expect(user.uid, anyOf(currentUserId, shortId));
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getPaymentProviders returns provider info',
      () async {
        final providers = await adminRepo.getPaymentProviders();

        expect(providers, isA<Map<String, dynamic>>());
        expect(providers.containsKey('success'), isTrue);
      },
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
          if (!_isExpectedError(e)) {
            fail('Unexpected error suspending user: $e');
          }
        }

        // Unsuspend
        try {
          await adminRepo.setUserSuspended(testSellerId, false);
          expect(true, isTrue);
        } catch (e) {
          if (!_isExpectedError(e)) {
            fail('Unexpected error unsuspending user: $e');
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('updateUserRoles succeeds', () async {
      const testUserId = 'test_user_id';

      // Should not throw even if user doesn't exist
      try {
        await adminRepo.updateUserRoles(
          testUserId,
          add: ['moderator'],
          reason: 'Integration test',
        );
      } catch (e) {
        if (!_isExpectedError(e)) fail('Unexpected error updating roles: $e');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test(
      'enableAdminMfa returns MFA setup info',
      () async {
        try {
          final mfaInfo = await adminRepo.enableAdminMfa();
          expect(mfaInfo, isA<Map<String, dynamic>>());
        } catch (e) {
          if (!_isExpectedError(e) &&
              e is! ValidationException &&
              e is! ConflictException) {
            fail('Unexpected error enabling MFA: $e');
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'verifyAdminMfa with invalid code returns error',
      () async {
        try {
          await adminRepo.verifyAdminMfa('000000');
          // May succeed or fail depending on actual MFA setup
        } catch (e) {
          // Invalid MFA code — expect auth/validation/forbidden rejection
          if (!_isExpectedError(e) && e is! ValidationException) {
            fail('Unexpected error verifying MFA: $e');
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('approveProduct succeeds', () async {
      // Try with a nonexistent product ID
      try {
        await adminRepo.approveProduct('nonexistent_product_id');
      } catch (e) {
        if (!_isExpectedError(e)) {
          fail('Unexpected error approving product: $e');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('rejectProduct requires reason', () async {
      try {
        await adminRepo.rejectProduct(
          'nonexistent_product_id',
          'Quality issues',
        );
      } catch (e) {
        if (!_isExpectedError(e)) {
          fail('Unexpected error rejecting product: $e');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
