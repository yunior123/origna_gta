import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/services/analytics_service.dart'
    show analyticsServiceProvider;

import 'login_state.dart';

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
      return LoginViewModel(ref);
    });

/// Maps OrignaBase auth exception codes to user-friendly translated error messages.
///
/// Handles all known error codes from the OrignaBase auth API. Unknown codes
/// fall back to a generic authentication failure message and are logged for
/// future handling.
String _friendlyAuthError(OrignaBaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'auth.errors.user_not_found'.tr();
    case 'wrong-password':
      return 'auth.errors.wrong_password'.tr();
    case 'invalid-credential':
      return 'auth.errors.invalid_credential'.tr();
    case 'invalid-email':
      return 'auth.errors.invalid_email'.tr();
    case 'user-disabled':
      return 'auth.errors.user_disabled'.tr();
    case 'too-many-requests':
      return 'auth.errors.too_many_requests'.tr();
    case 'email-already-in-use':
      return 'auth.errors.email_already_in_use'.tr();
    case 'weak-password':
      return 'auth.errors.weak_password'.tr();
    case 'operation-not-allowed':
      return 'auth.errors.operation_not_allowed'.tr();
    case 'network-request-failed':
      return 'auth.errors.network_error'.tr();
    case 'account-exists-with-different-credential':
      return 'auth.errors.account_exists_different_credential'.tr();
    default:
      AppLogger.d(
        '⚠️ Unhandled auth exception code: ${e.code}, message: ${e.message}',
        tag: 'auth',
      );
      return 'auth.errors.authentication_failed'.tr();
  }
}

/// Manages the login/registration screen: form validation, auth provider selection,
/// MFA flow, and error handling.
///
/// ## Supported Auth Methods
/// - Email/password (login + registration)
/// - Apple Sign-In
/// - Google Sign-In
///
/// ## Key Decisions
/// - Password strength validation mirrors backend policy (min 8 chars, uppercase,
///   lowercase, digit, special char, not in common password list).
/// - MFA handled inline: when OrignaBase returns `mfa-required`, state transitions
///   to MFA verification mode with [challengeToken].
/// - Email verification is NOT enforced at sign-in — it's a checkout gate instead.
///   This avoids blocking returning users who haven't verified yet.
/// - Analytics logging is fire-and-forget (`unawaited`) — never blocks auth flow.
/// - Auth mode toggle (login ↔ register) resets all form state.
///
/// See also:
/// - [LoginState] for the state shape
/// - [AuthRepository] for persistence layer
/// - [ValidationConstants] for input validation rules
class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginViewModel(this._ref) : super(const LoginState());

  /// Handles Apple Sign-In flow.
  ///
  /// Guards against double-tap via [state.isLoading]. Silently ignores
  /// user cancellation (no error message shown). Logs analytics on success.
  Future<void> handleAppleSignIn() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
      isSuccess: false,
      mfaRequired: false,
      challengeToken: null,
    );
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.signInWithApple();
      unawaited(_ref.read(analyticsServiceProvider).logLogin(method: 'apple'));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on OrignaBaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!e.toString().contains('cancelled') &&
          !e.toString().contains('user_cancelled')) {
        state = state.copyWith(
          errorMessage: 'auth.errors.apple_signin_failed'.tr(),
        );
      }
    }
  }

  /// Handles email/password authentication (login or registration based on [state.isLogin]).
  ///
  /// [email] — user's email address.
  /// [password] — user's password.
  /// [name] — required for registration, ignored for login.
  /// [marketingOptIn] — whether user consents to marketing emails (registration only).
  ///
  /// Registration enforces strong password policy ([_validatePasswordStrength]).
  /// Login does NOT enforce email verification — it's a checkout gate instead.
  ///
  /// On MFA-required: transitions state to MFA mode with [challengeToken].
  /// On success: sets [isSuccess] = true, clears MFA state.
  Future<void> handleAuth({
    required String email,
    required String password,
    String? name,
    bool marketingOptIn = false,
  }) async {
    if (state.isLoading) return;

    // Validate email for both login and registration
    final emailError = _validateEmail(email);
    if (emailError != null) {
      state = state.copyWith(errorMessage: emailError.tr());
      return;
    }

    // SECURITY FIX M-3: Enforce strong password policy for registration
    if (!state.isLogin) {
      final passwordError = _validatePasswordStrength(password);
      if (passwordError != null) {
        state = state.copyWith(errorMessage: passwordError.tr());
        return;
      }

      // Validate name
      final nameError = _validateName(name);
      if (nameError != null) {
        state = state.copyWith(errorMessage: nameError.tr());
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(authRepositoryProvider);

    try {
      if (state.isLogin) {
        await repository.signInWithEmail(email, password);
        // [F-82] Allow sign-in even if not verified, but show a warning or hint in UI if needed.
        // The business logic elsewhere (checkout) will block actions requiring verification.
        unawaited(
          _ref.read(analyticsServiceProvider).logLogin(method: 'email'),
        );
      } else {
        await repository.registerWithEmail(
          email,
          password,
          name ?? 'User',
          marketingOptIn: marketingOptIn,
        );
        unawaited(
          _ref.read(analyticsServiceProvider).logSignUp(method: 'email'),
        );

        // [F-80] Stay signed in after registration so profile is created immediately
        state = state.copyWith(
          isLoading: false,
          successMessage: 'auth.errors.registration_success'.tr(
            namedArgs: {'email': email},
          ),
          errorMessage: null,
          isSuccess: true,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        mfaRequired: false,
        challengeToken: null,
      );
    } on OrignaBaseAuthException catch (e) {
      AppLogger.d(
        '🔐 Auth exception — code: ${e.code}, message: ${e.message}',
        tag: 'auth',
      );
      if (e.code == 'mfa-required' && e.challengeToken != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          mfaRequired: true,
          challengeToken: e.challengeToken,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e),
        mfaRequired: false,
        challengeToken: null,
      );
    } catch (e) {
      AppLogger.d('🔐 Unexpected auth error: $e', tag: 'auth');
      String errorMessage = 'auth.errors.generic_error';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('permission-denied') ||
          errorStr.contains('permission_denied')) {
        errorMessage = state.isLogin
            ? 'auth.errors.profile_setup_failed'
            : 'auth.errors.account_creation_failed';
      } else if (errorStr.contains('network')) {
        errorMessage = 'auth.errors.network_error';
      } else if (errorStr.contains('email-already-in-use')) {
        errorMessage = 'auth.errors.email_already_in_use';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage.tr());
    }
  }

  /// Handles Google Sign-In flow.
  ///
  /// Guards against double-tap via [state.isLoading]. Silently ignores
  /// popup-closed/user cancellation. Logs analytics on success.
  Future<void> handleGoogleSignIn() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.signInWithGoogle();
      unawaited(_ref.read(analyticsServiceProvider).logLogin(method: 'google'));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on OrignaBaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!e.toString().contains('popup-closed') &&
          !e.toString().contains('cancelled')) {
        state = state.copyWith(
          errorMessage: 'auth.errors.google_signin_failed'.tr(),
        );
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  void setMarketingOptIn(bool value) {
    state = state.copyWith(marketingOptIn: value);
  }

  void toggleAuthMode() {
    state = state.copyWith(
      isLogin: !state.isLogin,
      acceptedTerms: false,
      marketingOptIn: false,
      mfaRequired: false,
      challengeToken: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Validate email format
  String? _validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'auth.validation.email_required_validation';
    }

    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.length < ValidationConstants.minEmailLength) {
      return 'auth.validation.email_too_short';
    }

    if (trimmedEmail.length > ValidationConstants.maxEmailLength) {
      return 'auth.validation.email_too_long';
    }

    if (!ValidationConstants.emailRegex.hasMatch(trimmedEmail)) {
      return 'auth.validation.email_invalid_validation';
    }

    return null; // Valid
  }

  /// Validate name format (must match server-side validation)
  String? _validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'auth.validation.name_required_validation';
    }

    final trimmedName = name.trim();

    if (trimmedName.length < ValidationConstants.minNameLength) {
      return 'auth.validation.name_too_short';
    }

    if (trimmedName.length > ValidationConstants.maxNameLength) {
      return 'auth.validation.name_too_long';
    }

    // Allow any Unicode letter + space/hyphen/apostrophe/period — mirrors backend
    final nameRegex = RegExp(r"^[\p{L} '\-\.·]+$", unicode: true);
    if (!nameRegex.hasMatch(trimmedName)) {
      return 'auth.validation.name_invalid_format';
    }

    return null; // Valid
  }

  /// Validate password strength (SECURITY FIX M-3)
  String? _validatePasswordStrength(String password) {
    // F-84: Enforce centralised password policy for registration
    if (password.length < ValidationConstants.minPasswordLength) {
      return 'auth.validation.password_min_8';
    }

    if (!ValidationConstants.passwordRegex.hasMatch(password)) {
      // Specific hints for better UX
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return 'auth.validation.password_uppercase';
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        return 'auth.validation.password_lowercase';
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        return 'auth.validation.password_number';
      }
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'auth.validation.password_special';
      }
      return 'auth.validation.password_weak';
    }

    // Check against common passwords
    if (ValidationConstants.commonPasswords.contains(password.toLowerCase())) {
      return 'auth.validation.password_common';
    }

    return null; // Valid
  }
}
