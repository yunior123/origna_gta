import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/spec_templates.dart';

void main() {
  group('ProductSpec', () {
    test('serialization roundtrip preserves all fields', () {
      const spec = ProductSpec(
        key: 'screenSize',
        value: '15.6',
        valueType: 'number',
        unit: 'inches',
        group: 'Display',
      );

      final jsonString = jsonEncode(spec.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = ProductSpec.fromJson(decoded);

      expect(restored.key, 'screenSize');
      expect(restored.value, '15.6');
      expect(restored.valueType, 'number');
      expect(restored.unit, 'inches');
      expect(restored.group, 'Display');
      expect(restored, spec);
    });

    test('defaults valueType to text', () {
      const spec = ProductSpec(key: 'brand', value: 'Samsung');
      expect(spec.valueType, 'text');
      expect(spec.unit, isNull);
      expect(spec.group, isNull);
    });
  });

  group('ProductSpecs', () {
    test('serialization roundtrip preserves all fields', () {
      const specs = ProductSpecs(
        specs: [
          ProductSpec(key: 'brand', value: 'Apple'),
          ProductSpec(
            key: 'screenSize',
            value: '14',
            valueType: 'number',
            unit: 'inches',
            group: 'Display',
          ),
        ],
        brand: 'Apple',
        color: 'Space Gray',
        material: 'Aluminum',
      );

      // Full JSON roundtrip (encode -> decode) to simulate real network flow
      final jsonString = jsonEncode(specs.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = ProductSpecs.fromJson(decoded);

      expect(restored.specs.length, 2);
      expect(restored.brand, 'Apple');
      expect(restored.color, 'Space Gray');
      expect(restored.material, 'Aluminum');
      expect(restored, specs);
    });

    test('empty specs list serializes correctly', () {
      const specs = ProductSpecs();

      final jsonString = jsonEncode(specs.toJson());
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = ProductSpecs.fromJson(decoded);

      expect(restored.specs, isEmpty);
      expect(restored.brand, isNull);
      expect(restored.color, isNull);
      expect(restored.material, isNull);
      expect(restored, specs);
    });
  });

  group('Product with specs', () {
    test('deserializes correctly from JSON with specs', () {
      final json = <String, dynamic>{
        'productId': 'prod_001',
        'name': 'MacBook Pro',
        'priceCents': 249900,
        'description': 'Laptop',
        'imageUrls': <String>['https://example.com/img.jpg'],
        'sellerId': 'seller_001',
        'categoryId': CategoryIds.computers,
        'stockQuantity': 10,
        'createdAt': '2026-01-15T10:00:00.000Z',
        'specs': {
          'specs': [
            {'key': 'processor', 'value': 'M4 Pro'},
            {
              'key': 'ram',
              'value': '16',
              'valueType': 'number',
              'unit': 'GB',
              'group': 'Performance',
            },
          ],
          'brand': 'Apple',
          'color': 'Space Black',
          'material': 'Aluminum',
        },
      };

      final product = Product.fromJson(json);

      expect(product.specs, isNotNull);
      expect(product.specs!.specs.length, 2);
      expect(product.specs!.specs[0].key, 'processor');
      expect(product.specs!.specs[0].value, 'M4 Pro');
      expect(product.specs!.specs[1].unit, 'GB');
      expect(product.specs!.brand, 'Apple');
      expect(product.specs!.color, 'Space Black');
    });

    test('product without specs has null field', () {
      final json = <String, dynamic>{
        'productId': 'prod_002',
        'name': 'Basic Product',
        'priceCents': 1999,
        'description': 'A product',
        'imageUrls': <String>[],
        'sellerId': 'seller_001',
        'categoryId': CategoryIds.electronics,
        'stockQuantity': 5,
        'createdAt': '2026-01-15T10:00:00.000Z',
      };

      final product = Product.fromJson(json);
      expect(product.specs, isNull);
    });
  });

  group('Spec template registry', () {
    test('getSpecsForCategory(1) returns Electronics templates', () {
      final config = getSpecsForCategory(CategoryIds.electronics);

      expect(config, isNotNull);
      expect(config!.categoryId, CategoryIds.electronics);
      expect(config.categoryName, 'Electronics');
      expect(config.templates, isNotEmpty);

      final keys = config.templates.map((t) => t.key).toList();
      expect(keys, contains(SpecKeyValues.brand));
      expect(keys, contains(SpecKeyValues.screenSize));
      expect(keys, contains(SpecKeyValues.certificationMark));
    });

    test('getSpecsForCategory(19) returns null (groceries uses nutrition)', () {
      final config = getSpecsForCategory(CategoryIds.groceries);
      expect(config, isNull);
    });

    test('all 20 non-food categories have templates', () {
      final nonFoodCategories = <int>[
        CategoryIds.electronics,
        CategoryIds.computers,
        CategoryIds.gaming,
        CategoryIds.homeKitchen,
        CategoryIds.fashion,
        CategoryIds.shoesAccessories,
        CategoryIds.jewelryWatches,
        CategoryIds.beautyPersonalCare,
        CategoryIds.healthWellness,
        CategoryIds.sportsFitness,
        CategoryIds.automotive,
        CategoryIds.toolsHardware,
        CategoryIds.officeSupplies,
        CategoryIds.books,
        CategoryIds.musicInstruments,
        CategoryIds.toysGames,
        CategoryIds.babyKids,
        CategoryIds.petSupplies,
        CategoryIds.artCollectibles,
        CategoryIds.digitalProducts,
      ];

      expect(nonFoodCategories.length, 20);

      for (final catId in nonFoodCategories) {
        final config = getSpecsForCategory(catId);
        expect(
          config,
          isNotNull,
          reason: 'Category $catId should have spec templates',
        );
        expect(
          config!.templates,
          isNotEmpty,
          reason: 'Category $catId templates should not be empty',
        );
        expect(
          config.groups,
          isNotEmpty,
          reason: 'Category $catId groups should not be empty',
        );
      }
    });

    test('Fashion category has fibreContent marked as required', () {
      final config = getSpecsForCategory(CategoryIds.fashion);
      expect(config, isNotNull);

      final fibreTemplate = config!.templates.firstWhere(
        (t) => t.key == SpecKeyValues.fibreContent,
      );
      expect(fibreTemplate.isRequired, isTrue);
    });

    test('all templates have non-empty French labels', () {
      for (final entry in specTemplateRegistry.entries) {
        for (final template in entry.value.templates) {
          expect(
            template.labelFr,
            isNotEmpty,
            reason:
                'Template ${template.key} in category ${entry.key} missing French label',
          );
        }
      }
    });
  });
}
