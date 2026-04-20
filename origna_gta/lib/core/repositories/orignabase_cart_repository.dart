import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

/// OrignaBase implementation of [CartRepository].
///
/// This repository manages the buyer's shopping cart using OrignaBase subcollections.
/// Cart items are stored under `users/{userId}/cart/{docId}`, where `docId` is
/// deterministic (either the product ID or `productId_variantId`).
///
/// Deterministic IDs allow for simple upserts and prevent duplicate entries for
/// the same product/variant without requiring complex transactional logic.
class OrignaBaseCartRepository implements CartRepository {
  /// Maximum quantity allowed for a single cart item.
  static const int maxCartItemQuantity = 99;

  /// Minimum quantity allowed for a cart item (quantities < 1 trigger removal).
  static const int minCartItemQuantity = 1;

  final OrignaBase _ob;

  /// Creates a new instance of [OrignaBaseCartRepository].
  OrignaBaseCartRepository(this._ob);

  Never _throwStockConflict({
    required int availableStock,
    required int currentQty,
    required int requestedQty,
  }) {
    if (availableStock <= 0) {
      throw ConflictException('This product is out of stock', statusCode: 409);
    }

    if (currentQty > 0) {
      throw ConflictException(
        'Only $availableStock items available (you already have $currentQty in your cart)',
        statusCode: 409,
      );
    }

    throw ConflictException(
      requestedQty > maxCartItemQuantity
          ? 'Cart item quantity cannot exceed $maxCartItemQuantity'
          : 'Only $availableStock items available in stock',
      statusCode: 409,
    );
  }

  /// Returns the cart subcollection reference for a specific user.
  ///
  /// Normalizes the [userId] to its bare record ID to match the PostgreSQL
  /// parent_id filter format (`users:<bareId>`).
  SubcollectionRef _cartRef(String userId) {
    final bareId = userId.contains(':') ? userId.split(':').last : userId;
    return _ob
        .collection(Collections.users)
        .subcollection(bareId, Collections.cart);
  }

  /// Adds a specified quantity of a product (or variant) to the user's cart.
  ///
  /// Parameters:
  /// - [userId]: the ID of the buyer.
  /// - [productId]: the ID of the product to add.
  /// - [quantity]: number of units to add.
  /// - [variantId]: optional ID of the product variant.
  ///
  /// This method performs several steps:
  /// 1. Verifies that the product exists and has sufficient stock.
  /// 2. Checks if the item already exists in the cart.
  /// 3. Increments the quantity if it exists, or creates a new entry if not.
  ///
  /// Throws:
  /// - [NotFoundException] if the product does not exist.
  /// - [ConflictException] if the requested quantity exceeds available stock.
  ///
  /// Gotchas:
  /// - Uses a read-then-write pattern since the SDK does not yet support
  ///   client-side transactions.
  /// - Explicitly sets the `parent_id` and `userId` fields to satisfy backend
  ///   security rules and subcollection filtering requirements.
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

    // Verify product exists
    final productDoc = await _ob
        .collection(Collections.products)
        .doc(productId)
        .get();
    if (productDoc == null || !productDoc.exists) {
      throw NotFoundException('Product not found', statusCode: 404);
    }

    // Determine available stock (variant-level if applicable)
    int availableStock;
    if (variantId != null) {
      final variants =
          (productDoc.data[Fields.variants] as List?)?.cast<dynamic>() ?? [];
      final matchingVariant = variants.cast<Map<String, dynamic>>().firstWhere(
        (v) => v[Fields.variantId] == variantId,
        orElse: () => <String, dynamic>{},
      );
      if (matchingVariant.isEmpty) {
        throw NotFoundException(
          'Variant $variantId not found for product $productId',
          statusCode: 404,
        );
      }
      availableStock =
          (matchingVariant[Fields.stockQuantity] as num?)?.toInt() ??
          (productDoc.get<num>(Fields.stockQuantity))?.toInt() ??
          0;
    } else {
      availableStock =
          (productDoc.get<num>(Fields.stockQuantity))?.toInt() ?? 0;
    }

    final imageUrls = List<String>.from(
      productDoc.data[Fields.imageUrls] as Iterable? ?? const <String>[],
    );
    final priceSnapshot = (productDoc.get<num>(Fields.priceCents))?.toInt();

    // Read existing cart entry to compute total requested quantity
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
        existing.data[Fields.parentId] == parentId;
    final currentQty = hasValidExisting
        ? (existing.get<num>(Fields.quantity))?.toInt() ?? 0
        : 0;

    // Stock check must account for quantity already in cart
    final totalRequested = currentQty + quantity;
    final effectiveCap = availableStock < maxCartItemQuantity
        ? availableStock
        : maxCartItemQuantity;
    if (availableStock < totalRequested ||
        totalRequested > maxCartItemQuantity) {
      _throwStockConflict(
        availableStock: effectiveCap,
        currentQty: currentQty,
        requestedQty: totalRequested,
      );
    }

    // Always use set (upsert) to ensure parent_id and userId are written.
    // update() would 403 on stale docs that lack userId/parent_id.
    if (hasValidExisting) {
      await cartRef.doc(docId).update({
        Fields.quantity: FieldValue.increment(quantity),
        Fields.priceSnapshot: priceSnapshot,
        ...?variantId == null ? null : {Fields.variantId: variantId},
        ...?variantTitle == null ? null : {Fields.variantTitle: variantTitle},
        ...?variantOptions == null
            ? null
            : {Fields.variantOptions: variantOptions},
        ...?variantSku == null ? null : {Fields.variantSku: variantSku},
      });

      final updated = await cartRef.doc(docId).get();
      final updatedQty = (updated?.get<num>(Fields.quantity))?.toInt() ?? 0;
      if (updatedQty > effectiveCap) {
        await cartRef.doc(docId).update({Fields.quantity: effectiveCap});
        _throwStockConflict(
          availableStock: effectiveCap,
          currentQty: currentQty,
          requestedQty: updatedQty,
        );
      }
      return;
    }

    final data = <String, dynamic>{
      ...CartModel(
        productId: productId,
        quantity: quantity,
        createdAt: DateTime.now(),
        variantId: variantId,
        variantTitle: variantTitle,
        variantOptions: variantOptions,
        variantSku: variantSku,
        priceSnapshot: priceSnapshot,
        productName: productDoc.get<String>(Fields.name),
        productDescription: productDoc.get<String>(Fields.description),
        imageUrls: imageUrls,
      ).toMap(),
      // userId required by cart create rule: auth.uid == incoming.userId.
      Fields.userId: fullUserId,
      // parent_id required by SubcollectionRef.get() which filters by it.
      // doc().set() does not inject parent_id automatically (only add() does).
      // Must match SubcollectionRef._parentFilterValue = '$parentCollection:$parentId'.
      Fields.parentId: parentId,
    };
    await cartRef.doc(docId).set(data);
  }

  /// Removes all items from the user\'s cart using a batch deletion.
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

  /// Returns the ID of the seller for a specific product.
  @override
  Future<String?> getProductSellerId(String productId) async {
    final doc = await _ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return null;
    return doc.get<String>(Fields.sellerId);
  }

  /// Validates whether a specific variant is active and exists for a product.
  @override
  Future<bool> isVariantValid(String productId, String variantId) async {
    final doc = await _ob.collection(Collections.products).doc(productId).get();
    if (doc == null || !doc.exists) return false;
    final variants = (doc.data[Fields.variants] as List<dynamic>?) ?? [];
    return variants.any((v) {
      final map = v as Map<String, dynamic>?;
      return map != null &&
          map[Fields.variantId] == variantId &&
          (map['active'] as bool? ?? true);
    });
  }

  /// Removes a single item from the cart.
  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    await _cartRef(userId).doc(cartItemId).delete();
  }

  /// Updates the optional buyer note for a cart item.
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

  /// Updates the quantity for a cart item.
  ///
  /// If the quantity is set to less than [minCartItemQuantity], the item is
  /// removed from the cart.
  @override
  Future<void> updateQuantity(
    String userId,
    String cartItemId,
    int quantity,
  ) async {
    final cartItemRef = _cartRef(userId).doc(cartItemId);
    if (quantity < minCartItemQuantity) {
      await cartItemRef.delete();
      return;
    }

    // Read cart item to get product/variant info for stock check
    final cartDoc = await cartItemRef.get();
    if (cartDoc == null || !cartDoc.exists) return;

    final productId =
        cartDoc.get<String>(Fields.productId) ?? cartItemId.split('_').first;
    final variantId = cartDoc.get<String>(Fields.variantId);

    // Verify stock before updating quantity
    final productDoc = await _ob
        .collection(Collections.products)
        .doc(productId)
        .get();
    if (productDoc != null && productDoc.exists) {
      int availableStock;
      if (variantId != null) {
        final variants =
            (productDoc.data[Fields.variants] as List?)?.cast<dynamic>() ?? [];
        final matchingVariant = variants
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (v) => v[Fields.variantId] == variantId,
              orElse: () => <String, dynamic>{},
            );
        if (matchingVariant.isEmpty) {
          throw NotFoundException(
            'Variant $variantId not found for product $productId',
            statusCode: 404,
          );
        }
        availableStock =
            (matchingVariant[Fields.stockQuantity] as num?)?.toInt() ??
            (productDoc.get<num>(Fields.stockQuantity))?.toInt() ??
            0;
      } else {
        availableStock =
            (productDoc.get<num>(Fields.stockQuantity))?.toInt() ?? 0;
      }

      if (availableStock < quantity) {
        throw ConflictException(
          'Only $availableStock items available in stock',
          statusCode: 409,
        );
      }
    }

    await cartItemRef.update({
      Fields.quantity: quantity.clamp(minCartItemQuantity, maxCartItemQuantity),
    });
  }

  /// Provides a real-time stream of the user\'s cart items.
  ///
  /// Emits the full cart on initial load, then updates based on real-time
  /// document changes (create, update, delete). Items are sorted by creation date.
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
