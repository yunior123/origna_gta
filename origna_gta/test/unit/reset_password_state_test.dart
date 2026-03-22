import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/auth/reset_password_state.dart';

void main() {
  group('ResetPasswordState', () {
    test('creates with default values', () {
      const state = ResetPasswordState();
      expect(state.isVerifying, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.userEmail, isNull);
    });

    test('creates with custom values', () {
      final state = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        isSuccess: false,
        errorMessage: 'Test error',
        userEmail: 'test@example.com',
      );
      expect(state.isVerifying, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, 'Test error');
      expect(state.userEmail, 'test@example.com');
    });

    test('copyWith preserves unchanged values', () {
      final original = ResetPasswordState(
        isVerifying: false,
        userEmail: 'original@example.com',
      );
      final copied = original.copyWith(isLoading: true);
      expect(copied.isVerifying, isFalse);
      expect(copied.isLoading, isTrue);
      expect(copied.userEmail, 'original@example.com');
    });

    test('copyWith can update all fields', () {
      const original = ResetPasswordState();
      final copied = original.copyWith(
        isVerifying: false,
        isLoading: false,
        isSuccess: true,
        errorMessage: null,
        userEmail: 'updated@example.com',
      );
      expect(copied.isVerifying, isFalse);
      expect(copied.isLoading, isFalse);
      expect(copied.isSuccess, isTrue);
      expect(copied.errorMessage, isNull);
      expect(copied.userEmail, 'updated@example.com');
    });

    test('copyWith can clear nullable fields', () {
      final state = ResetPasswordState(
        errorMessage: 'Error',
        userEmail: 'test@example.com',
      );
      final cleared = state.copyWith(errorMessage: null, userEmail: null);
      expect(cleared.errorMessage, isNull);
      expect(cleared.userEmail, isNull);
    });

    test('equality works for identical states', () {
      final state1 = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        userEmail: 'test@example.com',
      );
      final state2 = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        userEmail: 'test@example.com',
      );
      expect(state1, equals(state2));
    });

    test('equality fails for different states', () {
      final state1 = ResetPasswordState(isVerifying: true);
      final state2 = ResetPasswordState(isVerifying: false);
      expect(state1, isNot(equals(state2)));
    });

    test('hashCode is consistent with equality', () {
      final state1 = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        userEmail: 'test@example.com',
      );
      final state2 = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        userEmail: 'test@example.com',
      );
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('toString contains all fields', () {
      final state = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        isSuccess: true,
        errorMessage: 'Error',
        userEmail: 'test@example.com',
      );
      final str = state.toString();
      expect(str, contains('isVerifying: false'));
      expect(str, contains('isLoading: true'));
      expect(str, contains('isSuccess: true'));
      expect(str, contains('errorMessage: Error'));
      expect(str, contains('userEmail: test@example.com'));
    });
  });

  group('ResetPasswordState transitions', () {
    test('initial state is verifying', () {
      const state = ResetPasswordState();
      expect(state.isVerifying, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('transition from verifying to ready', () {
      const verifying = ResetPasswordState();
      final ready = verifying.copyWith(isVerifying: false);
      expect(ready.isVerifying, isFalse);
      expect(ready.isLoading, isFalse);
    });

    test('transition to loading', () {
      final ready = ResetPasswordState(isVerifying: false);
      final loading = ready.copyWith(isLoading: true);
      expect(loading.isVerifying, isFalse);
      expect(loading.isLoading, isTrue);
      expect(loading.isSuccess, isFalse);
    });

    test('transition from loading to success', () {
      final loading = ResetPasswordState(isVerifying: false, isLoading: true);
      final success = loading.copyWith(isLoading: false, isSuccess: true);
      expect(success.isVerifying, isFalse);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);
      expect(success.errorMessage, isNull);
    });

    test('transition from loading to error', () {
      final loading = ResetPasswordState(isVerifying: false, isLoading: true);
      final error = loading.copyWith(
        isLoading: false,
        errorMessage: 'Reset failed',
      );
      expect(error.isVerifying, isFalse);
      expect(error.isLoading, isFalse);
      expect(error.isSuccess, isFalse);
      expect(error.errorMessage, 'Reset failed');
    });

    test('can retry after error', () {
      final error = ResetPasswordState(
        isVerifying: false,
        errorMessage: 'Previous error',
      );
      final retryLoading = error.copyWith(isLoading: true, errorMessage: null);
      expect(retryLoading.isLoading, isTrue);
      expect(retryLoading.errorMessage, isNull);
    });
  });

  group('ResetPasswordState pattern matching', () {
    test('map works correctly', () {
      final state = ResetPasswordState(isVerifying: false, isSuccess: true);
      final result = state.map((s) => 'mapped-${s.isSuccess}');
      expect(result, 'mapped-true');
    });

    test('maybeMap with orElse', () {
      final state = ResetPasswordState();
      final result = state.maybeMap((s) => 'mapped', orElse: () => 'orElse');
      expect(result, 'mapped');
    });

    test('when works correctly', () {
      final state = ResetPasswordState(
        isVerifying: false,
        isLoading: true,
        isSuccess: false,
        errorMessage: null,
        userEmail: 'test@example.com',
      );
      final result = state.when(
        (isVerifying, isLoading, isSuccess, errorMessage, userEmail) =>
            '$isVerifying-$isLoading-$isSuccess',
      );
      expect(result, 'false-true-false');
    });

    test('whenOrNull returns null when callback is null', () {
      final state = ResetPasswordState();
      final result = state.whenOrNull(null);
      expect(result, isNull);
    });

    test('whenOrNull returns value when callback is provided', () {
      final state = ResetPasswordState(isVerifying: false);
      final result = state.whenOrNull(
        (isVerifying, isLoading, isSuccess, errorMessage, userEmail) =>
            'result',
      );
      expect(result, 'result');
    });
  });
}
