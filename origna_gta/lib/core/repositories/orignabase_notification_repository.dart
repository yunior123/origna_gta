import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

/// OrignaBase implementation of the notification repository.
///
/// Uses the flat [Collections.notifications] collection with a [Fields.userId]
/// field to reference the notification owner. Provides batch and single-item
/// read-state management.
///
/// Error handling: 403 (Forbidden) and 404 (NotFound) are silently swallowed
/// since they indicate the notification was already deleted or the user no
/// longer has access — both are non-fatal for read-state updates.
class OrignaBaseNotificationRepository {
  /// The OrignaBase client used for database operations.
  final OrignaBase _ob;

  /// Creates a notification repository with the given OrignaBase [client].
  OrignaBaseNotificationRepository(this._ob);

  /// Marks all unread notifications as read for the given user.
  ///
  /// Parameters:
  /// - [uid]: the user's document ID.
  ///
  /// Queries for all unread notifications, then batch-updates them.
  /// Silently succeeds when:
  /// - The user has no notifications (empty result).
  /// - The backend returns 403 (null resource context in PostgreSQL rules).
  ///
  /// Throws on other errors (logged via [AppError]).
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

  /// Marks a single notification as read by its document ID.
  ///
  /// Parameters:
  /// - [uid]: the user's document ID.
  /// - [notificationId]: the notification document ID.
  ///
  /// Silently succeeds when:
  /// - The notification does not exist (404).
  /// - The user lacks access (403).
  /// - An internal server error occurs for a nonexistent document.
  ///
  /// Throws on other errors (logged via [AppError]).
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
      if (e.statusCode == null && e.message.contains('Internal server error')) {
        return;
      }
      AppError.log(e, context: 'ob_notification.markRead');
      rethrow;
    }
  }
}
