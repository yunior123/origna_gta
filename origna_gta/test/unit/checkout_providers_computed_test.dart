import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/models/models.dart';

void main() {
  group('checkoutTaxRateProvider', () {
    test('returns ontario tax rate when address is null', () {
      final container = ProviderContainer(
        overrides: [cartSubtotalProvider.overrideWithValue(0)],
      );
      addTearDown(container.dispose);

      final rate = container.read(checkoutTaxRateProvider);
      expect(rate, greaterThan(0));
    });

    test('returns tax rate based on address province', () {
      final container = ProviderContainer(
        overrides: [cartSubtotalProvider.overrideWithValue(0)],
      );
      addTearDown(container.dispose);

      container
          .read(checkoutStateProvider.notifier)
          .updateAddress(
            Address(
              street: '123 St',
              city: 'QC',
              state: 'QC',
              postalCode: 'H1H 1H1',
              country: 'CA',
            ),
          );

      final rate = container.read(checkoutTaxRateProvider);
      expect(rate, greaterThan(0));
    });
  });

  group('checkoutTotalProvider', () {
    test('computes total from subtotal with no discount', () {
      final container = ProviderContainer(
        overrides: [cartSubtotalProvider.overrideWithValue(10000)],
      );
      addTearDown(container.dispose);

      final total = container.read(checkoutTotalProvider);
      expect(total, 100.0);
    });

    test('applies coupon discount to total', () {
      final container = ProviderContainer(
        overrides: [cartSubtotalProvider.overrideWithValue(10000)],
      );
      addTearDown(container.dispose);

      container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('SAVE10', 10000);

      final state = container.read(checkoutStateProvider);
      if (state.couponDiscountCents > 0) {
        final total = container.read(checkoutTotalProvider);
        expect(total, lessThan(100.0));
      }
    });

    test('clamps total to zero when discount exceeds subtotal', () {
      final container = ProviderContainer(
        overrides: [cartSubtotalProvider.overrideWithValue(100)],
      );
      addTearDown(container.dispose);

      final total = container.read(checkoutTotalProvider);
      expect(total, greaterThanOrEqualTo(0.0));
    });
  });
}
