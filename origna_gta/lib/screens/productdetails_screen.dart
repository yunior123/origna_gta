import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/models/qa_model.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:share_plus/share_plus.dart';
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
                  Text('product.not_found'.tr(), style: TextStyle(fontSize: 18, color: DesignTokens.textSecondary)),
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
                actions: [
                  if (product.slug != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Share',
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: 'Check out ${product.name} on Origna!\n${envConfig.baseUrl}/p/${product.slug}', subject: product.name),
                      ),
                    ),
                ],
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
                              key: const Key('productdetail_back_button'),
                              tooltip: 'product.go_back'.tr(),
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
                                key: const Key('product_detail_name'),
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
                                Text(
                                  '${'product.price'.tr()}:',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  key: const Key('product_detail_price'),
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Delivery Information Card — suppress for digital
                          if (!product.isDigital) _DeliveryInfoCard(product: product),
                          if (!product.isDigital) const SizedBox(height: 28),
                          Text(
                            'product.description'.tr(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : DesignTokens.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          GlassContainer(
                            key: const Key('product_description_section'),
                            child: Text(
                              product.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          if (product.isDigital) ...[const SizedBox(height: 12), _DigitalProductInfo(product: product)],
                          const SizedBox(height: 28),
                          _QuantitySelector(viewModel: viewModel),
                          const SizedBox(height: 24),
                          _AddToCartButton(productId: productId, sellerId: product.sellerId, stockQuantity: product.stockQuantity),
                          const SizedBox(height: 32),
                          _QASection(productId: productId, sellerId: product.sellerId),
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
                label: Text('common.retry'.tr()),
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
                    tooltip: 'common.close'.tr(),
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

class _AddToCartButton extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;
  final int stockQuantity;

  const _AddToCartButton({required this.productId, required this.sellerId, required this.stockQuantity});

  @override
  ConsumerState<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<_AddToCartButton> {
  bool _notifyLoading = false;
  bool? _subscribed; // null = unknown, true = subscribed, false = not subscribed

  @override
  Widget build(BuildContext context) {
    final quantity = ref.watch(productDetailViewModelProvider.select((state) => state.quantity));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProduct = currentUser != null && currentUser.uid == widget.sellerId;

    // If user is the seller, show disabled button with message
    if (isOwnProduct) {
      return Column(
        key: const Key('product_own_product_message'),
        children: [
          ModernButton(label: 'product.own_product_title'.tr(), onPressed: null, fullWidth: true, icon: Icons.storefront),
          const SizedBox(height: 8),
          Text(
            'product.own_product_msg'.tr(),
            style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    // Out of stock: show "Notify me when available" button
    if (widget.stockQuantity <= 0) {
      final isSubscribed = _subscribed ?? false;
      return Column(
        key: const Key('product_notify_section'),
        children: [
          ModernButton(
            key: const Key('product_notify_me_button'),
            label: isSubscribed ? 'product.notify_cancel'.tr() : 'product.notify_me'.tr(),
            onPressed: _notifyLoading ? null : () => _toggleNotification(context, currentUser),
            fullWidth: true,
            icon: isSubscribed ? Icons.notifications_off_outlined : Icons.notifications_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'product.out_of_stock'.tr(),
            style: TextStyle(fontSize: 13, color: DesignTokens.error, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    return ModernButton(
      label: 'product.add_to_cart'.tr(),
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
        final success = await ref.read(cartControllerProvider).addToCart(widget.productId, quantity);

        if (success) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.vibrate();
        }

        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(success ? 'cart.added_success'.tr() : 'cart.added_failure'.tr()),
              backgroundColor: success ? DesignTokens.success : DesignTokens.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      key: const Key('product_add_to_cart_button'),
      fullWidth: true,
      icon: Icons.shopping_cart_checkout,
    );
  }

  Future<void> _toggleNotification(BuildContext context, dynamic currentUser) async {
    if (currentUser == null) {
      showLoginPrompt(context);
      return;
    }
    setState(() => _notifyLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      final isSubscribed = _subscribed ?? false;
      if (isSubscribed) {
        await functions
            .httpsCallable(CloudFunctionEndpoints.unsubscribeStockNotification)
            .call({Fields.productId: widget.productId});
        if (mounted) setState(() => _subscribed = false);
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(content: Text('product.notify_cancelled'.tr()), backgroundColor: DesignTokens.textSecondary));
        }
      } else {
        await functions
            .httpsCallable(CloudFunctionEndpoints.subscribeStockNotification)
            .call({Fields.productId: widget.productId});
        if (mounted) setState(() => _subscribed = true);
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(content: Text('product.notify_subscribed'.tr()), backgroundColor: DesignTokens.success));
        }
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(AppError.getMessage(e, 'product.notify_error'.tr())), backgroundColor: DesignTokens.error));
      }
    } finally {
      if (mounted) setState(() => _notifyLoading = false);
    }
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
                'product.details.delivery_information'.tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : DesignTokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Estimated delivery time
          _DeliveryInfoRow(icon: Icons.access_time_rounded, label: 'checkout.estimated_delivery'.tr(), value: deliveryInfo.estimateText, isDark: isDark),
          const SizedBox(height: 10),
          if (deliveryInfo.supplierRegion != null) ...[
            _DeliveryInfoRow(
              icon: Icons.public_rounded,
              label: 'product.ships_from'.tr(),
              value: deliveryInfo.supplierRegion!,
              isDark: isDark,
              isWarning: deliveryInfo.isInternational,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          _DeliveryInfoRow(
            icon: deliveryInfo.hasTracking ? Icons.track_changes_rounded : Icons.info_outline_rounded,
            label: 'product.tracking'.tr(),
            value: deliveryInfo.hasTracking ? 'product.tracking_available'.tr() : 'product.tracking_limited'.tr(),
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
                    'product.free_shipping'.tr(),
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
                    child: Text('product.details.international_disclaimer'.tr(), style: TextStyle(fontSize: 12, color: DesignTokens.warning, height: 1.3)),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isWarning ? DesignTokens.warning : (isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _DigitalProductInfo extends StatelessWidget {
  final Product product;
  const _DigitalProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    final builds = product.digitalBuilds ?? {};
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_outlined, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(
                product.digitalType == DigitalTypeValues.software ? 'Desktop Software' : 'Digital Book',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ],
          ),
          if (builds.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Available for:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: builds.keys.map((p) {
                final label = const {'macos': 'macOS', 'windows': 'Windows', 'linux': 'Linux'}[p] ?? p;
                return Chip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('License key + download link delivered after purchase.', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
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

class _QACard extends ConsumerWidget {
  final QAModel qa;
  final String productId;
  final String sellerId;
  final String? currentUserId;

  const _QACard({required this.qa, required this.productId, required this.sellerId, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeller = currentUserId == sellerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = DateFormat.yMMMd();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, size: 20, color: DesignTokens.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(qa.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'qa.asked_on'.tr(namedArgs: {'date': formatter.format(qa.createdAt)}),
                      style: const TextStyle(fontSize: 12, color: DesignTokens.textDisabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (qa.answer != null && qa.answer!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20, color: DesignTokens.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'qa.answer_label'.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DesignTokens.success),
                        ),
                        const SizedBox(height: 4),
                        Text(qa.answer!, style: const TextStyle(fontSize: 15)),
                        if (qa.answeredAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${'qa.answered'.tr()} ${formatter.format(qa.answeredAt!)}',
                            style: const TextStyle(fontSize: 11, color: DesignTokens.textDisabled),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSeller) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAnswerDialog(context, ref),
                icon: const Icon(Icons.reply, size: 18),
                label: Text('qa.your_answer'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('qa.your_answer'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'qa.answer_hint'.tr()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(qaControllerProvider.notifier).answerQuestion(productId: productId, qaId: qa.id, answer: controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('qa.answer_submitted'.tr())));
              }
            },
            child: Text('qa.submit_answer'.tr()),
          ),
        ],
      ),
    );
  }
}

class _QASection extends ConsumerStatefulWidget {
  final String productId;
  final String sellerId;

  const _QASection({required this.productId, required this.sellerId});

  @override
  ConsumerState<_QASection> createState() => _QASectionState();
}

class _QASectionState extends ConsumerState<_QASection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final qaAsync = ref.watch(qaListProvider(widget.productId));
    final currentUserId = ref.watch(userIdProvider);
    final isSeller = currentUserId == widget.sellerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'qa.title'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : DesignTokens.textPrimary),
        ),
        const SizedBox(height: 16),
        qaAsync.when(
          data: (qaList) {
            if (qaList.isEmpty) {
              return _emptyState(context, currentUserId, isSeller);
            }

            final displayList = _showAll ? qaList : qaList.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...displayList.map((qa) => _QACard(qa: qa, productId: widget.productId, sellerId: widget.sellerId, currentUserId: currentUserId)),
                if (qaList.length > 3 && !_showAll)
                  TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    child: Text('qa.see_all'.tr(namedArgs: {'count': qaList.length.toString()})),
                  ),
                const SizedBox(height: 16),
                if (!isSeller && currentUserId != null)
                  ElevatedButton.icon(
                    onPressed: () => _showAskDialog(context),
                    icon: const Icon(Icons.help_outline),
                    label: Text('qa.ask_question'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
                      foregroundColor: DesignTokens.primary,
                      elevation: 0,
                      side: const BorderSide(color: DesignTokens.primary),
                    ),
                  )
                else if (currentUserId == null)
                  Center(
                    child: Text('qa.sign_in_to_ask'.tr(), style: const TextStyle(color: DesignTokens.textSecondary)),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading Q&A: $e', style: const TextStyle(color: DesignTokens.error)),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String? currentUserId, bool isSeller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 48, color: DesignTokens.textDisabled),
          const SizedBox(height: 16),
          Text(
            'qa.no_questions'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignTokens.textSecondary),
          ),
          if (!isSeller && currentUserId != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _showAskDialog(context), child: Text('qa.ask_question'.tr())),
          ] else if (currentUserId == null) ...[
            const SizedBox(height: 16),
            Text(
              'qa.sign_in_to_ask'.tr(),
              style: const TextStyle(color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void _showAskDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('qa.ask_question'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'qa.question_hint'.tr()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(qaControllerProvider.notifier).askQuestion(widget.productId, controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('qa.question_submitted'.tr())));
              }
            },
            child: Text('qa.submit_question'.tr()),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _QuantityButton({super.key, required this.icon, required this.onPressed, required this.semanticLabel});

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
          '${'product.quantity'.tr()}:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(width: 20),
        GlassContainer(
          child: Row(
            children: [
              _QuantityButton(
                key: const Key('product_qty_minus'),
                icon: Icons.remove,
                onPressed: quantity > 1 ? viewModel.decrementQuantity : null,
                semanticLabel: 'btn-product-qty-minus',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  key: const Key('product_qty_value'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              _QuantityButton(
                key: const Key('product_qty_plus'),
                icon: Icons.add,
                onPressed: viewModel.incrementQuantity,
                semanticLabel: 'btn-product-qty-plus',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
