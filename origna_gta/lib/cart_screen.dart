import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/cartitem_screen.dart';
import 'package:origna_gta/checkout_screen.dart';
import 'package:origna_gta/utils.dart';

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
          child: StreamBuilder<DocumentSnapshot>(
            // Stream the specific user document
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<dynamic> cartData = snapshot.data!.get('cart') ?? [];
              final List<CartItemModel> cartItems = cartData.map((e) => CartItemModel.fromMap(e as Map<String, dynamic>)).toList();
              if (cartItems.isEmpty) {
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

              return FutureBuilder<List<CartItemDetailModel>>(
                future: _fetchCartItemsWithDetails(cartItems),
                builder: (context, AsyncSnapshot<List<CartItemDetailModel>> productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<CartItemDetailModel> itemsWithDetails = productSnapshot.data ?? [];

                  if (itemsWithDetails.isEmpty) {
                    return const Center(child: Text("Cart items unavailable"));
                  }

                  final total = itemsWithDetails.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

                  return Column(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            return ListView.builder(
                              itemCount: productSnapshot.data!.length,
                              itemBuilder: (context, index) {
                                final item = productSnapshot.data![index];
                                return CartItem(
                                  item: item.toMap(),
                                  onRemove: () => _updateQuantity(user.uid, item.toMap()['productId'], 0),
                                  onQuantityChanged: (newQty) => _updateQuantity(user.uid, item.toMap()['productId'], newQty),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
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
                                  // Using NumberFormat for localized Canadian currency
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
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<CartItemDetailModel>> _fetchCartItemsWithDetails(List<CartItemModel> cartItems) async {
    final itemsWithDetails = <CartItemDetailModel>[];

    // Use Future.wait to fetch all product data in parallel for better performance
    final detailFutures = cartItems.map((item) async {
      final productId = item.productId;
      final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      final productModel = ProductModel.fromDocument(productDoc);

      if (productDoc.exists) {
        return CartItemDetailModel(
          productId: productId,
          name: productModel.name,
          price: productModel.price,
          imageUrls: List<String>.from(productModel.imageUrls ),
          quantity: item.quantity,
          dateCreated: item.dateCreated,
          sellerAddress: productModel.sellerAddress,
          sellerId: productModel.sellerId,
          
        );
      }
      return null;
    });

    final results = await Future.wait(detailFutures);

    // Filter out nulls (in case a product was deleted from the database)
    for (var res in results) {
      if (res != null) itemsWithDetails.add(res);
    }

    return itemsWithDetails;
  }

  // Helper method to handle quantity changes in the array
  Future<void> _updateQuantity(String uid, String pid, int newQty) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final List<Map<String, dynamic>> cart = List<Map<String, dynamic>>.from(snapshot.get('cart'));

      if (newQty <= 0) {
        cart.removeWhere((item) => item['productId'] == pid);
      } else {
        int idx = cart.indexWhere((item) => item['productId'] == pid);
        if (idx != -1) cart[idx]['quantity'] = newQty;
      }

      transaction.update(docRef, {'cart': cart});
    });
  }
}