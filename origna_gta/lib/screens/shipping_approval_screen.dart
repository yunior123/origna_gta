import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/shipping_approval_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

/// Screen for buyers to approve or reject shipping cost changes
/// This is shown when the seller's actual shipping cost exceeds the estimate by more than 20%
class ShippingApprovalScreen extends ConsumerWidget {
  const ShippingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final approvalsAsync = ref.watch(pendingShippingApprovalsProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [isDark ? Colors.grey[900]! : Colors.grey[50]!, isDark ? Colors.grey[800]! : Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: 'Shipping Approvals'),
        backgroundColor: Colors.transparent,
        body: approvalsAsync.when(
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
                  'Loading approvals...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $error')),
          ),
          data: (approvals) {
            if (approvals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[300]!.withOpacity(0.2), Colors.green[400]!.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline, size: 60, color: Colors.green[600]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No pending approvals',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[900]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Orders requiring shipping approval will appear here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final items = order.items;
    final estimatedShipping = order.shippingCost;
    final actualShipping = order.actualShipping;
    final pendingTotal = order.pendingTotal;
    final originalTotal = order.total;
    final shippingDifference = actualShipping - estimatedShipping;
    final percentIncrease = estimatedShipping > 0 ? ((shippingDifference / estimatedShipping) * 100).toStringAsFixed(0) : '0';

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
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)]),
                    borderRadius: BorderRadius.circular(DesignTokens.radius12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Approval Needed',
                        style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 20),

            // Shipping cost comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[200]!.withOpacity(0.2), Colors.orange[300]!.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 22, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Shipping Cost Update',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.orange[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('\$${estimatedShipping.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Colors.grey[400]),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Actual',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${actualShipping.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.red[200]!.withOpacity(0.3), Colors.red[300]!.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                      border: Border.all(color: Colors.red[400]!.withOpacity(0.3)),
                    ),
                    child: Text(
                      '+\$${shippingDifference.toStringAsFixed(2)} (+$percentIncrease%)',
                      style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order items summary
            Text('Items (${items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${items.length - 3} more items',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 20),

            // Total comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Total',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${originalTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500], decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'New Total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${pendingTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (_isProcessing)
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(colors: [DesignTokens.primary, DesignTokens.secondary]).createShader(bounds),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8))),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red[300]!.withOpacity(0.2), Colors.red[400]!.withOpacity(0.1)]),
                        borderRadius: BorderRadius.circular(DesignTokens.radius12),
                        border: Border.all(color: Colors.red[400]!.withOpacity(0.4)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showRejectConfirmation(context),
                          borderRadius: BorderRadius.circular(DesignTokens.radius12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Reject & Cancel',
                                style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(onPressed: () => _handleApproval(true), label: 'Approve', icon: Icons.check_circle),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius20)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            Text(
              'Cancel Order?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[900]),
            ),
          ],
        ),
        content: Text(
          'Rejecting the shipping cost will cancel your order. '
          'The payment authorization will be released and you will not be charged.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Go Back', style: TextStyle(color: Colors.grey[600])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange[400]!.withValues(alpha: 0.9), Colors.orange[500]!.withValues(alpha: 0.9)]),
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  _handleApproval(false);
                },
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Yes, Cancel Order',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
