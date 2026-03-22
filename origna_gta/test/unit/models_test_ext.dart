import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart';

void main() {
  group('Address Model - Additional Coverage', () {
    test('copyWith preserves optional fields when not specified', () {
      final original = Address(
        addressId: 'addr1',
        street: '123 Main',
        apartment: 'Apt 1',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V',
        country: 'CA',
        phoneNumber: '555-1234',
        isDefault: true,
        label: 'Home',
        latitude: 43.0,
        longitude: -79.0,
      );

      final updated = original.copyWith(street: '456 Oak');

      expect(updated.street, '456 Oak');
      expect(updated.phoneNumber, '555-1234');
      expect(updated.label, 'Home');
      expect(updated.latitude, 43.0);
      expect(updated.longitude, -79.0);
    });

    test('fromMap with non-map sellerAddress falls back to empty', () {
      final map = {
        Fields.street: 'Test St',
        Fields.city: 'Test City',
        Fields.state: 'TS',
        Fields.postalCode: 'T1T1T1',
        Fields.country: 'Canada',
      };

      final address = Address.fromMap(map);
      expect(address.street, 'Test St');
      expect(address.apartment, '');
      expect(address.isDefault, false);
      expect(address.label, isNull);
    });

    test('Address equality comparison', () {
      final a1 = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V',
        country: 'Canada',
      );
      final a2 = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V',
        country: 'Canada',
      );

      expect(a1.street, a2.street);
      expect(a1.city, a2.city);
      expect(a1.state, a2.state);
      expect(a1.postalCode, a2.postalCode);
      expect(a1.country, a2.country);
    });

    test('formattedAddress handles empty apartment', () {
      final address = Address(
        street: '456 Oak Ave',
        apartment: '',
        city: 'Montreal',
        state: 'QC',
        postalCode: 'H2X',
        country: 'Canada',
      );

      expect(address.formattedAddress, '456 Oak Ave\nMontreal, QC H2X\nCanada');
    });
  });

  group('CartItemDetailModel - Additional Coverage', () {
    test('fromMap with valid delivery options', () {
      final map = {
        Fields.productId: 'p1',
        Fields.name: 'Test',
        Fields.description: 'Desc',
        Fields.price: 10.0,
        Fields.imageUrls: ['img.jpg'],
        Fields.quantity: 1,
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.sellerId: 's1',
        Fields.sellerName: 'Seller',
        Fields.sellerAddress: {},
        Fields.deliveryOptions: [
          {'type': 'standard', 'costCents': 500, 'estimatedDays': 5},
        ],
      };

      final item = CartItemDetailModel.fromMap(map);
      expect(item.deliveryOptions.length, 1);
    });

    test('fromMap with null delivery options', () {
      final map = {
        Fields.productId: 'p1',
        Fields.name: 'Test',
        Fields.description: 'Desc',
        Fields.price: 10.0,
        Fields.imageUrls: [],
        Fields.quantity: 1,
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.sellerId: 's1',
        Fields.sellerName: 'Seller',
        Fields.sellerAddress: null,
        Fields.deliveryOptions: null,
      };

      final item = CartItemDetailModel.fromMap(map);
      expect(item.deliveryOptions, isEmpty);
      expect(item.sellerAddress.country, 'Canada');
    });

    test('toMap includes all fields with values', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Product',
        description: 'Description',
        price: 25.99,
        imageUrls: ['img1.jpg', 'img2.jpg'],
        quantity: 3,
        createdAt: DateTime(2024, 6, 15),
        sellerAddress: Address(
          street: '1 Seller St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V',
          country: 'Canada',
        ),
        sellerId: 'seller1',
        sellerName: 'Seller One',
        status: 'shipped',
        trackingNumber: 'TRACK123',
        confirmedByBuyer: true,
        madeInCountry: 'CA',
        weightKg: 0.5,
        weightUnit: 'kg',
        lengthCm: 20.0,
        widthCm: 15.0,
        heightCm: 10.0,
        dimensionUnit: 'cm',
        isLocalDeliveryOnly: true,
        isPerishable: true,
        estimatedShipDays: 7,
        minimumOrderQuantity: 2,
        freeShipping: true,
        isDigital: false,
        isAgeRestricted: false,
        buyerNote: 'Handle with care',
        isSmallSupplier: true,
        variantId: 'v1',
        variantTitle: 'Large / Red',
        variantOptions: {'size': 'Large', 'color': 'Red'},
      );

      final map = item.toMap();

      expect(map[Fields.productId], 'p1');
      expect(map[Fields.name], 'Product');
      expect(map[Fields.price], 25.99);
      expect(map[Fields.imageUrls], ['img1.jpg', 'img2.jpg']);
      expect(map[Fields.quantity], 3);
      expect(map[Fields.sellerId], 'seller1');
      expect(map[Fields.sellerName], 'Seller One');
      expect(map[Fields.status], 'shipped');
      expect(map[Fields.trackingNumber], 'TRACK123');
      expect(map[Fields.confirmedByBuyer], true);
      expect(map[Fields.madeInCountry], 'CA');
      expect(map[Fields.weightKg], 0.5);
      expect(map[Fields.isPerishable], true);
      expect(map[Fields.isSmallSupplier], true);
      expect(map[Fields.variantId], 'v1');
      expect(map[Fields.variantOptions], {'size': 'Large', 'color': 'Red'});
    });

    test('priceCents calculated from price when not provided', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: '',
        price: 12.34,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime(2024, 1, 1),
        sellerAddress: Address.empty(),
        sellerId: 's1',
        sellerName: 'S',
      );

      expect(item.priceCents, 1234);
    });

    test('priceCents uses explicit value when provided', () {
      final item = CartItemDetailModel(
        productId: 'p1',
        name: 'Test',
        description: '',
        price: 12.34,
        priceCents: 999,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime(2024, 1, 1),
        sellerAddress: Address.empty(),
        sellerId: 's1',
        sellerName: 'S',
      );

      expect(item.priceCents, 999);
    });
  });

  group('OrderModel - Additional Coverage', () {
    test('fromDocument creates correct OrderModel', () {
      final doc = DocumentSnapshot(
        id: 'order_doc_001',
        data: {
          Fields.orderId: 'ord_001',
          Fields.userId: 'user_001',
          Fields.items: [
            {
              Fields.productId: 'p1',
              Fields.name: 'Item',
              Fields.description: 'Desc',
              Fields.price: 50.0,
              Fields.imageUrls: ['img.jpg'],
              Fields.quantity: 2,
              Fields.createdAt: DateTime(2024, 6, 15),
              Fields.sellerId: 's1',
              Fields.sellerName: 'Seller',
              Fields.status: 'delivered',
            },
          ],
          Fields.totalAmountCents: 10000,
          Fields.subtotalCents: 9000,
          Fields.shippingCostCents: 1000,
          Fields.taxAmountCents: 500,
          Fields.orderStatus: 'confirmed',
          Fields.paymentStatus: 'paid',
          Fields.shippingAddress: {
            Fields.street: '1 St',
            Fields.city: 'Toronto',
          },
          Fields.createdAt: DateTime(2024, 6, 1),
          Fields.customerId: 'cus_001',
          Fields.customerEmail: 'customer@example.com',
          Fields.taxes: {'GST': 5.0},
          Fields.currency: 'CAD',
          Fields.sellerIds: ['s1'],
          Fields.stripeSessionId: 'sess_001',
        },
      );

      final order = OrderModel.fromDocument(doc);

      expect(order.orderId, 'ord_001');
      expect(order.userId, 'user_001');
      expect(order.items.length, 1);
      expect(order.items.first.productId, 'p1');
      expect(order.totalAmountCents, 10000);
    });

    test('fromMap handles missing items gracefully', () {
      final data = {
        Fields.orderId: 'ord_empty',
        Fields.userId: 'u1',
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: 'pending',
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.customerId: 'c1',
        Fields.customerEmail: 'e@e.com',
        Fields.taxes: {},
        Fields.currency: 'CAD',
        Fields.sellerIds: [],
        Fields.stripeSessionId: '',
        Fields.items: null,
      };

      final order = OrderModel.fromMap(data);
      expect(order.items, isEmpty);
    });

    test('fromMap with valid items', () {
      final data = {
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: 'pending',
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.customerId: 'c1',
        Fields.customerEmail: 'e@e.com',
        Fields.taxes: {},
        Fields.currency: 'CAD',
        Fields.sellerIds: [],
        Fields.stripeSessionId: '',
        Fields.items: [
          {
            Fields.productId: 'p1',
            Fields.name: 'Item',
            Fields.description: 'Desc',
            Fields.price: 10.0,
            Fields.imageUrls: [],
            Fields.quantity: 1,
            Fields.createdAt: DateTime(2024, 1, 1),
            Fields.sellerId: 's1',
            Fields.sellerName: 'Seller',
          },
        ],
      };

      final order = OrderModel.fromMap(data);
      expect(order.items.length, 1);
    });

    test('toMap roundtrip preserves complex data', () {
      final order = OrderModel(
        orderId: 'ord_complex',
        userId: 'u1',
        totalAmountCents: 25000,
        subtotalCents: 20000,
        shippingCostCents: 3000,
        taxAmountCents: 2000,
        orderStatus: OrderStatusValues.delivered,
        paymentStatus: PaymentStatusValues.paid,
        shippingAddress: {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V',
        },
        createdAt: DateTime(2024, 6, 15),
        customerId: 'cus_001',
        customerEmail: 'buyer@example.com',
        taxes: {'GST': 5.0, 'PST': 7.0},
        currency: 'CAD',
        sellerIds: ['s1', 's2'],
        stripeSessionId: 'sess_complex',
        shippingApprovalStatus: ShippingApprovalStatusValues.approved,
        shippingApprovalRequired: true,
        actualShippingCents: 2800,
        pendingTotalCents: 0,
        sellerPayouts: [
          SellerPayout(
            sellerId: 's1',
            amountCents: 10000,
            platformFeeCents: 250,
            netAmountCents: 9750,
            status: PayoutStatusValues.completed,
          ),
        ],
        confirmedByClient: true,
        confirmedAt: DateTime(2024, 6, 20),
        platformFeeTotalCents: 500,
        payoutStatus: PayoutStatusValues.completed,
        ratings: {'s1': 5, 's2': 4},
        items: [],
      );

      final map = order.toMap();

      expect(map[Fields.userId], 'u1');
      expect(map[Fields.totalAmountCents], 25000);
      expect(map[Fields.taxAmountCents], 2000);
      expect(map[Fields.currency], 'CAD');
      expect(map[Fields.sellerIds], ['s1', 's2']);
      expect(
        map[Fields.shippingApprovalStatus],
        ShippingApprovalStatusValues.approved,
      );
      expect(map[Fields.confirmedByClient], true);
      expect(map[Fields.payoutStatus], PayoutStatusValues.completed);
      expect(map[Fields.ratings], {'s1': 5, 's2': 4});
    });

    test('fromMap handles missing items gracefully', () {
      final data = {
        Fields.orderId: 'ord_empty',
        Fields.userId: 'u1',
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: 'pending',
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.customerId: 'c1',
        Fields.customerEmail: 'e@e.com',
        Fields.taxes: {},
        Fields.currency: 'CAD',
        Fields.sellerIds: [],
        Fields.stripeSessionId: '',
        Fields.items: null,
      };

      final order = OrderModel.fromMap(data);
      expect(order.items, isEmpty);
    });

    test('fromMap skips invalid items gracefully', () {
      final data = {
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: 'pending',
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.customerId: 'c1',
        Fields.customerEmail: 'e@e.com',
        Fields.taxes: {},
        Fields.currency: 'CAD',
        Fields.sellerIds: [],
        Fields.stripeSessionId: '',
        Fields.items: [],
      };

      final order = OrderModel.fromMap(data);
      expect(order.items, isEmpty);
    });

    test('toMap roundtrip preserves data', () {
      final order = OrderModel(
        orderId: 'ord_complex',
        userId: 'u1',
        totalAmountCents: 25000,
        subtotalCents: 20000,
        shippingCostCents: 3000,
        taxAmountCents: 2000,
        orderStatus: OrderStatusValues.delivered,
        paymentStatus: PaymentStatusValues.paid,
        shippingAddress: {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V',
        },
        createdAt: DateTime(2024, 6, 15),
        customerId: 'cus_001',
        customerEmail: 'buyer@example.com',
        taxes: {'GST': 5.0, 'PST': 7.0},
        currency: 'CAD',
        sellerIds: ['s1', 's2'],
        stripeSessionId: 'sess_complex',
        shippingApprovalStatus: ShippingApprovalStatusValues.approved,
        shippingApprovalRequired: true,
        actualShippingCents: 2800,
        pendingTotalCents: 0,
        sellerPayouts: [
          SellerPayout(
            sellerId: 's1',
            amountCents: 10000,
            platformFeeCents: 250,
            netAmountCents: 9750,
            status: PayoutStatusValues.completed,
          ),
        ],
        confirmedByClient: true,
        confirmedAt: DateTime(2024, 6, 20),
        platformFeeTotalCents: 500,
        payoutStatus: PayoutStatusValues.completed,
        ratings: {'s1': 5, 's2': 4},
        items: [],
      );

      final map = order.toMap();

      expect(map[Fields.userId], 'u1');
      expect(map[Fields.totalAmountCents], 25000);
      expect(map[Fields.taxAmountCents], 2000);
      expect(map[Fields.currency], 'CAD');
      expect(map[Fields.sellerIds], ['s1', 's2']);
      expect(
        map[Fields.shippingApprovalStatus],
        ShippingApprovalStatusValues.approved,
      );
      expect(map[Fields.confirmedByClient], true);
      expect(map[Fields.payoutStatus], PayoutStatusValues.completed);
      expect(map[Fields.ratings], {'s1': 5, 's2': 4});
    });

    test('computed getters work correctly', () {
      final order = OrderModel(
        orderId: 'ord_getters',
        userId: 'u1',
        totalAmountCents: 12599,
        subtotalCents: 10000,
        shippingCostCents: 1599,
        taxAmountCents: 1000,
        orderStatus: 'pending',
        shippingAddress: {},
        createdAt: DateTime(2024, 1, 1),
        customerId: 'c1',
        customerEmail: 'e@e.com',
        taxes: {},
        currency: 'CAD',
        sellerIds: [],
        stripeSessionId: 'sess',
        items: [],
      );

      expect(order.total, 125.99);
      expect(order.subtotal, 100.0);
      expect(order.shippingCost, 15.99);
      expect(order.taxAmount, 10.0);
    });
  });

  group('ProductModel - Additional Coverage', () {
    test('fromDocument with full data', () {
      final doc = DocumentSnapshot(
        id: 'prod_001',
        data: {
          Fields.name: 'Test Product',
          Fields.price: 29.99,
          Fields.priceCents: 2999,
          Fields.categoryId: 1,
          Fields.imageUrls: ['img.jpg'],
          Fields.sellerAddress: {
            Fields.street: '123 St',
            Fields.city: 'Toronto',
            Fields.state: 'ON',
            Fields.postalCode: 'M5V',
            Fields.country: 'Canada',
          },
          Fields.description: 'A test product',
          Fields.sellerId: 'seller_001',
          Fields.stockQuantity: 100,
          Fields.keywords: ['test', 'product'],
        },
      );

      final product = ProductModel.fromDocument(doc);

      expect(product.id, 'prod_001');
      expect(product.name, 'Test Product');
      expect(product.categoryId, 1);
    });

    test('fromMap with string priceCents', () {
      final map = {
        Fields.productId: 'p1',
        Fields.name: 'Product',
        Fields.priceCents: '2999',
        Fields.categoryId: 1,
      };

      final product = ProductModel.fromMap(map);
      expect(product.priceCents, 2999);
    });

    test('fromMap with double price', () {
      final map = {
        Fields.productId: 'p1',
        Fields.name: 'Product',
        Fields.price: 29.99,
        Fields.priceCents: 2999,
        Fields.categoryId: 1,
      };

      final product = ProductModel.fromMap(map);
      expect(product.priceCents, 2999);
    });

    test('fromMap handles empty deliveryOptions', () {
      final map = {
        Fields.productId: 'p1',
        Fields.name: 'Product',
        Fields.price: 10.0,
        Fields.categoryId: 1,
        Fields.deliveryOptions: [],
      };

      final product = ProductModel.fromMap(map);
      expect(product.deliveryOptions, isEmpty);
    });

    test('toMap includes deliveryOptions', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Product',
        priceCents: 1000,
        imageUrls: [],
        sellerAddress: Address.empty(),
        description: '',
        sellerId: 's1',
        stockQuantity: 10,
        categoryId: 1,
        keywords: [],
        deliveryOptions: [
          SellerDeliveryOption.fromMap({
            'type': 'standard',
            'costCents': 500,
            'estimatedDays': 5,
          })!,
        ],
      );

      final map = product.toMap();
      expect(map[Fields.deliveryOptions], isA<List>());
      expect((map[Fields.deliveryOptions] as List).length, 1);
    });

    test('enabledDeliveryOptions returns all options', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Product',
        priceCents: 1000,
        imageUrls: [],
        sellerAddress: Address.empty(),
        description: '',
        sellerId: 's1',
        stockQuantity: 10,
        categoryId: 1,
        keywords: [],
        deliveryOptions: [
          SellerDeliveryOption.fromMap({
            'type': 'standard',
            'costCents': 500,
            'estimatedDays': 5,
          })!,
          SellerDeliveryOption.fromMap({
            'type': 'express',
            'costCents': 1000,
            'estimatedDays': 2,
          })!,
        ],
      );

      expect(product.enabledDeliveryOptions.length, 2);
    });

    test('getDeliveryOption returns null for non-existent speed', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Product',
        priceCents: 1000,
        imageUrls: [],
        sellerAddress: Address.empty(),
        description: '',
        sellerId: 's1',
        stockQuantity: 10,
        categoryId: 1,
        keywords: [],
        deliveryOptions: [
          SellerDeliveryOption.fromMap({
            'type': 'standard',
            'costCents': 500,
            'estimatedDays': 5,
          })!,
        ],
      );

      expect(product.getDeliveryOption(DeliverySpeed.express), isNull);
    });
  });

  group('SellerPayout - Additional Coverage', () {
    test('fromMap with all fields', () {
      final map = {
        Fields.sellerId: 'seller_001',
        Fields.stripeAccountId: 'acct_123',
        Fields.amountCents: 10000,
        Fields.platformFeeCents: 250,
        Fields.netAmountCents: 9750,
        Fields.status: 'completed',
        Fields.stripeTransferId: 'tr_789',
        Fields.payoutDate: DateTime(2024, 6, 15),
        Fields.failureReason: null,
      };

      final payout = SellerPayout.fromMap(map);

      expect(payout.sellerId, 'seller_001');
      expect(payout.stripeAccountId, 'acct_123');
      expect(payout.amountCents, 10000);
      expect(payout.platformFeeCents, 250);
      expect(payout.netAmountCents, 9750);
      expect(payout.status, 'completed');
      expect(payout.stripeTransferId, 'tr_789');
      expect(payout.payoutDate, DateTime(2024, 6, 15));
      expect(payout.failureReason, isNull);
    });

    test('dollar getters compute correctly', () {
      final payout = SellerPayout(
        sellerId: 's1',
        amountCents: 15000,
        platformFeeCents: 375,
        netAmountCents: 14625,
      );

      expect(payout.amount, 150.0);
      expect(payout.platformFee, 3.75);
      expect(payout.netAmount, 146.25);
    });

    test('paid getter returns correct status', () {
      final completed = SellerPayout(
        sellerId: 's1',
        amountCents: 100,
        platformFeeCents: 5,
        netAmountCents: 95,
        status: PayoutStatusValues.completed,
      );
      final pending = SellerPayout(
        sellerId: 's1',
        amountCents: 100,
        platformFeeCents: 5,
        netAmountCents: 95,
        status: PayoutStatusValues.pending,
      );

      expect(completed.paid, true);
      expect(pending.paid, false);
    });

    test('toMap includes all fields', () {
      final payout = SellerPayout(
        sellerId: 's1',
        stripeAccountId: 'acct_001',
        amountCents: 10000,
        platformFeeCents: 250,
        netAmountCents: 9750,
        status: 'completed',
        stripeTransferId: 'tr_001',
        payoutDate: DateTime(2024, 6, 15),
        failureReason: 'insufficient_funds',
      );

      final map = payout.toMap();

      expect(map[Fields.sellerId], 's1');
      expect(map[Fields.stripeAccountId], 'acct_001');
      expect(map[Fields.amountCents], 10000);
      expect(map[Fields.status], 'completed');
      expect(map[Fields.failureReason], 'insufficient_funds');
    });
  });

  group('UserModel (models.dart) - Additional Coverage', () {
    test('fromMap with string roles', () {
      final map = {
        Fields.uid: 'u1',
        Fields.email: 'test@example.com',
        Fields.name: 'Test User',
        Fields.roles: ['admin', 'seller'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = UserModel.fromMap(map);

      expect(user.roles, [UserRole.admin, UserRole.seller]);
    });

    test('fromMap handles unknown role strings', () {
      final map = {
        Fields.uid: 'u1',
        Fields.email: 'test@example.com',
        Fields.name: 'Test',
        Fields.roles: ['unknown_role', 'buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = UserModel.fromMap(map);

      expect(user.roles.length, 2);
      expect(user.roles, contains(UserRole.buyer));
    });

    test('fromMap handles empty roles', () {
      final map = {
        Fields.uid: 'u1',
        Fields.email: 'test@example.com',
        Fields.name: 'Test',
        Fields.roles: [],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = UserModel.fromMap(map);

      expect(user.roles, isEmpty);
    });

    test('fromMap parses address', () {
      final map = {
        Fields.uid: 'u1',
        Fields.email: 'test@example.com',
        Fields.name: 'Test',
        Fields.roles: ['buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.address: {
          Fields.street: '123 Main St',
          Fields.city: 'Toronto',
          Fields.state: 'ON',
          Fields.postalCode: 'M5V 1A1',
          Fields.country: 'Canada',
        },
      };

      final user = UserModel.fromMap(map);

      expect(user.address, isNotNull);
      expect(user.address?.street, '123 Main St');
      expect(user.address?.city, 'Toronto');
    });

    test('toMap includes all required fields', () {
      final user = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        name: 'Test User',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        customerId: 'cus_123',
        stripeAccountId: 'acct_456',
        payoutsEnabled: true,
        chargesEnabled: true,
        onboardingCompleted: true,
        suspended: false,
        paymentProvider: 'stripe',
        verified: true,
        verificationStatus: 'approved',
        pendingRequirements: ['document_upload'],
        mfaEnabled: true,
        termsVersion: '2.0',
      );

      final map = user.toMap();

      expect(map[Fields.uid], 'u1');
      expect(map[Fields.email], 'test@example.com');
      expect(map[Fields.name], 'Test User');
      expect(map[Fields.roles], [UserRole.seller]);
      expect(map[Fields.customerId], 'cus_123');
      expect(map[Fields.mfaEnabled], true);
    });

    test('copyWith updates all fields', () {
      final original = UserModel(
        uid: 'u1',
        email: 'original@example.com',
        name: 'Original',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        email: 'updated@example.com',
        name: 'Updated',
        roles: [UserRole.seller],
        suspended: true,
        isPremium: true,
      );

      expect(updated.uid, 'u1');
      expect(updated.email, 'updated@example.com');
      expect(updated.name, 'Updated');
      expect(updated.roles, [UserRole.seller]);
      expect(updated.suspended, true);
      expect(updated.isPremium, true);
    });

    test('canSell checks multiple conditions', () {
      final sellerComplete = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        onboardingCompleted: true,
        chargesEnabled: true,
        payoutsEnabled: true,
      );

      final sellerSuspended = UserModel(
        uid: 'u2',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        onboardingCompleted: true,
        chargesEnabled: true,
        payoutsEnabled: true,
        suspended: true,
      );

      final buyerNotSeller = UserModel(
        uid: 'u3',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
        onboardingCompleted: true,
        chargesEnabled: true,
        payoutsEnabled: true,
      );

      expect(sellerSuspended.suspended, true);
      expect(buyerNotSeller.roles, [UserRole.buyer]);
      expect(sellerComplete.onboardingCompleted, true);
    });

    test('canReceivePayouts field checks', () {
      final sellerComplete = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        payoutsEnabled: true,
        onboardingCompleted: true,
      );

      final buyer = UserModel(
        uid: 'u2',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
        payoutsEnabled: true,
        onboardingCompleted: true,
      );

      expect(sellerComplete.payoutsEnabled, true);
      expect(sellerComplete.onboardingCompleted, true);
      expect(buyer.roles, [UserRole.buyer]);
    });

    test('hasPendingRequirements works correctly', () {
      final withReqs = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        pendingRequirements: ['document', 'verification'],
      );

      final withoutReqs = UserModel(
        uid: 'u2',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        pendingRequirements: [],
      );

      expect(withReqs.hasPendingRequirements, true);
      expect(withoutReqs.hasPendingRequirements, false);
    });
  });

  group('DocumentSnapshot', () {
    test('data returns stored map', () {
      final data = {'key': 'value'};
      final doc = DocumentSnapshot(id: 'doc1', data: data);

      expect(doc.id, 'doc1');
      expect(doc.data(), data);
    });

    test('data returns empty map when empty', () {
      final doc = DocumentSnapshot(id: 'doc_empty', data: {});
      expect(doc.data(), isEmpty);
    });
  });

  group('FavoriteItem', () {
    test('fromDocument creates valid FavoriteItem', () {
      final doc = DocumentSnapshot(
        id: 'fav_doc_001',
        data: {
          Fields.productId: 'prod_001',
          Fields.dateFavorited: DateTime(2024, 6, 15),
        },
      );

      final item = FavoriteItem.fromDocument(doc);

      expect(item.productId, 'prod_001');
      expect(item.dateFavorited, DateTime(2024, 6, 15));
    });

    test('fromDocument uses doc.id when productId missing', () {
      final doc = DocumentSnapshot(
        id: 'fav_doc_002',
        data: {Fields.dateFavorited: DateTime(2024, 6, 15)},
      );

      final item = FavoriteItem.fromDocument(doc);

      expect(item.productId, 'fav_doc_002');
    });

    test('toMap returns correct map', () {
      final item = FavoriteItem(
        productId: 'prod_003',
        dateFavorited: DateTime(2024, 6, 20),
      );

      final map = item.toMap();

      expect(map[Fields.productId], 'prod_003');
      expect(map[Fields.dateFavorited], DateTime(2024, 6, 20));
    });
  });

  group('CartModel - Additional Coverage', () {
    test('fromMap with missing quantity defaults to 1', () {
      final map = {
        Fields.productId: 'p1',
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final cart = CartModel.fromMap(map);

      expect(cart.quantity, 1);
    });

    test('fromMap with explicit zero quantity', () {
      final map = {
        Fields.productId: 'p1',
        Fields.quantity: 0,
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final cart = CartModel.fromMap(map);

      expect(cart.quantity, 0);
    });

    test('fromMap uses docId for cartItemId', () {
      final map = {
        Fields.productId: 'p1',
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final cart = CartModel.fromMap(map, docId: 'cart_001');

      expect(cart.cartItemId, 'cart_001');
    });

    test('toMap omits null variant fields', () {
      final cart = CartModel(
        productId: 'p1',
        quantity: 1,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = cart.toMap();

      expect(map.containsKey(Fields.variantId), false);
      expect(map.containsKey(Fields.variantSku), false);
      expect(map.containsKey(Fields.priceSnapshot), false);
    });
  });

  group('CartItemModel - Additional Coverage', () {
    test('fromMap with all variant fields', () {
      final map = {
        Fields.productId: 'p1',
        Fields.quantity: 2,
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.variantId: 'v1',
        Fields.variantTitle: 'Large',
        Fields.variantOptions: {'size': 'L'},
        Fields.buyerNote: 'Gift wrap',
      };

      final item = CartItemModel.fromMap(map);

      expect(item.variantId, 'v1');
      expect(item.variantTitle, 'Large');
      expect(item.variantOptions, {'size': 'L'});
      expect(item.buyerNote, 'Gift wrap');
    });

    test('toMap with cartItemId', () {
      final item = CartItemModel(
        cartItemId: 'cart_item_001',
        productId: 'p1',
        quantity: 3,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = item.toMap();

      expect(map[Fields.productId], 'p1');
      expect(map[Fields.quantity], 3);
    });
  });

  group('ImageModel', () {
    test('constructor creates valid ImageModel', () {
      final image = ImageModel(
        url: 'https://example.com/image.jpg',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(image.url, 'https://example.com/image.jpg');
      expect(image.bytes.length, 4);
    });
  });

  group('ProductCategories', () {
    test('constructor creates valid ProductCategories', () {
      final category = ProductCategories(
        categoryId: 1,
        name: 'Electronics',
        icon: Icons.computer,
      );

      expect(category.categoryId, 1);
      expect(category.name, 'Electronics');
    });
  });

  group('AddressDetails', () {
    test('constructor creates valid AddressDetails', () {
      final details = AddressDetails(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        latitude: 43.6532,
        longitude: -79.3832,
      );

      expect(details.street, '123 Main St');
      expect(details.city, 'Toronto');
      expect(details.latitude, 43.6532);
      expect(details.longitude, -79.3832);
    });
  });
}
