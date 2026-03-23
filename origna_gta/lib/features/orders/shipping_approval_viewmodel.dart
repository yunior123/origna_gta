import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'shipping_approval_viewmodel.freezed.dart';

/// Documentation for ShippingApprovalState
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

/// Documentation for ShippingApprovalViewModel
class ShippingApprovalViewModel extends StateNotifier<ShippingApprovalState> {
  final Ref _ref;

  ShippingApprovalViewModel(this._ref) : super(const ShippingApprovalState());

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
