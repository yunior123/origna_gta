import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

part 'checkout_state.freezed.dart';

// ignore_for_file: unused_element

// ============================================================================
// CHECKOUT RESULT
// ============================================================================

sealed class CheckoutResult {}

/// Documentation for CheckoutSuccess
class CheckoutSuccess extends CheckoutResult {
  final String checkoutUrl;
  final String orderId;
  final String sessionId;

  CheckoutSuccess({
    required this.checkoutUrl,
    required this.orderId,
    required this.sessionId,
  });
}

/// Documentation for CheckoutError
class CheckoutError extends CheckoutResult {
  final String message;
  final String? code;

  CheckoutError({required this.message, this.code});
}

/// Documentation for CheckoutAlreadyProcessed
class CheckoutAlreadyProcessed extends CheckoutResult {
  final String existingOrderId;

  CheckoutAlreadyProcessed({required this.existingOrderId});
}

// ============================================================================
// CHECKOUT STATE
// ============================================================================

@freezed
abstract class CheckoutState with _$CheckoutState {
  const CheckoutState._();

  const factory CheckoutState({
    Address? address,
    @Default(0.0)
    double baseShippingCost, // Base shipping before delivery speed surcharge
    @Default({})
    Map<String, double> sellerShippingCosts, // Breakdown per seller
    @Default({}) Map<String, String> sellerNames, // Seller names for display
    @Default(DeliverySpeed.standard) DeliverySpeed deliverySpeed,
    @Default([DeliverySpeed.standard])
    List<DeliverySpeed> availableDeliverySpeeds,
    @Default(false) bool isLocalDelivery, // Within ~50km of seller
    @Default({}) Map<String, double> taxBreakdown,
    @Default(false) bool isCalculatingShipping,
    String? shippingError,
    @Default(false) bool isProcessing,
    String? idempotencyKey,
    String? checkoutError,
    @Default(PaymentProviderValues.stripe) String paymentProvider,
    String? couponCode,
    @Default(0) int couponDiscountCents,
    @Default(false) bool isCouponLoading,
    String? couponError,

    /// F-77: Server-calculated tax amount in cents returned from create_checkout_session.
    /// Use this for display in the review screen instead of client-side estimates.
    @Default(0) int serverTaxAmountCents,

    /// F-74: Indicates if any item in the cart is shipped from outside Canada.
    @Default(false) bool hasInternationalItems,
  }) = _CheckoutState;

  /// Total shipping cost including delivery speed surcharge
  /// Standard (free) uses base cost, express/same-day add surcharge
  double get shippingCost {
    if (deliverySpeed == DeliverySpeed.standard) {
      return baseShippingCost;
    }
    return baseShippingCost + deliverySpeed.baseSurcharge;
  }

  double get taxAmount =>
      taxBreakdown.values.fold(0.0, (total, v) => total + v);
}

// ============================================================================
// CHECKOUT UI STATE PROVIDERS
// ============================================================================

/// Provider for terms acceptance state — shared between _TermsText and _CheckoutButton
final checkoutTermsAcceptedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Tracks whether the user has interacted with the terms checkbox — gates error state
final checkoutTermsInteractedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider for digital product EULA acceptance — required when cart contains digital items
final checkoutEulaAcceptedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Tracks whether user has interacted with the EULA checkbox — gates error display
final checkoutEulaInteractedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider for age verification acceptance — required when cart contains age-restricted items
final checkoutAgeVerifAcceptedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Tracks whether user has interacted with the age gate checkbox — gates error display
final checkoutAgeVerifInteractedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
