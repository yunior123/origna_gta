import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/home/home_state.dart';
import 'package:origna_gta/models/generated/models.dart';

Product _product({
  required String id,
  String? madeInCountry,
  String? shipFromCountry,
}) {
  return Product(
    productId: id,
    name: 'Product $id',
    priceCents: 1000,
    description: 'Test product',
    imageUrls: const ['https://example.com/image.jpg'],
    sellerId: 'seller-1',
    madeInCountry: madeInCountry,
    categoryId: 1,
    stockQuantity: 5,
    createdAt: DateTime(2026, 1, 1),
    shipFromCountry: shipFromCountry,
  );
}

void main() {
  group('HomeState.displayedProducts', () {
    test('returns all products when made-in-Canada filter is off', () {
      final state = HomeState(
        products: [
          _product(id: 'ca', madeInCountry: 'CA', shipFromCountry: 'CA'),
          _product(id: 'cn', madeInCountry: 'CN', shipFromCountry: 'CA'),
          _product(id: 'unknown', shipFromCountry: 'CA'),
        ],
        canadaOnly: false,
      );

      expect(state.displayedProducts.map((p) => p.productId), [
        'ca',
        'cn',
        'unknown',
      ]);
    });

    test('keeps Canada-made products and excludes imported or unknown origin', () {
      final state = HomeState(
        products: [
          _product(id: 'made-ca', madeInCountry: 'CA', shipFromCountry: 'CN'),
          _product(id: 'made-canada', madeInCountry: 'Canada', shipFromCountry: 'CA'),
          _product(id: 'made-cn', madeInCountry: 'CN', shipFromCountry: 'CA'),
          _product(id: 'unknown-origin', shipFromCountry: 'CA'),
        ],
        canadaOnly: true,
      );

      expect(
        state.displayedProducts.map((p) => p.productId).toList(),
        ['made-ca', 'made-canada'],
      );
    });
  });
}
