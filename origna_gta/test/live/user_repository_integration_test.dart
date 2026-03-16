import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/models/models.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('OrignaBaseUserRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseUserRepository repo;
    late String buyerId;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as buyer
      final authState = await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);
      buyerId = authState.userId!;

      repo = OrignaBaseUserRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'getUserProfile returns user data for authenticated user',
      () async {
        if (!runLive) return;
        final profile = await repo.getUserProfile(buyerId);
        expect(profile, isNotNull);
        expect(profile!.uid, equals(buyerId));
        expect(profile.email, isNotEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getUserProfile returns null for nonexistent user',
      () async {
        if (!runLive) return;
        // Backend may return 403 (rule denies when no resource) or null.
        // Both indicate "profile not found".
        try {
          final profile = await repo.getUserProfile('nonexistent_user_xyz');
          expect(profile, isNull);
        } catch (e) {
          expect(e.toString().toLowerCase(),
              anyOf(contains('403'), contains('permission'), contains('forbidden')),
              reason: 'Expected null or 403 for nonexistent user, got: $e');
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchAddresses returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        final stream = repo.watchAddresses(buyerId);
        expect(stream, isNotNull);

        // Emit at least one event within 10 seconds
        final event = await stream.first.timeout(const Duration(seconds: 10));
        expect(event, isList);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'addBuyerAddress and deleteBuyerAddress work correctly',
      () async {
        if (!runLive) return;
        final address = Address(
          street: '123 Test St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1A 1A1',
          country: 'CA',
          label: 'test_address',
          isDefault: false,
        );

        // Add address
        final addressId = await repo.addBuyerAddress(address);
        expect(addressId, isNotEmpty);

        // Verify it exists
        final stream = repo.watchAddresses(buyerId);
        var addresses = await stream.first.timeout(const Duration(seconds: 10));
        expect(
          addresses.any((a) => a.addressId == addressId),
          isTrue,
          reason: 'Address should be in list',
        );

        // Delete address
        await repo.deleteBuyerAddress(addressId);

        // Verify it's deleted
        addresses = await stream.first.timeout(const Duration(seconds: 10));
        expect(
          addresses.any((a) => a.addressId == addressId),
          isFalse,
          reason: 'Address should be removed',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'setDefaultBuyerAddress and updateBuyerAddress work correctly',
      () async {
        if (!runLive) return;
        final address = Address(
          street: '456 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M2A 1A1',
          country: 'CA',
          label: 'home',
          isDefault: false,
        );

        // Add address
        final addressId = await repo.addBuyerAddress(address);
        expect(addressId, isNotEmpty);

        // Set as default
        await repo.setDefaultBuyerAddress(addressId);

        // Update address
        final updated = address.copyWith(street: '789 Oak Ave');
        await repo.updateBuyerAddress(addressId, updated);

        // Verify changes
        final stream = repo.watchAddresses(buyerId);
        final addresses = await stream.first.timeout(const Duration(seconds: 10));
        final addressData = addresses.firstWhere((a) => a.addressId == addressId);
        expect(addressData.street, equals('789 Oak Ave'));
        expect(addressData.isDefault, isTrue);

        // Clean up
        await repo.deleteBuyerAddress(addressId);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getSellerAccountStatus returns status object',
      () async {
        if (!runLive) return;
        final status = await repo.getSellerAccountStatus(buyerId);
        expect(status, isNotNull);
        expect(status.isSeller, isA<bool>());
        expect(status.chargesEnabled, isA<bool>());
        expect(status.detailsSubmitted, isA<bool>());
        expect(status.hasPendingRequirements, isA<bool>());
        expect(status.pendingRequirements, isList);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellerAccountStatus returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        final stream = repo.watchSellerAccountStatus(buyerId);
        expect(stream, isNotNull);

        // Emit at least one event within 10 seconds
        final event = await stream.first.timeout(const Duration(seconds: 10));
        expect(event, isNotNull);
        expect(event.isSeller, isA<bool>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
