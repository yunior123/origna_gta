class LoginState {
  final bool isLoading;
  final bool isLogin;
  final bool obscurePassword;
  final bool acceptedTerms;
  final String? errorMessage;
  final bool isSuccess;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  LoginState({
    this.isLoading = false,
    this.isLogin = true,
    this.obscurePassword = true,
    this.acceptedTerms = false,
    this.errorMessage,
    this.isSuccess = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isLogin,
    bool? obscurePassword,
    bool? acceptedTerms,
    String? errorMessage,
    bool? isSuccess,
    int? failedAttempts,
    DateTime? lockoutUntil,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isLogin: isLogin ?? this.isLogin,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
    );
  }
}
