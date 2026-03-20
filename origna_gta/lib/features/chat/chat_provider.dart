// Migrated: delegates to OrignaBase chat repository.
// Screens continue using chatRepositoryProvider, chatMessagesProvider, chatViewModelProvider, etc.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';

import 'chat_repository.dart';

// ─── Repository ────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<OrignaBaseChatRepository>((ref) {
  return OrignaBaseChatRepository(ref.watch(orignabaseProvider));
});

// ─── Messages stream ───────────────────────────────────────────────────────

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).messagesStream(chatId);
});

// ─── User's buyer chats stream ─────────────────────────────────────────────

final myBuyerChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = ref.watch(obUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).userChatsStream(uid);
});

// ─── User's seller chats stream ────────────────────────────────────────────

final mySellerChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = ref.watch(obUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).sellerChatsStream(uid);
});

// ─── Unified chat inbox (buyer + seller merged, deduped, sorted) ───────────

final myAllChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = ref.watch(obUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).allChatsStream(uid);
});

// ─── Chat ViewModel ────────────────────────────────────────────────────────

/// Chat state used by the ChatViewModel.
class ChatState {
  final bool isLoading;
  final String? errorMessage;
  final String? chatId;
  final bool isOwnProduct;
  final bool isPremiumRequired;

  const ChatState({
    this.isLoading = false,
    this.errorMessage,
    this.chatId,
    this.isOwnProduct = false,
    this.isPremiumRequired = false,
  });

  ChatState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? chatId,
    bool? isOwnProduct,
    bool? isPremiumRequired,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      chatId: chatId ?? this.chatId,
      isOwnProduct: isOwnProduct ?? this.isOwnProduct,
      isPremiumRequired: isPremiumRequired ?? this.isPremiumRequired,
    );
  }
}

final chatViewModelProvider =
    StateNotifierProvider.autoDispose.family<ChatViewModel, ChatState, String>((ref, productId) {
  return ChatViewModel(ref, productId);
});

/// Chat viewmodel — uses OrignaBase chat repository.
class ChatViewModel extends StateNotifier<ChatState> {
  final Ref _ref;
  final String _productId;
  Timer? _markReadTimer;

  ChatViewModel(this._ref, this._productId) : super(const ChatState());

  @override
  void dispose() {
    _markReadTimer?.cancel();
    super.dispose();
  }

  Future<void> openChat() async {
    if (state.chatId != null || state.isLoading) return;

    // Proactive Premium Check
    SubscriptionInfo? subInfo;
    final subState = _ref.read(subscriptionStreamProvider);
    
    if (subState is AsyncData<SubscriptionInfo?>) {
      subInfo = subState.value;
    } else {
      // If loading or error, try to get the future value
      try {
        subInfo = await _ref.read(subscriptionStreamProvider.future);
      } catch (_) {
        // Fallback to non-premium on error
      }
    }

    if (subInfo == null || !subInfo.isPremium) {
      state = state.copyWith(isPremiumRequired: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, isPremiumRequired: false);
    try {
      final chatId = await _ref.read(chatRepositoryProvider).getOrCreateChat(_productId);
      state = state.copyWith(isLoading: false, chatId: chatId);
    } on OrignaBaseException catch (e) {
      final isSelfChat = e.message.contains('yourself');
      final isPremiumErr = e.message.toLowerCase().contains('premium');
      state = state.copyWith(
        isLoading: false,
        isOwnProduct: isSelfChat,
        isPremiumRequired: isPremiumErr,
        errorMessage: (isSelfChat || isPremiumErr) ? null : e.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
    }
  }

  Future<void> sendMessage(String text) async {
    final chatId = state.chatId;
    final trimmed = text.trim();
    if (chatId == null || trimmed.isEmpty) return;
    if (state.isLoading) return;

    if (trimmed.length < BusinessRules.minMessageLength) {
      state = state.copyWith(errorMessage: 'Message is too short (minimum ${BusinessRules.minMessageLength} characters).');
      return;
    }
    if (trimmed.length > BusinessRules.maxMessageLength) {
      state = state.copyWith(errorMessage: 'Message exceeds the maximum length of ${BusinessRules.maxMessageLength} characters.');
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(chatRepositoryProvider).sendMessage(chatId, trimmed);
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void markReadDebounced() {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(milliseconds: 500), () => markRead());
  }

  Future<void> markRead() async {
    final chatId = state.chatId;
    if (chatId == null) return;
    await _ref.read(chatRepositoryProvider).markRead(chatId);
  }

  String _parseError(Object e) {
    if (e is OrignaBaseException) {
      final msg = e.message;
      if (msg.toLowerCase().contains('premium')) {
        return 'A Premium membership is required to chat with sellers.';
      }
      if (msg.contains('rate') || msg.contains('exhausted')) {
        return 'Too many messages. Please slow down.';
      }
      return msg;
    }
    final str = e.toString();
    if (str.contains('] ')) return str.split('] ').last;
    return str;
  }
}
