// coverage:ignore-file
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/constants.dart' hide PaymentStatus, OrderStatus;
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Seller analytics dashboard — shows total orders, revenue, top products,
/// and orders this month from existing seller order data.
class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Container(
        decoration: BoxDecoration(gradient: DesignTokens.backgroundGradient(isDark: isDark)),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'seller.analytics_title'.tr()),
          backgroundColor: DesignTokens.transparent,
          body: AnimatedEmptyState(
            icon: Icons.login_rounded,
            title: 'seller.login_required'.tr(),
            subtitle: 'seller.login_to_view'.tr(),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Container(
      decoration: BoxDecoration(gradient: DesignTokens.backgroundGradient(isDark: isDark)),
      child: Scaffold(
        key: const Key('seller_analytics_screen'),
        appBar: AppBarFactory.simple(title: 'seller.analytics_title'.tr()),
        backgroundColor: DesignTokens.transparent,
        body: ordersAsync.when(
          data: (orders) => _AnalyticsDashboard(orders: orders),
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (err, st) => Center(
            child: FadeSlideIn(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: DesignTokens.error),
                  const SizedBox(height: DesignTokens.spacing12),
                  Text(
                    'errors.something_went_wrong'.tr(),
                    style: TextStyle(color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsDashboard extends StatelessWidget {
  final List<Order> orders;

  const _AnalyticsDashboard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);

    // Compute metrics
    final totalOrders = orders.length;
    final completedOrders = orders.where((o) => o.orderStatus == OrderStatus.delivered).toList();
    final ordersThisMonth = orders.where((o) => o.createdAt.isAfter(startOfMonth)).toList();
    final cancelledOrders = orders.where((o) => o.orderStatus == OrderStatus.cancelled).length;

    // Revenue from delivered orders only (cents)
    final totalRevenueCents = completedOrders.fold<int>(0, (sum, o) => sum + o.subtotalCents);
    final monthRevenueCents = ordersThisMonth
        .where((o) => o.orderStatus == OrderStatus.delivered)
        .fold<int>(0, (sum, o) => sum + o.subtotalCents);

    // Top products by quantity sold (across all orders)
    final productCounts = <String, _ProductStat>{};
    for (final order in completedOrders) {
      for (final item in order.items) {
        final key = item.productId;
        productCounts.putIfAbsent(key, () => _ProductStat(name: item.name, quantity: 0, revenueCents: 0));
        productCounts[key] = _ProductStat(
          name: item.name,
          quantity: productCounts[key]!.quantity + item.quantity,
          revenueCents: productCounts[key]!.revenueCents + (item.unitPriceCents * item.quantity),
        );
      }
    }
    final topProducts = productCounts.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));
    final displayProducts = topProducts.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI cards row
              FadeSlideIn(
                child: Wrap(
                  spacing: DesignTokens.spacing12,
                  runSpacing: DesignTokens.spacing12,
                  children: [
                    _KpiCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'seller.analytics_total_orders'.tr(),
                      value: totalOrders.toString(),
                      isDark: isDark,
                    ),
                    _KpiCard(
                      icon: Icons.attach_money_rounded,
                      label: 'seller.analytics_total_revenue'.tr(),
                      value: '\$${(totalRevenueCents / 100).toStringAsFixed(2)}',
                      isDark: isDark,
                    ),
                    _KpiCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'seller.analytics_orders_this_month'.tr(),
                      value: ordersThisMonth.length.toString(),
                      isDark: isDark,
                    ),
                    _KpiCard(
                      icon: Icons.trending_up_rounded,
                      label: 'seller.analytics_month_revenue'.tr(),
                      value: '\$${(monthRevenueCents / 100).toStringAsFixed(2)}',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spacing24),

              // Order status breakdown
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: _SectionCard(
                  isDark: isDark,
                  title: 'seller.analytics_order_breakdown'.tr(),
                  child: Column(
                    children: [
                      _StatusRow(
                        label: 'seller.analytics_delivered'.tr(),
                        count: completedOrders.length,
                        color: DesignTokens.success,
                      ),
                      _StatusRow(
                        label: 'seller.analytics_pending'.tr(),
                        count: orders.where((o) => o.orderStatus == OrderStatus.pending).length,
                        color: DesignTokens.textSecondary,
                      ),
                      _StatusRow(
                        label: 'seller.analytics_confirmed'.tr(),
                        count: orders.where((o) => o.orderStatus == OrderStatus.confirmed).length,
                        color: DesignTokens.info,
                      ),
                      _StatusRow(
                        label: 'seller.analytics_shipped'.tr(),
                        count: orders.where((o) => o.orderStatus == OrderStatus.shipped).length,
                        color: DesignTokens.warning,
                      ),
                      _StatusRow(
                        label: 'seller.analytics_cancelled'.tr(),
                        count: cancelledOrders,
                        color: DesignTokens.error,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spacing24),

              // Top products
              if (displayProducts.isNotEmpty)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _SectionCard(
                    isDark: isDark,
                    title: 'seller.analytics_top_products'.tr(),
                    child: Column(
                      children: [
                        for (int i = 0; i < displayProducts.length; i++)
                          _TopProductRow(
                            rank: i + 1,
                            stat: displayProducts[i],
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: DesignTokens.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStat {
  final String name;
  final int quantity;
  final int revenueCents;

  const _ProductStat({required this.name, required this.quantity, required this.revenueCents});
}

// ─── KPI Card ────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _KpiCard({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing16),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.white,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: DesignTokens.primary),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({required this.isDark, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacing20),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          child,
        ],
      ),
    );
  }
}

// ─── Status Row ──────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: DesignTokens.spacing8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: DesignTokens.textSecondary)),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.textOnDark
                  : DesignTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Product Row ─────────────────────────────────────────────────────────

class _TopProductRow extends StatelessWidget {
  final int rank;
  final _ProductStat stat;
  final bool isDark;

  const _TopProductRow({required this.rank, required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${'seller.analytics_qty_sold'.tr()}: ${stat.quantity}',
                  style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '\$${(stat.revenueCents / 100).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignTokens.success,
            ),
          ),
        ],
      ),
    );
  }
}
