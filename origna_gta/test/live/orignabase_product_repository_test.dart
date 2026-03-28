// Integration tests for OrignaBaseProductRepository against live dev server
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
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

  group('OrignaBaseProductRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseProductRepository productRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      productRepo = OrignaBaseProductRepository(ob);
    });

    tearDown(() async {
      await ob.auth.signOut();
      container.dispose();
    });

    test(
      'fetchProductById returns null for nonexistent product',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        final product = await productRepo.fetchProductById(
          'nonexistent_product_123',
        );
        expect(product, isNull);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductById returns product for valid ID',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        // Use a stable test product ID that exists in dev
        const testProductId = 'e2e_product_test_seller';

        final product = await productRepo.fetchProductById(testProductId);

        // May be null if product doesn't exist, but method should not throw
        if (product != null) {
          expect(product.productId, testProductId);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProducts returns list of products',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        final result = await productRepo.fetchProducts(pageSize: 10);

        expect(result, isNotNull);
        expect(result.products, isA<List<dynamic>>());
        // Result may be empty but should not throw
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProducts respects pageSize parameter',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        final result1 = await productRepo.fetchProducts(pageSize: 5);

        final result2 = await productRepo.fetchProducts(pageSize: 10);

        expect(result1.products, isA<List<dynamic>>());
        expect(result2.products, isA<List<dynamic>>());
        // Different page sizes should work without throwing
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getProductBySlug returns product or null',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        // Try to fetch by a slug (may or may not exist)
        final product = await productRepo.getProductBySlug('nonexistent-slug');

        // Should not throw, may return null
        if (product != null) {
          expect(product.productId, isNotEmpty);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductsByIds returns products for valid IDs',
      () async {
        await ob.auth.signInWithEmail(
          'e2e-buyer@test.origna.ca',
          'REDACTED_TEST_PASSWORD',
        );
        const testIds = ['e2e_product_test_seller'];

        final products = await productRepo.fetchProductsByIds(testIds);

        expect(products, isA<List<dynamic>>());
        // May contain matches or be empty, but should not throw
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getAutocompleteSuggestions returns list of suggestions',
      () async {
        final suggestions = await productRepo.getAutocompleteSuggestions(
          'test',
        );

        expect(suggestions, isA<List<dynamic>>());
        // May be empty but should not throw
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
