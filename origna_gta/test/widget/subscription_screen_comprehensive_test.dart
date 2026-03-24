import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/features/subscription/subscription_state.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/models/models.dart';
import '../test_utils.dart';

class FakeAuthRepositoryForSub implements AuthRepository {
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    // FakeAuthRepositoryForSub available if needed for provider overrides
  });

  group('SubscriptionInfo', () {
    test('default values', () {
      const info = SubscriptionInfo(status: 'inactive', isPremium: false);

      expect(info.status, 'inactive');
      expect(info.isPremium, isFalse);
      expect(info.currentPeriodEnd, isNull);
      expect(info.cancelAtPeriodEnd, isFalse);
    });

    test('with all fields', () {
      final endDate = DateTime(2026, 6, 1);
      final info = SubscriptionInfo(
        status: 'active',
        isPremium: true,
        currentPeriodEnd: endDate,
        cancelAtPeriodEnd: true,
      );

      expect(info.status, 'active');
      expect(info.isPremium, isTrue);
      expect(info.currentPeriodEnd, endDate);
      expect(info.cancelAtPeriodEnd, isTrue);
    });

    test('fromMap with valid data', () {
      final info = SubscriptionInfo.fromMap({
        'status': 'active',
        'currentPeriodEnd': '2026-06-01T00:00:00.000Z',
        'cancelAtPeriodEnd': false,
      });

      expect(info.status, 'active');
      expect(info.isPremium, isTrue);
      expect(info.currentPeriodEnd, isNotNull);
      expect(info.cancelAtPeriodEnd, isFalse);
    });

    test('fromMap with missing fields uses defaults', () {
      final info = SubscriptionInfo.fromMap({});

      expect(info.status, 'inactive');
      expect(info.isPremium, isFalse);
      expect(info.currentPeriodEnd, isNull);
      expect(info.cancelAtPeriodEnd, isFalse);
    });

    test('fromMap with cancelAtPeriodEnd true', () {
      final info = SubscriptionInfo.fromMap({
        'status': 'active',
        'cancelAtPeriodEnd': true,
      });

      expect(info.cancelAtPeriodEnd, isTrue);
      expect(info.isPremium, isTrue);
    });
  });

  group('SubscriptionState', () {
    test('default state', () {
      const state = SubscriptionState();
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.checkoutUrl, isNull);
    });

    test('copyWith works', () {
      const state = SubscriptionState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);

      final withError = state.copyWith(errorMessage: 'Failed');
      expect(withError.errorMessage, 'Failed');

      final withUrl = state.copyWith(checkoutUrl: 'https://checkout.test');
      expect(withUrl.checkoutUrl, 'https://checkout.test');
    });
  });
}
