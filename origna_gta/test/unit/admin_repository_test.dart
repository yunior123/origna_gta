import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

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
])
import 'admin_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late FirebaseAdminRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    
    repository = FirebaseAdminRepository(mockFirestore, mockFunctions);
    
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
  });

  group('FirebaseAdminRepository Unit Tests', () {
    test('approveProduct calls correct cloud function', () async {
      await repository.approveProduct('prod_123');
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.adminApproveProduct)).called(1);
      verify(mockCallable.call({Fields.productId: 'prod_123'})).called(1);
    });

    test('deleteProduct calls correct cloud function', () async {
      await repository.deleteProduct('prod_123');
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.deleteProduct)).called(1);
      verify(mockCallable.call({Fields.productId: 'prod_123'})).called(1);
    });

    test('fetchUserById returns user if exists', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();
      
      when(mockFirestore.collection(Collections.users)).thenReturn(mockCollection);
      when(mockCollection.doc('user_123')).thenReturn(mockDoc);
      when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.id).thenReturn('user_123');
      when(mockSnapshot.data()).thenReturn({
        Fields.email: 'test@example.com',
        Fields.name: 'Test User',
        Fields.roles: ['buyer'],
        Fields.createdAt: Timestamp.now(),
      });
      
      final user = await repository.fetchUserById('user_123');
      
      expect(user, isNotNull);
      expect(user!.uid, 'user_123');
      expect(user.email, 'test@example.com');
    });

    test('fetchUserById returns null if not exists', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();
      
      when(mockFirestore.collection(Collections.users)).thenReturn(mockCollection);
      when(mockCollection.doc('non_existent')).thenReturn(mockDoc);
      when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(false);
      
      final user = await repository.fetchUserById('non_existent');
      
      expect(user, isNull);
    });

    test('setUserSuspended calls suspend cloud function', () async {
      await repository.setUserSuspended('user_123', true);
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.suspendSeller)).called(1);
      verify(mockCallable.call({Fields.sellerId: 'user_123', ApiKeys.reason: 'Suspended by admin'})).called(1);
    });

    test('setUserSuspended calls unsuspend cloud function', () async {
      await repository.setUserSuspended('user_123', false);
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.unsuspendSeller)).called(1);
      verify(mockCallable.call({Fields.sellerId: 'user_123', ApiKeys.reason: 'Unsuspended by admin'})).called(1);
    });

    test('updateUserRoles calls correct cloud function', () async {
      await repository.updateUserRoles('user_123', add: ['admin'], reason: 'Promotion');
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.updateUserRoles)).called(1);
      verify(mockCallable.call({
        Fields.targetUserId: 'user_123',
        ApiKeys.add: ['admin'],
        ApiKeys.remove: [],
        ApiKeys.reason: 'Promotion',
      })).called(1);
    });

    test('watchOrders returns correct stream', () async {
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      final mockLimitQuery = MockQuery();
      final mockSnapshots = MockQuerySnapshot();
      
      when(mockFirestore.collection(Collections.orders)).thenReturn(mockCollection);
      when(mockCollection.orderBy(any, descending: anyNamed('descending'))).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockLimitQuery);
      when(mockLimitQuery.snapshots()).thenAnswer((_) => Stream.value(mockSnapshots));
      when(mockSnapshots.docs).thenReturn([]);
      
      final stream = repository.watchOrders();
      expect(stream, isA<Stream<List<dynamic>>>());
      
      await for (final list in stream) {
        expect(list, isEmpty);
        break;
      }
    });
  });
}
