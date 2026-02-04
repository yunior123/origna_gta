/// Environment Configuration for OrignaGTA Flutter App
/// =====================================================
///
/// WHAT'S EMULATED (Local):
/// - Firebase Auth (port 9099)
/// - Firestore (port 8080)
/// - Firebase Functions (port 5001)
/// - Firebase Storage (port 9199)
///
/// WHAT'S REAL (Even in Emulator Mode):
/// - Cloudflare R2 → Uses emulator/ folder prefix
/// - Stripe → Uses test keys (sk_test_*)
/// - Algolia → Uses products_emulator index
/// - All other external APIs
///
/// USAGE:
/// - Emulator mode: Pass --dart-define=ENVIRONMENT=emulator
/// - Production mode: Pass --dart-define=ENVIRONMENT=production (or omit)
///
/// VS Code will automatically pass these flags when using launch configurations.
library;

import 'package:flutter/foundation.dart';

/// Environment enumeration
enum AppEnvironment {
  emulator,   // Local development with Firebase emulators (micro-staging)
  production, // Production Firebase project
}

/// Environment configuration class
class EnvConfig {
  // Singleton pattern
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  /// Get current environment from compile-time constant
  static const String _envString = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
  
  /// Whether to use Firebase emulators
  static const bool _useEmulators = bool.fromEnvironment(
    'USE_EMULATORS',
    defaultValue: false,
  );

  /// Current environment
  AppEnvironment get environment {
    if (_envString == 'emulator' || _useEmulators) {
      return AppEnvironment.emulator;
    }
    return AppEnvironment.production;
  }

  /// Check if running in emulator mode
  bool get isEmulator => environment == AppEnvironment.emulator;
  
  /// Check if running in production mode
  bool get isProduction => environment == AppEnvironment.production;

  /// Whether to connect to Firebase emulators
  /// In web, also check localhost detection
  bool get shouldUseEmulators {
    if (_useEmulators) return true;
    if (environment == AppEnvironment.emulator) return true;
    // For web, auto-detect localhost
    if (kIsWeb) {
      try {
        // This will be evaluated at runtime for web
        return Uri.base.host.contains('localhost') || 
               Uri.base.host.contains('127.0.0.1');
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// R2 Storage paths based on environment
  String get r2ProductsFolder => isEmulator ? 'emulator/products' : 'products';
  String get r2UsersFolder => isEmulator ? 'emulator/users' : 'users';
  
  /// Algolia index name based on environment
  String get algoliaIndexName => isEmulator ? 'products_emulator' : 'products';

  /// Get environment display name
  String get displayName {
    switch (environment) {
      case AppEnvironment.emulator:
        return 'Emulator (Micro-Staging)';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  /// Print environment info (for debugging)
  void printInfo() {
    debugPrint('╔════════════════════════════════════════════════════════════╗');
    debugPrint('║ 🔧 ENVIRONMENT CONFIGURATION                               ║');
    debugPrint('╠════════════════════════════════════════════════════════════╣');
    debugPrint('║ Environment: ${displayName.padRight(43)}║');
    debugPrint('║ Use Emulators: ${shouldUseEmulators.toString().padRight(41)}║');
    debugPrint('║ R2 Products: ${r2ProductsFolder.padRight(43)}║');
    debugPrint('║ Algolia Index: ${algoliaIndexName.padRight(41)}║');
    debugPrint('║ Is Debug Mode: ${(!kReleaseMode).toString().padRight(41)}║');
    debugPrint('╚════════════════════════════════════════════════════════════╝');
  }
}

/// Global instance for easy access
final envConfig = EnvConfig();
