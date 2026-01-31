import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';

// ============================================================================
// CORE PROVIDERS - Firebase instances
// ============================================================================

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  final functions = FirebaseFunctions.instance;
  if (kDebugMode) {
    functions.useFunctionsEmulator('127.0.0.1', 8081);
  }
  return functions;
});

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirebaseProductRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository(ref.watch(firestoreProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return FirebaseCartRepository(ref.watch(firestoreProvider));
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return GeoapifyLocationRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirebaseOrderRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(firebaseAuthProvider).authStateChanges());
final currentUserProvider = Provider<User?>((ref) => ref.watch(authStateProvider).valueOrNull);
final userIdProvider = Provider<String?>((ref) => ref.watch(currentUserProvider)?.uid);
