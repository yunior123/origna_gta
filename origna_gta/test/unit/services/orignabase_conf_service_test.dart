import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/orignabase_conf_service.dart';
import 'package:orignabase/orignabase.dart';

void main() {
  group('OrignaBaseConfigService', () {
    test('singleton returns same instance', () {
      final a = OrignaBaseConfigService();
      final b = OrignaBaseConfigService();
      expect(identical(a, b), isTrue);
    });

    test('initialize with skipFetch does not call OrignaBase', () async {
      final ob = OrignaBase.initialize(url: 'http://127.0.0.1:0');
      final service = OrignaBaseConfigService();
      await service.initialize(ob, skipFetch: true);

      expect(service.geoapifyKey, isEmpty);
      expect(service.imageBaseUrl, isEmpty);
      expect(service.sentryDnsKey, isEmpty);
      expect(service.googleWebClientId, isEmpty);
    });

    test('properties return empty string when not initialized', () {
      final service = OrignaBaseConfigService();
      expect(service.geoapifyKey, isA<String>());
      expect(service.imageBaseUrl, isA<String>());
      expect(service.sentryDnsKey, isA<String>());
      expect(service.googleWebClientId, isA<String>());
    });

    test('getString returns empty string for missing key', () async {
      final service = OrignaBaseConfigService();
      final value = await service.getString('missing_key');
      expect(value, isEmpty);
    });
  });
}
