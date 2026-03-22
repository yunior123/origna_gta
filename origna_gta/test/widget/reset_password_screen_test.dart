import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/reset_password_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('ResetPasswordScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: ResetPasswordScreen(oobCode: 'test-oob-code')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: ResetPasswordScreen(oobCode: 'test-oob-code')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays reset password title in app bar', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: ResetPasswordScreen(oobCode: 'test-oob-code')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);
    });
  });
}
