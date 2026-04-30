import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

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
  Query offset(int count) => this;

  @override
  Query startAfterId(String id) => this;

  @override
  Stream<DocumentChange> snapshots() {
    _snapshotController ??= StreamController<DocumentChange>.broadcast();
    return _snapshotController!.stream;
  }

  void emitChange(DocumentChange change) {
    _snapshotController?.add(change);
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

  @override
  Query offset(int count) => this;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseCartRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    repository = OrignaBaseCartRepository(fakeOb);
  });

  group('OrignaBaseCartRepository - constructor', () {
    test('creates repository with OrignaBase', () {
      final repo = OrignaBaseCartRepository(fakeOb);
      expect(repo, isA<OrignaBaseCartRepository>());
    });

    test('exposes maxCartItemQuantity constant', () {
      expect(OrignaBaseCartRepository.maxCartItemQuantity, 99);
    });

    test('exposes minCartItemQuantity constant', () {
      expect(OrignaBaseCartRepository.minCartItemQuantity, 1);
    });
  });

  group('OrignaBaseCartRepository - addToCart edge cases', () {
    test('handles quantity at maximum boundary', () async {
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 200}),
        ),
      );
      await repository.addToCart('user_1', 'prod_1', 99);
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['user_1_prod_1']!;
      expect(docRef.lastSetData?[Fields.quantity], 99);
    });

    test('rejects quantity above maximum', () async {
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 200}),
        ),
      );
      expect(
        () => repository.addToCart('user_1', 'prod_1', 150),
        throwsA(isA<ConflictException>()),
      );
    });

    test('handles userId with users: prefix', () async {
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 100}),
        ),
      );
      await repository.addToCart('users:user_1', 'prod_1', 1);
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['user_1_prod_1']!;
      expect(docRef.lastSetData?[Fields.userId], 'user_1');
      expect(docRef.lastSetData?['parent_id'], 'users:user_1');
    });

    test('handles productId with special characters', () async {
      fakeOb.productsCollection.setDoc(
        'prod-special_123',
        _FakeDocumentRef(
          id: 'prod-special_123',
          doc: _FakeDocument('prod-special_123', {Fields.stockQuantity: 100}),
        ),
      );
      await repository.addToCart('user_1', 'prod-special_123', 1);
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      expect(cartRef.docsMap.containsKey('user_1_prod-special_123'), true);
    });

    test('preserves createdAt for existing items', () async {
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 100}),
        ),
      );
      final existingTime = DateTime(2025, 1, 1);
      final existingTimeStr = existingTime.toIso8601String();
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final existingDoc = _FakeDocument('prod_1', {
        Fields.productId: 'prod_1',
        Fields.quantity: 3,
        'parent_id': 'users:user_1',
        Fields.createdAt: existingTimeStr,
      });
      cartRef.queryDocs = [existingDoc];
      cartRef.setDoc('prod_1', _FakeDocumentRef(doc: existingDoc));

      await repository.addToCart('user_1', 'prod_1', 2);

      final docRef = cartRef.docsMap['prod_1']!;
      final createdAt = docRef.documentValue?.data[Fields.createdAt];
      expect(createdAt, existingTimeStr);
    });

    test('sets new createdAt for new items', () async {
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 100}),
        ),
      );
      await repository.addToCart('user_1', 'prod_1', 1);
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = cartRef.docsMap['user_1_prod_1']!;
      expect(docRef.lastSetData?[Fields.createdAt], isNotNull);
    });
  });

  group('OrignaBaseCartRepository - clearCart edge cases', () {
    test('handles empty cart gracefully', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      cartRef.queryDocs = [];

      await repository.clearCart('user_1');

      expect(fakeOb.batchInstance.operations, isEmpty);
    });

    test('clears single item', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      cartRef.queryDocs = [
        _FakeDocument('users__cart:prod_1', {Fields.productId: 'prod_1'}),
      ];

      await repository.clearCart('user_1');

      expect(fakeOb.batchInstance.operations.length, 1);
    });

    test('clears multiple items', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      cartRef.queryDocs = [
        _FakeDocument('users__cart:prod_1', {Fields.productId: 'prod_1'}),
        _FakeDocument('users__cart:prod_2', {Fields.productId: 'prod_2'}),
        _FakeDocument('users__cart:prod_3', {Fields.productId: 'prod_3'}),
      ];

      await repository.clearCart('user_1');

      expect(fakeOb.batchInstance.operations.length, 3);
    });
  });

  group('OrignaBaseCartRepository - getProductSellerId edge cases', () {
    test('returns null for non-existent product', () async {
      final sellerId = await repository.getProductSellerId('nonexistent');
      expect(sellerId, isNull);
    });

    test('returns null for document with exists=false', () async {
      final doc = _FakeDocument('prod_1', {}, exists: false);
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final sellerId = await repository.getProductSellerId('prod_1');
      expect(sellerId, isNull);
    });

    test('returns sellerId string', () async {
      final doc = _FakeDocument('prod_1', {Fields.sellerId: 'seller_abc'});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final sellerId = await repository.getProductSellerId('prod_1');
      expect(sellerId, 'seller_abc');
    });

    test('returns null when sellerId field is null', () async {
      final doc = _FakeDocument('prod_1', {});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final sellerId = await repository.getProductSellerId('prod_1');
      expect(sellerId, isNull);
    });
  });

  group('OrignaBaseCartRepository - isVariantValid edge cases', () {
    test('returns false for non-existent product', () async {
      final valid = await repository.isVariantValid('nonexistent', 'red');
      expect(valid, false);
    });

    test('returns false for empty variants list', () async {
      final doc = _FakeDocument('prod_1', {Fields.variants: []});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'red');
      expect(valid, false);
    });

    test('returns false for null variants', () async {
      final doc = _FakeDocument('prod_1', {});
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'red');
      expect(valid, false);
    });

    test(
      'returns true for variant without isActive (defaults to true)',
      () async {
        final doc = _FakeDocument('prod_1', {
          Fields.variants: [
            {Fields.variantId: 'green'},
          ],
        });
        fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

        final valid = await repository.isVariantValid('prod_1', 'green');
        expect(valid, true);
      },
    );

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

    test('returns false for wrong variantId', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.variants: [
          {Fields.variantId: 'red', 'isActive': true},
        ],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final valid = await repository.isVariantValid('prod_1', 'blue');
      expect(valid, false);
    });
  });

  group('OrignaBaseCartRepository - updateQuantity edge cases', () {
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

    test('clamps to maximum quantity', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final cartDoc = _FakeDocument('prod_1', {
        Fields.productId: 'prod_1',
        Fields.quantity: 2,
      });
      final docRef = _FakeDocumentRef(id: 'prod_1', doc: cartDoc);
      cartRef.setDoc('prod_1', docRef);
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 300}),
        ),
      );

      await repository.updateQuantity('user_1', 'prod_1', 200);

      expect(docRef.lastUpdateData?[Fields.quantity], 99);
    });

    test('sets quantity to minimum when at boundary', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final cartDoc = _FakeDocument('prod_1', {
        Fields.productId: 'prod_1',
        Fields.quantity: 5,
      });
      final docRef = _FakeDocumentRef(id: 'prod_1', doc: cartDoc);
      cartRef.setDoc('prod_1', docRef);
      fakeOb.productsCollection.setDoc(
        'prod_1',
        _FakeDocumentRef(
          id: 'prod_1',
          doc: _FakeDocument('prod_1', {Fields.stockQuantity: 100}),
        ),
      );

      await repository.updateQuantity('user_1', 'prod_1', 1);

      expect(docRef.lastUpdateData?[Fields.quantity], 1);
    });
  });

  group('OrignaBaseCartRepository - updateBuyerNote edge cases', () {
    test('sets empty string note', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateBuyerNote('user_1', 'prod_1', '');

      expect(docRef.lastUpdateData?[Fields.buyerNote], '');
    });

    test('sets long note', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      final longNote = 'a' * 500;
      await repository.updateBuyerNote('user_1', 'prod_1', longNote);

      expect(docRef.lastUpdateData?[Fields.buyerNote], longNote);
    });

    test('sets note with special characters', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final docRef = _FakeDocumentRef(id: 'prod_1');
      cartRef.setDoc('prod_1', docRef);

      await repository.updateBuyerNote(
        'user_1',
        'prod_1',
        'Please wrap it! 🎁',
      );

      expect(docRef.lastUpdateData?[Fields.buyerNote], 'Please wrap it! 🎁');
    });
  });

  group('OrignaBaseCartRepository - watchCart', () {
    test('returns stream that can be listened to', () {
      final stream = repository.watchCart('user_1');
      expect(stream, isA<Stream<List<CartItemModel>>>());
    });

    test('emits items sorted by createdAt', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;
      final now = DateTime.now();

      cartRef.queryDocs = [
        _FakeDocument('prod_2', {
          Fields.productId: 'prod_2',
          Fields.quantity: 1,
          Fields.createdAt: now
              .add(const Duration(minutes: 2))
              .toIso8601String(),
        }),
        _FakeDocument('prod_1', {
          Fields.productId: 'prod_1',
          Fields.quantity: 1,
          Fields.createdAt: now.toIso8601String(),
        }),
      ];

      final stream = repository.watchCart('user_1');
      final items = await stream.first;

      expect(items.length, 2);
    });

    test('filters out items with zero quantity', () async {
      final cartRef = fakeOb.usersCollection.cartSubcollection;

      cartRef.queryDocs = [
        _FakeDocument('prod_1', {
          Fields.productId: 'prod_1',
          Fields.quantity: 0,
          Fields.createdAt: DateTime.now().toIso8601String(),
        }),
      ];

      final stream = repository.watchCart('user_1');
      final items = await stream.first;

      expect(items, isEmpty);
    });
  });
}
