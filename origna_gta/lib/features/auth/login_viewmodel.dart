import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/env_config.dart';

import 'login_state.dart';

final loginViewModelProvider = StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref);
});

/// Maps Firebase Auth error codes to translation keys.
/// On web, [FirebaseAuthException.message] is often just "Error",
/// so we must rely on [FirebaseAuthException.code] instead.
String _friendlyAuthError(FirebaseAuthException e) {
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
      if (kDebugMode) {
        debugPrint('⚠️ Unhandled FirebaseAuthException code: ${e.code}, message: ${e.message}');
      }
      return 'auth.errors.authentication_failed'.tr();
  }
}

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginViewModel(this._ref) : super(LoginState());

  Future<void> handleAppleSignIn() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.signInWithApple();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!e.toString().contains('cancelled') && !e.toString().contains('user_cancelled')) {
        state = state.copyWith(errorMessage: 'auth.errors.apple_signin_failed'.tr());
      }
    }
  }

  Future<void> handleAuth({required String email, required String password, String? name, bool marketingOptIn = false}) async {
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
        final isVerified = await repository.isEmailVerified();
        if (!isVerified && !envConfig.isDev && !envConfig.isTest) {
          try {
            await repository.sendEmailVerification();
          } catch (_) {
            // Ignore send failures - user can resend later
          }
          await repository.signOut();
          state = state.copyWith(
            isLoading: false,
            errorMessage: null,
            successMessage: 'auth.errors.email_verification_required'.tr(namedArgs: {'email': email}),
          );
          return;
        }
      } else {
        await repository.registerWithEmail(email, password, name ?? 'User', marketingOptIn: marketingOptIn);

        // SECURITY FIX: Force logout and require email verification before login
        // BYPASS for integration tests/dev
        if (envConfig.isDev || envConfig.isTest) {
          state = state.copyWith(isLoading: false, isSuccess: true);
          return;
        }

        await repository.signOut();
        state = state.copyWith(
          isLoading: false,
          isLogin: true, // Redirect to Login mode
          acceptedTerms: false, // Reset

          successMessage: 'auth.errors.registration_success'.tr(namedArgs: {'email': email}),
          errorMessage: null,
        );
        // Do NOT set isSuccess=true, as that triggers navigation to home
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 FirebaseAuthException — code: ${e.code}, message: ${e.message}');
      }
      state = state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 Unexpected auth error: $e');
      }
      String errorMessage = 'auth.errors.generic_error';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('permission-denied') || errorStr.contains('permission_denied')) {
        errorMessage = state.isLogin ? 'auth.errors.profile_setup_failed' : 'auth.errors.account_creation_failed';
      } else if (errorStr.contains('network')) {
        errorMessage = 'auth.errors.network_error';
      } else if (errorStr.contains('email-already-in-use')) {
        errorMessage = 'auth.errors.email_already_in_use';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage.tr());
    }
  }

  Future<void> handleGoogleSignIn() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(authRepositoryProvider);

    try {
      await repository.signInWithGoogle();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendlyAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!e.toString().contains('popup-closed') && !e.toString().contains('cancelled')) {
        state = state.copyWith(errorMessage: 'auth.errors.google_signin_failed'.tr());
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
    state = state.copyWith(isLogin: !state.isLogin, acceptedTerms: false, marketingOptIn: false);
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

    if (trimmedEmail.length < 6) {
      return 'auth.validation.email_too_short';
    }

    if (trimmedEmail.length > 254) {
      return 'auth.validation.email_too_long';
    }

    if (!ValidationConstants.emailRegex.hasMatch(trimmedEmail)) {
      return 'auth.validation.email_invalid_validation';
    }

    return null; // Valid
  }

  /// Validate name format (must match Firestore rules)
  String? _validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'auth.validation.name_required_validation';
    }

    final trimmedName = name.trim();

    if (trimmedName.length < 2) {
      return 'auth.validation.name_too_short';
    }

    if (trimmedName.length > 60) {
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
    if (password.length < 8) {
      return 'auth.validation.password_min_8';
    }
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

    // Check against common passwords
    final commonPasswords = ['password', '12345678', 'qwerty123', 'abc123456', 'password1'];
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'auth.validation.password_common';
    }

    return null; // Valid
  }
}
