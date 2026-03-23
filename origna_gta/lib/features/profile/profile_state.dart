import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    String? errorMessage,
    String? successMessage,
    @Default(false) bool isDeleted,
  }) = _ProfileState;
}
