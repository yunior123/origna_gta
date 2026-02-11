/// Common utilities for Patrol tests in OrignaGTA.
///
/// Usage:
/// ```dart
/// import 'common.dart';
///
/// void main() {
///   patrol('my test', ($) async {
///     await createApp($);
///     // ...
///   });
/// }
/// ```
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:patrol/patrol.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:patrol/patrol.dart';

// ──────────────────────────────────────────────────────────────────
// Configuration
// ──────────────────────────────────────────────────────────────────

final _patrolTesterConfig = PatrolTesterConfig(printLogs: true);

/// Flag to avoid double-initialising Firebase across tests.
bool _firebaseInitialised = false;

// ──────────────────────────────────────────────────────────────────
// App bootstrap (one-time Firebase init + emulators)
// ──────────────────────────────────────────────────────────────────

/// Initialise Firebase and pump the OrignaGTA app.
///
/// Call this at the beginning of every `patrol()` callback.
/// Firebase is only initialised on the first invocation; subsequent
/// calls just pump the widget.
Future<void> createApp(PatrolIntegrationTester $) async {
  if (!_firebaseInitialised) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Connect to Firebase emulators for testing
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      debugPrint('✓ Patrol: connected to Firebase Emulators');
    } catch (e) {
      debugPrint('Patrol: emulator connection: $e');
    }

    await ConfigService().initialize(skipFetch: true);
    _firebaseInitialised = true;
  }

  await $.pumpWidgetAndSettle(
    const ProviderScope(child: OrignaApp()),
  );
}

// ──────────────────────────────────────────────────────────────────
// Test helper – short alias for patrolTest with project defaults
// ──────────────────────────────────────────────────────────────────

/// Convenience wrapper around [patrolTest] with OrignaGTA defaults.
@isTest
void patrol(
  String description,
  Future<void> Function(PatrolIntegrationTester) callback, {
  bool? skip,
  List<String> tags = const [],
}) {
  patrolTest(
    description,
    config: _patrolTesterConfig,
    skip: skip,
    callback,
    tags: tags,
  );
}

// ──────────────────────────────────────────────────────────────────
// Test data constants
// ──────────────────────────────────────────────────────────────────

/// Buyer account seeded in Firebase emulator.
const kTestBuyerEmail = 'yuniorrodriguezo460@gmail.com';
const kTestBuyerPassword = '123456';

// ──────────────────────────────────────────────────────────────────
// Reusable interaction helpers
// ──────────────────────────────────────────────────────────────────

/// Log in as the test buyer via the login screen.
///
/// Assumes the app has been pumped and the login screen is visible.
Future<void> loginAsBuyer(PatrolIntegrationTester $) async {
  // Enter email
  final emailField = $(#login_email_field);
  if (emailField.exists) {
    await emailField.enterText(kTestBuyerEmail);
  } else {
    // Fallback: find by Key
    await $(const Key('login_email_field')).enterText(kTestBuyerEmail);
  }

  // Enter password
  final passwordField = $(#login_password_field);
  if (passwordField.exists) {
    await passwordField.enterText(kTestBuyerPassword);
  } else {
    await $(const Key('login_password_field')).enterText(kTestBuyerPassword);
  }

  // Tap the sign in button
  await $(const Key('login_submit_button')).tap();

  // Wait for navigation to complete
  await $.pump(const Duration(seconds: 5));
}
