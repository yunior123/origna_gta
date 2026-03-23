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
class OrignaBaseOrderRepository
    with OrderQueryHelpers
    implements OrderRepository {
  final OrignaBase _ob;

  OrignaBaseOrderRepository(this._ob);

  // Mixin accessor
  @override
  OrignaBase get ob => _ob;

  // ---------------------------------------------------------------------------
  // Helper: convert an OrignaBase Document to a models.Order
  // ---------------------------------------------------------------------------
  @override
  models.Order docToOrder(Document doc) {
    final data = <String, dynamic>{...doc.data, Fields.orderId: doc.id};
    return models.Order.fromMap(data, doc.id);
  }

  // ---------------------------------------------------------------------------
  // Backend action calls via ob.request
  // ---------------------------------------------------------------------------

  @override
  Future<void> approveShippingCost(String orderId, bool approved) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersApproveShipping,
      body: {Fields.orderId: orderId, ApiKeys.approved: approved},
    );
  }

  @override
  Future<void> capturePayment(String orderId) async {
    await _ob.request(
      'POST',
      ApiEndpoints.paymentsCapture,
      body: {Fields.orderId: orderId},
    );
  }

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

  @override
  Future<models.Order?> fetchOrderById(String orderId) async {
    final doc = await _ob.collection(Collections.orders).doc(orderId).get();
    if (doc == null || !doc.exists) return null;
    return docToOrder(doc);
  }

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
        ApiKeys.newShippingCost: newShippingCostCents,
        ApiKeys.reason: reason,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Realtime streams — delegated to OrderQueryHelpers mixin
  // ---------------------------------------------------------------------------

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

  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) =>
      watchPaidOrderBySessionImpl(sessionId);

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
