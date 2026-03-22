import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/auth/login_state.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/features/auth/mfa_viewmodel.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>(), MockSpec<OrignaBaseAuth>()])
import 'mfa_viewmodel_test.mocks.dart';

// =============================================================================
// HELPERS
// =============================================================================

UserModel _makeUser({bool mfaEnabled = false}) {
  return UserModel(
    uid: 'user_123',
    email: 'test@example.com',
    name: 'Test User',
    roles: const [UserRole.buyer],
    createdAt: DateTime(2026),
    mfaEnabled: mfaEnabled,
  );
}

ProviderContainer _createContainer({
  required MockOrignaBase mockOb,
  UserModel? userProfile,
}) {
  return ProviderContainer(
    overrides: [
      orignabaseProvider.overrideWithValue(mockOb),
      if (userProfile != null)
        userProfileProvider.overrideWith(
          (ref) => Stream.value(userProfile).asBroadcastStream(),
        )
      else
        userProfileProvider.overrideWith(
          (ref) => Stream.value(null).asBroadcastStream(),
        ),
    ],
  );
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  late MockOrignaBase mockOb;
  late MockOrignaBaseAuth mockAuth;

  setUp(() {
    mockOb = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();
    when(mockOb.auth).thenReturn(mockAuth);
  });

  // ---------------------------------------------------------------------------
  // 1. Initial state
  // ---------------------------------------------------------------------------
  group('MfaState defaults', () {
    test('initial state has correct defaults', () {
      final state = MfaState();
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.currentStep, 0);
      expect(state.qrCodeBase64, isNull);
      expect(state.manualKey, isNull);
      expect(state.appleOtpauthUrl, isNull);
      expect(state.recoveryCodes, isEmpty);
      expect(state.mfaEnabled, isFalse);
      expect(state.codesSaved, isFalse);
    });

    test('copyWith preserves unmodified fields', () {
      final original = MfaState(
        isLoading: true,
        currentStep: 2,
        qrCodeBase64: 'qr',
        manualKey: 'key',
        mfaEnabled: true,
      );
      final updated = original.copyWith(currentStep: 3);
      expect(updated.isLoading, isTrue);
      expect(updated.currentStep, 3);
      expect(updated.qrCodeBase64, 'qr');
      expect(updated.manualKey, 'key');
      expect(updated.mfaEnabled, isTrue);
    });

    test('copyWith can set nullable fields to null', () {
      final state = MfaState(
        errorMessage: 'err',
        qrCodeBase64: 'qr',
        manualKey: 'key',
        appleOtpauthUrl: 'url',
      );
      final cleared = state.copyWith(
        errorMessage: null,
        qrCodeBase64: null,
        manualKey: null,
        appleOtpauthUrl: null,
      );
      expect(cleared.errorMessage, isNull);
      expect(cleared.qrCodeBase64, isNull);
      expect(cleared.manualKey, isNull);
      expect(cleared.appleOtpauthUrl, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. checkStatus()
  // ---------------------------------------------------------------------------
  group('checkStatus', () {
    test('sets mfaEnabled=true when userProfile has mfaEnabled=true', () async {
      final container = _createContainer(
        mockOb: mockOb,
        userProfile: _makeUser(mfaEnabled: true),
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final vm = container.read(mfaViewModelProvider.notifier);
      vm.checkStatus();

      expect(container.read(mfaViewModelProvider).mfaEnabled, isTrue);
    });

    test(
      'sets mfaEnabled=false when userProfile has mfaEnabled=false',
      () async {
        final container = _createContainer(
          mockOb: mockOb,
          userProfile: _makeUser(mfaEnabled: false),
        );
        addTearDown(container.dispose);

        container.listen(userProfileProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        final vm = container.read(mfaViewModelProvider.notifier);
        vm.checkStatus();

        expect(container.read(mfaViewModelProvider).mfaEnabled, isFalse);
      },
    );

    test('does nothing when userProfile is null', () async {
      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final vm = container.read(mfaViewModelProvider.notifier);
      vm.checkStatus();

      // Remains at default false since profile was null.
      expect(container.read(mfaViewModelProvider).mfaEnabled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. startSetup() success
  // ---------------------------------------------------------------------------
  group('startSetup', () {
    test(
      'success sets step=1, qrCodeBase64, manualKey, appleOtpauthUrl',
      () async {
        when(mockAuth.setupMfa()).thenAnswer(
          (_) async => MfaSetupResult(
            qrCodeBase64: 'testQrData',
            manualKey: 'JBSWY3DPEHPK3PXP',
            appleOtpauthUrl: 'otpauth://totp/test',
          ),
        );

        final container = _createContainer(mockOb: mockOb);
        addTearDown(container.dispose);

        final vm = container.read(mfaViewModelProvider.notifier);
        await vm.startSetup();

        final state = container.read(mfaViewModelProvider);
        expect(state.isLoading, isFalse);
        expect(state.currentStep, 1);
        expect(state.qrCodeBase64, 'testQrData');
        expect(state.manualKey, 'JBSWY3DPEHPK3PXP');
        expect(state.appleOtpauthUrl, 'otpauth://totp/test');
        expect(state.errorMessage, isNull);
      },
    );

    test('success with null appleOtpauthUrl', () async {
      when(mockAuth.setupMfa()).thenAnswer(
        (_) async => MfaSetupResult(qrCodeBase64: 'qr', manualKey: 'key'),
      );

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.startSetup();

      final state = container.read(mfaViewModelProvider);
      expect(state.currentStep, 1);
      expect(state.appleOtpauthUrl, isNull);
    });

    // -------------------------------------------------------------------------
    // 4. startSetup() failure
    // -------------------------------------------------------------------------
    test('failure sets errorMessage and stays on current step', () async {
      when(mockAuth.setupMfa()).thenThrow(Exception('Server error'));

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.startSetup();

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.currentStep, 0);
      expect(state.qrCodeBase64, isNull);
    });

    test('failure with OrignaBaseException sets errorMessage', () async {
      when(
        mockAuth.setupMfa(),
      ).thenThrow(OrignaBaseException('Auth required', statusCode: 401));

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.startSetup();

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.currentStep, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. verifySetup() success
  // ---------------------------------------------------------------------------
  group('verifySetup', () {
    test(
      'success sets step=3, recoveryCodes populated, mfaEnabled=true',
      () async {
        final recoveryCodes = ['ABCD-1234', 'EFGH-5678', 'IJKL-9012'];
        when(
          mockAuth.verifyMfaSetup(any),
        ).thenAnswer((_) async => recoveryCodes);

        final container = _createContainer(mockOb: mockOb);
        addTearDown(container.dispose);

        final vm = container.read(mfaViewModelProvider.notifier);
        await vm.verifySetup('123456');

        final state = container.read(mfaViewModelProvider);
        expect(state.isLoading, isFalse);
        expect(state.currentStep, 3);
        expect(state.recoveryCodes, recoveryCodes);
        expect(state.mfaEnabled, isTrue);
        expect(state.errorMessage, isNull);
      },
    );

    test('success with empty recovery codes list', () async {
      when(mockAuth.verifyMfaSetup(any)).thenAnswer((_) async => <String>[]);

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.verifySetup('123456');

      final state = container.read(mfaViewModelProvider);
      expect(state.currentStep, 3);
      expect(state.recoveryCodes, isEmpty);
      expect(state.mfaEnabled, isTrue);
    });

    // -------------------------------------------------------------------------
    // 6. verifySetup() failure
    // -------------------------------------------------------------------------
    test('failure sets errorMessage and stays on current step', () async {
      // First set up successfully to get to step 1.
      when(mockAuth.setupMfa()).thenAnswer(
        (_) async => MfaSetupResult(qrCodeBase64: 'qr', manualKey: 'key'),
      );

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.startSetup();
      expect(container.read(mfaViewModelProvider).currentStep, 1);

      // Now fail verification.
      when(
        mockAuth.verifyMfaSetup(any),
      ).thenThrow(Exception('Invalid TOTP code'));
      await vm.verifySetup('000000');

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.currentStep, 1); // Did not advance.
      expect(state.mfaEnabled, isFalse);
    });

    test('failure with OrignaBaseException preserves step', () async {
      when(
        mockAuth.verifyMfaSetup(any),
      ).thenThrow(OrignaBaseException('Code expired', statusCode: 400));

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      vm.goToStep(2); // Simulate being on verify step.
      await vm.verifySetup('999999');

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.currentStep, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. confirmSaved()
  // ---------------------------------------------------------------------------
  group('confirmSaved', () {
    test('sets codesSaved=true and step=4', () {
      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      vm.confirmSaved();

      final state = container.read(mfaViewModelProvider);
      expect(state.codesSaved, isTrue);
      expect(state.currentStep, 4);
    });

    test('preserves other state fields', () async {
      when(
        mockAuth.verifyMfaSetup(any),
      ).thenAnswer((_) async => ['RC1', 'RC2']);

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      await vm.verifySetup('123456');
      vm.confirmSaved();

      final state = container.read(mfaViewModelProvider);
      expect(state.codesSaved, isTrue);
      expect(state.currentStep, 4);
      expect(state.mfaEnabled, isTrue);
      expect(state.recoveryCodes, ['RC1', 'RC2']);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. goToStep()
  // ---------------------------------------------------------------------------
  group('goToStep', () {
    test('changes currentStep to specified value', () {
      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      vm.goToStep(1);
      expect(container.read(mfaViewModelProvider).currentStep, 1);

      vm.goToStep(2);
      expect(container.read(mfaViewModelProvider).currentStep, 2);

      vm.goToStep(0);
      expect(container.read(mfaViewModelProvider).currentStep, 0);
    });

    test('does not affect other state fields', () {
      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);
      vm.goToStep(3);

      final state = container.read(mfaViewModelProvider);
      expect(state.currentStep, 3);
      expect(state.isLoading, isFalse);
      expect(state.mfaEnabled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. disable() success
  // ---------------------------------------------------------------------------
  group('disable', () {
    test('success resets all state, mfaEnabled=false', () async {
      when(mockAuth.setupMfa()).thenAnswer(
        (_) async => MfaSetupResult(
          qrCodeBase64: 'qr',
          manualKey: 'key',
          appleOtpauthUrl: 'url',
        ),
      );
      when(mockAuth.verifyMfaSetup(any)).thenAnswer((_) async => ['RC1']);
      when(mockAuth.disableMfa(any)).thenAnswer((_) async {});

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      // Set up MFA fully.
      await vm.startSetup();
      await vm.verifySetup('123456');
      vm.confirmSaved();

      expect(container.read(mfaViewModelProvider).mfaEnabled, isTrue);
      expect(container.read(mfaViewModelProvider).codesSaved, isTrue);

      // Disable MFA.
      await vm.disable('654321');

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.mfaEnabled, isFalse);
      expect(state.currentStep, 0);
      expect(state.qrCodeBase64, isNull);
      expect(state.manualKey, isNull);
      expect(state.appleOtpauthUrl, isNull);
      expect(state.recoveryCodes, isEmpty);
      expect(state.codesSaved, isFalse);
      expect(state.errorMessage, isNull);
    });

    // -------------------------------------------------------------------------
    // 10. disable() failure
    // -------------------------------------------------------------------------
    test('failure sets errorMessage and mfaEnabled stays true', () async {
      when(mockAuth.verifyMfaSetup(any)).thenAnswer((_) async => ['RC1']);

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      // Simulate MFA enabled.
      await vm.verifySetup('123456');
      expect(container.read(mfaViewModelProvider).mfaEnabled, isTrue);

      // Disable fails.
      when(mockAuth.disableMfa(any)).thenThrow(Exception('Wrong TOTP code'));
      await vm.disable('000000');

      final state = container.read(mfaViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.mfaEnabled, isTrue);
    });

    test('failure with OrignaBaseException keeps mfaEnabled true', () async {
      when(mockAuth.verifyMfaSetup(any)).thenAnswer((_) async => ['RC1']);

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      // Simulate MFA enabled.
      await vm.verifySetup('123456');

      when(
        mockAuth.disableMfa(any),
      ).thenThrow(OrignaBaseException('Forbidden', statusCode: 403));
      await vm.disable('000000');

      final state = container.read(mfaViewModelProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.mfaEnabled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 11. LoginState MFA fields
  // ---------------------------------------------------------------------------
  group('LoginState MFA fields', () {
    test('defaults are correct', () {
      final state = LoginState();
      expect(state.mfaRequired, isFalse);
      expect(state.challengeToken, isNull);
    });

    test('copyWith sets mfaRequired and challengeToken', () {
      final state = LoginState();
      final updated = state.copyWith(
        mfaRequired: true,
        challengeToken: 'challenge_abc123',
      );
      expect(updated.mfaRequired, isTrue);
      expect(updated.challengeToken, 'challenge_abc123');
    });

    test('copyWith can reset challengeToken to null', () {
      final state = LoginState(mfaRequired: true, challengeToken: 'token');
      final cleared = state.copyWith(mfaRequired: false, challengeToken: null);
      expect(cleared.mfaRequired, isFalse);
      expect(cleared.challengeToken, isNull);
    });

    test('copyWith preserves MFA fields when not specified', () {
      final state = LoginState(mfaRequired: true, challengeToken: 'abc');
      final updated = state.copyWith(isLoading: true);
      expect(updated.mfaRequired, isTrue);
      expect(updated.challengeToken, 'abc');
      expect(updated.isLoading, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 12. OrignaBaseAuthException challengeToken
  // ---------------------------------------------------------------------------
  group('OrignaBaseAuthException challengeToken', () {
    test('preserves challengeToken', () {
      final ex = OrignaBaseAuthException(
        code: 'mfa-required',
        message: 'Multi-factor authentication required',
        challengeToken: 'ct_xyz789',
      );
      expect(ex.code, 'mfa-required');
      expect(ex.message, 'Multi-factor authentication required');
      expect(ex.challengeToken, 'ct_xyz789');
    });

    test('challengeToken defaults to null', () {
      final ex = OrignaBaseAuthException(
        code: 'user-not-found',
        message: 'Not found',
      );
      expect(ex.challengeToken, isNull);
    });

    test('toString includes code and message', () {
      final ex = OrignaBaseAuthException(
        code: 'mfa-required',
        message: 'MFA needed',
        challengeToken: 'token123',
      );
      final str = ex.toString();
      expect(str, contains('mfa-required'));
      expect(str, contains('MFA needed'));
    });
  });

  // ---------------------------------------------------------------------------
  // Full flow integration
  // ---------------------------------------------------------------------------
  group('Full MFA setup flow', () {
    test('setup -> verify -> confirmSaved transitions through steps', () async {
      when(mockAuth.setupMfa()).thenAnswer(
        (_) async => MfaSetupResult(
          qrCodeBase64: 'qrData',
          manualKey: 'SECRET',
          appleOtpauthUrl: 'otpauth://totp/app',
        ),
      );
      when(
        mockAuth.verifyMfaSetup(any),
      ).thenAnswer((_) async => ['RECOVERY-1', 'RECOVERY-2', 'RECOVERY-3']);

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      // Step 0: idle.
      expect(container.read(mfaViewModelProvider).currentStep, 0);

      // Start setup -> step 1.
      await vm.startSetup();
      expect(container.read(mfaViewModelProvider).currentStep, 1);
      expect(container.read(mfaViewModelProvider).qrCodeBase64, 'qrData');

      // Navigate to verify step.
      vm.goToStep(2);
      expect(container.read(mfaViewModelProvider).currentStep, 2);

      // Verify -> step 3.
      await vm.verifySetup('123456');
      expect(container.read(mfaViewModelProvider).currentStep, 3);
      expect(container.read(mfaViewModelProvider).mfaEnabled, isTrue);
      expect(container.read(mfaViewModelProvider).recoveryCodes.length, 3);

      // Confirm saved -> step 4.
      vm.confirmSaved();
      expect(container.read(mfaViewModelProvider).currentStep, 4);
      expect(container.read(mfaViewModelProvider).codesSaved, isTrue);
    });

    test('setup -> verify fail -> retry verify -> success', () async {
      when(mockAuth.setupMfa()).thenAnswer(
        (_) async => MfaSetupResult(qrCodeBase64: 'qr', manualKey: 'key'),
      );

      int callCount = 0;
      when(mockAuth.verifyMfaSetup(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('Wrong code');
        return ['RC1'];
      });

      final container = _createContainer(mockOb: mockOb);
      addTearDown(container.dispose);

      final vm = container.read(mfaViewModelProvider.notifier);

      await vm.startSetup();
      expect(container.read(mfaViewModelProvider).currentStep, 1);

      // First verify fails.
      await vm.verifySetup('000000');
      expect(container.read(mfaViewModelProvider).errorMessage, isNotNull);
      expect(container.read(mfaViewModelProvider).currentStep, 1);
      expect(container.read(mfaViewModelProvider).mfaEnabled, isFalse);

      // Retry verify succeeds.
      await vm.verifySetup('123456');
      expect(container.read(mfaViewModelProvider).errorMessage, isNull);
      expect(container.read(mfaViewModelProvider).currentStep, 3);
      expect(container.read(mfaViewModelProvider).mfaEnabled, isTrue);
    });
  });
}
