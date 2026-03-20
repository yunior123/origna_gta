import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// USER PROFILE PROVIDER
// ============================================================================

/// Stream of current user's profile data from repository
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(null);

  final repository = ref.watch(authRepositoryProvider);
  return repository.watchProfile(userId);
});

// ============================================================================
// TERMS VERSION GATE
// ============================================================================

/// True when the signed-in user has not accepted the current required Terms version.
/// Returns false while the profile is still loading (avoid flash of gate).
/// Gate logic:
///  - null termsVersion → user registered before versioning; do NOT re-prompt for v1.0
///    (they already accepted the original terms at sign-up via CASL checkboxes)
///  - termsVersion present but differs from current → must re-accept
final needsTermsUpdateProvider = Provider.autoDispose<bool>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.whenOrNull(
        data: (profile) {
          if (profile == null) return false;
          final userVersion = profile.termsVersion;
          // Null means pre-versioning sign-up — do not force re-accept of v1.0.
          // Only re-prompt when version is present but outdated.
          if (userVersion == null) return false;
          return userVersion != PolicyVersionValues.defaultVersion;
        },
      ) ??
      false;
});

// ============================================================================
// AUTH ACTIONS — wraps repository calls so screens never read repositories directly
// ============================================================================

class AuthActions {
  final AuthRepository _repo;
  const AuthActions(this._repo);

  Future<void> signOut() => _repo.signOut();
  Future<bool> isEmailVerified() => _repo.isEmailVerified();
  Future<void> ensureUserDocumentExists() => _repo.ensureUserDocumentExists();
  Future<void> sendEmailVerification() => _repo.sendEmailVerification();
}

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(authRepositoryProvider));
});
