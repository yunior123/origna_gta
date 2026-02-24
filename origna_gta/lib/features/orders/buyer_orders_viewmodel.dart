import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

class BuyerOrdersState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  /// The unique key (orderId_productId) of the item whose receipt is currently being confirmed.
  final String? confirmingItemId;

  BuyerOrdersState({this.isLoading = false, this.isSuccess = false, this.errorMessage, this.confirmingItemId});

  BuyerOrdersState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage, String? confirmingItemId}) {
    return BuyerOrdersState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      confirmingItemId: confirmingItemId,
    );
  }
}

final buyerOrdersViewModelProvider = StateNotifierProvider.autoDispose<BuyerOrdersViewModel, BuyerOrdersState>((ref) {
  return BuyerOrdersViewModel(ref);
});

class BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState> {
  final Ref _ref;

  BuyerOrdersViewModel(this._ref) : super(BuyerOrdersState());

  Future<bool> confirmReceipt(String orderId, String itemKey) async {
    if (state.confirmingItemId != null) return false;
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null, confirmingItemId: itemKey);
    try {
      await _ref.read(orderRepositoryProvider).confirmReceipt(orderId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to confirm order receipt'));
      return false;
    }
  }
}
