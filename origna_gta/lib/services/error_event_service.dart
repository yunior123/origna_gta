import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// Best-effort internal error-event persistence.
///
/// Stores structured diagnostic events in OrignaBase so support can correlate
/// user-visible `ORIGNA-*` codes with stack traces, auth context, and metadata.
abstract final class ErrorEventService {
  static final Random _random = Random.secure();
  static final Map<String, DateTime> _recentFingerprints = <String, DateTime>{};

  static OrignaBase? _ob;
  static String _environment = 'unknown';

  static void initialize(OrignaBase ob, {required String environment}) {
    _ob = ob;
    _environment = environment;
  }

  static Future<void> record({
    required Object error,
    required String? userFacingCode,
    required String userFacingMessage,
    String? sentryEventId,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
    String source = 'flutter_app',
    String severity = 'error',
  }) async {
    final ob = _ob;
    if (ob == null) return;

    final payload = buildPayload(
      error: error,
      userFacingCode: userFacingCode,
      userFacingMessage: userFacingMessage,
      sentryEventId: sentryEventId,
      stackTrace: stackTrace,
      context: context,
      extras: extras,
      source: source,
      severity: severity,
      environment: _environment,
      userId: ob.auth.currentUserId,
      email: ob.auth.currentEmail,
    );

    final fingerprint = payload[Fields.fingerprint] as String?;
    if (fingerprint == null || _isDuplicateFingerprint(fingerprint)) {
      return;
    }

    try {
      await ob.collection(Collections.errorEvents).add(payload);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('ErrorEventService.persist failed: $e');
      }
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildPayload({
    required Object error,
    required String? userFacingCode,
    required String userFacingMessage,
    required String environment,
    String? sentryEventId,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
    String source = 'flutter_app',
    String severity = 'error',
    String? userId,
    String? email,
  }) {
    final eventId = _generateInternalEventId();
    final fingerprint = _fingerprintFor(
      code: userFacingCode,
      context: context,
      error: error,
    );

    final payload = <String, dynamic>{
      Fields.internalEventId: eventId,
      Fields.errorCode: userFacingCode ?? 'ORIGNA-SYS-999',
      Fields.userFacingMessage: userFacingMessage,
      Fields.sentryEventId: sentryEventId,
      Fields.errorType: error.runtimeType.toString(),
      Fields.errorMessage: _truncate('$error', maxLength: 4000),
      Fields.stackTrace: _truncate(stackTrace?.toString(), maxLength: 12000),
      Fields.environment: environment,
      Fields.source: source,
      Fields.routeOrAction: context,
      Fields.severity: severity,
      Fields.status: 'new',
      Fields.fingerprint: fingerprint,
      Fields.userId: userId,
      Fields.email: email,
      Fields.metadata: _buildMetadata(extras),
      Fields.createdAt: FieldValue.serverTimestamp(),
    }..removeWhere((_, value) => value == null);

    return payload;
  }

  static String _generateInternalEventId() {
    final now = DateTime.now().toUtc();
    final date =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = (_random.nextInt(0xFFFFFF) + 1)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(6, '0');
    return 'SE-$date-$suffix';
  }

  static String _fingerprintFor({
    required String? code,
    required String? context,
    required Object error,
  }) {
    return '${code ?? 'ORIGNA-SYS-999'}|${context ?? 'unknown'}|${error.runtimeType}|$error';
  }

  static bool _isDuplicateFingerprint(String fingerprint) {
    final now = DateTime.now().toUtc();
    _recentFingerprints.removeWhere(
      (_, timestamp) => now.difference(timestamp) > const Duration(seconds: 30),
    );
    final previous = _recentFingerprints[fingerprint];
    if (previous != null) {
      return true;
    }
    _recentFingerprints[fingerprint] = now;
    return false;
  }

  static Map<String, dynamic>? _buildMetadata(Map<String, dynamic>? extras) {
    final sanitized = <String, dynamic>{
      'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'buildMode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
    };
    if (extras != null && extras.isNotEmpty) {
      extras.forEach((key, value) {
        sanitized[key] = _normalizeJsonValue(value);
      });
    }
    return sanitized;
  }

  static dynamic _normalizeJsonValue(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _normalizeJsonValue(nestedValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeJsonValue).toList(growable: false);
    }

    try {
      return jsonDecode(jsonEncode(value));
    } catch (_) {
      return _truncate(value.toString(), maxLength: 1000);
    }
  }

  static String? _truncate(String? value, {required int maxLength}) {
    if (value == null) return null;
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }
}
