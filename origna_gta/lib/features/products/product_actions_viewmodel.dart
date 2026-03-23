import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'product_actions_viewmodel.freezed.dart';

/// Documentation for ProductActionsState
@freezed
abstract class ProductActionsState with _$ProductActionsState {
  const factory ProductActionsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _ProductActionsState;
}

final productActionsViewModelProvider =
    StateNotifierProvider.autoDispose<
      ProductActionsViewModel,
      ProductActionsState
    >((ref) {
      return ProductActionsViewModel(ref);
    });

/// Documentation for ProductActionsViewModel
class ProductActionsViewModel extends StateNotifier<ProductActionsState> {
  final Ref _ref;

  ProductActionsViewModel(this._ref) : super(const ProductActionsState());

  Future<bool> deleteProduct(String productId) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );
    try {
      await _ref.read(productRepositoryProvider).deleteProduct(productId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to perform action'),
      );
      return false;
    }
  }
}
