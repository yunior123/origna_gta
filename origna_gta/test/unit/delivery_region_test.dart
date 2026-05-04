import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils/delivery_region.dart';

void main() {
  group('DeliveryRegion.fromCountry', () {
    test('null returns canada (default)', () {
      expect(DeliveryRegion.fromCountry(null), DeliveryRegion.canada);
    });

    test('empty string returns canada (default)', () {
      expect(DeliveryRegion.fromCountry(''), DeliveryRegion.canada);
    });

    test('Canada returns canada', () {
      expect(DeliveryRegion.fromCountry('Canada'), DeliveryRegion.canada);
    });

    test('canada (lowercase) returns canada', () {
      expect(DeliveryRegion.fromCountry('canada'), DeliveryRegion.canada);
    });

    test('CA returns canada', () {
      expect(DeliveryRegion.fromCountry('CA'), DeliveryRegion.canada);
    });

    test('ca (lowercase) returns canada', () {
      expect(DeliveryRegion.fromCountry('ca'), DeliveryRegion.canada);
    });

    test('USA returns international', () {
      expect(DeliveryRegion.fromCountry('USA'), DeliveryRegion.international);
    });

    test('Mexico returns international', () {
      expect(
        DeliveryRegion.fromCountry('Mexico'),
        DeliveryRegion.international,
      );
    });

    test('France returns international', () {
      expect(
        DeliveryRegion.fromCountry('France'),
        DeliveryRegion.international,
      );
    });
  });

  group('DeliveryRegion.isDomestic', () {
    test('canada is domestic', () {
      expect(DeliveryRegion.canada.isDomestic, isTrue);
    });

    test('international is not domestic', () {
      expect(DeliveryRegion.international.isDomestic, isFalse);
    });
  });

  group('DeliveryRegion.isInternational', () {
    test('canada is not international', () {
      expect(DeliveryRegion.canada.isInternational, isFalse);
    });

    test('international is international', () {
      expect(DeliveryRegion.international.isInternational, isTrue);
    });
  });

  group('DeliveryRegion.flagEmoji', () {
    test('canada flag is 🇨🇦', () {
      expect(DeliveryRegion.canada.flagEmoji, '🇨🇦');
    });

    test('international flag is 🌍', () {
      expect(DeliveryRegion.international.flagEmoji, '🌍');
    });
  });

  group('DeliveryRegion.localizedLabel', () {
    test('canada returns non-empty string', () {
      expect(DeliveryRegion.canada.localizedLabel(), isNotEmpty);
    });

    test('international returns non-empty string', () {
      expect(DeliveryRegion.international.localizedLabel(), isNotEmpty);
    });
  });

  group('DeliveryRegion.localizedDeliveryEstimate', () {
    test('international with 28 days returns non-empty', () {
      expect(
        DeliveryRegion.international.localizedDeliveryEstimate(
          estimatedShipDays: 28,
        ),
        isNotEmpty,
      );
    });

    test('canada with 3 days returns empty (domestic, short lead time)', () {
      expect(
        DeliveryRegion.canada.localizedDeliveryEstimate(estimatedShipDays: 3),
        isEmpty,
      );
    });
  });
}
