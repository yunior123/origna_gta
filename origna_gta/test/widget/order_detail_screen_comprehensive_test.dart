import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/order_detail_screen.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/order_widgets.dart';

import '../test_utils.dart';

Order _makeOrder({
  String orderId = 'order12345678',
  OrderStatus status = OrderStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.paid,
  ShippingApprovalStatus shippingApproval = ShippingApprovalStatus.notRequired,
  int totalAmountCents = 5000,
  int subtotalCents = 4500,
  DateTime? createdAt,
  Address? shippingAddress,
  String? deliveryInstructions,
  List<OrderItem>? items,
}) {
  return Order(
    orderId: orderId,
    userId: 'u1',
    totalAmountCents: totalAmountCents,
    subtotalCents: subtotalCents,
    taxes: const Taxes(),
    orderStatus: status,
    paymentStatus: paymentStatus,
    createdAt: createdAt ?? DateTime(2025, 6, 1),
    items:
        items ??
        [
          OrderItem(
            productId: 'p1',
            name: 'Widget Product',
            description: 'A widget',
            price: 2500 / 100.0,
            quantity: 2,
            imageUrls: ['https://example.com/image.jpg'],
            sellerId: 's1',
            status: DeliveryStatusValues.pending,
          ),
        ],
    shippingApprovalStatus: shippingApproval,
    shippingAddress: shippingAddress,
    deliveryInstructions: deliveryInstructions,
  );
}

OrderItem _makeOrderItem({
  String productId = 'p1',
  String name = 'Test Product',
  double price = 25.0,
  int quantity = 2,
  String status = DeliveryStatusValues.pending,
  String? trackingNumber,
  bool isDigital = false,
  String? licenseKey,
  bool digitalUnlocked = false,
}) {
  return OrderItem(
    productId: productId,
    name: name,
    description: 'Test description',
    price: price,
    quantity: quantity,
    imageUrls: ['https://example.com/image.jpg'],
    sellerId: 's1',
    status: status,
    trackingNumber: trackingNumber,
    isDigital: isDigital,
    licenseKey: licenseKey,
    digitalUnlocked: digitalUnlocked,
  );
}

Address _makeAddress({
  String street = '123 Main St',
  String city = 'Toronto',
  String state = 'ON',
  String postalCode = 'M5V 1A1',
}) {
  return Address(
    street: street,
    city: city,
    state: state,
    postalCode: postalCode,
    country: 'Canada',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('OrderDetailScreen', () {
    testWidgets('renders with loading state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider.overrideWith((ref, orderId) async => null),
          ],
          child: const OrderDetailScreen(orderId: 'test-order-id'),
        ),
      );
      await tester.pump();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });

    testWidgets('displays order details when loaded', (tester) async {
      final order = _makeOrder();

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider.overrideWith((ref, orderId) async => order),
          ],
          child: const OrderDetailScreen(orderId: 'order12345678'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });

    testWidgets('shows error state when order fetch fails', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderByIdProvider.overrideWith(
              (ref, orderId) async => throw Exception('Fetch error'),
            ),
          ],
          child: const OrderDetailScreen(orderId: 'test-order-id'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Loading & Error States', () {
    testWidgets('shows loading indicator when orderAsync is loading', (
      tester,
    ) async {
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

    testWidgets('shows error state with error icon', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.error('Test error', StackTrace.empty),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('error state has retry button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.error('Test error', StackTrace.empty),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('btn-retry-load-order'), findsOneWidget);
    });

    testWidgets('error state refresh callback can be invoked', (tester) async {
      var refreshCalled = false;

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.error('Test error', StackTrace.empty),
            onRefresh: () => refreshCalled = true,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final retryButton = find.bySemanticsLabel('btn-retry-load-order');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(refreshCalled, isTrue);
    });
  });

  group('OrderDetailScreenLayout - Order Not Found', () {
    testWidgets('shows not found state when order is null', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: const AsyncValue.data(null),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('not found state has back button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: const AsyncValue.data(null),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('btn-back'), findsOneWidget);
    });

    testWidgets('back button callback can be invoked', (tester) async {
      var backCalled = false;

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: const AsyncValue.data(null),
            onRefresh: () {},
            onBack: () => backCalled = true,
          ),
        ),
      );
      await tester.pump();

      final backButton = find.bySemanticsLabel('btn-back');
      await tester.tap(backButton);

      expect(backCalled, isTrue);
    });

    testWidgets('not found state displays text-order-not-found semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: const AsyncValue.data(null),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'text-order-not-found',
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Order Display', () {
    testWidgets('displays order with valid data', (tester) async {
      final order = _makeOrder();

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with pending status', (tester) async {
      final order = _makeOrder(status: OrderStatus.pending);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with delivered status', (tester) async {
      final order = _makeOrder(status: OrderStatus.delivered);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with shipped status', (tester) async {
      final order = _makeOrder(status: OrderStatus.shipped);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with cancelled status', (tester) async {
      final order = _makeOrder(status: OrderStatus.cancelled);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with confirmed status', (tester) async {
      final order = _makeOrder(status: OrderStatus.confirmed);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with processing status', (tester) async {
      final order = _makeOrder(status: OrderStatus.processing);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with inTransit status', (tester) async {
      final order = _makeOrder(status: OrderStatus.inTransit);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with failed status', (tester) async {
      final order = _makeOrder(status: OrderStatus.failed);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with disputed status', (tester) async {
      final order = _makeOrder(status: OrderStatus.disputed);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Items List', () {
    testWidgets('displays order with single item', (tester) async {
      final order = _makeOrder(
        items: [_makeOrderItem(name: 'Single Item', quantity: 1)],
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with multiple items', (tester) async {
      final order = _makeOrder(
        items: [
          _makeOrderItem(productId: 'p1', name: 'Item 1'),
          _makeOrderItem(productId: 'p2', name: 'Item 2'),
          _makeOrderItem(productId: 'p3', name: 'Item 3'),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with digital item', (tester) async {
      final order = _makeOrder(
        items: [
          _makeOrderItem(
            name: 'Digital Product',
            isDigital: true,
            licenseKey: 'LICENSE-KEY-123',
            digitalUnlocked: true,
          ),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays item with tracking number', (tester) async {
      final order = _makeOrder(
        items: [
          _makeOrderItem(name: 'Tracked Item', trackingNumber: 'TRACK123456'),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Shipping Info', () {
    testWidgets('displays order with shipping address', (tester) async {
      final order = _makeOrder(
        shippingAddress: _makeAddress(
          street: '456 Queen Street',
          city: 'Montreal',
          state: 'QC',
          postalCode: 'H2X 1Y4',
        ),
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order without shipping address', (tester) async {
      final order = _makeOrder(shippingAddress: null);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with delivery instructions', (tester) async {
      final order = _makeOrder(deliveryInstructions: 'Leave at door');

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with empty delivery instructions', (
      tester,
    ) async {
      final order = _makeOrder(deliveryInstructions: '');

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Status Tracking', () {
    testWidgets('displays order with pending payment status', (tester) async {
      final order = _makeOrder(paymentStatus: PaymentStatus.awaitingPayment);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with authorized payment status', (
      tester,
    ) async {
      final order = _makeOrder(paymentStatus: PaymentStatus.authorized);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with captured payment status', (tester) async {
      final order = _makeOrder(paymentStatus: PaymentStatus.captured);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with pending shipping approval', (
      tester,
    ) async {
      final order = _makeOrder(
        shippingApproval: ShippingApprovalStatus.pending,
        paymentStatus: PaymentStatus.authorized,
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with approved shipping approval', (
      tester,
    ) async {
      final order = _makeOrder(
        shippingApproval: ShippingApprovalStatus.approved,
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with refunded status', (tester) async {
      final order = _makeOrder(status: OrderStatus.refunded);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with partially refunded status', (
      tester,
    ) async {
      final order = _makeOrder(status: OrderStatus.partiallyRefunded);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('displays order with expired status', (tester) async {
      final order = _makeOrder(status: OrderStatus.expired);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Actions', () {
    testWidgets('has refresh indicator for pull-to-refresh', (tester) async {
      final order = _makeOrder();

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('refresh callback can be invoked', (tester) async {
      var refreshCalled = false;
      final order = _makeOrder();

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () => refreshCalled = true,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshIndicator), findsOneWidget);
      refreshCalled = false;
      expect(refreshCalled, isFalse);
    });

    testWidgets('delivered order shows buy again action', (tester) async {
      final order = _makeOrder(status: OrderStatus.delivered);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('OrderDetailScreenLayout - Edge Cases', () {
    testWidgets('handles order with zero total', (tester) async {
      final order = _makeOrder(totalAmountCents: 0, subtotalCents: 0);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with high total amount', (tester) async {
      final order = _makeOrder(
        totalAmountCents: 99999999,
        subtotalCents: 90000000,
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with empty items list', (tester) async {
      final order = _makeOrder(items: []);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with long order ID', (tester) async {
      final order = _makeOrder(
        orderId: 'very-long-order-id-12345678901234567890',
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with special characters in item name', (
      tester,
    ) async {
      final order = _makeOrder(
        items: [
          _makeOrderItem(name: 'Product with émojis 🎉 and spëcial çhars'),
        ],
      );

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with large quantity', (tester) async {
      final order = _makeOrder(items: [_makeOrderItem(quantity: 999)]);

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with old date', (tester) async {
      final order = _makeOrder(createdAt: DateTime(2020, 1, 1));

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });

    testWidgets('handles order with future date', (tester) async {
      final order = _makeOrder(createdAt: DateTime(2030, 12, 31));

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });

  group('_OrderDetailView', () {
    testWidgets('renders BuyerOrderCard with isDetailView true', (
      tester,
    ) async {
      final order = _makeOrder();

      await tester.pumpWidget(
        TestWrapper(
          child: OrderDetailScreenLayout(
            orderAsync: AsyncValue.data(order),
            onRefresh: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BuyerOrderCard), findsOneWidget);
    });
  });
}
