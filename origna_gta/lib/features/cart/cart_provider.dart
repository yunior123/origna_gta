import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

final cartControllerProvider = Provider<CartController>((ref) {
  return CartController(ref);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(data: (items) => items.fold(0, (total, item) => total + item.quantity), orElse: () => 0);
});

/// Provider for cart item creation date (used to avoid rebuilding item UI on quantity changes)
final cartItemDateProvider = Provider.autoDispose.family<Timestamp?, String>((ref, productId) {
  return ref.watch(
    cartItemsProvider.select((async) {
      return async.maybeWhen(data: (items) => items.where((i) => i.productId == productId).firstOrNull?.dateCreated, orElse: () => null);
    }),
  );
});

/// Family provider for individual cart item details - cached by Riverpod
final cartItemDetailProvider = FutureProvider.autoDispose.family<CartItemDetailModel?, String>((ref, productId) async {
  final firestore = ref.watch(firestoreProvider);
  final dateCreated = ref.watch(cartItemDateProvider(productId));
  if (dateCreated == null) return null;

  final quantity = ref.read(cartItemQuantityProvider(productId)).valueOrNull ?? 1;

  final productDoc = await firestore.collection('products').doc(productId).get();
  if (!productDoc.exists) return null;

  final productData = productDoc.data()!;
  return CartItemDetailModel(
    productId: productId,
    name: productData['name'] ?? '',
    description: productData['description'] ?? '',
    price: (productData['price'] ?? 0).toDouble(),
    imageUrls: List<String>.from(productData['imageUrls'] ?? []),
    quantity: quantity,
    dateCreated: dateCreated,
    sellerAddress: Address.fromMap(productData['sellerAddress'] ?? {}),
    sellerId: productData['sellerId'] ?? '',
    deliveryStatus: 'pending',
    weightKg: productData['weightKg'] != null ? (productData['weightKg'] as num).toDouble() : null,
    lengthCm: productData['lengthCm'] != null ? (productData['lengthCm'] as num).toDouble() : null,
    widthCm: productData['widthCm'] != null ? (productData['widthCm'] as num).toDouble() : null,
    heightCm: productData['heightCm'] != null ? (productData['heightCm'] as num).toDouble() : null,
    isLocalDeliveryOnly: productData['isLocalDeliveryOnly'] ?? false,
    isPerishable: productData['isPerishable'] ?? false,
    estimatedShipDays: productData['estimatedShipDays'] ?? 3,
    deliveryOptions: productData['deliveryOptions'] != null
        ? (productData['deliveryOptions'] as List).map((o) => SellerDeliveryOption.fromMap(o as Map<String, dynamic>)).toList()
        : [],
    minimumOrderQuantity: (productData['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
    freeShipping: productData['freeShipping'] ?? false,
    isDigital: productData['isDigital'] ?? false,
  );
});

// ============================================================================
// CART DETAILS PROVIDER (with product info) - BATCH FETCH
// ============================================================================

/// Provider that returns the current quantity for a specific product in cart
/// Uses document-level stream to prevent rebuilds when other items change
final cartItemQuantityProvider = StreamProvider.autoDispose.family<int, String>((ref, productId) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(0);

  return ref.watch(firestoreProvider).collection('users').doc(userId).collection('cart').doc(productId).snapshots().map((doc) {
    if (!doc.exists) return 0;
    return (doc.data()?['quantity'] ?? 0) as int;
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
final cartSubtotalProvider = Provider<double>((ref) {
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
                weightKg: productData['weightKg'] != null ? (productData['weightKg'] as num).toDouble() : null,
                lengthCm: productData['lengthCm'] != null ? (productData['lengthCm'] as num).toDouble() : null,
                widthCm: productData['widthCm'] != null ? (productData['widthCm'] as num).toDouble() : null,
                heightCm: productData['heightCm'] != null ? (productData['heightCm'] as num).toDouble() : null,
                isLocalDeliveryOnly: productData['isLocalDeliveryOnly'] ?? false,
                isPerishable: productData['isPerishable'] ?? false,
                estimatedShipDays: productData['estimatedShipDays'] ?? 3,
                deliveryOptions: productData['deliveryOptions'] != null
                    ? (productData['deliveryOptions'] as List).map((o) => SellerDeliveryOption.fromMap(o as Map<String, dynamic>)).toList()
                    : [],
                minimumOrderQuantity: (productData['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
                freeShipping: productData['freeShipping'] ?? false,
                isDigital: productData['isDigital'] ?? false,
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

class CartController {
  final Ref _ref;

  CartController(this._ref);

  CartRepository get _repository => _ref.read(cartRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);

  Future<bool> addToCart(String productId, int quantity) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.addToCart(userId, productId, quantity);
      return true;
    } catch (e) {
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
