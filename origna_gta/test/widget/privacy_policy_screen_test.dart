import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('PrivacyPolicyScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    });

    testWidgets('contains LegalScreenBody', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LegalScreenBody), findsOneWidget);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays privacy policy hero title', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays badge', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Your privacy matters'), findsOneWidget);
    });

    testWidgets('has lock icon in badge', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });
  });
}
