import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/profile/profile_provider.dart';
import 'package:origna_gta/features/profile/profile_viewmodel.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';

import '../../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<OrignaBase>(),
])
import 'profile_viewmodel_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;
  late MockOrignaBase mockOrignaBase;
  late ProviderContainer container;

  const testUserId = 'user_123';

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
    mockOrignaBase = MockOrignaBase();
    initTestMocks();
  });

  tearDown(() {
    container.dispose();
  });

  group('profileViewModelProvider', () {
    test('initial state has default values', () {
      container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(mockOrignaBase),
          authActionsProvider.overrideWith((ref) => AuthActions(mockAuthRepo)),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          obUserIdProvider.overrideWithValue(testUserId),
        ],
      );

      final state = container.read(profileViewModelProvider);

      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.isDeleted, false);
    });
  });

  group('OrignaBaseProfileViewModel', () {
    late OrignaBaseProfileViewModel viewModel;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(mockOrignaBase),
          authActionsProvider.overrideWith((ref) => AuthActions(mockAuthRepo)),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          obUserIdProvider.overrideWithValue(testUserId),
        ],
      );

      viewModel = container.read(profileViewModelProvider.notifier);
    });

    group('signOut', () {
      test('calls auth actions signOut', () async {
        when(mockAuthRepo.signOut()).thenAnswer((_) async {});

        await viewModel.signOut();

        verify(mockAuthRepo.signOut()).called(1);
      });
    });

    group('updateLanguage', () {
      test('no-ops when user is not logged in', () async {
        final emptyContainer = ProviderContainer(
          overrides: [
            orignabaseProvider.overrideWithValue(mockOrignaBase),
            authActionsProvider.overrideWith((ref) => AuthActions(mockAuthRepo)),
            userRepositoryProvider.overrideWithValue(mockUserRepo),
            obUserIdProvider.overrideWithValue(null),
          ],
        );

        final emptyViewModel = emptyContainer.read(profileViewModelProvider.notifier);

        await emptyViewModel.updateLanguage('fr');

        verifyNever(mockUserRepo.updatePreferredLanguage(any, any));

        emptyContainer.dispose();
      });

      test('updates language and sets success message', () async {
        when(mockUserRepo.updatePreferredLanguage(testUserId, 'fr'))
            .thenAnswer((_) async {});

        await viewModel.updateLanguage('fr');

        verify(mockUserRepo.updatePreferredLanguage(testUserId, 'fr'))
            .called(1);

        final state = container.read(profileViewModelProvider);
        expect(state.isLoading, false);
        expect(state.successMessage, isNotNull);
      });

      test('sets error message on failure', () async {
        when(mockUserRepo.updatePreferredLanguage(testUserId, 'fr'))
            .thenThrow(Exception('Network error'));

        await viewModel.updateLanguage('fr');

        final state = container.read(profileViewModelProvider);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('exportData', () {
      test('sets error when user is not logged in', () async {
        final emptyContainer = ProviderContainer(
          overrides: [
            orignabaseProvider.overrideWithValue(mockOrignaBase),
            authActionsProvider.overrideWith((ref) => AuthActions(mockAuthRepo)),
            userRepositoryProvider.overrideWithValue(mockUserRepo),
            obUserIdProvider.overrideWithValue(null),
          ],
        );

        final emptyViewModel = emptyContainer.read(profileViewModelProvider.notifier);

        await emptyViewModel.exportData();

        final state = emptyContainer.read(profileViewModelProvider);
        expect(state.errorMessage, isNotNull);

        emptyContainer.dispose();
      });

      test('requests export and sets success message', () async {
        when(mockOrignaBase.request(
          'POST',
          ApiEndpoints.adminExportData,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {});

        await viewModel.exportData();

        verify(mockOrignaBase.request(
          'POST',
          ApiEndpoints.adminExportData,
          body: {},
        )).called(1);

        final state = container.read(profileViewModelProvider);
        expect(state.isLoading, false);
        expect(state.successMessage, isNotNull);
      });

      test('sets error message on failure', () async {
        when(mockOrignaBase.request(
          'POST',
          ApiEndpoints.adminExportData,
          body: anyNamed('body'),
        )).thenThrow(Exception('Export failed'));

        await viewModel.exportData();

        final state = container.read(profileViewModelProvider);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('deleteAccount', () {
      test('returns error for invalid confirmation', () async {
        await viewModel.deleteAccount('confirm');

        final state = container.read(profileViewModelProvider);
        expect(state.errorMessage, isNotNull);
        expect(state.isDeleted, false);
      });

      test('returns error for empty confirmation', () async {
        await viewModel.deleteAccount('');

        final state = container.read(profileViewModelProvider);
        expect(state.errorMessage, isNotNull);
      });

      test('returns error when user is not logged in', () async {
        final emptyContainer = ProviderContainer(
          overrides: [
            orignabaseProvider.overrideWithValue(mockOrignaBase),
            authActionsProvider.overrideWith((ref) => AuthActions(mockAuthRepo)),
            userRepositoryProvider.overrideWithValue(mockUserRepo),
            obUserIdProvider.overrideWithValue(null),
          ],
        );

        final emptyViewModel = emptyContainer.read(profileViewModelProvider.notifier);

        await emptyViewModel.deleteAccount('DELETE');

        final state = emptyContainer.read(profileViewModelProvider);
        expect(state.errorMessage, isNotNull);

        emptyContainer.dispose();
      });

      test('deletes account with valid confirmation', () async {
        when(mockOrignaBase.request(
          'POST',
          ApiEndpoints.authDeleteAccount,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {});
        when(mockAuthRepo.signOut()).thenAnswer((_) async {});

        await viewModel.deleteAccount('DELETE');

        verify(mockOrignaBase.request(
          'POST',
          ApiEndpoints.authDeleteAccount,
          body: {Fields.userId: testUserId, 'confirmation': 'DELETE_MY_ACCOUNT'},
        )).called(1);

        verify(mockAuthRepo.signOut()).called(1);

        final state = container.read(profileViewModelProvider);
        expect(state.isDeleted, true);
        expect(state.isLoading, false);
      });

      test('sets error message on failure', () async {
        when(mockOrignaBase.request(
          'POST',
          ApiEndpoints.authDeleteAccount,
          body: anyNamed('body'),
        )).thenThrow(Exception('Delete failed'));

        await viewModel.deleteAccount('DELETE');

        final state = container.read(profileViewModelProvider);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });
    });
  });

  group('ProfileState', () {
    test('initial state has correct defaults', () {
      const state = ProfileState();

      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.isDeleted, false);
    });

    test('copyWith creates new state with updated values', () {
      const state = ProfileState();
      final newState = state.copyWith(
        isLoading: true,
        errorMessage: 'Error',
      );

      expect(newState.isLoading, true);
      expect(newState.errorMessage, 'Error');
      expect(newState.successMessage, isNull);
    });

    test('copyWith preserves unchanged values', () {
      const state = ProfileState(
        isLoading: true,
        successMessage: 'Success',
      );
      final newState = state.copyWith(errorMessage: 'Error');

      expect(newState.isLoading, true);
      expect(newState.successMessage, 'Success');
      expect(newState.errorMessage, 'Error');
    });
  });
}
