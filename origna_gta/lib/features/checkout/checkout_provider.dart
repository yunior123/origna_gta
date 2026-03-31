// Checkout provider — re-exports OrignaBase checkout provider + computed providers.

export 'checkout_state.dart';
export 'orignabase_checkout_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/utils/utils.dart' show getTaxRate, provinceTaxRates;

import 'orignabase_checkout_provider.dart';

/// Computed provider for tax rate based on the buyer's shipping address.
///
/// Falls back to Ontario's HST rate (13%) when no address is set.
/// Used by checkout summary to display the tax percentage label.
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final address = ref.watch(checkoutStateProvider.select((s) => s.address));
  if (address == null) {
    // For digital-only carts with no address, use the buyer's profile province
    // instead of blindly defaulting to Ontario.
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final profileProvince = userProfile?.address?.state;
    return getTaxRate(profileProvince ?? ProvinceCodeValues.ontario);
  }
  return getTaxRate(address.state);
});

/// Computed provider for checkout total in dollars.
///
/// Formula: `(subtotal - coupon) + tax + shipping`
///
/// ## Key Decisions
/// - Platform fee is deducted from the **seller's** payout — NOT added to buyer's charge.
///   Stripe PaymentIntent amount = discounted_subtotal + shipping + tax only.
/// - [cartSubtotalProvider] returns integer cents — divided by 100.0 for dollar conversion.
/// - Coupon discount clamped to 0 minimum — negative totals are impossible.
final checkoutTotalProvider = Provider.autoDispose<double>((ref) {
  final (couponDiscountCents, taxAmount, shippingCost) = ref.watch(
    checkoutStateProvider.select(
      (s) => (s.couponDiscountCents, s.taxAmount, s.shippingCost),
    ),
  );
  // cartSubtotalProvider returns INTEGER CENTS — divide by 100.0 to get dollars.
  final subtotalDollars = ref.watch(cartSubtotalProvider) / 100.0;
  final couponDiscountDollars = couponDiscountCents / 100.0;
  return (subtotalDollars - couponDiscountDollars).clamp(0.0, double.infinity) +
      taxAmount +
      shippingCost;
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

/// Computed single tax amount (in dollars) for a given subtotal + province.
/// Used by _OrderReviewSheet to display the tax line item without inline math.
final checkoutTaxAmountProvider = Provider.autoDispose
    .family<double, ({double subtotal, String province})>((ref, params) {
      final effective = ref.watch(
        checkoutEffectiveSubtotalProvider(params.subtotal),
      );
      final shippingCost = ref.watch(
        checkoutStateProvider.select((s) => s.shippingCost),
      );
      final taxRate = getTaxRate(params.province);
      return (effective + shippingCost) * taxRate;
    });

/// Computed detailed tax breakdown (name → amount in dollars) for a given
/// province + subtotal. Used by _OrderSummary to render per-tax-type lines
/// without inline business logic.
final checkoutTaxBreakdownProvider = Provider.autoDispose
    .family<Map<String, double>, ({double subtotal, String province})>((
      ref,
      params,
    ) {
      final effective = ref.watch(
        checkoutEffectiveSubtotalProvider(params.subtotal),
      );
      final shippingCost = ref.watch(
        checkoutStateProvider.select((s) => s.shippingCost),
      );
      final taxableBase = effective + shippingCost;
      final rates = provinceTaxRates[params.province] ?? {'HST': 0.13};
      return {
        for (final entry in rates.entries) entry.key: taxableBase * entry.value,
      };
    });

/// Per-tax-type rate map (name → rate 0.0–1.0) for a province.
/// Used by _OrderSummary._buildTaxBreakdownRows for display labels like "GST (5.00%)".
final checkoutProvinceRatesMapProvider = Provider.autoDispose
    .family<Map<String, double>, String>(
      (ref, province) => provinceTaxRates[province] ?? {'HST': 0.13},
    );

/// Tax rate for a given province (0.0–1.0). Used for display labels like "HST (13.00%)".
/// Pure lookup — no side effects.
final checkoutProvinceTaxRateProvider = Provider.autoDispose
    .family<double, String>((ref, province) => getTaxRate(province));

/// Coupon discount converted to dollars for display. Avoids inline cents→dollars
/// math in widget build() methods.
final checkoutCouponDiscountDollarsProvider = Provider.autoDispose<double>((
  ref,
) {
  final cents = ref.watch(
    checkoutStateProvider.select((s) => s.couponDiscountCents),
  );
  return cents / 100.0;
});

/// Subtotal converted to integer cents. Avoids inline `(subtotal * 100).round()`
/// in widget build() methods.
final checkoutSubtotalCentsProvider = Provider.autoDispose.family<int, double>((
  ref,
  subtotalDollars,
) {
  return (subtotalDollars * 100).round();
});

/// Backward-compatible typedef so screens can reference CheckoutNotifier.
typedef CheckoutNotifier = OrignaBaseCheckoutNotifier;
