import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

import 'login_state.dart';

final loginViewModelProvider = StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref);
});

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginViewModel(this._ref) : super(LoginState());

  Future<void> handleAuth({required String email, required String password, String? name}) async {
    if (state.isLoading) return;

    // SECURITY FIX M-3: Enforce strong password policy for registration
    if (!state.isLogin) {
      final passwordError = _validatePasswordStrength(password);
      if (passwordError != null) {
        state = state.copyWith(errorMessage: passwordError);
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(authRepositoryProvider);

    try {
      if (state.isLogin) {
        await repository.signInWithEmail(email, password);
      } else {
        await repository.registerWithEmail(email, password, name ?? 'User');
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message ?? 'Authentication failed');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An error occurred. Please try again.');
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
      state = state.copyWith(isLoading: false, errorMessage: e.message ?? 'Google sign-in failed');
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

  void toggleAuthMode() {
    state = state.copyWith(isLogin: !state.isLogin, acceptedTerms: false);
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
}
