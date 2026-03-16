// coverage:ignore-file
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

import 'seller_products_viewmodel.dart' show SellerProductsState;

final obSellerProductsViewModelProvider = StateNotifierProvider
    .autoDispose<OrignaBaseSellerProductsViewModel, SellerProductsState>((ref) {
  return OrignaBaseSellerProductsViewModel(ref);
});

/// OrignaBase seller products viewmodel.
class OrignaBaseSellerProductsViewModel
    extends StateNotifier<SellerProductsState> {
  final Ref _ref;

  OrignaBaseSellerProductsViewModel(this._ref)
      : super(const SellerProductsState());

  OrignaBase get _ob => _ref.read(orignabaseProvider);

  /// Calls bulk update products via OrignaBase HTTP endpoint.
  /// [action] must be one of: "pause", "activate", "archive"
  Future<void> bulkAction(String action) async {
    if (state.selectedIds.isEmpty || state.isLoading) return;

    state = state.copyWith(
        isLoading: true, errorMessage: null, successMessage: null);

    try {
      final result =
          await _ob.request('POST', ApiEndpoints.productsBulkUpdate, body: {
        Fields.productIds: state.selectedIds.toList(),
        Fields.action: action,
      });

      final data = Map<String, dynamic>.from(result as Map);
      final updated = data['data']?['updated'] ?? data['updated'] ?? 0;
      final skipped = data['data']?['skipped'] ?? data['skipped'] ?? 0;

      state = state.copyWith(
        isLoading: false,
        selectedIds: {},
        successMessage:
            '$updated product${updated == 1 ? '' : 's'} ${action}d'
            '${skipped > 0 ? ' ($skipped skipped)' : ''}',
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: AppError.getMessage(
              e, 'seller.bulk_action_failed'.tr()));
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  void selectAll(List<String> productIds) {
    state = state.copyWith(selectedIds: productIds.toSet());
  }

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
