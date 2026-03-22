// Checkout provider — re-exports OrignaBase checkout provider + computed providers.

export 'checkout_state.dart';
export 'orignabase_checkout_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/utils.dart' show getTaxRate;

import 'orignabase_checkout_provider.dart';

/// Computed provider for tax rate based on address.
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  if (checkoutState.address == null) {
    return getTaxRate(ProvinceCodeValues.ontario);
  }
  return getTaxRate(checkoutState.address!.state);
});

/// Computed provider for checkout total.
/// Formula: (subtotal - coupon) + tax + shipping.
/// NOTE: The platform fee is deducted from the SELLER's payout — it is NOT added to the buyer's
/// charge. Stripe PaymentIntent amount = discounted_subtotal + shipping + tax only.
final checkoutTotalProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  // cartSubtotalProvider returns INTEGER CENTS — divide by 100.0 to get dollars.
  final subtotalDollars = ref.watch(cartSubtotalProvider) / 100.0;
  final couponDiscountDollars = checkoutState.couponDiscountCents / 100.0;
  return (subtotalDollars - couponDiscountDollars).clamp(0.0, double.infinity) +
      checkoutState.taxAmount +
      checkoutState.shippingCost;
});

/// Computed effective subtotal after coupon discount (in dollars).
/// Used by checkout summary and items sections to avoid inline math in build().
final checkoutEffectiveSubtotalProvider = Provider.autoDispose
    .family<double, double>((ref, subtotalDollars) {
      final couponDiscountCents = ref.watch(
        checkoutStateProvider.select((s) => s.couponDiscountCents),
      );
      return (subtotalDollars - couponDiscountCents / 100.0).clamp(
        0.0,
        double.infinity,
      );
    });

/// Computed platform fee amount (in dollars) for display.
/// Platform fee is deducted from seller's payout — NOT added to buyer charge.
final checkoutPlatformFeeProvider = Provider.autoDispose.family<double, double>(
  (ref, subtotalDollars) {
    final effective = ref.watch(
      checkoutEffectiveSubtotalProvider(subtotalDollars),
    );
    return effective * (BusinessRules.platformFeePercent / 100.0);
  },
);

/// Computed buyer total (subtotal - coupon + tax + shipping) for a given subtotal + province.
/// Centralizes the formula: effective + (taxRate * (effective + shipping)) + shipping.
final checkoutBuyerTotalProvider = Provider.autoDispose
    .family<double, ({double subtotal, String province})>((ref, params) {
      final effective = ref.watch(
        checkoutEffectiveSubtotalProvider(params.subtotal),
      );
      final shippingCost = ref.watch(
        checkoutStateProvider.select((s) => s.shippingCost),
      );
      final taxRate = getTaxRate(params.province);
      return effective + (taxRate * (effective + shippingCost)) + shippingCost;
    });

/// Backward-compatible typedef so screens can reference CheckoutNotifier.
typedef CheckoutNotifier = OrignaBaseCheckoutNotifier;
