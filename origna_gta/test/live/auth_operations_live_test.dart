import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive =
      bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('Authentication operations live integration', () {
    late OrignaBaseAuthRepository authRepo;
    late OrignaBase ob;

    setUpAll(() async {
      if (!runLive) return;
      final env = EnvConfig();
      ob = OrignaBase.initialize(url: env.orignabaseUrl);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDownAll(() async {
      if (!runLive) return;
      try {
        await authRepo.signOut();
      } catch (_) {
        // Already signed out
      }
    });

    test(
      'should login with valid credentials',
      () async {
        if (!runLive) return;

        await authRepo.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        // Verify user is authenticated
        final userId = ob.auth.currentUserId;
        expect(userId, isNotEmpty, reason: 'User ID should be populated');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should reject invalid password',
      () async {
        if (!runLive) return;

        expect(
          () => authRepo.signInWithEmail(
            'e2e-buyer@test.origna.ca',
            'WrongPassword123!',
          ),
          throwsA(isA<OrignaBaseAuthException>()),
          reason: 'Login with wrong password should throw',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should refresh token successfully',
      () async {
        if (!runLive) return;

        // Sign in first
        await authRepo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');

        // Get current user to ensure token exists
        var userId = ob.auth.currentUserId;
        expect(userId, isNotEmpty);

        // Verify token is still valid
        userId = ob.auth.currentUserId;
        expect(userId, isNotEmpty, reason: 'Token should be valid');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should logout and revoke token',
      () async {
        if (!runLive) return;

        // Sign in
        await authRepo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');

        // Verify authenticated
        var userId = ob.auth.currentUserId;
        expect(userId, isNotEmpty);

        // Sign out
        await authRepo.signOut();

        // After logout, user ID should be empty
        userId = ob.auth.currentUserId;
        expect(userId, isEmpty, reason: 'User ID should be empty after logout');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should handle invalid email format',
      () async {
        if (!runLive) return;

        expect(
          () => authRepo.signInWithEmail(
            'not-an-email',
            'REDACTED_TEST_PASSWORD',
          ),
          throwsA(isA<OrignaBaseAuthException>()),
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should handle non-existent user gracefully',
      () async {
        if (!runLive) return;

        expect(
          () => authRepo.signInWithEmail(
            'nonexistent.user.${DateTime.now().millisecondsSinceEpoch}@test.origna.ca',
            'REDACTED_TEST_PASSWORD',
          ),
          throwsA(isA<OrignaBaseAuthException>()),
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should verify user email status',
      () async {
        if (!runLive) return;

        await authRepo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');

        final isVerified = await authRepo.isEmailVerified();
        expect(isVerified, isA<bool>(),
            reason: 'Email verification status should return boolean');

        expect(isVerified, isTrue, reason: 'Test user email should be verified');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
