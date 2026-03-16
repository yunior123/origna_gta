// coverage:ignore-file
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

/// OrignaBase implementation of the notification repository.
///
/// Notifications are stored in the flat [Collections.notifications] collection
/// with a [Fields.userId] field referencing the owner.
class OrignaBaseNotificationRepository {
  final OrignaBase _ob;

  OrignaBaseNotificationRepository(this._ob);

  /// Marks all unread notifications as read using batch update.
  ///
  /// Silently succeeds when the user has no notifications (list returns
  /// empty or 403 due to null resource context on the SurrealDB rule).
  Future<void> markAllRead(String uid) async {
    try {
      final snapshot = await _ob
          .collection(Collections.notifications)
          .where(Fields.userId, isEqualTo: uid)
          .where(Fields.isRead, isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _ob.batch();
      for (final doc in snapshot.docs) {
        // doc.id may include collection prefix e.g. "notifications:abc123".
        // batch.update expects only the bare record ID part.
        final bareId = doc.id.contains(':') ? doc.id.split(':').last : doc.id;
        batch.update(Collections.notifications, bareId, {Fields.isRead: true});
      }
      await batch.commit();
    } on ForbiddenException {
      // 403 when there are no notifications: null resource → isOwner fails.
      // Treat as "nothing to mark read".
      return;
    } on OrignaBaseException catch (e) {
      if (e.statusCode == 403) return;
      AppError.log(e, context: 'ob_notification.markAllRead');
      rethrow;
    }
  }

  /// Marks a single notification as read.
  ///
  /// Silently succeeds when the notification does not exist (non-fatal).
  Future<void> markRead(String uid, String notificationId) async {
    try {
      await _ob
          .collection(Collections.notifications)
          .doc(notificationId)
          .update({Fields.isRead: true});
    } on ForbiddenException {
      return;
    } on NotFoundException {
      return;
    } on OrignaBaseException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return;
      // Internal server error on nonexistent doc is also acceptable.
      if (e.statusCode == null && e.message.contains('Internal server error')) return;
      AppError.log(e, context: 'ob_notification.markRead');
      rethrow;
    }
  }
}
