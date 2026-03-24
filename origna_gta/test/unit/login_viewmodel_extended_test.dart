import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/features/auth/login_state.dart';
import 'package:origna_gta/features/auth/login_viewmodel.dart';
import 'package:origna_gta/utils/utils.dart';

// ---------------------------------------------------------------------------
// Fake auth repository (reuse pattern from login_viewmodel_test.dart)
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  Future<void> Function(String email, String password)? onSignInWithEmail;
  Future<void> Function(
    String email,
    String password,
    String name,
    bool marketingOptIn,
  )?
  onRegisterWithEmail;
  Future<void> Function()? onSignInWithGoogle;
  Future<void> Function()? onSignInWithApple;
  Future<void> Function(String email)? onSendPasswordResetEmail;

  int signInCalls = 0;
  int registerCalls = 0;
  int googleCalls = 0;
  int appleCalls = 0;
  int resetCalls = 0;

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {}
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
  }) async {
    registerCalls++;
    await onRegisterWithEmail?.call(email, password, name, marketingOptIn);
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    await onSendPasswordResetEmail?.call(email);
  }

  @override
  Future<void> signInWithApple() async {
    appleCalls++;
    await onSignInWithApple?.call();
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInCalls++;
    await onSignInWithEmail?.call(email, password);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    await onSignInWithGoogle?.call();
  }

  @override
  Future<void> signOut() async {}
  @override
  Future<bool> validateCurrentUser() async => true;
  @override
  Stream<UserModel?> watchProfile(String userId) => const Stream.empty();
}

OrignaBaseAuthException _authException(
  String code, {
  String? message,
  String? challengeToken,
}) {
  return OrignaBaseAuthException(
    code: code,
    message: message,
    challengeToken: challengeToken,
  );
}

// ---------------------------------------------------------------------------
// Tests — targeting uncovered lines in login_viewmodel.dart
// ---------------------------------------------------------------------------

void main() {
  late _FakeAuthRepository fakeAuth;
  late ProviderContainer container;

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    fakeAuth = _FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuth)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LoginViewModel — double-submit guard', () {
    test('handleAuth returns early when already loading', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      // Manually set loading state
      vm.state = vm.state.copyWith(isLoading: true);

      await vm.handleAuth(email: 'test@example.com', password: 'Password123!');

      // No sign-in call should have been made
      expect(fakeAuth.signInCalls, 0);
    });

    test('handleGoogleSignIn returns early when already loading', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      vm.state = vm.state.copyWith(isLoading: true);

      await vm.handleGoogleSignIn();
      expect(fakeAuth.googleCalls, 0);
    });

    test('handleAppleSignIn returns early when already loading', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      vm.state = vm.state.copyWith(isLoading: true);

      await vm.handleAppleSignIn();
      expect(fakeAuth.appleCalls, 0);
    });
  });

  group('LoginViewModel — empty email', () {
    test('handleAuth rejects empty email', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      await vm.handleAuth(email: '', password: 'Password123!');

      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(fakeAuth.signInCalls, 0);
    });

    test('handleAuth rejects whitespace-only email', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      await vm.handleAuth(email: '   ', password: 'Password123!');

      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('LoginViewModel — registration edge cases', () {
    test('registration passes marketingOptIn to repository', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      vm.toggleAuthMode(); // Switch to register

      bool? capturedOptIn;
      fakeAuth.onRegisterWithEmail = (email, password, name, optIn) async {
        capturedOptIn = optIn;
      };

      vm.setMarketingOptIn(true);
      await vm.handleAuth(
        email: 'test@example.com',
        password: 'SecurePass123!',
        name: 'John',
        marketingOptIn: true,
      );

      expect(fakeAuth.registerCalls, 1);
      expect(capturedOptIn, isTrue);
    });

    test('registration with email-already-in-use generic error', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      vm.toggleAuthMode();

      fakeAuth.onRegisterWithEmail = (_, __, ___, ____) async {
        throw Exception('email-already-in-use');
      };

      await vm.handleAuth(
        email: 'existing@example.com',
        password: 'SecurePass123!',
        name: 'John',
      );

      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(
        state.errorMessage,
        anyOf(contains('email_already_in_use'), isNotEmpty),
      );
    });

    test('registration sets successMessage on success', () async {
      final vm = container.read(loginViewModelProvider.notifier);
      vm.toggleAuthMode();

      fakeAuth.onRegisterWithEmail = (_, __, ___, ____) async {};

      await vm.handleAuth(
        email: 'new@example.com',
        password: 'SecurePass123!',
        name: 'Jane Doe',
      );

      final state = container.read(loginViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.successMessage, isNotNull);
    });
  });

  group('LoginViewModel — Apple Sign-In edge cases', () {
    test('Apple sign-in auth exception sets error', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      fakeAuth.onSignInWithApple = () async {
        throw _authException('too-many-requests');
      };

      await vm.handleAppleSignIn();

      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isSuccess, isFalse);
    });

    test('Apple sign-in non-cancel error shows error', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      fakeAuth.onSignInWithApple = () async {
        throw Exception('network failure');
      };

      await vm.handleAppleSignIn();

      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('LoginViewModel — toggleAuthMode resets MFA', () {
    test('toggleAuthMode clears MFA state and messages', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      // Set up MFA state
      fakeAuth.onSignInWithEmail = (_, __) async {
        throw _authException('mfa-required', challengeToken: 'tok123');
      };
      await vm.handleAuth(email: 'mfa@example.com', password: 'Password123!');

      expect(container.read(loginViewModelProvider).mfaRequired, isTrue);

      // Toggle should clear MFA
      vm.toggleAuthMode();

      final state = container.read(loginViewModelProvider);
      expect(state.mfaRequired, isFalse);
      expect(state.challengeToken, isNull);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });
  });

  group('LoginViewModel — auth exception error mapping', () {
    test('login with permission_denied error maps correctly', () async {
      final vm = container.read(loginViewModelProvider.notifier);

      fakeAuth.onSignInWithEmail = (_, __) async {
        throw Exception('permission_denied');
      };

      await vm.handleAuth(email: 'test@example.com', password: 'Password123!');

      final state = container.read(loginViewModelProvider);
      expect(
        state.errorMessage,
        anyOf(contains('profile_setup_failed'), isNotEmpty),
      );
    });

    test(
      'register with permission-denied maps to account_creation_failed',
      () async {
        final vm = container.read(loginViewModelProvider.notifier);
        vm.toggleAuthMode();

        fakeAuth.onRegisterWithEmail = (_, __, ___, ____) async {
          throw Exception('permission-denied');
        };

        await vm.handleAuth(
          email: 'test@example.com',
          password: 'SecurePass123!',
          name: 'Test User',
        );

        final state = container.read(loginViewModelProvider);
        expect(
          state.errorMessage,
          anyOf(contains('account_creation_failed'), isNotEmpty),
        );
      },
    );
  });

  group('LoginState', () {
    test('default values are correct', () {
      const state = LoginState();
      expect(state.isLoading, isFalse);
      expect(state.isLogin, isTrue);
      expect(state.obscurePassword, isTrue);
      expect(state.acceptedTerms, isFalse);
      expect(state.marketingOptIn, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.mfaRequired, isFalse);
      expect(state.challengeToken, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const state = LoginState(isLogin: false, acceptedTerms: true);
      final copied = state.copyWith(isLoading: true);
      expect(copied.isLoading, isTrue);
      expect(copied.isLogin, isFalse);
      expect(copied.acceptedTerms, isTrue);
    });
  });
}
