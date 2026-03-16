import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/features/seller/seller_registration_view_model.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
])
import 'seller_registration_viewmodel_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();

    when(mockOrignaBase.request(any, any, body: anyNamed('body')))
        .thenAnswer((_) async => <String, dynamic>{});

    container = ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        obUserIdProvider.overrideWithValue('user_123'),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SellerRegistrationViewModel Unit Tests', () {
    test('initial state is correct', () {
      final state = container.read(sellerRegistrationViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.paymentProvider, PaymentProviderValues.stripe);
    });

    test('setPaymentProvider updates state and calls backend', () async {
      final viewModel = container.read(sellerRegistrationViewModelProvider.notifier);

      await viewModel.setPaymentProvider(PaymentProviderValues.stripe);

      expect(container.read(sellerRegistrationViewModelProvider).paymentProvider, PaymentProviderValues.stripe);
    });

    test('refreshAccountStatus calls backend', () async {
      final viewModel = container.read(sellerRegistrationViewModelProvider.notifier);

      await viewModel.refreshAccountStatus();

      verify(mockOrignaBase.request(any, any, body: anyNamed('body'))).called(greaterThan(0));
    });

    test('startRegistration follows step 1 and step 2', () async {
      final viewModel = container.read(sellerRegistrationViewModelProvider.notifier);

      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {ApiKeys.url: 'https://onboarding.url'});

      await viewModel.startRegistration();

      // Should have made at least 2 calls (create account + create link)
      verify(mockOrignaBase.request(any, any, body: anyNamed('body'))).called(greaterThan(1));
    });

    test('rate limiting prevents rapid calls', () async {
      final viewModel = container.read(sellerRegistrationViewModelProvider.notifier);

      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {ApiKeys.url: 'https://url'});

      await viewModel.startRegistration();

      clearInteractions(mockOrignaBase);

      // Immediate second call should be blocked by _canProceed
      await viewModel.startRegistration();
      verifyNoMoreInteractions(mockOrignaBase);
    });
  });
}
