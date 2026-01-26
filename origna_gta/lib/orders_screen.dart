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

// class OrdersScreen extends StatelessWidget {
//   const OrdersScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return const Scaffold(body: Center(child: Text('Please log in to view orders')));
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))));
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
//                   const SizedBox(height: 16),
//                   Text('No orders yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
//                 ],
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final orderQ = snapshot.data!.docs[index];
//               final OrderModel order = OrderModel.fromDocument(orderQ);
//               final items = List<Map<String, dynamic>>.from(order.items );
//               final total = order.total ;
//               final status = order.status ;
//               final createdAt = order.createdAt as Timestamp?;

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Order #${orderQ.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         _buildStatusChip(status),
//                       ],
//                     ),
//                     if (createdAt != null) ...[
//                       const SizedBox(height: 4),
//                       Text(DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt.toDate()), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//                     ],
//                     const Divider(height: 24),
//                     ...items
//                         .take(2)
//                         .map(
//                           (item) => Padding(
//                             padding: const EdgeInsets.only(bottom: 4),
//                             child: Text('${item['name']} x${item['quantity']}', style: const TextStyle(fontSize: 14)),
//                           ),
//                         ),
//                     if (items.length > 2) Text('+${items.length - 2} more items', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Total:', style: TextStyle(fontWeight: FontWeight.w600)),
//                         Text(
//                           '\$${total.toStringAsFixed(2)}',
//                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildStatusChip(String status) {
//     Color color;
//     String label;

//     switch (status.toLowerCase()) {
//       case 'pending':
//         color = Colors.orange;
//         label = 'Pending';
//         break;
//       case 'processing':
//         color = Colors.blue;
//         label = 'Processing';
//         break;
//       case 'shipped':
//         color = Colors.purple;
//         label = 'Shipped';
//         break;
//       case 'delivered':
//         color = Colors.green;
//         label = 'Delivered';
//         break;
//       case 'cancelled':
//         color = Colors.red;
//         label = 'Cancelled';
//         break;
//       default:
//         color = Colors.grey;
//         label = status;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
//       ),
//     );
//   }
// }
