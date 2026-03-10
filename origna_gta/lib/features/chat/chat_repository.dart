// coverage:ignore-file
// Migrated: delegates to OrignaBase chat repository.
// Screens continue using ChatRepository, ChatMessage, ChatThread.

export 'orignabase_chat_repository.dart';

import 'orignabase_chat_repository.dart';

/// Data class for a single chat message.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderDisplayName;
  final String text;
  final DateTime createdAt;
  final bool isRead;
  final bool deleted;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.text,
    required this.createdAt,
    required this.isRead,
    this.deleted = false,
  });
}

/// Data class for a chat thread summary.
class ChatThread {
  final String chatId;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int buyerUnreadCount;
  final int sellerUnreadCount;

  const ChatThread({
    required this.chatId,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
    this.buyerUnreadCount = 0,
    this.sellerUnreadCount = 0,
  });
}

/// Backward-compatible alias — the OrignaBase repository is the concrete implementation.
typedef ChatRepository = OrignaBaseChatRepository;
