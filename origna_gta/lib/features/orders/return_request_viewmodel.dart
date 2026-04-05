import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/utils.dart';

part 'return_request_viewmodel.freezed.dart';

/// State for the return request viewmodel.
@freezed
abstract class ReturnRequestState with _$ReturnRequestState {
  const factory ReturnRequestState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _ReturnRequestState;
}

final returnRequestViewModelProvider =
    StateNotifierProvider.autoDispose<
      ReturnRequestViewModel,
      ReturnRequestState
    >((ref) {
      return ReturnRequestViewModel(ref);
    });

/// ViewModel for submitting return requests.
/// Keeps repository calls and state management out of the screen.
class ReturnRequestViewModel extends StateNotifier<ReturnRequestState> {
  final Ref _ref;

  ReturnRequestViewModel(this._ref) : super(const ReturnRequestState());

  /// Preview constructor — skips all backend calls.
  ReturnRequestViewModel.preview(this._ref)
    : super(const ReturnRequestState());

  /// Submit a return request for the given order and items.
  ///
  /// Returns `true` on success, `false` on failure.
  /// On success, invalidates the order and return requests caches.
  /// Enforces the return window client-side as defense-in-depth
  /// (server also validates).
  Future<bool> submitReturn({
    required String orderId,
    required List<String> cartItemIds,
    required String reason,
    String? description,
  }) async {
    if (state.isLoading) return false;

    // Client-side return window enforcement (defense-in-depth)
    try {
      final order = await _ref
          .read(orderRepositoryProvider)
          .fetchOrderById(orderId);
      if (order != null) {
        final now = DateTime.now();
        bool hasEligibleItem = false;
        for (final item in order.items) {
          if (item.deliveredAt != null) {
            final deadline = item.deliveredAt!.add(
              const Duration(days: BusinessRules.returnWindowDays),
            );
            if (now.isBefore(deadline)) {
              hasEligibleItem = true;
              break;
            }
          }
        }
        if (!hasEligibleItem) {
          state = state.copyWith(
            errorMessage:
                'The ${BusinessRules.returnWindowDays}-day return window has expired',
          );
          return false;
        }
      }
    } catch (e) {
      AppLogger.w(
        'ReturnRequestViewModel: return window check failed (server will enforce)',
        tag: 'orders',
        error: e,
      );
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );

    try {
      await _ref
          .read(orderRepositoryProvider)
          .createReturnRequest(
            orderId: orderId,
            cartItemIds: cartItemIds,
            reason: reason,
            description: description,
          );

      // Invalidate caches so the UI refreshes
      _ref.invalidate(orderByIdProvider(orderId));
      _ref.invalidate(returnRequestsProvider(orderId));

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to submit return request'),
      );
      return false;
    }
  }

  /// Clear transient status flags after the screen has shown feedback.
  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }
}
