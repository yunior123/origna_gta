import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>(), MockSpec<OrignaBaseAuth>()])
import 'chat_repository_coverage_boost_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late MockOrignaBaseAuth mockAuth;
  late OrignaBaseChatRepository repo;

  setUp(() {
    mockOb = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();

    when(mockOb.auth).thenReturn(mockAuth);
    when(mockAuth.currentUserId).thenReturn('user_123');

    repo = OrignaBaseChatRepository(mockOb);
  });

  group('getOrCreateChat', () {
    test('throws when not authenticated', () async {
      when(mockAuth.currentUserId).thenReturn(null);
      expect(
        () => repo.getOrCreateChat('prod_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when empty userId', () async {
      when(mockAuth.currentUserId).thenReturn('');
      expect(
        () => repo.getOrCreateChat('prod_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });
  });

  group('sendMessage', () {
    test('throws when not authenticated', () async {
      when(mockAuth.currentUserId).thenReturn(null);
      expect(
        () => repo.sendMessage('chat_1', 'hello'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when empty userId', () async {
      when(mockAuth.currentUserId).thenReturn('');
      expect(
        () => repo.sendMessage('chat_1', 'hello'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('sends message successfully', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.sendMessage('chat_1', 'hello world');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.chatSend,
          body: {Fields.chatId: 'chat_1', Fields.messageText: 'hello world'},
        ),
      ).called(1);
    });
  });

  group('deleteMessage', () {
    test('throws when not authenticated', () async {
      when(mockAuth.currentUserId).thenReturn(null);
      expect(
        () => repo.deleteMessage('chat_1', 'msg_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when empty userId', () async {
      when(mockAuth.currentUserId).thenReturn('');
      expect(
        () => repo.deleteMessage('chat_1', 'msg_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('deletes message successfully', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.deleteMessage('chat_1', 'msg_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.chatDeleteMessage,
          body: {Fields.chatId: 'chat_1', Fields.messageId: 'msg_1'},
        ),
      ).called(1);
    });
  });

  group('markRead', () {
    test('throws when not authenticated', () async {
      when(mockAuth.currentUserId).thenReturn(null);
      expect(
        () => repo.markRead('chat_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when empty userId', () async {
      when(mockAuth.currentUserId).thenReturn('');
      expect(
        () => repo.markRead('chat_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('marks read successfully', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.markRead('chat_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.chatMarkRead,
          body: {Fields.chatId: 'chat_1'},
        ),
      ).called(1);
    });
  });

  group('ChatMessage model', () {
    test('ChatMessage creation and properties', () {
      final msg = ChatMessage(
        id: 'msg_1',
        senderId: 'user_1',
        senderDisplayName: 'Test User',
        text: 'Hello there',
        createdAt: DateTime(2026, 1, 1),
        isRead: false,
        deleted: false,
      );

      expect(msg.id, 'msg_1');
      expect(msg.senderId, 'user_1');
      expect(msg.senderDisplayName, 'Test User');
      expect(msg.text, 'Hello there');
      expect(msg.isRead, isFalse);
      expect(msg.deleted, isFalse);
    });

    test('ChatMessage with read and deleted flags', () {
      final msg = ChatMessage(
        id: 'msg_2',
        senderId: 'user_2',
        senderDisplayName: 'Other',
        text: 'Read message',
        createdAt: DateTime(2026, 1, 2),
        isRead: true,
        deleted: true,
      );

      expect(msg.isRead, isTrue);
      expect(msg.deleted, isTrue);
    });
  });

  group('ChatThread model', () {
    test('ChatThread creation with all fields', () {
      final thread = ChatThread(
        chatId: 'chat_1',
        productId: 'prod_1',
        productTitle: 'Test Product',
        productImageUrl: 'https://example.com/img.jpg',
        buyerId: 'buyer_1',
        sellerId: 'seller_1',
        lastMessage: 'Hello',
        lastMessageAt: DateTime(2026, 1, 1),
        buyerUnreadCount: 2,
        sellerUnreadCount: 0,
      );

      expect(thread.chatId, 'chat_1');
      expect(thread.productId, 'prod_1');
      expect(thread.productTitle, 'Test Product');
      expect(thread.productImageUrl, 'https://example.com/img.jpg');
      expect(thread.buyerId, 'buyer_1');
      expect(thread.sellerId, 'seller_1');
      expect(thread.buyerUnreadCount, 2);
      expect(thread.sellerUnreadCount, 0);
      expect(thread.lastMessage, 'Hello');
    });

    test('ChatThread with null optional fields', () {
      final thread = ChatThread(
        chatId: 'chat_2',
        productId: 'prod_2',
        productTitle: 'Test',
        buyerId: 'b1',
        sellerId: 's1',
      );
      expect(thread.lastMessageAt, isNull);
      expect(thread.lastMessage, isNull);
      expect(thread.productImageUrl, isNull);
      expect(thread.buyerUnreadCount, 0);
      expect(thread.sellerUnreadCount, 0);
    });
  });
}
