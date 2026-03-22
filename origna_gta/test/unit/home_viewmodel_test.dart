import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'home_viewmodel_test.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  Product createTestProduct(String id, String name) {
    return Product(
      productId: id,
      name: name,
      priceCents: 1000,
      description: 'Test description',
      imageUrls: const [],
      sellerId: 'seller1',
      categoryId: 1,
      stockQuantity: 10,
      createdAt: DateTime.now(),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockProductRepository();

    when(
      mockRepo.fetchProducts(
        searchQuery: anyNamed('searchQuery'),
        categoryId: anyNamed('categoryId'),
        subcategory: anyNamed('subcategory'),
        lastDocumentId: anyNamed('lastDocumentId'),
        pageSize: anyNamed('pageSize'),
        sortOption: anyNamed('sortOption'),
        minPriceCents: anyNamed('minPriceCents'),
        maxPriceCents: anyNamed('maxPriceCents'),
      ),
    ).thenAnswer((_) async => ProductQueryResult(products: [createTestProduct('init', 'initial product')], lastDocumentId: null, hasMore: true));

    container = ProviderContainer(overrides: [productRepositoryProvider.overrideWithValue(mockRepo)]);

    // Keep alive and wait for initial load
    container.listen(homeViewModelProvider, (_, _) {});

    // Constructor triggers load
    await Future.delayed(const Duration(milliseconds: 10));
    while (container.read(homeViewModelProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDown(() {
    container.dispose();
  });

  group('HomeViewModel', () {
    test('initial state loads products', () {
      verify(mockRepo.fetchProducts(searchQuery: '')).called(greaterThan(0));
      expect(container.read(homeViewModelProvider).products.length, 1);
    });

    test('onSearchChanged updates state and reloads with debounce', () {
      fakeAsync((async) {
        final viewModel = container.read(homeViewModelProvider.notifier);
        viewModel.onSearchChanged('new query');

        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();
        expect(container.read(homeViewModelProvider).searchQuery, '');

        async.elapse(const Duration(milliseconds: 301));
        async.flushMicrotasks();
        expect(container.read(homeViewModelProvider).searchQuery, 'new query');

        verify(
          mockRepo.fetchProducts(
            searchQuery: 'new query',
            categoryId: anyNamed('categoryId'),
            subcategory: anyNamed('subcategory'),
            lastDocumentId: anyNamed('lastDocumentId'),
            pageSize: anyNamed('pageSize'),
            sortOption: anyNamed('sortOption'),
            minPriceCents: anyNamed('minPriceCents'),
            maxPriceCents: anyNamed('maxPriceCents'),
          ),
        ).called(greaterThan(0));
      });
    });

    test('onCategorySelected updates state and reloads', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onCategorySelected(1);
      expect(container.read(homeViewModelProvider).selectedCategoryId, 1);
    });

    test('onSubcategorySelected updates state and reloads', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onSubcategorySelected('test_sub');
      expect(container.read(homeViewModelProvider).selectedSubcategory, 'test_sub');
    });

    test('loadProducts handles error', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      reset(mockRepo);
      when(
        mockRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          pageSize: anyNamed('pageSize'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenThrow(Exception('Failed'));

      await Future.delayed(Duration.zero);

      await viewModel.loadProducts();

      final state = container.read(homeViewModelProvider);
      expect(state.errorMessage, isNotNull, reason: 'Error should be set. State: isLoading=${state.isLoading}, hasMore=${state.hasMore}');
      expect(state.isLoading, isFalse);
    });

    test('loadProducts filters duplicate IDs', () async {
      final p1 = createTestProduct('1', 'P1');
      final p2 = createTestProduct('2', 'P2');

      final viewModel = container.read(homeViewModelProvider.notifier);

      reset(mockRepo);
      when(
        mockRepo.fetchProducts(
          searchQuery: anyNamed('searchQuery'),
          categoryId: anyNamed('categoryId'),
          subcategory: anyNamed('subcategory'),
          lastDocumentId: anyNamed('lastDocumentId'),
          pageSize: anyNamed('pageSize'),
          sortOption: anyNamed('sortOption'),
          minPriceCents: anyNamed('minPriceCents'),
          maxPriceCents: anyNamed('maxPriceCents'),
        ),
      ).thenAnswer((_) async => ProductQueryResult(products: [p1, p2], lastDocumentId: null, hasMore: true));

      await viewModel.refresh();
      expect(container.read(homeViewModelProvider).products.length, 2);

      reset(mockRepo);
      when(
        mockRepo.fetchProducts(
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
          products: [
            p2, // duplicate
            createTestProduct('3', 'P3'),
          ],
          lastDocumentId: null,
          hasMore: false,
        ),
      );

      await viewModel.loadProducts();
      final products = container.read(homeViewModelProvider).products;
      expect(products.length, 3, reason: 'IDs: ${products.map((p) => p.productId).toList()}');
    });

    test('onSearchFocusChanged updates overlay and suggestions', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onSearchFocusChanged(true);
      expect(container.read(homeViewModelProvider).showSearchOverlay, isTrue);

      viewModel.onSearchFocusChanged(false);
      expect(container.read(homeViewModelProvider).showSearchOverlay, isFalse);
    });

    test('refresh resets state and reloads', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);
      await viewModel.refresh();
      verify(mockRepo.fetchProducts(searchQuery: anyNamed('searchQuery'))).called(greaterThan(0));
    });

    test('onToggleCanadaOnly toggles state', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      final initial = container.read(homeViewModelProvider).canadaOnly;
      viewModel.onToggleCanadaOnly();
      expect(container.read(homeViewModelProvider).canadaOnly, !initial);
    });

    test('onSortChanged updates state and reloads', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onSortChanged(SortOption.priceHighToLow);
      expect(container.read(homeViewModelProvider).selectedSort, SortOption.priceHighToLow);
    });

    test('onPriceFilterChanged updates state and reloads', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onPriceFilterChanged(1000, 5000);
      expect(container.read(homeViewModelProvider).minPriceCents, 1000);
    });

    test('clearRecentSearches clears state', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);
      await viewModel.addRecentSearch('query');
      await viewModel.clearRecentSearches();
      expect(container.read(homeViewModelProvider).recentSearches, isEmpty);
    });

    test('onSearchSubmitted clears overlay and adds recent search', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onSearchFocusChanged(true);
      viewModel.onSearchSubmitted('test term');

      expect(container.read(homeViewModelProvider).showSearchOverlay, isFalse);
      expect(container.read(homeViewModelProvider).recentSearches, contains('test term'));
    });
  });
}
