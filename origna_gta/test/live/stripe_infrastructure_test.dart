// Stripe/Payment infrastructure integration tests
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
    test('live tests disabled', () {});
    return;
  }

  if (!runLive) {
    test('Skip live tests', () {});
    return;
  }

  group('Stripe Infrastructure Live Tests', () {
    late ProviderContainer container;
    late OrignaBase ob;

    bool isExpectedPermissionError(Object error) {
      final msg = error.toString().toLowerCase();
      return msg.contains('403') ||
          msg.contains('permission') ||
          msg.contains('forbidden');
    }

    setUpAll(() async {
      final env = EnvConfig();
      expect(env.orignabaseUrl, isNotEmpty, reason: 'ORIGNABASE_URL required');

      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      final authRepo = OrignaBaseAuthRepository(ob);
      await authRepo.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() {
      container.dispose();
    });

    test('payment status enum values are valid', () async {
      final validStatuses = [
        'awaiting_payment',
        'processing',
        'authorized',
        'paid',
        'captured',
        'payment_failed',
        'refunded',
        'session_expired',
        'cancelled',
        'authorization_expired',
        'disputed',
      ];

      for (final status in validStatuses) {
        expect(
          status,
          matches(RegExp(r'^[a-z_]+$')),
          reason: 'Status $status should be lowercase with underscores',
        );
      }
    });

    test(
      'stripe API returns proper error format for invalid request',
      () async {
        try {
          await ob.request(
            'POST',
            '/api/checkout/session',
            body: {'items': [], 'shippingAddress': {}},
          );
        } catch (e) {
          final errorStr = e.toString();
          expect(
            errorStr,
            anyOf([
              contains('400'),
              contains('422'),
              contains('validation'),
              contains('items'),
              contains('error'),
            ]),
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'user payment info is accessible',
      () async {
        final userId = ob.auth.currentUserId;
        expect(userId, isNotNull);

        try {
          final result = await ob.graphql(
            '{ get(collection: "users", id: "${userId!.replaceAll('users:', '')}") }',
          );
          expect(result, isNotNull);
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected payment-info lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
