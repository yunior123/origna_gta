import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/core/providers.dart';

import '../test_utils.dart';

void main() {
  setUp(() {
    initTestMocks();
  });

  Widget createTestWidget({
    String orderId = 'order_123',
    double valueCad = 99.99,
    int itemCount = 2,
    int? estimatedShipDays,
    bool isLocalDelivery = false,
  }) {
    return TestWrapper(
      overrides: [
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
      ],
      child: OrderSuccessScreen(
        orderId: orderId,
        valueCad: valueCad,
        itemCount: itemCount,
        estimatedShipDays: estimatedShipDays,
        isLocalDelivery: isLocalDelivery,
      ),
    );
  }

  /// Pump enough frames for FadeSlideIn animations to complete
  /// without using pumpAndSettle (which times out on confetti).
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pump(); // initial frame + postFrameCallback
    await tester.pump(const Duration(milliseconds: 100)); // start animations
    await tester.pump(const Duration(seconds: 1)); // finish animations
  }

  group('OrderSuccessScreen Widget Tests', () {
    testWidgets('renders order placed title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.text('orders.order_placed'.tr()), findsOneWidget);
    });

    testWidgets('shows order ID', (tester) async {
      await tester.pumpWidget(createTestWidget(orderId: 'order_123'));
      await pumpScreen(tester);

      expect(find.textContaining('order_123'), findsOneWidget);
    });

    testWidgets('shows thank you message', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.text('orders.thank_you'.tr()), findsOneWidget);
    });

    testWidgets('shows continue shopping button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.text('orders.continue_shopping'.tr()), findsOneWidget);
    });

    testWidgets('shows view my orders button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.text('orders.view_my_orders'.tr()), findsOneWidget);
    });

    testWidgets('shows success check icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows item count when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(itemCount: 3));
      await pumpScreen(tester);

      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('shows order value when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(valueCad: 149.99));
      await pumpScreen(tester);

      expect(find.textContaining('149.99'), findsOneWidget);
    });

    testWidgets('shows delivery window when estimatedShipDays provided', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(estimatedShipDays: 5));
      await pumpScreen(tester);

      expect(find.text('orders.estimated_delivery'.tr()), findsOneWidget);
    });

    testWidgets('shows delivery policy copy for non-local physical orders', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(estimatedShipDays: 5));
      await pumpScreen(tester);

      expect(
        find.text('orders.estimated_delivery_international'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows delivery icon when estimatedShipDays provided', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(estimatedShipDays: 5));
      await pumpScreen(tester);

      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('shows confetti animation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpScreen(tester);

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
