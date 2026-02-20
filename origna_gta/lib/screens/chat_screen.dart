import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/premium_paywall_widget.dart';

import '../features/chat/chat_provider.dart';
import '../features/chat/chat_repository.dart';

class ChatScreenArgs {
  final String productId;
  final String productTitle;

  const ChatScreenArgs({required this.productId, required this.productTitle});
}

class ChatScreen extends ConsumerStatefulWidget {
  final String productId;
  final String productTitle;

  const ChatScreen({super.key, required this.productId, required this.productTitle});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider(widget.productId).notifier).openChat();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(chatViewModelProvider(widget.productId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBarFactory.simple(title: widget.productTitle),
      body: Column(
        children: [
          if (vmState.errorMessage != null && vmState.errorMessage!.contains('Premium'))
            Expanded(
              child: Center(
                child: PremiumPaywallWidget(featureName: 'Chat with Sellers'),
              ),
            )
          else if (vmState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(vmState.errorMessage!, style: TextStyle(color: DesignTokens.error)),
            )
          else if (vmState.isLoading && vmState.chatId == null)
            const Expanded(child: Center(child: ModernLoadingIndicator()))
          else if (vmState.chatId != null) ...[
            Expanded(
              child: _MessagesList(
                chatId: vmState.chatId!,
                myUid: myUid,
                isDark: isDark,
                scrollController: _scrollController,
                onNewMessages: _scrollToBottom,
              ),
            ),
            _MessageInput(
              controller: _textController,
              isDark: isDark,
              onSend: () async {
                final text = _textController.text.trim();
                if (text.isEmpty) return;
                _textController.clear();
                await ref.read(chatViewModelProvider(widget.productId).notifier).sendMessage(text);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MessagesList extends ConsumerWidget {
  final String chatId;
  final String myUid;
  final bool isDark;
  final ScrollController scrollController;
  final VoidCallback onNewMessages;

  const _MessagesList({
    required this.chatId,
    required this.myUid,
    required this.isDark,
    required this.scrollController,
    required this.onNewMessages,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));

    ref.listen(chatMessagesProvider(chatId), (prev, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onNewMessages());
      }
    });

    return messagesAsync.when(
      loading: () => const Center(child: ModernLoadingIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Say hello! 👋',
              style: TextStyle(color: DesignTokens.textSecondary),
            ),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (ctx, i) => _MessageBubble(
            message: messages[i],
            isMe: messages[i].senderId == myUid,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 1)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: isMe
                ? DesignTokens.primary
                : (isDark ? DesignTokens.darkSurface : Colors.grey.shade200),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isMe ? Colors.white : (isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.isDark, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? DesignTokens.darkOutline : DesignTokens.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: DesignTokens.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? DesignTokens.darkSurfaceVariant : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'btn-send-message',
            child: IconButton.filled(
              key: const Key('chat_send_button'),
              icon: const Icon(Icons.send_rounded),
              onPressed: onSend,
              tooltip: 'Send',
              style: IconButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
