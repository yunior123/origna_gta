import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/utils.dart' show AppError;
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/core/routes.dart';

part 'parts/warehouses_card_section.dart';
part 'parts/warehouses_form_section.dart';
part 'parts/warehouses_helper_widgets.dart';

/// Seller warehouse management screen.
/// Allows sellers to add, edit, and delete shipping locations (warehouses or personal addresses).
/// Accessible from seller profile settings.
class SellerWarehousesScreen extends ConsumerStatefulWidget {
  const SellerWarehousesScreen({super.key});

  static const routeName = AppRoutes.sellerWarehouses;

  @override
  ConsumerState<SellerWarehousesScreen> createState() =>
      _SellerWarehousesScreenState();
}

class _SellerWarehousesScreenState
    extends ConsumerState<SellerWarehousesScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to state changes for error/success feedback
    ref.listenManual(warehousesViewModelProvider, (prev, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
          ),
        );
        ref.read(warehousesViewModelProvider.notifier).clearStatus();
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('seller.warehouse_saved'.tr()),
            backgroundColor: DesignTokens.success,
          ),
        );
        ref.read(warehousesViewModelProvider.notifier).clearStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(sellerWarehousesStreamProvider);
    final vmIsLoading = ref.watch(
      warehousesViewModelProvider.select((s) => s.isLoading),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        appBar: AppBarFactory.simple(
          title: 'seller.warehouses_title'.tr(),
          subtitle: 'seller.warehouses_subtitle'.tr(),
        ),
        body: warehousesAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => Center(
            child: AnimatedEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'common.error_loading'.tr(),
              subtitle: AppError.getMessage(e),
              action: ModernButton(
                label: 'common.retry'.tr(),
                onPressed: () => ref.invalidate(sellerWarehousesStreamProvider),
                icon: Icons.refresh,
              ),
            ),
          ),
          data: (warehouses) => _WarehousesList(
            warehouses: warehouses,
            isActionLoading: vmIsLoading,
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: DesignTokens.primary,
          foregroundColor: DesignTokens.white,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text('seller.add_location'.tr()),
          onPressed: vmIsLoading ? null : () => _showWarehouseForm(context),
        ),
      ),
    );
  }

  void _showWarehouseForm(BuildContext context, {SellerWarehouse? existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? DesignTokens.darkCard : DesignTokens.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WarehouseFormSheet(
        existing: existing,
        onSave:
            ({
              required String label,
              required String type,
              required String city,
              required String province,
              required String country,
              required bool isDefault,
            }) async {
              // FIX L-01: This callback is never invoked — the form always calls
              // onSaveFull with the complete address map.  Assert so any accidental
              // call surfaces immediately in tests rather than silently dropping a save.
              assert(
                false,
                'onSave should never be called; use onSaveFull instead',
              );
            },
        onSaveFull:
            ({
              required String label,
              required String type,
              required Map<String, dynamic> addressMap,
              required bool isDefault,
            }) async {
              await ref
                  .read(warehousesViewModelProvider.notifier)
                  .submitWarehouseForm(
                    warehouseId: existing?.warehouseId,
                    label: label,
                    type: type,
                    addressMap: addressMap,
                    isDefault: isDefault,
                  );
            },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Warehouses list
// ---------------------------------------------------------------------------

class _WarehousesList extends ConsumerWidget {
  final List<SellerWarehouse> warehouses;
  final bool isActionLoading;

  const _WarehousesList({
    required this.warehouses,
    required this.isActionLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (warehouses.isEmpty) {
      return Center(
        child: AnimatedEmptyState(
          icon: Icons.warehouse_outlined,
          title: 'seller.no_warehouses_yet'.tr(),
          subtitle: 'seller.warehouses_empty_desc'.tr(),
          showMascot: true,
        ),
      );
    }

    return RefreshIndicator(
      color: DesignTokens.primary,
      onRefresh: () async => ref.invalidate(sellerWarehousesStreamProvider),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ResponsiveBreakpoints.contentMaxWidth,
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: warehouses.length,
            itemBuilder: (context, i) {
              final wh = warehouses[i];
              return _WarehouseCard(
                warehouse: wh,
                isActionLoading: isActionLoading,
                onEdit: () => context
                    .findAncestorStateOfType<_SellerWarehousesScreenState>()
                    ?._showWarehouseForm(context, existing: wh),
                onDelete: () async {
                  final confirmed = await _confirmDelete(context, wh.label);
                  if (confirmed == true) {
                    await ref
                        .read(warehousesViewModelProvider.notifier)
                        .deleteWarehouse(wh.warehouseId);
                  }
                },
                onSetDefault: () => ref
                    .read(warehousesViewModelProvider.notifier)
                    .updateWarehouse(
                      warehouseId: wh.warehouseId,
                      isDefault: true,
                    ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text(
          'seller.warehouse_delete_confirm'.tr(namedArgs: {'name': label}),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'btn-dialog-cancel',
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'btn-dialog-confirm-delete',
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
              child: Text('common.delete'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
