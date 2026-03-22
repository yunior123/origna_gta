import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/seller_products_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SellerProductsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: SellerProductsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SellerProductsScreen), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      await tester.pumpWidget(const TestWrapper(child: SellerProductsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
