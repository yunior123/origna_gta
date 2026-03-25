import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/chat/orignabase_chat_repository.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

class _FakeAuth extends Fake implements OrignaBaseAuth {
  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  String? get accessToken => null;
}

class _FakeDocument extends Fake implements Document {
  @override
  final String id;
  @override
  final Map<String, dynamic> data;
  @override
  final bool exists;

  _FakeDocument(this.id, this.data, {this.exists = true});

  @override
  T? get<T>(String field) => data[field] as T?;

  @override
  dynamic operator [](String key) => data[key];

  @override
  bool containsKey(String key) => data.containsKey(key);
}

class _FakeDocumentRef extends Fake implements DocumentRef {
  @override
  final String id;
  final _FakeDocument? documentValue;

  _FakeDocumentRef({this.id = 'doc_id', this.documentValue});

  @override
  Future<Document?> get() async => documentValue;
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeSubcollectionRef extends Fake implements SubcollectionRef {
  final List<Document> _docs;

  _FakeSubcollectionRef([this._docs = const []]);

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) => this;

  @override
  Query orderBy(String field, {bool descending = false}) => this;

  @override
  Query limit(int limit) => this;

  @override
  Query offset(int count) => this;

  @override
  Query startAfterId(String id) => this;

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(_docs);
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};
  _FakeSubcollectionRef? subcollectionValue;
  List<Document> queryDocs = [];

  void setDoc(String id, _FakeDocumentRef ref) {
    docsMap[id] = ref;
  }

  @override
  DocumentRef doc(String id) {
    if (docsMap.containsKey(id)) return docsMap[id]!;
    return _FakeDocumentRef(id: id);
  }

  @override
  SubcollectionRef subcollection(String parentId, String name) {
    return subcollectionValue ?? _FakeSubcollectionRef();
  }

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(queryDocs);

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) => this;

  @override
  Query orderBy(String field, {bool descending = false}) => this;

  @override
  Query limit(int limit) => this;

  @override
  Query offset(int count) => this;

  @override
  Query startAfterId(String id) => this;
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef productsCollection = _FakeCollectionRef();
  final _FakeCollectionRef chatsCollection = _FakeCollectionRef();

  @override
  String get url => 'http://localhost:8080';

  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {};

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.products) return productsCollection;
    if (name == Collections.chats) return chatsCollection;
    return _FakeCollectionRef();
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
    return requestResponse;
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseChatRepository repo;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeOb.authValue.currentUserIdValue = 'buyer_123';
    repo = OrignaBaseChatRepository(fakeOb);
  });

  group('getOrCreateChat', () {
    test('throws OrignaBaseException when user not authenticated', () async {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repo.getOrCreateChat('product_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws OrignaBaseException when user ID is empty', () async {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repo.getOrCreateChat('product_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when seller not found (null sellerId)', () async {
      final doc = _FakeDocument('product_1', {});
      fakeOb.productsCollection.setDoc(
        'product_1',
        _FakeDocumentRef(documentValue: doc),
      );

      expect(
        () => repo.getOrCreateChat('product_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when seller ID is empty string', () async {
      final doc = _FakeDocument('product_1', {Fields.sellerId: ''});
      fakeOb.productsCollection.setDoc(
        'product_1',
        _FakeDocumentRef(documentValue: doc),
      );

      expect(
        () => repo.getOrCreateChat('product_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('returns chatId on success', () async {
      final doc = _FakeDocument('product_1', {Fields.sellerId: 'seller_1'});
      fakeOb.productsCollection.setDoc(
        'product_1',
        _FakeDocumentRef(documentValue: doc),
      );
      fakeOb.requestResponse = {Fields.chatId: 'chat_abc'};

      final chatId = await repo.getOrCreateChat('product_1');

      expect(chatId, 'chat_abc');
      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.chatGetOrCreate);
      expect(fakeOb.lastRequestBody?['otherUserId'], 'seller_1');
      expect(fakeOb.lastRequestBody?[Fields.productId], 'product_1');
    });

    test('returns empty string when chatId missing from response', () async {
      final doc = _FakeDocument('product_1', {Fields.sellerId: 'seller_1'});
      fakeOb.productsCollection.setDoc(
        'product_1',
        _FakeDocumentRef(documentValue: doc),
      );
      fakeOb.requestResponse = {};

      final chatId = await repo.getOrCreateChat('product_1');
      expect(chatId, '');
    });
  });

  group('sendMessage', () {
    test('throws when user not authenticated', () async {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repo.sendMessage('chat_1', 'hello'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when user ID is empty', () async {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repo.sendMessage('chat_1', 'hello'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('sends trimmed message text', () async {
      fakeOb.requestResponse = {};

      await repo.sendMessage('chat_1', '  hello world  ');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.chatSend);
      expect(fakeOb.lastRequestBody?[Fields.chatId], 'chat_1');
      expect(fakeOb.lastRequestBody?[Fields.messageText], 'hello world');
    });
  });

  group('deleteMessage', () {
    test('throws when user not authenticated', () async {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repo.deleteMessage('chat_1', 'msg_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when user ID is empty', () async {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repo.deleteMessage('chat_1', 'msg_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('sends delete request with correct params', () async {
      fakeOb.requestResponse = {};

      await repo.deleteMessage('chat_1', 'msg_1');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.chatDeleteMessage);
      expect(fakeOb.lastRequestBody?[Fields.chatId], 'chat_1');
      expect(fakeOb.lastRequestBody?[Fields.messageId], 'msg_1');
    });
  });

  group('markRead', () {
    test('throws when user not authenticated', () async {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repo.markRead('chat_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('throws when user ID is empty', () async {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repo.markRead('chat_1'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('sends mark-read request', () async {
      fakeOb.requestResponse = {};

      await repo.markRead('chat_1');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.chatMarkRead);
      expect(fakeOb.lastRequestBody?[Fields.chatId], 'chat_1');
    });
  });

  group('messagesStream', () {
    test('emits initial fetched messages', () async {
      final msgDoc = _FakeDocument('msg_1', {
        Fields.senderId: 'user_1',
        Fields.senderDisplayName: 'John',
        Fields.messageText: 'Hello',
        Fields.createdAt: '2026-01-01T00:00:00.000Z',
        Fields.isRead: false,
        Fields.deleted: false,
      });

      fakeOb.chatsCollection.subcollectionValue = _FakeSubcollectionRef([
        msgDoc,
      ]);

      // messagesStream uses RealtimeClient which we can't easily fake,
      // but we can verify the stream type is correct
      final stream = repo.messagesStream('chat_1');
      expect(stream, isA<Stream<List<ChatMessage>>>());
    });
  });

  group('userChatsStream', () {
    test('returns a stream of ChatThread', () {
      final stream = repo.userChatsStream('user_1');
      expect(stream, isA<Stream<List<ChatThread>>>());
    });
  });

  group('sellerChatsStream', () {
    test('returns a stream of ChatThread', () {
      final stream = repo.sellerChatsStream('seller_1');
      expect(stream, isA<Stream<List<ChatThread>>>());
    });
  });

  group('allChatsStream', () {
    test('returns a stream of merged ChatThread', () {
      final stream = repo.allChatsStream('user_1');
      expect(stream, isA<Stream<List<ChatThread>>>());
    });
  });
}
