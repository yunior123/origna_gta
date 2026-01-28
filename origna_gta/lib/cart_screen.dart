import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/cartitem_screen.dart';
import 'package:origna_gta/checkout_screen.dart';
import 'package:origna_gta/utils.dart';

// Optimized version - only rebuilds specific items when quantity changes
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view cart')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Your cart is empty'),
                    ],
                  ),
                );
              }

              final cartDocs = snapshot.data!.docs;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        final doc = cartDocs[index];
                        // Each item gets its own optimized widget
                        return _OptimizedCartItem(
                          userId: user.uid,
                          productId: doc.id,
                          initialQuantity: (doc.data() as Map<String, dynamic>)['quantity'] as int,
                        );
                      },
                    ),
                  ),
                  // Bottom summary uses a separate stream to calculate total
                  _CartSummary(userId: user.uid, cartDocs: cartDocs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Separate widget for each cart item - only this rebuilds when its quantity changes
class _OptimizedCartItem extends StatelessWidget {
  final String userId;
  final String productId;
  final int initialQuantity;

  const _OptimizedCartItem({
    required this.userId,
    required this.productId,
    required this.initialQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CartItemDetailModel?>(
      future: _fetchProductDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading...'),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return const SizedBox.shrink();
        }

        // Use StreamBuilder only for this specific item's quantity
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart')
              .doc(productId)
              .snapshots(),
          builder: (context, quantitySnapshot) {
            int currentQuantity = initialQuantity;
            
            if (quantitySnapshot.hasData && quantitySnapshot.data!.exists) {
              currentQuantity = (quantitySnapshot.data!.data() as Map<String, dynamic>)['quantity'] as int;
            }

            final updatedItem = item.copyWith(quantity: currentQuantity);

            return CartItemScreen(
              item: updatedItem.toMap(),
              onRemove: () => _updateQuantity(0),
              onQuantityChanged: (newQty) => _updateQuantity(newQty),
            );
          },
        );
      },
    );
  }

  Future<CartItemDetailModel?> _fetchProductDetails() async {
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
        
    if (!productDoc.exists) return null;

    final productModel = ProductModel.fromDocument(productDoc);
    return CartItemDetailModel(
      productId: productId,
      name: productModel.name,
      description: productModel.description,
      price: productModel.price,
      imageUrls: List<String>.from(productModel.imageUrls),
      quantity: initialQuantity,
      dateCreated: Timestamp.now(),
      sellerAddress: productModel.sellerAddress,
      sellerId: productModel.sellerId,
      deliveryStatus: "pending",
    );
  }

  Future<void> _updateQuantity(int newQty) async {
    final cartDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);

    if (newQty <= 0) {
      await cartDocRef.delete();
    } else {
      await cartDocRef.update({'quantity': newQty});
    }
  }
}

// Separate widget for cart summary - only rebuilds when cart changes
class _CartSummary extends StatelessWidget {
  final String userId;
  final List<QueryDocumentSnapshot> cartDocs;

  const _CartSummary({
    required this.userId,
    required this.cartDocs,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CartItemDetailModel>>(
      future: _fetchAllItemsWithDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data!;
        
        // Use StreamBuilder to react to quantity changes for total calculation
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart')
              .snapshots(),
          builder: (context, cartSnapshot) {
            double total = 0;
            
            if (cartSnapshot.hasData) {
              final currentQuantities = <String, int>{};
              for (var doc in cartSnapshot.data!.docs) {
                currentQuantities[doc.id] = (doc.data() as Map<String, dynamic>)['quantity'] as int;
              }
              
              total = items.fold<double>(0, (sum, item) {
                final quantity = currentQuantities[item.productId] ?? item.quantity;
                return sum + (item.price * quantity);
              });
            }

            final updatedItems = items.map((item) {
              final newQuantity = cartSnapshot.hasData
                  ? (cartSnapshot.data!.docs
                      .firstWhere((doc) => doc.id == item.productId,
                          orElse: () => throw Exception())
                      .data() as Map<String, dynamic>)['quantity'] as int? ?? item.quantity
                  : item.quantity;
              return item.copyWith(quantity: newQuantity);
            }).toList();

            return _buildBottomSummary(total, context, updatedItems);
          },
        );
      },
    );
  }

  Future<List<CartItemDetailModel>> _fetchAllItemsWithDetails() async {
    final futures = cartDocs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(doc.id)
          .get();
          
      if (!productDoc.exists) return null;

      final productModel = ProductModel.fromDocument(productDoc);
      return CartItemDetailModel(
        productId: doc.id,
        name: productModel.name,
        description: productModel.description,
        price: productModel.price,
        imageUrls: List<String>.from(productModel.imageUrls),
        quantity: data['quantity'] as int,
        dateCreated: data['dateCreated'] as Timestamp,
        sellerAddress: productModel.sellerAddress,
        sellerId: productModel.sellerId,
        deliveryStatus: "pending",
      );
    });

    final results = await Future.wait(futures);
    return results.whereType<CartItemDetailModel>().toList();
  }

  Container _buildBottomSummary(double total, BuildContext context, List<CartItemDetailModel> itemsWithDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                NumberFormat.currency(locale: "en_CA", symbol: "CAD \$").format(total),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(items: itemsWithDetails, total: total),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to add copyWith method to CartItemDetailModel
extension CartItemDetailModelExtension on CartItemDetailModel {
  CartItemDetailModel copyWith({
    String? productId,
    String? name,
    String? description,
    double? price,
    List<String>? imageUrls,
    int? quantity,
    Timestamp? dateCreated,
    Address? sellerAddress,
    String? sellerId,
    String? deliveryStatus,
  }) {
    return CartItemDetailModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      dateCreated: dateCreated ?? this.dateCreated,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerId: sellerId ?? this.sellerId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}