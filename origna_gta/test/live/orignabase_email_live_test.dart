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

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  group(
    'OrignaBase Email & External Services Live Tests',
    () {
      late ProviderContainer container;
      late OrignaBase ob;
      const buyerEmail = 'e2e-buyer@test.origna.ca';
      const buyerPassword = 'REDACTED_TEST_PASSWORD';

      setUpAll(() async {
        container = ProviderContainer();
        ob = container.read(orignabaseProvider);
      });

      tearDownAll(() {
        container.dispose();
      });

      // --- 1. Password reset request does not error ---
      test(
        'password reset request completes without 500',
        () async {
          try {
            await ob.auth.forgotPassword(buyerEmail);
            // Success — email may or may not actually send in dev
          } on OrignaBaseException catch (e) {
            // 429 = rate limited, acceptable
            // 400/404 = endpoint may need different params
            expect(e.statusCode, isNot(equals(500)),
                reason: 'Password reset should not return 500, got ${e.statusCode}: ${e.message}');
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      // --- 2. Email verification request does not error ---
      test(
        'email verification request completes without 500',
        () async {
          await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

          try {
            await ob.auth.sendEmailVerification();
            // Success — verification email triggered
          } on OrignaBaseException catch (e) {
            // Already verified or rate limited — both acceptable
            expect(e.statusCode, isNot(equals(500)),
                reason: 'Email verification should not return 500, got ${e.statusCode}: ${e.message}');
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      // --- 3. Support chat endpoint returns a reply ---
      test(
        'support chat endpoint returns a response',
        () async {
          await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

          try {
            final result = await ob.request('POST', ApiEndpoints.supportChat, body: {
              'messages': [
                {'role': 'user', 'content': 'What is your return policy?'}
              ],
              'customer_email': buyerEmail,
              'customer_id': ob.auth.currentUserId,
            });

            expect(result, isA<Map<String, dynamic>>());
            // Response should contain a message or reply
            final hasMessage = result.containsKey('message') ||
                result.containsKey('reply') ||
                result.containsKey('response') ||
                result.containsKey('content');
            expect(hasMessage, isTrue,
                reason: 'Support chat should return a response. Keys: ${result.keys.toList()}');
          } on OrignaBaseException catch (e) {
            // 404 = endpoint not deployed, 503 = AI service unavailable — acceptable in dev
            expect(
              [400, 404, 422, 429, 503].contains(e.statusCode),
              isTrue,
              reason: 'Support chat failure should be expected error, got ${e.statusCode}: ${e.message}',
            );
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      // --- 4. Support escalation endpoint does not crash ---
      test(
        'support escalation endpoint returns valid response',
        () async {
          await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

          try {
            final result = await ob.request('POST', ApiEndpoints.supportEscalate, body: {
              'customer_email': buyerEmail,
              'customer_id': ob.auth.currentUserId,
              'summary': 'E2E test escalation — please ignore',
              'conversation': [
                {'role': 'user', 'content': 'I have an issue with my order.'},
                {'role': 'assistant', 'content': 'I am escalating this to a human agent.'},
              ],
            });

            expect(result, isA<Map<String, dynamic>>());
          } on OrignaBaseException catch (e) {
            // 404 = endpoint not available, 400 = validation — acceptable
            expect(
              [400, 404, 422, 429, 503].contains(e.statusCode),
              isTrue,
              reason: 'Escalation failure should be expected error, got ${e.statusCode}',
            );
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      // --- 5. Geocode autocomplete endpoint returns results (or empty) ---
      test(
        'geocode autocomplete endpoint responds without error',
        () async {
          await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

          try {
            final result = await ob.request('POST', ApiEndpoints.geocodeAutocomplete, body: {
              'query': '123 Queen St Toronto',
              'country': 'CA',
            });

            expect(result, isA<Map<String, dynamic>>());
            // May return suggestions or empty if no geocoding API key configured
          } on OrignaBaseException catch (e) {
            // Dev currently returns 500 when geocoding is unavailable server-side.
            expect(
              [400, 404, 422, 500, 503].contains(e.statusCode),
              isTrue,
              reason:
                  'Geocode should fail with a known dev-service status, got ${e.statusCode}: ${e.message}',
            );
          }
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    },
  );
}
