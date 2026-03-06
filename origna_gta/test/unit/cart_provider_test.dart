import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@GenerateNiceMocks([MockSpec<CartRepository>(), MockSpec<FirebaseFirestore>()])
import 'cart_provider_test.mocks.dart';

void main() {
  late MockCartRepository mockRepo;
  late MockFirebaseFirestore mockFirestore;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockCartRepository();
    mockFirestore = MockFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockRepo),
        firestoreProvider.overrideWithValue(mockFirestore),
        userIdProvider.overrideWith((ref) => 'test_user'),
      ],
    );
  });

  group('CartController', () {
    test('addToCart success', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => 'other_seller');
      when(mockRepo.addToCart('test_user', 'p1', 1, variantId: null))
          .thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('p1', 1);

      expect(result, isTrue);
      verify(mockRepo.addToCart('test_user', 'p1', 1, variantId: null)).called(1);
    });

    test('addToCart fails if user is seller', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => 'test_user');

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('p1', 1);

      expect(result, isFalse);
      verifyNever(mockRepo.addToCart(any, any, any, variantId: anyNamed('variantId')));
    });

    test('updateQuantity success', () async {
      when(mockRepo.updateQuantity('test_user', 'c1', 2))
          .thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('c1', 2);

      expect(result, isTrue);
      verify(mockRepo.updateQuantity('test_user', 'c1', 2)).called(1);
    });

    test('removeFromCart success', () async {
      when(mockRepo.removeFromCart('test_user', 'c1'))
          .thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      await controller.removeFromCart('c1');

      verify(mockRepo.removeFromCart('test_user', 'c1')).called(1);
    });

    test('clearCart success', () async {
      when(mockRepo.clearCart('test_user'))
          .thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      await controller.clearCart();

      verify(mockRepo.clearCart('test_user')).called(1);
    });

    test('canAddToCart returns true for other seller', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => 'other_seller');

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');

      expect(result, isTrue);
    });

    test('canAddToCart returns false for own product', () async {
      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => 'test_user');

      final controller = container.read(cartControllerProvider);
      final result = await controller.canAddToCart('p1');

      expect(result, isFalse);
    });

    test('updateBuyerNote success', () async {
      when(mockRepo.updateBuyerNote('test_user', 'c1', 'note'))
          .thenAnswer((_) async => {});

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('c1', 'note');

      verify(mockRepo.updateBuyerNote('test_user', 'c1', 'note')).called(1);
    });
  });
}
