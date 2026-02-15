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
  // Handle "Sign In Required" popup — dismiss it, don't navigate to login
  final signInPopup = find.byKey(const Key('login_dialog_sign_in_button'));
  if (signInPopup.evaluate().isNotEmpty &&
      find.byKey(const Key('login_submit_button')).evaluate().isEmpty) {
    // Dismiss via Cancel to avoid pushing login route (crash risk)
    final cancelBtn = find.byKey(const Key('login_dialog_cancel_button'));
    if (cancelBtn.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
    }
  }

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
