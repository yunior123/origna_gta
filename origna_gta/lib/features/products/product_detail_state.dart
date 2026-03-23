import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_state.freezed.dart';

/// Documentation for ProductDetailState
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
