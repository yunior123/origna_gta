import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/shipping_approval_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

/// Screen for buyers to approve or reject shipping cost changes
/// This is shown when the seller's actual shipping cost exceeds the estimate by more than 20%
class ShippingApprovalScreen extends ConsumerWidget {
  const ShippingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingShippingApprovalsProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Shipping Approvals'),
      backgroundColor: const Color(0xFFF5F5F5),
      body: approvalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (approvals) {
          if (approvals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text('No pending approvals', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Orders requiring shipping approval will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final order = approvals[index];
              return _ApprovalCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  final Order order;

  const _ApprovalCard({required this.order});

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order.items;
    final estimatedShipping = order.shippingCost;
    final actualShipping = order.actualShipping;
    final pendingTotal = order.pendingTotal;
    final originalTotal = order.total;
    final shippingDifference = actualShipping - estimatedShipping;
    final percentIncrease = estimatedShipping > 0 ? ((shippingDifference / estimatedShipping) * 100).toStringAsFixed(0) : '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(DateFormat('MMM dd, yyyy').format(order.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text(
                        'Approval Needed',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Shipping cost comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_shipping, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Shipping Cost Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text('\$${estimatedShipping.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Actual', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(
                            '\$${actualShipping.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '+\$${shippingDifference.toStringAsFixed(2)} (+$percentIncrease%)',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order items summary
            Text('Items (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                        Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3) Text('+ ${items.length - 3} more items', style: TextStyle(color: Colors.grey[500], fontSize: 12)),

            const Divider(height: 24),

            // Total comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Original Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      '\$${originalTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('New Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${pendingTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectConfirmation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject & Cancel Order'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApproval(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(bool approved) async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(shippingApprovalViewModelProvider.notifier);

    final success = await viewModel.approveShippingCost(widget.order.orderId, approved);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(approved ? 'Shipping approved' : 'Order cancelled'), backgroundColor: approved ? Colors.green : Colors.orange),
      );
    } else {
      final error = ref.read(shippingApprovalViewModelProvider).errorMessage ?? 'Failed to update shipping approval';
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }

    setState(() => _isProcessing = false);
  }

  void _showRejectConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Rejecting the shipping cost will cancel your order. '
          'The payment authorization will be released and you will not be charged.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Go Back')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleApproval(false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }
}
