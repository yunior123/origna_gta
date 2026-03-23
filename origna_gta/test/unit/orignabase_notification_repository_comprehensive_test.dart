import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
  MockSpec<Document>(),
  MockSpec<WriteBatch>(),
])
import 'orignabase_notification_repository_comprehensive_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late MockCollectionRef mockCollection;
  late MockDocumentRef mockDocRef;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshot;
  late MockWriteBatch mockBatch;
  late OrignaBaseNotificationRepository repository;

  const uid = 'user_123';

  setUp(() {
    mockOb = MockOrignaBase();
    mockCollection = MockCollectionRef();
    mockDocRef = MockDocumentRef();
    mockQuery = MockQuery();
    mockSnapshot = MockQuerySnapshot();
    mockBatch = MockWriteBatch();

    when(
      mockOb.collection(Collections.notifications),
    ).thenReturn(mockCollection);
    when(
      mockCollection.where(Fields.userId, isEqualTo: uid),
    ).thenReturn(mockQuery);
    when(mockOb.batch()).thenReturn(mockBatch);

    repository = OrignaBaseNotificationRepository(mockOb);
  });

  group('OrignaBaseNotificationRepository - constructor', () {
    test('creates repository with OrignaBase', () {
      final repo = OrignaBaseNotificationRepository(mockOb);
      expect(repo, isA<OrignaBaseNotificationRepository>());
    });
  });

  group('OrignaBaseNotificationRepository - markAllRead', () {
    test('does nothing when no unread notifications', () async {
      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      await repository.markAllRead(uid);

      verifyNever(mockOb.batch());
    });

    test('batch updates all unread notifications', () async {
      final doc1 = MockDocument();
      final doc2 = MockDocument();
      when(doc1.id).thenReturn('notifications:n1');
      when(doc2.id).thenReturn('n2');

      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([doc1, doc2]);
      when(
        mockBatch.update(Collections.notifications, any, any),
      ).thenAnswer((_) {});
      when(
        mockBatch.commit(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await repository.markAllRead(uid);

      verify(
        mockBatch.update(Collections.notifications, 'n1', {
          Fields.isRead: true,
        }),
      ).called(1);
      verify(
        mockBatch.update(Collections.notifications, 'n2', {
          Fields.isRead: true,
        }),
      ).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('handles ForbiddenException silently', () async {
      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(
        mockQuery.get(),
      ).thenThrow(ForbiddenException('Forbidden', statusCode: 403));

      await repository.markAllRead(uid);
    });

    test('handles OrignaBaseException with 403 status', () async {
      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(
        mockQuery.get(),
      ).thenThrow(OrignaBaseException('Forbidden', statusCode: 403));

      await repository.markAllRead(uid);
    });

    test('rethrows non-403 OrignaBaseException', () async {
      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(
        mockQuery.get(),
      ).thenThrow(OrignaBaseException('Server error', statusCode: 500));

      expect(
        () => repository.markAllRead(uid),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('handles doc IDs without collection prefix', () async {
      final doc = MockDocument();
      when(doc.id).thenReturn('bare_id_123');

      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([doc]);
      when(
        mockBatch.update(Collections.notifications, any, any),
      ).thenAnswer((_) {});
      when(
        mockBatch.commit(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await repository.markAllRead(uid);

      verify(
        mockBatch.update(Collections.notifications, 'bare_id_123', {
          Fields.isRead: true,
        }),
      ).called(1);
    });

    test('handles large number of notifications', () async {
      final docs = List.generate(100, (i) {
        final doc = MockDocument();
        when(doc.id).thenReturn('n$i');
        return doc;
      });

      when(
        mockQuery.where(Fields.isRead, isEqualTo: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn(docs);
      when(
        mockBatch.update(Collections.notifications, any, any),
      ).thenAnswer((_) {});
      when(
        mockBatch.commit(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await repository.markAllRead(uid);

      verify(mockBatch.update(Collections.notifications, any, any)).called(100);
    });
  });

  group('OrignaBaseNotificationRepository - markRead', () {
    test('updates single notification', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenAnswer((_) async => null);

      await repository.markRead(uid, 'n1');

      verify(mockDocRef.update({Fields.isRead: true})).called(1);
    });

    test('handles ForbiddenException silently', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenThrow(ForbiddenException('Forbidden', statusCode: 403));

      await repository.markRead(uid, 'n1');
    });

    test('handles NotFoundException silently', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenThrow(NotFoundException('Not found', statusCode: 404));

      await repository.markRead(uid, 'n1');
    });

    test('handles OrignaBaseException with 404 status', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenThrow(OrignaBaseException('Not found', statusCode: 404));

      await repository.markRead(uid, 'n1');
    });

    test('handles internal server error on nonexistent doc', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenThrow(OrignaBaseException('Internal server error'));

      await repository.markRead(uid, 'n1');
    });

    test('rethrows unexpected OrignaBaseException', () async {
      when(mockCollection.doc('n1')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenThrow(OrignaBaseException('Unexpected', statusCode: 500));

      expect(
        () => repository.markRead(uid, 'n1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('handles empty notification ID gracefully', () async {
      when(mockCollection.doc('')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenAnswer((_) async => null);

      await repository.markRead(uid, '');

      verify(mockCollection.doc('')).called(1);
    });

    test('handles notification ID with special characters', () async {
      when(mockCollection.doc('notification-123_abc')).thenReturn(mockDocRef);
      when(
        mockDocRef.update({Fields.isRead: true}),
      ).thenAnswer((_) async => null);

      await repository.markRead(uid, 'notification-123_abc');

      verify(mockCollection.doc('notification-123_abc')).called(1);
    });
  });
}
