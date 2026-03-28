import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/analytics_service.dart'
    show analyticsServiceProvider;
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// FILTER STATE PROVIDERS
// ============================================================================

/// Full product details for all favorited products.
///
/// Chunks favorite IDs into batches of 30 (OrignaBase batch query limit) and
/// fetches all chunks in parallel via [Future.wait]. Reassembles results into
/// a single flat list.
///
/// Parameters:
/// - None (watches [favoritesProvider]).
///
/// Returns:
/// - A list of [Product] models for all items in the user's wishlist.
///
/// Gotchas:
/// - High number of favorites can trigger multiple parallel network requests.
///
/// See also:
/// - [favoritesProvider] for the reactive set of favorite IDs
/// - [FavoritesController] for toggle operations
final favoritedProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
  if (favoriteIds.isEmpty) return [];

  final repository = ref.watch(productRepositoryProvider);
  final ids = favoriteIds.toList();

  // Chunk into 30-ID batches (batch query limit)
  final chunks = [
    for (var i = 0; i < ids.length; i += 30)
      ids.sublist(i, min(i + 30, ids.length)),
  ];
  // Fetch chunks in parallel
  final results = await Future.wait(
    chunks.map((c) => repository.fetchProductsByIds(c)),
  );
  return results.expand((x) => x).toList();
});

/// Riverpod provider for [FavoritesController].
final favoritesControllerProvider = Provider.autoDispose<FavoritesController>((
  ref,
) {
  return FavoritesController(ref);
});

// ============================================================================
// PRODUCTS PROVIDER
// ============================================================================

/// Stream of favorite product IDs for the current user.
///
/// Returns an empty set when no user is signed in.
///
/// ## Key Decisions
/// - Uses [keepAlive] when a user is logged in to prevent the stream from being
///   disposed during transient rebuilds (e.g., category switches clear the product
///   grid which briefly removes all ProductCard watchers). Without this, the
///   stream restarts in AsyncLoading and the heart icon blinks.
/// - The [keepAlive] link is closed on dispose to prevent leaks after logout.
///
/// Gotchas:
/// - This provider only tracks IDs; use [favoritedProductsProvider] for full data.
final favoritesProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value({});

  // Keep the stream alive while a user is logged in so it survives
  // product-grid rebuilds (category change, search, etc.).
  // Store the link so we can close it on logout to prevent keepAlive leaks.
  final link = ref.keepAlive();
  ref.onDispose(link.close);

  final repository = ref.watch(productRepositoryProvider);
  return repository.watchFavorites(userId);
});

/// Convenience provider that applies current filter state (category, search) to the product list.
///
/// Returns:
/// - A list of products matching the current [selectedCategoryProvider] and [searchQueryProvider].
final filteredProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  final query = ProductQuery(categoryId: categoryId, searchQuery: searchQuery);

  return ref.watch(productsProvider(query).future);
});

/// Fetches a single product by its document ID.
///
/// Returns `null` if the product doesn't exist. Used by product detail screen
/// deep links and admin product preview.
///
/// Parameters:
/// - [productId]: the ID of the product to fetch.
final productByIdProvider = FutureProvider.autoDispose.family<Product?, String>(
  (ref, productId) async {
    final repository = ref.watch(productRepositoryProvider);
    return repository.fetchProductById(productId);
  },
);

/// Fetches a single product by its URL-friendly slug.
///
/// Parameters:
/// - [slug]: the product slug.
final productBySlugProvider = FutureProvider.autoDispose
    .family<Product?, String>((ref, slug) async {
      final repository = ref.watch(productRepositoryProvider);
      return repository.getProductBySlug(slug);
    });

/// Fetches a page of products based on query parameters.
///
/// Parameters:
/// - [query]: [ProductQuery] object containing filters and limits.
final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, ProductQuery>((ref, query) async {
      final repository = ref.watch(productRepositoryProvider);
      final result = await repository.fetchProducts(
        categoryId: query.categoryId,
        searchQuery: query.searchQuery,
        pageSize: query.limit,
      );
      return result.products;
    });

/// Fetches up to 8 active products in the same category, excluding the current product.
///
/// Used by the "Customers also bought" row on the product detail screen.
///
/// Parameters:
/// - [excludeProductId]: the ID of the product being viewed.
/// - [categoryId]: the category ID to filter by.
final similarProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String excludeProductId, int categoryId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(productRepositoryProvider);
      final result = await repository.fetchProducts(
        categoryId: params.categoryId,
        pageSize: 12,
      );
      return result.products
          .where((p) => p.productId != params.excludeProductId)
          .take(8)
          .toList();
    });

/// Products from the same seller (excluding current product).
///
/// Used for "More from this seller" section on product detail page.
///
/// Parameters:
/// - [sellerId]: the ID of the seller.
/// - [excludeProductId]: the ID of the product being viewed.
final moreFromSellerProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String sellerId, String excludeProductId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(productRepositoryProvider);
      final result = await repository.fetchProducts(
        sellerId: params.sellerId,
        pageSize: 12,
      );
      return result.products
          .where((p) => p.productId != params.excludeProductId)
          .where(
            (p) => p.lifecycleStatus == ProductLifecycleStatusValues.active,
          )
          .take(8)
          .toList();
    });

/// Streams the count of unanswered product questions for a seller.
///
/// Parameters:
/// - [sellerId]: the ID of the seller.
final sellerUnansweredQaProvider = StreamProvider.autoDispose
    .family<int, String>((ref, sellerId) {
      final repository = ref.watch(productRepositoryProvider);
      return repository.watchUnansweredQuestionsCount(sellerId);
    });

// ============================================================================
// FAVORITES PROVIDER
// ============================================================================

/// State provider for the current search query string.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// State provider for the currently selected category ID (null = all categories).
final selectedCategoryProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Stateless controller for toggling product favorites and checking favorite status.
///
/// Reads from [favoritesProvider] for reactive state — callers watch that provider
/// for UI updates. This controller is for mutations only.
///
/// ## Key Decisions
/// - [toggleFavorite] logs add/remove analytics separately — allows tracking
///   wishlist conversion funnel.
/// - All operations require an authenticated user — return early if no userId.
///
/// See also:
/// - [favoritesProvider] for the reactive favorite IDs set
/// - [ProductRepository.toggleFavorite] for persistence
class FavoritesController {
  final Ref _ref;

  /// Creates a new [FavoritesController].
  FavoritesController(this._ref);

  ProductRepository get _repository => _ref.read(productRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Checks whether a product is currently in the user's favorites list.
  ///
  /// Parameters:
  /// - [productId]: the ID of the product to check.
  bool isFavorite(String productId) {
    final favorites = _ref.read(favoritesProvider).valueOrNull ?? {};
    return favorites.contains(productId);
  }

  /// Toggles the favorite status of a product.
  ///
  /// Parameters:
  /// - [productId]: the ID of the product to toggle.
  /// - [productName]: optional name for analytics.
  /// - [priceCad]: optional price for analytics.
  ///
  /// Logs `add_to_wishlist` or `remove_from_wishlist` analytics events on success.
  Future<void> toggleFavorite(
    String productId, {
    String? productName,
    double? priceCad,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    final wasFavorited = isFavorite(productId);
    await _repository.toggleFavorite(userId, productId);
    if (productName != null && priceCad != null && !wasFavorited) {
      unawaited(
        _ref
            .read(analyticsServiceProvider)
            .logAddToWishlist(
              productId: productId,
              productName: productName,
              priceCad: priceCad,
            ),
      );
    } else if (productName != null && wasFavorited) {
      unawaited(
        _ref
            .read(analyticsServiceProvider)
            .logRemoveFromWishlist(
              productId: productId,
              productName: productName,
            ),
      );
    }
  }
}

/// Query parameters for products
class ProductQuery {
  final int? categoryId;
  final String searchQuery;
  final int limit;

  const ProductQuery({this.categoryId, this.searchQuery = '', this.limit = 20});

  @override
  int get hashCode => Object.hash(categoryId, searchQuery, limit);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductQuery &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery &&
          limit == other.limit;
}

/// Stream provider for product ratings.
final productRatingsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, productId) {
      final ob = ref.watch(orignabaseProvider);
      final ratings = ob.collection(Collections.productRatings);

      Future<List<Map<String, dynamic>>> fetchRatings() async {
        final snapshot = await ratings
            .where(Fields.productId, isEqualTo: productId)
            .orderBy(Fields.createdAt, descending: true)
            .limit(10)
            .get();
        return snapshot.docs
            .map(
              (doc) => <String, dynamic>{...doc.data, Fields.ratingId: doc.id},
            )
            .toList();
      }

      return Stream.multi((controller) async {
        try {
          controller.add(await fetchRatings());
        } catch (error, stackTrace) {
          AppError.log(
            error,
            stackTrace: stackTrace,
            context: 'productRatingsProvider[$productId]',
          );
          controller.add(const []);
        }
        final subscription = ratings
            .snapshots()
            .asyncMap((_) => fetchRatings())
            .listen(
              controller.add,
              onError: (Object e, StackTrace st) {
                AppError.log(
                  e,
                  stackTrace: st,
                  context: 'productRatingsProvider.realtime[$productId]',
                );
              },
            );
        controller.onCancel = () => subscription.cancel();
      });
    });


// === Widget Previews ===
