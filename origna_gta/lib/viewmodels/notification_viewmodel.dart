import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/utils/utils.dart';

/// ViewModel for the notifications screen.
///
/// Manages mark-all-read and mark-read operations with proper
/// loading/error state handling, following MVVM architecture.
class NotificationViewModel extends AsyncNotifier<void> {
  String? _uid;

  @override
  Future<void> build() async {
    // No initial async work needed
  }

  /// Sets the current user ID for notification operations.
  void setUid(String? uid) {
    _uid = uid;
  }

  /// Marks all notifications as read for the current user.
  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncLoading();
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'NotificationViewModel.markAllRead',
      );
      state = AsyncError(e, st);
    }
  }

  /// Marks a single notification as read.
  Future<void> markRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await ref
          .read(notificationRepositoryProvider)
          .markRead(uid, notificationId);
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'NotificationViewModel.markRead',
      );
    }
  }
}

/// Riverpod provider for [NotificationViewModel].
final notificationViewModelProvider =
    AsyncNotifierProvider<NotificationViewModel, void>(
      NotificationViewModel.new,
    );
