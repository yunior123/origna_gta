import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBase Return Requests Live Tests', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository repo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      final authState = await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);

      repo = OrignaBaseOrderRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'fetchReturnRequests returns list for an order',
      () async {
        if (!runLive) return;
        final returns = await repo.fetchReturnRequests('seed_order_001');
        expect(returns, isA<List<Object?>>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('OrignaBase Orders Live Tests', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository repo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      final authState = await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);

      repo = OrignaBaseOrderRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test('watchBuyerOrders returns stream of buyer orders', () async {
      if (!runLive) return;
      const userId = 'users:e8baqega99d6c1x8cf9n';
      final stream = repo.watchBuyerOrders(userId);
      expect(stream, isA<Stream<Object?>>());
    }, skip: !runLive);

    test(
      'fetchOrderById returns order details',
      () async {
        if (!runLive) return;
        final order = await repo.fetchOrderById('orders:seed_order_001');
        expect(order, isNotNull);
        expect(order!.orderId, contains('seed_order_001'));
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
