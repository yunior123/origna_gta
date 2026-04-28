import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/orders/buyer_orders_viewmodel.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@GenerateNiceMocks([MockSpec<OrderRepository>()])
import 'buyer_orders_viewmodel_test.mocks.dart';

void main() {
  late MockOrderRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockOrderRepository();
    container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  group('BuyerOrdersViewModel', () {
    test('confirmReceipt calls repository and succeeds', () async {
      const orderId = 'o123';
      const itemKey = '${orderId}_p456';
      when(
        mockRepo.confirmReceipt(orderId, productId: 'p456'),
      ).thenAnswer((_) async => {});

      final viewModel = container.read(buyerOrdersViewModelProvider.notifier);
      final result = await viewModel.confirmReceipt(orderId, itemKey);

      expect(result, isTrue);
      expect(container.read(buyerOrdersViewModelProvider).isLoading, isFalse);
      verify(mockRepo.confirmReceipt(orderId, productId: 'p456')).called(1);
    });

    test(
      'confirmReceipt passes null productId when item key is malformed',
      () async {
        const orderId = 'o123';
        const itemKey = 'unexpected-format';
        when(
          mockRepo.confirmReceipt(orderId, productId: null),
        ).thenAnswer((_) async {});

        final viewModel = container.read(buyerOrdersViewModelProvider.notifier);
        final result = await viewModel.confirmReceipt(orderId, itemKey);

        expect(result, isTrue);
        verify(mockRepo.confirmReceipt(orderId, productId: null)).called(1);
      },
    );

    test(
      'confirmReceipt stores an error message on repository failure',
      () async {
        const orderId = 'o123';
        const itemKey = '${orderId}_p456';
        when(
          mockRepo.confirmReceipt(orderId, productId: 'p456'),
        ).thenThrow(Exception('backend failed'));

        final viewModel = container.read(buyerOrdersViewModelProvider.notifier);
        final result = await viewModel.confirmReceipt(orderId, itemKey);
        final state = container.read(buyerOrdersViewModelProvider);

        expect(result, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.confirmingItemId, isNull);
        expect(state.errorMessage, isNotNull);
      },
    );

    test(
      'confirmReceipt rejects a second request while one is in progress',
      () async {
        const orderId = 'o123';
        const itemKey = '${orderId}_p456';
        final completer = Completer<void>();
        when(
          mockRepo.confirmReceipt(orderId, productId: 'p456'),
        ).thenAnswer((_) => completer.future);

        final viewModel = container.read(buyerOrdersViewModelProvider.notifier);
        final firstCall = viewModel.confirmReceipt(orderId, itemKey);
        final secondResult = await viewModel.confirmReceipt(orderId, itemKey);

        expect(secondResult, isFalse);
        expect(
          container.read(buyerOrdersViewModelProvider).confirmingItemId,
          itemKey,
        );

        completer.complete();
        expect(await firstCall, isTrue);
        verify(mockRepo.confirmReceipt(orderId, productId: 'p456')).called(1);
      },
    );
  });
}
