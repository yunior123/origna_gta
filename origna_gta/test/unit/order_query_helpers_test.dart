import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/order_query_helpers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/base_models.dart'
    show PaymentStatus;
import 'package:origna_gta/models/generated/models.dart' as models;

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
  MockSpec<Document>(),
  MockSpec<DocumentChange>(),
])
import 'order_query_helpers_test.mocks.dart';

class _TestOrderQueryHelpers with OrderQueryHelpers {
  @override
  final OrignaBase ob;

  final models.Order Function(Document doc) _converter;

  _TestOrderQueryHelpers({
    required this.ob,
    required models.Order Function(Document doc) converter,
  }) : _converter = converter;

  @override
  models.Order docToOrder(Document doc) => _converter(doc);
}

models.Order _makeOrder({
  required String orderId,
  PaymentStatus paymentStatus = PaymentStatus.captured,
  String userId = 'u1',
  int totalCents = 1000,
}) {
  return models.Order(
    orderId: orderId,
    userId: userId,
    items: [],
    subtotalCents: totalCents,
    totalAmountCents: totalCents,
    taxes: const models.Taxes(),
    paymentStatus: paymentStatus,
    orderStatus: models.OrderStatus.confirmed,
    createdAt: DateTime.now(),
  );
}

Document _makeDoc({
  required String id,
  Map<String, dynamic>? data,
  bool exists = true,
}) {
  final doc = MockDocument();
  when(doc.id).thenReturn(id);
  when(doc.exists).thenReturn(exists);
  when(doc.data).thenReturn(data ?? {Fields.orderId: id});
  return doc;
}

DocumentChange _makeChange({
  required Document doc,
  ChangeType type = ChangeType.create,
}) {
  final change = MockDocumentChange();
  when(change.document).thenReturn(doc);
  when(change.type).thenReturn(type);
  return change;
}

void main() {
  group('OrderQueryHelpers static methods', () {
    group('paymentStatusToString', () {
      test('maps awaitingPayment', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.awaitingPayment,
          ),
          PaymentStatusValues.awaitingPayment,
        );
      });

      test('maps processing', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.processing,
          ),
          PaymentStatusValues.processing,
        );
      });

      test('maps paid', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.paid),
          PaymentStatusValues.paid,
        );
      });

      test('maps authorized', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.authorized,
          ),
          PaymentStatusValues.authorized,
        );
      });

      test('maps captured', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.captured,
          ),
          PaymentStatusValues.captured,
        );
      });

      test('maps paymentFailed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.paymentFailed,
          ),
          PaymentStatusValues.paymentFailed,
        );
      });

      test('maps refunded', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.refunded,
          ),
          PaymentStatusValues.refunded,
        );
      });

      test('maps sessionExpired', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.sessionExpired,
          ),
          PaymentStatusValues.sessionExpired,
        );
      });

      test('maps cancelled', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelled,
          ),
          PaymentStatusValues.cancelled,
        );
      });

      test('maps authorizationExpired', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.authorizationExpired,
          ),
          PaymentStatusValues.authorizationExpired,
        );
      });

      test('maps disputed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.disputed,
          ),
          PaymentStatusValues.disputed,
        );
      });

      test('maps capturing', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.capturing,
          ),
          PaymentStatusValues.capturing,
        );
      });

      test('maps cancelling', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelling,
          ),
          PaymentStatusValues.cancelling,
        );
      });

      test('maps expiring', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.expiring,
          ),
          PaymentStatusValues.expiring,
        );
      });

      test('maps partiallyRefunded', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.partiallyRefunded,
          ),
          PaymentStatusValues.partiallyRefunded,
        );
      });

      test('maps voided', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.voided),
          PaymentStatusValues.voided,
        );
      });

      test('maps cancelFailed', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.cancelFailed,
          ),
          PaymentStatusValues.cancelFailed,
        );
      });

      test('all PaymentStatus enum values have a mapping', () {
        final allValues = models.PaymentStatus.values;
        for (final status in allValues) {
          final result = OrderQueryHelpers.paymentStatusToString(status);
          expect(result, isNotEmpty);
          expect(result, isA<String>());
        }
      });

      test('returns underscore format for all statuses', () {
        expect(
          OrderQueryHelpers.paymentStatusToString(
            models.PaymentStatus.awaitingPayment,
          ),
          contains('_'),
        );
        expect(
          OrderQueryHelpers.paymentStatusToString(models.PaymentStatus.paid),
          isNot(contains('_')),
        );
      });
    });

    group('normalizeId', () {
      test('strips collection prefix', () {
        expect(OrderQueryHelpers.normalizeId('orders:abc123'), 'abc123');
      });

      test('returns id as-is when no colon', () {
        expect(OrderQueryHelpers.normalizeId('abc123'), 'abc123');
      });

      test(
        'handles multiple colons by stripping only the collection prefix',
        () {
          expect(OrderQueryHelpers.normalizeId('a:b:c'), 'b:c');
        },
      );

      test('handles empty string after colon', () {
        expect(OrderQueryHelpers.normalizeId('orders:'), '');
      });

      test('handles empty string input', () {
        expect(OrderQueryHelpers.normalizeId(''), '');
      });

      test('handles single character input', () {
        expect(OrderQueryHelpers.normalizeId('x'), 'x');
      });

      test('handles UUID-style IDs', () {
        const uuid = '550e8400-e29b-41d4-a716-446655440000';
        expect(OrderQueryHelpers.normalizeId(uuid), uuid);
      });

      test('handles collection:uuid format', () {
        const uuid = '550e8400-e29b-41d4-a716-446655440000';
        expect(OrderQueryHelpers.normalizeId('orders:$uuid'), uuid);
      });

      test('handles numeric IDs', () {
        expect(OrderQueryHelpers.normalizeId('orders:12345'), '12345');
      });

      test('handles IDs with special characters', () {
        expect(
          OrderQueryHelpers.normalizeId('orders:test_id-123'),
          'test_id-123',
        );
      });

      test('handles only colon', () {
        expect(OrderQueryHelpers.normalizeId(':'), '');
      });

      test('handles leading colon', () {
        expect(OrderQueryHelpers.normalizeId(':test'), 'test');
      });
    });

    group('activePaymentStatuses', () {
      test('contains expected statuses', () {
        final statuses = OrderQueryHelpers.activePaymentStatuses;
        expect(statuses, contains(PaymentStatus.authorized.value));
        expect(statuses, contains(PaymentStatus.captured.value));
        expect(statuses, contains(PaymentStatus.disputed.value));
        expect(statuses, contains(PaymentStatus.refunded.value));
        expect(statuses, contains(PaymentStatus.cancelled.value));
        expect(statuses, contains(PaymentStatus.authorizationExpired.value));
      });

      test('has 6 entries', () {
        expect(OrderQueryHelpers.activePaymentStatuses.length, 6);
      });

      test('does not contain awaitingPayment', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.awaitingPayment.value)),
        );
      });

      test('does not contain processing', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.processing.value)),
        );
      });

      test('does not contain paid', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.paid.value)),
        );
      });

      test('does not contain paymentFailed', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.paymentFailed.value)),
        );
      });

      test('does not contain sessionExpired', () {
        expect(
          OrderQueryHelpers.activePaymentStatuses,
          isNot(contains(PaymentStatus.sessionExpired.value)),
        );
      });

      test('is a List<String>', () {
        expect(OrderQueryHelpers.activePaymentStatuses, isA<List<String>>());
      });

      test('all values are valid PaymentStatusValues', () {
        final allValidValues = PaymentStatusValues.all.toSet();
        for (final status in OrderQueryHelpers.activePaymentStatuses) {
          expect(allValidValues, contains(status));
        }
      });

      test('contains no duplicates', () {
        final statuses = OrderQueryHelpers.activePaymentStatuses;
        final uniqueStatuses = statuses.toSet();
        expect(statuses.length, uniqueStatuses.length);
      });
    });
  });

  group('watchOrdersImpl', () {
    late MockOrignaBase mockOb;
    late MockCollectionRef mockCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;

    setUp(() {
      mockOb = MockOrignaBase();
      mockCollection = MockCollectionRef();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();

      when(mockOb.collection(Collections.orders)).thenReturn(mockCollection);
    });

    test('seeds initial state from query', () async {
      final doc1 = _makeDoc(id: 'order1');
      final doc2 = _makeDoc(id: 'order2');
      when(mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final orders = await helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .first;

      expect(orders.length, 2);
      expect(orders.map((o) => o.orderId), containsAll(['order1', 'order2']));

      await changeController.close();
    });

    test('sorts orders using provided sort function', () async {
      final doc1 = _makeDoc(id: 'order1');
      final doc2 = _makeDoc(id: 'order2');
      when(mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(
          orderId: doc.id,
          totalCents: int.parse(doc.id.replaceAll('order', '')) * 1000,
        ),
      );

      final orders = await helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders.reversed.toList(),
            realtimeChanges: () => changeController.stream,
          )
          .first;

      expect(orders.first.orderId, 'order2');
      expect(orders.last.orderId, 'order1');

      await changeController.close();
    });

    test('filters orders using accept function', () async {
      final doc1 = _makeDoc(id: 'order1');
      when(mockSnapshot.docs).thenReturn([doc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final orders = await helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (order) => order.orderId == 'order1',
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .first;

      expect(orders.length, 1);
      expect(orders.first.orderId, 'order1');

      await changeController.close();
    });

    test('handles empty initial snapshot', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final orders = await helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .first;

      expect(orders, isEmpty);

      await changeController.close();
    });

    test('adds order on document change', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .take(2)
          .toList();

      await Future.delayed(const Duration(milliseconds: 50));

      final newDoc = _makeDoc(id: 'newOrder');
      final change = _makeChange(doc: newDoc, type: ChangeType.create);
      changeController.add(change);

      await Future.delayed(const Duration(milliseconds: 50));
      await changeController.close();

      final ordersList = await ordersFuture;
      expect(ordersList.first, isEmpty);
      expect(ordersList.last.length, 1);
      expect(ordersList.last.first.orderId, 'newOrder');
    });

    test('removes order on delete change', () async {
      final doc1 = _makeDoc(id: 'order1');
      when(mockSnapshot.docs).thenReturn([doc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .take(2)
          .toList();

      await Future.delayed(const Duration(milliseconds: 50));

      final deleteChange = _makeChange(doc: doc1, type: ChangeType.delete);
      changeController.add(deleteChange);

      await Future.delayed(const Duration(milliseconds: 50));
      await changeController.close();

      final ordersList = await ordersFuture;
      expect(ordersList.first.length, 1);
      expect(ordersList.last, isEmpty);
    });

    test('removes order when accept returns false', () async {
      final doc1 = _makeDoc(id: 'order1');
      when(mockSnapshot.docs).thenReturn([doc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      var acceptValue = true;
      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => acceptValue,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .take(2)
          .toList();

      await Future.delayed(const Duration(milliseconds: 50));

      acceptValue = false;
      final modifyChange = _makeChange(doc: doc1, type: ChangeType.update);
      changeController.add(modifyChange);

      await Future.delayed(const Duration(milliseconds: 50));
      await changeController.close();

      final ordersList = await ordersFuture;
      expect(ordersList.first.length, 1);
      expect(ordersList.last, isEmpty);
    });

    test('updates order on modified change', () async {
      final doc1 = _makeDoc(
        id: 'order1',
        data: {Fields.orderId: 'order1', Fields.totalAmountCents: 1000},
      );
      when(mockSnapshot.docs).thenReturn([doc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      var totalCents = 1000;
      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id, totalCents: totalCents),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .take(2)
          .toList();

      await Future.delayed(const Duration(milliseconds: 50));

      totalCents = 2000;
      final modifyChange = _makeChange(doc: doc1, type: ChangeType.update);
      changeController.add(modifyChange);

      await Future.delayed(const Duration(milliseconds: 50));
      await changeController.close();

      final ordersList = await ordersFuture;
      expect(ordersList.first.first.totalAmountCents, 1000);
      expect(ordersList.last.first.totalAmountCents, 2000);
    });

    test('handles errors from initial query', () async {
      when(mockQuery.get()).thenThrow(Exception('Query failed'));

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final stream = helper.watchOrdersImpl(
        initialQuery: () => mockQuery,
        accept: (_) => true,
        sort: (orders) => orders,
        realtimeChanges: () => changeController.stream,
      );

      expect(stream.first, throwsA(isA<Exception>()));

      await changeController.close();
    });

    test('skips malformed documents silently', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => throw Exception('Malformed'),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .first
          .timeout(const Duration(seconds: 2));

      await changeController.close();

      final orders = await ordersFuture;
      expect(orders, isEmpty);
    });

    test('stream remains active after WebSocket error', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final changeController = StreamController<DocumentChange>.broadcast();
      when(
        mockCollection.snapshots(),
      ).thenAnswer((_) => changeController.stream);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final ordersFuture = helper
          .watchOrdersImpl(
            initialQuery: () => mockQuery,
            accept: (_) => true,
            sort: (orders) => orders,
            realtimeChanges: () => changeController.stream,
          )
          .take(2)
          .toList();

      await Future.delayed(const Duration(milliseconds: 50));

      changeController.addError(Exception('WebSocket error'));

      await Future.delayed(const Duration(milliseconds: 50));

      final newDoc = _makeDoc(id: 'recovered');
      final newChange = _makeChange(doc: newDoc, type: ChangeType.create);
      changeController.add(newChange);

      await Future.delayed(const Duration(milliseconds: 50));
      await changeController.close();

      final ordersList = await ordersFuture;
      expect(ordersList.first, isEmpty);
      expect(ordersList.last.length, 1);
    });
  });

  group('watchPaidOrderBySessionImpl', () {
    late MockOrignaBase mockOb;
    late MockCollectionRef mockCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;

    setUp(() {
      mockOb = MockOrignaBase();
      mockCollection = MockCollectionRef();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();

      when(mockOb.collection(Collections.orders)).thenReturn(mockCollection);
      when(
        mockCollection.where(
          Fields.stripeSessionId,
          isEqualTo: anyNamed('isEqualTo'),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(Fields.paymentStatus, isEqualTo: anyNamed('isEqualTo')),
      ).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockQuery);
    });

    test('returns null when no order found', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final order = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      expect(order, isNull);
    });

    test('returns order when found', () async {
      final doc = _makeDoc(
        id: 'order1',
        data: {
          Fields.orderId: 'order1',
          Fields.stripeSessionId: 'session_123',
          Fields.paymentStatus: PaymentStatusValues.captured,
        },
      );
      when(mockSnapshot.docs).thenReturn([doc]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final order = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      expect(order, isNotNull);
      expect(order!.orderId, 'order1');
    });

    test('queries with correct session ID filter', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      await helper
          .watchPaidOrderBySessionImpl('test_session_id')
          .first
          .timeout(const Duration(seconds: 5));

      verify(
        mockCollection.where(
          Fields.stripeSessionId,
          isEqualTo: 'test_session_id',
        ),
      ).called(1);
    });

    test('queries with captured payment status filter', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      verify(
        mockQuery.where(
          Fields.paymentStatus,
          isEqualTo: PaymentStatusValues.captured,
        ),
      ).called(1);
    });

    test('applies limit of 1', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      verify(mockQuery.limit(1)).called(1);
    });

    test('emits null initially when no order', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final results = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .take(1)
          .timeout(const Duration(seconds: 5))
          .toList();

      expect(results, containsAll([isNull]));
    });

    test('emits error on query failure', () async {
      when(mockQuery.get()).thenThrow(Exception('Query failed'));

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      expect(
        helper.watchPaidOrderBySessionImpl('session_123').first,
        throwsA(isA<Exception>()),
      );
    });

    test('polls multiple times until order appears', () async {
      var callCount = 0;
      when(mockQuery.get()).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) {
          return _emptySnapshot();
        }
        final doc = _makeDoc(id: 'order1');
        final snap = MockQuerySnapshot();
        when(snap.docs).thenReturn([doc]);
        return snap;
      });

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final results = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .take(3)
          .timeout(const Duration(seconds: 15))
          .toList();

      expect(results.first, isNull);
      expect(results.last, isNotNull);
      expect(callCount, greaterThanOrEqualTo(3));
    });

    test('uses first document from snapshot', () async {
      final doc1 = _makeDoc(id: 'order1');
      final doc2 = _makeDoc(id: 'order2');
      when(mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final order = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      expect(order!.orderId, 'order1');
    });

    test('handles empty snapshot docs list', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestOrderQueryHelpers(
        ob: mockOb,
        converter: (doc) => _makeOrder(orderId: doc.id),
      );

      final order = await helper
          .watchPaidOrderBySessionImpl('session_123')
          .first
          .timeout(const Duration(seconds: 5));

      expect(order, isNull);
    });
  });
}

MockQuerySnapshot _emptySnapshot() {
  final snap = MockQuerySnapshot();
  when(snap.docs).thenReturn([]);
  return snap;
}
