import 'package:flutter/foundation.dart';
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
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/services/orignabase_conf_service.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

class AppAuthProviderInfo {
  final String providerId;

  const AppAuthProviderInfo(this.providerId);
}

class PublicAuthProviderAvailability {
  final bool enabled;
  final bool clientIdConfigured;
  final bool clientSecretConfigured;

  const PublicAuthProviderAvailability({
    required this.enabled,
    required this.clientIdConfigured,
    required this.clientSecretConfigured,
  });

  factory PublicAuthProviderAvailability.fromJson(Map<String, dynamic>? json) {
    return PublicAuthProviderAvailability(
      enabled: json?['enabled'] == true,
      clientIdConfigured: json?['client_id_configured'] == true,
      clientSecretConfigured: json?['client_secret_configured'] == true,
    );
  }
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
      emailVerified: state.emailVerified,
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
  final initialState = ob.auth.currentState;
  if (initialState.isAuthenticated && initialState.userId != null) {
    // Use emailVerified directly from the JWT claim (already present in AuthState).
    // Calling isEmailVerified() here would invoke refreshToken() on every auth event
    // for unverified users, causing an infinite loop: stream event → refreshToken →
    // new stream event → refreshToken → ...
    yield AppAuthUser.fromAuthState(initialState);
  } else {
    yield null;
  }

  await for (final state in ob.auth.authStateChanges) {
    if (!state.isAuthenticated || state.userId == null) {
      yield null;
      continue;
    }

    // Use emailVerified directly from the JWT claim embedded in AuthState.
    // The EmailVerificationRequiredScreen._checkVerification() explicitly calls
    // isEmailVerified() (which calls refreshToken()) when the user taps
    // "I've Verified My Email", triggering a fresh authStateChanges event with
    // the updated claim — no polling needed here.
    yield AppAuthUser.fromAuthState(state);
  }
});

final googleAuthAvailabilityProvider =
    FutureProvider<PublicAuthProviderAvailability>((ref) async {
      if (!kIsWeb) {
        return const PublicAuthProviderAvailability(
          enabled: true,
          clientIdConfigured: true,
          clientSecretConfigured: true,
        );
      }

      final ob = ref.watch(orignabaseProvider);
      try {
        final response = await ob.request('GET', '/auth/providers');
        final google = response['google'];
        return PublicAuthProviderAvailability.fromJson(
          google is Map<String, dynamic>
              ? google
              : google is Map
              ? google.map((key, value) => MapEntry(key.toString(), value))
              : null,
        );
      } catch (_) {
        final clientId = (await OrignaBaseConfigService().getString(
          RemoteConfigKeys.googleWebClientId,
        )).trim();
        return PublicAuthProviderAvailability(
          enabled: clientId.isNotEmpty,
          clientIdConfigured: clientId.isNotEmpty,
          clientSecretConfigured: false,
        );
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


// === Widget Previews ===
