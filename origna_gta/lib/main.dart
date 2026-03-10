import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/services/orignabase_conf_service.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Keep the semantics handle alive so it doesn't get GC'd in release mode.
/// Without this, ensureSemantics() has no lasting effect.
SemanticsHandle? _semanticsHandle;

void main() {
  // Use path URL strategy (no # in URLs) for cleaner web URLs
  usePathUrlStrategy();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize easy_localization — required before runApp
      // Supports EN (default) + FR (Quebec Bill 96 / Loi 96 compliance)
      // FLUTTER-Y: Safari may throw on localStorage access (private browsing).
      // Fall through gracefully — EasyLocalization will use in-memory fallback.
      try {
        await EasyLocalization.ensureInitialized();
      } catch (e, st) {
        debugPrint('⚠️ EasyLocalization init failed (non-fatal): $e');
        if (!kDebugMode) await Sentry.captureException(e, stackTrace: st);
      }

      // Force semantic tree on web for accessibility + E2E Playwright testing.
      // Flutter Web renders to <canvas> — this generates a parallel <flt-semantics>
      // DOM tree with ARIA attributes that Playwright can target.
      // IMPORTANT: Store the handle — if it's GC'd, semantics gets disabled.
      // debug always on, profile only if FORCE_SEMANTICS=true, release never
      if (kIsWeb && (kDebugMode || const bool.fromEnvironment('FORCE_SEMANTICS'))) {
        _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
        if (kDebugMode) {
          debugPrint('♿ Semantics enabled: ${_semanticsHandle != null}');
        }
      }

      // Initialize the OrignaBase-backed config service.
      final ob = OrignaBase.initialize(url: envConfig.orignabaseUrl);
      await OrignaBaseConfigService().initialize(ob);

      await SentryFlutter.init((options) {
        options.dsn = OrignaBaseConfigService().sentryDnsKey;
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
            final user = event.user!;
            event.user = SentryUser(
              id: user.id,
              username: user.username,
              ipAddress: null, // F-286: IP is PII under PIPEDA — never forward to Sentry
              data: user.data,
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
          // Mobile: 100% only in production; 10% in dev/staging to avoid noise + quota burn
          options.tracesSampleRate = envConfig.isProduction ? 1.0 : 0.1;
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
