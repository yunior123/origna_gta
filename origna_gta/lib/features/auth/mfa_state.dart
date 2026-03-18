// coverage:ignore-file
const _omit = Object();

/// State for MFA setup and management flow.
class MfaState {
  final bool isLoading;
  final String? errorMessage;
  final int currentStep; // 0=idle, 1=scan QR, 2=verify code, 3=backup codes, 4=done
  final String? qrCodeBase64;
  final String? manualKey;
  final String? appleOtpauthUrl;
  final List<String> recoveryCodes;
  final bool mfaEnabled;
  final bool codesSaved; // user confirmed they saved recovery codes

  MfaState({
    this.isLoading = false,
    this.errorMessage,
    this.currentStep = 0,
    this.qrCodeBase64,
    this.manualKey,
    this.appleOtpauthUrl,
    this.recoveryCodes = const [],
    this.mfaEnabled = false,
    this.codesSaved = false,
  });

  MfaState copyWith({
    bool? isLoading,
    Object? errorMessage = _omit,
    int? currentStep,
    Object? qrCodeBase64 = _omit,
    Object? manualKey = _omit,
    Object? appleOtpauthUrl = _omit,
    List<String>? recoveryCodes,
    bool? mfaEnabled,
    bool? codesSaved,
  }) {
    return MfaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _omit) ? this.errorMessage : errorMessage as String?,
      currentStep: currentStep ?? this.currentStep,
      qrCodeBase64: identical(qrCodeBase64, _omit) ? this.qrCodeBase64 : qrCodeBase64 as String?,
      manualKey: identical(manualKey, _omit) ? this.manualKey : manualKey as String?,
      appleOtpauthUrl: identical(appleOtpauthUrl, _omit) ? this.appleOtpauthUrl : appleOtpauthUrl as String?,
      recoveryCodes: recoveryCodes ?? this.recoveryCodes,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      codesSaved: codesSaved ?? this.codesSaved,
    );
  }
}
