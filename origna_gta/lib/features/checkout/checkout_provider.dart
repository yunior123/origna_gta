// coverage:ignore-file
// Migrated: delegates to OrignaBase checkout provider.
// Screens continue using checkoutStateProvider, checkoutTaxRateProvider, checkoutTotalProvider.

export 'checkout_state.dart';
export 'orignabase_checkout_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart' show getTaxRate;

import 'orignabase_checkout_provider.dart';

/// Backward-compatible alias — screens use this name.
final checkoutStateProvider = obCheckoutStateProvider;

/// Computed provider for tax rate based on address.
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  if (checkoutState.address == null) return getTaxRate(ProvinceCodeValues.ontario);
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
  return (subtotalDollars - couponDiscountDollars).clamp(0.0, double.infinity) + checkoutState.taxAmount + checkoutState.shippingCost;
});

/// Backward-compatible typedef so screens can reference CheckoutNotifier.
typedef CheckoutNotifier = OrignaBaseCheckoutNotifier;
