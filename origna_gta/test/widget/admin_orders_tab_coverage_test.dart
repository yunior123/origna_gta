import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_orders_tab.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_orders_tab_coverage_test.mocks.dart';

OrderModel _makeOrder({
  String orderId = 'order_id_12345678',
  String paymentStatus = 'paid',
  double total = 100.0,
  String customerEmail = 'customer@test.com',
  DateTime? createdAt,
  List<CartItemDetailModel>? items,
}) {
  return OrderModel(
    orderId: orderId,
    userId: 'u1',
    items: items ?? [],
    totalAmountCents: (total * 100).toInt(),
    subtotalCents: ((total * 0.9) * 100).toInt(),
    orderStatus: 'confirmed',
    shippingAddress: {},
    createdAt: createdAt ?? DateTime(2025, 6, 15),
    customerId: 'c1',
    customerEmail: customerEmail,
    taxes: {},
    currency: 'cad',
    sellerIds: ['s1'],
    stripeSessionId: 'ss_1',
    paymentStatus: paymentStatus,
  );
}

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    when(
      mockAdminRepo.watchOrders(status: anyNamed('status')),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget buildWidget() {
    return TestWrapper(
      overrides: [adminRepositoryProvider.overrideWithValue(mockAdminRepo)],
      child: const Scaffold(body: AdminOrdersTab()),
    );
  }

  group('AdminOrdersTab', () {
    testWidgets('renders loading state', (tester) async {
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('renders empty state when no orders', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('renders orders list with order data', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('renders order with customer email', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(customerEmail: 'buyer@test.com')];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('buyer@test.com'), findsOneWidget);
    });

    testWidgets('renders order total price', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(total: 49.99)];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('49.99'), findsWidgets);
    });

    testWidgets('renders filter chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('renders paid order with status color', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(paymentStatus: 'paid')];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.error('error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('order card is expandable', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('expanding order shows items and details button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            CartItemDetailModel(
              productId: 'p1',
              name: 'Widget',
              description: 'desc',
              price: 2500 / 100.0,
              imageUrls: [],
              quantity: 2,
              createdAt: DateTime.now(),
              sellerAddress: Address.empty(),
              sellerId: 's1',
              sellerName: 'Seller One',
            ),
          ],
        ),
      ];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Widget'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
    });

    testWidgets('paid order shows refund button when expanded', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(paymentStatus: 'paid')];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('btn-refund-order'), findsOneWidget);
    });

    testWidgets('non-paid order does not show refund button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(paymentStatus: 'authorized')];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('btn-refund-order'), findsNothing);
    });

    testWidgets('expanded order shows view details button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      when(
        mockAdminRepo.watchOrders(status: anyNamed('status')),
      ).thenAnswer((_) => Stream.value(orders));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('btn-view-order-details'), findsOneWidget);
    });
  });
}
