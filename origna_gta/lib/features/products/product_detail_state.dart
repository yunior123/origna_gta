import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_state.freezed.dart';

/// Immutable state for the product detail screen.
///
/// Tracks user selections that drive the "Add to Cart" flow:
/// - [quantity]: how many units to add (clamped to [1, ∞) by ViewModel)
/// - [currentImageIndex]: active carousel image for gallery navigation
/// - [selectedOptions]: chosen variant dimensions (e.g., {"Size": "M", "Color": "Red"})
/// - [selectedVariantId]: resolved variant document ID when all options are selected
/// - [sellerMetrics]/[sellerMetricsLoading]: lazy-loaded seller performance data
///
/// See also:
/// - [ProductDetailViewModel] for state mutations
/// - [SellerMetrics] for the metrics shape
@freezed
abstract class ProductDetailState with _$ProductDetailState {
  const factory ProductDetailState({
    @Default(1) int quantity,
    @Default(0) int currentImageIndex,
    @Default({}) Map<String, String> selectedOptions,
    String? selectedVariantId,
    SellerMetrics? sellerMetrics,
    @Default(false) bool sellerMetricsLoading,
  }) = _ProductDetailState;
}

/// Seller performance metrics displayed on the product detail screen.
///
/// All fields are nullable — when metrics are unavailable (seller is new,
/// document doesn't exist, or stream errored), the UI hides the metrics card
/// rather than showing N/A values.
///
/// ## Fields
/// - [avgResponseHours]: mean time to respond to buyer messages
/// - [avgShipDays]: mean days from order confirmation to shipment
/// - [positiveRatePct]: percentage of positive reviews (0–100)
/// - [totalReviews]: total number of reviews received
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
