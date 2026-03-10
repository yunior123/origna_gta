// coverage:ignore-file
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// OrignaBase implementation of the notification repository.
///
/// Notifications are stored as a subcollection: users/{uid}/notifications/{notificationId}.
class OrignaBaseNotificationRepository {
  final OrignaBase _ob;

  OrignaBaseNotificationRepository(this._ob);

  SubcollectionRef _notificationsRef(String uid) =>
      _ob.collection(Collections.users).subcollection(uid, Collections.notifications);

  /// Marks all unread notifications as read using batch update.
  Future<void> markAllRead(String uid) async {
    final snapshot = await _notificationsRef(uid)
        .where(Fields.isRead, isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _ob.batch();
    for (final doc in snapshot.docs) {
      batch.update(
        '${Collections.users}/$uid/${Collections.notifications}',
        doc.id,
        {Fields.isRead: true},
      );
    }
    await batch.commit();
  }

  /// Marks a single notification as read.
  Future<void> markRead(String uid, String notificationId) async {
    await _notificationsRef(uid).doc(notificationId).update({Fields.isRead: true});
  }
}
