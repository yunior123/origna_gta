import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:origna_gta/utils/constants.dart';

abstract class OrderRepository {
  Stream<List<Map<String, dynamic>>> watchBuyerOrders(String userId);
  Stream<List<Map<String, dynamic>>> watchSellerOrders(String userId);
  Stream<Map<String, dynamic>?> watchPaidOrderBySession(String sessionId);
  Future<void> confirmReceipt(String orderId, List<String> itemIds);
  Future<void> updateShippingCost(String orderId, double newShippingCost, String reason);
  Future<void> capturePayment(String orderId);
  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber, String? carrier});
  Future<Map<String, dynamic>?> fetchOrderById(String orderId);
  Future<Map<String, dynamic>> createCheckoutSession(Map<String, dynamic> orderData);
  Future<void> updateLastSession(String userId, String sessionId, String orderId);
  Future<void> approveShippingCost(String orderId, bool approved);
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseOrderRepository(this._firestore, this._functions);

  @override
  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBuyerOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('paymentStatus', whereIn: [PaymentStatus.paid.value, PaymentStatus.authorized.value])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> watchSellerOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('sellerIds', arrayContains: userId)
        .where('paymentStatus', whereIn: ['paid', 'authorized'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  @override
  Stream<Map<String, dynamic>?> watchPaidOrderBySession(String sessionId) {
    return _firestore
        .collection('orders')
        .where('stripeSessionId', isEqualTo: sessionId)
        .where('paymentStatus', isEqualTo: PaymentStatus.paid.value)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return {'id': doc.id, ...doc.data()};
        });
  }

  @override
  Future<void> confirmReceipt(String orderId, List<String> itemIds) async {
    await _functions.httpsCallable('confirm_order_receipt').call({'orderId': orderId, 'itemIds': itemIds});
  }

  @override
  Future<void> updateShippingCost(String orderId, double newShippingCost, String reason) async {
    await _functions.httpsCallable('update_shipping_cost').call({'orderId': orderId, 'newShippingCost': newShippingCost, 'reason': reason});
  }

  @override
  Future<void> capturePayment(String orderId) async {
    await _functions.httpsCallable('capture_payment').call({'orderId': orderId});
  }

  @override
  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber, String? carrier}) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) throw Exception('Order not found');

    final items = List<Map<String, dynamic>>.from(orderDoc.data()?['items'] ?? []);
    final itemIndex = items.indexWhere((item) => item['productId'] == itemId);
    if (itemIndex == -1) throw Exception('Item not found');

    items[itemIndex]['deliveryStatus'] = status;
    if (trackingNumber != null) items[itemIndex]['trackingNumber'] = trackingNumber;
    if (carrier != null) items[itemIndex]['carrier'] = carrier;

    await orderRef.update({'items': items});
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession(Map<String, dynamic> orderData) async {
    final callable = _functions.httpsCallable('create_checkout_session');
    final response = await callable.call(orderData);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> updateLastSession(String userId, String sessionId, String orderId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastCheckoutSession': sessionId,
      'lastOrderId': orderId,
      'lastCheckoutTimestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> approveShippingCost(String orderId, bool approved) async {
    await _functions.httpsCallable('approve_shipping_cost').call({'orderId': orderId, 'approved': approved});
  }
}
