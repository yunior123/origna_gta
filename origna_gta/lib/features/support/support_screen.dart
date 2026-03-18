// coverage:ignore-file
/// Customer Support Chat Screen
///
/// Accessible from Profile → "Get Help" menu item (logged-in users only).
/// Shows category picker first, then a full chat UI with the AI agent.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/features/support/support_provider.dart';
import 'package:origna_gta/features/support/support_state.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:origna_gta/widgets/modern_textfield.dart';

/// Entry point for customer support — guards auth, then shows chat.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _conversationStarted = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onCategorySelected(SupportCategory category) async {
    setState(() {
      _conversationStarted = true;
    });

    await ref
        .read(supportViewModelProvider.notifier)
        .startConversation(category);
    _scrollToBottom();
  }

  Future<void> _onSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await ref.read(supportViewModelProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Auth gate — redirect to login if not authenticated
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      });
      return const Scaffold(body: ModernLoadingIndicator(centered: true));
    }

    final supportState = ref.watch(supportViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: double.infinity,
      mobilePlus: 520,
      tablet: 680,
      desktop: 760,
    );

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'support.title'.tr()),
      backgroundColor: isDark ? DesignTokens.darkBackground : DesignTokens.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Escalated banner
              if (supportState.isEscalated)
                _EscalatedBanner(isDark: isDark),

              // Main content
              Expanded(
                child: _conversationStarted
                    ? _ChatBody(
                        messages: supportState.messages,
                        scrollController: _scrollController,
                        isDark: isDark,
                      )
                    : _CategoryPicker(
                        isDark: isDark,
                        onCategorySelected: _onCategorySelected,
                      ),
              ),

              // Error display
              if (supportState.errorMessage != null)
                _ErrorBanner(
                  message: supportState.errorMessage!,
                  isDark: isDark,
                ),

              // Input area — only shown once conversation is started
              if (_conversationStarted && !supportState.isEscalated)
                _MessageInput(
                  controller: _messageController,
                  isLoading: supportState.isLoading,
                  isDark: isDark,
                  onSend: _onSend,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Picker
// ---------------------------------------------------------------------------

class _CategoryPicker extends StatelessWidget {
  final bool isDark;
  final void Function(SupportCategory) onCategorySelected;

  const _CategoryPicker({required this.isDark, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final categories = [
      (SupportCategory.orderStatus, Icons.local_shipping_outlined, 'support.category_order_status'),
      (SupportCategory.refundRequest, Icons.assignment_return_outlined, 'support.category_refund'),
      (SupportCategory.accountIssue, Icons.manage_accounts_outlined, 'support.category_account'),
      (SupportCategory.billingDispute, Icons.credit_card_outlined, 'support.category_billing'),
      (SupportCategory.other, Icons.help_outline_rounded, 'support.category_other'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent avatar + greeting
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: DesignTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.support_agent_rounded, color: DesignTokens.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'support.agent_name'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
                      ),
                    ),
                    Text(
                      'support.agent_tagline'.tr(),
                      style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'support.choose_category'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Category tiles
          ...categories.map(
            (entry) => _CategoryTile(
              icon: entry.$2,
              labelKey: entry.$3,
              isDark: isDark,
              onTap: () => onCategorySelected(entry.$1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.labelKey,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: labelKey.tr(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5) : DesignTokens.white,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            border: Border.all(
              color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.primary.withValues(alpha: 0.15),
                      DesignTokens.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: Icon(icon, color: DesignTokens.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  labelKey.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: DesignTokens.textDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Body
// ---------------------------------------------------------------------------

class _ChatBody extends StatelessWidget {
  final List<SupportMessage> messages;
  final ScrollController scrollController;
  final bool isDark;

  const _ChatBody({
    required this.messages,
    required this.scrollController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: ModernLoadingIndicator(centered: true));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _ChatBubble(message: message, isDark: isDark);
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final SupportMessage message;
  final bool isDark;

  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Agent avatar row
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: DesignTokens.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: DesignTokens.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'support.agent_name'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? DesignTokens.primaryGradient : null,
                color: isUser
                    ? null
                    : (isDark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isUser
                      ? DesignTokens.textOnPrimary
                      : (isDark ? DesignTokens.textOnDark : DesignTokens.textPrimary),
                ),
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 10, color: DesignTokens.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Message Input
// ---------------------------------------------------------------------------

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.isLoading,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        border: Border(
          top: BorderSide(
            color: isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ModernTextField(
                controller: controller,
                hint: 'support.input_hint'.tr(),
                isMultiline: true,
                maxLines: 4,
                minLines: 1,
                semanticsLabel: 'support-input',
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'btn-send-support',
              child: GestureDetector(
                onTap: isLoading ? null : onSend,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLoading ? null : DesignTokens.primaryGradient,
                    color: isLoading ? DesignTokens.textDisabled : null,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: isLoading
                      ? const ModernLoadingIndicator.small()
                      : const Icon(Icons.send_rounded, color: DesignTokens.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banners
// ---------------------------------------------------------------------------

class _EscalatedBanner extends StatelessWidget {
  final bool isDark;

  const _EscalatedBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.warning.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(color: DesignTokens.warning.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: DesignTokens.warningText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'support.escalated_banner'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignTokens.warningText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DesignTokens.error.withValues(alpha: 0.1),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: DesignTokens.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
