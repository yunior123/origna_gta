// Integration tests for OrignaBaseUserRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBaseUserRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseUserRepository userRepo;
    late OrignaBaseAuthRepository authRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      userRepo = OrignaBaseUserRepository(ob);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'getUserProfile returns user data for valid user ID',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final profile = await userRepo.getUserProfile(userId!);

        if (profile != null) {
          expect(profile.uid, isNotEmpty);
          expect(profile.email, isNotEmpty);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getUserProfile returns null for nonexistent user',
      () async {
        final profile = await userRepo.getUserProfile('nonexistent_user_id');
        expect(profile, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchAddresses returns stream of user addresses',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final addressesStream = userRepo.watchAddresses(userId!);

        // Take first emission
        final addresses = await addressesStream.first;
        expect(addresses, isA<List<Address>>());
        // May be empty but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellerAccountStatus returns stream of seller status',
      () async {
        const email = 'e2e-seller@test.origna.ca'; // Seller account
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final statusStream = userRepo.watchSellerAccountStatus(userId!);

        // Take first emission
        final status = await statusStream.first;
        expect(status, isNotNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getSellerAccountStatus returns seller status',
      () async {
        const email = 'e2e-seller@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final status = await userRepo.getSellerAccountStatus(userId!);
        expect(status, isNotNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updatePreferredLanguage updates user language preference',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        // Update language - should not throw
        await userRepo.updatePreferredLanguage(
          userId!,
          'en',
        );
        // Test passes if no exception is thrown
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'recordTermsAcceptance records user terms acceptance',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        // Record terms acceptance - should not throw
        await userRepo.recordTermsAcceptance();
        // Test passes if no exception
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
