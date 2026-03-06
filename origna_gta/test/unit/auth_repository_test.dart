import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([
  MockSpec<auth.FirebaseAuth>(),
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult>(),
  MockSpec<auth.User>(),
  MockSpec<auth.UserCredential>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;
  late MockUser mockUser;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
    mockUser = MockUser();
    
    repository = FirebaseAuthRepository(mockAuth, mockFirestore, mockFunctions);
    repository.turnstileOverride = () async => 'mock_token';
    
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
    when(mockCallable.call(any)).thenAnswer((_) async => mockResult);
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user_123');
    when(mockUser.providerData).thenReturn([]);
  });

  group('FirebaseAuthRepository Unit Tests', () {
    test('deleteAccount calls backend', () async {
      await repository.deleteAccount();
      verify(mockFunctions.httpsCallable(CloudFunctionEndpoints.deleteAccount)).called(1);
    });

    test('signInWithEmail calls auth and ensures document', () async {
      final mockCredential = MockUserCredential();
      when(mockAuth.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => mockCredential);
      when(mockCredential.user).thenReturn(mockUser);
      
      // Mock Firestore check for existing doc
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();
      when(mockFirestore.collection(Collections.users)).thenReturn(mockCollection);
      when(mockCollection.doc('user_123')).thenReturn(mockDoc);
      when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(true);

      await repository.signInWithEmail('test@example.com', 'password123');
      
      verify(mockAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password123')).called(1);
    });

    test('isEmailVerified reloads user', () async {
      when(mockUser.emailVerified).thenReturn(true);
      final verified = await repository.isEmailVerified();
      expect(verified, isTrue);
      verify(mockUser.reload()).called(1);
    });
  });
}
