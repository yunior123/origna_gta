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

  /// Returns true if [variantId] exists and is active in the product's variants array.
  /// Returns false if the product doesn't exist or the variant is not found/inactive.
  Future<bool> isVariantValid(String productId, String variantId);

  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> updateBuyerNote(String userId, String cartItemId, String? note);
  Future<void> updateQuantity(String userId, String cartItemId, int quantity);

  Stream<List<CartItemModel>> watchCart(String userId);
}
