import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/terms_of_service_screen.dart';
import 'package:origna_gta/widgets/legal_screen_body.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('TermsOfServiceScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TermsOfServiceScreen), findsOneWidget);
    });

    testWidgets('contains LegalScreenBody', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LegalScreenBody), findsOneWidget);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays legal agreement badge', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Legal Agreement'), findsOneWidget);
    });

    testWidgets('has verified icon in badge', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });
  });
}
