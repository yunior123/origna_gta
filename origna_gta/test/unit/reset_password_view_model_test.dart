import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/features/auth/reset_password_view_model.dart';
import 'package:origna_gta/utils/utils.dart';

class FakeAuthRepository implements AuthRepository {
  Future<void> Function(String code, String newPassword)?
  onConfirmPasswordReset;
  int confirmPasswordResetCallCount = 0;

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    confirmPasswordResetCallCount += 1;
    await onConfirmPasswordReset?.call(code, newPassword);
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> ensureUserDocumentExists() async {}

  @override
  Future<bool> isEmailVerified() async => false;

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name, {
    bool marketingOptIn = false,
  }) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> validateCurrentUser() async => true;

  @override
  Stream<UserModel?> watchProfile(String userId) => const Stream.empty();
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;
  const oobCode = 'test-code';

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
  });

  group('ResetPasswordViewModel', () {
    test('initialization completes verification state', () async {
      final keepAlive = container.listen(
        resetPasswordViewModelProvider(oobCode),
        (_, _) {},
      );
      container.read(resetPasswordViewModelProvider(oobCode).notifier);

      await Future.delayed(Duration.zero);

      final state = container.read(resetPasswordViewModelProvider(oobCode));
      expect(state.isVerifying, isFalse);
      expect(state.errorMessage, isNull);
      keepAlive.close();
    });

    test('resetPassword validates password requirements', () async {
      final viewModel = container.read(
        resetPasswordViewModelProvider(oobCode).notifier,
      );
      final keepAlive = container.listen(
        resetPasswordViewModelProvider(oobCode),
        (_, _) {},
      );
      await Future.delayed(Duration.zero);

      // Empty
      await viewModel.resetPassword('', '');
      expect(
        container.read(resetPasswordViewModelProvider(oobCode)).errorMessage,
        isNotNull,
      );

      // Too short
      await viewModel.resetPassword('123', '123');
      expect(
        container.read(resetPasswordViewModelProvider(oobCode)).errorMessage,
        isNotNull,
      );

      // Mismatch
      await viewModel.resetPassword('Password123!', 'Password124!');
      expect(
        container.read(resetPasswordViewModelProvider(oobCode)).errorMessage,
        isNotNull,
      );
      keepAlive.close();
    });

    test('resetPassword success', () async {
      fakeAuthRepository.onConfirmPasswordReset = (code, password) =>
          Future<void>.value();

      final viewModel = container.read(
        resetPasswordViewModelProvider(oobCode).notifier,
      );
      final keepAlive = container.listen(
        resetPasswordViewModelProvider(oobCode),
        (_, _) {},
      );
      await Future.delayed(Duration.zero);

      await viewModel.resetPassword('Password123!', 'Password123!');

      final state = container.read(resetPasswordViewModelProvider(oobCode));
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(fakeAuthRepository.confirmPasswordResetCallCount, 1);
      keepAlive.close();
    });

    test('resetPassword handles auth failure', () async {
      fakeAuthRepository.onConfirmPasswordReset = (code, password) async {
        throw OrignaBaseAuthException(code: 'weak-password');
      };

      final viewModel = container.read(
        resetPasswordViewModelProvider(oobCode).notifier,
      );
      final keepAlive = container.listen(
        resetPasswordViewModelProvider(oobCode),
        (_, _) {},
      );
      await Future.delayed(Duration.zero);

      await viewModel.resetPassword('Password123!', 'Password123!');

      final state = container.read(resetPasswordViewModelProvider(oobCode));
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
      keepAlive.close();
    });

    test('resetPassword handles generic failure', () async {
      fakeAuthRepository.onConfirmPasswordReset = (code, password) async {
        throw Exception('error');
      };

      final viewModel = container.read(
        resetPasswordViewModelProvider(oobCode).notifier,
      );
      final keepAlive = container.listen(
        resetPasswordViewModelProvider(oobCode),
        (_, _) {},
      );
      await Future.delayed(Duration.zero);

      await viewModel.resetPassword('Password123!', 'Password123!');

      final state = container.read(resetPasswordViewModelProvider(oobCode));
      expect(state.errorMessage, isNotNull);
      expect(state.isLoading, isFalse);
      keepAlive.close();
    });
  });
}
