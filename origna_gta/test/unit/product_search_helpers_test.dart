import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/product_search_helpers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
  MockSpec<Document>(),
  MockSpec<DocumentRef>(),
])
import 'product_search_helpers_test.mocks.dart';

class _TestSearch with ProductSearchHelpers {
  @override
  final OrignaBase ob;

  final Product Function(Document doc) _converter;

  _TestSearch({
    required this.ob,
    required Product Function(Document doc) converter,
  }) : _converter = converter;

  @override
  Product docToProduct(Document doc) => _converter(doc);
}

void main() {
  late MockOrignaBase mockOb;
  late MockCollectionRef mockCollection;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshot;

  setUp(() {
    mockOb = MockOrignaBase();
    mockCollection = MockCollectionRef();
    mockQuery = MockQuery();
    mockSnapshot = MockQuerySnapshot();

    when(mockOb.collection(Collections.products)).thenReturn(mockCollection);
    when(
      mockCollection.where(
        Fields.lifecycleStatus,
        isEqualTo: ProductLifecycleStatusValues.active,
      ),
    ).thenReturn(mockQuery);
  });

  Product makeProduct(Document doc) => Product(
    productId: doc.id,
    name: 'Product ${doc.id}',
    description: 'Desc',
    priceCents: 1000,
    sellerId: 's1',
    categoryId: 1,
    imageUrls: const [],
    stockQuantity: 5,
    createdAt: DateTime.now(),
  );

  Document makeDoc(String id) {
    final doc = MockDocument();
    when(doc.id).thenReturn(id);
    when(doc.exists).thenReturn(true);
    when(doc.data).thenReturn({
      Fields.productId: id,
      Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
    });
    return doc;
  }

  void stubBatchFetch(Map<String, Document?> docsById) {
    when(
      mockCollection.where(Fields.productId, whereIn: anyNamed('whereIn')),
    ).thenAnswer((invocation) {
      final ids = List<String>.from(
        invocation.namedArguments[#whereIn] as List<dynamic>,
      );
      final batchQuery = MockQuery();
      final batchSnapshot = MockQuerySnapshot();
      when(batchQuery.get()).thenAnswer((_) async => batchSnapshot);
      when(batchSnapshot.docs).thenReturn(
        ids.map((id) => docsById[id]).whereType<Document>().toList(),
      );
      return batchQuery;
    });
  }

  group('ProductSearchHelpers.fetchProductsImpl', () {
    test('returns products from snapshot', () async {
      final doc = makeDoc('p1');
      when(mockSnapshot.docs).thenReturn([doc]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl(pageSize: 20);

      expect(result.products.length, 1);
      expect(result.products.first.productId, 'p1');
      expect(result.hasMore, isFalse);
      expect(result.lastDocumentId, 'p1');
    });

    test('detects hasMore when docs exceed pageSize', () async {
      final docs = List.generate(3, (i) => makeDoc('p$i'));
      when(mockSnapshot.docs).thenReturn(docs);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl(pageSize: 2);

      expect(result.products.length, 2);
      expect(result.hasMore, isTrue);
    });

    test('applies search query filter', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(Fields.keywords, contains: anyNamed('contains')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(searchQuery: 'test query');

      verify(mockQuery.where(Fields.keywords, contains: 'test')).called(1);
      verify(mockQuery.where(Fields.keywords, contains: 'query')).called(1);
    });

    test('applies categoryId filter', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(Fields.categoryId, isEqualTo: 5),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(categoryId: 5);

      verify(mockQuery.where(Fields.categoryId, isEqualTo: 5)).called(1);
    });

    test('applies price range filters', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(
          Fields.priceCents,
          isGreaterThan: anyNamed('isGreaterThan'),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(Fields.priceCents, isLessThan: anyNamed('isLessThan')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(minPriceCents: 1000, maxPriceCents: 5000);

      verify(mockQuery.where(Fields.priceCents, isGreaterThan: 999)).called(1);
      verify(mockQuery.where(Fields.priceCents, isLessThan: 5001)).called(1);
    });

    test('skips malformed documents', () async {
      final goodDoc = makeDoc('p1');
      final badDoc = makeDoc('bad');

      when(mockSnapshot.docs).thenReturn([goodDoc, badDoc]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(
        ob: mockOb,
        converter: (doc) {
          if (doc.id == 'bad') throw Exception('malformed');
          return makeProduct(doc);
        },
      );
      final result = await helper.fetchProductsImpl(pageSize: 20);

      expect(result.products.length, 1);
      expect(result.products.first.productId, 'p1');
    });
  });

  group('ProductSearchHelpers.fetchProductsByIdsImpl', () {
    test('returns empty list for empty input', () async {
      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl([]);
      expect(result, isEmpty);
    });

    test('fetches products by ID', () async {
      final doc = makeDoc('p1');
      stubBatchFetch({'p1': doc});

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl(['p1']);

      expect(result.length, 1);
      expect(result.first.productId, 'p1');
      verify(
        mockCollection.where(Fields.productId, whereIn: ['p1']),
      ).called(1);
    });

    test('skips non-existent documents', () async {
      final mockDocRef = MockDocumentRef();
      final doc = MockDocument();
      when(doc.exists).thenReturn(false);
      when(doc.id).thenReturn('p_missing');

      stubBatchFetch({});
      when(mockCollection.doc('p_missing')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => doc);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl(['p_missing']);

      expect(result, isEmpty);
    });
  });

  group('ProductSearchHelpers.getProductBySlugImpl', () {
    test('returns null when no product found', () async {
      final mockSlugQuery = MockQuery();
      when(
        mockCollection.where(Fields.slug, isEqualTo: 'test-slug'),
      ).thenReturn(mockSlugQuery);
      when(
        mockSlugQuery.where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        ),
      ).thenReturn(mockSlugQuery);
      when(mockSlugQuery.limit(1)).thenReturn(mockSlugQuery);
      when(mockSlugQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.getProductBySlugImpl('test-slug');

      expect(result, isNull);
    });

    test('returns product when found by slug', () async {
      final mockSlugQuery = MockQuery();
      final doc = makeDoc('p1');

      when(
        mockCollection.where(Fields.slug, isEqualTo: 'test-slug'),
      ).thenReturn(mockSlugQuery);
      when(
        mockSlugQuery.where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        ),
      ).thenReturn(mockSlugQuery);
      when(mockSlugQuery.limit(1)).thenReturn(mockSlugQuery);
      when(mockSlugQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([doc]);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.getProductBySlugImpl('test-slug');

      expect(result, isNotNull);
      expect(result!.productId, 'p1');
    });
  });

  group('ProductSearchHelpers.fetchProductByIdImpl', () {
    test('returns null when document does not exist', () async {
      final mockDocRef = MockDocumentRef();
      when(mockCollection.doc('p1')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => null);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('p1');

      expect(result, isNull);
    });

    test('returns null when document exists but is not active', () async {
      final mockDocRef = MockDocumentRef();
      final doc = MockDocument();
      when(doc.exists).thenReturn(true);
      when(doc.data).thenReturn({Fields.lifecycleStatus: 'draft'});

      when(mockCollection.doc('p1')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => doc);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('p1');

      expect(result, isNull);
    });

    test('returns product when document exists and is active', () async {
      final mockDocRef = MockDocumentRef();
      final doc = makeDoc('p1');

      when(mockCollection.doc('p1')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => doc);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('p1');

      expect(result, isNotNull);
      expect(result!.productId, 'p1');
    });
  });

  group('ProductSearchHelpers.fetchProductsImpl edge cases', () {
    test('handles empty search query', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl(searchQuery: '');

      expect(result.products, isEmpty);
    });

    test('handles whitespace-only search query', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl(searchQuery: '   ');

      expect(result.products, isEmpty);
    });

    test('handles subcategory filter', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(
        mockQuery.where(Fields.subcategory, isEqualTo: 'electronics'),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(subcategory: 'electronics');

      verify(
        mockQuery.where(Fields.subcategory, isEqualTo: 'electronics'),
      ).called(1);
    });

    test('handles lastDocumentId for pagination', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(mockQuery.startAfterId('last-doc-id')).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(lastDocumentId: 'last-doc-id');

      verify(mockQuery.startAfterId('last-doc-id')).called(1);
    });

    test('applies SortOption.priceLowToHigh correctly', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(mockQuery.orderBy(Fields.priceCents)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(Fields.createdAt, descending: true),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(sortOption: SortOption.priceLowToHigh);

      verify(mockQuery.orderBy(Fields.priceCents)).called(1);
      verify(mockQuery.orderBy(Fields.createdAt, descending: true)).called(1);
    });

    test('applies SortOption.priceHighToLow correctly', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(Fields.priceCents, descending: true),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(Fields.createdAt, descending: true),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(sortOption: SortOption.priceHighToLow);

      verify(mockQuery.orderBy(Fields.priceCents, descending: true)).called(1);
      verify(mockQuery.orderBy(Fields.createdAt, descending: true)).called(1);
    });

    test('applies SortOption.newest correctly', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(Fields.createdAt, descending: true),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      await helper.fetchProductsImpl(sortOption: SortOption.newest);

      verify(mockQuery.orderBy(Fields.createdAt, descending: true)).called(1);
    });

    test('returns correct lastDocumentId when hasMore', () async {
      final docs = List.generate(3, (i) => makeDoc('p$i'));
      when(mockSnapshot.docs).thenReturn(docs);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl(pageSize: 2);

      expect(result.hasMore, isTrue);
      expect(result.lastDocumentId, 'p1');
    });

    test('returns null lastDocumentId when no products', () async {
      when(mockSnapshot.docs).thenReturn([]);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsImpl();

      expect(result.lastDocumentId, isNull);
    });
  });

  group('ProductSearchHelpers.fetchProductsByIdsImpl edge cases', () {
    test('handles chunking for more than 30 IDs', () async {
      final ids = List.generate(65, (i) => 'p$i');
      final docsById = {for (final id in ids) id: makeDoc(id)};
      stubBatchFetch(docsById);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl(ids);

      verify(
        mockCollection.where(Fields.productId, whereIn: anyNamed('whereIn')),
      ).called(3);
      expect(result.length, 65);
    });

    test('handles malformed documents gracefully', () async {
      final doc = MockDocument();

      when(doc.exists).thenReturn(true);
      when(doc.id).thenReturn('malformed');
      when(doc.data).thenReturn({});
      stubBatchFetch({'malformed': doc});

      final helper = _TestSearch(
        ob: mockOb,
        converter: (doc) {
          if (doc.id == 'malformed') throw Exception('parse error');
          return makeProduct(doc);
        },
      );
      final result = await helper.fetchProductsByIdsImpl(['malformed']);

      expect(result, isEmpty);
    });

    test('handles null document return', () async {
      final mockDocRef = MockDocumentRef();

      stubBatchFetch({});
      when(mockCollection.doc('null-doc')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => null);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl(['null-doc']);

      expect(result, isEmpty);
    });

    test('handles exactly 30 IDs (boundary)', () async {
      final ids = List.generate(30, (i) => 'p$i');
      final docsById = {for (final id in ids) id: makeDoc(id)};
      stubBatchFetch(docsById);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductsByIdsImpl(ids);

      verify(
        mockCollection.where(Fields.productId, whereIn: anyNamed('whereIn')),
      ).called(1);
      expect(result.length, 30);
    });
  });

  group('ProductSearchHelpers.getProductBySlugImpl edge cases', () {
    test('handles empty slug', () async {
      final mockSlugQuery = MockQuery();
      when(
        mockCollection.where(Fields.slug, isEqualTo: ''),
      ).thenReturn(mockSlugQuery);
      when(
        mockSlugQuery.where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        ),
      ).thenReturn(mockSlugQuery);
      when(mockSlugQuery.limit(1)).thenReturn(mockSlugQuery);
      when(mockSlugQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.getProductBySlugImpl('');

      expect(result, isNull);
    });

    test('handles slug with special characters', () async {
      const slug = 'test-product_123!';
      final mockSlugQuery = MockQuery();
      when(
        mockCollection.where(Fields.slug, isEqualTo: slug),
      ).thenReturn(mockSlugQuery);
      when(
        mockSlugQuery.where(
          Fields.lifecycleStatus,
          isEqualTo: ProductLifecycleStatusValues.active,
        ),
      ).thenReturn(mockSlugQuery);
      when(mockSlugQuery.limit(1)).thenReturn(mockSlugQuery);
      when(mockSlugQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.getProductBySlugImpl(slug);

      verify(mockCollection.where(Fields.slug, isEqualTo: slug)).called(1);
      expect(result, isNull);
    });
  });

  group('ProductSearchHelpers.fetchProductByIdImpl edge cases', () {
    test('handles null document return', () async {
      final mockDocRef = MockDocumentRef();
      when(mockCollection.doc('nonexistent')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => null);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('nonexistent');

      expect(result, isNull);
    });

    test('handles document with null data', () async {
      final mockDocRef = MockDocumentRef();
      final doc = MockDocument();

      when(doc.exists).thenReturn(true);
      when(doc.id).thenReturn('null-data');
      when(doc.data).thenReturn({});
      when(mockCollection.doc('null-data')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => doc);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('null-data');

      expect(result, isNull);
    });

    test('handles document with inactive lifecycle status', () async {
      final mockDocRef = MockDocumentRef();
      final doc = MockDocument();

      when(doc.exists).thenReturn(true);
      when(doc.id).thenReturn('inactive');
      when(doc.data).thenReturn({
        Fields.lifecycleStatus: ProductLifecycleStatusValues.draft,
      });
      when(mockCollection.doc('inactive')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => doc);

      final helper = _TestSearch(ob: mockOb, converter: makeProduct);
      final result = await helper.fetchProductByIdImpl('inactive');

      expect(result, isNull);
    });
  });
}
