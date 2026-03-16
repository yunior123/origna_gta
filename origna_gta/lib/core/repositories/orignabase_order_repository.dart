// coverage:ignore-file
import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/constants.dart' as constants;

/// OrignaBase implementation of [OrderRepository].
///
/// For realtime streams: OrignaBase does not support query-level `.snapshots()`
/// yet (only document and collection level). Streams are implemented using
/// periodic polling with client-side filtering.
class OrignaBaseOrderRepository implements OrderRepository {
  final OrignaBase _ob;

  /// Polling interval for realtime stream simulation.
  static const _pollInterval = Duration(seconds: 5);

  OrignaBaseOrderRepository(this._ob);

  // ---------------------------------------------------------------------------
  // Helper: convert an OrignaBase Document to a models.Order
  // ---------------------------------------------------------------------------
  models.Order _docToOrder(Document doc) {
    final data = <String, dynamic>{...doc.data, Fields.orderId: doc.id};
    // Normalize timestamps from ISO strings if needed (OrignaBase stores strings)
    return models.Order.fromJson(data);
  }

  /// Valid payment statuses for buyer/seller order streams.
  static final _activePaymentStatuses = [
    constants.PaymentStatus.authorized.value,
    constants.PaymentStatus.captured.value,
    constants.PaymentStatus.disputed.value,
    constants.PaymentStatus.refunded.value,
    constants.PaymentStatus.cancelled.value,
    constants.PaymentStatus.authorizationExpired.value,
  ];

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
      // Per-item receipt confirmation — triggers partial payout for that seller
      await _ob.request(
        'POST',
        ApiEndpoints.ordersConfirmReceipt,
        body: {Fields.orderId: orderId, Fields.productId: productId},
      );
    } else {
      // Whole-order payment capture (single-seller path)
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
    return _docToOrder(doc);
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
    double newShippingCost,
    String reason,
  ) async {
    await _ob.request(
      'POST',
      ApiEndpoints.ordersUpdateShipping,
      body: {
        Fields.orderId: orderId,
        ApiKeys.newShippingCost: newShippingCost,
        ApiKeys.reason: reason,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Realtime streams (polling-based until OrignaBase supports query snapshots)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<models.Order>> watchBuyerOrders(String userId) {
    return _pollOrders(
      queryBuilder: () => _ob
          .collection(Collections.orders)
          .where(Fields.userId, isEqualTo: userId)
          .where(Fields.paymentStatus, whereIn: _activePaymentStatuses)
          .orderBy(Fields.createdAt, descending: true)
          .limit(BusinessRules.ordersPageSize),
    );
  }

  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) {
    return _pollOrders(
      queryBuilder: () => _ob
          .collection(Collections.orders)
          .where(Fields.stripeSessionId, isEqualTo: sessionId)
          .where(
            Fields.paymentStatus,
            isEqualTo: constants.PaymentStatus.captured.value,
          )
          .limit(1),
    ).map((orders) => orders.isEmpty ? null : orders.first);
  }

  @override
  Stream<List<models.Order>> watchSellerOrders(String userId) {
    return _pollOrders(
      queryBuilder: () => _ob
          .collection(Collections.orders)
          .where(Fields.sellerIds, contains: userId)
          .where(Fields.paymentStatus, whereIn: _activePaymentStatuses)
          .limit(BusinessRules.ordersPageSize),
      clientSort: (orders) {
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      },
    );
  }

  /// Generic polling helper that periodically executes a query and emits results.
  Stream<List<models.Order>> _pollOrders({
    required Query Function() queryBuilder,
    List<models.Order> Function(List<models.Order>)? clientSort,
  }) {
    late StreamController<List<models.Order>> controller;
    Timer? timer;

    Future<void> fetch() async {
      try {
        final snapshot = await queryBuilder().get();
        var orders = snapshot.docs.map(_docToOrder).toList();
        if (clientSort != null) {
          orders = clientSort(orders);
        }
        if (!controller.isClosed) {
          controller.add(orders);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<List<models.Order>>(
      onListen: () {
        fetch(); // Initial fetch
        timer = Timer.periodic(_pollInterval, (_) => fetch());
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
