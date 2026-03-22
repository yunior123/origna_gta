import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/turnstile_service.dart';

void main() {
  group('TurnstileService', () {
    test('getToken returns null on non-web platforms', () async {
      if (!kIsWeb) {
        final token = await TurnstileService.getToken();
        expect(token, isNull);
      }
    });

    test('reset does nothing on non-web platforms', () {
      if (!kIsWeb) {
        TurnstileService.reset();
      }
    });

    test('getToken is a static method', () {
      expect(TurnstileService.getToken, isA<Function>());
    });

    test('reset is a static method', () {
      expect(TurnstileService.reset, isA<Function>());
    });

    test('getToken returns Future<String?>', () async {
      final result = TurnstileService.getToken();
      expect(result, isA<Future<String?>>());
    });
  });
}
