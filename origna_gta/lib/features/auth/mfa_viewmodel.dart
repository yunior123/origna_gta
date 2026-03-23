import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';
import 'mfa_state.dart';

final mfaViewModelProvider =
    StateNotifierProvider.autoDispose<MfaViewModel, MfaState>(
  (ref) => MfaViewModel(ref),
);

class MfaViewModel extends StateNotifier<MfaState> {
  final Ref _ref;

  MfaViewModel(this._ref) : super(const MfaState());

  /// Reads mfaEnabled from the current user profile.
  void checkStatus() {
    final profile = _ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      state = state.copyWith(mfaEnabled: profile.mfaEnabled);
    }
  }

  /// Initiates MFA setup — fetches QR code and manual key from OrignaBase.
  Future<void> startSetup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ref.read(orignabaseProvider).auth.setupMfa();
      state = state.copyWith(
        isLoading: false,
        currentStep: 1,
        qrCodeBase64: result.qrCodeBase64,
        manualKey: result.manualKey,
        appleOtpauthUrl: result.appleOtpauthUrl,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to start MFA setup'),
      );
    }
  }

  /// Verifies the TOTP code and receives recovery codes on success.
  Future<void> verifySetup(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final codes =
          await _ref.read(orignabaseProvider).auth.verifyMfaSetup(code);
      state = state.copyWith(
        isLoading: false,
        currentStep: 3,
        recoveryCodes: codes,
        mfaEnabled: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to verify MFA code'),
      );
    }
  }

  /// Navigate to a specific setup step.
  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// User confirms they have saved recovery codes.
  void confirmSaved() {
    state = state.copyWith(codesSaved: true, currentStep: 4);
  }

  /// Verifies a TOTP code during MFA challenge (login flow).
  /// Returns `true` if authentication succeeded.
  Future<bool> verifyChallenge(String challengeToken, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ref
          .read(orignabaseProvider)
          .auth
          .verifyMfaChallenge(challengeToken, code);
      state = state.copyWith(isLoading: false);
      return result.isAuthenticated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'MFA verification failed'),
      );
      return false;
    }
  }

  /// Uses a recovery code during MFA challenge (login flow).
  /// Returns `true` if authentication succeeded.
  Future<bool> useRecoveryCode(String challengeToken, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ref
          .read(orignabaseProvider)
          .auth
          .useMfaRecoveryCode(challengeToken, code);
      state = state.copyWith(isLoading: false);
      return result.isAuthenticated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Recovery code verification failed'),
      );
      return false;
    }
  }

  /// Disables MFA after verifying the provided TOTP code.
  Future<void> disable(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _ref.read(orignabaseProvider).auth.disableMfa(code);
      state = state.copyWith(
        isLoading: false,
        mfaEnabled: false,
        currentStep: 0,
        qrCodeBase64: null,
        manualKey: null,
        appleOtpauthUrl: null,
        recoveryCodes: const [],
        codesSaved: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to disable MFA'),
      );
    }
  }
}
