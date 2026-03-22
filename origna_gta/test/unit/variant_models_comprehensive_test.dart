import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/variant_models.dart';

void main() {
  group('ProductVariantEntry', () {
    group('constructor', () {
      test('creates with all fields', () {
        final entry = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M', 'Color': 'Red'},
          priceCents: 1999,
          stockQuantity: 50,
          sku: 'SKU-001',
          isActive: true,
        );
        expect(entry.variantId, 'v1');
        expect(entry.optionValues, {'Size': 'M', 'Color': 'Red'});
        expect(entry.priceCents, 1999);
        expect(entry.stockQuantity, 50);
        expect(entry.sku, 'SKU-001');
        expect(entry.isActive, isTrue);
      });

      test('creates with defaults', () {
        const entry = ProductVariantEntry(optionValues: {'Color': 'Blue'});
        expect(entry.variantId, '');
        expect(entry.priceCents, isNull);
        expect(entry.stockQuantity, 0);
        expect(entry.sku, isNull);
        expect(entry.isActive, isTrue);
      });
    });

    group('fromMap', () {
      test('parses complete data', () {
        final map = {
          Fields.variantId: 'var-123',
          Fields.optionValues: {'Size': 'L'},
          Fields.priceCents: 2999,
          Fields.stockQuantity: 25,
          Fields.variantSku: 'SKU-ABC',
          'isActive': false,
        };
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.variantId, 'var-123');
        expect(entry.optionValues, {'Size': 'L'});
        expect(entry.priceCents, 2999);
        expect(entry.stockQuantity, 25);
        expect(entry.sku, 'SKU-ABC');
        expect(entry.isActive, isFalse);
      });

      test('handles missing variantId', () {
        final map = <String, dynamic>{Fields.optionValues: <String, String>{}};
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.variantId, '');
      });

      test('handles null priceCents', () {
        final map = {Fields.optionValues: <String, String>{}};
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.priceCents, isNull);
      });

      test('converts legacy price field to cents', () {
        final map = {
          Fields.optionValues: <String, String>{},
          Fields.price: 19.99,
        };
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.priceCents, 1999);
      });

      test('converts legacy price with rounding', () {
        final map = {
          Fields.optionValues: <String, String>{},
          Fields.price: 19.999,
        };
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.priceCents, closeTo(2000, 1));
      });

      test('prefers priceCents over legacy price', () {
        final map = {
          Fields.optionValues: <String, String>{},
          Fields.priceCents: 1500,
          Fields.price: 99.99,
        };
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.priceCents, 1500);
      });

      test('handles missing stockQuantity', () {
        final map = {Fields.optionValues: <String, String>{}};
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.stockQuantity, 0);
      });

      test('handles missing isActive', () {
        final map = {Fields.optionValues: <String, String>{}};
        final entry = ProductVariantEntry.fromMap(map);
        expect(entry.isActive, isTrue);
      });
    });

    group('priceDollars', () {
      test('converts cents to dollars', () {
        const entry = ProductVariantEntry(optionValues: {}, priceCents: 1999);
        expect(entry.priceDollars, 19.99);
      });

      test('returns null when priceCents is null', () {
        const entry = ProductVariantEntry(optionValues: {});
        expect(entry.priceDollars, isNull);
      });

      test('handles zero price', () {
        const entry = ProductVariantEntry(optionValues: {}, priceCents: 0);
        expect(entry.priceDollars, 0.0);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        final entry = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M'},
          priceCents: 1999,
          stockQuantity: 10,
          sku: 'SKU-123',
          isActive: false,
        );
        final map = entry.toMap();
        expect(map[Fields.variantId], 'v1');
        expect(map[Fields.optionValues], {'Size': 'M'});
        expect(map[Fields.priceCents], 1999);
        expect(map[Fields.stockQuantity], 10);
        expect(map[Fields.variantSku], 'SKU-123');
        expect(map['isActive'], isFalse);
      });
    });

    group('copyWith', () {
      test('updates variantId', () {
        const entry = ProductVariantEntry(variantId: 'v1', optionValues: {});
        final copied = entry.copyWith(variantId: 'v2');
        expect(copied.variantId, 'v2');
      });

      test('updates optionValues', () {
        const entry = ProductVariantEntry(optionValues: {'Size': 'M'});
        final copied = entry.copyWith(optionValues: {'Size': 'L'});
        expect(copied.optionValues, {'Size': 'L'});
      });

      test('updates priceCents to null', () {
        const entry = ProductVariantEntry(optionValues: {}, priceCents: 1000);
        final copied = entry.copyWith(priceCents: null);
        expect(copied.priceCents, isNull);
      });

      test('updates stockQuantity', () {
        const entry = ProductVariantEntry(optionValues: {}, stockQuantity: 5);
        final copied = entry.copyWith(stockQuantity: 10);
        expect(copied.stockQuantity, 10);
      });

      test('updates sku to null', () {
        const entry = ProductVariantEntry(optionValues: {}, sku: 'OLD-SKU');
        final copied = entry.copyWith(sku: null);
        expect(copied.sku, isNull);
      });

      test('preserves sku when not updated', () {
        const entry = ProductVariantEntry(
          optionValues: {},
          sku: 'PRESERVED-SKU',
        );
        final copied = entry.copyWith(stockQuantity: 20);
        expect(copied.sku, 'PRESERVED-SKU');
      });

      test('updates isActive', () {
        const entry = ProductVariantEntry(optionValues: {}, isActive: true);
        final copied = entry.copyWith(isActive: false);
        expect(copied.isActive, isFalse);
      });
    });

    group('equality', () {
      test('equal entries match', () {
        final entry1 = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M'},
          priceCents: 1999,
          stockQuantity: 10,
          sku: 'SKU',
          isActive: true,
        );
        final entry2 = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M'},
          priceCents: 1999,
          stockQuantity: 10,
          sku: 'SKU',
          isActive: true,
        );
        expect(entry1, equals(entry2));
      });

      test('different variantId not equal', () {
        const entry1 = ProductVariantEntry(variantId: 'v1', optionValues: {});
        const entry2 = ProductVariantEntry(variantId: 'v2', optionValues: {});
        expect(entry1, isNot(equals(entry2)));
      });

      test('different optionValues not equal', () {
        const entry1 = ProductVariantEntry(optionValues: {'Size': 'M'});
        const entry2 = ProductVariantEntry(optionValues: {'Size': 'L'});
        expect(entry1, isNot(equals(entry2)));
      });

      test('different priceCents not equal', () {
        const entry1 = ProductVariantEntry(optionValues: {}, priceCents: 1000);
        const entry2 = ProductVariantEntry(optionValues: {}, priceCents: 2000);
        expect(entry1, isNot(equals(entry2)));
      });

      test('different stockQuantity not equal', () {
        const entry1 = ProductVariantEntry(optionValues: {}, stockQuantity: 5);
        const entry2 = ProductVariantEntry(optionValues: {}, stockQuantity: 10);
        expect(entry1, isNot(equals(entry2)));
      });

      test('different sku not equal', () {
        const entry1 = ProductVariantEntry(optionValues: {}, sku: 'SKU1');
        const entry2 = ProductVariantEntry(optionValues: {}, sku: 'SKU2');
        expect(entry1, isNot(equals(entry2)));
      });

      test('different isActive not equal', () {
        const entry1 = ProductVariantEntry(optionValues: {}, isActive: true);
        const entry2 = ProductVariantEntry(optionValues: {}, isActive: false);
        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('hashCode', () {
      test('consistent with equality', () {
        final entry1 = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M'},
          priceCents: 1999,
          stockQuantity: 10,
          sku: 'SKU',
          isActive: true,
        );
        final entry2 = ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'M'},
          priceCents: 1999,
          stockQuantity: 10,
          sku: 'SKU',
          isActive: true,
        );
        expect(entry1.hashCode, equals(entry2.hashCode));
      });
    });
  });

  group('VariantOption', () {
    group('constructor', () {
      test('creates with all fields', () {
        const option = VariantOption(
          name: 'Size',
          values: ['S', 'M', 'L', 'XL'],
        );
        expect(option.name, 'Size');
        expect(option.values, ['S', 'M', 'L', 'XL']);
      });

      test('creates empty values list', () {
        const option = VariantOption(name: 'Color', values: []);
        expect(option.name, 'Color');
        expect(option.values, isEmpty);
      });
    });

    group('fromMap', () {
      test('parses complete data', () {
        final map = {
          Fields.name: 'Size',
          'values': ['S', 'M', 'L'],
        };
        final option = VariantOption.fromMap(map);
        expect(option.name, 'Size');
        expect(option.values, ['S', 'M', 'L']);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        const option = VariantOption(name: 'Color', values: ['Red', 'Blue']);
        final map = option.toMap();
        expect(map[Fields.name], 'Color');
        expect(map['values'], ['Red', 'Blue']);
      });
    });

    group('copyWith', () {
      test('updates name', () {
        const option = VariantOption(name: 'Size', values: ['S', 'M']);
        final copied = option.copyWith(name: 'Color');
        expect(copied.name, 'Color');
        expect(copied.values, ['S', 'M']);
      });

      test('updates values', () {
        const option = VariantOption(name: 'Size', values: ['S', 'M']);
        final copied = option.copyWith(values: ['L', 'XL']);
        expect(copied.name, 'Size');
        expect(copied.values, ['L', 'XL']);
      });

      test('preserves unchanged fields', () {
        const option = VariantOption(name: 'Size', values: ['S', 'M', 'L']);
        final copied = option.copyWith();
        expect(copied.name, 'Size');
        expect(copied.values, ['S', 'M', 'L']);
      });
    });

    group('equality', () {
      test('equal options match', () {
        const option1 = VariantOption(name: 'Size', values: ['S', 'M', 'L']);
        const option2 = VariantOption(name: 'Size', values: ['S', 'M', 'L']);
        expect(option1, equals(option2));
      });

      test('different name not equal', () {
        const option1 = VariantOption(name: 'Size', values: []);
        const option2 = VariantOption(name: 'Color', values: []);
        expect(option1, isNot(equals(option2)));
      });

      test('different values not equal', () {
        const option1 = VariantOption(name: 'Size', values: ['S', 'M']);
        const option2 = VariantOption(name: 'Size', values: ['M', 'L']);
        expect(option1, isNot(equals(option2)));
      });

      test('different order not equal', () {
        const option1 = VariantOption(name: 'Size', values: ['S', 'M']);
        const option2 = VariantOption(name: 'Size', values: ['M', 'S']);
        expect(option1, isNot(equals(option2)));
      });
    });

    group('hashCode', () {
      test('consistent with equality', () {
        const option1 = VariantOption(name: 'Size', values: ['S', 'M', 'L']);
        const option2 = VariantOption(name: 'Size', values: ['S', 'M', 'L']);
        expect(option1.hashCode, equals(option2.hashCode));
      });
    });
  });

  group('Variant selection logic', () {
    test('matching variant by options', () {
      final variants = [
        ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'S', 'Color': 'Red'},
        ),
        ProductVariantEntry(
          variantId: 'v2',
          optionValues: {'Size': 'M', 'Color': 'Red'},
        ),
        ProductVariantEntry(
          variantId: 'v3',
          optionValues: {'Size': 'M', 'Color': 'Blue'},
        ),
      ];

      final selected = variants.firstWhere(
        (v) => mapEquals(v.optionValues, {'Size': 'M', 'Color': 'Red'}),
      );
      expect(selected.variantId, 'v2');
    });

    test('finding available options for selection', () {
      final variants = [
        ProductVariantEntry(
          variantId: 'v1',
          optionValues: {'Size': 'S'},
          stockQuantity: 10,
        ),
        ProductVariantEntry(
          variantId: 'v2',
          optionValues: {'Size': 'M'},
          stockQuantity: 0,
        ),
        ProductVariantEntry(
          variantId: 'v3',
          optionValues: {'Size': 'L'},
          stockQuantity: 5,
        ),
      ];

      final inStock = variants.where((v) => v.stockQuantity > 0).toList();
      expect(inStock.length, 2);
      expect(inStock[0].variantId, 'v1');
      expect(inStock[1].variantId, 'v3');
    });

    test('price range calculation', () {
      final variants = [
        ProductVariantEntry(optionValues: {}, priceCents: 1000),
        ProductVariantEntry(optionValues: {}, priceCents: 2000),
        ProductVariantEntry(optionValues: {}, priceCents: 1500),
      ];

      final prices = variants
          .where((v) => v.priceCents != null)
          .map((v) => v.priceCents!)
          .toList();
      expect(prices.reduce((a, b) => a < b ? a : b), 1000);
      expect(prices.reduce((a, b) => a > b ? a : b), 2000);
    });

    test('active variants filtering', () {
      final variants = [
        ProductVariantEntry(optionValues: {}, isActive: true),
        ProductVariantEntry(optionValues: {}, isActive: false),
        ProductVariantEntry(optionValues: {}, isActive: true),
      ];

      final active = variants.where((v) => v.isActive).toList();
      expect(active.length, 2);
    });

    test('variant with null price handling', () {
      final variants = [
        ProductVariantEntry(optionValues: {}, priceCents: 1000),
        ProductVariantEntry(optionValues: {}, priceCents: null),
        ProductVariantEntry(optionValues: {}, priceCents: 2000),
      ];

      final withPrice = variants.where((v) => v.priceCents != null).toList();
      expect(withPrice.length, 2);
    });
  });
}
