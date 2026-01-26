import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        // Query orders containing products from this seller
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerIds', arrayContains: uid)
            .where('paymentStatus', isEqualTo: 'paid') // Only show paid orders
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active orders to fulfill', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _SellerOrderCard(
                orderDoc: snapshot.data!.docs[index],
                sellerUid: uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final DocumentSnapshot orderDoc;
  final String sellerUid;

  const _SellerOrderCard({required this.orderDoc, required this.sellerUid});

  @override
  Widget build(BuildContext context) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final allItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    
    // Filter to show ONLY this seller's items
    final myItems = allItems.where((item) => item['sellerId'] == sellerUid).toList();
    
    final buyerEmail = data['customerEmail'] ?? 'Unknown';
    final delivery = data['deliveryInfo'] ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(), // Remove default border
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF6B35), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${orderDoc.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  DateFormat('MMM dd • hh:mm a').format(createdAt ?? DateTime.now()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buyer Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buyerEmail, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            delivery['formattedAddress'] ?? 'No address provided',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Text(
                  "ITEMS TO FULFILL",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                ),
                const SizedBox(height: 12),

                // Dynamic List of Seller Items
                ...myItems.map((item) {
                  return _buildItemRow(context, item, allItems);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, Map<String, dynamic> item, List<Map<String, dynamic>> allItems) {
    final status = item['status'] ?? 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Quantity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("x${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              // Status Chip
              _buildStatusChip(status),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons based on status
          if (status == 'pending' || status == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(context, item, allItems, 'shipped'),
                icon: const Icon(Icons.local_shipping, size: 16),
                label: const Text("Mark as Shipped"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )
          else if (status == 'shipped')
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: null, // Disabled
                     child: Text("Tracking: ${item['trackingNumber'] ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () => _showUpdateDialog(context, item, allItems, 'delivered'),
                     icon: const Icon(Icons.check_circle_outline, size: 16),
                     label: const Text("Mark Delivered"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.green,
                       foregroundColor: Colors.white,
                       elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                     ),
                   ),
                 ),
               ],
             )
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    IconData icon;
    String label = status.toUpperCase();

    switch (status) {
      case 'shipped':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default: // pending/confirmed
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> targetItem, List<Map<String, dynamic>> allItems, String nextAction) {
    final trackingController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nextAction == 'shipped' ? "Mark as Shipped" : "Confirm Delivery"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update status for: ${targetItem['name']}"),
            const SizedBox(height: 16),
            if (nextAction == 'shipped') ...[
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(
                  labelText: "Tracking Number",
                  hintText: "e.g. UPS123456789",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The customer will receive an email with this tracking number.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else 
              const Text("Are you sure this item has been delivered to the customer?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Find index of the item
              final index = allItems.indexOf(targetItem);
              if (index != -1) {
                // 2. Update local list
                if (nextAction == 'shipped') {
                  allItems[index]['status'] = 'shipped';
                  allItems[index]['trackingNumber'] = trackingController.text.trim();
                } else {
                  allItems[index]['status'] = 'delivered';
                }
                allItems[index]['updatedAt'] = Timestamp.now();

                // 3. Update Firestore
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderDoc.id)
                    .update({'items': allItems});
                
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nextAction == 'shipped' ? const Color(0xFFFF6B35) : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(nextAction == 'shipped' ? "Update Status" : "Confirm Delivery"),
          ),
        ],
      ),
    );
  }
}