import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritedProductsProvider);
    final userModel = ref.watch(userProfileProvider.select((value) => value.valueOrNull));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
              : [const Color(0xFFF0F2FF), Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'Favorites'),
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
                        child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Loading favorites...', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          error: (error, stack) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load favorites',
            subtitle: '$error',
          ),
          data: (products) {
            if (products.isEmpty) {
              return const AnimatedEmptyState(
                icon: Icons.favorite_outline_rounded,
                title: 'No favorites yet',
                subtitle: 'Tap the heart icon on products\nto save them here.',
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: GridView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacing16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(context),
                    crossAxisSpacing: DesignTokens.spacing12,
                    mainAxisSpacing: DesignTokens.spacing12,
                    childAspectRatio: _getCardAspectRatio(context),
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: ProductCard(productId: product.productId, product: product, userModel: userModel),
                    );
                  },
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
    if (width < 360) return 0.6;
    if (width < 600) return 0.65;
    return 0.75;
  }
}
