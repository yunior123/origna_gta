import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'seller_products_viewmodel.dart' show SellerProductsState;

final obSellerProductsViewModelProvider =
    StateNotifierProvider.autoDispose<
      OrignaBaseSellerProductsViewModel,
      SellerProductsState
    >((ref) {
      return OrignaBaseSellerProductsViewModel(ref);
    });

/// Manages seller product bulk operations: selection state and batch actions.
///
/// Provides multi-select UI pattern for the seller's product list:
/// - Toggle individual product selection
/// - Select all / clear selection
/// - Bulk actions: pause, activate, archive selected products
///
/// ## Key Decisions
/// - Bulk actions use a dedicated API endpoint ([ApiEndpoints.productsBulkUpdate])
///   instead of individual product updates — reduces database round-trips.
/// - Selection state is a `Set<String>` — O(1) lookup for toggle operations.
/// - [bulkAction] is guarded against double-requests via `state.isLoading`.
///
/// See also:
/// - [SellerProductsState] for the state shape
/// - [sellerProductsProvider] for the product list stream
class OrignaBaseSellerProductsViewModel
    extends StateNotifier<SellerProductsState> {
  final Ref _ref;

  OrignaBaseSellerProductsViewModel(this._ref)
    : super(const SellerProductsState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  /// Executes a bulk action on all selected products.
  ///
  /// [action] — one of: "pause", "activate", "archive".
  ///
  /// No-ops if [selectedIds] is empty or another bulk action is in flight.
  /// Clears selection on success and sets a human-readable [successMessage]
  /// with the count of updated/skipped products.
  Future<void> bulkAction(String action) async {
    if (state.selectedIds.isEmpty || state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final result = await _ob.request(
        'POST',
        ApiEndpoints.productsBulkUpdate,
        body: {
          Fields.productIds: state.selectedIds.toList(),
          Fields.action: action,
        },
      );

      final data = Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
      final int updated =
          (data['data']?['updated'] as int?) ?? (data['updated'] as int?) ?? 0;
      final int skipped =
          (data['data']?['skipped'] as int?) ?? (data['skipped'] as int?) ?? 0;

      final String message = skipped > 0
          ? 'seller.bulk_products_updated_skipped'.tr(
              args: [updated.toString(), action, skipped.toString()],
            )
          : 'seller.bulk_products_updated'.tr(
              args: [updated.toString(), action],
            );

      state = state.copyWith(
        isLoading: false,
        selectedIds: {},
        successMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'seller.bulk_action_failed'.tr()),
      );
    }
  }

  /// Clears all product selections.
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Selects all products in the provided list.
  ///
  /// [productIds] — the full list of product IDs to select.
  void selectAll(List<String> productIds) {
    state = state.copyWith(selectedIds: productIds.toSet());
  }

  /// Toggles selection state for a single product.
  ///
  /// [productId] — the product document ID to toggle.
  void toggleSelection(String productId) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(productId)) {
      ids.remove(productId);
    } else {
      ids.add(productId);
    }
    state = state.copyWith(selectedIds: ids);
  }
}
