import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/env_config.dart';

import 'login_state.dart';

/// Maps Firebase Auth error codes to user-friendly messages.
/// On web, [FirebaseAuthException.message] is often just "Error",
/// so we must rely on [FirebaseAuthException.code] instead.
String _friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'invalid-credential':
      return 'Invalid email or password. Please try again.';
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'too-many-requests':
      return 'Too many failed attempts. Please try again later.';
    case 'email-already-in-use':
      return 'This email is already registered. Try logging in.';
    case 'weak-password':
      return 'Password is too weak. Use at least 8 characters.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled.';
    case 'network-request-failed':
      return 'Network error. Please check your connection.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with this email using a different sign-in method.';
    default:
      if (kDebugMode) {
        debugPrint('⚠️ Unhandled FirebaseAuthException code: ${e.code}, message: ${e.message}');
      }
      return 'Authentication failed. Please try again.';
  }
}

final loginViewModelProvider = StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref);
});

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginViewModel(this._ref) : super(LoginState());

  Future<void> handleAuth({required String email, required String password, String? name}) async {
    if (state.isLoading) return;

    final now = DateTime.now();
    final lockoutUntil = state.lockoutUntil;
    if (lockoutUntil != null && now.isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(now).inMinutes + 1;
      state = state.copyWith(errorMessage: 'Too many attempts. Try again in ${remaining}m.');
      return;
    }

    // Validate email for both login and registration
    final emailError = _validateEmail(email);
    if (emailError != null) {
      state = state.copyWith(errorMessage: emailError);
      return;
    }

    // SECURITY FIX M-3: Enforce strong password policy for registration
    if (!state.isLogin) {
      final passwordError = _validatePasswordStrength(password);
      if (passwordError != null) {
        state = state.copyWith(errorMessage: passwordError);
        return;
      }
      
      // Validate name
      final nameError = _validateName(name);
      if (nameError != null) {
        state = state.copyWith(errorMessage: nameError);
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
            successMessage: 'Please verify your email first. A verification link has been sent to $email.',
          );
          return;
        }
      } else {
        await repository.registerWithEmail(email, password, name ?? 'User');
        
        // SECURITY FIX: Force logout and require email verification before login
        // BYPASS for integration tests/dev
        if (envConfig.isDev || envConfig.isTest) {
          state = state.copyWith(isLoading: false, isSuccess: true, failedAttempts: 0, lockoutUntil: null);
          return;
        }

        await repository.signOut();
        state = state.copyWith(
          isLoading: false,
          isLogin: true, // Redirect to Login mode
          acceptedTerms: false, // Reset
          //TODO traslate
          successMessage: 'Registration successful! Verification email sent to $email.',
          errorMessage: null,
        );
        // Do NOT set isSuccess=true, as that triggers navigation to home
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true, failedAttempts: 0, lockoutUntil: null);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 FirebaseAuthException — code: ${e.code}, message: ${e.message}');
      }
      final attempts = state.failedAttempts + 1;
      DateTime? newLockout;
      if (attempts >= 5) {
        final backoffMinutes = attempts >= 8 ? 15 : 5;
        newLockout = DateTime.now().add(Duration(minutes: backoffMinutes));
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e),
        failedAttempts: attempts,
        lockoutUntil: newLockout,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 Unexpected auth error: $e');
      }
      String errorMessage = 'An error occurred. Please try again.';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('permission-denied') || errorStr.contains('permission_denied')) {
        errorMessage = state.isLogin
            ? 'Sign-in succeeded but profile setup failed. Please try again.'
            : 'Account creation failed. Please check your name format (2-60 characters, letters, spaces, hyphens, apostrophes, periods).';
      } else if (errorStr.contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (errorStr.contains('email-already-in-use')) {
        errorMessage = 'This email is already registered. Try logging in.';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
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
        state = state.copyWith(errorMessage: 'Google sign-in failed. Please try again.');
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

  /// Validate password strength (SECURITY FIX M-3)
  String? _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character (!@#\$%^&*...)';
    }

    // Check against common passwords
    final commonPasswords = ['password', '12345678', 'qwerty123', 'abc123456', 'password1'];
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'Password is too common. Choose a stronger password';
    }

    return null; // Valid
  }

  /// Validate email format
  String? _validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmedEmail = email.trim().toLowerCase();
    
    if (trimmedEmail.length < 6) {
      return 'Email is too short';
    }
    
    if (trimmedEmail.length > 254) {
      return 'Email is too long';
    }
    
    // Standard email regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }
    
    return null; // Valid
  }

  /// Validate name format (must match Firestore rules)
  String? _validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }
    
    final trimmedName = name.trim();
    
    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (trimmedName.length > 60) {
      return 'Name must be less than 60 characters';
    }
    
    // Allow letters, spaces, hyphens, apostrophes, periods (O'Brien, Jr., María-José)
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ][a-zA-ZÀ-ÿ' .\-]*[a-zA-ZÀ-ÿ.]?$");
    if (!nameRegex.hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
    }
    
    return null; // Valid
  }
}
