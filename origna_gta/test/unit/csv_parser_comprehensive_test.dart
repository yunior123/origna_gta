import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/csv_parser.dart';

void main() {
  group('parseCsv', () {
    group('basic parsing', () {
      test('parses simple single-row CSV', () {
        const csv = 'name,value\nAlice,42';
        final rows = parseCsv(csv);
        expect(rows.length, 1);
        expect(rows[0]['name'], 'Alice');
        expect(rows[0]['value'], '42');
      });

      test('parses multi-row CSV', () {
        const csv = 'name,value\nAlice,42\nBob,99';
        final rows = parseCsv(csv);
        expect(rows.length, 2);
        expect(rows[0]['name'], 'Alice');
        expect(rows[1]['name'], 'Bob');
      });

      test('parses CSV with many columns', () {
        const csv = 'a,b,c,d,e\n1,2,3,4,5';
        final rows = parseCsv(csv);
        expect(rows.length, 1);
        expect(rows[0]['a'], '1');
        expect(rows[0]['e'], '5');
      });

      test('handles empty fields', () {
        const csv = 'a,b,c\n1,,3';
        final rows = parseCsv(csv);
        expect(rows[0]['a'], '1');
        expect(rows[0]['b'], '');
        expect(rows[0]['c'], '3');
      });

      test('handles trailing comma', () {
        const csv = 'a,b,c\n1,2,';
        final rows = parseCsv(csv);
        expect(rows[0]['c'], '');
      });

      test('handles leading comma', () {
        const csv = 'a,b,c\n,2,3';
        final rows = parseCsv(csv);
        expect(rows[0]['a'], '');
        expect(rows[0]['b'], '2');
      });
    });

    group('quoted fields', () {
      test('parses quoted field with comma', () {
        const csv = 'name,description\n"Widget","A great, amazing product"';
        final rows = parseCsv(csv);
        expect(rows[0]['description'], 'A great, amazing product');
      });

      test('parses quoted field with newline', () {
        const csv = 'name,value\n"multi\nline",42';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'multi\nline');
      });

      test('parses escaped quotes', () {
        const csv = 'name,value\n"Widget ""Pro""",99';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'Widget "Pro"');
      });

      test('parses double escaped quotes', () {
        const csv = 'name,value\n"""quoted""",42';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], '"quoted"');
      });

      test('parses unquoted and quoted fields mixed', () {
        const csv = 'name,desc,price\nWidget,"A good product",99';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'Widget');
        expect(rows[0]['desc'], 'A good product');
        expect(rows[0]['price'], '99');
      });

      test('handles empty quoted field', () {
        const csv = 'name,value\n"",""';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], '');
        expect(rows[0]['value'], '');
      });

      test('handles quote at start of unquoted field', () {
        const csv = 'name,value\n"quoted" rest,42';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'quoted rest');
      });
    });

    group('multiline handling', () {
      test('handles field spanning multiple lines', () {
        const csv = 'name,value\n"line1\nline2\nline3",42';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'line1\nline2\nline3');
      });

      test('handles quoted field followed by unquoted', () {
        const csv = 'name,value\n"multi\nline",42\nSimple,99';
        final rows = parseCsv(csv);
        expect(rows.length, 2);
        expect(rows[0]['name'], 'multi\nline');
        expect(rows[1]['name'], 'Simple');
      });
    });

    group('edge cases', () {
      test('throws on empty string', () {
        expect(() => parseCsv(''), throwsFormatException);
      });

      test('throws on whitespace-only content', () {
        expect(() => parseCsv(' '), throwsFormatException);
      });

      test('returns empty list for CSV with only header', () {
        final result = parseCsv('header');
        expect(result, isEmpty);
      });

      test('skips empty lines in middle', () {
        const csv = 'name,value\n\nAlice,42\n\nBob,99';
        final rows = parseCsv(csv);
        expect(rows.length, 2);
      });

      test('skips empty lines at end', () {
        const csv = 'name,value\nAlice,42\n';
        final rows = parseCsv(csv);
        expect(rows.length, 1);
      });

      test('pads missing columns with empty strings', () {
        const csv = 'a,b,c\n1,2';
        final rows = parseCsv(csv);
        expect(rows[0]['c'], '');
      });

      test('truncates extra columns', () {
        const csv = 'a,b\n1,2,3,4,5';
        final rows = parseCsv(csv);
        expect(rows.length, 1);
        expect(rows[0].length, 2);
        expect(rows[0]['a'], '1');
        expect(rows[0]['b'], '2');
      });
    });

    group('whitespace handling', () {
      test('trims whitespace from values', () {
        const csv = 'name,value\n Alice , 42 ';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'Alice');
        expect(rows[0]['value'], '42');
      });

      test('preserves internal whitespace in quoted fields', () {
        const csv = 'name,value\n" Alice ",42';
        final rows = parseCsv(csv);
        expect(rows[0]['name'], 'Alice');
      });
    });
  });

  group('mapCsvToBulkProduct', () {
    group('basic mapping', () {
      test('maps minimal required fields', () {
        final row = {
          'title': 'Widget',
          'price': '99',
          'stock': '10',
          'category': 'electronics',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['title'], 'Widget');
        expect(product['priceCents'], greaterThan(0));
        expect(product['stockQuantity'], greaterThanOrEqualTo(0));
        expect(product['categoryId'], 'electronics');
      });

      test('maps all standard fields', () {
        final row = {
          'title': 'Product',
          'description': 'A description',
          'price': '19.99',
          'stock': '100',
          'category': 'cat1',
          'subcategory': 'sub1',
          'weight': '2.5',
          'perishable': 'true',
          'digital': 'false',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['title'], 'Product');
        expect(product['description'], 'A description');
        expect(product['priceCents'], 1999);
        expect(product['stockQuantity'], 100);
        expect(product['categoryId'], 'cat1');
        expect(product['subcategory'], 'sub1');
        expect(product['weight'], 2.5);
        expect(product['isPerishable'], isTrue);
        expect(product['isDigital'], isFalse);
      });
    });

    group('field name variations', () {
      test('accepts "name" for title', () {
        final row = {
          'name': 'Widget',
          'price': '10',
          'stock': '5',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['title'], 'Widget');
      });

      test('accepts "product name" for title', () {
        final row = {
          'product name': 'Widget',
          'price': '10',
          'stock': '5',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['title'], 'Widget');
      });

      test('accepts "pricecents" for price', () {
        final row = {
          'title': 'W',
          'pricecents': '1999',
          'stock': '5',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['priceCents'], 1999);
      });

      test('accepts "stockquantity" for stock', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stockquantity': '50',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['stockQuantity'], 50);
      });

      test('accepts "categoryid" for category', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '5',
          'categoryid': 'cat1',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['categoryId'], 'cat1');
      });

      test('accepts "desc" for description', () {
        final row = {
          'title': 'W',
          'desc': 'A product',
          'price': '10',
          'stock': '5',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['description'], 'A product');
      });

      test('accepts "isperishable" for perishable', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '5',
          'category': 'cat',
          'isperishable': 'yes',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['isPerishable'], isTrue);
      });

      test('accepts "is_digital" for digital', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '5',
          'category': 'cat',
          'is_digital': '1',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['isDigital'], isTrue);
      });
    });

    group('price parsing', () {
      test('converts dollars to cents', () {
        final row = {
          'title': 'W',
          'price': '19.99',
          'stock': '1',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['priceCents'], 1999);
      });

      test('handles prices already in cents (>1000)', () {
        final row = {
          'title': 'W',
          'price': '1999',
          'stock': '1',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['priceCents'], 1999);
      });

      test('multiplies small integers to cents', () {
        final row = {
          'title': 'W',
          'price': '19',
          'stock': '1',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['priceCents'], 1900);
      });

      test('handles zero price', () {
        final row = {
          'title': 'W',
          'price': '0',
          'stock': '1',
          'category': 'cat',
        };
        final product = mapCsvToBulkProduct(row);
        expect(product['priceCents'], 0);
      });

      test('throws on invalid price', () {
        final row = {
          'title': 'W',
          'price': 'invalid',
          'stock': '1',
          'category': 'cat',
        };
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });

      test('throws on empty price', () {
        final row = {
          'title': 'W',
          'price': '',
          'stock': '1',
          'category': 'cat',
        };
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });
    });

    group('boolean parsing', () {
      test('parses "true"', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': 'true',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isTrue);
      });

      test('parses "1"', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': '1',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isTrue);
      });

      test('parses "yes"', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': 'yes',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isTrue);
      });

      test('parses "y"', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': 'y',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isTrue);
      });

      test('parses "false"', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': 'false',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isFalse);
      });

      test('defaults to false for unknown', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': '1',
          'category': 'cat',
          'perishable': 'maybe',
        };
        expect(mapCsvToBulkProduct(row)['isPerishable'], isFalse);
      });
    });

    group('validation', () {
      test('throws on missing title', () {
        final row = {'price': '10', 'stock': '1', 'category': 'cat'};
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });

      test('throws on empty title', () {
        final row = {
          'title': '',
          'price': '10',
          'stock': '1',
          'category': 'cat',
        };
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });

      test('throws on missing category', () {
        final row = {'title': 'W', 'price': '10', 'stock': '1'};
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });

      test('throws on empty category', () {
        final row = {'title': 'W', 'price': '10', 'stock': '1', 'category': ''};
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });

      test('throws on invalid stock', () {
        final row = {
          'title': 'W',
          'price': '10',
          'stock': 'abc',
          'category': 'cat',
        };
        expect(() => mapCsvToBulkProduct(row), throwsFormatException);
      });
    });
  });

  group('generateCsvTemplate', () {
    test('generates non-empty string', () {
      final template = generateCsvTemplate();
      expect(template, isNotEmpty);
    });

    test('contains expected headers', () {
      final template = generateCsvTemplate();
      expect(template, contains('title'));
      expect(template, contains('description'));
      expect(template, contains('price'));
      expect(template, contains('stock'));
      expect(template, contains('category'));
    });

    test('contains example products', () {
      final template = generateCsvTemplate();
      expect(template, contains('Wireless Headphones'));
      expect(template, contains('Organic Coffee Beans'));
    });

    test('is parseable as valid CSV', () {
      final template = generateCsvTemplate();
      final rows = parseCsv(template);
      expect(rows.length, 2);
      expect(rows[0].containsKey('title'), isTrue);
      expect(rows[1].containsKey('title'), isTrue);
    });

    test('example rows have all columns', () {
      final template = generateCsvTemplate();
      final rows = parseCsv(template);
      for (final row in rows) {
        expect(row.containsKey('title'), isTrue);
        expect(row.containsKey('description'), isTrue);
        expect(row.containsKey('price'), isTrue);
        expect(row.containsKey('stock'), isTrue);
        expect(row.containsKey('category'), isTrue);
        expect(row.containsKey('subcategory'), isTrue);
        expect(row.containsKey('weight'), isTrue);
        expect(row.containsKey('perishable'), isTrue);
        expect(row.containsKey('digital'), isTrue);
      }
    });
  });
}
