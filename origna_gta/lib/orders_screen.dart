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
      appBar: AppBar(title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold))),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('paymentStatus', isEqualTo: 'paid') // Only show paid orders
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No paid orders found"));

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

class _BuyerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BuyerOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
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
                Text(
                  DateFormat('MMM dd').format((data['createdAt'] as Timestamp).toDate()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            // Render each item with its OWN status
            ...items.map((item) {
              final status = item['status'] ?? 'pending';
              final isShipped = status == 'shipped';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text("Qty: ${item['quantity']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    // Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isShipped ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isShipped ? "Shipped" : "Processing",
                            style: TextStyle(
                              color: isShipped ? Colors.green : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isShipped && item['trackingNumber'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Track: ${item['trackingNumber']}",
                              style: const TextStyle(fontSize: 10, color: Colors.blue),
                            ),
                          ),
                      ],
                    )
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
