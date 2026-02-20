import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

class ProductRatingState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ProductRatingState({this.isLoading = false, this.isSuccess = false, this.errorMessage});

  ProductRatingState copyWith({bool? isLoading, bool? isSuccess, String? errorMessage}) {
    return ProductRatingState(isLoading: isLoading ?? this.isLoading, isSuccess: isSuccess ?? this.isSuccess, errorMessage: errorMessage);
  }
}

final productRatingViewModelProvider = StateNotifierProvider.autoDispose<ProductRatingViewModel, ProductRatingState>((ref) {
  return ProductRatingViewModel(ref);
});

class ProductRatingViewModel extends StateNotifier<ProductRatingState> {
  final Ref _ref;

  ProductRatingViewModel(this._ref) : super(ProductRatingState());

  Future<bool> submitRating(String orderId, String productId, int rating, {List<Uint8List>? reviewImages}) async {
    if (state.isLoading) return false;
    if (rating < 1 || rating > 5) {
      state = state.copyWith(errorMessage: 'rating.invalid_range'.tr());
      return false;
    }
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    try {
      List<String>? reviewImageUrls;
      if (reviewImages != null && reviewImages.isNotEmpty) {
        final userId = _ref.read(userIdProvider) ?? 'unknown';
        reviewImageUrls = await _ref.read(productRepositoryProvider).uploadReviewImages(reviewImages, userId);
      }
      await _ref.read(productRepositoryProvider).submitRating(orderId, productId, rating, reviewImageUrls: reviewImageUrls);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'Failed to submit rating'));
      return false;
    }
  }
}
