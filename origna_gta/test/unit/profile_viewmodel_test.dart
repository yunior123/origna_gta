import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/profile/profile_viewmodel.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

@GenerateNiceMocks([MockSpec<UserRepository>(), MockSpec<AuthRepository>(), MockSpec<FirebaseFunctions>(), MockSpec<HttpsCallable>()])
import 'profile_viewmodel_test.mocks.dart';

void main() {
  late MockUserRepository mockUserRepo;
  late MockAuthRepository mockAuthRepo;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late ProviderContainer container;

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockAuthRepo = MockAuthRepository();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        firebaseFunctionsProvider.overrideWithValue(mockFunctions),
        userIdProvider.overrideWith((ref) => 'test_user'),
      ],
    );
  });

  group('ProfileViewModel', () {
    test('initial state is correct', () {
      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('signOut calls auth repository', () async {
      final viewModel = container.read(profileViewModelProvider.notifier);
      await viewModel.signOut();
      verify(mockAuthRepo.signOut()).called(1);
    });

    test('updateLanguage calls user repository and succeeds', () async {
      final viewModel = container.read(profileViewModelProvider.notifier);
      
      await viewModel.updateLanguage('fr');

      expect(container.read(profileViewModelProvider).isLoading, isFalse);
      verify(mockUserRepo.updatePreferredLanguage('test_user', 'fr')).called(1);
    });

    test('exportData calls cloud function', () async {
      final viewModel = container.read(profileViewModelProvider.notifier);
      
      when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
      // Return a dummy HttpsCallableResult or null depending on what the code expects
      when(mockCallable.call()).thenAnswer((_) async => throw Exception('Mock result not needed')); 

      try {
        await viewModel.exportData();
      } catch (_) {}

      expect(container.read(profileViewModelProvider).isLoading, isFalse);
      verify(mockFunctions.httpsCallable(any)).called(1);
    });

    test('deleteAccount requires correct confirmation string', () async {
      final viewModel = container.read(profileViewModelProvider.notifier);
      
      await viewModel.deleteAccount('WRONG');
      expect(container.read(profileViewModelProvider).errorMessage, contains('DELETE'));
      verifyNever(mockAuthRepo.deleteAccount());

      await viewModel.deleteAccount('DELETE');
      expect(container.read(profileViewModelProvider).isDeleted, isTrue);
      verify(mockAuthRepo.deleteAccount()).called(1);
    });
  });
}
