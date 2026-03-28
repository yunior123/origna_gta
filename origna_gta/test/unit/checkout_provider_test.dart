import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/checkout/checkout_provider.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<OrignaBase>(),
])
import 'checkout_provider_test.mocks.dart';

void main() {
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late MockOrignaBase mockOrignaBase;
  late ProviderContainer container;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    mockOrignaBase = MockOrignaBase();

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        obUserIdProvider.overrideWithValue('user_123'),
      ],
    );
  });

  group('CheckoutNotifier Tests', () {
    test('initial state is correct', () {
      final state = container.read(checkoutStateProvider);
      expect(state.isProcessing, isFalse);
      expect(state.address, isNull);
    });

    test('updateAddress updates state', () {
      final address = Address(
        street: 'S',
        city: 'C',
        state: 'P',
        postalCode: 'Z',
        country: 'CA',
      );
      container.read(checkoutStateProvider.notifier).updateAddress(address);

      final state = container.read(checkoutStateProvider);
      expect(state.address, address);
    });

    test('applyCoupon calls OrignaBase', () async {
      when(
        mockOrignaBase.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {Fields.discountAmountCents: 500});

      await container
          .read(checkoutStateProvider.notifier)
          .applyCoupon('SAVE5', 10000);

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

    test(
      'applyCoupon preserves coupon usage limit errors from OrignaBase',
      () async {
        when(
          mockOrignaBase.request(any, any, body: anyNamed('body')),
        ).thenThrow(
          OrignaBaseException(
            "You've reached the maximum uses for this coupon",
          ),
        );

        await container
            .read(checkoutStateProvider.notifier)
            .applyCoupon('SAVE5', 10000);

        final state = container.read(checkoutStateProvider);
        expect(state.couponCode, isNull);
        expect(state.couponDiscountCents, 0);
        expect(
          state.couponError,
          "You've reached the maximum uses for this coupon",
        );
      },
    );
  });
}
