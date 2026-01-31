import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// FILTER STATE PROVIDERS
// ============================================================================

/// Currently selected category ID (null = all categories)
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// ============================================================================
// PRODUCTS PROVIDER
// ============================================================================

/// Query parameters for products
class ProductQuery {
  final int? categoryId;
  final String searchQuery;
  final int limit;

  const ProductQuery({
    this.categoryId,
    this.searchQuery = '',
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductQuery &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery &&
          limit == other.limit;

  @override
  int get hashCode => categoryId.hashCode ^ searchQuery.hashCode ^ limit.hashCode;
}

/// Fetches products based on query parameters (legacy, kept for compat if needed, but home uses VM now)
final productsProvider = FutureProvider.autoDispose.family<List<ProductModel>, ProductQuery>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.fetchProducts(
    categoryId: query.categoryId,
    searchQuery: query.searchQuery,
    pageSize: query.limit,
  );
  return result.products;
});

/// Convenience provider that uses current filter state
final filteredProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  final query = ProductQuery(
    categoryId: categoryId,
    searchQuery: searchQuery,
  );

  return ref.watch(productsProvider(query).future);
});

/// Fetches a single product by ID
final productByIdProvider = FutureProvider.autoDispose.family<ProductModel?, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProductById(productId);
});

// ============================================================================
// FAVORITES PROVIDER
// ============================================================================

/// Stream of favorite product IDs for current user
final favoritesProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value({});

  final repository = ref.watch(productRepositoryProvider);
  return repository.watchFavorites(userId);
});

/// Favorites controller
final favoritesControllerProvider = Provider<FavoritesController>((ref) {
  return FavoritesController(ref);
});

class FavoritesController {
  final Ref _ref;
  
  FavoritesController(this._ref);

  String? get _userId => _ref.read(userIdProvider);
  ProductRepository get _repository => _ref.read(productRepositoryProvider);

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.toggleFavorite(userId, productId);
  }

  /// Check if product is favorited
  bool isFavorite(String productId) {
    final favorites = _ref.read(favoritesProvider).valueOrNull ?? {};
    return favorites.contains(productId);
  }
}

/// Full product details for all favorites
final favoritedProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
  if (favoriteIds.isEmpty) return [];

  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProductsByIds(favoriteIds.toList());
});
