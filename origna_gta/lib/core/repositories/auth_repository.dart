import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

abstract class AuthRepository {
  Future<void> deleteAccount();
  Future<UserCredential> registerWithEmail(String email, String password, String name);
  Future<void> sendPasswordResetEmail(String email);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> watchProfile(String userId);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAuthRepository(this._auth, this._firestore, this._functions);

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Call the collective delete function which handles Firestore, Auth, and Stripe
    await _functions.httpsCallable('delete_account').call({'confirmation': 'DELETE_MY_ACCOUNT'});
  }

  @override
  Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _createUserDocumentIfNeeded(userCredential.user, name: name);
    return userCredential;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    final UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      userCredential = await _auth.signInWithProvider(googleProvider);
    }

    await _createUserDocumentIfNeeded(userCredential.user);
    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Stream<UserModel?> watchProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap({...doc.data()!, 'uid': doc.id});
    });
  }

  Future<void> _createUserDocumentIfNeeded(User? user, {String? name}) async {
    if (user == null) return;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': name ?? user.displayName ?? 'User',
        'roles': [UserRoles.buyer],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = docSnapshot.data();
      final roles = List<String>.from(data?['roles'] ?? const []);
      if (!roles.contains(UserRoles.buyer)) {
        await userDoc.update({
          'roles': FieldValue.arrayUnion([UserRoles.buyer]),
        });
      }
    }
  }
}
