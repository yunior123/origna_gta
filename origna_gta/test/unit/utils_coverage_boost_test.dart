import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/compat/timestamp.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

void main() {
  group('parseDateTime', () {
    test('returns null for null input', () {
      expect(parseDateTime(null), isNull);
    });

    test('returns DateTime for DateTime input', () {
      final dt = DateTime(2026, 1, 15);
      expect(parseDateTime(dt), equals(dt));
    });

    test('returns DateTime for Timestamp input', () {
      final ts = Timestamp.fromDate(DateTime(2026, 1, 15));
      final result = parseDateTime(ts);
      expect(result, isNotNull);
      expect(result!.year, 2026);
    });

    test('returns DateTime for valid String input', () {
      final result = parseDateTime('2026-01-15T12:00:00Z');
      expect(result, isNotNull);
      expect(result!.year, 2026);
    });

    test('returns null for invalid String', () {
      expect(parseDateTime('not-a-date'), isNull);
    });

    test('handles int as seconds (recent date range)', () {
      // Use a value in the seconds range (2010-2100)
      // 1700000000 is ~2023-11-14 in seconds
      final result = parseDateTime(1700000000);
      expect(result, isNotNull);
      // Should be treated as seconds and converted to milliseconds
      expect(result!.year, greaterThanOrEqualTo(2023));
    });

    test('handles int as milliseconds (out of seconds range)', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = parseDateTime(now);
      expect(result, isNotNull);
    });

    test('returns null for unsupported type', () {
      expect(parseDateTime(true), isNull);
    });
  });

  group('parseDateTimeRequired', () {
    test('returns parsed date for valid input', () {
      final result = parseDateTimeRequired('2026-01-15T12:00:00Z');
      expect(result.year, 2026);
    });

    test('returns fallback for null', () {
      final fallback = DateTime(2020, 1, 1);
      final result = parseDateTimeRequired(null, fallback);
      expect(result, equals(fallback));
    });

    test('returns now when no fallback and null', () {
      final result = parseDateTimeRequired(null);
      expect(result.year, DateTime.now().year);
    });
  });

  group('dynamicToDateTime', () {
    test('converts DateTime', () {
      final dt = DateTime(2026, 3, 15);
      expect(dynamicToDateTime(dt), equals(dt));
    });

    test('converts String', () {
      final result = dynamicToDateTime('2026-03-15T10:00:00Z');
      expect(result.year, 2026);
    });
  });

  group('dynamicToTimestamp', () {
    test('converts DateTime', () {
      final dt = DateTime(2026, 3, 15);
      expect(dynamicToTimestamp(dt), equals(dt));
    });
  });

  group('calculateDetailedTaxes', () {
    test('returns empty map for null address', () {
      expect(calculateDetailedTaxes(null, 100.0), isEmpty);
    });

    test('calculates Ontario HST', () {
      final addr = Address(
        street: '123',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      final result = calculateDetailedTaxes(addr, 100.0);
      expect(result.containsKey('HST'), isTrue);
      expect(result['HST'], closeTo(13.0, 0.01));
    });

    test('calculates Quebec GST+QST', () {
      final addr = Address(
        street: '123',
        city: 'Montreal',
        state: 'QC',
        postalCode: 'H1H 1H1',
        country: 'CA',
      );
      final result = calculateDetailedTaxes(addr, 100.0);
      expect(result.containsKey('GST'), isTrue);
      expect(result.containsKey('QST'), isTrue);
      expect(result['GST'], closeTo(5.0, 0.01));
      expect(result['QST'], closeTo(9.975, 0.01));
    });

    test('calculates BC GST+PST', () {
      final addr = Address(
        street: '123',
        city: 'Vancouver',
        state: 'BC',
        postalCode: 'V1V 1V1',
        country: 'CA',
      );
      final result = calculateDetailedTaxes(addr, 100.0);
      expect(result.containsKey('GST'), isTrue);
      expect(result.containsKey('PST'), isTrue);
    });

    test('calculates Alberta GST only', () {
      final addr = Address(
        street: '123',
        city: 'Calgary',
        state: 'AB',
        postalCode: 'T1T 1T1',
        country: 'CA',
      );
      final result = calculateDetailedTaxes(addr, 100.0);
      expect(result.length, 1);
      expect(result.containsKey('GST'), isTrue);
      expect(result['GST'], closeTo(5.0, 0.01));
    });

    test('defaults to GST for unknown province', () {
      final addr = Address(
        street: '123',
        city: 'Unknown',
        state: 'XX',
        postalCode: 'X1X 1X1',
        country: 'CA',
      );
      final result = calculateDetailedTaxes(addr, 100.0);
      expect(result.containsKey('GST'), isTrue);
    });
  });

  group('getTaxRate', () {
    test('returns 13% for Ontario', () {
      expect(getTaxRate('ON'), closeTo(0.13, 0.001));
    });

    test('returns combined rate for Quebec', () {
      expect(getTaxRate('QC'), closeTo(0.14975, 0.001));
    });

    test('returns 5% for Alberta', () {
      expect(getTaxRate('AB'), closeTo(0.05, 0.001));
    });

    test('returns default 13% for unknown province', () {
      expect(getTaxRate('XX'), closeTo(0.13, 0.001));
    });

    test('returns 15% for NB', () {
      expect(getTaxRate('NB'), closeTo(0.15, 0.001));
    });
  });

  group('hasValidAddress', () {
    test('returns false for null', () {
      expect(hasValidAddress(null), isFalse);
    });

    test('returns true for valid Canadian address', () {
      final addr = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(hasValidAddress(addr), isTrue);
    });

    test('returns false for empty street', () {
      final addr = Address(
        street: '',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('returns false for empty city', () {
      final addr = Address(
        street: '123 Main',
        city: '',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('returns false for invalid province code', () {
      final addr = Address(
        street: '123',
        city: 'City',
        state: 'ZZ',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('returns false for empty postal code', () {
      final addr = Address(
        street: '123',
        city: 'City',
        state: 'ON',
        postalCode: '',
        country: 'CA',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('returns false for empty country', () {
      final addr = Address(
        street: '123',
        city: 'City',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: '',
      );
      expect(hasValidAddress(addr), isFalse);
    });
  });

  group('isValidTaxCode', () {
    test('returns true for null', () {
      expect(isValidTaxCode(null), isTrue);
    });

    test('returns true for empty string', () {
      expect(isValidTaxCode(''), isTrue);
    });

    test('returns true for valid tax code', () {
      expect(isValidTaxCode('txcd_12345678'), isTrue);
    });

    test('returns false for invalid format', () {
      expect(isValidTaxCode('invalid'), isFalse);
    });

    test('returns false for wrong prefix', () {
      expect(isValidTaxCode('txcd12345678'), isFalse);
    });

    test('returns false for wrong digit count', () {
      expect(isValidTaxCode('txcd_1234567'), isFalse);
    });
  });

  group('generateSearchKeywords', () {
    test('generates prefixes for single word', () {
      final keywords = generateSearchKeywords('Blue');
      expect(keywords, contains('b'));
      expect(keywords, contains('bl'));
      expect(keywords, contains('blu'));
      expect(keywords, contains('blue'));
    });

    test('generates prefixes for multi-word', () {
      final keywords = generateSearchKeywords('Blue Shoes');
      expect(keywords, contains('b'));
      expect(keywords, contains('blue shoes'));
    });

    test('returns single empty string for empty input', () {
      final keywords = generateSearchKeywords('');
      expect(keywords, ['']);
    });

    test('handles whitespace-only input', () {
      final keywords = generateSearchKeywords('   ');
      expect(keywords, ['']);
    });

    test('limits keywords', () {
      final longName = List.generate(50, (i) => 'word$i').join(' ');
      final keywords = generateSearchKeywords(longName);
      expect(keywords.length, lessThanOrEqualTo(30));
    });
  });

  group('calculateFallbackShipping', () {
    CartItemDetailModel makeItem({int quantity = 1}) {
      return CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: 'desc',
        price: 10.0,
        priceCents: 1000,
        imageUrls: [],
        quantity: quantity,
        createdAt: DateTime.now(),
        sellerAddress: Address(
          street: '123',
          city: 'City',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
        sellerId: 's1',
        sellerName: 'Seller',
      );
    }

    test('same province gets lowest rate', () {
      final cost = calculateFallbackShipping([makeItem()], 'ON', 'ON');
      expect(cost, closeTo(12.99, 0.01));
    });

    test('different province gets higher rate', () {
      final cost = calculateFallbackShipping([makeItem()], 'ON', 'BC');
      expect(cost, greaterThan(12.99));
    });

    test('multiple items add cost', () {
      final cost = calculateFallbackShipping(
        [makeItem(quantity: 3)],
        'ON',
        'ON',
      );
      expect(cost, greaterThan(12.99));
    });
  });

  group('provinceTaxRates', () {
    test('Canadian provinces have valid rates', () {
      const canadianProvinces = [
        'AB',
        'BC',
        'MB',
        'NB',
        'NL',
        'NS',
        'NT',
        'NU',
        'ON',
        'PE',
        'QC',
        'SK',
        'YT',
      ];
      for (final code in canadianProvinces) {
        final rates = provinceTaxRates[code]!;
        final totalRate = rates.values.fold(0.0, (a, b) => a + b);
        expect(totalRate, greaterThan(0));
        expect(totalRate, lessThan(0.20));
      }
    });

    test('Cuban provinces have zero tax rates', () {
      const cubanProvinces = [
        'HAB',
        'MAT',
        'VC',
        'SC',
        'HOL',
        'CMG',
        'CAV',
        'SSP',
        'CFG',
        'PR',
        'GRA',
        'LT',
        'GU',
        'IJ',
        'ART',
        'MAY',
      ];
      for (final code in cubanProvinces) {
        final rates = provinceTaxRates[code]!;
        expect(rates.isEmpty, isTrue, reason: '$code should have no tax rates');
      }
    });

    test('covers all Canadian provinces and territories', () {
      final expected = [
        'AB',
        'BC',
        'MB',
        'NB',
        'NL',
        'NS',
        'NT',
        'NU',
        'ON',
        'PE',
        'QC',
        'SK',
        'YT',
      ];
      for (final code in expected) {
        expect(
          provinceTaxRates.containsKey(code),
          isTrue,
          reason: 'Missing province: $code',
        );
      }
    });
  });

  group('productCategories', () {
    test('has 21 categories', () {
      expect(productCategories.length, 21);
    });

    test('all have unique IDs', () {
      final ids = productCategories.map((c) => c.categoryId).toSet();
      expect(ids.length, productCategories.length);
    });

    test('all have non-empty names', () {
      for (final cat in productCategories) {
        expect(cat.name, isNotEmpty);
      }
    });
  });

  group('calculateShippingCost', () {
    test('returns empty map for null address', () async {
      final result = await calculateShippingCost([], null);
      expect(result, isEmpty);
    });

    test('returns empty map for address without coordinates', () async {
      final addr = Address(
        street: '123',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      final result = await calculateShippingCost([], addr);
      expect(result, isEmpty);
    });
  });

  group('calculateTieredShipping', () {
    CartItemDetailModel makeItem({double weightKg = 1.0, int quantity = 1}) {
      return CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: 'desc',
        price: 10.0,
        priceCents: 1000,
        imageUrls: [],
        quantity: quantity,
        createdAt: DateTime.now(),
        sellerAddress: Address(
          street: '123',
          city: 'City',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
        sellerId: 's1',
        sellerName: 'Seller',
        weightKg: weightKg,
      );
    }

    test('calculates for short distance', () {
      final cost = calculateTieredShipping(10.0, [
        makeItem(),
      ], DeliverySpeed.standard);
      expect(cost, greaterThanOrEqualTo(0));
    });

    test('calculates for medium distance', () {
      final cost = calculateTieredShipping(200.0, [
        makeItem(),
      ], DeliverySpeed.standard);
      expect(cost, greaterThan(0));
    });

    test('calculates for long distance', () {
      final cost = calculateTieredShipping(2000.0, [
        makeItem(),
      ], DeliverySpeed.standard);
      expect(cost, greaterThan(0));
    });

    test('express is more expensive than standard', () {
      final standard = calculateTieredShipping(100.0, [
        makeItem(),
      ], DeliverySpeed.standard);
      final express = calculateTieredShipping(100.0, [
        makeItem(),
      ], DeliverySpeed.express);
      expect(express, greaterThanOrEqualTo(standard));
    });
  });

  group('Address model', () {
    test('toMap roundtrip', () {
      final addr = Address(
        street: '123 Main St',
        apartment: 'Apt 4',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
        latitude: 43.6532,
        longitude: -79.3832,
        phoneNumber: '+14165551234',
      );

      final map = addr.toMap();
      final restored = Address.fromMap(map);
      expect(restored.street, addr.street);
      expect(restored.apartment, addr.apartment);
      expect(restored.city, addr.city);
      expect(restored.state, addr.state);
      expect(restored.postalCode, addr.postalCode);
      expect(restored.country, addr.country);
      expect(restored.latitude, addr.latitude);
      expect(restored.longitude, addr.longitude);
    });

    test('fromMap handles empty map', () {
      final addr = Address.fromMap({});
      expect(addr.street, isEmpty);
      expect(addr.city, isEmpty);
    });

    test('Address with same values have same properties', () {
      final a1 = Address(
        street: '123',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      final a2 = Address(
        street: '123',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(a1.street, equals(a2.street));
      expect(a1.city, equals(a2.city));
      expect(a1.state, equals(a2.state));
    });

    test('Address isDefault defaults to false', () {
      final addr = Address(
        street: '123',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );
      expect(addr.isDefault, isFalse);
    });
  });
}
