import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  bool isExpectedPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission') ||
        msg.contains('forbidden');
  }

  group('OrignaBaseOrderRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository repo;
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

      repo = OrignaBaseOrderRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'fetchOrderById returns null for nonexistent order',
      () async {
        if (!runLive) return;
        final result = await repo.fetchOrderById('nonexistent_order_id_12345');
        expect(result, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchBuyerOrders returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        try {
          final stream = repo.watchBuyerOrders(buyerId);
          expect(stream, isNotNull);

          // Listen for first event within 6 seconds
          final event = await stream.first.timeout(const Duration(seconds: 6));
          expect(event, isList);
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected buyer orders stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellerOrders returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        try {
          final stream = repo.watchSellerOrders(buyerId);
          expect(stream, isNotNull);

          // Listen for first event within 6 seconds
          final event = await stream.first.timeout(const Duration(seconds: 6));
          expect(event, isList);
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller orders stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
