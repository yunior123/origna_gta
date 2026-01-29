import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seller Orders')),
        body: const Center(child: Text('Please log in to view orders')),
      );
    }

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Seller Orders'),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerIds', arrayContains: user.uid)
            .where('paymentStatus', whereIn: [
              PaymentStatus.paid.value,
              PaymentStatus.authorized.value, // Include authorized orders for manual capture
            ])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No seller orders yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Orders containing your products will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final orderData = doc.data() as Map<String, dynamic>;
              return _SellerOrderCard(
                orderId: doc.id,
                data: orderData,
                sellerId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _SellerOrderCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final String sellerId;

  const _SellerOrderCard({
    required this.orderId,
    required this.data,
    required this.sellerId,
  });

  @override
  State<_SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends State<_SellerOrderCard> {
  bool _isUpdatingShipping = false;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final data = widget.data;
    final sellerId = widget.sellerId;
    // Parse order data
    final itemsData = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final allItems = itemsData.map((e) => CartItemDetailModel.fromMap(e)).toList();
    
    // Filter only items belonging to this seller
    final sellerItems = allItems.where((item) => item.sellerId == sellerId).toList();
    
    if (sellerItems.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no items belong to seller
    }

    final createdAt = data['createdAt'] as Timestamp?;
    final deliveryInfo = data['deliveryInfo'] as Map<String, dynamic>?;
    final customerEmail = data['customerEmail'] as String?;

    // Calculate seller's total from their items
    final sellerTotal = sellerItems.fold<double>(
      0.0,
      (acc, item) => acc + (item.price * item.quantity),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(createdAt.toDate()),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
                Text(
                  '\$${sellerTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF6B35)),
                ),
              ],
            ),

            // Customer Info
            if (customerEmail != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customerEmail,
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Delivery Address
            if (deliveryInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliveryInfo['formattedAddress'] ?? 'Address not provided',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Divider(height: 24),

            // Manual capture banner - show if payment is authorized but not captured
            if (data['paymentStatus'] == PaymentStatus.authorized.value) ...[
              _buildAuthorizationBanner(data),
              const SizedBox(height: 12),
            ],

            // Seller's Items
            Text(
              'Your Items (${sellerItems.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            ...sellerItems.map((item) {
              return _buildSellerItem(context, item, data);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizationBanner(Map<String, dynamic> data) {
    final estimatedShipping = (data['estimatedShipping'] ?? 0.0).toDouble();
    final actualShipping = data['actualShipping'];
    final approvalStatus = data['shippingApprovalStatus'] as String?;
    final authExpires = data['authorizationExpiresAt'];

    String expiresText = '';
    if (authExpires != null) {
      final expiresDate = authExpires is Timestamp
          ? authExpires.toDate()
          : DateTime.tryParse(authExpires.toString());
      if (expiresDate != null) {
        final daysLeft = expiresDate.difference(DateTime.now()).inDays;
        expiresText = '$daysLeft days left to capture';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Payment Authorized',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              if (expiresText.isNotEmpty)
                Text(
                  expiresText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            actualShipping == null
                ? 'Enter actual shipping cost and confirm shipment to capture payment.'
                : approvalStatus == ShippingApprovalStatus.pending.value
                    ? 'Waiting for buyer to approve the updated shipping cost.'
                    : 'Ready to capture payment. Confirm shipment to proceed.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated shipping: \$${estimatedShipping.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (actualShipping != null)
                Text(
                  'Actual: \$${(actualShipping as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          if (actualShipping == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingShipping ? null : () => _showUpdateShippingDialog(data),
                icon: _isUpdatingShipping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.local_shipping, size: 18),
                label: Text(_isUpdatingShipping ? 'Updating...' : 'Confirm Shipping Cost'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpdateShippingDialog(Map<String, dynamic> orderData) {
    final estimatedShipping = (orderData['estimatedShipping'] ?? 0.0).toDouble();
    final shippingController = TextEditingController(text: estimatedShipping.toStringAsFixed(2));
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Shipping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated shipping: \$${estimatedShipping.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: shippingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Actual Shipping Cost',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'If more than 20% higher, buyer approval required',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final actualShipping = double.tryParse(shippingController.text);
              if (actualShipping == null || actualShipping < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid shipping cost')),
                );
                return;
              }

              final tracking = trackingController.text.trim();
              if (tracking.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a tracking number')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _updateShippingAndCapture(actualShipping, tracking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Ship'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateShippingAndCapture(double actualShipping, String trackingNumber) async {
    setState(() => _isUpdatingShipping = true);

    try {
      // First, update the shipping cost
      final updateShipping = FirebaseFunctions.instance.httpsCallable('update_shipping_cost');
      final updateResult = await updateShipping.call({
        'orderId': widget.orderId,
        'actualShipping': actualShipping,
      });

      final approvalRequired = updateResult.data['approvalRequired'] == true;

      if (approvalRequired) {
        // Buyer approval needed - show message and don't capture yet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shipping cost exceeds estimate. Waiting for buyer approval.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // No approval needed - capture payment
        setState(() => _isUpdatingShipping = false);

        final capturePayment = FirebaseFunctions.instance.httpsCallable('capture_payment');
        await capturePayment.call({
          'orderId': widget.orderId,
          'trackingNumber': trackingNumber,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment captured and item shipped!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to process shipping'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingShipping = false);
      }
    }
  }

  Widget _buildSellerItem(BuildContext context, CartItemDetailModel item, Map<String, dynamic> orderData) {
    final deliveryStatus = DeliveryStatus.fromValue(item.deliveryStatus);
    final isShipped = deliveryStatus == DeliveryStatus.shipped;
    final isDelivered = deliveryStatus == DeliveryStatus.delivered;
    final isAuthorized = orderData['paymentStatus'] == PaymentStatus.authorized.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _productImage(item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity} • \$${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),

                    // Tracking Number Display
                    if (isShipped && item.trackingNumber != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tracking: ${item.trackingNumber}',
                          style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Badge
              _buildStatusBadge(deliveryStatus),
            ],
          ),

          // Action Buttons - Only show for paid orders (not authorized - those use the banner)
          if (!isDelivered && !isAuthorized) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isShipped)
                  TextButton.icon(
                    onPressed: () => _showMarkAsShippedDialog(context, item),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('Mark as Shipped'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                if (isShipped && !isDelivered)
                  TextButton.icon(
                    onPressed: () => _markAsDelivered(context, item),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark as Delivered'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DeliveryStatus status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == DeliveryStatus.delivered) {
      statusColor = Colors.green;
      statusText = DeliveryStatus.delivered.displayText;
      statusIcon = Icons.check_circle;
    } else if (status == DeliveryStatus.shipped) {
      statusColor = Colors.blue;
      statusText = DeliveryStatus.shipped.displayText;
      statusIcon = Icons.local_shipping;
    } else {
      statusColor = Colors.orange;
      statusText = DeliveryStatus.pending.displayText;
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAsShippedDialog(BuildContext context, CartItemDetailModel item) {
    final trackingController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Shipped'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'Enter tracking number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (trackingController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a tracking number')),
                );
                return;
              }
              Navigator.pop(context);
              _updateItemStatus(context, item, 'shipped', trackingController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _markAsDelivered(BuildContext context, CartItemDetailModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: Text('Confirm that ${item.name} has been delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateItemStatus(context, item, 'delivered', null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItemStatus(
    BuildContext context,
    CartItemDetailModel item,
    String newStatus,
    String? trackingNumber,
  ) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      final orderDoc = await orderRef.get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

      // Update the specific item
      for (var i = 0; i < items.length; i++) {
        if (items[i]['productId'] == item.productId) {
          items[i]['deliveryStatus'] = newStatus;
          if (trackingNumber != null) {
            items[i]['trackingNumber'] = trackingNumber;
          }
          break;
        }
      }

      // Update Firestore
      await orderRef.update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _productImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 24, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}