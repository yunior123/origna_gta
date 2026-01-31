import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class CartRepository {
  Stream<List<CartItemModel>> watchCart(String userId);
  Future<void> addToCart(String userId, String productId, int quantity);
  Future<void> updateQuantity(String userId, String productId, int quantity);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> clearCart(String userId);
}

class FirebaseCartRepository implements CartRepository {
  final FirebaseFirestore _firestore;
  static const int maxCartItemQuantity = 99;
  static const int minCartItemQuantity = 1;

  FirebaseCartRepository(this._firestore);

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => CartItemModel.fromMap(doc.data())).where((item) => item.quantity > 0).toList();
        });
  }

  @override
  Future<void> addToCart(String userId, String productId, int quantity) async {
    if (quantity < minCartItemQuantity) return;
    final cartItemRef = _firestore.collection('users').doc(userId).collection('cart').doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(cartItemRef);

      if (snapshot.exists) {
        int currentQty = snapshot.data()?['quantity'] ?? 0;
        int newQty = (currentQty + quantity).clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.update(cartItemRef, {'quantity': newQty});
      } else {
        final clampedQty = quantity.clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.set(cartItemRef, CartModel(productId: productId, quantity: clampedQty, dateCreated: DateTime.now()).toMap());
      }
    });
  }

  @override
  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    final cartItemRef = _firestore.collection('users').doc(userId).collection('cart').doc(productId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({'quantity': quantity.clamp(minCartItemQuantity, maxCartItemQuantity)});
    }
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    await _firestore.collection('users').doc(userId).collection('cart').doc(productId).delete();
  }

  @override
  Future<void> clearCart(String userId) async {
    final cartRef = _firestore.collection('users').doc(userId).collection('cart');
    final snapshot = await cartRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
