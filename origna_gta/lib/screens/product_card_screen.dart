import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/products/product_actions_viewmodel.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends ConsumerStatefulWidget {
  final String productId;
  final Product product;
  final UserModel? userModel;

  const ProductCard({
    super.key,
    required this.productId,
    required this.product,
    required this.userModel,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentImageIndex = 0;
  final int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> imageUrls = widget.product.imageUrls;
    final name = widget.product.name;
    final price = widget.product.price;
    final rating = widget.product.rating.toDouble();
    final isAdmin = widget.userModel?.roles.contains(UserRoles.admin) ?? false;
    final isOwner = widget.userModel?.uid == widget.product.sellerId;
    final canManageProduct = isAdmin || isOwner;

    // Use reactive favorites provider (only rebuild when this bool changes)
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (value) => value.maybeWhen(
          data: (favs) => favs.contains(widget.productId),
          orElse: () => false,
        ),
      ),
    );

    // Responsive sizing
    final cardWidth = MediaQuery.of(context).size.width;
    final isCompact = cardWidth < 400;
    final padding = isCompact ? 8.0 : 12.0;
    final titleFontSize = isCompact ? 12.0 : 14.0;
    final priceFontSize = isCompact ? 14.0 : 16.0;
    final iconSize = isCompact ? 16.0 : 18.0;
    final favIconSize = isCompact ? 18.0 : 20.0;

    return Semantics(
      label: 'product-card-${widget.productId}',
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: ProductDetailsArgs(
              productId: widget.productId,
              product: widget.product.toJson(),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primary.withValues(
                  alpha: isDark ? 0.08 : 0.04,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section with favorite button
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'product_image_${widget.productId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isCompact ? 12 : 16),
                        ),
                        child: SizedBox.expand(
                          child: imageUrls.isNotEmpty
                              ? Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: imageUrls.length,
                                      onPageChanged: (index) => setState(
                                        () => _currentImageIndex = index,
                                      ),
                                      itemBuilder: (context, index) {
                                        return CachedNetworkImage(
                                          imageUrl:
                                              isValidImageUrl(imageUrls[index])
                                              ? imageUrls[index]
                                              : '',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                                baseColor:
                                                    DesignTokens.outlineVariant,
                                                highlightColor:
                                                    DesignTokens.surface,
                                                child: Container(
                                                  color: Colors.white,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color:
                                                    DesignTokens.outlineVariant,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: isCompact ? 30 : 50,
                                                ),
                                              ),
                                        );
                                      },
                                    ),
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
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 8 : 12,
                                            ),
                                          ),
                                          child: Text(
                                            '${_currentImageIndex + 1}/${imageUrls.length}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCompact ? 10 : 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Container(
                                  color: DesignTokens.outlineVariant,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: isCompact ? 30 : 50,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // N-10: Trending badge
                    if (widget.product.isTrending)
                      Positioned(
                        top: isCompact ? 4 : 8,
                        left: isCompact ? 4 : 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 5 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Trending',
                            style: TextStyle(
                              fontSize: isCompact ? 9 : 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: isCompact ? 4 : 8,
                      right: isCompact ? 4 : 8,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 1.0,
                          end: 1.3,
                        ).animate(_controller),
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: Semantics(
                            button: true,
                            label: 'btn-favorite-${widget.productId}',
                            child: InkWell(
                              onTap: () => _toggleFavorite(),
                              customBorder: const CircleBorder(),
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
                  ],
                ),
              ),

              // Product info section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                            height: 1.25,
                            color: isDark
                                ? Colors.white
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
                      if (widget.product.isDigital)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                                widget.product.digitalType ==
                                        DigitalTypeValues.software
                                    ? 'Software'
                                    : 'Book',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: DesignTokens.digital,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
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
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: priceFontSize,
                                color: DesignTokens.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Hide add to cart button if user owns this product
                          if (!isOwner)
                            Semantics(
                              button: true,
                              label: 'btn-add-to-cart-${widget.productId}',
                              child: Material(
                                color: DesignTokens.primary,
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 6 : 8,
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final messanger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    final user = ref.read(currentUserProvider);
                                    if (user == null) {
                                      showLoginPrompt(context);
                                      return;
                                    }
                                    final success = await ref
                                        .read(cartControllerProvider)
                                        .addToCart(widget.productId, _quantity);
                                    if (mounted) {
                                      messanger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Added to cart'
                                                : 'Failed to add to cart',
                                          ),
                                          backgroundColor: success
                                              ? DesignTokens.success
                                              : DesignTokens.error,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    isCompact ? 6 : 8,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 8 : 12,
                                      vertical: isCompact ? 4 : 6,
                                    ),
                                    child: Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (canManageProduct)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : DesignTokens.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        key: Key('product_edit_button_${widget.product.name}'),
                        icon: Icon(
                          Icons.edit,
                          color: DesignTokens.primary,
                          size: iconSize,
                        ),
                        onPressed: () => _editProduct(context),
                        tooltip: 'product.edit_product'.tr(),
                        padding: EdgeInsets.all(isCompact ? 4 : 8),
                        constraints: BoxConstraints(
                          minWidth: isCompact ? 32 : 48,
                          minHeight: isCompact ? 32 : 48,
                        ),
                      ),
                      // Q&A badge: show unanswered count for seller/admin
                      _QaBadgeButton(
                        productId: widget.productId,
                        product: widget.product,
                        iconSize: iconSize,
                        isCompact: isCompact,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: DesignTokens.error,
                          size: iconSize,
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                        tooltip: 'product.delete_product'.tr(),
                        padding: EdgeInsets.all(isCompact ? 4 : 8),
                        constraints: BoxConstraints(
                          minWidth: isCompact ? 32 : 48,
                          minHeight: isCompact ? 32 : 48,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  // Add a utility function to validate image URLs
  bool isValidImageUrl(String url) {
    return url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  Future<void> _deleteProduct() async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(productActionsViewModelProvider.notifier);
    final success = await viewModel.deleteProduct(widget.productId);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('product.deleted_success'.tr()),
          backgroundColor: DesignTokens.success,
        ),
      );
    } else {
      final error =
          ref.read(productActionsViewModelProvider).errorMessage ??
          'Error deleting product';
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: DesignTokens.error),
      );
    }
  }

  void _editProduct(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.editProduct,
      arguments: EditProductArgs(product: widget.product),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('product.delete_product'.tr()),
        content: Text(
          'product.delete_confirm'.tr(namedArgs: {'name': widget.product.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error,
              foregroundColor: Colors.white,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      showLoginPrompt(context, text: "auth.sign_in_favorites_required");
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await _controller.forward();
    await _controller.reverse();

    try {
      await ref
          .read(favoritesControllerProvider)
          .toggleFavorite(widget.productId);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('favorites.update_failed'.tr()),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }
}

/// Badge button showing count of unanswered Q&A questions for the seller.
class _QaBadgeButton extends ConsumerWidget {
  final String productId;
  final Product product;
  final double iconSize;
  final bool isCompact;

  const _QaBadgeButton({
    required this.productId,
    required this.product,
    required this.iconSize,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unansweredQaCountProvider(productId));
    final count = countAsync.valueOrNull ?? 0;

    return Tooltip(
      message: count > 0
          ? 'Q&A: $count unanswered question${count == 1 ? '' : 's'}'
          : 'Q&A: No pending questions',
      child: Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: count > 0
                  ? DesignTokens.warning
                  : DesignTokens.textSecondary,
              size: iconSize,
            ),
            tooltip: count > 0
                ? 'Q&A: $count unanswered question${count == 1 ? '' : 's'}'
                : 'Q&A: No pending questions',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.productDetails,
              arguments: ProductDetailsArgs(
                productId: productId,
                product: product.toJson(),
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isCompact ? 32 : 48,
              minHeight: isCompact ? 32 : 48,
            ),
          ),
          if (count > 0)
            Positioned(
              top: isCompact ? 0 : 2,
              right: isCompact ? 0 : 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: DesignTokens.warning,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
