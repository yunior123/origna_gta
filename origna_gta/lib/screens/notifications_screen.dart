import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:flutter/widget_previews.dart';

/// Live stream of the current user's notifications via OrignaBase realtime.
///
/// Kept public so global lifecycle handlers can invalidate it after a
/// meaningful background gap and avoid stale badges/lists on resume.
final userNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final uid = ref.watch(currentUserProvider)?.uid;
      if (uid == null) return Stream.value(const []);
      return ref
          .watch(notificationRepositoryProvider)
          .watchNotifications(uid)
          .map((items) => items.map(AppNotification.fromMap).toList());
    });

/// Lists push notifications with read/unread state and mark-all-read action.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));

    return NotificationsScreenLayout(
      notificationsAsync: notificationsAsync,
      uid: uid,
      onRefresh: () async => ref.invalidate(userNotificationsProvider),
      onBack: () => Navigator.of(context).pop(),
      onMarkAllRead: () => _markAll(context, uid, ref),
      onMarkRead: (n) => _markRead(n, uid, ref),
    );
  }

  Future<void> _markAll(
    BuildContext context,
    String? uid,
    WidgetRef ref,
  ) async {
    if (uid == null) return;
    try {
      // MVVM FIX (AUDIT): Delegated to NotificationRepository — UI no longer builds database queries.
      await ref.read(notificationRepositoryProvider).markAllRead(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notifications.all_marked_read'.tr()),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'NotificationsScreen._markAll');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.generic_error'.tr()),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markRead(
    AppNotification notification,
    String? uid,
    WidgetRef ref,
  ) async {
    if (notification.isRead || uid == null) return;
    // MVVM FIX (AUDIT): Delegated to NotificationRepository.
    await ref
        .read(notificationRepositoryProvider)
        .markRead(uid, notification.id);
  }
}

/// Lists push notifications with read/unread state and mark-all-read action.Layout
class NotificationsScreenLayout extends StatelessWidget {
  final AsyncValue<List<AppNotification>> notificationsAsync;
  final String? uid;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;
  final void Function(AppNotification) onMarkRead;

  const NotificationsScreenLayout({
    super.key,
    required this.notificationsAsync,
    required this.uid,
    required this.onRefresh,
    required this.onBack,
    required this.onMarkAllRead,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.transparent,
        appBar: AppBarFactory.simple(
          title: 'notifications.title'.tr(),
          onBackPressed: onBack,
        ),
        body: notificationsAsync.when(
          loading: () => const Center(child: ModernLoadingIndicator()),
          error: (e, _) => AnimatedEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'common.error_loading'.tr(),
            subtitle: AppError.getMessage(e),
            action: ModernButton(
              label: 'common.retry'.tr(),
              icon: Icons.refresh,
              isOutlined: true,
              onPressed: onRefresh,
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return AnimatedEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'notifications.no_notifications'.tr(),
                subtitle: 'notifications.no_notifications_desc'.tr(),
                showMascot: true,
              );
            }

            final now = DateTime.now();
            final today = <AppNotification>[];
            final thisWeek = <AppNotification>[];
            final earlier = <AppNotification>[];

            for (final n in notifications) {
              final diff = now.difference(n.createdAt);
              if (diff.inDays == 0) {
                today.add(n);
              } else if (diff.inDays < 7) {
                thisWeek.add(n);
              } else {
                earlier.add(n);
              }
            }

            final hasUnread = notifications.any((n) => !n.isRead);

            return Column(
              children: [
                // Mark all read action bar
                if (hasUnread && uid != null)
                  _MarkAllReadBar(onMarkAllRead: onMarkAllRead),
                Expanded(
                  child: RefreshIndicator(
                    color: DesignTokens.primary,
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(DesignTokens.spacing16),
                      itemCount: () {
                        int count = 0;
                        if (today.isNotEmpty) {
                          count += 1 + today.length; // header + items
                        }
                        if (thisWeek.isNotEmpty) count += 1 + thisWeek.length;
                        if (earlier.isNotEmpty) count += 1 + earlier.length;
                        count += 1; // bottom spacing
                        return count;
                      }(),
                      itemBuilder: (context, index) {
                        int offset = 0;
                        // Today section
                        if (today.isNotEmpty) {
                          if (index == offset) {
                            return _SectionHeader(
                              label: 'notifications.today'.tr(),
                            );
                          }
                          offset++;
                          if (index < offset + today.length) {
                            final n = today[index - offset];
                            return FadeSlideIn(
                              child: _NotificationTile(
                                notification: n,
                                onMarkRead: () => onMarkRead(n),
                              ),
                            );
                          }
                          offset += today.length;
                        }
                        // This week section
                        if (thisWeek.isNotEmpty) {
                          if (index == offset) {
                            return _SectionHeader(
                              label: 'notifications.this_week'.tr(),
                            );
                          }
                          offset++;
                          if (index < offset + thisWeek.length) {
                            final n = thisWeek[index - offset];
                            return FadeSlideIn(
                              child: _NotificationTile(
                                notification: n,
                                onMarkRead: () => onMarkRead(n),
                              ),
                            );
                          }
                          offset += thisWeek.length;
                        }
                        // Earlier section
                        if (earlier.isNotEmpty) {
                          if (index == offset) {
                            return _SectionHeader(
                              label: 'notifications.earlier'.tr(),
                            );
                          }
                          offset++;
                          if (index < offset + earlier.length) {
                            final n = earlier[index - offset];
                            return FadeSlideIn(
                              child: _NotificationTile(
                                notification: n,
                                onMarkRead: () => onMarkRead(n),
                              ),
                            );
                          }
                          offset += earlier.length;
                        }
                        // Bottom spacing
                        return const SizedBox(height: DesignTokens.spacing32);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> data) {
    final ts = data[Fields.createdAt];
    DateTime parsedDate;
    if (ts is DateTime) {
      parsedDate = ts;
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return AppNotification(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data[Fields.type] as String? ?? '',
      isRead: data[Fields.isRead] as bool? ?? false,
      createdAt: parsedDate,
    );
  }
}

class _MarkAllReadBar extends StatelessWidget {
  final VoidCallback onMarkAllRead;

  const _MarkAllReadBar({required this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.primary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: 'btn-mark-all-read',
            child: TextButton.icon(
              onPressed: onMarkAllRead,
              icon: const Icon(
                Icons.done_all_rounded,
                size: 18,
                color: DesignTokens.primary,
              ),
              label: Text(
                'notifications.mark_all_read'.tr(),
                style: const TextStyle(
                  color: DesignTokens.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: notification.isRead
          ? notification.title
          : 'notifications.unread_label'.tr(
              namedArgs: {'title': notification.title},
            ),
      child: GestureDetector(
        onTap: onMarkRead,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.white.withValues(alpha: 0.9))
                : (isDark
                      ? DesignTokens.primary.withValues(alpha: 0.1)
                      : DesignTokens.primary.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(DesignTokens.radius16),
            border: Border.all(
              color: notification.isRead
                  ? (isDark
                        ? DesignTokens.white.withValues(alpha: 0.05)
                        : DesignTokens.outline.withValues(alpha: 0.3))
                  : DesignTokens.primary.withValues(alpha: 0.25),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.black.withValues(
                  alpha: isDark ? 0.15 : 0.04,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: notification.isRead
                      ? null
                      : LinearGradient(
                          colors: [
                            DesignTokens.gradientStart.withValues(alpha: 0.15),
                            DesignTokens.gradientEnd.withValues(alpha: 0.15),
                          ],
                        ),
                  color: notification.isRead
                      ? DesignTokens.primary.withValues(alpha: 0.08)
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.type),
                  size: 22,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: isDark
                                  ? DesignTokens.white
                                  : DesignTokens.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: DesignTokens.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: DesignTokens.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      NotificationTypes.orderConfirmation => Icons.shopping_bag_outlined,
      NotificationTypes.shippingUpdate => Icons.local_shipping_outlined,
      NotificationTypes.paymentIssue => Icons.payment_outlined,
      NotificationTypes.accountUpdate => Icons.account_circle_outlined,
      NotificationTypes.chatMessage => Icons.chat_bubble_outline_rounded,
      NotificationTypes.stockAvailable => Icons.inventory_2_outlined,
      NotificationTypes.newOrder => Icons.storefront_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'notifications.time_just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'notifications.time_minutes_ago'.tr(
        namedArgs: {'n': diff.inMinutes.toString()},
      );
    }
    if (diff.inHours < 24) {
      return 'notifications.time_hours_ago'.tr(
        namedArgs: {'n': diff.inHours.toString()},
      );
    }
    if (diff.inDays < 7) {
      return 'notifications.time_days_ago'.tr(
        namedArgs: {'n': diff.inDays.toString()},
      );
    }
    return 'notifications.time_weeks_ago'.tr(
      namedArgs: {'n': (diff.inDays / 7).floor().toString()},
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DesignTokens.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

final _previewNotificationsMixed = [
  AppNotification(
    id: 'notif-order-confirmed',
    title: 'Order confirmed — Small-Batch Espresso Beans',
    body: 'Your order #OG-2048 has been confirmed and is now being prepared.',
    type: NotificationTypes.orderConfirmation,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  AppNotification(
    id: 'notif-chat',
    title: 'New message from North Roast Co.',
    body: 'We packed your order and added a note about roast date freshness.',
    type: NotificationTypes.chatMessage,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'notif-shipping',
    title: 'Shipping update — Tracking now available',
    body: 'Carrier UPS picked up your package. Delivery is expected this week.',
    type: NotificationTypes.shippingUpdate,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
  ),
  AppNotification(
    id: 'notif-stock',
    title: 'Back in stock — Ceramic Morning Mug',
    body: 'An item from your wishlist is available again in limited quantity.',
    type: NotificationTypes.stockAvailable,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  AppNotification(
    id: 'notif-payment',
    title: 'Payment method needs attention',
    body: 'Please review your saved card before your next subscription renewal.',
    type: NotificationTypes.paymentIssue,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

final _previewNotificationsUnread = [
  AppNotification(
    id: 'notif-new-order',
    title: 'New order from Toronto buyer',
    body: 'A buyer just placed an order for 3 products from your storefront.',
    type: NotificationTypes.newOrder,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
  ),
  AppNotification(
    id: 'notif-account',
    title: 'Account update completed',
    body: 'Your seller verification details were successfully reviewed.',
    type: NotificationTypes.accountUpdate,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  AppNotification(
    id: 'notif-order-2',
    title: 'Order confirmed — Maple Gift Box',
    body: 'Your buyer order is confirmed and the shipping label is next.',
    type: NotificationTypes.orderConfirmation,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

Widget _notificationsLoading() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: const AsyncValue.loading(),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () {},
    onMarkRead: (_) {},
  ),
);

Widget _notificationsEmpty() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: const AsyncValue.data([]),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () {},
    onMarkRead: (_) {},
  ),
);

Widget _notificationsMixed() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: AsyncValue.data(_previewNotificationsMixed),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () {},
    onMarkRead: (_) {},
  ),
);

Widget _notificationsUnread() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: AsyncValue.data(_previewNotificationsUnread),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () {},
    onMarkRead: (_) {},
  ),
);

@Preview(
  name: 'Notifications Feed Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewNotificationsScreenMobile() =>
    previewMobile(child: _notificationsMixed());

@Preview(
  name: 'Notifications Feed Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewNotificationsScreenDesktop() =>
    previewDesktop(child: _notificationsMixed());

@Preview(
  name: 'Notifications Unread Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewNotificationsUnreadMobile() =>
    previewMobile(child: _notificationsUnread());

@Preview(
  name: 'Notifications Empty Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewNotificationsScreenEmptyDesktop() =>
    previewDesktop(child: _notificationsEmpty());

@Preview(
  name: 'Notifications Loading Dark — Tablet',
  group: 'Screens',
  size: Size(768, 1024),
)
Widget previewNotificationsScreenTablet() =>
    previewTablet(child: _notificationsLoading());

@Preview(
  name: 'Notifications Feed Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewNotificationsLightDesktop() =>
    previewDesktop(theme: previewLightTheme, child: _notificationsMixed());
