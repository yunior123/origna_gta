import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/seller/orignabase_warehouses_viewmodel.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/base_models.dart';

// ---------------------------------------------------------------------------
// Test fakes
// ---------------------------------------------------------------------------

class _FakeOb implements OrignaBase {
  Object? nextError;
  String? lastMethod;
  String? lastPath;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastMethod = method;
    lastPath = path;
    if (nextError != null) throw nextError!;
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Address _testAddress({String city = 'Toronto'}) => Address(
  street: '123 Main St',
  city: city,
  state: 'ON',
  postalCode: 'M1M 1M1',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeOb fakeOb;

  ProviderContainer makeContainer({String? userId}) {
    return ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(fakeOb),
        userIdProvider.overrideWithValue(userId),
      ],
    );
  }

  setUp(() {
    fakeOb = _FakeOb();
  });

  group('OrignaBaseWarehousesViewModel', () {
    test('initial state is empty and not loading', () {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.warehouses, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('createWarehouse rejects empty label', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: '',
            type: 'physical',
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('createWarehouse rejects label > 100 chars', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'a' * 101,
            type: 'physical',
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('createWarehouse rejects address with no city', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: 'physical',
            address: _testAddress(city: ''),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('createWarehouse throws error when no userId', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: 'physical',
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('createWarehouse sets isSuccess=true on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: 'physical',
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(fakeOb.lastMethod, 'POST');
    });

    test('createWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('server error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: 'physical',
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
    });

    test('clearStatus resets errorMessage and isSuccess', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      // Trigger a success first
      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: 'physical',
            address: _testAddress(),
          );
      expect(c.read(obWarehousesViewModelProvider).isSuccess, isTrue);

      c.read(obWarehousesViewModelProvider.notifier).clearStatus();

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'createWarehouse guards against double-submit while loading',
      () async {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        final notifier = c.read(obWarehousesViewModelProvider.notifier);
        // Force loading state
        notifier.state = notifier.state.copyWith(isLoading: true);

        await notifier.createWarehouse(
          label: 'Warehouse',
          type: 'physical',
          address: _testAddress(),
        );

        // Should have returned early, no API call
        expect(fakeOb.lastMethod, isNull);
      },
    );
  });
}
