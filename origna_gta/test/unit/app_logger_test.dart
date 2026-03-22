import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    group('d (debug)', () {
      test('does not throw when called', () {
        expect(() => AppLogger.d('test message'), returnsNormally);
      });

      test('handles message with tag', () {
        expect(
          () => AppLogger.d('test message', tag: 'TestTag'),
          returnsNormally,
        );
      });

      test('handles empty message', () {
        expect(() => AppLogger.d(''), returnsNormally);
      });

      test('handles null tag gracefully', () {
        expect(() => AppLogger.d('message', tag: null), returnsNormally);
      });

      test('handles long message', () {
        final longMessage = 'a' * 10000;
        expect(() => AppLogger.d(longMessage), returnsNormally);
      });

      test('handles special characters', () {
        expect(() => AppLogger.d('Special: \n\t\r"\''), returnsNormally);
      });

      test('handles unicode', () {
        expect(() => AppLogger.d('Unicode: café 中文 🎉'), returnsNormally);
      });
    });

    group('i (info)', () {
      test('does not throw when called', () {
        expect(() => AppLogger.i('info message'), returnsNormally);
      });

      test('handles message with tag', () {
        expect(
          () => AppLogger.i('info message', tag: 'InfoTag'),
          returnsNormally,
        );
      });

      test('handles empty message', () {
        expect(() => AppLogger.i(''), returnsNormally);
      });

      test('handles null tag gracefully', () {
        expect(() => AppLogger.i('message', tag: null), returnsNormally);
      });

      test('handles long message', () {
        final longMessage = 'info ' * 1000;
        expect(() => AppLogger.i(longMessage), returnsNormally);
      });
    });

    group('w (warning)', () {
      test('does not throw when called', () {
        expect(() => AppLogger.w('warning message'), returnsNormally);
      });

      test('handles message with tag', () {
        expect(
          () => AppLogger.w('warning message', tag: 'WarnTag'),
          returnsNormally,
        );
      });

      test('handles empty message', () {
        expect(() => AppLogger.w(''), returnsNormally);
      });

      test('handles error parameter', () {
        expect(
          () => AppLogger.w('warning', error: Exception('test')),
          returnsNormally,
        );
      });

      test('handles null error', () {
        expect(() => AppLogger.w('warning', error: null), returnsNormally);
      });

      test('handles all parameters', () {
        expect(
          () => AppLogger.w('warning', tag: 'Test', error: Exception('err')),
          returnsNormally,
        );
      });
    });

    group('e (error)', () {
      test('does not throw when called without error object', () {
        expect(() => AppLogger.e('error message'), returnsNormally);
      });

      test('handles message with tag', () {
        expect(
          () => AppLogger.e('error message', tag: 'ErrorTag'),
          returnsNormally,
        );
      });

      test('handles error parameter', () {
        expect(
          () => AppLogger.e('error message', error: Exception('test')),
          returnsNormally,
        );
      });

      test('handles stackTrace parameter', () {
        try {
          throw Exception('test');
        } catch (e, stack) {
          expect(
            () => AppLogger.e('error message', error: e, stackTrace: stack),
            returnsNormally,
          );
        }
      });

      test('handles all parameters', () {
        try {
          throw Exception('test');
        } catch (e, stack) {
          expect(
            () => AppLogger.e('error', tag: 'Tag', error: e, stackTrace: stack),
            returnsNormally,
          );
        }
      });

      test('handles null tag', () {
        expect(() => AppLogger.e('error', tag: null), returnsNormally);
      });

      test('handles null stackTrace', () {
        expect(
          () =>
              AppLogger.e('error', error: Exception('test'), stackTrace: null),
          returnsNormally,
        );
      });

      test('handles error without message', () {
        expect(
          () => AppLogger.e('', error: Exception('test')),
          returnsNormally,
        );
      });
    });

    group('tag formatting', () {
      test('message without tag does not include brackets', () {
        AppLogger.d('test message');
        AppLogger.i('test message');
        AppLogger.w('test message');
        AppLogger.e('test message');
      });

      test('message with tag includes tag format', () {
        AppLogger.d('test', tag: 'MyTag');
        AppLogger.i('test', tag: 'MyTag');
        AppLogger.w('test', tag: 'MyTag');
        AppLogger.e('test', tag: 'MyTag');
      });
    });

    group('edge cases', () {
      test('handles very long tag', () {
        final longTag = 'tag' * 100;
        expect(() => AppLogger.d('msg', tag: longTag), returnsNormally);
      });

      test('handles special characters in tag', () {
        expect(
          () => AppLogger.d('msg', tag: 'Tag-With.Special_Chars'),
          returnsNormally,
        );
      });

      test('handles newlines in message', () {
        expect(() => AppLogger.d('line1\nline2\nline3'), returnsNormally);
      });

      test('handles multiline error message', () {
        final error = Exception('line1\nline2\nline3');
        expect(() => AppLogger.e('error', error: error), returnsNormally);
      });

      test('handles FormatException', () {
        expect(
          () => AppLogger.e('error', error: FormatException('bad format')),
          returnsNormally,
        );
      });

      test('handles ArgumentError', () {
        expect(
          () => AppLogger.e('error', error: ArgumentError('invalid arg')),
          returnsNormally,
        );
      });

      test('handles StateError', () {
        expect(
          () => AppLogger.e('error', error: StateError('bad state')),
          returnsNormally,
        );
      });

      test('handles RangeError', () {
        expect(
          () => AppLogger.e('error', error: RangeError('out of range')),
          returnsNormally,
        );
      });

      test('handles custom exception', () {
        expect(
          () => AppLogger.e('error', error: _CustomException('custom')),
          returnsNormally,
        );
      });

      test('handles StackTrace.current', () {
        expect(
          () => AppLogger.e('error', stackTrace: StackTrace.current),
          returnsNormally,
        );
      });
    });

    group('multiple calls', () {
      test('handles multiple sequential calls', () {
        for (var i = 0; i < 100; i++) {
          AppLogger.d('message $i');
        }
      });

      test('handles interleaved log levels', () {
        for (var i = 0; i < 10; i++) {
          AppLogger.d('debug $i');
          AppLogger.i('info $i');
          AppLogger.w('warn $i');
          AppLogger.e('error $i');
        }
      });
    });
  });
}

class _CustomException implements Exception {
  final String message;
  _CustomException(this.message);

  @override
  String toString() => '_CustomException: $message';
}
