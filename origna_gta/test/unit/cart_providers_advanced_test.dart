// ignore_for_file: unused_element, unused_local_variable
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/core/repositories/cart_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/models/generated/product_models.dart'
    hide SellerDeliveryOption;
import 'package:origna_gta/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<CartRepository>(), MockSpec<ProductRepository>()])
import 'cart_providers_advanced_test.mocks.dart';

CartItemModel _cartItem({
  String cartItemId = 'item1',
  String productId = 'prod1',
  int quantity = 1,
  DateTime? createdAt,
}) {
  return CartItemModel(
    cartItemId: cartItemId,
    productId: productId,
    quantity: quantity,
    createdAt: createdAt ?? DateTime.now(),
  );
}

CartItemDetailModel _detailItem({
  String productId = 'prod1',
  String name = 'Test Product',
  double price = 29.99,
  int quantity = 1,
  bool isDigital = false,
  bool isLocalDeliveryOnly = false,
  bool isPerishable = false,
  String sellerState = 'ON',
  List<SellerDeliveryOption> deliveryOptions = const [],
}) {
  return CartItemDetailModel(
    productId: productId,
    name: name,
    description: 'A test product',
    price: price,
    priceCents: (price * 100).round(),
    imageUrls: const ['https://example.com/img.jpg'],
    quantity: quantity,
    createdAt: DateTime.now(),
    sellerAddress: Address(
      street: '123 Main St',
      city: 'Toronto',
      state: sellerState,
      postalCode: 'M5V 1A1',
      country: 'Canada',
    ),
    sellerId: 'seller1',
    sellerName: 'Test Seller',
    isDigital: isDigital,
    isLocalDeliveryOnly: isLocalDeliveryOnly,
    isPerishable: isPerishable,
    deliveryOptions: deliveryOptions,
  );
}

UserModel _userModel({String state = 'ON'}) => UserModel(
  uid: 'u1',
  email: 'test@test.com',
  name: 'Test User',
  roles: const [UserRole.buyer],
  createdAt: DateTime.now(),
  address: Address(
    street: '1 St',
    city: 'Toronto',
    state: state,
    postalCode: 'M5V',
    country: 'Canada',
  ),
);

Product _product({
  String productId = 'p1',
  String name = 'Test Widget',
  int priceCents = 2999,
  String lifecycleStatus = 'active',
}) => Product(
  productId: productId,
  name: name,
  priceCents: priceCents,
  description: 'A widget',
  imageUrls: const ['img.jpg'],
  sellerId: 's1',
  categoryId: 1,
  stockQuantity: 10,
  createdAt: DateTime.now(),
  lifecycleStatus: lifecycleStatus,
);

void main() {
  SharedPreferences.setMockInitialValues({});

  late MockCartRepository mockRepo;
  late MockProductRepository mockProductRepo;

  setUp(() {
    mockRepo = MockCartRepository();
    mockProductRepo = MockProductRepository();
  });

  // ================================================================
  // cartShippingValidationProvider
  // ================================================================
  group('cartShippingValidationProvider', () {
    test('returns empty list when cart is empty', () async {
      final container = ProviderContainer(
        overrides: [cartWithDetailsProvider.overrideWith((ref) async => [])],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test('digital items are always shippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(productId: 'p1', isDigital: true, sellerState: 'BC'),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test('local-only item in same province is shippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isLocalDeliveryOnly: true,
                sellerState: 'ON',
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test('local-only item in different province is unshippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isLocalDeliveryOnly: true,
                sellerState: 'BC',
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, ['p1']);
    });

    test('perishable item in different province is unshippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isPerishable: true,
                sellerState: 'QC',
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, ['p1']);
    });

    test('nationwide delivery option makes item shippable anywhere', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isLocalDeliveryOnly: true,
                sellerState: 'BC',
                deliveryOptions: [
                  const SellerDeliveryOption(
                    type: 'standard',
                    description: '',
                    costCents: 999,
                    estimatedDays: 3,
                    availableNationwide: true,
                  ),
                ],
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test('standard delivery for non-local item is shippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isLocalDeliveryOnly: false,
                isPerishable: false,
                sellerState: 'BC',
                deliveryOptions: [
                  const SellerDeliveryOption(
                    type: 'standard',
                    description: '',
                    costCents: 999,
                    estimatedDays: 3,
                    availableNationwide: false,
                  ),
                ],
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test('mixed items returns correct unshippable list', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(productId: 'digital', isDigital: true),
              _detailItem(
                productId: 'local-other',
                isLocalDeliveryOnly: true,
                sellerState: 'BC',
              ),
              _detailItem(
                productId: 'local-same',
                isLocalDeliveryOnly: true,
                sellerState: 'ON',
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, ['local-other']);
    });

    test('no delivery options and not local → shippable', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(
                productId: 'p1',
                isLocalDeliveryOnly: false,
                isPerishable: false,
                sellerState: 'BC',
              ),
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_userModel(state: 'ON')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cartShippingValidationProvider.future,
      );
      expect(result, isEmpty);
    });

    test(
      'local-only with local delivery option in same province is shippable',
      () async {
        final container = ProviderContainer(
          overrides: [
            cartWithDetailsProvider.overrideWith(
              (ref) async => [
                _detailItem(
                  productId: 'p1',
                  isLocalDeliveryOnly: true,
                  sellerState: 'ON',
                  deliveryOptions: [
                    const SellerDeliveryOption(
                      type: 'pickup',
                      description: '',
                      costCents: 0,
                      estimatedDays: 1,
                      availableNationwide: false,
                    ),
                  ],
                ),
              ],
            ),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(_userModel(state: 'ON')),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(
          cartShippingValidationProvider.future,
        );
        expect(result, isEmpty);
      },
    );
  });

  // ================================================================
  // deliveryInstructionsProvider
  // ================================================================
  group('cartSubtotalProvider', () {
    test('returns 0 when cart details are loading', () {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) => Future<List<CartItemDetailModel>>.delayed(
              const Duration(hours: 1),
              () => [],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(cartSubtotalProvider), 0);
    });

    test('returns 0 for empty cart', () async {
      final container = ProviderContainer(
        overrides: [cartWithDetailsProvider.overrideWith((ref) async => [])],
      );
      addTearDown(container.dispose);

      await container.read(cartWithDetailsProvider.future);
      expect(container.read(cartSubtotalProvider), 0);
    });

    test('calculates subtotal in cents', () async {
      final container = ProviderContainer(
        overrides: [
          cartWithDetailsProvider.overrideWith(
            (ref) async => [
              _detailItem(productId: 'p1', price: 10.00, quantity: 2),
              _detailItem(productId: 'p2', price: 25.50, quantity: 3),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(cartWithDetailsProvider.future);
      // 1000*2 + 2550*3 = 2000 + 7650 = 9650
      expect(container.read(cartSubtotalProvider), 9650);
    });
  });

  // ================================================================
  // deliveryInstructionsProvider
  // ================================================================
  group('deliveryInstructionsProvider', () {
    test('starts with empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(deliveryInstructionsProvider), '');
    });

    test('can be updated and read back', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Ring doorbell';
      expect(container.read(deliveryInstructionsProvider), 'Ring doorbell');
    });

    test('can be cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(deliveryInstructionsProvider.notifier).state =
          'Leave at door';
      container.read(deliveryInstructionsProvider.notifier).state = '';
      expect(container.read(deliveryInstructionsProvider), '');
    });
  });

  // ================================================================
  // CartController additional edge cases
  // ================================================================
  group('CartController additional edge cases', () {
    test('addToCart with variant validation throwing returns false', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWithValue('user1'),
        ],
      );
      addTearDown(container.dispose);

      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller1');
      when(
        mockRepo.isVariantValid('p1', 'v1'),
      ).thenThrow(Exception('db error'));

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart('p1', 1, variantId: 'v1');
      expect(result, isFalse);
    });

    test('addToCart with analytics params succeeds', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWithValue('user1'),
        ],
      );
      addTearDown(container.dispose);

      when(
        mockRepo.getProductSellerId('p1'),
      ).thenAnswer((_) async => 'seller1');
      when(
        mockRepo.addToCart(any, any, any, variantId: anyNamed('variantId')),
      ).thenAnswer((_) async {});

      final controller = container.read(cartControllerProvider);
      final result = await controller.addToCart(
        'p1',
        2,
        productName: 'Widget',
        priceCad: 19.99,
      );
      expect(result, isTrue);
    });

    test('updateBuyerNote with empty string calls repository', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWithValue('user1'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      await controller.updateBuyerNote('item1', '');

      verify(mockRepo.updateBuyerNote('user1', 'item1', '')).called(1);
    });

    test('updateQuantity with zero calls repository', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWithValue('user1'),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(cartControllerProvider);
      final result = await controller.updateQuantity('item1', 0);

      expect(result, isTrue);
      verify(mockRepo.updateQuantity('user1', 'item1', 0)).called(1);
    });

    test('canAddToCart when sellerId returns empty string', () async {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWithValue('user1'),
        ],
      );
      addTearDown(container.dispose);

      when(mockRepo.getProductSellerId('p1')).thenAnswer((_) async => '');

      final controller = container.read(cartControllerProvider);
      expect(await controller.canAddToCart('p1'), isTrue);
    });
  });
}
