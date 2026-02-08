import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/algolia_service.dart';
import 'package:origna_gta/utils/constants.dart';

import 'product_repository.dart';

/// Algolia-based product repository with Firestore fallback
/// Provides fast search with automatic fallback to reliable Firestore queries
class AlgoliaProductRepository implements ProductRepository {
  final AlgoliaService _algoliaService;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AlgoliaProductRepository(
    this._algoliaService,
    this._firestore,
    this._functions,
  );

  @override
  Future<String> addProduct(Product product) async {
    if (kDebugMode) {
      debugPrint(
        'REPO: [AlgoliaProductRepository] Attempting to add product...',
      );
    }
    try {
      final docRef = await _firestore
          .collection(Collections.products)
          .add(product.toJson());
      if (kDebugMode) debugPrint('REPO: Local write returned ID: ${docRef.id}');

      // Force server synchronization verification
      if (kDebugMode) debugPrint('REPO: Verifying server persistence...');
      final serverDoc = await docRef.get(
        const GetOptions(source: Source.server),
      );

      if (!serverDoc.exists) {
        if (kDebugMode) {
          debugPrint(
            'REPO: CRITICAL ERROR - Document not found on server immediately after write!',
          );
        }
        // Throwing ensures the UI/Test treats this as a failure
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'sync-failed',
          message: 'Write succeeded locally but failed to persist to server.',
        );
      }

      if (kDebugMode) debugPrint('REPO: Server verification SUCCESS.');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint('REPO: addProduct FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(Collections.products).doc(productId).delete();
  }

  @override
  Future<Product?> fetchProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection(Collections.products)
          .doc(productId)
          .get();
      if (!doc.exists) return null;
      return Product.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching product: $e');
      return null;
    }
  }

  @override
  Future<ProductQueryResult> fetchProducts({
    String? searchQuery,
    int? categoryId,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  }) async {
    final hasTextSearch = searchQuery != null && searchQuery.isNotEmpty;

    // Route: text search + Algolia available → Algolia (with Firestore fallback)
    if (hasTextSearch && _algoliaService.isAvailable) {
      try {
        return await _searchWithAlgolia(searchQuery, categoryId, pageSize);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️  Algolia error, falling back to Firestore: $e');
        }
        // Fall through to Firestore
      }
    }

    // Route: everything else → Firestore (categories, browse, text when Algolia down)
    return await _fetchFromFirestore(
      searchQuery: searchQuery,
      categoryId: categoryId,
      lastDocument: lastDocument,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final snapshot = await _firestore
          .collection(Collections.products)
          .where(FieldPath.documentId, whereIn: chunk)
          .where(Fields.isActive, isEqualTo: true)
          .get();
      results.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
    }
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async {
    // Could be enhanced with Algolia autocomplete in the future
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection(Collections.products)
        .where(Fields.keywords, arrayContains: query.toLowerCase())
        .where(Fields.isActive, isEqualTo: true)
        .limit(5)
        .get();

    return snapshot.docs
        .map(
          (doc) => {
            Fields.name: doc.data()[Fields.name],
            Fields.productId: doc.id,
          },
        )
        .toList();
  }

  @override
  Future<String?> getUploadUrl(String fileName) async {
    throw UnimplementedError(
      'Image upload URLs should be handled by FirebaseProductRepository',
    );
  }

  @override
  Future<void> submitRating(
    String orderId,
    String productId,
    int rating,
  ) async {
    // Call backend Cloud Function for secure rating submission
    // Backend validates: auth, ownership, delivery status, duplicate check
    await _functions.httpsCallable('submit_product_rating').call({
      Fields.orderId: orderId,
      Fields.productId: productId,
      Fields.rating: rating,
    });
  }

  @override
  Future<void> toggleFavorite(String userId, String productId) async {
    final favRef = _firestore
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.favorites)
        .doc(productId);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        Fields.productId: productId,
        Fields.dateFavorited: FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection(Collections.products)
        .doc(productId)
        .update(updates);
  }

  @override
  Future<List<String>> uploadImages(
    List<Uint8List> images,
    String productId,
  ) async {
    throw UnimplementedError(
      'Image upload should be handled by FirebaseProductRepository',
    );
  }

  @override
  Stream<Set<String>> watchFavorites(String userId) {
    return _firestore
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.favorites)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<ProductQueryResult> _fetchFromFirestore({
    String? searchQuery,
    int? categoryId,
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  }) async {
    if (kDebugMode) print('📍 Using Firestore fallback');

    Query<Map<String, dynamic>> query = _firestore.collection(
      Collections.products,
    );

    // Apply filters
    query = query.where(Fields.isActive, isEqualTo: true);

    if (categoryId != null) {
      query = query.where(Fields.categoryId, isEqualTo: categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Firestore array-contains search on keywords
      final keywords = searchQuery.toLowerCase().split(' ');
      if (keywords.isNotEmpty) {
        query = query.where(Fields.keywords, arrayContains: keywords.first);
      }
    }

    query = query.orderBy(Fields.dateCreated, descending: true);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(pageSize);

    final snapshot = await query.get();
    final products = snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .toList();

    return ProductQueryResult(
      products: products,
      hasMore: snapshot.docs.length >= pageSize,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<ProductQueryResult> _searchWithAlgolia(
    String query,
    int? categoryId,
    int pageSize,
  ) async {
    try {
      // Trigger search
      _algoliaService.search(query, categoryId: categoryId);

      // Wait for response with timeout to prevent infinite hang
      // when Algolia is unreachable (e.g. emulator environment)
      final response = await _algoliaService.responses.first.timeout(
        const Duration(seconds: 5),
      );

      // Convert Algolia hits to Product
      final products = response.hits.map((hit) {
        final data = AlgoliaService.hitToProductMap(hit);
        return Product.fromJson({
          ...data,
          Fields.productId: data[Fields.productId] ?? '',
        });
      }).toList();

      if (kDebugMode) {
        print('✅ Algolia search returned ${products.length} products');
      }

      return ProductQueryResult(
        products: products,
        // Algolia doesn't support cursor-based pagination with Firestore
        // DocumentSnapshots, so signal no more pages to prevent infinite loops.
        hasMore: false,
        lastDocument: null,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Algolia search failed: $e');
      rethrow;
    }
  }
}
