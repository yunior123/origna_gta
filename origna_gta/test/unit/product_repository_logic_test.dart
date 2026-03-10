import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:orignabase/orignabase.dart' show FieldValue;

void main() {
  group('sanitizeProductData', () {
    test('removes server-controlled fields', () {
      final raw = {
        Fields.productId: 'should-be-removed',
        Fields.ratingCount: 5,
        Fields.rating: 4.5,
        Fields.sellerId: 'seller1',
        Fields.lifecycleStatus: 'active',
        'name': 'Test Product',
      };

      final result = sanitizeProductData(raw);

      expect(result.containsKey(Fields.productId), isFalse);
      expect(result.containsKey(Fields.ratingCount), isFalse);
      expect(result.containsKey(Fields.rating), isFalse);
      expect(result.containsKey(Fields.sellerId), isFalse);
      expect(result.containsKey(Fields.lifecycleStatus), isFalse);
      expect(result['name'], 'Test Product');
    });

    test('normalizes empty apartment to null in sellerAddress', () {
      final raw = {
        Fields.sellerAddress: {
          'street': '123 Main St',
          'apartment': '',
          'city': 'Toronto',
        },
      };

      final result = sanitizeProductData(raw);
      final addr = result[Fields.sellerAddress] as Map;
      expect(addr['apartment'], isNull);
    });

    test('preserves non-empty apartment in sellerAddress', () {
      final raw = {
        Fields.sellerAddress: {
          'street': '123 Main St',
          'apartment': 'Unit 5',
          'city': 'Toronto',
        },
      };

      final result = sanitizeProductData(raw);
      final addr = result[Fields.sellerAddress] as Map;
      expect(addr['apartment'], 'Unit 5');
    });

    test('normalizes whitespace-only apartment to null', () {
      final raw = {
        Fields.sellerAddress: {
          'apartment': '   ',
        },
      };

      final result = sanitizeProductData(raw);
      final addr = result[Fields.sellerAddress] as Map;
      expect(addr['apartment'], isNull);
    });

    test('adds serverTimestamp when ensureDateCreated is true', () {
      final raw = {'name': 'Test'};
      final result = sanitizeProductData(raw, ensureDateCreated: true);
      expect(result[Fields.createdAt], isA<FieldValue>());
    });

    test('converts string createdAt to ISO-8601 string', () {
      final raw = {Fields.createdAt: '2024-01-01T00:00:00.000Z'};
      final result = sanitizeProductData(raw);
      expect(result[Fields.createdAt], '2024-01-01T00:00:00.000Z');
    });

    test('converts invalid string createdAt to serverTimestamp', () {
      final raw = {Fields.createdAt: 'not-a-date'};
      final result = sanitizeProductData(raw);
      expect(result[Fields.createdAt], isA<FieldValue>());
    });

    test('converts DateTime createdAt to ISO-8601 string', () {
      final dt = DateTime(2024, 6, 15);
      final raw = {Fields.createdAt: dt};
      final result = sanitizeProductData(raw);
      expect(result[Fields.createdAt], dt.toIso8601String());
    });

    test('does not modify original map', () {
      final raw = {
        Fields.productId: 'p1',
        'name': 'Test',
      };
      sanitizeProductData(raw);
      expect(raw.containsKey(Fields.productId), isTrue);
    });
  });

  group('ProductQueryResult', () {
    test('construction with defaults', () {
      final result = ProductQueryResult(products: [], hasMore: false);
      expect(result.products, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocumentId, isNull);
    });
  });
}
