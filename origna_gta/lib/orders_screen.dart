// OrdersScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/utils.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('paymentStatus', isEqualTo: 'paid') // Only show paid orders
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No paid orders found"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _BuyerOrderCard(data: orderData);
            },
          );
        },
      ),
    );
  }
}

Widget _productImage(String? url) {
  if (url == null || url.isEmpty) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.image, size: 20, color: Colors.grey),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      url,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20)),
    ),
  );
}

class _BuyerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BuyerOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final itemsData = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final items = itemsData.map((e) => CartItemDetailModel.fromMap(e)).toList();
    final total = data['total'] ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: \$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM dd').format((data['createdAt'] as Timestamp).toDate()), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Divider(),
            // Render each item with its OWN status
            ...items.map((item) {
              final status = item.deliveryStatus;
              final isShipped = status == 'shipped';
              final isDelivered = status == "delivered";
              final quantity = item.quantity;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // 🖼 Product Image
                    _productImage(item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
                    const SizedBox(width: 12),

                    // 📦 Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text("Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),

                          if (isShipped && item.trackingNumber != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("Tracking: ${item.trackingNumber}", style: const TextStyle(fontSize: 11, color: Colors.blue)),
                            ),
                        ],
                      ),
                    ),
                    // 🚚 Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? Colors.blue.withOpacity(0.1)
                            : isShipped
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDelivered
                            ? "Delivered"
                            : isShipped
                            ? "Shipped"
                            : "Processing",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDelivered
                              ? Colors.blue
                              : isShipped
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
