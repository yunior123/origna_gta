import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'product_actions_viewmodel.freezed.dart';

/// State for product actions (delete, toggle status, archive).
@freezed
abstract class ProductActionsState with _$ProductActionsState {
  const factory ProductActionsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _ProductActionsState;
}

/// Riverpod provider for [ProductActionsViewModel].
///
/// Auto-disposed — fresh state per action invocation.
final productActionsViewModelProvider =
    StateNotifierProvider.autoDispose<
      ProductActionsViewModel,
      ProductActionsState
    >((ref) {
      return ProductActionsViewModel(ref);
    });

/// ViewModel for product lifecycle actions: activate, deactivate, delete.
///
/// All mutations set [ProductActionsState.isLoading] during the operation and
/// [isSuccess] on completion. Errors are captured into [errorMessage].
class ProductActionsViewModel extends StateNotifier<ProductActionsState> {
  final Ref _ref;

  ProductActionsViewModel(this._ref) : super(const ProductActionsState());

  /// Deletes a product by [productId].
  ///
  /// Returns `true` on success, `false` on failure or if already loading (double-submit guard).
  /// Rethrows nothing — errors are captured into [ProductActionsState.errorMessage].
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
