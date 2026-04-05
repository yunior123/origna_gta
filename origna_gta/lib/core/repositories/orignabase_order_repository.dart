import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/order_query_helpers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

/// OrignaBase implementation of [OrderRepository].
///
/// Realtime stream logic is extracted into [OrderQueryHelpers].
/// This file focuses on the public API surface and mutation endpoints.
///
/// All mutations go through OrignaBase's server-side endpoints (via `_ob.request`)
/// to enforce business rules, payment verification, and multi-seller order splitting.
class OrignaBaseOrderRepository
    with OrderQueryHelpers
    implements OrderRepository {
  /// The OrignaBase client used for API requests.
  final OrignaBase _ob;

  /// Creates an order repository with the given OrignaBase [client].
  OrignaBaseOrderRepository(this._ob);

  // Mixin accessor
  @override
  OrignaBase get ob => _ob;

  // ---------------------------------------------------------------------------
  // Helper: convert an OrignaBase Document to a models.Order
  // ---------------------------------------------------------------------------

  /// Converts an OrignaBase [Document] to a [models.Order].
  ///
  /// Merges the document data with the document ID as `orderId`.
  @override
  models.Order docToOrder(Document doc) {
    final data = <String, dynamic>{...doc.data, Fields.orderId: doc.id};
    return models.Order.fromMap(data, doc.id);
  }

  // ---------------------------------------------------------------------------
  // Backend action calls via ob.request
  // ---------------------------------------------------------------------------

  /// Approves or rejects a seller-submitted shipping cost update.
  ///
  /// [orderId]: the order ID.
  /// [approved]: whether the buyer approves the new shipping cost.
  @override
  Future<void> cancelOrder(String orderId) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersCancelOrder,
      body: {Fields.orderId: orderId},
    );
  }

  @override
  Future<void> approveShippingCost(String orderId, bool approved) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersApproveShipping,
      body: {Fields.orderId: orderId, ApiKeys.approved: approved},
    );
  }

  /// Captures the pre-authorized Stripe payment for an order.
  ///
  /// [orderId]: the order to capture payment for.
  /// Called after buyer confirms delivery or auto-capture triggers.
  @override
  Future<void> capturePayment(String orderId) async {
    await _ob.request(
      'POST',
      ApiEndpoints.paymentsCapture,
      body: {Fields.orderId: orderId},
    );
  }

  /// Buyer confirms receipt of an order, triggering payment capture.
  ///
  /// [orderId]: the order ID.
  /// [productId]: optional specific product ID for partial receipt confirmation.
  ///   If omitted, confirms the entire order (triggers capture endpoint).
  @override
  Future<void> confirmReceipt(String orderId, {String? productId}) async {
    if (productId != null && productId.isNotEmpty) {
      await _ob.request(
        'POST',
        ApiEndpoints.ordersConfirmReceipt,
        body: {Fields.orderId: orderId, Fields.productId: productId},
      );
    } else {
      await _ob.request(
        'POST',
        ApiEndpoints.paymentsCapture,
        body: {Fields.orderId: orderId},
      );
    }
  }

  /// Creates a Stripe Checkout session for the given order data.
  ///
  /// [orderData]: the order payload (items, shipping, buyer info).
  ///
  /// Returns a map with `sessionId` and `checkoutUrl` for redirecting
  /// the user to Stripe's hosted checkout page.
  @override
  Future<Map<String, dynamic>> createCheckoutSession(
    Map<String, dynamic> orderData,
  ) async {
    final response = await _ob.request(
      'POST',
      ApiEndpoints.checkoutSession,
      body: orderData,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Fetches a single order by document ID.
  ///
  /// Returns null if the order does not exist.
  @override
  Future<models.Order?> fetchOrderById(String orderId) async {
    final doc = await _ob.collection(Collections.orders).doc(orderId).get();
    if (doc == null || !doc.exists) return null;
    return docToOrder(doc);
  }

  /// Updates the shipping status of a specific item within an order.
  ///
  /// [orderId]: the order containing the item.
  /// [itemId]: the product/item ID to update.
  /// [status]: the new status (e.g., 'shipped', 'delivered').
  /// [trackingNumber]: optional tracking number for shipped items.
  /// [carrier]: optional carrier name (e.g., 'Canada Post', 'UPS').
  /// [carrierNote]: optional seller note about the shipment.
  @override
  Future<void> updateItemStatus(
    String orderId,
    String itemId,
    String status, {
    String? trackingNumber,
    String? carrier,
    String? carrierNote,
  }) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersUpdateItemStatus,
      body: {
        Fields.orderId: orderId,
        Fields.productId: itemId,
        ApiKeys.newStatus: status,
        ...?trackingNumber == null
            ? null
            : {Fields.trackingNumber: trackingNumber},
        ...?carrier == null ? null : {Fields.carrier: carrier},
        ...?carrierNote == null ? null : {Fields.carrierNote: carrierNote},
      },
    );
  }

  /// Persists the last checkout session and order IDs on the user document.
  ///
  /// Used for post-payment recovery (e.g., polling the success screen).
  ///
  /// [userId]: the buyer's user ID.
  /// [sessionId]: the Stripe checkout session ID.
  /// [orderId]: the resulting order ID.
  @override
  Future<void> updateLastSession(
    String userId,
    String sessionId,
    String orderId,
  ) async {
    await _ob.collection(Collections.users).doc(userId).update({
      Fields.lastCheckoutSession: sessionId,
      Fields.lastOrderId: orderId,
      Fields.lastCheckoutTimestamp: FieldValue.serverTimestamp(),
    });
  }

  /// Submits a revised shipping cost for an order with an audit reason.
  ///
  /// [orderId]: the order to update.
  /// [newShippingCostCents]: the new shipping cost in cents.
  /// [reason]: the reason for the cost change (audit trail).
  @override
  Future<void> updateShippingCost(
    String orderId,
    int newShippingCostCents,
    String reason,
  ) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersUpdateShipping,
      body: {
        Fields.orderId: orderId,
        ApiKeys.newShippingCostCents: newShippingCostCents,
        ApiKeys.reason: reason,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Realtime streams — delegated to OrderQueryHelpers mixin
  // ---------------------------------------------------------------------------

  /// Provides a realtime stream of orders placed by the buyer.
  ///
  /// Filters to orders with active payment statuses, sorted by creation date descending.
  @override
  Stream<List<models.Order>> watchBuyerOrders(String userId) {
    return watchOrdersImpl(
      initialQuery: () => _ob
          .collection(Collections.orders)
          .where(Fields.userId, isEqualTo: userId)
          .where(
            Fields.paymentStatus,
            whereIn: OrderQueryHelpers.activePaymentStatuses,
          )
          .orderBy(Fields.createdAt, descending: true)
          .limit(BusinessRules.ordersPageSize),
      accept: (order) =>
          OrderQueryHelpers.normalizeId(order.userId) ==
              OrderQueryHelpers.normalizeId(userId) &&
          OrderQueryHelpers.activePaymentStatuses.contains(
            OrderQueryHelpers.paymentStatusToString(order.paymentStatus),
          ),
      sort: (list) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// Watches a single order matched by Stripe session ID.
  ///
  /// Polls until a captured order with the given session ID exists.
  /// Returns null if no matching order is found.
  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) =>
      watchPaidOrderBySessionImpl(sessionId);

  /// Provides a realtime stream of orders containing items sold by the seller.
  ///
  /// Filters to orders where the seller is listed in `sellerIds`,
  /// with active payment statuses. Sorted by creation date descending.
  @override
  Stream<List<models.Order>> watchSellerOrders(String userId) {
    return watchOrdersImpl(
      initialQuery: () => _ob
          .collection(Collections.orders)
          .where(Fields.sellerIds, contains: userId)
          .where(
            Fields.paymentStatus,
            whereIn: OrderQueryHelpers.activePaymentStatuses,
          )
          .limit(BusinessRules.ordersPageSize),
      accept: (order) {
        final ids = order.sellerIds;
        return ids.any(
              (id) =>
                  OrderQueryHelpers.normalizeId(id) ==
                  OrderQueryHelpers.normalizeId(userId),
            ) &&
            OrderQueryHelpers.activePaymentStatuses.contains(
              OrderQueryHelpers.paymentStatusToString(order.paymentStatus),
            );
      },
      sort: (list) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Return requests
  // ---------------------------------------------------------------------------

  /// Creates a return request for specific items in an order.
  ///
  /// [orderId]: the order containing the items to return.
  /// [cartItemIds]: the specific cart item IDs to return.
  /// [reason]: the return reason code.
  /// [description]: optional free-text description of the issue.
  ///
  /// Returns the server response as a map (includes the return request ID).
  @override
  Future<Map<String, dynamic>> createReturnRequest({
    required String orderId,
    required List<String> cartItemIds,
    required String reason,
    String? description,
  }) async {
    final response = await _ob.request(
      'POST',
      ApiEndpoints.ordersCreateReturn,
      body: {
        Fields.orderId: orderId,
        ApiKeys.itemIds: cartItemIds,
        Fields.returnReason: reason,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Fetches return requests for a specific order.
  ///
  /// [orderId]: the order to query return requests for.
  /// [limit]: max results per page (default 50).
  /// [offset]: number of results to skip for pagination.
  ///
  /// Returns a list of [models.ReturnRequest] models.
  @override
  Future<List<models.ReturnRequest>> fetchReturnRequests(
    String orderId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final snapshot = await _ob
        .collection(Collections.returnRequests)
        .where(Fields.orderId, isEqualTo: orderId)
        .limit(limit)
        .offset(offset)
        .get();
    return snapshot.docs
        .map((doc) => models.ReturnRequest.fromMap(doc.data, doc.id))
        .toList();
  }
}
