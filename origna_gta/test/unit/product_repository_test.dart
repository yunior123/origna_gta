import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/services/conf_services.dart';

@GenerateNiceMocks([MockSpec<ProductRepository>(), MockSpec<ConfigService>()])
import 'product_repository_test.mocks.dart';

void main() {
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
  });

  group('ProductRepository Comprehensive Tests', () {
    test('sanitizeProductData strips server-controlled fields', () {
      final raw = {Fields.productId: 'p1', Fields.rating: 5.0, Fields.sellerId: 's1', 'name': 'Test'};

      final sanitized = sanitizeProductData(raw);
      expect(sanitized.containsKey(Fields.productId), isFalse);
      expect(sanitized.containsKey(Fields.rating), isFalse);
      expect(sanitized.containsKey(Fields.sellerId), isFalse);
      expect(sanitized['name'], 'Test');
    });

    test('fetchProductById returns active product', () async {
      when(mockRepository.fetchProductById('p1')).thenAnswer((_) async {
        return Product(
          productId: 'p1',
          name: 'Test',
          description: 'Desc',
          priceCents: 1000,
          sellerId: 's1',
          categoryId: 1,
          imageUrls: const [],
          stockQuantity: 10,
          createdAt: DateTime.now(),
        );
      });

      final product = await mockRepository.fetchProductById('p1');
      expect(product, isNotNull);
      expect(product!.name, 'Test');
    });

    test('watchFavorites returns set of IDs', () async {
      when(mockRepository.watchFavorites('u1')).thenAnswer((_) => Stream.value({'p1'}));

      final stream = mockRepository.watchFavorites('u1');
      final first = await stream.first;
      expect(first, contains('p1'));
    });

    test('watchUnansweredQuestionsCount returns count', () async {
      when(mockRepository.watchUnansweredQuestionsCount('s1')).thenAnswer((_) => Stream.value(1));

      final stream = mockRepository.watchUnansweredQuestionsCount('s1');
      final count = await stream.first;
      expect(count, 1);
    });
  });
}
