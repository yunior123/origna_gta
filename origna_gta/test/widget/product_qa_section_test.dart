import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/qa_model.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_qa_section.dart';


import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    required String productId,
    required String sellerId,
    String? currentUserId,
    List<QAModel>? qaList,
  }) {
    return TestWrapper(
      overrides: [
        qaListProvider(
          productId,
        ).overrideWith((_) => Stream.value(qaList ?? [])),
        userIdProvider.overrideWithValue(currentUserId),
        subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
        currentUserProvider.overrideWithValue(
          currentUserId != null
              ? AppAuthUser(uid: currentUserId, email: 'test@test.com')
              : null,
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: QASection(productId: productId, sellerId: sellerId),
        ),
      ),
    );
  }

  group('QASection', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('renders with questions', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Is this product good?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          qaList: qaList,
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('renders QA with answer', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Is this waterproof?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
          answer: 'Yes, it is waterproof.',
          answeredAt: DateTime(2025, 6, 16),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          qaList: qaList,
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('seller sees unanswered question', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'How long is the warranty?',
          authorId: 'buyer1',
          createdAt: DateTime(2025, 6, 15),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'seller1',
          qaList: qaList,
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('unauthenticated user sees section', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', sellerId: 'seller1', currentUserId: null),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('non-seller sees section', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('multiple questions render', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Question 1?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 1),
        ),
        QAModel(
          id: 'qa2',
          question: 'Question 2?',
          authorId: 'user2',
          createdAt: DateTime(2025, 6, 2),
        ),
        QAModel(
          id: 'qa3',
          question: 'Question 3?',
          authorId: 'user3',
          createdAt: DateTime(2025, 6, 3),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          qaList: qaList,
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            qaListProvider('p1').overrideWith((_) => const Stream.empty()),
            userIdProvider.overrideWithValue('user1'),
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(
              child: QASection(productId: 'p1', sellerId: 'seller1'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            qaListProvider(
              'p1',
            ).overrideWith((_) => Stream.error('Network error')),
            userIdProvider.overrideWithValue('user1'),
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(
              child: QASection(productId: 'p1', sellerId: 'seller1'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QASection), findsOneWidget);
    });
  });
}
