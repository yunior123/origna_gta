import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('OrignaBaseProductRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseProductRepository repo;

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

      repo = OrignaBaseProductRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'fetchProductById returns product with correct fields for stable test product',
      () async {
        if (!runLive) return;
        final product = await repo.fetchProductById('e2e_product_test_seller');
        expect(product, isNotNull);
        expect(product!.productId, equals('e2e_product_test_seller'));
        expect(product.priceCents, isPositive);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductById returns null for nonexistent product',
      () async {
        if (!runLive) return;
        final product = await repo.fetchProductById('nonexistent_product_xyz');
        expect(product, isNull);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProducts returns ProductQueryResult with list of products',
      () async {
        if (!runLive) return;
        final result = await repo.fetchProducts(
          searchQuery: 'test',
          pageSize: 10,
          sortOption: SortOption.newest,
        );
        expect(result, isNotNull);
        expect(result.products, isList);
        expect(result.lastDocumentId, isA<String?>());
        expect(result.hasMore, isA<bool>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductsByIds returns list of products',
      () async {
        if (!runLive) return;
        final ids = ['e2e_product_test_seller'];
        final products = await repo.fetchProductsByIds(ids);
        expect(products, isList);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'fetchProductsByIds returns empty list for empty input',
      () async {
        if (!runLive) return;
        final products = await repo.fetchProductsByIds([]);
        expect(products, isEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchFavorites returns a stream',
      () async {
        if (!runLive) return;
        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        final stream = repo.watchFavorites(userId!);
        expect(stream, isNotNull);

        // Emit at least one event
        final event = await stream.first.timeout(const Duration(seconds: 10));
        expect(event, isA<Set<String>>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'watchUnansweredQuestionsCount returns a stream',
      () async {
        if (!runLive) return;
        final sellerId = ob.auth.currentUserId;
        expect(sellerId, isNotNull);

        final stream = repo.watchUnansweredQuestionsCount(sellerId!);
        expect(stream, isNotNull);

        // Emit at least one event
        final event = await stream.first.timeout(const Duration(seconds: 10));
        expect(event, isA<int>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'generateProductId returns non-empty string',
      () async {
        if (!runLive) return;
        final id = repo.generateProductId();
        expect(id, isNotEmpty);
        expect(id, isA<String>());
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
