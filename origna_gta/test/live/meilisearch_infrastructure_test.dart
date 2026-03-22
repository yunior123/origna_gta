// Meilisearch/Search infrastructure integration tests
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('Skip live tests', () {}, skip: 'live tests disabled');
    return;
  }

  group('Meilisearch Infrastructure Live Tests', () {
    late ProviderContainer container;
    late OrignaBase ob;

    setUpAll(() async {
      final env = EnvConfig();
      expect(env.orignabaseUrl, isNotEmpty, reason: 'ORIGNABASE_URL required');

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      final authRepo = OrignaBaseAuthRepository(ob);
      await authRepo.signInWithEmail(
        'e2e-seller@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'search returns products for generic query',
      () async {
        final result = await ob.search('products', 'product');
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        expect(
          hits,
          isNotEmpty,
          reason: 'Search should return at least one product',
        );
        expect(result['estimatedTotalHits'], greaterThan(0));
        expect(result['processingTimeMs'], isA<int>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with empty query returns browse mode',
      () async {
        final result = await ob.search('products', '');
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        expect(hits, isNotEmpty, reason: 'Browse mode should show products');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with non-matching query returns empty',
      () async {
        final result = await ob.search('products', 'xyznonexistent123456789');
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        expect(hits, isEmpty, reason: 'Non-matching query should return empty');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search respects limit parameter',
      () async {
        final result = await ob.search('products', 'product', limit: 3);
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        expect(hits.length, lessThanOrEqualTo(3));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search results contain required fields',
      () async {
        final result = await ob.search('products', 'product');
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        if (hits.isNotEmpty) {
          final firstHit = hits.first as Map<String, dynamic>;
          expect(
            firstHit.containsKey('name'),
            isTrue,
            reason: 'Product should have name field',
          );
          expect(
            firstHit.containsKey('priceCents'),
            isTrue,
            reason: 'Product should have priceCents field',
          );
          expect(
            firstHit.containsKey('sellerId'),
            isTrue,
            reason: 'Product should have sellerId field',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search with filter returns filtered results',
      () async {
        final result = await ob.search(
          'products',
          'product',
          filter: 'lifecycleStatus = active',
        );
        final hits = (result['hits'] as List<dynamic>?) ?? [];

        expect(
          hits,
          isNotEmpty,
          reason: 'Filtered search should return results',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'search pagination returns different results per page',
      () async {
        final page1 = await ob.search('products', '', limit: 5);
        final page1Hits = (page1['hits'] as List<dynamic>?) ?? [];

        if (page1Hits.length >= 5) {
          final page2 = await ob.search('products', '', limit: 5, offset: 5);
          final page2Hits = (page2['hits'] as List<dynamic>?) ?? [];

          if (page2Hits.isNotEmpty) {
            final page1Ids = page1Hits.map((h) => (h as Map)['id']).toSet();
            final page2Ids = page2Hits.map((h) => (h as Map)['id']).toSet();

            expect(
              page1Ids.intersection(page2Ids).isEmpty,
              isTrue,
              reason: 'Different pages should have different products',
            );
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
