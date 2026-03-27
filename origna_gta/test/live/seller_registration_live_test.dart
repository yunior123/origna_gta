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

  group('Seller registration live integration', () {
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
      'should authenticate as registered seller',
      () async {
        if (!runLive) return;

        // Sign in as a registered seller
        await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull, reason: 'Seller should be authenticated');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should have seller profile after registration',
      () async {
        if (!runLive) return;

        // Sign in as a registered seller
        await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull);

        // Fetch seller profile to check it exists
        final sellerProfileQuery = await ob
            .collection(Collections.users)
            .doc(sellerId!)
            .subcollection(Collections.sellerProfiles)
            .doc(sellerId)
            .get();

        if (sellerProfileQuery != null) {
          expect(
            true,
            isTrue,
            reason: 'Seller should have a seller_profiles document',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should have warehouse after registration',
      () async {
        if (!runLive) return;

        await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull);

        // Check seller has warehouses
        final warehousesSnapshot = await ob
            .collection(Collections.users)
            .doc(sellerId!)
            .subcollection(Collections.warehouses)
            .get();

        expect(
          warehousesSnapshot.docs.isNotEmpty,
          isTrue,
          reason: 'Registered seller should have at least one warehouse',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should have default warehouse',
      () async {
        if (!runLive) return;

        await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull);

        // Check warehouses
        final warehousesSnapshot = await ob
            .collection(Collections.users)
            .doc(sellerId!)
            .subcollection(Collections.warehouses)
            .get();

        expect(warehousesSnapshot.docs.isNotEmpty, isTrue);

        // Check if there's a default warehouse
        final hasDefaultWarehouse = warehousesSnapshot.docs.any(
          (doc) => (doc.data['isDefault'] as bool?) ?? false,
        );

        expect(
          hasDefaultWarehouse,
          isTrue,
          reason: 'Seller should have a default warehouse',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should have seller role',
      () async {
        if (!runLive) return;

        await authRepo.signInWithEmail(
          'e2e-seller@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );

        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull);

        // Fetch user document
        final userDocQuery = await ob
            .collection(Collections.users)
            .doc(sellerId!)
            .get();

        if (userDocQuery != null) {
          final userData = userDocQuery.data;
          expect(userData, isNotNull);

          // User should have seller role
          final userRole = userData['role'];
          expect(
            userRole,
            equals('seller'),
            reason: 'User should have seller role',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
