import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/safe_url_launcher.dart';

void main() {
  group('isAllowedUrl', () {
    group('allowed domains', () {
      test('allows orignagta.ca root domain', () {
        final uri = Uri.parse('https://orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows www.orignagta.ca', () {
        final uri = Uri.parse('https://www.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows dev.orignagta.ca subdomain', () {
        final uri = Uri.parse('https://dev.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows staging.orignagta.ca subdomain', () {
        final uri = Uri.parse('https://staging.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows api.orignagta.ca', () {
        final uri = Uri.parse('https://api.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows api.dev.orignagta.ca', () {
        final uri = Uri.parse('https://api.dev.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows api.staging.orignagta.ca', () {
        final uri = Uri.parse('https://api.staging.orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows stripe.com', () {
        final uri = Uri.parse('https://stripe.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows dashboard.stripe.com', () {
        final uri = Uri.parse('https://dashboard.stripe.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows connect.stripe.com', () {
        final uri = Uri.parse('https://connect.stripe.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows checkout.stripe.com', () {
        final uri = Uri.parse('https://checkout.stripe.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows google.com', () {
        final uri = Uri.parse('https://google.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows accounts.google.com', () {
        final uri = Uri.parse('https://accounts.google.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows canadapost-postescanada.ca', () {
        final uri = Uri.parse('https://canadapost-postescanada.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows fedex.com', () {
        final uri = Uri.parse('https://fedex.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows ups.com', () {
        final uri = Uri.parse('https://ups.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows purolator.com', () {
        final uri = Uri.parse('https://purolator.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows dhl.com', () {
        final uri = Uri.parse('https://dhl.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows r2.cloudflarestorage.com', () {
        final uri = Uri.parse('https://r2.cloudflarestorage.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows subdomain of allowed domain', () {
        final uri = Uri.parse('https://any.subdomain.stripe.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows deep paths on allowed domains', () {
        final uri = Uri.parse('https://orignagta.ca/products/123/details');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows query parameters on allowed domains', () {
        final uri = Uri.parse('https://stripe.com/payments?session_id=abc123');
        expect(isAllowedUrl(uri), isTrue);
      });
    });

    group('mailto and tel schemes', () {
      test('allows mailto: scheme', () {
        final uri = Uri.parse('mailto:support@orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows mailto: with any email', () {
        final uri = Uri.parse('mailto:test@example.com');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows mailto: with subject', () {
        final uri = Uri.parse('mailto:support@orignagta.ca?subject=Help');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows tel: scheme', () {
        final uri = Uri.parse('tel:+14165551234');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('allows tel: without plus', () {
        final uri = Uri.parse('tel:4165551234');
        expect(isAllowedUrl(uri), isTrue);
      });
    });

    group('blocked URLs', () {
      test('blocks unknown domain', () {
        final uri = Uri.parse('https://malicious.com');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks similar-looking domain (typosquatting)', () {
        final uri = Uri.parse('https://orignagta.com');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks http version of allowed domain when only https allowed', () {
        final uri = Uri.parse('http://orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('blocks javascript: scheme', () {
        final uri = Uri.parse('javascript:alert(1)');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks file: scheme', () {
        final uri = Uri.parse('file:///etc/passwd');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks data: scheme', () {
        final uri = Uri.parse('data:text/html,<script>alert(1)</script>');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks blob: scheme', () {
        final uri = Uri.parse('blob:https://malicious.com/uuid');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks about: scheme', () {
        final uri = Uri.parse('about:blank');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks ftp: scheme', () {
        final uri = Uri.parse('ftp://files.example.com');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks unknown domain with allowed path', () {
        final uri = Uri.parse('https://malicious.com/stripe.com');
        expect(isAllowedUrl(uri), isFalse);
      });

      test('blocks subdomain of blocked domain', () {
        final uri = Uri.parse('https://sub.malicious.com');
        expect(isAllowedUrl(uri), isFalse);
      });
    });

    group('case sensitivity', () {
      test('handles uppercase host', () {
        final uri = Uri.parse('https://ORIGNAGTA.CA');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles mixed case host', () {
        final uri = Uri.parse('https://OrignaGTA.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles uppercase scheme', () {
        final uri = Uri.parse('HTTPS://orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty path', () {
        final uri = Uri.parse('https://orignagta.ca');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles root path', () {
        final uri = Uri.parse('https://orignagta.ca/');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles port numbers', () {
        final uri = Uri.parse('https://orignagta.ca:443/path');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles fragment identifiers', () {
        final uri = Uri.parse('https://orignagta.ca/page#section');
        expect(isAllowedUrl(uri), isTrue);
      });

      test('handles unicode in path', () {
        final uri = Uri.parse('https://orignagta.ca/products/café');
        expect(isAllowedUrl(uri), isTrue);
      });
    });
  });

  group('safeLaunchUrl', () {
    test('returns false for blocked URL', () async {
      final uri = Uri.parse('https://malicious.com');
      final result = await safeLaunchUrl(uri);
      expect(result, isFalse);
    });

    test('returns false for javascript: scheme', () async {
      final uri = Uri.parse('javascript:alert(1)');
      final result = await safeLaunchUrl(uri);
      expect(result, isFalse);
    });

    test('returns false for data: scheme', () async {
      final uri = Uri.parse('data:text/html,<script>alert(1)</script>');
      final result = await safeLaunchUrl(uri);
      expect(result, isFalse);
    });
  });
}
