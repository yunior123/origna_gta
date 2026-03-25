import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/constants.dart';

void main() {
  group('CartItemDetailModel', () {
    test('creates with all required fields', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test Product',
        description: 'A description',
        price: 25.99,
        priceCents: 2599,
        imageUrls: ['https://example.com/img.jpg'],
        quantity: 2,
        createdAt: DateTime(2026, 1, 1),
        sellerAddress: Address(
          street: '123 Main',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
        sellerId: 'seller_1',
        sellerName: 'Test Seller',
      );

      expect(item.productId, 'p1');
      expect(item.name, 'Test Product');
      expect(item.price, 25.99);
      expect(item.priceCents, 2599);
      expect(item.quantity, 2);
      expect(item.sellerId, 'seller_1');
    });

    test('creates with all optional fields', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: 'desc',
        price: 10.0,
        priceCents: 1000,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: Address(
          street: '123',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M1M 1M1',
          country: 'CA',
        ),
        sellerId: 's1',
        sellerName: 'Seller',
        weightKg: 2.5,
        lengthCm: 30.0,
        widthCm: 20.0,
        heightCm: 10.0,
        isDigital: false,
        isPerishable: true,
        isLocalDeliveryOnly: false,
        estimatedShipDays: 5,
        freeShipping: true,
        madeInCountry: 'CA',
        isAgeRestricted: true,
        variantId: 'var_1',
        variantTitle: 'Red/Large',
        variantOptions: {'color': 'Red', 'size': 'Large'},
        buyerNote: 'Handle with care',
        minimumOrderQuantity: 2,
        status: DeliveryStatus.shipped.value,
        trackingNumber: 'TRACK123',
        confirmedByBuyer: true,
      );

      expect(item.weightKg, 2.5);
      expect(item.isPerishable, isTrue);
      expect(item.freeShipping, isTrue);
      expect(item.isAgeRestricted, isTrue);
      expect(item.variantId, 'var_1');
      expect(item.buyerNote, 'Handle with care');
      expect(item.trackingNumber, 'TRACK123');
      expect(item.confirmedByBuyer, isTrue);
    });

    test('has correct defaults', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: '',
        price: 10.0,
        priceCents: 1000,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: Address.empty(),
        sellerId: 's1',
        sellerName: 'S',
      );

      expect(item.isDigital, isFalse);
      expect(item.isPerishable, isFalse);
      expect(item.isLocalDeliveryOnly, isFalse);
      expect(item.freeShipping, isFalse);
      expect(item.isAgeRestricted, isFalse);
      expect(item.confirmedByBuyer, isFalse);
      expect(item.estimatedShipDays, 3);
      expect(item.minimumOrderQuantity, 1);
      expect(item.weightKg, isNull);
      expect(item.variantId, isNull);
      expect(item.buyerNote, isNull);
    });

    test('priceCents auto-computed from price when not provided', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: '',
        price: 25.99,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: Address.empty(),
        sellerId: 's1',
        sellerName: 'S',
      );
      expect(item.priceCents, 2599);
    });

    test('fromMap creates from backend data', () {
      final item = CartItemDetailModel.fromMap({
        Fields.productId: 'p1',
        Fields.name: 'Product',
        Fields.description: 'desc',
        Fields.price: 10.0,
        Fields.priceCents: 1000,
        Fields.imageUrls: ['img1.jpg'],
        Fields.quantity: 2,
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.sellerId: 's1',
        Fields.sellerName: 'Seller',
        Fields.sellerAddress: {
          Fields.street: '123',
          Fields.city: 'Toronto',
          Fields.state: 'ON',
          Fields.postalCode: 'M1M 1M1',
          Fields.country: 'CA',
        },
      });

      expect(item.productId, 'p1');
      expect(item.quantity, 2);
    });
  });

  group('CartItemModel', () {
    test('creates from map', () {
      final item = CartItemModel.fromMap({
        Fields.productId: 'p1',
        Fields.quantity: 3,
        Fields.createdAt: DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(item.productId, 'p1');
      expect(item.quantity, 3);
    });

    test('fromMap handles missing fields', () {
      final item = CartItemModel.fromMap({});
      expect(item.productId, isEmpty);
      expect(item.quantity, greaterThanOrEqualTo(0));
    });

    test('cartItemId property', () {
      final item = CartItemModel.fromMap({
        Fields.productId: 'p1',
        Fields.quantity: 1,
        Fields.createdAt: DateTime.now().toIso8601String(),
      }, docId: 'p1_var_1');
      expect(item.cartItemId, 'p1_var_1');
    });
  });

  group('UserModel', () {
    test('creates with required fields', () {
      final user = UserModel(
        uid: 'u1',
        email: 'test@test.com',
        name: 'Test User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.uid, 'u1');
      expect(user.email, 'test@test.com');
      expect(user.name, 'Test User');
      expect(user.roles, contains(UserRole.buyer));
    });

    test('fromMap handles all fields', () {
      final user = UserModel.fromMap({
        Fields.uid: 'u1',
        Fields.email: 'test@test.com',
        Fields.name: 'Test',
        Fields.roles: ['buyer', 'seller'],
        Fields.createdAt: DateTime(2026, 1, 1).toIso8601String(),
        Fields.address: {
          Fields.street: '123 Main',
          Fields.city: 'Montreal',
          Fields.state: 'QC',
          Fields.postalCode: 'H1H 1H1',
          Fields.country: 'CA',
        },
      });

      expect(user.email, 'test@test.com');
      expect(user.roles.length, 2);
      expect(user.address, isNotNull);
      expect(user.address!.state, 'QC');
    });

    test('admin role check', () {
      final admin = UserModel(
        uid: 'u1',
        email: 'admin@test.com',
        name: 'Admin',
        roles: [UserRole.admin, UserRole.buyer],
        createdAt: DateTime.now(),
      );

      expect(admin.roles.contains(UserRole.admin), isTrue);
      expect(admin.roles.contains(UserRole.seller), isFalse);
    });

    test('seller role check', () {
      final seller = UserModel(
        uid: 'u1',
        email: 'seller@test.com',
        name: 'Seller',
        roles: [UserRole.seller, UserRole.buyer],
        createdAt: DateTime.now(),
      );

      expect(seller.roles.contains(UserRole.seller), isTrue);
      expect(seller.roles.contains(UserRole.admin), isFalse);
    });

    test('has correct defaults', () {
      final user = UserModel(
        uid: 'u1',
        email: 'test@test.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime.now(),
      );

      expect(user.payoutsEnabled, isFalse);
      expect(user.chargesEnabled, isFalse);
      expect(user.onboardingCompleted, isFalse);
      expect(user.suspended, isFalse);
      expect(user.isPremium, isFalse);
      expect(user.mfaEnabled, isFalse);
      expect(user.verified, isFalse);
    });
  });

  group('Address', () {
    test('empty creates empty address', () {
      final addr = Address.empty();
      expect(addr.street, isEmpty);
      expect(addr.city, isEmpty);
      expect(addr.state, isEmpty);
    });

    test('toMap includes all fields', () {
      final addr = Address(
        street: '123 Main',
        apartment: 'Suite 4',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
        phoneNumber: '+14165551234',
        latitude: 43.65,
        longitude: -79.38,
        isDefault: true,
        label: 'Home',
      );

      final map = addr.toMap();
      expect(map[Fields.street], '123 Main');
      expect(map[Fields.apartment], 'Suite 4');
      expect(map[Fields.phoneNumber], '+14165551234');
      expect(map[Fields.latitude], 43.65);
      expect(map[Fields.isDefault], isTrue);
      expect(map[Fields.label], 'Home');
    });

    test('fullAddress formatting', () {
      final addr = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'CA',
      );

      expect(addr.fullAddress, isNotEmpty);
      expect(addr.fullAddress, contains('Toronto'));
      expect(addr.fullAddress, contains('ON'));
    });
  });

  group('DeliverySpeed', () {
    test('all speeds have values', () {
      for (final speed in DeliverySpeed.values) {
        expect(speed.value, isNotEmpty);
      }
    });

    test('standard has zero surcharge', () {
      expect(DeliverySpeed.standard.baseSurcharge, 0.0);
    });

    test('express has positive surcharge', () {
      expect(DeliverySpeed.express.baseSurcharge, greaterThan(0));
    });
  });

  group('SellerPayout (models.dart)', () {
    test('creates from map', () {
      final payout = SellerPayout.fromMap({
        Fields.sellerId: 's1',
        Fields.sellerName: 'Test Seller',
        'grossAmountCents': 10000,
        'platformFeeCents': 1000,
        'netPayoutCents': 9000,
      });
      expect(payout.sellerId, 's1');
    });
  });

  group('DocumentSnapshot', () {
    test('holds id and data', () {
      const doc = DocumentSnapshot(id: 'doc_1', data: {'field1': 'value1'});
      expect(doc.id, 'doc_1');
      expect(doc.data(), containsPair('field1', 'value1'));
    });
  });

  group('OrderModel.fromMap edge cases', () {
    test('handles empty items list', () {
      final order = OrderModel.fromMap({
        Fields.orderId: 'ord_empty',
        Fields.userId: 'u1',
        Fields.items: [],
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      expect(order.items, isEmpty);
      expect(order.total, 0.0);
    });

    test('handles seller payouts parsing', () {
      final order = OrderModel.fromMap({
        Fields.orderId: 'ord_payouts',
        Fields.userId: 'u1',
        Fields.items: [],
        Fields.totalAmountCents: 10000,
        Fields.subtotalCents: 8000,
        Fields.orderStatus: OrderStatusValues.confirmed,
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.sellerPayouts: [
          {
            Fields.sellerId: 's1',
            Fields.sellerName: 'Seller 1',
            'grossAmountCents': 8000,
            'platformFeeCents': 800,
            'netPayoutCents': 7200,
          },
        ],
      });

      expect(order.sellerPayouts.length, 1);
      expect(order.sellerPayouts.first.sellerId, 's1');
    });

    test('fromDocument works', () {
      final doc = DocumentSnapshot(
        id: 'ord_doc',
        data: {
          Fields.userId: 'u1',
          Fields.items: [],
          Fields.totalAmountCents: 5000,
          Fields.subtotalCents: 4000,
          Fields.orderStatus: OrderStatusValues.pending,
          Fields.shippingAddress: {},
          Fields.createdAt: DateTime.now().toIso8601String(),
        },
      );

      final order = OrderModel.fromDocument(doc);
      expect(order.orderId, 'ord_doc');
      expect(order.totalAmountCents, 5000);
    });
  });

  group('OrderModel computed properties', () {
    test('total and subtotal convert cents to dollars', () {
      final order = OrderModel.fromMap({
        Fields.orderId: 'ord_3',
        Fields.userId: 'user_1',
        Fields.items: [],
        Fields.totalAmountCents: 2599,
        Fields.subtotalCents: 2000,
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      expect(order.total, closeTo(25.99, 0.01));
      expect(order.subtotal, closeTo(20.00, 0.01));
    });
  });

  group('ProductModel', () {
    test('fromMap creates basic model', () {
      final product = ProductModel.fromMap({
        Fields.productId: 'p1',
        Fields.name: 'Test Product',
        Fields.description: 'A great product',
        Fields.price: 25.99,
        Fields.priceCents: 2599,
        Fields.imageUrls: ['https://example.com/img.jpg'],
        Fields.categoryId: 1,
        Fields.subcategory: 'Phones',
        Fields.sellerId: 's1',
        Fields.sellerName: 'Seller Name',
        Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        Fields.stockQuantity: 10,
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      expect(product.name, 'Test Product');
      expect(product.priceCents, 2599);
      expect(product.stockQuantity, 10);
    });

    test('fromMap handles missing optional fields', () {
      final product = ProductModel.fromMap({
        Fields.productId: 'p2',
        Fields.name: 'Minimal',
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      expect(product.name, 'Minimal');
    });
  });
}
