import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('OrignaBaseNotificationRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseNotificationRepository repo;
    late String buyerId;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as buyer
      final authState = await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);
      buyerId = authState.userId!;

      repo = OrignaBaseNotificationRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'markAllRead completes without error',
      () async {
        if (!runLive) return;
        expect(
          repo.markAllRead(buyerId),
          completes,
          reason: 'markAllRead should complete without throwing',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'markRead completes without error for valid notification ID',
      () async {
        if (!runLive) return;
        // Note: This uses a fake ID — the operation may silently fail on dev
        // if no such notification exists, but should not throw
        expect(
          repo.markRead(buyerId, 'fake_notification_id_12345'),
          completes,
          reason: 'markRead should complete',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
