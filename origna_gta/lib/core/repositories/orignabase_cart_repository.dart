// coverage:ignore-file
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

/// OrignaBase implementation of [CartRepository].
///
/// Cart items are stored as a subcollection: users/{userId}/cart/{docId}.
/// Document IDs are deterministic: `productId` or `productId_variantId`.
class OrignaBaseCartRepository implements CartRepository {
  static const int maxCartItemQuantity = 99;
  static const int minCartItemQuantity = 1;

  final OrignaBase _ob;

  OrignaBaseCartRepository(this._ob);

  SubcollectionRef _cartRef(String userId) =>
      _ob.collection(Collections.users).subcollection(userId, Collections.cart);

  @override
  Future<void> addToCart(
    String userId,
    String productId,
    int quantity, {
    String? variantId,
    String? variantTitle,
    Map<String, String>? variantOptions,
    String? variantSku,
  }) async {
    if (quantity < minCartItemQuantity) return;
    final cartRef = _cartRef(userId);
    final docId = variantId != null ? '${productId}_$variantId' : productId;

    // Read-then-write: OrignaBase does not have client-side transactions yet.
    // Use deterministic doc ID to avoid duplicates.
    final existing = await cartRef.doc(docId).get();

    if (existing != null && existing.exists) {
      final currentQty = (existing.get<num>(Fields.quantity))?.toInt() ?? 0;
      final newQty = (currentQty + quantity).clamp(minCartItemQuantity, maxCartItemQuantity);
      await cartRef.doc(docId).update({Fields.quantity: newQty});
    } else {
      final clampedQty = quantity.clamp(minCartItemQuantity, maxCartItemQuantity);
      final data = CartModel(
        productId: productId,
        quantity: clampedQty,
        createdAt: DateTime.now(),
        variantId: variantId,
        variantTitle: variantTitle,
        variantOptions: variantOptions,
        variantSku: variantSku,
      ).toMap();
      await cartRef.doc(docId).set(data);
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    final cartRef = _cartRef(userId);
    final snapshot = await cartRef.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _ob.batch();
    for (final doc in snapshot.docs) {
      batch.delete('${Collections.users}/$userId/${Collections.cart}', doc.id);
    }
    await batch.commit();
  }

  @override
  Future<String?> getProductSellerId(String productId) async {
    final doc = await _ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return null;
    return doc.get<String>(Fields.sellerId);
  }

  @override
  Future<bool> isVariantValid(String productId, String variantId) async {
    final doc = await _ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return false;
    final variants = (doc.data[Fields.variants] as List<dynamic>?) ?? [];
    return variants.any((v) {
      final map = v as Map<String, dynamic>?;
      return map != null &&
          map[Fields.variantId] == variantId &&
          (map['isActive'] as bool? ?? true);
    });
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    await _cartRef(userId).doc(cartItemId).delete();
  }

  @override
  Future<void> updateBuyerNote(String userId, String cartItemId, String? note) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (note == null) {
      await cartItemRef.update({Fields.buyerNote: FieldValue.delete()});
    } else {
      // Merge-style update: only set the buyerNote field
      await cartItemRef.update({Fields.buyerNote: note});
    }
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({
        Fields.quantity: quantity.clamp(minCartItemQuantity, maxCartItemQuantity),
      });
    }
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return (() async* {
      final cartRef = _cartRef(userId);
      final state = <String, CartItemModel>{};

      final initial = await cartRef.get();
      for (final doc in initial.docs) {
        final item = CartItemModel.fromMap(doc.data, docId: doc.id);
        if (item.quantity > 0) {
          state[doc.id] = item;
        }
      }
      yield _sortedCartItems(state);

      await for (final change in cartRef.snapshots()) {
        final item = CartItemModel.fromMap(
          change.document.data,
          docId: change.document.id,
        );

        if (!change.document.exists || item.quantity <= 0) {
          state.remove(change.document.id);
        } else {
          state[change.document.id] = item;
        }

        yield _sortedCartItems(state);
      }
    })();
  }

  List<CartItemModel> _sortedCartItems(Map<String, CartItemModel> state) {
    final items = state.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }
}
