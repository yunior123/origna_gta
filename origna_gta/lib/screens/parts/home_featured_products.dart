part of '../home_screen.dart';
class _PaginationLoader extends ConsumerWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(
      homeViewModelProvider.select((state) => state.isLoadingMore),
    );

    if (!isLoadingMore) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Semantics(
            label: 'common.loading_more'.tr(),
            liveRegion: true,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [DesignTokens.primary, DesignTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const ModernLoadingIndicator(
                strokeWidth: 3,
                color: DesignTokens.white,
                centered: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  final double cardAspectRatio;
  final UserModel? fallbackUserModel;

  const _ProductGrid({
    required this.cardAspectRatio,
    required this.fallbackUserModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      homeViewModelProvider.select((state) => state.isLoading),
    );
    final products = ref.watch(
      homeViewModelProvider.select((state) => state.displayedProducts),
    );
    final errorMessage = ref.watch(
      homeViewModelProvider.select((state) => state.errorMessage),
    );
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Error state with retry
    if (errorMessage != null && products.isEmpty && !isLoading) {
      return SliverToBoxAdapter(
        child: AnimatedEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'home.error_loading_products'.tr(),
          subtitle: errorMessage,
          action: ModernButton(
            label: 'common.retry'.tr(),
            icon: Icons.refresh,
            fullWidth: false,
            height: 44,
            onPressed: () =>
                ref.read(homeViewModelProvider.notifier).loadProducts(),
          ),
        ),
      );
    }

    if (products.isEmpty && !isLoading) {
      return SliverToBoxAdapter(
        child: AnimatedEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'home.no_products_found'.tr(),
          subtitle: 'home.try_adjusting'.tr(),
          showMascot: true,
        ),
      );
    }

    if (isLoading) {
      final spacing = ResponsiveBreakpoints.getSpacing(context, SpacingSize.sm);
      final columns = ResponsiveBreakpoints.getGridColumns(context);
      return SliverPadding(
        padding: EdgeInsets.all(spacing),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: cardAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ShimmerCard(isDark: isDark),
            childCount: columns * 2,
          ),
        ),
      );
    }

    final spacing = ResponsiveBreakpoints.getSpacing(context, SpacingSize.sm);

    // Build rank map: sort trending products by score desc, assign rank 1–3
    final rankMap = <String, int>{};
    final trendingProducts = products.where((p) => p.isTrending).toList()
      ..sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
    for (var i = 0; i < trendingProducts.length && i < 3; i++) {
      rankMap[trendingProducts[i].productId] = i + 1;
    }

    return SliverPadding(
      padding: EdgeInsets.all(spacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveBreakpoints.getGridColumns(context),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: cardAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return ProductCard(
              key: Key('product_card_${product.name}'),
              productId: product.productId,
              product: product,
              userModel: userProfile ?? fallbackUserModel,
              trendingRank: rankMap[product.productId],
            );
          },
          childCount: products.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.darkOutline : DesignTokens.outline,
      highlightColor: isDark
          ? DesignTokens.darkSurfaceVariant
          : DesignTokens.outlineVariant,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: DesignTokens.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radius16),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: DesignTokens.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: DesignTokens.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: 60,
                      decoration: BoxDecoration(
                        color: DesignTokens.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
