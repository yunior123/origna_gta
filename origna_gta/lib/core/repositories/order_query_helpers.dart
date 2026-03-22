import 'dart:async';

import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/base_models.dart'
    show PaymentStatus;
import 'package:origna_gta/models/generated/models.dart' as models;

/// Extracted realtime stream helpers for [OrignaBaseOrderRepository].
///
/// Contains the generic _watchOrders pattern and session-based polling so the
/// main repository file stays focused on the public API surface.
mixin OrderQueryHelpers {
  OrignaBase get ob;
  models.Order docToOrder(Document doc);

  /// Valid payment statuses for buyer/seller order streams.
  static final activePaymentStatuses = [
    PaymentStatus.authorized.value,
    PaymentStatus.captured.value,
    PaymentStatus.disputed.value,
    PaymentStatus.refunded.value,
    PaymentStatus.cancelled.value,
    PaymentStatus.authorizationExpired.value,
  ];

  /// Converts [PaymentStatus] enum to its database string value.
  static String paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.awaitingPayment:
        return PaymentStatusValues.awaitingPayment;
      case PaymentStatus.processing:
        return PaymentStatusValues.processing;
      case PaymentStatus.paid:
        return PaymentStatusValues.paid;
      case PaymentStatus.authorized:
        return PaymentStatusValues.authorized;
      case PaymentStatus.captured:
        return PaymentStatusValues.captured;
      case PaymentStatus.paymentFailed:
        return PaymentStatusValues.paymentFailed;
      case PaymentStatus.refunded:
        return PaymentStatusValues.refunded;
      case PaymentStatus.sessionExpired:
        return PaymentStatusValues.sessionExpired;
      case PaymentStatus.cancelled:
        return PaymentStatusValues.cancelled;
      case PaymentStatus.authorizationExpired:
        return PaymentStatusValues.authorizationExpired;
      case PaymentStatus.disputed:
        return PaymentStatusValues.disputed;
      case PaymentStatus.capturing:
        return PaymentStatusValues.capturing;
      case PaymentStatus.cancelling:
        return PaymentStatusValues.cancelling;
      case PaymentStatus.expiring:
        return PaymentStatusValues.expiring;
      case PaymentStatus.partiallyRefunded:
        return PaymentStatusValues.partiallyRefunded;
      case PaymentStatus.voided:
        return PaymentStatusValues.voided;
      case PaymentStatus.cancelFailed:
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
          if (accept(order)) {
            state[order.orderId] = order;
          }
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
              isEqualTo: PaymentStatus.captured.value,
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
