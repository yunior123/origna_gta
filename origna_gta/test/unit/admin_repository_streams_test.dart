import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/admin/orignabase_admin_repository.dart';
import 'package:origna_gta/utils/utils.dart';

// =============================================================================
// FAKES — reuse the fake pattern from orignabase_admin_repository_impl_test
// =============================================================================

class _FakeAuth extends Fake implements OrignaBaseAuth {
  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;
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

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  List<Document> queryDocs;
  bool shouldThrow;

  _FakeCollectionRef({this.queryDocs = const [], this.shouldThrow = false});

  @override
  DocumentRef doc(String id) => _FakeDocumentRef();

  @override
  Future<QuerySnapshot> get() async {
    if (shouldThrow) throw Exception('Query failed');
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
}

class _FakeDocumentRef extends Fake implements DocumentRef {
  @override
  Future<Document?> get() async => null;
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final Map<String, _FakeCollectionRef> collections = {};

  _FakeOrignaBase() {
    collections[Collections.orders] = _FakeCollectionRef();
    collections[Collections.products] = _FakeCollectionRef();
    collections[Collections.users] = _FakeCollectionRef();
    collections[Collections.productRatings] = _FakeCollectionRef();
  }

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    return collections[name] ?? _FakeCollectionRef();
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return {'success': true};
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseAdminRepository repo;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeOb.authValue.currentUserIdValue = 'admin_1';
    repo = OrignaBaseAdminRepository(fakeOb);
  });

  group('watchOrders', () {
    test('emits order list from collection', () async {
      final orderDoc = _FakeDocument('ord_1', {
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.createdAt: '2026-01-01T00:00:00Z',
        Fields.totalAmountCents: 10000,
        Fields.subtotalCents: 9000,
        Fields.taxAmountCents: 500,
        Fields.shippingCostCents: 500,
        Fields.items: <dynamic>[],
        Fields.userId: 'buyer_1',
      });
      fakeOb.collections[Collections.orders]!.queryDocs = [orderDoc];

      final stream = repo.watchOrders();
      final orders = await stream.first;
      expect(orders, isNotEmpty);
      expect(orders.first.orderId, 'ord_1');
    });

    test('emits with status filter', () async {
      fakeOb.collections[Collections.orders]!.queryDocs = [];

      final stream = repo.watchOrders(status: OrderStatusValues.pending);
      final orders = await stream.first;
      expect(orders, isEmpty);
    });

    test('emits with "all" status filter (no filter applied)', () async {
      fakeOb.collections[Collections.orders]!.queryDocs = [];

      final stream = repo.watchOrders(status: FilterValues.all);
      final orders = await stream.first;
      expect(orders, isEmpty);
    });

    test('emits error on query failure', () async {
      fakeOb.collections[Collections.orders]!.shouldThrow = true;

      final stream = repo.watchOrders();
      expect(stream.first, throwsException);
    });
  });

  group('watchProducts', () {
    test('emits product list from collection', () async {
      final prodDoc = _FakeDocument('prod_1', {
        Fields.name: 'Test Product',
        Fields.priceCents: 5000,
        Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        Fields.createdAt: '2026-01-01T00:00:00Z',
      });
      fakeOb.collections[Collections.products]!.queryDocs = [prodDoc];

      final stream = repo.watchProducts();
      final products = await stream.first;
      expect(products, isNotEmpty);
    });

    test('emits filtered by sellerId', () async {
      fakeOb.collections[Collections.products]!.queryDocs = [];

      final stream = repo.watchProducts(sellerId: 'seller_1');
      final products = await stream.first;
      expect(products, isEmpty);
    });
  });

  group('watchPendingReviewProducts', () {
    test('emits pending review products', () async {
      fakeOb.collections[Collections.products]!.queryDocs = [];

      final stream = repo.watchPendingReviewProducts();
      final products = await stream.first;
      expect(products, isEmpty);
    });
  });

  group('watchReviews', () {
    test('emits review maps', () async {
      final reviewDoc = _FakeDocument('rev_1', {
        Fields.rating: 5,
        Fields.reviewText: 'Great product',
        Fields.createdAt: '2026-01-01T00:00:00Z',
      });
      fakeOb.collections[Collections.productRatings]!.queryDocs = [reviewDoc];

      final stream = repo.watchReviews();
      final reviews = await stream.first;
      expect(reviews, isNotEmpty);
      expect(reviews.first['id'], 'rev_1');
    });

    test('supports flaggedOnly filter', () async {
      fakeOb.collections[Collections.productRatings]!.queryDocs = [];

      final stream = repo.watchReviews(flaggedOnly: true);
      final reviews = await stream.first;
      expect(reviews, isEmpty);
    });

    test('supports hasPhotosOnly filter', () async {
      fakeOb.collections[Collections.productRatings]!.queryDocs = [];

      final stream = repo.watchReviews(hasPhotosOnly: true);
      final reviews = await stream.first;
      expect(reviews, isEmpty);
    });
  });

  group('watchSellers', () {
    test('emits seller users', () async {
      final userDoc = _FakeDocument('user_1', {
        Fields.email: 'seller@test.com',
        Fields.name: 'Seller One',
        Fields.roles: [UserRoleValues.seller],
        Fields.createdAt: '2026-01-01T00:00:00Z',
      });
      fakeOb.collections[Collections.users]!.queryDocs = [userDoc];

      final stream = repo.watchSellers();
      final sellers = await stream.first;
      expect(sellers, isNotEmpty);
    });
  });

  group('watchUsers', () {
    test('emits all users', () async {
      final userDoc = _FakeDocument('user_1', {
        Fields.email: 'user@test.com',
        Fields.name: 'User One',
        Fields.roles: [UserRoleValues.buyer],
        Fields.createdAt: '2026-01-01T00:00:00Z',
      });
      fakeOb.collections[Collections.users]!.queryDocs = [userDoc];

      final stream = repo.watchUsers();
      final users = await stream.first;
      expect(users, isNotEmpty);
    });
  });
}
