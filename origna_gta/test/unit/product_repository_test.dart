import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
])
import 'product_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late FirebaseProductRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    
    repository = FirebaseProductRepository(mockFirestore, mockFunctions);
    
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
    
    // Recursive mock for where()
    final whereMock = (Invocation invocation) => mockQuery;
    when(mockCollection.where(any, 
      isEqualTo: anyNamed('isEqualTo'), 
      isNotEqualTo: anyNamed('isNotEqualTo'),
      isLessThan: anyNamed('isLessThan'),
      isLessThanOrEqualTo: anyNamed('isLessThanOrEqualTo'),
      isGreaterThan: anyNamed('isGreaterThan'),
      isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
      arrayContains: anyNamed('arrayContains'),
      arrayContainsAny: anyNamed('arrayContainsAny'),
      whereIn: anyNamed('whereIn'),
      whereNotIn: anyNamed('whereNotIn'),
      isNull: anyNamed('isNull')
    )).thenAnswer(whereMock);
    
    when(mockQuery.where(any, 
      isEqualTo: anyNamed('isEqualTo'),
      isNotEqualTo: anyNamed('isNotEqualTo'),
      isLessThan: anyNamed('isLessThan'),
      isLessThanOrEqualTo: anyNamed('isLessThanOrEqualTo'),
      isGreaterThan: anyNamed('isGreaterThan'),
      isGreaterThanOrEqualTo: anyNamed('isGreaterThanOrEqualTo'),
      arrayContains: anyNamed('arrayContains'),
      arrayContainsAny: anyNamed('arrayContainsAny'),
      whereIn: anyNamed('whereIn'),
      whereNotIn: anyNamed('whereNotIn'),
      isNull: anyNamed('isNull')
    )).thenAnswer(whereMock);

    when(mockQuery.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
    when(mockQuery.limit(any)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
  });

  final fullProductMap = {
    Fields.productId: 'prod_123',
    Fields.name: 'Test Product',
    Fields.price: 99.99,
    Fields.description: 'Test description',
    Fields.imageUrls: ['https://example.com/img.jpg'],
    Fields.sellerId: 'seller_123',
    Fields.categoryId: 1,
    Fields.stockQuantity: 10,
    Fields.createdAt: Timestamp.now(),
    Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
  };

  group('FirebaseProductRepository Unit Tests', () {
    test('fetchProductById returns product if exists and active', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn(fullProductMap);
      when(mockSnapshot.id).thenReturn('prod_123');
      
      final product = await repository.fetchProductById('prod_123');
      expect(product, isNotNull);
      expect(product!.productId, 'prod_123');
    });

    test('fetchProducts applies filters and sorts', () async {
      when(mockQuerySnapshot.docs).thenReturn([]);
      
      await repository.fetchProducts(
        searchQuery: 'honey',
        categoryId: 1,
        sortOption: SortOption.priceLowToHigh,
        minPriceCents: 1000,
      );
      
      verify(mockCollection.where(Fields.lifecycleStatus, isEqualTo: ProductLifecycleStatusValues.active)).called(1);
      verify(mockQuery.where(Fields.keywords, arrayContains: 'honey')).called(1);
      verify(mockQuery.where(Fields.categoryId, isEqualTo: 1)).called(1);
      verify(mockQuery.where(Fields.priceCents, isGreaterThanOrEqualTo: 1000)).called(1);
      verify(mockQuery.orderBy(Fields.priceCents)).called(1);
    });

    test('watchUnansweredQuestionsCount returns correct count', () async {
      when(mockQuerySnapshot.docs).thenReturn([MockQueryDocumentSnapshot(), MockQueryDocumentSnapshot()]);
      
      final stream = repository.watchUnansweredQuestionsCount('seller_123');
      final count = await stream.first;
      
      expect(count, 2);
      verify(mockFirestore.collection(Collections.productQuestions)).called(1);
      verify(mockCollection.where(Fields.sellerId, isEqualTo: 'seller_123')).called(1);
      verify(mockQuery.where(Fields.isAnswered, isEqualTo: false)).called(1);
    });

    test('getUploadUrlInfo calls correct cloud function', () async {
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
      when(mockResult.data).thenReturn({
        'uploadUrls': [
          {'uploadUrl': 'http://upload', 'publicUrl': 'http://public'}
        ]
      });
      
      final info = await repository.getUploadUrlInfo('file.jpg');
      expect(info!['uploadUrl'], 'http://upload');
      expect(info['publicUrl'], 'http://public');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.uploadProductImages)).called(1);
    });
  });
}
