import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'buyer_orders_viewmodel.freezed.dart';

/// Documentation for BuyerOrdersState
@freezed
abstract class BuyerOrdersState with _$BuyerOrdersState {
  const factory BuyerOrdersState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,

    /// The unique key (orderId_productId) of the item whose receipt is currently being confirmed.
    String? confirmingItemId,
  }) = _BuyerOrdersState;
}

final buyerOrdersViewModelProvider =
    StateNotifierProvider.autoDispose<BuyerOrdersViewModel, BuyerOrdersState>((
      ref,
    ) {
      return BuyerOrdersViewModel(ref);
    });

/// Documentation for BuyerOrdersViewModel
class BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState> {
  final Ref _ref;

  BuyerOrdersViewModel(this._ref) : super(const BuyerOrdersState());

  Future<bool> confirmReceipt(String orderId, String itemKey) async {
    if (state.confirmingItemId != null) return false;
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
      confirmingItemId: itemKey,
    );
    try {
      // Extract productId from itemKey (format: "orderId_productId")
      final productId = itemKey.startsWith('${orderId}_')
          ? itemKey.substring(orderId.length + 1)
          : null;
      await _ref
          .read(orderRepositoryProvider)
          .confirmReceipt(orderId, productId: productId);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        confirmingItemId: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to confirm order receipt'),
        confirmingItemId: null,
      );
      return false;
    }
  }
}
