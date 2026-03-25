import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/features/checkout/checkout_state.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/constants.dart';

@GenerateNiceMocks([
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<OrignaBase>(),
  MockSpec<OrignaBaseAuth>(),
])
import 'checkout_coverage_boost_test.mocks.dart';

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late MockOrignaBase mockOrignaBase;
  late MockOrignaBaseAuth mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    mockOrignaBase = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();

    when(mockOrignaBase.auth).thenReturn(mockAuth);
    when(
      mockOrignaBase.request(any, any, body: anyNamed('body')),
    ).thenAnswer((_) async => <String, dynamic>{});

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        obUserIdProvider.overrideWithValue('user_123'),
        cartSubtotalProvider.overrideWithValue(10000),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  UserModel createTestUser({String? email}) {
    return UserModel(
      uid: 'user_123',
      email: email ?? 'test@test.com',
      name: 'Test User',
      roles: [UserRole.buyer],
      createdAt: DateTime.now(),
    );
  }

  CartItemDetailModel createTestItem({
    bool isDigital = false,
    String sellerId = 's1',
    String? madeInCountry,
    bool isPerishable = false,
    bool isLocalDeliveryOnly = false,
    int priceCents = 1000,
    int quantity = 1,
    double? sellerLat,
    double? sellerLon,
  }) {
    return CartItemDetailModel(
      productId: 'p1',
      name: 'Test Product',
      description: 'A test product description',
      price: priceCents / 100.0,
      priceCents: priceCents,
      imageUrls: [],
      quantity: quantity,
      createdAt: DateTime.now(),
      sellerAddress: Address(
        street: '123 St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
        latitude: sellerLat,
        longitude: sellerLon,
      ),
      sellerId: sellerId,
      sellerName: 'Test Seller',
      isDigital: isDigital,
      madeInCountry: madeInCountry,
      isPerishable: isPerishable,
      isLocalDeliveryOnly: isLocalDeliveryOnly,
    );
  }

  group('applyCoupon error paths', () {
    test('applyCoupon ignores empty code', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.applyCoupon('  ', 10000);
      expect(container.read(checkoutStateProvider).couponCode, isNull);
    });

    test('applyCoupon handles OrignaBaseException', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(OrignaBaseException('Invalid coupon'));

      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.applyCoupon('BADCODE', 10000);

      final state = container.read(checkoutStateProvider);
      expect(state.isCouponLoading, isFalse);
      expect(state.couponError, 'Invalid coupon');
    });

    test('applyCoupon handles generic exception', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(Exception('Network error'));

      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.applyCoupon('CODE', 10000);

      final state = container.read(checkoutStateProvider);
      expect(state.isCouponLoading, isFalse);
      expect(state.couponError, isNotNull);
    });

    test('applyCoupon with sellerIds passes them', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.applyCoupon('CODE5', 10000, sellerIds: ['s1', 's2']);

      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, 'CODE5');
      expect(state.couponDiscountCents, 500);
    });
  });

  group('verifyCartPrices', () {
    test('verifyCartPrices returns map on success', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {ApiKeys.hasChanges: false});

      final notifier = container.read(checkoutStateProvider.notifier);
      final result = await notifier.verifyCartPrices([createTestItem()]);
      expect(result[ApiKeys.hasChanges], isFalse);
    });

    test('verifyCartPrices rethrows on error', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(Exception('Server error'));

      final notifier = container.read(checkoutStateProvider.notifier);
      expect(
        () => notifier.verifyCartPrices([createTestItem()]),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('calculateShipping edge cases', () {
    test('calculateShipping with empty items sets error', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.calculateShipping([]);

      final state = container.read(checkoutStateProvider);
      expect(state.shippingError, isNotNull);
    });

    test(
      'calculateShipping with digital-only items and no address sets zero cost',
      () async {
        final notifier = container.read(checkoutStateProvider.notifier);
        await notifier.calculateShipping([createTestItem(isDigital: true)]);

        final state = container.read(checkoutStateProvider);
        expect(state.baseShippingCost, 0);
        expect(state.isCalculatingShipping, isFalse);
      },
    );

    test(
      'calculateShipping with physical items and no address sets error',
      () async {
        final notifier = container.read(checkoutStateProvider.notifier);
        await notifier.calculateShipping([createTestItem()]);

        final state = container.read(checkoutStateProvider);
        expect(state.shippingError, isNotNull);
      },
    );

    test(
      'calculateShipping with address and digital items sets zero',
      () async {
        final notifier = container.read(checkoutStateProvider.notifier);
        notifier.updateAddress(
          Address(
            street: '123 St',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M1M 1M1',
            country: 'CA',
          ),
        );
        await notifier.calculateShipping([createTestItem(isDigital: true)]);

        final state = container.read(checkoutStateProvider);
        expect(state.baseShippingCost, 0);
      },
    );
  });

  group('calculateTaxes', () {
    test('calculateTaxes without address does nothing', () {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.calculateTaxes(100.0);

      final state = container.read(checkoutStateProvider);
      expect(state.taxBreakdown, isEmpty);
    });

    test('calculateTaxes with address computes taxes', () {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.updateAddress(
        Address(
          street: '123 St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
      );
      notifier.calculateTaxes(100.0, shippingCost: 10.0);

      final state = container.read(checkoutStateProvider);
      // Ontario HST is 13%
      expect(state.taxBreakdown, isNotEmpty);
      expect(state.taxBreakdown.containsKey('HST'), isTrue);
    });
  });

  group('startCheckout validation', () {
    test('startCheckout rejects empty cart', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      final result = await notifier.startCheckout(
        items: [],
        user: createTestUser(),
        subtotalCents: 10000,
      );
      expect(result, isA<CheckoutError>());
      expect((result as CheckoutError).message, contains('cart'));
    });

    test('startCheckout rejects zero subtotal', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      final result = await notifier.startCheckout(
        items: [createTestItem()],
        user: createTestUser(),
        subtotalCents: 0,
      );
      expect(result, isA<CheckoutError>());
    });

    test('startCheckout rejects empty email', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.updateAddress(
        Address(
          street: '123 St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
      );
      final result = await notifier.startCheckout(
        items: [createTestItem()],
        user: createTestUser(email: ''),
        subtotalCents: 10000,
      );
      expect(result, isA<CheckoutError>());
    });

    test('startCheckout rejects missing address for physical items', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      final result = await notifier.startCheckout(
        items: [createTestItem()],
        user: createTestUser(),
        subtotalCents: 10000,
      );
      expect(result, isA<CheckoutError>());
    });

    test('startCheckout rejects when already processing', () async {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.updateAddress(
        Address(
          street: '123',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
      );

      // Simulate processing state by starting a checkout that hangs
      final completer = Completer<Map<String, dynamic>>();
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) => completer.future);

      // Start first checkout (will hang)
      final future1 = notifier.startCheckout(
        items: [createTestItem(priceCents: 500)],
        user: createTestUser(),
        subtotalCents: 500,
      );

      // Wait for state to update
      await Future.microtask(() {});

      // Second call should fail
      final result = await notifier.startCheckout(
        items: [createTestItem(priceCents: 500)],
        user: createTestUser(),
        subtotalCents: 500,
      );
      expect(result, isA<CheckoutError>());

      // Cleanup
      completer.complete({ApiKeys.hasChanges: false});
      await future1;
    });
  });

  group('removeCoupon', () {
    test('removeCoupon clears coupon state', () async {
      // Apply coupon first
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      final notifier = container.read(checkoutStateProvider.notifier);
      await notifier.applyCoupon('SAVE5', 10000);

      expect(container.read(checkoutStateProvider).couponCode, 'SAVE5');

      notifier.removeCoupon();

      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, isNull);
      expect(state.couponDiscountCents, 0);
    });
  });

  group('CheckoutState computed properties', () {
    test('shippingCost returns base for standard', () {
      const state = CheckoutState(
        baseShippingCost: 10.0,
        deliverySpeed: DeliverySpeed.standard,
      );
      expect(state.shippingCost, 10.0);
    });

    test('shippingCost adds surcharge for express', () {
      const state = CheckoutState(
        baseShippingCost: 10.0,
        deliverySpeed: DeliverySpeed.express,
      );
      expect(state.shippingCost, greaterThan(10.0));
    });

    test('taxAmount sums all tax components', () {
      const state = CheckoutState(taxBreakdown: {'GST': 5.0, 'PST': 7.0});
      expect(state.taxAmount, 12.0);
    });
  });

  group('CheckoutResult types', () {
    test('CheckoutSuccess holds url, orderId, sessionId', () {
      final result = CheckoutSuccess(
        checkoutUrl: 'https://stripe.com/session',
        orderId: 'ord_123',
        sessionId: 'sess_123',
      );
      expect(result.checkoutUrl, 'https://stripe.com/session');
      expect(result.orderId, 'ord_123');
      expect(result.sessionId, 'sess_123');
    });

    test('CheckoutError holds message and optional code', () {
      final error = CheckoutError(message: 'fail', code: 'test');
      expect(error.message, 'fail');
      expect(error.code, 'test');
    });

    test('CheckoutAlreadyProcessed holds existingOrderId', () {
      final processed = CheckoutAlreadyProcessed(existingOrderId: 'ord_old');
      expect(processed.existingOrderId, 'ord_old');
    });
  });

  group('Checkout UI state providers', () {
    test('checkoutTermsAcceptedProvider defaults to false', () {
      expect(container.read(checkoutTermsAcceptedProvider), isFalse);
    });

    test('checkoutTermsInteractedProvider defaults to false', () {
      expect(container.read(checkoutTermsInteractedProvider), isFalse);
    });

    test('checkoutEulaAcceptedProvider defaults to false', () {
      expect(container.read(checkoutEulaAcceptedProvider), isFalse);
    });

    test('checkoutEulaInteractedProvider defaults to false', () {
      expect(container.read(checkoutEulaInteractedProvider), isFalse);
    });

    test('checkoutAgeVerifAcceptedProvider defaults to false', () {
      expect(container.read(checkoutAgeVerifAcceptedProvider), isFalse);
    });

    test('checkoutAgeVerifInteractedProvider defaults to false', () {
      expect(container.read(checkoutAgeVerifInteractedProvider), isFalse);
    });

    test('terms providers can be toggled', () {
      container.read(checkoutTermsAcceptedProvider.notifier).state = true;
      expect(container.read(checkoutTermsAcceptedProvider), isTrue);

      container.read(checkoutTermsInteractedProvider.notifier).state = true;
      expect(container.read(checkoutTermsInteractedProvider), isTrue);
    });
  });

  group('setPaymentProvider', () {
    test('rejects non-Stripe providers', () {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.setPaymentProvider('paypal');
      expect(
        container.read(checkoutStateProvider).paymentProvider,
        PaymentProviderValues.stripe,
      );
    });
  });
}
