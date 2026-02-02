import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';

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
      'productId': hit['objectID'],
      'name': hit['name'],
      'price': hit['price'],
      'imageUrls': hit['imageUrls'] ?? [],
      'description': hit['description'] ?? '',
      'categoryId': hit['categoryId'],
      'sellerId': hit['sellerId'] ?? '',
      'dateCreated': hit['dateCreated'] ?? DateTime.now().toIso8601String(),
      'stockQuantity': hit['stockQuantity'] ?? 0,
      'rating': hit['rating'] ?? 0.0,
      'ratingCount': hit['ratingCount'] ?? 0,
      'keywords': hit['keywords'] ?? hit['searchKeywords'] ?? [],
      'sellerAddress': hit['sellerAddress'] ?? {},
      'isActive': hit['isActive'] ?? true,
      'weightKg': hit['weightKg'],
      'lengthCm': hit['lengthCm'],
      'widthCm': hit['widthCm'],
      'heightCm': hit['heightCm'],
      'isLocalDeliveryOnly': hit['isLocalDeliveryOnly'] ?? false,
      'estimatedShipDays': hit['estimatedShipDays'] ?? 3,
      'taxCode': hit['taxCode'],
      'deliveryOptions': hit['deliveryOptions'] ?? [],
      'isPerishable': hit['isPerishable'] ?? false,
      'minimumOrderQuantity': hit['minimumOrderQuantity'] ?? 1,
      'freeShipping': hit['freeShipping'] ?? false,
    };
  }
}
