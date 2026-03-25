import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/products/recommendations_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';

Product _makeProduct({
  required String productId,
  required String sellerId,
  String name = 'Test Product',
  int priceCents = 1999,
  String lifecycleStatus = ProductLifecycleStatusValues.active,
}) => Product(
  productId: productId,
  name: name,
  priceCents: priceCents,
  description: 'Test description',
  imageUrls: const ['https://example.com/img.jpg'],
  sellerId: sellerId,
  categoryId: CategoryIds.electronics,
  stockQuantity: 10,
  createdAt: DateTime(2026),
  lifecycleStatus: lifecycleStatus,
);

void main() {
  group('bundledProductsProvider', () {
    test('returns empty list for empty IDs', () async {
      final container = ProviderContainer(
        overrides: [
          bundledProductsProvider(
            const [],
          ).overrideWith((_) async => <Product>[]),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        bundledProductsProvider(const []).future,
      );
      expect(result, isEmpty);
    });

    test('returns products for valid IDs', () async {
      final bundled = [
        _makeProduct(productId: 'p2', sellerId: 's1', name: 'Bundled A'),
        _makeProduct(productId: 'p3', sellerId: 's1', name: 'Bundled B'),
      ];
      final container = ProviderContainer(
        overrides: [
          bundledProductsProvider(const [
            'p2',
            'p3',
          ]).overrideWith((_) async => bundled),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        bundledProductsProvider(const ['p2', 'p3']).future,
      );
      expect(result.length, 2);
      expect(result.first.name, 'Bundled A');
    });
  });

  group('moreFromSellerProvider', () {
    test('excludes current product from results', () async {
      final products = [
        _makeProduct(productId: 'p1', sellerId: 's1'),
        _makeProduct(productId: 'p2', sellerId: 's1'),
        _makeProduct(productId: 'p3', sellerId: 's1'),
      ];

      final container = ProviderContainer(
        overrides: [
          moreFromSellerProvider((
            sellerId: 's1',
            excludeProductId: 'p1',
          )).overrideWith((_) async {
            return products
                .where((p) => p.productId != 'p1')
                .where(
                  (p) =>
                      p.lifecycleStatus == ProductLifecycleStatusValues.active,
                )
                .take(8)
                .toList();
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        moreFromSellerProvider((sellerId: 's1', excludeProductId: 'p1')).future,
      );
      expect(result.length, 2);
      expect(result.every((p) => p.productId != 'p1'), isTrue);
    });

    test('filters out non-active products', () async {
      final products = [
        _makeProduct(
          productId: 'p2',
          sellerId: 's1',
          lifecycleStatus: ProductLifecycleStatusValues.draft,
        ),
        _makeProduct(productId: 'p3', sellerId: 's1'),
      ];

      final container = ProviderContainer(
        overrides: [
          moreFromSellerProvider((
            sellerId: 's1',
            excludeProductId: 'p1',
          )).overrideWith((_) async {
            return products
                .where((p) => p.productId != 'p1')
                .where(
                  (p) =>
                      p.lifecycleStatus == ProductLifecycleStatusValues.active,
                )
                .take(8)
                .toList();
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        moreFromSellerProvider((sellerId: 's1', excludeProductId: 'p1')).future,
      );
      expect(result.length, 1);
      expect(result.first.productId, 'p3');
    });

    test('returns empty list when seller has no other products', () async {
      final container = ProviderContainer(
        overrides: [
          moreFromSellerProvider((
            sellerId: 's1',
            excludeProductId: 'p1',
          )).overrideWith((_) async => <Product>[]),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        moreFromSellerProvider((sellerId: 's1', excludeProductId: 'p1')).future,
      );
      expect(result, isEmpty);
    });
  });
}
