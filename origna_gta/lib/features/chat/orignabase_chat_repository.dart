import 'dart:async';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'chat_repository.dart';

/// OrignaBase chat repository — replaces legacy backend.
/// Chat messages use subcollection: chats/{chatId}/messages
/// Chat threads use collection: chats
class OrignaBaseChatRepository {
  final OrignaBase _ob;

  const OrignaBaseChatRepository(this._ob);

  // ---------------------------------------------------------------------------
  // Auth helper — decode userId from JWT
  // ---------------------------------------------------------------------------
  String? get _currentUserId {
    return _ob.auth.currentUserId;
  }

  /// Get or create a chat thread. Returns chatId.
  ///
  /// Queries the chats collection for an existing thread matching the
  /// productId + current buyerId. If none exists, creates a new one.
  Future<String> getOrCreateChat(String productId) async {
    final buyerId = _currentUserId;
    if (buyerId == null || buyerId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }

    final product = await _ob
        .collection(Collections.products)
        .doc(productId)
        .get();
    final sellerId = product?.get<String>(Fields.sellerId);
    if (sellerId == null || sellerId.isEmpty) {
      throw OrignaBaseException('Seller not found for product');
    }

    final result = await _ob.request(
      'POST',
      ApiEndpoints.chatGetOrCreate,
      body: {'otherUserId': sellerId, Fields.productId: productId},
    );
    return result[Fields.chatId] as String? ?? '';
  }

  /// Stream messages for a given chat thread (real-time via WebSocket).
  Stream<List<ChatMessage>> messagesStream(
    String chatId, {
    int limit = 100,
    int offset = 0,
  }) {
    final controller = StreamController<List<ChatMessage>>();
    final messages = <String, ChatMessage>{};

    // Initial fetch
    _fetchMessages(chatId, limit: limit, offset: offset)
        .then((initial) {
          for (final msg in initial) {
            messages[msg.id] = msg;
          }
          controller.add(_sortedMessages(messages));
        })
        .catchError((Object e, StackTrace st) {
          AppError.log(
            e,
            stackTrace: st,
            context: 'ob_chat.messagesStream.init',
          );
          if (e is! OrignaBaseException) controller.addError(e);
        });

    // Realtime updates via subcollection
    final realtime = RealtimeClient(_ob);
    realtime.connect();
    final subCollectionName =
        '${Collections.chats}__${Collections.chatMessages}';
    final sub = realtime
        .subscribe(subCollectionName)
        .listen(
          (change) {
            final doc = change.document;
            // Only include messages for this chatId
            final parentId = doc.data['parent_id'] as String?;
            if (parentId != '${Collections.chats}:$chatId') return;

            switch (change.type) {
              case ChangeType.create:
              case ChangeType.update:
                messages[doc.id] = _docToMessage(doc);
                controller.add(_sortedMessages(messages));
              case ChangeType.delete:
                messages.remove(doc.id);
                controller.add(_sortedMessages(messages));
            }
          },
          onError: (Object e, StackTrace st) {
            AppError.log(
              e,
              stackTrace: st,
              context: 'ob_chat.messagesStream.realtime',
            );
          },
        );

    controller.onCancel = () {
      sub.cancel();
      realtime.disconnect();
    };

    return controller.stream;
  }

  /// Stream all chat threads where user is buyer.
  Stream<List<ChatThread>> userChatsStream(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _watchThreads(Fields.buyerId, userId, limit: limit, offset: offset);
  }

  /// Stream chat threads where user is seller.
  Stream<List<ChatThread>> sellerChatsStream(
    String sellerId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _watchThreads(
      Fields.sellerId,
      sellerId,
      limit: limit,
      offset: offset,
    );
  }

  /// Unified inbox merging buyer and seller threads.
  Stream<List<ChatThread>> allChatsStream(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ChatThread>>();
    List<ChatThread> buyerThreads = [];
    List<ChatThread> sellerThreads = [];

    void emit() {
      final mergedMap = <String, ChatThread>{
        for (final t in buyerThreads) t.chatId: t,
        for (final t in sellerThreads) t.chatId: t,
      };
      final merged = mergedMap.values.toList()
        ..sort((a, b) {
          final at = a.lastMessageAt;
          final bt = b.lastMessageAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
      controller.add(merged);
    }

    final sub1 = userChatsStream(userId, limit: limit, offset: offset).listen((
      threads,
    ) {
      buyerThreads = threads;
      emit();
    }, onError: controller.addError);
    final sub2 = sellerChatsStream(userId, limit: limit, offset: offset).listen(
      (threads) {
        sellerThreads = threads;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  /// Send a message to a chat thread via direct subcollection write.
  Future<void> sendMessage(String chatId, String text) async {
    final senderId = _currentUserId;
    if (senderId == null || senderId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }

    await _ob.request(
      'POST',
      ApiEndpoints.chatSend,
      body: {Fields.chatId: chatId, Fields.messageText: text.trim()},
    );
  }

  /// Soft-delete a message — sets deleted flag to true.
  Future<void> deleteMessage(String chatId, String messageId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }
    await _ob.request(
      'POST',
      ApiEndpoints.chatDeleteMessage,
      body: {Fields.chatId: chatId, Fields.messageId: messageId},
    );
  }

  /// Mark all unread messages in a chat as read.
  ///
  /// Queries unread messages in the subcollection and batch-updates them.
  Future<void> markRead(String chatId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }
    await _ob.request(
      'POST',
      ApiEndpoints.chatMarkRead,
      body: {Fields.chatId: chatId},
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<List<ChatMessage>> _fetchMessages(
    String chatId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final snapshot = await _ob
        .collection(Collections.chats)
        .subcollection(chatId, Collections.chatMessages)
        .orderBy(Fields.createdAt, descending: true)
        .limit(limit)
        .offset(offset)
        .get();

    final messages = snapshot.docs.map(_docToMessage).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  ChatMessage _docToMessage(Document doc) {
    final data = doc.data;
    final createdAtRaw = data[Fields.createdAt];
    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      senderId: data[Fields.senderId] as String? ?? '',
      senderDisplayName: data[Fields.senderDisplayName] as String? ?? '',
      text: data[Fields.messageText] as String? ?? '',
      createdAt: createdAt,
      isRead: data[Fields.isRead] as bool? ?? false,
      deleted: data[Fields.deleted] as bool? ?? false,
    );
  }

  Stream<List<ChatThread>> _watchThreads(
    String field,
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    final controller = StreamController<List<ChatThread>>();
    final threads = <String, ChatThread>{};

    // Initial fetch
    _ob
        .collection(Collections.chats)
        .where(field, isEqualTo: userId)
        .orderBy(Fields.lastMessageAt, descending: true)
        .limit(limit)
        .offset(offset)
        .get()
        .then((snapshot) {
          for (final doc in snapshot.docs) {
            threads[doc.id] = _docToThread(doc);
          }
          controller.add(_sortedThreads(threads));
        })
        .catchError((Object e, StackTrace st) {
          AppError.log(
            e,
            stackTrace: st,
            context: 'ob_chat._watchThreads.init',
          );
          controller.addError(e);
        });

    // Realtime updates
    final realtime = RealtimeClient(_ob);
    realtime.connect();
    final sub = realtime
        .subscribe(Collections.chats)
        .listen(
          (change) {
            final doc = change.document;
            final matchesField = doc.data[field] as String?;
            if (matchesField != userId) return;

            switch (change.type) {
              case ChangeType.create:
              case ChangeType.update:
                threads[doc.id] = _docToThread(doc);
                controller.add(_sortedThreads(threads));
              case ChangeType.delete:
                threads.remove(doc.id);
                controller.add(_sortedThreads(threads));
            }
          },
          onError: (Object e, StackTrace st) {
            AppError.log(
              e,
              stackTrace: st,
              context: 'ob_chat._watchThreads.realtime',
            );
          },
        );

    controller.onCancel = () {
      sub.cancel();
      realtime.disconnect();
    };

    return controller.stream;
  }

  ChatThread _docToThread(Document doc) {
    final data = doc.data;
    final lastMsgRaw = data[Fields.lastMessageAt];
    DateTime? lastMessageAt;
    if (lastMsgRaw is String) {
      lastMessageAt = DateTime.tryParse(lastMsgRaw);
    } else if (lastMsgRaw is int) {
      lastMessageAt = DateTime.fromMillisecondsSinceEpoch(lastMsgRaw);
    }

    return ChatThread(
      chatId: doc.id,
      productId: data[Fields.productId] as String? ?? '',
      productTitle: data[Fields.productTitle] as String? ?? '',
      productImageUrl: data[Fields.productImageUrl] as String?,
      buyerId: data[Fields.buyerId] as String? ?? '',
      sellerId: data[Fields.sellerId] as String? ?? '',
      lastMessage: data[Fields.lastMessage] as String?,
      lastMessageAt: lastMessageAt,
      buyerUnreadCount: (data[Fields.buyerUnreadCount] as int?) ?? 0,
      sellerUnreadCount: (data[Fields.sellerUnreadCount] as int?) ?? 0,
    );
  }

  List<ChatMessage> _sortedMessages(Map<String, ChatMessage> map) {
    final list = map.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  List<ChatThread> _sortedThreads(Map<String, ChatThread> map) {
    final list = map.values.toList()
      ..sort((a, b) {
        final at = a.lastMessageAt;
        final bt = b.lastMessageAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    return list;
  }
}
