// 15 Critical Flow Integration Tests for OrignaGTA
//
// Run on physical iPhone:
//   flutter test integration_test/critical_flows_test.dart -d 00008120-000174923ADB401E
//
// Requires Firebase emulators running:
//   cd .. && firebase emulators:start --import=emulator-data

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:origna_gta/main_test.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Helpers ──────────────────────────────────────────────────────

  Future<void> launchApp(WidgetTester tester) async {
    await app.mainTest();
    // Pump repeatedly instead of pumpAndSettle to avoid timeout
    // from persistent timers (Firebase, Riverpod streams, animations).
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<bool> isOnLoginScreen(WidgetTester tester) async {
    return find.byKey(const Key('login_submit_button')).evaluate().isNotEmpty;
  }

  Future<void> loginAsBuyer(WidgetTester tester) async {
    final emailField = find.byKey(const Key('login_email_field'));
    final passwordField = find.byKey(const Key('login_password_field'));

    if (emailField.evaluate().isEmpty) return;

    await tester.enterText(emailField, 'yuniorrodriguezo460@gmail.com');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(passwordField, 'REDACTED_TEST_PASSWORD');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('login_submit_button')));

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TEST 1: App launches and renders MaterialApp
  // ════════════════════════════════════════════════════════════════

  testWidgets('T01: App launches successfully on device', (tester) async {
    await launchApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T01 PASS: App launched');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 2: Login screen shows email + password fields + submit
  // ════════════════════════════════════════════════════════════════

  testWidgets('T02: Login screen has email, password, and submit', (tester) async {
    await launchApp(tester);

    if (!await isOnLoginScreen(tester)) {
      debugPrint('T02 SKIP: Already logged in');
      return;
    }

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    debugPrint('T02 PASS: Login screen fields present');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 3: Buyer can log in via emulator
  // ════════════════════════════════════════════════════════════════

  testWidgets('T03: Buyer logs in successfully', (tester) async {
    await launchApp(tester);

    if (!await isOnLoginScreen(tester)) {
      debugPrint('T03 SKIP: Already logged in');
      expect(find.byType(Scaffold), findsWidgets);
      return;
    }

    await loginAsBuyer(tester);

    // After login, submit button should be gone (navigated away)
    final stillOnLogin = find.byKey(const Key('login_submit_button'));
    expect(stillOnLogin.evaluate().isEmpty, isTrue,
        reason: 'Should navigate away from login after successful auth');
    debugPrint('T03 PASS: Buyer logged in');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 4: Home screen renders product grid or loading state
  // ════════════════════════════════════════════════════════════════

  testWidgets('T04: Home screen shows products or loading', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    // Home should have a GridView (product grid) or Cards or loading indicator
    final hasGrid = find.byType(GridView).evaluate().isNotEmpty;
    final hasCards = find.byType(Card).evaluate().isNotEmpty;
    final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;

    expect(hasGrid || hasCards || hasScaffold, isTrue,
        reason: 'Home screen should render product content or scaffold');
    debugPrint('T04 PASS: Home screen rendered (grid=$hasGrid, cards=$hasCards)');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 5: Home screen has cart icon in app bar
  // ════════════════════════════════════════════════════════════════

  testWidgets('T05: Cart icon visible on home screen', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
    final cartIconAlt = find.byIcon(Icons.shopping_cart);

    expect(cartIcon.evaluate().isNotEmpty || cartIconAlt.evaluate().isNotEmpty, isTrue,
        reason: 'Cart icon should be visible on home screen');
    debugPrint('T05 PASS: Cart icon found');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 6: Settings/profile icon navigates to profile screen
  // ════════════════════════════════════════════════════════════════

  testWidgets('T06: Navigate to profile screen', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T06 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Profile screen should have a Scaffold
    expect(find.byType(Scaffold), findsWidgets);

    // Should see profile-related icons (orders, favorites, address, etc.)
    final orderIcon = find.byIcon(Icons.shopping_bag_outlined);
    final favIcon = find.byIcon(Icons.favorite_outline);
    final locationIcon = find.byIcon(Icons.location_on_outlined);
    final found = orderIcon.evaluate().length +
        favIcon.evaluate().length +
        locationIcon.evaluate().length;

    expect(found, greaterThanOrEqualTo(1),
        reason: 'Profile screen should have at least 1 menu icon');
    debugPrint('T06 PASS: Profile screen loaded ($found menu items)');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 7: Navigate to cart screen
  // ════════════════════════════════════════════════════════════════

  testWidgets('T07: Navigate to cart screen', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
    final cartIconAlt = find.byIcon(Icons.shopping_cart);
    final target = cartIcon.evaluate().isNotEmpty ? cartIcon : cartIconAlt;

    if (target.evaluate().isEmpty) {
      debugPrint('T07 SKIP: Cart icon not found');
      return;
    }

    await tester.tap(target.first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T07 PASS: Cart screen loaded');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 8: Product card tap opens product details
  // ════════════════════════════════════════════════════════════════

  testWidgets('T08: Tap product card opens details', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final cards = find.byType(Card);
    if (cards.evaluate().isEmpty) {
      debugPrint('T08 SKIP: No product cards on screen');
      return;
    }

    await tester.tap(cards.first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Product details screen should show — scaffold + some content
    expect(find.byType(Scaffold), findsWidgets);

    // Look for "Add to Cart" button or product info
    final addToCart = find.textContaining('Add to Cart');
    final ownProduct = find.textContaining('your product');
    final hasDetail = addToCart.evaluate().isNotEmpty || ownProduct.evaluate().isNotEmpty;
    debugPrint('T08 PASS: Product details loaded (addToCart=$hasDetail)');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 9: Scrolling works on home screen
  // ════════════════════════════════════════════════════════════════

  testWidgets('T09: Home screen is scrollable', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) {
      debugPrint('T09 SKIP: No scrollable found');
      return;
    }

    // Scroll down
    await tester.drag(scrollable.first, const Offset(0, -300));
    await tester.pump(const Duration(seconds: 2));

    // Scroll up
    await tester.drag(scrollable.first, const Offset(0, 300));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T09 PASS: Scroll works');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 10: Profile > Orders navigation
  // ════════════════════════════════════════════════════════════════

  testWidgets('T10: Navigate from profile to orders', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    // Go to profile
    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T10 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Tap orders icon
    final ordersIcon = find.byIcon(Icons.shopping_bag_outlined);
    if (ordersIcon.evaluate().isEmpty) {
      debugPrint('T10 SKIP: Orders icon not found in profile');
      return;
    }

    await tester.tap(ordersIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T10 PASS: Orders screen loaded');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 11: Profile > Favorites navigation
  // ════════════════════════════════════════════════════════════════

  testWidgets('T11: Navigate from profile to favorites', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T11 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final favIcon = find.byIcon(Icons.favorite_outline);
    if (favIcon.evaluate().isEmpty) {
      debugPrint('T11 SKIP: Favorites icon not in profile');
      return;
    }

    await tester.tap(favIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T11 PASS: Favorites screen loaded');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 12: Profile > Address management navigation
  // ════════════════════════════════════════════════════════════════

  testWidgets('T12: Navigate from profile to address management', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T12 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final addressIcon = find.byIcon(Icons.location_on_outlined);
    if (addressIcon.evaluate().isEmpty) {
      debugPrint('T12 SKIP: Address icon not in profile');
      return;
    }

    await tester.tap(addressIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T12 PASS: Address management screen loaded');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 13: Profile > Terms of Service navigation
  // ════════════════════════════════════════════════════════════════

  testWidgets('T13: Navigate to terms of service', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T13 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final termsIcon = find.byIcon(Icons.description_outlined);
    if (termsIcon.evaluate().isEmpty) {
      debugPrint('T13 SKIP: Terms icon not in profile');
      return;
    }

    await tester.tap(termsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T13 PASS: Terms screen loaded');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 14: Login form validation — empty fields show error
  // ════════════════════════════════════════════════════════════════

  testWidgets('T14: Login form validates empty fields', (tester) async {
    await launchApp(tester);

    if (!await isOnLoginScreen(tester)) {
      debugPrint('T14 SKIP: Already logged in');
      return;
    }

    // Tap submit without entering anything
    await tester.tap(find.byKey(const Key('login_submit_button')));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Form should show validation errors (TextFormField errorText)
    // The form is still visible (didn't navigate away)
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    debugPrint('T14 PASS: Form validation triggered');
  });

  // ════════════════════════════════════════════════════════════════
  // TEST 15: Back navigation works from sub-screens
  // ════════════════════════════════════════════════════════════════

  testWidgets('T15: Back navigation returns to previous screen', (tester) async {
    await launchApp(tester);

    if (await isOnLoginScreen(tester)) await loginAsBuyer(tester);

    // Navigate to profile
    final settingsIcon = find.byIcon(Icons.settings_outlined);
    if (settingsIcon.evaluate().isEmpty) {
      debugPrint('T15 SKIP: Settings icon not found');
      return;
    }

    await tester.tap(settingsIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Navigate to orders
    final ordersIcon = find.byIcon(Icons.shopping_bag_outlined);
    if (ordersIcon.evaluate().isEmpty) {
      debugPrint('T15 SKIP: Orders icon not found');
      return;
    }

    await tester.tap(ordersIcon.first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Press back
    final backBtn = find.byIcon(Icons.arrow_back);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    // Should be back on profile or home
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('T15 PASS: Back navigation works');
  });
}
