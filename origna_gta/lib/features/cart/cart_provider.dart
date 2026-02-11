import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final cartControllerProvider = Provider.autoDispose<CartController>((ref) {
  return CartController(ref);
});

final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(data: (items) => items.fold(0, (total, item) => total + item.quantity), orElse: () => 0);
});

/// Provider for cart item creation date (used to avoid rebuilding item UI on quantity changes)
final cartItemDateProvider = Provider.autoDispose.family<Timestamp?, String>((ref, productId) {
  return ref.watch(
    cartItemsProvider.select((async) {
      return async.maybeWhen(data: (items) => items.where((i) => i.productId == productId).firstOrNull?.createdAt, orElse: () => null);
    }),
  );
});

/// Family provider for individual cart item details - cached by Riverpod
/// AUDIT FIX: Reads from batch-fetched cache instead of making individual
/// Firestore reads per item (N+1 query elimination).
final cartItemDetailProvider = FutureProvider.autoDispose.family<CartItemDetailModel?, String>((ref, productId) async {
  final createdAt = ref.watch(cartItemDateProvider(productId));
  if (createdAt == null) return null;

  // Pull from batch-fetched product cache (single whereIn query for all cart items)
  final productCache = await ref.watch(_cartProductsBatchProvider.future);
  final productData = productCache[productId];
  if (productData == null) return null;

  return CartItemDetailModel(
    productId: productId,
    name: productData[Fields.name] ?? '',
    description: productData[Fields.description] ?? '',
    price: (productData[Fields.price] ?? 0).toDouble(),
    imageUrls: List<String>.from(productData[Fields.imageUrls] ?? []),
    quantity: 0, // Placeholder — real quantity rendered by CartItemScreen's own Consumer
    createdAt: createdAt,
    sellerAddress: Address.fromMap(productData[Fields.sellerAddress] ?? {}),
    sellerId: productData[Fields.sellerId] ?? '',
    deliveryStatus: DeliveryStatusValues.pending,
    weightKg: productData[Fields.weightKg] != null ? (productData[Fields.weightKg] as num).toDouble() : null,
    lengthCm: productData[Fields.lengthCm] != null ? (productData[Fields.lengthCm] as num).toDouble() : null,
    widthCm: productData[Fields.widthCm] != null ? (productData[Fields.widthCm] as num).toDouble() : null,
    heightCm: productData[Fields.heightCm] != null ? (productData[Fields.heightCm] as num).toDouble() : null,
    isLocalDeliveryOnly: productData[Fields.isLocalDeliveryOnly] ?? false,
    isPerishable: productData[Fields.isPerishable] ?? false,
    estimatedShipDays: productData[Fields.estimatedShipDays] ?? 3,
    deliveryOptions: productData[Fields.deliveryOptions] != null
        ? (productData[Fields.deliveryOptions] as List)
            .whereType<Map>()
            .map((o) => SellerDeliveryOption.fromMap(o.cast<String, dynamic>()))
            .whereType<SellerDeliveryOption>()
            .toList()
        : [],
    minimumOrderQuantity: (productData[Fields.minimumOrderQuantity] as num?)?.toInt() ?? 1,
    freeShipping: productData[Fields.freeShipping] ?? false,
    isDigital: productData[Fields.isDigital] ?? false,
  );
});

// ============================================================================
// BATCH PRODUCT CACHE — fetches all cart product docs in one whereIn query
// ============================================================================

/// Internal provider that batch-fetches product documents for all cart items.
/// Returns a `Map<productId, productData>` for O(1) lookup by [cartItemDetailProvider].
final _cartProductsBatchProvider = FutureProvider.autoDispose<Map<String, Map<String, dynamic>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final cartItems = ref.watch(cartItemsProvider);

  final productIds = cartItems.maybeWhen(
    data: (items) => items.map((i) => i.productId).toList(),
    orElse: () => <String>[],
  );

  if (productIds.isEmpty) return {};

  final Map<String, Map<String, dynamic>> cache = {};

  // Firestore whereIn limit is 30 — batch accordingly
  for (int i = 0; i < productIds.length; i += 30) {
    final chunk = productIds.skip(i).take(30).toList();
    final snapshot = await firestore
        .collection(Collections.products)
        .where(FieldPath.documentId, whereIn: chunk)
        .get();
    for (final doc in snapshot.docs) {
      if (doc.exists) {
        cache[doc.id] = doc.data();
      }
    }
  }

  return cache;
});

// ============================================================================
// CART DETAILS PROVIDER (with product info) - BATCH FETCH
// ============================================================================

/// Provider that returns the current quantity for a specific product in cart
/// Uses document-level stream to prevent rebuilds when other items change
final cartItemQuantityProvider = StreamProvider.autoDispose.family<int, String>((ref, productId) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(0);

  return ref.watch(firestoreProvider).collection(Collections.users).doc(userId).collection(Collections.cart).doc(productId).snapshots().map((doc) {
    if (!doc.exists) return 0;
    return (doc.data()?[Fields.quantity] ?? 0) as int;
  });
});

// ============================================================================
// CART PROVIDERS
// ============================================================================

final cartItemsProvider = StreamProvider.autoDispose<List<CartItemModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(cartRepositoryProvider).watchCart(userId);
});

/// Cart subtotal - computed from cartWithDetailsProvider
final cartSubtotalProvider = Provider.autoDispose<double>((ref) {
  final cartDetails = ref.watch(cartWithDetailsProvider);
  return cartDetails.maybeWhen(data: (items) => items.fold(0.0, (total, item) => total + (item.price * item.quantity)), orElse: () => 0.0);
});

// ============================================================================
// SINGLE CART ITEM DETAIL PROVIDER (Family)
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
        final snapshot = await firestore.collection(Collections.products).where(FieldPath.documentId, whereIn: batch).get();

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
                name: productData[Fields.name] ?? '',
                description: productData[Fields.description] ?? '',
                price: (productData[Fields.price] ?? 0).toDouble(),
                imageUrls: List<String>.from(productData[Fields.imageUrls] ?? []),
                quantity: cartItem.quantity,
                createdAt: cartItem.createdAt,
                sellerAddress: Address.fromMap(productData[Fields.sellerAddress] ?? {}),
                sellerId: productData[Fields.sellerId] ?? '',
                deliveryStatus: DeliveryStatusValues.pending,
                weightKg: productData[Fields.weightKg] != null ? (productData[Fields.weightKg] as num).toDouble() : null,
                lengthCm: productData[Fields.lengthCm] != null ? (productData[Fields.lengthCm] as num).toDouble() : null,
                widthCm: productData[Fields.widthCm] != null ? (productData[Fields.widthCm] as num).toDouble() : null,
                heightCm: productData[Fields.heightCm] != null ? (productData[Fields.heightCm] as num).toDouble() : null,
                isLocalDeliveryOnly: productData[Fields.isLocalDeliveryOnly] ?? false,
                isPerishable: productData[Fields.isPerishable] ?? false,
                estimatedShipDays: productData[Fields.estimatedShipDays] ?? 3,
                deliveryOptions: productData[Fields.deliveryOptions] != null
                    ? (productData[Fields.deliveryOptions] as List)
                        .whereType<Map>()
                        .map((o) => SellerDeliveryOption.fromMap(o.cast<String, dynamic>()))
                        .whereType<SellerDeliveryOption>()
                        .toList()
                    : [],
                minimumOrderQuantity: (productData[Fields.minimumOrderQuantity] as num?)?.toInt() ?? 1,
                freeShipping: productData[Fields.freeShipping] ?? false,
                isDigital: productData[Fields.isDigital] ?? false,
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

// Provider for delivery instructions (stored during cart/checkout flow)
final deliveryInstructionsProvider = StateProvider.autoDispose<String>((ref) => '');

class CartController {
  final Ref _ref;

  CartController(this._ref);

  CartRepository get _repository => _ref.read(cartRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Check if user can add this product (not their own)
  Future<bool> canAddToCart(String productId) async {
    final userId = _userId;
    if (userId == null) return false;
    
    try {
      final sellerId = await _repository.getProductSellerId(productId);
      if (sellerId == null) return false;
      return sellerId != userId;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      // Check if user is trying to buy their own product
      final sellerId = await _repository.getProductSellerId(productId);
      if (sellerId == null) return false;
      if (sellerId == userId) return false;
      
      await _repository.addToCart(userId, productId, quantity);
      return true;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  Future<void> clearCart() async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.clearCart(userId);
  }

  void refreshCart() {
    _ref.invalidate(cartItemsProvider);
  }

  Future<void> removeFromCart(String productId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.removeFromCart(userId, productId);
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.updateQuantity(userId, productId, newQuantity);
  }
}
