/// Environment Configuration for OrignaGTA Flutter App
/// =====================================================
///
/// WHAT'S EMULATED (Local):
/// - OrignaBase Auth
/// - OrignaBase Database
/// - OrignaBase Handlers
/// - OrignaBase Storage
///
/// WHAT'S REAL (Even in Emulator Mode):
/// - Cloudflare R2 → Uses emulator/ folder prefix
/// - Stripe → Uses test keys (sk_test_*)
/// - All other external APIs
///
/// BACKEND CONTRACT:
/// - `baseUrl` is the public website host and share-link origin.
/// - `orignabaseUrl` is the primary backend for auth, data, and business APIs.
/// - Web bundle served from Hetzner VPS with Caddy.
///
/// USAGE:
/// - Emulator mode: Pass --dart-define=ENVIRONMENT=emulator
/// - Dev mode: Pass --dart-define=ENVIRONMENT=dev
/// - Production mode: Pass --dart-define=ENVIRONMENT=production
///
/// VS Code will automatically pass these flags when using launch configurations.
library;

import 'package:flutter/foundation.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// Environment enumeration
enum AppEnvironment {
  emulator, // Local development against OrignaBase/local services
  dev, // Development environment
  staging, // Staging environment
  production, // Production environment
}

String _baseUrlForEnvironment(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.emulator:
      return 'http://localhost:5001';
    case AppEnvironment.dev:
      return 'https://dev.orignagta.ca';
    case AppEnvironment.staging:
      return 'https://staging.orignagta.ca';
    case AppEnvironment.production:
      return 'https://orignagta.ca';
  }
}

String _orignabaseUrlForEnvironment(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.emulator:
      return 'http://localhost:8080';
    case AppEnvironment.dev:
      return 'https://api.dev.orignagta.ca';
    case AppEnvironment.staging:
      return 'https://api.staging.orignagta.ca';
    case AppEnvironment.production:
      return 'https://api.orignagta.ca';
  }
}

/// Environment configuration class
class EnvConfig {
  // Singleton pattern
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  static String baseUrlFor(AppEnvironment environment) =>
      _baseUrlForEnvironment(environment);

  static String orignabaseUrlFor(AppEnvironment environment) =>
      _orignabaseUrlForEnvironment(environment);

  /// Get current environment from compile-time constant
  static const String _envString = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  /// Whether to use local OrignaBase services
  static const bool _useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false,
  );

  static const String _orignabaseUrlOverride = String.fromEnvironment(
    'ORIGNABASE_URL',
    defaultValue: '',
  );

  /// Cached environment — resolved once at construction time, never re-evaluated.
  late final AppEnvironment _cachedEnvironment = _resolveEnvironment();

  AppEnvironment _resolveEnvironment() {
    if (_envString == 'emulator' || _useEmulators) {
      return AppEnvironment.emulator;
    }
    if (_envString == 'dev') return AppEnvironment.dev;
    if (_envString == 'staging') return AppEnvironment.staging;
    if (_envString == 'production') return AppEnvironment.production;
    // Reject unknown environment strings instead of silently falling back to production.
    throw StateError(
      'Unknown ENVIRONMENT="$_envString". '
      'Valid values: emulator, dev, staging, production.',
    );
  }

  /// Current environment (memoized — safe to call on every rebuild)
  AppEnvironment get environment => _cachedEnvironment;

  /// Check if running in emulator mode
  bool get isEmulator => environment == AppEnvironment.emulator;
  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  /// Public website host used for links and browser-facing routes.
  String get baseUrl => _baseUrlForEnvironment(environment);

  /// Whether we are running in an integration test environment
  bool get isTest => const bool.fromEnvironment('IS_TEST', defaultValue: false);

  /// Whether to connect to local OrignaBase services.
  bool get shouldUseEmulators {
    if (_useEmulators) return true;
    if (environment == AppEnvironment.emulator) return true;
    // For web, auto-detect localhost logic removed to respect explicit environment config
    // if (kIsWeb) { ... }
    return false;
  }

  /// R2 Storage paths based on environment — BOOT-M4: switch over enum
  String get r2ProductsFolder => switch (environment) {
    AppEnvironment.emulator => 'emulator/products',
    AppEnvironment.dev => 'dev/products',
    AppEnvironment.staging => 'staging/products',
    AppEnvironment.production => 'products',
  };
  String get r2UsersFolder => switch (environment) {
    AppEnvironment.emulator => 'emulator/users',
    AppEnvironment.dev => 'dev/users',
    AppEnvironment.staging => 'staging/users',
    AppEnvironment.production => 'users',
  };

  /// Primary OrignaBase API URL for auth, data, and business logic.
  /// Non-production defaults fail away from production unless explicitly overridden.
  String get orignabaseUrl {
    if (_orignabaseUrlOverride.isNotEmpty) {
      return _orignabaseUrlOverride;
    }

    final defaultUrl = orignabaseUrlFor(environment);
    if (defaultUrl.isEmpty) {
      throw StateError(
        'ENVIRONMENT=${environment.name} requires ORIGNABASE_URL to be set.',
      );
    }
    return defaultUrl;
  }

  /// Get environment display name
  String get displayName {
    switch (environment) {
      case AppEnvironment.emulator:
        return 'Emulator (Micro-Staging)';
      case AppEnvironment.dev:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  /// Print environment info (for debugging)
  void printInfo() {
    AppLogger.i(
      'ENV CONFIG: $displayName | emulators=$shouldUseEmulators | r2=$r2ProductsFolder | url=$orignabaseUrl | debug=${!kReleaseMode}',
      tag: 'env',
    );
  }
}

/// Global instance for easy access
final envConfig = EnvConfig();
