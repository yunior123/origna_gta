import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'cart_provider_comprehensive_test2.mocks.dart';

@GenerateNiceMocks([MockSpec<CartRepository>(), MockSpec<ProductRepository>()])
void main() {
  late MockCartRepository mockCartRepository;
  late MockProductRepository mockProductRepository;
  late ProviderContainer container;

  const testUserId = 'test-user-123';
  const testProductId = 'product-123';
  const testCartItemId = 'cart-item-123';
  const testSellerId = 'seller-456';
  const testVariantId = 'variant-789';

  setUp(() {
    mockCartRepository = MockCartRepository();
    mockProductRepository = MockProductRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({String? userId}) {
    return ProviderContainer(
      overrides: [
        userIdProvider.overrideWithValue(userId),
        cartRepositoryProvider.overrideWithValue(mockCartRepository),
        productRepositoryProvider.overrideWithValue(mockProductRepository),
      ],
    );
  }

  group('CartController - addToCart', () {
    test('returns false when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      final result = await controller.addToCart(testProductId, 1);

      expect(result, isFalse);
      verifyNever(mockCartRepository.addToCart(any, any, any));
    });

    test('returns false when product seller ID is null', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => null);

      final result = await controller.addToCart(testProductId, 1);

      expect(result, isFalse);
      verify(mockCartRepository.getProductSellerId(testProductId)).called(1);
      verifyNever(mockCartRepository.addToCart(any, any, any));
    });

    test('returns false when user tries to buy their own product', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testUserId);

      final result = await controller.addToCart(testProductId, 1);

      expect(result, isFalse);
      verify(mockCartRepository.getProductSellerId(testProductId)).called(1);
      verifyNever(mockCartRepository.addToCart(any, any, any));
    });

    test('returns false when variant ID is invalid', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testSellerId);
      when(
        mockCartRepository.isVariantValid(testProductId, testVariantId),
      ).thenAnswer((_) async => false);

      final result = await controller.addToCart(
        testProductId,
        1,
        variantId: testVariantId,
      );

      expect(result, isFalse);
      verify(mockCartRepository.getProductSellerId(testProductId)).called(1);
      verify(
        mockCartRepository.isVariantValid(testProductId, testVariantId),
      ).called(1);
      verifyNever(mockCartRepository.addToCart(any, any, any));
    });

    test('returns true and adds to cart successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testSellerId);
      when(
        mockCartRepository.addToCart(any, any, any),
      ).thenAnswer((_) async {});

      final result = await controller.addToCart(testProductId, 2);

      expect(result, isTrue);
      verify(mockCartRepository.getProductSellerId(testProductId)).called(1);
      verify(
        mockCartRepository.addToCart(testUserId, testProductId, 2),
      ).called(1);
    });

    test('adds to cart with variant ID successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testSellerId);
      when(
        mockCartRepository.isVariantValid(testProductId, testVariantId),
      ).thenAnswer((_) async => true);
      when(
        mockCartRepository.addToCart(
          any,
          any,
          any,
          variantId: anyNamed('variantId'),
        ),
      ).thenAnswer((_) async {});

      final result = await controller.addToCart(
        testProductId,
        1,
        variantId: testVariantId,
      );

      expect(result, isTrue);
      verify(
        mockCartRepository.addToCart(
          testUserId,
          testProductId,
          1,
          variantId: testVariantId,
        ),
      ).called(1);
    });

    test('returns false on exception', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenThrow(Exception('Network error'));

      final result = await controller.addToCart(testProductId, 1);

      expect(result, isFalse);
    });
  });

  group('CartController - canAddToCart', () {
    test('returns false when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      final result = await controller.canAddToCart(testProductId);

      expect(result, isFalse);
    });

    test('returns false when product seller ID is null', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => null);

      final result = await controller.canAddToCart(testProductId);

      expect(result, isFalse);
    });

    test('returns false when user is the seller', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testUserId);

      final result = await controller.canAddToCart(testProductId);

      expect(result, isFalse);
    });

    test('returns true when user can add product', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenAnswer((_) async => testSellerId);

      final result = await controller.canAddToCart(testProductId);

      expect(result, isTrue);
    });

    test('returns false on exception', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.getProductSellerId(testProductId),
      ).thenThrow(Exception('Network error'));

      final result = await controller.canAddToCart(testProductId);

      expect(result, isFalse);
    });
  });

  group('CartController - removeFromCart', () {
    test('does nothing when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      await controller.removeFromCart(testCartItemId);

      verifyNever(mockCartRepository.removeFromCart(any, any));
    });

    test('removes item from cart successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.removeFromCart(any, any),
      ).thenAnswer((_) async {});

      await controller.removeFromCart(testCartItemId);

      verify(
        mockCartRepository.removeFromCart(testUserId, testCartItemId),
      ).called(1);
    });
  });

  group('CartController - updateQuantity', () {
    test('returns false when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      final result = await controller.updateQuantity(testCartItemId, 3);

      expect(result, isFalse);
      verifyNever(mockCartRepository.updateQuantity(any, any, any));
    });

    test('updates quantity successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.updateQuantity(any, any, any),
      ).thenAnswer((_) async {});

      final result = await controller.updateQuantity(testCartItemId, 5);

      expect(result, isTrue);
      verify(
        mockCartRepository.updateQuantity(testUserId, testCartItemId, 5),
      ).called(1);
    });

    test('updates quantity to 1 successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.updateQuantity(any, any, any),
      ).thenAnswer((_) async {});

      final result = await controller.updateQuantity(testCartItemId, 1);

      expect(result, isTrue);
      verify(
        mockCartRepository.updateQuantity(testUserId, testCartItemId, 1),
      ).called(1);
    });
  });

  group('CartController - clearCart', () {
    test('does nothing when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      await controller.clearCart();

      verifyNever(mockCartRepository.clearCart(any));
    });

    test('clears cart successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(mockCartRepository.clearCart(any)).thenAnswer((_) async {});

      await controller.clearCart();

      verify(mockCartRepository.clearCart(testUserId)).called(1);
    });
  });

  group('CartController - updateBuyerNote', () {
    test('does nothing when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      await controller.updateBuyerNote(testCartItemId, 'Test note');

      verifyNever(mockCartRepository.updateBuyerNote(any, any, any));
    });

    test('updates buyer note successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.updateBuyerNote(any, any, any),
      ).thenAnswer((_) async {});

      await controller.updateBuyerNote(testCartItemId, 'Please gift wrap');

      verify(
        mockCartRepository.updateBuyerNote(
          testUserId,
          testCartItemId,
          'Please gift wrap',
        ),
      ).called(1);
    });

    test('clears buyer note when null passed', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockCartRepository.updateBuyerNote(any, any, any),
      ).thenAnswer((_) async {});

      await controller.updateBuyerNote(testCartItemId, null);

      verify(
        mockCartRepository.updateBuyerNote(testUserId, testCartItemId, null),
      ).called(1);
    });
  });

  group('CartController - saveForLater', () {
    test('returns false when user is not logged in', () async {
      container = createContainer(userId: null);
      final controller = container.read(cartControllerProvider);

      final result = await controller.saveForLater(
        testProductId,
        testCartItemId,
      );

      expect(result, isFalse);
    });

    test('returns true and saves for later successfully', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockProductRepository.toggleFavorite(any, any),
      ).thenAnswer((_) async {});
      when(
        mockCartRepository.removeFromCart(any, any),
      ).thenAnswer((_) async {});

      final result = await controller.saveForLater(
        testProductId,
        testCartItemId,
      );

      expect(result, isTrue);
      verify(
        mockProductRepository.toggleFavorite(testUserId, testProductId),
      ).called(1);
      verify(
        mockCartRepository.removeFromCart(testUserId, testCartItemId),
      ).called(1);
    });

    test('returns false on exception', () async {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      when(
        mockProductRepository.toggleFavorite(any, any),
      ).thenThrow(Exception('Network error'));

      final result = await controller.saveForLater(
        testProductId,
        testCartItemId,
      );

      expect(result, isFalse);
    });
  });

  group('CartController - refreshCart', () {
    test('invalidates cartItemsProvider', () {
      container = createContainer(userId: testUserId);
      final controller = container.read(cartControllerProvider);

      controller.refreshCart();

      expect(container.read(cartItemsProvider), isA<AsyncValue>());
    });
  });

  group('cartItemCountProvider', () {
    test('returns 0 when cart is empty', () {
      container = createContainer(userId: testUserId);
      final count = container.read(cartItemCountProvider);
      expect(count, equals(0));
    });
  });

  group('deliveryInstructionsProvider', () {
    test('defaults to empty string', () {
      container = createContainer(userId: testUserId);
      final instructions = container.read(deliveryInstructionsProvider);
      expect(instructions, equals(''));
    });

    test('can be updated', () {
      container = createContainer(userId: testUserId);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Leave at door';

      final instructions = container.read(deliveryInstructionsProvider);
      expect(instructions, equals('Leave at door'));
    });

    test('can be cleared', () {
      container = createContainer(userId: testUserId);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Ring doorbell';
      container.read(deliveryInstructionsProvider.notifier).state = '';

      final instructions = container.read(deliveryInstructionsProvider);
      expect(instructions, equals(''));
    });
  });

  group('Delivery Options - SellerDeliveryOption', () {
    test('calculates cost for single item', () {
      final option = SellerDeliveryOption(
        type: DeliveryTypeValues.standard,
        description: 'Standard Delivery',
        costCents: 1000,
        estimatedDays: 5,
      );

      final cost = option.calculateCostForQuantity(1);
      expect(cost, equals(10.00));
    });

    test('applies quantity discount percent', () {
      final option = SellerDeliveryOption(
        type: DeliveryTypeValues.standard,
        description: 'Bulk Delivery',
        costCents: 1000,
        estimatedDays: 5,
        quantityDiscounts: [
          ShippingQuantityDiscount(
            minQuantity: 3,
            discountType: 'percent',
            discountValue: 20.0,
          ),
        ],
      );

      final cost = option.calculateCostForQuantity(5);
      expect(cost, closeTo(8.00, 0.01));
    });

    test('applies quantity discount fixed', () {
      final option = SellerDeliveryOption(
        type: DeliveryTypeValues.standard,
        description: 'Bulk Delivery',
        costCents: 1000,
        estimatedDays: 5,
        quantityDiscounts: [
          ShippingQuantityDiscount(
            minQuantity: 2,
            discountType: 'fixed',
            discountValue: 3.0,
          ),
        ],
      );

      final cost = option.calculateCostForQuantity(3);
      expect(cost, closeTo(7.00, 0.01));
    });

    test('applies flat rate discount', () {
      final option = SellerDeliveryOption(
        type: DeliveryTypeValues.standard,
        description: 'Flat Rate Delivery',
        costCents: 2000,
        estimatedDays: 5,
        quantityDiscounts: [
          ShippingQuantityDiscount(
            minQuantity: 5,
            discountType: 'flat_rate',
            discountValue: 5.0,
          ),
        ],
      );

      final cost = option.calculateCostForQuantity(10);
      expect(cost, equals(5.00));
    });

    test('applies additional item costs', () {
      final option = SellerDeliveryOption(
        type: DeliveryTypeValues.standard,
        description: 'Standard Delivery',
        costCents: 1000,
        estimatedDays: 5,
        maxItemsPerShipment: 2,
        additionalItemCostCents: 500,
      );

      // Base cost: 10.00, extra items: 5 - 2 = 3, extra cost: 3 * 5.00 = 15.00
      // Total: 10.00 + 15.00 = 25.00
      final cost = option.calculateCostForQuantity(5);
      expect(cost, closeTo(25.00, 0.01));
    });

    test('deliveryTimeText formats correctly', () {
      expect(
        SellerDeliveryOption(
          type: 'same_day',
          description: '',
          costCents: 0,
          estimatedDays: 0,
        ).deliveryTimeText,
        equals('Same day'),
      );

      expect(
        SellerDeliveryOption(
          type: 'express',
          description: '',
          costCents: 0,
          estimatedDays: 1,
        ).deliveryTimeText,
        equals('1 day'),
      );

      expect(
        SellerDeliveryOption(
          type: 'standard',
          description: '',
          costCents: 0,
          estimatedDays: 5,
        ).deliveryTimeText,
        equals('5 days'),
      );
    });

    test('priceText formats correctly', () {
      expect(
        SellerDeliveryOption(
          type: 'standard',
          description: '',
          costCents: 0,
          estimatedDays: 5,
        ).priceText,
        equals('Free'),
      );

      expect(
        SellerDeliveryOption(
          type: 'express',
          description: '',
          costCents: 999,
          estimatedDays: 2,
        ).priceText,
        equals(r'$9.99'),
      );
    });

    test('fromMap parses correctly', () {
      final map = <String, dynamic>{
        'type': 'express',
        'description': 'Express Delivery',
        'costCents': 1500,
        'estimatedDays': 2,
        'availableNationwide': true,
      };

      final option = SellerDeliveryOption.fromMap(map)!;

      expect(option.type, equals('express'));
      expect(option.costCents, equals(1500));
      expect(option.estimatedDays, equals(2));
      expect(option.availableNationwide, isTrue);
    });

    test('toMap serializes correctly', () {
      final option = SellerDeliveryOption(
        type: 'standard',
        description: 'Standard',
        costCents: 500,
        estimatedDays: 5,
        availableNationwide: false,
      );

      final map = option.toMap();

      expect(map['type'], equals('standard'));
      expect(map['costCents'], equals(500));
      expect(map['estimatedDays'], equals(5));
      expect(map['availableNationwide'], isFalse);
    });

    test('defaultOptions returns standard options', () {
      final defaults = SellerDeliveryOption.defaultOptions();

      expect(defaults.length, equals(3));
      expect(defaults.any((o) => o.type == 'standard'), isTrue);
      expect(defaults.any((o) => o.type == 'express'), isTrue);
      expect(defaults.any((o) => o.type == 'same_day'), isTrue);
    });
  });

  group('DeliverySpeed enum', () {
    test('enum values are correct', () {
      expect(DeliverySpeed.standard.value, equals('standard'));
      expect(DeliverySpeed.express.value, equals('express'));
      expect(DeliverySpeed.sameDay.value, equals('same_day'));
    });

    test('displayName is not empty', () {
      expect(DeliverySpeed.standard.displayName, isNotEmpty);
      expect(DeliverySpeed.express.displayName, isNotEmpty);
    });

    test('fromValue parses correctly', () {
      expect(
        DeliverySpeed.fromValue('standard'),
        equals(DeliverySpeed.standard),
      );
      expect(DeliverySpeed.fromValue('express'), equals(DeliverySpeed.express));
      expect(
        DeliverySpeed.fromValue('invalid'),
        equals(DeliverySpeed.standard),
      );
    });
  });

  group('CartItemDetailModel delivery options', () {
    test('delivery options are parsed from map', () {
      final map = <String, dynamic>{
        Fields.productId: 'prod-1',
        Fields.name: 'Product',
        Fields.description: 'Desc',
        Fields.price: 10.0,
        Fields.priceCents: 1000,
        Fields.imageUrls: <String>[],
        Fields.quantity: 1,
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.sellerAddress: <String, dynamic>{},
        Fields.sellerId: 'seller-1',
        Fields.sellerName: 'Seller',
        Fields.deliveryOptions: [
          <String, dynamic>{
            'type': 'standard',
            'description': 'Standard',
            'costCents': 500,
            'estimatedDays': 5,
          },
        ],
      };

      final model = CartItemDetailModel.fromMap(map);

      expect(model.deliveryOptions.length, equals(1));
      expect(model.deliveryOptions.first.type, equals('standard'));
    });
  });

  group('ShippingQuantityDiscount', () {
    test('fromMap parses correctly', () {
      final map = <String, dynamic>{
        'minQuantity': 5,
        'discountType': 'percent',
        'discountValue': 15.0,
        'label': 'Bulk Discount',
      };

      final discount = ShippingQuantityDiscount.fromMap(map);

      expect(discount.minQuantity, equals(5));
      expect(discount.discountType, equals('percent'));
      expect(discount.discountValue, equals(15.0));
      expect(discount.label, equals('Bulk Discount'));
    });

    test('toMap serializes correctly', () {
      final discount = ShippingQuantityDiscount(
        minQuantity: 10,
        discountType: 'fixed',
        discountValue: 5.0,
        label: 'Volume Discount',
      );

      final map = discount.toMap();

      expect(map['minQuantity'], equals(10));
      expect(map['discountType'], equals('fixed'));
      expect(map['discountValue'], equals(5.0));
      expect(map['label'], equals('Volume Discount'));
    });

    test('defaults to percent discount type', () {
      final map = <String, dynamic>{'minQuantity': 3, 'discountValue': 10.0};

      final discount = ShippingQuantityDiscount.fromMap(map);

      expect(discount.discountType, equals('percent'));
    });
  });
}
