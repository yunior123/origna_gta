import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/rating_dialog.dart';
import 'package:origna_gta/shipping_approval_screen.dart';
import 'package:origna_gta/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view orders')),
      );
    }

    final ordersAsync = ref.watch(buyerOrdersRawProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'My Orders'),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (orders) {
          if (orders.isEmpty) {
            return const AnimatedEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No orders yet',
              subtitle: 'Your paid orders will appear here',
            );
          }

          // Check for pending shipping approvals
          final pendingApprovals = orders.where((data) {
            return data['shippingApprovalStatus'] == ShippingApprovalStatus.pending.value;
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
                    final orderData = orders[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: _BuyerOrderCard(orderId: orderData['id'] as String, data: orderData),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
// TODO it happens after seller registration completes, before it was ok, now its ok too, but check anyways
// The following _TypeError was thrown building _BuyerOrderCard(dirty, state:
// _BuyerOrderCardState#fefa3):
// TypeError: null: type 'Null' is not a subtype of type 'Map<String, dynamic>'

// The relevant error-causing widget was:
//   _BuyerOrderCard
//   _BuyerOrderCard:file:///Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta/lib/orders_screen.dart:62:30

// When the exception was thrown, this was the stack:
// dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/errors.dart 274:3        throw_
// errors.dart:274
// dart-sdk/lib/_internal/js_shared/lib/rti.dart 1503:3                               _generalAsCheckImplementation
// rti.dart:1503
// package:origna_gta/utils.dart 601:59                                               fromMap
// utils.dart:601
// package:origna_gta/orders_screen.dart 201:60                                       <fn>
// orders_screen.dart:201
// dart-sdk/lib/internal/iterable.dart 442:31                                         elementAt
// iterable.dart:442
// dart-sdk/lib/internal/iterable.dart 371:26                                         moveNext
// iterable.dart:371
// dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/operations.dart 1279:20  next
// operations.dart:1279
// dart-sdk/lib/_internal/js_dev_runtime/patch/core_patch.dart 357:14                 of
// core_patch.dart:357
// dart-sdk/lib/internal/iterable.dart 224:7                                          toList
// iterable.dart:224
// package:origna_gta/orders_screen.dart 201:69                                       build
// orders_screen.dart:201
// package:flutter/src/widgets/framework.dart 5934:27                                 build
// framework.dart:5934
// package:flutter_riverpod/src/consumer.dart 539:20                                  build
// consumer.dart:539
// package:flutter/src/widgets/framework.dart 5820:15                                 performRebuild
// framework.dart:5820
// package:flutter/src/widgets/framework.dart 5985:11                                 performRebuild
// framework.dart:5985
// package:flutter/src/widgets/framework.dart 5532:7                                  rebuild
// framework.dart:5532
// package:flutter/src/widgets/framework.dart 5802:5                                  [_firstBuild]
// framework.dart:5802
// package:flutter/src/widgets/framework.dart 5976:11                                 [_firstBuild]
// framework.dart:5976
// package:flutter/src/widgets/framework.dart 5796:5                                  mount
// framework.dart:5796
// ...     Normal element mounting (29 frames)
// package:flutter/src/widgets/framework.dart 4590:19                                 inflateWidget
// framework.dart:4590
// package:flutter/src/widgets/framework.dart 4059:18                                 updateChild
// framework.dart:4059
// package:flutter/src/widgets/framework.dart 5844:16                                 performRebuild
// framework.dart:5844
// package:flutter/src/widgets/framework.dart 5985:11                                 performRebuild
// framework.dart:5985

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
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShippingApprovalScreen()),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count order${count > 1 ? 's' : ''} need${count == 1 ? 's' : ''} approval',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Tap to review shipping cost changes',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order card using ConsumerStatefulWidget for proper state management
class _BuyerOrderCard extends ConsumerStatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _BuyerOrderCard({required this.orderId, required this.data});

  @override
  ConsumerState<_BuyerOrderCard> createState() => _BuyerOrderCardState();
}

class _BuyerOrderCardState extends ConsumerState<_BuyerOrderCard> {
  bool _isConfirming = false;
  String? _confirmingItemId;

  /// Check if a product has already been rated in this order
  bool _isProductRated(String productId) {
    final ratings = widget.data['ratings'] as Map<String, dynamic>?;
    return ratings?.containsKey(productId) ?? false;
  }

  /// Check if item is confirmed by buyer
  bool _isItemConfirmed(CartItemDetailModel item) {
    return item.confirmedByBuyer;
  }

  Future<void> _confirmReceipt(CartItemDetailModel item) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isConfirming = true;
      _confirmingItemId = item.productId;
    });

    final ordersController = ref.read(ordersControllerProvider);
    final result = await ordersController.confirmReceipt(widget.orderId, [item.productId]);

    if (!mounted) return;

    switch (result) {
      case OrderSuccess(:final message):
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      case OrderError(:final message):
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
    }

    setState(() {
      _isConfirming = false;
      _confirmingItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse order data
    final itemsData = List<Map<String, dynamic>>.from(widget.data['items'] ?? []);
    final items = itemsData.map((e) => CartItemDetailModel.fromMap(e)).toList();
    final total = (widget.data['total'] ?? 0.0).toDouble();
    final createdAt = widget.data['createdAt'] as dynamic;
    final deliveryInfo = widget.data['deliveryInfo'] as Map<String, dynamic>?;
    final isOrderConfirmed = widget.data['confirmedByClient'] == true;
    final paymentStatus = widget.data['paymentStatus'] as String?;
    final isAuthorized = paymentStatus == PaymentStatus.authorized.value;
    final shippingApprovalStatus = widget.data['shippingApprovalStatus'] as String?;
    final isPendingApproval = shippingApprovalStatus == ShippingApprovalStatus.pending.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(_parseTimestamp(createdAt)),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF6B35)),
                ),
              ],
            ),

            // Payment status banner for authorized orders
            if (isAuthorized) ...[
              const SizedBox(height: 12),
              _buildPaymentStatusBanner(isPendingApproval),
            ],

            // Delivery Address
            if (deliveryInfo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliveryInfo['formattedAddress'] ?? 'Address not provided',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // Items List
            ...items.map((item) {
              return _buildOrderItem(context, item, isOrderConfirmed);
            }),
          ],
        ),
      ),
    );
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is DateTime) return timestamp;
    if (timestamp != null && timestamp.toDate != null) {
      return timestamp.toDate();
    }
    return DateTime.now();
  }

  Widget _buildOrderItem(BuildContext context, CartItemDetailModel item, bool isOrderConfirmed) {
    final deliveryStatus = DeliveryStatus.fromValue(item.deliveryStatus);
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
                    Text(
                      'Qty: ${item.quantity} - \$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),

                    // Tracking Number
                    if (isShipped && item.trackingNumber != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tracking: ${item.trackingNumber}',
                          style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Action buttons for delivered items
          if (isDelivered) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Confirm Receipt button
                if (!isConfirmed && !isOrderConfirmed)
                  TextButton.icon(
                    onPressed: isConfirmingThis ? null : () => _confirmReceipt(item),
                    icon: isConfirmingThis
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(isConfirmingThis ? 'Confirming...' : 'Confirm Receipt'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 12),
                // Rating button
                if (!isRated)
                  TextButton.icon(
                    onPressed: () => showRatingDialog(
                      context: context,
                      orderId: widget.orderId,
                      productId: item.productId,
                      productName: item.name,
                    ),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Rate'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[600],
                          fontWeight: FontWeight.w500,
                        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPendingApproval ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPendingApproval ? Colors.orange.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPendingApproval ? Icons.pending_actions : Icons.credit_card,
            size: 18,
            color: isPendingApproval ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPendingApproval ? 'Shipping cost changed - your approval is needed' : 'Payment authorized - awaiting seller shipment',
              style: TextStyle(
                fontSize: 12,
                color: isPendingApproval ? Colors.orange[800] : Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
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
