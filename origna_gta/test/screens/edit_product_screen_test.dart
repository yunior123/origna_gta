import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  late AppAuthUser mockUser;

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
  });

  group('EditProductScreen Smoke Test', () {
    testWidgets('renders edit product screen correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_123',
        name: 'Existing Product',
        description: 'Existing description.',
        priceCents: 4999,
        sellerId: 'test_user_123',
        categoryId: 1,
        imageUrls: [],
        stockQuantity: 5,
        createdAt: DateTime.now(),
        isDigital: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Existing Product'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with full product data from API', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_full',
        name: 'Full Product',
        nameF: 'Produit Complet',
        description: 'Full product description.',
        descriptionF: 'Description complète du produit.',
        priceCents: 9999,
        compareAtPriceCents: 14999,
        sellerId: 'test_user_123',
        categoryId: 5,
        imageUrls: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
        stockQuantity: 25,
        createdAt: DateTime(2026, 1, 15),
        isDigital: false,
        isPerishable: false,
        isLocalDeliveryOnly: false,
        isAgeRestricted: false,
        estimatedShipDays: 5,
        minimumOrderQuantity: 2,
        freeShipping: false,
        weightKg: 1.5,
        lengthCm: 30.0,
        widthCm: 20.0,
        heightCm: 10.0,
        taxCode: 'txcd_99999999',
        sellerAddress: const Address(
          street: '123 Main St',
          apartment: 'Suite 4',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 2T6',
          country: 'Canada',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
        deliveryOptions: const [
          SellerDeliveryOption(
            type: 'standard',
            description: 'Standard Delivery',
            costCents: 599,
            estimatedDays: 5,
          ),
          SellerDeliveryOption(
            type: 'express',
            description: 'Express Delivery',
            costCents: 1299,
            estimatedDays: 2,
          ),
        ],
        inventory: const InventoryConfig(
          managed: true,
          trackQuantity: true,
          lowStockThreshold: 10,
        ),
        lifecycleStatus: 'active',
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Full Product'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with null sellerAddress', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_no_addr',
        name: 'No Address Product',
        description: 'Product without seller address.',
        priceCents: 2500,
        sellerId: 'test_user_123',
        categoryId: 3,
        imageUrls: [],
        stockQuantity: 0,
        createdAt: DateTime.now(),
        isDigital: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Address Product'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders digital product', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_digital',
        name: 'Digital Product',
        description: 'A software product.',
        priceCents: 1999,
        sellerId: 'test_user_123',
        categoryId: 21,
        imageUrls: ['https://example.com/img.jpg'],
        stockQuantity: 999,
        createdAt: DateTime.now(),
        isDigital: true,
        digitalType: 'software',
        digitalBuilds: const {
          'macos': 'https://example.com/macos.dmg',
          'windows': 'https://example.com/windows.exe',
        },
        deviceLimit: 3,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Digital Product'), findsWidgets);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders with invalid categoryId', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;

      final testProduct = Product(
        productId: 'prod_bad_cat',
        name: 'Bad Category Product',
        description: 'Product with invalid categoryId.',
        priceCents: 999,
        sellerId: 'test_user_123',
        categoryId: 9999,
        imageUrls: [],
        stockQuantity: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: EditProductScreen(product: testProduct),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bad Category Product'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
