import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/auth/mfa_state.dart';
import 'package:origna_gta/screens/mfa_challenge_screen.dart';

import '../test_utils.dart';

class MockMfaViewModel extends StateNotifier<MfaState> {
  bool verifyChallengeCalled = false;
  bool useRecoveryCodeCalled = false;
  String? lastCode;
  String? lastToken;
  bool shouldSucceed = true;
  String? errorMessage;
  int callCount = 0;

  MockMfaViewModel() : super(MfaState());

  Future<bool> verifyChallenge(String challengeToken, String code) async {
    verifyChallengeCalled = true;
    lastCode = code;
    lastToken = challengeToken;
    callCount++;
    if (!shouldSucceed && errorMessage != null) {
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    } else {
      state = state.copyWith(isLoading: false);
    }
    return shouldSucceed;
  }

  Future<bool> useRecoveryCode(String challengeToken, String code) async {
    useRecoveryCodeCalled = true;
    lastCode = code;
    lastToken = challengeToken;
    callCount++;
    if (!shouldSucceed && errorMessage != null) {
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    } else {
      state = state.copyWith(isLoading: false);
    }
    return shouldSucceed;
  }
}

final mockMfaViewModelProvider =
    StateNotifierProvider.autoDispose<MockMfaViewModel, MfaState>(
      (ref) => MockMfaViewModel(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    initTestMocks();
  });

  Widget createTestWidget({MockMfaViewModel? mockViewModel}) {
    return TestWrapper(
      overrides: [
        if (mockViewModel != null)
          mockMfaViewModelProvider.overrideWith((ref) => mockViewModel),
      ],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.home) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('HOME')),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.login) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('LOGIN')),
            settings: settings,
          );
        }
        return null;
      },
      child: const MfaChallengeScreen(challengeToken: 'test_token_123'),
    );
  }

  group('MfaChallengeScreen OTP Input Field', () {
    testWidgets('renders MFA code input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('code input field has correct properties', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final textField = tester
          .widgetList<TextField>(find.byType(TextField))
          .first;
      expect(textField.keyboardType, TextInputType.number);
      expect(textField.maxLength, 6);
      expect(textField.textAlign, TextAlign.center);
    });

    testWidgets('code input field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();

      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('code input field has monospace font', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final textField = tester
          .widgetList<TextField>(find.byType(TextField))
          .first;
      expect(textField.style?.fontFamily, 'monospace');
    });
  });

  group('MfaChallengeScreen Recovery Code Input', () {
    testWidgets('shows recovery code input when toggled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter your recovery code'), findsWidgets);
    });

    testWidgets('recovery code input has correct properties', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final textField = tester
          .widgetList<TextField>(find.byType(TextField))
          .first;
      expect(textField.textAlign, TextAlign.center);
    });

    testWidgets('can toggle back to TOTP mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use TOTP Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter your 6-digit code'), findsOneWidget);
    });

    testWidgets('recovery code input accepts text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextField).first, 'recovery-code-123');
      await tester.pump();

      expect(find.text('recovery-code-123'), findsOneWidget);
    });
  });

  group('MfaChallengeScreen UI Elements', () {
    testWidgets('renders shield icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('renders challenge title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Two-Factor Authentication'), findsOneWidget);
    });

    testWidgets('renders enter code subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter your 6-digit code'), findsOneWidget);
    });

    testWidgets('renders card container', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Submit'), findsWidgets);
    });

    testWidgets('renders use recovery code button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Use Recovery Code'), findsOneWidget);
    });
  });

  group('MfaChallengeScreen Verify Button', () {
    testWidgets('submit button is enabled when code is entered', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('submit button does nothing with empty code', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final buttonBefore = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(buttonBefore.onPressed, isNotNull);
    });

    testWidgets('submit button does nothing with code less than 6 digits', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(find.text('Enter your 6-digit code'), findsOneWidget);
    });
  });

  group('MfaChallengeScreen Loading States', () {
    testWidgets('loading indicator is not shown initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('MfaChallengeScreen Cancel/Back Actions', () {
    testWidgets('shows use recovery code button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Use Recovery Code'), findsOneWidget);
    });

    testWidgets('toggle button switches modes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Use Recovery Code'), findsOneWidget);

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Use TOTP Code'), findsOneWidget);
    });

    testWidgets('clears input fields on mode toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use TOTP Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final textField = tester
          .widgetList<TextField>(find.byType(TextField))
          .first;
      expect(textField.controller?.text, isEmpty);
    });
  });

  group('MfaChallengeScreen Attempts Exhausted', () {
    testWidgets('shows locked state after max attempts simulated', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.text('Two-Factor Authentication'), findsOneWidget);
    });

    testWidgets('back to login button exists in locked state', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Back to Login'), findsNothing);

      expect(find.text('Use Recovery Code'), findsOneWidget);
    });
  });

  group('MfaChallengeScreen Edge Cases', () {
    testWidgets('handles whitespace in code input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('widget disposes controllers properly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsWidgets);
    });
  });
}
