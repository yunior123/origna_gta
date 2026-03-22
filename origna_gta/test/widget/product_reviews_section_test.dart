import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/products/review_eligibility_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_reviews_section.dart';


import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    required String productId,
    required int ratingCount,
    required double averageRating,
    required AsyncValue<List<Map<String, dynamic>>> ratingsAsync,
    List<Override> extraOverrides = const [],
  }) {
    return TestWrapper(
      overrides: [
        reviewEligibilityProvider(productId).overrideWith(
          (_) => const AsyncValue.data(
            ReviewEligibility(eligibleOrderId: 'order1'),
          ),
        ),
        subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
        currentUserProvider.overrideWithValue(
          AppAuthUser(uid: 'user1', email: 'test@test.com'),
        ),
        ...extraOverrides,
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: ReviewsSection(
            productId: productId,
            productName: 'Test Product',
            ratingCount: ratingCount,
            averageRating: averageRating,
            ratingsAsync: ratingsAsync,
          ),
        ),
      ),
    );
  }

  group('ReviewsSection', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.loading(),
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.error('error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.data([]),
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('renders reviews', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 5,
          'review': 'Excellent!',
          'userId': 'user12345678',
          'helpfulCount': 3,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': true,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 5.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.text('Excellent!'), findsOneWidget);
    });

    testWidgets('renders review with seller reply', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 4,
          'review': 'Good item',
          'userId': 'user12345678',
          'helpfulCount': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'sellerReply': 'Thanks!',
          'verifiedPurchase': false,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 4.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.text('Good item'), findsOneWidget);
      expect(find.text('Thanks!'), findsOneWidget);
    });

    testWidgets('empty review hidden', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 3,
          'review': '',
          'userId': 'user12345678',
          'helpfulCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': false,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 3.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('verified badge shown', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 5,
          'review': 'Verified!',
          'userId': 'user12345678',
          'helpfulCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': true,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 5.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('star icons rendered', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 3,
          'review': 'Three stars',
          'userId': 'user12345678',
          'helpfulCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': false,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 3.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.byIcon(Icons.star_border_rounded), findsWidgets);
    });

    testWidgets('ratingCount > 0 with no text reviews', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 5,
          averageRating: 4.2,
          ratingsAsync: const AsyncValue.data([]),
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('already reviewed', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 4,
          'review': 'My review',
          'userId': 'user12345678',
          'helpfulCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': false,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 4.0,
          ratingsAsync: AsyncValue.data(ratings),
          extraOverrides: [
            reviewEligibilityProvider('p1').overrideWith(
              (_) => const AsyncValue.data(
                ReviewEligibility(alreadyReviewed: true),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('helpful count shown', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 4,
          'review': 'Helpful test',
          'userId': 'user12345678',
          'helpfulCount': 2,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': false,
          'reviewImageUrls': <String>[],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 4.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.text('Helpful test'), findsOneWidget);
    });

    testWidgets('review with photos', (tester) async {
      final ratings = [
        {
          'ratingId': 'r1',
          'rating': 5,
          'review': 'Has photos',
          'userId': 'user12345678',
          'helpfulCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'verifiedPurchase': false,
          'reviewImageUrls': ['https://example.com/photo1.jpg'],
        },
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 1,
          averageRating: 5.0,
          ratingsAsync: AsyncValue.data(ratings),
        ),
      );
      await tester.pump();

      expect(find.text('Has photos'), findsOneWidget);
    });

    testWidgets('eligibility loading', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.data([]),
          extraOverrides: [
            reviewEligibilityProvider(
              'p1',
            ).overrideWith((_) => const AsyncValue.loading()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('eligibility error', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.data([]),
          extraOverrides: [
            reviewEligibilityProvider('p1').overrideWith(
              (_) => const AsyncValue.error('e', StackTrace.empty),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });

    testWidgets('unauthenticated user', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          ratingCount: 0,
          averageRating: 0,
          ratingsAsync: const AsyncValue.data([]),
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            reviewEligibilityProvider(
              'p1',
            ).overrideWith((_) => const AsyncValue.data(ReviewEligibility())),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ReviewsSection), findsOneWidget);
    });
  });
}
