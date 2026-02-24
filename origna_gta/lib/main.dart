import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
// import 'package:origna_gta/firebase_options.dart'; // Deprecated in favor of config/
import 'package:origna_gta/config/firebase_config_dev.dart';
import 'package:origna_gta/config/firebase_config_prod.dart';
import 'package:origna_gta/config/firebase_config_staging.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/services/notification_service.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Keep the semantics handle alive so it doesn't get GC'd in release mode.
/// Without this, ensureSemantics() has no lasting effect.
// ignore: unused_element
SemanticsHandle? _semanticsHandle;

void main() {
  // Use path URL strategy (no # in URLs) for cleaner web URLs
  usePathUrlStrategy();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize easy_localization — required before runApp
      // Supports EN (default) + FR (Quebec Bill 96 / Loi 96 compliance)
      await EasyLocalization.ensureInitialized();

      // Force semantic tree on web for accessibility + E2E Playwright testing.
      // Flutter Web renders to <canvas> — this generates a parallel <flt-semantics>
      // DOM tree with ARIA attributes that Playwright can target.
      // IMPORTANT: Store the handle — if it's GC'd, semantics gets disabled.
      // debug always on, profile only if FORCE_SEMANTICS=true, release never
      if (kIsWeb && (kDebugMode || const bool.fromEnvironment('FORCE_SEMANTICS'))) {
        _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
      }

      FirebaseOptions firebaseOptions;

      switch (envConfig.environment) {
        case AppEnvironment.dev:
          firebaseOptions = FirebaseConfigDev.currentPlatform;
          break;
        case AppEnvironment.staging:
          firebaseOptions = FirebaseConfigStaging.currentPlatform;
          break;
        case AppEnvironment.production:
          firebaseOptions = FirebaseConfigProd.currentPlatform;
          break;
        case AppEnvironment.emulator:
          // For emulator, we can use dev or prod config as base, 
          // but we MUST connect to emulators. 
          // Let's use Prod config as base to match previous behavior, 
          // but ConfigService will handle avoiding real calls if needed.
          firebaseOptions = FirebaseConfigProd.currentPlatform; 
          break;
      }

      await Firebase.initializeApp(options: firebaseOptions);

      // Print environment info (debug only)
      if (!kReleaseMode) {
        envConfig.printInfo();
        // Also print to browser console (more visible)
        if (kIsWeb) {
          // ignore: avoid_print
          print('🔧 ENV: ${envConfig.displayName}, shouldUseEmulators: ${envConfig.shouldUseEmulators}');
          // ignore: avoid_print
          print('🔧 Uri.base.host: ${Uri.base.host}');
        }
      }

      // EMULATOR CONFIGURATION - Uses env_config to determine if emulators should be used
      if (envConfig.shouldUseEmulators) {
        try {
          await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
          FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
          FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
          await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
          debugPrint('✅ Connected to Firebase Emulators (${envConfig.displayName})');
          // ignore: avoid_print
          if (kIsWeb) print('✅ EMULATORS CONNECTED');
        } catch (e) {
          debugPrint('❌ Failed to connect to emulators: $e');
          // ignore: avoid_print
          if (kIsWeb) print('❌ EMULATOR CONNECTION FAILED: $e');
        }
      } else {
        debugPrint('🌐 Using Production Firebase (${envConfig.displayName})');
        // ignore: avoid_print
        if (kIsWeb) print('⚠️ PRODUCTION MODE - NOT USING EMULATORS');
      }

      // Set auth persistence to LOCAL for web (survives page refreshes and browser restarts)
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          debugPrint('🔐 Auth persistence set to LOCAL');
          


        } catch (e) {
          debugPrint('⚠️ Could not set auth persistence: $e');
        }
      }

      // Explicitly enable Firestore persistence for Web if valid
      // Note: Persistence can sometimes cause issues with multiple tabs or restrictive browser environments.
      // But for E2E it might mask network failure as success.
      // We want to verify it SYNCED.
      /*
      if (kIsWeb) {
         try {
           await FirebaseFirestore.instance.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
         } catch(e) {
           debugPrint('Persistence init error: $e');
         }
      }
      */

      await ConfigService().initialize();

      // Register FCM background handler before runApp — FCM requires this to be
      // called at app startup before any other Firebase Messaging calls.
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      await SentryFlutter.init((options) {
        options.dsn = ConfigService().sentryDnsKey;
        // Use env_config for environment naming (dev/staging must not be labeled 'emulator')
        options.environment = envConfig.isProduction
            ? 'production'
            : envConfig.isStaging
                ? 'staging'
                : envConfig.isDev
                    ? 'dev'
                    : 'emulator';
        options.tracesSampleRate = 0.1; // 10% of transactions
        options.beforeSend = (event, hint) {
          // Filter sensitive data - strip emails before sending
          if (event.user != null) {
            event.user = SentryUser(id: event.user!.id, username: event.user!.username, ipAddress: event.user!.ipAddress, data: event.user!.data);
          }
          return event;
        };
        // On web, disable frame tracking & auto performance
        if (kIsWeb) {
          options.enableAutoPerformanceTracing = false;
          options.enableFramesTracking = false;
          options.enableAutoSessionTracking = false;
        } else {
          // mobile defaults (optional tuning):
          options.tracesSampleRate = 1.0;
        }
      });

      // Set global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exceptionAsString();
        // Ignore the disposed Web engine view error
        if (kIsWeb && message.contains('disposed EngineFlutterView')) {
          return;
        }
        // Log to Sentry
        Sentry.captureException(details.exception, stackTrace: details.stack);
        // Let Flutter still show errors in debug
        FlutterError.presentError(details);
      };

      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const ProviderScope(child: OrignaApp()),
        ),
      );
    },
    (exception, stackTrace) async {
      // Capture unhandled errors to Sentry
      await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}
