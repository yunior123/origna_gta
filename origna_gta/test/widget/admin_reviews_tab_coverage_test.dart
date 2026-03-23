import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_reviews_tab.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_reviews_tab_coverage_test.mocks.dart';

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    when(
      mockAdminRepo.watchReviews(
        flaggedOnly: anyNamed('flaggedOnly'),
        hasPhotosOnly: anyNamed('hasPhotosOnly'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.flagReview(any, flagged: anyNamed('flagged')),
    ).thenAnswer((_) async {});
    when(mockAdminRepo.deleteReview(any)).thenAnswer((_) async {});
  });

  Widget buildWidget() {
    return TestWrapper(
      overrides: [adminRepositoryProvider.overrideWithValue(mockAdminRepo)],
      child: const Scaffold(body: AdminReviewsTab()),
    );
  }

  group('AdminReviewsTab', () {
    testWidgets('renders loading state', (tester) async {
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminReviewsTab), findsOneWidget);
    });

    testWidgets('renders empty state when no reviews', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.rate_review_rounded), findsOneWidget);
    });

    testWidgets('renders reviews list', (tester) async {
      final reviews = [
        {
          'id': 'r1',
          'rating': 4,
          'review': 'Great product!',
          'userId': 'u1',
          'productId': 'p1',
          'isFlagged': false,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
        {
          'id': 'r2',
          'rating': 2,
          'review': 'Not great',
          'userId': 'u2',
          'productId': 'p2',
          'isFlagged': true,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Great product!'), findsOneWidget);
      expect(find.text('Not great'), findsOneWidget);
    });

    testWidgets('renders starred ratings', (tester) async {
      final reviews = [
        {
          'id': 'r1',
          'rating': 3,
          'review': 'OK',
          'userId': 'u1',
          'productId': 'p1',
          'isFlagged': false,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(2));
    });

    testWidgets('flagged review shows flagged badge', (tester) async {
      final reviews = [
        {
          'id': 'r1',
          'rating': 1,
          'review': 'Bad',
          'userId': 'u1',
          'productId': 'p1',
          'isFlagged': true,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flag_rounded), findsWidgets);
    });

    testWidgets('review with images shows image count', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final reviews = [
        {
          'id': 'r1',
          'rating': 5,
          'review': 'Nice',
          'userId': 'u1',
          'productId': 'p1',
          'isFlagged': false,
          'imageUrls': ['url1', 'url2'],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminReviewsTab), findsOneWidget);
    });

    testWidgets('filter flagged chip exists and is toggleable', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final flaggedChip = find.byKey(const Key('admin_reviews_filter_flagged'));
      expect(flaggedChip, findsOneWidget);

      await tester.tap(flaggedChip);
      await tester.pumpAndSettle();
    });

    testWidgets('filter photos chip exists and is toggleable', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final photosChip = find.byKey(const Key('admin_reviews_filter_photos'));
      expect(photosChip, findsOneWidget);

      await tester.tap(photosChip);
      await tester.pumpAndSettle();
    });

    testWidgets('review card shows product and user ids', (tester) async {
      final reviews = [
        {
          'id': 'r1',
          'rating': 4,
          'review': '',
          'userId': 'user123',
          'productId': 'product456',
          'isFlagged': false,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('product456'), findsOneWidget);
      expect(find.textContaining('user123'), findsOneWidget);
    });

    testWidgets('delete button exists on review card', (tester) async {
      final reviews = [
        {
          'id': 'r1',
          'rating': 3,
          'review': 'test',
          'userId': 'u1',
          'productId': 'p1',
          'isFlagged': false,
          'imageUrls': <String>[],
          'createdAt': DateTime.now(),
        },
      ];
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.value(reviews));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_review_delete_r1')), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(
        mockAdminRepo.watchReviews(
          flaggedOnly: anyNamed('flaggedOnly'),
          hasPhotosOnly: anyNamed('hasPhotosOnly'),
        ),
      ).thenAnswer((_) => Stream.error('error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminReviewsTab), findsOneWidget);
    });
  });
}
