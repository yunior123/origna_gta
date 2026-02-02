import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/services/algolia_service.dart';

void main() {
  group('Algolia Service Tests', () {
    test('hitToProductMap should correctly parse all fields', () {
      // Arrange
      final hit = {
        'objectID': 'test_123',
        'name': 'Test Product',
        'price': 29.99,
        'categoryId': 19,
        'sellerId': 'seller_abc',
        'imageUrls': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        'description': 'A test product description',
        'stockQuantity': 100,
        'rating': 4.7,
        'ratingCount': 256,
        'keywords': ['test', 'product', 'sample'],
        'sellerAddress': {'street': '123 Main St', 'city': 'Toronto', 'state': 'ON', 'postalCode': 'M5V1A1', 'country': 'Canada'},
        'isActive': true,
        'freeShipping': true,
        'isPerishable': false,
        'isLocalDeliveryOnly': false,
        'minimumOrderQuantity': 2,
        'estimatedShipDays': 3,
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['productId'], 'test_123');
      expect(result['name'], 'Test Product');
      expect(result['price'], 29.99);
      expect(result['categoryId'], 19);
      expect(result['sellerId'], 'seller_abc');
      expect(result['imageUrls'], hasLength(2));
      expect(result['description'], 'A test product description');
      expect(result['stockQuantity'], 100);
      expect(result['rating'], 4.7);
      expect(result['ratingCount'], 256);
      expect(result['freeShipping'], true);
      expect(result['isPerishable'], false);
      expect(result['minimumOrderQuantity'], 2);
      expect(result['estimatedShipDays'], 3);
    });

    test('hitToProductMap should handle missing optional fields', () {
      // Arrange
      final hit = {'objectID': 'test_456', 'name': 'Minimal Product', 'price': 9.99, 'categoryId': 1};

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['productId'], 'test_456');
      expect(result['name'], 'Minimal Product');
      expect(result['price'], 9.99);
      expect(result['categoryId'], 1);
      expect(result['imageUrls'], isEmpty);
      expect(result['description'], '');
      expect(result['stockQuantity'], 0);
      expect(result['rating'], 0.0);
      expect(result['ratingCount'], 0);
      expect(result['freeShipping'], false);
      expect(result['isPerishable'], false);
      expect(result['isLocalDeliveryOnly'], false);
    });

    test('hitToProductMap should handle null values gracefully', () {
      // Arrange
      final hit = {
        'objectID': 'test_789',
        'name': 'Product with Nulls',
        'price': 15.50,
        'categoryId': 5,
        'sellerId': null,
        'imageUrls': null,
        'description': null,
        'stockQuantity': null,
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['productId'], 'test_789');
      expect(result['name'], 'Product with Nulls');
      expect(result['price'], 15.50);
      expect(result['sellerId'], '');
      expect(result['imageUrls'], isEmpty);
      expect(result['description'], '');
      expect(result['stockQuantity'], 0);
    });

    test('hitToProductMap should parse complex seller address', () {
      // Arrange
      final hit = {
        'objectID': 'test_address',
        'name': 'Product with Address',
        'price': 20.00,
        'categoryId': 10,
        'sellerAddress': {
          'street': '456 Oak Ave',
          'apartment': 'Unit 3B',
          'city': 'Vancouver',
          'state': 'BC',
          'postalCode': 'V6B 2N9',
          'country': 'Canada',
          'latitude': 49.2827,
          'longitude': -123.1207,
        },
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['productId'], 'test_address');
      expect(result['sellerAddress'], isNotNull);
      expect(result['sellerAddress']['city'], 'Vancouver');
      expect(result['sellerAddress']['state'], 'BC');
      expect(result['sellerAddress']['country'], 'Canada');
    });

    test('hitToProductMap should parse all boolean flags correctly', () {
      // Arrange
      final hit = {
        'objectID': 'test_bools',
        'name': 'Product with Flags',
        'price': 12.99,
        'categoryId': 7,
        'isActive': false,
        'freeShipping': true,
        'isPerishable': true,
        'isLocalDeliveryOnly': true,
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['isActive'], false);
      expect(result['freeShipping'], true);
      expect(result['isPerishable'], true);
      expect(result['isLocalDeliveryOnly'], true);
    });

    test('hitToProductMap should parse search keywords array', () {
      // Arrange
      final hit = {
        'objectID': 'test_keywords',
        'name': 'Product with Keywords',
        'price': 8.50,
        'categoryId': 3,
        'keywords': ['organic', 'local', 'fresh', 'produce'],
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['keywords'], hasLength(4));
      expect(result['keywords'], contains('organic'));
      expect(result['keywords'], contains('local'));
      expect(result['keywords'], contains('fresh'));
      expect(result['keywords'], contains('produce'));
    });

    test('hitToProductMap should handle numeric fields correctly', () {
      // Arrange
      final hit = {
        'objectID': 'test_numbers',
        'name': 'Product with Numbers',
        'price': 99.99,
        'categoryId': 12,
        'stockQuantity': 500,
        'rating': 4.95,
        'ratingCount': 1234,
        'minimumOrderQuantity': 5,
        'estimatedShipDays': 7,
        'weightKg': 2.5,
        'lengthCm': 30.0,
        'widthCm': 20.0,
        'heightCm': 10.0,
      };

      // Act
      final result = AlgoliaService.hitToProductMap(hit);

      // Assert
      expect(result['price'], 99.99);
      expect(result['stockQuantity'], 500);
      expect(result['rating'], 4.95);
      expect(result['ratingCount'], 1234);
      expect(result['minimumOrderQuantity'], 5);
      expect(result['estimatedShipDays'], 7);
      expect(result['weightKg'], 2.5);
      expect(result['lengthCm'], 30.0);
      expect(result['widthCm'], 20.0);
      expect(result['heightCm'], 10.0);
    });
  });

  group('Algolia Integration Validation', () {
    test('AlgoliaService.create should initialize with valid credentials', () {
      // This test validates the service can be created
      // In production, credentials come from Firebase Remote Config

      const testAppId = 'TEST_APP_ID';
      const testSearchKey = 'TEST_SEARCH_KEY';

      // Act & Assert
      expect(() => AlgoliaService.create(appId: testAppId, searchApiKey: testSearchKey), returnsNormally);
    });
  });
}
