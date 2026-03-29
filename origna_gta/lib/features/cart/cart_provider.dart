import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/services/analytics_service.dart'
    show analyticsServiceProvider;
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Riverpod provider for [CartController].
///
/// Auto-disposed when no widgets watch cart state — fresh controller
/// on next access ensures correct userId binding after login/logout.
final cartControllerProvider = Provider.autoDispose<CartController>((ref) {
  return CartController(ref);
});

/// Total number of items in the cart (sum of all item quantities).
///
/// Returns 0 while loading or when cart is empty. Used by the cart badge
/// icon in the bottom navigation bar.
final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return cartItems.maybeWhen(
    data: (items) => items.fold(0, (total, item) => total + item.quantity),
    orElse: () => 0,
  );
});

/// Provider for cart item creation date (used to avoid rebuilding item UI on quantity changes)
/// Keyed by cartItemDocId (format: productId or productId_variantId) to correctly
/// distinguish items with the same product but different variants.
final cartItemDateProvider = Provider.autoDispose.family<DateTime?, String>((
  ref,
  cartItemDocId,
) {
  return ref.watch(
    cartItemsProvider.select((async) {
      return async.maybeWhen(
        data: (items) => items
            .where((i) => i.cartItemId == cartItemDocId)
            .firstOrNull
            ?.createdAt,
        orElse: () => null,
      );
    }),
  );
});

/// Provider for individual cart item details, keyed by cart item document ID.
///
/// Parameters:
/// - [cartItemDocId]: unique identifier for the cart item (format: `productId` or `productId_variantId`).
///
/// Returns:
/// - A [FutureProvider] emitting a [CartItemDetailModel] enriched with product metadata.
///
/// AUDIT FIX: Reads from a batch-fetched product cache ([_cartProductsBatchProvider])
/// instead of making individual database reads per item, eliminating N+1 query issues.
///
/// Gotchas:
/// - If a product is no longer active, returns a model populated from the cart item's price snapshot.
final cartItemDetailProvider = FutureProvider.autoDispose
    .family<CartItemDetailModel?, String>((ref, cartItemDocId) async {
      final createdAt = ref.watch(cartItemDateProvider(cartItemDocId));
      if (createdAt == null) return null;

      // Extract productId: doc ID is "productId" or "productId_variantId"
      // Database auto-IDs use Base62 (no underscores), so the first segment is always productId.
      final productId = cartItemDocId.split('_').first;

      // Pull from batch-fetched product cache (single whereIn query for all cart items)
      final productCache = await ref.watch(_cartProductsBatchProvider.future);
      final productData = productCache[productId];

      // Find the exact cart item to get variant info — await to ensure state is fully resolved
      final cartItems = await ref.watch(cartItemsProvider.future);
      final cartItem = cartItems
          .where((i) => i.cartItemId == cartItemDocId)
          .firstOrNull;

      final isUnavailable =
          productData == null ||
          productData[Fields.lifecycleStatus] !=
              ProductLifecycleStatusValues.active;

      if (isUnavailable) {
        if (cartItem == null) return null;
        final snapshotPriceCents = cartItem.priceSnapshot ?? 0;
        return CartItemDetailModel(
          productId: productId,
          name: cartItem.productName ?? '',
          description: cartItem.productDescription ?? '',
          price: snapshotPriceCents / 100.0,
          priceCents: snapshotPriceCents,
          imageUrls: cartItem.imageUrls,
          quantity: cartItem.quantity,
          createdAt: createdAt,
          sellerAddress: Address.fromMap(const <String, dynamic>{}),
          sellerId: '',
          sellerName: '',
          estimatedShipDays: 3,
          deliveryOptions: const [],
          minimumOrderQuantity: 1,
          freeShipping: false,
          isDigital: false,
          variantId: cartItem.variantId,
          variantTitle: cartItem.variantTitle,
          variantOptions: cartItem.variantOptions,
        );
      }

      return CartItemDetailModel(
        productId: productId,
        name: (productData[Fields.name] as String?) ?? '',
        description: (productData[Fields.description] as String?) ?? '',
        price: ((productData[Fields.price] as num?) ?? 0).toDouble(),
        priceCents: productData[Fields.priceCents] != null
            ? (productData[Fields.priceCents] as num).toInt()
            : (((productData[Fields.price] as num?) ?? 0).toDouble() * 100)
                  .round(),
        imageUrls: List<String>.from(
          productData[Fields.imageUrls] as Iterable? ?? [],
        ),
        quantity: cartItem?.quantity ?? 1,
        createdAt: createdAt,
        sellerAddress: Address.fromMap(
          productData[Fields.sellerAddress] as Map<String, dynamic>? ?? {},
        ),
        sellerId: (productData[Fields.sellerId] as String?) ?? '',
        sellerName: (productData[Fields.sellerName] as String?) ?? '',
        weightKg: productData[Fields.weightKg] != null
            ? (productData[Fields.weightKg] as num).toDouble()
            : null,
        lengthCm: productData[Fields.lengthCm] != null
            ? (productData[Fields.lengthCm] as num).toDouble()
            : null,
        widthCm: productData[Fields.widthCm] != null
            ? (productData[Fields.widthCm] as num).toDouble()
            : null,
        heightCm: productData[Fields.heightCm] != null
            ? (productData[Fields.heightCm] as num).toDouble()
            : null,
        isLocalDeliveryOnly:
            (productData[Fields.isLocalDeliveryOnly] as bool?) ?? false,
        isPerishable: (productData[Fields.isPerishable] as bool?) ?? false,
        estimatedShipDays:
            (productData[Fields.estimatedShipDays] as num?)?.toInt() ?? 3,
        deliveryOptions: productData[Fields.deliveryOptions] != null
            ? (productData[Fields.deliveryOptions] as List<dynamic>)
                  .whereType<Map<dynamic, dynamic>>()
                  .map(
                    (o) =>
                        SellerDeliveryOption.fromMap(o.cast<String, dynamic>()),
                  )
                  .whereType<SellerDeliveryOption>()
                  .toList()
            : [],
        minimumOrderQuantity:
            (productData[Fields.minimumOrderQuantity] as num?)?.toInt() ?? 1,
        freeShipping: (productData[Fields.freeShipping] as bool?) ?? false,
        isDigital: (productData[Fields.isDigital] as bool?) ?? false,
        variantId: cartItem?.variantId,
        variantTitle: cartItem?.variantTitle,
        variantOptions: cartItem?.variantOptions,
      );
    });

// ============================================================================
// BATCH PRODUCT CACHE — fetches all cart product docs in one whereIn query
// ============================================================================

/// Provider that returns the current quantity for a specific cart item.
///
/// Parameters:
/// - [cartItemId]: the document ID of the cart item.
///
/// Returns:
/// - An [AsyncValue] containing the integer quantity.
///
/// F-004 fix: using productId caused merged quantities when the same product appeared twice.
final cartItemQuantityProvider = Provider.autoDispose
    .family<AsyncValue<int>, String>((ref, cartItemId) {
      final itemsAsync = ref.watch(cartItemsProvider);
      return itemsAsync.whenData((items) {
        final matches = items.where((item) => item.cartItemId == cartItemId);
        return matches.isEmpty ? 0 : matches.first.quantity;
      });
    });

// ============================================================================
// AUDIT FIX (C4): Unavailable cart items provider
// ============================================================================

// ============================================================================
// CART PROVIDERS
// ============================================================================

/// Stream of all cart items for the currently authenticated user.
final cartItemsProvider = StreamProvider.autoDispose<List<CartItemModel>>((
  ref,
) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(cartRepositoryProvider).watchCart(userId);
});

// ============================================================================
// CART DETAILS PROVIDER (with product info) - BATCH FETCH
// ============================================================================

/// Validates that all cart items can be shipped to the buyer's default address.
///
/// Returns:
/// - A list of product IDs that are un-shippable to the buyer's current province.
final cartShippingValidationProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final cartItems = await ref.watch(cartWithDetailsProvider.future);
  if (cartItems.isEmpty) return [];

  final userProfile = await ref.watch(userProfileProvider.future);
  final destinationState = userProfile?.address?.state;

  // Digital items always shippable.
  // Physical items: check deliveryOptions. If any option is availableNationwide or matches the state, it's shippable.
  final unshippable = <String>[];

  for (final item in cartItems) {
    if (item.isDigital) continue;

    final isLocalOnly = item.isLocalDeliveryOnly || item.isPerishable;
    final sellerState = item.sellerAddress.state;

    // If local-only and different province, it's un-shippable unless there's a nationwide option
    bool canShip = false;
    if (item.deliveryOptions.isEmpty) {
      // Fallback: if no delivery options defined, assume standard nationwide unless explicitly restricted
      canShip = !isLocalOnly || (sellerState == destinationState);
    } else {
      canShip = item.deliveryOptions.any(
        (opt) =>
            opt.availableNationwide ||
            (opt.type == DeliveryTypeValues.standard && !isLocalOnly) ||
            (isLocalOnly && sellerState == destinationState),
      );
    }

    if (!canShip) {
      unshippable.add(item.productId);
    }
  }

  return unshippable;
});

/// Computes the cart subtotal in integer cents.
///
/// Used for all financial arithmetic and business rule checks (e.g., free shipping threshold).
final cartSubtotalProvider = Provider.autoDispose<int>((ref) {
  final cartDetails = ref.watch(cartWithDetailsProvider);
  return cartDetails.maybeWhen(
    data: (items) => items.fold(
      0,
      (total, item) => total + (item.priceCents * item.quantity),
    ),
    orElse: () => 0,
  );
});

/// Fetches cart items with full product details using the batch-fetch cache.
///
/// Returns:
/// - A list of [CartItemDetailModel] for all items in the user's cart.
final cartWithDetailsProvider =
    FutureProvider.autoDispose<List<CartItemDetailModel>>((ref) async {
      final cartItems = ref.watch(cartItemsProvider);
      final productCache = await ref.watch(_cartProductsBatchProvider.future);

      return cartItems.when(
        data: (items) async {
          if (items.isEmpty) return [];

          final List<CartItemDetailModel> results = [];
          for (final cartItem in items) {
            final productData = productCache[cartItem.productId];
            if (productData != null &&
                productData[Fields.lifecycleStatus] ==
                    ProductLifecycleStatusValues.active) {
              results.add(
                CartItemDetailModel(
                  productId: cartItem.productId,
                  name: (productData[Fields.name] as String?) ?? '',
                  description:
                      (productData[Fields.description] as String?) ?? '',
                  price: ((productData[Fields.price] as num?) ?? 0).toDouble(),
                  priceCents: productData[Fields.priceCents] != null
                      ? (productData[Fields.priceCents] as num).toInt()
                      : (((productData[Fields.price] as num?) ?? 0).toDouble() *
                                100)
                            .round(),
                  imageUrls: List<String>.from(
                    productData[Fields.imageUrls] as Iterable? ?? [],
                  ),
                  quantity: cartItem.quantity,
                  createdAt: cartItem.createdAt,
                  sellerAddress: Address.fromMap(
                    productData[Fields.sellerAddress]
                            as Map<String, dynamic>? ??
                        {},
                  ),
                  sellerId: (productData[Fields.sellerId] as String?) ?? '',
                  sellerName:
                      (productData[Fields.sellerName] as String?) ??
                      'Unknown Seller',
                  weightKg: productData[Fields.weightKg] != null
                      ? (productData[Fields.weightKg] as num).toDouble()
                      : null,
                  lengthCm: productData[Fields.lengthCm] != null
                      ? (productData[Fields.lengthCm] as num).toDouble()
                      : null,
                  widthCm: productData[Fields.widthCm] != null
                      ? (productData[Fields.widthCm] as num).toDouble()
                      : null,
                  heightCm: productData[Fields.heightCm] != null
                      ? (productData[Fields.heightCm] as num).toDouble()
                      : null,
                  isLocalDeliveryOnly:
                      (productData[Fields.isLocalDeliveryOnly] as bool?) ??
                      false,
                  isPerishable:
                      (productData[Fields.isPerishable] as bool?) ?? false,
                  estimatedShipDays:
                      (productData[Fields.estimatedShipDays] as num?)
                          ?.toInt() ??
                      3,
                  deliveryOptions: productData[Fields.deliveryOptions] != null
                      ? (productData[Fields.deliveryOptions] as List<dynamic>)
                            .whereType<Map<dynamic, dynamic>>()
                            .map(
                              (o) => SellerDeliveryOption.fromMap(
                                o.cast<String, dynamic>(),
                              ),
                            )
                            .whereType<SellerDeliveryOption>()
                            .toList()
                      : [],
                  minimumOrderQuantity:
                      (productData[Fields.minimumOrderQuantity] as num?)
                          ?.toInt() ??
                      1,
                  freeShipping:
                      (productData[Fields.freeShipping] as bool?) ?? false,
                  isDigital: (productData[Fields.isDigital] as bool?) ?? false,
                  buyerNote: cartItem.buyerNote,
                  variantId: cartItem.variantId,
                  variantTitle: cartItem.variantTitle,
                  variantOptions: cartItem.variantOptions,
                ),
              );
            }
          }

          return results;
        },
        loading: () => [],
        error: (e, st) =>
            throw e, // Rethrow so cart screen can show retry banner
      );
    });

/// State provider for delivery instructions entered during checkout.
final deliveryInstructionsProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

// ============================================================================
// SINGLE CART ITEM DETAIL PROVIDER (Family)
// ============================================================================

/// Identifies products in the cart that are no longer available in the active catalog.
///
/// Returns:
/// - A list of product IDs for unavailable items.
final unavailableCartItemsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final cartItems = ref.watch(cartItemsProvider);
  final productCache = await ref.watch(_cartProductsBatchProvider.future);

  return cartItems.maybeWhen(
    data: (items) {
      return items
          .where((item) => !productCache.containsKey(item.productId))
          .map((item) => item.productId)
          .toList();
    },
    orElse: () => <String>[],
  );
});

/// Internal provider that batch-fetches full product documents for all cart entries.
///
/// Returns a map of `productId` to its raw JSON data.
final _cartProductsBatchProvider =
    FutureProvider.autoDispose<Map<String, Map<String, dynamic>>>((ref) async {
      final productRepository = ref.watch(productRepositoryProvider);
      final cartItems = ref.watch(cartItemsProvider);

      final productIds = cartItems.maybeWhen(
        data: (items) => items.map((i) => i.productId).toList(),
        orElse: () => <String>[],
      );

      if (productIds.isEmpty) return {};

      final Map<String, Map<String, dynamic>> cache = {};
      try {
        final products = await productRepository.fetchProductsByIds(productIds);
        for (final product in products) {
          cache[product.productId] = product.toJson();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
      }

      return cache;
    });

/// Stateless controller for cart mutations: add, remove, and update.
///
/// All operations require an authenticated user.
///
/// ## Key Decisions
/// - Self-purchase prevention: [addToCart] returns `false` if the buyer is the seller.
/// - Variant validation: [addToCart] verifies the variant is active before adding.
/// - Analytics: All mutations log fire-and-forget analytics events.
class CartController {
  final Ref _ref;

  /// Creates a new [CartController].
  CartController(this._ref);

  CartRepository get _repository => _ref.read(cartRepositoryProvider);
  String? get _userId => _ref.read(userIdProvider);

  /// Adds a product to the user's cart.
  ///
  /// Parameters:
  /// - [productId]: the ID of the product.
  /// - [quantity]: units to add.
  /// - [variantId]: optional variant ID.
  ///
  /// Returns:
  /// - `true` on success, `false` on failure or if self-purchase is attempted.
  Future<bool> addToCart(
    String productId,
    int quantity, {
    String? variantId,
    String? productName,
    double? priceCad,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      // Check if user is trying to buy their own product
      final sellerId = await _repository.getProductSellerId(productId);
      if (sellerId == null) return false;
      if (sellerId == userId) return false;

      // Validate variantId exists and is active in the product's variants array
      if (variantId != null) {
        final valid = await _repository.isVariantValid(productId, variantId);
        if (!valid) return false;
      }

      await _repository.addToCart(
        userId,
        productId,
        quantity,
        variantId: variantId,
      );
      if (productName != null && priceCad != null) {
        unawaited(
          _ref
              .read(analyticsServiceProvider)
              .logAddToCart(
                productId: productId,
                productName: productName,
                priceCad: priceCad,
                quantity: quantity,
              ),
        );
      }
      return true;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  /// Checks if the current user can add a specific product to their cart.
  ///
  /// Prevents users from purchasing products they are selling.
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

  /// Clears all items from the current user's cart.
  Future<void> clearCart() async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.clearCart(userId);
  }

  /// Forces a refresh of the cart item stream by invalidating the provider.
  void refreshCart() {
    _ref.invalidate(cartItemsProvider);
  }

  /// Removes a specific item from the user's cart.
  ///
  /// Parameters:
  /// - [cartItemId]: the ID of the cart entry to remove.
  Future<void> removeFromCart(String cartItemId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.removeFromCart(userId, cartItemId);
  }

  /// Saves a cart item to favorites and removes it from the cart.
  ///
  /// Parameters:
  /// - [productId]: the product to favorite.
  /// - [cartItemId]: the cart entry to remove after favoriting.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> saveForLater(String productId, String cartItemId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _ref
          .read(productRepositoryProvider)
          .toggleFavorite(userId, productId);
      await removeFromCart(cartItemId);
      return true;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  /// Updates the optional buyer note for a cart item.
  ///
  /// Parameters:
  /// - [cartItemId]: the cart entry to update.
  /// - [note]: the note text, or null to clear.
  Future<void> updateBuyerNote(String cartItemId, String? note) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.updateBuyerNote(userId, cartItemId, note);
  }

  /// Updates the quantity of an item in the cart.
  ///
  /// Parameters:
  /// - [cartItemId]: the ID of the cart item.
  /// - [newQuantity]: the updated number of units.
  Future<bool> updateQuantity(String cartItemId, int newQuantity) async {
    final userId = _userId;
    if (userId == null) return false;

    await _repository.updateQuantity(userId, cartItemId, newQuantity);
    return true;
  }
}

// === Widget Previews ===
