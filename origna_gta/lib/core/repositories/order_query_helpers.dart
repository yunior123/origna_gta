import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/constants.dart' as constants;

/// Extracted realtime stream helpers for [OrignaBaseOrderRepository].
///
/// Contains the generic _watchOrders pattern and session-based polling so the
/// main repository file stays focused on the public API surface.
mixin OrderQueryHelpers {
  OrignaBase get ob;
  models.Order docToOrder(Document doc);

  /// Valid payment statuses for buyer/seller order streams.
  static final activePaymentStatuses = [
    constants.PaymentStatus.authorized.value,
    constants.PaymentStatus.captured.value,
    constants.PaymentStatus.disputed.value,
    constants.PaymentStatus.refunded.value,
    constants.PaymentStatus.cancelled.value,
    constants.PaymentStatus.authorizationExpired.value,
  ];

  /// Converts [models.PaymentStatus] enum to its database string value.
  static String paymentStatusToString(models.PaymentStatus status) {
    switch (status) {
      case models.PaymentStatus.awaitingPayment:
        return PaymentStatusValues.awaitingPayment;
      case models.PaymentStatus.processing:
        return PaymentStatusValues.processing;
      case models.PaymentStatus.paid:
        return PaymentStatusValues.paid;
      case models.PaymentStatus.authorized:
        return PaymentStatusValues.authorized;
      case models.PaymentStatus.captured:
        return PaymentStatusValues.captured;
      case models.PaymentStatus.paymentFailed:
        return PaymentStatusValues.paymentFailed;
      case models.PaymentStatus.refunded:
        return PaymentStatusValues.refunded;
      case models.PaymentStatus.sessionExpired:
        return PaymentStatusValues.sessionExpired;
      case models.PaymentStatus.cancelled:
        return PaymentStatusValues.cancelled;
      case models.PaymentStatus.authorizationExpired:
        return PaymentStatusValues.authorizationExpired;
      case models.PaymentStatus.disputed:
        return PaymentStatusValues.disputed;
      case models.PaymentStatus.capturing:
        return PaymentStatusValues.capturing;
      case models.PaymentStatus.cancelling:
        return PaymentStatusValues.cancelling;
      case models.PaymentStatus.expiring:
        return PaymentStatusValues.expiring;
      case models.PaymentStatus.partiallyRefunded:
        return PaymentStatusValues.partiallyRefunded;
      case models.PaymentStatus.voided:
        return PaymentStatusValues.voided;
      case models.PaymentStatus.cancelFailed:
        return PaymentStatusValues.cancelFailed;
    }
  }

  /// Strips `collection:` prefix for flexible ID comparison.
  static String normalizeId(String id) =>
      id.contains(':') ? id.split(':').last : id;

  /// Realtime stream backed by WebSocket subscription on the `orders`
  /// collection. Seeds state from an initial HTTP fetch, then applies
  /// incremental changes received over the socket.
  Stream<List<models.Order>> watchOrdersImpl({
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
          final order = docToOrder(doc);
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
        wsSub = ob
            .collection(Collections.orders)
            .snapshots()
            .listen(
              (change) {
                if (controller.isClosed) return;
                try {
                  final order = docToOrder(change.document);
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
              onError: (_) {
                /* SDK reconnects automatically; state stays valid. */
              },
            );
      }
      ..onCancel = () {
        wsSub?.cancel();
      };

    return controller.stream;
  }

  /// Session lookup: short-lived stream that polls until the order appears.
  /// WebSocket is not suitable here because we don't know the order ID upfront.
  Stream<models.Order?> watchPaidOrderBySessionImpl(String sessionId) {
    late StreamController<models.Order?> controller;
    Timer? timer;

    Future<void> fetch() async {
      try {
        final snapshot = await ob
            .collection(Collections.orders)
            .where(Fields.stripeSessionId, isEqualTo: sessionId)
            .where(
              Fields.paymentStatus,
              isEqualTo: constants.PaymentStatus.captured.value,
            )
            .limit(1)
            .get();
        if (!controller.isClosed) {
          final order = snapshot.docs.isEmpty
              ? null
              : docToOrder(snapshot.docs.first);
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
}
