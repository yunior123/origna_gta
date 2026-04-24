// Extensions for Freezed enums — provides displayText, value, fromValue
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';

// ============================================================================
// DELIVERY STATUS EXTENSIONS
// ============================================================================

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayText {
    switch (this) {
      case DeliveryStatus.pending:
        return 'delivery_status.pending'.tr();
      case DeliveryStatus.shipped:
        return 'delivery_status.shipped'.tr();
      case DeliveryStatus.delivered:
        return 'delivery_status.delivered'.tr();
      case DeliveryStatus.refunded:
        return 'delivery_status.refunded'.tr();
    }
  }

  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return DeliveryStatusValues.pending;
      case DeliveryStatus.shipped:
        return DeliveryStatusValues.shipped;
      case DeliveryStatus.delivered:
        return DeliveryStatusValues.delivered;
      case DeliveryStatus.refunded:
        return DeliveryStatusValues.refunded;
    }
  }

  static DeliveryStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case DeliveryStatusValues.pending:
        return DeliveryStatus.pending;
      case DeliveryStatusValues.shipped:
        return DeliveryStatus.shipped;
      case DeliveryStatusValues.delivered:
        return DeliveryStatus.delivered;
      case DeliveryStatusValues.refunded:
        return DeliveryStatus.refunded;
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
        return 'orders.status.pending'.tr();
      case OrderStatus.confirmed:
        return 'orders.status.confirmed'.tr();
      case OrderStatus.processing:
        return 'orders.status.processing'.tr();
      case OrderStatus.shipped:
        return 'orders.status.shipped'.tr();
      case OrderStatus.inTransit:
        return 'orders.status.in_transit'.tr();
      case OrderStatus.delivered:
        return 'orders.status.delivered'.tr();
      case OrderStatus.cancelled:
        return 'orders.status.cancelled'.tr();
      case OrderStatus.failed:
        return 'orders.status.failed'.tr();
      case OrderStatus.expired:
        return 'orders.status.expired'.tr();
      case OrderStatus.disputed:
        return 'orders.status.disputed'.tr();
      case OrderStatus.refunded:
        return 'orders.status.refunded'.tr();
      case OrderStatus.partiallyRefunded:
        return 'orders.status.partially_refunded'.tr();
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatusValues.pending;
      case OrderStatus.confirmed:
        return OrderStatusValues.confirmed;
      case OrderStatus.processing:
        return OrderStatusValues.processing;
      case OrderStatus.shipped:
        return OrderStatusValues.shipped;
      case OrderStatus.inTransit:
        return OrderStatusValues.inTransit;
      case OrderStatus.delivered:
        return OrderStatusValues.delivered;
      case OrderStatus.cancelled:
        return OrderStatusValues.cancelled;
      case OrderStatus.failed:
        return OrderStatusValues.failed;
      case OrderStatus.expired:
        return OrderStatusValues.expired;
      case OrderStatus.disputed:
        return OrderStatusValues.disputed;
      case OrderStatus.refunded:
        return OrderStatusValues.refunded;
      case OrderStatus.partiallyRefunded:
        return OrderStatusValues.partiallyRefunded;
    }
  }

  static OrderStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case OrderStatusValues.pending:
        return OrderStatus.pending;
      case OrderStatusValues.confirmed:
        return OrderStatus.confirmed;
      case OrderStatusValues.processing:
        return OrderStatus.processing;
      case OrderStatusValues.shipped:
        return OrderStatus.shipped;
      case OrderStatusValues.inTransit:
        return OrderStatus.inTransit;
      case OrderStatusValues.delivered:
        return OrderStatus.delivered;
      case OrderStatusValues.cancelled:
        return OrderStatus.cancelled;
      case OrderStatusValues.failed:
        return OrderStatus.failed;
      case OrderStatusValues.expired:
        return OrderStatus.expired;
      case OrderStatusValues.disputed:
        return OrderStatus.disputed;
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
        return 'payment_status.awaiting_payment'.tr();
      case PaymentStatus.processing:
        return 'payment_status.processing'.tr();
      case PaymentStatus.paid:
        return 'payment_status.paid'.tr();
      case PaymentStatus.authorized:
        return 'payment_status.authorized'.tr();
      case PaymentStatus.captured:
        return 'payment_status.captured'.tr();
      case PaymentStatus.paymentFailed:
        return 'payment_status.payment_failed'.tr();
      case PaymentStatus.refunded:
        return 'payment_status.refunded'.tr();
      case PaymentStatus.partiallyRefunded:
        return 'payment_status.partially_refunded'.tr();
      case PaymentStatus.voided:
        return 'payment_status.voided'.tr();
      case PaymentStatus.sessionExpired:
        return 'payment_status.session_expired'.tr();
      case PaymentStatus.cancelled:
        return 'payment_status.cancelled'.tr();
      case PaymentStatus.authorizationExpired:
        return 'payment_status.authorization_expired'.tr();
      case PaymentStatus.disputed:
        return 'payment_status.disputed'.tr();
      case PaymentStatus.capturing:
        return 'payment_status.capturing'.tr();
      case PaymentStatus.cancelling:
        return 'payment_status.cancelling'.tr();
      case PaymentStatus.expiring:
        return 'payment_status.expiring'.tr();
      case PaymentStatus.cancelFailed:
        return 'payment_status.cancel_failed'.tr();
    }
  }

  String get value {
    switch (this) {
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
      case PaymentStatus.partiallyRefunded:
        return PaymentStatusValues.partiallyRefunded;
      case PaymentStatus.voided:
        return PaymentStatusValues.voided;
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
      case PaymentStatus.cancelFailed:
        return PaymentStatusValues.cancelFailed;
    }
  }

  static PaymentStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case PaymentStatusValues.awaitingPayment:
        return PaymentStatus.awaitingPayment;
      case PaymentStatusValues.processing:
        return PaymentStatus.processing;
      case PaymentStatusValues.paid:
        return PaymentStatus.paid;
      case PaymentStatusValues.authorized:
        return PaymentStatus.authorized;
      case PaymentStatusValues.captured:
        return PaymentStatus.captured;
      case PaymentStatusValues.paymentFailed:
        return PaymentStatus.paymentFailed;
      case PaymentStatusValues.refunded:
        return PaymentStatus.refunded;
      case PaymentStatusValues.sessionExpired:
        return PaymentStatus.sessionExpired;
      case PaymentStatusValues.cancelled:
        return PaymentStatus.cancelled;
      case PaymentStatusValues.authorizationExpired:
        return PaymentStatus.authorizationExpired;
      case PaymentStatusValues.disputed:
        return PaymentStatus.disputed;
      case PaymentStatusValues.capturing:
        return PaymentStatus.capturing;
      case PaymentStatusValues.cancelling:
        return PaymentStatus.cancelling;
      case PaymentStatusValues.expiring:
        return PaymentStatus.expiring;
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
        return 'shipping_approval_status.not_required'.tr();
      case ShippingApprovalStatus.pending:
        return 'shipping_approval_status.pending'.tr();
      case ShippingApprovalStatus.approved:
        return 'shipping_approval_status.approved'.tr();
      case ShippingApprovalStatus.rejected:
        return 'shipping_approval_status.rejected'.tr();
    }
  }

  String get value {
    switch (this) {
      case ShippingApprovalStatus.notRequired:
        return ShippingApprovalStatusValues.notRequired;
      case ShippingApprovalStatus.pending:
        return ShippingApprovalStatusValues.pending;
      case ShippingApprovalStatus.approved:
        return ShippingApprovalStatusValues.approved;
      case ShippingApprovalStatus.rejected:
        return ShippingApprovalStatusValues.rejected;
    }
  }

  static ShippingApprovalStatus fromValue(String? value) {
    switch (value?.toLowerCase()) {
      case ShippingApprovalStatusValues.notRequired:
        return ShippingApprovalStatus.notRequired;
      case ShippingApprovalStatusValues.pending:
        return ShippingApprovalStatus.pending;
      case ShippingApprovalStatusValues.approved:
        return ShippingApprovalStatus.approved;
      case ShippingApprovalStatusValues.rejected:
        return ShippingApprovalStatus.rejected;
      default:
        return ShippingApprovalStatus.notRequired;
    }
  }
}

// ============================================================================
// RETURN STATUS HELPERS
// ============================================================================

/// Helper to get display text and color for a return request status string.
class ReturnStatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  const ReturnStatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });

  /// Resolve a return status string to its display config.
  static ReturnStatusConfig fromValue(String status) {
    switch (status) {
      case ReturnStatusValues.requested:
        return ReturnStatusConfig(
          label: 'return_status.requested'.tr(),
          color: DesignTokens.secondary,
          icon: Icons.hourglass_empty,
        );
      case ReturnStatusValues.approved:
        return ReturnStatusConfig(
          label: 'return_status.approved'.tr(),
          color: DesignTokens.success,
          icon: Icons.check_circle_outline,
        );
      case ReturnStatusValues.labelIssued:
        return ReturnStatusConfig(
          label: 'return_status.label_issued'.tr(),
          color: DesignTokens.info,
          icon: Icons.local_shipping_outlined,
        );
      case ReturnStatusValues.received:
        return ReturnStatusConfig(
          label: 'return_status.received'.tr(),
          color: DesignTokens.primary,
          icon: Icons.inventory_2_outlined,
        );
      case ReturnStatusValues.refunded:
        return ReturnStatusConfig(
          label: 'return_status.refunded'.tr(),
          color: DesignTokens.success,
          icon: Icons.paid_outlined,
        );
      case ReturnStatusValues.rejected:
        return ReturnStatusConfig(
          label: 'return_status.rejected'.tr(),
          color: DesignTokens.error,
          icon: Icons.cancel_outlined,
        );
      case ReturnStatusValues.escalated:
        return ReturnStatusConfig(
          label: 'return_status.escalated'.tr(),
          color: DesignTokens.warning,
          icon: Icons.priority_high,
        );
      default:
        return ReturnStatusConfig(
          label: 'return_status.unknown'.tr(),
          color: DesignTokens.textSecondary,
          icon: Icons.help_outline,
        );
    }
  }
}
