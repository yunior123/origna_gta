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

  OrignaBaseAuthException({required this.code, this.message, this.challengeToken});

  @override
  String toString() =>
      'OrignaBaseAuthException(code: $code, message: $message)';
}

/// OrignaBase implementation of [AuthRepository].
///
class OrignaBaseAuthRepository implements AuthRepository {
  final OrignaBase _ob;
  bool _googleSignInInitialized = false;

  OrignaBaseAuthRepository(this._ob);

  // ---------------------------------------------------------------------------
  // Auth methods
  // ---------------------------------------------------------------------------

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
          AppLogger.d('Verification email sent to $trimmedEmail during registration', tag: 'auth');
        } catch (e) {
          AppLogger.w('Failed to send verification email: $e', tag: 'auth');
        }
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

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
      final authState = await _ob.auth.signInWithEmail(trimmedEmail, password);

      if (authState.isAuthenticated && authState.userId != null) {
        await _createUserDocumentIfNeeded(
          userId: authState.userId!,
          email: trimmedEmail,
          consentMethod: ConsentMethodValues.signupForm,
        );
      }

      // Handle MFA challenge
      if (authState.mfaRequired && authState.challengeToken != null) {
        throw OrignaBaseAuthException(
          code: 'mfa-required',
          message: 'Multi-factor authentication required',
        );
      }
    } catch (e) {
      _rethrowAsAuthException(e);
    }
  }

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
            AppLogger.d('Failed to save Apple name to pending_profiles: $e', tag: 'auth');
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

  @override
  Future<void> signOut() async {
    try {
      await OrignaBaseNotificationService.instance.clearTokenFromOrignaBase();
    } catch (e) {
      AppLogger.d('Failed to clear notification token on sign out: $e', tag: 'auth');
    }

    _ob.auth.signOut();

    // Also sign out of Google if signed in
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}

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
    } catch (e) {
      AppLogger.d('Error checking email verification: $e', tag: 'auth');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

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

  @override
  Future<void> deleteAccount() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _ob.request(
      'POST',
      ApiEndpoints.authDeleteAccount,
      body: {'confirmation': 'DELETE_MY_ACCOUNT'},
    );
    _ob.auth.signOut();
  }

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

  @override
  Future<bool> validateCurrentUser() async {
    final accessToken = _ob.auth.accessToken;
    if (accessToken == null) return true; // No user, nothing to validate

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
        AppLogger.d('User profile not found, signing out stale session', tag: 'auth');
        await signOut();
        return false;
      }

      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not found') ||
          errorStr.contains('disabled') ||
          errorStr.contains('expired') ||
          errorStr.contains('unauthorized')) {
        AppLogger.d('User account no longer valid, signing out', tag: 'auth');
        await signOut();
        return false;
      }
      // Network error — don't sign out, could be temporary
      AppLogger.d('Error validating user: $e', tag: 'auth');
      return true;
    }
  }

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
        body: {'userId': userId},
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

  /// Current user ID from the last known auth state, or null.
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

  /// Maps OrignaBase errors to [OrignaBaseAuthException] with codes
  /// compatible with the existing error handling in login_viewmodel.dart.
  ///
  Never _rethrowAsAuthException(Object e) {
    if (e is OrignaBaseAuthException) throw e;

    final errorStr = e.toString().toLowerCase();

    if (errorStr.contains('not found') || errorStr.contains('not_found')) {
      throw OrignaBaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      );
    }
    if (errorStr.contains('wrong password') ||
        errorStr.contains('invalid_credentials')) {
      throw OrignaBaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password',
      );
    }
    if (errorStr.contains('invalid email') ||
        errorStr.contains('invalid_email')) {
      throw OrignaBaseAuthException(
        code: 'invalid-email',
        message: 'Invalid email',
      );
    }
    if (errorStr.contains('disabled') || errorStr.contains('suspended')) {
      throw OrignaBaseAuthException(
        code: 'user-disabled',
        message: 'Account disabled',
      );
    }
    if (errorStr.contains('too many') || errorStr.contains('rate_limit')) {
      throw OrignaBaseAuthException(
        code: 'too-many-requests',
        message: 'Too many requests',
      );
    }
    if (errorStr.contains('already') || errorStr.contains('duplicate')) {
      throw OrignaBaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use',
      );
    }
    if (errorStr.contains('weak password') ||
        errorStr.contains('weak_password')) {
      throw OrignaBaseAuthException(
        code: 'weak-password',
        message: 'Password too weak',
      );
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      throw OrignaBaseAuthException(
        code: 'network-request-failed',
        message: 'Network error',
      );
    }
    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      throw OrignaBaseAuthException(
        code: 'cancelled',
        message: 'Operation cancelled',
      );
    }

    throw OrignaBaseAuthException(code: 'unknown', message: e.toString());
  }
}
