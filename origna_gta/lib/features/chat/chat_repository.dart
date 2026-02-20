import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data[Fields.createdAt];
    return ChatMessage(
      id: doc.id,
      senderId: data[Fields.senderId] as String? ?? '',
      text: data[Fields.messageText] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isRead: data[Fields.isRead] as bool? ?? false,
    );
  }
}

class ChatThread {
  final String chatId;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatThread({
    required this.chatId,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data[Fields.lastMessageAt];
    return ChatThread(
      chatId: doc.id,
      productId: data[Fields.productId] as String? ?? '',
      productTitle: data[Fields.productTitle] as String? ?? '',
      productImageUrl: data[Fields.productImageUrl] as String?,
      buyerId: data[Fields.buyerId] as String? ?? '',
      sellerId: data[Fields.sellerId] as String? ?? '',
      lastMessage: data[Fields.lastMessage] as String?,
      lastMessageAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  const ChatRepository(this._firestore, this._functions);

  /// Get or create a chat thread. Returns chatId.
  Future<String> getOrCreateChat(String productId) async {
    final result = await _functions
        .httpsCallable(CloudFunctionEndpoints.getOrCreateChat)
        .call<Map<String, dynamic>>({Fields.productId: productId});
    return result.data[Fields.chatId] as String;
  }

  /// Stream messages for a given chat thread (real-time).
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _firestore
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.chatMessages)
        .orderBy(Fields.createdAt, descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// Stream all chat threads for the current user (buyer or seller).
  Stream<List<ChatThread>> userChatsStream(String userId) {
    // We do two queries and merge — buyer and seller threads
    // For simplicity, query by buyerId; sellers see their threads via a separate widget
    return _firestore
        .collection(Collections.chats)
        .where(Fields.buyerId, isEqualTo: userId)
        .orderBy(Fields.lastMessageAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromFirestore).toList());
  }

  /// Stream chat threads where user is seller.
  Stream<List<ChatThread>> sellerChatsStream(String sellerId) {
    return _firestore
        .collection(Collections.chats)
        .where(Fields.sellerId, isEqualTo: sellerId)
        .orderBy(Fields.lastMessageAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromFirestore).toList());
  }

  /// Send a message directly to Firestore (client-side write per security rules).
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.chatMessages)
        .doc();

    batch.set(msgRef, {
      Fields.senderId: senderId,
      Fields.messageText: text.trim(),
      Fields.createdAt: now,
      Fields.isRead: false,
    });

    // Update lastMessage on the thread
    batch.update(_firestore.collection(Collections.chats).doc(chatId), {
      Fields.lastMessage: text.trim(),
      Fields.lastMessageAt: now,
    });

    await batch.commit();
  }

  /// Mark all unread messages in a chat as read.
  Future<void> markRead(String chatId) async {
    await _functions
        .httpsCallable(CloudFunctionEndpoints.markMessagesRead)
        .call<void>({Fields.chatId: chatId});
  }
}
