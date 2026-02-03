import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seller Orders')),
        body: const Center(child: Text('Please log in')),
      );
    }

    if (userProfile?.suspended == true) {
      return Scaffold(
        appBar: AppBarFactory.simple(title: 'Seller Orders'),
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 72, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Seller account suspended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Contact support to restore access.', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Seller Orders'),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No seller orders yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _SellerOrderCard(order: order, sellerId: user.uid);
            },
          );
        },
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

    final sellerTotal = sellerItems.fold<double>(0.0, (acc, item) => acc + (item.price * item.quantity));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM dd, yyyy').format(order.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  '\$${sellerTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.deliveryInfo.formattedAddress, style: const TextStyle(fontSize: 12)),
            const Divider(height: 24),
            if (order.paymentStatus == PaymentStatus.awaitingPayment) _buildAuthorizationBanner(context, ref),
            const Text('Your Items', style: TextStyle(fontWeight: FontWeight.bold)),
            ...sellerItems.map((item) => _buildSellerItem(context, ref, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizationBanner(BuildContext context, WidgetRef ref) {
    final actualShipping = order.actualShipping;
    final approvalStatus = order.shippingApprovalStatus;
    final isLoading = ref.watch(sellerOrdersViewModelProvider.select((state) => state.isLoading));

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Authorized',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
          ),
          const SizedBox(height: 4),
          Text(
            actualShipping <= 0.0
                ? 'Enter actual shipping cost to capture payment.'
                : (approvalStatus == ShippingApprovalStatus.pending ? 'Waiting for buyer approval.' : 'Ready to capture.'),
            style: const TextStyle(fontSize: 11),
          ),
          if (actualShipping <= 0.0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _showUpdateShippingDialog(context, ref),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Shipping & Ship'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerItem(BuildContext context, WidgetRef ref, OrderItem item) {
    final status = item.deliveryStatus;
    final isAuthorized = order.paymentStatus == PaymentStatus.awaitingPayment;

    return ListTile(
      leading: Image.network(item.imageUrls.first, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image)),
      title: Text(item.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text('Qty: ${item.quantity} • ${status.displayText}', style: const TextStyle(fontSize: 12)),
      trailing: !isAuthorized && status != DeliveryStatus.delivered
          ? IconButton(
              icon: Icon(status == DeliveryStatus.shipped ? Icons.check_circle : Icons.local_shipping),
              onPressed: () {
                if (status == DeliveryStatus.pending) {
                  _showMarkAsShippedDialog(context, ref, item);
                } else {
                  ref.read(sellerOrdersViewModelProvider.notifier).updateItemStatus(order.orderId, item.productId, DeliveryStatus.delivered.value);
                }
              },
            )
          : null,
    );
  }

  void _showMarkAsShippedDialog(BuildContext context, WidgetRef ref, OrderItem item) {
    final trackingController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Shipped'),
        content: TextField(
          controller: trackingController,
          decoration: const InputDecoration(labelText: 'Tracking Number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final tracking = trackingController.text.trim();
              if (tracking.isNotEmpty) {
                Navigator.pop(context);
                ref.read(sellerOrdersViewModelProvider.notifier).updateItemStatus(order.orderId, item.productId, 'shipped', trackingNumber: tracking);
              }
            },
            child: const Text('Confirm'),
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
        title: const Text('Confirm Shipping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shippingController,
              decoration: const InputDecoration(labelText: 'Actual Cost'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(labelText: 'Tracking Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final cost = double.tryParse(shippingController.text);
              final tracking = trackingController.text.trim();
              if (cost != null && tracking.isNotEmpty) {
                Navigator.pop(context);
                ref.read(sellerOrdersViewModelProvider.notifier).updateShippingAndCapture(order.orderId, cost, tracking);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
