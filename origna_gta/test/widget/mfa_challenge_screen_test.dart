import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/mfa_challenge_screen.dart';

import '../test_utils.dart';

void main() {
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
      await tester.pumpAndSettle();

      expect(find.text('mfa.challenge_title'.tr()), findsOneWidget);
    });

    testWidgets('shows shield icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('shows enter code subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('mfa.enter_code'.tr()), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('mfa.submit'.tr()), findsOneWidget);
    });

    testWidgets('shows use recovery code button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('mfa.use_recovery_code'.tr()), findsOneWidget);
    });

    testWidgets('shows code input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('toggles to recovery mode when button pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('mfa.use_recovery_code'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('mfa.enter_recovery_code'.tr()), findsOneWidget);
    });
  });
}
