import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// AUTH CONTROLLER PROVIDER
// ============================================================================

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

/// Controller for authentication operations
class AuthController {
  final Ref _ref;
  
  AuthController(this._ref);
  
  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document
    await _createUserDocumentIfNeeded(userCredential.user, name: name);
    
    return userCredential;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Create user document in Firestore if it doesn't exist
  Future<void> _createUserDocumentIfNeeded(User? user, {String? name}) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: name ?? user.displayName ?? 'User',
        roles: ['buyer'],
        createdAt: DateTime.now(),
      );
      await userDoc.set(newUser.toMap());
    }
  }

  /// Delete user account (GDPR compliance)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete the Firebase auth account
      await user.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}

// ============================================================================
// USER PROFILE PROVIDER
// ============================================================================

/// Stream of current user's profile data from Firestore
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(null);

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromMap({...doc.data()!, 'uid': doc.id});
      });
});
