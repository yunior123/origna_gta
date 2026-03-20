import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Horizontal scrolling row of similar products in the same category.
class SimilarProductsSection extends ConsumerWidget {
  final String productId;
  final int categoryId;

  const SimilarProductsSection({
    super.key,
    required this.productId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == 0) return const SizedBox.shrink();

    final similarAsync = ref.watch(
      similarProductsProvider((
        excludeProductId: productId,
        categoryId: categoryId,
      )),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return similarAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product.customers_also_bought'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, i) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final p = products[idx];
                  return SizedBox(
                    width: 150,
                    child: ProductCard(
                      productId: p.productId,
                      product: p,
                      userModel: null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: ModernLoadingIndicator(size: 20),
        ),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'errors.something_went_wrong'.tr(),
          style: TextStyle(color: DesignTokens.error, fontSize: 13),
        ),
      ),
    );
  }
}
