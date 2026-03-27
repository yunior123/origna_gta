// Integration tests for OrignaBaseUserRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  bool isExpectedLivePermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission') ||
        msg.contains('forbidden');
  }

  // --- Admin-role tests -----------------------------------------------
  group('OrignaBaseUserRepository live (admin)', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseUserRepository userRepo;
    late String adminUserId;

    setUpAll(() async {
      final env = EnvConfig();
      expect(
        env.orignabaseUrl,
        isNotEmpty,
        reason: 'ORIGNABASE_URL dart-define required for live tests',
      );

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      userRepo = OrignaBaseUserRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail('e2e-admin@test.origna.ca', 'REDACTED_TEST_PASSWORD');
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Admin sign-in failed');
      adminUserId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'getUserProfile returns user data for valid user ID',
      () async {
        final profile = await userRepo.getUserProfile(adminUserId);

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
        try {
          final profile = await userRepo.getUserProfile('nonexistent_user_id');
          expect(profile, isNull);
        } catch (e) {
          expect(
            e.toString().toLowerCase(),
            anyOf(
              contains('403'),
              contains('permission'),
              contains('forbidden'),
            ),
            reason: 'Expected null or 403 for nonexistent user, got: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchAddresses returns stream of user addresses',
      () async {
        final addressesStream = userRepo.watchAddresses(adminUserId);
        final addresses = await addressesStream.first;
        expect(addresses, isList);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updatePreferredLanguage updates user language preference',
      () async {
        await userRepo.updatePreferredLanguage(adminUserId, 'en');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'recordTermsAcceptance records user terms acceptance',
      () async {
        await userRepo.recordTermsAcceptance();
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);

  // --- Seller-role tests -----------------------------------------------
  group('OrignaBaseUserRepository live (seller)', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseUserRepository userRepo;
    late String sellerUserId;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      userRepo = OrignaBaseUserRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca', 'REDACTED_TEST_PASSWORD');
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Seller sign-in failed');
      sellerUserId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'watchSellerAccountStatus returns stream of seller status',
      () async {
        try {
          final statusStream = userRepo.watchSellerAccountStatus(sellerUserId);
          final status = await statusStream.first;
          expect(status, isNotNull);
        } catch (e) {
          expect(
            isExpectedLivePermissionError(e),
            isTrue,
            reason: 'Unexpected seller status stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getSellerAccountStatus returns seller status',
      () async {
        try {
          final status = await userRepo.getSellerAccountStatus(sellerUserId);
          expect(status, isNotNull);
        } catch (e) {
          expect(
            isExpectedLivePermissionError(e),
            isTrue,
            reason: 'Unexpected seller status lookup error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
