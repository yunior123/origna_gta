import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  // Use path URL strategy (no # in URLs) for cleaner web URLs
  usePathUrlStrategy();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // EMULATOR CONFIGURATION
      if (kIsWeb && Uri.base.host.contains('localhost')) {
        try {
          await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
          FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
          FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
          await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
          debugPrint('Using Firebase Emulators based on localhost detection');
        } catch (e) {
          debugPrint('Failed to connect to emulators: $e');
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
           print('Persistence init error: $e');
         }
      }
      */

      await ConfigService().initialize();

      await SentryFlutter.init((options) {
        options.dsn = ConfigService().sentryDnsKey;
        options.environment = kReleaseMode ? 'production' : 'development';
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

      runApp(const ProviderScope(child: OrignaApp()));
    },
    (exception, stackTrace) async {
      // Capture unhandled errors to Sentry
      await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}
