// coverage:ignore-file
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

import 'profile_state.dart';

final obProfileViewModelProvider =
    StateNotifierProvider.autoDispose<OrignaBaseProfileViewModel, ProfileState>(
        (ref) {
  return OrignaBaseProfileViewModel(ref);
});

/// OrignaBase profile viewmodel.
class OrignaBaseProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;

  OrignaBaseProfileViewModel(this._ref) : super(ProfileState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  Future<void> signOut() async {
    _ob.auth.signOut();
  }

  Future<void> updateLanguage(String langCode) async {
    final userId = _ref.read(obUserIdProvider);
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ref
          .read(userRepositoryProvider)
          .updatePreferredLanguage(userId, langCode);
      state = state.copyWith(
          isLoading: false,
          successMessage: 'profile.language_updated'.tr());
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage:
              AppError.getMessage(e, 'Failed to update language'));
    }
  }

  Future<void> exportData() async {
    final userId = _ref.read(obUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(errorMessage: 'Authentication required');
      return;
    }
    state = state.copyWith(
        isLoading: true, errorMessage: null, successMessage: null);
    try {
      await _ob.request('POST', '/api/admin/export-data', body: {'userId': userId});
      state = state.copyWith(
          isLoading: false,
          successMessage: 'profile.export_started'.tr());
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage:
              AppError.getMessage(e, 'Failed to export data'));
    }
  }

  Future<void> deleteAccount(String confirmation) async {
    if (confirmation.toUpperCase() != 'DELETE') {
      state =
          state.copyWith(errorMessage: 'Please type DELETE to confirm');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = _ref.read(obUserIdProvider);
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required');
      }
      await _ob.request('POST', '/api/auth/delete-account', body: {
        'userId': userId,
        'confirmation': 'DELETE_MY_ACCOUNT',
      });
      _ob.auth.signOut();
      state = state.copyWith(isLoading: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage:
              AppError.getMessage(e, 'Failed to delete account'));
    }
  }
}
