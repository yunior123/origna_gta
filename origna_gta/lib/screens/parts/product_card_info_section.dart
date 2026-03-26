part of '../product_card_screen.dart';

/// Product info section: name, digital badge, trending views, rating,
/// price (with compare-at), delivery estimate, and add-to-cart button.
class _ProductCardInfoSection extends ConsumerWidget {
  final String productId;
  final Product product;
  final bool isCompact;
  final bool isOwner;
  final bool isOutOfStock;

  const _ProductCardInfoSection({
    required this.productId,
    required this.product,
    required this.isCompact,
    required this.isOwner,
    required this.isOutOfStock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = isCompact ? 8.0 : 12.0;
    final titleFontSize = isCompact ? 12.0 : 14.0;
    final priceFontSize = isCompact ? 14.0 : 16.0;
    final iconSize = isCompact ? 16.0 : 18.0;
    final name = product.name;
    final rating = product.rating.toDouble();

    return Expanded(
      flex: 4,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Product name — Flexible prevents overflow when optional rows are present
            Flexible(
              child: SizedBox(
                height: titleFontSize * 1.25 * 2 + 2,
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                    height: 1.25,
                    color: isDark
                        ? DesignTokens.white
                        : DesignTokens.textPrimary,
                  ),
                  strutStyle: StrutStyle(
                    fontSize: titleFontSize,
                    height: 1.25,
                    forceStrutHeight: true,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Digital product badge
            if (product.isDigital) _digitalBadge(),
            // Social proof (view count)
            if (product.isTrending && product.viewCount > 0) _viewCountRow(),
            // Rating row
            _ratingRow(rating),
            // Price + add to cart row
            _priceAndCartRow(context, ref, priceFontSize, iconSize),
          ],
        ),
      ),
    );
  }

  Widget _digitalBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.digital.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.download_outlined,
            size: 10,
            color: DesignTokens.digital,
          ),
          const SizedBox(width: 3),
          Text(
            product.digitalType == DigitalTypeValues.software
                ? 'product.digital_type_software'.tr()
                : 'product.digital_type_book'.tr(),
            style: const TextStyle(
              fontSize: 10,
              color: DesignTokens.digital,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceAndCartRow(
    BuildContext context,
    WidgetRef ref,
    double priceFontSize,
    double iconSize,
  ) {
    final price = product.price;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.compareAtPrice case final compareAt?
                  when compareAt > price)
                Text(
                  '\$${compareAt.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: priceFontSize - 2,
                    color: DesignTokens.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: priceFontSize,
                  color: (product.compareAtPrice ?? 0) > price
                      ? DesignTokens.error
                      : DesignTokens.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!product.isDigital)
                _DeliveryEstimate(product: product, isCompact: isCompact),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (!isOwner && !isOutOfStock)
          _AddToCartButton(
            productId: productId,
            isCompact: isCompact,
            iconSize: iconSize,
          ),
      ],
    );
  }

  Widget _ratingRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: isCompact ? 12 : 14,
          color: DesignTokens.warning,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: DesignTokens.textSecondary,
          ),
        ),
        if (product.ratingCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '(${product.ratingCount})',
            style: TextStyle(
              fontSize: isCompact ? 9 : 11,
              color: DesignTokens.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _viewCountRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: isCompact ? 9 : 11,
            color: DesignTokens.statusInTransit,
          ),
          const SizedBox(width: 3),
          Text(
            'product.social_proof_views'.tr(
              namedArgs: {'count': _formatViewCount(product.viewCount)},
            ),
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              color: DesignTokens.statusInTransit,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small add-to-cart button extracted to keep info section readable.
class _AddToCartButton extends ConsumerWidget {
  final String productId;
  final bool isCompact;
  final double iconSize;

  const _AddToCartButton({
    required this.productId,
    required this.isCompact,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'btn-add-to-cart-$productId',
      child: Material(
        color: DesignTokens.primary,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        child: InkWell(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final user = ref.read(currentUserProvider);
            if (user == null) {
              showLoginPrompt(context);
              return;
            }
            final success = await ref
                .read(cartControllerProvider)
                .addToCart(productId, 1);
            if (context.mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'cart.added_to_cart'.tr()
                        : 'cart.add_to_cart_failed'.tr(),
                  ),
                  backgroundColor: success
                      ? DesignTokens.success
                      : DesignTokens.error,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            child: Icon(
              Icons.add_shopping_cart,
              color: DesignTokens.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
