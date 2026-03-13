import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';

/// Documentation for SellerMetrics
class SellerMetrics {
  final double? avgResponseHours;
  final double? avgShipDays;
  final double? positiveRatePct;
  final int? totalReviews;

  const SellerMetrics({
    this.avgResponseHours,
    this.avgShipDays,
    this.positiveRatePct,
    this.totalReviews,
  });
}

/// Documentation for ProductDetailState
class ProductDetailState {
  final int quantity;
  final int currentImageIndex;
  final Map<String, String> selectedOptions;
  final String? selectedVariantId;
  final SellerMetrics? sellerMetrics;
  final bool sellerMetricsLoading;

  const ProductDetailState({
    this.quantity = 1,
    this.currentImageIndex = 0,
    this.selectedOptions = const {},
    this.selectedVariantId,
    this.sellerMetrics,
    this.sellerMetricsLoading = false,
  });

  ProductDetailState copyWith({
    int? quantity,
    int? currentImageIndex,
    Map<String, String>? selectedOptions,
    String? selectedVariantId,
    SellerMetrics? sellerMetrics,
    bool? sellerMetricsLoading,
    bool clearSellerMetrics = false,
  }) {
    return ProductDetailState(
      quantity: quantity ?? this.quantity,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      sellerMetrics: clearSellerMetrics
          ? null
          : sellerMetrics ?? this.sellerMetrics,
      sellerMetricsLoading: sellerMetricsLoading ?? this.sellerMetricsLoading,
    );
  }
}

final productDetailViewModelProvider =
    StateNotifierProvider.autoDispose<
      ProductDetailViewModel,
      ProductDetailState
    >((ref) {
      return ProductDetailViewModel(ref);
    });

final sellerMetricsProvider = StreamProvider.autoDispose
    .family<SellerMetrics, String>((ref, sellerId) {
      if (sellerId.isEmpty) return Stream.value(const SellerMetrics());

      try {
        EnvConfig().orignabaseUrl;
      } catch (_) {
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

/// Documentation for ProductDetailViewModel
class ProductDetailViewModel extends StateNotifier<ProductDetailState> {
  final Ref _ref;

  ProductDetailViewModel(this._ref) : super(ProductDetailState());

  void setQuantity(int quantity) {
    if (quantity < 1) return;
    state = state.copyWith(quantity: quantity);
  }

  /// Increments the selected quantity by 1 (no upper-bound guard; caller enforces stock limit).
  void incrementQuantity() =>
      state = state.copyWith(quantity: state.quantity + 1);

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
  void setSelectedVariantId(String? variantId) =>
      state = state.copyWith(selectedVariantId: variantId);

  /// Fetches seller metrics from database and stores in state.
  void fetchSellerMetrics(String sellerId) {
    final trimmedSellerId = sellerId.trim();
    if (trimmedSellerId.isEmpty) {
      state = state.copyWith(
        sellerMetricsLoading: false,
        clearSellerMetrics: true,
      );
      return;
    }
    final metricsAsync = _ref.read(sellerMetricsProvider(trimmedSellerId));
    state = state.copyWith(
      sellerMetrics: metricsAsync.valueOrNull,
      sellerMetricsLoading: metricsAsync.isLoading,
      clearSellerMetrics: !metricsAsync.hasValue,
    );
  }

  /// Submits a helpful/not-helpful vote for a product review.
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
        '/api/products/review-vote',
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
