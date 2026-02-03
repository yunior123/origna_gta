// Test-only main entry point that skips URL strategy configuration
// This file is used exclusively for integration tests to avoid the
// "Cannot set URL strategy a second time" error

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';

/// Flag to track if app has been initialized
bool _appInitialized = false;

/// Initialize app for a single test (doesn't re-run if already initialized)
Future<void> initAppForTest() async {
  if (!_appInitialized) {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // EMULATOR CONFIGURATION
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      debugPrint('✓ Connected to Firebase Emulators for testing');
    } catch (e) {
      debugPrint('Emulator connection: $e');
    }

    await ConfigService().initialize(skipFetch: true);
    _appInitialized = true;
  }
}

/// Main entry point for tests - skips URL strategy
Future<void> mainTest() async {
  if (_appInitialized) {
    // App already initialized, just run the widget
    runApp(const ProviderScope(child: OrignaApp()));
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // EMULATOR CONFIGURATION - Always use emulators for tests
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    debugPrint('✓ Connected to Firebase Emulators for testing');
  } catch (e) {
    debugPrint('Emulator connection: $e');
  }

  await ConfigService().initialize(skipFetch: true);

  _appInitialized = true;

  runApp(const ProviderScope(child: OrignaApp()));
}

/// Reset app state (for test isolation)
void resetAppState() {
  _appInitialized = false;
}
