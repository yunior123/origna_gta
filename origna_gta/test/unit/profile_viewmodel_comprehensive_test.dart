import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/profile/orignabase_profile_viewmodel.dart';
import 'package:origna_gta/features/profile/profile_state.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<OrignaBaseAuth>(),
  MockSpec<UserRepository>(),
])
import 'profile_viewmodel_comprehensive_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late MockOrignaBaseAuth mockAuth;
  late MockUserRepository mockUserRepo;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();
    mockUserRepo = MockUserRepository();

    when(mockOrignaBase.auth).thenReturn(mockAuth);
    when(
      mockOrignaBase.request(any, any, body: anyNamed('body')),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      mockUserRepo.updatePreferredLanguage(any, any),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({String? userId}) {
    return ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        obUserIdProvider.overrideWithValue(userId),
      ],
    );
  }

  group('ProfileViewModel Initial State Tests', () {
    test('initial state has isLoading false', () {
      container = createContainer(userId: 'user_123');
      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
    });

    test('initial state has no error message', () {
      container = createContainer(userId: 'user_123');
      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNull);
    });

    test('initial state has no success message', () {
      container = createContainer(userId: 'user_123');
      final state = container.read(profileViewModelProvider);
      expect(state.successMessage, isNull);
    });

    test('initial state has isDeleted false', () {
      container = createContainer(userId: 'user_123');
      final state = container.read(profileViewModelProvider);
      expect(state.isDeleted, isFalse);
    });
  });

  group('ProfileViewModel State Transitions Tests', () {
    test('signOut calls auth.signOut()', () async {
      container = createContainer(userId: 'user_123');

      await container.read(profileViewModelProvider.notifier).signOut();

      verify(mockAuth.signOut()).called(1);
    });

    test('updateLanguage sets successMessage on success', () async {
      container = createContainer(userId: 'user_123');

      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('fr');

      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      verify(mockUserRepo.updatePreferredLanguage('user_123', 'fr')).called(1);
    });

    test('updateLanguage sets errorMessage on failure', () async {
      container = createContainer(userId: 'user_123');

      when(
        mockUserRepo.updatePreferredLanguage(any, any),
      ).thenThrow(Exception('Network error'));

      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('en');

      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('updateLanguage does nothing when userId is null', () async {
      container = createContainer(userId: null);

      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('fr');

      verifyNever(mockUserRepo.updatePreferredLanguage(any, any));
    });
  });

  group('ProfileViewModel exportData Tests', () {
    test('exportData sets errorMessage when userId is null', () async {
      container = createContainer(userId: null);

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('exportData sets errorMessage when userId is empty', () async {
      container = createContainer(userId: '');

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('exportData calls correct API endpoint', () async {
      container = createContainer(userId: 'user_123');

      await container.read(profileViewModelProvider.notifier).exportData();

      verify(
        mockOrignaBase.request(
          'POST',
          ApiEndpoints.adminExportData,
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('exportData sets successMessage on success', () async {
      container = createContainer(userId: 'user_123');

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.successMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('exportData sets errorMessage on failure', () async {
      container = createContainer(userId: 'user_123');

      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(Exception('Server error'));

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
    });
  });

  group('ProfileViewModel deleteAccount Tests', () {
    test('deleteAccount rejects wrong confirmation', () async {
      container = createContainer(userId: 'user_123');

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('WRONG');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
      verifyNever(mockOrignaBase.request(any, any, body: anyNamed('body')));
    });

    test('deleteAccount accepts DELETE confirmation', () async {
      container = createContainer(userId: 'user_123');

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      final state = container.read(profileViewModelProvider);
      expect(state.isDeleted, isTrue);
      expect(state.isLoading, isFalse);
      verify(mockAuth.signOut()).called(1);
    });

    test('deleteAccount calls correct API endpoint', () async {
      container = createContainer(userId: 'user_123');

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      verify(
        mockOrignaBase.request(
          'POST',
          ApiEndpoints.authDeleteAccount,
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('deleteAccount sets errorMessage when userId is null', () async {
      container = createContainer(userId: null);

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
    });

    test('deleteAccount sets errorMessage when userId is empty', () async {
      container = createContainer(userId: '');

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
    });

    test('deleteAccount sets errorMessage on failure', () async {
      container = createContainer(userId: 'user_123');

      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(Exception('Server error'));

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
    });
  });

  group('ProfileViewModel Error Handling Tests', () {
    test('handles OrignaBaseException correctly', () async {
      container = createContainer(userId: 'user_123');

      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(OrignaBaseException('Custom error'));

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('handles generic Exception correctly', () async {
      container = createContainer(userId: 'user_123');

      when(
        mockUserRepo.updatePreferredLanguage(any, any),
      ).thenThrow(Exception('Generic error'));

      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('fr');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('ProfileViewModel Edge Cases Tests', () {
    test('multiple signOut calls are handled', () async {
      container = createContainer(userId: 'user_123');

      await container.read(profileViewModelProvider.notifier).signOut();
      await container.read(profileViewModelProvider.notifier).signOut();

      verify(mockAuth.signOut()).called(2);
    });

    test('rapid consecutive updateLanguage calls', () async {
      container = createContainer(userId: 'user_123');

      await Future.wait([
        container.read(profileViewModelProvider.notifier).updateLanguage('fr'),
        container.read(profileViewModelProvider.notifier).updateLanguage('en'),
      ]);

      verify(mockUserRepo.updatePreferredLanguage(any, any)).called(2);
    });

    test('deleteAccount with whitespace in confirmation', () async {
      container = createContainer(userId: 'user_123');

      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('  DELETE  ');

      final state = container.read(profileViewModelProvider);
      expect(state.isDeleted, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('ProfileState copyWith Tests', () {
    test('copyWith preserves isLoading when not specified', () {
      final state = ProfileState(isLoading: true);

      final copied = state.copyWith();

      expect(copied.isLoading, isTrue);
    });

    test('copyWith preserves isDeleted when not specified', () {
      final state = ProfileState(isDeleted: true);

      final copied = state.copyWith();

      expect(copied.isDeleted, isTrue);
    });

    test('copyWith updates individual fields', () {
      final state = ProfileState();

      final copied = state.copyWith(
        isLoading: true,
        errorMessage: 'Error',
        successMessage: 'Success',
        isDeleted: true,
      );

      expect(copied.isLoading, isTrue);
      expect(copied.errorMessage, 'Error');
      expect(copied.successMessage, 'Success');
      expect(copied.isDeleted, isTrue);
    });

    test('copyWith can null out messages', () {
      final state = ProfileState(
        errorMessage: 'Error',
        successMessage: 'Success',
      );

      final copied = state.copyWith(errorMessage: null, successMessage: null);

      expect(copied.errorMessage, isNull);
      expect(copied.successMessage, isNull);
    });
  });
}
