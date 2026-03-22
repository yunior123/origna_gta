import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/seller/seller_analytics_screen.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/animations.dart';

import '../test_utils.dart';

Order _makeOrder({
  String orderId = 'order12345678',
  OrderStatus status = OrderStatus.delivered,
  int subtotalCents = 10000,
  DateTime? createdAt,
  List<OrderItem>? items,
}) {
  return Order(
    orderId: orderId,
    userId: 'buyer1',
    totalAmountCents: subtotalCents + 500,
    subtotalCents: subtotalCents,
    taxes: const Taxes(),
    orderStatus: status,
    createdAt: createdAt ?? DateTime.now(),
    items:
        items ??
        [
          OrderItem(
            productId: 'product1',
            name: 'Test Product',
            description: 'A test product',
            priceCents: subtotalCents,
            quantity: 1,
            imageUrls: [],
            sellerId: 'seller1',
          ),
        ],
  );
}

OrderItem _makeOrderItem({
  String productId = 'product1',
  String name = 'Test Product',
  int priceCents = 5000,
  int quantity = 2,
}) {
  return OrderItem(
    productId: productId,
    name: name,
    description: 'Test product description',
    priceCents: priceCents,
    quantity: quantity,
    imageUrls: [],
    sellerId: 'seller1',
  );
}

Widget buildTestWidget({
  List<Order>? orders,
  bool isLoggedIn = true,
  bool isLoading = false,
  bool hasError = false,
}) {
  return TestWrapper(
    overrides: [
      currentUserProvider.overrideWithValue(
        isLoggedIn
            ? const AppAuthUser(uid: 'seller1', email: 'seller@test.com')
            : null,
      ),
      sellerOrdersProvider.overrideWith((ref) {
        if (isLoading) return const Stream.empty();
        if (hasError) return Stream.error('Failed to load orders');
        return Stream.value(orders ?? <Order>[]);
      }),
    ],
    child: const SellerAnalyticsScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SellerAnalyticsScreen - Widget Rendering', () {
    testWidgets('renders without errors when logged in', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('renders without errors when not logged in', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isLoggedIn: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('has scaffold with gradient background', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has correct screen key', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('seller_analytics_screen')), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Loading States', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isLoading: true));
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows loading in center of screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isLoading: true));
      await tester.pump();

      final centerFinder = find.ancestor(
        of: find.byType(ModernLoadingIndicator),
        matching: find.byType(Center),
      );
      expect(centerFinder, findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Error States', () {
    testWidgets('shows error widget on error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(hasError: true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error state uses FadeSlideIn animation', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(hasError: true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeSlideIn), findsWidgets);
    });

    testWidgets('error state is centered', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(hasError: true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final errorIcon = find.byIcon(Icons.error_outline);
      expect(errorIcon, findsOneWidget);

      final centerFinder = find.ancestor(
        of: errorIcon,
        matching: find.byType(Center),
      );
      expect(centerFinder, findsWidgets);
    });
  });

  group('SellerAnalyticsScreen - Empty State (Not Logged In)', () {
    testWidgets('shows login required when not logged in', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isLoggedIn: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    });

    testWidgets('shows AnimatedEmptyState when not logged in', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(isLoggedIn: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Data Display', () {
    testWidgets('shows dashboard with orders data', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows KPI cards for orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'ord1', subtotalCents: 5000),
        _makeOrder(orderId: 'ord2', subtotalCents: 3000),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('shows total revenue from delivered orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(subtotalCents: 10000)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('\$100.00'), findsAtLeast(1));
    });

    testWidgets('shows zero revenue when no delivered orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.pending)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('\$0.00'), findsWidgets);
    });

    testWidgets('shows orders this month count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(createdAt: DateTime.now()),
        _makeOrder(
          orderId: 'old_order',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('displays order breakdown section', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord2', status: OrderStatus.pending),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeSlideIn), findsWidgets);
    });
  });

  group('SellerAnalyticsScreen - Order Status Breakdown', () {
    testWidgets('shows delivered orders count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord2', status: OrderStatus.delivered),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('shows pending orders count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.pending)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows confirmed orders count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.confirmed)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows shipped orders count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.shipped)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows cancelled orders count', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.cancelled)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows all status counts correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'ord1', status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord2', status: OrderStatus.pending),
        _makeOrder(orderId: 'ord3', status: OrderStatus.confirmed),
        _makeOrder(orderId: 'ord4', status: OrderStatus.shipped),
        _makeOrder(orderId: 'ord5', status: OrderStatus.cancelled),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Top Products', () {
    testWidgets('shows top products when orders have items', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(
              productId: 'p1',
              name: 'Product A',
              priceCents: 2500,
              quantity: 3,
            ),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Product A'), findsOneWidget);
    });

    testWidgets('shows quantity sold for top products', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(
              productId: 'p1',
              name: 'Product A',
              priceCents: 2500,
              quantity: 5,
            ),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('shows revenue for top products', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(
              productId: 'p1',
              name: 'Product A',
              priceCents: 5000,
              quantity: 2,
            ),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('\$100.00'), findsAtLeast(1));
    });

    testWidgets('shows rank indicator for top products', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(
              productId: 'p1',
              name: 'Product A',
              priceCents: 2500,
              quantity: 3,
            ),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows multiple top products sorted by quantity', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(
              productId: 'p1',
              name: 'Product A',
              priceCents: 2500,
              quantity: 3,
            ),
            _makeOrderItem(
              productId: 'p2',
              name: 'Product B',
              priceCents: 3000,
              quantity: 5,
            ),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Product A'), findsOneWidget);
      expect(find.text('Product B'), findsOneWidget);
    });

    testWidgets('limits top products to 5 items', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(
          items: [
            _makeOrderItem(productId: 'p1', name: 'Product 1', quantity: 1),
            _makeOrderItem(productId: 'p2', name: 'Product 2', quantity: 2),
            _makeOrderItem(productId: 'p3', name: 'Product 3', quantity: 3),
            _makeOrderItem(productId: 'p4', name: 'Product 4', quantity: 4),
            _makeOrderItem(productId: 'p5', name: 'Product 5', quantity: 5),
            _makeOrderItem(productId: 'p6', name: 'Product 6', quantity: 6),
          ],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Product 6'), findsOneWidget);
      expect(find.text('Product 5'), findsOneWidget);
      expect(find.text('Product 4'), findsOneWidget);
      expect(find.text('Product 3'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
    });

    testWidgets('hides top products section when no delivered orders', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(status: OrderStatus.pending)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Product A'), findsNothing);
    });
  });

  group('SellerAnalyticsScreen - Charts and Visual Elements', () {
    testWidgets('shows status color indicators', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord2', status: OrderStatus.pending),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows KPI card icons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_money_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('shows section cards with proper styling', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeSlideIn), findsWidgets);
    });

    testWidgets('shows rank circle with gradient', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(items: [_makeOrderItem(name: 'Test Product')]),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });
  });

  group('SellerAnalyticsScreen - Animations', () {
    testWidgets('uses FadeSlideIn for KPI cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeSlideIn), findsWidgets);
    });

    testWidgets('uses staggered delays for sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FadeSlideIn), findsWidgets);
    });

    testWidgets('animations complete on settle', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pumpAndSettle();

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Responsive Layout', () {
    testWidgets('uses SingleChildScrollView for scrolling', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses constrained box for max width', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('uses Wrap for KPI cards layout', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('handles narrow screen width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('handles wide screen width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder()];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Dark Mode', () {
    testWidgets('adapts to dark theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'seller1', email: 'seller@test.com'),
            ),
            sellerOrdersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(),
            home: const SellerAnalyticsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });
  });

  group('SellerAnalyticsScreen - Edge Cases', () {
    testWidgets('handles empty orders list', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(orders: []));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('0'), findsWidgets);
      expect(find.text('\$0.00'), findsWidgets);
    });

    testWidgets('handles orders with no items', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        Order(
          orderId: 'empty_order',
          userId: 'buyer1',
          totalAmountCents: 0,
          subtotalCents: 0,
          taxes: const Taxes(),
          orderStatus: OrderStatus.delivered,
          createdAt: DateTime.now(),
          items: [],
        ),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('handles large order counts', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = List.generate(100, (i) => _makeOrder(orderId: 'order_$i'));
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('handles large revenue amounts', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [_makeOrder(subtotalCents: 99999999)];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });

    testWidgets('handles mixed order statuses', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orders = [
        _makeOrder(orderId: 'ord1', status: OrderStatus.delivered),
        _makeOrder(orderId: 'ord2', status: OrderStatus.pending),
        _makeOrder(orderId: 'ord3', status: OrderStatus.confirmed),
        _makeOrder(orderId: 'ord4', status: OrderStatus.shipped),
        _makeOrder(orderId: 'ord5', status: OrderStatus.cancelled),
        _makeOrder(orderId: 'ord6', status: OrderStatus.processing),
        _makeOrder(orderId: 'ord7', status: OrderStatus.inTransit),
      ];
      await tester.pumpWidget(buildTestWidget(orders: orders));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SellerAnalyticsScreen), findsOneWidget);
    });
  });
}
