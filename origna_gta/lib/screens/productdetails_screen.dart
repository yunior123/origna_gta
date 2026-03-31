import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:origna_gta/features/products/stock_notification_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
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

import 'package:origna_gta/screens/widgets/product_detail/product_actions_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_detail_skeleton.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_image_gallery.dart';
import 'package:origna_gta/screens/widgets/product_detail/nutrition_facts_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_specs_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_info_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_price_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_qa_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_reviews_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/related_products_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/seller_products_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/fbt_section.dart';
import 'package:origna_gta/screens/widgets/product_detail/video_player_dialog.dart';

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

  /// Builds the best available product snapshot so the detail screen can render
  /// even if the follow-up product fetch fails after navigation.
  Product? _resolveDisplayProduct(AsyncValue<Product?> productAsync) {
    Product? initialProduct;
    if (widget.product != null) {
      try {
        initialProduct = Product.fromJson(widget.product!);
      } catch (_) {}
    }

    final fetchedProduct = productAsync.valueOrNull;
    return switch ((initialProduct, fetchedProduct)) {
      (final initial?, final fetched?)
          when fetched.imageUrls.isEmpty && initial.imageUrls.isNotEmpty =>
        fetched.copyWith(imageUrls: initial.imageUrls),
      (_, final fetched?) => fetched,
      (final initial?, _) => initial,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;
    final productAsync = ref.watch(productByIdProvider(productId));
    final viewModel = ref.read(productDetailViewModelProvider.notifier);
    final selectedVariantId = ref.watch(
      productDetailViewModelProvider.select((s) => s.selectedVariantId),
    );
    final product = _resolveDisplayProduct(productAsync);
    final resolvedProductId = product?.productId ?? productId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratingsAsync = ref.watch(productRatingsProvider(resolvedProductId));

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
              ResponsiveBreakpoints.isMobile(context)
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
          _recordRecentlyViewedOnce(resolvedProductId);
          final imageUrls = product.imageUrls;
          final hasVideo =
              product.videoUrl != null && product.videoUrl!.isNotEmpty;
          final isWideScreen = !ResponsiveBreakpoints.isMobile(context);

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
              FBTSection(product: product),
              const SizedBox(height: 32),
              ReviewsSection(
                productId: resolvedProductId,
                productName: product.name,
                ratingCount: product.ratingCount,
                averageRating: product.rating,
                ratingsAsync: ratingsAsync,
                onRetry: () =>
                    ref.invalidate(productRatingsProvider(resolvedProductId)),
              ),
              const SizedBox(height: 32),
              QASection(
                productId: resolvedProductId,
                sellerId: product.sellerId,
              ),
              const SizedBox(height: 32),
              SellerProductsSection(
                sellerId: product.sellerId,
                excludeProductId: resolvedProductId,
              ),
              const SizedBox(height: 32),
              SimilarProductsSection(
                productId: resolvedProductId,
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
                          IconButton(
                            key: const Key('productdetail_back_button'),
                            tooltip: 'btn-back-product-details',
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
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
                expandedHeight: (MediaQuery.sizeOf(context).height * 0.45)
                    .clamp(320.0, 480.0),
                backgroundColor: isDark
                    ? DesignTokens.darkSurface
                    : DesignTokens.white,
                actions: [buildShareButton()],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      buildImageGallery(
                        height: (MediaQuery.sizeOf(context).height * 0.45)
                            .clamp(320.0, 480.0),
                      ),
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
                          child: IconButton(
                            key: const Key('productdetail_back_button'),
                            tooltip: 'btn-back-product-details',
                            icon: const Icon(
                              Icons.arrow_back,
                              color: DesignTokens.white,
                            ),
                            onPressed: () => Navigator.pop(context),
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
        loading: () => product != null
            ? _buildResolvedProductBody(
                context,
                productId,
                product,
                viewModel,
                selectedVariantId,
                isDark,
                ratingsAsync,
              )
            : const ProductDetailSkeleton(),
        error: (e, s) => product != null
            ? _buildResolvedProductBody(
                context,
                productId,
                product,
                viewModel,
                selectedVariantId,
                isDark,
                ratingsAsync,
              )
            : AnimatedEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'product.load_error'.tr(),
                subtitle: AppError.getMessage(e),
                action: SizedBox(
                  width: 200,
                  child: ModernButton(
                    label: 'common.retry'.tr(),
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(productByIdProvider(resolvedProductId)),
                  ),
                ),
              ),
      ),
    );
  }

  /// Renders product details from an already available product snapshot.
  Widget _buildResolvedProductBody(
    BuildContext context,
    String productId,
    Product product,
    ProductDetailViewModel viewModel,
    String? selectedVariantId,
    bool isDark,
    AsyncValue<List<Map<String, dynamic>>> ratingsAsync,
  ) {
    final matchedVariant = product.hasVariants && selectedVariantId != null
        ? product.variants
              .where((v) => v.variantId == selectedVariantId)
              .firstOrNull
        : null;
    final displayPrice = matchedVariant != null
        ? (matchedVariant.priceCents ?? 0) / 100.0
        : product.price;
    final isOutOfStock =
        (matchedVariant?.stockQuantity ?? product.stockQuantity) <= 0;
    final profileSnapshot = ref.watch(
      userProfileProvider.select((a) => a.valueOrNull),
    );
    final canManage =
        profileSnapshot?.uid == product.sellerId ||
        profileSnapshot?.roles.contains(UserRole.admin) == true;

    return _buildProductScaffoldBody(
      context,
      productId,
      product,
      viewModel,
      displayPrice,
      isOutOfStock,
      isDark,
      ratingsAsync,
      canManage,
    );
  }

  /// Builds the main product-detail layout once a concrete [product] exists.
  Widget _buildProductScaffoldBody(
    BuildContext context,
    String productId,
    Product product,
    ProductDetailViewModel viewModel,
    double displayPrice,
    bool isOutOfStock,
    bool isDark,
    AsyncValue<List<Map<String, dynamic>>> ratingsAsync,
    bool canManage,
  ) {
    _recordRecentlyViewedOnce(productId);
    final imageUrls = product.imageUrls;
    final hasVideo = product.videoUrl != null && product.videoUrl!.isNotEmpty;
    final isWideScreen = !ResponsiveBreakpoints.isMobile(context);

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
        FBTSection(product: product),
        const SizedBox(height: 32),
        ReviewsSection(
          productId: productId,
          productName: product.name,
          ratingCount: product.ratingCount,
          averageRating: product.rating,
          ratingsAsync: ratingsAsync,
          onRetry: () => ref.invalidate(productRatingsProvider(productId)),
        ),
        const SizedBox(height: 32),
        QASection(productId: productId, sellerId: product.sellerId),
        const SizedBox(height: 32),
        SellerProductsSection(
          sellerId: product.sellerId,
          excludeProductId: productId,
        ),
        const SizedBox(height: 32),
        SimilarProductsSection(
          productId: productId,
          categoryId: product.categoryId,
        ),
        const SizedBox(height: 40),
      ],
    );

    Widget buildImageGallery({required double height, bool wide = false}) =>
        ProductImageGallery(
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
                    IconButton(
                      key: const Key('productdetail_back_button'),
                      tooltip: 'btn-back-product-details',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
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
          pinned: true,
          expandedHeight: 360,
          backgroundColor: isDark
              ? DesignTokens.darkSurface
              : DesignTokens.white,
          leading: IconButton(
            key: const Key('productdetail_back_button'),
            tooltip: 'btn-back-product-details',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [buildShareButton()],
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: buildImageGallery(height: 320),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
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
        if (product.specs != null && product.specs!.specs.isNotEmpty) ...[
          const SizedBox(height: 28),
          ProductSpecsSection(product: product),
        ],
        if (product.nutritionFacts != null || product.foodMetadata != null) ...[
          const SizedBox(height: 28),
          NutritionFactsSection(product: product),
        ],
        const SizedBox(height: 28),
        VariantAndCartSection(product: product, viewModel: viewModel),
      ],
    );
  }
}

// ═══ Widget Previews ═══

/// Preview stub — returns false immediately, no backend calls.
class _PreviewStockNotifier extends StockNotificationNotifier {
  _PreviewStockNotifier(super.ref, super.productId, super.variantKey);

  @override
  Future<void> init() async => state = const AsyncValue.data(false);
}

Widget _productDetailsContent({int stockQuantity = 5}) => previewScope(
  extraOverrides: [
    productByIdProvider('preview-id').overrideWith(
      (ref) => Future.value(
        Product(
          productId: 'preview-id',
          sellerId: 'test-seller',
          name: 'Premium Headphones',
          description:
              'Experience high-quality sound with these noise-canceling headphones.',
          priceCents: 29999,
          stockQuantity: stockQuantity,
          imageUrls: ['images/33.png'],
          categoryId: 1,
          createdAt: DateTime.now(),
        ),
      ),
    ),
    userProfileProvider.overrideWith((ref) => Stream.value(null)),
    subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
    qaListProvider('preview-id').overrideWith((ref) => Stream.value([])),
    productRatingsProvider(
      'preview-id',
    ).overrideWith((ref) => Stream.value(const [])),
    similarProductsProvider((
      excludeProductId: 'preview-id',
      categoryId: 1,
    )).overrideWith((ref) => Future.value([])),
    stockNotificationNotifierProvider.overrideWith(
      (ref, args) =>
          _PreviewStockNotifier(ref, args.productId, args.variantKey),
    ),
  ],
  child: const ProductDetailScreen(productId: 'preview-id'),
);

// ── Dark (default) ──────────────────────────────────────────────────────────
@Preview(
  name: 'Product Details Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewProductDetailScreenMobile() =>
    previewMobile(child: _productDetailsContent());

@Preview(
  name: 'Product Details Dark — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewProductDetailScreenTablet() =>
    previewTablet(child: _productDetailsContent());

@Preview(
  name: 'Product Details Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewProductDetailScreenDesktop() =>
    previewDesktop(child: _productDetailsContent());

@Preview(
  name: 'Product Details Dark — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewProductDetailScreenWeb() =>
    previewWeb(child: _productDetailsContent());

// ── Light ────────────────────────────────────────────────────────────────────
@Preview(
  name: 'Product Details Light — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewProductDetailLightMobile() =>
    previewMobile(theme: previewLightTheme, child: _productDetailsContent());

@Preview(
  name: 'Product Details Light — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewProductDetailLightTablet() =>
    previewTablet(theme: previewLightTheme, child: _productDetailsContent());

@Preview(
  name: 'Product Details Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewProductDetailLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _productDetailsContent());

@Preview(
  name: 'Product Details Light — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewProductDetailLightWeb() =>
    previewWeb(theme: previewLightTheme, child: _productDetailsContent());

// ── Out of Stock ─────────────────────────────────────────────────────────────
@Preview(
  name: 'Product Details Out of Stock — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewProductDetailOosMobile() =>
    previewMobile(child: _productDetailsContent(stockQuantity: 0));

@Preview(
  name: 'Product Details Out of Stock — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewProductDetailOosTablet() =>
    previewTablet(child: _productDetailsContent(stockQuantity: 0));

@Preview(
  name: 'Product Details Out of Stock — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewProductDetailOosDesktop() =>
    previewDesktop(child: _productDetailsContent(stockQuantity: 0));

@Preview(
  name: 'Product Details Out of Stock — Web',
  group: 'Screens',
  size: Size(1440, 900),
)
Widget previewProductDetailOosWeb() =>
    previewWeb(child: _productDetailsContent(stockQuantity: 0));

// ── Out of Stock Light ────────────────────────────────────────────────────────
@Preview(
  name: 'Product Details Out of Stock Light — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewProductDetailOosLightMobile() => previewMobile(
  theme: previewLightTheme,
  child: _productDetailsContent(stockQuantity: 0),
);

@Preview(
  name: 'Product Details Out of Stock Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewProductDetailOosLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _productDetailsContent(stockQuantity: 0),
);
