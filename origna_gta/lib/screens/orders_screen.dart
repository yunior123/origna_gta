import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/buyer_orders_viewmodel.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart' hide Address;
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/rating_dialog.dart';

// ============================================================================
// STATUS CONFIGURATION
// ============================================================================

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  final String description;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.description,
  });
}

/// Get visual config for an order-level status
_StatusConfig _orderStatusConfig(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return _StatusConfig(color: DesignTokens.secondary, icon: Icons.hourglass_empty, label: 'Pending', description: 'Awaiting confirmation');
    case OrderStatus.confirmed:
      return _StatusConfig(color: DesignTokens.info, icon: Icons.verified_outlined, label: 'Confirmed', description: 'Payment confirmed');
    case OrderStatus.processing:
      return _StatusConfig(color: DesignTokens.primary, icon: Icons.autorenew, label: 'Processing', description: 'Seller is preparing your order');
    case OrderStatus.shipped:
      return const _StatusConfig(color: Color(0xFF06B6D4), icon: Icons.local_shipping, label: 'Shipped', description: 'Handed to carrier');
    case OrderStatus.inTransit:
      return const _StatusConfig(color: Color(0xFF14B8A6), icon: Icons.flight_takeoff, label: 'In Transit', description: 'On its way to you');
    case OrderStatus.delivered:
      return _StatusConfig(color: DesignTokens.success, icon: Icons.check_circle, label: 'Delivered', description: 'Order delivered!');
    case OrderStatus.cancelled:
      return _StatusConfig(color: DesignTokens.error, icon: Icons.cancel_outlined, label: 'Cancelled', description: 'Order was cancelled');
    case OrderStatus.failed:
      return _StatusConfig(color: DesignTokens.error, icon: Icons.error_outline, label: 'Failed', description: 'Something went wrong');
    case OrderStatus.expired:
      return _StatusConfig(color: DesignTokens.textSecondary, icon: Icons.timer_off, label: 'Expired', description: 'Order has expired');
    case OrderStatus.refunded:
      return _StatusConfig(color: DesignTokens.warning, icon: Icons.money_off, label: 'Refunded', description: 'Full refund issued');
    case OrderStatus.partiallyRefunded:
      return _StatusConfig(color: DesignTokens.warning, icon: Icons.money_off, label: 'Partial Refund', description: 'Partial refund issued');
    case OrderStatus.disputed:
      return _StatusConfig(color: DesignTokens.error, icon: Icons.gavel, label: 'Disputed', description: 'Payment dispute opened');
  }
}

/// Get visual config for an item-level status string
_StatusConfig _itemStatusConfig(String status) {
  if (status == OrderStatusValues.confirmed) {
    return _StatusConfig(color: DesignTokens.info, icon: Icons.verified_outlined, label: 'Confirmed', description: 'Payment confirmed');
  } else if (status == OrderStatusValues.processing) {
    return _StatusConfig(color: DesignTokens.primary, icon: Icons.autorenew, label: 'Processing', description: 'Being prepared');
  } else if (status == OrderStatusValues.shipped) {
    return const _StatusConfig(color: Color(0xFF06B6D4), icon: Icons.local_shipping, label: 'Shipped', description: 'Shipped');
  } else if (status == OrderStatusValues.inTransit) {
    return const _StatusConfig(color: Color(0xFF14B8A6), icon: Icons.flight_takeoff, label: 'In Transit', description: 'Almost there');
  } else if (status == OrderStatusValues.delivered) {
    return _StatusConfig(color: DesignTokens.success, icon: Icons.check_circle, label: 'Delivered', description: 'Received');
  } else if (status == OrderStatusValues.refunded) {
    return _StatusConfig(color: DesignTokens.warning, icon: Icons.money_off, label: 'Refunded', description: 'Refund issued');
  } else if (status == OrderStatusValues.cancelled) {
    return _StatusConfig(color: DesignTokens.error, icon: Icons.cancel_outlined, label: 'Cancelled', description: 'Cancelled');
  } else if (status == OrderStatusValues.disputed) {
    return _StatusConfig(color: DesignTokens.error, icon: Icons.gavel, label: 'Disputed', description: 'Payment dispute opened');
  } else {
    // 'pending' or unknown
    return _StatusConfig(color: DesignTokens.secondary, icon: Icons.hourglass_empty, label: 'Pending', description: 'Awaiting preparation');
  }
}

/// Map order status to timeline step index (0-4)
/// Returns -1 for statuses that don't fit the normal flow
int _timelineStep(OrderStatus status) {
  switch (status) {
    case OrderStatus.confirmed:
      return 0;
    case OrderStatus.processing:
      return 1;
    case OrderStatus.shipped:
      return 2;
    case OrderStatus.inTransit:
      return 3;
    case OrderStatus.delivered:
      return 4;
    default:
      return -1;
  }
}

// ============================================================================
// ORDERS SCREEN
// ============================================================================

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        body: AnimatedEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'auth.sign_in_required'.tr(),
          subtitle: 'orders.order_history_desc'.tr(),
        ),
      );
    }

    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'orders.my_orders'.tr()),
        backgroundColor: Colors.transparent,
        body: ordersAsync.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, ref, error),
          data: (orders) {
            if (orders.isEmpty) return _buildEmptyState(isDark);

            final pendingApprovals = orders.where((o) {
              return o.shippingApprovalStatus == ShippingApprovalStatus.pending;
            }).toList();

            return Column(
              children: [
                if (pendingApprovals.isNotEmpty) _PendingApprovalsBanner(count: pendingApprovals.length),
                Expanded(
                  child: RefreshIndicator(
                    color: DesignTokens.primary,
                    onRefresh: () async => ref.invalidate(buyerOrdersProvider),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 80 * index),
                          child: _BuyerOrderCard(order: orders[index]),
                        );
                      },
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
              ),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: ModernLoadingIndicator(size: 40, strokeWidth: 3, color: Colors.white, centered: false),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('home.loading_your_orders'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AnimatedEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'orders.no_orders'.tr(),
      subtitle: 'orders.no_orders_desc'.tr(),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final message = AppError.getMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [DesignTokens.error.withValues(alpha: 0.15), DesignTokens.error.withValues(alpha: 0.08)],
                ),
              ),
              child: Icon(Icons.error_outline_rounded, size: 50, color: DesignTokens.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 28),
            ModernButton(onPressed: () => ref.invalidate(buyerOrdersProvider), label: 'Retry', icon: Icons.refresh),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BUYER ORDER CARD
// ============================================================================

class _BuyerOrderCard extends ConsumerStatefulWidget {
  final Order order;
  const _BuyerOrderCard({required this.order});

  @override
  ConsumerState<_BuyerOrderCard> createState() => _BuyerOrderCardState();
}

class _BuyerOrderCardState extends ConsumerState<_BuyerOrderCard> {
  bool _isConfirming = false;
  String? _confirmingItemId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final statusConfig = _orderStatusConfig(order.orderStatus);
    final isAuthorized = order.paymentStatus == PaymentStatus.authorized;
    final isPendingApproval = order.shippingApprovalStatus == ShippingApprovalStatus.pending;
    final showTimeline = _timelineStep(order.orderStatus) >= 0;
    final isTerminal = [OrderStatus.cancelled, OrderStatus.failed, OrderStatus.expired, OrderStatus.refunded, OrderStatus.partiallyRefunded, OrderStatus.disputed].contains(order.orderStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : DesignTokens.primary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: DesignTokens.textPrimary.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── ORDER HEADER ───────────────────────────────────
          _buildHeader(order, statusConfig, isDark),

          // ─── STATUS TIMELINE or TERMINAL BADGE ──────────────
          if (showTimeline)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _OrderStatusTimeline(currentStep: _timelineStep(order.orderStatus)),
            )
          else if (isTerminal)
            _buildTerminalBadge(statusConfig, isDark),

          // ─── STATUS DESCRIPTION ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusConfig.color.withValues(alpha: 0.1), statusConfig.color.withValues(alpha: 0.04)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(color: statusConfig.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(statusConfig.icon, size: 18, color: statusConfig.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusConfig.description,
                      style: TextStyle(fontSize: 13, color: statusConfig.color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── PAYMENT BANNER (authorized orders, NOT delivered/terminal) ──
          if (isAuthorized && !isTerminal && order.orderStatus != OrderStatus.delivered)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildPaymentStatusBanner(isPendingApproval),
            ),

          // ─── DIVIDER ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: (isDark ? Colors.white : DesignTokens.textSecondary).withValues(alpha: 0.1)),
          ),

          // ─── ITEMS LIST ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary, letterSpacing: 0.5),
            ),
          ),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildOrderItem(context, item, order.confirmedByClient),
              )),

          // ─── DELIVERY ADDRESS ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _buildAddressSection(order.shippingAddress, isDark),
          ),

          // ─── DELIVERY INSTRUCTIONS ───────────────────────────
          if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _buildDeliveryInstructionsSection(order.deliveryInstructions!, isDark),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(Order order, _StatusConfig statusConfig, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusConfig.color.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radius20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusConfig.color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: statusConfig.color.withValues(alpha: 0.5), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status label
                    Text(
                      statusConfig.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusConfig.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      isDark ? Colors.white : DesignTokens.textPrimary,
                      isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM dd, yyyy · h:mm a').format(order.createdAt),
                  style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radius16),
              boxShadow: [
                BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TERMINAL STATUS BADGE (cancelled, failed, expired, refunded)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTerminalBadge(_StatusConfig config, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [config.color.withValues(alpha: 0.15), config.color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          border: Border.all(color: config.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, size: 20, color: config.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: config.color)),
                  const SizedBox(height: 2),
                  Text(config.description, style: TextStyle(fontSize: 12, color: config.color.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ORDER ITEM
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildOrderItem(BuildContext context, OrderItem item, bool isOrderConfirmed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusConfig = _itemStatusConfig(item.status);
    final isDelivered = item.status == OrderStatusValues.delivered;
    final isRated = _isProductRated(item.productId);
    final isConfirmed = _isItemConfirmed(item);
    final isConfirmingThis = _isConfirming && _confirmingItemId == item.productId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Image ──
              _productImage(item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
              const SizedBox(width: 14),

              // ── Product Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _infoPill('Qty: ${item.quantity}', isDark),
                        const SizedBox(width: 8),
                        _infoPill('\$${item.price.toStringAsFixed(2)}', isDark),
                      ],
                    ),
                    // Tracking number
                    if (item.trackingNumber != null && item.trackingNumber!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF06B6D4).withValues(alpha: 0.12), const Color(0xFF06B6D4).withValues(alpha: 0.04)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, size: 14, color: Color(0xFF06B6D4)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.trackingNumber!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Status Chip ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusConfig.color.withValues(alpha: 0.15), statusConfig.color.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusConfig.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusConfig.icon, size: 14, color: statusConfig.color),
                    const SizedBox(width: 4),
                    Text(
                      statusConfig.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusConfig.color),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Action Buttons (delivered items) ──
          if (isDelivered) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: DesignTokens.textSecondary.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Confirm Receipt
                  if (!isConfirmed && !isOrderConfirmed)
                    _actionButton(
                      icon: isConfirmingThis ? null : Icons.check_circle_outline,
                      label: isConfirmingThis ? 'Confirming...' : 'Confirm Receipt',
                      color: DesignTokens.success,
                      isLoading: isConfirmingThis,
                      onTap: isConfirmingThis ? null : () => _confirmReceipt(item),
                    ),
                  // Confirmed indicator
                  if (isConfirmed || isOrderConfirmed)
                    _statusIndicator(Icons.verified, 'Confirmed', DesignTokens.success),
                  const SizedBox(width: 10),
                  // Rate button
                  if (!isRated)
                    _actionButton(
                      icon: Icons.star_outline_rounded,
                      label: 'Rate',
                      color: DesignTokens.warning,
                      onTap: () => showRatingDialog(
                        context: context,
                        orderId: widget.order.orderId,
                        productId: item.productId,
                        productName: item.name,
                      ),
                    ),
                  // Rated indicator
                  if (isRated) _statusIndicator(Icons.star_rounded, 'Rated', DesignTokens.warning),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _infoPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : DesignTokens.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _actionButton({IconData? icon, required String label, required Color color, bool isLoading = false, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: 'btn-${label.toLowerCase().replaceAll(' ', '-')}',
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(DesignTokens.radius12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                ModernLoadingIndicator(size: 14, strokeWidth: 2, color: color, centered: false)
              else if (icon != null)
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _statusIndicator(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADDRESS SECTION
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAddressSection(Address address, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.primary.withValues(alpha: 0.12), DesignTokens.secondary.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on_rounded, size: 18, color: DesignTokens.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('orders.delivery_address'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(
                  address.formattedAddress,
                  style: TextStyle(fontSize: 13, color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELIVERY INSTRUCTIONS SECTION
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDeliveryInstructionsSection(String instructions, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.info.withValues(alpha: 0.06) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: DesignTokens.info.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.edit_note_outlined, size: 18, color: DesignTokens.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('common.delivery_instructions'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.info, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(
                  instructions,
                  style: TextStyle(fontSize: 13, color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PAYMENT STATUS BANNER
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPaymentStatusBanner(bool isPendingApproval) {
    final (bannerColor, bannerIcon) = isPendingApproval ? (DesignTokens.secondary, Icons.pending_actions) : (DesignTokens.primary, Icons.credit_card);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor.withValues(alpha: 0.12), bannerColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bannerColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(bannerIcon, size: 18, color: bannerColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPendingApproval ? 'Shipping cost changed — your approval is needed' : 'Payment authorized — awaiting seller shipment',
              style: TextStyle(fontSize: 13, color: bannerColor, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUSINESS LOGIC (preserved from original)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _confirmReceipt(OrderItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(buyerOrdersViewModelProvider.notifier);

    setState(() {
      _isConfirming = true;
      _confirmingItemId = item.productId;
    });

    final success = await viewModel.confirmReceipt(widget.order.orderId, [item.productId]);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(SnackBar(content: Text('orders.receipt_confirmed'.tr()), backgroundColor: DesignTokens.success));
    } else {
      final error = ref.read(buyerOrdersViewModelProvider).errorMessage ?? 'Failed to confirm receipt';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: DesignTokens.error));
    }

    setState(() {
      _isConfirming = false;
      _confirmingItemId = null;
    });
  }

  bool _isItemConfirmed(OrderItem item) => item.confirmedByBuyer;

  bool _isProductRated(String productId) => widget.order.ratings.any((r) => r.productId == productId);

  // ──────────────────────────────────────────────────────────────────────────
  // PRODUCT IMAGE
  // ──────────────────────────────────────────────────────────────────────────

  Widget _productImage(String? url) {
    const size = 76.0;
    const radius = 14.0;

    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DesignTokens.primary.withValues(alpha: 0.08), DesignTokens.secondary.withValues(alpha: 0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.image_outlined, size: 28, color: DesignTokens.primary.withValues(alpha: 0.4)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: DesignTokens.textPrimary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _ImageShimmer(size: size),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.outlineVariant, DesignTokens.outline],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.broken_image_outlined, size: 28, color: DesignTokens.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ORDER STATUS TIMELINE
// ============================================================================

class _OrderStatusTimeline extends StatelessWidget {
  /// 0=Confirmed, 1=Processing, 2=Shipped, 3=In Transit, 4=Delivered
  final int currentStep;

  const _OrderStatusTimeline({required this.currentStep});

  static const _steps = [
    (icon: Icons.verified_outlined, label: 'Confirmed'),
    (icon: Icons.autorenew, label: 'Processing'),
    (icon: Icons.local_shipping, label: 'Shipped'),
    (icon: Icons.flight_takeoff, label: 'Transit'),
    (icon: Icons.check_circle, label: 'Delivered'),
  ];

  static const _stepColors = [
    DesignTokens.info, // confirmed - blue
    DesignTokens.primary, // processing - primary
    Color(0xFF06B6D4), // shipped - cyan
    Color(0xFF14B8A6), // in transit - teal
    DesignTokens.success, // delivered - green
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? const Color(0xFF3A3A50) : const Color(0xFFE0E4EE);

    return SizedBox(
      height: 70,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          // Even indices = step nodes, odd indices = connecting lines
          if (index.isEven) {
            final stepIndex = index ~/ 2;
            return _buildStepNode(stepIndex, isDark, inactiveColor);
          } else {
            final lineIndex = index ~/ 2;
            return _buildConnector(lineIndex, isDark, inactiveColor);
          }
        }),
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, bool isDark, Color inactiveColor) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;
    final isActive = isCompleted || isCurrent;
    final step = _steps[stepIndex];
    final color = _stepColors[stepIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 36 : 28,
          height: isCurrent ? 36 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isActive ? null : inactiveColor,
            boxShadow: isCurrent
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                : isCompleted
                    ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6)]
                    : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : step.icon,
            size: isCurrent ? 18 : 14,
            color: isActive ? Colors.white : (isDark ? DesignTokens.textSecondary : DesignTokens.textDisabled),
          ),
        ),
        const SizedBox(height: 6),
        // Label
        Text(
          step.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? color : (isDark ? DesignTokens.textSecondary : DesignTokens.textDisabled),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int lineIndex, bool isDark, Color inactiveColor) {
    final isCompleted = lineIndex < currentStep;
    final fromColor = _stepColors[lineIndex];
    final toColor = _stepColors[lineIndex + 1];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? LinearGradient(colors: [fromColor, toColor])
                : null,
            color: isCompleted ? null : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// IMAGE SHIMMER PLACEHOLDER
// ============================================================================

class _ImageShimmer extends StatefulWidget {
  final double size;
  const _ImageShimmer({required this.size});

  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DesignTokens.outlineVariant, DesignTokens.surfaceVariant, DesignTokens.outlineVariant],
              stops: [0.0, _controller.value, 1.0],
              begin: const Alignment(-1.5, -0.5),
              end: const Alignment(1.5, 0.5),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PENDING APPROVALS BANNER
// ============================================================================

class _PendingApprovalsBanner extends StatelessWidget {
  final int count;
  const _PendingApprovalsBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      beginOffset: const Offset(0, -0.1),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DesignTokens.warning, DesignTokens.warning.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          boxShadow: [BoxShadow(color: DesignTokens.warning.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Semantics(
          button: true,
          label: 'btn-pending-approvals',
          child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.shippingApproval),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.pending_actions, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count order${count > 1 ? 's' : ''} need${count == 1 ? 's' : ''} approval',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tap to review shipping cost changes',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
