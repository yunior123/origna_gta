import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

part 'product_rating_viewmodel.freezed.dart';

/// State for the rating submission flow: star count, review text, images.
@freezed
abstract class ProductRatingState with _$ProductRatingState {
  const factory ProductRatingState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorMessage,
    String? reviewText,
  }) = _ProductRatingState;
}

final productRatingViewModelProvider =
    StateNotifierProvider.autoDispose<
      ProductRatingViewModel,
      ProductRatingState
    >((ref) {
      return ProductRatingViewModel(ref);
    });

/// Manages product rating/review submission with optional image upload.
class ProductRatingViewModel extends StateNotifier<ProductRatingState> {
  final Ref _ref;
  KeepAliveLink? _keepAliveLink;

  ProductRatingViewModel(this._ref) : super(const ProductRatingState());

  /// Updates the draft review text shown in the rating form.
  void setReviewText(String? text) => state = state.copyWith(reviewText: text);

  /// Submits a product rating with an optional review text and images.
  ///
  /// Uses atomic backend submission (QA-H1) where images and document are created together.
  ///
  /// Throws nothing — all errors are captured into [ProductRatingState.errorMessage].
  Future<bool> submitRating(
    String orderId,
    String productId,
    int rating, {
    List<Uint8List>? reviewImages,
    String? reviewText,
  }) async {
    if (state.isLoading) return false;
    if (rating < 1 || rating > 5) {
      state = state.copyWith(errorMessage: 'rating.invalid_range'.tr());
      return false;
    }
    // Prevent double-submit if widget is rebuilt during submission (autoDispose)
    _keepAliveLink = _ref.keepAlive();
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      errorMessage: null,
    );
    try {
      await _ref
          .read(productRepositoryProvider)
          .submitRatingAtomic(
            orderId,
            productId,
            rating,
            reviewImages: reviewImages,
            reviewText: reviewText ?? state.reviewText,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'Failed to submit rating'),
      );
      return false;
    } finally {
      _keepAliveLink?.close();
      _keepAliveLink = null;
    }
  }
}
