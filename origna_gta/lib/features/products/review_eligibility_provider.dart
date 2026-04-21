import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/core/providers.dart';

/// Review eligibility result for a product.
class ReviewEligibility {
  /// The order ID eligible for rating (first delivered order containing the product).
  final String? eligibleOrderId;

  /// Whether the user has already submitted a review for this product.
  final bool alreadyReviewed;

  const ReviewEligibility({this.eligibleOrderId, this.alreadyReviewed = false});

  /// User can write a review: has a delivered order and hasn't reviewed yet.
  bool get canReview => eligibleOrderId != null && !alreadyReviewed;
}

/// Checks whether the current user can write a review for [productId].
///
/// Returns [ReviewEligibility] with eligible order info.
/// - User must be logged in
/// - Must have at least one order with status "delivered" or "confirmed" containing this product
/// - Must not have already rated this product in that order
final reviewEligibilityProvider = Provider.autoDispose
    .family<AsyncValue<ReviewEligibility>, String>((ref, productId) {
      final userId = ref.watch(userIdProvider);
      if (userId == null) {
        return const AsyncValue.data(ReviewEligibility());
      }

      final ordersAsync = ref.watch(buyerOrdersProvider);

      return ordersAsync.whenData((orders) {
        // Find orders containing this product that are delivered or confirmed
        for (final order in orders) {
          final hasProduct = order.items.any(
            (item) => item.productId == productId,
          );
          if (!hasProduct) continue;

          final isEligibleStatus =
              order.orderStatus.name == OrderStatusValues.delivered ||
              order.orderStatus.name == OrderStatusValues.confirmed ||
              order.orderStatus.name == OrderStatusValues.shipped;

          if (!isEligibleStatus) continue;

          // Check if already rated in this order's ratings list
          final alreadyRated = order.ratings.any(
            (r) => r.productId == productId,
          );

          if (alreadyRated) {
            return const ReviewEligibility(alreadyReviewed: true);
          }

          return ReviewEligibility(eligibleOrderId: order.orderId);
        }

        return const ReviewEligibility();
      });
    });
