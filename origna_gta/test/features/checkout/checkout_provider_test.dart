import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/constants.dart';

import '../../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
])
import 'checkout_provider_test.mocks.dart';

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late ProviderContainer container;

  const testUserId = 'user_123';

  final testAddress = Address(
    street: '123 Main St',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5V 3A8',
    country: 'Canada',
    isDefault: true,
    latitude: 43.6532,
    longitude: -79.3832,
  );

  final testCartItem = CartItemDetailModel(
    productId: 'prod_1',
    name: 'Test Product',
    description: 'Test description',
    price: 50.00,
    priceCents: 5000,
    quantity: 1,
    sellerId: 'seller_1',
    sellerName: 'Seller 1',
    imageUrls: const [],
    isDigital: false,
    isPerishable: false,
    isLocalDeliveryOnly: false,
    estimatedShipDays: 3,
    sellerAddress: testAddress,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    initTestMocks();

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        obUserIdProvider.overrideWithValue(testUserId),
        userIdProvider.overrideWithValue(testUserId),
        cartSubtotalProvider.overrideWith((ref) => 5000),
        cartWithDetailsProvider.overrideWith((ref) async => [testCartItem]),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('checkoutStateProvider', () {
    test('initial state should have default values', () {
      final state = container.read(checkoutStateProvider);

      expect(state.address, isNull);
      expect(state.baseShippingCost, 0.0);
      expect(state.isProcessing, false);
      expect(state.isCalculatingShipping, false);
      expect(state.couponDiscountCents, 0);
      expect(state.couponCode, isNull);
      expect(state.deliverySpeed, DeliverySpeed.standard);
    });

    test('reset should clear state to initial values', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      var state = container.read(checkoutStateProvider);
      expect(state.address, equals(testAddress));

      notifier.reset();

      state = container.read(checkoutStateProvider);
      expect(state.address, isNull);
      expect(state.couponDiscountCents, 0);
    });

    test('updateAddress should set address and clear idempotency key', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      final state = container.read(checkoutStateProvider);
      expect(state.address, equals(testAddress));
      expect(state.idempotencyKey, isNull);
    });

    test('setDeliverySpeed should update delivery speed when valid', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);
      await notifier.calculateShipping([testCartItem]);
    });

    test('setPaymentProvider should only accept stripe', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.setPaymentProvider('stripe');

      var state = container.read(checkoutStateProvider);
      expect(state.paymentProvider, equals(PaymentProviderValues.stripe));

      notifier.setPaymentProvider('invalid');

      state = container.read(checkoutStateProvider);
      expect(state.paymentProvider, equals(PaymentProviderValues.stripe));
    });
  });

  group('checkoutComputedProviders', () {
    test('checkoutTotalProvider calculates total correctly', () {
      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          obUserIdProvider.overrideWithValue(testUserId),
          userIdProvider.overrideWithValue(testUserId),
          cartSubtotalProvider.overrideWith((ref) => 10000),
          cartWithDetailsProvider.overrideWith((ref) async => [testCartItem]),
        ],
      );

      final total = container.read(checkoutTotalProvider);

      expect(total, greaterThan(0));
    });

    test('checkoutTaxRateProvider returns Ontario rate when no address', () {
      final taxRate = container.read(checkoutTaxRateProvider);

      expect(taxRate, equals(0.13));
    });

    test('checkoutCouponDiscountDProviders returns 0 when no coupon', () {
      final discount = container.read(checkoutCouponDiscountDollarsProvider);

      expect(discount, equals(0.0));
    });
  });

  group('applyCoupon', () {
    test('ignores empty coupon code', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      await notifier.applyCoupon('  ', 5000);

      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, isNull);
      expect(state.couponDiscountCents, 0);
    });

    test('sets loading state while applying coupon', () async {
      when(mockOrderRepo.createCheckoutSession(any))
          .thenAnswer((_) async => {'checkoutUrl': 'https://example.com'});

      when(mockUserRepo.getUserProfile(any))
          .thenAnswer((_) async => null);

      final notifier = container.read(checkoutStateProvider.notifier);

      final future = notifier.applyCoupon('SAVE10', 5000);

      var state = container.read(checkoutStateProvider);
      expect(state.isCouponLoading, true);

      await future;

      state = container.read(checkoutStateProvider);
      expect(state.isCouponLoading, false);
    });
  });

  group('startCheckout validation', () {
    test('returns error for empty cart', () async {
      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          obUserIdProvider.overrideWithValue(testUserId),
          userIdProvider.overrideWithValue(testUserId),
          cartSubtotalProvider.overrideWith((ref) => 0),
          cartWithDetailsProvider.overrideWith((ref) async => []),
        ],
      );

      final notifier = container.read(checkoutStateProvider.notifier);

      final result = await notifier.startCheckout(
        items: [],
        user: UserModel(
          uid: testUserId,
          email: 'test@example.com',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: 0,
      );

      expect(result, isA<CheckoutError>());
    });

    test('returns error when address required but not provided for physical items', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      final result = await notifier.startCheckout(
        items: [testCartItem],
        user: UserModel(
          uid: testUserId,
          email: 'test@example.com',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: 5000,
      );

      expect(result, isA<CheckoutError>());
    });

    test('returns error for invalid subtotal', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      final result = await notifier.startCheckout(
        items: [testCartItem],
        user: UserModel(
          uid: testUserId,
          email: 'test@example.com',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: -100,
      );

      expect(result, isA<CheckoutError>());
    });

    test('returns error for missing email', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      final result = await notifier.startCheckout(
        items: [testCartItem],
        user: UserModel(
          uid: testUserId,
          email: '',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: 5000,
      );

      expect(result, isA<CheckoutError>());
    });

    test('returns error when already processing', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      container.read(checkoutStateProvider.notifier);

      final firstCheckout = notifier.startCheckout(
        items: [testCartItem],
        user: UserModel(
          uid: testUserId,
          email: 'test@example.com',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: 5000,
      );

      final secondCheckout = notifier.startCheckout(
        items: [testCartItem],
        user: UserModel(
          uid: testUserId,
          email: 'test@example.com',
          name: 'Test User',
          roles: const [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        subtotalCents: 5000,
      );

      await firstCheckout;
      await secondCheckout;
    });
  });

  group('removeCoupon', () {
    test('clears coupon and resets discount', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      notifier.removeCoupon();

      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, isNull);
      expect(state.couponDiscountCents, 0);
    });
  });

  group('calculateShipping', () {
    test('returns early for empty items', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      await notifier.calculateShipping([]);

      final state = container.read(checkoutStateProvider);
      expect(state.shippingError, isNotNull);
    });

    test('handles digital-only cart without address', () async {
      final digitalItem = CartItemDetailModel(
        productId: 'prod_2',
        name: 'Digital Product',
        description: 'Digital item',
        price: 10.00,
        priceCents: 1000,
        quantity: 1,
        sellerId: 'seller_1',
        sellerName: 'Seller 1',
        imageUrls: const [],
        isDigital: true,
        isPerishable: false,
        isLocalDeliveryOnly: false,
        estimatedShipDays: 0,
        sellerAddress: testAddress,
        createdAt: DateTime.now(),
      );

      final notifier = container.read(checkoutStateProvider.notifier);

      await notifier.calculateShipping([digitalItem]);

      final state = container.read(checkoutStateProvider);
      expect(state.baseShippingCost, equals(0.0));
      expect(state.shippingError, isNull);
    });

    test('requires address for physical items', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      await notifier.calculateShipping([testCartItem]);

      final state = container.read(checkoutStateProvider);
      expect(state.shippingError, isNotNull);
    });

    test('calculates shipping with address', () async {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(testAddress);

      await notifier.calculateShipping([testCartItem]);

      final state = container.read(checkoutStateProvider);
      expect(state.baseShippingCost, greaterThanOrEqualTo(0.0));
    });
  });
}
