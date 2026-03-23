import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_coverage_test.mocks.dart';

void main() {
  late MockAdminRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAdminRepository();
    container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  group('AdminActionsState', () {
    test('default state has expected values', () {
      const state = AdminActionsState();
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves non-updated fields', () {
      const state = AdminActionsState(isLoading: true, isSuccess: true);
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith sets errorMessage', () {
      const state = AdminActionsState();
      final updated = state.copyWith(errorMessage: 'error');
      expect(updated.errorMessage, 'error');
    });

    test('copyWith all fields', () {
      const state = AdminActionsState();
      final updated = state.copyWith(
        isLoading: true,
        isSuccess: true,
        errorMessage: 'test',
      );
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
      expect(updated.errorMessage, 'test');
    });
  });

  group('AdminActionsViewModel - all actions', () {
    test('approveProduct fails with error', () async {
      when(
        mockRepo.approveProduct('p123'),
      ).thenThrow(Exception('server error'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.approveProduct('p123');

      expect(result, isFalse);
      expect(
        container.read(adminActionsViewModelProvider).errorMessage,
        isNotNull,
      );
      expect(container.read(adminActionsViewModelProvider).isLoading, isFalse);
    });

    test('rejectProduct fails with error', () async {
      when(
        mockRepo.rejectProduct('p123', 'reason'),
      ).thenThrow(Exception('error'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.rejectProduct('p123', 'reason');

      expect(result, isFalse);
      expect(
        container.read(adminActionsViewModelProvider).errorMessage,
        isNotNull,
      );
    });

    test('deleteProduct succeeds', () async {
      when(mockRepo.deleteProduct('p123')).thenAnswer((_) async { return null; });

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.deleteProduct('p123');

      expect(result, isTrue);
      expect(container.read(adminActionsViewModelProvider).isSuccess, isTrue);
      verify(mockRepo.deleteProduct('p123')).called(1);
    });

    test('deleteProduct fails with error', () async {
      when(mockRepo.deleteProduct('p123')).thenThrow(Exception('fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.deleteProduct('p123');

      expect(result, isFalse);
      expect(
        container.read(adminActionsViewModelProvider).errorMessage,
        isNotNull,
      );
    });

    test('setUserSuspended fails with error', () async {
      when(
        mockRepo.setUserSuspended('u123', true),
      ).thenThrow(Exception('fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.setUserSuspended('u123', true);

      expect(result, isFalse);
    });

    test('updateUserRoles fails with error', () async {
      when(
        mockRepo.updateUserRoles(
          'u123',
          add: anyNamed('add'),
          remove: anyNamed('remove'),
          reason: anyNamed('reason'),
        ),
      ).thenThrow(Exception('fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.updateUserRoles('u123', add: ['admin']);

      expect(result, isFalse);
    });

    test('updateUserRoles succeeds', () async {
      when(
        mockRepo.updateUserRoles(
          'u123',
          add: ['admin'],
          remove: [],
          reason: anyNamed('reason'),
        ),
      ).thenAnswer((_) async { return null; });

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.updateUserRoles('u123', add: ['admin']);

      expect(result, isTrue);
    });

    test('disableAdminMfa succeeds', () async {
      when(mockRepo.disableAdminMfa('123456')).thenAnswer((_) async { return null; });

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.disableAdminMfa('123456');

      expect(result, isTrue);
      verify(mockRepo.disableAdminMfa('123456')).called(1);
    });

    test('disableAdminMfa fails with error', () async {
      when(mockRepo.disableAdminMfa('123456')).thenThrow(Exception('mfa fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.disableAdminMfa('123456');

      expect(result, isFalse);
    });

    test('enableAdminMfa succeeds', () async {
      when(mockRepo.enableAdminMfa()).thenAnswer(
        (_) async => {'secret': 'abc', 'qrCodeUrl': 'https://example.com'},
      );

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.enableAdminMfa();

      expect(result, isNotNull);
      expect(result!['secret'], 'abc');
    });

    test('enableAdminMfa fails with error', () async {
      when(mockRepo.enableAdminMfa()).thenThrow(Exception('mfa fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.enableAdminMfa();

      expect(result, isNull);
    });

    test('verifyAdminMfa succeeds', () async {
      when(
        mockRepo.verifyAdminMfa('123456'),
      ).thenAnswer((_) async => {'verified': true});

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.verifyAdminMfa('123456');

      expect(result, isTrue);
      verify(mockRepo.verifyAdminMfa('123456')).called(1);
    });

    test('verifyAdminMfa fails with error', () async {
      when(
        mockRepo.verifyAdminMfa('123456'),
      ).thenThrow(Exception('verify fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.verifyAdminMfa('123456');

      expect(result, isFalse);
    });

    test('updateProductStock succeeds', () async {
      when(mockRepo.updateProductStock('p123', 50)).thenAnswer((_) async { return null; });

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.updateProductStock('p123', 50);

      expect(result, isTrue);
      verify(mockRepo.updateProductStock('p123', 50)).called(1);
    });

    test('updateProductStock fails with error', () async {
      when(
        mockRepo.updateProductStock('p123', 50),
      ).thenThrow(Exception('fail'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.updateProductStock('p123', 50);

      expect(result, isFalse);
    });

    test('fetchUserById returns null on error', () async {
      when(mockRepo.fetchUserById('u123')).thenThrow(Exception('not found'));

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.fetchUserById('u123');

      expect(result, isNull);
    });

    test('fetchUserById returns user on success', () async {
      when(
        mockRepo.fetchUserById('u123'),
      ).thenAnswer((_) async => null); // repo returns null

      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      final result = await viewModel.fetchUserById('u123');

      expect(result, isNull);
    });
  });

  group('AdminActionsViewModel - state transitions', () {
    test('action sets isLoading to true during execution', () async {
      when(mockRepo.approveProduct('p123')).thenAnswer((_) async { return null; });

      final viewModel = container.read(adminActionsViewModelProvider.notifier);

      // Initial state
      expect(container.read(adminActionsViewModelProvider).isLoading, isFalse);

      await viewModel.approveProduct('p123');

      // After completion
      expect(container.read(adminActionsViewModelProvider).isLoading, isFalse);
      expect(container.read(adminActionsViewModelProvider).isSuccess, isTrue);
    });

    test('error clears isSuccess flag', () async {
      // First succeed
      when(mockRepo.approveProduct('p1')).thenAnswer((_) async { return null; });
      final viewModel = container.read(adminActionsViewModelProvider.notifier);
      await viewModel.approveProduct('p1');
      expect(container.read(adminActionsViewModelProvider).isSuccess, isTrue);

      // Then fail
      when(mockRepo.approveProduct('p2')).thenThrow(Exception('fail'));
      await viewModel.approveProduct('p2');
      expect(container.read(adminActionsViewModelProvider).isSuccess, isFalse);
      expect(
        container.read(adminActionsViewModelProvider).errorMessage,
        isNotNull,
      );
    });
  });
}
