// Extensions pour les enums Freezed - fournit compatibilité avec ancien code
import 'package:origna_gta/models/generated/models.dart';

// ============================================================================
// DELIVERY STATUS EXTENSIONS
// ============================================================================

extension DeliveryStatusExtension on DeliveryStatus {
  /// Get display text for UI
  String get displayText {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.processing:
        return 'Processing';
      case DeliveryStatus.shipped:
        return 'Shipped';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.returned:
        return 'Returned';
    }
  }

  /// Get string value for API/database
  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.processing:
        return 'processing';
      case DeliveryStatus.shipped:
        return 'shipped';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
      case DeliveryStatus.returned:
        return 'returned';
    }
  }

  /// Parse from string value
  static DeliveryStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'processing':
        return DeliveryStatus.processing;
      case 'shipped':
        return DeliveryStatus.shipped;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'returned':
        return DeliveryStatus.returned;
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
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
    }
  }

  static OrderStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
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
      case PaymentStatus.paymentReceived:
        return 'Payment Received';
      case PaymentStatus.paymentFailed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  String get value {
    switch (this) {
      case PaymentStatus.awaitingPayment:
        return 'awaiting_payment';
      case PaymentStatus.paymentReceived:
        return 'payment_received';
      case PaymentStatus.paymentFailed:
        return 'payment_failed';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
    }
  }

  static PaymentStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'awaiting_payment':
        return PaymentStatus.awaitingPayment;
      case 'payment_received':
      case 'authorized': // Legacy compatibility
        return PaymentStatus.paymentReceived;
      case 'payment_failed':
        return PaymentStatus.paymentFailed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
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
