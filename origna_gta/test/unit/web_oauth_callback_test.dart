import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/origna_app.dart';

void main() {
  group('extractWebOAuthCallbackParams', () {
    test('reads OAuth tokens from fragment callback', () {
      final uri = Uri.parse(
        'https://orignagta.ca/login#ob_access_token=abc&ob_refresh_token=def&ob_provider=google',
      );

      final params = extractWebOAuthCallbackParams(uri);

      expect(params['ob_access_token'], 'abc');
      expect(params['ob_refresh_token'], 'def');
    });

    test('falls back to query params when fragment is absent', () {
      final uri = Uri.parse(
        'https://orignagta.ca/login?ob_access_token=abc&ob_refresh_token=def',
      );

      final params = extractWebOAuthCallbackParams(uri);

      expect(params['ob_access_token'], 'abc');
      expect(params['ob_refresh_token'], 'def');
    });
  });

  group('cleanedWebOAuthCallbackUrl', () {
    test('removes OAuth callback params and fragment', () {
      final uri = Uri.parse(
        'https://orignagta.ca/login?ts=123&ob_access_token=abc#ob_access_token=abc&ob_refresh_token=def',
      );

      expect(
        cleanedWebOAuthCallbackUrl(uri),
        'https://orignagta.ca/login?ts=123',
      );
    });
  });

  group('resolvedWebOAuthCallbackRoute', () {
    test('preserves protected route callback target', () {
      final uri = Uri.parse(
        'https://orignagta.ca/orders?tab=active#ob_access_token=abc&ob_refresh_token=def',
      );

      expect(resolvedWebOAuthCallbackRoute(uri), '/orders?tab=active');
    });

    test('uses login redirect query when callback lands on login route', () {
      final uri = Uri.parse(
        'https://orignagta.ca/login?redirect=%2Fcart%3Fcoupon%3DSAVE10#ob_access_token=abc',
      );

      expect(resolvedWebOAuthCallbackRoute(uri), '/cart?coupon=SAVE10');
    });

    test('falls back to home when login callback has no redirect target', () {
      final uri = Uri.parse(
        'https://orignagta.ca/login#ob_access_token=abc&ob_refresh_token=def',
      );

      expect(resolvedWebOAuthCallbackRoute(uri), '/');
    });
  });
}
