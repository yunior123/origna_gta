import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/constants.dart' as constants;

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseOrderRepository(this._firestore, this._functions);

  @override
  Future<void> approveShippingCost(String orderId, bool approved) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.approveShippingCost).call({
      Fields.orderId: orderId,
      ApiKeys.approved: approved,
    });
  }

  @override
  Future<void> capturePayment(String orderId) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.capturePayment).call({Fields.orderId: orderId});
  }

  @override
  Future<void> confirmReceipt(String orderId, List<String> itemIds) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.confirmOrderReceipt).call({
      Fields.orderId: orderId,
      ApiKeys.itemIds: itemIds,
    });
  }

  @override
  Future<Map<String, dynamic>> createCheckoutSession(Map<String, dynamic> orderData) async {
    final callable = _functions.httpsCallable(CloudFunctionEndpoints.createCheckoutSession);
    final response = await callable.call(orderData);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<models.Order?> fetchOrderById(String orderId) async {
    final doc = await _firestore.collection(Collections.orders).doc(orderId).get();
    if (!doc.exists) return null;
    return models.Order.fromFirestore(doc);
  }

  @override
  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber, String? carrier}) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.updateItemStatus).call({
      Fields.orderId: orderId,
      Fields.productId: itemId,
      ApiKeys.newStatus: status,
      Fields.trackingNumber: ?trackingNumber,
      Fields.carrier: ?carrier,
    });
  }

  @override
  Future<void> updateLastSession(String userId, String sessionId, String orderId) async {
    await _firestore.collection(Collections.users).doc(userId).update({
      Fields.lastCheckoutSession: sessionId,
      Fields.lastOrderId: orderId,
      Fields.lastCheckoutTimestamp: FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateShippingCost(String orderId, double newShippingCost, String reason) async {
    await _functions.httpsCallable(CloudFunctionEndpoints.updateShippingCost).call({
      Fields.orderId: orderId,
      ApiKeys.newShippingCost: newShippingCost,
      ApiKeys.reason: reason,
    });
  }

  @override
  Stream<List<models.Order>> watchBuyerOrders(String userId) {
    return _firestore
        .collection(Collections.orders)
        .where(Fields.userId, isEqualTo: userId)
        .where(Fields.paymentStatus, whereIn: [
          constants.PaymentStatus.authorized.value,
          constants.PaymentStatus.captured.value,
          constants.PaymentStatus.refunded.value,
          constants.PaymentStatus.cancelled.value,
          constants.PaymentStatus.authorizationExpired.value,
        ])
        .orderBy(Fields.createdAt, descending: true)
        .limit(50) // Pagination: limit initial load for scalability (100M+ users)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => models.Order.fromFirestore(doc)).toList());
  }

  @override
  Stream<models.Order?> watchPaidOrderBySession(String sessionId) {
    return _firestore
        .collection(Collections.orders)
        .where(Fields.stripeSessionId, isEqualTo: sessionId)
        .where(Fields.paymentStatus, isEqualTo: constants.PaymentStatus.captured.value)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return models.Order.fromFirestore(snapshot.docs.first);
        });
  }

  @override
  Stream<List<models.Order>> watchSellerOrders(String userId) {
    return _firestore
        .collection(Collections.orders)
        .where(Fields.sellerIds, arrayContains: userId)
        .where(Fields.paymentStatus, whereIn: [
          constants.PaymentStatus.authorized.value,
          constants.PaymentStatus.captured.value,
          constants.PaymentStatus.refunded.value,
          constants.PaymentStatus.cancelled.value,
          constants.PaymentStatus.authorizationExpired.value,
        ])
        .orderBy(Fields.createdAt, descending: true)
        .limit(50) // Pagination: limit initial load for scalability (100M+ users)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => models.Order.fromFirestore(doc)).toList());
  }
}

abstract class OrderRepository {
  Future<void> approveShippingCost(String orderId, bool approved);
  Future<void> capturePayment(String orderId);
  Future<void> confirmReceipt(String orderId, List<String> itemIds);
  Future<Map<String, dynamic>> createCheckoutSession(Map<String, dynamic> orderData);
  Future<models.Order?> fetchOrderById(String orderId);
  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber, String? carrier});
  Future<void> updateLastSession(String userId, String sessionId, String orderId);
  Future<void> updateShippingCost(String orderId, double newShippingCost, String reason);
  Stream<List<models.Order>> watchBuyerOrders(String userId);
  Stream<models.Order?> watchPaidOrderBySession(String sessionId);
  Stream<List<models.Order>> watchSellerOrders(String userId);
}
