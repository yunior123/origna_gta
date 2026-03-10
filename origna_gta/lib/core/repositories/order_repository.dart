// coverage:ignore-file
import 'package:origna_gta/models/generated/models.dart' as models;

abstract class OrderRepository {
  /// Approves or rejects a seller-submitted shipping cost update for [orderId].
  Future<void> approveShippingCost(String orderId, bool approved);

  /// Captures the pre-authorized Stripe payment for [orderId].
  /// Must be called after buyer confirms delivery (or auto-capture cron fires).
  Future<void> capturePayment(String orderId);

  /// Buyer confirms receipt of [orderId]; triggers capture if not yet done.
  Future<void> confirmReceipt(String orderId, {String? productId});

  /// Creates a Stripe Checkout session for the given [orderData] payload.
  /// Returns a map containing at least `{sessionId, checkoutUrl}`.
  Future<Map<String, dynamic>> createCheckoutSession(Map<String, dynamic> orderData);

  /// Fetches a single order by document ID.
  /// Returns null if the document does not exist.
  Future<models.Order?> fetchOrderById(String orderId);

  /// Updates the shipping status of a specific item within an order.
  ///
  /// [itemId] is the product ID of the item to update.
  /// [trackingNumber], [carrier], and [carrierNote] are optional and only relevant for the `shipped` status.
  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber, String? carrier, String? carrierNote});

  /// Persists the last Stripe session and order IDs on the user document for
  /// post-payment recovery (e.g., polling the success screen).
  Future<void> updateLastSession(String userId, String sessionId, String orderId);

  /// Submits a revised shipping cost for [orderId] with an audit [reason].
  Future<void> updateShippingCost(String orderId, double newShippingCost, String reason);

  /// Real-time stream of all orders placed by [userId] in terminal or active payment states.
  Stream<List<models.Order>> watchBuyerOrders(String userId);

  /// Watches a single order matched by Stripe session ID, resolving only once it is captured.
  /// Returns null if no matching captured order exists yet.
  Stream<models.Order?> watchPaidOrderBySession(String sessionId);

  /// Real-time stream of orders containing items sold by [userId].
  /// Results are sorted client-side by createdAt descending because the database
  /// does not support arrayContains + whereIn + orderBy on a different field.
  Stream<List<models.Order>> watchSellerOrders(String userId);
}
