import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isLoading,
    @Default(true) bool isLogin,
    @Default(true) bool obscurePassword,
    @Default(false) bool acceptedTerms,
    @Default(false)
    bool marketingOptIn, // CASL/Loi 25: separate marketing consent
    String? errorMessage,
    String? successMessage,
    @Default(false) bool isSuccess,
    @Default(false) bool mfaRequired,
    String? challengeToken,
  }) = _LoginState;
}
