import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductDetailState {
  final int quantity;
  final int currentImageIndex;

  ProductDetailState({
    this.quantity = 1,
    this.currentImageIndex = 0,
  });

  ProductDetailState copyWith({
    int? quantity,
    int? currentImageIndex,
  }) {
    return ProductDetailState(
      quantity: quantity ?? this.quantity,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
    );
  }
}

final productDetailViewModelProvider =
    StateNotifierProvider.autoDispose<ProductDetailViewModel, ProductDetailState>((ref) {
  return ProductDetailViewModel();
});

class ProductDetailViewModel extends StateNotifier<ProductDetailState> {
  ProductDetailViewModel() : super(ProductDetailState());

  void setQuantity(int quantity) {
    if (quantity < 1) return;
    state = state.copyWith(quantity: quantity);
  }

  void incrementQuantity() => state = state.copyWith(quantity: state.quantity + 1);
  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void setImageIndex(int index) => state = state.copyWith(currentImageIndex: index);
}
