import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'seller_orders_state.dart';

final sellerOrdersViewModelProvider = StateNotifierProvider.autoDispose<SellerOrdersViewModel, SellerOrdersState>((ref) {
  return SellerOrdersViewModel(ref);
});

class SellerOrdersViewModel extends StateNotifier<SellerOrdersState> {
  final Ref _ref;

  SellerOrdersViewModel(this._ref) : super(SellerOrdersState());

  Future<void> updateShippingAndCapture(String orderId, double actualShipping, String trackingNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final repository = _ref.read(orderRepositoryProvider);
    
    try {
      await repository.updateShippingCost(orderId, actualShipping, 'Actual carrier cost');
      await repository.capturePayment(orderId);
      
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateItemStatus(String orderId, String itemId, String status, {String? trackingNumber}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
