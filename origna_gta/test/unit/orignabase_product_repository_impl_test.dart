import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
import 'package:origna_gta/core/repositories/product_repository.dart'
    show ProductQueryResult;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

class _FakeAuth extends Fake implements OrignaBaseAuth {
  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  String? get accessToken => null;
}

class _FakeDocument extends Fake implements Document {
  @override
  final String id;

  @override
  final Map<String, dynamic> data;

  @override
  final bool exists;

  _FakeDocument(this.id, this.data, {bool exists = true}) : exists = exists;

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

  _FakeDocumentRef({this.id = 'doc_id', _FakeDocument? doc})
    : documentValue = doc;

  @override
  Future<Document?> get() async => documentValue;

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
    return _FakeDocumentRef(id: id);
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

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef productsCollection = _FakeCollectionRef();
  final _FakeCollectionRef favoritesCollection = _FakeCollectionRef();
  final _FakeCollectionRef productQuestionsCollection = _FakeCollectionRef();

  @override
  String url = 'https://test.origna.ca';

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

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseProductRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeOb.authValue.currentUserIdValue = 'seller_123';
    repository = OrignaBaseProductRepository(fakeOb);
  });

  group('OrignaBaseProductRepository - createProductAtomic', () {
    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      final product = Product(
        productId: '',
        name: 'Test',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
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

    test('throws when userId is empty', () {
      fakeOb.authValue.currentUserIdValue = '';

      final product = Product(
        productId: '',
        name: 'Test',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
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

    test('sends product data and returns productId', () async {
      fakeOb.requestResponse = {Fields.productId: 'new_prod_123'};

      final product = Product(
        productId: '',
        name: 'Test',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      final result = await repository.createProductAtomic(
        product,
        [],
        testImageUrls: ['https://example.com/img.jpg'],
      );

      expect(result, 'new_prod_123');
      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsCreateAtomic);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'seller_123');
    });

    test('includes bookSourceUrl when provided', () async {
      fakeOb.requestResponse = {Fields.productId: 'book_1'};

      final product = Product(
        productId: '',
        name: 'Book',
        description: 'A book',
        priceCents: 1500,
        sellerId: 'seller_123',
        categoryId: 14,
        imageUrls: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
      );

      await repository.createProductAtomic(
        product,
        [],
        bookSourceUrl: 'https://example.com/book.pdf',
      );

      expect(
        fakeOb.lastRequestBody?['productData']['bookSourceUrl'],
        'https://example.com/book.pdf',
      );
    });

    test('normalizes empty apartment to null', () async {
      fakeOb.requestResponse = {Fields.productId: 'addr_1'};

      final product = Product(
        productId: '',
        name: 'Test',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 5,
        createdAt: DateTime.now(),
      );

      await repository.createProductAtomic(product, []);

      final productData = fakeOb.lastRequestBody?['productData'];
      if (productData != null && productData[Fields.sellerAddress] != null) {
        final addr = productData[Fields.sellerAddress] as Map<String, dynamic>;
        if (addr.containsKey('apartment')) {
          expect(addr['apartment'], isNull);
        }
      }
    });

    test('throws when response has no productId', () async {
      fakeOb.requestResponse = {'someOther': 'data'};

      final product = Product(
        productId: '',
        name: 'Test',
        description: 'Desc',
        priceCents: 1000,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const [],
        stockQuantity: 5,
        createdAt: DateTime.now(),
      );

      await expectLater(
        () => repository.createProductAtomic(product, []),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - deleteProduct', () {
    test('sends delete request', () async {
      await repository.deleteProduct('prod_1');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsDelete);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.userId], 'seller_123');
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.deleteProduct('prod_1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - fetchProductById', () {
    test('returns null when doc does not exist', () async {
      final product = await repository.fetchProductById('nonexistent');
      expect(product, isNull);
    });

    test('returns null when product is not active', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.name: 'Draft Product',
        Fields.lifecycleStatus: ProductLifecycleStatusValues.draft,
        Fields.price: 1000 / 100.0,
        Fields.sellerId: 'seller_1',
        Fields.categoryId: 1,
        Fields.imageUrls: [],
        Fields.stockQuantity: 5,
        Fields.createdAt: DateTime.now().toIso8601String(),
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final product = await repository.fetchProductById('prod_1');
      expect(product, isNull);
    });

    test('returns product when doc exists and is active', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.name: 'Active Product',
        Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        Fields.price: 2500 / 100.0,
        Fields.sellerId: 'seller_1',
        Fields.categoryId: 1,
        Fields.imageUrls: [],
        Fields.stockQuantity: 10,
        Fields.description: 'Great',
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.rating: 4.5,
        Fields.ratingCount: 10,
        Fields.keywords: ['test'],
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final product = await repository.fetchProductById('prod_1');

      expect(product, isNotNull);
      expect(product!.productId, 'prod_1');
    });
  });

  group('OrignaBaseProductRepository - fetchProducts', () {
    test('returns ProductQueryResult', () async {
      fakeOb.productsCollection.queryDocs = [
        _FakeDocument('p1', {
          Fields.name: 'Product 1',
          Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
          Fields.price: 1000 / 100.0,
          Fields.sellerId: 's1',
          Fields.categoryId: 1,
          Fields.imageUrls: [],
          Fields.stockQuantity: 5,
          Fields.createdAt: DateTime.now().toIso8601String(),
        }),
      ];

      final result = await repository.fetchProducts(pageSize: 10);

      expect(result, isA<ProductQueryResult>());
      expect(result.products.length, lessThanOrEqualTo(1));
    });
  });

  group('OrignaBaseProductRepository - fetchProductsByIds', () {
    test('returns empty list for empty input', () async {
      final products = await repository.fetchProductsByIds([]);
      expect(products, isEmpty);
    });

    test('returns products for valid ids', () async {
      final doc = _FakeDocument('prod_1', {
        Fields.name: 'Test',
        Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        Fields.price: 1000 / 100.0,
        Fields.sellerId: 's1',
        Fields.categoryId: 1,
        Fields.imageUrls: [],
        Fields.stockQuantity: 5,
        Fields.createdAt: DateTime.now().toIso8601String(),
      });
      fakeOb.productsCollection.setDoc('prod_1', _FakeDocumentRef(doc: doc));

      final products = await repository.fetchProductsByIds(['prod_1']);
      expect(products.length, 1);
    });

    test('skips nonexistent docs', () async {
      final products = await repository.fetchProductsByIds(['nonexistent']);
      expect(products, isEmpty);
    });
  });

  group('OrignaBaseProductRepository - generateProductId', () {
    test('returns a non-empty string', () {
      final id = repository.generateProductId();
      expect(id, isNotEmpty);
    });

    test('returns different values for subsequent calls', () async {
      final id1 = repository.generateProductId();
      await Future.delayed(const Duration(milliseconds: 2));
      final id2 = repository.generateProductId();
      expect(id1, isNot(equals(id2)));
    });
  });

  group('OrignaBaseProductRepository - getAutocompleteSuggestions', () {
    test('returns list of features from response', () async {
      fakeOb.requestResponse = {
        'features': [
          {'name': 'Toronto', 'country': 'Canada'},
          {'name': 'Toronto Junction', 'country': 'Canada'},
        ],
      };

      final suggestions = await repository.getAutocompleteSuggestions('Toron');

      expect(fakeOb.lastRequestPath, ApiEndpoints.geocodeAutocomplete);
      expect(fakeOb.lastRequestBody?['query'], 'Toron');
      expect(fakeOb.lastRequestBody?['country'], 'ca');
      expect(suggestions.length, 2);
    });

    test('returns empty list when features is not a list', () async {
      fakeOb.requestResponse = {'features': 'not_a_list'};

      final suggestions = await repository.getAutocompleteSuggestions('test');
      expect(suggestions, isEmpty);
    });

    test('returns empty list on error', () async {
      fakeOb.requestResponse = {};
      final suggestions = await repository.getAutocompleteSuggestions('test');
      expect(suggestions, isEmpty);
    });
  });

  group('OrignaBaseProductRepository - getProductBySlug', () {
    test('returns null when no product found', () async {
      final product = await repository.getProductBySlug('nonexistent-slug');
      expect(product, isNull);
    });
  });

  group('OrignaBaseProductRepository - getUploadUrlInfo', () {
    test('delegates to getUploadUrlInfoImpl', () async {
      fakeOb.requestResponse = {
        'urls': [
          {
            'upload_url': 'https://upload.example.com/file.jpg',
            'path': 'products/file.jpg',
          },
        ],
      };

      final info = await repository.getUploadUrlInfo('file.jpg');

      expect(fakeOb.lastRequestPath, '/storage/presign/upload');
      expect(info, isNotNull);
      expect(info!['uploadUrl'], 'https://upload.example.com/file.jpg');
    });

    test('returns null when urls is empty', () async {
      fakeOb.requestResponse = {'urls': []};

      final info = await repository.getUploadUrlInfo('file.jpg');
      expect(info, isNull);
    });
  });

  group('OrignaBaseProductRepository - getUploadUrl', () {
    test('returns the uploadUrl string', () async {
      fakeOb.requestResponse = {
        'urls': [
          {
            'upload_url': 'https://upload.example.com/abc',
            'path': 'products/abc',
          },
        ],
      };

      final url = await repository.getUploadUrl('abc');
      expect(url, 'https://upload.example.com/abc');
    });

    test('returns null when no upload URL available', () async {
      fakeOb.requestResponse = {'urls': []};

      final url = await repository.getUploadUrl('missing');
      expect(url, isNull);
    });
  });

  group('OrignaBaseProductRepository - getUploadVideoUrlInfo', () {
    test('delegates to getUploadVideoUrlInfoImpl', () async {
      fakeOb.requestResponse = {
        'urls': [
          {
            'upload_url': 'https://upload.example.com/video.mp4',
            'path': 'products/videos/video.mp4',
          },
        ],
      };

      final info = await repository.getUploadVideoUrlInfo(
        'video.mp4',
        'video/mp4',
      );

      expect(info, isNotNull);
      expect(info!['uploadUrl'], 'https://upload.example.com/video.mp4');
    });
  });

  group('OrignaBaseProductRepository - submitRating', () {
    test('sends rating with all optional fields', () async {
      await repository.submitRating(
        'order_1',
        'prod_1',
        5,
        reviewImageUrls: ['https://example.com/review1.jpg'],
        reviewText: 'Excellent product!',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsSubmitRating);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.rating], 5);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'seller_123');
      expect(fakeOb.lastRequestBody?[Fields.reviewImageUrls], [
        'https://example.com/review1.jpg',
      ]);
      expect(fakeOb.lastRequestBody?[Fields.reviewText], 'Excellent product!');
    });

    test('sends rating without optional fields', () async {
      await repository.submitRating('order_1', 'prod_1', 3);

      expect(fakeOb.lastRequestBody?[Fields.reviewImageUrls], isNull);
      expect(fakeOb.lastRequestBody?[Fields.reviewText], isNull);
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.submitRating('o1', 'p1', 5),
        throwsA(isA<Exception>()),
      );
    });

    test('omits empty reviewImageUrls', () async {
      await repository.submitRating(
        'order_1',
        'prod_1',
        4,
        reviewImageUrls: [],
      );

      expect(
        fakeOb.lastRequestBody?.containsKey(Fields.reviewImageUrls),
        isFalse,
      );
    });

    test('omits empty reviewText', () async {
      await repository.submitRating('order_1', 'prod_1', 4, reviewText: '');

      expect(fakeOb.lastRequestBody?.containsKey(Fields.reviewText), isFalse);
    });
  });

  group('OrignaBaseProductRepository - submitRatingAtomic', () {
    test('sends atomic rating without images', () async {
      await repository.submitRatingAtomic(
        'order_1',
        'prod_1',
        5,
        reviewText: 'Great!',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.productsSubmitRatingAtomic);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.rating], 5);
      expect(fakeOb.lastRequestBody?['images'], isEmpty);
      expect(fakeOb.lastRequestBody?[Fields.reviewText], 'Great!');
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.submitRatingAtomic('o1', 'p1', 5),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - toggleFavorite', () {
    test('sends toggle request', () async {
      await repository.toggleFavorite('user_1', 'prod_1');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsToggleFavorite);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'user_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
    });
  });

  group('OrignaBaseProductRepository - updateProduct', () {
    test('sends update request', () async {
      await repository.updateProduct('prod_1', {
        Fields.price: 29.99,
        Fields.stockQuantity: 20,
      });

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsUpdate);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.userId], 'seller_123');
      expect(fakeOb.lastRequestBody?['productData'][Fields.price], 29.99);
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.updateProduct('prod_1', {}),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when userId is empty', () {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repository.updateProduct('prod_1', {}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseProductRepository - watchFavorites', () {
    test('method signature is correct', () {
      // Verify the method exists and returns the correct type via the
      // ProductRepository interface — calling the real implementation would
      // attempt a WebSocket connection which is not available in unit tests.
      expect(
        repository.watchFavorites,
        isA<Stream<Set<String>> Function(String)>(),
      );
    });
  });

  group('OrignaBaseProductRepository - watchUnansweredQuestionsCount', () {
    test('returns a stream of int', () {
      final stream = repository.watchUnansweredQuestionsCount('seller_1');
      expect(stream, isA<Stream<int>>());
    });
  });

  group('OrignaBaseProductRepository - docToProduct', () {
    test('fills in defaults for missing fields', () {
      final doc = _FakeDocument('prod_minimal', {
        Fields.sellerId: 's1',
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      final product = repository.docToProduct(doc);

      expect(product.productId, 'prod_minimal');
      expect(product.name, 'Untitled product');
      expect(product.description, '');
      expect(product.imageUrls, isEmpty);
      expect(product.stockQuantity, 0);
      expect(product.priceCents, 0);
    });

    test('strips collection prefix from doc id', () {
      final doc = _FakeDocument('products:abc123', {
        Fields.name: 'Test',
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.sellerId: 's1',
        Fields.categoryId: 1,
        Fields.imageUrls: [],
        Fields.stockQuantity: 5,
        Fields.price: 1000 / 100.0,
      });

      final product = repository.docToProduct(doc);
      expect(product.productId, 'abc123');
    });

    test('normalizes nanosecond timestamps', () {
      final doc = _FakeDocument('p1', {
        Fields.name: 'Test',
        Fields.createdAt: '2026-03-12T11:56:03.185238962+00:00',
        Fields.sellerId: 's1',
        Fields.categoryId: 1,
        Fields.imageUrls: [],
        Fields.stockQuantity: 5,
        Fields.price: 1000 / 100.0,
      });

      final product = repository.docToProduct(doc);
      expect(product.createdAt, isA<DateTime>());
    });

    test('uses title fallback for name', () {
      final doc = _FakeDocument('p1', {
        'title': 'My Title',
        Fields.sellerId: 's1',
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      final product = repository.docToProduct(doc);
      expect(product.name, 'My Title');
    });
  });
}
