import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class CartRepository {
  Future<void> addToCart(String userId, String productId, int quantity);
  Future<void> clearCart(String userId);

  /// Fetch the seller ID for a product to prevent self-purchase.
  /// Returns null if the product does not exist.
  Future<String?> getProductSellerId(String productId);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> updateBuyerNote(String userId, String productId, String? note);
  Future<void> updateQuantity(String userId, String productId, int quantity);

  Stream<List<CartItemModel>> watchCart(String userId);
}

class FirebaseCartRepository implements CartRepository {
  static const int maxCartItemQuantity = 99;
  static const int minCartItemQuantity = 1;
  final FirebaseFirestore _firestore;

  FirebaseCartRepository(this._firestore);

  @override
  Future<void> addToCart(String userId, String productId, int quantity) async {
    if (quantity < minCartItemQuantity) return;
    final cartItemRef = _firestore.collection(Collections.users).doc(userId).collection(Collections.cart).doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(cartItemRef);

      if (snapshot.exists) {
        int currentQty = snapshot.data()?[Fields.quantity] ?? 0;
        int newQty = (currentQty + quantity).clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.update(cartItemRef, {Fields.quantity: newQty});
      } else {
        final clampedQty = quantity.clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.set(cartItemRef, CartModel(productId: productId, quantity: clampedQty, createdAt: DateTime.now()).toMap());
      }
    });
  }

  @override
  Future<void> clearCart(String userId) async {
    final cartRef = _firestore.collection(Collections.users).doc(userId).collection(Collections.cart);
    final snapshot = await cartRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<String?> getProductSellerId(String productId) async {
    final productDoc = await _firestore.collection(Collections.products).doc(productId).get();
    if (!productDoc.exists) return null;
    return productDoc.data()?[Fields.sellerId] as String?;
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    await _firestore.collection(Collections.users).doc(userId).collection(Collections.cart).doc(productId).delete();
  }

  @override
  Future<void> updateBuyerNote(String userId, String productId, String? note) async {
    final cartItemRef = _firestore.collection(Collections.users).doc(userId).collection(Collections.cart).doc(productId);
    if (note == null) {
      await cartItemRef.update({Fields.buyerNote: FieldValue.delete()}).catchError((_) {});
    } else {
      await cartItemRef.set({Fields.buyerNote: note}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateQuantity(String userId, String productId, int quantity) async {
    final cartItemRef = _firestore.collection(Collections.users).doc(userId).collection(Collections.cart).doc(productId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({Fields.quantity: quantity.clamp(minCartItemQuantity, maxCartItemQuantity)});
    }
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return _firestore.collection(Collections.users).doc(userId).collection(Collections.cart).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItemModel.fromMap(doc.data())).where((item) => item.quantity > 0).toList();
    });
  }
}
