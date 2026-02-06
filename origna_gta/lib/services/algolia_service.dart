import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Algolia search service for products
/// Simple wrapper that delegates to Firestore fallback immediately
/// Algolia implementation reserved for future optimization
class AlgoliaService {
  static const String _indexName = 'products';

  final HitsSearcher _hitsSearcher;

  AlgoliaService._({required HitsSearcher hitsSearcher}) : _hitsSearcher = hitsSearcher;

  /// Stream of search responses
  Stream<SearchResponse> get responses => _hitsSearcher.responses;

  /// Dispose resources
  void dispose() {
    _hitsSearcher.dispose();
  }

  /// Set search with optional category filter
  void search(String searchQuery, {int? categoryId}) {
    _hitsSearcher.applyState((state) => state.copyWith(query: searchQuery, page: 0));
  }

  /// Initialize Algolia service with credentials from env
  static AlgoliaService create({required String appId, required String searchApiKey}) {
    final searcher = HitsSearcher(applicationID: appId, apiKey: searchApiKey, indexName: _indexName);

    return AlgoliaService._(hitsSearcher: searcher);
  }

  /// Parse Algolia hit to product map
  static Map<String, dynamic> hitToProductMap(Map<String, dynamic> hit) {
    return {
      Fields.productId: hit['objectID'],
      Fields.name: hit[Fields.name],
      Fields.price: hit[Fields.price],
      Fields.imageUrls: hit[Fields.imageUrls] ?? [],
      Fields.description: hit[Fields.description] ?? '',
      Fields.categoryId: hit[Fields.categoryId],
      Fields.sellerId: hit[Fields.sellerId] ?? '',
      Fields.dateCreated: hit[Fields.dateCreated] ?? DateTime.now().toIso8601String(),
      Fields.stockQuantity: hit[Fields.stockQuantity] ?? 0,
      Fields.rating: hit[Fields.rating] ?? 0.0,
      Fields.ratingCount: hit[Fields.ratingCount] ?? 0,
      Fields.keywords: hit[Fields.keywords] ?? hit['searchKeywords'] ?? [],
      Fields.sellerAddress: hit[Fields.sellerAddress] ?? {},
      Fields.isActive: hit[Fields.isActive] ?? true,
      Fields.weightKg: hit[Fields.weightKg],
      Fields.lengthCm: hit[Fields.lengthCm],
      Fields.widthCm: hit[Fields.widthCm],
      Fields.heightCm: hit[Fields.heightCm],
      Fields.isLocalDeliveryOnly: hit[Fields.isLocalDeliveryOnly] ?? false,
      Fields.estimatedShipDays: hit[Fields.estimatedShipDays] ?? 3,
      Fields.taxCode: hit[Fields.taxCode],
      Fields.deliveryOptions: hit[Fields.deliveryOptions] ?? [],
      Fields.isPerishable: hit[Fields.isPerishable] ?? false,
      Fields.minimumOrderQuantity: hit[Fields.minimumOrderQuantity] ?? 1,
      Fields.freeShipping: hit[Fields.freeShipping] ?? false,
    };
  }
}
