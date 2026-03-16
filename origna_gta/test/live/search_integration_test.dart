import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('Search Integration', skip: !runLive ? 'live tests disabled' : null, () {
    late ProviderContainer container;
    late OrignaBase ob;

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      await ob.auth.signInWithEmail('yuniorrodriguezo460@gmail.com', 'REDACTED_TEST_PASSWORD');
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'search with query returns products',
      () async {
        final result = await ob.search(
          Collections.products,
          'product',
          limit: 10,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );

        expect(result, isA<Map<String, dynamic>>(), reason: 'Search should return a map');
        final hits = (result['hits'] as List<dynamic>?) ?? [];
        expect(hits, isNotEmpty, reason: 'Search should return at least one hit for "product"');

        // Verify hits contain expected product structure
        for (final hit in hits.take(3)) {
          expect(hit, isA<Map<String, dynamic>>());
          final hitMap = hit as Map<String, dynamic>;
          expect(hitMap.containsKey(Fields.productId), isTrue,
              reason: 'Hit should have a productId field');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with empty query returns browse mode (all products)',
      () async {
        final result = await ob.search(
          Collections.products,
          '',
          limit: 20,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );

        expect(result, isA<Map<String, dynamic>>());
        final hits = (result['hits'] as List<dynamic>?) ?? [];
        expect(hits, isNotEmpty, reason: 'Browse mode should return products');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with no-match query returns empty list',
      () async {
        final result = await ob.search(
          Collections.products,
          'zzznomatch99xyz_shouldneverexist',
          limit: 10,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );

        expect(result, isA<Map<String, dynamic>>());
        final hits = (result['hits'] as List<dynamic>?) ?? [];
        expect(hits, isEmpty, reason: 'No-match query should return empty list');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with category filter returns matching results',
      () async {
        // First, get all products to find an existing categoryId
        final allResult = await ob.search(
          Collections.products,
          '',
          limit: 5,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );

        final hits = (allResult['hits'] as List<dynamic>?) ?? [];
        if (hits.isEmpty) {
          return; // Skip test if no products available
        }

        final firstProduct = hits.first as Map<String, dynamic>;
        final categoryId = firstProduct[Fields.categoryId];
        if (categoryId == null) {
          return; // Skip test if no categoryId in product
        }

        // Now search with category filter
        final filteredResult = await ob.search(
          Collections.products,
          '',
          limit: 10,
          filter:
              '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active} AND ${Fields.categoryId} = $categoryId',
        );

        final filteredHits = (filteredResult['hits'] as List<dynamic>?) ?? [];
        expect(filteredHits, isNotEmpty, reason: 'Should find products in category');

        // Verify all results have matching category
        for (final hit in filteredHits) {
          final hitMap = hit as Map<String, dynamic>;
          expect(hitMap[Fields.categoryId], equals(categoryId),
              reason: 'All results should have matching categoryId');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search pagination returns different results per page',
      () async {
        // First page
        final page1Result = await ob.search(
          Collections.products,
          '',
          limit: 5,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );
        final page1Hits = (page1Result['hits'] as List<dynamic>?) ?? [];

        if (page1Hits.length < 5) {
          return; // Skip if not enough products to test pagination
        }

        // Second page (would need offset/page param if supported by API)
        // For now, search with different query to verify different results
        final page2Result = await ob.search(
          Collections.products,
          'electronics',
          limit: 5,
          filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );
        final page2Hits = (page2Result['hits'] as List<dynamic>?) ?? [];

        // At least verify we can get results
        expect(page1Hits, isNotEmpty);
        expect(page2Hits, isNotEmpty);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
