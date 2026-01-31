// seller_registration_state.dart
class SellerRegistrationState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SellerRegistrationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SellerRegistrationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SellerRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable to allow clearing errors
      successMessage: successMessage, // Nullable to allow clearing success messages
    );
  }
}