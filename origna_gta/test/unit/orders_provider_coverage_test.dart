import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

// Helper to create minimal Order for testing
models.Order _makeOrder({
  required String orderId,
  String userId = 'user_1',
  models.OrderStatus orderStatus = models.OrderStatus.pending,
  int subtotalCents = 10000,
  int platformFeeTotalCents = 500,
  int totalAmountCents = 11000,
  List<models.OrderItem>? items,
  models.ShippingApprovalStatus shippingApprovalStatus =
      models.ShippingApprovalStatus.notRequired,
}) {
  return models.Order(
    orderId: orderId,
    userId: userId,
    items: items ?? [],
    totalAmountCents: totalAmountCents,
    subtotalCents: subtotalCents,
    platformFeeTotalCents: platformFeeTotalCents,
    taxes: const models.Taxes(),
    createdAt: DateTime(2026, 1, 1),
    orderStatus: orderStatus,
    shippingApprovalStatus: shippingApprovalStatus,
  );
}

models.OrderItem _makeItem({
  String productId = 'prod_1',
  String sellerId = 'seller_1',
  int priceCents = 5000,
  int quantity = 2,
}) {
  return models.OrderItem(
    productId: productId,
    name: 'Test Product',
    description: 'A test product',
    priceCents: priceCents,
    quantity: quantity,
    imageUrls: const [],
    sellerId: sellerId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrderResult types', () {
    test('OrderSuccess holds message', () {
      final success = OrderSuccess(message: 'Order placed');
      expect(success.message, 'Order placed');
    });

    test('OrderError holds message and optional code', () {
      final error = OrderError(message: 'Failed', code: 'E001');
      expect(error.message, 'Failed');
      expect(error.code, 'E001');
    });

    test('OrderError code defaults to null', () {
      final error = OrderError(message: 'Failed');
      expect(error.code, isNull);
    });

    test('OrderSuccess is OrderResult', () {
      final result = OrderSuccess(message: 'ok');
      expect(result, isA<OrderResult>());
    });

    test('OrderError is OrderResult', () {
      final result = OrderError(message: 'err');
      expect(result, isA<OrderResult>());
    });
  });

  group('SellerEarningsSummary', () {
    test('defaults all fields to 0', () {
      const summary = SellerEarningsSummary();
      expect(summary.totalRevenueCents, 0);
      expect(summary.pendingCount, 0);
      expect(summary.completedCount, 0);
    });

    test('constructs with provided values', () {
      const summary = SellerEarningsSummary(
        totalRevenueCents: 50000,
        pendingCount: 3,
        completedCount: 7,
      );
      expect(summary.totalRevenueCents, 50000);
      expect(summary.pendingCount, 3);
      expect(summary.completedCount, 7);
    });
  });

  group('SellerOrderNetAmounts', () {
    test('constructs with required values', () {
      const amounts = SellerOrderNetAmounts(
        sellerTotal: 10000,
        platformFee: 250,
        sellerNet: 9750,
      );
      expect(amounts.sellerTotal, 10000);
      expect(amounts.platformFee, 250);
      expect(amounts.sellerNet, 9750);
    });
  });

  group('sellerEarningsSummaryProvider', () {
    test('returns default when userId is null', () {
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue(null),
          sellerOrdersProvider.overrideWith(
            (ref) => Stream.value(<models.Order>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final summary = container.read(sellerEarningsSummaryProvider);
      expect(summary.totalRevenueCents, 0);
      expect(summary.pendingCount, 0);
      expect(summary.completedCount, 0);
    });

    test('computes correct earnings from seller orders', () async {
      final orders = [
        _makeOrder(
          orderId: 'o1',
          orderStatus: models.OrderStatus.delivered,
          subtotalCents: 10000,
          platformFeeTotalCents: 800,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 5000, quantity: 2),
          ],
        ),
        _makeOrder(
          orderId: 'o2',
          orderStatus: models.OrderStatus.confirmed,
          subtotalCents: 5000,
          platformFeeTotalCents: 400,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 2500, quantity: 2),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('seller_1'),
          sellerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      // Listen and wait for the stream to emit data
      container.listen(sellerOrdersProvider, (_, _) {});
      await container.read(sellerOrdersProvider.future);

      final summary = container.read(sellerEarningsSummaryProvider);
      expect(summary.completedCount, 1);
      expect(summary.pendingCount, 1);
    });

    test('excludes cancelled/failed/expired orders from pending count', () {
      final orders = [
        _makeOrder(
          orderId: 'o1',
          orderStatus: models.OrderStatus.cancelled,
          subtotalCents: 5000,
          platformFeeTotalCents: 400,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 5000, quantity: 1),
          ],
        ),
        _makeOrder(
          orderId: 'o2',
          orderStatus: models.OrderStatus.failed,
          subtotalCents: 3000,
          platformFeeTotalCents: 240,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 3000, quantity: 1),
          ],
        ),
        _makeOrder(
          orderId: 'o3',
          orderStatus: models.OrderStatus.expired,
          subtotalCents: 2000,
          platformFeeTotalCents: 160,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 2000, quantity: 1),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('seller_1'),
          sellerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      container.read(sellerOrdersProvider);
      final summary = container.read(sellerEarningsSummaryProvider);
      expect(summary.pendingCount, 0);
      expect(summary.completedCount, 0);
    });
  });

  group('sellerOrderNetProvider', () {
    test('returns zero amounts when order not found', () {
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('seller_1'),
          sellerOrdersProvider.overrideWith(
            (ref) => Stream.value(<models.Order>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(sellerOrdersProvider);
      final amounts = container.read(
        sellerOrderNetProvider((orderId: 'missing', sellerId: 'seller_1')),
      );
      expect(amounts.sellerTotal, 0);
      expect(amounts.platformFee, 0);
      expect(amounts.sellerNet, 0);
    });

    test('computes correct net amounts for seller items', () async {
      final orders = [
        _makeOrder(
          orderId: 'o1',
          subtotalCents: 10000,
          platformFeeTotalCents: 800,
          items: [
            _makeItem(sellerId: 'seller_1', priceCents: 5000, quantity: 1),
            _makeItem(sellerId: 'other_seller', priceCents: 5000, quantity: 1),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('seller_1'),
          sellerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      // Listen and wait for the stream to emit data
      container.listen(sellerOrdersProvider, (_, _) {});
      await container.read(sellerOrdersProvider.future);

      final amounts = container.read(
        sellerOrderNetProvider((orderId: 'o1', sellerId: 'seller_1')),
      );
      // sellerTotal = 5000/100 * 1 = 50.0
      expect(amounts.sellerTotal, 50.0);
      expect(amounts.platformFee, greaterThan(0));
      expect(amounts.sellerNet, lessThan(amounts.sellerTotal));
    });
  });

  group('pendingApprovalsCountProvider', () {
    test('returns 0 when no pending approvals', () {
      final orders = [
        _makeOrder(
          orderId: 'o1',
          shippingApprovalStatus: models.ShippingApprovalStatus.notRequired,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user_1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      container.read(buyerOrdersProvider);
      final count = container.read(pendingApprovalsCountProvider);
      expect(count, 0);
    });

    test('counts pending shipping approvals', () async {
      final orders = [
        _makeOrder(
          orderId: 'o1',
          shippingApprovalStatus: models.ShippingApprovalStatus.pending,
        ),
        _makeOrder(
          orderId: 'o2',
          shippingApprovalStatus: models.ShippingApprovalStatus.pending,
        ),
        _makeOrder(
          orderId: 'o3',
          shippingApprovalStatus: models.ShippingApprovalStatus.notRequired,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user_1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      // Listen and wait for the stream to emit data
      container.listen(buyerOrdersProvider, (_, _) {});
      await container.read(buyerOrdersProvider.future);

      final count = container.read(pendingApprovalsCountProvider);
      expect(count, 2);
    });
  });

  group('buyerOrdersProvider', () {
    test('returns empty list when userId is null', () async {
      final container = ProviderContainer(
        overrides: [userIdProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      final ordersAsync = container.read(buyerOrdersProvider);
      expect(ordersAsync, isA<AsyncValue<List<models.Order>>>());
    });
  });

  group('sellerOrdersProvider', () {
    test('returns empty list when userId is null', () async {
      final container = ProviderContainer(
        overrides: [userIdProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      final ordersAsync = container.read(sellerOrdersProvider);
      expect(ordersAsync, isA<AsyncValue<List<models.Order>>>());
    });
  });
}
