import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/chat/chat_provider.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

/// Lists all chat conversations for the current user (buyer-seller messaging).
class ChatConversationsScreen extends ConsumerWidget {
  const ChatConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptionAsync = ref.watch(subscriptionStreamProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        appBar: AppBarFactory.simple(
          title: 'chat.inbox_title'.tr(),
          subtitle: 'chat.inbox_subtitle'.tr(),
        ),
        body: subscriptionAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (_, _) => const _ChatInboxBody(isPremium: false),
          data: (sub) {
            final isPremium = sub?.isPremium ?? false;
            return _ChatInboxBody(isPremium: isPremium);
          },
        ),
      ),
    );
  }
}

class _ChatInboxBody extends ConsumerWidget {
  final bool isPremium;
  const _ChatInboxBody({required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(myAllChatsProvider);
    final uid = ref.watch(userIdProvider) ?? '';

    return threadsAsync.when(
      loading: () => const Center(child: ModernLoadingIndicator()),
      error: (error, _) => AnimatedEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'common.error'.tr(),
        subtitle: error.toString(),
        action: ModernButton(
          label: 'common.retry'.tr(),
          icon: Icons.refresh,
          isPrimary: false,
          onPressed: () => ref.invalidate(myAllChatsProvider),
        ),
      ),
      data: (threads) {
        final ovThreads = threads
            .where((t) => _isOrignaVenturesSeller(t.sellerId))
            .toList();
        final otherThreads = threads
            .where((t) => !_isOrignaVenturesSeller(t.sellerId))
            .toList();

        if (threads.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'chat.inbox_empty'.tr(),
            subtitle: 'chat.inbox_empty_desc'.tr(),
          );
        }

        final canChatAllSellers =
            isPremium || SellerConstants.sellerOnboardingEnabled;
        final visibleThreads = canChatAllSellers ? threads : ovThreads;
        final comingSoonThreads = canChatAllSellers
            ? <ChatThread>[]
            : otherThreads;

        return RefreshIndicator(
          color: DesignTokens.primary,
          onRefresh: () async => ref.invalidate(myAllChatsProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visibleThreads.length + comingSoonThreads.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 76,
              endIndent: 16,
              color: DesignTokens.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              if (index < visibleThreads.length) {
                final thread = visibleThreads[index];
                final isBuyer = thread.buyerId == uid;
                final unreadCount = isBuyer
                    ? thread.buyerUnreadCount
                    : thread.sellerUnreadCount;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                  child: _ChatThreadTile(
                    thread: thread,
                    unreadCount: unreadCount,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: ChatArgs(
                        productId: thread.productId,
                        productTitle: thread.productTitle,
                      ),
                    ),
                  ),
                );
              }
              final comingIndex = index - visibleThreads.length;
              final thread = comingSoonThreads[comingIndex];
              return FadeSlideIn(
                delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                child: _ChatThreadTile(
                  thread: thread,
                  unreadCount: 0,
                  isComingSoon: true,
                  onTap: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }
}

bool _isOrignaVenturesSeller(String sellerId) =>
    sellerId == SellerConstants.orignaVenturesSellerId;

class _ChatThreadTile extends StatelessWidget {
  final ChatThread thread;
  final int unreadCount;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _ChatThreadTile({
    required this.thread,
    required this.unreadCount,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = !isComingSoon && unreadCount > 0;

    return Semantics(
      button: !isComingSoon,
      label: 'chat-thread-${thread.chatId}',
      child: InkWell(
        onTap: isComingSoon ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _ProductAvatar(
                imageUrl: thread.productImageUrl,
                productTitle: thread.productTitle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.productTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isComingSoon
                                  ? DesignTokens.textSecondary
                                  : (isDark
                                        ? DesignTokens.textOnDark
                                        : DesignTokens.textPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isComingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: DesignTokens.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              'chat.coming_soon'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.primary,
                              ),
                            ),
                          ),
                        ] else if (thread.lastMessageAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(thread.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? DesignTokens.primary
                                  : DesignTokens.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isComingSoon
                                ? 'chat.seller_onboarding_disabled'.tr()
                                : (thread.lastMessage ??
                                      'chat.tap_to_chat'.tr()),
                            style: TextStyle(
                              fontSize: 13,
                              color: isComingSoon
                                  ? DesignTokens.textSecondary.withValues(
                                      alpha: 0.7,
                                    )
                                  : (hasUnread
                                        ? (isDark
                                              ? DesignTokens.textOnDark
                                              : DesignTokens.textPrimary)
                                        : DesignTokens.textSecondary),
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isComingSoon && hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: DesignTokens.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: DesignTokens.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isComingSoon
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: DesignTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'common.now'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(time);
  }
}

class _ProductAvatar extends StatelessWidget {
  final String? imageUrl;
  final String productTitle;

  const _ProductAvatar({this.imageUrl, required this.productTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.15),
            DesignTokens.secondary.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => _fallbackIcon(),
                errorWidget: (context, url, error) => _fallbackIcon(),
              )
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return ShaderMask(
      shaderCallback: (bounds) =>
          DesignTokens.primaryGradient.createShader(bounds),
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 22,
        color: DesignTokens.white,
      ),
    );
  }
}

// ─── Flutter Previews ────────────────────────────────────────────────────────

// === Widget Previews ===

// ═══ Widget Previews ═══

const _previewChatImageBase = 'https://fastly.picsum.photos/id';

String _previewChatImage(int id, {int width = 900, int height = 900}) =>
    '$_previewChatImageBase/$id/$width/$height.jpg';

final _previewChatSubscription = SubscriptionInfo(
  status: SubscriptionStatusValues.premiumActive.first,
  isPremium: true,
  currentPeriodEnd: DateTime(2026, 5, 18),
);

final _previewChatUser = AppAuthUser(
  uid: 'preview-uid',
  email: 'preview.chat@origna.ca',
  emailVerified: true,
);

final _previewChatThreads = [
  ChatThread(
    chatId: 'chat-preview-1',
    productId: 'product-chat-1',
    productTitle: 'Stoneware Matcha Bowl',
    productImageUrl: _previewChatImage(1060),
    buyerId: 'preview-uid',
    sellerId: 'seller-chat-1',
    lastMessage: 'I can ship this tomorrow morning from Montreal.',
    lastMessageAt: DateTime(2026, 4, 18, 9, 42),
    buyerUnreadCount: 2,
  ),
  ChatThread(
    chatId: 'chat-preview-2',
    productId: 'product-chat-2',
    productTitle: 'Premium Espresso Beans',
    productImageUrl: _previewChatImage(225),
    buyerId: 'preview-uid',
    sellerId: 'seller-chat-2',
    lastMessage: 'Thanks, I added a fresh roast batch for you.',
    lastMessageAt: DateTime(2026, 4, 17, 18, 15),
    buyerUnreadCount: 0,
  ),
  ChatThread(
    chatId: 'chat-preview-3',
    productId: 'product-chat-3',
    productTitle: 'Wool Throw Blanket',
    productImageUrl: _previewChatImage(1074),
    buyerId: 'buyer-chat-3',
    sellerId: 'preview-uid',
    lastMessage: 'The navy colourway is back in stock next week.',
    lastMessageAt: DateTime(2026, 4, 16, 13, 5),
    sellerUnreadCount: 3,
  ),
];

Widget _chatConversationsPreview({
  SubscriptionInfo? subscription,
  List<ChatThread>? threads,
}) => previewScopeLoggedIn(
  uid: _previewChatUser.uid,
  extraOverrides: [
    currentUserProvider.overrideWith((ref) => _previewChatUser),
    subscriptionStreamProvider.overrideWith(
      (ref) => Stream.value(subscription ?? _previewChatSubscription),
    ),
    myAllChatsProvider.overrideWith(
      (ref) => Stream.value(threads ?? _previewChatThreads),
    ),
  ],
  child: const ChatConversationsScreen(),
);

@Preview(
  name: 'Chat Conversations — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewChatConversationsScreenMobile() =>
    previewMobile(child: _chatConversationsPreview());

@Preview(
  name: 'Chat Conversations — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewChatConversationsScreenDesktop() =>
    previewDesktop(child: _chatConversationsPreview());

@Preview(
  name: 'Chat Conversations Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewChatConversationsLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _chatConversationsPreview(),
);

@Preview(
  name: 'Chat Conversations Paywall — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewChatConversationsPaywallDesktop() => previewDesktop(
  child: _chatConversationsPreview(
    subscription: const SubscriptionInfo(status: 'inactive', isPremium: false),
    threads: const [],
  ),
);
