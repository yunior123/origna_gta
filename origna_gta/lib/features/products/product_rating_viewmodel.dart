import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

class ProductRatingState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? reviewText;

  ProductRatingState({this.isLoading = false, this.isSuccess = false, this.errorMessage, this.reviewText});

  ProductRatingState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage, String? reviewText}) {
    return ProductRatingState(isLoading: isLoading ?? this.isLoading, isSuccess: isSuccess ?? this.isSuccess, errorMessage: errorMessage, reviewText: reviewText ?? this.reviewText);
  }
}

final productRatingViewModelProvider = StateNotifierProvider.autoDispose<ProductRatingViewModel, ProductRatingState>((ref) {
  return ProductRatingViewModel(ref);
});

class ProductRatingViewModel extends StateNotifier<ProductRatingState> {
  final Ref _ref;
  KeepAliveLink? _keepAliveLink;

  ProductRatingViewModel(this._ref) : super(ProductRatingState());

  void setReviewText(String? text) => state = state.copyWith(reviewText: text);

  Future<bool> submitRating(String orderId, String productId, int rating, {List<Uint8List>? reviewImages, String? reviewText}) async {
    if (state.isLoading) return false;
    if (rating < 1 || rating > 5) {
      state = state.copyWith(errorMessage: 'rating.invalid_range'.tr());
      return false;
    }
    // Prevent double-submit if widget is rebuilt during submission (autoDispose)
    _keepAliveLink = _ref.keepAlive();
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    List<String>? reviewImageUrls;
    try {
      if (reviewImages != null && reviewImages.isNotEmpty) {
        final userId = _ref.read(userIdProvider) ?? 'unknown';
        reviewImageUrls = await _ref.read(productRepositoryProvider).uploadReviewImages(reviewImages, userId);
      }
      await _ref.read(productRepositoryProvider).submitRating(orderId, productId, rating, reviewImageUrls: reviewImageUrls, reviewText: reviewText ?? state.reviewText);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      // If rating submission failed after images were uploaded, log orphaned URLs for cleanup.
      if (reviewImageUrls != null && reviewImageUrls.isNotEmpty) {
        AppError.log(Exception('Orphaned review images after rating failure: $reviewImageUrls'), stackTrace: st, context: 'product_rating_orphaned_images');
      }
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to submit rating'));
      return false;
    } finally {
      _keepAliveLink?.close();
      _keepAliveLink = null;
    }
  }
}
