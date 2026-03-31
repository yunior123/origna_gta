import 'dart:async';

import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// Service that automatically signs out users after a period of inactivity.
///
/// SECURITY: Implements Phase 3 session timeout. Tracks user interactions via
/// [recordActivity] and triggers a sign-out after [BusinessRules.sessionTimeoutMinutes]
/// minutes of no activity.
///
/// Design:
/// - Singleton pattern for global access.
/// - Backend-agnostic: injects auth callbacks via [configure].
/// - User-bound timer: only signs out the user whose session started the timer
///   (prevents accidental logout if user switches accounts).
/// - Shows a SnackBar notification before signing out.
class SessionTimeoutService {
  static final Duration _defaultInactivityTimeout = Duration(
    minutes: BusinessRules.sessionTimeoutMinutes,
  );

  /// The inactivity timeout duration (configurable for testing).
  Duration _inactivityTimeout = _defaultInactivityTimeout;

  /// Overrides the inactivity timeout in tests.
  @visibleForTesting
  set inactivityTimeout(Duration value) => _inactivityTimeout = value;

  /// Resets the singleton to its initial state for testing.
  @visibleForTesting
  static void resetInstance() {
    _instance.stopMonitoring();
    _instance._inactivityTimeout = _defaultInactivityTimeout;
    _instance._currentUserIdProvider = null;
    _instance._signOutCallback = null;
  }

  /// Singleton instance
  /// The singleton instance.
  static final SessionTimeoutService _instance =
      SessionTimeoutService._internal();

  /// Timer that fires when inactivity timeout is reached.
  Timer? _timeoutTimer;

  /// Timestamp of the last recorded user activity.
  DateTime _lastActivityTime = DateTime.now();

  /// Navigator key used for showing SnackBars on timeout.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// The user ID whose session started the current timer (BOOT-H2 binding).
  String? _watchedUserId;

  /// Provider function that returns the current authenticated user ID.
  String? Function()? _currentUserIdProvider;

  /// Callback function that performs the actual sign-out.
  Future<void> Function()? _signOutCallback;

  /// Overrides the last activity time in tests.
  @visibleForTesting
  set lastActivityTime(DateTime value) => _lastActivityTime = value;

  /// Exposes the timeout handler for testing.
  @visibleForTesting
  Future<void> handleTimeoutForTesting() => _handleTimeout();

  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._internal();

  /// Inject app auth callbacks so this service stays backend-agnostic.
  void configure({
    String? Function()? currentUserIdProvider,
    Future<void> Function()? signOutCallback,
  }) {
    _currentUserIdProvider = currentUserIdProvider;
    _signOutCallback = signOutCallback;
  }

  /// Get remaining time before timeout
  Duration getRemainingTime() {
    final elapsed = DateTime.now().difference(_lastActivityTime);
    final remaining = _inactivityTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if session is about to expire (< 5 minutes remaining)
  bool isAboutToExpire() {
    return getRemainingTime().inMinutes < 5;
  }

  /// Call this whenever user interacts with the app (no context needed)
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }

  /// Start monitoring user activity. Pass the app's [GlobalKey] of [NavigatorState].
  void startMonitoring(GlobalKey<NavigatorState> navigatorKey) {
    _timeoutTimer?.cancel(); // Prevent timer leak on repeated calls
    final currentUserId = _currentUserIdProvider?.call();
    if (currentUserId == null) return;
    _navigatorKey = navigatorKey;
    _watchedUserId = currentUserId; // BOOT-H2: bind timer to this user
    _resetTimer();
  }

  /// Stop monitoring (when user logs out manually)
  void stopMonitoring() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _navigatorKey = null;
    _watchedUserId = null; // BOOT-H2: clear binding
  }

  /// Handle timeout event - sign out user
  Future<void> _handleTimeout() async {
    final currentUserId = _currentUserIdProvider?.call();
    if (currentUserId == null) return;
    // BOOT-H2: only sign out the exact user whose session started this timer
    if (_watchedUserId != null && currentUserId != _watchedUserId) return;

    try {
      await _signOutCallback?.call();

      // Show snackbar using the NavigatorState's context (never stale)
      final ctx = _navigatorKey?.currentContext;
      if (ctx != null) {
        // ignore: use_build_context_synchronously — context is obtained fresh at call time
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(UIMessages.sessionExpired),
            duration: const Duration(seconds: 5),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
    } catch (e) {
      // Auto-logout failed — user will need to re-authenticate manually.
      // Log but don't crash — timeout handler must be resilient.
      AppLogger.w('Session timeout sign-out failed: $e', tag: 'session');
    }
  }

  /// Reset the inactivity timer
  void _resetTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_inactivityTimeout, _handleTimeout);
  }
}
