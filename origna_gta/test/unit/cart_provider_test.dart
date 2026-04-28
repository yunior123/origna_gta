import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([MockSpec<CartRepository>()])
import 'cart_provider_test.mocks.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class StubProductRepository extends Fake implements ProductRepository {
  @override
  Future<List<Product>> fetchProductsByIds(List<String> productIds) async => [];
}

void main() {
  late MockCartRepository mockRepo;
  late MockProductRepository mockProductRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockCartRepository();
    mockProductRepository = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockRepo),
        productRepositoryProvider.overrideWithValue(mockProductRepository),
        userIdProvider.overrideWith((ref) => 'user_123'),
      ],
    );
  });

  group('CartController Tests', () {
    test('addToCart calls repository', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller_456');
      when(
        mockRepo.addToCart(any, any, any, variantId: anyNamed('variantId')),
      ).thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 2);

      expect(success, isTrue);
      verify(mockRepo.addToCart('user_123', 'p1', 2)).called(1);
    });

    test('addToCart fails if own product', () async {
      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'user_123');

      final controller = container.read(cartControllerProvider);
      final success = await controller.addToCart('p1', 2);

      expect(success, isFalse);
      verifyNever(mockRepo.addToCart(any, any, any));
    });

    test('updateQuantity calls repository', () async {
      final controller = container.read(cartControllerProvider);
      await controller.updateQuantity('item_1', 5);

      verify(mockRepo.updateQuantity('user_123', 'item_1', 5)).called(1);
    });

    test('removeFromCart calls repository', () async {
      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('item_1');

      verify(mockRepo.removeFromCart('user_123', 'item_1')).called(1);
    });
  });

  group('Cart Providers Tests', () {
    test('cartItemCountProvider computes total', () async {
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
                quantity: 3,
                createdAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      // Wait for the stream to emit
      await container.read(cartItemsProvider.future);

      final count = container.read(cartItemCountProvider);
      expect(count, 5);
    });

    test(
      'cartItemDetailProvider preserves snapshot data for missing products',
      () async {
        final createdAt = DateTime.now();
        final container = ProviderContainer(
          overrides: [
            productRepositoryProvider.overrideWithValue(
              StubProductRepository(),
            ),
            cartItemsProvider.overrideWith(
              (ref) => Stream.value([
                CartItemModel(
                  cartItemId: 'p1',
                  productId: 'p1',
                  quantity: 2,
                  createdAt: createdAt,
                  productName: 'Archived Product',
                  productDescription: 'Saved in cart',
                  imageUrls: const ['https://example.com/p1.png'],
                  priceSnapshot: 2599,
                ),
              ]),
            ),
          ],
        );

        await container.read(cartItemsProvider.future);
        final detail = await container.read(
          cartItemDetailProvider('p1').future,
        );

        expect(detail, isNotNull);
        expect(detail!.name, 'Archived Product');
        expect(detail.priceCents, 2599);
        expect(detail.price, 25.99);
        expect(detail.imageUrls, ['https://example.com/p1.png']);
      },
    );
  });
}
