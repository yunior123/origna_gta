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

  /// Returns the cart subcollection reference using the bare record ID
  /// (stripping any collection prefix like "users:") so it matches the
  /// SurrealDB parent_id filter format: `users:<bareId>`.
  SubcollectionRef _cartRef(String userId) {
    final bareId = userId.contains(':') ? userId.split(':').last : userId;
    return _ob
        .collection(Collections.users)
        .subcollection(bareId, Collections.cart);
  }

  /// Adds [quantity] units of [productId] to the user's cart.
  ///
  /// Verifies stock availability before mutation. Uses deterministic doc IDs
  /// (`productId` or `productId_variantId`) to prevent duplicates without
  /// client-side transactions.
  ///
  /// Throws [NotFoundException] if product doesn't exist.
  /// Throws [ConflictException] if insufficient stock.
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

    // Verify product stock before mutating cart
    final productDoc = await _ob
        .collection(Collections.products)
        .doc(productId)
        .get();
    if (productDoc == null || !productDoc.exists) {
      throw NotFoundException('Product not found', statusCode: 404);
    }
    final stockQuantity =
        (productDoc.get<num>(Fields.stockQuantity))?.toInt() ?? 0;
    if (stockQuantity < quantity) {
      throw ConflictException(
        stockQuantity == 0
            ? 'This product is out of stock'
            : 'Only $stockQuantity items available in stock',
        statusCode: 409,
      );
    }

    final cartRef = _cartRef(userId);
    final docId = variantId != null ? '${productId}_$variantId' : productId;

    // Read-then-write: OrignaBase does not have client-side transactions yet.
    // Use deterministic doc ID to avoid duplicates.
    final existing = await cartRef.doc(docId).get();
    final bareUserId = userId.contains(':') ? userId.split(':').last : userId;
    // Reconstruct full userId for rule check: auth.uid == incoming.userId.
    // auth.uid = JWT sub = 'users:bareId'. incoming.userId must match.
    final fullUserId = userId.contains(':')
        ? userId
        : '${Collections.users}:$userId';
    final parentId = '${Collections.users}:$bareUserId';

    // Compute quantity: accumulate if valid existing doc (has parent_id from this user).
    final bool hasValidExisting =
        existing != null &&
        existing.exists &&
        existing.data['parent_id'] == parentId;
    final currentQty = hasValidExisting
        ? (existing.get<num>(Fields.quantity))?.toInt() ?? 0
        : 0;
    final newQty = (currentQty + quantity).clamp(
      minCartItemQuantity,
      maxCartItemQuantity,
    );

    // Always use set (upsert) to ensure parent_id and userId are written.
    // update() would 403 on stale docs that lack userId/parent_id.
    final data = <String, dynamic>{
      ...CartModel(
        productId: productId,
        quantity: newQty,
        createdAt: hasValidExisting
            ? (CartItemModel.fromMap(existing.data, docId: docId).createdAt)
            : DateTime.now(),
        variantId: variantId,
        variantTitle: variantTitle,
        variantOptions: variantOptions,
        variantSku: variantSku,
      ).toMap(),
      // userId required by cart create rule: auth.uid == incoming.userId.
      Fields.userId: fullUserId,
      // parent_id required by SubcollectionRef.get() which filters by it.
      // doc().set() does not inject parent_id automatically (only add() does).
      // Must match SubcollectionRef._parentFilterValue = '$parentCollection:$parentId'.
      'parent_id': parentId,
    };
    await cartRef.doc(docId).set(data);
  }

  /// Deletes all cart items for [userId] using a batch operation.
  ///
  /// Extracts bare record IDs from the full document paths before deletion.
  @override
  Future<void> clearCart(String userId) async {
    final cartRef = _cartRef(userId);
    final snapshot = await cartRef.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _ob.batch();
    final collectionName = '${Collections.users}__${Collections.cart}';
    for (final doc in snapshot.docs) {
      // doc.id is the full record path e.g. "users__cart:itemId".
      // batch.delete expects only the bare record ID part.
      final bareId = doc.id.contains(':') ? doc.id.split(':').last : doc.id;
      batch.delete(collectionName, bareId);
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
  Future<void> updateBuyerNote(
    String userId,
    String cartItemId,
    String? note,
  ) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (note == null) {
      await cartItemRef.update({Fields.buyerNote: FieldValue.delete()});
    } else {
      // Merge-style update: only set the buyerNote field
      await cartItemRef.update({Fields.buyerNote: note});
    }
  }

  @override
  Future<void> updateQuantity(
    String userId,
    String cartItemId,
    int quantity,
  ) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
    } else {
      await cartItemRef.update({
        Fields.quantity: quantity.clamp(
          minCartItemQuantity,
          maxCartItemQuantity,
        ),
      });
    }
  }

  /// Real-time stream of cart items for [userId], sorted by creation date.
  ///
  /// Emits the full cart on initial load, then incrementally applies
  /// create/update/delete changes from OrignaBase realtime subscriptions.
  /// Items with quantity <= 0 are filtered out.
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
