import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

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

/// Fetches products based on query parameters
final productsProvider = FutureProvider.autoDispose.family<List<ProductModel>, ProductQuery>((ref, query) async {
  final firestore = ref.watch(firestoreProvider);
  
  Query productsQuery = firestore
      .collection('products')
      .where('stockQuantity', isGreaterThan: 0);

  // Apply category filter
  if (query.categoryId != null) {
    productsQuery = productsQuery.where('categoryId', isEqualTo: query.categoryId);
  }

  // Apply search filter
  if (query.searchQuery.isNotEmpty) {
    final searchLower = query.searchQuery.toLowerCase();
    productsQuery = productsQuery.where('searchKeywords', arrayContains: searchLower);
  }

  // Apply limit
  productsQuery = productsQuery.limit(query.limit);

  final snapshot = await productsQuery.get();
  
  return snapshot.docs
      .map((doc) => ProductModel.fromDocument(doc))
      .toList();
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

// ============================================================================
// SINGLE PRODUCT PROVIDER
// ============================================================================

/// Fetches a single product by ID
final productByIdProvider = FutureProvider.autoDispose.family<ProductModel?, String>((ref, productId) async {
  final firestore = ref.watch(firestoreProvider);
  
  final doc = await firestore.collection('products').doc(productId).get();
  
  if (!doc.exists) return null;
  
  return ProductModel.fromDocument(doc);
});

// ============================================================================
// FAVORITES PROVIDER
// ============================================================================

/// Stream of favorite product IDs for current user
final favoritesProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value({});

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

/// Favorites controller
final favoritesControllerProvider = Provider<FavoritesController>((ref) {
  return FavoritesController(ref);
});

class FavoritesController {
  final Ref _ref;
  
  FavoritesController(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    final userId = _userId;
    if (userId == null) return;

    final favRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId);

    final doc = await favRef.get();
    
    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'productId': productId,
        'dateFavorited': Timestamp.now(),
      });
    }
  }

  /// Check if product is favorited
  bool isFavorite(String productId) {
    final favorites = _ref.read(favoritesProvider).valueOrNull ?? {};
    return favorites.contains(productId);
  }
}
