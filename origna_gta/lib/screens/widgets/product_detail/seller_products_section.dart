import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Horizontal scrolling row of products from the same seller.
class SellerProductsSection extends ConsumerWidget {
  final String sellerId;
  final String excludeProductId;

  const SellerProductsSection({
    super.key,
    required this.sellerId,
    required this.excludeProductId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sellerId.isEmpty) return const SizedBox.shrink();

    final productsAsync = ref.watch(
      moreFromSellerProvider((
        sellerId: sellerId,
        excludeProductId: excludeProductId,
      )),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product.more_from_seller'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, i) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final p = products[idx];
                  return SizedBox(
                    width: 170,
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
      error: (err, st) {
        // Silently fail — this is a non-critical "more from seller" section.
        // Logging the error for debugging without showing UI noise.
        AppError.log(err, stackTrace: st, context: 'SellerProductsSection');
        return const SizedBox.shrink();
      },
    );
  }
}
