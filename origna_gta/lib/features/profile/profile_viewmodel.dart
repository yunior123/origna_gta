import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';
import 'profile_state.dart';

final profileViewModelProvider = StateNotifierProvider.autoDispose<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel(ref);
});

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileViewModel(this._ref) : super(ProfileState());

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
  }

  Future<void> deleteAccount(String confirmation) async {
    if (confirmation.toUpperCase() != 'DELETE') {
      state = state.copyWith(errorMessage: 'Please type DELETE to confirm');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ref.read(authRepositoryProvider).deleteAccount();
      state = state.copyWith(isLoading: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to delete account'));
    }
  }
}
