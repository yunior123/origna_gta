// coverage:ignore-file
import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/constants.dart' as constants;

/// OrignaBase implementation of [OrderRepository].
///
/// Realtime streams use WebSocket subscriptions on the `orders` collection
/// with client-side filtering by userId/sellerId.  An initial HTTP fetch seeds
/// the state; subsequent WebSocket events update it incrementally.
class OrignaBaseOrderRepository implements OrderRepository {
  final OrignaBase _ob;

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
  // Realtime streams (WebSocket + client-side filtering)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<models.Order>> watchBuyerOrders(String userId) {
    return _watchOrders(
      initialQuery: () => _ob
          .collection(Collections.orders)
          .where(Fields.userId, isEqualTo: userId)
          .where(Fields.paymentStatus, whereIn: _activePaymentStatuses)
          .orderBy(Fields.createdAt, descending: true)
          .limit(BusinessRules.ordersPageSize),
      // Accept this document on realtime events
      accept: (order) =>
          _normalizeId(order.userId) == _normalizeId(userId) &&
          _activePaymentStatuses.contains(order.paymentStatus),
      sort: (list) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) {
    // Session lookup: short-lived stream that polls until the order appears.
    // WebSocket is not suitable here because we don't know the order ID upfront.
    late StreamController<models.Order?> controller;
    Timer? timer;

    Future<void> fetch() async {
      try {
        final snapshot = await _ob
            .collection(Collections.orders)
            .where(Fields.stripeSessionId, isEqualTo: sessionId)
            .where(
              Fields.paymentStatus,
              isEqualTo: constants.PaymentStatus.captured.value,
            )
            .limit(1)
            .get();
        if (!controller.isClosed) {
          final order =
              snapshot.docs.isEmpty ? null : _docToOrder(snapshot.docs.first);
          controller.add(order);
          if (order != null) timer?.cancel(); // Stop once found
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<models.Order?>(
      onListen: () {
        fetch();
        timer = Timer.periodic(const Duration(seconds: 3), (_) => fetch());
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<List<models.Order>> watchSellerOrders(String userId) {
    return _watchOrders(
      initialQuery: () => _ob
          .collection(Collections.orders)
          .where(Fields.sellerIds, contains: userId)
          .where(Fields.paymentStatus, whereIn: _activePaymentStatuses)
          .limit(BusinessRules.ordersPageSize),
      accept: (order) {
        final ids = order.sellerIds ?? <String>[];
        return ids.any((id) => _normalizeId(id) == _normalizeId(userId)) &&
            _activePaymentStatuses.contains(order.paymentStatus);
      },
      sort: (list) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// Strips `collection:` prefix for flexible ID comparison.
  static String _normalizeId(String id) =>
      id.contains(':') ? id.split(':').last : id;

  /// Realtime stream backed by WebSocket subscription on the `orders`
  /// collection.  Seeds state from an initial HTTP fetch, then applies
  /// incremental changes received over the socket.
  Stream<List<models.Order>> _watchOrders({
    required Query Function() initialQuery,
    required bool Function(models.Order) accept,
    required List<models.Order> Function(List<models.Order>) sort,
  }) {
    final state = <String, models.Order>{};
    final controller = StreamController<List<models.Order>>();

    Future<void> seed() async {
      try {
        final snapshot = await initialQuery().get();
        state.clear();
        for (final doc in snapshot.docs) {
          final order = _docToOrder(doc);
          state[order.orderId] = order;
        }
        if (!controller.isClosed) controller.add(sort(state.values.toList()));
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    StreamSubscription<DocumentChange>? wsSub;

    controller
      ..onListen = () async {
        await seed();
        wsSub = _ob.collection(Collections.orders).snapshots().listen(
          (change) {
            if (controller.isClosed) return;
            try {
              final order = _docToOrder(change.document);
              if (change.type == ChangeType.delete || !accept(order)) {
                state.remove(order.orderId);
              } else {
                state[order.orderId] = order;
              }
              controller.add(sort(state.values.toList()));
            } catch (_) {
              // Malformed document — skip silently.
            }
          },
          onError: (_) {/* SDK reconnects automatically; state stays valid. */},
        );
      }
      ..onCancel = () {
        wsSub?.cancel();
      };

    return controller.stream;
  }
}
