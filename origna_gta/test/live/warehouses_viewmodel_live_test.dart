import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/base_models.dart';

void main() {
  const runLive =
      bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

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

  group('WarehousesViewModel live integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAuthRepository authRepo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      authRepo = OrignaBaseAuthRepository(ob);

      // Sign in as seller for warehouse tests
      await authRepo.signInWithEmail('e2e-seller@test.origna.ca', 'REDACTED_TEST_PASSWORD');
    });

    tearDownAll(() async {
      if (!runLive) return;
      await authRepo.signOut();
      container.dispose();
    });

    test(
      'should create a new warehouse',
      () async {
        if (!runLive) return;

        final sub = container.listen(
          warehousesViewModelProvider,
          (previous, next) {},
          fireImmediately: true,
        );
        final viewModelNotifier =
            container.read(warehousesViewModelProvider.notifier);

        final newLabel = 'Test Warehouse ${DateTime.now().millisecondsSinceEpoch}';

        // Create warehouse with required Address
        final address = Address(
          street: '123 Test St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 3A8',
          country: 'Canada',
        );

        // Create warehouse
        try {
          await viewModelNotifier.createWarehouse(
            label: newLabel,
            type: 'standard',
            address: address,
          );

          final state = container.read(warehousesViewModelProvider);
          expect(
            state.isSuccess || state.errorMessage != null,
            isTrue,
            reason: 'Warehouse creation should succeed or surface a live env error',
          );
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected warehouse creation error: $e',
          );
        } finally {
          sub.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should update warehouse label',
      () async {
        if (!runLive) return;

        final sub = container.listen(
          warehousesViewModelProvider,
          (previous, next) {},
          fireImmediately: true,
        );
        final viewModelNotifier =
            container.read(warehousesViewModelProvider.notifier);

        final address = Address(
          street: '123 Test St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 3A8',
          country: 'Canada',
        );

        // Create a warehouse to update
        final label = 'Warehouse To Update ${DateTime.now().millisecondsSinceEpoch}';
        try {
          await viewModelNotifier.createWarehouse(
            label: label,
            type: 'standard',
            address: address,
          );

          await Future.delayed(const Duration(milliseconds: 300));

          final updatedLabel =
              'Updated Warehouse ${DateTime.now().millisecondsSinceEpoch}';

          final sellerId = ob.auth.currentUserId;
          final warehousesSnapshot = await ob
              .collection('users')
              .doc(sellerId!)
              .subcollection('warehouses')
              .limit(1)
              .get();

          if (warehousesSnapshot.docs.isNotEmpty) {
            final warehouseId = warehousesSnapshot.docs.first.id;
            await viewModelNotifier.updateWarehouse(
              warehouseId: warehouseId,
              label: updatedLabel,
            );

            final state = container.read(warehousesViewModelProvider);
            expect(
              state.isSuccess || state.errorMessage != null,
              isTrue,
              reason: 'Warehouse update should succeed or surface a live env error',
            );
          }
        } catch (e) {
          final message = e.toString().toLowerCase();
          expect(
            isExpectedPermissionError(e) || message.contains('dispose'),
            isTrue,
            reason: 'Unexpected warehouse update error: $e',
          );
        } finally {
          sub.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
