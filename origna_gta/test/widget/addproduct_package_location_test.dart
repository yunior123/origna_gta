import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/models/models.dart' as models;
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<ProductRepository>(),
  MockSpec<LocationRepository>(),
  MockSpec<EnvConfig>(),
])
import 'addproduct_package_location_test.mocks.dart';

void main() {
  late AppAuthUser mockUser;
  late MockProductRepository mockProductRepo;
  late MockLocationRepository mockLocationRepo;
  late MockEnvConfig mockConfig;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
    mockProductRepo = MockProductRepository();
    mockLocationRepo = MockLocationRepository();
    mockConfig = MockEnvConfig();

    when(mockConfig.isDev).thenReturn(true);
    when(mockConfig.isEmulator).thenReturn(false);

    when(
      mockProductRepo.fetchProducts(
        searchQuery: anyNamed('searchQuery'),
        categoryId: anyNamed('categoryId'),
        subcategory: anyNamed('subcategory'),
        lastDocumentId: anyNamed('lastDocumentId'),
        pageSize: anyNamed('pageSize'),
        sortOption: anyNamed('sortOption'),
        minPriceCents: anyNamed('minPriceCents'),
        maxPriceCents: anyNamed('maxPriceCents'),
      ),
    ).thenAnswer(
      (_) async => ProductQueryResult(
        products: [],
        lastDocumentId: null,
        hasMore: false,
      ),
    );
  });

  Widget buildTestWidget({
    List<Override> overrides = const [],
    List<SellerWarehouse> warehouses = const [],
  }) {
    return TestWrapper(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            models.UserModel(
              uid: 'test_user_123',
              name: 'Test',
              email: 'test@example.com',
              roles: [UserRole.seller],
              createdAt: DateTime.now(),
            ),
          ),
        ),
        productRepositoryProvider.overrideWithValue(mockProductRepo),
        locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        sellerWarehousesStreamProvider.overrideWith(
          (ref) => Stream.value(warehouses),
        ),
        envConfigProvider.overrideWithValue(mockConfig),
        ...overrides,
      ],
      child: const AddProductScreen(),
    );
  }

  group('AddProductScreen — Package & Location Section', () {
    testWidgets('renders empty warehouse section when no warehouses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No locations'), findsOneWidget);
      expect(find.text('Add location'), findsOneWidget);
      expect(
        find.byKey(const Key('addproduct_manage_warehouses_button')),
        findsOneWidget,
      );
      expect(find.text('Manual address'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders warehouse list when warehouses exist', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Main Warehouse',
          address: const Address(
            street: '123 Main St',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 2L7',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        SellerWarehouse(
          warehouseId: 'wh2',
          label: 'Secondary Location',
          address: const Address(
            street: '456 Side St',
            city: 'Montreal',
            state: 'QC',
            postalCode: 'H2X 1Y9',
          ),
          type: WarehouseTypeValues.personal,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Main Warehouse'), findsOneWidget);
      expect(find.text('Secondary Location'), findsOneWidget);
      expect(
        find.byKey(const Key('addproduct_manage_warehouses_button')),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders street, city, postal code fields in empty warehouse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('addproduct_street_field')), findsOneWidget);
      expect(find.byKey(const Key('addproduct_city_field')), findsOneWidget);
      expect(
        find.byKey(const Key('addproduct_postal_code_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('addproduct_province_dropdown')),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
    });

    testWidgets('fills street, city, postal code fields', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(
        find.byKey(const Key('addproduct_street_field')),
        '789 Queen St W',
      );
      await tester.enterText(
        find.byKey(const Key('addproduct_city_field')),
        'Toronto',
      );
      await tester.enterText(
        find.byKey(const Key('addproduct_postal_code_field')),
        'M5V 1T3',
      );
      await tester.pump();

      expect(find.text('789 Queen St W'), findsOneWidget);
      expect(find.text('Toronto'), findsOneWidget);
      expect(find.text('M5V 1T3'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('default warehouse renders correctly', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Default Warehouse',
          address: const Address(
            street: '1 Main',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Default Warehouse'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('non-default warehouse does not show default badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Secondary',
          address: const Address(
            street: '2 Side',
            city: 'Montreal',
            state: 'QC',
            postalCode: 'H2X 1Y9',
          ),
          type: WarehouseTypeValues.personal,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Default'), findsNothing);

      tester.view.resetPhysicalSize();
    });

    testWidgets('warehouse loading state renders screen', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      // Screen should render without crashing
      expect(find.byType(AddProductScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('warehouse error state shows error banner', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            sellerWarehousesStreamProvider.overrideWith(
              (ref) => Stream.error(Exception('Network error')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('error'), findsWidgets);

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders Ships from header for warehouse list', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Main',
          address: const Address(
            street: '1 Main',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Ships from'), findsWidgets);

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders info icon for warehouse hint', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Main',
          address: const Address(
            street: '1 Main',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.info_outline_rounded), findsWidgets);

      tester.view.resetPhysicalSize();
    });

    testWidgets('personal type warehouse renders correctly', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Home Office',
          address: const Address(
            street: '1 Main',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.personal,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Home Office'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('warehouse checkbox is present for each warehouse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Warehouse A',
          address: const Address(
            street: '1 A St',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        SellerWarehouse(
          warehouseId: 'wh2',
          label: 'Warehouse B',
          address: const Address(
            street: '2 B St',
            city: 'Montreal',
            state: 'QC',
            postalCode: 'H2X 1Y9',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const Key('addproduct_warehouse_checkbox_wh1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('addproduct_warehouse_checkbox_wh2')),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
    });

    testWidgets('warehouse address details are displayed', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Main Warehouse',
          address: const Address(
            street: '123 Main St',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 2L7',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Toronto'), findsWidgets);
      expect(find.textContaining('ON'), findsWidgets);
      expect(find.textContaining('M5V 2L7'), findsWidgets);

      tester.view.resetPhysicalSize();
    });

    testWidgets('warehouse with checkbox shows correct initial state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      final warehouses = [
        SellerWarehouse(
          warehouseId: 'wh1',
          label: 'Main',
          address: const Address(
            street: '1 Main',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5V 0A1',
          ),
          type: WarehouseTypeValues.warehouse,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(warehouses: warehouses));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('addproduct_warehouse_checkbox_wh1')),
      );
      expect(checkbox.value, isFalse);

      tester.view.resetPhysicalSize();
    });

    testWidgets('empty warehouse section shows hint text', (tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Ships from'), findsOneWidget);
      expect(find.text('Manual address'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('empty warehouse section shows apartment field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(warehouses: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Apartment'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });
  });
}
