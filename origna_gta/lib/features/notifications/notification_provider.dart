import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether notification permission has been granted.
/// Uses StateNotifier per CLAUDE.md architecture rules (no raw StateProvider for logic).
class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false);

  void setGranted(bool granted) => state = granted;
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool>(
  (ref) => NotificationPermissionNotifier(),
);
