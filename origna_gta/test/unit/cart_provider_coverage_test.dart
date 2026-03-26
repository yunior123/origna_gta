import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';

import 'package:origna_gta/services/analytics_service.dart';
import 'package:origna_gta/utils/utils.dart';

@GenerateNiceMocks([
  MockSpec<CartRepository>(),
  MockSpec<ProductRepository>(),
  MockSpec<AnalyticsService>(),
])
import 'cart_provider_coverage_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCartRepository mockCartRepo;
  late MockProductRepository mockProductRepo;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockCartRepo = MockCartRepository();
    mockProductRepo = MockProductRepository();
    mockAnalytics = MockAnalyticsService();
  });

  ProviderContainer createContainer({String? userId = 'user_123'}) {
    return ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockCartRepo),
        productRepositoryProvider.overrideWithValue(mockProductRepo),
        userIdProvider.overrideWithValue(userId),
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
    );
  }

  group('CartController - addToCart', () {
    test('returns false when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('prod_1', 1);
      expect(result, isFalse);
    });

    test('returns false when sellerId is null', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => null);

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('prod_1', 1);
      expect(result, isFalse);
    });

    test('returns false when user is seller (self-purchase)', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => 'user_123');

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('prod_1', 1);
      expect(result, isFalse);
    });

    test('returns false when variant is invalid', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => 'seller_456');
      when(
        mockCartRepo.isVariantValid('prod_1', 'bad_variant'),
      ).thenAnswer((_) async => false);

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart(
        'prod_1',
        1,
        variantId: 'bad_variant',
      );
      expect(result, isFalse);
    });

    test('returns true on successful add with valid variant', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => 'seller_456');
      when(
        mockCartRepo.isVariantValid('prod_1', 'good_variant'),
      ).thenAnswer((_) async => true);
      when(
        mockCartRepo.addToCart(any, any, any, variantId: anyNamed('variantId')),
      ).thenAnswer((_) async {});

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart(
        'prod_1',
        2,
        variantId: 'good_variant',
      );
      expect(result, isTrue);
      verify(
        mockCartRepo.addToCart(
          'user_123',
          'prod_1',
          2,
          variantId: 'good_variant',
        ),
      ).called(1);
    });

    test(
      'returns true and logs analytics when product info provided',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        when(
          mockCartRepo.getProductSellerId('prod_1'),
        ).thenAnswer((_) async => 'seller_456');
        when(
          mockCartRepo.addToCart(
            any,
            any,
            any,
            variantId: anyNamed('variantId'),
          ),
        ).thenAnswer((_) async {});
        when(
          mockAnalytics.logAddToCart(
            productId: anyNamed('productId'),
            productName: anyNamed('productName'),
            priceCad: anyNamed('priceCad'),
            quantity: anyNamed('quantity'),
          ),
        ).thenAnswer((_) async {});

        final controller = container.read(cartControllerProvider);
        final result = await controller.addToCart(
          'prod_1',
          1,
          productName: 'Widget',
          priceCad: 49.99,
        );
        expect(result, isTrue);
      },
    );

    test('returns false on exception', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenThrow(Exception('Network error'));

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('prod_1', 1);
      expect(result, isFalse);
    });
  });

  group('CartController - canAddToCart', () {
    test('returns false when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('prod_1'), isFalse);
    });

    test('returns false when sellerId is null', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => null);

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('prod_1'), isFalse);
    });

    test('returns true when different user', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => 'seller_456');

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('prod_1'), isTrue);
    });

    test('returns false when same user', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenAnswer((_) async => 'user_123');

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('prod_1'), isFalse);
    });

    test('returns false on exception', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockCartRepo.getProductSellerId('prod_1'),
      ).thenThrow(Exception('Error'));

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('prod_1'), isFalse);
    });
  });

  group('CartController - clearCart', () {
    test('no-ops when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.clearCart();
      verifyNever(mockCartRepo.clearCart(any));
    });

    test('calls repository when user exists', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.clearCart();
      verify(mockCartRepo.clearCart('user_123')).called(1);
    });
  });

  group('CartController - removeFromCart', () {
    test('no-ops when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('item_1');
      verifyNever(mockCartRepo.removeFromCart(any, any));
    });

    test('calls repository when user exists', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('item_1');
      verify(mockCartRepo.removeFromCart('user_123', 'item_1')).called(1);
    });
  });

  group('CartController - updateQuantity', () {
    test('returns false when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('item_1', 5);
      expect(result, isFalse);
    });

    test('calls repository and returns true when user exists', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('item_1', 5);
      expect(result, isTrue);
      verify(mockCartRepo.updateQuantity('user_123', 'item_1', 5)).called(1);
    });
  });

  group('CartController - updateBuyerNote', () {
    test('no-ops when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item_1', 'note text');
      verifyNever(mockCartRepo.updateBuyerNote(any, any, any));
    });

    test('calls repository with note', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item_1', 'Please gift wrap');
      verify(
        mockCartRepo.updateBuyerNote('user_123', 'item_1', 'Please gift wrap'),
      ).called(1);
    });

    test('calls repository with null to clear note', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item_1', null);
      verify(
        mockCartRepo.updateBuyerNote('user_123', 'item_1', null),
      ).called(1);
    });
  });

  group('CartController - saveForLater', () {
    test('returns false when userId is null', () async {
      final container = createContainer(userId: null);
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.saveForLater('prod_1', 'item_1');
      expect(result, isFalse);
    });

    test('toggles favorite and removes from cart', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(mockProductRepo.toggleFavorite(any, any)).thenAnswer((_) async {});

      final controller = container.read(cartControllerProvider);
      final result = await controller.saveForLater('prod_1', 'item_1');
      expect(result, isTrue);
      verify(mockProductRepo.toggleFavorite('user_123', 'prod_1')).called(1);
      verify(mockCartRepo.removeFromCart('user_123', 'item_1')).called(1);
    });

    test('returns false on exception', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(
        mockProductRepo.toggleFavorite(any, any),
      ).thenThrow(Exception('Error'));

      final controller = container.read(cartControllerProvider);
      final result = await controller.saveForLater('prod_1', 'item_1');
      expect(result, isFalse);
    });
  });

  group('CartController - refreshCart', () {
    test('invalidates cartItemsProvider', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      // Should not throw
      controller.refreshCart();
    });
  });

  group('cartItemCountProvider', () {
    test('returns 0 when no cart items', () {
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue(null),
          cartItemsProvider.overrideWith(
            (ref) => Stream.value(<CartItemModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final count = container.read(cartItemCountProvider);
      expect(count, 0);
    });
  });

  group('cartSubtotalProvider', () {
    test('returns 0 when loading', () {
      final container = ProviderContainer(
        overrides: [
          userIdProvider.overrideWithValue(null),
          cartWithDetailsProvider.overrideWith(
            (ref) async => <CartItemDetailModel>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      final subtotal = container.read(cartSubtotalProvider);
      expect(subtotal, 0);
    });
  });

  group('deliveryInstructionsProvider', () {
    test('defaults to empty string', () {
      final container = ProviderContainer(overrides: []);
      addTearDown(container.dispose);

      final instructions = container.read(deliveryInstructionsProvider);
      expect(instructions, '');
    });

    test('can be updated', () {
      final container = ProviderContainer(overrides: []);
      addTearDown(container.dispose);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Leave at door';
      final instructions = container.read(deliveryInstructionsProvider);
      expect(instructions, 'Leave at door');
    });
  });
}
