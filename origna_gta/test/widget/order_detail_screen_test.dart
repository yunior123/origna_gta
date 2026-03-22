import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/order_detail_screen.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('OrderDetailScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: OrderDetailScreen(orderId: 'test-order-id')),
      );
      await tester.pump();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: OrderDetailScreen(orderId: 'test-order-id')),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });
  });

  group('OrderDetailScreenLayout', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: const AsyncValue.loading(),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });
  });
}
