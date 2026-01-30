import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:origna_gta/cartitem_screen.dart';
import 'package:origna_gta/checkout_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

// Optimized version using Riverpod
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view cart')));
    }

    final cartItemsAsync = ref.watch(cartItemsProvider);

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Shopping Cart'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: cartItemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (cartItems) {
              if (cartItems.isEmpty) {
                return const AnimatedEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  subtitle: 'Add items to get started',
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * index),
                          child: _OptimizedCartItem(
                            productId: cartItem.productId,
                            initialQuantity: cartItem.quantity,
                          ),
                        );
                      },
                    ),
                  ),
                  FadeSlideIn(
                    delay: Duration(milliseconds: 50 * cartItems.length),
                    beginOffset: const Offset(0, 0.2),
                    child: _CartSummary(cartItems: cartItems),
                  ),
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
class _OptimizedCartItem extends ConsumerWidget {
  final String productId;
  final int initialQuantity;

  const _OptimizedCartItem({
    required this.productId,
    required this.initialQuantity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartController = ref.read(cartControllerProvider);
    
    return FutureBuilder<CartItemDetailModel?>(
      future: _fetchProductDetails(ref),
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

        // Watch cart items to get current quantity
        final cartItems = ref.watch(cartItemsProvider).valueOrNull ?? [];
        final currentQuantity = cartItems
            .firstWhere((i) => i.productId == productId, orElse: () => CartItemModel(productId: productId, quantity: initialQuantity, dateCreated: Timestamp.now()))
            .quantity;

        final updatedItem = item.copyWith(quantity: currentQuantity);

        return CartItemScreen(
          item: updatedItem.toMap(),
          onRemove: () => cartController.removeFromCart(productId),
          onQuantityChanged: (newQty) => cartController.updateQuantity(productId, newQty),
        );
      },
    );
  }

  Future<CartItemDetailModel?> _fetchProductDetails(WidgetRef ref) async {
    final firestore = ref.read(firestoreProvider);
    final productDoc = await firestore.collection('products').doc(productId).get();
        
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
}

// Separate widget for cart summary - uses computed provider
class _CartSummary extends ConsumerWidget {
  final List<CartItemModel> cartItems;

  const _CartSummary({required this.cartItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartDetailsAsync = ref.watch(cartWithDetailsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return cartDetailsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (itemsWithDetails) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat.currency(locale: "en_CA", symbol: "CAD \$").format(subtotal),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: itemsWithDetails.isEmpty ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(items: itemsWithDetails, total: subtotal),
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
      },
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