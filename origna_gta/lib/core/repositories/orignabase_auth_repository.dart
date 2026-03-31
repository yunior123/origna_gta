import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/orignabase_notification_service.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:origna_gta/utils/safe_url_launcher.dart';

import 'auth_repository.dart';

/// Returns the device's preferred language if it's one we support (en/fr), else 'en'.
String _deviceLanguage() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return code == LanguageValues.french
      ? LanguageValues.french
      : LanguageValues.english;
}

/// OrignaBase-specific auth exception that mirrors common auth error codes.
/// so the existing error handling in login_viewmodel.dart works unchanged.
class OrignaBaseAuthException implements Exception {
  final String code;
  final String? message;
  final String? challengeToken;

  OrignaBaseAuthException({
    required this.code,
    this.message,
    this.challengeToken,
  });

  @override
  String toString() =>
      'OrignaBaseAuthException(code: $code, message: $message)';
}

/// OrignaBase implementation of [AuthRepository].
///
/// This repository handles all authentication-related operations, including
/// multi-factor authentication, third-party OAuth providers, and account management.
///
/// Error codes from OrignaBase SDK exceptions are mapped to Firebase-style
/// codes (`user-not-found`, `wrong-password`, etc.) to maintain compatibility
/// with existing error handling logic in the app.
class OrignaBaseAuthRepository implements AuthRepository {
  final OrignaBase _ob;
  bool _googleSignInInitialized = false;

  /// Creates a new instance of [OrignaBaseAuthRepository].
  OrignaBaseAuthRepository(this._ob);

  /// Timestamp of last successful re-authentication (epoch milliseconds).
  /// Used to enforce a freshness window for sensitive operations like account deletion.
  int? _lastReAuthenticatedAt;

  // ---------------------------------------------------------------------------
  // Auth methods
  // ---------------------------------------------------------------------------

  /// Registers a new user with email and password.
  ///
  /// Parameters:
  /// - [email]: the user's email address.
  /// - [password]: the user's chosen password.
  /// - [name]: the user's display name.
  /// - [marketingOptIn]: whether the user opted into marketing communications.
  ///
  /// This method also:
  /// 1. Creates a user profile document in the `users` collection.
  /// 2. Sends an email verification link.
  ///
  /// Throws:
  /// - [OrignaBaseAuthException] with code `invalid-email` if the email format is incorrect.
  /// - [OrignaBaseAuthException] with various codes if the registration fails.
  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name, {
    bool marketingOptIn = false,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!ValidationConstants.emailRegex.hasMatch(trimmedEmail)) {
      throw OrignaBaseAuthException(
        code: 'invalid-email',
        message: 'Email format is invalid',
      );
    }

    try {
      final authState = await _ob.auth.register(trimmedEmail, password);

      if (authState.isAuthenticated && authState.userId != null) {
        // Create user profile document
        await _createUserDocumentIfNeeded(
          userId: authState.userId!,
          email: trimmedEmail,
          name: name,
          consentMethod: ConsentMethodValues.signupForm,
          initialMarketingOptIn: marketingOptIn,
        );

        // Send verification email
        try {
          await _ob.auth.sendEmailVerification();
          AppLogger.d(
            'Verification email sent to $trimmedEmail during registration',
            tag: 'auth',
          );
        } catch (e) {
          AppLogger.w('Failed to send verification email: $e', tag: 'auth');
        }
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  /// Signs in a user with email and password.
  ///
  /// Parameters:
  /// - [email]: the user's email address.
  /// - [password]: the user's password.
  ///
  /// This method includes a retry mechanism for network errors (up to 3 attempts).
  ///
  /// Throws:
  /// - [OrignaBaseAuthException] with code `mfa-required` if the account has MFA enabled.
  /// - [OrignaBaseAuthException] with various codes if sign-in fails.
  ///
  /// Gotchas:
  /// - Retries are avoided on rate-limited (429) errors to prevent amplifying brute-force attacks.
  @override
  Future<void> signInWithEmail(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!ValidationConstants.emailRegex.hasMatch(trimmedEmail)) {
      throw OrignaBaseAuthException(
        code: 'invalid-email',
        message: 'Email format is invalid',
      );
    }

    try {
      AuthState authState;
      var attempt = 0;
      while (true) {
        try {
          authState = await _ob.auth.signInWithEmail(trimmedEmail, password);
          break;
        } on RateLimitException {
          // SECURITY: Never retry on 429 — amplifies brute-force attacks.
          rethrow;
        } on NetworkException catch (_) {
          attempt += 1;
          if (attempt >= 3) rethrow;
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      // Handle MFA challenge BEFORE creating profile
      if (authState.mfaRequired && authState.challengeToken != null) {
        throw OrignaBaseAuthException(
          code: 'mfa-required',
          message: 'Multi-factor authentication required',
          challengeToken: authState.challengeToken,
        );
      }

      if (authState.isAuthenticated && authState.userId != null) {
        await _createUserDocumentIfNeeded(
          userId: authState.userId!,
          email: trimmedEmail,
          consentMethod: ConsentMethodValues.signupForm,
        );
      }

      // Handle MFA challenge — preserve challengeToken so UI can proceed
      if (authState.mfaRequired && authState.challengeToken != null) {
        throw OrignaBaseAuthException(
          code: 'mfa-required',
          message: 'Multi-factor authentication required',
          challengeToken: authState.challengeToken,
        );
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  /// Signs in a user with Google OAuth.
  ///
  /// Handles platform-specific differences:
  /// - **Web**: Uses a server-side OAuth redirect flow via `/auth/google/start`.
  /// - **Mobile**: Uses the native Google Sign-In SDK to obtain an ID token.
  ///
  /// Throws:
  /// - [OrignaBaseAuthException] if Google Sign-In is disabled on the backend.
  /// - [OrignaBaseAuthException] if the ID token cannot be obtained (mobile).
  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, google_sign_in_web (GIS SDK) does NOT support authenticate().
        // The primary path is the OrignaBase server-side OAuth redirect via
        // /auth/google/start. We first check /auth/providers to confirm Google
        // is enabled; if that endpoint is unavailable (e.g. 404 on backends
        // that don't implement it), we attempt the redirect directly.
        // See: https://pub.dev/packages/google_sign_in_web — "authenticate is not supported on the web"
        bool? googleEnabledOnBackend;
        try {
          final providers = await _ob.request('GET', '/auth/providers');
          final google = providers['google'];
          googleEnabledOnBackend = google is Map && google['enabled'] == true;
        } on OrignaBaseAuthException {
          rethrow;
        } catch (_) {
          // /auth/providers is unavailable (404 or network error) — treat as
          // unknown; attempt the redirect directly and let it fail there if
          // Google OAuth is not configured on the backend.
          googleEnabledOnBackend = null;
        }

        if (googleEnabledOnBackend == false) {
          // Backend explicitly said Google is disabled.
          throw OrignaBaseAuthException(
            code: 'operation-not-allowed',
            message: 'Google Sign-In is not enabled on this server.',
          );
        }

        // googleEnabledOnBackend is true (provider check passed) or null
        // (/auth/providers endpoint missing). Either way, attempt the redirect.
        final redirectTo = Uri.base.replace(fragment: '');
        final startUrl = Uri.parse(
          '${_ob.url}/auth/google/start',
        ).replace(queryParameters: {'redirect_to': redirectTo.toString()});
        final launched = await safeLaunchUrl(
          startUrl,
          webOnlyWindowName: '_self',
        );
        if (!launched) {
          throw OrignaBaseAuthException(
            code: 'operation-not-allowed',
            message: 'Failed to start Google OAuth flow.',
          );
        }
        // Navigation initiated — method returns; auth state updated on redirect-back.
        return;
      }

      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize();
        _googleSignInInitialized = true;
      }
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw OrignaBaseAuthException(
          code: 'missing-id-token',
          message: 'Failed to obtain Google ID token',
        );
      }

      final authState = await _ob.auth.signInWithGoogle(idToken);

      if (authState.isAuthenticated && authState.userId != null) {
        await _createUserDocumentIfNeeded(
          userId: authState.userId!,
          email: authState.email ?? account.email,
          name: account.displayName,
          consentMethod: ConsentMethodValues.googleOauth,
        );
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  /// Signs in a user with Apple Sign-In.
  ///
  /// Uses the native `SignInWithApple` SDK. The user's name is only provided
  /// by Apple on the very first sign-in attempt and is persisted to `pending_profiles`.
  @override
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final authorizationCode = appleCredential.authorizationCode;

      // Apple only provides name on FIRST sign-in
      String? fullName;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        fullName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
      }

      final authState = await _ob.auth.signInWithApple(
        authorizationCode,
        displayName: fullName,
      );

      if (authState.isAuthenticated && authState.userId != null) {
        // Save name to pending profiles if provided (Apple only gives it once)
        if (fullName != null && fullName.isNotEmpty) {
          try {
            await _ob
                .collection(Collections.pendingProfiles)
                .doc(authState.userId!)
                .update({
                  Fields.name: fullName,
                  Fields.updatedAt: DateTime.now().toIso8601String(),
                });
          } catch (e) {
            AppLogger.d(
              'Failed to save Apple name to pending_profiles: $e',
              tag: 'auth',
            );
          }
        }

        await _createUserDocumentIfNeeded(
          userId: authState.userId!,
          email: authState.email ?? appleCredential.email,
          name: fullName,
          consentMethod: ConsentMethodValues.appleOauth,
        );
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  /// Signs out the current user.
  ///
  /// Clears the notification token from the backend, signs out of OrignaBase,
  /// and disconnects the Google account if applicable.
  @override
  Future<void> signOut() async {
    try {
      await OrignaBaseNotificationService.instance.clearTokenFromOrignaBase();
    } catch (e) {
      AppLogger.d(
        'Failed to clear notification token on sign out: $e',
        tag: 'auth',
      );
    }

    await _ob.auth.signOut();

    // Also sign out of Google if signed in
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      AppLogger.w('Google disconnect failed', tag: 'auth', error: e);
    }

    // Wait for auth state to propagate
    try {
      await _ob.auth.authStateChanges
          .firstWhere((state) => !state.isAuthenticated)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort: don't block navigation if event is delayed
    }
  }

  // ---------------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------------

  /// Sends a verification email to the currently authenticated user.
  ///
  /// Throws [OrignaBaseAuthException] if no user is signed in.
  @override
  Future<void> sendEmailVerification() async {
    final accessToken = _ob.auth.accessToken;
    if (accessToken == null) {
      throw OrignaBaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user',
      );
    }

    try {
      await _ob.auth.sendEmailVerification();
      AppLogger.d('Verification email sent', tag: 'auth');
    } catch (e) {
      AppLogger.d('Failed to send verification email: $e', tag: 'auth');
      rethrow;
    }
  }

  /// Checks whether the current user's email address has been verified.
  ///
  /// This method uses the access token claim for a fast path and refreshes
  /// the token to pick up recent changes if necessary.
  @override
  Future<bool> isEmailVerified() async {
    // Fast path: trust the current access-token claim when it already says the
    // user is verified. This avoids hammering /auth/refresh during app boot and
    // on verification-gated screens.
    if (_ob.auth.isEmailVerified) {
      return true;
    }

    // Otherwise refresh once to pick up any recent verification change.
    try {
      final authState = await _ob.auth.refreshToken();
      if (!authState.isAuthenticated) return false;
      return _ob.auth.isEmailVerified;
    } on NetworkException catch (e) {
      // Network error — don't assume unverified, rethrow so caller can retry
      AppLogger.w('Network error checking email verification: $e', tag: 'auth');
      rethrow;
    } catch (e) {
      // Auth error (expired session, invalid token) — treat as unverified
      AppLogger.d('Error checking email verification: $e', tag: 'auth');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  /// Sends a password reset email to the specified address.
  ///
  /// Implements anti-enumeration security by swallowing "user-not-found" errors.
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!ValidationConstants.emailRegex.hasMatch(trimmedEmail)) {
      throw OrignaBaseAuthException(
        code: 'invalid-email',
        message: 'Email format is invalid',
      );
    }

    try {
      await _ob.auth.forgotPassword(trimmedEmail);
    } catch (e) {
      // SECURITY: Don't expose if email exists or not (anti-enumeration)
      if (kDebugMode) {
        AppLogger.w('Password reset error (suppressed): $e', tag: 'auth');
      }
      // Swallow user-not-found to prevent email enumeration
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not found') || errorStr.contains('not_found')) {
        return;
      }
      rethrow;
    }
  }

  /// Completes the password reset flow using a verification code.
  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _ob.auth.resetPassword(code, newPassword);
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Account management
  // ---------------------------------------------------------------------------

  /// Re-authenticates the user with their password.
  ///
  /// This is required before sensitive operations like account deletion.
  /// Sets [_lastReAuthenticatedAt] to the current time.
  Future<void> reAuthenticate(String password) async {
    final email = _ob.auth.currentState.email;
    if (email == null || email.isEmpty) {
      throw OrignaBaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user to re-authenticate',
      );
    }
    try {
      await _ob.auth.signInWithEmail(email, password);
      _lastReAuthenticatedAt = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

  /// Permanently deletes the current user's account and signs them out.
  ///
  /// Throws [OrignaBaseAuthException] with code `requires-recent-login` if the
  /// user has not re-authenticated within the last 60 seconds.
  @override
  Future<void> deleteAccount() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw OrignaBaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user — cannot delete account',
      );
    }

    // Require re-authentication within the last 60 seconds
    const reAuthWindowMs = 60 * 1000;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastReAuthenticatedAt == null ||
        (now - _lastReAuthenticatedAt!) > reAuthWindowMs) {
      throw OrignaBaseAuthException(
        code: 'requires-recent-login',
        message: 'Please re-authenticate before deleting your account',
      );
    }

    await _ob.request(
      'POST',
      ApiEndpoints.authDeleteAccount,
      body: {'confirmation': 'DELETE_MY_ACCOUNT'},
    );
    await _ob.auth.signOut();
  }

  /// Ensures that a user profile document exists in the `users` collection.
  ///
  /// This is called during app initialization to recover from failed profile
  /// creation attempts during sign-up.
  @override
  Future<void> ensureUserDocumentExists() async {
    final accessToken = _ob.auth.accessToken;
    if (accessToken == null) return;

    try {
      final authState = await _ob.auth.refreshToken();
      if (!authState.isAuthenticated || authState.userId == null) return;

      await _createUserDocumentIfNeeded(
        userId: authState.userId!,
        email: authState.email,
        consentMethod: ConsentMethodValues.signupForm,
      );

      AppLogger.d('User document ensured for ${authState.email}', tag: 'auth');
    } catch (e) {
      AppLogger.d('Could not ensure user document: $e', tag: 'auth');
    }
  }

  /// Validates whether the current user session is still valid.
  ///
  /// Refreshes the token and checks for the existence of the user document.
  /// Automatically signs out the user if the session is stale or the account is disabled.
  @override
  Future<bool> validateCurrentUser() async {
    final accessToken = _ob.auth.accessToken;
    if (accessToken == null) return false;

    try {
      final authState = await _ob.auth.refreshToken();

      if (!authState.isAuthenticated || authState.userId == null) {
        AppLogger.d('User session invalid, signing out', tag: 'auth');
        await signOut();
        return false;
      }

      // Check if user profile exists
      final userDoc = await _ob
          .collection(Collections.users)
          .doc(authState.userId!)
          .get();
      if (userDoc == null) {
        AppLogger.d(
          'User profile not found, signing out stale session',
          tag: 'auth',
        );
        await signOut();
        return false;
      }

      return true;
    } on NetworkException catch (e) {
      // Network error — don't sign out, could be temporary
      AppLogger.d('Network error validating user: $e', tag: 'auth');
      return true;
    } on NotFoundException catch (e) {
      AppLogger.d('User not found, signing out: $e', tag: 'auth');
      await signOut();
      return false;
    } on AuthException catch (e) {
      AppLogger.d('Auth error validating user, signing out: $e', tag: 'auth');
      await signOut();
      return false;
    } on ForbiddenException catch (e) {
      AppLogger.d('User disabled/forbidden, signing out: $e', tag: 'auth');
      await signOut();
      return false;
    } catch (e) {
      // Unknown error — check if it looks like a transient network issue
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('timeout') ||
          msg.contains('socket') ||
          msg.contains('connection')) {
        AppLogger.d(
          'Transient error validating user (not signing out): $e',
          tag: 'auth',
        );
        return true;
      }
      // Non-transient unknown error — sign out to be safe
      AppLogger.w(
        'Unknown error validating user, signing out: $e',
        tag: 'auth',
      );
      await signOut();
      return false;
    }
  }

  /// Provides a stream of the user's profile model.
  ///
  /// Emits the current profile immediately and updates whenever the auth state changes.
  @override
  Stream<UserModel?> watchProfile(String userId) async* {
    // Emit immediately from the current auth state so the provider resolves
    // on page reload (localStorage restore does NOT fire authStateChanges).
    yield await _fetchProfileForAuthState(userId, _ob.auth.currentState);
    // Continue emitting on subsequent auth state changes (login/logout/refresh).
    await for (final authState in _ob.auth.authStateChanges) {
      yield await _fetchProfileForAuthState(userId, authState);
    }
  }

  /// Internal helper to fetch the profile document based on an [AuthState].
  Future<UserModel?> _fetchProfileForAuthState(
    String userId,
    AuthState authState,
  ) async {
    if (!authState.isAuthenticated || authState.userId != userId) {
      return null;
    }
    try {
      final response = await _ob.request(
        'POST',
        ApiEndpoints.usersProfileGet,
        body: {Fields.userId: userId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) return null;
      final profile = Map<String, dynamic>.from(data)..remove('success');
      if (profile.isEmpty) return null;
      profile.putIfAbsent(Fields.uid, () => userId);
      final address = profile[Fields.address];
      if (address is Map<String, dynamic>) {
        profile[Fields.address] = {...address, Fields.userId: userId};
      }
      return UserModel.fromMap(profile);
    } catch (e) {
      AppLogger.d('Error watching profile: $e', tag: 'auth');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the current user ID from the OrignaBase client.
  String? get _currentUserId {
    return _ob.auth.currentUserId;
  }

  /// Creates the user profile document in OrignaBase if it doesn't already exist.
  Future<void> _createUserDocumentIfNeeded({
    required String userId,
    String? email,
    String? name,
    required String consentMethod,
    bool? initialMarketingOptIn,
  }) async {
    try {
      // Check if doc already exists
      final existing = await _ob
          .collection(Collections.users)
          .doc(userId)
          .get();
      if (existing != null && existing.exists) return; // Profile already exists

      // Attempt to recover name from pending_profiles
      String? savedName = name;
      bool marketingOptIn = initialMarketingOptIn ?? false;

      try {
        final pendingDoc = await _ob
            .collection(Collections.pendingProfiles)
            .doc(userId)
            .get();
        if (pendingDoc != null && pendingDoc.exists) {
          final pendingData = pendingDoc.data;
          if (savedName == null || savedName.isEmpty) {
            savedName = pendingData[Fields.name] as String?;
          }
          if (initialMarketingOptIn == null) {
            marketingOptIn =
                pendingData[Fields.marketingOptIn] as bool? ?? false;
          }
          // Clean up pending profile
          await _ob
              .collection(Collections.pendingProfiles)
              .doc(userId)
              .delete();
        }
      } catch (e) {
        AppLogger.d('Could not check pending_profiles: $e', tag: 'auth');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await _ob.request(
        'POST',
        ApiEndpoints.usersCreateProfile,
        body: {
          Fields.userId: userId,
          Fields.email: email ?? '',
          Fields.name: savedName ?? 'User',
          Fields.roles: [UserRoleValues.buyer],
          Fields.preferredLanguage: _deviceLanguage(),
          Fields.marketingOptIn: marketingOptIn,
          Fields.consentMethod: consentMethod,
          Fields.consentTimestamp: now,
          Fields.termsAcceptedAt: now,
          Fields.termsVersion: PolicyVersionValues.defaultVersion,
          Fields.privacyAcceptedAt: now,
          Fields.privacyPolicyVersion: PolicyVersionValues.defaultVersion,
        },
      );
    } catch (e) {
      AppLogger.d('Error creating user document: $e', tag: 'auth');
      // Don't rethrow — profile creation failure shouldn't block auth
    }
  }

  /// Maps OrignaBase SDK exceptions to [OrignaBaseAuthException] with codes
  /// compatible with the existing error handling in login_viewmodel.dart.
  ///
  /// Uses typed SDK exceptions (NotFoundException, AuthException, etc.) instead
  /// of brittle string matching that breaks when Rust error messages change.
  Never _rethrowAsAuthException(Object e) {
    if (e is OrignaBaseAuthException) throw e;

    // Match on OrignaBase SDK typed exceptions first (statusCode-based)
    if (e is NotFoundException) {
      throw OrignaBaseAuthException(code: 'user-not-found', message: e.message);
    }
    if (e is AuthException) {
      // 401 — covers wrong password, invalid credentials, expired tokens
      final msg = e.message.toLowerCase();
      if (msg.contains('disabled') || msg.contains('suspended')) {
        throw OrignaBaseAuthException(
          code: 'user-disabled',
          message: e.message,
        );
      }
      throw OrignaBaseAuthException(code: 'wrong-password', message: e.message);
    }
    if (e is ValidationException) {
      // 422 — covers invalid email, weak password
      final msg = e.message.toLowerCase();
      if (msg.contains('email')) {
        throw OrignaBaseAuthException(
          code: 'invalid-email',
          message: e.message,
        );
      }
      if (msg.contains('password')) {
        throw OrignaBaseAuthException(
          code: 'weak-password',
          message: e.message,
        );
      }
      throw OrignaBaseAuthException(code: 'invalid-email', message: e.message);
    }
    if (e is ConflictException) {
      // 409 — duplicate email
      throw OrignaBaseAuthException(
        code: 'email-already-in-use',
        message: e.message,
      );
    }
    if (e is RateLimitException) {
      // 429
      throw OrignaBaseAuthException(
        code: 'too-many-requests',
        message: e.message,
      );
    }
    if (e is NetworkException) {
      throw OrignaBaseAuthException(
        code: 'network-request-failed',
        message: e.message,
      );
    }
    if (e is ForbiddenException) {
      throw OrignaBaseAuthException(code: 'user-disabled', message: e.message);
    }

    // Fallback for non-SDK exceptions (e.g. platform errors, cancellations)
    final errorStr = e.toString().toLowerCase();

    // Pattern matching for common error messages
    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      throw OrignaBaseAuthException(
        code: 'cancelled',
        message: 'Operation cancelled',
      );
    }
    if (errorStr.contains('already') || errorStr.contains('duplicate')) {
      throw OrignaBaseAuthException(
        code: 'email-already-in-use',
        message: e.toString(),
      );
    }
    if (errorStr.contains('network')) {
      throw OrignaBaseAuthException(
        code: 'network-request-failed',
        message: e.toString(),
      );
    }
    // Check for "weak" specifically before general "password" check
    if (errorStr.contains('weak')) {
      throw OrignaBaseAuthException(
        code: 'weak-password',
        message: e.toString(),
      );
    }
    // "wrong password" or just "password" in auth context = wrong-password
    if (errorStr.contains('wrong') ||
        (errorStr.contains('password') && !errorStr.contains('weak'))) {
      throw OrignaBaseAuthException(
        code: 'wrong-password',
        message: e.toString(),
      );
    }
    if (errorStr.contains('not found')) {
      throw OrignaBaseAuthException(
        code: 'user-not-found',
        message: e.toString(),
      );
    }
    if (errorStr.contains('disabled') ||
        (errorStr.contains('account') && errorStr.contains('suspended'))) {
      throw OrignaBaseAuthException(
        code: 'user-disabled',
        message: e.toString(),
      );
    }
    if (errorStr.contains('too many')) {
      throw OrignaBaseAuthException(
        code: 'too-many-requests',
        message: e.toString(),
      );
    }

    throw OrignaBaseAuthException(code: 'unknown', message: e.toString());
  }
}
