import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/screens/notifications_screen.dart';

import '../_preview_theme.dart';

Widget _notificationsLoading() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: const AsyncValue.loading(),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () async {},
    onMarkRead: (n) async {},
  ),
);

Widget _notificationsEmpty() => previewScope(
  child: NotificationsScreenLayout(
    notificationsAsync: const AsyncValue.data([]),
    uid: 'preview-uid',
    onRefresh: () async {},
    onBack: () {},
    onMarkAllRead: () async {},
    onMarkRead: (n) async {},
  ),
);

@Preview(name: 'Notifications Center — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewNotificationsScreenMobile() => previewMobile(child: _notificationsLoading());

@Preview(name: 'Notifications Center — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewNotificationsScreenTablet() => previewTablet(child: _notificationsLoading());

@Preview(name: 'Notifications Center — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewNotificationsScreenDesktop() => previewDesktop(child: _notificationsLoading());

@Preview(name: 'Notifications Center — Web', group: 'Screens', size: Size(1440, 900))
Widget previewNotificationsScreenWeb() => previewWeb(child: _notificationsLoading());

@Preview(name: 'Notifications Empty State — Mobile', group: 'Screens', size: Size(390, 844))
Widget previewNotificationsScreenEmptyMobile() => previewMobile(child: _notificationsEmpty());

@Preview(name: 'Notifications Empty State — Tablet', group: 'Screens', size: Size(768, 1024))
Widget previewNotificationsScreenEmptyTablet() => previewTablet(child: _notificationsEmpty());

@Preview(name: 'Notifications Empty State — Desktop', group: 'Screens', size: Size(1280, 800))
Widget previewNotificationsScreenEmptyDesktop() => previewDesktop(child: _notificationsEmpty());

@Preview(name: 'Notifications Empty State — Web', group: 'Screens', size: Size(1440, 900))
Widget previewNotificationsScreenEmptyWeb() => previewWeb(child: _notificationsEmpty());
