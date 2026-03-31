import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/app_logger.dart';

import 'product_repository.dart';

/// Extracted search/query helpers for [OrignaBaseProductRepository].
///
/// These are pure functions (+ OrignaBase collection refs) so they can be
/// unit-tested in isolation without instantiating the full repository.
/// Mixed into [OrignaBaseProductRepository] to keep the main file focused
/// on the public API surface.
mixin ProductSearchHelpers {
  /// The OrignaBase client instance (provided by the mixing class).
  OrignaBase get ob;

  /// Converts an OrignaBase [Document] to a [Product] model.
  Product docToProduct(Document doc);

  /// Fetches products matching optional filters with cursor-based pagination.
  ///
  /// Parameters:
  /// - [searchQuery]: full-text search query (split into words, matched against keywords).
  /// - [categoryId]: filter by category ID.
  /// - [subcategory]: filter by subcategory name.
  /// - [sellerId]: filter by seller ID.
  /// - [lastDocumentId]: cursor for pagination (ID of the last document from the previous page).
  /// - [pageSize]: number of products per page (default 20). Internally fetches N+1 for hasMore detection.
  /// - [sortOption]: sorting strategy (relevance, priceLowToHigh, priceHighToLow, newest).
  /// - [minPriceCents]/[maxPriceCents]: price range filter in cents.
  ///
  /// Returns a [ProductQueryResult] with products, cursor, and hasMore flag.
  ///
  /// Error handling:
  /// - Malformed documents are skipped and logged (does not abort the query).
  /// - Only active products (lifecycleStatus == 'active') are returned.
  Future<ProductQueryResult> fetchProductsImpl({
    String? searchQuery,
    int? categoryId,
    String? subcategory,
    String? sellerId,
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
    if (sellerId != null && sellerId.isNotEmpty) {
      query = query.where(Fields.sellerId, isEqualTo: sellerId);
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
    final docsToMap = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

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
  ///
  /// Parameters:
  /// - [productIds]: list of product document IDs to fetch.
  ///
  /// Returns a list of [Product] models. Missing or malformed documents are
  /// silently skipped. Splits into chunks of 30, fires all chunk queries in
  /// parallel via [Future.wait], then reassembles results in the original
  /// request order.
  Future<List<Product>> fetchProductsByIdsImpl(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    // Split into chunks of 30
    final chunks = <List<String>>[];
    for (int i = 0; i < productIds.length; i += 30) {
      chunks.add(productIds.skip(i).take(30).toList());
    }

    // Fire all chunk queries in parallel
    final chunkResults = await Future.wait(
      chunks.map((chunk) => _fetchChunk(chunk)),
    );

    // Merge all chunk maps into a single lookup, preserving original order
    final allProducts = <String, Product>{};
    for (final chunkMap in chunkResults) {
      allProducts.addAll(chunkMap);
    }

    // Return in original request order
    return [
      for (final id in productIds)
        if (allProducts.containsKey(id)) allProducts[id]!,
    ];
  }

  /// Fetches a single chunk of product IDs and returns a map of productId -> Product.
  Future<Map<String, Product>> _fetchChunk(List<String> chunk) async {
    final snapshot = await ob
        .collection(Collections.products)
        .where(Fields.productId, whereIn: chunk)
        .get();

    final productsById = <String, Product>{};
    final fetchedIds = <String>{};
    for (final doc in snapshot.docs) {
      if (!doc.exists) continue;
      final fetchedId = doc.data[Fields.productId] as String? ?? doc.id;
      fetchedIds.add(fetchedId);
      try {
        final product = docToProduct(doc);
        productsById[product.productId] = product;
      } catch (e) {
        AppLogger.d(
          'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
          tag: 'product',
        );
      }
    }

    final missingIds = chunk
        .where(
          (productId) =>
              !productsById.containsKey(productId) &&
              !fetchedIds.contains(productId),
        )
        .toList();
    if (missingIds.isNotEmpty) {
      final fallbackDocs = await Future.wait(
        missingIds.map(
          (id) => ob.collection(Collections.products).doc(id).get(),
        ),
      );
      for (final doc in fallbackDocs) {
        if (doc == null || !doc.exists) continue;
        try {
          final product = docToProduct(doc);
          productsById[product.productId] = product;
        } catch (e) {
          AppLogger.d(
            'OrignaBaseProductRepo: skipping malformed doc ${doc.id}: $e',
            tag: 'product',
          );
        }
      }
    }

    return productsById;
  }

  /// Looks up a single active product by its URL slug.
  ///
  /// Parameters:
  /// - [slug]: the URL-friendly product identifier.
  ///
  /// Returns the matching [Product], or `null` if no active product with
  /// that slug exists.
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
  ///
  /// Returns `null` when the product does not exist or is not active.
  /// SDK network/auth errors propagate to the caller (the Riverpod provider
  /// enters [AsyncError] so the UI can show retry / login prompts).
  /// Deserialization errors are caught and logged — returning `null` so the
  /// UI shows "product not found" instead of a generic load error.
  Future<Product?> fetchProductByIdImpl(String productId) async {
    final doc = await ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return null;
    if (doc.data[Fields.lifecycleStatus] !=
        ProductLifecycleStatusValues.active) {
      return null;
    }
    try {
      return docToProduct(doc);
    } catch (e, st) {
      AppLogger.d(
        'OrignaBaseProductRepo: failed to deserialize product $productId: $e\n$st',
        tag: 'product',
      );
      return null;
    }
  }
}
