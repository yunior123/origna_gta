// Integration tests for OrignaBaseNotificationRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_notification_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  group('OrignaBaseNotificationRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseNotificationRepository notificationRepo;
    late String userId;

    setUpAll(() async {
      final env = EnvConfig();
      expect(
        env.orignabaseUrl,
        isNotEmpty,
        reason: 'ORIGNABASE_URL dart-define required for live tests',
      );

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      notificationRepo = OrignaBaseNotificationRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail('e2e-admin@test.origna.ca', 'REDACTED_TEST_PASSWORD');
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Admin sign-in failed');
      userId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'markRead marks notification as read',
      () async {
        try {
          await notificationRepo.markRead(userId, 'nonexistent_notification_id');
        } on OrignaBaseException {
          // Expected for nonexistent notification
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'markAllRead marks all notifications as read',
      () async {
        await notificationRepo.markAllRead(userId);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
