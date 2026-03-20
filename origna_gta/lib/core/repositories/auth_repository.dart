import 'package:origna_gta/utils/utils.dart';

abstract class AuthRepository {
  Future<void> confirmPasswordReset(String code, String newPassword);
  Future<void> deleteAccount();
  Future<void> ensureUserDocumentExists(); // ✅ New method to create database document for verified users
  Future<bool> isEmailVerified();
  Future<void> registerWithEmail(String email, String password, String name, {bool marketingOptIn = false});
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signInWithApple();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();

  /// Validates that the current user still exists in auth storage
  /// Returns true if valid, false if user was deleted (and signs out)
  Future<bool> validateCurrentUser();

  Stream<UserModel?> watchProfile(String userId);
}
