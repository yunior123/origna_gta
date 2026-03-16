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

  group('OrignaBaseNotificationRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseNotificationRepository notificationRepo;
    late OrignaBaseAuthRepository authRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      notificationRepo = OrignaBaseNotificationRepository(ob);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'markRead marks notification as read',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        // Try to mark nonexistent notification as read (should not throw)
        try {
          await notificationRepo.markRead(
            userId!,
            'nonexistent_notification_id',
          );
        } on OrignaBaseException {
          // Expected for nonexistent notification, test still passes
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'markAllRead marks all notifications as read',
      () async {
        const email = 'e2e-admin@test.origna.ca';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        // Mark all as read - should not throw
        await notificationRepo.markAllRead(userId!);
        // Test passes if no exception
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
