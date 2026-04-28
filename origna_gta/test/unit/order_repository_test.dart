import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/models/generated/models.dart' as gen;

@GenerateNiceMocks([MockSpec<OrderRepository>()])
import 'order_repository_test.mocks.dart';

void main() {
  late MockOrderRepository mockRepository;

  setUp(() {
    mockRepository = MockOrderRepository();
  });

  group('OrderRepository Tests', () {
    test('fetchOrderById returns order', () async {
      final fakeOrder = gen.Order(
        orderId: 'o1',
        userId: 'u1',
        items: const [],
        totalAmountCents: 1000,
        subtotalCents: 1000,
        shippingCostCents: 0,
        taxAmountCents: 0,
        taxes: const gen.Taxes(),
        orderStatus: gen.OrderStatus.confirmed,
        paymentStatus: gen.PaymentStatus.authorized,
        shippingApprovalStatus: gen.ShippingApprovalStatus.notRequired,
        createdAt: DateTime.now(),
        shippingAddress: const gen.Address(
          street: 'S',
          city: 'C',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
        currency: 'cad',
        sellerIds: const ['s1'],
        stripeSessionId: 'sess_1',
      );

      when(
        mockRepository.fetchOrderById('o1'),
      ).thenAnswer((_) async => fakeOrder);

      final order = await mockRepository.fetchOrderById('o1');
      expect(order, isNotNull);
      expect(order!.orderId, 'o1');
    });

    test('watchBuyerOrders returns stream', () {
      when(
        mockRepository.watchBuyerOrders('u1'),
      ).thenAnswer((_) => Stream.value([]));

      final stream = mockRepository.watchBuyerOrders('u1');
      expect(stream, isA<Stream<List<gen.Order>>>());
    });
  });
}
