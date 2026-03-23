import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'seller_orders_state.dart';

final sellerOrdersViewModelProvider =
    StateNotifierProvider.autoDispose<SellerOrdersViewModel, SellerOrdersState>(
      (ref) {
        return SellerOrdersViewModel(ref);
      },
    );

/// Manages seller-side order fulfillment: updating shipping costs, adding
/// tracking numbers, and marking items as shipped/delivered.
///
/// ## State Flow
/// ```
/// Idle → Loading (API call in flight) → Success / Error
/// ```
///
/// ## Key Decisions
/// - All mutating methods guard against double-requests with `state.isLoading`.
/// - [updateShippingAndCapture] is a two-step operation: first updates the
///   shipping cost, then stores tracking info. The tracking write failure is
///   non-critical — logged but not propagated.
/// - When adding tracking, ALL items are updated to `shipped` status — the
///   seller ships the entire order as one shipment.
///
/// See also:
/// - [SellerOrdersState] for the state shape
/// - [OrderRepository] for persistence layer
class SellerOrdersViewModel extends StateNotifier<SellerOrdersState> {
  final Ref _ref;

  SellerOrdersViewModel(this._ref) : super(const SellerOrdersState());

  /// Updates the actual shipping cost and optionally stores tracking information.
  ///
  /// [orderId] — the order document ID.
  /// [actualShippingCents] — the real shipping cost in integer cents.
  /// [trackingNumber] — carrier tracking number (empty string skips tracking update).
  /// [carrier] — optional carrier name (e.g., "UPS", "FedEx").
  /// [carrierNote] — free-text override when carrier is "other".
  ///
  /// Two-step operation:
  /// 1. Updates shipping cost via [OrderRepository.updateShippingCost]
  /// 2. If tracking number provided, marks all items as `shipped` with tracking info
  ///
  /// The tracking write is non-critical — failures are logged but not shown to the user.
  Future<void> updateShippingAndCapture(
    String orderId,
    int actualShippingCents,
    String trackingNumber, {
    String? carrier,
    String? carrierNote,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    final repository = _ref.read(orderRepositoryProvider);

    try {
      // Step 1: Update shipping cost
      await repository.updateShippingCost(
        orderId,
        actualShippingCents,
        'Actual carrier cost',
      );

      // Step 2: Store tracking number if provided
      if (trackingNumber.isNotEmpty) {
        try {
          // Update ALL items with tracking info — seller ships the entire order as one shipment
          await repository.updateItemStatus(
            orderId,
            OrderItemIdValues.all,
            DeliveryStatusValues.shipped,
            trackingNumber: trackingNumber,
            carrier: carrier,
            carrierNote: carrierNote,
          );
        } catch (e) {
          // Non-critical tracking write failed — log for visibility
          AppError.log(e, context: 'sellerOrders.trackingUpdate');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to update shipping cost'),
      );
    }
  }

  /// Updates the delivery status of a specific order item.
  ///
  /// [orderId] — the order document ID.
  /// [itemId] — the item identifier (use [OrderItemIdValues.all] for all items).
  /// [status] — new delivery status (e.g., [DeliveryStatusValues.shipped]).
  /// [trackingNumber], [carrier], [carrierNote] — optional shipping metadata.
  Future<void> updateItemStatus(
    String orderId,
    String itemId,
    String status, {
    String? trackingNumber,
    String? carrier,
    String? carrierNote,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    final repository = _ref.read(orderRepositoryProvider);

    try {
      await repository.updateItemStatus(
        orderId,
        itemId,
        status,
        trackingNumber: trackingNumber,
        carrier: carrier,
        carrierNote: carrierNote,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to update item status'),
      );
    }
  }
}
