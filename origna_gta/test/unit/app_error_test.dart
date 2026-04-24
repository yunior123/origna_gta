import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/utils/utils.dart';

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
  });

  group('AppError.getMessage', () {
    test(
      'plain Exception with internal server error returns fallback, not raw message',
      () {
        final msg = AppError.getMessage(
          Exception('internal server error'),
          'fallback_msg',
        );
        expect(msg, 'fallback_msg');
        expect(msg, isNot(contains('internal server error')));
      },
    );

    test(
      'OrignaBaseException with internal server error returns sanitized message',
      () {
        final error = OrignaBaseException(
          'internal server error',
          statusCode: 500,
        );
        final msg = AppError.getMessage(error);
        expect(msg, contains('errors.service_unavailable'));
        expect(msg, isNot(contains('internal server error')));
      },
    );

    test(
      'OrignaBaseException with safe message returns the actual message',
      () {
        final error = OrignaBaseException('Product not found', statusCode: 404);
        final msg = AppError.getMessage(error);
        expect(msg, contains('Product not found'));
      },
    );

    test(
      'OrignaBaseException with FailedPrecondition returns service_unavailable translation',
      () {
        final error = OrignaBaseException(
          'FailedPrecondition: index required',
          statusCode: 400,
        );
        final msg = AppError.getMessage(error);
        expect(msg, contains('errors.service_unavailable'));
        expect(msg, isNot(contains('FailedPrecondition')));
      },
    );

    test('random error with fallback returns the fallback', () {
      final msg = AppError.getMessage(StateError('bad state'), 'my_fallback');
      expect(msg, 'my_fallback');
    });

    test('OrignaBaseException with Exception in message returns fallback', () {
      final error = OrignaBaseException(
        'Some Exception occurred',
        statusCode: 500,
      );
      final msg = AppError.getMessage(error, 'fallback_msg');
      expect(msg, 'fallback_msg');
      expect(msg, isNot(contains('Exception')));
    });
  });
}
