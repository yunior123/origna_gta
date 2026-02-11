import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

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

  /// Call this whenever user interacts with the app
  void recordActivity(BuildContext context) {
    _lastActivityTime = DateTime.now();
    _resetTimer(context);
  }

  /// Start monitoring user activity
  void startMonitoring(BuildContext context) {
    _timeoutTimer?.cancel(); // Prevent timer leak on repeated calls
    if (_auth.currentUser == null) return;

    _resetTimer(context);
  }

  /// Stop monitoring (when user logs out manually)
  void stopMonitoring() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Handle timeout event - sign out user
  Future<void> _handleTimeout(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _auth.signOut();

      // Show snackbar to inform user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expired due to inactivity. Please login again.'),
            duration: Duration(seconds: 5),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
    } catch (e) {
      // Auto-logout failed — user will need to re-authenticate manually
    }
  }

  /// Reset the inactivity timer
  void _resetTimer(BuildContext context) {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(_inactivityTimeout, () {
      _handleTimeout(context);
    });
  }
}
