import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/mfa_challenge_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    initTestMocks();
  });

  Widget createTestWidget() {
    return TestWrapper(
      child: const MfaChallengeScreen(challengeToken: 'test_token_123'),
    );
  }

  group('MfaChallengeScreen Widget Tests', () {
    testWidgets('renders challenge title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Two-Factor Authentication'), findsOneWidget);
    });

    testWidgets('shows shield icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('shows enter code subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter your 6-digit code'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Submit'), findsWidgets);
    });

    testWidgets('shows use recovery code button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Use Recovery Code'), findsOneWidget);
    });

    testWidgets('shows code input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('toggles to recovery mode when button pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Use Recovery Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Enter your recovery code'), findsWidgets);
    });
  });
}
