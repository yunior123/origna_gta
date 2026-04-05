import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';

import 'product_detail_state.dart';

export 'product_detail_state.dart';

/// Riverpod provider for [ProductDetailViewModel].
///
/// Auto-disposed when the product detail screen is popped — fresh state
/// on every navigation prevents stale quantity/image selections.
final productDetailViewModelProvider =
    StateNotifierProvider.autoDispose<
      ProductDetailViewModel,
      ProductDetailState
    >((ref) {
      return ProductDetailViewModel(ref);
    });

/// Real-time stream of seller performance metrics (response time, ship speed, rating).
///
/// Returns a default [SellerMetrics] when [sellerId] is empty or config is unavailable.
/// Stream errors are logged via [AppError.log] but do NOT propagate — the UI degrades
/// gracefully by hiding the metrics card.
///
/// ## Key Decisions
/// - Graceful degradation: returns default metrics instead of throwing, so the product
///   detail screen never blocks on missing seller data.
/// - Family provider keyed by sellerId — each seller's metrics cached independently.
final sellerMetricsProvider = StreamProvider.autoDispose
    .family<SellerMetrics, String>((ref, sellerId) {
      if (sellerId.isEmpty) return Stream.value(const SellerMetrics());

      try {
        EnvConfig().orignabaseUrl;
      } catch (e) {
        AppLogger.w(
          'sellerMetricsProvider: EnvConfig.orignabaseUrl unavailable',
          tag: 'product',
          error: e,
        );
        return Stream.value(const SellerMetrics());
      }

      final stream = ref
          .read(orignabaseProvider)
          .collection(Collections.sellerMetrics)
          .doc(sellerId)
          .snapshots()
          .map((change) {
            final data = change.document.data;
            return SellerMetrics(
              avgResponseHours: (data[Fields.avgResponseTimeHours] as num?)
                  ?.toDouble(),
              avgShipDays: (data[Fields.avgShipDays] as num?)?.toDouble(),
              positiveRatePct: (data[Fields.positiveRatePct] as num?)
                  ?.toDouble(),
              totalReviews: (data[Fields.totalReviews] as num?)?.toInt(),
            );
          });

      return stream.handleError((Object e, StackTrace st) {
        AppError.log(e, stackTrace: st, context: 'sellerMetricsProvider');
      });
    });

/// Manages product detail screen state: quantity selection, image gallery index,
/// variant option selections, and seller metrics.
///
/// ## State Flow
/// ```
/// Initial (quantity=1, imageIndex=0) → User selections (quantity, options, variant)
/// ```
///
/// ## Key Decisions
/// - Quantity has no upper-bound guard in [incrementQuantity] — the caller (UI)
///   must enforce the stock limit. This keeps the ViewModel stock-agnostic.
/// - [voteHelpful] moved from UI layer to ViewModel for MVVM compliance.
/// - Seller metrics are fetched lazily via [sellerMetricsProvider] — not blocking
///   initial render. The UI shows a skeleton until data arrives.
///
/// See also:
/// - [ProductDetailState] for the state shape
/// - [sellerMetricsProvider] for real-time seller data
class ProductDetailViewModel extends StateNotifier<ProductDetailState> {
  final Ref _ref;

  ProductDetailViewModel(this._ref) : super(const ProductDetailState());

  /// Sets the selected quantity to [quantity].
  ///
  /// No-ops if [quantity] < 1 — negative/zero quantities are invalid.
  /// Does NOT clamp to stock — stock enforcement happens at checkout.
  void setQuantity(int quantity) {
    if (quantity < 1) return;
    state = state.copyWith(quantity: quantity);
  }

  /// Increments the selected quantity by 1 (no upper-bound guard; caller enforces stock limit).
  void incrementQuantity() =>
      state = state.copyWith(quantity: state.quantity + 1);

  /// Decrements the selected quantity by 1.
  ///
  /// No-ops if quantity is already 1 — minimum order quantity is 1.
  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  /// Updates the active carousel image index for the product detail gallery.
  void setImageIndex(int index) =>
      state = state.copyWith(currentImageIndex: index);

  /// Sets a selected option (e.g. Size=M) and optionally updates the variant ID.
  void setSelectedOption(String optionName, String value, {String? variantId}) {
    final updatedOptions = Map<String, String>.from(state.selectedOptions);
    updatedOptions[optionName] = value;
    state = state.copyWith(
      selectedOptions: updatedOptions,
      selectedVariantId: variantId,
    );
  }

  /// Manually sets the selected variant ID.
  ///
  /// Used when variant selection is driven by external logic (e.g., URL deep link
  /// with variant param) rather than user tapping options.
  void setSelectedVariantId(String? variantId) =>
      state = state.copyWith(selectedVariantId: variantId);

  /// Fetches seller metrics from database and stores in state.
  ///
  /// Reads the current value from [sellerMetricsProvider] (not a stream) — this is
  /// a point-in-time snapshot. The UI can re-watch [sellerMetricsProvider] directly
  /// for real-time updates.
  ///
  /// Sets [sellerMetricsLoading] to false and clears metrics when [sellerId] is empty.
  void fetchSellerMetrics(String sellerId) {
    final trimmedSellerId = sellerId.trim();
    if (trimmedSellerId.isEmpty) {
      state = state.copyWith(sellerMetricsLoading: false, sellerMetrics: null);
      return;
    }
    final metricsAsync = _ref.read(sellerMetricsProvider(trimmedSellerId));
    state = state.copyWith(
      sellerMetrics: metricsAsync.valueOrNull,
      sellerMetricsLoading: metricsAsync.isLoading,
    );
  }

  /// Submits a helpful/not-helpful vote for a product review.
  ///
  /// [ratingId] — the review document ID to vote on.
  /// [productId] — the product the review belongs to (unused in body but kept for API compat).
  /// [helpful] — true for "helpful", false for "unhelpful".
  ///
  /// Throws [StateError] if no user is logged in — the caller must gate this behind auth.
  /// Rethrows on network errors so the UI can show a snackbar.
  ///
  /// MVVM FIX (AUDIT): Moved from UI layer to ViewModel.
  Future<void> voteHelpful(
    String ratingId,
    String productId,
    bool helpful,
  ) async {
    try {
      final ob = _ref.read(orignabaseProvider);
      final userId = _ref.read(obUserIdProvider);
      if (userId == null || userId.isEmpty) {
        throw StateError('User must be logged in to vote on reviews');
      }
      await ob.request(
        'POST',
        ApiEndpoints.productsReviewVote,
        body: {
          Fields.reviewId: ratingId,
          'vote': helpful ? 'helpful' : 'unhelpful',
        },
      );
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'voteHelpful');
      rethrow;
    }
  }
}
