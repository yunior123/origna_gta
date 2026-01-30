import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/widgets/animations.dart';

class AdminSellersTab extends StatelessWidget {
  const AdminSellersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('roles', arrayContains: UserRoles.seller).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error: ${snapshot.error}');
          return Center(child: Text('Error Fetching from Database'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AnimatedEmptyState(icon: Icons.store_outlined, title: 'No sellers yet', subtitle: 'Sellers will appear here when they register');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return FadeSlideIn(
              delay: Duration(milliseconds: 50 * index),
              child: _SellerCard(userId: doc.id, data: data),
            );
          },
        );
      },
    );
  }
}

class _SellerCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _SellerCard({required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final stripeAccountId = data['stripeAccountId'] as String?;
    final stripeOnboarded = data['stripeOnboardingComplete'] == true;
    final isSuspended = data['suspended'] == true;
    final createdAt = data['createdAt'] as Timestamp?;

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
                  Text('(${stripeAccountId.substring(0, 12)}...)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ],
            ),

            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text('Joined: ${_formatDate(createdAt.toDate())}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSuspended)
                  TextButton.icon(
                    onPressed: () => _suspendSeller(context, userId, name),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Suspend'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _unsuspendSeller(context, userId, name),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Unsuspend'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewSellerProducts(context, userId, name),
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

  void _suspendSeller(BuildContext context, String userId, String name) {
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
              await FirebaseFirestore.instance.collection('users').doc(userId).update({'suspended': true, 'suspendedAt': FieldValue.serverTimestamp()});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller suspended'), backgroundColor: Colors.orange));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _unsuspendSeller(BuildContext context, String userId, String name) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'suspended': false, 'suspendedAt': FieldValue.delete()});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller unsuspended'), backgroundColor: Colors.green));
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

class _SellerProductsScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const _SellerProductsScreen({required this.sellerId, required this.sellerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$sellerName\'s Products'), backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: sellerId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final price = (data['price'] ?? 0.0).toDouble();
              final stock = data['stockQuantity'] ?? 0;

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
