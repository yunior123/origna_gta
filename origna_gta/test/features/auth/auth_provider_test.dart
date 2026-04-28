import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

import '../../test_utils.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
import 'auth_provider_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late ProviderContainer container;

  const testUserId = 'user_123';

  final testUser = UserModel(
    uid: testUserId,
    email: 'test@example.com',
    name: 'Test User',
    roles: const [UserRole.buyer],
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    initTestMocks();
  });

  tearDown(() {
    container.dispose();
  });

  group('userProfileProvider', () {
    test('returns user profile when logged in', () async {
      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream.value(testUser));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final profile = await container.read(userProfileProvider.future);

      expect(profile, equals(testUser));
    });

    test('returns null when user is not logged in', () {
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(null),
        ],
      );

      final profileAsync = container.read(userProfileProvider);

      profileAsync.whenData((profile) {
        expect(profile, isNull);
      });
    });

    test('streams updates to profile', () async {
      final controller = StreamController<UserModel?>.broadcast();

      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => controller.stream);

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      container.read(userProfileProvider);

      controller.add(testUser);

      await Future.delayed(const Duration(milliseconds: 100));

      controller.close();
      container.dispose();
    });
  });

  group('needsTermsUpdateProvider', () {
    test('returns false when profile is null', () {
      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final needsUpdate = container.read(needsTermsUpdateProvider);

      expect(needsUpdate, false);
    });

    test('returns false when user has no terms version (pre-versioning)', () {
      final oldUser = UserModel(
        uid: testUserId,
        email: 'test@example.com',
        name: 'Test User',
        roles: const [UserRole.buyer],
        createdAt: DateTime.now(),
        termsVersion: null,
      );

      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream.value(oldUser));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final needsUpdate = container.read(needsTermsUpdateProvider);

      expect(needsUpdate, false);
    });

    test('returns false when user has current terms version', () {
      final currentUser = UserModel(
        uid: testUserId,
        email: 'test@example.com',
        name: 'Test User',
        roles: const [UserRole.buyer],
        createdAt: DateTime.now(),
        termsVersion: PolicyVersionValues.defaultVersion,
      );

      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream.value(currentUser));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final needsUpdate = container.read(needsTermsUpdateProvider);

      expect(needsUpdate, false);
    });

    test('returns true when user has outdated terms version', () async {
      final outdatedUser = UserModel(
        uid: testUserId,
        email: 'test@example.com',
        name: 'Test User',
        roles: const [UserRole.buyer],
        createdAt: DateTime.now(),
        termsVersion: '1.0.0',
      );

      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream.value(outdatedUser));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      await container.read(userProfileProvider.future);

      final needsUpdate = container.read(needsTermsUpdateProvider);

      expect(needsUpdate, true);
    });

    test('returns false while profile is loading', () {
      when(
        mockAuthRepo.watchProfile(testUserId),
      ).thenAnswer((_) => Stream<UserModel?>.empty());

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final needsUpdate = container.read(needsTermsUpdateProvider);

      expect(needsUpdate, false);
    });
  });

  group('authActionsProvider', () {
    setUp(() {
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
    });

    test('signOut delegates to repository', () async {
      when(mockAuthRepo.signOut()).thenAnswer((_) async {});

      final actions = container.read(authActionsProvider);

      await actions.signOut();

      verify(mockAuthRepo.signOut()).called(1);
    });

    test('isEmailVerified delegates to repository', () async {
      when(mockAuthRepo.isEmailVerified()).thenAnswer((_) async => true);

      final actions = container.read(authActionsProvider);

      final result = await actions.isEmailVerified();

      expect(result, true);
      verify(mockAuthRepo.isEmailVerified()).called(1);
    });

    test('ensureUserDocumentExists delegates to repository', () async {
      when(mockAuthRepo.ensureUserDocumentExists()).thenAnswer((_) async {});

      final actions = container.read(authActionsProvider);

      await actions.ensureUserDocumentExists();

      verify(mockAuthRepo.ensureUserDocumentExists()).called(1);
    });

    test('sendEmailVerification delegates to repository', () async {
      when(mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});

      final actions = container.read(authActionsProvider);

      await actions.sendEmailVerification();

      verify(mockAuthRepo.sendEmailVerification()).called(1);
    });
  });
}
