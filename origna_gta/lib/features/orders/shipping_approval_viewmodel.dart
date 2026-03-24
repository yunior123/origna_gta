import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'shipping_approval_viewmodel.freezed.dart';

/// Immutable state for the shipping cost approval action.
///
/// Tracks the async state of approve/reject operations:
/// - [isLoading]: true while API call is in flight
/// - [isSuccess]: true after successful approval/rejection
/// - [errorMessage]: localized error message on failure
/// - [wasApproved]: whether the last action was approve (true) or reject (false)
///
/// See also:
/// - [ShippingApprovalViewModel] for state mutations
@freezed
abstract class ShippingApprovalState with _$ShippingApprovalState {
  const factory ShippingApprovalState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,

    /// Whether the last approval was an "approve" (true) or "reject" (false).
    /// Only meaningful when [isSuccess] is true.
    @Default(true) bool wasApproved,
  }) = _ShippingApprovalState;
}

final shippingApprovalViewModelProvider =
    StateNotifierProvider.autoDispose<
      ShippingApprovalViewModel,
      ShippingApprovalState
    >((ref) {
      return ShippingApprovalViewModel(ref);
    });

/// Manages buyer approval of actual shipping costs for orders with
/// estimated shipping.
///
/// ## Flow
/// 1. Seller ships and updates actual shipping cost
/// 2. Buyer receives notification with the real cost
/// 3. Buyer approves (accepts cost) or rejects (disputes)
///
/// ## Key Decisions
/// - Guarded against double-tap: returns `false` if already loading.
/// - [clearStatus] should be called after showing success/error feedback
///   to prevent stale snackbars on rebuild.
///
/// See also:
/// - [ShippingApprovalState] for the state shape
/// - [OrderRepository.approveShippingCost] for the API call
class ShippingApprovalViewModel extends StateNotifier<ShippingApprovalState> {
  final Ref _ref;

  ShippingApprovalViewModel(this._ref) : super(const ShippingApprovalState());

  /// Approves or rejects the actual shipping cost for an order.
  ///
  /// [orderId] — the order document ID.
  /// [approved] — true to accept the cost, false to reject/dispute.
  ///
  /// Returns `true` on success, `false` on failure or if already loading.
  Future<bool> approveShippingCost(String orderId, bool approved) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );
    try {
      await _ref
          .read(orderRepositoryProvider)
          .approveShippingCost(orderId, approved);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        wasApproved: approved,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(
          e,
          'Failed to process shipping approval',
        ),
      );
      return false;
    }
  }

  /// Clear transient status flags after the screen has shown feedback.
  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }
}
