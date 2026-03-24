import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/features/chat/orignabase_chat_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuth implements OrignaBaseAuth {
  String? userId;

  @override
  String? get currentUserId => userId;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeOb implements OrignaBase {
  final _FakeAuth fakeAuth = _FakeAuth();
  Map<String, dynamic>? requestResult;
  Object? requestError;
  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;

  // For collection().doc().get() chain — product lookup
  Map<String, dynamic>? productData;
  bool productNotFound = false;

  @override
  OrignaBaseAuth get auth => fakeAuth;

  @override
  CollectionRef collection(String name) {
    // Return a real CollectionRef pointing at this fake OrignaBase.
    // The doc().get() call in getOrCreateChat will go through graphql(),
    // which we override below.
    return CollectionRef(this, name);
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastRequestMethod = method;
    lastRequestPath = path;
    lastRequestBody = body;
    if (requestError != null) throw requestError!;
    return requestResult ?? {};
  }

  @override
  Future<Map<String, dynamic>> graphql(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    // Simulate doc().get() for product lookup in getOrCreateChat
    if (productNotFound) {
      return {
        'data': {'get': null},
      };
    }
    if (productData != null) {
      return {
        'data': {
          'get': {'id': 'prod1', ...productData!},
        },
      };
    }
    return {
      'data': {'get': null},
    };
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeOb fakeOb;
  late OrignaBaseChatRepository repo;

  setUp(() {
    fakeOb = _FakeOb();
    repo = OrignaBaseChatRepository(fakeOb);
  });

  group('OrignaBaseChatRepository', () {
    group('getOrCreateChat', () {
      test('throws when user is not authenticated', () async {
        fakeOb.fakeAuth.userId = null;

        expect(
          () => repo.getOrCreateChat('prod1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when user id is empty', () async {
        fakeOb.fakeAuth.userId = '';

        expect(
          () => repo.getOrCreateChat('prod1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when product has no seller', () async {
        fakeOb.fakeAuth.userId = 'buyer1';
        fakeOb.productData = {'sellerId': null};

        expect(
          () => repo.getOrCreateChat('prod1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when product seller id is empty', () async {
        fakeOb.fakeAuth.userId = 'buyer1';
        fakeOb.productData = {'sellerId': ''};

        expect(
          () => repo.getOrCreateChat('prod1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('returns chatId from API on success', () async {
        fakeOb.fakeAuth.userId = 'buyer1';
        fakeOb.productData = {'sellerId': 'seller1'};
        fakeOb.requestResult = {'chatId': 'chat_abc'};

        final chatId = await repo.getOrCreateChat('prod1');
        expect(chatId, 'chat_abc');
        expect(fakeOb.lastRequestMethod, 'POST');
      });

      test('returns empty string when chatId missing from response', () async {
        fakeOb.fakeAuth.userId = 'buyer1';
        fakeOb.productData = {'sellerId': 'seller1'};
        fakeOb.requestResult = {};

        final chatId = await repo.getOrCreateChat('prod1');
        expect(chatId, '');
      });

      test('throws when product not found (null doc)', () async {
        fakeOb.fakeAuth.userId = 'buyer1';
        fakeOb.productNotFound = true;

        expect(() => repo.getOrCreateChat('nonexistent'), throwsA(anything));
      });
    });

    group('sendMessage', () {
      test('throws when user is not authenticated', () async {
        fakeOb.fakeAuth.userId = null;

        expect(
          () => repo.sendMessage('chat1', 'Hello'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when user id is empty', () async {
        fakeOb.fakeAuth.userId = '';

        expect(
          () => repo.sendMessage('chat1', 'Hello'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('sends message via API request and trims text', () async {
        fakeOb.fakeAuth.userId = 'user1';

        await repo.sendMessage('chat1', '  Hello World  ');
        expect(fakeOb.lastRequestMethod, 'POST');
        expect(fakeOb.lastRequestBody?['text'], 'Hello World');
        expect(fakeOb.lastRequestBody?['chatId'], 'chat1');
      });
    });

    group('deleteMessage', () {
      test('throws when user is not authenticated', () async {
        fakeOb.fakeAuth.userId = null;

        expect(
          () => repo.deleteMessage('chat1', 'msg1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when user id is empty', () async {
        fakeOb.fakeAuth.userId = '';

        expect(
          () => repo.deleteMessage('chat1', 'msg1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('calls API to delete message', () async {
        fakeOb.fakeAuth.userId = 'user1';

        await repo.deleteMessage('chat1', 'msg1');
        expect(fakeOb.lastRequestMethod, 'POST');
        expect(fakeOb.lastRequestBody?['chatId'], 'chat1');
        expect(fakeOb.lastRequestBody?['messageId'], 'msg1');
      });
    });

    group('markRead', () {
      test('throws when user is not authenticated', () async {
        fakeOb.fakeAuth.userId = null;

        expect(
          () => repo.markRead('chat1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('throws when user id is empty', () async {
        fakeOb.fakeAuth.userId = '';

        expect(
          () => repo.markRead('chat1'),
          throwsA(isA<OrignaBaseException>()),
        );
      });

      test('calls API to mark messages as read', () async {
        fakeOb.fakeAuth.userId = 'user1';

        await repo.markRead('chat1');
        expect(fakeOb.lastRequestMethod, 'POST');
        expect(fakeOb.lastRequestBody?['chatId'], 'chat1');
      });
    });
  });

  group('ChatMessage data class', () {
    test('default deleted is false', () {
      final msg = ChatMessage(
        id: 'msg1',
        senderId: 'user1',
        senderDisplayName: 'Name',
        text: 'Hello',
        createdAt: DateTime(2026, 3, 1),
        isRead: false,
      );
      expect(msg.deleted, isFalse);
    });

    test('stores all fields correctly', () {
      final date = DateTime(2026, 3, 24, 12, 0);
      final msg = ChatMessage(
        id: 'msg2',
        senderId: 'user2',
        senderDisplayName: 'Jane',
        text: 'World',
        createdAt: date,
        isRead: true,
        deleted: true,
      );
      expect(msg.id, 'msg2');
      expect(msg.senderId, 'user2');
      expect(msg.senderDisplayName, 'Jane');
      expect(msg.text, 'World');
      expect(msg.createdAt, date);
      expect(msg.isRead, isTrue);
      expect(msg.deleted, isTrue);
    });
  });

  group('ChatThread data class', () {
    test('defaults for optional fields', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'Product',
        buyerId: 'b1',
        sellerId: 's1',
      );
      expect(thread.productImageUrl, isNull);
      expect(thread.lastMessage, isNull);
      expect(thread.lastMessageAt, isNull);
      expect(thread.buyerUnreadCount, 0);
      expect(thread.sellerUnreadCount, 0);
    });

    test('stores all optional fields', () {
      final now = DateTime(2026, 3, 24);
      final thread = ChatThread(
        chatId: 'c2',
        productId: 'p2',
        productTitle: 'Widget',
        productImageUrl: 'https://img.test/a.jpg',
        buyerId: 'b2',
        sellerId: 's2',
        lastMessage: 'Hi',
        lastMessageAt: now,
        buyerUnreadCount: 5,
        sellerUnreadCount: 2,
      );
      expect(thread.chatId, 'c2');
      expect(thread.productImageUrl, 'https://img.test/a.jpg');
      expect(thread.lastMessage, 'Hi');
      expect(thread.lastMessageAt, now);
      expect(thread.buyerUnreadCount, 5);
      expect(thread.sellerUnreadCount, 2);
    });
  });

  group('ChatRepository typedef', () {
    test('ChatRepository is alias for OrignaBaseChatRepository', () {
      expect(ChatRepository, equals(OrignaBaseChatRepository));
    });
  });
}
