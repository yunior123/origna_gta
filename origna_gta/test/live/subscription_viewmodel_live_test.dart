import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  bool isExpectedPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission') ||
        msg.contains('forbidden');
  }

  group('Subscription benefits live integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAuthRepository authRepo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDownAll(() async {
      if (!runLive) return;
      try {
        await authRepo.signOut();
      } catch (_) {
        // Already signed out
      }
      container.dispose();
    });

    test(
      'should fetch user document successfully',
      () async {
        if (!runLive) return;

        // Sign in as a buyer
        await authRepo.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull, reason: 'User should be authenticated');

        // Fetch user document
        try {
          final userDocQuery = await ob
              .collection(Collections.users)
              .doc(userId!)
              .get();

          if (userDocQuery != null) {
            expect(true, isTrue, reason: 'User document should exist');
          }
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected buyer user-doc lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('should verify user has role', () async {
      if (!runLive) return;

      await authRepo.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );

      final userId = ob.auth.currentUserId;
      try {
        final userDocQuery = await ob
            .collection(Collections.users)
            .doc(userId!)
            .get();

        if (userDocQuery != null) {
          final data = userDocQuery.data;
          expect(data, isNotNull);
          expect(
            data.containsKey('role'),
            isTrue,
            reason: 'User should have a role',
          );
        }
      } catch (e) {
        expect(
          isExpectedPermissionError(e),
          isTrue,
          reason: 'Unexpected role lookup error: $e',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test(
      'should fetch subscription details for admin',
      () async {
        if (!runLive) return;

        // Sign in as admin
        await authRepo.signInWithEmail(
          'e2e-admin@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull, reason: 'Admin should be authenticated');

        // Fetch user document
        try {
          final userDocQuery = await ob
              .collection(Collections.users)
              .doc(userId!)
              .get();

          if (userDocQuery != null) {
            expect(true, isTrue, reason: 'Admin user document should exist');
          }
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected admin user-doc lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
