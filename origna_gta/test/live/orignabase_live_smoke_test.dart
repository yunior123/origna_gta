import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:uuid/uuid.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('OrignaBase live smoke', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'app provider can authenticate and search indexed products',
      () async {
        final env = EnvConfig();
        expect(
          env.orignabaseUrl,
          isNotEmpty,
          reason:
              'ORIGNABASE_URL dart-define should point tests at a live server.',
        );

        final ob = container.read(orignabaseProvider);
        final marker = const Uuid().v4();
        final email = 'app_live_$marker@example.com';

        await ob.auth.register(email, 'SecurePass123!');

        await ob.collection('products').add({
          'title': 'Widget $marker',
          'description': 'Search marker $marker',
          'status': 'active',
        });

        Map<String, dynamic> result = {};
        for (var attempt = 0; attempt < 20; attempt++) {
          try {
            result = await ob.search('products', marker, limit: 5);
          } on OrignaBaseException {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            continue;
          }
          final hits = (result['hits'] as List?) ?? const [];
          if (hits.isNotEmpty) {
            expect(
              hits.any((hit) => hit.toString().contains(marker)),
              isTrue,
              reason: 'Expected a search hit containing the indexed marker.',
            );
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }

        fail('Expected indexed search hits for marker $marker, got $result');
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
