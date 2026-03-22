import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/features/chat/orignabase_chat_repository.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<OrignaBaseAuth>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<SubcollectionRef>(),
  MockSpec<Document>(),
])
import 'orignabase_chat_repository_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late MockOrignaBaseAuth mockAuth;
  late MockCollectionRef mockChatsCollection;
  late MockCollectionRef mockProductsCollection;
  late MockDocumentRef mockProductDoc;
  late OrignaBaseChatRepository repository;

  setUp(() {
    mockOb = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();
    mockChatsCollection = MockCollectionRef();
    mockProductsCollection = MockCollectionRef();
    mockProductDoc = MockDocumentRef();

    when(mockOb.auth).thenReturn(mockAuth);
    when(mockAuth.currentUserId).thenReturn('user_123');
    when(mockOb.collection(Collections.chats)).thenReturn(mockChatsCollection);
    when(
      mockOb.collection(Collections.products),
    ).thenReturn(mockProductsCollection);

    repository = OrignaBaseChatRepository(mockOb);
  });

  group('OrignaBaseChatRepository', () {
    group('getOrCreateChat', () {
      test('throws when user is not authenticated', () async {
        when(mockAuth.currentUserId).thenReturn(null);

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when user id is empty', () async {
        when(mockAuth.currentUserId).thenReturn('');

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when seller not found for product', () async {
        when(mockProductsCollection.doc('p1')).thenReturn(mockProductDoc);
        when(mockProductDoc.get()).thenAnswer((_) async => null);

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('returns chatId on success', () async {
        final productDoc = MockDocument();
        when(mockProductsCollection.doc('p1')).thenReturn(mockProductDoc);
        when(mockProductDoc.get()).thenAnswer((_) async => productDoc);
        when(productDoc.get<String>(Fields.sellerId)).thenReturn('seller_1');

        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatGetOrCreate,
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => {Fields.chatId: 'chat_abc'});

        final result = await repository.getOrCreateChat('p1');
        expect(result, 'chat_abc');
      });
    });

    group('sendMessage', () {
      test('throws when user is not authenticated', () async {
        when(mockAuth.currentUserId).thenReturn(null);

        expect(
          () => repository.sendMessage('c1', 'hello'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('sends message when authenticated', () async {
        when(
          mockOb.request('POST', ApiEndpoints.chatSend, body: anyNamed('body')),
        ).thenAnswer((_) async => {});

        await repository.sendMessage('c1', 'hello');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatSend,
            body: {Fields.chatId: 'c1', Fields.messageText: 'hello'},
          ),
        ).called(1);
      });

      test('trims whitespace from message text', () async {
        when(
          mockOb.request('POST', ApiEndpoints.chatSend, body: anyNamed('body')),
        ).thenAnswer((_) async => {});

        await repository.sendMessage('c1', '  hello  ');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatSend,
            body: {Fields.chatId: 'c1', Fields.messageText: 'hello'},
          ),
        ).called(1);
      });
    });

    group('deleteMessage', () {
      test('throws when user is not authenticated', () async {
        when(mockAuth.currentUserId).thenReturn(null);

        expect(
          () => repository.deleteMessage('c1', 'm1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('deletes message when authenticated', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatDeleteMessage,
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => {});

        await repository.deleteMessage('c1', 'm1');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatDeleteMessage,
            body: {Fields.chatId: 'c1', Fields.messageId: 'm1'},
          ),
        ).called(1);
      });
    });

    group('markRead', () {
      test('throws when user is not authenticated', () async {
        when(mockAuth.currentUserId).thenReturn(null);

        expect(
          () => repository.markRead('c1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('marks chat as read when authenticated', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatMarkRead,
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => {});

        await repository.markRead('c1');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatMarkRead,
            body: {Fields.chatId: 'c1'},
          ),
        ).called(1);
      });
    });
  });
}
