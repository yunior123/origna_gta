import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/notification_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/screens/notifications_screen.dart';

import '../test_utils.dart';
import 'notifications_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NotificationRepository>()])
void main() {
  late MockNotificationRepository mockRepo;
  late AppAuthUser mockUser;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockUser = const AppAuthUser(uid: 'user_123', email: 'test@example.com');
    initTestMocks();
  });

  Widget createTestWidget({bool loggedIn = true}) {
    return TestWrapper(
      overrides: [
        currentUserProvider.overrideWithValue(loggedIn ? mockUser : null),
        notificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const NotificationsScreen(),
    );
  }

  group('NotificationsScreen Widget Tests', () {
    testWidgets('renders empty state when no notifications', (tester) async {
      when(
        mockRepo.watchNotifications('user_123'),
      ).thenAnswer((_) => Stream.value(const <Map<String, dynamic>>[]));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('notifications.no_notifications'.tr()), findsOneWidget);
    });

    testWidgets('renders list of notifications', (tester) async {
      when(mockRepo.watchNotifications('user_123')).thenAnswer(
        (_) => Stream.value([
          {
            'id': 'n1',
            'title': 'Test Title',
            'body': 'Test Body',
            Fields.type: 'order_confirmation',
            Fields.isRead: false,
            Fields.createdAt: DateTime(2026, 3, 1),
          },
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('can mark all read', (tester) async {
      when(mockRepo.watchNotifications('user_123')).thenAnswer(
        (_) => Stream.value([
          {
            'id': 'n1',
            'title': 'T1',
            'body': 'B1',
            Fields.type: 't',
            Fields.isRead: false,
            Fields.createdAt: DateTime(2026, 3, 1),
          },
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final markAllBtn = find.text('notifications.mark_all_read'.tr());
      await tester.tap(markAllBtn);
      await tester.pump();

      verify(mockRepo.markAllRead('user_123')).called(1);
    });

    testWidgets('can mark single read by tapping', (tester) async {
      when(mockRepo.watchNotifications('user_123')).thenAnswer(
        (_) => Stream.value([
          {
            'id': 'n1',
            'title': 'T1',
            'body': 'B1',
            Fields.type: 't',
            Fields.isRead: false,
            Fields.createdAt: DateTime(2026, 3, 1),
          },
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('T1'));
      await tester.pump();

      verify(mockRepo.markRead('user_123', 'n1')).called(1);
    });
  });
}
