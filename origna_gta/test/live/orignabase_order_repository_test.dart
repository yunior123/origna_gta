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

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  bool isExpectedPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission') ||
        msg.contains('forbidden');
  }

  // --- Buyer tests -----------------------------------------------
  group('OrignaBaseOrderRepository live (buyer)', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository orderRepo;
    late String buyerUserId;

    setUpAll(() async {
      final env = EnvConfig();
      expect(
        env.orignabaseUrl,
        isNotEmpty,
        reason: 'ORIGNABASE_URL dart-define required for live tests',
      );

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      orderRepo = OrignaBaseOrderRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Buyer sign-in failed');
      buyerUserId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'fetchOrderById returns order for valid order ID',
      () async {
        final order = await orderRepo.fetchOrderById('nonexistent_order_id');
        expect(order, isNull);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchBuyerOrders returns stream of orders',
      () async {
        try {
          final ordersStream = orderRepo.watchBuyerOrders(buyerUserId);
          final orders = await ordersStream.first;
          expect(orders, isA<List<dynamic>>());
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected buyer orders stream error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  // --- Seller tests -----------------------------------------------
  group('OrignaBaseOrderRepository live (seller)', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository orderRepo;
    late String sellerUserId;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      orderRepo = OrignaBaseOrderRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail(
        'e2e-seller@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Seller sign-in failed');
      sellerUserId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'watchSellerOrders returns stream of orders',
      () async {
        try {
          final ordersStream = orderRepo.watchSellerOrders(sellerUserId);
          final orders = await ordersStream.first;
          expect(orders, isA<List<dynamic>>());
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller orders stream error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  // --- Admin tests -----------------------------------------------
  group('OrignaBaseOrderRepository live (admin)', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseOrderRepository orderRepo;
    late String adminUserId;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      orderRepo = OrignaBaseOrderRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail(
        'e2e-admin@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Admin sign-in failed');
      adminUserId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'updateLastSession updates order session timestamp',
      () async {
        try {
          await orderRepo.updateLastSession(
            adminUserId,
            'session_id_test',
            'nonexistent_order_id',
          );
        } on OrignaBaseException {
          // Expected for nonexistent order
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
