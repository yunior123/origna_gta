import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/addproduct_screen.dart';
import 'package:origna_gta/utils/env_config.dart';

import '../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<ProductRepository>(),
  MockSpec<LocationRepository>(),
  MockSpec<EnvConfig>(),
])
import 'add_product_screen_test.mocks.dart';

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

  Widget buildTestWidget({List<Override> overrides = const []}) {
    return TestWrapper(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            UserModel(
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
          (ref) => Stream.value(const []),
        ),
        envConfigProvider.overrideWithValue(mockConfig),
        ...overrides,
      ],
      child: const AddProductScreen(),
    );
  }

  group('AddProductScreen Comprehensive Test', () {
    testWidgets('fills basic form and submits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(
        find.byKey(const Key('product_name_field')),
        'Excellent Smartphone',
      );
      await tester.enterText(
        find.byKey(const Key('product_description_field')),
        'A very long description for the smartphone product.',
      );
      await tester.enterText(
        find.byKey(const Key('product_price_field')),
        '999.99',
      );
      await tester.enterText(
        find.byKey(const Key('product_stock_field')),
        '10',
      );

      final categorySelector = find.byKey(
        const Key('addproduct_category_selector'),
      );
      await tester.ensureVisible(categorySelector);
      await tester.tap(categorySelector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Electronics').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final streetField = find.byKey(const Key('addproduct_street_field'));
      final cityField = find.byKey(const Key('addproduct_city_field'));
      final postalCodeField = find.byKey(
        const Key('addproduct_postal_code_field'),
      );
      await tester.ensureVisible(streetField);
      await tester.enterText(streetField, '123 Tech Ave');
      await tester.ensureVisible(cityField);
      await tester.enterText(cityField, 'Toronto');
      await tester.ensureVisible(postalCodeField);
      await tester.enterText(postalCodeField, 'M5V 2L7');

      final provinceDropdown = find.byKey(
        const Key('addproduct_province_dropdown'),
      );
      await tester.ensureVisible(provinceDropdown);
      await tester.tap(provinceDropdown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('ON').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      when(
        mockProductRepo.createProductAtomic(
          any,
          any,
          testImageUrls: anyNamed('testImageUrls'),
          bookSourceUrl: anyNamed('bookSourceUrl'),
        ),
      ).thenAnswer((_) async => 'prod_123');

      final submitBtn = find.byKey(const Key('addproduct_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(
        mockProductRepo.createProductAtomic(
          any,
          any,
          testImageUrls: anyNamed('testImageUrls'),
          bookSourceUrl: anyNamed('bookSourceUrl'),
        ),
      ).called(1);
      tester.view.resetPhysicalSize();
    });

    testWidgets('toggles digital product and fills fields', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final digitalSwitch = find.byKey(const Key('addproduct_digital_toggle'));
      await tester.ensureVisible(digitalSwitch);
      await tester.tap(digitalSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final typeSelector = find.byKey(
        const Key('addproduct_digital_type_software'),
      );
      await tester.ensureVisible(typeSelector);
      await tester.tap(typeSelector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      tester.view.resetPhysicalSize();
    });

    testWidgets('toggles variants and adds option', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Expand the Variants section first
      final variantTileTitle = find.text('Variants');
      await tester.ensureVisible(variantTileTitle);
      await tester.tap(variantTileTitle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Now the toggle should be visible
      final variantSwitch = find.byKey(
        const Key('addproduct_has_variants_toggle'),
      );
      await tester.ensureVisible(variantSwitch);
      await tester.tap(variantSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final addBtn = find.byKey(
        const Key('addproduct_add_variant_option_button'),
      );
      await tester.ensureVisible(addBtn);
      await tester.pump();
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Fill the dialog
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Size');
      await tester.enterText(fields.at(1), 'Small, Large');

      // Find the "Add" button in dialog actions
      final addButton = find.descendant(
        of: dialog,
        matching: find.byType(FilledButton),
      );
      await tester.tap(addButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Verify the card appeared
      expect(find.byKey(const Key('variant_option_0')), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('shows validation errors', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 5000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final submitBtn = find.byKey(const Key('addproduct_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const Key('addproduct_error_snackbar')),
        findsOneWidget,
      );
      tester.view.resetPhysicalSize();
    });
  });
}
