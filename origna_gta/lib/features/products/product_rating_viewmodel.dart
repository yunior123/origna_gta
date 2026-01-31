import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';

class ProductRatingState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ProductRatingState({this.isLoading = false, this.isSuccess = false, this.errorMessage});

  ProductRatingState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage}) {
    return ProductRatingState(isLoading: isLoading ?? this.isLoading, isSuccess: isSuccess ?? this.isSuccess, errorMessage: errorMessage);
  }
}

final productRatingViewModelProvider = StateNotifierProvider.autoDispose<ProductRatingViewModel, ProductRatingState>((ref) {
  return ProductRatingViewModel(ref);
});

class ProductRatingViewModel extends StateNotifier<ProductRatingState> {
  final Ref _ref;

  ProductRatingViewModel(this._ref) : super(ProductRatingState());

  Future<bool> submitRating(String orderId, String productId, int rating) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    try {
      await _ref.read(productRepositoryProvider).submitRating(orderId, productId, rating);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
