import 'package:origna_gta/utils/utils.dart';

/// Contract for cart operations.
///
/// Implementations: [OrignaBaseCartRepository] (production).
///
/// Cart items are stored per user. Document IDs are deterministic:
/// `productId` for simple items, `productId_variantId` for variants.
/// Quantity is clamped to [1, 99].
abstract class CartRepository {
  /// Adds [quantity] units of [productId] to the user's cart.
  ///
  /// Verifies stock availability before mutation. Accumulates quantity if the
  /// item already exists. Throws [NotFoundException] if product doesn't exist,
  /// [ConflictException] if out of stock.
  Future<void> addToCart(
    String userId,
    String productId,
    int quantity, {
    String? variantId,
    String? variantTitle,
    Map<String, String>? variantOptions,
    String? variantSku,
  });

  /// Deletes all cart items for [userId] using a batch operation.
  Future<void> clearCart(String userId);

  /// Fetches the seller ID for a product to prevent self-purchase.
  /// Returns null if the product does not exist.
  Future<String?> getProductSellerId(String productId);

  /// Returns true if [variantId] exists and is active in the product's variants array.
  /// Returns false if the product doesn't exist or the variant is not found/inactive.
  Future<bool> isVariantValid(String productId, String variantId);

  /// Removes a single cart item by its document ID.
  Future<void> removeFromCart(String userId, String cartItemId);

  /// Updates or removes the buyer note on a cart item.
  ///
  /// Pass null to remove the note entirely (FieldValue.delete()).
  Future<void> updateBuyerNote(String userId, String cartItemId, String? note);

  /// Updates the quantity of a cart item. Deletes the item if [quantity] < 1.
  Future<void> updateQuantity(String userId, String cartItemId, int quantity);

  /// Real-time stream of cart items for [userId], sorted by creation date.
  ///
  /// Emits initial snapshot then subsequent changes via OrignaBase realtime.
  Stream<List<CartItemModel>> watchCart(String userId);
}
