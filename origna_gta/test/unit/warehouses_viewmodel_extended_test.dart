import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
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
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastMethod = method;
    lastPath = path;
    lastBody = body;
    if (nextError != null) throw nextError!;
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Address _testAddress({String city = 'Montreal'}) => Address(
  street: '456 Test Ave',
  city: city,
  state: 'QC',
  postalCode: 'H2H 2H2',
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

  group('OrignaBaseWarehousesViewModel — updateWarehouse', () {
    test('updateWarehouse sets isSuccess=true on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(
            warehouseId: 'wh_1',
            label: 'Updated Warehouse',
            type: 'physical',
            address: _testAddress(),
            isDefault: true,
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(fakeOb.lastMethod, 'POST');
      expect(fakeOb.lastBody?['warehouseId'], 'wh_1');
      expect(fakeOb.lastBody?['label'], 'Updated Warehouse');
    });

    test(
      'updateWarehouse with only label sends only label and warehouseId',
      () async {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        await c
            .read(obWarehousesViewModelProvider.notifier)
            .updateWarehouse(warehouseId: 'wh_2', label: 'New Label');

        final state = c.read(obWarehousesViewModelProvider);
        expect(state.isSuccess, isTrue);
        expect(fakeOb.lastBody?['warehouseId'], 'wh_2');
        expect(fakeOb.lastBody?['label'], 'New Label');
        expect(fakeOb.lastBody?.containsKey('address'), isFalse);
      },
    );

    test('updateWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('server error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_1', label: 'Updated');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
    });

    test('updateWarehouse throws error when no userId', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('updateWarehouse guards against double-submit', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final notifier = c.read(obWarehousesViewModelProvider.notifier);
      notifier.state = notifier.state.copyWith(isLoading: true);

      await notifier.updateWarehouse(warehouseId: 'wh_1', label: 'Test');
      expect(fakeOb.lastMethod, isNull);
    });
  });

  group('OrignaBaseWarehousesViewModel — deleteWarehouse', () {
    test('deleteWarehouse sets isSuccess=true on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(fakeOb.lastMethod, 'POST');
      expect(fakeOb.lastBody?['warehouseId'], 'wh_1');
    });

    test('deleteWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('not-found');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('not found'));
      expect(state.isSuccess, isFalse);
    });

    test('deleteWarehouse throws error when no userId', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('deleteWarehouse guards against double-submit', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final notifier = c.read(obWarehousesViewModelProvider.notifier);
      notifier.state = notifier.state.copyWith(isLoading: true);

      await notifier.deleteWarehouse('wh_1');
      expect(fakeOb.lastMethod, isNull);
    });
  });

  group('OrignaBaseWarehousesViewModel — submitWarehouseForm', () {
    test('submitWarehouseForm creates when warehouseId is null', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .submitWarehouseForm(
            warehouseId: null,
            label: 'New Warehouse',
            type: 'physical',
            addressMap: {
              Fields.street: '123 Main St',
              Fields.city: 'Ottawa',
              Fields.state: 'ON',
              Fields.postalCode: 'K1K 1K1',
              Fields.country: 'CA',
            },
            isDefault: false,
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
    });

    test('submitWarehouseForm updates when warehouseId is provided', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .submitWarehouseForm(
            warehouseId: 'wh_existing',
            label: 'Updated',
            type: 'virtual',
            addressMap: {
              Fields.street: '789 Elm St',
              Fields.city: 'Vancouver',
              Fields.state: 'BC',
              Fields.postalCode: 'V5V 5V5',
              Fields.country: 'CA',
            },
            isDefault: true,
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(fakeOb.lastBody?['warehouseId'], 'wh_existing');
    });
  });

  group('OrignaBaseWarehousesViewModel — _parseError', () {
    test('maps unauthenticated error', () async {
      fakeOb.nextError = StateError('unauthenticated');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('log in'));
    });

    test('maps invalid-argument error', () async {
      fakeOb.nextError = Exception('[code] invalid-argument] Bad data');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('maps generic unknown error', () async {
      fakeOb.nextError = Exception('something random');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_1');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('Something went wrong'));
    });
  });

  group('WarehousesState', () {
    test('default state values', () {
      const state = WarehousesState();
      expect(state.warehouses, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const state = WarehousesState(isLoading: true, errorMessage: 'err');
      final copied = state.copyWith(isLoading: false);
      expect(copied.isLoading, isFalse);
      expect(copied.errorMessage, 'err');
    });
  });
}
