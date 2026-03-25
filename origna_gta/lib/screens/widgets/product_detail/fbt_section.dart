import 'package:origna_gta/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/recommendations_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_card.dart';

/// Riverpod state for FBT checkbox selections.
/// Key: product index, Value: checked state. All default to true.
final _fbtCheckedProvider = StateProvider.autoDispose.family<List<bool>, int>((
  ref,
  count,
) {
  return List.filled(count, true);
});

/// Amazon-style "Frequently Bought Together" section.
///
/// Shows the current product plus up to 5 bundled products with checkboxes,
/// a combined total, and an "Add all to Cart" button.
/// Cold start: uses seller-curated [Product.bundledProductIds].
class FBTSection extends ConsumerWidget {
  final Product product;
  const FBTSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundledIds = product.bundledProductIds;
    if (bundledIds.isEmpty) return const SizedBox.shrink();

    final bundledAsync = ref.watch(bundledProductsProvider(bundledIds));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return bundledAsync.when(
      data: (bundledProducts) {
        if (bundledProducts.isEmpty) return const SizedBox.shrink();

        final allProducts = [product, ...bundledProducts];
        final checked = ref.watch(_fbtCheckedProvider(allProducts.length));

        // Calculate total of checked items in cents
        final totalCents = allProducts.asMap().entries.fold<int>(0, (sum, e) {
          return checked[e.key] ? sum + e.value.priceCents : sum;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product.frequently_bought_together'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Product row with "+" separators
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildProductRow(
                          allProducts,
                          checked,
                          isDark,
                          ref,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Total price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'product.fbt_total'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DesignTokens.white
                                : DesignTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${(totalCents / 100).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: DesignTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add all to Cart button
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        button: true,
                        label: 'btn-add-all-to-cart',
                        child: ModernButton(
                          label: 'product.add_all_to_cart'.tr(),
                          icon: Icons.shopping_cart_outlined,
                          onPressed: () =>
                              _addCheckedToCart(allProducts, checked, ref),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<Widget> _buildProductRow(
    List<Product> products,
    List<bool> checked,
    bool isDark,
    WidgetRef ref,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < products.length; i++) {
      if (i > 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.add_rounded,
              size: 24,
              color: isDark
                  ? DesignTokens.textSecondary
                  : DesignTokens.textTertiary,
            ),
          ),
        );
      }
      final index = i;
      widgets.add(
        _FBTProductItem(
          product: products[i],
          isChecked: checked[i],
          isDark: isDark,
          onCheckedChanged: (isChecked) {
            final current = List<bool>.from(checked);
            current[index] = isChecked;
            ref.read(_fbtCheckedProvider(products.length).notifier).state =
                current;
          },
        ),
      );
    }
    return widgets;
  }

  Future<void> _addCheckedToCart(
    List<Product> allProducts,
    List<bool> checked,
    WidgetRef ref,
  ) async {
    final cart = ref.read(cartControllerProvider);
    for (var i = 0; i < allProducts.length; i++) {
      if (checked[i]) {
        final p = allProducts[i];
        await cart.addToCart(
          p.productId,
          1,
          productName: p.name,
          priceCad: p.priceCents / 100.0,
        );
      }
    }
  }
}

/// Individual product item in the FBT row.
class _FBTProductItem extends StatelessWidget {
  final Product product;
  final bool isChecked;
  final bool isDark;
  final ValueChanged<bool> onCheckedChanged;

  const _FBTProductItem({
    required this.product,
    required this.isChecked,
    required this.isDark,
    required this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : null;

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, e) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 6),
          // Product name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Price
          Text(
            '\$${(product.priceCents / 100).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primary,
            ),
          ),
          // Checkbox
          SizedBox(
            height: 32,
            child: Checkbox(
              value: isChecked,
              onChanged: (v) => onCheckedChanged(v ?? false),
              activeColor: DesignTokens.primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: DesignTokens.textTertiary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.image_outlined,
      size: 32,
      color: DesignTokens.textTertiary,
    ),
  );
}
