import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/features/products/product_rating_viewmodel.dart';

class _FakeProductRepo implements ProductRepository {
  Object? nextError;
  int submitCalls = 0;
  List<Uint8List>? lastImages;
  String? lastReviewText;

  @override
  Future<void> submitRatingAtomic(
    String orderId,
    String productId,
    int rating, {
    List<Uint8List>? reviewImages,
    String? reviewText,
  }) async {
    submitCalls++;
    lastImages = reviewImages;
    lastReviewText = reviewText;
    if (nextError != null) throw nextError!;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeProductRepo fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = _FakeProductRepo();
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);
  });

  group('ProductRatingViewModel', () {
    test('initial state is clean', () {
      final s = container.read(productRatingViewModelProvider);
      expect(s.isLoading, isFalse);
      expect(s.isSuccess, isFalse);
      expect(s.errorMessage, isNull);
      expect(s.reviewText, isNull);
    });

    test('setReviewText updates state', () {
      container
          .read(productRatingViewModelProvider.notifier)
          .setReviewText('Good!');
      expect(
        container.read(productRatingViewModelProvider).reviewText,
        'Good!',
      );
    });

    test('submitRating returns false for rating < 1', () async {
      final result = await container
          .read(productRatingViewModelProvider.notifier)
          .submitRating('o1', 'p1', 0);
      expect(result, isFalse);
      expect(
        container.read(productRatingViewModelProvider).errorMessage,
        isNotNull,
      );
      expect(fakeRepo.submitCalls, 0);
    });

    test('submitRating returns false for rating > 5', () async {
      final result = await container
          .read(productRatingViewModelProvider.notifier)
          .submitRating('o1', 'p1', 6);
      expect(result, isFalse);
      expect(fakeRepo.submitCalls, 0);
    });

    test('submitRating returns true on success', () async {
      final result = await container
          .read(productRatingViewModelProvider.notifier)
          .submitRating('o1', 'p1', 4, reviewText: 'Nice');
      expect(result, isTrue);
      expect(container.read(productRatingViewModelProvider).isSuccess, isTrue);
      expect(fakeRepo.submitCalls, 1);
    });

    test('submitRating sets errorMessage on failure', () async {
      fakeRepo.nextError = Exception('server error');
      final result = await container
          .read(productRatingViewModelProvider.notifier)
          .submitRating('o1', 'p1', 3);
      expect(result, isFalse);
      expect(
        container.read(productRatingViewModelProvider).errorMessage,
        isNotNull,
      );
    });

    test('submitRating passes images to repository', () async {
      final images = [
        Uint8List.fromList([1, 2, 3]),
      ];
      await container
          .read(productRatingViewModelProvider.notifier)
          .submitRating('o1', 'p1', 5, reviewImages: images);
      expect(fakeRepo.lastImages, images);
    });
  });
}
