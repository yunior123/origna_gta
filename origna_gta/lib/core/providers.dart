import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// CORE PROVIDERS - Firebase instances
// ============================================================================

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================

/// Stream of auth state changes (null when logged out, User when logged in)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current user provider (synchronous access to current user)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// User ID provider (convenience for getting just the uid)
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});
