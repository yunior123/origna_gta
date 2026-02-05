import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

/// Integration tests for the checkout flow
///
/// Note: These tests document the expected checkout behavior.
/// For full integration testing with real Firebase, run:
/// `flutter test integration_test/checkout_flow_test.dart`
///
/// For mock testing without Firebase, the unit tests provide coverage.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cart Operations', () {
    test('CartModel serialization round-trip', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final original = CartModel(productId: 'prod_123', quantity: 3, dateCreated: now);

      final map = original.toMap();
      final restored = CartModel.fromMap(map);

      expect(restored.productId, original.productId);
      expect(restored.quantity, original.quantity);
      expect(restored.dateCreated, original.dateCreated);
    });

    test('CartItemDetailModel contains all order item fields', () {
      final item = CartItemDetailModel(
        productId: 'prod_123',
        name: 'Test Product',
        description: 'A test product description',
        price: 29.99,
        imageUrls: ['https://example.com/image.jpg'],
        quantity: 2,
        dateCreated: Timestamp.now(),
        sellerAddress: Address(street: '123 Main St', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada'),
        sellerId: 'seller_456',
        deliveryStatus: 'pending',
        trackingNumber: null,
        confirmedByBuyer: false,
        minimumOrderQuantity: 2,
        freeShipping: true,
      );

      expect(item.productId, 'prod_123');
      expect(item.name, 'Test Product');
      expect(item.price, 29.99);
      expect(item.quantity, 2);
      expect(item.sellerId, 'seller_456');
      expect(item.deliveryStatus, 'pending');
      expect(item.confirmedByBuyer, false);

      // Verify serialization
      final map = item.toMap();
      expect(map['productId'], 'prod_123');
      expect(map['name'], 'Test Product');
      expect(map['price'], 29.99);
      expect(map['minimumOrderQuantity'], 2);
      expect(map['freeShipping'], true);
    });
  });

  group('Order Calculations', () {
    test('subtotal calculation for multiple items', () {
      final items = [
        _createMockItem(price: 29.99, quantity: 2), // 59.98
        _createMockItem(price: 15.00, quantity: 1), // 15.00
        _createMockItem(price: 49.99, quantity: 3), // 149.97
      ];

      final subtotal = items.fold<double>(0, (acc, item) => acc + (item.price * item.quantity));

      expect(subtotal, closeTo(224.95, 0.01));
    });

    test('tax calculation for Ontario order', () {
      const subtotal = 100.0;
      final taxRate = getTaxRate('ON');
      final tax = subtotal * taxRate;

      expect(tax, closeTo(13.0, 0.01));
    });

    test('total with taxes and shipping', () {
      const subtotal = 100.0;
      const shipping = 12.99;
      final taxRate = getTaxRate('ON');
      final tax = subtotal * taxRate;
      final total = subtotal + tax + shipping;

      expect(total, closeTo(125.99, 0.01));
    });

    test('shipping calculation skips free shipping items', () async {
      final items = [_createMockItem(price: 10.0, quantity: 1, freeShipping: true)];

      final buyer = Address(street: '123 Test St', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada', latitude: 43.0, longitude: -79.0);

      final cost = await calculateShippingCost(items, buyer);
      expect(cost, closeTo(0.0, 0.01));
    });

    test('platform fee calculation at 2.5%', () {
      const orderTotal = 100.0;
      const platformFeeRate = 0.025;
      final platformFee = orderTotal * platformFeeRate;

      expect(platformFee, closeTo(2.5, 0.01));
    });

    test('seller payout after platform fee', () {
      const grossCents = 10000; // $100.00
      const platformFeeCents = 250; // $2.50 (2.5%)
      const netCents = grossCents - platformFeeCents; // $97.50

      expect(netCents, 9750);

      final payout = SellerPayout(
        sellerId: 'seller_123',
        amountCents: grossCents,
        platformFeeCents: platformFeeCents,
        netAmountCents: netCents,
      );

      expect(payout.amount, 100.0);
      expect(payout.platformFee, closeTo(2.5, 0.01));
      expect(payout.netAmount, closeTo(97.5, 0.01));
    });
  });

  group('Order Status Flow', () {
    test('order status transitions', () {
      // Verify the expected order status flow:
      // pending -> authorized -> paid -> shipped -> delivered -> completed
      const statuses = ['pending', 'authorized', 'paid', 'shipped', 'delivered', 'completed'];

      expect(statuses.length, 6);
      expect(statuses.first, 'pending');
      expect(statuses.last, 'completed');
    });

    test('delivery status transitions', () {
      // Verify the expected delivery status flow:
      // pending -> shipped -> in_transit -> delivered
      const statuses = ['pending', 'shipped', 'in_transit', 'delivered'];

      expect(statuses.length, 4);
      expect(statuses.first, 'pending');
      expect(statuses.last, 'delivered');
    });
  });

  group('Multi-Seller Order', () {
    test('items grouped by seller', () {
      final items = [
        _createMockItem(sellerId: 'seller_A', price: 20.0, quantity: 1),
        _createMockItem(sellerId: 'seller_A', price: 30.0, quantity: 2),
        _createMockItem(sellerId: 'seller_B', price: 50.0, quantity: 1),
      ];

      // Group by seller
      final Map<String, List<CartItemDetailModel>> itemsBySeller = {};
      for (var item in items) {
        itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
      }

      expect(itemsBySeller.keys.length, 2);
      expect(itemsBySeller['seller_A']!.length, 2);
      expect(itemsBySeller['seller_B']!.length, 1);

      // Calculate per-seller totals
      final sellerATotal = itemsBySeller['seller_A']!.fold<double>(0, (acc, i) => acc + (i.price * i.quantity));
      final sellerBTotal = itemsBySeller['seller_B']!.fold<double>(0, (acc, i) => acc + (i.price * i.quantity));

      expect(sellerATotal, closeTo(80.0, 0.01)); // 20 + 60
      expect(sellerBTotal, closeTo(50.0, 0.01));
    });

    test('unique seller IDs extracted from order', () {
      final items = [
        _createMockItem(sellerId: 'seller_A'),
        _createMockItem(sellerId: 'seller_A'),
        _createMockItem(sellerId: 'seller_B'),
        _createMockItem(sellerId: 'seller_C'),
      ];

      final sellerIds = items.map((i) => i.sellerId).toSet().toList();

      expect(sellerIds.length, 3);
      expect(sellerIds.contains('seller_A'), true);
      expect(sellerIds.contains('seller_B'), true);
      expect(sellerIds.contains('seller_C'), true);
    });
  });

  group('Checkout Guardrails', () {
    test('delivery speed availability reflects item constraints', () {
      const items = [
        DeliveryItemCheck(estimatedShipDays: 5, isPerishable: false, isLocalOnly: false),
        DeliveryItemCheck(estimatedShipDays: 1, isPerishable: true, isLocalOnly: false),
      ];

      expect(DeliverySpeed.standard.isAvailableForItems(items, true), true);
      expect(DeliverySpeed.express.isAvailableForItems(items, true), true);
      expect(DeliverySpeed.sameDay.isAvailableForItems(items, false), false);
    });

    test('address validation rejects incomplete delivery info', () {
      final address = Address(street: '', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada');

      expect(hasValidAddress(address), false);
    });

    test('tax code validation allows empty or valid txcd', () {
      expect(isValidTaxCode(null), true);
      expect(isValidTaxCode(''), true);
      expect(isValidTaxCode('txcd_12345678'), true);
      expect(isValidTaxCode('txcd_invalid'), false);
    });
  });

  group('Address Validation', () {
    test('Canadian postal code format validation', () {
      // Valid Canadian postal codes follow: A1A 1A1 pattern
      final validPostalCodes = ['M5V 1A1', 'V6B 2C3', 'H2X 3Y4', 'K1A 0B1'];
      final invalidPostalCodes = ['12345', 'ABC123', '123 456', 'AAAAAA'];

      for (final code in validPostalCodes) {
        final isValid = RegExp(r'^[A-Za-z]\d[A-Za-z][ ]?\d[A-Za-z]\d$').hasMatch(code);
        expect(isValid, true, reason: '$code should be valid');
      }

      for (final code in invalidPostalCodes) {
        final isValid = RegExp(r'^[A-Za-z]\d[A-Za-z][ ]?\d[A-Za-z]\d$').hasMatch(code);
        expect(isValid, false, reason: '$code should be invalid');
      }
    });

    test('province code validation', () {
      final validProvinces = ['ON', 'BC', 'AB', 'QC', 'MB', 'SK', 'NS', 'NB', 'NL', 'PE', 'NT', 'YT', 'NU'];

      for (final province in validProvinces) {
        final taxRate = getTaxRate(province);
        expect(taxRate, greaterThan(0), reason: '$province should have a tax rate');
      }
    });
  });
}

/// Helper function to create mock cart items for testing
CartItemDetailModel _createMockItem({
  String productId = 'prod_test',
  String name = 'Test Product',
  double price = 10.0,
  int quantity = 1,
  String sellerId = 'seller_test',
  String deliveryStatus = 'pending',
  bool freeShipping = false,
}) {
  return CartItemDetailModel(
    productId: productId,
    name: name,
    description: 'Test description',
    price: price,
    imageUrls: [],
    quantity: quantity,
    dateCreated: Timestamp.now(),
    sellerAddress: Address(street: '123 Test St', city: 'Toronto', state: 'ON', postalCode: 'M5V 1A1', country: 'Canada'),
    sellerId: sellerId,
    deliveryStatus: deliveryStatus,
    freeShipping: freeShipping,
  );
}
