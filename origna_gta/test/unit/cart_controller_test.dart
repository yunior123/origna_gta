import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';

@GenerateNiceMocks([
  MockSpec<CartRepository>(),
  MockSpec<ProductRepository>(),
])
import 'cart_controller_test.mocks.dart';

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
        userIdProvider.overrideWithValue('user_123'),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CartController Unit Tests', () {
    test('addToCart returns false if user is seller of the product', () async {
      final controller = container.read(cartControllerProvider);
      when(mockRepo.getProductSellerId('prod_123')).thenAnswer((_) async => 'user_123');
      
      final result = await controller.addToCart('prod_123', 1);
      
      expect(result, isFalse);
      verifyNever(mockRepo.addToCart(any, any, any));
    });

    test('addToCart calls repository if valid', () async {
      final controller = container.read(cartControllerProvider);
      when(mockRepo.getProductSellerId('prod_123')).thenAnswer((_) async => 'seller_456');
      
      final result = await controller.addToCart('prod_123', 2);
      
      expect(result, isTrue);
      verify(mockRepo.addToCart('user_123', 'prod_123', 2, variantId: anyNamed('variantId'))).called(1);
    });

    test('canAddToCart returns correct value', () async {
      final controller = container.read(cartControllerProvider);
      when(mockRepo.getProductSellerId('prod_123')).thenAnswer((_) async => 'seller_456');
      expect(await controller.canAddToCart('prod_123'), isTrue);
      
      when(mockRepo.getProductSellerId('prod_789')).thenAnswer((_) async => 'user_123');
      expect(await controller.canAddToCart('prod_789'), isFalse);
    });

    test('clearCart calls repository', () async {
      final controller = container.read(cartControllerProvider);
      await controller.clearCart();
      verify(mockRepo.clearCart('user_123')).called(1);
    });

    test('removeFromCart calls repository', () async {
      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('cart_item_123');
      verify(mockRepo.removeFromCart('user_123', 'cart_item_123')).called(1);
    });

    test('saveForLater toggles favorite and removes from cart', () async {
      final controller = container.read(cartControllerProvider);
      when(mockProductRepository.toggleFavorite(any, any))
          .thenAnswer((_) async { return null; });
      
      final result = await controller.saveForLater('prod_123', 'cart_item_456');
      
      expect(result, isTrue);
      verify(mockProductRepository.toggleFavorite('user_123', 'prod_123'))
          .called(1);
      verify(mockRepo.removeFromCart('user_123', 'cart_item_456')).called(1);
    });
  });
}
