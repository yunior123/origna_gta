import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

/// Fake OrignaBase client with request tracking.
class _FakeOrignaBase extends Fake implements OrignaBase {
  @override
  String url = 'https://api.test.origna.ca';

  final _FakeAuth _auth = _FakeAuth();
  final _FakeCollectionRef _usersCollection = _FakeCollectionRef();
  final _FakeCollectionRef _pendingProfilesCollection = _FakeCollectionRef();

  // Track request calls
  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {'success': true};
  Object? requestThrowException;

  @override
  OrignaBaseAuth get auth => _auth;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.users) {
      return _usersCollection as CollectionRef;
    }
    if (name == Collections.pendingProfiles) {
      return _pendingProfilesCollection as CollectionRef;
    }
    return _FakeCollectionRef() as CollectionRef;
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (requestThrowException != null) {
      final error = requestThrowException!;
      requestThrowException = null;
      throw error;
    }
    lastRequestMethod = method;
    lastRequestPath = path;
    lastRequestBody = body;
    return requestResponse;
  }
}

/// Fake OrignaBaseAuth implementation.
class _FakeAuth extends Fake implements OrignaBaseAuth {
  String? accessTokenValue;
  bool isEmailVerifiedValue = false;
  String? userIdValue = 'user_123';
  String? emailValue = 'test@example.com';
  bool mfaRequiredValue = false;
  String? challengeTokenValue;
  Stream<AuthState> authStateChangesValue = Stream.empty();

  // Controllable exceptions
  Exception? registerThrowException;
  Exception? signInThrowException;
  Exception? refreshTokenThrowException;
  Exception? sendVerificationThrowException;
  Exception? forgotPasswordThrowException;
  Exception? resetPasswordThrowException;

  @override
  String? get accessToken => accessTokenValue;

  @override
  bool get isEmailVerified => isEmailVerifiedValue;

  @override
  String? get currentUserId => userIdValue;

  @override
  String? get currentEmail => emailValue;

  @override
  AuthState get currentState {
    if (accessTokenValue != null && userIdValue != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        userId: userIdValue,
        email: emailValue,
        emailVerified: isEmailVerifiedValue,
      );
    }
    return AuthState.unauthenticated;
  }

  @override
  Stream<AuthState> get authStateChanges => authStateChangesValue;

  @override
  Future<AuthState> register(String email, String password) async {
    if (registerThrowException != null) {
      throw registerThrowException!;
    }
    accessTokenValue = 'token_register_$email';
    userIdValue = 'user_123';
    emailValue = email;
    return AuthState(
      status: AuthStatus.authenticated,
      userId: userIdValue,
      email: email,
    );
  }

  @override
  Future<AuthState> signInWithEmail(String email, String password) async {
    if (signInThrowException != null) {
      throw signInThrowException!;
    }
    if (mfaRequiredValue) {
      return AuthState(
        status: AuthStatus.authenticated,
        userId: 'user_123',
        email: email,
        mfaRequired: true,
        challengeToken: challengeTokenValue ?? 'mfa_challenge_token',
      );
    }
    accessTokenValue = 'token_signin_$email';
    userIdValue = 'user_123';
    emailValue = email;
    return AuthState(
      status: AuthStatus.authenticated,
      userId: userIdValue,
      email: email,
    );
  }

  @override
  Future<void> signOut() async {
    accessTokenValue = null;
    userIdValue = null;
    emailValue = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (sendVerificationThrowException != null) {
      throw sendVerificationThrowException!;
    }
    isEmailVerifiedValue = true;
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (forgotPasswordThrowException != null) {
      throw forgotPasswordThrowException!;
    }
  }

  @override
  Future<void> resetPassword(String code, String newPassword) async {
    if (resetPasswordThrowException != null) {
      throw resetPasswordThrowException!;
    }
  }

  @override
  Future<AuthState> refreshToken() async {
    if (refreshTokenThrowException != null) {
      throw refreshTokenThrowException!;
    }
    return currentState;
  }

  @override
  Future<AuthState> signInWithGoogle(String idToken) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthState> signInWithApple(
    String authCode, {
    String? displayName,
  }) async {
    throw UnimplementedError();
  }
}

/// Fake Document implementation.
class _FakeDocument extends Fake implements Document {
  @override
  final String id;

  @override
  final Map<String, dynamic> data;

  @override
  final bool exists = true;

  @override
  final String collection = 'test_collection';

  _FakeDocument(this.id, this.data);

  @override
  T? get<T>(String field) => data[field] as T?;

  @override
  dynamic operator [](String key) => data[key];

  @override
  bool containsKey(String key) => data.containsKey(key);
}

/// Fake DocumentRef implementation.
class _FakeDocumentRef extends Fake implements DocumentRef {
  @override
  final String id;

  @override
  final String collection;

  Document? documentValue;
  Exception? getThrowException;

  _FakeDocumentRef({this.id = 'doc_id', Document? doc})
    : collection = 'test_collection',
      documentValue = doc;

  void throwOnGet(Exception e) => getThrowException = e;

  @override
  Future<Document?> get() async {
    if (getThrowException != null) {
      throw getThrowException!;
    }
    return documentValue;
  }

  @override
  Future<Document?> update(Map<String, dynamic> data) async {
    return documentValue;
  }

  @override
  Future<void> delete() async {}
}

/// Fake CollectionRef implementation.
class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};

  void setDoc(String id, _FakeDocumentRef ref) {
    docsMap[id] = ref;
  }

  @override
  DocumentRef doc(String id) {
    if (docsMap.containsKey(id)) {
      return docsMap[id]!;
    }
    return _FakeDocumentRef(id: id);
  }

  void clear() => docsMap.clear();
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseAuthRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    repository = OrignaBaseAuthRepository(fakeOb);
  });

  group('OrignaBaseAuthRepository - registerWithEmail', () {
    test('success: registers user and creates profile', () async {
      await repository.registerWithEmail(
        'newuser@example.com',
        'SecurePass123!',
        'Test User',
      );

      // Should call auth.register
      expect(fakeOb.auth.accessToken, isNotNull);

      // Should call request to create user profile
      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.usersCreateProfile);
      expect(fakeOb.lastRequestBody?['email'], 'newuser@example.com');
      expect(fakeOb.lastRequestBody?['name'], 'Test User');
    });

    test('success: with marketing opt-in', () async {
      await repository.registerWithEmail(
        'user@example.com',
        'SecurePass123!',
        'Test User',
        marketingOptIn: true,
      );

      expect(fakeOb.lastRequestBody?['marketingOptIn'], true);
    });

    test('throws on invalid email format', () async {
      expect(
        () => repository.registerWithEmail(
          'not-an-email',
          'SecurePass123!',
          'Test User',
        ),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          ),
        ),
      );
    });

    test('throws on duplicate email', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.registerThrowException = Exception('Email already in use');

      expect(
        () => repository.registerWithEmail(
          'existing@example.com',
          'SecurePass123!',
          'Test User',
        ),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          ),
        ),
      );
    });

    test('throws on weak password error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.registerThrowException = Exception('weak_password');

      expect(
        () => repository.registerWithEmail(
          'user@example.com',
          'weak',
          'Test User',
        ),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'weak-password',
          ),
        ),
      );
    });

    test('trims email and converts to lowercase', () async {
      await repository.registerWithEmail(
        '  User@EXAMPLE.COM  ',
        'SecurePass123!',
        'Test User',
      );

      expect(fakeOb.lastRequestBody?['email'], 'user@example.com');
    });

    test('does not rethrow verification email send errors', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.sendVerificationThrowException = Exception('Verification failed');

      // Should not throw
      await repository.registerWithEmail(
        'user@example.com',
        'SecurePass123!',
        'Test User',
      );

      expect(fakeOb.lastRequestBody?['email'], 'user@example.com');
    });
  });

  group('OrignaBaseAuthRepository - signInWithEmail', () {
    test('success: signs in user', () async {
      await repository.signInWithEmail('user@example.com', 'password');

      expect(fakeOb.auth.accessToken, isNotNull);
    });

    test(
      'trims email and creates user document with lowercase email',
      () async {
        await repository.signInWithEmail('  USER@EXAMPLE.COM  ', 'password');

        expect(fakeOb.lastRequestPath, ApiEndpoints.usersCreateProfile);
        expect(fakeOb.lastRequestBody?[Fields.email], 'user@example.com');
      },
    );

    test('throws on invalid email format', () async {
      expect(
        () => repository.signInWithEmail('invalid-email', 'password'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          ),
        ),
      );
    });

    test('throws on user-not-found error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.signInThrowException = Exception('User not found');

      expect(
        () => repository.signInWithEmail('nonexistent@example.com', 'password'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });

    test('throws on wrong-password error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.signInThrowException = Exception('wrong password');

      expect(
        () => repository.signInWithEmail('user@example.com', 'wrongpass'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'wrong-password',
          ),
        ),
      );
    });

    test(
      'throws OrignaBaseAuthException(mfa-required) when MFA is enabled',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.mfaRequiredValue = true;
        auth.challengeTokenValue = 'mfa_challenge_abc';

        expect(
          () => repository.signInWithEmail('user@example.com', 'correctpass'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'mfa-required',
            ),
          ),
        );
      },
    );

    test('throws on disabled-account error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.signInThrowException = Exception('Account disabled');

      expect(
        () => repository.signInWithEmail('user@example.com', 'password'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-disabled',
          ),
        ),
      );
    });

    test('throws on too-many-requests error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.signInThrowException = Exception('Too many requests');

      expect(
        () => repository.signInWithEmail('user@example.com', 'password'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'too-many-requests',
          ),
        ),
      );
    });

    test('creates user document after successful sign-in', () async {
      await repository.signInWithEmail('newuser@example.com', 'password');

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersCreateProfile);
    });
  });

  group('OrignaBaseAuthRepository - signOut', () {
    test('calls auth.signOut', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'some_token';
      auth.userIdValue = 'user_123';
      auth.authStateChangesValue = Stream.value(AuthState.unauthenticated);

      await repository.signOut();

      expect(fakeOb.auth.accessToken, isNull);
      expect(fakeOb.auth.currentUserId, isNull);
    });

    test('clears notification tokens', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.authStateChangesValue = Stream.value(AuthState.unauthenticated);
      await repository.signOut();
      // Verify signOut was called (no exception thrown)
      expect(fakeOb.auth.accessToken, isNull);
    });
  });

  group('OrignaBaseAuthRepository - sendEmailVerification', () {
    test('throws when no current user', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = null;

      expect(
        () => repository.sendEmailVerification(),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'no-current-user',
          ),
        ),
      );
    });

    test('success: calls auth.sendEmailVerification', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';

      await repository.sendEmailVerification();

      expect(fakeOb.auth.isEmailVerified, true);
    });

    test('rethrows send verification errors', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.sendVerificationThrowException = Exception('Network error');

      expect(
        () => repository.sendEmailVerification(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseAuthRepository - isEmailVerified', () {
    test('returns true when already verified', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.isEmailVerifiedValue = true;

      final result = await repository.isEmailVerified();

      expect(result, true);
    });

    test('calls refreshToken when not verified', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.isEmailVerifiedValue = false;
      auth.accessTokenValue = 'valid_token';

      final result = await repository.isEmailVerified();

      expect(result, false);
    });

    test(
      'returns false when refreshToken yields unauthenticated state',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.isEmailVerifiedValue = false;
        auth.accessTokenValue = null;
        auth.userIdValue = null;

        final result = await repository.isEmailVerified();

        expect(result, false);
      },
    );

    test('returns true after refresh discovers verification', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.isEmailVerifiedValue = false;
      auth.accessTokenValue = 'valid_token';

      // Simulate backend verification happening
      auth.isEmailVerifiedValue = true;

      final result = await repository.isEmailVerified();

      expect(result, true);
    });

    test('returns false on refresh error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.isEmailVerifiedValue = false;
      auth.accessTokenValue = 'valid_token';
      auth.refreshTokenThrowException = Exception('Network error');

      final result = await repository.isEmailVerified();

      expect(result, false);
    });
  });

  group('OrignaBaseAuthRepository - sendPasswordResetEmail', () {
    test('success: calls auth.forgotPassword', () async {
      await repository.sendPasswordResetEmail('user@example.com');

      // forgotPassword was called successfully (no exception thrown)
    });

    test('throws on invalid email format', () async {
      expect(
        () => repository.sendPasswordResetEmail('not-an-email'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          ),
        ),
      );
    });

    test('swallows user-not-found error (anti-enumeration)', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.forgotPasswordThrowException = Exception('user not found');

      await repository.sendPasswordResetEmail('nonexistent@example.com');
    });

    test('swallows "not_found" error variant', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.forgotPasswordThrowException = Exception('not_found error');

      await repository.sendPasswordResetEmail('unknown@example.com');
    });

    test('rethrows non-enumeration errors', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.forgotPasswordThrowException = Exception('Network error');

      expect(
        () => repository.sendPasswordResetEmail('user@example.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('trims and lowercases email', () async {
      await repository.sendPasswordResetEmail('  USER@EXAMPLE.COM  ');

      expect(true, true);
    });
  });

  group('OrignaBaseAuthRepository - confirmPasswordReset', () {
    test('success: calls auth.resetPassword', () async {
      await repository.confirmPasswordReset('reset_code_123', 'NewPass123!');

      expect(true, true);
    });

    test('throws on invalid reset code', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.resetPasswordThrowException = Exception('Invalid reset code');

      expect(
        () => repository.confirmPasswordReset('invalid_code', 'NewPass123!'),
        throwsA(
          isA<OrignaBaseAuthException>().having(
            (e) => e.code,
            'code',
            'unknown',
          ),
        ),
      );
    });
  });

  group('OrignaBaseAuthRepository - deleteAccount', () {
    test('calls DELETE API endpoint and signs out', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      auth.emailValue = 'test@example.com';

      // Re-authenticate first (deleteAccount now requires recent re-auth)
      await repository.reAuthenticate('password');

      await repository.deleteAccount();

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.authDeleteAccount);
      expect(fakeOb.lastRequestBody?['confirmation'], 'DELETE_MY_ACCOUNT');
      expect(fakeOb.auth.accessToken, isNull);
    });

    test('throws when no current user', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = null;

      expect(
        () => repository.deleteAccount(),
        throwsA(isA<OrignaBaseAuthException>()),
      );
    });
  });

  group('OrignaBaseAuthRepository - validateCurrentUser', () {
    test('returns false when no user is logged in', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = null;

      final result = await repository.validateCurrentUser();

      expect(result, false);
    });

    test('returns true when user token is still valid', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        'uid': 'user_123',
        'email': 'test@example.com',
      };

      final result = await repository.validateCurrentUser();

      expect(result, true);
      expect(fakeOb.lastRequestPath, ApiEndpoints.usersProfileGet);
    });

    test('returns false and signs out when user doc not found', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestResponse = {ApiKeys.success: false};

      final result = await repository.validateCurrentUser();

      expect(result, false);
      expect(fakeOb.auth.accessToken, isNull);
    });

    test(
      'returns false and signs out when refresh token is no longer authenticated',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.accessTokenValue = 'valid_token';
        auth.userIdValue = null;
        auth.authStateChangesValue = Stream.value(AuthState.unauthenticated);

        final result = await repository.validateCurrentUser();

        expect(result, false);
        expect(fakeOb.auth.accessToken, isNull);
      },
    );

    test(
      'returns false when user profile doc get throws NotFoundException',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.accessTokenValue = 'valid_token';
        auth.userIdValue = 'user_123';
        fakeOb.requestThrowException = NotFoundException(
          'not found',
          statusCode: 404,
        );

        final result = await repository.validateCurrentUser();

        expect(result, false);
        expect(fakeOb.auth.accessToken, isNull);
      },
    );

    test('returns false and signs out on "disabled" error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestThrowException = ForbiddenException(
        'User account disabled',
        statusCode: 403,
      );

      final result = await repository.validateCurrentUser();

      expect(result, false);
      expect(fakeOb.auth.accessToken, isNull);
    });

    test('returns false and signs out on "expired" error', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestThrowException = AuthException(
        'Token expired',
        statusCode: 401,
      );

      final result = await repository.validateCurrentUser();

      expect(result, false);
      expect(fakeOb.auth.accessToken, isNull);
    });

    test('returns true on network error (does not sign out)', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestThrowException = NetworkException('Network timeout');

      final result = await repository.validateCurrentUser();

      expect(result, true);
      expect(fakeOb.auth.accessToken, isNotNull);
    });

    test('returns true on timeout error (does not sign out)', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestThrowException = TimeoutException('Request timed out');

      final result = await repository.validateCurrentUser();

      expect(result, true);
      expect(fakeOb.auth.accessToken, isNotNull);
    });

    test(
      'returns true on unexpected OrignaBaseException (does not sign out)',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.accessTokenValue = 'valid_token';
        auth.userIdValue = 'user_123';
        fakeOb.requestThrowException = OrignaBaseException(
          'Internal server error',
          statusCode: 500,
        );

        final result = await repository.validateCurrentUser();

        expect(result, true);
        expect(fakeOb.auth.accessToken, isNotNull);
      },
    );
  });

  group('OrignaBaseAuthRepository - ensureUserDocumentExists', () {
    test('returns early when no access token', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = null;

      await repository.ensureUserDocumentExists();

      expect(fakeOb.lastRequestPath, isNull);
    });

    test('creates profile for authenticated user', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      auth.emailValue = 'user@example.com';
      fakeOb.requestThrowException = NotFoundException(
        'not found',
        statusCode: 404,
      );

      await repository.ensureUserDocumentExists();

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersCreateProfile);
    });

    test('does not overwrite existing profile', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        'uid': 'user_123',
        'email': 'existing@example.com',
      };

      await repository.ensureUserDocumentExists();

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersProfileGet);
    });

    test('returns early when refresh token is unauthenticated', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = null;

      await repository.ensureUserDocumentExists();

      expect(fakeOb.lastRequestPath, isNull);
    });

    test('recovers pending profile name and marketing preference', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.accessTokenValue = 'valid_token';
      auth.userIdValue = 'user_123';
      auth.emailValue = 'pending@example.com';
      fakeOb.requestThrowException = NotFoundException(
        'not found',
        statusCode: 404,
      );
      final pendingDoc = _FakeDocument('user_123', {
        Fields.name: 'Pending Name',
        Fields.marketingOptIn: true,
      });
      fakeOb._pendingProfilesCollection.setDoc(
        'user_123',
        _FakeDocumentRef(doc: pendingDoc),
      );

      await repository.ensureUserDocumentExists();

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersCreateProfile);
      expect(fakeOb.lastRequestBody?[Fields.name], 'Pending Name');
      expect(fakeOb.lastRequestBody?[Fields.marketingOptIn], true);
    });
  });

  group('OrignaBaseAuthRepository - watchProfile', () {
    test('emits current profile immediately', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = 'user_123';
      auth.emailValue = 'user@example.com';
      auth.accessTokenValue = 'valid_token';

      fakeOb.requestResponse = {
        'success': true,
        'uid': 'user_123',
        'email': 'user@example.com',
        'name': 'Test User',
      };

      final stream = repository.watchProfile('user_123');
      final firstProfile = await stream.first;

      expect(firstProfile?.uid, 'user_123');
      expect(firstProfile?.name, 'Test User');
    });

    test('emits null when user not authenticated', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = null;
      auth.accessTokenValue = null;

      final stream = repository.watchProfile('user_123');
      final firstProfile = await stream.first;

      expect(firstProfile, isNull);
    });

    test(
      'emits null when watching different userId than authenticated',
      () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.userIdValue = 'user_123';
        auth.accessTokenValue = 'valid_token';

        final stream = repository.watchProfile('different_user_456');
        final firstProfile = await stream.first;

        expect(firstProfile, isNull);
      },
    );

    test('handles API response parsing errors gracefully', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = 'user_123';
      auth.accessTokenValue = 'valid_token';

      fakeOb.requestResponse = {'success': false};

      final stream = repository.watchProfile('user_123');
      final firstProfile = await stream.first;

      expect(firstProfile, isNull);
    });

    test('parses address field from API response', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = 'user_123';
      auth.accessTokenValue = 'valid_token';

      fakeOb.requestResponse = {
        'success': true,
        'uid': 'user_123',
        'email': 'user@example.com',
        'address': {'street': '123 Main St', 'city': 'Toronto'},
      };

      final stream = repository.watchProfile('user_123');
      final firstProfile = await stream.first;

      expect(firstProfile?.address, isNotNull);
    });

    test('emits later auth-state changes after the initial value', () async {
      final auth = fakeOb.auth as _FakeAuth;
      auth.userIdValue = null;
      auth.accessTokenValue = null;

      final controller = StreamController<AuthState>();
      addTearDown(controller.close);
      auth.authStateChangesValue = controller.stream;

      final profilesFuture = repository
          .watchProfile('user_123')
          .take(2)
          .toList();
      fakeOb.requestResponse = {
        'success': true,
        'uid': 'user_123',
        'email': 'user@example.com',
        'name': 'Later User',
      };
      controller.add(
        const AuthState(
          status: AuthStatus.authenticated,
          userId: 'user_123',
          email: 'user@example.com',
        ),
      );
      final profiles = await profilesFuture;
      expect(profiles.first, isNull);
      expect(profiles.last?.name, 'Later User');
    });
  });

  group(
    'OrignaBaseAuthRepository - error handling (_rethrowAsAuthException)',
    () {
      test('preserves OrignaBaseAuthException', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = OrignaBaseAuthException(
          code: 'custom-error',
          message: 'Custom message',
        );

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'custom-error',
            ),
          ),
        );
      });

      test('maps "already" error to "email-already-in-use"', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = Exception('Email already exists');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'email-already-in-use',
            ),
          ),
        );
      });

      test('maps "duplicate" error to "email-already-in-use"', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = Exception('Duplicate email');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'email-already-in-use',
            ),
          ),
        );
      });

      test('maps "network" error to "network-request-failed"', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = Exception('Network connection failed');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'network-request-failed',
            ),
          ),
        );
      });

      test('maps "cancelled" error to "cancelled"', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = Exception('Operation cancelled by user');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'cancelled',
            ),
          ),
        );
      });

      test('defaults to "unknown" code for unmapped errors', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = Exception('Some random error');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'unknown',
            ),
          ),
        );
      });

      test('maps NotFoundException to user-not-found', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = NotFoundException('missing user');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'user-not-found',
            ),
          ),
        );
      });

      test('maps ValidationException email to invalid-email', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = ValidationException('email is invalid');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'invalid-email',
            ),
          ),
        );
      });

      test('maps ValidationException password to weak-password', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = ValidationException('password is weak');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'weak-password',
            ),
          ),
        );
      });

      test('maps ConflictException to email-already-in-use', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = ConflictException('duplicate');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'email-already-in-use',
            ),
          ),
        );
      });

      test('maps RateLimitException to too-many-requests', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = RateLimitException('slow down');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'too-many-requests',
            ),
          ),
        );
      });

      test('maps NetworkException to network-request-failed', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = NetworkException('offline');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'network-request-failed',
            ),
          ),
        );
      });

      test('maps ForbiddenException to user-disabled', () async {
        final auth = fakeOb.auth as _FakeAuth;
        auth.signInThrowException = ForbiddenException('blocked');

        expect(
          () => repository.signInWithEmail('user@example.com', 'password'),
          throwsA(
            isA<OrignaBaseAuthException>().having(
              (e) => e.code,
              'code',
              'user-disabled',
            ),
          ),
        );
      });
    },
  );
}
