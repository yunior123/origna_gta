import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/utils.dart';

void main() {
  group('Address', () {
    test('fromMap creates correct Address', () {
      final map = {
        'street': '123 Main St',
        'apartment': 'Unit 4B',
        'city': 'Toronto',
        'state': 'ON',
        'postalCode': 'M5V 1A1',
        'country': 'Canada',
        'phoneNumber': '416-555-1234',
        'isDefault': true,
        'label': 'Home',
        'latitude': 43.6532,
        'longitude': -79.3832,
      };

      final address = Address.fromMap(map);

      expect(address.street, '123 Main St');
      expect(address.apartment, 'Unit 4B');
      expect(address.city, 'Toronto');
      expect(address.state, 'ON');
      expect(address.postalCode, 'M5V 1A1');
      expect(address.country, 'Canada');
      expect(address.phoneNumber, '416-555-1234');
      expect(address.isDefault, true);
      expect(address.label, 'Home');
      expect(address.latitude, 43.6532);
      expect(address.longitude, -79.3832);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final address = Address.fromMap(map);

      expect(address.street, '');
      expect(address.apartment, '');
      expect(address.city, '');
      expect(address.state, '');
      expect(address.postalCode, '');
      expect(address.country, '');
      expect(address.phoneNumber, null);
      expect(address.isDefault, false);
      expect(address.label, null);
    });

    test('toMap returns correct map', () {
      final address = Address(
        street: '456 Oak Ave',
        apartment: 'Suite 100',
        city: 'Vancouver',
        state: 'BC',
        postalCode: 'V6B 1A1',
        country: 'Canada',
        phoneNumber: '604-555-5678',
        isDefault: true,
        label: 'Work',
        latitude: 49.2827,
        longitude: -123.1207,
      );

      final map = address.toMap();

      expect(map['street'], '456 Oak Ave');
      expect(map['apartment'], 'Suite 100');
      expect(map['city'], 'Vancouver');
      expect(map['state'], 'BC');
      expect(map['postalCode'], 'V6B 1A1');
      expect(map['country'], 'Canada');
      expect(map['phoneNumber'], '604-555-5678');
      expect(map['isDefault'], true);
      expect(map['label'], 'Work');
      expect(map['latitude'], 49.2827);
      expect(map['longitude'], -123.1207);
    });

    test('fullAddress returns formatted string', () {
      final address = Address(
        street: '123 Main St',
        apartment: 'Unit 4B',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );

      expect(address.fullAddress, '123 Main St, Unit 4B, Toronto, ON, M5V 1A1, Canada');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );

      final updated = original.copyWith(city: 'Vancouver', state: 'BC');

      expect(updated.street, '123 Main St');
      expect(updated.city, 'Vancouver');
      expect(updated.state, 'BC');
      expect(original.city, 'Toronto'); // Original unchanged
    });
  });

  group('UserModel', () {
    test('fromMap creates correct UserModel', () {
      final map = {
        'uid': 'user123',
        'email': 'test@example.com',
        'name': 'John Doe',
        'roles': ['buyer', 'seller'],
        'address': {
          'street': '123 Main St',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V 1A1',
          'country': 'Canada',
        },
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'customerId': 'cus_123',
        'stripeAccountId': 'acct_456',
        'payoutsEnabled': true,
        'chargesEnabled': true,
        'onboardingCompleted': true,
      };

      final user = UserModel.fromMap(map);

      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'John Doe');
      expect(user.roles, ['buyer', 'seller']);
      expect(user.address?.city, 'Toronto');
      expect(user.customerId, 'cus_123');
      expect(user.stripeAccountId, 'acct_456');
      expect(user.payoutsEnabled, true);
      expect(user.chargesEnabled, true);
      expect(user.onboardingCompleted, true);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'uid': 'user123',
        'email': 'test@example.com',
        'name': 'John Doe',
        'roles': ['buyer'],
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
      };

      final user = UserModel.fromMap(map);

      expect(user.uid, 'user123');
      expect(user.address, null);
      expect(user.customerId, null);
      expect(user.stripeAccountId, null);
      expect(user.payoutsEnabled, false);
    });

    test('toMap returns correct map', () {
      final user = UserModel(
        uid: 'user123',
        email: 'test@example.com',
        name: 'John Doe',
        roles: ['buyer', 'seller'],
        createdAt: DateTime(2024, 1, 15),
        customerId: 'cus_123',
        stripeAccountId: 'acct_456',
        payoutsEnabled: true,
        chargesEnabled: true,
        onboardingCompleted: true,
      );

      final map = user.toMap();

      expect(map['uid'], 'user123');
      expect(map['email'], 'test@example.com');
      expect(map['name'], 'John Doe');
      expect(map['roles'], ['buyer', 'seller']);
      expect(map['customerId'], 'cus_123');
      expect(map['stripeAccountId'], 'acct_456');
      expect(map['payoutsEnabled'], true);
    });

    test('canReceivePayouts returns true when conditions met', () {
      final seller = UserModel(
        uid: 'seller123',
        email: 'seller@example.com',
        name: 'Seller',
        roles: ['seller'],
        createdAt: DateTime.now(),
        payoutsEnabled: true,
        onboardingCompleted: true,
      );

      expect(seller.canReceivePayouts, true);
    });

    test('canReceivePayouts returns false when not onboarded', () {
      final seller = UserModel(
        uid: 'seller123',
        email: 'seller@example.com',
        name: 'Seller',
        roles: ['seller'],
        createdAt: DateTime.now(),
        payoutsEnabled: true,
        onboardingCompleted: false,
      );

      expect(seller.canReceivePayouts, false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = UserModel(
        uid: 'user123',
        email: 'test@example.com',
        name: 'John Doe',
        roles: ['buyer'],
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = original.copyWith(name: 'Jane Doe', roles: ['buyer', 'seller']);

      expect(updated.name, 'Jane Doe');
      expect(updated.roles, ['buyer', 'seller']);
      expect(updated.email, 'test@example.com'); // Unchanged
      expect(original.name, 'John Doe'); // Original unchanged
    });
  });

  group('ProductModel', () {
    test('fromMap creates correct ProductModel', () {
      final map = {
        'id': 'prod123',
        'name': 'Test Product',
        'price': 29.99,
        'imageUrls': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        'sellerAddress': {
          'street': '123 Main St',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V 1A1',
          'country': 'Canada',
        },
        'description': 'A great product',
        'sellerId': 'seller123',
        'stockQuantity': 50,
        'categoryId': 1,
        'rating': 4.5,
        'ratingCount': 100,
        'searchKeywords': ['test', 'product'],
        'weightKg': 0.5,
        'isLocalDeliveryOnly': false,
        'estimatedShipDays': 3,
      };

      final product = ProductModel.fromMap(map);

      expect(product.id, 'prod123');
      expect(product.name, 'Test Product');
      expect(product.price, 29.99);
      expect(product.imageUrls.length, 2);
      expect(product.sellerAddress.city, 'Toronto');
      expect(product.description, 'A great product');
      expect(product.sellerId, 'seller123');
      expect(product.stockQuantity, 50);
      expect(product.categoryId, 1);
      expect(product.rating, 4.5);
      expect(product.ratingCount, 100);
      expect(product.weightKg, 0.5);
      expect(product.isLocalDeliveryOnly, false);
      expect(product.estimatedShipDays, 3);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 'prod123',
        'name': 'Test Product',
        'price': 29.99,
        'categoryId': 1,
      };

      final product = ProductModel.fromMap(map);

      expect(product.id, 'prod123');
      expect(product.name, 'Test Product');
      expect(product.imageUrls, isEmpty);
      expect(product.rating, 0.0);
      expect(product.ratingCount, 0);
      expect(product.stockQuantity, 0);
      expect(product.weightKg, null);
    });

    test('toMap returns correct map', () {
      final product = ProductModel(
        id: 'prod123',
        name: 'Test Product',
        price: 29.99,
        imageUrls: ['https://example.com/image.jpg'],
        sellerAddress: Address(
          street: '123 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 1A1',
          country: 'Canada',
        ),
        description: 'A great product',
        sellerId: 'seller123',
        stockQuantity: 50,
        categoryId: 1,
        searchKeywords: ['test'],
        rating: 4.5,
        ratingCount: 100,
      );

      final map = product.toMap();

      expect(map['id'], 'prod123');
      expect(map['name'], 'Test Product');
      expect(map['price'], 29.99);
      expect(map['stockQuantity'], 50);
      expect(map['rating'], 4.5);
    });

    test('price parsing handles various numeric types', () {
      // Integer
      var product = ProductModel.fromMap({'price': 30, 'categoryId': 1});
      expect(product.price, 30.0);

      // String
      product = ProductModel.fromMap({'price': '25.50', 'categoryId': 1});
      expect(product.price, 25.50);

      // Null
      product = ProductModel.fromMap({'price': null, 'categoryId': 1});
      expect(product.price, 0.0);
    });
  });

  group('CartModel', () {
    test('fromMap creates correct CartModel', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final map = {
        'productId': 'prod123',
        'quantity': 3,
        'dateCreated': Timestamp.fromDate(now),
      };

      final cart = CartModel.fromMap(map);

      expect(cart.productId, 'prod123');
      expect(cart.quantity, 3);
      expect(cart.dateCreated, now);
    });

    test('toMap returns correct map', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final cart = CartModel(
        productId: 'prod123',
        quantity: 2,
        dateCreated: now,
      );

      final map = cart.toMap();

      expect(map['productId'], 'prod123');
      expect(map['quantity'], 2);
      expect((map['dateCreated'] as Timestamp).toDate(), now);
    });

    test('default quantity is 1', () {
      final cart = CartModel(
        productId: 'prod123',
        dateCreated: DateTime.now(),
      );

      expect(cart.quantity, 1);
    });
  });

  group('CartItemModel', () {
    test('fromMap creates correct CartItemModel', () {
      final map = {
        'productId': 'prod123',
        'quantity': 5,
        'dateCreated': Timestamp.fromDate(DateTime(2024, 1, 15)),
      };

      final item = CartItemModel.fromMap(map);

      expect(item.productId, 'prod123');
      expect(item.quantity, 5);
    });

    test('toMap returns correct map', () {
      final now = Timestamp.fromDate(DateTime(2024, 1, 15));
      final item = CartItemModel(
        productId: 'prod123',
        quantity: 3,
        dateCreated: now,
      );

      final map = item.toMap();

      expect(map['productId'], 'prod123');
      expect(map['quantity'], 3);
      expect(map['dateCreated'], now);
    });
  });

  group('SellerPayout', () {
    test('fromMap creates correct SellerPayout', () {
      final map = {
        'sellerId': 'seller123',
        'stripeAccountId': 'acct_456',
        'gross': 100.0,
        'platformFee': 2.5,
        'net': 97.5,
        'paid': true,
        'transferId': 'tr_789',
        'paidAt': Timestamp.fromDate(DateTime(2024, 1, 20)),
      };

      final payout = SellerPayout.fromMap(map);

      expect(payout.sellerId, 'seller123');
      expect(payout.stripeAccountId, 'acct_456');
      expect(payout.gross, 100.0);
      expect(payout.platformFee, 2.5);
      expect(payout.net, 97.5);
      expect(payout.paid, true);
      expect(payout.transferId, 'tr_789');
      expect(payout.paidAt, DateTime(2024, 1, 20));
    });

    test('toMap returns correct map', () {
      final payout = SellerPayout(
        sellerId: 'seller123',
        stripeAccountId: 'acct_456',
        gross: 100.0,
        platformFee: 2.5,
        net: 97.5,
        paid: false,
      );

      final map = payout.toMap();

      expect(map['sellerId'], 'seller123');
      expect(map['stripeAccountId'], 'acct_456');
      expect(map['gross'], 100.0);
      expect(map['platformFee'], 2.5);
      expect(map['net'], 97.5);
      expect(map['paid'], false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = SellerPayout(
        sellerId: 'seller123',
        gross: 100.0,
        platformFee: 2.5,
        net: 97.5,
      );

      final updated = original.copyWith(paid: true, transferId: 'tr_123');

      expect(updated.paid, true);
      expect(updated.transferId, 'tr_123');
      expect(updated.sellerId, 'seller123'); // Unchanged
      expect(original.paid, false); // Original unchanged
    });
  });
}
