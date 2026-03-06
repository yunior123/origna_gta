import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<WriteBatch>(),
])
import 'notification_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshots;
  late NotificationRepository repository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockQuery = MockQuery();
    mockSnapshots = MockQuerySnapshot();
    
    repository = NotificationRepository(mockFirestore);
    
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.collection(any)).thenReturn(mockCollection);
    when(mockCollection.where(any, isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockSnapshots);
  });

  group('NotificationRepository Unit Tests', () {
    test('markRead updates Firestore document', () async {
      await repository.markRead('user_123', 'notif_456');
      
      verify(mockFirestore.collection(Collections.users)).called(1);
      verify(mockCollection.doc('user_123')).called(1);
      verify(mockDoc.collection(Collections.notifications)).called(1);
      verify(mockCollection.doc('notif_456')).called(1);
      verify(mockDoc.update({Fields.isRead: true})).called(1);
    });

    test('markAllRead commits batch update', () async {
      final mockBatch = MockWriteBatch();
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockRef1 = MockDocumentReference();
      
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockSnapshots.docs).thenReturn([mockDoc1]);
      when(mockDoc1.reference).thenReturn(mockRef1);
      
      await repository.markAllRead('user_123');
      
      verify(mockBatch.update(mockRef1, {Fields.isRead: true})).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
