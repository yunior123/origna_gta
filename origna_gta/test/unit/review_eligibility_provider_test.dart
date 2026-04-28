import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/products/review_eligibility_provider.dart';
import 'package:origna_gta/models/generated/models.dart';

Order _makeOrder({
  required String orderId,
  required String userId,
  required OrderStatus status,
  required List<OrderItem> items,
  List<Ratings> ratings = const [],
}) {
  return Order(
    orderId: orderId,
    userId: userId,
    items: items,
    totalAmountCents: 1000,
    subtotalCents: 900,
    taxes: const Taxes(),
    orderStatus: status,
    createdAt: DateTime(2026, 1, 1),
    ratings: ratings,
  );
}

OrderItem _makeItem(String productId) => OrderItem(
  productId: productId,
  name: 'Test Product',
  description: 'desc',
  priceCents: 1000,
  quantity: 1,
  imageUrls: const [],
  sellerId: 'seller-1',
);

void main() {
  group('ReviewEligibility', () {
    test(
      'canReview is true when eligibleOrderId is set and not already reviewed',
      () {
        const e = ReviewEligibility(eligibleOrderId: 'order-1');
        expect(e.canReview, isTrue);
        expect(e.alreadyReviewed, isFalse);
      },
    );

    test('canReview is false when already reviewed', () {
      const e = ReviewEligibility(
        eligibleOrderId: 'order-1',
        alreadyReviewed: true,
      );
      expect(e.canReview, isFalse);
    });

    test('canReview is false when no eligible order', () {
      const e = ReviewEligibility();
      expect(e.canReview, isFalse);
    });
  });

  group('reviewEligibilityProvider', () {
    test('returns empty eligibility when user is not logged in', () {
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue(null),
          buyerOrdersProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(reviewEligibilityProvider('product-1'));
      expect(result.value?.canReview, isFalse);
      expect(result.value?.alreadyReviewed, isFalse);
    });

    test(
      'returns canReview=true for delivered order with matching product',
      () async {
        final orders = [
          _makeOrder(
            orderId: 'order-1',
            userId: 'user-1',
            status: OrderStatus.delivered,
            items: [_makeItem('product-1')],
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            userIdProvider.overrideWithValue('user-1'),
            buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
          ],
        );
        addTearDown(container.dispose);

        // Wait for the stream to emit
        await container.read(buyerOrdersProvider.future);

        final result = container.read(reviewEligibilityProvider('product-1'));
        expect(result.value?.canReview, isTrue);
        expect(result.value?.eligibleOrderId, 'order-1');
      },
    );

    test(
      'returns alreadyReviewed=true when product was already rated',
      () async {
        final orders = [
          _makeOrder(
            orderId: 'order-1',
            userId: 'user-1',
            status: OrderStatus.delivered,
            items: [_makeItem('product-1')],
            ratings: [
              Ratings(
                productId: 'product-1',
                rating: 5,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            userIdProvider.overrideWithValue('user-1'),
            buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(buyerOrdersProvider.future);

        final result = container.read(reviewEligibilityProvider('product-1'));
        expect(result.value?.alreadyReviewed, isTrue);
        expect(result.value?.canReview, isFalse);
      },
    );

    test('returns no eligibility for pending orders', () async {
      final orders = [
        _makeOrder(
          orderId: 'order-1',
          userId: 'user-1',
          status: OrderStatus.pending,
          items: [_makeItem('product-1')],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user-1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(buyerOrdersProvider.future);

      final result = container.read(reviewEligibilityProvider('product-1'));
      expect(result.value?.canReview, isFalse);
      expect(result.value?.eligibleOrderId, isNull);
    });

    test('returns no eligibility for unrelated product', () async {
      final orders = [
        _makeOrder(
          orderId: 'order-1',
          userId: 'user-1',
          status: OrderStatus.delivered,
          items: [_makeItem('product-other')],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user-1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(buyerOrdersProvider.future);

      final result = container.read(reviewEligibilityProvider('product-1'));
      expect(result.value?.canReview, isFalse);
    });

    test('returns canReview=true for confirmed order', () async {
      final orders = [
        _makeOrder(
          orderId: 'order-1',
          userId: 'user-1',
          status: OrderStatus.confirmed,
          items: [_makeItem('product-1')],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user-1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(buyerOrdersProvider.future);

      final result = container.read(reviewEligibilityProvider('product-1'));
      expect(result.value?.canReview, isTrue);
    });

    test('returns canReview=true for shipped order', () async {
      final orders = [
        _makeOrder(
          orderId: 'order-1',
          userId: 'user-1',
          status: OrderStatus.shipped,
          items: [_makeItem('product-1')],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue('user-1'),
          buyerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(buyerOrdersProvider.future);

      final result = container.read(reviewEligibilityProvider('product-1'));
      expect(result.value?.canReview, isTrue);
    });
  });
}
