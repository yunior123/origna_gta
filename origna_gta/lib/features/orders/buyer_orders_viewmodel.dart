import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

class BuyerOrdersState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  BuyerOrdersState({this.isLoading = false, this.isSuccess = false, this.errorMessage});

  BuyerOrdersState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage}) {
    return BuyerOrdersState(isLoading: isLoading ?? this.isLoading, isSuccess: isSuccess ?? this.isSuccess, errorMessage: errorMessage);
  }
}

final buyerOrdersViewModelProvider = StateNotifierProvider.autoDispose<BuyerOrdersViewModel, BuyerOrdersState>((ref) {
  return BuyerOrdersViewModel(ref);
});

class BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState> {
  final Ref _ref;

  BuyerOrdersViewModel(this._ref) : super(BuyerOrdersState());

  Future<bool> confirmReceipt(String orderId, List<String> itemIds) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    try {
      await _ref.read(orderRepositoryProvider).confirmReceipt(orderId, itemIds);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
