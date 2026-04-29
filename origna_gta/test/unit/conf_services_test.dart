import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/conf_services.dart';

void main() {
  group('ConfigService', () {
    test('singleton returns same instance', () {
      final a = ConfigService();
      final b = ConfigService();
      expect(identical(a, b), isTrue);
    });

    test('properties delegate to OrignaBaseConfigService', () {
      final service = ConfigService();

      expect(service.geoapifyKey, isA<String>());
      expect(service.imageBaseUrl, isA<String>());
      expect(service.glitchtipDsn, isA<String>());
      expect(service.sentryDnsKey, isA<String>());
      expect(service.googleWebClientId, isA<String>());
    });

    test('initialize completes without error', () async {
      final service = ConfigService();
      await service.initialize();
    });

    test('initialize with skipFetch completes without error', () async {
      final service = ConfigService();
      await service.initialize(skipFetch: true);
    });
  });
}
