import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/models/models.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  group('OrignaBaseAuthRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAuthRepository repo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      repo = OrignaBaseAuthRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'signInWithEmail succeeds with valid credentials',
      () async {
        if (!runLive) return;
        expect(
          repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD'),
          completes,
          reason: 'signInWithEmail should succeed with valid credentials',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signInWithEmail throws for invalid email format',
      () async {
        if (!runLive) return;
        expect(
          repo.signInWithEmail('not-an-email', 'REDACTED_TEST_PASSWORD'),
          throwsA(isA<OrignaBaseAuthException>()),
          reason: 'signInWithEmail should throw for invalid email format',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'isEmailVerified returns a boolean',
      () async {
        if (!runLive) return;
        // Sign in first
        await repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
        final result = await repo.isEmailVerified();
        expect(result, isA<bool>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'signOut completes without error',
      () async {
        if (!runLive) return;
        // Sign in first
        await repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
        expect(
          repo.signOut(),
          completes,
          reason: 'signOut should complete without throwing',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'validateCurrentUser returns true for authenticated user',
      () async {
        if (!runLive) return;
        // Sign in first
        await repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
        final result = await repo.validateCurrentUser();
        expect(result, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'ensureUserDocumentExists completes without error',
      () async {
        if (!runLive) return;
        // Sign in first
        await repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
        expect(
          repo.ensureUserDocumentExists(),
          completes,
          reason: 'ensureUserDocumentExists should complete',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchProfile returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        // Sign in first
        await repo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final stream = repo.watchProfile(userId!);
        expect(stream, isNotNull);

        // Emit at least one event within 10 seconds
        final event = await stream.first.timeout(const Duration(seconds: 10));
        // Event may be null if auth state doesn't match
        expect(event, isA<UserModel?>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
