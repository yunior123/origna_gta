import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/widgets/order_widgets.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import '../test_utils.dart';

void main() {
  group('Order Widgets Tests', () {
    testWidgets('OrderStatusTimeline renders all steps', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: OrderStatusTimeline(currentStep: 2),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('In Transit'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('PendingApprovalsBanner renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: PendingApprovalsBanner(count: 3),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 need approval'), findsOneWidget);
      expect(find.text('Review cost'), findsOneWidget);
    });

    test('getItemDeliveryStep returns correct indices', () {
      expect(getItemDeliveryStep(DeliveryStatusValues.pending), 0);
      expect(getItemDeliveryStep(DeliveryStatusValues.shipped), 1);
      expect(getItemDeliveryStep(DeliveryStatusValues.delivered), 2);
      expect(getItemDeliveryStep('other'), -1);
    });

    test('getItemStatusConfig returns correct config', () {
      expect(getItemStatusConfig(OrderStatusValues.confirmed).color, DesignTokens.info);
      expect(getItemStatusConfig(OrderStatusValues.processing).color, DesignTokens.primary);
      expect(getItemStatusConfig(OrderStatusValues.shipped).color, DesignTokens.statusShipped);
      expect(getItemStatusConfig(OrderStatusValues.delivered).color, DesignTokens.success);
      expect(getItemStatusConfig(DeliveryStatusValues.refunded).color, DesignTokens.warning);
      expect(getItemStatusConfig(OrderStatusValues.cancelled).color, DesignTokens.error);
      expect(getItemStatusConfig(OrderStatusValues.disputed).color, DesignTokens.error);
      expect(getItemStatusConfig(OrderStatusValues.inTransit).color, DesignTokens.info);
      expect(getItemStatusConfig(OrderStatusValues.failed).color, DesignTokens.error);
      expect(getItemStatusConfig(OrderStatusValues.expired).color, DesignTokens.textSecondary);
      expect(getItemStatusConfig(OrderStatusValues.partiallyRefunded).color, DesignTokens.warning);
      expect(getItemStatusConfig('unknown').color, DesignTokens.secondary);
    });

    test('getOrderStatusConfig returns correct config', () {
      expect(getOrderStatusConfig(OrderStatus.pending).color, DesignTokens.secondary);
      expect(getOrderStatusConfig(OrderStatus.confirmed).color, DesignTokens.info);
      expect(getOrderStatusConfig(OrderStatus.processing).color, DesignTokens.primary);
      expect(getOrderStatusConfig(OrderStatus.shipped).color, DesignTokens.statusShipped);
      expect(getOrderStatusConfig(OrderStatus.inTransit).color, DesignTokens.statusInTransit);
      expect(getOrderStatusConfig(OrderStatus.delivered).color, DesignTokens.success);
      expect(getOrderStatusConfig(OrderStatus.cancelled).color, DesignTokens.error);
      expect(getOrderStatusConfig(OrderStatus.failed).color, DesignTokens.error);
      expect(getOrderStatusConfig(OrderStatus.expired).color, DesignTokens.textSecondary);
      expect(getOrderStatusConfig(OrderStatus.disputed).color, DesignTokens.error);
      expect(getOrderStatusConfig(OrderStatus.partiallyRefunded).color, DesignTokens.info);
      expect(getOrderStatusConfig(OrderStatus.refunded).color, DesignTokens.info);
    });

    test('getTimelineStep returns correct indices', () {
      expect(getTimelineStep(OrderStatus.confirmed), 0);
      expect(getTimelineStep(OrderStatus.processing), 1);
      expect(getTimelineStep(OrderStatus.shipped), 2);
      expect(getTimelineStep(OrderStatus.inTransit), 3);
      expect(getTimelineStep(OrderStatus.delivered), 4);
      expect(getTimelineStep(OrderStatus.cancelled), -1);
    });
  });
}
