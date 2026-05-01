import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:orignabase/orignabase.dart';

import 'notification_repository_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<SubcollectionRef>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
  MockSpec<Document>(),
  MockSpec<WriteBatch>(),
  MockSpec<OrignaBaseAuth>(),
])
void main() {
  late MockOrignaBase mockOrignaBase;
  late MockOrignaBaseAuth mockAuth;
  late MockCollectionRef mockCollection;
  late MockDocumentRef mockUserDoc;
  late MockSubcollectionRef mockNotifications;
  late MockDocumentRef mockNotificationDoc;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshot;
  late MockWriteBatch mockBatch;
  late NotificationRepository repository;

  const userId = 'user_123';

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();
    mockCollection = MockCollectionRef();
    mockUserDoc = MockDocumentRef();
    mockNotifications = MockSubcollectionRef();
    mockNotificationDoc = MockDocumentRef();
    mockQuery = MockQuery();
    mockSnapshot = MockQuerySnapshot();
    mockBatch = MockWriteBatch();

    when(
      mockOrignaBase.collection(Collections.users),
    ).thenReturn(mockCollection);
    when(mockOrignaBase.url).thenReturn('http://127.0.0.1:9');
    when(mockOrignaBase.auth).thenReturn(mockAuth);
    when(mockAuth.accessToken).thenReturn(null);
    when(mockCollection.doc(userId)).thenReturn(mockUserDoc);
    when(
      mockUserDoc.subcollection(Collections.notifications),
    ).thenReturn(mockNotifications);
    when(mockNotifications.doc('n1')).thenReturn(mockNotificationDoc);
    when(
      mockNotifications.where(Fields.isRead, isEqualTo: false),
    ).thenReturn(mockQuery);
    when(
      mockNotifications.where('isRead', isEqualTo: false),
    ).thenReturn(mockQuery);
    when(
      mockNotifications.orderBy(Fields.createdAt, descending: true),
    ).thenReturn(mockQuery);
    when(mockQuery.limit(50)).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
    when(mockOrignaBase.batch()).thenReturn(mockBatch);

    repository = NotificationRepository(mockOrignaBase, enableRealtime: false);
  });

  group('NotificationRepository', () {
    test('markRead updates a single notification', () async {
      when(
        mockNotificationDoc.update({Fields.isRead: true, 'isRead': true}),
      ).thenAnswer((_) async => null);

      await repository.markRead(userId, 'n1');

      verify(
        mockNotificationDoc.update({Fields.isRead: true, 'isRead': true}),
      ).called(1);
    });

    test('markAllRead updates all unread notifications', () async {
      final doc1 = MockDocument();
      final doc2 = MockDocument();
      when(doc1.id).thenReturn('n1');
      when(doc1.data).thenReturn({Fields.isRead: false});
      when(doc2.id).thenReturn('n2');
      when(doc2.data).thenReturn({Fields.isRead: false});
      when(mockSnapshot.isEmpty).thenReturn(false);
      when(mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(
        mockBatch.commit(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await repository.markAllRead(userId);

      verify(
        mockBatch.update(
          '${Collections.users}__${Collections.notifications}',
          'n1',
          {Fields.isRead: true, 'isRead': true},
        ),
      ).called(1);
      verify(
        mockBatch.update(
          '${Collections.users}__${Collections.notifications}',
          'n2',
          {Fields.isRead: true, 'isRead': true},
        ),
      ).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test(
      'markAllRead skips batch commit when there are no unread notifications',
      () async {
        when(mockSnapshot.isEmpty).thenReturn(true);

        await repository.markAllRead(userId);

        verifyNever(mockOrignaBase.batch());
      },
    );

    test(
      'watchNotifications emits ordered notifications with stable ids',
      () async {
        final firstDoc = MockDocument();
        final secondDoc = MockDocument();
        when(firstDoc.id).thenReturn('n2');
        when(firstDoc.data).thenReturn({
          'message': 'Newest',
          Fields.createdAt: '2026-03-10T10:00:00.000',
        });
        when(secondDoc.id).thenReturn('n1');
        when(secondDoc.data).thenReturn({
          'message': 'Older',
          Fields.createdAt: '2026-03-09T10:00:00.000',
        });
        when(mockSnapshot.docs).thenReturn([firstDoc, secondDoc]);
        final notifications = await repository
            .watchNotifications(userId)
            .first
            .timeout(const Duration(seconds: 2));

        expect(notifications.length, 2);
        expect(notifications.first['id'], 'n2');
        expect(notifications.first['message'], 'Newest');
        expect(notifications.last['id'], 'n1');

        verify(
          mockNotifications.orderBy(Fields.createdAt, descending: true),
        ).called(1);
        verify(mockQuery.limit(50)).called(1);
      },
    );
  });
}
