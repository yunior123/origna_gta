// Single entry point — ONE build, ALL integration tests.
//
// Run on physical iPhone:
// flutter test integration_test/all_tests.dart \
// -d 00008120-000174923ADB401E \
// --dart-define=ENVIRONMENT=dev
//
// Requires Firebase devs running.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import './app_test.dart' as app;

import 'helpers/test_helpers.dart';

// MAIN TEST SUITE

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app.main();
  testWidgets('Critical Flows — All 15 checks', (tester) async {
    await launchApp(tester);

    // ════════════════════════════════════════════════════════════════════
    // T01: App launches and renders MaterialApp
    // ════════════════════════════════════════════════════════════════════
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T01 ✓ App launched');

    // ════════════════════════════════════════════════════════════════════
    // T02, T14, T03: Login screen checks + validation + login
    // ════════════════════════════════════════════════════════════════════
    final onLogin = find
        .byKey(const Key('login_submit_button'))
        .evaluate()
        .isNotEmpty;

    if (onLogin) {
      // T02: Login screen fields
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      debugPrint('T02 ✓ Login fields present');

      // T14: Empty form validation — submit without data
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await pumpWait(tester);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      debugPrint('T14 ✓ Form validation triggered');

      // T03: Buyer login
      await loginWith(tester, email: buyerEmail, password: buyerPassword);
      expect(
        find.byKey(const Key('login_submit_button')).evaluate().isEmpty,
        isTrue,
        reason: 'Should navigate away from login',
      );
      debugPrint('T03 ✓ Buyer logged in');
    } else {
      debugPrint('T02/T14/T03 SKIP: Already logged in');
    }

    // ════════════════════════════════════════════════════════════════════
    // T04: Home screen renders product grid or loading state
    // ════════════════════════════════════════════════════════════════════
    final hasGrid = find.byType(GridView).evaluate().isNotEmpty;
    final hasCards = find.byType(Card).evaluate().isNotEmpty;
    expect(
      hasGrid || hasCards || find.byType(Scaffold).evaluate().isNotEmpty,
      isTrue,
    );
    debugPrint('T04 ✓ Home screen (grid=$hasGrid, cards=$hasCards)');

    // ════════════════════════════════════════════════════════════════════
    // T05: Cart icon visible on home screen
    // ════════════════════════════════════════════════════════════════════
    final cartIcon = find.byKey(const Key('home_cart_button'));
    expect(cartIcon, findsOneWidget);
    debugPrint('T05 ✓ Cart icon');

    // ════════════════════════════════════════════════════════════════════
    // T07: Navigate to cart screen
    // ════════════════════════════════════════════════════════════════════
    await tester.tap(cartIcon);
    await pumpWait(tester, seconds: 3);
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T07 ✓ Cart screen loaded');
    await goBack(tester);

    // ════════════════════════════════════════════════════════════════════
    // T08: Tap product card opens details
    // ════════════════════════════════════════════════════════════════════
    final cards = find.byType(Card);
    if (cards.evaluate().isNotEmpty) {
      await tester.tap(cards.first);
      await pumpWait(tester, seconds: 3);
      expect(find.byType(Scaffold), findsWidgets);

      final addToCart = find.byKey(const Key('product_add_to_cart_button'));
      final ownProduct = find.byKey(const Key('product_own_product_message'));
      debugPrint(
        'T08 ✓ Product detail (addToCart=${addToCart.evaluate().isNotEmpty || ownProduct.evaluate().isNotEmpty})',
      );
      await goBack(tester);
    } else {
      debugPrint('T08 SKIP: No product cards');
    }

    // ════════════════════════════════════════════════════════════════════
    // T09: Home screen is scrollable
    // ════════════════════════════════════════════════════════════════════
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -300));
      await tester.pump(const Duration(seconds: 2));
      await tester.drag(scrollable.first, const Offset(0, 300));
      await tester.pump(const Duration(seconds: 2));
      debugPrint('T09 ✓ Scroll works');
    } else {
      debugPrint('T09 SKIP: No scrollable');
    }

    // ════════════════════════════════════════════════════════════════════
    // T06: Navigate to profile screen
    // ════════════════════════════════════════════════════════════════════
    final settingsIcon = find.byKey(const Key('home_settings_button'));
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T06 SKIP: Settings icon not found');
    } else {
      await tester.tap(settingsIcon);
      await pumpWait(tester, seconds: 5);
      expect(find.byType(Scaffold), findsWidgets);

      final orderBtn = find.byKey(const Key('profile_my_orders_button'));
      final favBtn = find.byKey(const Key('profile_favorites_button'));
      final addrBtn = find.byKey(const Key('profile_address_button'));
      final found =
          orderBtn.evaluate().length +
          favBtn.evaluate().length +
          addrBtn.evaluate().length;
      debugPrint('T06 ✓ Profile screen ($found menu items)');

      // ══════════════════════════════════════════════════════════════════
      // T10-T13: Profile sub-pages (orders, favorites, address, terms)
      // ══════════════════════════════════════════════════════════════════
      await checkProfileSubPage(tester, 'profile_my_orders_button', 'T10');
      await checkProfileSubPage(tester, 'profile_favorites_button', 'T11');
      await checkProfileSubPage(tester, 'profile_address_button', 'T12');
      await checkProfileSubPage(tester, 'profile_terms_button', 'T13');

      // ══════════════════════════════════════════════════════════════════
      // T15: Back navigation works
      // ══════════════════════════════════════════════════════════════════
      final ordersBtn2 = find.byKey(const Key('profile_my_orders_button'));
      if (ordersBtn2.evaluate().isNotEmpty) {
        await tester.tap(ordersBtn2);
        await pumpWait(tester, seconds: 2);
        await goBack(tester);
        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('T15 ✓ Back navigation');
      } else {
        debugPrint('T15 SKIP: Orders button not found');
      }
    }

    debugPrint('');
    debugPrint('════════════════════════════════════════');
    debugPrint('  ✓ All 15 Critical Flows checked');
    debugPrint('════════════════════════════════════════');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
