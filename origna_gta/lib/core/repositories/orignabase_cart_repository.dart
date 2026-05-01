import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// OrignaBase implementation of [CartRepository].
///
/// This repository manages the buyer's shopping cart using OrignaBase subcollections.
/// Cart items are stored under `users/{userId}/cart/{docId}`, where `docId` is
/// deterministic and buyer-scoped (`userId_productId` or
/// `userId_productId_variantId`).
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

  String _cartDocId(String bareUserId, String productId, String? variantId) {
    final itemKey = variantId != null ? '${productId}_$variantId' : productId;
    return '${bareUserId}_$itemKey';
  }

  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    if (value is Map) {
      for (final key in const ['integerValue', 'doubleValue', 'stringValue']) {
        final nested = value[key];
        if (nested != null) return _intValue(nested);
      }
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<CartItemModel>> _fetchCartViaGraphQL(String userId) async {
    final bareId = userId.contains(':') ? userId.split(':').last : userId;
    final response = await _ob.request(
      'POST',
      '/graphql',
      body: {
        'query':
            'query(\$collection:String!,\$filters:JSON,\$limit:Int){ list(collection:\$collection, filters:\$filters, limit:\$limit) }',
        'variables': {
          'collection': '${Collections.users}__${Collections.cart}',
          'filters': {
            Fields.parentId: {'_eq': '${Collections.users}:$bareId'},
          },
          'limit': 100,
        },
      },
    );

    final data = response['data'];
    final rawList = data is Map ? data['list'] : response['list'];
    if (rawList is! List) return const <CartItemModel>[];

    final items = <CartItemModel>[];
    for (final raw in rawList) {
      if (raw is! Map) continue;
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final docId = map['id']?.toString();
      try {
        final item = CartItemModel.fromMap(map, docId: docId);
        if (item.quantity > 0) items.add(item);
      } catch (error) {
        AppLogger.w(
          'Skipping malformed GraphQL cart item',
          tag: 'cart',
          error: error,
        );
      }
    }
    return items;
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
    final bareUserId = userId.contains(':') ? userId.split(':').last : userId;

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

    final parentId = '${Collections.users}:$bareUserId';
    final existingSnapshot = await cartRef
        .where(Fields.productId, isEqualTo: productId)
        .get();
    final existing = existingSnapshot.docs.cast<Document?>().firstWhere(
      (doc) =>
          doc != null &&
          doc.exists &&
          doc.data[Fields.parentId] == parentId &&
          doc.get<String>(Fields.variantId) == variantId,
      orElse: () => null,
    );
    final docId = existing == null
        ? _cartDocId(bareUserId, productId, variantId)
        : (existing.id.contains(':')
              ? existing.id.split(':').last
              : existing.id);

    // Compute quantity: accumulate if valid existing doc (has parent_id from this user).
    final bool hasValidExisting =
        existing != null &&
        existing.exists &&
        existing.data[Fields.parentId] == parentId;
    final currentQty = hasValidExisting
        ? _intValue(existing.data[Fields.quantity])
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
      final nextQty = currentQty + quantity;
      await cartRef.doc(docId).update({
        // PostgreSQL-backed OrignaBase currently stores FieldValue.increment
        // markers as JSON when called through GraphQL. Write the computed
        // integer explicitly so cart totals stay numeric in live checkout.
        Fields.quantity: nextQty,
        Fields.priceSnapshot: priceSnapshot,
        ...?variantId == null ? null : {Fields.variantId: variantId},
        ...?variantTitle == null ? null : {Fields.variantTitle: variantTitle},
        ...?variantOptions == null
            ? null
            : {Fields.variantOptions: variantOptions},
        ...?variantSku == null ? null : {Fields.variantSku: variantSku},
      });

      if (nextQty > effectiveCap) {
        await cartRef.doc(docId).update({Fields.quantity: effectiveCap});
        _throwStockConflict(
          availableStock: effectiveCap,
          currentQty: currentQty,
          requestedQty: nextQty,
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
      Fields.userId: bareUserId,
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
          (map['isActive'] as bool? ?? true);
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
    late StreamController<List<CartItemModel>> controller;
    StreamSubscription<DocumentChange>? realtimeSub;
    Timer? refreshTimer;

    controller = StreamController<List<CartItemModel>>(
      onListen: () async {
        final state = <String, CartItemModel>{};
        try {
          final cartRef = _cartRef(userId);

          Future<void> fetchAndEmit() async {
            try {
              state.clear();
              for (final item in await _fetchCartViaGraphQL(userId)) {
                state[item.cartItemId] = item;
              }
              if (!controller.isClosed) {
                controller.add(_sortedCartItems(state));
              }
            } catch (error, _) {
              if (!controller.isClosed) {
                AppLogger.w(
                  'Cart realtime refresh failed; keeping last known state',
                  tag: 'cart',
                  error: error,
                );
                controller.add(_sortedCartItems(state));
              }
            }
          }

          await fetchAndEmit();

          refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
            unawaited(fetchAndEmit());
          });

          try {
            realtimeSub = cartRef.snapshots().listen(
              (change) {
                try {
                  if (!change.document.exists) {
                    state.remove(change.document.id);
                  } else {
                    final item = CartItemModel.fromMap(
                      change.document.data,
                      docId: change.document.id,
                    );
                    if (item.quantity <= 0) {
                      state.remove(change.document.id);
                    } else {
                      state[change.document.id] = item;
                    }
                  }

                  if (!controller.isClosed) {
                    controller.add(_sortedCartItems(state));
                  }
                } catch (error) {
                  AppLogger.w(
                    'Skipping malformed cart realtime change',
                    tag: 'cart',
                    error: error,
                  );
                  if (!controller.isClosed) {
                    controller.add(_sortedCartItems(state));
                  }
                }
              },
              onError: (Object error, StackTrace _) {
                if (controller.isClosed) return;
                AppLogger.w(
                  'Cart realtime subscription failed; keeping last known state',
                  tag: 'cart',
                  error: error,
                );
                controller.add(_sortedCartItems(state));
              },
            );
          } catch (error) {
            AppLogger.w(
              'Cart realtime subscription setup failed; polling remains active',
              tag: 'cart',
              error: error,
            );
            if (!controller.isClosed) {
              scheduleMicrotask(() {
                if (controller.isClosed) return;
                controller.add(_sortedCartItems(state));
              });
            }
          }
        } catch (error) {
          if (!controller.isClosed) {
            AppLogger.w(
              'Cart stream setup failed; emitting last known state',
              tag: 'cart',
              error: error,
            );
            controller.add(_sortedCartItems(state));
          }
        }
      },
      onCancel: () {
        refreshTimer?.cancel();
        realtimeSub?.cancel();
      },
    );

    return controller.stream;
  }

  List<CartItemModel> _sortedCartItems(Map<String, CartItemModel> state) {
    final items = state.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }
}
