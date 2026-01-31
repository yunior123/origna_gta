import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/admin/admin_providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminSellersTab extends ConsumerWidget {
  const AdminSellersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(adminSellersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const Center(child: Text('Error Fetching from Database')),
          data: (sellers) {
            if (sellers.isEmpty) {
              return const AnimatedEmptyState(icon: Icons.store_outlined, title: 'No sellers yet', subtitle: 'Sellers will appear here when they register');
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sellers.length,
              itemBuilder: (context, index) {
                final data = sellers[index]; // Keep this line for context
                return FadeSlideIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: _SellerCard(user: data),
                );
              },
            );
          },
        );
  }
}

class _SellerCard extends ConsumerWidget {
  final UserModel user;

  const _SellerCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.name.isNotEmpty ? user.name : 'Unknown';
    final email = user.email;
    final stripeAccountId = user.stripeAccountId;
    final stripeOnboarded = user.onboardingCompleted;
    final isSuspended = user.suspended;
    final createdAt = user.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSuspended ? Colors.red : const Color(0xFFFF6B35),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (isSuspended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Text(
                                'Suspended',
                                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Stripe Status
            Row(
              children: [
                Icon(stripeOnboarded ? Icons.check_circle : Icons.pending, size: 18, color: stripeOnboarded ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Text(
                  stripeOnboarded ? 'Stripe Connected' : 'Stripe Pending',
                  style: TextStyle(color: stripeOnboarded ? Colors.green : Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (stripeAccountId != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${stripeAccountId.length > 12 ? stripeAccountId.substring(0, 12) : stripeAccountId}...)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),
            Text('Joined: ${_formatDate(createdAt)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSuspended)
                  TextButton.icon(
                    onPressed: () => _suspendSeller(context, ref, user.uid, name),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _unsuspendSeller(context, ref, user.uid, name),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Unsuspend'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewSellerProducts(context, user.uid, name),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Products'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _suspendSeller(BuildContext context, WidgetRef ref, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Seller'),
        content: Text('Are you sure you want to suspend $name? They will not be able to receive orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref.read(adminActionsViewModelProvider.notifier).setUserSuspended(userId, true);
              if (!context.mounted) return;
              if (context.mounted) {
                if (success) {
                  messenger.showSnackBar(const SnackBar(content: Text('Seller suspended'), backgroundColor: Colors.orange));
                } else {
                  final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to suspend seller';
                  messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _unsuspendSeller(BuildContext context, WidgetRef ref, String userId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(adminActionsViewModelProvider.notifier).setUserSuspended(userId, false);
    if (context.mounted) {
      if (success) {
        messenger.showSnackBar(const SnackBar(content: Text('Seller unsuspended'), backgroundColor: Colors.green));
      } else {
        final error = ref.read(adminActionsViewModelProvider).errorMessage ?? 'Failed to unsuspend seller';
        messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  void _viewSellerProducts(BuildContext context, String sellerId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SellerProductsScreen(sellerId: sellerId, sellerName: name),
      ),
    );
  }
}

class _SellerProductsScreen extends ConsumerWidget {
  final String sellerId;
  final String sellerName;

  const _SellerProductsScreen({required this.sellerId, required this.sellerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('$sellerName\'s Products'), backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
      body: ref
          .watch(adminProductsProvider(sellerId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('Error loading products')),
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No products'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final name = product.name;
                  final price = product.price;
                  final stock = product.stockQuantity;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('Stock: $stock • \$${price.toStringAsFixed(2)}'),
                      trailing: stock == 0
                          ? const Chip(
                              label: Text('Out of Stock', style: TextStyle(fontSize: 11)),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
