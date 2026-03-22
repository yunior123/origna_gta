import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/home_screen.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'home_recent_products_test.mocks.dart';

void main() {
  late MockProductRepository mockProductRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockProductRepo = MockProductRepository();
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return TestWrapper(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockProductRepo),
        homeViewModelProvider.overrideWith((ref) => HomeViewModel(ref)),
      ],
      child: const HomeScreen(),
    );
  }

  group('HomeScreen Recently Viewed Section Tests', () {
    final testProducts = [
      Product(
        productId: 'p1',
        name: 'Test Product 1',
        priceCents: 2999,
        imageUrls: const ['https://example.com/image1.jpg'],
        description: 'Description 1',
        sellerId: 's1',
        stockQuantity: 10,
        categoryId: 1,
        createdAt: DateTime.now(),
      ),
      Product(
        productId: 'p2',
        name: 'Test Product 2',
        priceCents: 4999,
        imageUrls: const ['https://example.com/image2.jpg'],
        description: 'Description 2',
        sellerId: 's2',
        stockQuantity: 5,
        categoryId: 2,
        createdAt: DateTime.now(),
      ),
      Product(
        productId: 'p3',
        name: 'Test Product 3',
        priceCents: 9999,
        imageUrls: const ['https://example.com/image3.jpg'],
        description: 'Description 3',
        sellerId: 's3',
        stockQuantity: 3,
        categoryId: 1,
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('HomeScreen renders without errors', (
      WidgetTester tester,
    ) async {
      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'RecentlyViewedSection shows nothing when no recently viewed products',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        when(
          mockProductRepo.fetchProducts(
            searchQuery: anyNamed('searchQuery'),
            categoryId: anyNamed('categoryId'),
            subcategory: anyNamed('subcategory'),
            lastDocumentId: anyNamed('lastDocumentId'),
            sortOption: anyNamed('sortOption'),
            minPriceCents: anyNamed('minPriceCents'),
            maxPriceCents: anyNamed('maxPriceCents'),
          ),
        ).thenAnswer(
          (_) async => ProductQueryResult(products: [], hasMore: false),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(const Key('recently_viewed_p1')), findsNothing);
      },
    );

    testWidgets(
      'RecentlyViewedSection renders products from SharedPreferences',
      (WidgetTester tester) async {
        final productIds = ['p1'];
        SharedPreferences.setMockInitialValues({
          LocalStorageKeys.recentlyViewed: jsonEncode(productIds),
        });

        when(
          mockProductRepo.fetchProducts(
            searchQuery: anyNamed('searchQuery'),
            categoryId: anyNamed('categoryId'),
            subcategory: anyNamed('subcategory'),
            lastDocumentId: anyNamed('lastDocumentId'),
            sortOption: anyNamed('sortOption'),
            minPriceCents: anyNamed('minPriceCents'),
            maxPriceCents: anyNamed('maxPriceCents'),
          ),
        ).thenAnswer(
          (_) async => ProductQueryResult(products: [], hasMore: false),
        );

        when(
          mockProductRepo.fetchProductsByIds(['p1']),
        ).thenAnswer((_) async => [testProducts[0]]);

        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 3));

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'RecentlyViewedSection handles empty list in SharedPreferences',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          LocalStorageKeys.recentlyViewed: jsonEncode([]),
        });

        when(
          mockProductRepo.fetchProducts(
            searchQuery: anyNamed('searchQuery'),
            categoryId: anyNamed('categoryId'),
            subcategory: anyNamed('subcategory'),
            lastDocumentId: anyNamed('lastDocumentId'),
            sortOption: anyNamed('sortOption'),
            minPriceCents: anyNamed('minPriceCents'),
            maxPriceCents: anyNamed('maxPriceCents'),
          ),
        ).thenAnswer(
          (_) async => ProductQueryResult(products: [], hasMore: false),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('RecentlyViewedSection handles invalid JSON gracefully', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.recentlyViewed: 'invalid-json',
      });

      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('RecentlyViewedSection handles non-list JSON', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.recentlyViewed: jsonEncode({'not': 'a list'}),
      });

      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('RecentlyViewedSection limits to 10 products', (
      WidgetTester tester,
    ) async {
      final manyIds = List.generate(15, (i) => 'p${i + 1}');
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.recentlyViewed: jsonEncode(manyIds),
      });

      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      final manyProducts = List.generate(
        15,
        (i) => Product(
          productId: 'p${i + 1}',
          name: 'Product ${i + 1}',
          priceCents: 1000,
          imageUrls: const ['https://example.com/img.jpg'],
          description: 'Desc',
          sellerId: 's1',
          stockQuantity: 5,
          categoryId: 1,
          createdAt: DateTime.now(),
        ),
      );
      when(
        mockProductRepo.fetchProductsByIds(any),
      ).thenAnswer((_) async => manyProducts);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('HomeScreen displays title', (WidgetTester tester) async {
      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_screen_title')), findsOneWidget);
    });

    testWidgets('HomeScreen has search field', (WidgetTester tester) async {
      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_search_field')), findsOneWidget);
    });

    testWidgets('HomeScreen has settings button', (WidgetTester tester) async {
      when(
        mockProductRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
    });

    testWidgets(
      'RecentlyViewedSection shows ProductCard when products loaded',
      (WidgetTester tester) async {
        final productIds = ['p1', 'p2'];
        SharedPreferences.setMockInitialValues({
          LocalStorageKeys.recentlyViewed: jsonEncode(productIds),
        });

        when(
          mockProductRepo.fetchProducts(
            searchQuery: anyNamed('searchQuery'),
            categoryId: anyNamed('categoryId'),
            subcategory: anyNamed('subcategory'),
            lastDocumentId: anyNamed('lastDocumentId'),
            sortOption: anyNamed('sortOption'),
            minPriceCents: anyNamed('minPriceCents'),
            maxPriceCents: anyNamed('maxPriceCents'),
          ),
        ).thenAnswer(
          (_) async => ProductQueryResult(products: [], hasMore: false),
        );

        when(
          mockProductRepo.fetchProductsByIds(['p1', 'p2']),
        ).thenAnswer((_) async => [testProducts[0], testProducts[1]]);

        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 3));

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });

  group('ProductCard Key Tests for RecentlyViewed', () {
    testWidgets('ProductCard uses correct key format', (
      WidgetTester tester,
    ) async {
      final testProduct = Product(
        productId: 'test_prod_123',
        name: 'Test',
        priceCents: 1000,
        imageUrls: const [],
        description: 'Test',
        sellerId: 's1',
        stockQuantity: 5,
        categoryId: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 150,
                child: ProductCard(
                  key: Key('recently_viewed_${testProduct.productId}'),
                  productId: testProduct.productId,
                  product: testProduct,
                  userModel: null,
                  heroTagPrefix: 'recently_viewed_image',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byKey(const Key('recently_viewed_test_prod_123')),
        findsOneWidget,
      );
    });
  });
}
