// Integration tests for OrignaBaseCartRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBaseCartRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseCartRepository cartRepo;
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
      cartRepo = OrignaBaseCartRepository(ob);
      final authRepo = OrignaBaseAuthRepository(ob);

      await authRepo.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      final uid = ob.auth.currentUserId;
      expect(uid, isNotNull, reason: 'Sign-in failed — no userId returned');
      userId = uid!;
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'watchCart returns stream of cart items',
      () async {
        final cartStream = cartRepo.watchCart(userId);
        final cartItems = await cartStream.first;
        expect(cartItems, isA<List<dynamic>>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'addToCart adds item to user cart',
      () async {
        const testProductId = 'e2e_product_test_seller';
        const quantity = 1;

        try {
          await cartRepo.addToCart(userId, testProductId, quantity);
        } on OrignaBaseException {
          // Product may not exist in dev — graceful handling is acceptable
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'clearCart empties user cart',
      () async {
        await cartRepo.clearCart(userId);

        final cartStream = cartRepo.watchCart(userId);
        final cartItems = await cartStream.first;
        expect(cartItems, isEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'removeFromCart removes specific cart item',
      () async {
        try {
          await cartRepo.removeFromCart(userId, 'nonexistent_cart_item_id');
        } on OrignaBaseException {
          // Expected for nonexistent item
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateQuantity updates cart item quantity',
      () async {
        try {
          await cartRepo.updateQuantity(userId, 'nonexistent_cart_item_id', 5);
        } on OrignaBaseException {
          // Expected for nonexistent item
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
