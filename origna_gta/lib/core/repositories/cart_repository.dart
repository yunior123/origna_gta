import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class CartRepository {
  Future<void> addToCart(String userId, String productId, int quantity, {
    String? variantId,
    String? variantTitle,
    Map<String, String>? variantOptions,
    String? variantSku,
  });
  Future<void> clearCart(String userId);

  /// Fetch the seller ID for a product to prevent self-purchase.
  /// Returns null if the product does not exist.
  Future<String?> getProductSellerId(String productId);
  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> updateBuyerNote(String userId, String cartItemId, String? note);
  Future<void> updateQuantity(String userId, String cartItemId, int quantity);

  Stream<List<CartItemModel>> watchCart(String userId);
}

class FirebaseCartRepository implements CartRepository {
  static const int maxCartItemQuantity = 99;
  static const int minCartItemQuantity = 1;
  final FirebaseFirestore _firestore;

  FirebaseCartRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _cartRef(String userId) =>
      _firestore.collection(Collections.users).doc(userId).collection(Collections.cart);

  @override
  Future<void> addToCart(String userId, String productId, int quantity, {
    String? variantId,
    String? variantTitle,
    Map<String, String>? variantOptions,
    String? variantSku,
  }) async {
    if (quantity < minCartItemQuantity) return;
    final cartRef = _cartRef(userId);

    await _firestore.runTransaction((transaction) async {
      // Query for existing productId+variantId combo
      Query<Map<String, dynamic>> query = cartRef.where(Fields.productId, isEqualTo: productId);
      if (variantId != null) {
        query = query.where(Fields.variantId, isEqualTo: variantId);
      }
      final existing = await query.get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentQty = (doc.data()[Fields.quantity] as num?)?.toInt() ?? 0;
        final newQty = (currentQty + quantity).clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.update(doc.reference, {Fields.quantity: newQty});
      } else {
        final newDocRef = cartRef.doc(); // Auto-generated ID
        final clampedQty = quantity.clamp(minCartItemQuantity, maxCartItemQuantity);
        transaction.set(newDocRef, CartModel(
          productId: productId,
          quantity: clampedQty,
          createdAt: DateTime.now(),
          variantId: variantId,
          variantTitle: variantTitle,
          variantOptions: variantOptions,
          variantSku: variantSku,
        ).toMap());
      }
    });
  }

  @override
  Future<void> clearCart(String userId) async {
    final cartRef = _cartRef(userId);
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
  Future<void> removeFromCart(String userId, String cartItemId) async {
    await _cartRef(userId).doc(cartItemId).delete();
  }

  @override
  Future<void> updateBuyerNote(String userId, String cartItemId, String? note) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (note == null) {
      await cartItemRef.update({Fields.buyerNote: FieldValue.delete()}).catchError((_) {});
    } else {
      await cartItemRef.set({Fields.buyerNote: note}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({Fields.quantity: quantity.clamp(minCartItemQuantity, maxCartItemQuantity)});
    }
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return _cartRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data(), docId: doc.id))
          .where((item) => item.quantity > 0)
          .toList();
    });
  }
}
