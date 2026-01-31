import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

// ============================================================================
// BUYER ORDERS PROVIDER
// ============================================================================

final buyerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchBuyerOrders(userId).map((list) {
    return list.map((m) {
      // Add id to map for OrderModel.fromMap if missing
      final data = Map<String, dynamic>.from(m);
      return OrderModel.fromMap(data);
    }).toList();
  });
});

final pendingApprovalsCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(buyerOrdersProvider);
  return ordersAsync.maybeWhen(data: (orders) => orders.where((o) => o.shippingApprovalStatus == ShippingApprovalStatus.pending.value).length, orElse: () => 0);
});

final pendingShippingApprovalsProvider = Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
  return ref.watch(buyerOrdersProvider).whenData((orders) {
    return orders.where((o) => o.shippingApprovalStatus == ShippingApprovalStatus.pending.value).toList();
  });
});

// ============================================================================
// SELLER ORDERS PROVIDER
// ============================================================================

final sellerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchSellerOrders(userId).map((list) {
    return list.map((m) => OrderModel.fromMap(m)).toList();
  });
});

// ============================================================================
// SINGLE ORDER PROVIDER
// ============================================================================

final orderByIdProvider = FutureProvider.autoDispose.family<OrderModel?, String>((ref, orderId) async {
  final data = await ref.watch(orderRepositoryProvider).fetchOrderById(orderId);
  if (data == null) return null;
  return OrderModel.fromMap(data);
});

/// Watch paid order by Stripe session ID (used for success redirect)
final paidOrderBySessionProvider = StreamProvider.autoDispose.family<OrderModel?, String>((ref, sessionId) {
  return ref.watch(orderRepositoryProvider).watchPaidOrderBySession(sessionId).map((data) {
    if (data == null) return null;
    return OrderModel.fromMap(data);
  });
});

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
