import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<OrignaBaseAuth>(),
  MockSpec<CollectionRef>(),
  MockSpec<DocumentRef>(),
  MockSpec<SubcollectionRef>(),
  MockSpec<Document>(),
  MockSpec<Query>(),
  MockSpec<QuerySnapshot>(),
])
import 'orignabase_chat_repository_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late MockOrignaBaseAuth mockAuth;
  late MockCollectionRef mockChatsCollection;
  late MockCollectionRef mockProductsCollection;
  late MockDocumentRef mockProductDoc;
  late MockSubcollectionRef mockMessagesSubcollection;
  late MockQuery mockQuery;
  late OrignaBaseChatRepository repository;

  setUp(() {
    mockOb = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();
    mockChatsCollection = MockCollectionRef();
    mockProductsCollection = MockCollectionRef();
    mockProductDoc = MockDocumentRef();
    mockMessagesSubcollection = MockSubcollectionRef();
    mockQuery = MockQuery();

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

      test('throws when product not found', () async {
        when(mockProductsCollection.doc('p1')).thenReturn(mockProductDoc);
        when(mockProductDoc.get()).thenAnswer((_) async => null);

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when product sellerId is empty', () async {
        final productDoc = MockDocument();
        when(mockProductsCollection.doc('p1')).thenReturn(mockProductDoc);
        when(mockProductDoc.get()).thenAnswer((_) async => productDoc);
        when(productDoc.get<String>(Fields.sellerId)).thenReturn('');

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when sellerId is null', () async {
        final productDoc = MockDocument();
        when(mockProductsCollection.doc('p1')).thenReturn(mockProductDoc);
        when(mockProductDoc.get()).thenAnswer((_) async => productDoc);
        when(productDoc.get<String>(Fields.sellerId)).thenReturn(null);

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

      test('returns empty string when chatId is null in response', () async {
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
        ).thenAnswer((_) async => {});

        final result = await repository.getOrCreateChat('p1');
        expect(result, '');
      });

      test('propagates request errors', () async {
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
        ).thenThrow(OrignaBaseException('Network error'));

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('handles network timeout with status code', () async {
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
        ).thenThrow(OrignaBaseException('Network timeout', statusCode: 504));

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(
            allOf(
              isA<OrignaBaseException>(),
              predicate<OrignaBaseException>((e) => e.statusCode == 504),
            ),
          ),
        );
      });

      test('handles 403 forbidden error', () async {
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
        ).thenThrow(OrignaBaseException('Forbidden', statusCode: 403));

        expect(
          () => repository.getOrCreateChat('p1'),
          throwsA(
            allOf(
              isA<OrignaBaseException>(),
              predicate<OrignaBaseException>((e) => e.statusCode == 403),
            ),
          ),
        );
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

      test('throws when user id is empty', () async {
        when(mockAuth.currentUserId).thenReturn('');

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

        await repository.sendMessage('c1', ' hello ');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatSend,
            body: {Fields.chatId: 'c1', Fields.messageText: 'hello'},
          ),
        ).called(1);
      });

      test('trims newlines and tabs from message text', () async {
        when(
          mockOb.request('POST', ApiEndpoints.chatSend, body: anyNamed('body')),
        ).thenAnswer((_) async => {});

        await repository.sendMessage('c1', '\nhello\t');

        verify(
          mockOb.request(
            'POST',
            ApiEndpoints.chatSend,
            body: {Fields.chatId: 'c1', Fields.messageText: 'hello'},
          ),
        ).called(1);
      });

      test('handles rate limit error with status code', () async {
        when(
          mockOb.request('POST', ApiEndpoints.chatSend, body: anyNamed('body')),
        ).thenThrow(
          OrignaBaseException('Rate limit exceeded', statusCode: 429),
        );

        expect(
          () => repository.sendMessage('c1', 'hello'),
          throwsA(
            allOf(
              isA<OrignaBaseException>(),
              predicate<OrignaBaseException>((e) => e.statusCode == 429),
            ),
          ),
        );
      });

      test('propagates send errors', () async {
        when(
          mockOb.request('POST', ApiEndpoints.chatSend, body: anyNamed('body')),
        ).thenThrow(OrignaBaseException('Failed to send'));

        expect(
          () => repository.sendMessage('c1', 'hello'),
          throwsA(isA<OrignaBaseException>()),
        );
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

      test('throws when user id is empty', () async {
        when(mockAuth.currentUserId).thenReturn('');

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

      test('handles not found error with status code', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatDeleteMessage,
            body: anyNamed('body'),
          ),
        ).thenThrow(OrignaBaseException('Message not found', statusCode: 404));

        expect(
          () => repository.deleteMessage('c1', 'm1'),
          throwsA(
            allOf(
              isA<OrignaBaseException>(),
              predicate<OrignaBaseException>((e) => e.statusCode == 404),
            ),
          ),
        );
      });

      test('propagates delete errors', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatDeleteMessage,
            body: anyNamed('body'),
          ),
        ).thenThrow(OrignaBaseException('Failed to delete'));

        expect(
          () => repository.deleteMessage('c1', 'm1'),
          throwsA(isA<OrignaBaseException>()),
        );
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

      test('throws when user id is empty', () async {
        when(mockAuth.currentUserId).thenReturn('');

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

      test('handles forbidden error with status code', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatMarkRead,
            body: anyNamed('body'),
          ),
        ).thenThrow(OrignaBaseException('Forbidden', statusCode: 403));

        expect(
          () => repository.markRead('c1'),
          throwsA(
            allOf(
              isA<OrignaBaseException>(),
              predicate<OrignaBaseException>((e) => e.statusCode == 403),
            ),
          ),
        );
      });

      test('propagates mark read errors', () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.chatMarkRead,
            body: anyNamed('body'),
          ),
        ).thenThrow(OrignaBaseException('Failed to mark read'));

        expect(
          () => repository.markRead('c1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });
    });

    group('ChatMessage model', () {
      test('creates message with all fields', () {
        final message = ChatMessage(
          id: 'msg_1',
          senderId: 'user_1',
          senderDisplayName: 'Alice',
          text: 'Hello world',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          isRead: true,
          deleted: false,
        );

        expect(message.id, 'msg_1');
        expect(message.senderId, 'user_1');
        expect(message.senderDisplayName, 'Alice');
        expect(message.text, 'Hello world');
        expect(message.isRead, isTrue);
        expect(message.deleted, isFalse);
      });

      test('deleted defaults to false', () {
        final message = ChatMessage(
          id: 'msg_1',
          senderId: 'user_1',
          senderDisplayName: 'Alice',
          text: 'Hello',
          createdAt: DateTime.now(),
          isRead: false,
        );

        expect(message.deleted, isFalse);
      });
    });

    group('ChatThread model', () {
      test('creates thread with all fields', () {
        final thread = ChatThread(
          chatId: 'chat_1',
          productId: 'prod_1',
          productTitle: 'Test Product',
          productImageUrl: 'https://example.com/image.jpg',
          buyerId: 'buyer_1',
          sellerId: 'seller_1',
          lastMessage: 'Hello',
          lastMessageAt: DateTime(2024, 1, 1, 10, 0),
          buyerUnreadCount: 2,
          sellerUnreadCount: 1,
        );

        expect(thread.chatId, 'chat_1');
        expect(thread.productId, 'prod_1');
        expect(thread.productTitle, 'Test Product');
        expect(thread.productImageUrl, 'https://example.com/image.jpg');
        expect(thread.buyerId, 'buyer_1');
        expect(thread.sellerId, 'seller_1');
        expect(thread.lastMessage, 'Hello');
        expect(thread.buyerUnreadCount, 2);
        expect(thread.sellerUnreadCount, 1);
      });

      test('unread counts default to 0', () {
        final thread = ChatThread(
          chatId: 'chat_1',
          productId: 'prod_1',
          productTitle: 'Test',
          buyerId: 'buyer_1',
          sellerId: 'seller_1',
        );

        expect(thread.buyerUnreadCount, 0);
        expect(thread.sellerUnreadCount, 0);
      });

      test('optional fields can be null', () {
        final thread = ChatThread(
          chatId: 'chat_1',
          productId: 'prod_1',
          productTitle: 'Test',
          buyerId: 'buyer_1',
          sellerId: 'seller_1',
        );

        expect(thread.productImageUrl, isNull);
        expect(thread.lastMessage, isNull);
        expect(thread.lastMessageAt, isNull);
      });
    });
  });
}
