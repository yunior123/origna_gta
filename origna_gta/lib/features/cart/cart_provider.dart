import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// CART PROVIDERS
// ============================================================================

/// Stream of cart items for current user
/// Uses Firestore snapshots for real-time updates when cart changes
final cartItemsProvider = StreamProvider.autoDispose<List<CartItemModel>>((ref) {
  final userId = ref.watch(userIdProvider);

  // Return empty stream immediately if no user
  if (userId == null) {
    return Stream.value([]);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .collection('cart')
      .snapshots()
      .handleError((error) {
        debugPrint('Error in cart stream: $error');
        // Return empty list on error to prevent UI issues
      })
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return CartItemModel.fromMap(doc.data());
          } catch (e) {
            debugPrint('Error parsing cart item: $e');
            // Return a placeholder item to prevent crashes
            return CartItemModel(
              productId: doc.id,
              quantity: 0,
              dateCreated: Timestamp.now(),
            );
          }
        }).where((item) => item.quantity > 0).toList();
      });
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

    try {
      final cartRef = _firestore.collection('users').doc(userId).collection('cart');
      final snapshot = await cartRef.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('Cart is already empty');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cart cleared successfully');

      // Force refresh the cart provider to ensure UI updates
      _ref.invalidate(cartItemsProvider);
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  /// Force refresh cart state - call this after external cart modifications
  void refreshCart() {
    _ref.invalidate(cartItemsProvider);
  }
}

// ============================================================================
// CART DETAILS PROVIDER (with product info) - BATCH FETCH
// ============================================================================

/// Fetches cart items with full product details using batch fetch
final cartWithDetailsProvider = FutureProvider.autoDispose<List<CartItemDetailModel>>((ref) async {
  final cartItems = ref.watch(cartItemsProvider);
  final firestore = ref.watch(firestoreProvider);

  return cartItems.when(
    data: (items) async {
      if (items.isEmpty) return [];

      final productIds = items.map((i) => i.productId).toList();
      final List<CartItemDetailModel> results = [];

      // Batch fetch products using whereIn (Firestore limit is 30 per query)
      for (var i = 0; i < productIds.length; i += 30) {
        final batch = productIds.skip(i).take(30).toList();
        final snapshot = await firestore.collection('products').where(FieldPath.documentId, whereIn: batch).get();

        // Create a map for O(1) lookup
        final productMap = {for (var doc in snapshot.docs) doc.id: doc};

        // Match products with cart items in original batch order
        for (final productId in batch) {
          final productDoc = productMap[productId];
          if (productDoc != null && productDoc.exists) {
            final cartItem = items.firstWhere((item) => item.productId == productId);
            final productData = productDoc.data();

            results.add(
              CartItemDetailModel(
                productId: productId,
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
      }

      return results;
    },
    loading: () => [],
    error: (e, st) => [],
  );
});

/// Cart subtotal - computed from cartWithDetailsProvider
final cartSubtotalProvider = Provider<double>((ref) {
  final cartDetails = ref.watch(cartWithDetailsProvider);
  return cartDetails.maybeWhen(data: (items) => items.fold(0.0, (total, item) => total + (item.price * item.quantity)), orElse: () => 0.0);
});

// ============================================================================
// SINGLE CART ITEM DETAIL PROVIDER (Family)
// ============================================================================

/// Family provider for individual cart item details - cached by Riverpod
final cartItemDetailProvider = FutureProvider.autoDispose.family<CartItemDetailModel?, String>((ref, productId) async {
  final firestore = ref.watch(firestoreProvider);
  final cartItems = ref.watch(cartItemsProvider).valueOrNull ?? [];

  final cartItem = cartItems.where((i) => i.productId == productId).firstOrNull;
  if (cartItem == null) return null;

  final productDoc = await firestore.collection('products').doc(productId).get();
  if (!productDoc.exists) return null;

  final productData = productDoc.data()!;
  return CartItemDetailModel(
    productId: productId,
    name: productData['name'] ?? '',
    description: productData['description'] ?? '',
    price: (productData['price'] ?? 0).toDouble(),
    imageUrls: List<String>.from(productData['imageUrls'] ?? []),
    quantity: cartItem.quantity,
    dateCreated: cartItem.dateCreated,
    sellerAddress: Address.fromMap(productData['sellerAddress'] ?? {}),
    sellerId: productData['sellerId'] ?? '',
    deliveryStatus: 'pending',
  );
});

/// Provider that returns the current quantity for a specific product in cart
final cartItemQuantityProvider = Provider.autoDispose.family<int, String>((ref, productId) {
  final cartItems = ref.watch(cartItemsProvider).valueOrNull ?? [];
  final cartItem = cartItems.where((i) => i.productId == productId).firstOrNull;
  return cartItem?.quantity ?? 0;
});
