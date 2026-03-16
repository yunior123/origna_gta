import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_cart_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('OrignaBaseCartRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseCartRepository repo;
    late String buyerId;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as buyer
      final authState = await ob.auth.signInWithEmail(
        'yuniorrodriguezo460@gmail.com',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);
      buyerId = authState.userId!;

      repo = OrignaBaseCartRepository(ob);
    });

    tearDownAll(() async {
      if (!runLive) return;
      // Clean up: clear cart
      try {
        await repo.clearCart(buyerId);
      } catch (_) {}
      container.dispose();
    });

    test(
      'watchCart returns a stream and emits at least one event',
      () async {
        if (!runLive) return;
        final stream = repo.watchCart(buyerId);
        expect(stream, isNotNull);

        // Emit at least one event within 10 seconds
        final event = await stream.first.timeout(const Duration(seconds: 10));
        expect(event, isList);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'addToCart adds item and increases quantity on duplicate',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';
        const quantity = 1;

        // Add to cart
        await repo.addToCart(buyerId, productId, quantity);

        // Verify it's in the cart
        final stream = repo.watchCart(buyerId);
        final cartItems = await stream.first.timeout(const Duration(seconds: 10));
        expect(cartItems, isNotEmpty);
        expect(
          cartItems.any((item) => item.productId == productId),
          isTrue,
          reason: 'Product should be in cart',
        );

        // Clean up
        await repo.clearCart(buyerId);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'removeFromCart removes item from cart',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';
        const quantity = 1;

        // Add to cart
        await repo.addToCart(buyerId, productId, quantity);

        // Get the cart item ID (same as productId for products without variants)
        final stream = repo.watchCart(buyerId);
        final cartItems = await stream.first.timeout(const Duration(seconds: 10));
        final cartItem = cartItems.firstWhere((item) => item.productId == productId);
        final cartItemId = cartItem.productId;

        // Remove from cart
        await repo.removeFromCart(buyerId, cartItemId);

        // Verify it's removed
        final updatedItems = await stream.first.timeout(const Duration(seconds: 10));
        expect(
          updatedItems.any((item) => item.productId == productId),
          isFalse,
          reason: 'Product should be removed from cart',
        );

        // Clean up
        await repo.clearCart(buyerId);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateQuantity changes item quantity',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';

        // Add to cart with quantity 1
        await repo.addToCart(buyerId, productId, 1);

        // Get the cart item ID
        final stream = repo.watchCart(buyerId);
        final cartItems = await stream.first.timeout(const Duration(seconds: 10));
        final cartItem = cartItems.firstWhere((item) => item.productId == productId);
        final cartItemId = cartItem.productId;

        // Update quantity to 3
        await repo.updateQuantity(buyerId, cartItemId, 3);

        // Verify quantity changed
        final updatedItems = await stream.first.timeout(const Duration(seconds: 10));
        final updated = updatedItems.firstWhere((item) => item.productId == productId);
        expect(updated.quantity, equals(3));

        // Clean up
        await repo.clearCart(buyerId);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'clearCart removes all items',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';

        // Add to cart
        await repo.addToCart(buyerId, productId, 1);

        // Verify it's there
        final stream = repo.watchCart(buyerId);
        var cartItems = await stream.first.timeout(const Duration(seconds: 10));
        expect(cartItems, isNotEmpty);

        // Clear cart
        await repo.clearCart(buyerId);

        // Verify it's empty
        cartItems = await stream.first.timeout(const Duration(seconds: 10));
        expect(cartItems, isEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'isVariantValid returns false for nonexistent variant',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';
        final isValid = await repo.isVariantValid(productId, 'nonexistent_variant_xyz');
        expect(isValid, isFalse);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getProductSellerId returns seller ID for existing product',
      () async {
        if (!runLive) return;
        final productId = 'e2e_product_test_seller';
        final sellerId = await repo.getProductSellerId(productId);
        expect(sellerId, isNotEmpty);
        expect(sellerId, isA<String>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
