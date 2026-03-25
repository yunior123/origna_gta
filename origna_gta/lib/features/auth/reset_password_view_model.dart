import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'reset_password_state.dart';

final resetPasswordViewModelProvider = StateNotifierProvider.autoDispose.family<ResetPasswordViewModel, ResetPasswordState, String>((ref, oobCode) {
  return ResetPasswordViewModel(ref, oobCode);
});

/// Manages the password reset flow: email validation, sending reset link, and code confirmation.
class ResetPasswordViewModel extends StateNotifier<ResetPasswordState> {
  final Ref _ref;
  final String _oobCode;

  ResetPasswordViewModel(this._ref, this._oobCode) : super(const ResetPasswordState()) {
    _verifyCode();
  }

  Future<void> _verifyCode() async {
    state = state.copyWith(isVerifying: false, errorMessage: null);
  }

  String _getLocalizedError(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'auth.reset_link_expired'.tr();
      case 'invalid-action-code':
        return 'auth.reset_link_invalid'.tr();
      case 'user-disabled':
        return 'auth.errors.user_disabled'.tr();
      case 'user-not-found':
        return 'auth.errors.user_not_found'.tr();
      case 'weak-password':
        return 'auth.validation.password_min_8'.tr();
      default:
        return 'auth.errors.generic_error'.tr();
    }
  }

  Future<void> resetPassword(String password, String confirmPassword) async {
    if (password.isEmpty || password.length < 8) {
      state = state.copyWith(errorMessage: 'auth.validation.password_min_8'.tr());
      return;
    }

    if (password != confirmPassword) {
      state = state.copyWith(errorMessage: 'auth.validation.passwords_mismatch'.tr());
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ref.read(authRepositoryProvider).confirmPasswordReset(
        _oobCode,
        password,
      );
      state = state.copyWith(
        isSuccess: true,
        isLoading: false,
      );
    } on OrignaBaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getLocalizedError(e.code),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'auth.errors.generic_error'.tr(),
      );
    }
  }
}
