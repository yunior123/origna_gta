import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:origna_gta/screens/seller/seller_warehouses_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>()])
import 'seller_warehouses_screen_test.mocks.dart';

void main() {
  const signedInUser = AppAuthUser(
    uid: 'seller_123',
    email: 'seller@example.com',
    emailVerified: true,
  );
  late MockOrignaBase mockOrignaBase;

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    initTestMocks();

    when(
      mockOrignaBase.request(any, any, body: anyNamed('body')),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  final testAddress = Address(
    street: '123 Main St',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5V 3A8',
    country: 'Canada',
  );

  final testWarehouse = SellerWarehouse(
    warehouseId: 'wh_123',
    label: 'Toronto Warehouse',
    type: WarehouseTypeValues.warehouse,
    address: testAddress,
    isDefault: true,
  );

  Widget createTestWidget({
    List<SellerWarehouse> warehouses = const [],
    WarehousesState vmState = const WarehousesState(),
  }) {
    return TestWrapper(
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        currentUserProvider.overrideWithValue(signedInUser),
        userIdProvider.overrideWithValue(signedInUser.uid),
        sellerWarehousesStreamProvider.overrideWith(
          (ref) => Stream.value(warehouses),
        ),
        warehousesViewModelProvider.overrideWith(
          (ref) => WarehousesViewModel(ref),
        ),
      ],
      child: const SellerWarehousesScreen(),
    );
  }

  group('SellerWarehousesScreen Widget Tests', () {
    testWidgets('renders empty state when no warehouses', (tester) async {
      await tester.pumpWidget(createTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('seller.no_warehouses_yet'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.warehouse_outlined), findsWidgets);
    });

    testWidgets('renders list of warehouses', (tester) async {
      await tester.pumpWidget(createTestWidget(warehouses: [testWarehouse]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Toronto Warehouse'), findsOneWidget);
      expect(find.text('common.default'.tr()), findsOneWidget);
      expect(find.text('Toronto, ON'), findsOneWidget);
    });

    testWidgets('can open add warehouse form', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(warehouses: [testWarehouse]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('seller.add_shipping_location'.tr()), findsOneWidget);
    });

    testWidgets('validates warehouse form', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(warehouses: [testWarehouse]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('seller.name_required'.tr()), findsOneWidget);
      expect(find.text('address.street_required'.tr()), findsOneWidget);
    });

    testWidgets('can delete warehouse after confirmation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(warehouses: [testWarehouse]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('common.delete'.tr()).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text(
          'seller.warehouse_delete_confirm'.tr(
            namedArgs: {'name': 'Toronto Warehouse'},
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('common.delete'.tr()).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).called(greaterThan(0));
    });

    testWidgets('can set warehouse as default', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final nonDefaultWh = testWarehouse.copyWith(
        warehouseId: 'wh_456',
        isDefault: false,
        label: 'Other',
      );
      await tester.pumpWidget(createTestWidget(warehouses: [nonDefaultWh]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('common.set_as_default'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).called(greaterThan(0));
    });
  });
}
