import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Repository for user notifications stored as a subcollection under users.
///
/// Notifications live at `users/{uid}/notifications/{notifId}` in OrignaBase.
/// Provides read/unread state management and a realtime stream sorted by
/// creation date (newest first).
///
/// Note: This is a separate implementation from [OrignaBaseNotificationRepository]
/// which uses the flat `notifications` collection with a `userId` field.
class NotificationRepository {
  /// Creates a notification repository with the given OrignaBase [client].
  NotificationRepository(this._ob);

  /// The OrignaBase client used for database operations.
  final OrignaBase _ob;

  /// Marks all unread notifications as read for the given user.
  ///
  /// Parameters:
  /// - [uid]: the user's document ID.
  ///
  /// Uses a batch update for efficiency. Silently succeeds if there are
  /// no unread notifications.
  Future<void> markAllRead(String uid) async {
    final snap = await _ob
        .collection(Collections.users)
        .doc(uid)
        .subcollection(Collections.notifications)
        .where(Fields.isRead, isEqualTo: false)
        .get();
    if (snap.isEmpty) return;
    final batch = _ob.batch();
    final collection = '${Collections.users}__${Collections.notifications}';
    for (final doc in snap.docs) {
      batch.update(collection, doc.id, {Fields.isRead: true});
    }
    await batch.commit();
  }

  /// Marks a single notification as read.
  ///
  /// Parameters:
  /// - [uid]: the user's document ID.
  /// - [notificationId]: the notification document ID to mark as read.
  Future<void> markRead(String uid, String notificationId) async {
    await _ob
        .collection(Collections.users)
        .doc(uid)
        .subcollection(Collections.notifications)
        .doc(notificationId)
        .update({Fields.isRead: true});
  }

  /// Provides a realtime stream of notifications for the user, newest first.
  ///
  /// Parameters:
  /// - [uid]: the user's document ID.
  /// - [limit]: max notifications per page (default 50).
  /// - [offset]: number of notifications to skip for pagination.
  ///
  /// Emits an initial snapshot, then re-fetches on any change to the
  /// subcollection via OrignaBase realtime snapshots.
  Stream<List<Map<String, dynamic>>> watchNotifications(
    String uid, {
    int limit = 50,
    int offset = 0,
  }) {
    final subcollection = _ob
        .collection(Collections.users)
        .doc(uid)
        .subcollection(Collections.notifications);

    Future<List<Map<String, dynamic>>> fetchOrderedNotifications() async {
      var query = subcollection
          .orderBy(Fields.createdAt, descending: true)
          .limit(limit);
      if (offset > 0) {
        query = query.offset(offset);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data})
          .toList();
    }

    return Stream.multi((controller) async {
      try {
        controller.add(await fetchOrderedNotifications());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }

      final subscription = subcollection
          .snapshots()
          .asyncMap((_) {
            return fetchOrderedNotifications();
          })
          .listen(controller.add, onError: controller.addError);

      controller.onCancel = () => subscription.cancel();
    });
  }
}

/// Riverpod provider for [NotificationRepository].
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(orignabaseProvider));
});
