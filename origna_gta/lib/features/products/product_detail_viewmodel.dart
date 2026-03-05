import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart';

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

class ProductDetailState {
  final int quantity;
  final int currentImageIndex;
  final SellerMetrics? sellerMetrics;
  final bool sellerMetricsLoading;

  ProductDetailState({
    this.quantity = 1,
    this.currentImageIndex = 0,
    this.sellerMetrics,
    this.sellerMetricsLoading = false,
  });

  ProductDetailState copyWith({
    int? quantity,
    int? currentImageIndex,
    SellerMetrics? sellerMetrics,
    bool? sellerMetricsLoading,
  }) {
    return ProductDetailState(
      quantity: quantity ?? this.quantity,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      sellerMetrics: sellerMetrics ?? this.sellerMetrics,
      sellerMetricsLoading: sellerMetricsLoading ?? this.sellerMetricsLoading,
    );
  }
}

final productDetailViewModelProvider =
    StateNotifierProvider.autoDispose<ProductDetailViewModel, ProductDetailState>((ref) {
  return ProductDetailViewModel(ref);
});

class ProductDetailViewModel extends StateNotifier<ProductDetailState> {
  final Ref _ref;

  ProductDetailViewModel(this._ref) : super(ProductDetailState());

  void setQuantity(int quantity) {
    if (quantity < 1) return;
    state = state.copyWith(quantity: quantity);
  }

  /// Increments the selected quantity by 1 (no upper-bound guard; caller enforces stock limit).
  void incrementQuantity() => state = state.copyWith(quantity: state.quantity + 1);

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  /// Updates the active carousel image index for the product detail gallery.
  void setImageIndex(int index) => state = state.copyWith(currentImageIndex: index);

  /// Fetches seller metrics from Firestore and stores in state.
  /// Submits a helpful/not-helpful vote for a product review.
  /// MVVM FIX (AUDIT): Moved from UI layer to ViewModel.
  Future<void> voteHelpful(String ratingId, String productId, bool helpful) async {
    try {
      final functions = _ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable(CloudFunctionEndpoints.voteReviewHelpful).call({
        Fields.ratingId: ratingId,
        Fields.productId: productId,
        'helpful': helpful,
      });
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'voteHelpful');
      rethrow;
    }
  }

  /// Silently no-ops if [sellerId] is empty or data is missing.
  Future<void> fetchSellerMetrics(String sellerId) async {
    if (sellerId.isEmpty) return;
    state = state.copyWith(sellerMetricsLoading: true);
    try {
      final doc = await _ref
          .read(firestoreProvider)
          .collection(Collections.sellerMetrics)
          .doc(sellerId)
          .get();
      if (!doc.exists) {
        state = state.copyWith(sellerMetricsLoading: false, sellerMetrics: const SellerMetrics());
        return;
      }
      final data = doc.data()!;
      state = state.copyWith(
        sellerMetricsLoading: false,
        sellerMetrics: SellerMetrics(
          avgResponseHours: (data[Fields.avgResponseTimeHours] as num?)?.toDouble(),
          avgShipDays: (data[Fields.avgShipDays] as num?)?.toDouble(),
          positiveRatePct: (data[Fields.positiveRatePct] as num?)?.toDouble(),
          totalReviews: (data[Fields.totalReviews] as num?)?.toInt(),
        ),
      );
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'fetchSellerMetrics');
      state = state.copyWith(sellerMetricsLoading: false, sellerMetrics: const SellerMetrics());
    }
  }
}
