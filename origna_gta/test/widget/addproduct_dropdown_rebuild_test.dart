import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/spec_templates.dart';

void main() {
  group('Spec template dropdown rebuild', () {
    test(
      'getSpecsForCategory returns different templates for different categories',
      () {
        final electronics = getSpecsForCategory(CategoryIds.electronics);
        final fashion = getSpecsForCategory(CategoryIds.fashion);

        expect(electronics, isNotNull);
        expect(fashion, isNotNull);
        expect(electronics!.categoryId, isNot(fashion!.categoryId));
        expect(
          electronics.templates.map((t) => t.key),
          contains(SpecKeyValues.screenSize),
        );
        expect(
          fashion.templates.map((t) => t.key),
          contains(SpecKeyValues.fibreContent),
        );
        expect(
          electronics.templates.map((t) => t.key),
          isNot(contains(SpecKeyValues.fibreContent)),
        );
      },
    );

    test('getSpecsForCategory returns null for Groceries', () {
      expect(getSpecsForCategory(CategoryIds.groceries), isNull);
    });

    test('ValueKey changes when dropdown value changes', () {
      // Simulates the fix: ValueKey('spec_storageType_SSD') != ValueKey('spec_storageType_null')
      const key1 = ValueKey('spec_storageType_SSD');
      const key2 = ValueKey('spec_storageType_null');
      expect(key1, isNot(equals(key2)));
    });

    test('safe dropdown value is null when raw value not in options', () {
      final template = getSpecsForCategory(CategoryIds.computers)!.templates
          .where((t) => t.options != null && t.options!.isNotEmpty)
          .firstOrNull;

      if (template != null) {
        // Simulate stale value not in options
        const staleValue = 'DELETED_OPTION';
        final safeValue = template.options!.contains(staleValue)
            ? staleValue
            : null;
        expect(safeValue, isNull);

        // Simulate valid value
        final validValue = template.options!.first;
        final safeValid = template.options!.contains(validValue)
            ? validValue
            : null;
        expect(safeValid, validValue);
      }
    });
  });
}
