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

      // Initialize OrignaBase SDK (sync — no network call).
      final ob = OrignaBase.initialize(url: envConfig.orignabaseUrl);

      // Set global Flutter error handler before runApp.
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

      // Start runApp immediately so Flutter renders at the earliest possible moment.
      // Config and Sentry are initialized in background — the app handles "not ready" state.
      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('fr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const ProviderScope(child: OrignaApp()),
        ),
      );

      // Background: fetch remote config (safe defaults already set).
      // 10s timeout — slow network should not block the rendered app.
      unawaited(
        OrignaBaseConfigService()
            .initialize(ob)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  debugPrint('⚠️ Config init timed out — proceeding with defaults'),
            )
            .catchError((_) {}),
      );

      // Background: initialize Sentry after config is likely populated.
      // Short delay gives config a head-start before reading sentryDnsKey.
      unawaited(
        Future.delayed(const Duration(seconds: 2)).then((_) async {
          try {
            await SentryFlutter.init((options) {
              options.dsn = OrignaBaseConfigService().sentryDnsKey;
              options.environment = envConfig.isProduction
                  ? 'production'
                  : envConfig.isStaging
                      ? 'staging'
                      : envConfig.isDev
                          ? 'dev'
                          : 'emulator';
              options.tracesSampleRate = 0.1;
              options.beforeSend = (event, hint) {
                if (event.user != null) {
                  final user = event.user!;
                  event.user = SentryUser(
                    id: user.id,
                    username: user.username,
                    ipAddress: null,
                    data: user.data,
                  );
                }
                return event;
              };
              if (kIsWeb) {
                options.enableAutoPerformanceTracing = false;
                options.enableFramesTracking = false;
                options.enableAutoSessionTracking = false;
              } else {
                options.tracesSampleRate = envConfig.isProduction ? 1.0 : 0.1;
              }
            }).timeout(const Duration(seconds: 10));
          } catch (_) {
            debugPrint('⚠️ Sentry init failed — continuing without error tracking');
          }
        }),
      );
    },
    (exception, stackTrace) async {
      // Capture unhandled errors to Sentry
      await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}
