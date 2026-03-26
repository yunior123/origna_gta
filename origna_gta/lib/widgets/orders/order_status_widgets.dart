import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/models/generated/base_models.dart' show OrderStatus;
export 'package:origna_gta/models/generated/base_models.dart' show OrderStatus;
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';

/// Empty state card shown when the buyer has no orders yet.
class EmptyOrdersCard extends StatelessWidget {
  final String? filterLabel;
  const EmptyOrdersCard({super.key, this.filterLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24, vertical: DesignTokens.spacing40),
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.darkOutline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, color: DesignTokens.primary, size: 34),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          Text(
            filterLabel != null ? 'No $filterLabel orders' : 'No orders yet',
            style: const TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeLg, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            filterLabel != null ? 'You have no orders with "$filterLabel" status.' : 'Your order history will appear here once you make a purchase.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeSm),
          ),
        ],
      ),
    );
  }
}

/// Small labeled chip for displaying order metadata (e.g., payment method, delivery speed).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: DesignTokens.darkSurfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radius8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DesignTokens.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeXs),
          ),
        ],
      ),
    );
  }
}

// OrderStatus is imported from base_models.dart — single source of truth.

/// Compact order summary showing items, total, and status for order lists.
class OrderSummaryCard extends StatelessWidget {
  final String orderId;

  final OrderStatus status;
  final int itemCount;
  final String total;
  final String date;
  final String? sellerName;
  const OrderSummaryCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.itemCount,
    required this.total,
    required this.date,
    this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.darkOutline, width: 1),
        boxShadow: DesignTokens.shadowMd,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId',
                    style: const TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeMd, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeXs),
                  ),
                ],
              ),
              StatusBadge(status: status, large: true),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          const Divider(color: DesignTokens.darkOutline, height: 1),
          const SizedBox(height: DesignTokens.spacing12),
          Row(
            children: [
              InfoChip(icon: Icons.shopping_bag_outlined, label: '$itemCount item${itemCount == 1 ? '' : 's'}'),
              const SizedBox(width: DesignTokens.spacing8),
              if (sellerName != null) InfoChip(icon: Icons.storefront_outlined, label: sellerName!),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeSm),
              ),
              Text(
                total,
                style: const TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeLg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Colored badge displaying the current order status (pending, shipped, delivered, etc.).
class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  final bool large;
  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final double iconSize = large ? 16 : 13;
    final double fontSize = large ? DesignTokens.fontSizeSm : DesignTokens.fontSizeXs;
    final EdgeInsets padding = large ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radius32),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: color, size: iconSize),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Single step in the order status timeline with icon, label, and completion state.
class TimelineStep extends StatelessWidget {
  final OrderStatus status;

  final String label;
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;
  const TimelineStep({
    super.key,
    required this.status,
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = isCompleted || isActive ? status.color : DesignTokens.timelineInactiveDark;
    final Color lineColor = isCompleted ? status.color.withValues(alpha: 0.5) : DesignTokens.timelineInactiveDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: isActive || isCompleted ? 0.2 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: isActive ? 2 : 1),
                ),
                child: Icon(isCompleted ? Icons.check_rounded : status.icon, color: nodeColor, size: 16),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(1)),
                ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.spacing12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive || isCompleted ? DesignTokens.white : DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeXs),
                ),
                SizedBox(height: isLast ? 0 : DesignTokens.spacing24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// UI presentation extension for the canonical [OrderStatus] enum
/// from base_models.dart — covers all backend statuses.
extension OrderStatusX on OrderStatus {
  Color get color => switch (this) {
    OrderStatus.pending => DesignTokens.textSecondary,
    OrderStatus.confirmed => DesignTokens.info,
    OrderStatus.processing => DesignTokens.primary,
    OrderStatus.shipped => DesignTokens.statusShipped,
    OrderStatus.inTransit => DesignTokens.info,
    OrderStatus.delivered => DesignTokens.success,
    OrderStatus.cancelled => DesignTokens.error,
    OrderStatus.failed => DesignTokens.error,
    OrderStatus.expired => DesignTokens.textSecondary,
    OrderStatus.disputed => DesignTokens.error,
    OrderStatus.refunded => DesignTokens.warning,
    OrderStatus.partiallyRefunded => DesignTokens.warning,
  };

  IconData get icon => switch (this) {
    OrderStatus.pending => Icons.hourglass_empty_rounded,
    OrderStatus.confirmed => Icons.check_circle_outline,
    OrderStatus.processing => Icons.autorenew_rounded,
    OrderStatus.shipped => Icons.local_shipping_outlined,
    OrderStatus.inTransit => Icons.flight_takeoff_rounded,
    OrderStatus.delivered => Icons.inventory_2_outlined,
    OrderStatus.cancelled => Icons.cancel_outlined,
    OrderStatus.failed => Icons.error_outline_rounded,
    OrderStatus.expired => Icons.timer_off_rounded,
    OrderStatus.disputed => Icons.gavel_rounded,
    OrderStatus.refunded => Icons.replay_rounded,
    OrderStatus.partiallyRefunded => Icons.replay_rounded,
  };

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.processing => 'Processing',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.inTransit => 'In Transit',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.failed => 'Failed',
    OrderStatus.expired => 'Expired',
    OrderStatus.disputed => 'Disputed',
    OrderStatus.refunded => 'Refunded',
    OrderStatus.partiallyRefunded => 'Partially Refunded',
  };
}


// === Widget Previews ===


// ═══ Widget Previews ═══

// ═══════════════════════════════════════════════════════════════════════════════
// @Preview functions
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 1. All status badges (compact) ──────────────────────────────────────────

@Preview(name: 'Status Badges — All (dark)', group: 'Order Status')
Widget previewAllStatusBadges() => previewWrapper(
  child: Wrap(
    spacing: DesignTokens.spacing8,
    runSpacing: DesignTokens.spacing8,
    children: OrderStatus.values.map((s) => StatusBadge(status: s)).toList(),
  ),
);

// ─── 2. All status badges (large, light mode) ────────────────────────────────

@Preview(name: 'Status Badges — Large (light)', group: 'Order Status', brightness: Brightness.light)
Widget previewAllStatusBadgesLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: Wrap(
    spacing: DesignTokens.spacing8,
    runSpacing: DesignTokens.spacing8,
    children: OrderStatus.values.map((s) => StatusBadge(status: s, large: true)).toList(),
  ),
);

// ─── 8. Refunded + Pending cards (edge-case statuses) ────────────────────────

@Preview(name: 'Edge-case Status Cards', group: 'Order Status')
Widget previewEdgeCaseCards() => previewGrid(
  children: [
    const OrderSummaryCard(
      orderId: 'E5T2-9981',
      status: OrderStatus.refunded,
      itemCount: 1,
      total: '\$59.99',
      date: 'Mar 1, 2026 · 08:00 AM',
      sellerName: 'Quick Returns Co',
    ),
    const OrderSummaryCard(orderId: 'F3M7-4410', status: OrderStatus.pending, itemCount: 2, total: '\$145.00', date: 'Mar 3, 2026 · 11:55 PM'),
  ],
);

// ─── 6. Empty state — no orders at all ───────────────────────────────────────

@Preview(name: 'Empty State — No orders', group: 'Order Status')
Widget previewEmptyOrders() => previewWrapper(child: const EmptyOrdersCard());

// ─── 7. Empty state — filtered (cancelled) ───────────────────────────────────

@Preview(name: 'Empty State — Filtered (cancelled)', group: 'Order Status')
Widget previewEmptyOrdersFiltered() => previewWrapper(child: const EmptyOrdersCard(filterLabel: 'cancelled'));

// ─── 3. Order summary cards — multiple statuses ───────────────────────────────

@Preview(name: 'Order Summary Cards', group: 'Order Status')
Widget previewOrderSummaryCards() => previewGrid(
  children: [
    const OrderSummaryCard(
      orderId: 'A7F3-2901',
      status: OrderStatus.delivered,
      itemCount: 3,
      total: '\$124.99',
      date: 'Feb 28, 2026 · 09:14 AM',
      sellerName: 'TechNorth CA',
    ),
    const OrderSummaryCard(
      orderId: 'B2K8-5566',
      status: OrderStatus.shipped,
      itemCount: 1,
      total: '\$49.00',
      date: 'Mar 1, 2026 · 02:30 PM',
      sellerName: 'Maple Goods',
    ),
    const OrderSummaryCard(orderId: 'C9R1-7743', status: OrderStatus.processing, itemCount: 5, total: '\$310.50', date: 'Mar 3, 2026 · 11:00 AM'),
    const OrderSummaryCard(
      orderId: 'D4L0-1122',
      status: OrderStatus.cancelled,
      itemCount: 2,
      total: '\$88.00',
      date: 'Mar 2, 2026 · 06:45 PM',
      sellerName: 'Digital Hub',
    ),
  ],
);

// ─── 4. Order timeline — in-progress (shipped is active step) ─────────────────

@Preview(name: 'Order Timeline — Shipped (active)', group: 'Order Status')
Widget previewOrderTimeline() => previewWrapper(
  child: Container(
    padding: const EdgeInsets.all(DesignTokens.spacing20),
    decoration: BoxDecoration(
      color: DesignTokens.darkCard,
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      border: Border.all(color: DesignTokens.darkOutline, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Timeline',
          style: TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeLg, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DesignTokens.spacing20),
        const TimelineStep(
          status: OrderStatus.confirmed,
          label: 'Order Confirmed',
          subtitle: 'Feb 28, 2026 · 09:14 AM',
          isActive: false,
          isCompleted: true,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.processing,
          label: 'Processing',
          subtitle: 'Mar 1, 2026 · 10:00 AM',
          isActive: false,
          isCompleted: true,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.shipped,
          label: 'Shipped',
          subtitle: 'Mar 2, 2026 · 03:22 PM — In transit',
          isActive: true,
          isCompleted: false,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.delivered,
          label: 'Delivered',
          subtitle: 'Estimated Mar 5, 2026',
          isActive: false,
          isCompleted: false,
          isLast: true,
        ),
      ],
    ),
  ),
);

// ─── 5. Order timeline — fully delivered ─────────────────────────────────────

@Preview(name: 'Order Timeline — Delivered (complete)', group: 'Order Status')
Widget previewOrderTimelineComplete() => previewWrapper(
  child: Container(
    padding: const EdgeInsets.all(DesignTokens.spacing20),
    decoration: BoxDecoration(
      color: DesignTokens.darkCard,
      borderRadius: BorderRadius.circular(DesignTokens.radius16),
      border: Border.all(color: DesignTokens.darkOutline, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Order Delivered',
              style: TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeLg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: DesignTokens.spacing8),
            const StatusBadge(status: OrderStatus.delivered, large: true),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing20),
        const TimelineStep(
          status: OrderStatus.confirmed,
          label: 'Order Confirmed',
          subtitle: 'Feb 20, 2026 · 08:00 AM',
          isActive: false,
          isCompleted: true,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.processing,
          label: 'Processing',
          subtitle: 'Feb 21, 2026 · 11:30 AM',
          isActive: false,
          isCompleted: true,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.shipped,
          label: 'Shipped',
          subtitle: 'Feb 22, 2026 · 04:00 PM',
          isActive: false,
          isCompleted: true,
          isLast: false,
        ),
        const TimelineStep(
          status: OrderStatus.delivered,
          label: 'Delivered',
          subtitle: 'Feb 25, 2026 · 01:15 PM',
          isActive: false,
          isCompleted: true,
          isLast: true,
        ),
      ],
    ),
  ),
);

// ─── 9. Badge color reference sheet ──────────────────────────────────────────

@Preview(name: 'Status Color Reference', group: 'Order Status')
Widget previewStatusColorReference() => previewWrapper(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Order Status — Color Reference',
        style: TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeLg, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: DesignTokens.spacing16),
      ...(OrderStatus.values.map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: DesignTokens.spacing8),
              SizedBox(
                width: 110,
                child: Text(
                  s.label,
                  style: const TextStyle(color: DesignTokens.white, fontSize: DesignTokens.fontSizeSm, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _colorHex(s.color),
                style: const TextStyle(color: DesignTokens.textSecondary, fontSize: DesignTokens.fontSizeXs, fontFamily: 'monospace'),
              ),
              const SizedBox(width: DesignTokens.spacing8),
              StatusBadge(status: s),
            ],
          ),
        ),
      )),
    ],
  ),
);

String _colorHex(Color c) {
  final v = c.toARGB32();
  return '#${v.toRadixString(16).substring(2).toUpperCase()}';
}

