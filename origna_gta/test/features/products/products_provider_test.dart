import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/products/products_provider.dart';

import '../../test_utils.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>()])
import 'products_provider_test.mocks.dart';

void main() {
  late MockProductRepository mockProductRepo;
  late ProviderContainer container;

  const testUserId = 'user_123';
  const testProductId = 'prod_1';
  const testCategoryId = 1;

  setUp(() {
    mockProductRepo = MockProductRepository();
    initTestMocks();
  });

  group('favoritesProvider', () {
    test('returns empty set when user is not logged in', () {
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(null),
        ],
      );

      final favoritesAsync = container.read(favoritesProvider);

      favoritesAsync.whenData((favorites) {
        expect(favorites, isEmpty);
      });

      container.dispose();
    });

    test('returns favorite IDs when logged in', () async {
      when(
        mockProductRepo.watchFavorites(testUserId),
      ).thenAnswer((_) => Stream.value({testProductId}));

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final favorites = await container.read(favoritesProvider.future);

      expect(favorites, contains(testProductId));

      container.dispose();
    });
  });

  group('favoritedProductsProvider', () {
    test('returns empty list when no favorites', () async {
      when(
        mockProductRepo.watchFavorites(testUserId),
      ).thenAnswer((_) => Stream.value({}));

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final subscription = container.listen(
        favoritedProductsProvider,
        (previous, next) {},
      );
      final products = await container.read(favoritedProductsProvider.future);

      expect(products, isEmpty);

      subscription.close();
      container.dispose();
    });

    test('fetches products for favorite IDs', () async {
      when(
        mockProductRepo.watchFavorites(testUserId),
      ).thenAnswer((_) => Stream.value({testProductId}));

      when(
        mockProductRepo.fetchProductsByIds([testProductId]),
      ).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final subscription = container.listen(
        favoritedProductsProvider,
        (previous, next) {},
      );
      final products = await container.read(favoritedProductsProvider.future);

      expect(products, hasLength(0));

      subscription.close();
      container.dispose();
    });

    test('chunks large favorite lists', () async {
      final manyIds = List.generate(35, (i) => 'prod_$i').toSet();
      final idsList = manyIds.toList();
      final chunk1 = idsList.sublist(0, 30);
      final chunk2 = idsList.sublist(30);

      when(
        mockProductRepo.watchFavorites(testUserId),
      ).thenAnswer((_) => Stream.value(manyIds));
      when(
        mockProductRepo.fetchProductsByIds(chunk1),
      ).thenAnswer((_) async => []);
      when(
        mockProductRepo.fetchProductsByIds(chunk2),
      ).thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final subscription = container.listen(
        favoritedProductsProvider,
        (previous, next) {},
      );
      await container.read(favoritedProductsProvider.future);

      verify(mockProductRepo.fetchProductsByIds(chunk1)).called(1);
      verify(mockProductRepo.fetchProductsByIds(chunk2)).called(1);

      subscription.close();
      container.dispose();
    });
  });

  group('FavoritesController', () {
    late FavoritesController controller;

    setUp(() async {
      when(
        mockProductRepo.watchFavorites(testUserId),
      ).thenAnswer((_) => Stream.value({testProductId}));

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      await container.read(favoritesProvider.future);
      controller = container.read(favoritesControllerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('isFavorite returns true for favorited product', () {
      final result = controller.isFavorite(testProductId);

      expect(result, true);
    });

    test('isFavorite returns false for non-favorited product', () {
      final result = controller.isFavorite('other_product');

      expect(result, false);
    });

    test('toggleFavorite calls repository', () async {
      when(
        mockProductRepo.toggleFavorite(testUserId, testProductId),
      ).thenAnswer((_) async {});

      await controller.toggleFavorite(testProductId);

      verify(
        mockProductRepo.toggleFavorite(testUserId, testProductId),
      ).called(1);
    });

    test('toggleFavorite does nothing when user not logged in', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(null),
        ],
      );

      final emptyController = emptyContainer.read(favoritesControllerProvider);

      await emptyController.toggleFavorite(testProductId);

      verifyNever(mockProductRepo.toggleFavorite(any, any));

      emptyContainer.dispose();
    });
  });

  group('productsProvider', () {
    test('fetches products with category filter', () async {
      when(
        mockProductRepo.fetchProducts(
          categoryId: testCategoryId,
          searchQuery: anyNamed('searchQuery'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer(
        (_) async => ProductQueryResult(products: [], hasMore: false),
      );

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );

      final query = ProductQuery(categoryId: testCategoryId);
      final products = await container.read(productsProvider(query).future);

      expect(products, hasLength(0));
      verify(
        mockProductRepo.fetchProducts(
          categoryId: testCategoryId,
          searchQuery: '',
          pageSize: 20,
        ),
      ).called(1);

      container.dispose();
    });
  });

  group('searchQueryProvider', () {
    test('has default empty value', () {
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );

      final query = container.read(searchQueryProvider);

      expect(query, isEmpty);

      container.dispose();
    });

    test('can be updated', () {
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );

      container.read(searchQueryProvider.notifier).state = 'new query';

      final query = container.read(searchQueryProvider);

      expect(query, equals('new query'));

      container.dispose();
    });
  });

  group('selectedCategoryProvider', () {
    test('has default null value', () {
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );

      final category = container.read(selectedCategoryProvider);

      expect(category, isNull);

      container.dispose();
    });

    test('can be updated', () {
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );

      container.read(selectedCategoryProvider.notifier).state = testCategoryId;

      final category = container.read(selectedCategoryProvider);

      expect(category, equals(testCategoryId));

      container.dispose();
    });
  });

  group('ProductQuery', () {
    test('equality works correctly', () {
      const query1 = ProductQuery(
        categoryId: 1,
        searchQuery: 'test',
        limit: 20,
      );
      const query2 = ProductQuery(
        categoryId: 1,
        searchQuery: 'test',
        limit: 20,
      );
      const query3 = ProductQuery(
        categoryId: 2,
        searchQuery: 'test',
        limit: 20,
      );

      expect(query1 == query2, true);
      expect(query1 == query3, false);
    });

    test('hashCode is consistent', () {
      const query1 = ProductQuery(
        categoryId: 1,
        searchQuery: 'test',
        limit: 20,
      );
      const query2 = ProductQuery(
        categoryId: 1,
        searchQuery: 'test',
        limit: 20,
      );

      expect(query1.hashCode, equals(query2.hashCode));
    });
  });
}
