import 'dart:async';

import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Service to automatically logout users after 15 minutes of inactivity.
///
/// SECURITY: Phase 3 - Session timeout implementation
/// Tracks user interactions and signs out after 15 minutes of inactivity.
class SessionTimeoutService {
  // BOOT-L1: sourced from BusinessRules constant instead of hardcoded
  static final Duration _inactivityTimeout = Duration(minutes: BusinessRules.sessionTimeoutMinutes);

  /// Singleton instance
  static final SessionTimeoutService _instance = SessionTimeoutService._internal();
  Timer? _timeoutTimer;
  DateTime _lastActivityTime = DateTime.now();
  GlobalKey<NavigatorState>? _navigatorKey;
  // BOOT-H2: Track which user started the timer to prevent signing out a different user
  String? _watchedUserId;
  String? Function()? _currentUserIdProvider;
  Future<void> Function()? _signOutCallback;
  
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
      // Auto-logout failed — user will need to re-authenticate manually
    }
  }

  /// Reset the inactivity timer
  void _resetTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_inactivityTimeout, _handleTimeout);
  }
}
