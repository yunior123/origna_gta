import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Algolia search service for products
/// Uses EnvConfig to select the correct index (products vs products_emulator).
/// Detects empty credentials and exposes [isAvailable] so callers can
/// fall back to Firestore without waiting for a timeout.
class AlgoliaService {
  final HitsSearcher? _hitsSearcher;

  /// Whether Algolia is usable (credentials present & non-empty).
  final bool isAvailable;

  AlgoliaService._({HitsSearcher? hitsSearcher, required this.isAvailable}) : _hitsSearcher = hitsSearcher;

  /// Stream of search responses (empty stream when unavailable)
  Stream<SearchResponse> get responses => _hitsSearcher?.responses ?? const Stream.empty();

  /// Dispose resources
  void dispose() {
    _hitsSearcher?.dispose();
  }

  /// Set search with optional category filter (facet)
  void search(String searchQuery, {int? categoryId, String? subcategory}) {
    if (_hitsSearcher == null) return;
    _hitsSearcher.applyState((state) {
      var newState = state.copyWith(query: searchQuery, page: 0);
      // Apply category and subcategory as facet filters when provided
      final filters = <FilterFacet>{};
      if (categoryId != null) {
        filters.add(Filter.facet(Fields.categoryId, categoryId));
      }
      if (subcategory != null && subcategory.isNotEmpty) {
        filters.add(Filter.facet(Fields.subcategory, subcategory));
      }
      if (filters.isNotEmpty) {
        newState = newState.copyWith(filterGroups: {FilterGroup.facet(filters: filters)});
      } else {
        newState = newState.copyWith(filterGroups: {});
      }
      return newState;
    });
  }

  /// Initialize Algolia service with credentials from env.
  /// Returns a disabled instance (isAvailable=false) when keys are empty.
  static AlgoliaService create({required String appId, required String searchApiKey}) {
    if (appId.isEmpty || searchApiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️  Algolia credentials empty → search disabled, using Firestore only');
      }
      return AlgoliaService._(isAvailable: false);
    }

    final indexName = EnvConfig().algoliaIndexName;
    if (kDebugMode) debugPrint('✅ Algolia initialized: index=$indexName');

    final searcher = HitsSearcher(applicationID: appId, apiKey: searchApiKey, indexName: indexName);
    return AlgoliaService._(hitsSearcher: searcher, isAvailable: true);
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
      Fields.createdAt: hit[Fields.createdAt] ?? DateTime.now().toIso8601String(),
      Fields.stockQuantity: hit[Fields.stockQuantity] ?? 0,
      Fields.rating: hit[Fields.rating] ?? 0.0,
      Fields.ratingCount: hit[Fields.ratingCount] ?? 0,
      Fields.keywords: hit[Fields.keywords] ?? hit['searchKeywords'] ?? [],
      Fields.sellerAddress: hit[Fields.sellerAddress] ?? {},
      Fields.lifecycleStatus: hit[Fields.lifecycleStatus] ?? 'active',
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
      Fields.subcategory: hit[Fields.subcategory] ?? '',
    };
  }
}
