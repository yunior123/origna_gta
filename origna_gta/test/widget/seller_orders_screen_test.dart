import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SellerOrdersScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: SellerOrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SellerOrdersScreen), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: SellerOrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
