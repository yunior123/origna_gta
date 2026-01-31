
class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final bool isDeleted;

  ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.isDeleted = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isDeleted,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
