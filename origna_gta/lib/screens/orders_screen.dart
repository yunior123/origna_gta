import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/buyer_orders_viewmodel.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/rating_dialog.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view orders')),
      );
    }
    final ordersAsync = ref.watch(buyerOrdersProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'My Orders'),
        backgroundColor: Colors.transparent,
        body: ordersAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary]).createShader(bounds),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8))),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading orders...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          error: (error, stack) => _buildErrorState(context, ref, error),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [DesignTokens.primary.withOpacity(0.2), DesignTokens.secondary.withOpacity(0.2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_bag_outlined, size: 60, color: DesignTokens.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No orders yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[900]),
                    ),
                    const SizedBox(height: 8),
                    Text('Your paid orders will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              );
            }

            // Check for pending shipping approvals
            final pendingApprovals = orders.where((o) {
              return o.shippingApprovalStatus == ShippingApprovalStatus.pending;
            }).toList();

            return Column(
              children: [
                // Shipping approval banner
                if (pendingApprovals.isNotEmpty) _PendingApprovalsBanner(count: pendingApprovals.length),

                // Orders list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 50 * index),
                        child: _BuyerOrderCard(order: order),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final message = AppError.getMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[300]!.withOpacity(0.2), Colors.red[400]!.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ModernButton(onPressed: () => ref.invalidate(buyerOrdersProvider), label: 'Retry', icon: Icons.refresh),
          ],
        ),
      ),
    );
  }
}

/// Order card using ConsumerStatefulWidget for proper state management
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
    final isAuthorized = order.paymentStatus == PaymentStatus.paymentReceived;
    final isPendingApproval = order.shippingApprovalStatus == ShippingApprovalStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.grey[800]!.withOpacity(0.6) : Colors.white.withOpacity(0.8),
            isDark ? Colors.grey[900]!.withOpacity(0.4) : Colors.grey[50]!.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        border: Border.all(color: DesignTokens.primary.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: DesignTokens.primary.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header with gradient text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary]).createShader(bounds),
                      child: Text(
                        'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(order.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.primary.withOpacity(0.2), DesignTokens.secondary.withOpacity(0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    border: Border.all(color: DesignTokens.primary.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: DesignTokens.primary),
                  ),
                ),
              ],
            ),

            // Payment status banner for authorized orders
            if (isAuthorized) ...[const SizedBox(height: 16), _buildPaymentStatusBanner(isPendingApproval)],

            // Delivery Address
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100]!.withOpacity(0.6),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: DesignTokens.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(order.deliveryInfo.formattedAddress, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),

            // Items List
            ...order.items.map((item) {
              return _buildOrderItem(context, item, order.confirmedByClient);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItem item, bool isOrderConfirmed) {
    final deliveryStatus = item.deliveryStatus;
    final isShipped = deliveryStatus == DeliveryStatus.shipped;
    final isDelivered = deliveryStatus == DeliveryStatus.delivered;
    final isRated = _isProductRated(item.productId);
    final isConfirmed = _isItemConfirmed(item);
    final isConfirmingThis = _isConfirming && _confirmingItemId == item.productId;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isDelivered) {
      statusColor = Colors.green;
      statusText = DeliveryStatus.delivered.displayText;
      statusIcon = Icons.check_circle;
    } else if (isShipped) {
      statusColor = Colors.blue;
      statusText = DeliveryStatus.shipped.displayText;
      statusIcon = Icons.local_shipping;
    } else {
      statusColor = Colors.orange;
      statusText = DeliveryStatus.pending.displayText;
      statusIcon = Icons.hourglass_empty;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _productImage(item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text('Qty: ${item.quantity} - \$${item.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),

                    // Tracking Number
                    if (isShipped && item.trackingNumber != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue[200]!.withOpacity(0.2), Colors.blue[300]!.withOpacity(0.1)]),
                          borderRadius: BorderRadius.circular(DesignTokens.radius8),
                          border: Border.all(color: Colors.blue[400]!.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Tracking: ${item.trackingNumber}',
                          style: TextStyle(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(DesignTokens.radius12),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Action buttons for delivered items
          if (isDelivered) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Confirm Receipt button
                if (!isConfirmed && !isOrderConfirmed)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green[300]!.withOpacity(0.2), Colors.green[400]!.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(color: Colors.green[400]!.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isConfirmingThis ? null : () => _confirmReceipt(item),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isConfirmingThis
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.green[400])),
                                    )
                                  : Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                              const SizedBox(width: 6),
                              Text(
                                isConfirmingThis ? 'Confirming...' : 'Confirm Receipt',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Confirmed indicator
                if (isConfirmed || isOrderConfirmed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Confirmed',
                        style: TextStyle(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                const SizedBox(width: 12),
                // Rating button
                if (!isRated)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber[200]!.withOpacity(0.2), Colors.amber[300]!.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(color: Colors.amber[600]!.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showRatingDialog(context: context, orderId: widget.order.orderId, productId: item.productId, productName: item.name),
                        borderRadius: BorderRadius.circular(DesignTokens.radius8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_outline, size: 16, color: Colors.amber[700]),
                              const SizedBox(width: 6),
                              Text(
                                'Rate',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Rated indicator
                if (isRated)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Rated',
                        style: TextStyle(fontSize: 12, color: Colors.amber[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBanner(bool isPendingApproval) {
    // Theme detection for future dark mode support
    final (bannerColor, bannerIcon) = isPendingApproval ? (Colors.orange, Icons.pending_actions) : (DesignTokens.primary, Icons.credit_card);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bannerColor.withOpacity(0.15), bannerColor.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, size: 20, color: bannerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPendingApproval ? 'Shipping cost changed - your approval is needed' : 'Payment authorized - awaiting seller shipment',
              style: TextStyle(fontSize: 13, color: bannerColor, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

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
      messenger.showSnackBar(const SnackBar(content: Text('Receipt confirmed! Seller will be paid.'), backgroundColor: Colors.green));
    } else {
      final error = ref.read(buyerOrdersViewModelProvider).errorMessage ?? 'Failed to confirm receipt';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }

    setState(() {
      _isConfirming = false;
      _confirmingItemId = null;
    });
  }

  /// Check if item is confirmed by buyer
  bool _isItemConfirmed(OrderItem item) {
    return item.confirmedByBuyer;
  }

  /// Check if a product has already been rated in this order
  bool _isProductRated(String productId) {
    return widget.order.ratings.any((rating) => rating.productId == productId);
  }

  Widget _productImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image, size: 24, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Pending approvals banner - extracted widget
class _PendingApprovalsBanner extends StatelessWidget {
  final int count;

  const _PendingApprovalsBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      beginOffset: const Offset(0, -0.1),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300.withOpacity(0.7), Colors.orange.shade600.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radius16),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShippingApprovalScreen()));
            },
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.pending_actions, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count order${count > 1 ? 's' : ''} need${count == 1 ? 's' : ''} approval',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to review shipping cost changes',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
