import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/models.dart';

void main() {
  group('Enum Extensions', () {
    test('DeliveryStatus extension maps values', () {
      expect(DeliveryStatus.pending.value, 'pending');
      expect(DeliveryStatus.shipped.displayText, 'Shipped');
      expect(DeliveryStatusExtension.fromValue('delivered'), DeliveryStatus.delivered);
      expect(DeliveryStatusExtension.fromValue('UNKNOWN'), DeliveryStatus.pending);
    });

    test('PaymentStatus extension handles legacy authorized', () {
      expect(PaymentStatusExtension.fromValue('authorized'), PaymentStatus.paymentReceived);
      expect(PaymentStatus.paymentReceived.value, 'payment_received');
      expect(PaymentStatus.refunded.displayText, 'Refunded');
    });

    test('ShippingApprovalStatus extension maps values', () {
      expect(ShippingApprovalStatus.pending.value, 'pending');
      expect(ShippingApprovalStatus.rejected.displayText, 'Rejected');
      expect(ShippingApprovalStatusExtension.fromValue('not_required'), ShippingApprovalStatus.notRequired);
    });

    test('OrderStatus extension maps values', () {
      expect(OrderStatus.pending.value, 'pending');
      expect(OrderStatus.delivered.displayText, 'Delivered');
      expect(OrderStatusExtension.fromValue('refunded'), OrderStatus.refunded);
    });
  });
}
