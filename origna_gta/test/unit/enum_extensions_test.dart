import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/enum_extensions.dart';

void main() {
  group('Enum Extensions Tests', () {
    test('DeliveryStatusExtension', () {
      expect(DeliveryStatus.pending.displayText, 'Pending');
      expect(DeliveryStatus.pending.value, 'pending');
      expect(DeliveryStatusExtension.fromValue('pending'), DeliveryStatus.pending);
      expect(DeliveryStatusExtension.fromValue('SHIPPED'), DeliveryStatus.shipped);
      expect(DeliveryStatusExtension.fromValue('unknown'), DeliveryStatus.pending);
    });

    test('OrderStatusExtension', () {
      expect(OrderStatus.confirmed.displayText, 'Confirmed');
      expect(OrderStatus.confirmed.value, 'confirmed');
      expect(OrderStatusExtension.fromValue('processing'), OrderStatus.processing);
      expect(OrderStatusExtension.fromValue('IN_TRANSIT'), OrderStatus.inTransit);
      expect(OrderStatusExtension.fromValue(null), OrderStatus.pending);
    });

    test('PaymentStatusExtension', () {
      expect(PaymentStatus.paid.displayText, 'Paid');
      expect(PaymentStatus.paid.value, 'paid');
      expect(PaymentStatusExtension.fromValue('authorized'), PaymentStatus.authorized);
      expect(PaymentStatusExtension.fromValue('CAPTURED'), PaymentStatus.captured);
      expect(PaymentStatusExtension.fromValue('session_expired'), PaymentStatus.sessionExpired);
    });

    test('ShippingApprovalStatusExtension', () {
      expect(ShippingApprovalStatus.approved.displayText, 'Approved');
      expect(ShippingApprovalStatus.approved.value, 'approved');
      expect(ShippingApprovalStatusExtension.fromValue('pending'), ShippingApprovalStatus.pending);
      expect(ShippingApprovalStatusExtension.fromValue('REJECTED'), ShippingApprovalStatus.rejected);
    });
  });
}
