part of '../product_card_screen.dart';

/// Image carousel section of the product card with favorite button,
/// trending/rank badges, and out-of-stock overlay.
class _ProductCardImageSection extends ConsumerWidget {
  final String productId;
  final Product product;
  final bool isCompact;
  final bool isOutOfStock;
  final bool isFavorite;
  final int? trendingRank;
  final String heroTagPrefix;
  final AnimationController favoriteController;
  final VoidCallback onToggleFavorite;

  const _ProductCardImageSection({
    required this.productId,
    required this.product,
    required this.isCompact,
    required this.isOutOfStock,
    required this.isFavorite,
    required this.trendingRank,
    required this.heroTagPrefix,
    required this.favoriteController,
    required this.onToggleFavorite,
  });

  bool _isValidImageUrl(String url) {
    final resolved = resolveMediaUrl(url);
    final uri = Uri.tryParse(resolved);
    return resolved.isNotEmpty &&
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrls = product.imageUrls
        .map((url) => url.trim())
        .where(_isValidImageUrl)
        .map(resolveMediaUrl)
        .toList(growable: false);
    final currentImageIndex = imageUrls.length > 1
        ? ref.watch(_productCardImageIndexProvider(productId))
        : 0;
    final favIconSize = isCompact ? 18.0 : 20.0;

    return Expanded(
      flex: 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: '${heroTagPrefix}_$productId',
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isCompact ? 12 : 16),
              ),
              child: SizedBox.expand(
                child: switch (imageUrls.length) {
                  0 => Stack(
                    children: [
                      _placeholderImage(),
                      if (isOutOfStock) _outOfStockOverlay(),
                    ],
                  ),
                  1 => Stack(
                    children: [
                      Semantics(
                        image: true,
                        excludeSemantics: true,
                        label: '${product.name} image',
                        child: ColorFiltered(
                          colorFilter: isOutOfStock
                              ? const ColorFilter.mode(
                                  DesignTokens.textSecondary,
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.mode(
                                  DesignTokens.transparent,
                                  BlendMode.multiply,
                                ),
                          child: _networkImage(imageUrls.single),
                        ),
                      ),
                      if (isOutOfStock) _outOfStockOverlay(),
                    ],
                  ),
                  _ => Stack(
                    children: [
                      PageView.builder(
                        itemCount: imageUrls.length,
                        onPageChanged: (index) =>
                            ref
                                    .read(
                                      _productCardImageIndexProvider(
                                        productId,
                                      ).notifier,
                                    )
                                    .state =
                                index,
                        itemBuilder: (context, index) {
                          return Semantics(
                            image: true,
                            excludeSemantics: true,
                            label:
                                '${product.name} image ${index + 1} of ${imageUrls.length}',
                            child: ColorFiltered(
                              colorFilter: isOutOfStock
                                  ? const ColorFilter.mode(
                                      DesignTokens.textSecondary,
                                      BlendMode.saturation,
                                    )
                                  : const ColorFilter.mode(
                                      DesignTokens.transparent,
                                      BlendMode.multiply,
                                    ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrls[index],
                                imageRenderMethodForWeb:
                                    _productCardWebRenderMethod,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    ModernSkeletonLoader.imagePlaceholder(),
                                errorWidget: (context, url, error) =>
                                    _placeholderImage(),
                              ),
                            ),
                          );
                        },
                      ),
                      if (isOutOfStock) _outOfStockOverlay(),
                      if (imageUrls.length > 1)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 5 : 8,
                              vertical: isCompact ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                isCompact ? 8 : 12,
                              ),
                            ),
                            child: Text(
                              '${currentImageIndex + 1}/${imageUrls.length}',
                              style: TextStyle(
                                color: DesignTokens.white,
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                },
              ),
            ),
          ),
          // Trending / rank badge
          if (trendingRank != null && trendingRank! <= 3)
            Positioned(
              top: isCompact ? 4 : 8,
              left: isCompact ? 4 : 8,
              child: _RankBadge(rank: trendingRank!, isCompact: isCompact),
            )
          else if (product.isTrending)
            Positioned(
              top: isCompact ? 4 : 8,
              left: isCompact ? 4 : 8,
              child: TrendingBadge(
                score: product.trendingScore,
                isCompact: isCompact,
                hotColors: const [DesignTokens.tertiary, DesignTokens.hotEnd],
                risingColors: const [
                  DesignTokens.statusInTransit,
                  DesignTokens.accent,
                ],
              ),
            ),
          // Favorite button
          Positioned(
            top: isCompact ? 4 : 8,
            right: isCompact ? 4 : 8,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.0,
                end: 1.3,
              ).animate(favoriteController),
              child: Material(
                color: DesignTokens.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: Semantics(
                  button: true,
                  label: 'btn-favorite-$productId',
                  child: InkWell(
                    onTap: onToggleFavorite,
                    customBorder: const CircleBorder(),
                    child: Semantics(
                      container: true,
                      child: Padding(
                        padding: EdgeInsets.all(isCompact ? 6 : 8),
                        child: Icon(
                          isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFavorite
                              ? DesignTokens.primary
                              : DesignTokens.textSecondary,
                          size: favIconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageRenderMethodForWeb: _productCardWebRenderMethod,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => ModernSkeletonLoader.imagePlaceholder(),
      errorWidget: (context, url, error) => _placeholderImage(),
    );
  }

  Widget _outOfStockOverlay() {
    return Positioned.fill(
      child: Container(
        color: DesignTokens.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'product.out_of_stock_label'.tr(),
              style: const TextStyle(
                color: DesignTokens.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.gradientStart, DesignTokens.gradientMiddle],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: isCompact ? 24 : 36,
          color: DesignTokens.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
