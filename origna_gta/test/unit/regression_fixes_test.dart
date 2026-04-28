import 'package:easy_localization/easy_localization.dart';
import 'package:orignabase/orignabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
  });

  group('Regression Fixes Unit Tests', () {
    test('AppError.getMessage sanitizes backend errors', () {
      final fakeOrignaBaseException = OrignaBaseException(
        'FailedPrecondition: The query requires an index.',
        statusCode: 400,
      );
      final msg = AppError.getMessage(
        fakeOrignaBaseException,
        'fallback error',
      );
      expect(msg, isNot(contains('FailedPrecondition')));
      expect(msg, isNot(contains('requires an index')));
    });

    test('Subcategories cover all 21 categories', () {
      for (int i = 1; i <= 21; i++) {
        final subcategories = SubcategoryConstants.forCategoryId(i);
        expect(
          subcategories,
          isNotEmpty,
          reason: 'Category ID $i should have subcategories defined',
        );
      }
    });
  });
}
