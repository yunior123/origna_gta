import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/models.dart';

void main() {
  group('Address', () {
    test('fromMap creates correct Address', () {
      final map = {
        Fields.street: '123 Main St',
        Fields.apartment: 'Unit 4B',
        Fields.city: 'Toronto',
        Fields.state: 'ON',
        Fields.postalCode: 'M5V 1A1',
        Fields.country: 'Canada',
        Fields.phoneNumber: '416-555-1234',
        Fields.isDefault: true,
        Fields.label: 'Home',
        Fields.latitude: 43.6532,
        Fields.longitude: -79.3832,
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

      expect(map[Fields.street], '456 Oak Ave');
      expect(map[Fields.apartment], 'Suite 100');
      expect(map[Fields.city], 'Vancouver');
      expect(map[Fields.state], 'BC');
      expect(map[Fields.postalCode], 'V6B 1A1');
      expect(map[Fields.country], 'Canada');
      expect(map[Fields.phoneNumber], '604-555-5678');
      expect(map[Fields.isDefault], true);
      expect(map[Fields.label], 'Work');
      expect(map[Fields.latitude], 49.2827);
      expect(map[Fields.longitude], -123.1207);
    });

    test('fullAddress returns formatted string', () {
      final address = Address(street: '123 Main St', apartment: 'Unit 4B', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada');

      expect(address.fullAddress, '123 Main St, Unit 4B, Toronto, ON, M5V 1A1, Canada');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Address(street: '123 Main St', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada');

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
        Fields.uid: 'user123',
        Fields.email: 'test@example.com',
        Fields.name: 'John Doe',
        Fields.roles: ['buyer', 'seller'],
        Fields.address: {Fields.street: '123 Main St', Fields.city: 'Toronto', Fields.state: 'ON', Fields.postalCode: 'M5V 1A1', Fields.country: 'Canada'},
        Fields.createdAt: Timestamp.fromDate(DateTime(2024, 1, 15)),
        Fields.customerId: 'cus_123',
        Fields.stripeAccountId: 'acct_456',
        Fields.payoutsEnabled: true,
        Fields.chargesEnabled: true,
        Fields.onboardingCompleted: true,
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
        Fields.uid: 'user123',
        Fields.email: 'test@example.com',
        Fields.name: 'John Doe',
        Fields.roles: ['buyer'],
        Fields.createdAt: Timestamp.fromDate(DateTime(2024, 1, 15)),
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

      expect(map[Fields.uid], 'user123');
      expect(map[Fields.email], 'test@example.com');
      expect(map[Fields.name], 'John Doe');
      expect(map[Fields.roles], ['buyer', 'seller']);
      expect(map[Fields.customerId], 'cus_123');
      expect(map[Fields.stripeAccountId], 'acct_456');
      expect(map[Fields.payoutsEnabled], true);
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
      final original = UserModel(uid: 'user123', email: 'test@example.com', name: 'John Doe', roles: ['buyer'], createdAt: DateTime(2024, 1, 15));

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
        Fields.productId: 'prod123',
        Fields.name: 'Test Product',
        Fields.price: 29.99,
        Fields.imageUrls: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        Fields.sellerAddress: {
          Fields.street: '123 Main St',
          Fields.city: 'Toronto',
          Fields.state: 'ON',
          Fields.postalCode: 'M5V 1A1',
          Fields.country: 'Canada',
        },
        Fields.description: 'A great product',
        Fields.sellerId: 'seller123',
        Fields.stockQuantity: 50,
        Fields.categoryId: 1,
        Fields.rating: 4.5,
        Fields.ratingCount: 100,
        Fields.keywords: ['test', 'product'],
        Fields.weightKg: 0.5,
        Fields.isLocalDeliveryOnly: false,
        Fields.estimatedShipDays: 3,
        Fields.lifecycleStatus: 'active',
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
      expect(product.lifecycleStatus, 'active');
    });

    test('fromMap handles missing optional fields', () {
      final map = {Fields.productId: 'prod123', Fields.name: 'Test Product', Fields.price: 29.99, Fields.categoryId: 1};

      final product = ProductModel.fromMap(map);

      expect(product.id, 'prod123');
      expect(product.name, 'Test Product');
      expect(product.imageUrls, isEmpty);
      expect(product.rating, 0.0);
      expect(product.ratingCount, 0);
      expect(product.stockQuantity, 0);
      expect(product.weightKg, null);
      expect(product.lifecycleStatus, 'draft');
    });

    test('toMap returns correct map', () {
      final product = ProductModel(
        id: 'prod123',
        name: 'Test Product',
        price: 29.99,
        imageUrls: ['https://example.com/image.jpg'],
        sellerAddress: Address(street: '123 Main St', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada'),
        description: 'A great product',
        sellerId: 'seller123',
        stockQuantity: 50,
        categoryId: 1,
        keywords: ['test'],
        rating: 4.5,
        ratingCount: 100,
        lifecycleStatus: 'active',
      );

      final map = product.toMap();

      expect(map[Fields.productId], 'prod123');
      expect(map[Fields.name], 'Test Product');
      expect(map[Fields.price], 29.99);
      expect(map[Fields.stockQuantity], 50);
      expect(map[Fields.rating], 4.5);
      expect(map[Fields.lifecycleStatus], 'active');
    });

    test('price parsing handles various numeric types', () {
      // Integer
      var product = ProductModel.fromMap({Fields.price: 30, Fields.categoryId: 1});
      expect(product.price, 30.0);

      // String
      product = ProductModel.fromMap({Fields.price: '25.50', Fields.categoryId: 1});
      expect(product.price, 25.50);

      // Null
      product = ProductModel.fromMap({Fields.price: null, Fields.categoryId: 1});
      expect(product.price, 0.0);
    });
  });

  group('CartModel', () {
    test('fromMap creates correct CartModel', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final map = {Fields.productId: 'prod123', Fields.quantity: 3, Fields.createdAt: Timestamp.fromDate(now)};

      final cart = CartModel.fromMap(map);

      expect(cart.productId, 'prod123');
      expect(cart.quantity, 3);
      expect(cart.createdAt, now);
    });

    test('toMap returns correct map', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final cart = CartModel(productId: 'prod123', quantity: 2, createdAt: now);

      final map = cart.toMap();

      expect(map[Fields.productId], 'prod123');
      expect(map[Fields.quantity], 2);
      expect((map[Fields.createdAt] as Timestamp).toDate(), now);
    });

    test('default quantity is 1', () {
      final cart = CartModel(productId: 'prod123', createdAt: DateTime.now());

      expect(cart.quantity, 1);
    });
  });

  group('CartItemModel', () {
    test('fromMap creates correct CartItemModel', () {
      final map = {
        Fields.productId: 'prod123',
        Fields.quantity: 5,
        Fields.createdAt: Timestamp.fromDate(DateTime(2024, 1, 15)),
        Fields.buyerNote: 'Gift for friend',
      };

      final item = CartItemModel.fromMap(map);

      expect(item.productId, 'prod123');
      expect(item.quantity, 5);
      expect(item.buyerNote, 'Gift for friend');
    });

    test('toMap returns correct map', () {
      final now = Timestamp.fromDate(DateTime(2024, 1, 15));
      final item = CartItemModel(cartItemId: 'cart_1', productId: 'prod123', quantity: 3, createdAt: now, buyerNote: 'Gift wrapped please');

      final map = item.toMap();

      expect(map[Fields.productId], 'prod123');
      expect(map[Fields.quantity], 3);
      expect(map[Fields.createdAt], now);
      expect(map[Fields.buyerNote], 'Gift wrapped please');
    });
  });

  group('SellerPayout', () {
    test('fromMap creates correct SellerPayout', () {
      final map = {
        Fields.sellerId: 'seller123',
        Fields.stripeAccountId: 'acct_456',
        Fields.amountCents: 10000,
        Fields.platformFeeCents: 250,
        Fields.netAmountCents: 9750,
        Fields.status: 'completed',
        Fields.stripeTransferId: 'tr_789',
        Fields.payoutDate: Timestamp.fromDate(DateTime(2024, 1, 20)),
      };

      final payout = SellerPayout.fromMap(map);

      expect(payout.sellerId, 'seller123');
      expect(payout.stripeAccountId, 'acct_456');
      expect(payout.amountCents, 10000);
      expect(payout.platformFeeCents, 250);
      expect(payout.netAmountCents, 9750);
      expect(payout.amount, 100.0);
      expect(payout.platformFee, 2.5);
      expect(payout.netAmount, 97.5);
      expect(payout.paid, true);
      expect(payout.stripeTransferId, 'tr_789');
      expect(payout.payoutDate, DateTime(2024, 1, 20));
    });

    test('toMap returns correct map', () {
      final payout = SellerPayout(
        sellerId: 'seller123',
        stripeAccountId: 'acct_456',
        amountCents: 10000,
        platformFeeCents: 250,
        netAmountCents: 9750,
        status: 'pending',
      );

      final map = payout.toMap();

      expect(map[Fields.sellerId], 'seller123');
      expect(map[Fields.stripeAccountId], 'acct_456');
      expect(map[Fields.amountCents], 10000);
      expect(map[Fields.platformFeeCents], 250);
      expect(map[Fields.netAmountCents], 9750);
      expect(map[Fields.status], 'pending');
    });

    test('dollar getters compute correctly from cents', () {
      final payout = SellerPayout(sellerId: 'seller123', amountCents: 10000, platformFeeCents: 250, netAmountCents: 9750);

      expect(payout.amount, 100.0);
      expect(payout.platformFee, 2.5);
      expect(payout.netAmount, 97.5);
      expect(payout.paid, false); // status defaults to 'pending'
    });
  });
}
