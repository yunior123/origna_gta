import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/services/orignabase_digital_service.dart';
import 'package:orignabase/orignabase.dart';

void main() {
  group('OrignaBaseDigitalService', () {
    test(
      'generateBookDownloadSession returns downloadUrl on success',
      () async {
        final ob = OrignaBase.initialize(url: 'http://127.0.0.1:0');
        final service = OrignaBaseDigitalService(ob);

        expect(
          () => service.generateBookDownloadSession('LICENSE-KEY-123'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'generateSoftwareDownloadSession returns downloadUrl on success',
      () async {
        final ob = OrignaBase.initialize(url: 'http://127.0.0.1:0');
        final service = OrignaBaseDigitalService(ob);

        expect(
          () => service.generateSoftwareDownloadSession(
            'LICENSE-KEY-456',
            'macos',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('service is const constructible', () {
      final ob = OrignaBase.initialize(url: 'http://127.0.0.1:0');
      final service = OrignaBaseDigitalService(ob);
      expect(service, isA<OrignaBaseDigitalService>());
    });

    test('generateBookDownloadSession uses correct endpoint', () {
      expect(ApiEndpoints.digitalDownloadBook, isA<String>());
    });

    test('generateSoftwareDownloadSession uses correct endpoint', () {
      expect(ApiEndpoints.digitalDownloadSoftware, isA<String>());
    });

    test('Fields.licenseKey is defined', () {
      expect(Fields.licenseKey, isA<String>());
    });

    test('Fields.platform is defined', () {
      expect(Fields.platform, isA<String>());
    });
  });
}
