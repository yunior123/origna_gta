import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Seller Flow — seller tools + seller orders',
    (tester) async {
      const strictIntegration = bool.fromEnvironment(
        'STRICT_INTEGRATION',
        defaultValue: true,
      );
      final tracker = await initializeIntegrationTest(
        tester,
        strictIntegration: strictIntegration,
      );

      debugStep('C01', 'Seller Flow — seller tools + seller orders');
      final sellerCred = await establishSession(
        tester,
        sellerCredentialCandidates,
        'C01',
        tracker,
        'S008',
        'Seller flow login failed with configured seller credentials',
      );
      if (sellerCred == null) return;

      final sellerAddButton = find.byKey(const Key('home_add_product_button'));
      tracker.check(
        'C034',
        sellerAddButton.evaluate().isNotEmpty,
        '[buyer,seller] add product visible',
      );
      if (sellerAddButton.evaluate().isNotEmpty) {
        await tester.tap(sellerAddButton.first);
        await pumpWait(tester, seconds: 3);
        tracker.check(
          'C035',
          find.byKey(const Key('addproduct_screen_title')).evaluate().isNotEmpty,
          '[buyer,seller] add product screen open',
        );
        await goBack(tester);
      } else {
        tracker.stopOnSkip(
          'S009',
          'Seller add-product button not visible for seller role account',
        );
      }

      if (await openSettings(tester)) {
        final sellerAdminPanel =
            find.byKey(const Key('profile_admin_panel_button'));
        if (!isAdminAccountEmail(sellerCred.email)) {
          tracker.check(
            'C036',
            sellerAdminPanel.evaluate().isEmpty,
            '[buyer,seller] admin panel cache',
          );
        }

        final sellerOrdersButton =
            find.byKey(const Key('profile_seller_orders_button'));
        final sellerDashboardButton =
            find.byKey(const Key('profile_seller_dashboard_button'));
        final becomeSellerButton =
            find.byKey(const Key('profile_become_seller_button'));

        tracker.check(
          'C037',
          sellerDashboardButton.evaluate().isNotEmpty ||
              sellerOrdersButton.evaluate().isNotEmpty,
          '[buyer,seller] dashboard/orders seller visible',
        );
        tracker.check(
          'C038',
          becomeSellerButton.evaluate().isEmpty,
          '[buyer,seller] become seller cache',
        );

        if (sellerDashboardButton.evaluate().isNotEmpty) {
          await tester.tap(sellerDashboardButton.first);
          await pumpWait(tester, seconds: 2);
          tracker.check(
            'C039',
            find.byType(Scaffold).evaluate().isNotEmpty,
            '[buyer,seller] dashboard screen visible',
          );
          await goBack(tester);
        }

        if (sellerOrdersButton.evaluate().isNotEmpty) {
          await tester.tap(sellerOrdersButton.first);
          await pumpWait(tester, seconds: 3);
          tracker.check(
            'C040',
            find
                .byKey(const Key('seller_orders_screen_title'))
                .evaluate()
                .isNotEmpty,
            '[buyer,seller] seller orders screen visible',
          );
          await goBack(tester);
        } else {
          tracker.stopOnSkip(
            'S010',
            'Seller orders button not found for seller role account',
          );
        }

        await goBack(tester);
        await pumpWait(tester, seconds: 2);
      }

      tracker.check(
        'C041',
        find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty,
        '[buyer,seller] retour home/profile stable',
      );

      final sellerBuyerOrders = find.byKey(const Key('profile_my_orders_button'));
      tracker.check(
        'C062',
        sellerBuyerOrders.evaluate().isNotEmpty ||
            find.byKey(const Key('home_cart_button')).evaluate().isNotEmpty,
        '[buyer,seller] conserve acces buyer side',
      );

      tracker.throwIfFailed();
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
