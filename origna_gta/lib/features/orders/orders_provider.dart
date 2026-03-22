import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/models.dart' as models;

// ============================================================================
// BUYER ORDERS PROVIDER
// ============================================================================

final buyerOrdersProvider = StreamProvider.autoDispose<List<models.Order>>((
  ref,
) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchBuyerOrders(userId);
});

// ============================================================================
// SINGLE ORDER PROVIDER
// ============================================================================

final orderByIdProvider = FutureProvider.autoDispose
    .family<models.Order?, String>((ref, orderId) async {
      return await ref.watch(orderRepositoryProvider).fetchOrderById(orderId);
    });

/// Watch paid order by Stripe session ID (used for success redirect)
final paidOrderBySessionProvider = StreamProvider.autoDispose
    .family<models.Order?, String>((ref, sessionId) {
      return ref
          .watch(orderRepositoryProvider)
          .watchPaidOrderBySession(sessionId);
    });

final pendingApprovalsCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(buyerOrdersProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders
        .where(
          (o) =>
              o.shippingApprovalStatus == models.ShippingApprovalStatus.pending,
        )
        .length,
    orElse: () => 0,
  );
});

final pendingShippingApprovalsProvider =
    Provider.autoDispose<AsyncValue<List<models.Order>>>((ref) {
      return ref.watch(buyerOrdersProvider).whenData((orders) {
        return orders
            .where(
              (o) =>
                  o.shippingApprovalStatus ==
                  models.ShippingApprovalStatus.pending,
            )
            .toList();
      });
    });

// ============================================================================
// SELLER ORDERS PROVIDER
// ============================================================================

final sellerOrdersProvider = StreamProvider.autoDispose<List<models.Order>>((
  ref,
) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);

  return ref.watch(orderRepositoryProvider).watchSellerOrders(userId);
});

// ============================================================================
// RETURN REQUEST PROVIDERS
// ============================================================================

/// Fetches return requests for a specific order.
final returnRequestsProvider = FutureProvider.autoDispose
    .family<List<models.ReturnRequest>, String>((ref, orderId) async {
      return ref.watch(orderRepositoryProvider).fetchReturnRequests(orderId);
    });

/// Documentation for OrderError
class OrderError extends OrderResult {
  final String message;
  final String? code;
  OrderError({required this.message, this.code});
}

// ============================================================================
// ORDER RESULT TYPES
// ============================================================================

sealed class OrderResult {}

/// Documentation for OrderSuccess
class OrderSuccess extends OrderResult {
  final String message;
  OrderSuccess({required this.message});
}

// ============================================================================
// SELLER EARNINGS SUMMARY (computed — no business logic in screens)
// ============================================================================

/// Immutable summary of seller earnings derived from orders.
@immutable
class SellerEarningsSummary {
  final double totalRevenue;
  final int pendingCount;
  final int completedCount;

  const SellerEarningsSummary({
    this.totalRevenue = 0.0,
    this.pendingCount = 0,
    this.completedCount = 0,
  });
}

/// Computes seller earnings summary from their orders.
/// Moves revenue/fee/count business logic out of the screen build() method.
final sellerEarningsSummaryProvider =
    Provider.autoDispose<SellerEarningsSummary>((ref) {
      final ordersAsync = ref.watch(sellerOrdersProvider);
      final userId = ref.watch(userIdProvider);
      if (userId == null) return const SellerEarningsSummary();

      return ordersAsync.maybeWhen(
        data: (orders) {
          var totalRevenue = 0.0;
          var pendingCount = 0;
          var completedCount = 0;

          const excludedStatuses = {
            models.OrderStatus.cancelled,
            models.OrderStatus.failed,
            models.OrderStatus.expired,
            models.OrderStatus.refunded,
            models.OrderStatus.partiallyRefunded,
            models.OrderStatus.disputed,
          };

          for (final order in orders) {
            final sellerItems = order.items.where((i) => i.sellerId == userId);
            final subtotal = sellerItems.fold<double>(
              0.0,
              (acc, i) => acc + i.price * i.quantity,
            );
            final orderSubtotal = order.subtotal > 0
                ? order.subtotal
                : subtotal;
            final feeShare = orderSubtotal > 0
                ? (order.platformFeeTotal / orderSubtotal) * subtotal
                : 0.0;
            totalRevenue += subtotal - feeShare;

            if (order.orderStatus == models.OrderStatus.delivered) {
              completedCount++;
            } else if (!excludedStatuses.contains(order.orderStatus)) {
              pendingCount++;
            }
          }

          return SellerEarningsSummary(
            totalRevenue: totalRevenue,
            pendingCount: pendingCount,
            completedCount: completedCount,
          );
        },
        orElse: () => const SellerEarningsSummary(),
      );
    });
