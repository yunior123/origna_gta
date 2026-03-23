import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/enum_extensions.dart';

void main() {
  group('DeliveryStatusExtension', () {
    test('displayText for all values', () {
      // displayText uses .tr() — returns the key when EasyLocalization is not initialized
      expect(DeliveryStatus.pending.displayText, 'delivery_status.pending');
      expect(DeliveryStatus.shipped.displayText, 'delivery_status.shipped');
      expect(DeliveryStatus.delivered.displayText, 'delivery_status.delivered');
      expect(DeliveryStatus.refunded.displayText, 'delivery_status.refunded');
    });

    test('value for all values', () {
      expect(DeliveryStatus.pending.value, 'pending');
      expect(DeliveryStatus.shipped.value, 'shipped');
      expect(DeliveryStatus.delivered.value, 'delivered');
      expect(DeliveryStatus.refunded.value, 'refunded');
    });

    test('fromValue parses all values', () {
      expect(
        DeliveryStatusExtension.fromValue('pending'),
        DeliveryStatus.pending,
      );
      expect(
        DeliveryStatusExtension.fromValue('shipped'),
        DeliveryStatus.shipped,
      );
      expect(
        DeliveryStatusExtension.fromValue('delivered'),
        DeliveryStatus.delivered,
      );
      expect(
        DeliveryStatusExtension.fromValue('refunded'),
        DeliveryStatus.refunded,
      );
      expect(
        DeliveryStatusExtension.fromValue('SHIPPED'),
        DeliveryStatus.shipped,
      );
      expect(DeliveryStatusExtension.fromValue(null), DeliveryStatus.pending);
      expect(
        DeliveryStatusExtension.fromValue('unknown'),
        DeliveryStatus.pending,
      );
    });
  });

  group('OrderStatusExtension', () {
    test('displayText for all values', () {
      // displayText uses .tr() — returns the key when EasyLocalization is not initialized
      expect(OrderStatus.pending.displayText, 'orders.status.pending');
      expect(OrderStatus.confirmed.displayText, 'orders.status.confirmed');
      expect(OrderStatus.processing.displayText, 'orders.status.processing');
      expect(OrderStatus.shipped.displayText, 'orders.status.shipped');
      expect(OrderStatus.inTransit.displayText, 'orders.status.in_transit');
      expect(OrderStatus.delivered.displayText, 'orders.status.delivered');
      expect(OrderStatus.cancelled.displayText, 'orders.status.cancelled');
      expect(OrderStatus.failed.displayText, 'orders.status.failed');
      expect(OrderStatus.expired.displayText, 'orders.status.expired');
      expect(OrderStatus.disputed.displayText, 'orders.status.disputed');
      expect(OrderStatus.refunded.displayText, 'orders.status.refunded');
      expect(
        OrderStatus.partiallyRefunded.displayText,
        'orders.status.partially_refunded',
      );
    });

    test('value for all values', () {
      expect(OrderStatus.pending.value, 'pending');
      expect(OrderStatus.confirmed.value, 'confirmed');
      expect(OrderStatus.processing.value, 'processing');
      expect(OrderStatus.shipped.value, 'shipped');
      expect(OrderStatus.inTransit.value, 'in_transit');
      expect(OrderStatus.delivered.value, 'delivered');
      expect(OrderStatus.cancelled.value, 'cancelled');
      expect(OrderStatus.failed.value, 'failed');
      expect(OrderStatus.expired.value, 'expired');
      expect(OrderStatus.disputed.value, 'disputed');
      expect(OrderStatus.refunded.value, 'refunded');
      expect(OrderStatus.partiallyRefunded.value, 'partially_refunded');
    });

    test('fromValue parses all values', () {
      expect(OrderStatusExtension.fromValue('pending'), OrderStatus.pending);
      expect(
        OrderStatusExtension.fromValue('confirmed'),
        OrderStatus.confirmed,
      );
      expect(
        OrderStatusExtension.fromValue('processing'),
        OrderStatus.processing,
      );
      expect(OrderStatusExtension.fromValue('shipped'), OrderStatus.shipped);
      expect(
        OrderStatusExtension.fromValue('in_transit'),
        OrderStatus.inTransit,
      );
      expect(
        OrderStatusExtension.fromValue('delivered'),
        OrderStatus.delivered,
      );
      expect(
        OrderStatusExtension.fromValue('cancelled'),
        OrderStatus.cancelled,
      );
      expect(OrderStatusExtension.fromValue('failed'), OrderStatus.failed);
      expect(OrderStatusExtension.fromValue('expired'), OrderStatus.expired);
      expect(OrderStatusExtension.fromValue('disputed'), OrderStatus.disputed);
      expect(
        OrderStatusExtension.fromValue('IN_TRANSIT'),
        OrderStatus.inTransit,
      );
      expect(OrderStatusExtension.fromValue(null), OrderStatus.pending);
      expect(OrderStatusExtension.fromValue('unknown'), OrderStatus.pending);
    });
  });

  group('PaymentStatusExtension', () {
    test('displayText for all values', () {
      // displayText uses .tr() — returns the key when EasyLocalization is not initialized
      expect(
        PaymentStatus.awaitingPayment.displayText,
        'payment_status.awaiting_payment',
      );
      expect(PaymentStatus.processing.displayText, 'payment_status.processing');
      expect(PaymentStatus.paid.displayText, 'payment_status.paid');
      expect(PaymentStatus.authorized.displayText, 'payment_status.authorized');
      expect(PaymentStatus.captured.displayText, 'payment_status.captured');
      expect(
        PaymentStatus.paymentFailed.displayText,
        'payment_status.payment_failed',
      );
      expect(PaymentStatus.refunded.displayText, 'payment_status.refunded');
      expect(
        PaymentStatus.partiallyRefunded.displayText,
        'payment_status.partially_refunded',
      );
      expect(PaymentStatus.voided.displayText, 'payment_status.voided');
      expect(
        PaymentStatus.sessionExpired.displayText,
        'payment_status.session_expired',
      );
      expect(PaymentStatus.cancelled.displayText, 'payment_status.cancelled');
      expect(
        PaymentStatus.authorizationExpired.displayText,
        'payment_status.authorization_expired',
      );
      expect(PaymentStatus.disputed.displayText, 'payment_status.disputed');
      expect(PaymentStatus.capturing.displayText, 'payment_status.capturing');
      expect(PaymentStatus.cancelling.displayText, 'payment_status.cancelling');
      expect(PaymentStatus.expiring.displayText, 'payment_status.expiring');
      expect(
        PaymentStatus.cancelFailed.displayText,
        'payment_status.cancel_failed',
      );
    });

    test('value for all values', () {
      expect(PaymentStatus.awaitingPayment.value, 'awaiting_payment');
      expect(PaymentStatus.processing.value, 'processing');
      expect(PaymentStatus.paid.value, 'paid');
      expect(PaymentStatus.authorized.value, 'authorized');
      expect(PaymentStatus.captured.value, 'captured');
      expect(PaymentStatus.paymentFailed.value, 'payment_failed');
      expect(PaymentStatus.refunded.value, 'refunded');
      expect(PaymentStatus.partiallyRefunded.value, 'partially_refunded');
      expect(PaymentStatus.voided.value, 'voided');
      expect(PaymentStatus.sessionExpired.value, 'session_expired');
      expect(PaymentStatus.cancelled.value, 'cancelled');
      expect(PaymentStatus.authorizationExpired.value, 'authorization_expired');
      expect(PaymentStatus.disputed.value, 'disputed');
      expect(PaymentStatus.capturing.value, 'capturing');
      expect(PaymentStatus.cancelling.value, 'cancelling');
      expect(PaymentStatus.expiring.value, 'expiring');
      expect(PaymentStatus.cancelFailed.value, 'cancel_failed');
    });

    test('fromValue parses all values', () {
      expect(
        PaymentStatusExtension.fromValue('awaiting_payment'),
        PaymentStatus.awaitingPayment,
      );
      expect(
        PaymentStatusExtension.fromValue('processing'),
        PaymentStatus.processing,
      );
      expect(PaymentStatusExtension.fromValue('paid'), PaymentStatus.paid);
      expect(
        PaymentStatusExtension.fromValue('authorized'),
        PaymentStatus.authorized,
      );
      expect(
        PaymentStatusExtension.fromValue('captured'),
        PaymentStatus.captured,
      );
      expect(
        PaymentStatusExtension.fromValue('payment_failed'),
        PaymentStatus.paymentFailed,
      );
      expect(
        PaymentStatusExtension.fromValue('refunded'),
        PaymentStatus.refunded,
      );
      expect(
        PaymentStatusExtension.fromValue('session_expired'),
        PaymentStatus.sessionExpired,
      );
      expect(
        PaymentStatusExtension.fromValue('cancelled'),
        PaymentStatus.cancelled,
      );
      expect(
        PaymentStatusExtension.fromValue('authorization_expired'),
        PaymentStatus.authorizationExpired,
      );
      expect(
        PaymentStatusExtension.fromValue('disputed'),
        PaymentStatus.disputed,
      );
      expect(
        PaymentStatusExtension.fromValue('capturing'),
        PaymentStatus.capturing,
      );
      expect(
        PaymentStatusExtension.fromValue('cancelling'),
        PaymentStatus.cancelling,
      );
      expect(
        PaymentStatusExtension.fromValue('expiring'),
        PaymentStatus.expiring,
      );
      expect(
        PaymentStatusExtension.fromValue('CAPTURED'),
        PaymentStatus.captured,
      );
      expect(
        PaymentStatusExtension.fromValue(null),
        PaymentStatus.awaitingPayment,
      );
      expect(
        PaymentStatusExtension.fromValue('invalid'),
        PaymentStatus.awaitingPayment,
      );
    });
  });

  group('ShippingApprovalStatusExtension', () {
    test('displayText for all values', () {
      // displayText uses .tr() — returns the key when EasyLocalization is not initialized
      expect(
        ShippingApprovalStatus.notRequired.displayText,
        'shipping_approval_status.not_required',
      );
      expect(
        ShippingApprovalStatus.pending.displayText,
        'shipping_approval_status.pending',
      );
      expect(
        ShippingApprovalStatus.approved.displayText,
        'shipping_approval_status.approved',
      );
      expect(
        ShippingApprovalStatus.rejected.displayText,
        'shipping_approval_status.rejected',
      );
    });

    test('value for all values', () {
      expect(ShippingApprovalStatus.notRequired.value, 'not_required');
      expect(ShippingApprovalStatus.pending.value, 'pending');
      expect(ShippingApprovalStatus.approved.value, 'approved');
      expect(ShippingApprovalStatus.rejected.value, 'rejected');
    });

    test('fromValue parses all values', () {
      expect(
        ShippingApprovalStatusExtension.fromValue('not_required'),
        ShippingApprovalStatus.notRequired,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue('pending'),
        ShippingApprovalStatus.pending,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue('approved'),
        ShippingApprovalStatus.approved,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue('rejected'),
        ShippingApprovalStatus.rejected,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue('REJECTED'),
        ShippingApprovalStatus.rejected,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue(null),
        ShippingApprovalStatus.notRequired,
      );
      expect(
        ShippingApprovalStatusExtension.fromValue('bad'),
        ShippingApprovalStatus.notRequired,
      );
    });
  });
}
