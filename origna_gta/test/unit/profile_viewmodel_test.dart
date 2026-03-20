import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/profile/profile_viewmodel.dart';

class TestOrignaBaseAuth implements OrignaBaseAuth {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestOrignaBase implements OrignaBase {
  TestOrignaBase(this.auth);

  @override
  final OrignaBaseAuth auth;

  int requestCalls = 0;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Future<Map<String, dynamic>> Function(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  })?
  onRequest;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    requestCalls += 1;
    lastMethod = method;
    lastPath = path;
    lastBody = body;
    return onRequest?.call(method, path, body: body, headers: headers) ??
        <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestUserRepository implements UserRepository {
  int updatePreferredLanguageCalls = 0;
  String? lastUserId;
  String? lastLang;

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {
    updatePreferredLanguageCalls += 1;
    lastUserId = userId;
    lastLang = lang;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestOrignaBaseAuth auth;
  late TestOrignaBase orignaBase;
  late TestUserRepository userRepo;
  late ProviderContainer container;

  setUp(() {
    auth = TestOrignaBaseAuth();
    orignaBase = TestOrignaBase(auth);
    userRepo = TestUserRepository();
    container = ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(orignaBase),
        userRepositoryProvider.overrideWithValue(userRepo),
        obUserIdProvider.overrideWithValue('user_123'),
      ],
    );
  });

  group('ProfileViewModel Tests', () {
    test('signOut calls OrignaBase auth', () async {
      await container.read(profileViewModelProvider.notifier).signOut();

      expect(auth.signOutCalls, 1);
    });

    test('updateLanguage calls repository', () async {
      await container
          .read(profileViewModelProvider.notifier)
          .updateLanguage('fr');

      expect(userRepo.updatePreferredLanguageCalls, 1);
      expect(userRepo.lastUserId, 'user_123');
      expect(userRepo.lastLang, 'fr');
    });

    test('deleteAccount requires confirmation', () async {
      await container
          .read(profileViewModelProvider.notifier)
          .deleteAccount('WRONG');

      final state = container.read(profileViewModelProvider);
      expect(state.errorMessage, contains('DELETE'));
      expect(orignaBase.requestCalls, 0);
      expect(auth.signOutCalls, 0);
    });

    test(
      'deleteAccount calls OrignaBase API and signs out on correct confirmation',
      () async {
        await container
            .read(profileViewModelProvider.notifier)
            .deleteAccount('DELETE');

        expect(orignaBase.requestCalls, 1);
        expect(orignaBase.lastMethod, 'POST');
        expect(orignaBase.lastPath, '/api/auth/delete-account');
        expect(orignaBase.lastBody, <String, dynamic>{
          'userId': 'user_123',
          'confirmation': 'DELETE_MY_ACCOUNT',
        });
        expect(auth.signOutCalls, 1);
      },
    );
  });
}
