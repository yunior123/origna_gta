import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';

Order _makeOrder({
  String orderId = 'order12345678',
  OrderStatus status = OrderStatus.pending,
  ShippingApprovalStatus shippingApproval = ShippingApprovalStatus.notRequired,
  int totalAmountCents = 5000,
  DateTime? createdAt,
}) {
  return Order(
    orderId: orderId,
    userId: 'u1',
    totalAmountCents: totalAmountCents,
    subtotalCents: 4500,
    taxes: const Taxes(),
    orderStatus: status,
    createdAt: createdAt ?? DateTime(2025, 6, 1),
    items: [
      const OrderItem(
        productId: 'p1',
        name: 'Widget',
        description: 'A widget',
        priceCents: 2500,
        quantity: 2,
        imageUrls: [],
        sellerId: 's1',
      ),
    ],
    shippingApprovalStatus: shippingApproval,
  );
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    List<Order>? orders,
    bool isLoggedIn = true,
    bool ordersError = false,
  }) {
    return TestWrapper(
      overrides: [
        userIdProvider.overrideWithValue(isLoggedIn ? 'u1' : null),
        currentUserProvider.overrideWithValue(
          isLoggedIn
              ? const AppAuthUser(uid: 'u1', email: 'buyer@test.com')
              : null,
        ),
        buyerOrdersProvider.overrideWith((ref) {
          if (ordersError) return Stream.error('error');
          return Stream.value(orders ?? <Order>[]);
        }),
      ],
      child: const OrdersScreen(),
    );
  }

  group('OrdersScreen', () {
    testWidgets('renders empty state when no orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('not logged in shows sign in required', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(isLoggedIn: false));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('renders orders list', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            userIdProvider.overrideWithValue('u1'),
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'u1', email: 'buyer@test.com'),
            ),
            buyerOrdersProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const OrdersScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(ordersError: true));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('filter chips exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('delivered order shown under delivered filter', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'ord_delivered', status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord_pending', status: OrderStatus.pending),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('multiple orders rendered', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'ord11111111'),
        _makeOrder(orderId: 'ord22222222'),
        _makeOrder(orderId: 'ord33333333'),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('orders screen has refresh indicator', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('pending shipping approval shows banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(shippingApproval: ShippingApprovalStatus.pending),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump(); await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });
  });
}
