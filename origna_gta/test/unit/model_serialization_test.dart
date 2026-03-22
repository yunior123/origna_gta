import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/models/generated/order_models.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/models/generated/seller_profile_models.dart';

void main() {
  group('Product serialization', () {
    final productJson = {
      'productId': 'p1',
      'name': 'Test Product',
      'nameF': 'Produit Test',
      'price': 29.99,
      'priceCents': 2999,
      'compareAtPrice': 39.99,
      'description': 'A test product',
      'descriptionF': 'Un produit test',
      'imageUrls': ['img1.jpg', 'img2.jpg'],
      'videoUrl': 'video.mp4',
      'videoDurationSeconds': 30,
      'sellerId': 's1',
      'madeInCountry': 'CA',
      'categoryId': 1,
      'stockQuantity': 50,
      'rating': 4.5,
      'ratingCount': 10,
      'createdAt': '2026-01-01T00:00:00.000',
      'lifecycleStatus': 'active',
      'weightKg': 1.5,
      'weightUnit': 'kg',
      'lengthCm': 30.0,
      'widthCm': 20.0,
      'heightCm': 10.0,
      'dimensionUnit': 'cm',
      'isLocalDeliveryOnly': true,
      'isPerishable': true,
      'estimatedShipDays': 2,
      'minimumOrderQuantity': 3,
      'freeShipping': true,
      'isDigital': false,
      'isAgeRestricted': true,
      'taxCode': 'TAX001',
      'keywords': ['test', 'product'],
      'approvalRejectionReason': 'Missing info',
      'cost': 15.0,
      'supplierSku': 'SUP-001',
      'supplierUrl': 'https://supplier.com/product',
      'sellerSku': 'SKU-001',
      'warehouseIds': ['wh1', 'wh2'],
      'shipFromCity': 'Toronto',
      'shipFromProvince': 'ON',
      'shipFromCountry': 'CA',
      'shipFromCountries': ['CA', 'US'],
      'trendingScore': 100,
      'viewCount': 500,
      'purchaseCount': 25,
      'isTrending': true,
      'trendingAt': '2026-02-01T00:00:00.000',
      'hasVariants': true,
      'subcategory': 'electronics',
      'condition': 'new',
      'warehouseStockMap': {'wh1': 30, 'wh2': 20},
      'updatedAt': '2026-02-15T00:00:00.000',
      'deliveryOptions': [],
      'variants': [],
      'variantOptions': [],
    };

    test('fromJson parses all fields', () {
      final product = Product.fromJson(productJson);
      expect(product.productId, 'p1');
      expect(product.name, 'Test Product');
      expect(product.nameF, 'Produit Test');
      expect(product.price, 29.99);
      expect(product.priceCents, 2999);
      expect(product.compareAtPrice, 39.99);
      expect(product.description, 'A test product');
      expect(product.imageUrls.length, 2);
      expect(product.videoUrl, 'video.mp4');
      expect(product.sellerId, 's1');
      expect(product.categoryId, 1);
      expect(product.stockQuantity, 50);
      expect(product.rating, 4.5);
      expect(product.ratingCount, 10);
      expect(product.isLocalDeliveryOnly, true);
      expect(product.isPerishable, true);
      expect(product.freeShipping, true);
      expect(product.isAgeRestricted, true);
      expect(product.trendingScore, 100);
      expect(product.isTrending, true);
      expect(product.hasVariants, true);
      expect(product.subcategory, 'electronics');
      expect(product.condition, 'new');
      expect(product.warehouseStockMap, {'wh1': 30, 'wh2': 20});
    });

    test('toJson roundtrip preserves data', () {
      final product = Product.fromJson(productJson);
      final json = product.toJson();
      expect(json['productId'], 'p1');
      expect(json['name'], 'Test Product');
      expect(json['price'], 29.99);
      expect(json['sellerId'], 's1');
      expect(json['categoryId'], 1);
      expect(json['trendingScore'], 100);
    });

    test('fromJson with minimal fields', () {
      final minimal = {
        'productId': 'p2',
        'name': 'Minimal',
        'price': 9.99,
        'description': 'Desc',
        'imageUrls': <String>[],
        'sellerId': 's2',
        'categoryId': 2,
        'stockQuantity': 0,
        'createdAt': '2026-01-01T00:00:00.000',
      };
      final product = Product.fromJson(minimal);
      expect(product.productId, 'p2');
      expect(product.rating, 0.0);
      expect(product.ratingCount, 0);
      expect(product.isDigital, false);
      expect(product.freeShipping, false);
      expect(product.estimatedShipDays, 3);
      expect(product.minimumOrderQuantity, 1);
      expect(product.trendingScore, 0);
      expect(product.viewCount, 0);
      expect(product.purchaseCount, 0);
      expect(product.isTrending, false);
      expect(product.hasVariants, false);
      expect(product.nameF, isNull);
      expect(product.videoUrl, isNull);
      expect(product.supplier, isNull);
      expect(product.inventory, isNull);
    });
  });

  group('InventoryConfig serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'managed': false,
        'trackQuantity': false,
        'allowBackorder': true,
        'lowStockThreshold': 10,
        'lastLowStockAlertAt': '2026-01-15T12:00:00.000',
        'reservationHoldMinutes': 60,
      };
      final config = InventoryConfig.fromJson(json);
      expect(config.managed, false);
      expect(config.trackQuantity, false);
      expect(config.allowBackorder, true);
      expect(config.lowStockThreshold, 10);
      expect(config.lastLowStockAlertAt, isNotNull);
      expect(config.reservationHoldMinutes, 60);
    });

    test('fromJson with defaults', () {
      final config = InventoryConfig.fromJson({});
      expect(config.managed, true);
      expect(config.trackQuantity, true);
      expect(config.allowBackorder, false);
      expect(config.lowStockThreshold, 5);
      expect(config.reservationHoldMinutes, 30);
    });

    test('toJson roundtrip', () {
      final config = const InventoryConfig(
        managed: true,
        trackQuantity: false,
        allowBackorder: true,
        lowStockThreshold: 15,
        reservationHoldMinutes: 45,
      );
      final json = config.toJson();
      expect(json['managed'], true);
      expect(json['trackQuantity'], false);
      expect(json['allowBackorder'], true);
      expect(json['lowStockThreshold'], 15);
    });
  });

  group('VariantOption serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'name': 'Color',
        'values': ['Red', 'Blue', 'Green'],
      };
      final option = VariantOption.fromJson(json);
      expect(option.name, 'Color');
      expect(option.values, ['Red', 'Blue', 'Green']);

      final output = option.toJson();
      expect(output['name'], 'Color');
      expect(output['values'], ['Red', 'Blue', 'Green']);
    });
  });

  group('ProductVariant serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'variantId': 'v1',
        'sku': 'SKU-V1',
        'priceCents': 1999,
        'stockQuantity': 25,
        'optionValues': {'Color': 'Red', 'Size': 'L'},
        'isActive': true,
      };
      final variant = ProductVariant.fromJson(json);
      expect(variant.variantId, 'v1');
      expect(variant.sku, 'SKU-V1');
      expect(variant.priceCents, 1999);
      expect(variant.stockQuantity, 25);
      expect(variant.optionValues, {'Color': 'Red', 'Size': 'L'});
      expect(variant.isActive, true);
    });

    test('toJson roundtrip', () {
      final variant = ProductVariant.fromJson({
        'variantId': 'v2',
        'stockQuantity': 0,
        'optionValues': {'Size': 'S'},
      });
      final json = variant.toJson();
      expect(json['variantId'], 'v2');
      expect(json['stockQuantity'], 0);
    });
  });

  group('ProductQuestion serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'questionId': 'q1',
        'productId': 'p1',
        'sellerId': 's1',
        'askerId': 'b1',
        'question': 'Is this waterproof?',
        'answer': 'Yes!',
        'answeredAt': '2026-02-01T00:00:00.000',
        'answeredBy': 's1',
        'isAnswered': true,
        'upvotes': 5,
        'createdAt': '2026-01-20T00:00:00.000',
      };
      final q = ProductQuestion.fromJson(json);
      expect(q.questionId, 'q1');
      expect(q.question, 'Is this waterproof?');
      expect(q.answer, 'Yes!');
      expect(q.isAnswered, true);
      expect(q.upvotes, 5);

      final output = q.toJson();
      expect(output['questionId'], 'q1');
    });

    test('fromJson without answer', () {
      final json = {
        'questionId': 'q2',
        'productId': 'p1',
        'sellerId': 's1',
        'askerId': 'b2',
        'question': 'Size guide?',
        'createdAt': '2026-01-20T00:00:00.000',
      };
      final q = ProductQuestion.fromJson(json);
      expect(q.answer, isNull);
      expect(q.answeredAt, isNull);
      expect(q.isAnswered, false);
      expect(q.upvotes, 0);
    });
  });

  group('SupplierInfo serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'type': 'aliexpress',
        'supplierUrl': 'https://aliexpress.com/item/123',
        'supplierSku': 'ALI-123',
        'cost': 5.99,
        'currency': 'USD',
        'shippingDays': '7-15',
        'hasTracking': true,
        'notes': 'Good supplier',
      };
      final info = SupplierInfo.fromJson(json);
      expect(info.type, 'aliexpress');
      expect(info.supplierUrl, 'https://aliexpress.com/item/123');
      expect(info.cost, 5.99);
      expect(info.currency, 'USD');
      expect(info.hasTracking, true);

      final output = info.toJson();
      expect(output['type'], 'aliexpress');
    });
  });

  group('SellerWarehouse serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'warehouseId': 'wh1',
        'label': 'Main Warehouse',
        'type': 'warehouse',
        'address': {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M1M 1M1',
          'country': 'CA',
        },
        'isDefault': true,
        'createdAt': '2026-01-01T00:00:00.000',
      };
      final wh = SellerWarehouse.fromJson(json);
      expect(wh.warehouseId, 'wh1');
      expect(wh.label, 'Main Warehouse');
      expect(wh.isDefault, true);
      expect(wh.type, 'warehouse');
      expect(wh.address.city, 'Toronto');

      final output = wh.toJson();
      expect(output['warehouseId'], 'wh1');
    });
  });

  group('Product with nested objects', () {
    test('fromJson with supplier and inventory', () {
      final json = {
        'productId': 'p3',
        'name': 'Dropship Product',
        'price': 49.99,
        'description': 'From AliExpress',
        'imageUrls': ['img.jpg'],
        'sellerId': 's3',
        'categoryId': 3,
        'stockQuantity': 100,
        'createdAt': '2026-01-01T00:00:00.000',
        'supplier': {
          'type': 'aliexpress',
          'supplierUrl': 'https://ali.com/item',
          'supplierSku': 'ALI-456',
          'cost': 10.0,
          'currency': 'USD',
        },
        'inventory': {
          'managed': true,
          'trackQuantity': true,
          'allowBackorder': false,
          'lowStockThreshold': 3,
        },
        'deliveryOptions': [
          {
            'type': 'standard',
            'description': 'Standard Shipping',
            'costCents': 500,
            'estimatedDays': 5,
          },
        ],
        'variants': [
          {
            'variantId': 'v1',
            'stockQuantity': 50,
            'optionValues': {'Color': 'Black'},
          },
        ],
        'variantOptions': [
          {
            'name': 'Color',
            'values': ['Black', 'White'],
          },
        ],
      };
      final product = Product.fromJson(json);
      expect(product.supplier, isNotNull);
      expect(product.supplier!.type, 'aliexpress');
      expect(product.inventory, isNotNull);
      expect(product.inventory!.managed, true);
      expect(product.deliveryOptions.length, 1);
      expect(product.variants.length, 1);
      expect(product.variantOptions.length, 1);
    });

    test('toJson preserves nested sellerAddress', () {
      final product = Product.fromJson({
        'productId': 'p4',
        'name': 'Nested',
        'price': 19.99,
        'description': 'Test',
        'imageUrls': <String>[],
        'sellerId': 's4',
        'categoryId': 1,
        'stockQuantity': 10,
        'createdAt': '2026-01-01T00:00:00.000',
        'sellerAddress': {
          'street': '123 Main St',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V 1A1',
          'country': 'CA',
        },
      });
      final json = product.toJson();
      expect(json['sellerAddress'], isNotNull);
    });
  });

  // ── Order Models ──

  group('Order serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'orderId': 'o1',
        'userId': 'u1',
        'items': [
          {
            'productId': 'p1',
            'name': 'Product 1',
            'description': 'Desc',
            'price': 20.0,
            'quantity': 2,
            'imageUrls': ['img.jpg'],
            'sellerId': 's1',
          },
        ],
        'totalAmountCents': 5000,
        'subtotalCents': 4000,
        'shippingCostCents': 500,
        'taxAmountCents': 500,
        'taxes': <String, dynamic>{
          'GST': 2.5,
          'PST': 0.0,
          'HST': 0.0,
          'QST': 0.0,
        },
        'createdAt': '2026-01-01T00:00:00.000',
        'shippingAddress': {
          'street': '456 Oak Ave',
          'city': 'Vancouver',
          'state': 'BC',
          'postalCode': 'V6B 1A1',
          'country': 'CA',
        },
        'orderStatus': 'pending',
        'paymentStatus': 'paid',
        'stripePaymentIntentId': 'pi_123',
        'deliveryInstructions': 'Leave at door',
        'sellerIds': ['s1'],
        'productIds': ['p1'],
        'couponCode': 'SAVE10',
        'discountAmountCents': 500,
        'confirmedByClient': true,
        'confirmedAt': '2026-01-05T00:00:00.000',
        'capturedAt': '2026-01-02T00:00:00.000',
        'expiresAt': '2026-01-10T00:00:00.000',
        'autoConfirmed': true,
        'autoCaptured': false,
        'refundAmountCents': 0,
        'stockRestored': false,
        'requiresManualReview': false,
        'fraudScore': 10,
      };
      final order = Order.fromJson(json);
      expect(order.orderId, 'o1');
      expect(order.userId, 'u1');
      expect(order.totalAmountCents, 5000);
      expect(order.items.length, 1);
      expect(order.items.first.productId, 'p1');
      expect(order.shippingAddress, isNotNull);
      expect(order.stripePaymentIntentId, 'pi_123');
      expect(order.deliveryInstructions, 'Leave at door');
      expect(order.couponCode, 'SAVE10');
      expect(order.discountAmountCents, 500);
      expect(order.confirmedByClient, true);
      expect(order.autoConfirmed, true);
      expect(order.fraudScore, 10);
    });

    test('toJson roundtrip', () {
      final order = Order.fromJson({
        'orderId': 'o2',
        'userId': 'u2',
        'totalAmountCents': 3000,
        'subtotalCents': 2500,
        'taxAmountCents': 250,
        'shippingCostCents': 250,
        'taxes': <String, dynamic>{
          'GST': 0.0,
          'PST': 0.0,
          'HST': 0.0,
          'QST': 0.0,
        },
        'createdAt': '2026-02-01T00:00:00.000',
        'items': <Map<String, dynamic>>[],
      });
      final json = order.toJson();
      expect(json['orderId'], 'o2');
      expect(json['totalAmountCents'], 3000);
    });

    test('fromJson with minimal fields', () {
      final order = Order.fromJson({
        'orderId': 'o3',
        'userId': 'u3',
        'totalAmountCents': 1000,
        'subtotalCents': 800,
        'taxAmountCents': 100,
        'shippingCostCents': 100,
        'taxes': <String, dynamic>{
          'GST': 0.0,
          'PST': 0.0,
          'HST': 0.0,
          'QST': 0.0,
        },
        'createdAt': '2026-01-01T00:00:00.000',
        'items': <Map<String, dynamic>>[],
      });
      expect(order.stripePaymentIntentId, isNull);
      expect(order.deliveryInstructions, isNull);
      expect(order.couponCode, isNull);
      expect(order.confirmedByClient, false);
      expect(order.autoConfirmed, false);
      expect(order.requiresManualReview, false);
      expect(order.fraudScore, 0);
      expect(order.version, 1);
      expect(order.schemaVersion, 1);
    });
  });

  group('OrderItem serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'productId': 'p1',
        'name': 'Test Item',
        'description': 'A desc',
        'price': 15.0,
        'quantity': 3,
        'imageUrls': ['item.jpg'],
        'sellerId': 's1',
        'status': 'pending',
        'isPerishable': true,
        'isDigital': false,
        'variantId': 'v1',
        'variantOptions': {'Size': 'M'},
        'weightKg': 0.5,
        'estimatedShipDays': 2,
        'taxCode': 'TAX001',
        'buyerNote': 'Handle with care',
      };
      final item = OrderItem.fromJson(json);
      expect(item.productId, 'p1');
      expect(item.name, 'Test Item');
      expect(item.quantity, 3);
      expect(item.price, 15.0);
      expect(item.isPerishable, true);
      expect(item.variantId, 'v1');
      expect(item.buyerNote, 'Handle with care');

      final output = item.toJson();
      expect(output['productId'], 'p1');
      expect(output['quantity'], 3);
    });

    test('fromJson with minimal fields', () {
      final item = OrderItem.fromJson({
        'productId': 'p2',
        'name': 'Minimal',
        'description': 'D',
        'price': 5.0,
        'quantity': 1,
        'imageUrls': <String>[],
        'sellerId': 's2',
      });
      expect(item.status, 'pending');
      expect(item.isPerishable, false);
      expect(item.isDigital, false);
      expect(item.freeShipping, false);
      expect(item.confirmedByBuyer, false);
      expect(item.digitalUnlocked, false);
      expect(item.estimatedShipDays, 3);
      expect(item.minimumOrderQuantity, 1);
    });
  });

  group('Address serialization', () {
    test('fromJson and toJson', () {
      final json = {
        'street': '100 King St',
        'city': 'Toronto',
        'state': 'ON',
        'postalCode': 'M5V 2T6',
        'country': 'CA',
        'apartment': '12B',
      };
      final address = Address.fromJson(json);
      expect(address.street, '100 King St');
      expect(address.city, 'Toronto');
      expect(address.state, 'ON');
      expect(address.postalCode, 'M5V 2T6');
      expect(address.country, 'CA');
      expect(address.apartment, '12B');

      final output = address.toJson();
      expect(output['street'], '100 King St');
      expect(output['apartment'], '12B');
    });
  });

  group('ProductCreate serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'name': 'New Product',
        'price': 25.0,
        'description': 'Fresh product',
        'imageUrls': ['img1.jpg'],
        'sellerId': 's1',
        'categoryId': 2,
        'stockQuantity': 100,
        'isDigital': false,
        'isPerishable': false,
        'isLocalDeliveryOnly': false,
        'estimatedShipDays': 5,
        'keywords': ['new', 'fresh'],
      };
      final create = ProductCreate.fromJson(json);
      expect(create.name, 'New Product');
      expect(create.price, 25.0);
      expect(create.sellerId, 's1');
      expect(create.stockQuantity, 100);
    });

    test('toJson roundtrip', () {
      final create = ProductCreate.fromJson({
        'name': 'Roundtrip',
        'price': 15.0,
        'description': 'Test',
        'imageUrls': <String>[],
        'sellerId': 's2',
        'categoryId': 1,
        'stockQuantity': 50,
      });
      final json = create.toJson();
      expect(json['name'], 'Roundtrip');
      expect(json['price'], 15.0);
    });
  });

  group('Product digital fields', () {
    test('product with digital type', () {
      final product = Product.fromJson({
        'productId': 'p11',
        'name': 'Ebook',
        'price': 5.0,
        'description': 'Digital book',
        'imageUrls': <String>[],
        'sellerId': 's1',
        'categoryId': 1,
        'stockQuantity': 999,
        'createdAt': '2026-01-01T00:00:00.000',
        'isDigital': true,
        'digitalType': 'ebook',
        'slug': 'my-ebook',
        'digitalBuilds': {'pdf': 'https://dl.com/book.pdf'},
        'deviceLimit': 3,
      });
      expect(product.isDigital, true);
      expect(product.digitalType, 'ebook');
      expect(product.slug, 'my-ebook');
      expect(product.deviceLimit, 3);
      expect(product.digitalBuilds!['pdf'], 'https://dl.com/book.pdf');
    });
  });

  // ── Address Model Comprehensive Tests ──

  group('Address comprehensive serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'street': '123 Main Street',
        'apartment': 'Apt 4B',
        'city': 'Toronto',
        'state': 'ON',
        'postalCode': 'M5V 1A1',
        'country': 'Canada',
        'phoneNumber': '+1-416-555-1234',
        'isDefault': true,
        'addressId': 'addr_123',
        'label': 'Home',
        'latitude': 43.6532,
        'longitude': -79.3832,
      };
      final address = Address.fromJson(json);
      expect(address.street, '123 Main Street');
      expect(address.apartment, 'Apt 4B');
      expect(address.city, 'Toronto');
      expect(address.state, 'ON');
      expect(address.postalCode, 'M5V 1A1');
      expect(address.country, 'Canada');
      expect(address.phoneNumber, '+1-416-555-1234');
      expect(address.isDefault, true);
      expect(address.addressId, 'addr_123');
      expect(address.label, 'Home');
      expect(address.latitude, 43.6532);
      expect(address.longitude, -79.3832);
    });

    test('fromJson with null/missing optional fields', () {
      final json = {
        'street': '456 Oak Ave',
        'city': 'Vancouver',
        'state': 'BC',
        'postalCode': 'V6B 2W2',
      };
      final address = Address.fromJson(json);
      expect(address.street, '456 Oak Ave');
      expect(address.apartment, '');
      expect(address.city, 'Vancouver');
      expect(address.state, 'BC');
      expect(address.postalCode, 'V6B 2W2');
      expect(address.country, 'Canada');
      expect(address.phoneNumber, isNull);
      expect(address.isDefault, false);
      expect(address.addressId, isNull);
      expect(address.label, isNull);
      expect(address.latitude, isNull);
      expect(address.longitude, isNull);
    });

    test('toJson roundtrip preserves all data', () {
      final original = Address(
        street: '789 Pine Rd',
        apartment: 'Unit 5',
        city: 'Montreal',
        state: 'QC',
        postalCode: 'H2X 1Y4',
        country: 'Canada',
        phoneNumber: '+1-514-555-5678',
        isDefault: false,
        addressId: 'addr_456',
        label: 'Work',
        latitude: 45.5017,
        longitude: -73.5673,
      );
      final json = original.toJson();
      final restored = Address.fromJson(json);
      expect(restored.street, original.street);
      expect(restored.apartment, original.apartment);
      expect(restored.city, original.city);
      expect(restored.state, original.state);
      expect(restored.postalCode, original.postalCode);
      expect(restored.country, original.country);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.isDefault, original.isDefault);
      expect(restored.addressId, original.addressId);
      expect(restored.label, original.label);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });

    test('copyWith modifies specified fields', () {
      final original = Address(
        street: '100 King St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
        isDefault: false,
      );
      final modified = original.copyWith(
        street: '200 Queen St',
        isDefault: true,
        label: 'Home',
      );
      expect(modified.street, '200 Queen St');
      expect(modified.city, 'Toronto');
      expect(modified.isDefault, true);
      expect(modified.label, 'Home');
      expect(original.isDefault, false);
      expect(original.label, isNull);
    });

    test('equality operators work correctly', () {
      final addr1 = Address(
        street: '100 King St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      );
      final addr2 = Address(
        street: '100 King St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      );
      final addr3 = Address(
        street: '200 Queen St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      );
      expect(addr1, equals(addr2));
      expect(addr1, isNot(equals(addr3)));
      expect(addr1.hashCode, equals(addr2.hashCode));
    });

    test('formattedAddress getter formats correctly', () {
      final address = Address(
        street: '123 Main St',
        apartment: 'Apt 5',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(address.formattedAddress, contains('123 Main St'));
      expect(address.formattedAddress, contains('Apt 5'));
      expect(address.formattedAddress, contains('Toronto'));
    });

    test('fullAddress getter formats correctly', () {
      final address = Address(
        street: '123 Main St',
        apartment: 'Apt 5',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(
        address.fullAddress,
        '123 Main St, Apt 5, Toronto, ON, M5V 1A1, Canada',
      );
    });
  });

  // ── Order Model Comprehensive Tests ──

  group('Order comprehensive serialization', () {
    final completeOrderJson = {
      'orderId': 'order_complete_1',
      'userId': 'user_123',
      'version': 2,
      'schemaVersion': 1,
      'customerId': 'cus_abc123',
      'customerEmail': 'buyer@example.com',
      'items': [
        {
          'productId': 'prod_1',
          'name': 'Test Product',
          'description': 'A test product',
          'price': 29.99,
          'quantity': 2,
          'imageUrls': ['img1.jpg', 'img2.jpg'],
          'sellerId': 'seller_1',
          'status': 'pending',
        },
      ],
      'totalAmountCents': 5998,
      'subtotalCents': 5998,
      'shippingCostCents': 0,
      'taxAmountCents': 779,
      'taxes': {'GST': 5.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
      'orderStatus': 'pending',
      'paymentStatus': 'awaiting_payment',
      'shippingAddress': {
        'street': '100 Buyer St',
        'city': 'Toronto',
        'state': 'ON',
        'postalCode': 'M5V 1A1',
        'country': 'Canada',
      },
      'createdAt': '2026-03-21T10:00:00.000',
      'currency': 'cad',
      'sellerIds': ['seller_1'],
      'productIds': ['prod_1'],
      'stripeSessionId': 'cs_test_123',
      'stripePaymentIntentId': 'pi_test_456',
      'shippingApprovalStatus': 'not_required',
      'shippingApprovalRequired': false,
      'actualShippingCents': 0,
      'pendingTotalCents': 6777,
      'sellerPayouts': [
        {
          'sellerId': 'seller_1',
          'amountCents': 5998,
          'platformFeeCents': 150,
          'netAmountCents': 5848,
          'status': 'pending',
        },
      ],
      'confirmedByClient': false,
      'platformFeeTotalCents': 150,
      'payoutStatus': 'pending',
      'ratings': <Map<String, dynamic>>[],
      'captureAttempts': 0,
      'autoConfirmed': false,
      'autoCaptured': false,
      'refundAmountCents': 0,
      'stockRestored': false,
      'requiresManualReview': false,
      'fraudScore': 0,
      'itemTaxes': <Map<String, dynamic>>[],
      'taxExempt': false,
      'discountAmountCents': 0,
    };

    test('fromJson with all fields', () {
      final order = Order.fromJson(completeOrderJson);
      expect(order.orderId, 'order_complete_1');
      expect(order.userId, 'user_123');
      expect(order.version, 2);
      expect(order.schemaVersion, 1);
      expect(order.customerId, 'cus_abc123');
      expect(order.customerEmail, 'buyer@example.com');
      expect(order.items.length, 1);
      expect(order.items.first.productId, 'prod_1');
      expect(order.totalAmountCents, 5998);
      expect(order.subtotalCents, 5998);
      expect(order.shippingCostCents, 0);
      expect(order.taxAmountCents, 779);
      expect(order.orderStatus, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaitingPayment);
      expect(order.shippingAddress, isNotNull);
      expect(order.shippingAddress!.city, 'Toronto');
      expect(order.currency, 'cad');
      expect(order.sellerIds, ['seller_1']);
      expect(order.productIds, ['prod_1']);
      expect(order.stripeSessionId, 'cs_test_123');
      expect(order.stripePaymentIntentId, 'pi_test_456');
      expect(order.shippingApprovalStatus, ShippingApprovalStatus.notRequired);
      expect(order.sellerPayouts.length, 1);
      expect(order.sellerPayouts.first.sellerId, 'seller_1');
      expect(order.fraudScore, 0);
    });

    test('fromJson with null/missing optional fields', () {
      final minimalJson = {
        'orderId': 'order_minimal',
        'userId': 'user_456',
        'items': <Map<String, dynamic>>[],
        'totalAmountCents': 1000,
        'subtotalCents': 1000,
        'taxes': {'GST': 0.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
        'createdAt': '2026-03-21T10:00:00.000',
      };
      final order = Order.fromJson(minimalJson);
      expect(order.orderId, 'order_minimal');
      expect(order.version, 1);
      expect(order.schemaVersion, 1);
      expect(order.customerId, isNull);
      expect(order.customerEmail, isNull);
      expect(order.shippingCostCents, 0);
      expect(order.taxAmountCents, 0);
      expect(order.orderStatus, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaitingPayment);
      expect(order.shippingAddress, isNull);
      expect(order.currency, 'cad');
      expect(order.stripeSessionId, isNull);
      expect(order.stripePaymentIntentId, isNull);
      expect(order.confirmedByClient, false);
      expect(order.autoConfirmed, false);
      expect(order.fraudScore, 0);
      expect(order.discountAmountCents, 0);
    });

    test('toJson roundtrip preserves top-level data', () {
      final original = Order.fromJson(completeOrderJson);
      final json = original.toJson();
      expect(json['orderId'], original.orderId);
      expect(json['userId'], original.userId);
      expect(json['totalAmountCents'], original.totalAmountCents);
      expect(json['orderStatus'], 'pending');
      expect(json['currency'], 'cad');
    });

    test('copyWith modifies specified fields', () {
      final original = Order.fromJson(completeOrderJson);
      final modified = original.copyWith(
        orderStatus: OrderStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        confirmedByClient: true,
      );
      expect(modified.orderStatus, OrderStatus.confirmed);
      expect(modified.paymentStatus, PaymentStatus.paid);
      expect(modified.confirmedByClient, true);
      expect(original.orderStatus, OrderStatus.pending);
      expect(original.confirmedByClient, false);
    });

    test('equality operators work correctly', () {
      final order1 = Order.fromJson({
        'orderId': 'order_eq_test',
        'userId': 'user_1',
        'items': <Map<String, dynamic>>[],
        'totalAmountCents': 1000,
        'subtotalCents': 1000,
        'taxes': {'GST': 0.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
        'createdAt': '2026-03-21T10:00:00.000',
      });
      final order2 = Order.fromJson({
        'orderId': 'order_eq_test',
        'userId': 'user_1',
        'items': <Map<String, dynamic>>[],
        'totalAmountCents': 1000,
        'subtotalCents': 1000,
        'taxes': {'GST': 0.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
        'createdAt': '2026-03-21T10:00:00.000',
      });
      final order3 = Order.fromJson({
        'orderId': 'order_different',
        'userId': 'user_1',
        'items': <Map<String, dynamic>>[],
        'totalAmountCents': 1000,
        'subtotalCents': 1000,
        'taxes': {'GST': 0.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
        'createdAt': '2026-03-21T10:00:00.000',
      });
      expect(order1, equals(order2));
      expect(order1, isNot(equals(order3)));
    });

    test('dollar amount getters work correctly', () {
      final order = Order.fromJson({
        'orderId': 'order_getters',
        'userId': 'user_1',
        'items': <Map<String, dynamic>>[],
        'totalAmountCents': 10000,
        'subtotalCents': 8500,
        'shippingCostCents': 500,
        'taxAmountCents': 1000,
        'taxes': {'GST': 0.0, 'PST': 0.0, 'HST': 0.0, 'QST': 0.0},
        'createdAt': '2026-03-21T10:00:00.000',
        'platformFeeTotalCents': 250,
        'refundAmountCents': 0,
        'pendingTotalCents': 10000,
        'actualShippingCents': 450,
      });
      expect(order.total, 100.0);
      expect(order.subtotal, 85.0);
      expect(order.shippingCost, 5.0);
      expect(order.taxAmount, 10.0);
      expect(order.platformFeeTotal, 2.5);
      expect(order.actualShipping, 4.5);
    });
  });

  // ── OrderItem Model Comprehensive Tests ──

  group('OrderItem comprehensive serialization', () {
    final completeItemJson = {
      'productId': 'prod_item_1',
      'cartItemId': 'cart_item_123',
      'name': 'Premium Widget',
      'description': 'High-quality widget with extra features',
      'price': 49.99,
      'quantity': 3,
      'imageUrls': ['widget1.jpg', 'widget2.jpg'],
      'sellerId': 'seller_xyz',
      'sellerAddress': {
        'street': '500 Seller Lane',
        'city': 'Vancouver',
        'state': 'BC',
        'postalCode': 'V6B 1A1',
        'country': 'Canada',
      },
      'status': 'pending',
      'trackingNumber': 'TRACK123456',
      'carrier': 'canada_post',
      'carrierNote': 'Signature required',
      'sellerSku': 'WIDGET-SKU-001',
      'sellerName': 'Widget Factory',
      'shippedAt': '2026-03-22T14:00:00.000',
      'deliveredAt': null,
      'refundedAt': null,
      'confirmedByBuyer': false,
      'variantId': 'var_blue_large',
      'variantTitle': 'Blue - Large',
      'variantOptions': {'Color': 'Blue', 'Size': 'Large'},
      'variantSku': 'WIDGET-BL-L',
      'weightKg': 0.75,
      'lengthCm': 20.0,
      'widthCm': 15.0,
      'heightCm': 10.0,
      'isLocalDeliveryOnly': false,
      'isPerishable': false,
      'estimatedShipDays': 3,
      'minimumOrderQuantity': 1,
      'freeShipping': true,
      'isDigital': false,
      'taxCode': 'TAX_STANDARD',
      'buyerNote': 'Please gift wrap',
      'fulfillmentWarehouseId': 'wh_main',
    };

    test('fromJson with all fields', () {
      final item = OrderItem.fromJson(completeItemJson);
      expect(item.productId, 'prod_item_1');
      expect(item.cartItemId, 'cart_item_123');
      expect(item.name, 'Premium Widget');
      expect(item.description, 'High-quality widget with extra features');
      expect(item.price, 49.99);
      expect(item.quantity, 3);
      expect(item.imageUrls.length, 2);
      expect(item.sellerId, 'seller_xyz');
      expect(item.sellerAddress, isNotNull);
      expect(item.sellerAddress!.city, 'Vancouver');
      expect(item.status, 'pending');
      expect(item.trackingNumber, 'TRACK123456');
      expect(item.carrier, 'canada_post');
      expect(item.carrierNote, 'Signature required');
      expect(item.sellerSku, 'WIDGET-SKU-001');
      expect(item.sellerName, 'Widget Factory');
      expect(item.variantId, 'var_blue_large');
      expect(item.variantTitle, 'Blue - Large');
      expect(item.variantOptions, {'Color': 'Blue', 'Size': 'Large'});
      expect(item.weightKg, 0.75);
      expect(item.freeShipping, true);
      expect(item.buyerNote, 'Please gift wrap');
    });

    test('fromJson with null/missing optional fields', () {
      final minimalJson = {
        'productId': 'prod_minimal',
        'name': 'Minimal Product',
        'description': 'Basic item',
        'price': 9.99,
        'quantity': 1,
        'imageUrls': <String>[],
        'sellerId': 'seller_min',
      };
      final item = OrderItem.fromJson(minimalJson);
      expect(item.productId, 'prod_minimal');
      expect(item.cartItemId, isNull);
      expect(item.status, 'pending');
      expect(item.trackingNumber, isNull);
      expect(item.carrier, isNull);
      expect(item.sellerAddress, isNull);
      expect(item.variantId, isNull);
      expect(item.variantOptions, isNull);
      expect(item.weightKg, isNull);
      expect(item.isPerishable, false);
      expect(item.isDigital, false);
      expect(item.freeShipping, false);
      expect(item.confirmedByBuyer, false);
      expect(item.estimatedShipDays, 3);
      expect(item.minimumOrderQuantity, 1);
      expect(item.buyerNote, isNull);
    });

    test('toJson produces correct structure', () {
      final original = OrderItem.fromJson(completeItemJson);
      final json = original.toJson();
      expect(json['productId'], original.productId);
      expect(json['name'], original.name);
      expect(json['price'], original.price);
      expect(json['quantity'], original.quantity);
      expect(json['sellerId'], original.sellerId);
      expect(json['trackingNumber'], original.trackingNumber);
      expect(json['freeShipping'], original.freeShipping);
    });

    test('copyWith modifies specified fields', () {
      final original = OrderItem.fromJson(completeItemJson);
      final modified = original.copyWith(
        status: 'shipped',
        quantity: 5,
        trackingNumber: 'NEWTRACK999',
      );
      expect(modified.status, 'shipped');
      expect(modified.quantity, 5);
      expect(modified.trackingNumber, 'NEWTRACK999');
      expect(original.status, 'pending');
      expect(original.quantity, 3);
    });

    test('equality operators work correctly', () {
      final item1 = OrderItem.fromJson({
        'productId': 'prod_eq',
        'name': 'Test',
        'description': 'Desc',
        'price': 10.0,
        'quantity': 1,
        'imageUrls': <String>[],
        'sellerId': 'seller_1',
      });
      final item2 = OrderItem.fromJson({
        'productId': 'prod_eq',
        'name': 'Test',
        'description': 'Desc',
        'price': 10.0,
        'quantity': 1,
        'imageUrls': <String>[],
        'sellerId': 'seller_1',
      });
      final item3 = OrderItem.fromJson({
        'productId': 'prod_diff',
        'name': 'Test',
        'description': 'Desc',
        'price': 10.0,
        'quantity': 1,
        'imageUrls': <String>[],
        'sellerId': 'seller_1',
      });
      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('subtotal getter calculates correctly', () {
      final item = OrderItem.fromJson({
        'productId': 'prod_subtotal',
        'name': 'Test',
        'description': 'Desc',
        'price': 19.99,
        'quantity': 3,
        'imageUrls': <String>[],
        'sellerId': 'seller_1',
      });
      expect(item.subtotal, closeTo(59.97, 0.001));
    });
  });

  // ── SellerProfile Model Comprehensive Tests ──

  group('SellerProfile comprehensive serialization', () {
    final completeSellerJson = {
      'stripeAccountId': 'acct_stripe_123',
      'payoutsEnabled': true,
      'chargesEnabled': true,
      'onboardingCompleted': true,
      'pendingRequirements': <String>[],
      'commissionRateBps': 250,
      'avgRating': 4.85,
      'totalReviews': 127,
      'totalSales': 543,
      'warehouseIds': ['wh_1', 'wh_2'],
      'businessName': 'Acme Widgets Inc.',
      'businessAddress': {
        'street': '1000 Industrial Blvd',
        'city': 'Mississauga',
        'state': 'ON',
        'postalCode': 'L5N 7A1',
        'country': 'Canada',
      },
      'acceptsReturns': true,
      'returnWindowDays': 30,
      'verified': true,
      'verificationStatus': 'verified',
      'platform': 'web',
      'payoutHoldDays': 7,
      'bankAccountLast4': '6789',
      'createdAt': '2025-01-15T00:00:00.000',
      'updatedAt': '2026-03-20T12:00:00.000',
    };

    test('fromJson with all fields', () {
      final seller = SellerProfile.fromJson(completeSellerJson);
      expect(seller.stripeAccountId, 'acct_stripe_123');
      expect(seller.payoutsEnabled, true);
      expect(seller.chargesEnabled, true);
      expect(seller.onboardingCompleted, true);
      expect(seller.pendingRequirements, isEmpty);
      expect(seller.commissionRateBps, 250);
      expect(seller.avgRating, 4.85);
      expect(seller.totalReviews, 127);
      expect(seller.totalSales, 543);
      expect(seller.warehouseIds, ['wh_1', 'wh_2']);
      expect(seller.businessName, 'Acme Widgets Inc.');
      expect(seller.businessAddress, isNotNull);
      expect(seller.businessAddress!.city, 'Mississauga');
      expect(seller.acceptsReturns, true);
      expect(seller.returnWindowDays, 30);
      expect(seller.verified, true);
      expect(seller.verificationStatus, 'verified');
      expect(seller.payoutHoldDays, 7);
      expect(seller.bankAccountLast4, '6789');
    });

    test('fromJson with null/missing optional fields', () {
      final minimalJson = <String, dynamic>{};
      final seller = SellerProfile.fromJson(minimalJson);
      expect(seller.stripeAccountId, isNull);
      expect(seller.payoutsEnabled, false);
      expect(seller.chargesEnabled, false);
      expect(seller.onboardingCompleted, false);
      expect(seller.pendingRequirements, isNull);
      expect(seller.commissionRateBps, 250);
      expect(seller.avgRating, 0.0);
      expect(seller.totalReviews, 0);
      expect(seller.totalSales, 0);
      expect(seller.warehouseIds, isNull);
      expect(seller.businessName, isNull);
      expect(seller.businessAddress, isNull);
      expect(seller.acceptsReturns, true);
      expect(seller.returnWindowDays, 30);
      expect(seller.verified, false);
      expect(seller.verificationStatus, isNull);
      expect(seller.bankAccountLast4, isNull);
    });

    test('fromJson with pending requirements', () {
      final json = {
        'stripeAccountId': 'acct_pending',
        'payoutsEnabled': false,
        'chargesEnabled': true,
        'onboardingCompleted': false,
        'pendingRequirements': ['identity.document', 'address.proof'],
      };
      final seller = SellerProfile.fromJson(json);
      expect(seller.pendingRequirements, isNotNull);
      expect(seller.pendingRequirements!.length, 2);
      expect(seller.pendingRequirements, contains('identity.document'));
    });

    test('toJson produces correct structure', () {
      final original = SellerProfile.fromJson(completeSellerJson);
      final json = original.toJson();
      expect(json['stripeAccountId'], original.stripeAccountId);
      expect(json['payoutsEnabled'], original.payoutsEnabled);
      expect(json['commissionRateBps'], original.commissionRateBps);
      expect(json['avgRating'], original.avgRating);
      expect(json['totalReviews'], original.totalReviews);
      expect(json['totalSales'], original.totalSales);
      expect(json['businessName'], original.businessName);
    });

    test('copyWith modifies specified fields', () {
      final original = SellerProfile.fromJson(completeSellerJson);
      final modified = original.copyWith(
        payoutsEnabled: false,
        avgRating: 4.95,
        totalSales: 600,
      );
      expect(modified.payoutsEnabled, false);
      expect(modified.avgRating, 4.95);
      expect(modified.totalSales, 600);
      expect(original.payoutsEnabled, true);
      expect(original.avgRating, 4.85);
      expect(original.totalSales, 543);
    });

    test('equality operators work correctly', () {
      final seller1 = SellerProfile.fromJson({
        'stripeAccountId': 'acct_eq',
        'avgRating': 4.5,
      });
      final seller2 = SellerProfile.fromJson({
        'stripeAccountId': 'acct_eq',
        'avgRating': 4.5,
      });
      final seller3 = SellerProfile.fromJson({
        'stripeAccountId': 'acct_diff',
        'avgRating': 4.5,
      });
      expect(seller1, equals(seller2));
      expect(seller1, isNot(equals(seller3)));
    });

    test('fromMap works correctly', () {
      final map = {
        'stripeAccountId': 'acct_frommap',
        'payoutsEnabled': true,
        'avgRating': 4.7,
        'totalReviews': 50,
        'businessAddress': {
          'street': '200 Main',
          'city': 'Calgary',
          'state': 'AB',
          'postalCode': 'T2P 1A1',
          'country': 'Canada',
        },
      };
      final seller = SellerProfile.fromMap(map);
      expect(seller.stripeAccountId, 'acct_frommap');
      expect(seller.payoutsEnabled, true);
      expect(seller.avgRating, 4.7);
      expect(seller.totalReviews, 50);
      expect(seller.businessAddress, isNotNull);
      expect(seller.businessAddress!.city, 'Calgary');
    });
  });

  // ── SellerPayout Model Tests ──

  group('SellerPayout serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'sellerId': 'seller_payout_1',
        'stripeAccountId': 'acct_payout',
        'amountCents': 10000,
        'platformFeeCents': 250,
        'netAmountCents': 9750,
        'status': 'pending',
        'payoutDate': '2026-03-25T00:00:00.000',
        'stripeTransferId': 'tr_transfer_123',
        'failureReason': null,
      };
      final payout = SellerPayout.fromJson(json);
      expect(payout.sellerId, 'seller_payout_1');
      expect(payout.stripeAccountId, 'acct_payout');
      expect(payout.amountCents, 10000);
      expect(payout.platformFeeCents, 250);
      expect(payout.netAmountCents, 9750);
      expect(payout.status, 'pending');
      expect(payout.stripeTransferId, 'tr_transfer_123');
    });

    test('fromJson with minimal fields', () {
      final json = {
        'sellerId': 'seller_min',
        'amountCents': 5000,
        'platformFeeCents': 125,
        'netAmountCents': 4875,
      };
      final payout = SellerPayout.fromJson(json);
      expect(payout.sellerId, 'seller_min');
      expect(payout.status, 'pending');
      expect(payout.stripeAccountId, isNull);
      expect(payout.payoutDate, isNull);
    });

    test('dollar amount getters work correctly', () {
      final payout = SellerPayout.fromJson({
        'sellerId': 's1',
        'amountCents': 10000,
        'platformFeeCents': 250,
        'netAmountCents': 9750,
      });
      expect(payout.amount, 100.0);
      expect(payout.platformFee, 2.5);
      expect(payout.netAmount, 97.5);
    });

    test('toJson roundtrip', () {
      final original = SellerPayout.fromJson({
        'sellerId': 'seller_rt',
        'amountCents': 7500,
        'platformFeeCents': 187,
        'netAmountCents': 7313,
        'status': 'completed',
      });
      final json = original.toJson();
      final restored = SellerPayout.fromJson(json);
      expect(restored.sellerId, original.sellerId);
      expect(restored.amountCents, original.amountCents);
      expect(restored.status, original.status);
    });
  });

  // ── Taxes Model Tests ──

  group('Taxes serialization', () {
    test('fromJson with all fields', () {
      final json = {'GST': 5.0, 'PST': 7.0, 'HST': 0.0, 'QST': 9.975};
      final taxes = Taxes.fromJson(json);
      expect(taxes.gst, 5.0);
      expect(taxes.pst, 7.0);
      expect(taxes.hst, 0.0);
      expect(taxes.qst, 9.975);
    });

    test('fromJson with missing fields uses defaults', () {
      final taxes = Taxes.fromJson({});
      expect(taxes.gst, 0.0);
      expect(taxes.pst, 0.0);
      expect(taxes.hst, 0.0);
      expect(taxes.qst, 0.0);
    });

    test('total getter sums correctly', () {
      final taxes = Taxes(gst: 5.0, pst: 7.0, hst: 13.0, qst: 9.975);
      expect(taxes.total, closeTo(34.975, 0.001));
    });

    test('toJson and toMap work correctly', () {
      final taxes = Taxes(gst: 5.0, pst: 7.0, hst: 0.0, qst: 0.0);
      final json = taxes.toJson();
      final map = taxes.toMap();
      expect(json['GST'], 5.0);
      expect(map['GST'], 5.0);
    });
  });

  // ── Ratings Model Tests ──

  group('Ratings serialization', () {
    test('fromJson with all fields', () {
      final json = {
        'productId': 'prod_rate',
        'rating': 4.5,
        'review': 'Great product!',
        'createdAt': '2026-03-21T10:00:00.000',
      };
      final rating = Ratings.fromJson(json);
      expect(rating.productId, 'prod_rate');
      expect(rating.rating, 4.5);
      expect(rating.review, 'Great product!');
    });

    test('fromJson without review', () {
      final json = {
        'productId': 'prod_noreview',
        'rating': 5.0,
        'createdAt': '2026-03-21T10:00:00.000',
      };
      final rating = Ratings.fromJson(json);
      expect(rating.productId, 'prod_noreview');
      expect(rating.rating, 5.0);
      expect(rating.review, isNull);
    });
  });
}
