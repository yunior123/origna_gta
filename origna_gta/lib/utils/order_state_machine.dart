import 'package:origna_gta/models/generated/base_models.dart';

class OrderStateMachine {
  static const Map<OrderStatus, List<OrderStatus>> _validTransitions = {
    OrderStatus.pending: [
      OrderStatus.confirmed,
      OrderStatus.cancelled,
      OrderStatus.refunded,
    ],
    OrderStatus.confirmed: [
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.cancelled,
      OrderStatus.refunded,
      OrderStatus.partiallyRefunded,
    ],
    OrderStatus.processing: [
      OrderStatus.shipped,
      OrderStatus.cancelled,
      OrderStatus.refunded,
      OrderStatus.partiallyRefunded,
    ],
    OrderStatus.shipped: [
      OrderStatus.inTransit,
      OrderStatus.refunded,
      OrderStatus.partiallyRefunded,
    ],
    OrderStatus.inTransit: [
      OrderStatus.delivered,
      OrderStatus.refunded,
      OrderStatus.partiallyRefunded,
    ],
    OrderStatus.delivered: [
      OrderStatus.refunded,
      OrderStatus.partiallyRefunded,
    ],
    OrderStatus.cancelled: <OrderStatus>[],
    OrderStatus.failed: <OrderStatus>[],
    OrderStatus.expired: <OrderStatus>[],
    OrderStatus.disputed: [OrderStatus.refunded, OrderStatus.partiallyRefunded],
    OrderStatus.refunded: <OrderStatus>[],
    OrderStatus.partiallyRefunded: [OrderStatus.refunded],
  };

  static bool canTransition(OrderStatus from, OrderStatus to) {
    final allowed = _validTransitions[from];
    if (allowed == null) return false;
    return allowed.contains(to);
  }

  static List<OrderStatus> getValidTransitions(OrderStatus from) {
    return _validTransitions[from] ?? [];
  }

  static bool isTerminal(OrderStatus status) {
    return _validTransitions[status]?.isEmpty ?? false;
  }
}
