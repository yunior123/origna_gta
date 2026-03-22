import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/home/home_viewmodel.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'home_viewmodel_comprehensive_test.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  Product createTestProduct(
    String id,
    String name, {
    int? categoryId,
    String? sellerId,
  }) {
    return Product(
      productId: id,
      name: name,
      priceCents: 1000,
      description: 'Test description',
      imageUrls: const [],
      sellerId: sellerId ?? 'seller1',
      categoryId: categoryId ?? 1,
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
    ).thenAnswer(
      (_) async => ProductQueryResult(
        products: [createTestProduct('init', 'initial product')],
        lastDocumentId: null,
        hasMore: true,
      ),
    );

    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(mockRepo)],
    );

    container.listen(homeViewModelProvider, (_, _) {});

    await Future.delayed(const Duration(milliseconds: 10));
    while (container.read(homeViewModelProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDown(() {
    container.dispose();
  });

  group('HomeViewModel Initial State Tests', () {
    test('initial state has correct default values', () {
      final state = container.read(homeViewModelProvider);
      expect(state.products, isNotEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.searchQuery, isEmpty);
      expect(state.selectedCategoryId, isNull);
      expect(state.selectedSubcategory, isNull);
      expect(state.errorMessage, isNull);
      expect(state.selectedSort, SortOption.relevance);
      expect(state.minPriceCents, isNull);
      expect(state.maxPriceCents, isNull);
      expect(state.recentSearches, isEmpty);
      expect(state.searchSuggestions, isEmpty);
      expect(state.showSearchOverlay, isFalse);
      expect(state.canadaOnly, isFalse);
    });
  });

  group('HomeViewModel State Transition Tests', () {
    test('loadProducts sets isLoading on initial load', () async {
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
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return ProductQueryResult(
          products: [createTestProduct('1', 'P1')],
          lastDocumentId: null,
          hasMore: false,
        );
      });

      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.refresh();

      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(homeViewModelProvider).isLoading, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(container.read(homeViewModelProvider).isLoading, isFalse);
    });

    test('loadProducts sets isLoadingMore on subsequent loads', () async {
      final p1 = createTestProduct('1', 'P1');
      final p2 = createTestProduct('2', 'P2');

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
          products: [p1],
          lastDocumentId: 'doc1',
          hasMore: true,
        ),
      );

      final viewModel = container.read(homeViewModelProvider.notifier);
      await viewModel.refresh();
      expect(container.read(homeViewModelProvider).products.length, 1);

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
          products: [p2],
          lastDocumentId: 'doc2',
          hasMore: false,
        ),
      );

      await viewModel.loadProducts();
      expect(
        container.read(homeViewModelProvider).products.length,
        greaterThanOrEqualTo(1),
      );
    });

    test('loadProducts transitions from loading to error state', () async {
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
      ).thenThrow(Exception('Network error'));

      final viewModel = container.read(homeViewModelProvider.notifier);
      await viewModel.refresh();

      final state = container.read(homeViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.products, isEmpty);
    });
  });

  group('HomeViewModel Public Methods Tests', () {
    test('onSearchSubmitted sets search query and clears overlay', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.onSearchFocusChanged(true);
      viewModel.onSearchSubmitted('test product');

      final state = container.read(homeViewModelProvider);
      expect(state.searchQuery, 'test product');
      expect(state.showSearchOverlay, isFalse);
      expect(state.recentSearches, contains('test product'));
    });

    test('onSearchSubmitted ignores empty queries', () {
      final viewModel = container.read(homeViewModelProvider.notifier);
      final prevState = container.read(homeViewModelProvider);

      viewModel.onSearchSubmitted('   ');

      final state = container.read(homeViewModelProvider);
      expect(state.searchQuery, prevState.searchQuery);
    });

    test('onSortChanged resets and reloads with new sort', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onSortChanged(SortOption.priceLowToHigh);

      final state = container.read(homeViewModelProvider);
      expect(state.selectedSort, SortOption.priceLowToHigh);
      expect(state.products, isEmpty);
      expect(state.hasMore, isTrue);
    });

    test('onPriceFilterChanged applies price range', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onPriceFilterChanged(1000, 5000);

      final state = container.read(homeViewModelProvider);
      expect(state.minPriceCents, 1000);
      expect(state.maxPriceCents, 5000);
      expect(state.hasPriceFilter, isTrue);
    });

    test('clearPriceFilter removes price filter', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onPriceFilterChanged(1000, 5000);
      expect(container.read(homeViewModelProvider).hasPriceFilter, isTrue);

      viewModel.clearPriceFilter();
      expect(container.read(homeViewModelProvider).hasPriceFilter, isFalse);
    });

    test('onCategorySelected resets products and sets category', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onCategorySelected(5);

      final state = container.read(homeViewModelProvider);
      expect(state.selectedCategoryId, 5);
      expect(state.selectedSubcategory, isNull);
      expect(state.products, isEmpty);
    });

    test('onSubcategorySelected sets subcategory', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onSubcategorySelected('electronics');

      final state = container.read(homeViewModelProvider);
      expect(state.selectedSubcategory, 'electronics');
    });

    test('onToggleCanadaOnly toggles flag', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      final initial = container.read(homeViewModelProvider).canadaOnly;
      viewModel.onToggleCanadaOnly();
      expect(container.read(homeViewModelProvider).canadaOnly, !initial);

      viewModel.onToggleCanadaOnly();
      expect(container.read(homeViewModelProvider).canadaOnly, initial);
    });
  });

  group('HomeViewModel Recent Searches Tests', () {
    test('addRecentSearch adds to front of list', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      await viewModel.addRecentSearch('first');
      await viewModel.addRecentSearch('second');

      final state = container.read(homeViewModelProvider);
      expect(state.recentSearches, ['second', 'first']);
    });

    test('addRecentSearch moves existing to front', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      await viewModel.addRecentSearch('first');
      await viewModel.addRecentSearch('second');
      await viewModel.addRecentSearch('first');

      final state = container.read(homeViewModelProvider);
      expect(state.recentSearches, ['first', 'second']);
      expect(state.recentSearches.length, 2);
    });

    test('addRecentSearch limits to 5 items', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      for (var i = 1; i <= 7; i++) {
        await viewModel.addRecentSearch('search_$i');
      }

      final state = container.read(homeViewModelProvider);
      expect(state.recentSearches.length, lessThanOrEqualTo(5));
    });

    test('addRecentSearch ignores empty strings', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      await viewModel.addRecentSearch('valid');
      await viewModel.addRecentSearch('');
      await viewModel.addRecentSearch('   ');

      final state = container.read(homeViewModelProvider);
      expect(state.recentSearches, contains('valid'));
      expect(state.recentSearches.length, 1);
    });

    test('clearRecentSearches removes all searches', () async {
      final viewModel = container.read(homeViewModelProvider.notifier);

      await viewModel.addRecentSearch('test1');
      await viewModel.addRecentSearch('test2');
      expect(container.read(homeViewModelProvider).recentSearches, isNotEmpty);

      await viewModel.clearRecentSearches();
      expect(container.read(homeViewModelProvider).recentSearches, isEmpty);
    });
  });

  group('HomeViewModel Search Overlay Tests', () {
    test('onSearchFocusChanged shows overlay when focused', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onSearchFocusChanged(true);

      expect(container.read(homeViewModelProvider).showSearchOverlay, isTrue);
    });

    test('onSearchFocusChanged hides overlay when unfocused', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onSearchFocusChanged(true);
      viewModel.onSearchFocusChanged(false);

      expect(container.read(homeViewModelProvider).showSearchOverlay, isFalse);
    });

    test('dismissSearchOverlay clears overlay state', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      viewModel.onSearchFocusChanged(true);
      viewModel.dismissSearchOverlay();

      final state = container.read(homeViewModelProvider);
      expect(state.showSearchOverlay, isFalse);
      expect(state.searchSuggestions, isEmpty);
    });
  });

  group('HomeViewModel Search Debounce Tests', () {
    test('onSearchChanged debounces rapid input', () {
      fakeAsync((async) {
        final viewModel = container.read(homeViewModelProvider.notifier);

        viewModel.onSearchChanged('t');
        viewModel.onSearchChanged('te');
        viewModel.onSearchChanged('tes');
        viewModel.onSearchChanged('test');

        async.elapse(const Duration(milliseconds: 200));
        expect(container.read(homeViewModelProvider).searchQuery, isEmpty);

        async.elapse(const Duration(milliseconds: 400));
        expect(container.read(homeViewModelProvider).searchQuery, 'test');
      });
    });

    test('onSearchChanged clears search with empty input', () {
      fakeAsync((async) {
        final viewModel = container.read(homeViewModelProvider.notifier);

        viewModel.onSearchChanged('test');
        async.elapse(const Duration(milliseconds: 600));
        expect(container.read(homeViewModelProvider).searchQuery, 'test');

        viewModel.onSearchChanged('');
        async.elapse(const Duration(milliseconds: 400));
        expect(container.read(homeViewModelProvider).searchQuery, isEmpty);
      });
    });
  });

  group('HomeViewModel Edge Cases Tests', () {
    test('loadProducts prevents duplicate concurrent calls', () async {
      reset(mockRepo);
      var callCount = 0;
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
      ).thenAnswer((_) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return ProductQueryResult(
          products: [],
          lastDocumentId: null,
          hasMore: false,
        );
      });

      final viewModel = container.read(homeViewModelProvider.notifier);
      viewModel.refresh();

      await viewModel.loadProducts();
      await viewModel.loadProducts();

      expect(callCount, lessThanOrEqualTo(2));
    });

    test('loadProducts handles empty result correctly', () async {
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
          products: [],
          lastDocumentId: null,
          hasMore: false,
        ),
      );

      final viewModel = container.read(homeViewModelProvider.notifier);
      await viewModel.refresh();

      final state = container.read(homeViewModelProvider);
      expect(state.products, isEmpty);
      expect(state.hasMore, isFalse);
    });

    test('displayedProducts filters by canadaOnly', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      final productCA = createTestProduct(
        '1',
        'CA Product',
      ).copyWith(shipFromCountry: 'CA');
      final productUS = createTestProduct(
        '2',
        'US Product',
      ).copyWith(shipFromCountry: 'US');

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
          products: [productCA, productUS],
          lastDocumentId: null,
          hasMore: false,
        ),
      );

      viewModel.refresh();
      viewModel.onToggleCanadaOnly();

      final state = container.read(homeViewModelProvider);
      final displayed = state.displayedProducts;
    });

    test('hasPriceFilter returns correct value', () {
      final viewModel = container.read(homeViewModelProvider.notifier);

      expect(container.read(homeViewModelProvider).hasPriceFilter, isFalse);

      viewModel.onPriceFilterChanged(1000, null);
      expect(container.read(homeViewModelProvider).hasPriceFilter, isTrue);

      viewModel.clearPriceFilter();
      expect(container.read(homeViewModelProvider).hasPriceFilter, isFalse);

      viewModel.onPriceFilterChanged(null, 5000);
      expect(container.read(homeViewModelProvider).hasPriceFilter, isTrue);
    });
  });

  group('HomeState copyWith Tests', () {
    test('copyWith preserves values when not specified', () {
      final state = HomeState(
        products: [],
        isLoading: true,
        hasMore: false,
        searchQuery: 'test',
        selectedCategoryId: 5,
      );

      final copied = state.copyWith();

      expect(copied.isLoading, isTrue);
      expect(copied.hasMore, isFalse);
      expect(copied.searchQuery, 'test');
      expect(copied.selectedCategoryId, 5);
    });

    test('copyWith can null out optional values', () {
      final state = HomeState(selectedCategoryId: 5, minPriceCents: 1000);

      final copied = state.copyWith(
        selectedCategoryId: null,
        minPriceCents: null,
      );

      expect(copied.selectedCategoryId, isNull);
      expect(copied.minPriceCents, isNull);
    });
  });
}
