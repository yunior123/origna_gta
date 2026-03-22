import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([MockSpec<CartRepository>()])
import 'cart_coverage_test.mocks.dart';

void main() {
  late MockCartRepository mockRepo;

  setUp(() {
    mockRepo = MockCartRepository();
  });

  group('CartController - addToCart edge cases', () {
    test('addToCart returns false when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1);
      expect(success, isFalse);
    });

    test('addToCart returns false when sellerId is null', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1);
      expect(success, isFalse);
    });

    test('addToCart returns false when buying own product', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'user_123');

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1);
      expect(success, isFalse);
    });

    test('addToCart with valid variant', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller_456');
      when(mockRepo.isVariantValid('p1', 'v1')).thenAnswer((_) async => true);
      when(
        mockRepo.addToCart(any, any, any, variantId: anyNamed('variantId')),
      ).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1, variantId: 'v1');
      expect(success, isTrue);
      verify(
        mockRepo.addToCart('user_123', 'p1', 1, variantId: 'v1'),
      ).called(1);
    });

    test('addToCart returns false when variant is invalid', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller_456');
      when(mockRepo.isVariantValid('p1', 'v1')).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1, variantId: 'v1');
      expect(success, isFalse);
    });

    test('addToCart catches exception and returns false', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 1);
      expect(success, isFalse);
    });
  });

  group('CartController - canAddToCart', () {
    test('canAddToCart returns false when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');
      expect(result, isFalse);
    });

    test('canAddToCart returns false when sellerId is null', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');
      expect(result, isFalse);
    });

    test('canAddToCart returns true for other sellers product', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller_456');

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');
      expect(result, isTrue);
    });

    test('canAddToCart returns false for own product', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'user_123');

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');
      expect(result, isFalse);
    });

    test('canAddToCart catches exception and returns false', () async {
      when(mockRepo.getProductSellerId('p1')).thenThrow(Exception('db error'));

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');
      expect(result, isFalse);
    });
  });

  group('CartController - other actions', () {
    test('clearCart does nothing when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.clearCart();
      verifyNever(mockRepo.clearCart(any));
    });

    test('clearCart calls repository when userId exists', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.clearCart();
      verify(mockRepo.clearCart('user_123')).called(1);
    });

    test('removeFromCart does nothing when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('item_1');
      verifyNever(mockRepo.removeFromCart(any, any));
    });

    test('updateQuantity does nothing when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('item_1', 3);
      expect(result, isFalse);
    });

    test('updateQuantity returns true on success', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('item_1', 5);
      expect(result, isTrue);
      verify(mockRepo.updateQuantity('user_123', 'item_1', 5)).called(1);
    });

    test('updateBuyerNote does nothing when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item_1', 'note');
      verifyNever(mockRepo.updateBuyerNote(any, any, any));
    });

    test('updateBuyerNote calls repository when userId exists', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item_1', 'Leave at door');
      verify(
        mockRepo.updateBuyerNote('user_123', 'item_1', 'Leave at door'),
      ).called(1);
    });

    test('saveForLater does nothing when userId is null', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.saveForLater('p1', 'item_1');
      expect(result, isFalse);
    });

    test('saveForLater catches exception and returns false', () async {
      when(
        mockRepo.removeFromCart('user_123', 'item_1'),
      ).thenThrow(Exception('remove failed'));

      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.saveForLater('p1', 'item_1');
      expect(result, isFalse);
    });
  });

  group('Cart item count provider', () {
    test('cartItemCountProvider returns 0 when loading', () {
      final container = ProviderContainer(
        overrides: [
          cartItemsProvider.overrideWith(
            (ref) => Stream.error(Exception('loading')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final count = container.read(cartItemCountProvider);
      expect(count, 0);
    });

    test('cartItemCountProvider sums quantities correctly', () async {
      final container = ProviderContainer(
        overrides: [
          cartItemsProvider.overrideWith(
            (ref) => Stream.value([
              CartItemModel(
                cartItemId: 'i1',
                productId: 'p1',
                quantity: 2,
                createdAt: DateTime.now(),
              ),
              CartItemModel(
                cartItemId: 'i2',
                productId: 'p2',
                quantity: 5,
                createdAt: DateTime.now(),
              ),
              CartItemModel(
                cartItemId: 'i3',
                productId: 'p3',
                quantity: 1,
                createdAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(cartItemsProvider.future);
      final count = container.read(cartItemCountProvider);
      expect(count, 8);
    });

    test('cartItemCountProvider returns 0 for empty cart', () async {
      final container = ProviderContainer(
        overrides: [cartItemsProvider.overrideWith((ref) => Stream.value([]))],
      );
      addTearDown(container.dispose);

      await container.read(cartItemsProvider.future);
      final count = container.read(cartItemCountProvider);
      expect(count, 0);
    });
  });

  group('deliveryInstructionsProvider', () {
    test('defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final val = container.read(deliveryInstructionsProvider);
      expect(val, '');
    });

    test('can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Leave at front door';
      expect(
        container.read(deliveryInstructionsProvider),
        'Leave at front door',
      );
    });
  });
}
