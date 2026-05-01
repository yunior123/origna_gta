import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<AuthRepository>(),
  MockSpec<OrignaBase>(),
])
import 'checkout_notifier_test.mocks.dart';

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthRepository mockAuthRepo;
  late MockOrignaBase mockOrignaBase;
  late ProviderContainer container;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    mockAuthRepo = MockAuthRepository();
    mockOrignaBase = MockOrignaBase();

    when(
      mockOrignaBase.request(any, any, body: anyNamed('body')),
    ).thenAnswer((_) async => <String, dynamic>{});

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        obUserIdProvider.overrideWithValue('user_123'),
        cartWithDetailsProvider.overrideWith((ref) async => []),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CheckoutNotifier Unit Tests', () {
    test('initial state is correct', () {
      final state = container.read(checkoutStateProvider);
      expect(state.isCalculatingShipping, isFalse);
      expect(state.isProcessing, isFalse);
      expect(state.address, isNull);
    });

    test('updateAddress updates state', () {
      final address = Address(
        street: '123 St',
        city: 'City',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      container.read(checkoutStateProvider.notifier).updateAddress(address);

      expect(container.read(checkoutStateProvider).address, address);
    });

    test('applyCoupon calls backend and updates state', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('SAVE5', 2000);

      final state = container.read(checkoutStateProvider);
      expect(state.couponCode, 'SAVE5');
      expect(state.couponDiscountCents, 500);
      verify(
        mockOrignaBase.request(
          'POST',
          '/api/coupons/apply',
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('removeCoupon clears coupon state', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      final notifier = container.read(checkoutStateProvider.notifier);

      await notifier.applyCoupon('SAVE5', 2000);
      expect(container.read(checkoutStateProvider).couponCode, 'SAVE5');

      notifier.removeCoupon();
      expect(container.read(checkoutStateProvider).couponCode, isNull);
      expect(container.read(checkoutStateProvider).couponDiscountCents, 0);
    });

    test('reset restores initial state', () {
      final notifier = container.read(checkoutStateProvider.notifier);
      notifier.updateAddress(
        Address(
          street: '123',
          city: 'C',
          state: 'S',
          postalCode: 'P',
          country: 'C',
        ),
      );

      notifier.reset();
      expect(container.read(checkoutStateProvider).address, isNull);
    });
  });
}
