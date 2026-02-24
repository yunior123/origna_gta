import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Service to automatically logout users after 15 minutes of inactivity.
///
/// SECURITY: Phase 3 - Session timeout implementation
/// Tracks user interactions and signs out after 15 minutes of inactivity.
class SessionTimeoutService {
  static const Duration _inactivityTimeout = Duration(minutes: 15);

  /// Singleton instance
  static final SessionTimeoutService _instance = SessionTimeoutService._internal();
  Timer? _timeoutTimer;
  DateTime _lastActivityTime = DateTime.now();
  GlobalKey<NavigatorState>? _navigatorKey;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._internal();

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
    if (_auth.currentUser == null) return;
    _navigatorKey = navigatorKey;
    _resetTimer();
  }

  /// Stop monitoring (when user logs out manually)
  void stopMonitoring() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _navigatorKey = null;
  }

  /// Handle timeout event - sign out user
  Future<void> _handleTimeout() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _auth.signOut();

      // Best-effort: wait for auth state propagation (esp. Web)
      try {
        await _auth
            .authStateChanges()
            .firstWhere((u) => u == null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

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
      // Auto-logout failed — user will need to re-authenticate manually
    }
  }

  /// Reset the inactivity timer
  void _resetTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_inactivityTimeout, _handleTimeout);
  }
}
