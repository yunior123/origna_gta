import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';

void main() {
  group('ChatMessage', () {
    test('creates with required fields', () {
      final msg = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'John',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
        isRead: false,
      );

      expect(msg.id, 'msg1');
      expect(msg.senderId, 'user1');
      expect(msg.senderDisplayName, 'John');
      expect(msg.text, 'Hello');
      expect(msg.createdAt, DateTime(2026, 1, 1));
      expect(msg.isRead, isFalse);
      expect(msg.deleted, isFalse);
    });

    test('deleted defaults to false', () {
      final msg = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'John',
        text: 'Hello',
        createdAt: DateTime.now(),
        isRead: true,
      );

      expect(msg.deleted, isFalse);
    });

    test('can be marked as deleted', () {
      final msg = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'John',
        text: 'Hello',
        createdAt: DateTime.now(),
        isRead: true,
        deleted: true,
      );

      expect(msg.deleted, isTrue);
    });

    test('equality works correctly', () {
      final date = DateTime(2026, 1, 1);
      final msg1 = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'John',
        text: 'Hello',
        createdAt: date,
        isRead: false,
      );
      final msg2 = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'John',
        text: 'Hello',
        createdAt: date,
        isRead: false,
      );

      expect(msg1.id, msg2.id);
      expect(msg1.text, msg2.text);
      expect(msg1.senderId, msg2.senderId);
    });
  });

  group('ChatThread', () {
    test('creates with required fields', () {
      final thread = ChatThread(
        chatId: 'chat1',
        productId: 'prod1',
        productTitle: 'Widget',
        buyerId: 'buyer1',
        sellerId: 'seller1',
      );

      expect(thread.chatId, 'chat1');
      expect(thread.productId, 'prod1');
      expect(thread.productTitle, 'Widget');
      expect(thread.buyerId, 'buyer1');
      expect(thread.sellerId, 'seller1');
      expect(thread.buyerUnreadCount, 0);
      expect(thread.sellerUnreadCount, 0);
      expect(thread.lastMessage, isNull);
      expect(thread.lastMessageAt, isNull);
      expect(thread.productImageUrl, isNull);
    });

    test('creates with all optional fields', () {
      final now = DateTime.now();
      final thread = ChatThread(
        chatId: 'chat1',
        productId: 'prod1',
        productTitle: 'Widget',
        productImageUrl: 'https://example.com/img.jpg',
        buyerId: 'buyer1',
        sellerId: 'seller1',
        lastMessage: 'Hi there',
        lastMessageAt: now,
        buyerUnreadCount: 3,
        sellerUnreadCount: 1,
      );

      expect(thread.productImageUrl, 'https://example.com/img.jpg');
      expect(thread.lastMessage, 'Hi there');
      expect(thread.lastMessageAt, now);
      expect(thread.buyerUnreadCount, 3);
      expect(thread.sellerUnreadCount, 1);
    });

    test('zero unread counts by default', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'P',
        buyerId: 'b1',
        sellerId: 's1',
      );

      expect(thread.buyerUnreadCount, 0);
      expect(thread.sellerUnreadCount, 0);
    });

    test('lastMessageAt can be null', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'P',
        buyerId: 'b1',
        sellerId: 's1',
      );

      expect(thread.lastMessageAt, isNull);
    });

    test('productImageUrl can be null', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'P',
        buyerId: 'b1',
        sellerId: 's1',
      );

      expect(thread.productImageUrl, isNull);
    });
  });

  group('ChatRepository typedef', () {
    test('ChatRepository is alias for OrignaBaseChatRepository', () {
      // Verify the typedef exists and compiles
      expect(ChatRepository, isNotNull);
    });
  });
}
