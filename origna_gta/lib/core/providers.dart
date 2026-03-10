import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_location_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:orignabase/orignabase.dart';

class AppAuthProviderInfo {
  final String providerId;

  const AppAuthProviderInfo(this.providerId);
}

class AppAuthUser {
  final String uid;
  final String? email;
  final bool emailVerified;
  final List<AppAuthProviderInfo> providerData;

  const AppAuthUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.providerData = const [],
  });

  factory AppAuthUser.fromAuthState(AuthState state) {
    return AppAuthUser(
      uid: state.userId ?? '',
      email: state.email,
    );
  }

  AppAuthUser copyWith({
    String? uid,
    String? email,
    bool? emailVerified,
    List<AppAuthProviderInfo>? providerData,
  }) {
    return AppAuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      providerData: providerData ?? this.providerData,
    );
  }
}

// ============================================================================
// REPOSITORY PROVIDERS — OrignaBase implementations
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return OrignaBaseAuthRepository(ref.watch(orignabaseProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return OrignaBaseCartRepository(ref.watch(orignabaseProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrignaBaseOrderRepository(ref.watch(orignabaseProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return OrignaBaseProductRepository(ref.watch(orignabaseProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return OrignaBaseUserRepository(ref.watch(orignabaseProvider));
});

// ============================================================================
// AUTH STATE PROVIDER — app-owned auth user backed by OrignaBase.
// ============================================================================

final authStateProvider = StreamProvider<AppAuthUser?>((ref) async* {
  final ob = ref.watch(orignabaseProvider);
  await for (final state in ob.auth.authStateChanges) {
    if (!state.isAuthenticated || state.userId == null) {
      yield null;
      continue;
    }

    var user = AppAuthUser.fromAuthState(state);
    try {
      final verified = await ref.read(authRepositoryProvider).isEmailVerified();
      user = user.copyWith(emailVerified: verified);
    } catch (_) {}
    yield user;
  }
});

final currentUserProvider = Provider<AppAuthUser?>(
  (ref) => ref.watch(authStateProvider).valueOrNull,
);

final userIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.uid,
);

// ============================================================================
// CORE PROVIDERS
// ============================================================================

final envConfigProvider = Provider<EnvConfig>((ref) => EnvConfig());

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return OrignaBaseLocationRepository(ref.watch(orignabaseProvider));
});

final userAddressesProvider = StreamProvider.autoDispose<List<Address>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(userRepositoryProvider).watchAddresses(userId);
});
