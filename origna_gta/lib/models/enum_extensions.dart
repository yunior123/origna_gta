// Extensions for Freezed enums — provides displayText, value, fromValue
import 'package:origna_gta/models/generated/models.dart';

// ============================================================================
// DELIVERY STATUS EXTENSIONS
// ============================================================================

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayText {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.shipped:
        return 'Shipped';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }

  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.shipped:
        return 'shipped';
      case DeliveryStatus.delivered:
        return 'delivered';
    }
  }

  static DeliveryStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'shipped':
        return DeliveryStatus.shipped;
      case 'delivered':
        return DeliveryStatus.delivered;
      default:
        return DeliveryStatus.pending;
    }
  }
}

// ============================================================================
// ORDER STATUS EXTENSIONS
// ============================================================================

extension OrderStatusExtension on OrderStatus {
  String get displayText {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.failed:
        return 'failed';
      case OrderStatus.expired:
        return 'expired';
      case OrderStatus.refunded:
        return 'refunded';
      case OrderStatus.partiallyRefunded:
        return 'partially_refunded';
    }
  }

  static OrderStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'failed':
        return OrderStatus.failed;
      case 'expired':
        return OrderStatus.expired;
      case 'refunded':
        return OrderStatus.refunded;
      case 'partially_refunded':
        return OrderStatus.partiallyRefunded;
      default:
        return OrderStatus.pending;
    }
  }
}

// ============================================================================
// PAYMENT STATUS EXTENSIONS
// ============================================================================

extension PaymentStatusExtension on PaymentStatus {
  String get displayText {
    switch (this) {
      case PaymentStatus.awaitingPayment:
        return 'Awaiting Payment';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.authorized:
        return 'Authorized';
      case PaymentStatus.captured:
        return 'Captured';
      case PaymentStatus.paymentFailed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.sessionExpired:
        return 'Session Expired';
    }
  }

  String get value {
    switch (this) {
      case PaymentStatus.awaitingPayment:
        return 'awaiting_payment';
      case PaymentStatus.processing:
        return 'processing';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.authorized:
        return 'authorized';
      case PaymentStatus.captured:
        return 'captured';
      case PaymentStatus.paymentFailed:
        return 'payment_failed';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.sessionExpired:
        return 'session_expired';
    }
  }

  static PaymentStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'awaiting_payment':
        return PaymentStatus.awaitingPayment;
      case 'processing':
        return PaymentStatus.processing;
      case 'paid':
        return PaymentStatus.paid;
      case 'authorized':
        return PaymentStatus.authorized;
      case 'captured':
        return PaymentStatus.captured;
      case 'payment_failed':
        return PaymentStatus.paymentFailed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'session_expired':
        return PaymentStatus.sessionExpired;
      default:
        return PaymentStatus.awaitingPayment;
    }
  }
}

// ============================================================================
// SHIPPING APPROVAL STATUS EXTENSIONS
// ============================================================================

extension ShippingApprovalStatusExtension on ShippingApprovalStatus {
  String get displayText {
    switch (this) {
      case ShippingApprovalStatus.notRequired:
        return 'Not Required';
      case ShippingApprovalStatus.pending:
        return 'Pending Approval';
      case ShippingApprovalStatus.approved:
        return 'Approved';
      case ShippingApprovalStatus.rejected:
        return 'Rejected';
    }
  }

  String get value {
    switch (this) {
      case ShippingApprovalStatus.notRequired:
        return 'not_required';
      case ShippingApprovalStatus.pending:
        return 'pending';
      case ShippingApprovalStatus.approved:
        return 'approved';
      case ShippingApprovalStatus.rejected:
        return 'rejected';
    }
  }

  static ShippingApprovalStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'not_required':
        return ShippingApprovalStatus.notRequired;
      case 'pending':
        return ShippingApprovalStatus.pending;
      case 'approved':
        return ShippingApprovalStatus.approved;
      case 'rejected':
        return ShippingApprovalStatus.rejected;
      default:
        return ShippingApprovalStatus.notRequired;
    }
  }
}
