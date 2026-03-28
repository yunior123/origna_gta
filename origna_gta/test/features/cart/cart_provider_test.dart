import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/models/models.dart';

import '../../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<CartRepository>(),
  MockSpec<ProductRepository>(),
])
import 'cart_provider_test.mocks.dart';

void main() {
  late MockCartRepository mockCartRepo;
  late MockProductRepository mockProductRepo;
  late ProviderContainer container;

  const testUserId = 'user_123';
  const testProductId = 'prod_1';

  final testCartItem = CartItemModel(
    productId: testProductId,
    quantity: 2,
    productName: 'Test Product',
    priceSnapshot: 5000,
    imageUrls: const ['https://example.com/img.jpg'],
    cartItemId: testProductId,
    createdAt: DateTime.now(),
  );

  final testAddress = Address(
    street: '123 Main St',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5V 3A8',
    country: 'CA',
  );

  setUp(() {
    mockCartRepo = MockCartRepository();
    mockProductRepo = MockProductRepository();
    initTestMocks();
  });

  group('cartItemsProvider', () {
    test('returns stream of cart items', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([testCartItem]));

      when(mockProductRepo.fetchProductsByIds([testProductId]))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final items = await container.read(cartItemsProvider.future);

      expect(items, hasLength(1));
      expect(items.first.productId, equals(testProductId));
      expect(items.first.quantity, equals(2));

      container.dispose();
    });

    test('returns empty list when user is not logged in', () {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      final emptyContainer = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(null),
        ],
      );

      final items = emptyContainer.read(cartItemsProvider);

      items.whenData((data) {
        expect(data, isEmpty);
      });

      emptyContainer.dispose();
    });
  });

  group('cartItemCountProvider', () {
    test('calculates total item count correctly', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([testCartItem]));

      when(mockProductRepo.fetchProductsByIds([testProductId]))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      await container.read(cartItemsProvider.future);

      final count = container.read(cartItemCountProvider);

      expect(count, equals(2));

      container.dispose();
    });

    test('returns 0 when cart is empty', () {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      final emptyContainer = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final count = emptyContainer.read(cartItemCountProvider);

      expect(count, equals(0));

      emptyContainer.dispose();
    });
  });

  group('cartSubtotalProvider', () {
    test('calculates subtotal in cents correctly', () async {
      final testCartItemDetail = CartItemDetailModel(
        productId: testProductId,
        name: 'Test Product',
        description: 'Test description',
        price: 50.00,
        priceCents: 5000,
        quantity: 2,
        sellerId: 'seller_1',
        sellerName: 'Seller 1',
        imageUrls: const [],
        createdAt: DateTime.now(),
        sellerAddress: testAddress,
        estimatedShipDays: 3,
        deliveryOptions: const [],
        minimumOrderQuantity: 1,
        freeShipping: false,
        isDigital: false,
      );

      container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [testCartItemDetail],
          ),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      await container.read(cartWithDetailsProvider.future);

      final subtotal = container.read(cartSubtotalProvider);

      expect(subtotal, equals(10000));

      container.dispose();
    });

    test('returns 0 when cart is empty', () {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      final emptyContainer = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final subtotal = emptyContainer.read(cartSubtotalProvider);

      expect(subtotal, equals(0));

      emptyContainer.dispose();
    });
  });

  group('CartController', () {
    test('addToCart returns false when user is not logged in', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          userIdProvider.overrideWithValue(null),
        ],
      );

      final emptyController = emptyContainer.read(cartControllerProvider);
      final result = await emptyController.addToCart(testProductId, 1);

      expect(result, false);

      emptyContainer.dispose();
    });

    test('addToCart returns false when user is the seller', () async {
      when(mockCartRepo.getProductSellerId(testProductId))
          .thenAnswer((_) async => testUserId);

      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart(testProductId, 1);

      expect(result, false);

      container.dispose();
    });

    test('removeFromCart calls repository', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.removeFromCart(testUserId, testProductId))
          .thenAnswer((_) async {});

      await controller.removeFromCart(testProductId);

      verify(mockCartRepo.removeFromCart(testUserId, testProductId)).called(1);

      container.dispose();
    });

    test('updateQuantity calls repository', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.updateQuantity(testUserId, testProductId, 5))
          .thenAnswer((_) async {});

      final result = await controller.updateQuantity(testProductId, 5);

      expect(result, true);
      verify(mockCartRepo.updateQuantity(testUserId, testProductId, 5))
          .called(1);

      container.dispose();
    });

    test('clearCart calls repository', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.clearCart(testUserId)).thenAnswer((_) async {});

      await controller.clearCart();

      verify(mockCartRepo.clearCart(testUserId)).called(1);

      container.dispose();
    });

    test('canAddToCart returns false for own product', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.getProductSellerId(testProductId))
          .thenAnswer((_) async => testUserId);

      final result = await controller.canAddToCart(testProductId);

      expect(result, false);

      container.dispose();
    });

    test('canAddToCart returns true for other seller product', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.getProductSellerId(testProductId))
          .thenAnswer((_) async => 'other_seller');

      final result = await controller.canAddToCart(testProductId);

      expect(result, true);

      container.dispose();
    });

    test('saveForLater toggles favorite and removes from cart', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockProductRepo.toggleFavorite(testUserId, testProductId))
          .thenAnswer((_) async {});
      when(mockCartRepo.removeFromCart(testUserId, testProductId))
          .thenAnswer((_) async {});

      final result = await controller.saveForLater(testProductId, testProductId);

      expect(result, true);
      verify(mockProductRepo.toggleFavorite(testUserId, testProductId))
          .called(1);
      verify(mockCartRepo.removeFromCart(testUserId, testProductId)).called(1);

      container.dispose();
    });

    test('updateBuyerNote calls repository', () async {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final controller = container.read(cartControllerProvider);

      when(mockCartRepo.updateBuyerNote(testUserId, testProductId, 'Test note'))
          .thenAnswer((_) async {});

      await controller.updateBuyerNote(testProductId, 'Test note');

      verify(mockCartRepo.updateBuyerNote(testUserId, testProductId, 'Test note'))
          .called(1);

      container.dispose();
    });
  });

  group('deliveryInstructionsProvider', () {
    test('has default empty value', () {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      final instructions = container.read(deliveryInstructionsProvider);

      expect(instructions, isEmpty);

      container.dispose();
    });

    test('can be updated', () {
      when(mockCartRepo.watchCart(testUserId))
          .thenAnswer((_) => Stream.value([]));

      when(mockProductRepo.fetchProductsByIds(any))
          .thenAnswer((_) async => []);

      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          productRepositoryProvider.overrideWithValue(mockProductRepo),
          userIdProvider.overrideWithValue(testUserId),
        ],
      );

      container.read(deliveryInstructionsProvider.notifier).state =
          'Leave at door';

      final instructions = container.read(deliveryInstructionsProvider);

      expect(instructions, equals('Leave at door'));

      container.dispose();
    });
  });
}
