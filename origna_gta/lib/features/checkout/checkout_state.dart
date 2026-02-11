import 'package:flutter/foundation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// CHECKOUT RESULT
// ============================================================================

sealed class CheckoutResult {}

class CheckoutSuccess extends CheckoutResult {
  final String checkoutUrl;
  final String orderId;
  final String sessionId;

  CheckoutSuccess({required this.checkoutUrl, required this.orderId, required this.sessionId});
}

class CheckoutError extends CheckoutResult {
  final String message;
  final String? code;

  CheckoutError({required this.message, this.code});
}

class CheckoutAlreadyProcessed extends CheckoutResult {
  final String existingOrderId;

  CheckoutAlreadyProcessed({required this.existingOrderId});
}

// ============================================================================
// CHECKOUT STATE
// ============================================================================

@immutable
class CheckoutState {
  final Address? address;
  final double baseShippingCost; // Base shipping before delivery speed surcharge
  final DeliverySpeed deliverySpeed;
  final List<DeliverySpeed> availableDeliverySpeeds;
  final bool isLocalDelivery; // Within ~50km of seller
  final Map<String, double> taxBreakdown;
  final bool isCalculatingShipping;
  final String? shippingError;
  final bool isProcessing;
  final String? idempotencyKey;
  final String? checkoutError;
  final String paymentProvider;

  const CheckoutState({
    this.address,
    this.baseShippingCost = 0.0,
    this.deliverySpeed = DeliverySpeed.standard,
    this.availableDeliverySpeeds = const [DeliverySpeed.standard],
    this.isLocalDelivery = false,
    this.taxBreakdown = const {},
    this.isCalculatingShipping = false,
    this.shippingError,
    this.isProcessing = false,
    this.idempotencyKey,
    this.checkoutError,
    this.paymentProvider = PaymentProviderValues.stripe,
  });

  /// Total shipping cost including delivery speed surcharge
  /// Standard (free) uses base cost, express/same-day add surcharge
  double get shippingCost {
    if (deliverySpeed == DeliverySpeed.standard) {
      return baseShippingCost;
    }
    return baseShippingCost + deliverySpeed.baseSurcharge;
  }

  double get taxAmount => taxBreakdown.values.fold(0.0, (total, v) => total + v);

  CheckoutState copyWith({
    Address? address,
    double? baseShippingCost,
    DeliverySpeed? deliverySpeed,
    List<DeliverySpeed>? availableDeliverySpeeds,
    bool? isLocalDelivery,
    Map<String, double>? taxBreakdown,
    bool? isCalculatingShipping,
    String? shippingError,
    bool? isProcessing,
    String? idempotencyKey,
    String? checkoutError,
    String? paymentProvider,
    bool clearShippingError = false,
    bool clearCheckoutError = false,
    bool clearIdempotencyKey = false,
  }) {
    return CheckoutState(
      address: address ?? this.address,
      baseShippingCost: baseShippingCost ?? this.baseShippingCost,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      availableDeliverySpeeds: availableDeliverySpeeds ?? this.availableDeliverySpeeds,
      isLocalDelivery: isLocalDelivery ?? this.isLocalDelivery,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      isCalculatingShipping: isCalculatingShipping ?? this.isCalculatingShipping,
      shippingError: clearShippingError ? null : (shippingError ?? this.shippingError),
      isProcessing: isProcessing ?? this.isProcessing,
      idempotencyKey: clearIdempotencyKey ? null : (idempotencyKey ?? this.idempotencyKey),
      checkoutError: clearCheckoutError ? null : (checkoutError ?? this.checkoutError),
      paymentProvider: paymentProvider ?? this.paymentProvider,
    );
  }
}
