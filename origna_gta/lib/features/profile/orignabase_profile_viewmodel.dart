import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show ApiEndpoints, Fields;
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';

import 'profile_state.dart';

/// Riverpod provider for [OrignaBaseProfileViewModel].
///
/// Auto-disposed when the profile screen is popped.
final profileViewModelProvider =
    StateNotifierProvider.autoDispose<OrignaBaseProfileViewModel, ProfileState>(
      (ref) {
        return OrignaBaseProfileViewModel(ref);
      },
    );

/// Manages profile-level actions: sign-out, language preference, data export, and account deletion.
///
/// ## Key Decisions
/// - Account deletion requires typing "DELETE" as confirmation — case-insensitive check
///   on the client, server expects a `'DELETE_MY_ACCOUNT'` string in the body.
/// - Data export is fire-and-forget from the client's perspective — the server emails
///   the export asynchronously.
/// - Language update persists to OrignaBase and sets [ProfileState.successMessage] on success.
///
/// See also:
/// - [ProfileState] for the state shape
class OrignaBaseProfileViewModel extends StateNotifier<ProfileState> {
  final Ref _ref;

  OrignaBaseProfileViewModel(this._ref) : super(const ProfileState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  /// Signs the current user out via [AuthActionsProvider].
  ///
  /// No state mutation — navigation is handled by the auth state listener.
  Future<void> signOut() async {
    await _ref.read(authActionsProvider).signOut();
  }

  /// Updates the user's preferred language and persists it to OrignaBase.
  ///
  /// Parameters:
  /// - [langCode]: ISO 639-1 language code (e.g., `'en'`, `'fr'`).
  ///
  /// No-ops silently when no user is logged in ([obUserIdProvider] returns null).
  /// Sets [ProfileState.successMessage] on completion.
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
        successMessage: 'profile.language_updated'.tr(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to update language'),
      );
    }
  }

  /// Requests a full data export from the server (GDPR compliance).
  ///
  /// The server processes the export asynchronously and emails a download link.
  /// Sets [ProfileState.successMessage] on accepted request.
  ///
  /// Gotchas:
  /// - Requires an authenticated user — sets error message if [obUserIdProvider] is null.
  Future<void> exportData() async {
    final userId = _ref.read(obUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(errorMessage: 'Authentication required');
      return;
    }
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await _ob.request('POST', ApiEndpoints.adminExportData, body: {});
      state = state.copyWith(
        isLoading: false,
        successMessage: 'profile.export_started'.tr(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to export data'),
      );
    }
  }

  /// Permanently deletes the user's account after server-side confirmation.
  ///
  /// Parameters:
  /// - [confirmation]: must be `'DELETE'` (case-insensitive) to proceed.
  ///
  /// On success, signs the user out and sets [ProfileState.isDeleted] = true.
  /// The server expects a `'DELETE_MY_ACCOUNT'` string in the request body.
  ///
  /// Gotchas:
  /// - This is irreversible — the server performs hard deletion, not soft-delete.
  Future<void> deleteAccount(String confirmation) async {
    if (confirmation.toUpperCase() != 'DELETE') {
      state = state.copyWith(errorMessage: 'Please type DELETE to confirm');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = _ref.read(obUserIdProvider);
      if (userId == null || userId.isEmpty) {
        throw StateError('Authentication required');
      }
      await _ob.request(
        'POST',
        ApiEndpoints.authDeleteAccount,
        body: {Fields.userId: userId, 'confirmation': 'DELETE_MY_ACCOUNT'},
      );
      await _ref.read(authActionsProvider).signOut();
      state = state.copyWith(isLoading: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to delete account'),
      );
    }
  }
}
