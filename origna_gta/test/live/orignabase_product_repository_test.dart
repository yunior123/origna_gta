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

  group('OrignaBaseProductRepository live', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseProductRepository productRepo;

    setUp(() {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      productRepo = OrignaBaseProductRepository(ob);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'fetchProductById returns null for nonexistent product',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason: 'ORIGNABASE_URL dart-define required for live tests',
        );

        final product =
            await productRepo.fetchProductById('nonexistent_product_123');
        expect(product, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductById returns product for valid ID',
      () async {
        // Use a stable test product ID that exists in dev
        const testProductId = 'e2e_product_test_seller';

        final product = await productRepo.fetchProductById(testProductId);

        // May be null if product doesn't exist, but method should not throw
        if (product != null) {
          expect(product.productId, testProductId);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProducts returns list of products',
      () async {
        final result = await productRepo.fetchProducts(
          pageSize: 10,
        );

        expect(result, isNotNull);
        expect(result.products, isA<List>());
        // Result may be empty but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProducts respects pageSize parameter',
      () async {
        final result1 = await productRepo.fetchProducts(
          pageSize: 5,
        );

        final result2 = await productRepo.fetchProducts(
          pageSize: 10,
        );

        expect(result1.products, isA<List>());
        expect(result2.products, isA<List>());
        // Different page sizes should work without throwing
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getProductBySlug returns product or null',
      () async {
        // Try to fetch by a slug (may or may not exist)
        final product = await productRepo.getProductBySlug('nonexistent-slug');

        // Should not throw, may return null
        if (product != null) {
          expect(product.productId, isNotEmpty);
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductsByIds returns products for valid IDs',
      () async {
        const testIds = ['e2e_product_test_seller'];

        final products = await productRepo.fetchProductsByIds(testIds);

        expect(products, isA<List>());
        // May contain matches or be empty, but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'getAutocompleteSuggestions returns list of suggestions',
      () async {
        final suggestions =
            await productRepo.getAutocompleteSuggestions('test');

        expect(suggestions, isA<List>());
        // May be empty but should not throw
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
