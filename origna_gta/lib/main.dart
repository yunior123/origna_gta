import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ConfigService().initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = ConfigService().sentryDnsKey;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.1; // 10% of transactions
      options.beforeSend = (event, hint) {
        // Filter sensitive data
        if (event.user != null) {
          event.user = event.user!.copyWith(
            email: null, // Don't send emails to Sentry
          );
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
    },
    appRunner: () async {

      // Set global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exceptionAsString();

        // Ignore the disposed Web engine view error
        if (kIsWeb && message.contains('disposed EngineFlutterView')) {
          return;
        }

        // Log to Sentry
        Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
        );

        // Let Flutter still show errors in debug
        FlutterError.presentError(details);
      };
      runApp(const OrignaApp());
    },
  );
}

// ============================================================================
// VERSION 1.0 - COMPLETED FEATURES
// ============================================================================
// [DONE] Contact us section - Added to ProfileScreen
// [DONE] Seller can edit products and mark as sold out - EditProductScreen
// [DONE] Terms and conditions screen with signup checkbox - TermsScreen, LoginScreen
// [DONE] API keys moved to Firebase Remote Config - ConfigService
// [DONE] T&C link in checkout
// [DONE] Delete product cloud function - functions/main.py delete_product
// [DONE] Atomic stock validation in checkout
// [DONE] Amount verification in Stripe webhook
// [DONE] Stock restoration for failed/expired payments
// [DONE] Rating system for delivered products

// ============================================================================
// FUTURE VERSIONS
// ============================================================================
// TODO v2.0: Splash and launch icons
// TODO v2.0: Admin Panel - Build separate admin dashboard for moderation
// TODO v2.0: Integration tests for checkout, payment flows, cloud functions
// TODO v4.0: Chatbot integration
// TODO v4.0: Algolia search for better product discovery
