// Test-only main entry point that skips URL strategy configuration
// This file is used exclusively for integration tests to avoid the
// "Cannot set URL strategy a second time" error

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/services/orignabase_conf_service.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/env_config.dart';

/// Flag to track if app has been initialized
bool _appInitialized = false;

/// Helper: run a future with a timeout, log success or failure.
Future<void> _timedStep(String name, Future<void> Function() action,
    {Duration timeout = const Duration(seconds: 10)}) async {
  AppLogger.d('$name ...', tag: 'test');
  try {
    await action().timeout(timeout);
    AppLogger.d('$name done', tag: 'test');
  } on TimeoutException {
    AppLogger.w('$name TIMED OUT after ${timeout.inSeconds}s — skipping', tag: 'test');
  } catch (e) {
    AppLogger.e('$name ERROR: $e', tag: 'test', error: e);
  }
}

/// Initialize app for a single test (doesn't re-run if already initialized)
Future<void> initAppForTest() async {
  if (!_appInitialized) {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    final ob = OrignaBase.initialize(url: envConfig.orignabaseUrl);
    await OrignaBaseConfigService().initialize(ob, skipFetch: true);
    _appInitialized = true;
  }
}

/// Main entry point for tests - skips URL strategy
Future<void> mainTest() async {
  AppLogger.d('mainTest() called (initialized=$_appInitialized)', tag: 'test');

  const isTest = bool.fromEnvironment('IS_TEST', defaultValue: false);
  const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  if (isTest && env != 'dev') {
    throw StateError(
      'Integration tests must run against DEV OrignaBase only. '
      'Re-run with --dart-define=ENVIRONMENT=dev (current ENVIRONMENT=$env).',
    );
  }

  if (_appInitialized) {
    AppLogger.d('Re-running app (already initialized)', tag: 'test');
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

  AppLogger.d('Step 1: WidgetsFlutterBinding', tag: 'test');
  WidgetsFlutterBinding.ensureInitialized();

  await _timedStep('Step 2: EasyLocalization', () async {
    await EasyLocalization.ensureInitialized();
  });
  AppLogger.d('Step 3: using OrignaBase services', tag: 'test');

  await _timedStep('Step 4: ConfigService', () async {
    // Web integration tests rely on Remote Config for keys like geoapify_api_key.
    // Keep skipFetch for non-web to reduce flakiness and speed up local runs.
    final ob = OrignaBase.initialize(url: envConfig.orignabaseUrl);
    await OrignaBaseConfigService().initialize(ob, skipFetch: !kIsWeb);
  });

  // Web + headless Chrome can emit an invalid lifecycle transition (hidden -> resumed)
  // that triggers a Flutter framework assertion inside AppLifecycleListener.
  // Ignore it in web test runs without touching FlutterError.onError (flutter_test is sensitive to that).
  final isTestRun = const bool.fromEnvironment('IS_TEST', defaultValue: false);
  if (kIsWeb && isTestRun) {
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      final message = error.toString();
      if (message.contains(
        'Invalid state transition from AppLifecycleState.hidden to AppLifecycleState.resumed',
      )) {
        AppLogger.w(
          'Ignored web lifecycle assertion in test run',
          tag: 'test',
        );
        return true;
      }
      return false;
    };
  }

  _appInitialized = true;

  AppLogger.d('Step 5: runApp()', tag: 'test');
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: OrignaApp()),
    ),
  );
  AppLogger.d('mainTest() complete', tag: 'test');
}

/// Reset app state (for test isolation)
void resetAppState() {
  _appInitialized = false;
}
