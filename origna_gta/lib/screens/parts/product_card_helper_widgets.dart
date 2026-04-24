part of '../product_card_screen.dart';

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
    final count =
        ref.watch(
          unansweredQaCountProvider(productId).select((a) => a.valueOrNull),
        ) ??
        0;

    return Tooltip(
      message: count > 0
          ? 'qa.pending_questions'.tr(namedArgs: {'count': '$count'})
          : 'qa.no_pending_questions'.tr(),
      child: Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          Semantics(
            button: true,
            label: 'btn-qa-badge',
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                color: count > 0
                    ? DesignTokens.warning
                    : DesignTokens.textSecondary,
                size: iconSize,
              ),
              tooltip: count > 0
                  ? 'qa.pending_questions'.tr(namedArgs: {'count': '$count'})
                  : 'qa.no_pending_questions'.tr(),
              onPressed: () => _openProductDetails(
                context,
                productId: productId,
                product: product.toJson(),
              ),
              padding: EdgeInsets.all(isCompact ? 4 : 8),
              constraints: BoxConstraints(
                minWidth: isCompact ? 32 : 48,
                minHeight: isCompact ? 32 : 48,
              ),
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
                    color: DesignTokens.white,
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

/// Delivery estimate chip shown below the product price on every card.
///
/// Logic (priority order):
///   1. Perishable -> "Same-day delivery"
///   2. Local-only -> "Local delivery"
///   3. International origin (shipFromCountry not CA/null) OR estimatedShipDays > 7
///                  -> "{min}-{max} days"
///   4. Standard Canadian -> "Get it by {MMM d}"
class _DeliveryEstimate extends StatelessWidget {
  final Product product;
  final bool isCompact;

  const _DeliveryEstimate({required this.product, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final double fontSize = isCompact ? 9.0 : 10.0;

    if (product.isPerishable) {
      return _chip(
        'product.delivery_same_day'.tr(),
        DesignTokens.success,
        fontSize,
      );
    }

    if (product.isLocalDeliveryOnly) {
      return _chip('product.delivery_local'.tr(), DesignTokens.info, fontSize);
    }

    final deliveryInfo = product.deliveryInfo;
    final isInternational = deliveryInfo.isInternational;
    final hasLongLeadTime = deliveryInfo.maxDays >= 28;
    final exactDays = deliveryInfo.minDays == deliveryInfo.maxDays
        ? deliveryInfo.minDays
        : null;

    if (isInternational || hasLongLeadTime) {
      return _chip(
        'product.delivery_within_weeks_or_longer'.tr(),
        DesignTokens.textSecondary,
        fontSize,
      );
    }

    if (exactDays != null) {
      return _chip(
        'product.delivery_business_days_exact'.tr(
          namedArgs: {'days': '$exactDays'},
        ),
        DesignTokens.success,
        fontSize,
      );
    }

    return _chip(
      'product.delivery_business_days'.tr(
        namedArgs: {
          'min': '${deliveryInfo.minDays}',
          'max': '${deliveryInfo.maxDays}',
        },
      ),
      DesignTokens.success,
      fontSize,
    );
  }

  Widget _chip(String label, Color color, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, color: color),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

String _formatViewCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}

/// Gold/silver/bronze rank badge for the top-3 trending products.
class _RankBadge extends StatelessWidget {
  final int rank; // 1, 2, or 3
  final bool isCompact;

  const _RankBadge({required this.rank, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final (colors, medal) = switch (rank) {
      1 => ([DesignTokens.goldPrimary, DesignTokens.goldDark], '🥇'),
      2 => ([DesignTokens.silverPrimary, DesignTokens.silverDark], '🥈'),
      _ => ([DesignTokens.bronzePrimary, DesignTokens.bronzeDark], '🥉'),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 7,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$medal #$rank',
        style: TextStyle(
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: DesignTokens.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
