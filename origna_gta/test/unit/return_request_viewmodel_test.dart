import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/features/orders/return_request_viewmodel.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

// ---------------------------------------------------------------------------
// Fake OrderRepository
// ---------------------------------------------------------------------------

class _FakeOrderRepository implements OrderRepository {
  Object? createReturnError;
  Map<String, dynamic> createReturnResult = {'id': 'return_1'};
  int createReturnCalls = 0;
  String? lastOrderId;
  List<String>? lastCartItemIds;
  String? lastReason;
  String? lastDescription;

  @override
  Future<Map<String, dynamic>> createReturnRequest({
    required String orderId,
    required List<String> cartItemIds,
    required String reason,
    String? description,
  }) async {
    createReturnCalls++;
    lastOrderId = orderId;
    lastCartItemIds = cartItemIds;
    lastReason = reason;
    lastDescription = description;
    if (createReturnError != null) throw createReturnError!;
    return createReturnResult;
  }

  // Stubs for other OrderRepository methods — not used in this test
  @override
  Future<void> cancelOrder(String orderId) async {}
  @override
  Future<void> approveShippingCost(String orderId, bool approved) async {}
  @override
  Future<void> capturePayment(String orderId) async {}
  @override
  Future<void> confirmReceipt(String orderId, {String? productId}) async {}
  @override
  Future<Map<String, dynamic>> createCheckoutSession(
    Map<String, dynamic> orderData,
  ) async => {};
  @override
  Future<models.Order?> fetchOrderById(String orderId) async => null;
  @override
  Future<void> updateItemStatus(
    String orderId,
    String itemId,
    String status, {
    String? trackingNumber,
    String? carrier,
    String? carrierNote,
  }) async {}
  @override
  Future<void> updateLastSession(
    String userId,
    String sessionId,
    String orderId,
  ) async {}
  @override
  Future<void> updateShippingCost(
    String orderId,
    int newShippingCostCents,
    String reason,
  ) async {}
  @override
  Stream<List<models.Order>> watchBuyerOrders(String userId) =>
      const Stream.empty();
  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) =>
      const Stream.empty();
  @override
  Stream<List<models.Order>> watchSellerOrders(String userId) =>
      const Stream.empty();
  @override
  Future<List<models.ReturnRequest>> fetchReturnRequests(
    String orderId, {
    int limit = 50,
    int offset = 0,
  }) async => [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeOrderRepository fakeOrderRepo;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(fakeOrderRepo)],
    );
  }

  setUp(() {
    fakeOrderRepo = _FakeOrderRepository();
  });

  group('ReturnRequestViewModel', () {
    test('initial state is idle', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      final state = c.read(returnRequestViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('submitReturn succeeds and sets isSuccess', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final result = await c
          .read(returnRequestViewModelProvider.notifier)
          .submitReturn(
            orderId: 'order_1',
            cartItemIds: ['item_1', 'item_2'],
            reason: 'Damaged',
            description: 'Box was crushed',
          );

      expect(result, isTrue);
      final state = c.read(returnRequestViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(fakeOrderRepo.createReturnCalls, 1);
      expect(fakeOrderRepo.lastOrderId, 'order_1');
      expect(fakeOrderRepo.lastCartItemIds, ['item_1', 'item_2']);
      expect(fakeOrderRepo.lastReason, 'Damaged');
      expect(fakeOrderRepo.lastDescription, 'Box was crushed');
    });

    test(
      'submitReturn returns false and sets errorMessage on failure',
      () async {
        fakeOrderRepo.createReturnError = Exception('Server error');
        final c = makeContainer();
        addTearDown(c.dispose);

        final result = await c
            .read(returnRequestViewModelProvider.notifier)
            .submitReturn(
              orderId: 'order_1',
              cartItemIds: ['item_1'],
              reason: 'Wrong item',
            );

        expect(result, isFalse);
        final state = c.read(returnRequestViewModelProvider);
        expect(state.isSuccess, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNotNull);
      },
    );

    test('submitReturn guards against double-submit while loading', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final notifier = c.read(returnRequestViewModelProvider.notifier);
      // Force loading state
      notifier.state = notifier.state.copyWith(isLoading: true);

      final result = await notifier.submitReturn(
        orderId: 'order_1',
        cartItemIds: ['item_1'],
        reason: 'Duplicate',
      );

      expect(result, isFalse);
      expect(fakeOrderRepo.createReturnCalls, 0);
    });

    test('submitReturn without description passes null', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c
          .read(returnRequestViewModelProvider.notifier)
          .submitReturn(
            orderId: 'order_2',
            cartItemIds: ['item_3'],
            reason: 'Changed mind',
          );

      expect(fakeOrderRepo.lastDescription, isNull);
    });

    test('clearStatus resets errorMessage and isSuccess', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      // First trigger a success
      await c
          .read(returnRequestViewModelProvider.notifier)
          .submitReturn(
            orderId: 'order_1',
            cartItemIds: ['item_1'],
            reason: 'Broken',
          );
      expect(c.read(returnRequestViewModelProvider).isSuccess, isTrue);

      // Clear status
      c.read(returnRequestViewModelProvider.notifier).clearStatus();

      final state = c.read(returnRequestViewModelProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('clearStatus after error resets errorMessage', () async {
      fakeOrderRepo.createReturnError = Exception('fail');
      final c = makeContainer();
      addTearDown(c.dispose);

      await c
          .read(returnRequestViewModelProvider.notifier)
          .submitReturn(
            orderId: 'order_1',
            cartItemIds: ['item_1'],
            reason: 'Bad',
          );
      expect(c.read(returnRequestViewModelProvider).errorMessage, isNotNull);

      c.read(returnRequestViewModelProvider.notifier).clearStatus();
      expect(c.read(returnRequestViewModelProvider).errorMessage, isNull);
    });
  });

  group('ReturnRequestState', () {
    test('copyWith preserves unchanged fields', () {
      const state = ReturnRequestState(
        isLoading: true,
        isSuccess: false,
        errorMessage: 'test error',
      );
      final copied = state.copyWith(isLoading: false);
      expect(copied.isLoading, isFalse);
      expect(copied.errorMessage, 'test error');
      expect(copied.isSuccess, isFalse);
    });

    test('default state has correct values', () {
      const state = ReturnRequestState();
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, isNull);
    });
  });
}
