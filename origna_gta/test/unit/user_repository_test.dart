import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
])
import 'user_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockDocumentSnapshot mockSnapshot;
  late FirebaseUserRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    
    repository = FirebaseUserRepository(mockFirestore, mockFunctions);
    
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
    when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
    when(mockResult.data).thenReturn({'success': true});
    
    // Default Firestore mocks
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.collection(any)).thenReturn(mockCollection);
    when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
  });

  group('FirebaseUserRepository Unit Tests', () {
    test('getUserProfile returns user if exists', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({
        Fields.email: 'test@example.com',
        Fields.name: 'Test User',
        Fields.roles: ['buyer'],
        Fields.createdAt: Timestamp.now(),
      });
      
      final user = await repository.getUserProfile('user_123');
      expect(user, isNotNull);
      expect(user!.email, 'test@example.com');
    });

    test('updatePreferredLanguage calls correct cloud function', () async {
      await repository.updatePreferredLanguage('user_123', 'fr');
      
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.updateUserProfile)).called(1);
      verify(mockCallable.call(argThat(containsPair(Fields.preferredLanguage, 'fr')))).called(1);
    });

    test('watchAddresses returns correct stream', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      when(mockCollection.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([]);
      
      final stream = repository.watchAddresses('user_123');
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('deleteBuyerAddress calls correct cloud function', () async {
      await repository.deleteBuyerAddress('addr_123');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.deleteBuyerAddress)).called(1);
      verify(mockCallable.call({Fields.addressId: 'addr_123'})).called(1);
    });

    test('setDefaultBuyerAddress calls correct cloud function', () async {
      await repository.setDefaultBuyerAddress('addr_123');
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.setDefaultBuyerAddress)).called(1);
      // It uses magic string 'addressId' in the source code
      verify(mockCallable.call({'addressId': 'addr_123'})).called(1);
    });

    test('getSellerAccountStatus handles both user and seller profile', () async {
      final usersCollection = MockCollectionReference();
      final sellerProfilesCollection = MockCollectionReference();
      final userDoc = MockDocumentReference();
      final spDoc = MockDocumentReference();
      final userSnap = MockDocumentSnapshot();
      final spSnap = MockDocumentSnapshot();

      when(mockFirestore.collection(Collections.users)).thenReturn(usersCollection);
      when(usersCollection.doc('user_123')).thenReturn(userDoc);
      when(userDoc.get()).thenAnswer((_) async => userSnap);
      
      when(mockFirestore.collection(Collections.sellerProfiles)).thenReturn(sellerProfilesCollection);
      when(sellerProfilesCollection.doc('user_123')).thenReturn(spDoc);
      when(spDoc.get()).thenAnswer((_) async => spSnap);

      when(userSnap.data()).thenReturn({Fields.roles: ['seller']});
      when(spSnap.data()).thenReturn({Fields.chargesEnabled: true, Fields.payoutsEnabled: true});

      final status = await repository.getSellerAccountStatus('user_123');
      expect(status.isSeller, isTrue);
      expect(status.chargesEnabled, isTrue);
    });
  });
}
