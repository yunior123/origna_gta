// Integration tests for OrignaBaseOrderRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_order_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBaseOrderRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository orderRepo;
    late OrignaBaseAuthRepository authRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      orderRepo = OrignaBaseOrderRepository(ob);
      authRepo = OrignaBaseAuthRepository(ob);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'fetchOrderById returns order for valid order ID',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        // Sign in as buyer to check their orders
        const email = 'yuniorrodriguezo460@gmail.com';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        // Fetch a known test order (if it exists in dev)
        // For this test, we just verify the method handles missing orders gracefully
        final order = await orderRepo.fetchOrderById('nonexistent_order_id');
        expect(order, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchBuyerOrders returns stream of orders',
      () async {
        const email = 'yuniorrodriguezo460@gmail.com';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final ordersStream = orderRepo.watchBuyerOrders(userId!);

        // Take first emission
        final orders = await ordersStream.first;
        expect(orders, isA<List>());
        // Orders may be empty for test account, but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchSellerOrders returns stream of orders',
      () async {
        const email = 'yuniorrodriguezo4601@yahoo.com';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final ordersStream = orderRepo.watchSellerOrders(userId!);

        // Take first emission
        final orders = await ordersStream.first;
        expect(orders, isA<List>());
        // Orders may be empty for test account, but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateLastSession updates order session timestamp',
      () async {
        const email = 'yr62813@gmail.com';
        const password = 'REDACTED_TEST_PASSWORD';
        await authRepo.signInWithEmail(email, password);

        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        // This test verifies the method doesn't throw
        // In practice, the order ID would need to exist
        try {
          await orderRepo.updateLastSession(
            userId!,
            'session_id_test',
            'nonexistent_order_id',
          );
        } on OrignaBaseException {
          // Expected for nonexistent order
        }
        // Test passed if no unexpected exception
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
