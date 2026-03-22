import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/subscription_cancel_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SubscriptionCancelScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionCancelScreen), findsOneWidget);
    });

    testWidgets('displays cancelled message', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('displays no charge message', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No charge was made'), findsOneWidget);
    });

    testWidgets('displays resubscribe button', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upgrade now'), findsOneWidget);
    });

    testWidgets('displays back to home button', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays premium outlined icon', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: SubscriptionCancelScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
    });
  });
}
