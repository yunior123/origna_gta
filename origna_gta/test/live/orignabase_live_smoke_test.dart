import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show Collections, Fields, ProductLifecycleStatusValues;
import 'package:origna_gta/utils/env_config.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBase live smoke', () {
    late ProviderContainer container;
    late OrignaBase ob;

    setUpAll(() async {
      final env = EnvConfig();
      expect(
        env.orignabaseUrl,
        isNotEmpty,
        reason: 'ORIGNABASE_URL dart-define should point tests at a live server.',
      );

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() {
      container.dispose();
    });

    test(
      'app provider can authenticate and search indexed products',
      () async {
        Map<String, dynamic> result = {};
        for (var attempt = 0; attempt < 20; attempt++) {
          try {
            result = await ob.search(
              Collections.products,
              'product',
              limit: 5,
              filter:
                  '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
            );
          } on OrignaBaseException {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            continue;
          }
          final hits = (result['hits'] as List?) ?? const [];
          if (hits.isNotEmpty) {
            for (final hit in hits) {
              expect(hit, isA<Map<String, dynamic>>());
              expect(
                (hit as Map<String, dynamic>).containsKey('id'),
                isTrue,
                reason: 'Search hit must contain id field (Meilisearch objectId)',
              );
            }
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }

        fail('Expected at least one active indexed product in dev, got $result');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
