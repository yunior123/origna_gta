import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// BUYER ORDERS PROVIDER
// ============================================================================

/// Stream of orders for the current user (buyer)
final userOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(firestoreProvider)
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromDocument(doc))
          .toList());
});

// ============================================================================
// SELLER ORDERS PROVIDER
// ============================================================================

/// Stream of orders containing products from the current seller
/// Filters for paid/authorized orders only (ready for fulfillment)
final sellerOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(firestoreProvider)
      .collection('orders')
      .where('sellerIds', arrayContains: userId)
      .where('paymentStatus', whereIn: ['paid', 'authorized'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
});

// ============================================================================
// SINGLE ORDER PROVIDER
// ============================================================================

/// Fetches a single order by ID
final orderByIdProvider = FutureProvider.autoDispose.family<OrderModel?, String>((ref, orderId) async {
  final firestore = ref.watch(firestoreProvider);
  
  final doc = await firestore.collection('orders').doc(orderId).get();
  
  if (!doc.exists) return null;
  
  return OrderModel.fromDocument(doc);
});

// ============================================================================
// ORDERS CONTROLLER
// ============================================================================

final ordersControllerProvider = Provider<OrdersController>((ref) {
  return OrdersController(ref);
});

class OrdersController {
  final Ref _ref;
  
  OrdersController(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  /// Confirm delivery (buyer confirms receipt)
  Future<void> confirmDelivery(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'deliveryConfirmed': true,
      'deliveryConfirmedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark order as shipped (seller confirms shipping)
  Future<void> markAsShipped(String orderId, String trackingNumber) async {
    await _firestore.collection('orders').doc(orderId).update({
      'shippingStatus': 'shipped',
      'trackingNumber': trackingNumber,
      'shippedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rate a completed order
  Future<void> rateOrder(String orderId, int rating, String review) async {
    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      'review': review,
      'ratedAt': FieldValue.serverTimestamp(),
    });
  }
}
