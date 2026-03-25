import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/models/generated/order_models.dart';
import 'package:origna_gta/models/models.dart' hide SellerPayout;

void main() {
  group('Order (freezed) creation', () {
    test('creates with required fields', () {
      final order = Order(
        orderId: 'ord_123',
        userId: 'user_1',
        items: const [
          OrderItem(
            productId: 'p1',
            name: 'Product',
            description: '',
            priceCents: 1000,
            quantity: 1,
            imageUrls: [],
            sellerId: 's1',
          ),
        ],
        totalAmountCents: 1130,
        subtotalCents: 1000,
        taxes: const Taxes(),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(order.orderId, 'ord_123');
      expect(order.userId, 'user_1');
      expect(order.items.length, 1);
      expect(order.totalAmountCents, 1130);
    });

    test('has correct defaults', () {
      final order = Order(
        orderId: 'ord_1',
        userId: 'user_1',
        items: const [],
        totalAmountCents: 0,
        subtotalCents: 0,
        taxes: const Taxes(),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(order.orderStatus, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaitingPayment);
      expect(order.shippingCostCents, 0);
      expect(order.taxAmountCents, 0);
      expect(order.version, 1);
      expect(order.schemaVersion, 1);
      expect(order.currency, BusinessRules.defaultCurrency);
    });
  });

  group('OrderItem', () {
    test('creates with required fields', () {
      const item = OrderItem(
        productId: 'p1',
        name: 'Test',
        description: '',
        priceCents: 1000,
        quantity: 2,
        imageUrls: [],
        sellerId: 's1',
      );
      expect(item.productId, 'p1');
      expect(item.priceCents, 1000);
      expect(item.quantity, 2);
    });

    test('creates with all optional fields', () {
      final item = OrderItem(
        productId: 'p1',
        name: 'Test Product',
        description: 'A detailed description',
        priceCents: 1500,
        quantity: 1,
        imageUrls: const ['https://example.com/img.jpg'],
        sellerId: 's1',
        trackingNumber: 'TRACK123',
        carrier: 'Canada Post',
        carrierNote: 'Leave at door',
        status: DeliveryStatusValues.shipped,
        shippedAt: DateTime(2026, 1, 15),
        deliveredAt: DateTime(2026, 1, 20),
        refundedAt: DateTime(2026, 2, 1),
        refundReason: 'Defective',
        refundAmountCents: 1500,
        refundId: 'ref_123',
        confirmedByBuyer: true,
        variantId: 'var_1',
        variantTitle: 'Red / Large',
        variantOptions: const {'color': 'Red', 'size': 'Large'},
        variantSku: 'SKU-RED-L',
        weightKg: 2.5,
        lengthCm: 30.0,
        widthCm: 20.0,
        heightCm: 10.0,
        isLocalDeliveryOnly: false,
        isPerishable: false,
        isDigital: false,
        taxCode: 'txcd_12345678',
        buyerNote: 'Please handle with care',
        fulfillmentWarehouseId: 'wh_1',
      );

      expect(item.trackingNumber, 'TRACK123');
      expect(item.carrier, 'Canada Post');
      expect(item.variantTitle, 'Red / Large');
      expect(item.refundAmountCents, 1500);
      expect(item.isDigital, isFalse);
      expect(item.buyerNote, 'Please handle with care');
      expect(item.description, 'A detailed description');
    });

    test('has correct defaults', () {
      const item = OrderItem(
        productId: 'p1',
        name: 'Test',
        description: '',
        priceCents: 1000,
        quantity: 1,
        imageUrls: [],
        sellerId: 's1',
      );
      expect(item.status, DeliveryStatusValues.pending);
      expect(item.confirmedByBuyer, isFalse);
      expect(item.isLocalDeliveryOnly, isFalse);
      expect(item.isPerishable, isFalse);
      expect(item.isDigital, isFalse);
      expect(item.freeShipping, isFalse);
      expect(item.estimatedShipDays, 3);
      expect(item.minimumOrderQuantity, 1);
      expect(item.description, '');
      expect(item.imageUrls, isEmpty);
    });
  });

  group('Taxes model', () {
    test('creates with all tax types', () {
      const taxes = Taxes(
        gstCents: 500,
        pstCents: 700,
        hstCents: 1300,
        qstCents: 998,
      );
      expect(taxes.gstCents, 500);
      expect(taxes.pstCents, 700);
      expect(taxes.hstCents, 1300);
      expect(taxes.qstCents, 998);
    });

    test('default taxes are zero', () {
      const taxes = Taxes();
      expect(taxes.gstCents, 0);
      expect(taxes.pstCents, 0);
      expect(taxes.hstCents, 0);
      expect(taxes.qstCents, 0);
    });

    test('dollar getters convert correctly', () {
      const taxes = Taxes(gstCents: 500, hstCents: 1300);
      expect(taxes.gst, closeTo(5.0, 0.01));
      expect(taxes.hst, closeTo(13.0, 0.01));
    });

    test('fromMap handles various data', () {
      final taxes = Taxes.fromMap({Fields.GST: 5.0, Fields.HST: 13.0});
      expect(taxes.gstCents, 500);
      expect(taxes.hstCents, 1300);
    });

    test('fromMap handles integer cents', () {
      final taxes = Taxes.fromMap({Fields.GST: 500, Fields.PST: 700});
      expect(taxes.gstCents, 500);
      expect(taxes.pstCents, 700);
    });
  });

  group('Ratings model', () {
    test('creates with required fields', () {
      final rating = Ratings(
        productId: 'p1',
        rating: 4.5,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(rating.productId, 'p1');
      expect(rating.rating, 4.5);
      expect(rating.review, isNull);
    });

    test('creates with review', () {
      final rating = Ratings(
        productId: 'p1',
        rating: 5.0,
        review: 'Great product!',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(rating.review, 'Great product!');
    });
  });

  group('OrderStatus enum', () {
    test('all statuses are defined', () {
      expect(OrderStatus.values.length, greaterThan(0));
      expect(OrderStatus.values, contains(OrderStatus.pending));
      expect(OrderStatus.values, contains(OrderStatus.confirmed));
      expect(OrderStatus.values, contains(OrderStatus.cancelled));
    });
  });

  group('PaymentStatus enum', () {
    test('all statuses are defined', () {
      expect(PaymentStatus.values.length, greaterThan(0));
      expect(PaymentStatus.values, contains(PaymentStatus.awaitingPayment));
      expect(PaymentStatus.values, contains(PaymentStatus.captured));
    });
  });

  group('Order.fromMap parsing', () {
    test('parses items through _parseOrderItem', () {
      final order = Order.fromMap({
        Fields.orderId: 'ord_parse',
        Fields.userId: 'user_1',
        Fields.items: [
          {
            Fields.productId: 'p1',
            Fields.name: 'Product 1',
            Fields.description: 'Desc',
            Fields.priceCents: 2500,
            Fields.quantity: 2,
            Fields.imageUrls: ['img1.jpg', 'img2.jpg'],
            Fields.sellerId: 's1',
            Fields.sellerName: 'Seller 1',
            Fields.status: DeliveryStatusValues.shipped,
            Fields.trackingNumber: 'TRACK-001',
            Fields.carrier: 'Canada Post',
            Fields.carrierNote: 'Front door',
            Fields.sellerSku: 'SKU-001',
            Fields.shippedAt: '2026-01-15T12:00:00Z',
            Fields.deliveredAt: '2026-01-20T12:00:00Z',
            Fields.confirmedByBuyer: true,
            Fields.variantId: 'var_1',
            Fields.variantTitle: 'Red/Large',
            Fields.variantOptions: {'color': 'Red', 'size': 'Large'},
            Fields.variantSku: 'SKU-RED-L',
            Fields.weightKg: 2.5,
            Fields.lengthCm: 30.0,
            Fields.widthCm: 20.0,
            Fields.heightCm: 10.0,
            Fields.isLocalDeliveryOnly: false,
            Fields.isPerishable: true,
            Fields.estimatedShipDays: 5,
            Fields.freeShipping: true,
            Fields.isDigital: false,
            Fields.taxCode: 'txcd_12345678',
            Fields.buyerNote: 'Gift wrapped',
            Fields.fulfillmentWarehouseId: 'wh_1',
            Fields.sellerAddress: {
              Fields.street: '456 Seller St',
              Fields.city: 'Vancouver',
              Fields.state: 'BC',
              Fields.postalCode: 'V1V 1V1',
              Fields.country: 'CA',
              Fields.latitude: 49.28,
              Fields.longitude: -123.12,
            },
          },
          {
            Fields.productId: 'p2',
            Fields.name: 'Digital Product',
            Fields.description: 'Digital desc',
            Fields.price: 5.0, // Legacy price field
            Fields.quantity: 1,
            Fields.sellerId: 's2',
            Fields.isDigital: true,
            Fields.licenseKey: 'LICENSE-KEY-123',
            Fields.digitalUnlocked: true,
            Fields.digitalType: 'software',
            Fields.digitalBuilds: {
              'windows': 'https://dl.com/win',
              'mac': 'https://dl.com/mac',
            },
          },
        ],
        Fields.totalAmountCents: 5500,
        Fields.subtotalCents: 5000,
        Fields.shippingCostCents: 200,
        Fields.taxAmountCents: 300,
        Fields.taxes: {Fields.GST: 5.0, Fields.PST: 7.0},
        Fields.orderStatus: OrderStatusValues.confirmed,
        Fields.paymentStatus: PaymentStatusValues.captured,
        Fields.shippingAddress: {
          Fields.street: '123 Main',
          Fields.city: 'Toronto',
          Fields.state: 'ON',
          Fields.postalCode: 'M1M 1M1',
          Fields.country: 'CA',
          Fields.phoneNumber: '+14165551234',
          Fields.isDefault: true,
          Fields.label: 'Home',
        },
        Fields.createdAt: '2026-01-01T00:00:00Z',
        Fields.sellerIds: ['s1', 's2'],
        Fields.stripeSessionId: 'sess_123',
        Fields.stripePaymentIntentId: 'pi_123',
        Fields.platformFeeTotalCents: 500,
        Fields.couponCode: 'SAVE10',
        Fields.discountAmountCents: 1000,
        Fields.deliveryInstructions: 'Leave at back door',
        Fields.sellerPayouts: [
          {
            Fields.sellerId: 's1',
            Fields.sellerName: 'Seller 1',
            'grossAmountCents': 4500,
            'platformFeeCents': 450,
            'netPayoutCents': 4050,
          },
        ],
        Fields.ratings: [
          {
            Fields.productId: 'p1',
            Fields.rating: 4.5,
            Fields.review: 'Great product',
            Fields.createdAt: '2026-02-01T00:00:00Z',
          },
        ],
      }, 'ord_parse');

      // Verify items parsed correctly
      expect(order.items.length, 2);

      // First item (physical with all fields)
      final item1 = order.items[0];
      expect(item1.productId, 'p1');
      expect(item1.priceCents, 2500);
      expect(item1.quantity, 2);
      expect(item1.trackingNumber, 'TRACK-001');
      expect(item1.carrier, 'Canada Post');
      expect(item1.confirmedByBuyer, isTrue);
      expect(item1.variantId, 'var_1');
      expect(item1.weightKg, 2.5);
      expect(item1.isPerishable, isTrue);
      expect(item1.buyerNote, 'Gift wrapped');
      expect(item1.sellerAddress, isNotNull);
      expect(item1.sellerAddress!.state, 'BC');

      // Second item (digital with legacy price)
      final item2 = order.items[1];
      expect(item2.productId, 'p2');
      expect(item2.priceCents, 500); // Converted from price: 5.0
      expect(item2.isDigital, isTrue);
      expect(item2.licenseKey, 'LICENSE-KEY-123');
      expect(item2.digitalUnlocked, isTrue);

      // Verify order-level fields
      expect(order.orderId, 'ord_parse');
      expect(order.orderStatus, OrderStatus.confirmed);
      expect(order.paymentStatus, PaymentStatus.captured);
      expect(order.platformFeeTotalCents, 500);
      expect(order.couponCode, 'SAVE10');
      expect(order.discountAmountCents, 1000);
      expect(order.shippingAddress, isNotNull);
      expect(order.shippingAddress!.phoneNumber, '+14165551234');

      // Verify taxes
      expect(order.taxes.gstCents, 500);
      expect(order.taxes.pstCents, 700);

      // Verify seller payouts
      expect(order.sellerPayouts.length, 1);

      // Verify ratings
      expect(order.ratings.length, 1);
      expect(order.ratings.first.rating, 4.5);
    });

    test('parses with minimal data', () {
      final order = Order.fromMap({
        Fields.userId: 'user_1',
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.createdAt: '2026-01-01T00:00:00Z',
      }, 'ord_min');

      expect(order.orderId, 'ord_min');
      expect(order.items, isEmpty);
      expect(order.orderStatus, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaitingPayment);
    });

    test('parses integer timestamp for createdAt', () {
      final order = Order.fromMap({
        Fields.userId: 'user_1',
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      }, 'ord_ts');

      expect(order.createdAt.year, 2026);
    });

    test('handles refunded item', () {
      final order = Order.fromMap({
        Fields.userId: 'user_1',
        Fields.items: [
          {
            Fields.productId: 'p1',
            Fields.name: 'Refunded Item',
            Fields.description: 'desc',
            Fields.priceCents: 1000,
            Fields.quantity: 1,
            Fields.sellerId: 's1',
            Fields.refundedAt: '2026-02-01T00:00:00Z',
            Fields.refundReason: 'Defective',
            Fields.refundAmountCents: 1000,
            Fields.refundId: 'ref_123',
          },
        ],
        Fields.totalAmountCents: 1000,
        Fields.subtotalCents: 1000,
        Fields.createdAt: '2026-01-01T00:00:00Z',
      }, 'ord_refund');

      final item = order.items.first;
      expect(item.refundReason, 'Defective');
      expect(item.refundAmountCents, 1000);
      expect(item.refundId, 'ref_123');
      expect(item.refundedAt, isNotNull);
    });
  });

  group('Order serialization', () {
    test('toJson produces valid map', () {
      final order = Order(
        orderId: 'ord_round',
        userId: 'user_1',
        items: const [
          OrderItem(
            productId: 'p1',
            name: 'Product',
            description: '',
            priceCents: 1000,
            quantity: 1,
            imageUrls: [],
            sellerId: 's1',
          ),
        ],
        totalAmountCents: 1130,
        subtotalCents: 1000,
        shippingCostCents: 0,
        taxAmountCents: 130,
        taxes: const Taxes(hstCents: 130),
        createdAt: DateTime(2026, 1, 1),
      );

      final json = order.toJson();
      expect(json, isNotNull);
      expect(json['orderId'], 'ord_round');
      expect(json['totalAmountCents'], 1130);
    });
  });

  group('OrderModel.fromMap', () {
    test('parses from map with items', () {
      final order = OrderModel.fromMap({
        Fields.orderId: 'ord_1',
        Fields.userId: 'user_1',
        Fields.customerId: 'cust_1',
        Fields.customerEmail: 'test@test.com',
        Fields.items: [
          {
            Fields.productId: 'p1',
            Fields.name: 'Item 1',
            Fields.price: 10.0,
            Fields.quantity: 2,
            Fields.sellerId: 's1',
            Fields.createdAt: DateTime.now().toIso8601String(),
          },
        ],
        Fields.totalAmountCents: 2500,
        Fields.subtotalCents: 2000,
        Fields.shippingCostCents: 200,
        Fields.taxAmountCents: 300,
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.shippingAddress: {
          Fields.street: '123 Main',
          Fields.city: 'Toronto',
          Fields.state: 'ON',
          Fields.postalCode: 'M1M 1M1',
          Fields.country: 'CA',
        },
        Fields.createdAt: DateTime.now().toIso8601String(),
        Fields.currency: 'CAD',
        Fields.sellerIds: ['s1'],
        Fields.stripeSessionId: 'sess_123',
      });

      expect(order.orderId, 'ord_1');
      expect(order.items.length, 1);
      expect(order.totalAmountCents, 2500);
      expect(order.subtotalCents, 2000);
      expect(order.shippingCostCents, 200);
    });

    test('handles missing optional fields', () {
      final order = OrderModel.fromMap({
        Fields.orderId: 'ord_2',
        Fields.userId: 'user_1',
        Fields.items: [],
        Fields.totalAmountCents: 0,
        Fields.subtotalCents: 0,
        Fields.orderStatus: OrderStatusValues.pending,
        Fields.shippingAddress: {},
        Fields.createdAt: DateTime.now().toIso8601String(),
      });

      expect(order.orderId, 'ord_2');
      expect(order.items, isEmpty);
      expect(order.sellerPayouts, isEmpty);
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
}
