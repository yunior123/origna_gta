import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils.dart';

// ============================================================================
// BUYER ORDERS PROVIDER
// ============================================================================

/// Stream of paid/authorized orders for the current user (buyer)
/// Filters by payment status to show only confirmed orders
final buyerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .where('paymentStatus', whereIn: [
        PaymentStatus.paid.value,
        PaymentStatus.authorized.value,
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error) {
        debugPrint('Error in buyer orders stream: $error');
      })
      .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList());
});

/// Stream of orders with raw data for shipping approval status
final buyerOrdersRawProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .where('paymentStatus', whereIn: [
        PaymentStatus.paid.value,
        PaymentStatus.authorized.value,
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error) {
        debugPrint('Error in buyer orders raw stream: $error');
      })
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

/// Count of orders pending shipping approval
final pendingApprovalsCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(buyerOrdersRawProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) => o['shippingApprovalStatus'] == ShippingApprovalStatus.pending.value).length,
    orElse: () => 0,
  );
});

/// Legacy provider for backward compatibility
final userOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => OrderModel.fromDocument(doc)).toList());
});

// ============================================================================
// SELLER ORDERS PROVIDER
// ============================================================================

/// Stream of orders containing products from the current seller
/// Filters for paid/authorized orders only (ready for fulfillment)
final sellerOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('sellerIds', arrayContains: userId)
      .where('paymentStatus', whereIn: ['paid', 'authorized'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error) {
        debugPrint('Error in seller orders stream: $error');
      })
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
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

  /// Confirm receipt of delivered items (buyer action)
  /// Calls cloud function to handle payout to seller
  Future<OrderResult> confirmReceipt(String orderId, List<String> itemIds) async {
    try {
      final functions = FirebaseFunctions.instance;
      if (kDebugMode) {
        functions.useFunctionsEmulator('127.0.0.1', 8081);
      }

      final callable = functions.httpsCallable('confirm_order_receipt');
      await callable.call({
        'orderId': orderId,
        'itemIds': itemIds,
      });

      return OrderSuccess(message: 'Receipt confirmed! Seller will be paid.');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Function Error: ${e.code} - ${e.message}');
      return OrderError(message: e.message ?? 'Failed to confirm receipt', code: e.code);
    } catch (e) {
      debugPrint('Error confirming receipt: $e');
      return OrderError(message: e.toString());
    }
  }

  /// Confirm delivery (buyer confirms receipt) - legacy method
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

  /// Update shipping cost (seller action)
  Future<OrderResult> updateShippingCost({
    required String orderId,
    required double newShippingCost,
    required String reason,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      if (kDebugMode) {
        functions.useFunctionsEmulator('127.0.0.1', 8081);
      }

      final callable = functions.httpsCallable('update_shipping_cost');
      await callable.call({
        'orderId': orderId,
        'newShippingCost': newShippingCost,
        'reason': reason,
      });

      return OrderSuccess(message: 'Shipping cost updated');
    } on FirebaseFunctionsException catch (e) {
      return OrderError(message: e.message ?? 'Failed to update shipping', code: e.code);
    } catch (e) {
      return OrderError(message: e.toString());
    }
  }

  /// Capture payment after shipping confirmation (seller action)
  Future<OrderResult> capturePayment(String orderId) async {
    try {
      final functions = FirebaseFunctions.instance;
      if (kDebugMode) {
        functions.useFunctionsEmulator('127.0.0.1', 8081);
      }

      final callable = functions.httpsCallable('capture_payment');
      await callable.call({'orderId': orderId});

      return OrderSuccess(message: 'Payment captured successfully');
    } on FirebaseFunctionsException catch (e) {
      return OrderError(message: e.message ?? 'Failed to capture payment', code: e.code);
    } catch (e) {
      return OrderError(message: e.toString());
    }
  }

  /// Update item delivery status (seller action)
  Future<OrderResult> updateItemStatus({
    required String orderId,
    required String itemId,
    required String status,
    String? trackingNumber,
    String? carrier,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        return OrderError(message: 'Order not found');
      }

      final items = List<Map<String, dynamic>>.from(orderDoc.data()?['items'] ?? []);
      final itemIndex = items.indexWhere((item) => item['productId'] == itemId);

      if (itemIndex == -1) {
        return OrderError(message: 'Item not found in order');
      }

      items[itemIndex]['deliveryStatus'] = status;
      if (trackingNumber != null) {
        items[itemIndex]['trackingNumber'] = trackingNumber;
      }
      if (carrier != null) {
        items[itemIndex]['carrier'] = carrier;
      }

      await orderRef.update({'items': items});

      return OrderSuccess(message: 'Item status updated');
    } catch (e) {
      return OrderError(message: e.toString());
    }
  }
}

// ============================================================================
// ORDER RESULT TYPES
// ============================================================================

sealed class OrderResult {}

class OrderSuccess extends OrderResult {
  final String message;
  OrderSuccess({required this.message});
}

class OrderError extends OrderResult {
  final String message;
  final String? code;
  OrderError({required this.message, this.code});
}
