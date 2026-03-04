import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/notifications_screen.dart';

import '../_preview_theme.dart';

@Preview(name: 'Notifications Center', group: 'Screens')
Widget previewNotificationsScreen() => previewResponsiveBreakpoints(
  builder: (breakpoint) => ProviderScope(
    child: NotificationsScreenLayout(
      notificationsAsync: const AsyncValue.loading(),
      uid: 'preview-uid',
      onRefresh: () async {},
      onBack: () {},
      onMarkAllRead: () async {},
      onMarkRead: (n) async {},
    ),
  ),
);

@Preview(name: 'Notifications — Empty State', group: 'Screens')
Widget previewNotificationsScreenEmpty() => previewResponsiveBreakpoints(
  builder: (breakpoint) => ProviderScope(
    child: NotificationsScreenLayout(
      notificationsAsync: const AsyncValue.data([]),
      uid: 'preview-uid',
      onRefresh: () async {},
      onBack: () {},
      onMarkAllRead: () async {},
      onMarkRead: (n) async {},
    ),
  ),
);
