import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/utils/order_state_machine.dart';

void main() {
  group('OrderStateMachine - Valid Transitions', () {
    test('pending -> confirmed is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.pending, OrderStatus.confirmed), isTrue);
    });

    test('pending -> cancelled is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.pending, OrderStatus.cancelled), isTrue);
    });

    test('confirmed -> shipped is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.confirmed, OrderStatus.shipped), isTrue);
    });

    test('confirmed -> cancelled is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.confirmed, OrderStatus.cancelled), isTrue);
    });

    test('shipped -> delivered is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.shipped, OrderStatus.delivered), isTrue);
    });

    test('processing -> shipped is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.processing, OrderStatus.shipped), isTrue);
    });

    test('processing -> cancelled is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.processing, OrderStatus.cancelled), isTrue);
    });

    test('inTransit -> delivered is valid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.inTransit, OrderStatus.delivered), isTrue);
    });

    test('pending -> shipped is invalid (skipping confirmed)', () {
      expect(OrderStateMachine.canTransition(OrderStatus.pending, OrderStatus.shipped), isFalse);
    });

    test('pending -> delivered is invalid (skipping states)', () {
      expect(OrderStateMachine.canTransition(OrderStatus.pending, OrderStatus.delivered), isFalse);
    });
  });

  group('OrderStateMachine - Invalid Transitions from Terminal States', () {
    test('delivered -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.delivered, OrderStatus.pending), isFalse);
    });

    test('delivered -> confirmed is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.delivered, OrderStatus.confirmed), isFalse);
    });

    test('delivered -> shipped is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.delivered, OrderStatus.shipped), isFalse);
    });

    test('delivered -> cancelled is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.delivered, OrderStatus.cancelled), isFalse);
    });

    test('cancelled -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.cancelled, OrderStatus.pending), isFalse);
    });

    test('cancelled -> confirmed is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.cancelled, OrderStatus.confirmed), isFalse);
    });

    test('cancelled -> delivered is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.cancelled, OrderStatus.delivered), isFalse);
    });

    test('failed -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.failed, OrderStatus.pending), isFalse);
    });

    test('expired -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.expired, OrderStatus.pending), isFalse);
    });

    test('disputed -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.disputed, OrderStatus.pending), isFalse);
    });

    test('refunded -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.refunded, OrderStatus.pending), isFalse);
    });

    test('partiallyRefunded -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.partiallyRefunded, OrderStatus.pending), isFalse);
    });
  });

  group('OrderStateMachine - Other Invalid Transitions', () {
    test('confirmed -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.confirmed, OrderStatus.pending), isFalse);
    });

    test('shipped -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.shipped, OrderStatus.pending), isFalse);
    });

    test('shipped -> confirmed is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.shipped, OrderStatus.confirmed), isFalse);
    });

    test('shipped -> cancelled is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.shipped, OrderStatus.cancelled), isFalse);
    });

    test('processing -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.processing, OrderStatus.pending), isFalse);
    });

    test('inTransit -> pending is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.inTransit, OrderStatus.pending), isFalse);
    });

    test('inTransit -> cancelled is invalid', () {
      expect(OrderStateMachine.canTransition(OrderStatus.inTransit, OrderStatus.cancelled), isFalse);
    });
  });

  group('OrderStateMachine - Terminal State Detection', () {
    test('delivered is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.delivered), isTrue);
    });

    test('cancelled is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.cancelled), isTrue);
    });

    test('failed is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.failed), isTrue);
    });

    test('expired is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.expired), isTrue);
    });

    test('disputed is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.disputed), isTrue);
    });

    test('refunded is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.refunded), isTrue);
    });

    test('partiallyRefunded is terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.partiallyRefunded), isTrue);
    });

    test('pending is not terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.pending), isFalse);
    });

    test('confirmed is not terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.confirmed), isFalse);
    });

    test('shipped is not terminal', () {
      expect(OrderStateMachine.isTerminal(OrderStatus.shipped), isFalse);
    });
  });

  group('OrderStateMachine - Get Valid Transitions', () {
    test('pending returns confirmed and cancelled', () {
      final transitions = OrderStateMachine.getValidTransitions(OrderStatus.pending);
      expect(transitions, containsAll([OrderStatus.confirmed, OrderStatus.cancelled]));
      expect(transitions.length, 2);
    });

    test('confirmed returns shipped and cancelled', () {
      final transitions = OrderStateMachine.getValidTransitions(OrderStatus.confirmed);
      expect(transitions, containsAll([OrderStatus.shipped, OrderStatus.cancelled]));
      expect(transitions.length, 2);
    });

    test('shipped returns delivered only', () {
      final transitions = OrderStateMachine.getValidTransitions(OrderStatus.shipped);
      expect(transitions, contains(OrderStatus.delivered));
      expect(transitions.length, 1);
    });

    test('delivered returns empty list', () {
      final transitions = OrderStateMachine.getValidTransitions(OrderStatus.delivered);
      expect(transitions, isEmpty);
    });

    test('cancelled returns empty list', () {
      final transitions = OrderStateMachine.getValidTransitions(OrderStatus.cancelled);
      expect(transitions, isEmpty);
    });
  });

  group('OrderStateMachine - Complete Lifecycle', () {
    test('full valid lifecycle: pending -> confirmed -> shipped -> delivered', () {
      var currentStatus = OrderStatus.pending;
      
      expect(OrderStateMachine.canTransition(currentStatus, OrderStatus.confirmed), isTrue);
      currentStatus = OrderStatus.confirmed;
      
      expect(OrderStateMachine.canTransition(currentStatus, OrderStatus.shipped), isTrue);
      currentStatus = OrderStatus.shipped;
      
      expect(OrderStateMachine.canTransition(currentStatus, OrderStatus.delivered), isTrue);
      currentStatus = OrderStatus.delivered;
      
      expect(OrderStateMachine.isTerminal(currentStatus), isTrue);
    });

    test('cancellation path: pending -> cancelled', () {
      expect(OrderStateMachine.canTransition(OrderStatus.pending, OrderStatus.cancelled), isTrue);
      expect(OrderStateMachine.isTerminal(OrderStatus.cancelled), isTrue);
    });

    test('cancellation path: confirmed -> cancelled', () {
      expect(OrderStateMachine.canTransition(OrderStatus.confirmed, OrderStatus.cancelled), isTrue);
      expect(OrderStateMachine.isTerminal(OrderStatus.cancelled), isTrue);
    });

    test('cancellation path: processing -> cancelled', () {
      expect(OrderStateMachine.canTransition(OrderStatus.processing, OrderStatus.cancelled), isTrue);
      expect(OrderStateMachine.isTerminal(OrderStatus.cancelled), isTrue);
    });
  });
}
