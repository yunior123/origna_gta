import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

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
import 'order_repository_test.mocks.dart';

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
  late FirebaseOrderRepository repository;

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
    
    repository = FirebaseOrderRepository(mockFirestore, mockFunctions);
    
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

  group('FirebaseOrderRepository Unit Tests', () {
    test('approveShippingCost calls correct cloud function', () async {
      await repository.approveShippingCost('order_123', true);
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.approveShippingCost)).called(1);
      verify(mockCallable.call({Fields.orderId: 'order_123', ApiKeys.approved: true})).called(1);
    });

    test('capturePayment calls correct cloud function', () async {
      await repository.capturePayment('order_123');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.capturePayment)).called(1);
      verify(mockCallable.call({Fields.orderId: 'order_123'})).called(1);
    });

    test('confirmReceipt calls confirmItemReceipt when productId provided', () async {
      await repository.confirmReceipt('order_123', productId: 'prod_456');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.confirmItemReceipt)).called(1);
      verify(mockCallable.call({Fields.orderId: 'order_123', Fields.productId: 'prod_456'})).called(1);
    });

    test('updateItemStatus sends correct payload', () async {
      await repository.updateItemStatus('order_123', 'prod_456', 'shipped', trackingNumber: 'TRK123', carrier: 'Canada Post');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.updateItemStatus)).called(1);
      verify(mockCallable.call(argThat(containsPair(Fields.trackingNumber, 'TRK123')))).called(1);
    });

    test('updateLastSession updates firestore', () async {
      when(mockCollection.doc('user_123')).thenReturn(mockDoc);
      await repository.updateLastSession('user_123', 'sess_456', 'order_789');
      // Use any for the whole map because FieldValue is hard to match exactly
      verify(mockDoc.update(any)).called(1);
    });

    test('watchPaidOrderBySession returns correct stream', () async {
      when(mockQuerySnapshot.docs).thenReturn([]);
      final stream = repository.watchPaidOrderBySession('sess_123');
      final result = await stream.first;
      expect(result, isNull);
      verify(mockCollection.where(any, isEqualTo: 'sess_123')).called(1);
    });
  });
}
