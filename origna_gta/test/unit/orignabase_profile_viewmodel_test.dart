import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/profile/orignabase_profile_viewmodel.dart';
// ---------------------------------------------------------------------------
// Test fakes
// ---------------------------------------------------------------------------

class _FakeAuth implements OrignaBaseAuth {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeOb implements OrignaBase {
  _FakeOb(this.auth);

  @override
  final OrignaBaseAuth auth;

  Map<String, dynamic>? nextResponse;
  Object? nextError;
  String? lastMethod;
  String? lastPath;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastMethod = method;
    lastPath = path;
    if (nextError != null) throw nextError!;
    return nextResponse ?? <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeUserRepo implements UserRepository {
  int updateLangCalls = 0;
  Object? nextError;

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {
    updateLangCalls++;
    if (nextError != null) throw nextError!;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeAuth fakeAuth;
  late _FakeOb fakeOb;
  late _FakeUserRepo fakeUserRepo;
  late _FakeAuthRepository fakeAuthRepo;
  late ProviderContainer container;

  ProviderContainer makeContainer({String? userId}) {
    return ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(fakeOb),
        userRepositoryProvider.overrideWithValue(fakeUserRepo),
        obUserIdProvider.overrideWithValue(userId),
        authActionsProvider.overrideWithValue(AuthActions(fakeAuthRepo)),
      ],
    );
  }

  setUp(() {
    fakeAuth = _FakeAuth();
    fakeOb = _FakeOb(fakeAuth);
    fakeUserRepo = _FakeUserRepo();
    fakeAuthRepo = _FakeAuthRepository();
    container = makeContainer(userId: 'user_123');
    addTearDown(container.dispose);
  });

  group('OrignaBaseProfileViewModel', () {
    test('initial state has no loading/error/success', () {
      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.isDeleted, isFalse);
    });

    test('signOut calls auth.signOut()', () async {
      await container.read(profileViewModelProvider.notifier).signOut();
      expect(fakeAuthRepo.signOutCalls, 1);
    });

    test('updateLanguage does nothing when userId is null', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c.read(profileViewModelProvider.notifier).updateLanguage('fr');

      expect(fakeUserRepo.updateLangCalls, 0);
    });

    test('updateLanguage sets successMessage on success', () async {
      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('fr');

      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(fakeUserRepo.updateLangCalls, 1);
    });

    test('updateLanguage sets errorMessage on failure', () async {
      fakeUserRepo.nextError = Exception('network error');

      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('en');

      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('exportData sets errorMessage when userId is null', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c.read(profileViewModelProvider.notifier).exportData();

      final state = c.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('exportData calls ob.request on success', () async {
      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(fakeOb.lastMethod, 'POST');
    });

    test('exportData sets errorMessage on failure', () async {
      fakeOb.nextError = Exception('server error');

      await container.read(profileViewModelProvider.notifier).exportData();

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('deleteAccount rejects wrong confirmation', () async {
      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('REMOVE');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
    });

    test('deleteAccount sets isDeleted=true on success', () async {
      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('DELETE');

      final state = container.read(profileViewModelProvider);
      expect(state.isDeleted, isTrue);
      expect(state.isLoading, isFalse);
      expect(fakeAuthRepo.signOutCalls, 1);
    });

    test('deleteAccount sets errorMessage when userId is null', () async {
      final c = makeContainer(userId: null);
      addTearDown(c.dispose);

      await c.read(profileViewModelProvider.notifier).deleteAccount('DELETE');

      final state = c.read(profileViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.isDeleted, isFalse);
    });
  });
}
