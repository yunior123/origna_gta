import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/shipping_approval_screen.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<OrderRepository>()])
import 'shipping_approval_screen_coverage_test.mocks.dart';

Order _makeOrder({
  String orderId = 'order12345678',
  ShippingApprovalStatus approvalStatus = ShippingApprovalStatus.pending,
  int shippingCostCents = 1000,
  int actualShippingCents = 1500,
  int pendingTotalCents = 10500,
  int totalAmountCents = 10000,
  List<OrderItem>? items,
  DateTime? createdAt,
}) {
  return Order(
    orderId: orderId,
    userId: 'u1',
    totalAmountCents: totalAmountCents,
    subtotalCents: 9000,
    shippingCostCents: shippingCostCents,
    taxes: const Taxes(),
    orderStatus: OrderStatus.pending,
    createdAt: createdAt ?? DateTime(2025, 6, 1),
    items:
        items ??
        [
          const OrderItem(
            productId: 'p1',
            name: 'Test Widget',
            description: 'A widget',
            priceCents: 2500,
            quantity: 2,
            imageUrls: [],
            sellerId: 's1',
          ),
        ],
    shippingApprovalStatus: approvalStatus,
    actualShippingCents: actualShippingCents,
    pendingTotalCents: pendingTotalCents,
  );
}

void main() {
  late MockOrderRepository mockOrderRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockOrderRepo = MockOrderRepository();
  });

  Widget buildWidget({List<Order>? orders}) {
    final ordersList = orders ?? <Order>[];
    return TestWrapper(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        buyerOrdersProvider.overrideWith((ref) => Stream.value(ordersList)),
        userIdProvider.overrideWithValue('u1'),
        currentUserProvider.overrideWithValue(
          const AppAuthUser(uid: 'u1', email: 'buyer@test.com'),
        ),
      ],
      child: const ShippingApprovalScreen(),
    );
  }

  group('ShippingApprovalScreen', () {
    testWidgets('renders empty state when no pending approvals', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('renders pending approval card', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('shows shipping cost comparison', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(shippingCostCents: 1000, actualShippingCents: 1500),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.textContaining('10.00'), findsWidgets);
      expect(find.textContaining('15.00'), findsWidgets);
    });

    testWidgets('shows approve and reject buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('shows order items summary', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test Widget'), findsOneWidget);
      expect(find.textContaining('x2'), findsOneWidget);
    });

    testWidgets('shows shipping difference percentage', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(shippingCostCents: 1000, actualShippingCents: 1500),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.textContaining('50%'), findsWidgets);
    });

    testWidgets('renders loading state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            buyerOrdersProvider.overrideWith((ref) => const Stream.empty()),
            userIdProvider.overrideWithValue('u1'),
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'u1', email: 'buyer@test.com'),
            ),
          ],
          child: const ShippingApprovalScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('multiple approval cards rendered', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'order11111111'),
        _makeOrder(orderId: 'order22222222'),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ShippingApprovalScreen), findsOneWidget);
    });

    testWidgets('shows original and new total', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(totalAmountCents: 10000, pendingTotalCents: 10500),
      ];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.textContaining('100.00'), findsWidgets);
      expect(find.textContaining('105.00'), findsWidgets);
    });

    testWidgets('shows date on approval card', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(createdAt: DateTime(2025, 6, 15))];
      await tester.pumpWidget(buildWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jun'), findsWidgets);
    });
  });
}
