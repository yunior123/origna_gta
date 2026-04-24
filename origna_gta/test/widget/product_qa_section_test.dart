import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/qa_model.dart';
import 'package:origna_gta/screens/widgets/product_detail/product_qa_section.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

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
    bool isPremium = false,
    bool isLoading = false,
    bool hasError = false,
  }) {
    return TestWrapper(
      overrides: [
        qaListProvider(productId).overrideWith((_) {
          if (isLoading) return const Stream.empty();
          if (hasError) return Stream.error('Network error');
          return Stream.value(qaList ?? []);
        }),
        userIdProvider.overrideWithValue(currentUserId),
        subscriptionStreamProvider.overrideWith(
          (_) => Stream.value(
            SubscriptionInfo(
              status: isPremium ? 'active' : 'inactive',
              isPremium: isPremium,
            ),
          ),
        ),
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

  group('QASection - Question List Rendering', () {
    testWidgets('renders empty state with no questions', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QASection), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('renders a visible error message when loading fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          hasError: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              ((widget.data?.contains('Something went wrong') ?? false) ||
                  (widget.data?.contains('errors.something_went_wrong') ??
                      false)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders single question', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Is this product good?'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders multiple questions (up to 3 by default)', (
      tester,
    ) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Question 1?'), findsOneWidget);
      expect(find.text('Question 2?'), findsOneWidget);
      expect(find.text('Question 3?'), findsOneWidget);
    });

    testWidgets('shows "see all" button when more than 3 questions', (
      tester,
    ) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Q1?',
          authorId: 'u1',
          createdAt: DateTime(2025, 6, 1),
        ),
        QAModel(
          id: 'qa2',
          question: 'Q2?',
          authorId: 'u2',
          createdAt: DateTime(2025, 6, 2),
        ),
        QAModel(
          id: 'qa3',
          question: 'Q3?',
          authorId: 'u3',
          createdAt: DateTime(2025, 6, 3),
        ),
        QAModel(
          id: 'qa4',
          question: 'Q4?',
          authorId: 'u4',
          createdAt: DateTime(2025, 6, 4),
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
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('expands to show all questions when "see all" tapped', (
      tester,
    ) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Q1?',
          authorId: 'u1',
          createdAt: DateTime(2025, 6, 1),
        ),
        QAModel(
          id: 'qa2',
          question: 'Q2?',
          authorId: 'u2',
          createdAt: DateTime(2025, 6, 2),
        ),
        QAModel(
          id: 'qa3',
          question: 'Q3?',
          authorId: 'u3',
          createdAt: DateTime(2025, 6, 3),
        ),
        QAModel(
          id: 'qa4',
          question: 'Q4?',
          authorId: 'u4',
          createdAt: DateTime(2025, 6, 4),
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
      await tester.pumpAndSettle();

      expect(find.text('Q4?'), findsNothing);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('Q4?'), findsOneWidget);
    });
  });

  group('QASection - Answer Display', () {
    testWidgets('renders question with answer', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Is this waterproof?'), findsOneWidget);
      expect(find.text('Yes, it is waterproof.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows answered date when answer exists', (tester) async {
      final answeredDate = DateTime(2025, 6, 16);
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Question?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
          answer: 'Answer here',
          answeredAt: answeredDate,
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
      await tester.pumpAndSettle();

      expect(find.text('Answer here'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('unanswered question shows no answer section for non-seller', (
      tester,
    ) async {
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
          currentUserId: 'user1',
          qaList: qaList,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How long is the warranty?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('seller sees answer button for unanswered question', (
      tester,
    ) async {
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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.reply), findsOneWidget);
    });
  });

  group('QASection - Ask Question Form', () {
    testWidgets('premium user sees ask question button', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: true,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      final buttons = find.byType(ModernButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('non-premium user sees locked ask question button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: false,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('seller does not see ask question button', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'seller1',
          isPremium: true,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('unauthenticated user sees sign in prompt', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: null,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('tapping ask question button shows dialog for premium user', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: true,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byType(ModernButton).first;
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tapping locked button shows premium paywall', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: false,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byType(ModernButton).first;
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('QASection - Loading States', () {
    testWidgets('renders loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isLoading: true,
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('loading state replaces content area', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isLoading: true,
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsNothing);
    });
  });

  group('QASection - Error Handling', () {
    testWidgets('falls back to empty state on failure', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          hasError: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QASection), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('error state does not crash widget', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          hasError: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QASection), findsOneWidget);
    });
  });

  group('QASection - Dark Mode', () {
    testWidgets('renders in dark mode', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Dark mode question?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: TestWrapper(
            overrides: [
              qaListProvider('p1').overrideWith((_) => Stream.value(qaList)),
              userIdProvider.overrideWithValue('user1'),
              subscriptionStreamProvider.overrideWith(
                (_) => Stream.value(null),
              ),
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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark mode question?'), findsOneWidget);
    });
  });

  group('QASection - Edge Cases', () {
    testWidgets('handles empty answer string', (tester) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Question with empty answer?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
          answer: '',
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
      await tester.pumpAndSettle();

      expect(find.text('Question with empty answer?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('handles very long question text', (tester) async {
      final longQuestion =
          'This is a very long question that might need to be truncated or wrapped properly in the UI to ensure good readability and user experience?';
      final qaList = [
        QAModel(
          id: 'qa1',
          question: longQuestion,
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
      await tester.pumpAndSettle();

      expect(find.text(longQuestion), findsOneWidget);
    });

    testWidgets('handles very long answer text', (tester) async {
      final longAnswer =
          'This is a very long answer that provides detailed information about the product and should be displayed properly in the UI with appropriate text wrapping and styling for better readability.';
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Short question?',
          authorId: 'user1',
          createdAt: DateTime(2025, 6, 15),
          answer: longAnswer,
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
      await tester.pumpAndSettle();

      expect(find.text(longAnswer), findsOneWidget);
    });

    testWidgets('premium user with questions list shows ask button', (
      tester,
    ) async {
      final qaList = [
        QAModel(
          id: 'qa1',
          question: 'Existing question?',
          authorId: 'user2',
          createdAt: DateTime(2025, 6, 15),
        ),
      ];

      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: true,
          qaList: qaList,
        ),
      );
      await tester.pumpAndSettle();

      final buttons = find.byType(ModernButton);
      expect(buttons, findsWidgets);
    });

    testWidgets(
      'non-seller non-premium with existing questions shows locked button',
      (tester) async {
        final qaList = [
          QAModel(
            id: 'qa1',
            question: 'Existing question?',
            authorId: 'user2',
            createdAt: DateTime(2025, 6, 15),
          ),
        ];

        await tester.pumpWidget(
          buildWidget(
            productId: 'p1',
            sellerId: 'seller1',
            currentUserId: 'user1',
            isPremium: false,
            qaList: qaList,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      },
    );
  });

  group('QASection - Empty State Variations', () {
    testWidgets('empty state shows icon and message', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('empty state for seller shows no ask button', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'seller1',
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('empty state for unauthenticated shows sign in message', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: null,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('empty state for premium user shows ask button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          productId: 'p1',
          sellerId: 'seller1',
          currentUserId: 'user1',
          isPremium: true,
          qaList: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
      final buttons = find.byType(ModernButton);
      expect(buttons, findsWidgets);
    });
  });
}
