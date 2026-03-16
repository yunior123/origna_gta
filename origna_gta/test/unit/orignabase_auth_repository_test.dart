import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrignaBaseAuthException', () {
    test('can be created with code and message', () {
      final ex = OrignaBaseAuthException(
        code: 'test-error',
        message: 'Something went wrong',
      );
      expect(ex.code, 'test-error');
      expect(ex.message, 'Something went wrong');
    });

    test('can be created with code only', () {
      final ex = OrignaBaseAuthException(code: 'test-error');
      expect(ex.code, 'test-error');
      expect(ex.message, isNull);
    });

    test('toString returns formatted string with code', () {
      final ex = OrignaBaseAuthException(
        code: 'test-error',
        message: 'Something went wrong',
      );
      final str = ex.toString();
      expect(str, contains('test-error'));
      expect(str, isA<String>());
    });

    test('toString returns correct format', () {
      final ex = OrignaBaseAuthException(
        code: 'invalid-email',
        message: 'Email is invalid',
      );
      expect(
        ex.toString(),
        'OrignaBaseAuthException(code: invalid-email, message: Email is invalid)',
      );
    });

    test('is an Exception', () {
      final ex = OrignaBaseAuthException(code: 'test');
      expect(ex, isA<Exception>());
    });
  });
}
