import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/screens/notifications_screen.dart';

import '../test_utils.dart';

class _TestNotificationRepository implements NotificationRepository {
  @override
  Future<void> markAllRead(String uid) async {}

  @override
  Future<void> markRead(String uid, String notificationId) async {}

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(
    String uid, {
    int limit = 50,
    int offset = 0,
  }) {
    return Stream.value([
      {
        'id': 'notif_1',
        'title': 'Test notification',
        'body': 'Still builds',
        Fields.type: 'order_update',
        Fields.isRead: false,
        Fields.createdAt: DateTime(2026, 3, 1),
      },
    ]);
  }
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  testWidgets('builds without error with mocked providers', (tester) async {
    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppAuthUser(
              uid: 'user_123',
              email: 'test@example.com',
            ),
          ),
          notificationRepositoryProvider.overrideWithValue(
            _TestNotificationRepository(),
          ),
        ],
        child: const NotificationsScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
