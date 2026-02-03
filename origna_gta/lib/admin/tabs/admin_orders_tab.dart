import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/admin/admin_providers.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminOrdersTab extends ConsumerStatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  ConsumerState<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;

  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final total = order.total;
    final paymentStatus = PaymentStatus.fromValue(order.paymentStatus);
    final createdAt = order.createdAt;
    final customerEmail = order.customerEmail.isNotEmpty ? order.customerEmail : 'Unknown';
    final items = order.items;

    Color statusColor;
    switch (paymentStatus) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        break;
      case PaymentStatus.authorized:
        statusColor = Colors.blue;
        break;
      case PaymentStatus.refunded:
        statusColor = Colors.purple;
        break;
      case PaymentStatus.paymentFailed:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.receipt, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text('#${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customerEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    paymentStatus.displayText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(DateFormat('MMM dd, yyyy').format(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name)),
                        Text('x${item.quantity}'),
                        const SizedBox(width: 16),
                        Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (paymentStatus == PaymentStatus.paid)
                      TextButton.icon(
                        onPressed: () => _showRefundDialog(context),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Refund'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    TextButton.icon(
                      onPressed: () => _viewOrderDetails(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Full Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDeliveryAddress(Map<String, dynamic> deliveryInfo) {
    final formatted = deliveryInfo['formattedAddress']?.toString();
    if (formatted != null && formatted.trim().isNotEmpty) return formatted;

    final street = deliveryInfo['street']?.toString() ?? '';
    final apartment = deliveryInfo['apartment']?.toString() ?? '';
    final city = deliveryInfo['city']?.toString() ?? '';
    final state = deliveryInfo['state']?.toString() ?? '';
    final postalCode = deliveryInfo['postalCode']?.toString() ?? '';
    final country = deliveryInfo['country']?.toString() ?? '';

    final line1 = [street, if (apartment.isNotEmpty) apartment].where((e) => e.isNotEmpty).join(' ');
    final line2 = [city, state, postalCode].where((e) => e.isNotEmpty).join(', ');
    final parts = [line1, line2, country].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? 'N/A' : parts.join('\n');
  }

  void _showRefundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue Refund'),
        content: const Text('This will refund the order via Stripe. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Refund functionality requires Stripe API integration'), backgroundColor: Colors.orange));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Issue Refund'),
          ),
        ],
      ),
    );
  }

  void _viewOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Order #${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailRow('Customer', order.customerEmail.isNotEmpty ? order.customerEmail : 'Unknown'),
              _buildDetailRow('User ID', order.userId.isNotEmpty ? order.userId : 'Unknown'),
              _buildDetailRow('Payment Status', PaymentStatus.fromValue(order.paymentStatus).displayText),
              _buildDetailRow('Total', '\$${order.total.toStringAsFixed(2)}'),
              if (order.deliveryInfo.isNotEmpty) _buildDetailRow('Address', _formatDeliveryAddress(order.deliveryInfo)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOrdersTabState extends ConsumerState<AdminOrdersTab> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Authorized', PaymentStatus.authorized.value),
                _buildFilterChip('Paid', PaymentStatus.paid.value),
                _buildFilterChip('Refunded', PaymentStatus.refunded.value),
                _buildFilterChip('Failed', PaymentStatus.paymentFailed.value),
              ],
            ),
          ),
        ),

        // Orders List
        Expanded(
          child: ref
              .watch(adminOrdersProvider(_statusFilter))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(child: Text('Error Fetching from Database')),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const AnimatedEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders found',
                      subtitle: 'Orders matching your filter will appear here',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final data = orders[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 30 * index),
                        child: _AdminOrderCard(order: data),
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: const Color(0xFF667EEA),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }
}
