import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/csv_parser.dart';

void main() {
  group('CSV Parser', () {
    test('parses simple CSV with headers and data', () {
      const csv = 'title,price,stock\nWidget A,99.99,50';
      final rows = parseCsv(csv);
      expect(rows.length, 1);
      expect(rows[0]['title'], 'Widget A');
      expect(rows[0]['price'], '99.99');
      expect(rows[0]['stock'], '50');
    });

    test('handles quoted fields with commas', () {
      const csv =
          'title,description,price\n"Widget A","A great, amazing product",99.99';
      final rows = parseCsv(csv);
      expect(rows.length, 1);
      expect(rows[0]['title'], 'Widget A');
      expect(rows[0]['description'], 'A great, amazing product');
    });

    test('handles escaped quotes in quoted fields', () {
      const csv = 'title,description\n"Widget ""Pro""","Say ""Hello"""';
      final rows = parseCsv(csv);
      expect(rows.length, 1);
      expect(rows[0]['title'], 'Widget "Pro"');
      expect(rows[0]['description'], 'Say "Hello"');
    });

    test('handles empty fields', () {
      const csv = 'title,description,price\nWidget A,,99.99';
      final rows = parseCsv(csv);
      expect(rows.length, 1);
      expect(rows[0]['title'], 'Widget A');
      expect(rows[0]['description'], '');
      expect(rows[0]['price'], '99.99');
    });

    test('skips empty lines', () {
      const csv = 'title,price\nWidget A,99.99\n\nWidget B,49.99';
      final rows = parseCsv(csv);
      expect(rows.length, 2);
      expect(rows[0]['title'], 'Widget A');
      expect(rows[1]['title'], 'Widget B');
    });

    test('throws on empty CSV', () {
      expect(() => parseCsv(''), throwsFormatException);
    });

    test('throws on CSV with no headers', () {
      expect(() => parseCsv(''), throwsFormatException);
    });
  });

  group('mapCsvToBulkProduct', () {
    test('maps minimal valid product', () {
      final row = {
        'title': 'Widget A',
        'price': '99.99',
        'stock': '50',
        'category': 'electronics',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['title'], 'Widget A');
      expect(product['priceCents'], 9999);
      expect(product['stockQuantity'], 50);
      expect(product['categoryId'], 'electronics');
      expect(product['isPerishable'], false);
      expect(product['isDigital'], false);
    });

    test('converts dollars to cents', () {
      final row = {
        'title': 'Widget',
        'price': '19.99',
        'stock': '10',
        'category': 'cat1',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['priceCents'], 1999);
    });

    test('handles prices already in cents', () {
      final row = {
        'title': 'Widget',
        'price': '1999',
        'stock': '10',
        'category': 'cat1',
      };
      final product = mapCsvToBulkProduct(row);
      // 1999 > 1000, so treated as cents
      expect(product['priceCents'], 1999);
    });

    test('converts small numbers to cents (< 1000)', () {
      final row = {
        'title': 'Widget',
        'price': '5',
        'stock': '10',
        'category': 'cat1',
      };
      final product = mapCsvToBulkProduct(row);
      // 5 < 1000, so multiply by 100
      expect(product['priceCents'], 500);
    });

    test('parses perishable flag', () {
      final row = {
        'title': 'Coffee',
        'price': '15.99',
        'stock': '100',
        'category': 'food',
        'perishable': 'true',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['isPerishable'], true);
    });

    test('parses digital flag', () {
      final row = {
        'title': 'eBook',
        'price': '9.99',
        'stock': '999',
        'category': 'books',
        'digital': 'yes',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['isDigital'], true);
    });

    test('includes optional fields when provided', () {
      final row = {
        'title': 'Widget',
        'price': '99.99',
        'stock': '10',
        'category': 'cat1',
        'weight': '2.5',
        'subcategory': 'Heavy',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['weight'], 2.5);
      expect(product['subcategory'], 'Heavy');
    });

    test('throws on missing title', () {
      final row = {'price': '99.99', 'stock': '10', 'category': 'cat1'};
      expect(() => mapCsvToBulkProduct(row), throwsFormatException);
    });

    test('throws on missing categoryId', () {
      final row = {'title': 'Widget', 'price': '99.99', 'stock': '10'};
      expect(() => mapCsvToBulkProduct(row), throwsFormatException);
    });

    test('throws on invalid price', () {
      final row = {
        'title': 'Widget',
        'price': 'invalid',
        'stock': '10',
        'category': 'cat1',
      };
      expect(() => mapCsvToBulkProduct(row), throwsFormatException);
    });

    test('throws on invalid stock', () {
      final row = {
        'title': 'Widget',
        'price': '99.99',
        'stock': 'not_a_number',
        'category': 'cat1',
      };
      expect(() => mapCsvToBulkProduct(row), throwsFormatException);
    });

    test('handles case-insensitive headers', () {
      final row = {
        'Title': 'Widget',
        'PRICE': '99.99',
        'StOcK': '10',
        'CaTegOrY': 'cat1',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['title'], 'Widget');
      expect(product['priceCents'], 9999);
    });

    test('allows alternative header names', () {
      final row = {
        'product name': 'Widget',
        'pricecents': '9999',
        'stockquantity': '10',
        'categoryid': 'cat1',
      };
      final product = mapCsvToBulkProduct(row);
      expect(product['title'], 'Widget');
      expect(product['priceCents'], 9999);
    });
  });

  group('generateCsvTemplate', () {
    test('generates valid CSV with headers', () {
      final csv = generateCsvTemplate();
      expect(csv.contains('title'), true);
      expect(csv.contains('price'), true);
      expect(csv.contains('stock'), true);
      expect(csv.contains('category'), true);
    });

    test('includes example rows', () {
      final csv = generateCsvTemplate();
      expect(csv.contains('Wireless Headphones'), true);
      expect(csv.contains('Organic Coffee Beans'), true);
    });

    test('generates parseable CSV', () {
      final csv = generateCsvTemplate();
      final rows = parseCsv(csv);
      expect(rows.length, 2); // Two example rows
      expect(rows[0].containsKey('title'), true);
    });
  });
}
