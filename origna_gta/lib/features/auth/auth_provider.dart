import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// USER PROFILE PROVIDER
// ============================================================================

/// Reactive stream of the current user's profile document.
///
/// Returns `null` when no user is signed in. Watches [userIdProvider] so the
/// stream automatically switches on login/logout. Auto-disposed when no
/// widgets are watching — re-fetched on next access.
///
/// See also:
/// - [userIdProvider] for the raw user ID
/// - [AuthRepository.watchProfile] for the underlying stream
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
///
/// Returns `false` while the profile is still loading (avoids flash of terms gate).
///
/// ## Gate Logic
/// - `null` termsVersion → user registered before versioning was introduced;
///   do NOT re-prompt (they already accepted original terms at sign-up via CASL checkboxes).
/// - termsVersion present but differs from [PolicyVersionValues.defaultVersion] → must re-accept.
///
/// This implements CASL + PIPEDA + Quebec Law 25 compliance requirements.
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

/// Thin wrapper around [AuthRepository] that screens can use without
/// importing the repository directly.
///
/// Enforces MVVM: screens call [AuthActions] methods, never repositories.
/// All methods delegate 1:1 to [AuthRepository].
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
