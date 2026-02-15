// ─────────────────────────────────────────────────────────────────────────────
// Shared Test Helpers — All integration tests import this.
// Centralizes credentials, pump helpers, login, and navigation.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/main_test.dart' as app;

// ─── CREDENTIALS ─────────────────────────────────────────────────────────────

const buyerEmail = 'yuniorrodriguezo4601@yahoo.com';
const buyerPassword = 'REDACTED_TEST_PASSWORD';
const sellerEmail = 'yr62813@gmail.com';
const sellerPassword = 'REDACTED_TEST_PASSWORD';
const adminEmail = 'yr62813@gmail.com';
const adminPassword = 'REDACTED_TEST_PASSWORD';

// ─── PUMP HELPERS ────────────────────────────────────────────────────────────

/// Pump N frames with a short delay.
Future<void> pumpFor(WidgetTester tester, {int frames = 5, int ms = 100}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

/// Wait for network / Firebase operations.
Future<void> pumpWait(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

// ─── APP LIFECYCLE ───────────────────────────────────────────────────────────

/// Launch app and wait for it to settle.
Future<void> launchApp(WidgetTester tester, {int pumpSeconds = 6}) async {
  await app.mainTest();
  await pumpWait(tester, seconds: pumpSeconds);
}

// ─── AUTH ─────────────────────────────────────────────────────────────────────

/// Login with email/password. Returns true if login was performed.
Future<bool> loginWith(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {

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

  // Wait for login fields
  for (var i = 0; i < 12; i++) {
    if (find.byKey(const Key('login_email_field')).evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 250));
  }

  final emailField = find.byKey(const Key('login_email_field'));
  final passwordField = find.byKey(const Key('login_password_field'));

  if (emailField.evaluate().isEmpty || passwordField.evaluate().isEmpty) {
    debugPrint('⚠️ Login fields not found — may already be logged in');
    return false;
  }

  // Toggle to Sign In mode if in Register mode
  if (find.byKey(const Key('login_name_field')).evaluate().isNotEmpty) {
    final toggle = find.byKey(const Key('login_toggle_mode_button'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await pumpFor(tester);
    }
  }

  await tester.enterText(emailField, email);
  await pumpFor(tester, frames: 3, ms: 100);
  await tester.enterText(passwordField, password);
  await pumpFor(tester, frames: 3, ms: 100);

  // Dismiss keyboard
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await pumpFor(tester, frames: 3, ms: 200);

  final loginButton = find.byKey(const Key('login_submit_button'));
  if (loginButton.evaluate().isEmpty) return false;

  await tester.tap(loginButton);
  await pumpWait(tester, seconds: 5);
  return true;
}

// ─── NAVIGATION ──────────────────────────────────────────────────────────────

/// Navigate to a tab by icon.
Future<void> navigateToTab(WidgetTester tester, IconData icon) async {
  final tabIcon = find.byIcon(icon);
  if (tabIcon.evaluate().isNotEmpty) {
    await tester.tap(tabIcon.first);
    await pumpWait(tester, seconds: 2);
  }
}

/// Tap a widget by Key name. Returns true if found and tapped.
Future<bool> tapByKey(WidgetTester tester, String keyName) async {
  final finder = find.byKey(Key(keyName));
  if (finder.evaluate().isNotEmpty) {
    await tester.tap(finder.first);
    await pumpFor(tester, frames: 5, ms: 100);
    return true;
  }
  return false;
}

/// Enter text into a field found by Key.
Future<void> enterTextByKey(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  if (field.evaluate().isNotEmpty) {
    await tester.tap(field);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(field, text);
    await pumpFor(tester, frames: 3, ms: 100);
  }
}

/// Go back to previous screen (tries multiple back button variants).
Future<void> goBack(WidgetTester tester) async {
  for (final icon in [Icons.arrow_back, Icons.arrow_back_rounded]) {
    final btn = find.byIcon(icon);
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn.first, warnIfMissed: false);
      await pumpWait(tester);
      return;
    }
  }
  for (final k in [
    'addproduct_back_button',
    'back_button',
    'profile_back_button'
  ]) {
    final btn = find.byKey(Key(k));
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn.first);
      await pumpWait(tester);
      return;
    }
  }
  debugPrint('⚠ No back button found');
}

/// Scroll until [finder] is visible in the first Scrollable.
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = -300,
  int maxScrolls = 20,
}) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return;
  for (var i = 0; i < maxScrolls; i++) {
    if (finder.evaluate().isNotEmpty) {
      final ro = finder.evaluate().first.renderObject;
      if (ro != null && ro.paintBounds.height > 0) return;
    }
    await tester.drag(scrollable.first, Offset(0, delta));
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Navigate to profile sub-screen, verify loaded, go back.
Future<void> checkProfileSubPage(
  WidgetTester tester,
  String buttonKey,
  String label,
) async {
  final btn = find.byKey(Key(buttonKey));
  if (btn.evaluate().isEmpty) {
    debugPrint('$label SKIP: Button not found');
    return;
  }
  await tester.tap(btn);
  await pumpWait(tester, seconds: 2);
  expect(find.byType(Scaffold), findsWidgets);
  debugPrint('$label ✓ Screen loaded');
  await goBack(tester);
  await pumpWait(tester);
}

Future<bool> handleSignInPopup(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final dialogKey = find.byKey(const Key('login_dialog_sign_in_button'));
  if (dialogKey.evaluate().isEmpty) return false;
  debugPrint('ℹ️ Sign In Required popup detected — navigating to login...');
  await tester.tap(dialogKey);
  await pumpWait(tester, seconds: 2);
  await loginWith(tester, email: email, password: password);
  await pumpWait(tester, seconds: 2);
  debugPrint('ℹ️ Login completed after popup');
  return true;
}

Future<bool> navigateToAddProduct(WidgetTester tester) async {
  final addBtn = find.byKey(const Key('home_add_product_button'));
  // The button might not be visible if user is not seller — wait a bit
  if (addBtn.evaluate().isEmpty) {
    await pumpSettle(tester, iterations: 8);
  }
  if (addBtn.evaluate().isEmpty) {
    debugPrint('⚠ Add Product button not found — user may not have seller/admin role');
    return false;
  }
  await tester.tap(addBtn);
  await pumpSettle(tester, iterations: 5);
  debugPrint('✓ Navigated to Add Product screen');
  return true;
}

Future<void> pumpSettle(WidgetTester tester, {int iterations = 10, int ms = 1000}) async {
  for (int i = 0; i < iterations; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> fillBasicProductFields(
  WidgetTester tester, {
  required String name,
  required String price,
  String description = 'Integration test product',
  String stock = '10',
}) async {
  await enterTextByKey(tester, 'product_name_field', name);
  await enterTextByKey(tester, 'product_description_field', description);
  await enterTextByKey(tester, 'product_price_field', price);
  await enterTextByKey(tester, 'product_stock_field', stock);
  debugPrint('✓ Filled basic fields: $name / \$$price / stock=$stock');
}

Future<void> tapGlassToggle(WidgetTester tester, String identifier) async {
  final keyFinder = find.byKey(Key(identifier));
  expect(keyFinder, findsWidgets, reason: 'Toggle Key "$identifier" not found');
  await tester.tap(keyFinder.first);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> fillAddress(WidgetTester tester) async {
  // Scroll down to make address fields visible
  await scrollUntilVisible(tester, find.byKey(const Key('addproduct_section_package')));
  await tester.pump(const Duration(milliseconds: 500));
  // Street
  await enterTextByKey(tester, 'addproduct_street_field', '123 Test Street');
  // City
  await enterTextByKey(tester, 'addproduct_city_field', 'Toronto');
  // Postal Code
  await enterTextByKey(tester, 'addproduct_postal_code_field', 'M5V 3L9');
  debugPrint('✓ Filled address fields using keys');
}

/// Attempt to submit the product form.
Future<void> tapPublishProduct(WidgetTester tester) async {
  final submitBtn = find.byKey(const Key('addproduct_submit_button'));
  await scrollUntilVisible(tester, submitBtn);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(submitBtn);
  await pumpSettle(tester, iterations: 8);
}

/// Verify product appears in marketplace
Future<bool> verifyProductInMarketplace(WidgetTester tester, String productName) async {
  debugPrint('🔍 Verifying product in marketplace: $productName');
 
  // Navigate to home/browse
  await navigateToTab(tester, Icons.home);
  for (var i = 0; i < 6; i++) { await tester.pump(const Duration(milliseconds: 500)); }
 
  // Search for product
  final searchIcon = find.byIcon(Icons.search);
  if (searchIcon.evaluate().isNotEmpty) {
    await tester.tap(searchIcon.first);
    for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
   
    final searchField = find.byType(TextField);
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField.first, productName);
      for (var i = 0; i < 6; i++) { await tester.pump(const Duration(milliseconds: 500)); }
    }
  }
  // Check if product appears
  final productFound = find.textContaining(productName);
 
  if (productFound.evaluate().isNotEmpty) {
    debugPrint('✓ Product found in marketplace');
    return true;
  }
  return false;
    }
// Future<void> enterTextByKey(WidgetTester tester, String key, String text) async {
//   final field = find.byKey(Key(key));
//   expect(field, findsOneWidget, reason: 'Field with Key("$key") not found');
//   await tester.tap(field);
//   await tester.pump(const Duration(milliseconds: 200));
//   await tester.enterText(field, text);
//   await tester.pump(const Duration(milliseconds: 300));
// }
// /// Tap a widget by its Key.
// Future<void> tapByKey(WidgetTester tester, String keyName) async {
//   final finder = find.byKey(Key(keyName));
//   expect(finder, findsWidgets, reason: 'Key "$keyName" not found on screen');
//   await tester.tap(finder.first);
//   await tester.pump(const Duration(milliseconds: 500));
// }

// Future<void> goBack(WidgetTester tester) async {
//   final backKeys = ['addproduct_back_button', 'back_button', 'profile_back_button'];
//   for (final k in backKeys) {
//     final finder = find.byKey(Key(k));
//     if (finder.evaluate().isNotEmpty) {
//       await tester.tap(finder.first);
//       await pumpSettle(tester, iterations: 3);
//       return;
//     }
//   }
//   final backButton = find.byIcon(Icons.arrow_back_rounded);
//   if (backButton.evaluate().isNotEmpty) {
//     await tester.tap(backButton.first);
//     await pumpSettle(tester, iterations: 3);
//     return;
//   }
//   // Fallback: Navigator pop via back icon
//   final backIcon = find.byType(BackButton);
//   if (backIcon.evaluate().isNotEmpty) {
//     await tester.tap(backIcon.first);
//     await pumpSettle(tester, iterations: 3);
//     return;
//   }
//   debugPrint('⚠ No back button found');
// }