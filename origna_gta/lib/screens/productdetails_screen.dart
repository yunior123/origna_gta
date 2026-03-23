import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';

import 'widgets/product_detail/product_actions_section.dart';
import 'widgets/product_detail/product_detail_skeleton.dart';
import 'widgets/product_detail/product_image_gallery.dart';
import 'widgets/product_detail/product_info_section.dart';
import 'widgets/product_detail/product_price_section.dart';
import 'widgets/product_detail/product_qa_section.dart';
import 'widgets/product_detail/product_reviews_section.dart';
import 'widgets/product_detail/related_products_section.dart';
import 'widgets/product_detail/video_player_dialog.dart';

/// ProductDetailScreen — coordinator composing extracted widget sections.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final Map<String, dynamic>? product;
  const ProductDetailScreen({super.key, required this.productId, this.product});
  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _lastRecordedProductId;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) _lastRecordedProductId = null;
  }

  void _recordRecentlyViewedOnce(String productId) {
    if (_lastRecordedProductId == productId) return;
    _lastRecordedProductId = productId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _recordRecentlyViewed(productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;
    final productAsync = ref.watch(productByIdProvider(productId));
    final viewModel = ref.read(productDetailViewModelProvider.notifier);
    final selectedVariantId = ref.watch(
      productDetailViewModelProvider.select((s) => s.selectedVariantId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratingsAsync = ref.watch(productRatingsProvider(productId));

    Product? initialProduct;
    if (widget.product != null) {
      try {
        initialProduct = Product.fromJson(widget.product!);
      } catch (_) {}
    }

    final fetchedProduct = productAsync.valueOrNull;
    final product = switch ((initialProduct, fetchedProduct)) {
      (final initial?, final fetched?)
          when fetched.imageUrls.isEmpty && initial.imageUrls.isNotEmpty =>
        fetched.copyWith(imageUrls: initial.imageUrls),
      (_, final fetched?) => fetched,
      (final initial?, _) => initial,
      _ => null,
    };

    final matchedVariant =
        product?.hasVariants == true && selectedVariantId != null
        ? product!.variants
              .where((v) => v.variantId == selectedVariantId)
              .firstOrNull
        : null;
    final displayPrice = matchedVariant != null
        ? (matchedVariant.priceCents ?? 0) / 100.0
        : (product?.price ?? 0.0);
    final isOutOfStock =
        (matchedVariant?.stockQuantity ?? (product?.stockQuantity ?? 1)) <= 0;
    final profileSnapshot = ref.watch(
      userProfileProvider.select((a) => a.valueOrNull),
    );
    final canManage =
        product != null &&
        (profileSnapshot?.uid == product.sellerId ||
            profileSnapshot?.roles.contains(UserRole.admin) == true);

    return Scaffold(
      bottomNavigationBar:
          product != null &&
              !canManage &&
              !product.hasVariants &&
              MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet
          ? StickyBottomCTA(
              product: product,
              isOutOfStock: isOutOfStock,
              isDark: isDark,
            )
          : null,
      body: productAsync.when(
        data: (_) {
          if (product == null) {
            return AnimatedEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'product.not_found'.tr(),
              subtitle: 'product.not_found_desc'.tr(),
            );
          }
          _recordRecentlyViewedOnce(productId);
          final imageUrls = product.imageUrls;
          final hasVideo =
              product.videoUrl != null && product.videoUrl!.isNotEmpty;
          final isWideScreen =
              MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;

          Widget buildProductInfo() => _ProductInfoColumn(
            product: product,
            displayPrice: displayPrice,
            isDark: isDark,
            viewModel: viewModel,
            onDeliveryEstimate: _buildDeliveryEstimate,
          );

          Widget buildBottomSections() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReviewsSection(
                productId: productId,
                productName: product.name,
                ratingCount: product.ratingCount,
                averageRating: product.rating,
                ratingsAsync: ratingsAsync,
                onRetry: () =>
                    ref.invalidate(productRatingsProvider(productId)),
              ),
              const SizedBox(height: 32),
              QASection(productId: productId, sellerId: product.sellerId),
              const SizedBox(height: 32),
              SimilarProductsSection(
                productId: productId,
                categoryId: product.categoryId,
              ),
              const SizedBox(height: 40),
            ],
          );

          Widget buildImageGallery({
            required double height,
            bool wide = false,
          }) => ProductImageGallery(
            imageUrls: imageUrls,
            hasVideo: hasVideo,
            videoUrl: product.videoUrl,
            height: height,
            isWideScreen: wide,
            onVideoTap: () => _showVideoPlayer(context, product.videoUrl!),
            onImageTap: (urls, idx) => _showImageDialog(context, urls, idx),
          );

          Widget buildShareButton() => product.slug != null
              ? IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'product.share'.tr(),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${'product.share_text'.tr(namedArgs: {'productName': product.name})}\n${envConfig.baseUrl}/p/${product.slug}',
                      subject: product.name,
                    ),
                  ),
                )
              : const SizedBox.shrink();

          if (isWideScreen) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: 'btn-back-product-details',
                            child: IconButton(
                              key: const Key('productdetail_back_button'),
                              tooltip: 'product.go_back'.tr(),
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Spacer(),
                          buildShareButton(),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: buildImageGallery(height: 480, wide: true),
                            ),
                            const SizedBox(width: 32),
                            Expanded(flex: 5, child: buildProductInfo()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: buildBottomSections(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: (MediaQuery.of(context).size.height * 0.40)
                    .clamp(280.0, 420.0),
                backgroundColor: isDark
                    ? DesignTokens.darkSurface
                    : DesignTokens.white,
                actions: [buildShareButton()],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      buildImageGallery(height: 340),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: DesignTokens.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DesignTokens.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Semantics(
                            button: true,
                            label: 'btn-back-product-details',
                            child: IconButton(
                              key: const Key('productdetail_back_button'),
                              tooltip: 'product.go_back'.tr(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: DesignTokens.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignTokens.darkSurface
                          : DesignTokens.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildProductInfo(),
                          const SizedBox(height: 32),
                          buildBottomSections(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ProductDetailSkeleton(),
        error: (e, s) => AnimatedEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'product.load_error'.tr(),
          subtitle: AppError.getMessage(e),
          action: SizedBox(
            width: 200,
            child: ModernButton(
              label: 'common.retry'.tr(),
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(productByIdProvider(productId)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryEstimate(BuildContext context, Product product) {
    if (product.isDigital) return const SizedBox.shrink();
    if (product.isPerishable) {
      return DeliveryChip(
        icon: Icons.schedule_outlined,
        label: 'product.delivery_same_day_available'.tr(),
        color: DesignTokens.success,
      );
    }
    if (product.freeShipping || product.isLocalDeliveryOnly) {
      return DeliveryChip(
        icon: Icons.local_shipping_outlined,
        label: product.isLocalDeliveryOnly
            ? 'product.delivery_local_free'.tr()
            : 'product.delivery_free'.tr(),
        color: DesignTokens.success,
      );
    }
    final deliveryInfo = product.deliveryInfo;
    if (deliveryInfo.isInternational) {
      return DeliveryChip(
        icon: Icons.flight_outlined,
        label: 'product.delivery_intl'.tr(
          namedArgs: {
            'min': deliveryInfo.minDays.toString(),
            'max': deliveryInfo.maxDays.toString(),
          },
        ),
        color: DesignTokens.textSecondary,
      );
    }
    final arrivalDate = DateTime.now().add(
      Duration(days: deliveryInfo.minDays + 2),
    );
    return DeliveryChip(
      icon: Icons.local_shipping_outlined,
      label: 'product.delivery_get_by'.tr(
        namedArgs: {'date': DateFormat('MMM d').format(arrivalDate)},
      ),
      color: DesignTokens.success,
    );
  }

  void _showImageDialog(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: DesignTokens.textPrimary,
      builder: (ctx) => Dialog(
        backgroundColor: DesignTokens.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (c, i) => InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[i],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (c, u) =>
                        ModernSkeletonLoader.imagePlaceholder(),
                    errorWidget: (c, u, e) => const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: DesignTokens.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'common.close'.tr(),
                  icon: const Icon(
                    Icons.close,
                    color: DesignTokens.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      barrierColor: DesignTokens.black,
      builder: (c) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  static Future<void> _recordRecentlyViewed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(LocalStorageKeys.recentlyViewed) ?? [];
    await prefs.setStringList(
      LocalStorageKeys.recentlyViewed,
      [id, ...raw.where((e) => e != id)].take(20).toList(),
    );
  }
}

/// Internal widget to build the product info column — extracted for readability.
class _ProductInfoColumn extends StatelessWidget {
  final Product product;
  final double displayPrice;
  final bool isDark;
  final ProductDetailViewModel viewModel;
  final Widget Function(BuildContext, Product) onDeliveryEstimate;

  const _ProductInfoColumn({
    required this.product,
    required this.displayPrice,
    required this.isDark,
    required this.viewModel,
    required this.onDeliveryEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: DesignTokens.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18, color: DesignTokens.warning),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (product.ratingCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '(${product.ratingCount})',
                style: TextStyle(
                  fontSize: 13,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SellerInfoCard(product: product),
        const SizedBox(height: 20),
        ProductPriceCard(product: product, displayPrice: displayPrice),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: onDeliveryEstimate(context, product),
        ),
        const SizedBox(height: 16),
        if (!product.isDigital) DeliveryInfoCard(product: product),
        if (!product.isDigital) const SizedBox(height: 28),
        Text(
          'product.description'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ExpandableDescription(description: product.description),
        if (product.isDigital) ...[
          const SizedBox(height: 12),
          DigitalProductInfo(product: product),
        ],
        const SizedBox(height: 28),
        VariantAndCartSection(product: product, viewModel: viewModel),
      ],
    );
  }
}
