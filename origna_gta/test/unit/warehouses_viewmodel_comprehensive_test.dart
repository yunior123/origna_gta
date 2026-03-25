import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/models/generated/product_models.dart';

class _FakeOb implements OrignaBase {
  Object? nextError;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int requestCount = 0;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    requestCount++;
    lastMethod = method;
    lastPath = path;
    lastBody = body;
    if (nextError != null) throw nextError!;
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Address _testAddress({
  String street = '123 Main St',
  String apartment = '',
  String city = 'Toronto',
  String state = 'ON',
  String postalCode = 'M1M 1M1',
  String country = 'Canada',
  String? phoneNumber,
  double? latitude,
  double? longitude,
  String? label,
}) => Address(
  street: street,
  apartment: apartment,
  city: city,
  state: state,
  postalCode: postalCode,
  country: country,
  phoneNumber: phoneNumber,
  latitude: latitude,
  longitude: longitude,
  label: label,
);

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

  group('WarehousesState', () {
    test('default state has empty warehouses and not loading', () {
      const state = WarehousesState();
      expect(state.warehouses, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates warehouses', () {
      const state = WarehousesState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.warehouses, isEmpty);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates errorMessage', () {
      const state = WarehousesState();
      final updated = state.copyWith(errorMessage: 'Something went wrong');
      expect(updated.errorMessage, 'Something went wrong');
    });

    test('copyWith clears errorMessage when null passed', () {
      final state = WarehousesState(errorMessage: 'error');
      final updated = state.copyWith(errorMessage: null);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = WarehousesState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith preserves values when not specified', () {
      final state = WarehousesState(
        isLoading: true,
        isSuccess: true,
        errorMessage: 'old error',
      );
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.isSuccess, isTrue);
      expect(updated.errorMessage, 'old error');
    });

    test('state can hold warehouses list', () {
      final warehouse = SellerWarehouse(
        warehouseId: 'wh_1',
        label: 'Main Warehouse',
        type: WarehouseTypeValues.warehouse,
        address: _testAddress(),
        isDefault: true,
      );
      final state = WarehousesState(warehouses: [warehouse]);
      expect(state.warehouses.length, 1);
      expect(state.warehouses.first.warehouseId, 'wh_1');
    });
  });

  group('OrignaBaseWarehousesViewModel - Warehouse Creation', () {
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
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('1-100 characters'));
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('createWarehouse rejects label > 100 chars', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'a' * 101,
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('1-100 characters'));
    });

    test('createWarehouse rejects whitespace-only label', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: '   ',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('createWarehouse rejects address with empty city', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(city: ''),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('City is required'));
    });

    test('createWarehouse rejects address with whitespace-only city', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(city: '   '),
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
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('createWarehouse sets isSuccess=true on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(fakeOb.lastMethod, 'POST');
      expect(fakeOb.lastPath, ApiEndpoints.warehousesCreate);
    });

    test('createWarehouse sends correct payload', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: '  Main Warehouse  ',
            type: WarehouseTypeValues.personal,
            address: _testAddress(
              street: '456 Oak Ave',
              city: 'Montreal',
              state: 'QC',
              postalCode: 'H2H 2H2',
              phoneNumber: '+1-514-555-0123',
            ),
            isDefault: true,
          );

      expect(fakeOb.lastBody?['label'], 'Main Warehouse');
      expect(fakeOb.lastBody?[Fields.type], WarehouseTypeValues.personal);
      expect(fakeOb.lastBody?['isDefault'], isTrue);
      final address = fakeOb.lastBody?['address'] as Map<String, dynamic>;
      expect(address[Fields.street], '456 Oak Ave');
      expect(address[Fields.city], 'Montreal');
      expect(address[Fields.state], 'QC');
      expect(address[Fields.postalCode], 'H2H 2H2');
      expect(address[Fields.phoneNumber], '+1-514-555-0123');
    });

    test('createWarehouse trims label', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: '  Warehouse Name  ',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      expect(fakeOb.lastBody?['label'], 'Warehouse Name');
    });

    test('createWarehouse handles address with optional fields', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(
              apartment: 'Apt 101',
              latitude: 45.5017,
              longitude: -73.5673,
              label: 'Work',
            ),
          );

      final address = fakeOb.lastBody?['address'] as Map<String, dynamic>;
      expect(address[Fields.apartment], 'Apt 101');
      expect(address[Fields.latitude], 45.5017);
      expect(address[Fields.longitude], -73.5673);
      expect(address[Fields.label], 'Work');
    });
  });

  group('OrignaBaseWarehousesViewModel - Warehouse Updates', () {
    test('updateWarehouse calls correct endpoint', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: 'Updated Label');

      expect(fakeOb.lastMethod, 'POST');
      expect(fakeOb.lastPath, ApiEndpoints.warehousesUpdate);
      expect(fakeOb.lastBody?['warehouseId'], 'wh_123');
      expect(fakeOb.lastBody?['label'], 'Updated Label');
    });

    test('updateWarehouse sets isSuccess on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: 'Updated Label');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('updateWarehouse with all fields', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(
            warehouseId: 'wh_123',
            label: 'New Label',
            type: WarehouseTypeValues.personal,
            address: _testAddress(city: 'Vancouver'),
            isDefault: true,
          );

      expect(fakeOb.lastBody?['warehouseId'], 'wh_123');
      expect(fakeOb.lastBody?['label'], 'New Label');
      expect(fakeOb.lastBody?[Fields.type], WarehouseTypeValues.personal);
      expect(fakeOb.lastBody?['isDefault'], isTrue);
      final address = fakeOb.lastBody?['address'] as Map<String, dynamic>;
      expect(address[Fields.city], 'Vancouver');
    });

    test('updateWarehouse trims label', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: '  Trimmed Label  ');

      expect(fakeOb.lastBody?['label'], 'Trimmed Label');
    });

    test('updateWarehouse only sends provided fields', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', isDefault: true);

      expect(fakeOb.lastBody?['warehouseId'], 'wh_123');
      expect(fakeOb.lastBody?['label'], isNull);
      expect(fakeOb.lastBody?[Fields.type], isNull);
      expect(fakeOb.lastBody?['address'], isNull);
      expect(fakeOb.lastBody?['isDefault'], isTrue);
    });

    test('updateWarehouse throws error when no userId', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: 'New Label');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });
  });

  group('OrignaBaseWarehousesViewModel - Warehouse Deletion', () {
    test('deleteWarehouse calls correct endpoint', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_123');

      expect(fakeOb.lastMethod, 'POST');
      expect(fakeOb.lastPath, ApiEndpoints.warehousesDelete);
      expect(fakeOb.lastBody?['warehouseId'], 'wh_123');
    });

    test('deleteWarehouse sets isSuccess on success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_123');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('deleteWarehouse throws error when no userId', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_123');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });
  });

  group('OrignaBaseWarehousesViewModel - Loading States', () {
    test(
      'createWarehouse guards against double-submit while loading',
      () async {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        final notifier = c.read(obWarehousesViewModelProvider.notifier);
        notifier.state = notifier.state.copyWith(isLoading: true);

        await notifier.createWarehouse(
          label: 'Warehouse',
          type: WarehouseTypeValues.warehouse,
          address: _testAddress(),
        );

        expect(fakeOb.lastMethod, isNull);
        expect(fakeOb.requestCount, 0);
      },
    );

    test(
      'updateWarehouse guards against double-submit while loading',
      () async {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        final notifier = c.read(obWarehousesViewModelProvider.notifier);
        notifier.state = notifier.state.copyWith(isLoading: true);

        await notifier.updateWarehouse(warehouseId: 'wh_123', label: 'New');

        expect(fakeOb.lastMethod, isNull);
        expect(fakeOb.requestCount, 0);
      },
    );

    test(
      'deleteWarehouse guards against double-submit while loading',
      () async {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        final notifier = c.read(obWarehousesViewModelProvider.notifier);
        notifier.state = notifier.state.copyWith(isLoading: true);

        await notifier.deleteWarehouse('wh_123');

        expect(fakeOb.lastMethod, isNull);
        expect(fakeOb.requestCount, 0);
      },
    );

    test('state transitions from loading to success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final states = <WarehousesState>[];
      c.listen(obWarehousesViewModelProvider, (prev, next) => states.add(next));

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      expect(states.any((s) => s.isLoading), isTrue);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.isLoading, isFalse);
    });
  });

  group('OrignaBaseWarehousesViewModel - Error Handling', () {
    test('createWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('server error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Main Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('updateWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('server error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: 'New Label');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('deleteWarehouse sets errorMessage on API failure', () async {
      fakeOb.nextError = Exception('server error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .deleteWarehouse('wh_123');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('error message for unauthenticated user', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('warehouse_error'));
    });

    test('error message for not-found warehouse', () async {
      fakeOb.nextError = Exception('not-found: warehouse does not exist');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_nonexistent', label: 'New');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('warehouse_error'));
    });

    test('error message for invalid argument', () async {
      fakeOb.nextError = Exception(
        'invalid-argument: Label cannot be empty] Label required',
      );
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Test',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('generic error message for unknown errors', () async {
      fakeOb.nextError = Exception('some random error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Test',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, contains('Something went wrong'));
    });
  });

  group('OrignaBaseWarehousesViewModel - State Transitions', () {
    test('clearStatus resets errorMessage and isSuccess', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );
      expect(c.read(obWarehousesViewModelProvider).isSuccess, isTrue);

      c.read(obWarehousesViewModelProvider.notifier).clearStatus();

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('clearStatus does not affect warehouses list', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final notifier = c.read(obWarehousesViewModelProvider.notifier);
      final warehouse = SellerWarehouse(
        warehouseId: 'wh_1',
        label: 'Test',
        type: WarehouseTypeValues.warehouse,
        address: _testAddress(),
      );
      notifier.state = notifier.state.copyWith(warehouses: [warehouse]);

      notifier.clearStatus();

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.warehouses, isNotEmpty);
    });

    test('successful operation clears previous error', () async {
      fakeOb.nextError = Exception('first error');
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );
      expect(c.read(obWarehousesViewModelProvider).errorMessage, isNotNull);

      fakeOb.nextError = null;
      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse 2',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isTrue);
    });

    test('failed operation clears previous success', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: _testAddress(),
          );
      expect(c.read(obWarehousesViewModelProvider).isSuccess, isTrue);

      fakeOb.nextError = Exception('error');
      await c
          .read(obWarehousesViewModelProvider.notifier)
          .updateWarehouse(warehouseId: 'wh_123', label: 'New');

      final state = c.read(obWarehousesViewModelProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('loading state clears previous error', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final notifier = c.read(obWarehousesViewModelProvider.notifier);
      notifier.state = notifier.state.copyWith(errorMessage: 'previous error');

      final states = <WarehousesState>[];
      c.listen(obWarehousesViewModelProvider, (prev, next) => states.add(next));

      await notifier.createWarehouse(
        label: 'Warehouse',
        type: WarehouseTypeValues.warehouse,
        address: _testAddress(),
      );

      expect(states.first.errorMessage, isNull);
    });
  });

  group('OrignaBaseWarehousesViewModel - Provider Aliases', () {
    test(
      'warehousesViewModelProvider is alias for obWarehousesViewModelProvider',
      () {
        final c = makeContainer(userId: 'seller_1');
        addTearDown(c.dispose);

        expect(
          c.read(warehousesViewModelProvider),
          same(c.read(obWarehousesViewModelProvider)),
        );
      },
    );

    test('WarehousesViewModel type alias', () {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      final notifier = c.read(warehousesViewModelProvider.notifier);
      expect(notifier, isA<WarehousesViewModel>());
      expect(notifier, isA<OrignaBaseWarehousesViewModel>());
    });
  });

  group('Address to Map Conversion', () {
    test('address with all fields', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: Address(
              street: '100 King St',
              apartment: 'Unit 5',
              city: 'Toronto',
              state: 'ON',
              postalCode: 'M5H 1A1',
              country: 'Canada',
              phoneNumber: '+1-416-555-0123',
              latitude: 43.6489,
              longitude: -79.3785,
              label: 'Office',
            ),
          );

      final address = fakeOb.lastBody?['address'] as Map<String, dynamic>;
      expect(address[Fields.street], '100 King St');
      expect(address[Fields.apartment], 'Unit 5');
      expect(address[Fields.city], 'Toronto');
      expect(address[Fields.state], 'ON');
      expect(address[Fields.postalCode], 'M5H 1A1');
      expect(address[Fields.country], 'Canada');
      expect(address[Fields.phoneNumber], '+1-416-555-0123');
      expect(address[Fields.latitude], 43.6489);
      expect(address[Fields.longitude], -79.3785);
      expect(address[Fields.label], 'Office');
    });

    test('address without optional fields', () async {
      final c = makeContainer(userId: 'seller_1');
      addTearDown(c.dispose);

      await c
          .read(obWarehousesViewModelProvider.notifier)
          .createWarehouse(
            label: 'Warehouse',
            type: WarehouseTypeValues.warehouse,
            address: Address(
              street: '100 King St',
              city: 'Toronto',
              state: 'ON',
              postalCode: 'M5H 1A1',
            ),
          );

      final address = fakeOb.lastBody?['address'] as Map<String, dynamic>;
      expect(address[Fields.street], '100 King St');
      expect(address[Fields.city], 'Toronto');
      expect(address[Fields.state], 'ON');
      expect(address[Fields.postalCode], 'M5H 1A1');
      expect(address.containsKey(Fields.apartment), isFalse);
      expect(address.containsKey(Fields.phoneNumber), isFalse);
      expect(address.containsKey(Fields.latitude), isFalse);
      expect(address.containsKey(Fields.longitude), isFalse);
      expect(address.containsKey(Fields.label), isFalse);
    });
  });
}
