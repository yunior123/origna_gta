import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

import 'chat_repository.dart';

// ─── Repository ────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

// ─── Messages stream ───────────────────────────────────────────────────────

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).messagesStream(chatId);
});

// ─── User's buyer chats stream ─────────────────────────────────────────────

final myBuyerChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).userChatsStream(uid);
});

// ─── User's seller chats stream ────────────────────────────────────────────

final mySellerChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).sellerChatsStream(uid);
});

// ─── Chat ViewModel ────────────────────────────────────────────────────────

class ChatState {
  final bool isLoading;
  final String? errorMessage;
  final String? chatId;

  const ChatState({this.isLoading = false, this.errorMessage, this.chatId});

  ChatState copyWith({bool? isLoading, String? errorMessage, String? chatId, bool clearError = false}) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      chatId: chatId ?? this.chatId,
    );
  }
}

final chatViewModelProvider =
    StateNotifierProvider.autoDispose.family<ChatViewModel, ChatState, String>((ref, productId) {
  return ChatViewModel(ref, productId);
});

class ChatViewModel extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _productId;

  ChatViewModel(this._ref, this._productId) : super(const ChatState());

  Future<void> openChat() async {
    if (state.chatId != null || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final chatId = await _ref.read(chatRepositoryProvider).getOrCreateChat(_productId);
      state = state.copyWith(isLoading: false, chatId: chatId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> sendMessage(String text) async {
    final chatId = state.chatId;
    if (chatId == null || text.trim().isEmpty) return;
    try {
      await _ref.read(chatRepositoryProvider).sendMessage(chatId, text);
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
    }
  }

  Future<void> markRead() async {
    final chatId = state.chatId;
    if (chatId == null) return;
    await _ref.read(chatRepositoryProvider).markRead(chatId);
  }

  String _parseError(Object e) {
    final str = e.toString();
    if (str.contains('premium')) return 'A Premium membership is required to chat with sellers.';
    if (str.contains('] ')) return str.split('] ').last;
    return str;
  }
}
