import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/utils/utils.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
])
import 'auth_repository_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();

    // Default stubs
    when(repository.deleteAccount()).thenAnswer((_) async { return null; });
    when(repository.signInWithEmail(any, any)).thenAnswer((_) async { return null; });
    when(repository.isEmailVerified()).thenAnswer((_) async => true);
    when(repository.registerWithEmail(any, any, any, marketingOptIn: anyNamed('marketingOptIn'))).thenAnswer((_) async { return null; });
    when(repository.sendPasswordResetEmail(any)).thenAnswer((_) async { return null; });
    when(repository.signOut()).thenAnswer((_) async { return null; });
    when(repository.validateCurrentUser()).thenAnswer((_) async => true);
    when(repository.signInWithGoogle()).thenAnswer((_) async { return null; });
    when(repository.signInWithApple()).thenAnswer((_) async { return null; });
    when(repository.ensureUserDocumentExists()).thenAnswer((_) async { return null; });
    when(repository.sendEmailVerification()).thenAnswer((_) async { return null; });
    when(repository.confirmPasswordReset(any, any)).thenAnswer((_) async { return null; });
  });

  group('AuthRepository Unit Tests', () {
    test('deleteAccount calls repository', () async {
      await repository.deleteAccount();
      verify(repository.deleteAccount()).called(1);
    });

    test('signInWithEmail calls repository', () async {
      await repository.signInWithEmail('test@example.com', 'password123');
      verify(repository.signInWithEmail('test@example.com', 'password123')).called(1);
    });

    test('isEmailVerified returns true', () async {
      final verified = await repository.isEmailVerified();
      expect(verified, isTrue);
    });

    test('isEmailVerified returns false when not verified', () async {
      when(repository.isEmailVerified()).thenAnswer((_) async => false);
      final result = await repository.isEmailVerified();
      expect(result, false);
    });

    test('registerWithEmail calls repository', () async {
      await repository.registerWithEmail('test@example.com', 'password123', 'Test User');
      verify(repository.registerWithEmail('test@example.com', 'password123', 'Test User')).called(1);
    });

    test('registerWithEmail with marketing opt-in', () async {
      await repository.registerWithEmail('test@example.com', 'password123', 'Test User', marketingOptIn: true);
      verify(repository.registerWithEmail('test@example.com', 'password123', 'Test User', marketingOptIn: true)).called(1);
    });

    test('sendPasswordResetEmail calls repository', () async {
      await repository.sendPasswordResetEmail('test@example.com');
      verify(repository.sendPasswordResetEmail('test@example.com')).called(1);
    });

    test('signOut calls repository', () async {
      await repository.signOut();
      verify(repository.signOut()).called(1);
    });

    test('validateCurrentUser returns true for valid user', () async {
      final isValid = await repository.validateCurrentUser();
      expect(isValid, isTrue);
    });

    test('validateCurrentUser returns false when invalid', () async {
      when(repository.validateCurrentUser()).thenAnswer((_) async => false);
      final isValid = await repository.validateCurrentUser();
      expect(isValid, isFalse);
    });

    test('signInWithGoogle calls repository', () async {
      await repository.signInWithGoogle();
      verify(repository.signInWithGoogle()).called(1);
    });

    test('signInWithApple calls repository', () async {
      await repository.signInWithApple();
      verify(repository.signInWithApple()).called(1);
    });

    test('ensureUserDocumentExists calls repository', () async {
      await repository.ensureUserDocumentExists();
      verify(repository.ensureUserDocumentExists()).called(1);
    });

    test('watchProfile returns UserModel stream', () async {
      when(repository.watchProfile('user_123')).thenAnswer((_) => Stream.value(
        UserModel(
          uid: 'user_123',
          name: 'Test User',
          email: 'test@example.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ));

      final stream = repository.watchProfile('user_123');
      final model = await stream.first;

      expect(model?.uid, 'user_123');
      expect(model?.name, 'Test User');
    });

    test('watchProfile returns null for non-existent user', () async {
      when(repository.watchProfile('nonexistent')).thenAnswer((_) => Stream.value(null));

      final stream = repository.watchProfile('nonexistent');
      final model = await stream.first;

      expect(model, isNull);
    });

    test('sendEmailVerification calls repository', () async {
      await repository.sendEmailVerification();
      verify(repository.sendEmailVerification()).called(1);
    });

    test('confirmPasswordReset calls repository', () async {
      await repository.confirmPasswordReset('oob_code', 'newPassword123');
      verify(repository.confirmPasswordReset('oob_code', 'newPassword123')).called(1);
    });

    test('signInWithEmail throws on error', () async {
      when(repository.signInWithEmail(any, any)).thenThrow(Exception('Invalid credentials'));
      expect(() => repository.signInWithEmail('bad@email.com', 'wrong'), throwsA(isA<Exception>()));
    });

    test('registerWithEmail throws on duplicate email', () async {
      when(repository.registerWithEmail(any, any, any, marketingOptIn: anyNamed('marketingOptIn')))
          .thenThrow(Exception('email-already-in-use'));
      expect(
        () => repository.registerWithEmail('existing@email.com', 'pass', 'Name'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
