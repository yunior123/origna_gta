class LoginState {
  final bool isLoading;
  final bool isLogin;
  final bool obscurePassword;
  final bool acceptedTerms;
  final bool marketingOptIn; // CASL/Loi 25: separate marketing consent
  final String? errorMessage;
  final String? successMessage;
  final bool isSuccess;

  LoginState({
    this.isLoading = false,
    this.isLogin = true,
    this.obscurePassword = true,
    this.acceptedTerms = false,
    this.marketingOptIn = false,
    this.errorMessage,
    this.successMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isLogin,
    bool? obscurePassword,
    bool? acceptedTerms,
    bool? marketingOptIn,
    String? errorMessage,
    String? successMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isLogin: isLogin ?? this.isLogin,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
