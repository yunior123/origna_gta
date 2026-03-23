import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

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
  final bool exists = true;

  _FakeDocument(this.id, this.data);

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
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeHttpClient extends Fake implements http.Client {
  http.Response? responseValue;
  Exception? throwException;

  @override
  Future<http.Response> put(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
  }) async {
    if (throwException != null) throw throwException!;
    return responseValue ?? http.Response('OK', 200);
  }
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef productsCollection = _FakeCollectionRef();
  final _FakeCollectionRef favoritesCollection = _FakeCollectionRef();
  final _FakeCollectionRef productQuestionsCollection = _FakeCollectionRef();

  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {'success': true};

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.products) return productsCollection;
    if (name == Collections.favorites) return favoritesCollection;
    if (name == Collections.productQuestions) return productQuestionsCollection;
    return _FakeCollectionRef();
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late _FakeHttpClient fakeHttp;
  late OrignaBaseProductRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeHttp = _FakeHttpClient();
    fakeOb.authValue.currentUserIdValue = 'seller_123';
    repository = OrignaBaseProductRepository(fakeOb, httpClient: fakeHttp);
  });

  group('OrignaBaseProductRepository - constructor', () {
    test('creates repository with OrignaBase', () {
      final repo = OrignaBaseProductRepository(fakeOb);
      expect(repo, isA<OrignaBaseProductRepository>());
    });

    test('creates repository with custom http client', () {
      final customClient = http.Client();
      final repo = OrignaBaseProductRepository(
        fakeOb,
        httpClient: customClient,
      );
      expect(repo, isA<OrignaBaseProductRepository>());
    });
  });

  group('OrignaBaseProductRepository - generateProductId', () {
    test('generates unique IDs', () {
      final id1 = repository.generateProductId();
      final id2 = repository.generateProductId();
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('generates alphanumeric IDs', () {
      final id = repository.generateProductId();
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(id), true);
    });
  });

  group('OrignaBaseProductRepository - createProductAtomic', () {
    test('creates product and returns ID', () async {
      fakeOb.requestResponse = {Fields.productId: 'prod_123'};
      final product = Product(
        productId: '',
        name: 'Test Product',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      final id = await repository.createProductAtomic(product, []);

      expect(id, 'prod_123');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsCreateAtomic);
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      final product = Product(
        productId: '',
        name: 'Test',
        description: '',
        priceCents: 1000,
        sellerId: '',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      expect(
        () => repository.createProductAtomic(product, []),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when productId missing in response', () {
      fakeOb.requestResponse = {};

      final product = Product(
        productId: '',
        name: 'Test',
        description: '',
        priceCents: 1000,
        sellerId: '',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      expect(
        () => repository.createProductAtomic(product, []),
        throwsA(isA<Exception>()),
      );
    });

    test('creates product with test image URLs', () async {
      fakeOb.requestResponse = {Fields.productId: 'prod_123'};
      final product = Product(
        productId: '',
        name: 'Test',
        description: '',
        priceCents: 1000,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      await repository.createProductAtomic(
        product,
        [],
        testImageUrls: ['https://example.com/image.jpg'],
      );

      expect(
        fakeOb.lastRequestBody?['testImageUrls'],
        contains('https://example.com/image.jpg'),
      );
    });
  });

  group('OrignaBaseProductRepository - deleteProduct', () {
    test('deletes product when authenticated', () async {
      await repository.deleteProduct('prod_123');

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsDelete);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_123');
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.deleteProduct('prod_123'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when userId is empty', () {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repository.deleteProduct('prod_123'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - updateProduct', () {
    test('updates product data', () async {
      await repository.updateProduct('prod_123', {'name': 'Updated Name'});

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsUpdate);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_123');
      expect(
        fakeOb.lastRequestBody?['productData'],
        isA<Map<String, dynamic>>(),
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.updateProduct('prod_123', {}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - submitRating', () {
    test('submits rating with review text', () async {
      await repository.submitRating(
        'order_1',
        'prod_1',
        5,
        reviewText: 'Great product!',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsSubmitRating);
      expect(fakeOb.lastRequestBody?[Fields.rating], 5);
      expect(fakeOb.lastRequestBody?[Fields.reviewText], 'Great product!');
    });

    test('submits rating with review images', () async {
      await repository.submitRating(
        'order_1',
        'prod_1',
        4,
        reviewImageUrls: ['https://example.com/img.jpg'],
      );

      expect(
        fakeOb.lastRequestBody?[Fields.reviewImageUrls],
        contains('https://example.com/img.jpg'),
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.submitRating('order_1', 'prod_1', 5),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - toggleFavorite', () {
    test('toggles favorite for user', () async {
      await repository.toggleFavorite('user_123', 'prod_123');

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsToggleFavorite);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'user_123');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_123');
    });
  });

  group('OrignaBaseProductRepository - getAutocompleteSuggestions', () {
    test('returns empty list on error', () async {
      fakeOb.requestResponse = {};

      final results = await repository.getAutocompleteSuggestions('test');

      expect(results, isEmpty);
    });

    test('returns features from response', () async {
      fakeOb.requestResponse = {
        'features': [
          {'place_name': 'Toronto, ON'},
        ],
      };

      final results = await repository.getAutocompleteSuggestions('Tor');

      expect(results.length, 1);
      expect(results[0]['place_name'], 'Toronto, ON');
    });

    test('handles non-list features gracefully', () async {
      fakeOb.requestResponse = {'features': 'not a list'};

      final results = await repository.getAutocompleteSuggestions('test');

      expect(results, isEmpty);
    });
  });

  group('OrignaBaseProductRepository - watchUnansweredQuestionsCount', () {
    test('returns stream of counts', () {
      final stream = repository.watchUnansweredQuestionsCount('seller_123');
      expect(stream, isA<Stream<int>>());
    });
  });

  group('OrignaBaseProductRepository - docToProduct', () {
    test('handles missing fields with defaults', () {
      final doc = _FakeDocument('prod_123', {});

      final product = repository.docToProduct(doc);

      expect(product.productId, 'prod_123');
      expect(product.name, 'Untitled product');
      expect(product.description, '');
      expect(product.imageUrls, isEmpty);
    });

    test('strips collection prefix from ID', () {
      final doc = _FakeDocument('products:prod_456', {});

      final product = repository.docToProduct(doc);

      expect(product.productId, 'prod_456');
    });

    test('uses title as name fallback', () {
      final doc = _FakeDocument('prod_123', {'title': 'From Title'});

      final product = repository.docToProduct(doc);

      expect(product.name, 'From Title');
    });

    test('normalizes nanosecond timestamps', () {
      final doc = _FakeDocument('prod_123', {
        'createdAt': '2026-03-12T11:56:03.185238962+00:00',
      });

      final product = repository.docToProduct(doc);

      expect(product.createdAt, isA<DateTime>());
    });

    test('handles DateTime objects', () {
      final now = DateTime.now();
      final doc = _FakeDocument('prod_123', {'createdAt': now});

      final product = repository.docToProduct(doc);

      expect(product.createdAt, isA<DateTime>());
    });
  });

  group('OrignaBaseProductRepository - getUploadUrl', () {
    test('returns upload URL from info', () async {
      fakeOb.requestResponse = {
        'urls': [
          {
            'upload_url': 'https://upload.example.com/abc',
            'path': 'products/img.jpg',
          },
        ],
      };

      final url = await repository.getUploadUrl('img.jpg');

      expect(url, isNotNull);
      expect(url, contains('upload.example.com'));
    });

    test('returns null when no URLs', () async {
      fakeOb.requestResponse = {'urls': []};

      final url = await repository.getUploadUrl('img.jpg');

      expect(url, isNull);
    });
  });

  group('OrignaBaseProductRepository - uploadProductVideo', () {
    test('uploads video and returns public URL', () async {
      fakeOb.requestResponse = {
        'urls': [
          {
            'upload_url': 'https://upload.example.com/video',
            'path': 'products/videos/test.mp4',
          },
        ],
      };
      fakeHttp.responseValue = http.Response('OK', 200);

      final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final xFile = _FakeXFile('test.mp4', bytes);

      final result = await repository.uploadProductVideo(xFile, 'seller_123');

      expect(result, contains('products/videos'));
    });
  });
}

class _FakeXFile extends Fake implements XFile {
  @override
  final String name;

  final Uint8List _bytes;

  _FakeXFile(this.name, this._bytes);

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}
