// Integration tests for OrignaBaseAuthRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:uuid/uuid.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBaseAuthRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAuthRepository authRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'registerWithEmail creates a new user account',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        final marker = const Uuid().v4();
        final email = 'live_auth_reg_$marker@example.com';
        final password = 'SecurePass123!';
        final name = 'Test User $marker';

        // Should not throw
        await authRepo.registerWithEmail(
          email,
          password,
          name,
          marketingOptIn: false,
        );

        // Verify user can sign in with those credentials
        await authRepo.signInWithEmail(email, password);
        expect(ob.auth.accessToken, isNotEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signInWithEmail authenticates with valid credentials',
      () async {
        const email = 'e2e-admin@test.origna.ca'; // Admin test account
        const password = 'REDACTED_TEST_PASSWORD';

        await authRepo.signInWithEmail(email, password);

        expect(ob.auth.accessToken, isNotEmpty);
        expect(ob.auth.currentUserId, isNotEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signInWithEmail throws for invalid credentials',
      () async {
        final marker = const Uuid().v4();
        const password = 'WrongPassword123!';

        expect(
          () => authRepo.signInWithEmail(
            'nonexistent_$marker@example.com',
            password,
          ),
          throwsA(isA<OrignaBaseAuthException>()),
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'isEmailVerified returns false for unverified user',
      () async {
        final marker = const Uuid().v4();
        final email = 'live_auth_unverified_$marker@example.com';
        const password = 'SecurePass123!';
        final name = 'Test User';

        // Register new user (unverified)
        await authRepo.registerWithEmail(email, password, name);
        await authRepo.signInWithEmail(email, password);

        final verified = await authRepo.isEmailVerified();
        expect(verified, isFalse);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signOut clears current user',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';

        await authRepo.signInWithEmail(email, password);
        expect(ob.auth.accessToken, isNotEmpty);

        await authRepo.signOut();
        expect(ob.auth.accessToken, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'validateCurrentUser returns true for authenticated user',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';

        await authRepo.signInWithEmail(email, password);

        final isValid = await authRepo.validateCurrentUser();
        expect(isValid, isTrue);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'validateCurrentUser returns false when no session exists',
      () async {
        // With no token, validateCurrentUser() returns false (no valid session).
        // A null accessToken means "not authenticated" — can't validate.
        ob.auth.signOut();

        final isValid = await authRepo.validateCurrentUser();
        // No session → not authenticated → false
        expect(isValid, isFalse);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
