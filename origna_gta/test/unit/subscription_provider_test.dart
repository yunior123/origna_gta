import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>(), MockSpec<UserRepository>()])
import 'subscription_provider_test.mocks.dart';

void main() {
  late MockOrignaBase mockOrignaBase;
  late MockUserRepository mockUserRepo;
  late ProviderContainer container;

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockUserRepo = MockUserRepository();

    container = ProviderContainer(
      overrides: [
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        obUserIdProvider.overrideWithValue('user-123'),
      ],
    );
  });

  group('SubscriptionViewModel', () {
    test('createSubscription success', () async {
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {'checkoutUrl': 'https://checkout.com'});

      final viewModel = container.read(subscriptionViewModelProvider.notifier);
      await viewModel.createSubscription();

      final state = container.read(subscriptionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.checkoutUrl, 'https://checkout.com');
      expect(state.errorMessage, isNull);
    });

    test('createSubscription error', () async {
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenThrow(Exception('test error'));

      final viewModel = container.read(subscriptionViewModelProvider.notifier);
      await viewModel.createSubscription();

      final state = container.read(subscriptionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('test error'));
    });

    test('cancelSubscription success', () async {
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {});

      final viewModel = container.read(subscriptionViewModelProvider.notifier);
      await viewModel.cancelSubscription();

      final state = container.read(subscriptionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('reactivateSubscription success', () async {
      when(mockOrignaBase.request(any, any, body: anyNamed('body')))
          .thenAnswer((_) async => {});

      final viewModel = container.read(subscriptionViewModelProvider.notifier);
      await viewModel.reactivateSubscription();

      final state = container.read(subscriptionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('clearCheckoutUrl works', () {
      final viewModel = container.read(subscriptionViewModelProvider.notifier);
      viewModel.clearCheckoutUrl();
      expect(container.read(subscriptionViewModelProvider).checkoutUrl, isNull);
    });
  });
}
