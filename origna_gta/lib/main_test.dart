// Test-only main entry point that skips URL strategy configuration
// This file is used exclusively for integration tests to avoid the
// "Cannot set URL strategy a second time" error

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';

/// Emulator host: localhost for simulators/web, LAN IP for physical devices.
String get _emulatorHost {
  if (kIsWeb) return 'localhost';
  // Physical iOS/Android devices can't reach localhost — use Mac's LAN IP.
  // Update this IP if your network changes.
  if (Platform.isIOS || Platform.isAndroid) return '192.168.2.42';
  return 'localhost';
}

/// Flag to track if app has been initialized
bool _appInitialized = false;

/// Initialize app for a single test (doesn't re-run if already initialized)
Future<void> initAppForTest() async {
  if (!_appInitialized) {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // EMULATOR CONFIGURATION
    final host = _emulatorHost;
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Connected to Firebase Emulators at $host');
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
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ProviderScope(child: OrignaApp()),
      ),
    );
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // EMULATOR CONFIGURATION - Always use emulators for tests
  final host = _emulatorHost;
  try {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    debugPrint('Connected to Firebase Emulators at $host');
  } catch (e) {
    debugPrint('Emulator connection: $e');
  }

  await ConfigService().initialize(skipFetch: true);

  _appInitialized = true;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: OrignaApp()),
    ),
  );
}

/// Reset app state (for test isolation)
void resetAppState() {
  _appInitialized = false;
}
