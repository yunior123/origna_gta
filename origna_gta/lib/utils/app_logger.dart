import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized logging utility.
///
/// - Debug/info logs only print in debug mode.
/// - Warnings add GlitchTip breadcrumbs through the Sentry-compatible SDK.
/// - Errors are captured by GlitchTip in release mode.
class AppLogger {
  AppLogger._();

  /// Debug-level log — only prints in debug mode.
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint(tag != null ? '[$tag] $message' : message);
    }
  }

  /// Info-level log — only prints in debug mode.
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint(tag != null ? '[$tag] $message' : message);
    }
  }

  /// Warning-level log — prints in debug, adds GlitchTip breadcrumb.
  static void w(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      debugPrint(tag != null ? '⚠️ [$tag] $message' : '⚠️ $message');
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: tag != null ? '[$tag] $message' : message,
        level: SentryLevel.warning,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Error-level log — prints in debug, captures to GlitchTip in release.
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = tag != null ? '[$tag] $message' : message;
    if (kDebugMode) {
      debugPrint('❌ $fullMessage');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'context': fullMessage}),
      );
    }
  }
}
