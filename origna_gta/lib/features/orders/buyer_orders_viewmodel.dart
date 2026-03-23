import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'buyer_orders_viewmodel.freezed.dart';

/// Immutable state for buyer order actions.
///
/// Tracks the async state of the "Confirm Receipt" action per-item:
/// - [isLoading]: true while the confirm API call is in flight
/// - [isSuccess]: true after a successful confirmation
/// - [errorMessage]: localized error message on failure
/// - [confirmingItemId]: the `orderId_productId` key of the item being confirmed
///   — used to show a loading spinner on the specific order item card
///
/// See also:
/// - [BuyerOrdersViewModel] for state mutations
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

/// Manages buyer-side order actions: confirming receipt of delivered items.
///
/// ## Key Decisions
/// - [confirmReceipt] uses a guard (`state.confirmingItemId != null`) to prevent
///   double-tap — only one confirmation can be in flight at a time.
/// - The `itemKey` format is `orderId_productId` — this lets us track which
///   specific item within a multi-seller order is being confirmed.
///
/// See also:
/// - [BuyerOrdersState] for the state shape
/// - [OrderRepository.confirmReceipt] for the API call
class BuyerOrdersViewModel extends StateNotifier<BuyerOrdersState> {
  final Ref _ref;

  BuyerOrdersViewModel(this._ref) : super(const BuyerOrdersState());

  /// Confirms the buyer's receipt of a delivered order item.
  ///
  /// [orderId] — the order document ID.
  /// [itemKey] — composite key in format `orderId_productId`.
  ///
  /// Returns `true` on success, `false` on failure or if another confirmation
  /// is already in flight. Extracts `productId` from `itemKey` and delegates
  /// to [OrderRepository.confirmReceipt].
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
