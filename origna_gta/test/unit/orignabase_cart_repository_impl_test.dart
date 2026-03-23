import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

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
  Map<String, dynamic>? lastSetData;
  Map<String, dynamic>? lastUpdateData;
  bool deleted = false;

  _FakeDocumentRef({this.id = 'doc_id', _FakeDocument? doc})
    : documentValue = doc;

  @override
  Future<Document?> get() async => documentValue;

  @override
  Future<Document?> set(Map<String, dynamic> data) async {
    lastSetData = data;
    return documentValue;
  }

  @override
  Future<Document?> update(Map<String, dynamic> data) async {
    lastUpdateData = data;
    return documentValue;
  }

  @override
  Future<void> delete() async {
    deleted = true;
  }
}

class _FakeSubcollectionRef extends Fake implements SubcollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};
  List<Document> queryDocs = [];
  StreamController<DocumentChange>? _snapshotController;

  @override
  final String collectionPath = 'users__cart';

  _FakeSubcollectionRef();

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
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(queryDocs);

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
  Query startAfterId(String id) => this;

  @override
  Stream<DocumentChange> snapshots() {
    _snapshotController ??= StreamController<DocumentChange>.broadcast();
    return _snapshotController!.stream;
  }
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};
  final _FakeSubcollectionRef cartSubcollection = _FakeSubcollectionRef();
  List<Document> queryDocs = [];

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
  SubcollectionRef subcollection(String docId, String childCollection) {
    return cartSubcollection;
  }

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(queryDocs);

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
  final _FakeCollectionRef usersCollection = _FakeCollectionRef();
  final _FakeCollectionRef productsCollection = _FakeCollectionRef();
  final _FakeBatch batchInstance = _FakeBatch();

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.users) return usersCollection;
    if (name == Collections.products) return productsCollection;
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
  }) async => {'success': true};
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseCartRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    repository = OrignaBaseCartRepository(fakeOb);
  });

  group('OrignaBaseCartRepository - constants', () {
    test('maxCartItemQuantity is 99', () {
      expect(OrignaBaseCartRepository.maxCartItemQuantity, 99);
    });

    test('minCartItemQuantity is 1', () {
      expect(OrignaBaseCartRepository.minCartItemQuantity, 1);
    });
  });

  group('OrignaBaseCartRepository - addToCart', () {
    test('returns early when quantity is below minimum', () async {
      await repository.addToCart('user_1', 'prod_1', 0);
      // No error, just returns early
    });

    test('returns early when quantity is negative', () async {
      await repository.addToCart('user_1', 'prod_1', -1);
    });

    test('creates new cart item with set', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;

      await repository.addToCart('user_1', 'prod_1', 2);

      final docRef = cartRef.docsMap['prod_1'];
      expect(docRef, isNotNull);
      expect(docRef!.lastSetData, isNotNull);
      expect(docRef.lastSetData?[Fields.productId], 'prod_1');
      expect(docRef.lastSetData?[Fields.quantity], 2);
      expect(docRef.lastSetData?[Fields.userId], 'users:user_1');
      expect(docRef.lastSetData?['parent_id'], 'users:user_1');
    });

    test('accumulates quantity for existing item', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final existingDoc = _FakeDocument('prod_1', {
        Fields.productId: 'prod_1',
        Fields.quantity: 3,
        'parent_id': 'users:user_1',
        Fields.createdAt: DateTime.now().toIso8601String(),
      });
      cartRef.setDoc('prod_1', _FakeDocumentRef(doc: existingDoc));

      await repository.addToCart('user_1', 'prod_1', 2);

      final docRef = cartRef.docsMap['prod_1']!;
      expect(docRef.lastSetData?[Fields.quantity], 5);
    });

    test('clamps quantity to maxCartItemQuantity', () async {
      await repository.addToCart('user_1', 'prod_1', 100);

      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['prod_1']!;
      expect(docRef.lastSetData?[Fields.quantity], 99);
    });

    test('handles userId with collection prefix', () async {
      await repository.addToCart('users:user_1', 'prod_1', 1);

      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['prod_1']!;
      expect(docRef.lastSetData?[Fields.userId], 'users:user_1');
      expect(docRef.lastSetData?['parent_id'], 'users:user_1');
    });

    test('creates variant doc ID when variantId is provided', () async {
      await repository.addToCart('user_1', 'prod_1', 1, variantId: 'red');

      final cartRef = fakeOb.usersCollection.cartSubcollection;
      expect(cartRef.docsMap.containsKey('prod_1_red'), true);
    });

    test('includes variant metadata', () async {
      await repository.addToCart(
        'user_1',
        'prod_1',
        1,
        variantId: 'red',
        variantTitle: 'Red',
        variantOptions: {'color': 'red'},
        variantSku: 'SKU-RED',
      );

      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['prod_1_red']!;
      expect(docRef.lastSetData?[Fields.variantId], 'red');
      expect(docRef.lastSetData?[Fields.variantTitle], 'Red');
      expect(docRef.lastSetData?[Fields.variantSku], 'SKU-RED');
    });

    test('ignores existing doc without matching parent_id', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final existingDoc = _FakeDocument('prod_1', {
        Fields.productId: 'prod_1',
        Fields.quantity: 5,
        'parent_id': 'users:different_user',
      });
      cartRef.setDoc('prod_1', _FakeDocumentRef(doc: existingDoc));

      await repository.addToCart('user_1', 'prod_1', 1);

      final docRef = cartRef.docsMap['prod_1']!;
      expect(docRef.lastSetData?[Fields.quantity], 1);
    });
  });

  group('OrignaBaseCartRepository - clearCart', () {
    test('clears all cart items via batch delete', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      cartRef.queryDocs = [
        _FakeDocument('users__cart:prod_1', {Fields.productId: 'prod_1'}),
        _FakeDocument('users__cart:prod_2', {Fields.productId: 'prod_2'}),
      ];

      await repository.clearCart('user_1');

      expect(fakeOb.batchInstance.operations.length, 2);
      expect(fakeOb.batchInstance.operations[0]['type'], 'delete');
      expect(fakeOb.batchInstance.operations[0]['id'], 'prod_1');
      expect(fakeOb.batchInstance.operations[1]['id'], 'prod_2');
    });

    test('returns early when cart is empty', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      cartRef.queryDocs = [];

      await repository.clearCart('user_1');

      expect(fakeOb.batchInstance.operations, isEmpty);
    });
  });

  group('OrignaBaseCartRepository - getProductSellerId', () {
    test('returns sellerId when product exists', () async {
      final doc = _FakeDocument('prod_1', {Fields.sellerId: 'seller_abc'});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final sellerId = await repository.getProductSellerId('prod_1');
      expect(sellerId, 'seller_abc');
    });

    test('returns null when product does not exist', () async {
      final sellerId = await repository.getProductSellerId('nonexistent');
      expect(sellerId, isNull);
    });

    test('returns null when doc exists is false', () async {
      final doc = _FakeDocument('prod_1', {}, exists: false);
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final sellerId = await repository.getProductSellerId('prod_1');
      expect(sellerId, isNull);
    });
  });

  group('OrignaBaseCartRepository - isVariantValid', () {
    test('returns true for active variant', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.variants: [
          {Fields.variantId: 'red', 'isActive': true},
          {Fields.variantId: 'blue', 'isActive': false},
        ],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'red');
      expect(valid, true);
    });

    test('returns false for inactive variant', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.variants: [
          {Fields.variantId: 'blue', 'isActive': false},
        ],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'blue');
      expect(valid, false);
    });

    test('returns false for nonexistent variant', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.variants: [
          {Fields.variantId: 'red', 'isActive': true},
        ],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'green');
      expect(valid, false);
    });

    test('returns false when product does not exist', () async {
      final valid = await repository.isVariantValid('nonexistent', 'red');
      expect(valid, false);
    });

    test('returns false when variants is null', () async {
      final doc = _FakeDocument('prod_1', {});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'red');
      expect(valid, false);
    });

    test('treats variant without isActive as active by default', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.variants: [
          {Fields.variantId: 'green'},
        ],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'green');
      expect(valid, true);
    });
  });

  group('OrignaBaseCartRepository - removeFromCart', () {
    test('deletes the cart item document', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.removeFromCart('user_1', 'prod_1');

      expect(docRef.deleted, true);
    });
  });

  group('OrignaBaseCartRepository - updateBuyerNote', () {
    test('sets buyerNote when note is provided', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateBuyerNote('user_1', 'prod_1', 'Please gift wrap');

      expect(docRef.lastUpdateData?[Fields.buyerNote], 'Please gift wrap');
    });

    test('deletes buyerNote when note is null', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateBuyerNote('user_1', 'prod_1', null);

      expect(docRef.lastUpdateData?[Fields.buyerNote], isA<FieldValue>());
    });
  });

  group('OrignaBaseCartRepository - updateQuantity', () {
    test('updates quantity when valid', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateQuantity('user_1', 'prod_1', 5);

      expect(docRef.lastUpdateData?[Fields.quantity], 5);
    });

    test('clamps to maxCartItemQuantity', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateQuantity('user_1', 'prod_1', 150);

      expect(docRef.lastUpdateData?[Fields.quantity], 99);
    });

    test('deletes item when quantity is zero', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateQuantity('user_1', 'prod_1', 0);

      expect(docRef.deleted, true);
    });

    test('deletes item when quantity is negative', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateQuantity('user_1', 'prod_1', -5);

      expect(docRef.deleted, true);
    });
  });

  group('OrignaBaseCartRepository - watchCart', () {
    test('returns a stream of cart items', () {
      final stream = repository.watchCart('user_1');
      expect(stream, isA<Stream<List<CartItemModel>>>());
    });
  });
}
