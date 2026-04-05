import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

class _FakeAuth extends Fake implements OrignaBaseAuth {
  @override
  String? get currentUserId => 'user_123';
}

class _FakeDocument extends Fake implements Document {
  @override
  final String id;

  @override
  final Map<String, dynamic> data;

  @override
  final bool exists;

  _FakeDocument(this.id, this.data, {this.exists = true});

  @override
  T? get<T>(String field) => data[field] as T?;

  @override
  dynamic operator [](String key) => data[key];

  @override
  bool containsKey(String key) => data.containsKey(key);
}

class _FakeDocumentRef extends Fake implements DocumentRef {
  @override
  final String id;

  _FakeDocument? documentValue;
  Map<String, dynamic>? lastUpdateData;

  _FakeDocumentRef({this.id = 'doc_id', _FakeDocument? doc})
    : documentValue = doc;

  @override
  Future<Document?> get() async => documentValue;

  @override
  Future<Document?> update(Map<String, dynamic> data) async {
    lastUpdateData = data;
    return documentValue;
  }

  @override
  Future<void> delete() async {}
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};
  List<Document> queryDocs = [];
  _FakeDocumentRef? lastDocSet;

  void setDoc(String id, _FakeDocumentRef ref) {
    docsMap[id] = ref;
  }

  @override
  DocumentRef doc(String id) {
    if (docsMap.containsKey(id)) return docsMap[id]!;
    final ref = _FakeDocumentRef(id: id);
    docsMap[id] = ref;
    return ref;
  }

  @override
  Future<QuerySnapshot> get() async {
    return _FakeQuerySnapshot(queryDocs);
  }

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) => this;

  @override
  Query orderBy(String field, {bool descending = false}) => this;

  @override
  Query limit(int limit) => this;

  @override
  Query offset(int count) => this;

  @override
  Query startAfterId(String id) => this;

  @override
  Future<Document> add(Map<String, dynamic> data) async {
    final ref = _FakeDocumentRef(id: 'auto_id');
    lastDocSet = ref;
    return _FakeDocument('auto_id', data);
  }
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeBatch extends Fake implements WriteBatch {
  final List<Map<String, dynamic>> operations = [];

  @override
  void delete(String collection, String docId) {
    operations.add({'type': 'delete', 'collection': collection, 'id': docId});
  }

  @override
  void create(String collection, Map<String, dynamic> data) {
    operations.add({'type': 'create', 'collection': collection, 'data': data});
  }

  @override
  void update(String collection, String id, Map<String, dynamic> data) {
    operations.add({'type': 'update', 'collection': collection, 'id': id});
  }

  @override
  Future<List<Map<String, dynamic>>> commit() async => [];
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef ordersCollection = _FakeCollectionRef();
  final _FakeCollectionRef usersCollection = _FakeCollectionRef();
  final _FakeCollectionRef returnRequestsCollection = _FakeCollectionRef();
  final _FakeBatch batchInstance = _FakeBatch();

  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {'success': true};

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.orders) return ordersCollection;
    if (name == Collections.users) return usersCollection;
    if (name == Collections.returnRequests) return returnRequestsCollection;
    return _FakeCollectionRef();
  }

  @override
  WriteBatch batch() => batchInstance;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastRequestMethod = method;
    lastRequestPath = path;
    lastRequestBody = body;
    return requestResponse;
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseOrderRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    repository = OrignaBaseOrderRepository(fakeOb);
  });

  group('OrignaBaseOrderRepository - docToOrder', () {
    test('converts document to Order model', () {
      final doc = _FakeDocument('order_123', {
        Fields.userId: 'user_1',
        Fields.orderStatus: OrderStatusValues.confirmed,
        Fields.paymentStatus: PaymentStatusValues.captured,
        Fields.totalAmountCents: 5000,
        Fields.subtotalCents: 4500,
        Fields.shippingCostCents: 500,
        Fields.taxAmountCents: 0,
        Fields.currency: 'cad',
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.shippingAddress: {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M1M 1M1',
          'country': 'CA',
        },
        Fields.items: [],
        Fields.sellerIds: ['seller_1'],
        Fields.stripeSessionId: 'sess_123',
      });

      final order = repository.docToOrder(doc);

      expect(order.orderId, 'order_123');
      expect(order.userId, 'user_1');
    });
  });

  group('OrignaBaseOrderRepository - approveShippingCost', () {
    test('sends approve request', () async {
      await repository.approveShippingCost('order_1', true);

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersApproveShipping);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[ApiKeys.approved], true);
    });

    test('sends reject request', () async {
      await repository.approveShippingCost('order_2', false);

      expect(fakeOb.lastRequestBody?[ApiKeys.approved], false);
    });
  });

  group('OrignaBaseOrderRepository - capturePayment', () {
    test('sends capture request', () async {
      await repository.capturePayment('order_1');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.paymentsCapture);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
    });
  });

  group('OrignaBaseOrderRepository - confirmReceipt', () {
    test('sends confirm receipt with productId', () async {
      await repository.confirmReceipt('order_1', productId: 'prod_1');

      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersConfirmReceipt);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
    });

    test('falls back to capturePayment without productId', () async {
      await repository.confirmReceipt('order_1');

      expect(fakeOb.lastRequestPath, ApiEndpoints.paymentsCapture);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
    });

    test('falls back to capturePayment with empty productId', () async {
      await repository.confirmReceipt('order_1', productId: '');

      expect(fakeOb.lastRequestPath, ApiEndpoints.paymentsCapture);
    });
  });

  group('OrignaBaseOrderRepository - createCheckoutSession', () {
    test('sends checkout data and returns response', () async {
      fakeOb.requestResponse = {
        ApiKeys.sessionId: 'sess_abc',
        ApiKeys.checkoutUrl: 'https://checkout.stripe.com/abc',
      };

      final result = await repository.createCheckoutSession({
        'items': [
          {'productId': 'p1', 'quantity': 1},
        ],
      });

      expect(fakeOb.lastRequestPath, ApiEndpoints.checkoutSession);
      expect(result[ApiKeys.sessionId], 'sess_abc');
      expect(result[ApiKeys.checkoutUrl], 'https://checkout.stripe.com/abc');
    });
  });

  group('OrignaBaseOrderRepository - fetchOrderById', () {
    test('returns order when doc exists', () async {
      final doc = _FakeDocument('order_1', {
        Fields.userId: 'user_1',
        Fields.totalAmountCents: 1000,
        Fields.subtotalCents: 900,
        Fields.shippingCostCents: 100,
        Fields.taxAmountCents: 0,
        Fields.currency: 'cad',
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.shippingAddress: {},
        Fields.items: [],
        Fields.sellerIds: [],
        Fields.stripeSessionId: 'sess_1',
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.paymentStatus: PaymentStatusValues.authorized,
        Fields.shippingApprovalStatus: ShippingApprovalStatusValues.notRequired,
        Fields.taxes: {},
      });
      fakeOb.ordersCollection.setDoc('order_1', _FakeDocumentRef(doc: doc));

      final order = await repository.fetchOrderById('order_1');

      expect(order, isNotNull);
      expect(order!.orderId, 'order_1');
    });

    test('returns null when doc does not exist', () async {
      final order = await repository.fetchOrderById('nonexistent');
      expect(order, isNull);
    });

    test('returns null when doc exists flag is false', () async {
      final doc = _FakeDocument('order_1', {}, exists: false);
      fakeOb.ordersCollection.setDoc('order_1', _FakeDocumentRef(doc: doc));

      final order = await repository.fetchOrderById('order_1');
      expect(order, isNull);
    });
  });

  group('OrignaBaseOrderRepository - updateItemStatus', () {
    test('sends update with tracking info', () async {
      await repository.updateItemStatus(
        'order_1',
        'item_1',
        DeliveryStatusValues.shipped,
        trackingNumber: '1Z999AA10123456784',
        carrier: CarrierValues.ups,
        carrierNote: 'Handle with care',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersUpdateItemStatus);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'item_1');
      expect(
        fakeOb.lastRequestBody?[ApiKeys.newStatus],
        DeliveryStatusValues.shipped,
      );
      expect(
        fakeOb.lastRequestBody?[Fields.trackingNumber],
        '1Z999AA10123456784',
      );
      expect(fakeOb.lastRequestBody?[Fields.carrier], CarrierValues.ups);
      expect(fakeOb.lastRequestBody?[Fields.carrierNote], 'Handle with care');
    });

    test('sends update without optional fields', () async {
      await repository.updateItemStatus(
        'order_1',
        'item_1',
        DeliveryStatusValues.pending,
      );

      expect(fakeOb.lastRequestBody?[Fields.trackingNumber], isNull);
      expect(fakeOb.lastRequestBody?[Fields.carrier], isNull);
      expect(fakeOb.lastRequestBody?[Fields.carrierNote], isNull);
    });
  });

  group('OrignaBaseOrderRepository - updateLastSession', () {
    test('updates user document with session data', () async {
      final userRef = _FakeDocumentRef(id: 'user_1');
      fakeOb.usersCollection.setDoc('user_1', userRef);

      await repository.updateLastSession('user_1', 'sess_1', 'order_1');

      expect(userRef.lastUpdateData, isNotNull);
      expect(userRef.lastUpdateData?[Fields.lastCheckoutSession], 'sess_1');
      expect(userRef.lastUpdateData?[Fields.lastOrderId], 'order_1');
    });
  });

  group('OrignaBaseOrderRepository - updateShippingCost', () {
    test('sends shipping cost update', () async {
      await repository.updateShippingCost(
        'order_1',
        1500,
        'Actual cost from carrier',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersUpdateShipping);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[ApiKeys.newShippingCostCents], 1500);
      expect(
        fakeOb.lastRequestBody?[ApiKeys.reason],
        'Actual cost from carrier',
      );
    });
  });

  group('OrignaBaseOrderRepository - createReturnRequest', () {
    test('sends return request with all fields', () async {
      fakeOb.requestResponse = {'success': true, Fields.returnId: 'ret_1'};

      final result = await repository.createReturnRequest(
        orderId: 'order_1',
        cartItemIds: ['item_1', 'item_2'],
        reason: 'Damaged item',
        description: 'Item arrived broken',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersCreateReturn);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[ApiKeys.itemIds], ['item_1', 'item_2']);
      expect(fakeOb.lastRequestBody?[Fields.returnReason], 'Damaged item');
      expect(fakeOb.lastRequestBody?['description'], 'Item arrived broken');
      expect(result[Fields.returnId], 'ret_1');
    });

    test('omits description when null', () async {
      await repository.createReturnRequest(
        orderId: 'order_2',
        cartItemIds: ['item_1'],
        reason: 'Wrong size',
      );

      expect(fakeOb.lastRequestBody?['description'], isNull);
    });

    test('omits description when empty', () async {
      await repository.createReturnRequest(
        orderId: 'order_2',
        cartItemIds: ['item_1'],
        reason: 'Wrong size',
        description: '',
      );

      expect(fakeOb.lastRequestBody?.containsKey('description'), isFalse);
    });
  });

  group('OrignaBaseOrderRepository - fetchReturnRequests', () {
    test('returns list of return requests', () async {
      fakeOb.returnRequestsCollection.queryDocs = [
        _FakeDocument('ret_1', {
          Fields.orderId: 'order_1',
          Fields.returnStatus: ReturnStatusValues.requested,
          Fields.returnReason: 'Damaged',
        }),
        _FakeDocument('ret_2', {
          Fields.orderId: 'order_1',
          Fields.returnStatus: ReturnStatusValues.approved,
          Fields.returnReason: 'Wrong item',
        }),
      ];

      final returns = await repository.fetchReturnRequests('order_1');

      expect(returns.length, 2);
    });

    test('returns empty list when no returns', () async {
      fakeOb.returnRequestsCollection.queryDocs = [];

      final returns = await repository.fetchReturnRequests('order_x');
      expect(returns, isEmpty);
    });
  });

  group('OrignaBaseOrderRepository - watchBuyerOrders', () {
    test('returns a stream', () {
      final stream = repository.watchBuyerOrders('user_1');
      expect(stream, isA<Stream<List<models.Order>>>());
    });
  });

  group('OrignaBaseOrderRepository - watchSellerOrders', () {
    test('returns a stream', () {
      final stream = repository.watchSellerOrders('seller_1');
      expect(stream, isA<Stream<List<models.Order>>>());
    });
  });

  group('OrignaBaseOrderRepository - watchPaidOrderBySession', () {
    test('returns a stream', () {
      final stream = repository.watchPaidOrderBySession('sess_1');
      expect(stream, isA<Stream<models.Order?>>());
    });
  });
}
