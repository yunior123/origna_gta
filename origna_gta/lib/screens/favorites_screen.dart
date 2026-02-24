import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritedProductsProvider);
    final userModel = ref.watch(userProfileProvider.select((value) => value.valueOrNull));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'favorites.my_favorites'.tr()),
        backgroundColor: Colors.transparent,
        body: favoritesAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
                    ),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: ModernLoadingIndicator(size: 32, strokeWidth: 3, color: Colors.white, centered: false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('favorites.loading_favorites'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          error: (error, stack) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'favorites.unable_to_load'.tr(),
            subtitle: '$error',
          ),
          data: (products) {
            if (products.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'favorites.empty_favorites'.tr(),
                subtitle: 'favorites.empty_favorites_desc'.tr(),
              );
            }

            final available = products.where((p) => p.lifecycleStatus == ProductLifecycleStatusValues.active).toList();
            final unavailable = products.where((p) => p.lifecycleStatus != ProductLifecycleStatusValues.active).toList();
            final displayList = [...available, ...unavailable];

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: CustomScrollView(
                  slivers: [
                    if (unavailable.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: DesignTokens.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DesignTokens.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: DesignTokens.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'favorites.items_unavailable'.tr(namedArgs: {'count': '${unavailable.length}'}),
                                  style: TextStyle(color: DesignTokens.warning, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.all(DesignTokens.spacing16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getCrossAxisCount(context),
                          crossAxisSpacing: DesignTokens.spacing12,
                          mainAxisSpacing: DesignTokens.spacing12,
                          childAspectRatio: _getCardAspectRatio(context),
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = displayList[index];
                            final isUnavailable = product.lifecycleStatus != ProductLifecycleStatusValues.active;
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 50 * index),
                              child: Opacity(
                                opacity: isUnavailable ? 0.45 : 1.0,
                                child: ProductCard(productId: product.productId, product: product, userModel: userModel),
                              ),
                            );
                          },
                          childCount: displayList.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Higher ratio = shorter cards (more items visible)
    if (width < 360) return 0.8;
    if (width < 600) return 0.85;
    return 0.95;
  }
}
