import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/seller/seller_products_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_skeleton_loader.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

part 'parts/seller_products_card_section.dart';
part 'parts/seller_products_bulk_section.dart';

/// Seller's product inventory with lifecycle status filters and bulk actions.
class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  ProviderSubscription<SellerProductsState>? _sellerProductsSubscription;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider.select((a) => a.valueOrNull));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: tr('seller.my_products')),
        body: AnimatedEmptyState(
          icon: Icons.login_rounded,
          title: tr('seller.login_required_title'),
          subtitle: tr('seller.login_required_subtitle'),
        ),
      );
    }

    final productsAsync = ref.watch(sellerProductsProvider);
    final bulkState = ref.watch(sellerProductsViewModelProvider);
    final bulkVm = ref.read(sellerProductsViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        key: const Key('seller_products_screen'),
        appBar: AppBarFactory.custom(
          title: tr('seller.my_products'),
          subtitle: productsAsync.valueOrNull?.isNotEmpty == true
              ? tr(
                  'seller.products_count',
                  namedArgs: {
                    'count': (productsAsync.valueOrNull?.length ?? 0)
                        .toString(),
                  },
                )
              : null,
          actions: [
            // FE-M3: Q&A badge — same as seller_orders_screen
            _UnansweredQaBadge(sellerId: user.uid),
            Semantics(
              button: true,
              label: 'btn-bulk-upload',
              child: IconButton(
                icon: const Icon(Icons.cloud_upload_outlined),
                tooltip: tr('bulk_upload_title'),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.sellerBulkUpload),
              ),
            ),
            Semantics(
              button: true,
              label: 'btn-add-product',
              child: IconButton(
                icon: const Icon(Icons.add_box_outlined),
                tooltip: tr('seller.add_product'),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.addProduct),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.transparent,
        body: productsAsync.when(
          loading: () => _SellerProductsSkeleton(isDark: isDark),
          error: (e, _) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: tr('seller.something_wrong'),
            subtitle: AppError.getMessage(e),
            action: ModernButton(
              label: 'common.retry'.tr(),
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(sellerProductsProvider),
              isOutlined: true,
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.inventory_2_outlined,
                title: tr('seller.no_products_yet'),
                subtitle: tr('seller.add_first_product'),
                showMascot: true,
                action: ModernButton(
                  label: tr('seller.add_product'),
                  icon: Icons.add_box_outlined,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.addProduct),
                ),
              );
            }

            return Column(
              children: [
                // Bulk action bar (shown when items selected)
                if (bulkState.selectedIds.isNotEmpty)
                  _BulkActionBar(
                    selectedCount: bulkState.selectedIds.length,
                    totalCount: products.length,
                    isLoading: bulkState.isLoading,
                    onSelectAll: () => bulkVm.selectAll(
                      products.map((p) => p.productId).toList(),
                    ),
                    onClearSelection: bulkVm.clearSelection,
                    onActivate: () => bulkVm.bulkAction('activate'),
                    onPause: () => bulkVm.bulkAction('pause'),
                    onArchive: () => _confirmArchive(
                      context,
                      bulkVm,
                      bulkState.selectedIds.length,
                    ),
                  ),
                // Product list
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      // Cap to 840px on desktop — product list shouldn't stretch to 1200px
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.isDesktop(context)
                            ? 840.0
                            : ResponsiveBreakpoints.contentMaxWidth.toDouble(),
                      ),
                      child: RefreshIndicator(
                        color: DesignTokens.primary,
                        onRefresh: () async =>
                            ref.invalidate(sellerProductsProvider),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(DesignTokens.spacing16),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isSelected = bulkState.selectedIds.contains(
                              product.productId,
                            );
                            return FadeSlideIn(
                              delay: Duration(
                                milliseconds: 30 * index.clamp(0, 10),
                              ),
                              child: _SellerProductCard(
                                product: product,
                                isSelected: isSelected,
                                isSelectionMode:
                                    bulkState.selectedIds.isNotEmpty,
                                onToggle: () =>
                                    bulkVm.toggleSelection(product.productId),
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  bulkVm.toggleSelection(product.productId);
                                },
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.editProduct,
                                  arguments: EditProductArgs(product: product),
                                ),
                              ),
                            );
                          },
                        ),
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

  void _confirmArchive(
    BuildContext context,
    SellerProductsViewModel vm,
    int count,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('seller.archive_products_title')),
        content: Text(
          tr(
            'seller.archive_confirmation',
            namedArgs: {'count': count.toString()},
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'btn-cancel-archive',
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel')),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-confirm-archive',
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.error,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                vm.bulkAction('archive');
              },
              child: Text(tr('seller.archive')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sellerProductsSubscription = ref.listenManual(
      sellerProductsViewModelProvider,
      (prev, next) {
        if (!mounted) return;
        if (next.successMessage != null &&
            next.successMessage != prev?.successMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: DesignTokens.success,
            ),
          );
        }
        if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _sellerProductsSubscription?.close();
    super.dispose();
  }
}


// === Widget Previews ===
