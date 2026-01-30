import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// CART PROVIDERS
// ============================================================================

/// Stream of cart items for current user
final cartItemsProvider = StreamProvider.autoDispose<List<CartItemModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .collection('cart')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CartItemModel.fromMap(doc.data())).toList());
});

/// Cart item count for badge display
final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(data: (items) => items.fold(0, (total, item) => total + item.quantity), orElse: () => 0);
});

/// Cart controller for mutations
final cartControllerProvider = Provider<CartController>((ref) {
  return CartController(ref);
});

class CartController {
  final Ref _ref;

  CartController(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Add item to cart (or increment quantity if exists)
  Future<bool> addToCart(String productId, int quantity) async {
    final userId = _userId;
    if (userId == null) return false;

    final cartItemRef = _firestore.collection('users').doc(userId).collection('cart').doc(productId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(cartItemRef);

        if (snapshot.exists) {
          int currentQty = snapshot.data()?['quantity'] ?? 0;
          transaction.update(cartItemRef, {'quantity': currentQty + quantity});
        } else {
          transaction.set(cartItemRef, CartModel(productId: productId, quantity: quantity, dateCreated: DateTime.now()).toMap());
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String productId, int newQuantity) async {
    final userId = _userId;
    if (userId == null) return;

    final cartItemRef = _firestore.collection('users').doc(userId).collection('cart').doc(productId);

    if (newQuantity <= 0) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({'quantity': newQuantity});
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    final userId = _userId;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).collection('cart').doc(productId).delete();
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    final userId = _userId;
    if (userId == null) return;

    final cartRef = _firestore.collection('users').doc(userId).collection('cart');

    final snapshot = await cartRef.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// ============================================================================
// CART DETAILS PROVIDER (with product info)
// ============================================================================

/// Fetches cart items with full product details
final cartWithDetailsProvider = FutureProvider.autoDispose<List<CartItemDetailModel>>((ref) async {
  final cartItems = ref.watch(cartItemsProvider);
  final firestore = ref.watch(firestoreProvider);

  return cartItems.when(
    data: (items) async {
      if (items.isEmpty) return [];

      final List<CartItemDetailModel> detailedItems = [];

      for (final cartItem in items) {
        final productDoc = await firestore.collection('products').doc(cartItem.productId).get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          detailedItems.add(
            CartItemDetailModel(
              productId: cartItem.productId,
              name: productData['name'] ?? '',
              description: productData['description'] ?? '',
              price: (productData['price'] ?? 0).toDouble(),
              imageUrls: List<String>.from(productData['imageUrls'] ?? []),
              quantity: cartItem.quantity,
              dateCreated: cartItem.dateCreated,
              sellerAddress: Address.fromMap(productData['sellerAddress'] ?? {}),
              sellerId: productData['sellerId'] ?? '',
              deliveryStatus: 'pending',
            ),
          );
        }
      }

      return detailedItems;
    },
    loading: () => [],
    error: (e, st) => [],
  );
});

/// Cart subtotal
final cartSubtotalProvider = Provider<double>((ref) {
  final cartDetails = ref.watch(cartWithDetailsProvider);
  return cartDetails.maybeWhen(data: (items) => items.fold(0.0, (total, item) => total + (item.price * item.quantity)), orElse: () => 0.0);
});
