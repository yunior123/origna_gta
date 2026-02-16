import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';
import 'seller_orders_state.dart';

final sellerOrdersViewModelProvider = StateNotifierProvider.autoDispose<SellerOrdersViewModel, SellerOrdersState>((ref) {
  return SellerOrdersViewModel(ref);
});

class SellerOrdersViewModel extends StateNotifier<SellerOrdersState> {
  final Ref _ref;

  SellerOrdersViewModel(this._ref) : super(SellerOrdersState());

  Future<void> updateShippingAndCapture(String orderId, double actualShipping, String trackingNumber) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    
    final repository = _ref.read(orderRepositoryProvider);
    
    try {
      // Step 1: Update shipping cost
      await repository.updateShippingCost(orderId, actualShipping, 'Actual carrier cost');
      
      // Step 2: Capture payment — if this fails, shipping is updated but payment not captured.
      // The seller can retry capture separately. Cron job auto_capture_confirmed_receipts
      // will also catch it if receipt is confirmed.
      try {
        await repository.capturePayment(orderId);
      } catch (captureError) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: AppError.getMessage(captureError, 'seller.shipping_capture_failed'.tr()),
        );
        return;
      }

      // Step 3: Store tracking number if provided
      if (trackingNumber.isNotEmpty) {
        try {
          // Update the first item with tracking info (seller ships entire order)
          await repository.updateItemStatus(
            orderId,
            OrderItemIdValues.all,
            OrderStatusValues.shipped,
            trackingNumber: trackingNumber,
          );
        } catch (_) {
          // Non-critical: shipping + capture succeeded, tracking is best-effort
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to update shipping cost'));
    }
  }

  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    
    final repository = _ref.read(orderRepositoryProvider);
    
    try {
      await repository.updateItemStatus(
        orderId,
        itemId,
        status,
        trackingNumber: trackingNumber,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to update item status'));
    }
  }
}
