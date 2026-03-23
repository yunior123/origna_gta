part of '../seller_warehouses_screen.dart';

// ---------------------------------------------------------------------------
// Warehouse card
// ---------------------------------------------------------------------------

class _WarehouseCard extends StatelessWidget {
  final SellerWarehouse warehouse;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _WarehouseCard({
    required this.warehouse,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? DesignTokens.darkCard : DesignTokens.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: warehouse.isDefault
            ? BorderSide(color: DesignTokens.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                warehouse.isWarehouse
                    ? Icons.warehouse_outlined
                    : Icons.home_outlined,
                color: DesignTokens.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          warehouse.label,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (warehouse.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'common.default'.tr(),
                            style: TextStyle(
                              color: DesignTokens.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warehouse.typeLabel,
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    warehouse.cityProvince,
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    warehouse.address.country,
                    style: TextStyle(
                      color: DesignTokens.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              tooltip: 'seller.warehouse_options'.tr(),
              color: isDark ? DesignTokens.darkCard : DesignTokens.white,
              iconColor: DesignTokens.textSecondary,
              itemBuilder: (_) => [
                if (!warehouse.isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        const Icon(Icons.star_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('common.set_as_default'.tr())),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('common.edit'.tr())),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: DesignTokens.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: DesignTokens.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (isActionLoading) return;
                switch (value) {
                  case 'default':
                    onSetDefault();
                    break;
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
