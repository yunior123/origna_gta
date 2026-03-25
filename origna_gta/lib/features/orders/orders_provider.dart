import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart'
    show BusinessRules;
import 'package:origna_gta/models/generated/models.dart' as models;

// ============================================================================
// BUYER ORDERS PROVIDER
// ============================================================================

/// Real-time stream of orders placed by the current buyer.
///
/// Filters to active payment statuses only (excludes awaiting_payment).
/// Sorted by createdAt descending. Returns empty list when no user is signed in.
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

/// Fetches a single order by document ID. Returns null if not found.
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

/// Count of orders with pending shipping cost approval from the buyer.
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

/// Filtered list of buyer orders that require shipping cost approval.
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

/// Real-time stream of orders containing items sold by the current user.
///
/// Uses `sellerIds contains userId` filter. Sorted client-side by createdAt descending.
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

/// Order operation failed. [code] for programmatic handling (e.g., 'not-found').
class OrderError extends OrderResult {
  final String message;
  final String? code;
  OrderError({required this.message, this.code});
}

// ============================================================================
// ORDER RESULT TYPES
// ============================================================================

/// Result type for order mutation operations (cancel, refund, status update).
sealed class OrderResult {}

/// Order operation succeeded with a user-facing [message].
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
  final int totalRevenueCents;
  final int pendingCount;
  final int completedCount;

  const SellerEarningsSummary({
    this.totalRevenueCents = 0,
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
          var totalRevenueCents = 0;
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
            final subtotalCents = sellerItems.fold<int>(
              0,
              (acc, i) => acc + i.priceCents * i.quantity,
            );
            final orderSubtotalCents = order.subtotalCents > 0
                ? order.subtotalCents
                : subtotalCents;
            final feeShareCents = orderSubtotalCents > 0
                ? (order.platformFeeTotalCents * subtotalCents) ~/
                      orderSubtotalCents
                : 0;
            totalRevenueCents += subtotalCents - feeShareCents;

            if (order.orderStatus == models.OrderStatus.delivered) {
              completedCount++;
            } else if (!excludedStatuses.contains(order.orderStatus)) {
              pendingCount++;
            }
          }

          return SellerEarningsSummary(
            totalRevenueCents: totalRevenueCents,
            pendingCount: pendingCount,
            completedCount: completedCount,
          );
        },
        orElse: () => const SellerEarningsSummary(),
      );
    });

// ============================================================================
// SELLER ORDER NET AMOUNTS (per-card fee computation — not in build())
// ============================================================================

/// Pre-computed net amounts for a single seller order card.
/// Moves fee arithmetic out of _SellerOrderCard.build().
@immutable
class SellerOrderNetAmounts {
  final double sellerTotal;
  final double platformFee;
  final double sellerNet;

  const SellerOrderNetAmounts({
    required this.sellerTotal,
    required this.platformFee,
    required this.sellerNet,
  });
}

/// Computes gross, fee, and net for the seller's items in one order.
/// Family key: (orderId, sellerId)
final sellerOrderNetProvider = Provider.autoDispose
    .family<SellerOrderNetAmounts, ({String orderId, String sellerId})>((
      ref,
      params,
    ) {
      final ordersAsync = ref.watch(sellerOrdersProvider);
      return ordersAsync.maybeWhen(
        data: (orders) {
          final order = orders.cast<models.Order?>().firstWhere(
            (o) => o?.orderId == params.orderId,
            orElse: () => null,
          );
          if (order == null) {
            return const SellerOrderNetAmounts(
              sellerTotal: 0,
              platformFee: 0,
              sellerNet: 0,
            );
          }
          final sellerItems = order.items.where(
            (item) => item.sellerId == params.sellerId,
          );
          final sellerTotal = sellerItems.fold<double>(
            0.0,
            (acc, item) => acc + (item.price * item.quantity),
          );
          // Per-seller fee = seller's own subtotal × platform fee rate
          final platformFee =
              sellerTotal * (BusinessRules.platformFeePercent / 100.0);
          return SellerOrderNetAmounts(
            sellerTotal: sellerTotal,
            platformFee: platformFee,
            sellerNet: sellerTotal - platformFee,
          );
        },
        orElse: () => const SellerOrderNetAmounts(
          sellerTotal: 0,
          platformFee: 0,
          sellerNet: 0,
        ),
      );
    });
