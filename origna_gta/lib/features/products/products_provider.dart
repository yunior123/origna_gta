import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/models/generated/models.dart';

// ============================================================================
// FILTER STATE PROVIDERS
// ============================================================================

/// Full product details for all favorites
final favoritedProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
  if (favoriteIds.isEmpty) return [];

  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProductsByIds(favoriteIds.toList());
});

/// Favorites controller
final favoritesControllerProvider = Provider.autoDispose<FavoritesController>((ref) {
  return FavoritesController(ref);
});

// ============================================================================
// PRODUCTS PROVIDER
// ============================================================================

/// Stream of favorite product IDs for current user.
/// Uses [keepAlive] when a user is logged in to prevent the stream from being
/// disposed during transient rebuilds (e.g. category switches clear the product
/// grid which briefly removes all ProductCard watchers). Without this, the
/// stream restarts in AsyncLoading and the heart icon blinks.
final favoritesProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value({});

  // Keep the stream alive while a user is logged in so it survives
  // product-grid rebuilds (category change, search, etc.).
  ref.keepAlive();

  final repository = ref.watch(productRepositoryProvider);
  return repository.watchFavorites(userId);
});

/// Convenience provider that uses current filter state
final filteredProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  final query = ProductQuery(categoryId: categoryId, searchQuery: searchQuery);

  return ref.watch(productsProvider(query).future);
});

/// Fetches a single product by ID
final productByIdProvider = FutureProvider.autoDispose.family<Product?, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.fetchProductById(productId);
});

/// Fetches products based on query parameters
final productsProvider = FutureProvider.autoDispose.family<List<Product>, ProductQuery>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.fetchProducts(categoryId: query.categoryId, searchQuery: query.searchQuery, pageSize: query.limit);
  return result.products;
});

// ============================================================================
// FAVORITES PROVIDER
// ============================================================================

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected category ID (null = all categories)
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

class FavoritesController {
  final Ref _ref;

  FavoritesController(this._ref);

  ProductRepository get _repository => _ref.read(productRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Check if product is favorited
  bool isFavorite(String productId) {
    final favorites = _ref.read(favoritesProvider).valueOrNull ?? {};
    return favorites.contains(productId);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.toggleFavorite(userId, productId);
  }
}

/// Query parameters for products
class ProductQuery {
  final int? categoryId;
  final String searchQuery;
  final int limit;

  const ProductQuery({this.categoryId, this.searchQuery = '', this.limit = 20});

  @override
  int get hashCode => categoryId.hashCode ^ searchQuery.hashCode ^ limit.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductQuery && runtimeType == other.runtimeType && categoryId == other.categoryId && searchQuery == other.searchQuery && limit == other.limit;
}
