import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/app_logger.dart';

import 'product_repository.dart';

/// Extracted search/query helpers for [OrignaBaseProductRepository].
///
/// These are pure functions (+ OrignaBase collection refs) so they can be
/// unit-tested in isolation without instantiating the full repository.
mixin ProductSearchHelpers {
  OrignaBase get ob;
  Product docToProduct(Document doc);

  /// Fetches products matching optional filters with cursor pagination.
  Future<ProductQueryResult> fetchProductsImpl({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    String? lastDocumentId,
    int pageSize = 20,
    SortOption sortOption = SortOption.relevance,
    int? minPriceCents,
    int? maxPriceCents,
  }) async {
    Query query = ob
        .collection(Collections.products)
        .where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final words = searchQuery.toLowerCase().trim().split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          query = query.where(Fields.keywords, contains: word);
        }
      }
    }

    if (categoryId != null) {
      query = query.where(Fields.categoryId, isEqualTo: categoryId);
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      query = query.where(Fields.subcategory, isEqualTo: subcategory);
    }
    if (minPriceCents != null) {
      query = query.where(Fields.priceCents, isGreaterThan: minPriceCents - 1);
    }
    if (maxPriceCents != null) {
      query = query.where(Fields.priceCents, isLessThan: maxPriceCents + 1);
    }

    // Sort ordering
    switch (sortOption) {
      case SortOption.priceLowToHigh:
        query = query
            .orderBy(Fields.priceCents)
            .orderBy(Fields.createdAt, descending: true);
      case SortOption.priceHighToLow:
        query = query
            .orderBy(Fields.priceCents, descending: true)
            .orderBy(Fields.createdAt, descending: true);
      case SortOption.newest:
      case SortOption.relevance:
        query = query.orderBy(Fields.createdAt, descending: true);
    }

    // N+1 pattern for hasMore detection
    query = query.limit(pageSize + 1);

    if (lastDocumentId != null) {
      query = query.startAfterId(lastDocumentId);
    }

    final snapshot = await query.get();

    final hasMore = snapshot.docs.length > pageSize;
    final docsToMap =
        hasMore ? snapshot.docs.take(pageSize).toList() : snapshot.docs;

    final products = docsToMap.expand((doc) {
      try {
        return [docToProduct(doc)];
      } catch (e) {
        AppLogger.d(
          'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
          tag: 'product',
        );
        return <Product>[];
      }
    }).toList();

    return ProductQueryResult(
      products: products,
      lastDocumentId: products.isNotEmpty ? products.last.productId : null,
      hasMore: hasMore,
    );
  }

  /// Fetches multiple products by their IDs in parallel chunks of 30.
  Future<List<Product>> fetchProductsByIdsImpl(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final List<Product> results = [];
    for (int i = 0; i < productIds.length; i += 30) {
      final chunk = productIds.skip(i).take(30).toList();
      final futures = chunk.map(
        (id) => ob.collection(Collections.products).doc(id).get(),
      );
      final docs = await Future.wait(futures);
      for (final doc in docs) {
        if (doc != null && doc.exists) {
          try {
            results.add(docToProduct(doc));
          } catch (e) {
            AppLogger.d(
              'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
              tag: 'product',
            );
          }
        }
      }
    }
    return results;
  }

  /// Looks up a single active product by its URL slug.
  Future<Product?> getProductBySlugImpl(String slug) async {
    final snapshot = await ob
        .collection(Collections.products)
        .where(Fields.slug, isEqualTo: slug)
        .where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        )
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return docToProduct(snapshot.docs.first);
  }

  /// Fetches a single active product by ID.
  Future<Product?> fetchProductByIdImpl(String productId) async {
    final doc =
        await ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return null;
    if (doc.data[Fields.lifecycleStatus] !=
        ProductLifecycleStatusValues.active) {
      return null;
    }
    return docToProduct(doc);
  }
}
