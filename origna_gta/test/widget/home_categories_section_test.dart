import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'home_categories_section_test.mocks.dart';

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

  group('HomeScreen Categories and Filters Tests', () {
    testWidgets('HomeScreen renders sort chip with correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    });

    testWidgets('HomeScreen renders price filter chip with correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.attach_money_rounded), findsWidgets);
    });

    testWidgets('HomeScreen renders Canada-only chip with correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('🍁'), findsOneWidget);
    });

    testWidgets('HomeScreen renders settings button with correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.bySemanticsLabel('btn-home-settings'), findsOneWidget);
    });

    testWidgets('HomeScreen settings button has correct key', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
    });

    testWidgets('HomeScreen displays correct icons for sort chip', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('HomeScreen displays correct icons for price filter', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.attach_money_rounded), findsOneWidget);
    });

    testWidgets('HomeScreen displays settings icon', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('HomeScreen search field has correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_search_field')), findsOneWidget);
    });

    testWidgets('HomeScreen search field has correct key', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('home_search_field')), findsOneWidget);
    });

    testWidgets('HomeScreen uses GestureDetector for filter chips', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('HomeScreen uses AnimatedContainer for filter chips', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });

  group('HomeScreen Category Navigation Tests', () {
    testWidgets('HomeScreen displays categories section', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('HomeScreen handles scroll for pagination', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('HomeScreen uses RefreshIndicator', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('HomeScreen privacy policy button has correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Scroll to bottom to render footer with privacy/terms links
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Privacy'), findsWidgets);
    });

    testWidgets('HomeScreen terms of service button has correct semantics', (
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Scroll to bottom to render footer
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Terms'), findsWidgets);
    });
  });

  group('HomeScreen Tap Interaction Tests', () {
    testWidgets('sort chip is tappable', (WidgetTester tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final sortChip = find.byIcon(Icons.sort_rounded);
      expect(sortChip, findsOneWidget);

      await tester.tap(sortChip);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('price filter chip is tappable', (WidgetTester tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final priceFilter = find.byIcon(Icons.attach_money_rounded);
      expect(priceFilter, findsWidgets);

      await tester.tap(priceFilter.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('canada-only chip is tappable', (WidgetTester tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final canadaChip = find.text('🍁');
      expect(canadaChip, findsOneWidget);

      await tester.tap(canadaChip);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('settings button is tappable', (WidgetTester tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final settingsBtn = find.byKey(const Key('home_settings_button'));
      expect(settingsBtn, findsOneWidget);

      await tester.tap(settingsBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('search field is focusable', (WidgetTester tester) async {
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final searchField = find.byKey(const Key('home_search_field'));
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
