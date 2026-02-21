import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/seller/seller_products_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: tr('seller.my_products')),
        body: AnimatedEmptyState(icon: Icons.login_rounded, title: tr('seller.login_required_title'), subtitle: tr('seller.login_required_subtitle')),
      );
    }

    final productsAsync = ref.watch(sellerProductsProvider);
    final bulkState = ref.watch(sellerProductsViewModelProvider);
    final bulkVm = ref.read(sellerProductsViewModelProvider.notifier);

    // Listen for success/error messages
    ref.listen(sellerProductsViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: DesignTokens.success));
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: DesignTokens.error));
      }
    });

    return Container(
      decoration: BoxDecoration(gradient: DesignTokens.backgroundGradient(isDark: isDark)),
      child: Scaffold(
        key: const Key('seller_products_screen'),
        appBar: AppBarFactory.custom(
          title: tr('seller.my_products'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: tr('seller.add_product'),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: productsAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => AnimatedEmptyState(icon: Icons.error_outline_rounded, title: tr('seller.something_wrong'), subtitle: e.toString()),
          data: (products) {
            if (products.isEmpty) {
              return AnimatedEmptyState(icon: Icons.inventory_2_outlined, title: tr('seller.no_products_yet'), subtitle: tr('seller.add_first_product'));
            }

            return Column(
              children: [
                // Bulk action bar (shown when items selected)
                if (bulkState.selectedIds.isNotEmpty)
                  _BulkActionBar(
                    selectedCount: bulkState.selectedIds.length,
                    totalCount: products.length,
                    isLoading: bulkState.isLoading,
                    onSelectAll: () => bulkVm.selectAll(products.map((p) => p.productId).toList()),
                    onClearSelection: bulkVm.clearSelection,
                    onActivate: () => bulkVm.bulkAction('activate'),
                    onPause: () => bulkVm.bulkAction('pause'),
                    onArchive: () => _confirmArchive(context, bulkVm, bulkState.selectedIds.length),
                  ),
                // Product list
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(DesignTokens.spacing16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isSelected = bulkState.selectedIds.contains(product.productId);
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                            child: _SellerProductCard(
                              product: product,
                              isSelected: isSelected,
                              isSelectionMode: bulkState.selectedIds.isNotEmpty,
                              onToggle: () => bulkVm.toggleSelection(product.productId),
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                bulkVm.toggleSelection(product.productId);
                              },
                              onEdit: () => Navigator.pushNamed(context, AppRoutes.editProduct, arguments: EditProductArgs(product: product)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, SellerProductsViewModel vm, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('seller.archive_products_title')),
        content: Text(tr('seller.archive_confirmation', namedArgs: {'count': count.toString()})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DesignTokens.error),
            onPressed: () {
              Navigator.pop(ctx);
              vm.bulkAction('archive');
            },
            child: Text(tr('seller.archive')),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  final String approvalStatus;
  const _ApprovalBadge({required this.approvalStatus});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (approvalStatus) {
      ProductApprovalStatusValues.underReview => (DesignTokens.info, tr('seller.under_review')),
      ProductApprovalStatusValues.rejected => (DesignTokens.error, tr('seller.rejected')),
      _ => (DesignTokens.textSecondary, approvalStatus),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool isLoading;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onActivate;
  final VoidCallback onPause;
  final VoidCallback onArchive;

  const _BulkActionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.isLoading,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onActivate,
    required this.onPause,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: DesignTokens.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          GestureDetector(onTap: onClearSelection, child: const Icon(Icons.close_rounded, size: 20)),
          const SizedBox(width: 8),
          Text(
            tr('seller.selected_count', namedArgs: {'count': selectedCount.toString()}),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (selectedCount < totalCount) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSelectAll,
              child: Text(tr('seller.select_all'), style: TextStyle(color: DesignTokens.primary, fontSize: 13)),
            ),
          ],
          const Spacer(),
          if (isLoading)
            const SizedBox(width: 20, height: 20, child: ModernLoadingIndicator(strokeWidth: 2, centered: false))
          else ...[
            _ActionChip(label: tr('seller.activate'), icon: Icons.check_circle_outline, color: DesignTokens.success, onTap: onActivate),
            const SizedBox(width: 6),
            _ActionChip(label: tr('seller.pause'), icon: Icons.pause_circle_outline, color: DesignTokens.warning, onTap: onPause),
            const SizedBox(width: 6),
            _ActionChip(label: tr('seller.archive'), icon: Icons.archive_outlined, color: DesignTokens.error, onTap: onArchive),
          ],
        ],
      ),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;

  const _SellerProductCard({
    required this.product,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggle,
    required this.onLongPress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isSelectionMode ? onToggle : onEdit,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primary.withValues(alpha: 0.08)
              : isDark
              ? DesignTokens.darkSurfaceVariant
              : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: isSelected ? DesignTokens.primary : DesignTokens.outline.withValues(alpha: 0.15), width: isSelected ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Selection checkbox
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSelected ? DesignTokens.primary : DesignTokens.textDisabled,
                  size: 22,
                ),
              ),
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrls.isNotEmpty
                  ? Image.network(product.imageUrls.first, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderImage())
                  : _placeholderImage(),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusBadge(status: product.status),
                      if (product.approvalStatus != ProductApprovalStatusValues.approved) ...[
                        const SizedBox(width: 6),
                        _ApprovalBadge(approvalStatus: product.approvalStatus),
                      ],
                      const Spacer(),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DesignTokens.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${product.stockQuantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.stockQuantity <= 0
                          ? DesignTokens.error
                          : product.stockQuantity <= 5
                          ? DesignTokens.warning
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Edit arrow
            if (!isSelectionMode) Icon(Icons.chevron_right_rounded, color: DesignTokens.textDisabled, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.image_outlined, color: DesignTokens.textDisabled, size: 24),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ProductStatusValues.active => (DesignTokens.success, tr('seller.active')),
      ProductStatusValues.paused => (DesignTokens.warning, tr('seller.pause')),
      ProductStatusValues.archived => (DesignTokens.textDisabled, tr('seller.archived')),
      ProductStatusValues.draft => (DesignTokens.info, tr('seller.draft')),
      ProductStatusValues.outOfStock => (DesignTokens.error, tr('seller.out_of_stock')),
      _ => (DesignTokens.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
