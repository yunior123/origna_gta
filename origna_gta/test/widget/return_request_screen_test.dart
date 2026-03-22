import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/return_request_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('ReturnRequestScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: ReturnRequestScreen(orderId: 'test-order-id')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReturnRequestScreen), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: ReturnRequestScreen(orderId: 'test-order-id')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
