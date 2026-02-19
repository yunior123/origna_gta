import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/utils/constants.dart' hide PaymentStatus, ShippingApprovalStatus;

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'seller.manage_orders'.tr()),
          backgroundColor: Colors.transparent,
          body: AnimatedEmptyState(
            icon: Icons.login_rounded,
            title: 'seller.login_required'.tr(),
            subtitle: 'seller.login_to_view'.tr(),
          ),
        ),
      );
    }

    if (userProfile?.suspended == true) {
      return Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.backgroundGradient(isDark: isDark),
        ),
        child: Scaffold(
          appBar: AppBarFactory.simple(title: 'seller.manage_orders'.tr()),
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeSlideIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.block_rounded, size: 56, color: DesignTokens.error),
                    ),
                    const SizedBox(height: DesignTokens.spacing20),
                    Text('seller.account_suspended'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: DesignTokens.spacing8),
                    Text('seller.contact_support'.tr(), style: TextStyle(color: DesignTokens.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        key: const Key('seller_orders_screen_title'),
        appBar: AppBarFactory.custom(
          title: 'seller.manage_orders'.tr(),
          actions: [
            Tooltip(
              message: 'Integration Guide',
              child: IconButton(
                icon: const Icon(Icons.integration_instructions_outlined),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.sellerIntegration),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
          loading: () => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: DesignTokens.shadowMd,
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => DesignTokens.primaryGradient.createShader(bounds),
                child: const ModernLoadingIndicator(strokeWidth: 3, color: Colors.white, centered: false),
              ),
            ),
          ),
          error: (error, _) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'seller.something_wrong'.tr(),
            subtitle: 'seller.could_not_load'.tr(),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.storefront_outlined,
                title: 'seller.no_orders_yet'.tr(),
                subtitle: 'seller.orders_appear_here'.tr(),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacing16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index.clamp(0, 8)),
                      child: _SellerOrderCard(order: order, sellerId: user.uid),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  final Order order;
  final String sellerId;

  const _SellerOrderCard({required this.order, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerItems = order.items.where((item) => item.sellerId == sellerId).toList();
    if (sellerItems.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sellerTotal = sellerItems.fold<double>(0.0, (acc, item) => acc + (item.price * item.quantity));
    // Platform fee is computed by the backend — always use server-provided value
    final platformFee = order.platformFeeTotal;
    final sellerNet = sellerTotal - platformFee;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : DesignTokens.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
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
                    Text('${'seller.order_prefix'.tr()}${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMM dd, yyyy').format(order.createdAt), style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Tooltip(
                    message: 'Gross: \$${sellerTotal.toStringAsFixed(2)} − \$${platformFee.toStringAsFixed(2)} fee',
                    child: Text(
                      '\$${sellerNet.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: DesignTokens.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.shippingAddress.formattedAddress,
                      style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.textDisabled : DesignTokens.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 28, color: isDark ? Colors.white.withValues(alpha: 0.08) : DesignTokens.outlineVariant),
            if (order.paymentStatus == PaymentStatus.awaitingPayment) _buildAuthorizationBanner(context, ref, isDark),
            // Delivery instructions from buyer
            if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty)
              _buildDeliveryInstructionsBanner(isDark),
            Text('seller.your_items'.tr(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : DesignTokens.textPrimary)),
            const SizedBox(height: 8),
            ...sellerItems.map((item) => _buildSellerItem(context, ref, item, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInstructionsBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignTokens.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DesignTokens.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit_note_outlined, size: 16, color: DesignTokens.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'seller.delivery_instructions'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.info, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  order.deliveryInstructions!,
                  style: TextStyle(fontSize: 13, color: isDark ? DesignTokens.outlineVariant : DesignTokens.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizationBanner(BuildContext context, WidgetRef ref, bool isDark) {
    final actualShipping = order.actualShipping;
    final approvalStatus = order.shippingApprovalStatus;
    final isLoading = ref.watch(sellerOrdersViewModelProvider.select((state) => state.isLoading));

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.primary.withValues(alpha: 0.08), DesignTokens.secondary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment_rounded, size: 16, color: DesignTokens.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'seller.payment_authorized'.tr(),
                style: TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            actualShipping <= 0.0
                ? 'seller.enter_shipping_cost'.tr()
                : (approvalStatus == ShippingApprovalStatus.pending ? 'seller.waiting_buyer_approval'.tr() : 'seller.ready_to_capture'.tr()),
            style: TextStyle(fontSize: 12, color: isDark ? DesignTokens.textDisabled : DesignTokens.textSecondary),
          ),
          if (actualShipping <= 0.0) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ModernButton(
                label: 'Confirm Shipping & Ship',
                onPressed: isLoading ? null : () => _showUpdateShippingDialog(context, ref),
                isLoading: isLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerItem(BuildContext context, WidgetRef ref, OrderItem item, bool isDark) {
    final statusStr = item.status;
    final isAuthorized = order.paymentStatus == PaymentStatus.awaitingPayment;
    final isRefunded = statusStr == DeliveryStatusValues.refunded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          child: Image.network(item.imageUrls.first, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radius8)),
            child: Icon(Icons.image_outlined, color: DesignTokens.textDisabled, size: 20),
          )),
        ),
        title: Row(
          children: [
            Flexible(child: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            if (item.isDigital) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_outlined, size: 10, color: Colors.deepPurple),
                    const SizedBox(width: 3),
                    const Text('Digital', style: TextStyle(fontSize: 10, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${'seller.qty_prefix'.tr()} ${item.quantity}', style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                const SizedBox(width: 8),
                _buildStatusChip(statusStr),
              ],
            ),
            if (item.carrier != null) Text('${'seller.carrier_prefix'.tr()} ${item.carrier}', style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
            if (item.refundedAt != null) Text('${'seller.refunded_prefix'.tr()} ${DateFormat.yMd().format(item.refundedAt!)}', style: TextStyle(fontSize: 11, color: DesignTokens.warning)),
          ],
        ),
        // Suppress mark-shipped button for digital items — fulfilled automatically
        trailing: !item.isDigital && !isAuthorized && statusStr == DeliveryStatusValues.pending && !isRefunded
            ? Container(
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.local_shipping_rounded,
                    color: DesignTokens.primary,
                    size: 22,
                  ),
                  tooltip: 'seller.mark_shipped'.tr(),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showMarkAsShippedDialog(context, ref, item);
                  },
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == DeliveryStatusValues.delivered) {
      color = DesignTokens.success;
    } else if (status == DeliveryStatusValues.shipped) {
      color = DesignTokens.primary;
    } else if (status == DeliveryStatusValues.refunded) {
      color = DesignTokens.warning;
    } else {
      color = DesignTokens.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayText(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
          
  String _getStatusDisplayText(String status) {
    if (status == DeliveryStatusValues.pending) return 'Pending';
    if (status == DeliveryStatusValues.shipped) return 'Shipped';
    if (status == DeliveryStatusValues.delivered) return 'Delivered';
    if (status == DeliveryStatusValues.refunded) return 'Refunded';
    return status;
  }

  void _showMarkAsShippedDialog(BuildContext context, WidgetRef ref, OrderItem item) {
    final trackingController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)]),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(Icons.local_shipping_rounded, size: 18, color: DesignTokens.primary),
            ),
            const SizedBox(width: 12),
            Text('seller.mark_shipped'.tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Semantics(
          textField: true,
          label: 'input-tracking-number',
          child: TextField(
          controller: trackingController,
          decoration: InputDecoration(
            labelText: 'seller.tracking_number'.tr(),
            prefixIcon: Icon(Icons.qr_code_rounded, color: DesignTokens.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(color: DesignTokens.primary, width: 2),
            ),
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: TextStyle(color: DesignTokens.textSecondary)),
          ),
          SizedBox(
            width: 120,
            child: ModernButton(
              label: 'common.confirm'.tr(),
              onPressed: () {
                final tracking = trackingController.text.trim();
                if (tracking.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(sellerOrdersViewModelProvider.notifier).updateItemStatus(order.orderId, item.productId, DeliveryStatusValues.shipped, trackingNumber: tracking);
                }
              },
              height: 42,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateShippingDialog(BuildContext context, WidgetRef ref) {
    final estimatedShipping = order.shippingCost;
    final shippingController = TextEditingController(text: estimatedShipping.toStringAsFixed(2));
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)]),
                borderRadius: BorderRadius.circular(DesignTokens.radius8),
              ),
              child: Icon(Icons.payment_rounded, size: 18, color: DesignTokens.primary),
            ),
            const SizedBox(width: 12),
            Text('seller.confirm_shipping'.tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              textField: true,
              label: 'input-actual-cost',
              child: TextField(
              controller: shippingController,
              decoration: InputDecoration(
              labelText: 'seller.actual_cost'.tr(),
                prefixIcon: Icon(Icons.attach_money_rounded, color: DesignTokens.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: BorderSide(color: DesignTokens.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            ),
            const SizedBox(height: 14),
            Semantics(
              textField: true,
              label: 'input-tracking-number-update',
              child: TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: 'seller.tracking_number'.tr(),
                prefixIcon: Icon(Icons.qr_code_rounded, color: DesignTokens.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  borderSide: BorderSide(color: DesignTokens.primary, width: 2),
                ),
              ),
            ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr(), style: TextStyle(color: DesignTokens.textSecondary)),
          ),
          SizedBox(
            width: 120,
            child: ModernButton(
              label: 'common.confirm'.tr(),
              onPressed: () {
                final cost = double.tryParse(shippingController.text);
                final tracking = trackingController.text.trim();
                if (cost != null && tracking.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(sellerOrdersViewModelProvider.notifier).updateShippingAndCapture(order.orderId, cost, tracking);
                }
              },
              height: 42,
            ),
          ),
        ],
      ),
    );
  }
}
