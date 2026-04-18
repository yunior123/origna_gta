import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
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
import 'package:origna_gta/utils/media_url_resolver.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/shared/trending_badge.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';

part 'parts/product_card_image_section.dart';
part 'parts/product_card_info_section.dart';
part 'parts/product_card_helper_widgets.dart';

/// Product grid card: image, title, price, rating, favorite toggle. Navigates to detail on tap.
class ProductCard extends ConsumerStatefulWidget {
  final String productId;
  final Product product;
  final UserModel? userModel;
  // 1–3 → show gold/silver/bronze rank badge; null → no badge
  final int? trendingRank;
  // Prefix for the Hero tag — must be unique per render context to avoid
  // duplicate-Hero assertion when the same product appears in multiple lists
  // (e.g., product grid AND recently-viewed horizontal row).
  final String heroTagPrefix;

  const ProductCard({
    super.key,
    required this.productId,
    required this.product,
    required this.userModel,
    this.trendingRank,
    this.heroTagPrefix = 'product_image',
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

/// Private provider for ProductCard image index
final _productCardImageIndexProvider = StateProvider.autoDispose
    .family<int, String>((_, _) => 0);

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = widget.userModel?.roles.contains(UserRole.admin) ?? false;
    final isOwner = widget.userModel?.uid == widget.product.sellerId;
    final canManageProduct = isAdmin || isOwner;
    final isOutOfStock = widget.product.stockQuantity <= 0;
    final isCompact = ResponsiveBreakpoints.isMobile(context);
    final iconSize = isCompact ? 16.0 : 18.0;

    // Use reactive favorites provider (only rebuild when this bool changes)
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (value) => value.maybeWhen(
          data: (favs) => favs.contains(widget.productId),
          orElse: () => false,
        ),
      ),
    );

    return Semantics(
      label: 'product-card-${widget.productId}',
      container: true,
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
            color: isDark ? DesignTokens.darkCard : DesignTokens.white,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            border: Border.all(
              color: isDark
                  ? DesignTokens.white.withValues(alpha: 0.06)
                  : DesignTokens.transparent,
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
                color: DesignTokens.black.withValues(
                  alpha: isDark ? 0.2 : 0.04,
                ),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section with favorite button
              _ProductCardImageSection(
                productId: widget.productId,
                product: widget.product,
                isCompact: isCompact,
                isOutOfStock: isOutOfStock,
                isFavorite: isFavorite,
                trendingRank: widget.trendingRank,
                heroTagPrefix: widget.heroTagPrefix,
                favoriteController: _controller,
                onToggleFavorite: _toggleFavorite,
              ),
              // Product info section
              _ProductCardInfoSection(
                productId: widget.productId,
                product: widget.product,
                isCompact: isCompact,
                isOwner: isOwner,
                isOutOfStock: isOutOfStock,
              ),
              // Management actions for owner/admin
              if (canManageProduct)
                _buildManagementBar(isDark, isCompact, iconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementBar(bool isDark, bool isCompact, double iconSize) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? DesignTokens.white.withValues(alpha: 0.08)
                : DesignTokens.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            button: true,
            label: 'btn-edit-product-${widget.product.name}',
            child: IconButton(
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
          ),
          _QaBadgeButton(
            productId: widget.productId,
            product: widget.product,
            iconSize: iconSize,
            isCompact: isCompact,
          ),
          Semantics(
            button: true,
            label: 'btn-delete-product-${widget.product.name}',
            child: IconButton(
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
          ),
        ],
      ),
    );
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
          'product.delete_error'.tr();
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
          Semantics(
            button: true,
            label: 'btn-cancel-delete-product',
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('common.cancel'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-confirm-delete-product',
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteProduct();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.error,
                foregroundColor: DesignTokens.white,
              ),
              child: Text('common.delete'.tr()),
            ),
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


// ═══ Widget Previews ═══

Widget _productCardContent() {
  final product = Product(
    productId: 'preview-id',
    sellerId: 'test-seller',
    name: 'Standard Product Instance',
    description:
        'A fantastic product for preview purposes with some descriptive text here.',
    priceCents: 1999,
    stockQuantity: 10,
    imageUrls: ['https://picsum.photos/400'],
    categoryId: 1,
    createdAt: DateTime.now(),
  );
  return previewScope(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 200,
          height: 300,
          child: ProductCard(
            productId: 'preview-id',
            product: product,
            userModel: null,
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Product Card Component — Mobile',
  group: 'Components',
  size: Size(390, 844),
)
Widget previewProductCardScreenMobile() =>
    previewMobile(child: _productCardContent());

@Preview(
  name: 'Product Card Component — Desktop',
  group: 'Components',
  size: Size(1280, 800),
)
Widget previewProductCardScreenDesktop() =>
    previewDesktop(child: _productCardContent());

@Preview(
  name: 'Product Card Component Light — Desktop',
  group: 'Components',
  size: Size(1280, 800),
)
Widget previewProductCardScreenLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _productCardContent());
