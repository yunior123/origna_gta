import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AppAuthProviderInfo', () {
    test('stores providerId correctly', () {
      const info = AppAuthProviderInfo('google.com');
      expect(info.providerId, 'google.com');
    });
  });

  group('PublicAuthProviderAvailability', () {
    test('fromJson handles valid data', () {
      final json = {
        'enabled': true,
        'client_id_configured': true,
        'client_secret_configured': false,
      };
      final availability = PublicAuthProviderAvailability.fromJson(json);
      expect(availability.enabled, isTrue);
      expect(availability.clientIdConfigured, isTrue);
      expect(availability.clientSecretConfigured, isFalse);
    });

    test('fromJson handles null', () {
      final availability = PublicAuthProviderAvailability.fromJson(null);
      expect(availability.enabled, isFalse);
      expect(availability.clientIdConfigured, isFalse);
      expect(availability.clientSecretConfigured, isFalse);
    });

    test('fromJson handles empty map', () {
      final json = <String, dynamic>{};
      final availability = PublicAuthProviderAvailability.fromJson(json);
      expect(availability.enabled, isFalse);
      expect(availability.clientIdConfigured, isFalse);
      expect(availability.clientSecretConfigured, isFalse);
    });

    test('fromJson handles partial enabled only', () {
      final json = {'enabled': true};
      final availability = PublicAuthProviderAvailability.fromJson(json);
      expect(availability.enabled, isTrue);
      expect(availability.clientIdConfigured, isFalse);
      expect(availability.clientSecretConfigured, isFalse);
    });

    test('fromJson handles string values incorrectly typed', () {
      final json = {'enabled': 'true', 'client_id_configured': 'yes'};
      final availability = PublicAuthProviderAvailability.fromJson(json);
      expect(availability.enabled, isFalse);
      expect(availability.clientIdConfigured, isFalse);
    });
  });

  group('AppAuthUser', () {
    test('creates with required fields only', () {
      const user = AppAuthUser(uid: 'user123');
      expect(user.uid, 'user123');
      expect(user.email, isNull);
      expect(user.emailVerified, isFalse);
      expect(user.providerData, isEmpty);
    });

    test('creates with email', () {
      const user = AppAuthUser(uid: 'user123', email: 'test@example.com');
      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.emailVerified, isFalse);
    });

    test('creates with all fields', () {
      const user = AppAuthUser(
        uid: 'user123',
        email: 'test@example.com',
        emailVerified: true,
        providerData: [AppAuthProviderInfo('google.com')],
      );
      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.emailVerified, isTrue);
      expect(user.providerData.length, 1);
      expect(user.providerData.first.providerId, 'google.com');
    });

    test('copyWith preserves unchanged fields', () {
      const user = AppAuthUser(
        uid: 'user123',
        email: 'test@example.com',
        emailVerified: true,
      );
      final copied = user.copyWith(email: 'new@example.com');
      expect(copied.uid, 'user123');
      expect(copied.email, 'new@example.com');
      expect(copied.emailVerified, isTrue);
    });

    test('copyWith updates uid', () {
      const user = AppAuthUser(uid: 'user123');
      final copied = user.copyWith(uid: 'user456');
      expect(copied.uid, 'user456');
    });

    test('copyWith updates emailVerified', () {
      const user = AppAuthUser(uid: 'user123', emailVerified: false);
      final copied = user.copyWith(emailVerified: true);
      expect(copied.emailVerified, isTrue);
    });

    test('copyWith updates providerData', () {
      const user = AppAuthUser(uid: 'user123');
      final copied = user.copyWith(
        providerData: [AppAuthProviderInfo('password')],
      );
      expect(copied.providerData.length, 1);
      expect(copied.providerData.first.providerId, 'password');
    });

    test('equality works for identical users', () {
      const user1 = AppAuthUser(
        uid: 'user123',
        email: 'test@example.com',
        emailVerified: true,
      );
      const user2 = AppAuthUser(
        uid: 'user123',
        email: 'test@example.com',
        emailVerified: true,
      );
      expect(user1, equals(user2));
    });

    test('equality fails for different uid', () {
      const user1 = AppAuthUser(uid: 'user123');
      const user2 = AppAuthUser(uid: 'user456');
      expect(user1, isNot(equals(user2)));
    });

    test('hashCode is consistent with equality', () {
      const user1 = AppAuthUser(uid: 'user123', email: 'test@example.com');
      const user2 = AppAuthUser(uid: 'user123', email: 'test@example.com');
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });

  group('envConfigProvider', () {
    test('returns EnvConfig instance', () {
      final config = container.read(envConfigProvider);
      expect(config, isA<EnvConfig>());
    });

    test('returns same instance on multiple reads', () {
      final config1 = container.read(envConfigProvider);
      final config2 = container.read(envConfigProvider);
      expect(identical(config1, config2), isTrue);
    });
  });

  group('currentUserProvider', () {
    test('returns null by default when not authenticated', () {
      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });
  });

  group('userIdProvider', () {
    test('returns null by default when no current user', () {
      final userId = container.read(userIdProvider);
      expect(userId, isNull);
    });

    test('can be overridden', () {
      final container2 = ProviderContainer(
        overrides: [userIdProvider.overrideWithValue('test-user-id')],
      );
      final userId = container2.read(userIdProvider);
      expect(userId, 'test-user-id');
      container2.dispose();
    });
  });

  group('Provider overrides', () {
    test('userIdProvider can be overridden with null', () {
      final container2 = ProviderContainer(
        overrides: [userIdProvider.overrideWithValue(null)],
      );
      expect(container2.read(userIdProvider), isNull);
      container2.dispose();
    });

    test('currentUserProvider can be overridden', () {
      final testUser = AppAuthUser(uid: 'test-uid', email: 'test@example.com');
      final container2 = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(testUser)],
      );
      final user = container2.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.uid, 'test-uid');
      container2.dispose();
    });
  });

  group('Repository providers', () {
    test('authRepositoryProvider is a Provider', () {
      expect(authRepositoryProvider, isA<Provider<AuthRepository>>());
    });

    test('cartRepositoryProvider is a Provider', () {
      expect(cartRepositoryProvider, isA<Provider<CartRepository>>());
    });

    test('orderRepositoryProvider is a Provider', () {
      expect(orderRepositoryProvider, isA<Provider<OrderRepository>>());
    });

    test('productRepositoryProvider is a Provider', () {
      expect(productRepositoryProvider, isA<Provider<ProductRepository>>());
    });

    test('userRepositoryProvider is a Provider', () {
      expect(userRepositoryProvider, isA<Provider<UserRepository>>());
    });

    test('locationRepositoryProvider is a Provider', () {
      expect(locationRepositoryProvider, isA<Provider<LocationRepository>>());
    });
  });
}
