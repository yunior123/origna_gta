import 'package:origna_gta/models/generated/base_models.dart';

class OrderStateMachine {
  static const Map<OrderStatus, List<OrderStatus>> _validTransitions = {
    OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
    OrderStatus.confirmed: [OrderStatus.shipped, OrderStatus.cancelled],
    OrderStatus.processing: [OrderStatus.shipped, OrderStatus.cancelled],
    OrderStatus.shipped: [OrderStatus.delivered],
    OrderStatus.inTransit: [OrderStatus.delivered],
    OrderStatus.delivered: <OrderStatus>[],
    OrderStatus.cancelled: <OrderStatus>[],
    OrderStatus.failed: <OrderStatus>[],
    OrderStatus.expired: <OrderStatus>[],
    OrderStatus.disputed: <OrderStatus>[],
    OrderStatus.refunded: <OrderStatus>[],
    OrderStatus.partiallyRefunded: <OrderStatus>[],
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
