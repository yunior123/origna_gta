part of '../addproduct_screen.dart';

// ============================================================================
// SUPPLIER SECTION — Margin preview, supplier info badge
// ============================================================================

extension _AddProductSupplierSection on _AddProductScreenState {
  Widget buildMarginPreview(AddProductState state) {
    if (state.selectedSupplierCurrency != 'CAD') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: DesignTokens.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'product.margin_warning'.tr(
                  namedArgs: {'currency': state.selectedSupplierCurrency},
                ),
                style: TextStyle(fontSize: 12, color: DesignTokens.warning),
              ),
            ),
          ],
        ),
      );
    }

    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    if (cost <= 0 || price <= 0) return const SizedBox.shrink();

    final margin = ((price - cost) / price * 100);
    final profit = price - cost;
    final isGood = margin > 30;
    final isOk = margin > 15;
    final color = isGood
        ? DesignTokens.success
        : (isOk ? DesignTokens.warning : DesignTokens.error);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${margin.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'product.profit_margin'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'product.per_unit'.tr(
                        namedArgs: {'amount': profit.toStringAsFixed(2)},
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isGood
                    ? Icons.trending_up_rounded
                    : (isOk
                          ? Icons.trending_flat_rounded
                          : Icons.trending_down_rounded),
                color: color,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSupplierInfoBadge(String supplierId) {
    final config = getSupplierConfig(supplierId);
    final deliveryRange = getSupplierDeliveryRange(supplierId);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, size: 18, color: config.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.translatedDisplayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: config.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${config.translatedRegion} · ${deliveryRange.minDays}-${deliveryRange.maxDays} days · ${config.translatedCountry}',
                  style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (config.isInternational)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.info.withValues(alpha: 0.15),
                    DesignTokens.info.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'product.intl_label'.tr(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.info,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
