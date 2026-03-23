import 'package:freezed_annotation/freezed_annotation.dart';

part 'mfa_state.freezed.dart';

@freezed
abstract class MfaState with _$MfaState {
  const factory MfaState({
    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(0)
    int currentStep, // 0=idle, 1=scan QR, 2=verify code, 3=backup codes, 4=done
    String? qrCodeBase64,
    String? manualKey,
    String? appleOtpauthUrl,
    @Default([]) List<String> recoveryCodes,
    @Default(false) bool mfaEnabled,
    @Default(false) bool codesSaved, // user confirmed they saved recovery codes
  }) = _MfaState;
}
