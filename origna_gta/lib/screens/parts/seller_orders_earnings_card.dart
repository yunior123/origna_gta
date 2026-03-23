part of '../seller_orders_screen.dart';

/// Revenue summary card shown at the top of the seller orders list.
class _EarningsSummaryCard extends StatelessWidget {
  final double totalRevenue;
  final int pendingCount;
  final int completedCount;
  final bool isDark;

  const _EarningsSummaryCard({
    required this.totalRevenue,
    required this.pendingCount,
    required this.completedCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.gradientStart, DesignTokens.gradientMiddle],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'seller.total_earnings'.tr(),
                  style: TextStyle(
                    color: DesignTokens.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: DesignTokens.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'seller.after_platform_fee'.tr(),
                  style: TextStyle(
                    color: DesignTokens.white.withValues(alpha: 0.54),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatPill(
                icon: Icons.hourglass_empty_rounded,
                label: '$pendingCount',
                sublabel: 'seller.pending'.tr(),
                color: DesignTokens.warning,
              ),
              const SizedBox(height: 8),
              _StatPill(
                icon: Icons.check_circle_rounded,
                label: '$completedCount',
                sublabel: 'seller.completed'.tr(),
                color: DesignTokens.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DesignTokens.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sublabel,
            style: TextStyle(
              color: DesignTokens.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
