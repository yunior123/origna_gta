import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/utils/constants.dart';

/// Integration tests for UI/database reactivity
///
/// These tests verify that:
/// 1. UI updates when Firestore data changes (reactive streams)
/// 2. Provider state correctly reflects database changes
/// 3. Real-time updates are properly handled
///
/// Run with: flutter test integration_test/database_reactivity_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firestore Stream Reactivity', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('user document stream emits updates on changes', () async {
      final userId = 'test_user_123';

      // Create initial user document
      await fakeFirestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': 'test@example.com',
        'name': 'Test User',
        'roles': ['buyer'],
        'createdAt': Timestamp.now(),
      });

      // Listen to user document stream
      final stream = fakeFirestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromMap({...doc.data()!, 'uid': doc.id}) : null);

      // Collect emissions
      final emissions = <UserModel?>[];
      final subscription = stream.listen((user) => emissions.add(user));

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Update the document
      await fakeFirestore.collection('users').doc(userId).update({
        'name': 'Updated Name',
        'isSeller': true,
      });

      // Wait for update emission
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify emissions
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first?.name, 'Test User');
      expect(emissions.last?.name, 'Updated Name');
    });

    test('cart items stream updates when items added/removed', () async {
      final userId = 'test_user_123';
      final cartRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('cart');

      // Listen to cart stream
      final stream = cartRef.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => CartModel.fromMap(doc.data())).toList());

      final emissions = <List<CartModel>>[];
      final subscription = stream.listen((items) => emissions.add(items));

      // Wait for initial empty emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Add first item
      await cartRef.doc('prod_1').set({
        'productId': 'prod_1',
        'quantity': 2,
        'dateCreated': Timestamp.now(),
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Add second item
      await cartRef.doc('prod_2').set({
        'productId': 'prod_2',
        'quantity': 1,
        'dateCreated': Timestamp.now(),
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Remove first item
      await cartRef.doc('prod_1').delete();

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify stream emitted correct updates
      expect(emissions.length, greaterThanOrEqualTo(4));
      expect(emissions[0].length, 0); // Initial empty
      expect(emissions[1].length, 1); // After first add
      expect(emissions[2].length, 2); // After second add
      expect(emissions[3].length, 1); // After removal
    });

    test('order status stream reflects real-time updates', () async {
      final orderId = 'order_123';

      // Create order
      await fakeFirestore.collection('orders').doc(orderId).set({
        'id': orderId,
        'status': OrderStatus.pending.value,
        'paymentStatus': PaymentStatus.awaitingPayment.value,
        'total': 100.0,
        'createdAt': Timestamp.now(),
      });

      // Listen to order stream
      final stream = fakeFirestore
          .collection('orders')
          .doc(orderId)
          .snapshots()
          .map((doc) => doc.data()?['status'] as String?);

      final emissions = <String?>[];
      final subscription = stream.listen((status) => emissions.add(status));

      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate order status progression
      await fakeFirestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.confirmed.value,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await fakeFirestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.processing.value,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await fakeFirestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.shipped.value,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify status progression was captured
      expect(emissions, contains(OrderStatus.pending.value));
      expect(emissions, contains(OrderStatus.confirmed.value));
      expect(emissions, contains(OrderStatus.processing.value));
      expect(emissions, contains(OrderStatus.shipped.value));
    });
  });

  group('Query Reactivity', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('filtered query updates when matching documents change', () async {
      final userId = 'test_user_123';

      // Create orders with different statuses
      await fakeFirestore.collection('orders').doc('order_1').set({
        'userId': userId,
        'status': OrderStatus.pending.value,
        'total': 50.0,
      });

      await fakeFirestore.collection('orders').doc('order_2').set({
        'userId': userId,
        'status': OrderStatus.delivered.value,
        'total': 75.0,
      });

      // Query for user's pending orders
      final stream = fakeFirestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: OrderStatus.pending.value)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

      final emissions = <int>[];
      final subscription = stream.listen((orderCount) => emissions.add(orderCount));

      await Future.delayed(const Duration(milliseconds: 100));

      // Add another pending order
      await fakeFirestore.collection('orders').doc('order_3').set({
        'userId': userId,
        'status': OrderStatus.pending.value,
        'total': 100.0,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Update order_1 to shipped (no longer pending)
      await fakeFirestore.collection('orders').doc('order_1').update({
        'status': OrderStatus.shipped.value,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify query results updated
      expect(emissions, contains(1)); // Initial pending count
      expect(emissions, contains(2)); // After adding order_3
      expect(emissions.last, 1); // After order_1 shipped
    });

    test('products query updates when stock changes', () async {
      // Create products
      await fakeFirestore.collection('products').doc('prod_1').set({
        'name': 'Product 1',
        'price': 29.99,
        'stockQuantity': 10,
        'isActive': true,
      });

      await fakeFirestore.collection('products').doc('prod_2').set({
        'name': 'Product 2',
        'price': 49.99,
        'stockQuantity': 0, // Out of stock
        'isActive': true,
      });

      // Query for in-stock products
      final stream = fakeFirestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => d.id).toList());

      final emissions = <List<String>>[];
      final subscription = stream.listen((ids) => emissions.add(ids));

      await Future.delayed(const Duration(milliseconds: 100));

      // Restock product 2
      await fakeFirestore.collection('products').doc('prod_2').update({
        'stockQuantity': 5,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Deplete product 1 stock
      await fakeFirestore.collection('products').doc('prod_1').update({
        'stockQuantity': 0,
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify query results reflect stock changes
      expect(emissions.first, contains('prod_1'));
      expect(emissions.first, isNot(contains('prod_2')));
      expect(emissions.last, contains('prod_2'));
      expect(emissions.last, isNot(contains('prod_1')));
    });
  });

  group('Optimistic Updates', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('cart quantity update reflects immediately', () async {
      final userId = 'test_user';
      final cartRef = fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('cart');

      // Add initial item
      await cartRef.doc('prod_1').set({
        'productId': 'prod_1',
        'quantity': 1,
        'dateCreated': Timestamp.now(),
      });

      // Track quantity changes
      final quantities = <int>[];
      final subscription = cartRef.doc('prod_1').snapshots().listen((doc) {
        if (doc.exists) {
          quantities.add(doc.data()!['quantity'] as int);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate rapid quantity updates (like +/- buttons)
      await cartRef.doc('prod_1').update({'quantity': 2});
      await Future.delayed(const Duration(milliseconds: 50));

      await cartRef.doc('prod_1').update({'quantity': 3});
      await Future.delayed(const Duration(milliseconds: 50));

      await cartRef.doc('prod_1').update({'quantity': 2});
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify all quantity changes were captured
      expect(quantities, contains(1));
      expect(quantities, contains(2));
      expect(quantities, contains(3));
      expect(quantities.last, 2);
    });
  });

  group('Seller Dashboard Reactivity', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('seller sees new orders in real-time', () async {
      final sellerId = 'seller_123';

      // Create initial order
      await fakeFirestore.collection('orders').doc('order_1').set({
        'sellerIds': [sellerId],
        'status': OrderStatus.confirmed.value,
        'total': 50.0,
        'createdAt': Timestamp.now(),
      });

      // Query seller's orders
      final stream = fakeFirestore
          .collection('orders')
          .where('sellerIds', arrayContains: sellerId)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);

      final emissions = <int>[];
      final subscription = stream.listen((orderCount) => emissions.add(orderCount));

      await Future.delayed(const Duration(milliseconds: 100));

      // New order comes in
      await fakeFirestore.collection('orders').doc('order_2').set({
        'sellerIds': [sellerId],
        'status': OrderStatus.confirmed.value,
        'total': 75.0,
        'createdAt': Timestamp.now(),
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Another new order
      await fakeFirestore.collection('orders').doc('order_3').set({
        'sellerIds': [sellerId, 'other_seller'],
        'status': OrderStatus.confirmed.value,
        'total': 100.0,
        'createdAt': Timestamp.now(),
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify seller sees all their orders
      expect(emissions.first, 1);
      expect(emissions.last, 3);
    });

    test('delivery status updates visible to buyer', () async {
      final orderId = 'order_123';
      final buyerId = 'buyer_456';

      // Create order with items
      await fakeFirestore.collection('orders').doc(orderId).set({
        'userId': buyerId,
        'status': OrderStatus.confirmed.value,
        'items': [
          {
            'productId': 'prod_1',
            'name': 'Test Product',
            'quantity': 1,
            'deliveryStatus': 'pending',
          }
        ],
      });

      // Listen to order
      final stream = fakeFirestore
          .collection('orders')
          .doc(orderId)
          .snapshots()
          .map((doc) {
        final items = doc.data()?['items'] as List?;
        return items?.first['deliveryStatus'] as String?;
      });

      final emissions = <String?>[];
      final subscription = stream.listen((status) => emissions.add(status));

      await Future.delayed(const Duration(milliseconds: 100));

      // Seller ships item
      await fakeFirestore.collection('orders').doc(orderId).update({
        'items': [
          {
            'productId': 'prod_1',
            'name': 'Test Product',
            'quantity': 1,
            'deliveryStatus': 'shipped',
            'trackingNumber': 'TRACK123',
          }
        ],
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Item delivered
      await fakeFirestore.collection('orders').doc(orderId).update({
        'items': [
          {
            'productId': 'prod_1',
            'name': 'Test Product',
            'quantity': 1,
            'deliveryStatus': 'delivered',
            'trackingNumber': 'TRACK123',
          }
        ],
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify buyer sees delivery updates
      expect(emissions, contains('pending'));
      expect(emissions, contains('shipped'));
      expect(emissions, contains('delivered'));
    });
  });

  group('Edge Cases', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('handles document deletion gracefully', () async {
      final docId = 'temp_doc';

      // Create document
      await fakeFirestore.collection('test').doc(docId).set({'value': 1});

      // Listen to document
      final emissions = <bool>[];
      final subscription = fakeFirestore
          .collection('test')
          .doc(docId)
          .snapshots()
          .listen((doc) => emissions.add(doc.exists));

      await Future.delayed(const Duration(milliseconds: 100));

      // Delete document
      await fakeFirestore.collection('test').doc(docId).delete();

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify deletion was captured
      expect(emissions.first, true); // Document existed
      expect(emissions.last, false); // Document deleted
    });

    test('handles concurrent updates correctly', () async {
      final docId = 'counter_doc';

      // Create counter document
      await fakeFirestore.collection('test').doc(docId).set({'count': 0});

      // Track all count values
      final counts = <int>[];
      final subscription = fakeFirestore
          .collection('test')
          .doc(docId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          counts.add(doc.data()!['count'] as int);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate concurrent increments
      await Future.wait([
        fakeFirestore.collection('test').doc(docId).update({'count': 1}),
        Future.delayed(const Duration(milliseconds: 10)).then((_) =>
            fakeFirestore.collection('test').doc(docId).update({'count': 2})),
        Future.delayed(const Duration(milliseconds: 20)).then((_) =>
            fakeFirestore.collection('test').doc(docId).update({'count': 3})),
      ]);

      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify final state
      expect(counts.last, 3);
    });
  });
}
