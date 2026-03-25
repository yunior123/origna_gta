import 'package:origna_gta/utils/utils.dart';

/// Contract for all authentication operations.
///
/// Implementations: [OrignaBaseAuthRepository] (production).
///
/// Handles registration, sign-in (email, Google, Apple), email verification,
/// password reset, account deletion, and user profile watching.
///
/// All methods throw [OrignaBaseAuthException] on failure with error codes
/// compatible with the existing error handling in login_viewmodel.dart.
abstract class AuthRepository {
  /// Completes a password reset using the one-time [code] from the reset email.
  Future<void> confirmPasswordReset(String code, String newPassword);

  /// Permanently deletes the current user's account and signs out.
  ///
  /// Requires recent re-authentication (within 60 seconds).
  /// Throws `requires-recent-login` if re-auth is stale.
  Future<void> deleteAccount();

  /// Creates the user profile document in OrignaBase if it doesn't exist.
  ///
  /// Called after OAuth sign-in to ensure the user has a profile record
  /// with default roles, consent fields, and preferred language.
  Future<void> ensureUserDocumentExists();

  /// Checks whether the current user's email is verified.
  ///
  /// Fast path: trusts the JWT claim if already verified.
  /// Slow path: refreshes the token once to pick up recent verification changes.
  Future<bool> isEmailVerified();

  /// Registers a new user with email/password and creates their profile document.
  ///
  /// Sends a verification email on success. [marketingOptIn] records CASL consent.
  Future<void> registerWithEmail(
    String email,
    String password,
    String name, {
    bool marketingOptIn = false,
  });

  /// Sends (or re-sends) an email verification link to the current user.
  Future<void> sendEmailVerification();

  /// Sends a password reset email. Swallows user-not-found errors to prevent
  /// email enumeration (anti-phishing).
  Future<void> sendPasswordResetEmail(String email);

  /// Initiates Apple Sign-In via the native Sign In with Apple SDK.
  ///
  /// Apple provides the user's name only on the first sign-in; the name is
  /// persisted to `pending_profiles` for later profile creation.
  Future<void> signInWithApple();

  /// Signs in with email and password. Retries up to 3 times on network errors
  /// (never on 429 rate limits). Throws `mfa-required` if MFA is enabled.
  Future<void> signInWithEmail(String email, String password);

  /// Initiates Google Sign-In. On web, redirects to OrignaBase OAuth flow.
  /// On mobile, uses the native Google Sign-In SDK.
  Future<void> signInWithGoogle();

  /// Signs out of OrignaBase, Google, and clears notification tokens.
  Future<void> signOut();

  /// Validates that the current user still exists in auth storage.
  ///
  /// Returns true if valid. Returns false and signs out if the user was
  /// deleted, disabled, or the session expired. Does NOT sign out on
  /// transient network errors (could be temporary).
  Future<bool> validateCurrentUser();

  /// Reactive stream of the current user's profile document.
  ///
  /// Emits immediately from the current auth state, then on each
  /// subsequent auth state change. Returns null when signed out.
  Stream<UserModel?> watchProfile(String userId);
}
