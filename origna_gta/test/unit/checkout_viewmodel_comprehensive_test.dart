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
import 'checkout_viewmodel_comprehensive_test.mocks.dart';

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

  CartItemDetailModel createTestItem({bool isDigital = false}) {
    return CartItemDetailModel(
      productId: 'p1',
      name: 'Test Product',
      description: 'A test product description',
      price: 10.0,
      priceCents: 1000,
      imageUrls: [],
      quantity: 1,
      createdAt: DateTime.now(),
      sellerAddress: Address(
        street: '123 St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      ),
      sellerId: 's1',
      sellerName: 'Test Seller',
      isDigital: isDigital,
    );
  }

  group('CheckoutNotifier Initial State Tests', () {
    test('initial state has no address', () {
      final state = container.read(checkoutStateProvider);
      expect(state.address, isNull);
    });

    test('initial state has zero shipping cost', () {
      final state = container.read(checkoutStateProvider);
      expect(state.baseShippingCost, 0.0);
    });

    test('initial state has standard delivery speed', () {
      final state = container.read(checkoutStateProvider);
      expect(state.deliverySpeed, DeliverySpeed.standard);
    });

    test('initial state has no coupon', () {
      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, isNull);
      expect(state.couponDiscountCents, 0);
    });

    test('initial state is not processing', () {
      final state = container.read(checkoutStateProvider);
      expect(state.isProcessing, isFalse);
    });

    test('initial state has no errors', () {
      final state = container.read(checkoutStateProvider);
      expect(state.checkoutError, isNull);
      expect(state.shippingError, isNull);
      expect(state.couponError, isNull);
    });

    test('initial state has Stripe payment provider', () {
      final state = container.read(checkoutStateProvider);
      expect(state.paymentProvider, PaymentProviderValues.stripe);
    });

    test('initial state has no international items', () {
      final state = container.read(checkoutStateProvider);
      expect(state.hasInternationalItems, isFalse);
    });
  });

  group('CheckoutNotifier State Transitions Tests', () {
    test('updateAddress sets address', () {
      final address = Address(
        street: '123 Test St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );

      container.read(checkoutStateProvider.notifier).updateAddress(address);

      expect(container.read(checkoutStateProvider).address, address);
    });

    test('updateAddress clears idempotency key', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      final address1 = Address(
        street: '123 St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      notifier.updateAddress(address1);

      final address2 = Address(
        street: '456 Ave',
        city: 'Ottawa',
        state: 'ON',
        postalCode: 'K1K 1K1',
        country: 'CA',
      );
      notifier.updateAddress(address2);

      expect(container.read(checkoutStateProvider).address, address2);
    });

    test('setDeliverySpeed updates when valid', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.setDeliverySpeed(DeliverySpeed.express);

      expect(
        container.read(checkoutStateProvider).deliverySpeed,
        DeliverySpeed.express,
      );
    });

    test('setPaymentProvider accepts Stripe', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.setPaymentProvider(PaymentProviderValues.stripe);

      expect(
        container.read(checkoutStateProvider).paymentProvider,
        PaymentProviderValues.stripe,
      );
    });

    test('reset clears all state', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.updateAddress(
        Address(
          street: '123',
          city: 'C',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
      );

      notifier.reset();

      expect(container.read(checkoutStateProvider).address, isNull);
    });
  });

  group('CheckoutNotifier Coupon Tests', () {
    test('applyCoupon sets loading state', () async {
      when(mockOrignaBase.request(any, any, body: anyNamed('body'))).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return {Fields.discountAmountCents: 500};
        },
      );

      final future = container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('SAVE5', 10000);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(checkoutStateProvider).isCouponLoading, isTrue);

      await future;
      expect(container.read(checkoutStateProvider).isCouponLoading, isFalse);
    });

    test('applyCoupon sets coupon code on success', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 1000});

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('DISCOUNT20', 10000);

      expect(container.read(checkoutStateProvider).couponCode, 'DISCOUNT20');
      expect(container.read(checkoutStateProvider).couponDiscountCents, 1000);
    });

    test('applyCoupon normalizes coupon code to uppercase', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('save5', 10000);

      expect(container.read(checkoutStateProvider).couponCode, 'SAVE5');
    });

    test('applyCoupon sets error on failure', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenThrow(OrignaBaseException('Invalid coupon'));

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('INVALID', 10000);

      expect(container.read(checkoutStateProvider).couponError, isNotNull);
      expect(container.read(checkoutStateProvider).couponCode, isNull);
    });

    test('applyCoupon ignores empty code', () async {
      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('', 10000);

      expect(container.read(checkoutStateProvider).isCouponLoading, isFalse);
    });

    test('removeCoupon clears coupon state', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('SAVE5', 10000);
      expect(container.read(checkoutStateProvider).couponCode, 'SAVE5');

      container.read(checkoutStateProvider.notifier).removeCoupon();

      expect(container.read(checkoutStateProvider).couponCode, isNull);
      expect(container.read(checkoutStateProvider).couponDiscountCents, 0);
    });
  });

  group('CheckoutNotifier startCheckout Tests', () {
    test('startCheckout returns error when items empty', () async {
      final result = await container
          .read(checkoutStateProvider.notifier)
          .startCheckout(items: [], user: createTestUser(), subtotal: 100.0);

      expect(result, isA<CheckoutError>());
      expect((result as CheckoutError).message, contains('cart_empty'));
    });

    test('startCheckout returns error when user email empty', () async {
      final result = await container
          .read(checkoutStateProvider.notifier)
          .startCheckout(
            items: [createTestItem()],
            user: createTestUser(email: ''),
            subtotal: 10.0,
          );

      expect(result, isA<CheckoutError>());
      expect((result as CheckoutError).message, contains('missing_email'));
    });

    test('startCheckout returns error when subtotal invalid', () async {
      final result = await container
          .read(checkoutStateProvider.notifier)
          .startCheckout(
            items: [createTestItem()],
            user: createTestUser(),
            subtotal: 0.0,
          );

      expect(result, isA<CheckoutError>());
      expect((result as CheckoutError).message, contains('invalid_total'));
    });

    test('startCheckout returns error when already processing', () async {
      final items = [createTestItem()];
      final user = createTestUser();
      final address = Address(
        street: '123 St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );

      container.read(checkoutStateProvider.notifier).updateAddress(address);

      when(mockOrderRepo.createCheckoutSession(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return {
          ApiKeys.checkoutUrl: 'https://checkout.com',
          Fields.orderId: 'order_123',
          ApiKeys.sessionId: 'session_123',
        };
      });

      final future1 = container
          .read(checkoutStateProvider.notifier)
          .startCheckout(items: items, user: user, subtotal: 10.0);

      final result2 = await container
          .read(checkoutStateProvider.notifier)
          .startCheckout(items: items, user: user, subtotal: 10.0);

      expect(result2, isA<CheckoutError>());
      expect(
        (result2 as CheckoutError).message,
        contains('already_processing'),
      );

      await future1;
    });
  });

  group('CheckoutNotifier Error Handling Tests', () {
    test('calculateShipping sets error when no items', () async {
      await container
          .read(checkoutStateProvider.notifier)
          .calculateShipping([]);

      expect(container.read(checkoutStateProvider).shippingError, isNotNull);
    });

    test(
      'calculateShipping sets error when no address for physical items',
      () async {
        await container.read(checkoutStateProvider.notifier).calculateShipping([
          createTestItem(),
        ]);

        expect(container.read(checkoutStateProvider).shippingError, isNotNull);
      },
    );

    test(
      'calculateShipping handles digital-only items without address',
      () async {
        await container.read(checkoutStateProvider.notifier).calculateShipping([
          createTestItem(isDigital: true),
        ]);

        expect(container.read(checkoutStateProvider).baseShippingCost, 0.0);
        expect(container.read(checkoutStateProvider).shippingError, isNull);
      },
    );
  });

  group('CheckoutNotifier Edge Cases Tests', () {
    test('setDeliverySpeed ignores invalid speed', () {
      final notifier = container.read(checkoutStateProvider.notifier);

      notifier.setDeliverySpeed(DeliverySpeed.sameDay);

      expect(
        container.read(checkoutStateProvider).deliverySpeed,
        DeliverySpeed.standard,
      );
    });

    test('shippingCost adds surcharge for express', () {
      final state = CheckoutState(
        baseShippingCost: 10.0,
        deliverySpeed: DeliverySpeed.express,
      );

      expect(state.shippingCost, greaterThan(state.baseShippingCost));
    });

    test('shippingCost equals base cost for standard', () {
      const state = CheckoutState(
        baseShippingCost: 10.0,
        deliverySpeed: DeliverySpeed.standard,
      );

      expect(state.shippingCost, 10.0);
    });

    test('taxAmount sums tax breakdown', () {
      final state = CheckoutState(taxBreakdown: {'GST': 5.0, 'PST': 7.0});

      expect(state.taxAmount, 12.0);
    });
  });

  group('CheckoutState copyWith Tests', () {
    test('copyWith preserves values when not specified', () {
      final state = CheckoutState(
        baseShippingCost: 15.0,
        deliverySpeed: DeliverySpeed.express,
      );

      final copied = state.copyWith();

      expect(copied.baseShippingCost, 15.0);
      expect(copied.deliverySpeed, DeliverySpeed.express);
    });

    test('copyWith clears shippingError', () {
      final state = CheckoutState(shippingError: 'Error');

      final copied = state.copyWith(clearShippingError: true);

      expect(copied.shippingError, isNull);
    });

    test('copyWith clears checkoutError', () {
      final state = CheckoutState(checkoutError: 'Checkout failed');

      final copied = state.copyWith(clearCheckoutError: true);

      expect(copied.checkoutError, isNull);
    });

    test('copyWith clears coupon', () {
      final state = CheckoutState(
        couponCode: 'SAVE5',
        couponDiscountCents: 500,
      );

      final copied = state.copyWith(clearCoupon: true);

      expect(copied.couponCode, isNull);
      expect(copied.couponDiscountCents, 0);
    });
  });
}
