// ─────────────────────────────────────────────────────────────────────────────
// Shared Test Helpers — All integration tests import this.
// Centralizes credentials, pump helpers, login, and navigation.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:origna_gta/main_test.dart' as app;

bool _appBootstrapped = false;

void debugStep(String id, String message) {
  debugPrint('[$id] $message');
}

class CaseTracker {
  final bool strictIntegration;
  int caseCount = 0;
  final List<String> failedCases = [];

  CaseTracker({required this.strictIntegration});

  void check(String id, bool condition, String label) {
    caseCount++;
    if (!condition) {
      debugStep(id, 'FAIL — $label');
      if (strictIntegration) {
        failedCases.add('$id: $label');
      }
      return;
    }
    debugStep(id, 'PASS — $label');
  }

  void stopOnSkip(String id, String reason) {
    debugStep(id, 'SKIP => STOP — $reason');
    if (strictIntegration) {
      failedCases.add('$id: SKIP => STOP — $reason');
    }
  }

  void throwIfFailed() {
    if (strictIntegration && failedCases.isNotEmpty) {
      final preview = failedCases.take(20).join(' | ');
      fail(
        'Integration run completed with ${failedCases.length} failed checks. First failures: $preview',
      );
    } else if (!strictIntegration && failedCases.isNotEmpty) {
      debugStep(
        'Z03',
        'Non-strict mode: ${failedCases.length} failed checks recorded but not fatal',
      );
    }
  }
}

// ─── CREDENTIALS ─────────────────────────────────────────────────────────────

const buyerEmail = 'yuniorrodriguezo460@gmail.com';
const buyerPassword = 'REDACTED_TEST_PASSWORD';
const sellerEmail = 'yuniorrodriguezo4601@yahoo.com';
const sellerPassword = 'REDACTED_TEST_PASSWORD';
const adminEmail = 'yr62813@gmail.com';
const adminPassword = 'REDACTED_TEST_PASSWORD';

class Credential {
  final String label;
  final String email;
  final String password;

  const Credential({
    required this.label,
    required this.email,
    required this.password,
  });
}

const buyerCredentialCandidates = <Credential>[
  Credential(label: '[buyer]', email: buyerEmail, password: 'REDACTED_TEST_PASSWORD'),
];

const sellerCredentialCandidates = <Credential>[
  Credential(
    label: '[buyer,seller]',
    email: sellerEmail,
    password: 'REDACTED_TEST_PASSWORD',
  ),
];

const adminCredentialCandidates = <Credential>[
  Credential(
    label: '[buyer,seller,admin]',
    email: adminEmail,
    password: 'REDACTED_TEST_PASSWORD',
  ),
];

// ─── PUMP HELPERS ────────────────────────────────────────────────────────────

/// Pump N frames with a short delay.
Future<void> pumpFor(
  WidgetTester tester, {
  int frames = 5,
  int ms = 100,
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

/// Wait for network / Firebase operations.
Future<void> pumpWait(WidgetTester tester, {int seconds = 3}) async {
  debugPrint('⏱️  pumpWait START: ${seconds}s');
  final iterations = seconds * 2;
  for (var i = 0; i < iterations; i++) {
    debugPrint('  ⏱️  Pump ${i + 1}/$iterations (500ms)');
    await tester.pump(const Duration(milliseconds: 500));
  }
  debugPrint('✅ pumpWait COMPLETE: ${seconds}s elapsed');
}

Future<bool> waitForAppBootstrap(
  WidgetTester tester, {
  int timeoutSeconds = 180,
}) async {
  debugPrint('🚀 waitForAppBootstrap START: timeout=${timeoutSeconds}s');
  final materialApp = find.byType(MaterialApp);
  final scaffold = find.byType(Scaffold);
  final homeSettings = find.byKey(const Key('home_settings_button'));

  final maxTicks = timeoutSeconds * 2;
  for (var i = 0; i < maxTicks; i++) {
    final hasMaterialApp = materialApp.evaluate().isNotEmpty;
    final hasScaffold = scaffold.evaluate().isNotEmpty;
    final hasHomeSettings = homeSettings.evaluate().isNotEmpty;

    if (i % 10 == 0) {
      debugPrint('  [$i/$maxTicks] MaterialApp=$hasMaterialApp Scaffold=$hasScaffold HomeSettings=$hasHomeSettings');
    }

    if (hasMaterialApp && (hasScaffold || hasHomeSettings)) {
      debugPrint('✅ waitForAppBootstrap COMPLETE: app ready after ${i * 500}ms');
      return true;
    }

    await tester.pump(const Duration(milliseconds: 500));
  }

  debugPrint('❌ waitForAppBootstrap TIMEOUT: ${timeoutSeconds}s exceeded');
  return false;
}

// ─── APP LIFECYCLE ───────────────────────────────────────────────────────────

/// Launch app and wait for it to settle.
Future<void> launchApp(WidgetTester tester, {int pumpSeconds = 6}) async {
  debugPrint('🚀🚀 launchApp START: pumpSeconds=$pumpSeconds');
  debugPrint('  📱 Calling app.mainTest()...');
  await app.mainTest();
  debugPrint('  ✅ app.mainTest() complete');
  
  debugPrint('  ⏱️  pumpWait for ${pumpSeconds}s...');
  await pumpWait(tester, seconds: pumpSeconds);
  
  debugPrint('  🔍 Checking bootstrap status...');
  final bootstrapped = await waitForAppBootstrap(tester);
  if (!bootstrapped) {
    debugPrint('❌❌ launchApp FAILED: bootstrap timeout');
    fail(
      'launchApp: bootstrap timeout (MaterialApp=${find.byType(MaterialApp).evaluate().isNotEmpty}, '
      'Scaffold=${find.byType(Scaffold).evaluate().isNotEmpty}, '
      'home_settings_button=${find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty})',
    );
  }
  debugPrint('✅✅ launchApp COMPLETE: app running');
}

Future<void> ensureAppStarted(WidgetTester tester, {int pumpSeconds = 6}) async {
  if (!_appBootstrapped) {
    await app.mainTest();
    await pumpWait(tester, seconds: pumpSeconds);
    _appBootstrapped = true;
  }

  final bootstrapped = await waitForAppBootstrap(tester);
  if (!bootstrapped) {
    fail(
      'ensureAppStarted: bootstrap timeout (MaterialApp=${find.byType(MaterialApp).evaluate().isNotEmpty}, '
      'Scaffold=${find.byType(Scaffold).evaluate().isNotEmpty}, '
      'home_settings_button=${find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty})',
    );
  }
}

Future<bool> ensureHomeReady(WidgetTester tester, {int timeoutSeconds = 15}) async {
  await navigateToTab(tester, Icons.home);
  final maxTicks = timeoutSeconds * 2;
  for (var i = 0; i < maxTicks; i++) {
    final hasSettings =
        find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty;
    final hasCart =
        find.byKey(const Key('home_cart_button')).evaluate().isNotEmpty;
    final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
    if (hasSettings && hasScaffold) {
      return true;
    }
    if (!hasScaffold) {
      await tester.pump(const Duration(milliseconds: 350));
      continue;
    }
    if (!hasSettings && hasCart) {
      await navigateToTab(tester, Icons.home);
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  return find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty;
}

// ─── LOGIN HELPERS ───────────────────────────────────────────────────────────

Future<bool> loginWith(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  debugPrint('🔐 loginWith START: email=$email');
  
  // Wait for login fields
  debugPrint('  ⏳ Waiting for login fields...');
  for (var i = 0; i < 12; i++) {
    if (find.byKey(const Key('login_email_field')).evaluate().isNotEmpty) {
      debugPrint('  ✅ Login fields found after ${i + 1} attempts');
      break;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  final emailField = find.byKey(const Key('login_email_field'));
  final passwordField = find.byKey(const Key('login_password_field'));

  if (emailField.evaluate().isEmpty || passwordField.evaluate().isEmpty) {
    debugPrint('⚠️ Login fields not found — may already be logged in');
    return false;
  }
  debugPrint('  📧 Email field: present');
  debugPrint('  🔑 Password field: present');

  // Toggle to Sign In mode if in Register mode
  if (find.byKey(const Key('login_name_field')).evaluate().isNotEmpty) {
    debugPrint('  ℹ️  In Register mode, toggling to Sign In...');
    final toggle = find.byKey(const Key('login_toggle_mode_button'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle.first, warnIfMissed: false);
      await pumpFor(tester);
      debugPrint('  ✅ Toggled to Sign In mode');
    }
  }

  debugPrint('  ⌨️  Entering email...');
  await tester.enterText(emailField, email);
  await pumpFor(tester, frames: 3, ms: 100);
  debugPrint('  ✅ Email entered');
  
  debugPrint('  ⌨️  Entering password...');
  await tester.enterText(passwordField, password);
  await pumpFor(tester, frames: 3, ms: 100);
  debugPrint('  ✅ Password entered');

  // Dismiss keyboard
  debugPrint('  ⌨️  Dismissing keyboard...');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await pumpFor(tester, frames: 3, ms: 200);
  debugPrint('  ✅ Keyboard dismissed');

  final loginButton = find.byKey(const Key('login_submit_button'));
  if (loginButton.evaluate().isEmpty) {
    debugPrint('  ❌ Login button not found');
    return false;
  }
  debugPrint('  🔘 Login button found, tapping...');

  await tester.tap(loginButton.first, warnIfMissed: false);
  debugPrint('  ⏳ Waiting 5s for login to complete...');
  await pumpWait(tester, seconds: 5);
  debugPrint('✅ loginWith COMPLETE');
  return true;
}

bool isAdminAccountEmail(String email) {
  final lower = email.toLowerCase();
  return adminCredentialCandidates
      .map((credential) => credential.email.toLowerCase())
      .contains(lower);
}

Future<Credential?> switchToAnyCredential(
  WidgetTester tester,
  List<Credential> credentials,
) async {
  if (credentials.isEmpty) return null;
  
  final credential = credentials.first;
  debugPrint('🔄 switchToAnyCredential: ${credential.email}');
  
  debugPrint('  ⚙️  Looking for settings button...');
  final settingsButton = find.byKey(const Key('home_settings_button'));
  if (settingsButton.evaluate().isEmpty) {
    debugPrint('  ❌ Settings button not found');
    return null;
  }
  debugPrint('  ✅ Settings button found, tapping...');

  await tester.tap(settingsButton.first, warnIfMissed: false);

  debugPrint('  ⏳ Waiting 4s for popup/profile to appear...');
  await pumpWait(tester, seconds: 4);

  debugPrint('  💬 Checking for sign-in popup...');
  final _ = await handleSignInPopup(
    tester,
    email: credential.email,
    password: credential.password,
  );

  debugPrint('  ✅ switchToAnyCredential completed');
  return credential;
}

Future<Credential?> switchCredentialWithRecovery(
  WidgetTester tester,
  List<Credential> candidates,
  String scope,
) async {
  final credential = await switchToAnyCredential(tester, candidates);
  if (credential != null) {
    await ensureHomeReady(tester, timeoutSeconds: 3);
    return credential;
  }
  return null;
}

Future<bool> ensureAddProductCreationContext(WidgetTester tester) async {
  final credential = await switchCredentialWithRecovery(
    tester,
    <Credential>[...adminCredentialCandidates, ...sellerCredentialCandidates],
    'P00',
  );
  if (credential == null) {
    return false;
  }

  await ensureHomeReady(tester, timeoutSeconds: 12);
  final canNavigate = await navigateToAddProduct(tester);
  if (!canNavigate) {
    debugStep(
      'P00',
      'Role session established but add-product entry is still unavailable',
    );
    return false;
  }

  return true;
}

// ─── NAVIGATION ──────────────────────────────────────────────────────────────

/// Navigate to a tab by icon.
Future<void> navigateToTab(WidgetTester tester, IconData icon) async {
  debugPrint('🔀 navigateToTab: icon=$icon');
  final tabIcon = find.byIcon(icon);
  if (tabIcon.evaluate().isNotEmpty) {
    debugPrint('  ✅ Tab icon found, tapping...');
    await tester.tap(tabIcon.first, warnIfMissed: false);
    debugPrint('  ⏳ Waiting 2s...');
    await pumpWait(tester, seconds: 2);
    debugPrint('✅ navigateToTab COMPLETE');
  } else {
    debugPrint('  ❌ Tab icon not found');
  }
}

Future<bool> _ensureFinderOnScreen(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 16,
}) async {
  debugPrint('📐 _ensureFinderOnScreen: maxAttempts=$maxAttempts');
  if (finder.evaluate().isEmpty) {
    debugPrint('  ❌ Finder is empty');
    return false;
  }

  try {
    debugPrint('  📄 Attempting ensureVisible...');
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 150));
    debugPrint('  ✅ ensureVisible succeeded');
  } catch (e) {
    debugPrint('  ⚠️  ensureVisible failed: $e');
  }

  bool isOnScreen() {
    if (finder.evaluate().isEmpty) return false;
    final center = tester.getCenter(finder.first, warnIfMissed: false);
    final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    final onScreen = center.dx >= 0 &&
        center.dy >= 0 &&
        center.dx <= logicalSize.width &&
        center.dy <= logicalSize.height;
    debugPrint('    isOnScreen: center=$center, size=$logicalSize, result=$onScreen');
    return onScreen;
  }

  if (isOnScreen()) {
    debugPrint('✅ _ensureFinderOnScreen: widget already on screen');
    return true;
  }

  debugPrint('  🔍 Looking for scrollable...');
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) {
    debugPrint('  ❌ No scrollable found');
    return false;
  }
  debugPrint('  ✅ Scrollable found, starting scroll attempts...');

  for (var i = 0; i < maxAttempts; i++) {
    final direction = i < (maxAttempts ~/ 2) ? -280.0 : 280.0;
    debugPrint('  [${i + 1}/$maxAttempts] Dragging direction=$direction');
    await tester.drag(scrollable.first, Offset(0, direction));
    await tester.pump(const Duration(milliseconds: 220));
    if (finder.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 120));
      } catch (_) {}
    }
    if (isOnScreen()) {
      debugPrint('✅✅ _ensureFinderOnScreen SUCCESS: widget on screen after ${i + 1} attempts');
      return true;
    }
  }

  debugPrint('❌ _ensureFinderOnScreen FAILED: widget not on screen after $maxAttempts attempts');
  return false;
}

/// Tap a widget by Key name. Returns true if found and tapped.
Future<bool> tapByKey(WidgetTester tester, String keyName) async {
  debugPrint('🔘 tapByKey: key="$keyName"');
  final finder = find.byKey(Key(keyName));
  if (finder.evaluate().isNotEmpty) {
    debugPrint('  ✅ Widget found');
    final ready = await _ensureFinderOnScreen(tester, finder);
    if (!ready) {
      debugPrint('  ❌ Widget off-screen/non-hit-testable');
      fail(
        'tapByKey: widget "$keyName" is present but off-screen/non-hit-testable',
      );
    }
    debugPrint('  🔘 Tapping...');
    await tester.tap(finder.first, warnIfMissed: false);
    await pumpFor(tester, frames: 5, ms: 100);
    debugPrint('✅ tapByKey SUCCESS');
    return true;
  }
  debugPrint('  ❌ Widget not found');
  return false;
}

/// Enter text into a field found by Key.
Future<void> enterTextByKey(
  WidgetTester tester,
  String key,
  String text,
) async {
  debugPrint('⌨️  enterTextByKey: key="$key", text=${text.substring(0, min(text.length, 20))}...');
  final field = find.byKey(Key(key));
  if (field.evaluate().isNotEmpty) {
    debugPrint('  ✅ Field found');
    final ready = await _ensureFinderOnScreen(tester, field);
    if (!ready) {
      debugPrint('  ❌ Field off-screen/non-hit-testable');
      fail(
        'enterTextByKey: field "$key" is present but off-screen/non-hit-testable',
      );
    }
    debugPrint('  🔘 Tapping field...');
    await tester.tap(field.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    debugPrint('  ⌨️  Entering text...');
    await tester.enterText(field, text);
    await pumpFor(tester, frames: 3, ms: 100);
    debugPrint('✅ enterTextByKey SUCCESS');
  } else {
    debugPrint('  ❌ Field not found');
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
  final materialBackButton = find.byType(BackButton);
  if (materialBackButton.evaluate().isNotEmpty) {
    await tester.tap(materialBackButton.first, warnIfMissed: false);
    await pumpWait(tester);
    return;
  }

  final closeButton = find.byType(CloseButton);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.first, warnIfMissed: false);
    await pumpWait(tester);
    return;
  }

  for (final k in [
    'addproduct_back_button',
    'back_button',
    'profile_back_button',
  ]) {
    final btn = find.byKey(Key(k));
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn.first, warnIfMissed: false);
      await pumpWait(tester);
      return;
    }
  }

  try {
    await tester.pageBack();
    await pumpWait(tester, seconds: 2);
    return;
  } catch (_) {}

  debugPrint('⚠ No back button found');
}

/// Scroll until [finder] is visible in the first Scrollable.
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = -300,
  int maxScrolls = 20,
}) async {
  final scrollables = find.byType(Scrollable).evaluate().toList();
  if (scrollables.isEmpty) return;

  Finder? activeScrollable;
  for (final element in scrollables) {
    final candidate = find.byElementPredicate((e) => e == element);
    final onScreen = await _ensureFinderOnScreen(
      tester,
      candidate,
      maxAttempts: 1,
    );
    if (onScreen) {
      activeScrollable = candidate;
      break;
    }
  }

  activeScrollable ??= find.byElementPredicate((e) => e == scrollables.first);

  if (finder.evaluate().isNotEmpty) {
    final ready = await _ensureFinderOnScreen(tester, finder, maxAttempts: 6);
    if (ready) return;
  }

  for (var i = 0; i < maxScrolls; i++) {
    if (finder.evaluate().isNotEmpty) {
      final ready = await _ensureFinderOnScreen(tester, finder, maxAttempts: 3);
      if (ready) return;
    }
    await tester.drag(
      activeScrollable.first,
      Offset(0, delta),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  if (finder.evaluate().isNotEmpty) {
    final ready = await _ensureFinderOnScreen(tester, finder, maxAttempts: 12);
    if (!ready) {
      fail(
        'scrollUntilVisible: target is present but still off-screen/non-hit-testable',
      );
    }
  }
}

/// Navigate to profile sub-screen, verify loaded, go back.
Future<void> checkProfileSubPage(
  WidgetTester tester,
  String buttonKey,
  String label,
) async {
  if (buttonKey == 'profile_terms_button' || buttonKey.contains('terms')) {
    debugPrint(
      '$label SKIP: External terms/policy page intentionally not tapped in E2E',
    );
    return;
  }

  final btn = find.byKey(Key(buttonKey));
  if (btn.evaluate().isEmpty) {
    debugPrint('$label SKIP: Button not found');
    return;
  }
  await scrollUntilVisible(tester, btn, delta: -220, maxScrolls: 12);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(btn.first, warnIfMissed: false);
  await pumpWait(tester, seconds: 2);
  expect(find.byType(Scaffold), findsWidgets);
  debugPrint('$label ✓ Screen loaded');
  await goBack(tester);
  await pumpWait(tester);

  final profileAnchor = find.byKey(const Key('profile_my_orders_button'));
  final homeSettings = find.byKey(const Key('home_settings_button'));
  if (profileAnchor.evaluate().isEmpty && homeSettings.evaluate().isEmpty) {
    try {
      await tester.pageBack();
      await pumpWait(tester, seconds: 2);
    } catch (_) {}
  }
}

Future<bool> handleSignInPopup(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  debugPrint('🔍 handleSignInPopup: checking for dialog...');
  debugPrint('  Looking for key: login_dialog_sign_in_button');
  final dialogKey = find.byKey(const Key('login_dialog_sign_in_button'));
  debugPrint('  Dialog button found: ${dialogKey.evaluate().isNotEmpty}');
  
  if (dialogKey.evaluate().isEmpty) {
    debugPrint('  ❌ No popup found');
    debugPrint('  DEBUG: Listing all visible Text widgets...');
    final allTexts = find.byType(Text);
    final textCount = allTexts.evaluate().length;
    debugPrint('    Total Text widgets: $textCount');
    if (textCount > 0 && textCount < 50) {
      // Only show if reasonable number
      for (var i = 0; i < min(10, textCount); i++) {
        final widget = tester.widget<Text>(allTexts.at(i));
        final data = widget.data?.toString() ?? '';
        if (data.length < 100) {
          debugPrint('      Text[$i]: ${data.substring(0, min(50, data.length))}');
        }
      }
    }
    return false;
  }
  debugPrint('  ✅ Popup detected');
  debugPrint('ℹ️ Sign In Required popup detected — navigating to login...');
  debugPrint('  🔘 Tapping Sign In button in dialog...');
  debugPrint('    Dialog button widget count: ${dialogKey.evaluate().length}');
  debugPrint('    Attempting to tap dialogKey.first with warnIfMissed=false...');
  
  // Wait longer for dialog to be fully rendered and clickable
  debugPrint('    Waiting for dialog to stabilize...');
  await pumpWait(tester, seconds: 2);
  
  debugPrint('    Executing tap...');
  await tester.tap(dialogKey.first, warnIfMissed: false);
  debugPrint('  ✅ Tap completed');
  debugPrint('  ⏳ Waiting 3s after dialog dismiss...');
  await pumpWait(tester, seconds: 3);
  debugPrint('  📝 Calling loginWith...');
  await loginWith(tester, email: email, password: password);
  debugPrint('  ⏳ Waiting 2s after login...');
  await pumpWait(tester, seconds: 2);
  debugPrint('✅ handleSignInPopup COMPLETE — Login completed after popup');
  return true;
}

Future<bool> navigateToAddProduct(WidgetTester tester) async {
  final addBtn = find.byKey(const Key('home_add_product_button'));

  // Retry loop to absorb auth/profile provider timing on web integration runs
  for (int attempt = 0; attempt < 4; attempt++) {
    if (addBtn.evaluate().isNotEmpty) break;
    await navigateToTab(tester, Icons.home);
    await pumpWait(tester, seconds: 2);
    await pumpSettle(tester, iterations: 4);
  }

  if (addBtn.evaluate().isEmpty) {
    debugPrint(
      '⚠ Add Product button not found after retries — user may not have seller/admin role or profile not loaded',
    );
    return false;
  }

  final ready = await _ensureFinderOnScreen(tester, addBtn);
  if (!ready) {
    fail(
      'navigateToAddProduct: add product button is present but off-screen/non-hit-testable',
    );
  }
  await tester.tap(addBtn.first, warnIfMissed: false);
  await pumpSettle(tester, iterations: 5);
  debugPrint('✓ Navigated to Add Product screen');
  return true;
}

Future<void> pumpSettle(
  WidgetTester tester, {
  int iterations = 3,
  int ms = 1000,
}) async {
  for (int i = 0; i < iterations; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

// ─── TEST INITIALIZATION HELPERS ─────────────────────────────────────────────

/// Initialize integration test with standard setup.
Future<CaseTracker> initializeIntegrationTest(
  WidgetTester tester, {
  bool strictIntegration = true,
}) async {
  await ensureAppStarted(tester);
  return CaseTracker(strictIntegration: strictIntegration);
}

/// Establish user session with credential recovery and home verification.
Future<Credential?> establishSession(
  WidgetTester tester,
  List<Credential> candidates,
  String scope,
  CaseTracker tracker,
  String skipCode,
  String skipMessage,
) async {
  
  final credential = await switchCredentialWithRecovery(
    tester,
    candidates,
    scope,
  );
  if (credential == null) {
    tracker.stopOnSkip(skipCode, skipMessage);
    tracker.throwIfFailed();
    return null;
  }
  await ensureHomeReady(tester, timeoutSeconds: 2);
  return credential;
}

/// Open settings panel from home.
Future<bool> openSettings(WidgetTester tester) async {
  final settingsButton = find.byKey(const Key('home_settings_button'));
  if (settingsButton.evaluate().isEmpty) return false;
  
  await tester.tap(settingsButton.first, warnIfMissed: false);
  
  await pumpWait(tester, seconds: 3);
  return true;
}

// ─── PRODUCT TEST HELPERS ────────────────────────────────────────────────────

/// Publish product and verify success with tracker.
Future<bool> publishAndVerify(
  WidgetTester tester,
  CaseTracker tracker,
  String testId,
  String checkCode,
  String skipCode,
) async {
  await tapPublishProduct(tester);
  final hasSuccess = await didPublishSucceed(tester);
  tracker.check(checkCode, hasSuccess, '$testId publication reussie');
  if (!hasSuccess) {
    tracker.stopOnSkip(
      skipCode,
      '$testId publish failed (validation/images/backend)',
    );
  }
  return hasSuccess;
}

/// Clean up after product publish and verify in marketplace.
Future<bool> cleanupAndVerifyProduct(
  WidgetTester tester,
  String productName,
  CaseTracker tracker,
  String checkCode,
  String testId,
) async {
  if (find.byKey(const Key('addproduct_screen_title')).evaluate().isNotEmpty) {
    await goBack(tester);
    await pumpSettle(tester, iterations: 3);
  }
  await pumpSettle(tester, iterations: 3);
  final exist = await verifyProductInMarketplace(tester, productName);
  tracker.check(checkCode, exist, '$testId trouve dans marketplace');
  return exist;
}

Future<void> fillBasicProductFields(
  WidgetTester tester, {
  required String name,
  required String price,
  String description = 'Integration test product',
  String stock = '10',
  String categoryItemKey = 'category_item_categories.electronics',
}) async {
  await enterTextByKey(tester, 'product_name_field', name);
  await enterTextByKey(tester, 'product_description_field', description);
  await enterTextByKey(tester, 'product_price_field', price);
  await enterTextByKey(tester, 'product_stock_field', stock);

  final categorySelector = find.byKey(
    const Key('addproduct_category_selector'),
  );
  if (categorySelector.evaluate().isNotEmpty) {
    final categoryReady = await _ensureFinderOnScreen(
      tester,
      categorySelector,
      maxAttempts: 14,
    );
    if (!categoryReady) {
      fail(
        'fillBasicProductFields: category selector is present but off-screen/non-hit-testable',
      );
    }

    await tester.tap(categorySelector.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    final categoryItem = find.byKey(Key(categoryItemKey));
    if (categoryItem.evaluate().isNotEmpty) {
      await tester.tap(categoryItem.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      final fallbackOption = find.textContaining('Elect');
      if (fallbackOption.evaluate().isNotEmpty) {
        await tester.tap(fallbackOption.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      } else {
        fail(
          'fillBasicProductFields: no selectable category option found in dropdown',
        );
      }
    }
  } else {
    fail('fillBasicProductFields: addproduct_category_selector not found');
  }

  debugPrint('✓ Filled basic fields: $name / \$$price / stock=$stock');
}

Future<void> tapGlassToggle(WidgetTester tester, String identifier) async {
  final keyFinder = find.byKey(Key(identifier));
  expect(keyFinder, findsWidgets, reason: 'Toggle Key "$identifier" not found');
  final ready = await _ensureFinderOnScreen(tester, keyFinder);
  if (!ready) {
    fail(
      'tapGlassToggle: toggle "$identifier" is present but off-screen/non-hit-testable',
    );
  }
  await tester.tap(keyFinder.first);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> fillAddress(WidgetTester tester) async {
  // Scroll down to make address fields visible
  await scrollUntilVisible(
    tester,
    find.byKey(const Key('addproduct_section_package')),
  );
  await tester.pump(const Duration(milliseconds: 500));
  // Street (triggers Geoapify suggestions)
  await enterTextByKey(tester, 'addproduct_street_field', '123 Test Street');
  await tester.pump(const Duration(milliseconds: 900));

  var suggestionSelected = false;
  final suggestionTiles = find.byType(ListTile);
  if (suggestionTiles.evaluate().isNotEmpty) {
    final ready = await _ensureFinderOnScreen(
      tester,
      suggestionTiles,
      maxAttempts: 8,
    );
    if (ready) {
      await tester.tap(suggestionTiles.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      suggestionSelected = true;
      debugPrint('✓ fillAddress: selected first address suggestion');
    }
  }

  if (!suggestionSelected) {
    // Manual fallback when suggestions are unavailable.
    await enterTextByKey(tester, 'addproduct_city_field', 'Toronto');

    final provinceDropdown = find.byKey(
      const Key('addproduct_province_dropdown'),
    );
    if (provinceDropdown.evaluate().isNotEmpty) {
      final provinceReady = await _ensureFinderOnScreen(
        tester,
        provinceDropdown,
        maxAttempts: 14,
      );
      if (!provinceReady) {
        fail(
          'fillAddress: province dropdown is present but off-screen/non-hit-testable',
        );
      }

      await tester.tap(provinceDropdown.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      final ontarioOption = find.text('ON');
      if (ontarioOption.evaluate().isNotEmpty) {
        await tester.tap(ontarioOption.last, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      }
    } else {
      fail('fillAddress: addproduct_province_dropdown not found');
    }

    await enterTextByKey(tester, 'addproduct_postal_code_field', 'M5V 3L9');
  }

  debugPrint('✓ Filled address fields using keys/suggestions');
}

/// Attempt to submit the product form.
Future<String?> tapPublishProduct(WidgetTester tester) async {
  final submitBtn = find.byKey(const Key('addproduct_submit_button'));
  final ready = await _ensureFinderOnScreen(tester, submitBtn, maxAttempts: 20);
  if (!ready) {
    fail(
      'tapPublishProduct: submit button is present but off-screen/non-hit-testable',
    );
  }

  final currentUser = FirebaseAuth.instance.currentUser;
  debugPrint(
    'ℹ️ Publish auth context: uid=${currentUser?.uid} email=${currentUser?.email}',
  );

  await tester.tap(submitBtn.first);

  String? latestSnack;
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 500));

    final errorSnackText = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Text),
    );
    if (errorSnackText.evaluate().isNotEmpty) {
      final textWidget = tester.widget<Text>(errorSnackText.first);
      latestSnack =
          textWidget.data ??
          textWidget.textSpan?.toPlainText() ??
          'unknown error';
    }

    final hasSuccessSnack = find
        .byKey(const Key('addproduct_success_snackbar'))
        .evaluate()
        .isNotEmpty;
    final leftAddProductScreen = find
        .byKey(const Key('addproduct_screen_title'))
        .evaluate()
        .isEmpty;

    if (hasSuccessSnack || leftAddProductScreen) {
      break;
    }
  }

  if (latestSnack != null && latestSnack.trim().isNotEmpty) {
    debugPrint('⚠ Publish snackbar: $latestSnack');
  }

  return latestSnack;
}

Future<bool> didPublishSucceed(WidgetTester tester) async {
  for (var i = 0; i < 90; i++) {
    final hasSuccessSnack = find
        .byKey(const Key('addproduct_success_snackbar'))
        .evaluate()
        .isNotEmpty;
    final hasLeftAddProductScreen = find
        .byKey(const Key('addproduct_screen_title'))
        .evaluate()
        .isEmpty;
    if (hasSuccessSnack || hasLeftAddProductScreen) {
      return true;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  return false;
}

List<double> extractDollarAmounts(Finder finder) {
  final amounts = <double>[];
  final dollarRegex = RegExp(r'\$\s*([0-9]+(?:\.[0-9]{1,2})?)');

  for (final element in finder.evaluate()) {
    final widget = element.widget;
    if (widget is! Text) continue;

    final content = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    for (final match in dollarRegex.allMatches(content)) {
      final raw = match.group(1);
      final value = raw == null ? null : double.tryParse(raw);
      if (value != null) {
        amounts.add(value);
      }
    }
  }

  return amounts;
}

/// Verify product appears in marketplace
Future<bool> verifyProductInMarketplace(
  WidgetTester tester,
  String productName,
) async {
  debugPrint('🔍 Verifying product in marketplace: $productName');

  // Navigate to home/browse
  await navigateToTab(tester, Icons.home);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Search for product
  final searchIcon = find.byIcon(Icons.search);
  if (searchIcon.evaluate().isNotEmpty) {
    await tester.tap(searchIcon.first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final searchField = find.byType(TextField);
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField.first, productName);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
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
