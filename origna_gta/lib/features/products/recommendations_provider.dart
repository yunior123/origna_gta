import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/product_models.dart';

/// Fetches bundled/FBT products by their IDs (max 5, matching server validation).
/// Used for the "Frequently Bought Together" section on product detail page.
/// Cold start: uses seller-curated [Product.bundledProductIds].
/// Future: replace with co-purchase recommendations from backend.
final bundledProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, List<String>>((ref, productIds) async {
      if (productIds.isEmpty) return [];
      final repo = ref.watch(productRepositoryProvider);
      final products = <Product>[];
      for (final id in productIds.take(5)) {
        final product = await repo.fetchProductById(id);
        if (product != null) products.add(product);
      }
      return products;
    });
