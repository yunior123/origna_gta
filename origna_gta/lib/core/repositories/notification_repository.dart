import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Notification repository backed by OrignaBase subcollections.
class NotificationRepository {
  NotificationRepository(this._ob);

  final OrignaBase _ob;

  /// Mark all unread notifications as read for a user.
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

  /// Mark a single notification as read.
  Future<void> markRead(String uid, String notificationId) async {
    await _ob
        .collection(Collections.users)
        .doc(uid)
        .subcollection(Collections.notifications)
        .doc(notificationId)
        .update({Fields.isRead: true});
  }

  /// Stream of notifications for a user, newest first.
  Stream<List<Map<String, dynamic>>> watchNotifications(String uid) {
    final subcollection = _ob
        .collection(Collections.users)
        .doc(uid)
        .subcollection(Collections.notifications);

    Future<List<Map<String, dynamic>>> fetchOrderedNotifications() async {
      final snapshot = await subcollection
          .orderBy(Fields.createdAt, descending: true)
          .limit(50)
          .get();
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

      final subscription = subcollection.snapshots().asyncMap((_) {
        return fetchOrderedNotifications();
      }).listen(
        controller.add,
        onError: controller.addError,
      );

      controller.onCancel = () => subscription.cancel();
    });
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(orignabaseProvider));
});
