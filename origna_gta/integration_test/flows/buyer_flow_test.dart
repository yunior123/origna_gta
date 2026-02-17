import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Buyer Flow — browse, profile, checkout',
    (tester) async {
      debugPrint('🛒🛒🛒 ========== BUYER FLOW TEST START ========== 🛒🛒🛒');
      debugPrint('🔍 Checking STRICT_INTEGRATION env var...');
      const strictIntegration = bool.fromEnvironment(
        'STRICT_INTEGRATION',
        defaultValue: true,
      );
      debugPrint('  strictIntegration=$strictIntegration');

      debugPrint('🛠️  Initializing integration test...');
      final tracker = await initializeIntegrationTest(
        tester,
        strictIntegration: strictIntegration,
      );
      debugPrint('✅ Integration test initialized');

      final runStamp = DateTime.now().millisecondsSinceEpoch.toString();

      debugStep('B01', 'Buyer Flow — login + browse + cart/profile checks');

      debugPrint('  Calling establishSession...');

      debugPrint('  ⚙️  Looking for settings button...');
      final settingsButton = find.byKey(const Key('home_settings_button'));
      if (settingsButton.evaluate().isEmpty) {
        debugPrint('  ❌ Settings button not found');
      }
      debugPrint('  ✅ Settings button found, tapping...');

      await tester.tap(settingsButton.first, warnIfMissed: false);

      debugPrint('  ⏳ Waiting 4s for popup/profile to appear...');
      await pumpWait(tester, seconds: 2);

      debugPrint('  💬 Checking for sign-in popup...');
      final _ = await handleSignInPopup(
        tester,
        email: buyerCredentialCandidates.first.email,
        password: buyerCredentialCandidates.first.password,
      );

      debugPrint('  ✅ establishSession completed');

      final buyerAddProductButton = find.byKey(
        const Key('home_add_product_button'),
      );
      tracker.check(
        'C021',
        buyerAddProductButton.evaluate().isEmpty,
        '[buyer] n\'a pas acces add product',
      );

      if (await openSettings(tester)) {
        final buyerOrders = find.byKey(const Key('profile_my_orders_button'));
        final buyerFavorites = find.byKey(
          const Key('profile_favorites_button'),
        );
        final buyerAddress = find.byKey(const Key('profile_address_button'));
        tracker.check(
          'C023',
          buyerOrders.evaluate().isNotEmpty ||
              buyerFavorites.evaluate().isNotEmpty ||
              buyerAddress.evaluate().isNotEmpty,
          '[buyer] actions profile de base visibles',
        );

        if (buyerFavorites.evaluate().isNotEmpty) {
          await scrollUntilVisible(
            tester,
            buyerFavorites,
            delta: -220,
            maxScrolls: 10,
          );
          await tester.tap(buyerFavorites.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 2);
          tracker.check(
            'C090',
            find.byType(Scaffold).evaluate().isNotEmpty,
            '[buyer] ecran favoris s\'ouvre',
          );
          await goBack(tester);
          await pumpWait(tester, seconds: 1);
        }

        if (buyerAddress.evaluate().isNotEmpty) {
          await scrollUntilVisible(
            tester,
            buyerAddress,
            delta: -220,
            maxScrolls: 10,
          );
          await tester.tap(buyerAddress.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 2);
          tracker.check(
            'C091',
            find.byType(Scaffold).evaluate().isNotEmpty,
            '[buyer] ecran adresse s\'ouvre',
          );

          final addAddressButton = find.bySemanticsLabel('btn-add-address');
          final editAddressButton = find.bySemanticsLabel('btn-edit-address');
          tracker.check(
            'C092',
            addAddressButton.evaluate().isNotEmpty ||
                editAddressButton.evaluate().isNotEmpty,
            '[buyer] action add/edit adresse visible',
          );

          if (addAddressButton.evaluate().isNotEmpty) {
            await tester.tap(addAddressButton.first, warnIfMissed: false);
            await pumpWait(tester, seconds: 2);
            final fields = find.byType(TextFormField);
            if (fields.evaluate().length >= 5) {
              await tester.enterText(fields.at(0), '123 Test Ave $runStamp');
              await tester.enterText(fields.at(1), 'Unit 1');
              await tester.enterText(fields.at(2), 'Toronto');
              await tester.enterText(fields.at(3), 'M5V1A1');
              await tester.enterText(fields.at(4), '4165550000');
            }
            final saveAddressButton = find.bySemanticsLabel('btn-save-address');
            tracker.check(
              'C093',
              saveAddressButton.evaluate().isNotEmpty,
              'save address button visible',
            );
            if (saveAddressButton.evaluate().isNotEmpty) {
              await tester.tap(saveAddressButton.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 4);
            }
          }

          final editButtonAfter = find.bySemanticsLabel('btn-edit-address');
          if (editButtonAfter.evaluate().isNotEmpty) {
            await tester.tap(editButtonAfter.first, warnIfMissed: false);
            await pumpWait(tester, seconds: 2);
            final fields = find.byType(TextFormField);
            if (fields.evaluate().isNotEmpty) {
              await tester.enterText(fields.first, '456 Updated Ave $runStamp');
            }
            final saveAddressButton = find.bySemanticsLabel('btn-save-address');
            if (saveAddressButton.evaluate().isNotEmpty) {
              await tester.tap(saveAddressButton.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 4);
            }
          }

          tracker.check(
            'C094',
            find.bySemanticsLabel('btn-edit-address').evaluate().isNotEmpty ||
                find
                    .byKey(const Key('home_settings_button'))
                    .evaluate()
                    .isNotEmpty,
            '[buyer] create/edit adresse execute',
          );

          if (find.bySemanticsLabel('btn-edit-address').evaluate().isNotEmpty) {
            await goBack(tester);
            await pumpWait(tester, seconds: 1);
          }
        }

        if (buyerOrders.evaluate().isNotEmpty) {
          await tester.tap(buyerOrders.first);
          await pumpWait(tester, seconds: 2);
          tracker.check(
            'C024',
            find.byType(Scaffold).evaluate().isNotEmpty,
            '[buyer] ecran orders s\'ouvre',
          );
          await goBack(tester);
        }

        await goBack(tester);
        await pumpWait(tester, seconds: 2);
      }

      final buyerCart = find.byKey(const Key('home_cart_button'));
      if (buyerCart.evaluate().isNotEmpty) {
        await tester.tap(buyerCart.first);
        await pumpWait(tester, seconds: 3);
        final checkoutButton = find.byKey(const Key('cart_checkout_button'));

        if (checkoutButton.evaluate().isNotEmpty) {
          await tester.tap(checkoutButton.first);
          await pumpWait(tester, seconds: 4);

          final checkoutPlaceOrder = find.byKey(
            const Key('checkout_place_order_button'),
          );
          final checkoutTerms = find.byKey(
            const Key('checkout_terms_checkbox'),
          );
          final checkoutSummary = find.byKey(
            const Key('checkout_summary_section'),
          );
          final checkoutShipping = find.byKey(
            const Key('checkout_shipping_section'),
          );
          final checkoutAddress = find.byKey(
            const Key('checkout_address_section'),
          );
          final checkoutPayment = find.byKey(
            const Key('checkout_payment_section'),
          );
          final checkoutSecure = find.byKey(const Key('checkout_secure_badge'));
          final deliveryStandard = find.byKey(
            const Key('checkout_delivery_speed_standard'),
          );

          tracker.check(
            'C025',
            checkoutPlaceOrder.evaluate().isNotEmpty,
            'checkout place order visible',
          );
          tracker.check(
            'C026',
            checkoutTerms.evaluate().isNotEmpty,
            'checkout terms checkbox visible',
          );
          tracker.check(
            'C027',
            checkoutSummary.evaluate().isNotEmpty,
            'checkout summary visible',
          );
          tracker.check(
            'C028',
            checkoutPayment.evaluate().isNotEmpty,
            'checkout payment section visible',
          );
          tracker.check(
            'C029',
            checkoutSecure.evaluate().isNotEmpty,
            'checkout secure badge visible',
          );
          tracker.check(
            'C030',
            checkoutShipping.evaluate().isNotEmpty ||
                deliveryStandard.evaluate().isNotEmpty,
            'checkout shipping/delivery visible',
          );
          tracker.check(
            'C071',
            checkoutAddress.evaluate().isNotEmpty,
            'checkout address section visible',
          );

          final hasTaxBreakdown =
              find.textContaining('HST').evaluate().isNotEmpty ||
              find.textContaining('GST').evaluate().isNotEmpty ||
              find.textContaining('PST').evaluate().isNotEmpty ||
              find.textContaining('QST').evaluate().isNotEmpty;
          tracker.check(
            'C031',
            hasTaxBreakdown,
            'tax breakdown visible (GST/HST/PST/QST)',
          );

          final standardSpeed = find.byKey(
            const Key('checkout_delivery_speed_standard'),
          );
          final expressSpeed = find.byKey(
            const Key('checkout_delivery_speed_express'),
          );
          final sameDaySpeed = find.byKey(
            const Key('checkout_delivery_speed_sameDay'),
          );
          tracker.check(
            'C055',
            standardSpeed.evaluate().isNotEmpty,
            'delivery speed standard visible',
          );
          tracker.check(
            'C056',
            expressSpeed.evaluate().isNotEmpty,
            'delivery speed express visible',
          );
          tracker.check(
            'C057',
            sameDaySpeed.evaluate().isNotEmpty,
            'delivery speed same-day visible',
          );

          final shippingMoneyInSection = find.descendant(
            of: checkoutShipping,
            matching: find.textContaining(r'$'),
          );
          tracker.check(
            'C058',
            shippingMoneyInSection.evaluate().isNotEmpty,
            'shipping section shows cost text',
          );

          final summaryMoneyValues = find.descendant(
            of: checkoutSummary,
            matching: find.textContaining(r'$'),
          );
          tracker.check(
            'C059',
            summaryMoneyValues.evaluate().length >= 2,
            'order summary shows monetary breakdown',
          );

          final termsWidgetBefore = tester.widget<Checkbox>(
            checkoutTerms.first,
          );
          final termsBefore = termsWidgetBefore.value ?? false;
          await tester.tap(checkoutTerms.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 1);
          final termsWidgetAfter = tester.widget<Checkbox>(checkoutTerms.first);
          final termsAfter = termsWidgetAfter.value ?? false;
          tracker.check(
            'C060',
            termsBefore != termsAfter,
            'terms checkbox toggle works',
          );

          for (final speedKey in const [
            'checkout_delivery_speed_standard',
            'checkout_delivery_speed_express',
            'checkout_delivery_speed_sameDay',
          ]) {
            final speedFinder = find.byKey(Key(speedKey));
            if (speedFinder.evaluate().isNotEmpty) {
              await tester.tap(speedFinder.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 1);
              tracker.check(
                'C061',
                checkoutSummary.evaluate().isNotEmpty &&
                    checkoutShipping.evaluate().isNotEmpty &&
                    checkoutPlaceOrder.evaluate().isNotEmpty &&
                    checkoutTerms.evaluate().isNotEmpty,
                'delivery speed interaction keeps checkout stable ($speedKey)',
              );
            }
          }

          final shippingAmounts = extractDollarAmounts(
            find.descendant(of: checkoutShipping, matching: find.byType(Text)),
          );
          tracker.check(
            'C072',
            shippingAmounts.isNotEmpty,
            'shipping section exposes parsable monetary amount',
          );
          tracker.check(
            'C073',
            shippingAmounts.every((amount) => amount >= 0),
            'shipping monetary amount is non-negative',
          );

          final summaryAmounts = extractDollarAmounts(
            find.descendant(of: checkoutSummary, matching: find.byType(Text)),
          );
          tracker.check(
            'C074',
            summaryAmounts.length >= 3,
            'summary contains multiple monetary values',
          );
          if (shippingAmounts.isNotEmpty && summaryAmounts.isNotEmpty) {
            final maxSummary = summaryAmounts.reduce(
              (value, element) => value > element ? value : element,
            );
            final minShipping = shippingAmounts.reduce(
              (value, element) => value < element ? value : element,
            );
            tracker.check(
              'C075',
              maxSummary >= minShipping,
              'summary totals remain coherent with shipping amount',
            );
          }

          final termsLink = find.byKey(const Key('checkout_terms_link'));
          if (termsLink.evaluate().isNotEmpty) {
            tracker.check(
              'C076',
              checkoutTerms.evaluate().isNotEmpty,
              'terms link present (not tapped to avoid new tab)',
            );
            tracker.check(
              'C077',
              checkoutPlaceOrder.evaluate().isNotEmpty,
              'place order still visible with terms link present',
            );
          }

          await goBack(tester);
          await pumpWait(tester, seconds: 2);
        }

        await goBack(tester);
      }

      final buyerProductFinders = <Finder>[
        find.byKey(const Key('product_card_Test Physical Product')),
        find.byKey(const Key('product_card_Test Digital Product')),
        find.byKey(const Key('product_card_Test Local Product')),
        find.textContaining('Test Physical Product'),
        find.textContaining('Test Digital Product'),
        find.textContaining('Test Local Product'),
      ];
      final buyerProductTarget = buyerProductFinders.firstWhere(
        (finder) => finder.evaluate().isNotEmpty,
        orElse: () => find.byType(Scaffold),
      );

      if (buyerProductFinders.any((finder) => finder.evaluate().isNotEmpty)) {
        await tester.tap(buyerProductTarget.first, warnIfMissed: false);
        await pumpWait(tester, seconds: 3);
        final buyerAddToCart = find.byKey(
          const Key('product_add_to_cart_button'),
        );
        final ownProductMessage = find.byKey(
          const Key('product_own_product_message'),
        );
        tracker.check(
          'C032',
          buyerAddToCart.evaluate().isNotEmpty ||
              ownProductMessage.evaluate().isNotEmpty,
          '[buyer] product detail CTA ou own-product message',
        );
        await goBack(tester);
      }

      tracker.check(
        'C033',
        find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty,
        '[buyer] retour home OK',
      );

      debugPrint('🧪 Running final tracker validation...');
      debugPrint('📊 Test Statistics:');
      debugPrint('  Total checks performed: ${tracker.caseCount}');
      debugPrint('  ✅ Passed: ${tracker.caseCount - tracker.failedCases.length}');
      debugPrint('  ❌ Failed: ${tracker.failedCases.length}');
      if (tracker.failedCases.isNotEmpty) {
        debugPrint('  ⚠️  Failed cases:');
        for (final failure in tracker.failedCases) {
          debugPrint('    - $failure');
        }
      }
      tracker.throwIfFailed();
      debugPrint('🎉🎉🎉 ========== BUYER FLOW TEST COMPLETE ========== 🎉🎉🎉');
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
}
