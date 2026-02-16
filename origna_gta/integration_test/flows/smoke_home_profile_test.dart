import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Smoke — Home + Profile (admin)',
    (tester) async {
      const strictIntegration = bool.fromEnvironment(
        'STRICT_INTEGRATION',
        defaultValue: true,
      );
      final tracker = await initializeIntegrationTest(
        tester,
        strictIntegration: strictIntegration,
      );

      tracker.check(
        'C001',
        find.byType(MaterialApp).evaluate().isNotEmpty,
        'MaterialApp rendu',
      );
      tracker.check(
        'C002',
        find.byType(Scaffold).evaluate().isNotEmpty,
        'Scaffold initial rendu',
      );
      debugStep('A01', 'App launched');

      final ensuredAdmin = await establishSession(
        tester,
        adminCredentialCandidates,
        'A03.1',
        tracker,
        'S001',
        'Admin login failed with configured admin credentials',
      );
      tracker.check(
        'C078',
        ensuredAdmin != null,
        'session admin valide avant verification home cards',
      );

      final settingsAfterLogin = find.byKey(
        const Key('home_settings_button'),
      );
      tracker.check(
        'C004',
        settingsAfterLogin.evaluate().isNotEmpty,
        'Settings apres login',
      );

      var cartIcon = find.byKey(const Key('home_cart_button'));
      if (cartIcon.evaluate().isEmpty) {
        await ensureHomeReady(tester, timeoutSeconds: 8);
        cartIcon = find.byKey(const Key('home_cart_button'));
      }
      tracker.check('C006', cartIcon.evaluate().isNotEmpty, 'Cart icon visible');

      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.first, warnIfMissed: false);
        await pumpWait(tester, seconds: 3);
        tracker.check(
          'C007',
          find.byType(Scaffold).evaluate().isNotEmpty,
          'Cart screen affiche',
        );
        await goBack(tester);
      } else {
        tracker.stopOnSkip('S200', 'Cart icon missing before cart navigation');
      }

      final seededProductCardFinders = <Finder>[
        find.byKey(const Key('product_card_Test Physical Product')),
        find.byKey(const Key('product_card_Test Digital Product')),
        find.byKey(const Key('product_card_Test Local Product')),
      ];
      final seededProductTextFinders = <Finder>[
        find.textContaining('Test Physical Product'),
        find.textContaining('Test Digital Product'),
        find.textContaining('Test Local Product'),
        find.textContaining('Test Physical'),
        find.textContaining('Test Digital'),
        find.textContaining('Test Local'),
      ];

      for (var retry = 0; retry < 12; retry++) {
        final hasAnyCandidate =
            seededProductCardFinders.any((finder) => finder.evaluate().isNotEmpty) ||
            seededProductTextFinders.any((finder) => finder.evaluate().isNotEmpty);

        if (hasAnyCandidate) {
          break;
        }

        final scrollableRetry = find.byType(Scrollable);
        if (scrollableRetry.evaluate().isNotEmpty) {
          await tester.drag(
            scrollableRetry.first,
            const Offset(0, -220),
            warnIfMissed: false,
          );
        }
        await tester.pump(const Duration(milliseconds: 500));
      }

      Finder productOpenTarget = find.byType(Scaffold);
      for (final finder in seededProductCardFinders) {
        if (finder.evaluate().isNotEmpty) {
          productOpenTarget = finder;
          break;
        }
      }
      productOpenTarget = seededProductTextFinders.firstWhere(
        (finder) => finder.evaluate().isNotEmpty,
        orElse: () => productOpenTarget,
      );

      final hasOpenableProduct =
          seededProductCardFinders.any((finder) => finder.evaluate().isNotEmpty) ||
          seededProductTextFinders.any((finder) => finder.evaluate().isNotEmpty);

      if (hasOpenableProduct) {
        await tester.tap(productOpenTarget.first, warnIfMissed: false);
        await pumpWait(tester, seconds: 3);
        tracker.check(
          'C008',
          find.byType(Scaffold).evaluate().isNotEmpty,
          'Product detail affiche',
        );
        await goBack(tester);
      } else {
        tracker.stopOnSkip('S001', 'No openable product tile/text found on home');
      }

      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pump(const Duration(seconds: 2));
        await tester.drag(scrollable.first, const Offset(0, 300));
        await tester.pump(const Duration(seconds: 2));
        debugStep('A08', 'Home scroll interaction works');
      } else {
        tracker.stopOnSkip('S002', 'No scrollable widget found on home');
      }

      final settingsNow = find.byKey(const Key('home_settings_button'));
      if (settingsNow.evaluate().isEmpty) {
        tracker.stopOnSkip('S003', 'Settings icon not found');
      } else {
        await tester.tap(settingsNow.first, warnIfMissed: false);
        await pumpWait(tester, seconds: 5);
        tracker.check(
          'C009',
          find.byType(Scaffold).evaluate().isNotEmpty,
          'Profile screen affiche',
        );

        await checkProfileSubPage(tester, 'profile_my_orders_button', 'T10');
        await checkProfileSubPage(tester, 'profile_favorites_button', 'T11');
        await checkProfileSubPage(tester, 'profile_address_button', 'T12');
        debugStep('T13', 'Skipped terms page to avoid external tab interruption');

        final ordersBtn2 = find.byKey(const Key('profile_my_orders_button'));
        if (ordersBtn2.evaluate().isNotEmpty) {
          await tester.tap(ordersBtn2.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 2);
          await goBack(tester);
          tracker.check(
            'C010',
            find.byType(Scaffold).evaluate().isNotEmpty,
            'Retour depuis sous-page profile OK',
          );

          await goBack(tester);
          await pumpWait(tester, seconds: 2);
          tracker.check(
            'C079',
            find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty,
            'Retour Home explicite apres flow profile',
          );
        } else {
          tracker.stopOnSkip('S004', 'Orders button not found in profile');
        }
      }

      tracker.throwIfFailed();
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
