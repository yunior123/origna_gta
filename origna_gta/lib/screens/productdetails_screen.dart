import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  final Map<String, dynamic>? product; // Optional initial data

  const ProductDetailScreen({super.key, required this.productId, this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final viewModel = ref.read(productDetailViewModelProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: DesignTokens.textDisabled),
                  const SizedBox(height: 16),
                  Text('Product not found', style: TextStyle(fontSize: 18, color: DesignTokens.textSecondary)),
                ],
              ),
            );
          }
          final imageUrls = product.imageUrls;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: 340,
                backgroundColor: isDark ? DesignTokens.textPrimary : Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [DesignTokens.primary.withValues(alpha: 0.1), DesignTokens.secondary.withValues(alpha: 0.1)],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrls.isNotEmpty
                            ? PageView.builder(
                                itemCount: imageUrls.length,
                                onPageChanged: viewModel.setImageIndex,
                                itemBuilder: (context, index) {
                                  return Semantics(
                                    label: 'Product image ${index + 1} of ${imageUrls.length}. Tap to view fullscreen',
                                    button: true,
                                    image: true,
                                    child: GestureDetector(
                                      onTap: () => _showImageDialog(context, imageUrls, index),
                                      child: SizedBox.expand(
                                        child: CachedNetworkImage(
                                        imageUrl: imageUrls[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: DesignTokens.outlineVariant,
                                          highlightColor: DesignTokens.surface,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(color: DesignTokens.outlineVariant, child: const Icon(Icons.image_not_supported, size: 100)),
                                      ),
                                    ),
                                  ),
                                  );
                                },
                              )
                            : Container(color: DesignTokens.outlineVariant, child: const Icon(Icons.image_not_supported, size: 100)),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                            ),
                            child: IconButton(
                              tooltip: 'Go back',
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Positioned(bottom: 16, left: 0, right: 0, child: _ImageDots(imageCount: imageUrls.length)),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.textPrimary : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [DesignTokens.primary, DesignTokens.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(Icons.star, size: 18, color: DesignTokens.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.rating.toStringAsFixed(1),
                                      style: TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [DesignTokens.primary.withValues(alpha: 0.95), DesignTokens.secondary.withValues(alpha: 0.95)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(DesignTokens.radius16),
                              boxShadow: [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Price:',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Delivery Information Card
                          _DeliveryInfoCard(product: product),
                          const SizedBox(height: 28),
                          Text(
                            'Description',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : DesignTokens.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          GlassContainer(
                            child: Text(
                              product.description,
                              style: TextStyle(fontSize: 15, color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary, height: 1.6, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _QuantitySelector(viewModel: viewModel),
                          const SizedBox(height: 24),
                          _AddToCartButton(productId: productId, sellerId: product.sellerId),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [DesignTokens.primary, DesignTokens.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const ModernLoadingIndicator(color: Colors.white, strokeWidth: 3, centered: false),
          ),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: DesignTokens.error.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(fontSize: 16, color: DesignTokens.textSecondary)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.invalidate(productByIdProvider(productId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: DesignTokens.textPrimary,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: DesignTokens.outlineVariant,
                          highlightColor: DesignTokens.surface,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddToCartButton extends ConsumerWidget {
  final String productId;
  final String sellerId;

  const _AddToCartButton({required this.productId, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProduct = currentUser != null && currentUser.uid == sellerId;

    // If user is the seller, show disabled button with message
    if (isOwnProduct) {
      return Column(
        children: [
          ModernButton(
            label: 'This is your product',
            onPressed: null,
            fullWidth: true,
            icon: Icons.storefront,
          ),
          const SizedBox(height: 8),
          Text(
            'You cannot purchase your own products',
            style: TextStyle(
              fontSize: 13,
              color: DesignTokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return ModernButton(
      label: 'Add to Cart',
      onPressed: () async {
        final user = ref.read(currentUserProvider);
        if (user == null) {
          if (context.mounted) showLoginPrompt(context);
          return;
        }
        if (context.mounted) {
          final verified = await checkEmailVerifiedOrPrompt(context);
          if (!verified) return;
        }
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final success = await ref.read(cartControllerProvider).addToCart(productId, quantity);
        
        if (success) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.vibrate();
        }

        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(success ? 'Added to cart successfully! 🎉' : 'Failed to add to cart'),
              backgroundColor: success ? DesignTokens.success : DesignTokens.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      fullWidth: true,
      icon: Icons.shopping_cart_checkout,
    );
  }
}

// ============================================================================
// DELIVERY INFO CARD - Shows estimated delivery time to buyers
// ============================================================================

class _DeliveryInfoCard extends StatelessWidget {
  final Product product;

  const _DeliveryInfoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deliveryInfo = product.deliveryInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(product.isDigital ? Icons.download_rounded : Icons.local_shipping_outlined, color: DesignTokens.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Delivery Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : DesignTokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Estimated delivery time
          _DeliveryInfoRow(icon: Icons.access_time_rounded, label: 'Estimated Delivery', value: deliveryInfo.estimateText, isDark: isDark),
          if (deliveryInfo.isInternational) ...[
            const SizedBox(height: 10),
            _DeliveryInfoRow(
              icon: Icons.public_rounded,
              label: 'Ships From',
              value: deliveryInfo.supplierRegion ?? 'International',
              isDark: isDark,
              isWarning: true,
            ),
          ],
          const SizedBox(height: 10),
          _DeliveryInfoRow(
            icon: deliveryInfo.hasTracking ? Icons.track_changes_rounded : Icons.info_outline_rounded,
            label: 'Tracking',
            value: deliveryInfo.hasTracking ? 'Available' : 'Limited tracking',
            isDark: isDark,
          ),
          if (product.freeShipping) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_rounded, size: 16, color: DesignTokens.success),
                  const SizedBox(width: 6),
                  Text(
                    'Free Shipping',
                    style: TextStyle(color: DesignTokens.success, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (deliveryInfo.isInternational) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: DesignTokens.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'International shipping times may vary. Customs processing may add delays.',
                      style: TextStyle(fontSize: 12, color: DesignTokens.warning, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isWarning;

  const _DeliveryInfoRow({required this.icon, required this.label, required this.value, required this.isDark, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isWarning ? DesignTokens.warning : (isDark ? DesignTokens.textOnDarkSecondary : DesignTokens.textSecondary)),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 14, color: isDark ? DesignTokens.textOnDarkSecondary : DesignTokens.textSecondary)),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isWarning ? DesignTokens.warning : (isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary)),
        ),
      ],
    );
  }
}

class _ImageDots extends ConsumerWidget {
  final int imageCount;

  const _ImageDots({required this.imageCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageCount <= 1) return const SizedBox.shrink();

    final currentIndex = ref.watch(productDetailViewModelProvider.select((state) => state.currentImageIndex));

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          imageCount,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: currentIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _QuantityButton({required this.icon, required this.onPressed, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: DesignTokens.primary.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: onPressed != null ? DesignTokens.primary : DesignTokens.textDisabled, size: 20),
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends ConsumerWidget {
  final ProductDetailViewModel viewModel;

  const _QuantitySelector({required this.viewModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));

    return Row(
      children: [
        Text(
          'Quantity:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : DesignTokens.textPrimary),
        ),
        const SizedBox(width: 20),
        GlassContainer(
          child: Row(
            children: [
              _QuantityButton(icon: Icons.remove, onPressed: quantity > 1 ? viewModel.decrementQuantity : null, semanticLabel: 'btn-product-qty-minus'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              _QuantityButton(icon: Icons.add, onPressed: viewModel.incrementQuantity, semanticLabel: 'btn-product-qty-plus'),
            ],
          ),
        ),
      ],
    );
  }
}
