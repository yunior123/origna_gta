import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/qa/qa_repository.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/qa_model.dart';

@GenerateNiceMocks([MockSpec<QARepository>()])
import 'qa_provider_test.mocks.dart';

void main() {
  late MockQARepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockQARepository();
    container = ProviderContainer(
      overrides: [
        qaRepositoryProvider.overrideWithValue(mockRepo),
        userIdProvider.overrideWith((ref) => 'user_123'),
        subscriptionStreamProvider.overrideWith(
          (ref) => Stream.value(
            const SubscriptionInfo(isPremium: true, status: 'active'),
          ),
        ),
      ],
    );

    when(mockRepo.submitQuestion(any, any)).thenAnswer((_) async => {});
    when(mockRepo.submitAnswer(any, any)).thenAnswer((_) async => {});
  });

  group('QAController Tests', () {
    test('askQuestion calls repository when premium', () async {
      // Wait for subscription state to load
      await container.read(subscriptionStreamProvider.future);

      await container
          .read(qaControllerProvider.notifier)
          .askQuestion('p1', 'What is this?');

      verify(mockRepo.submitQuestion('p1', 'What is this?')).called(1);
      expect(container.read(qaControllerProvider).hasError, isFalse);
    });

    test('askQuestion fails when not premium', () async {
      container = ProviderContainer(
        overrides: [
          qaRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => 'user_123'),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(isPremium: false, status: 'none'),
            ),
          ),
        ],
      );

      await container.read(subscriptionStreamProvider.future);
      await container
          .read(qaControllerProvider.notifier)
          .askQuestion('p1', 'What is this?');

      expect(container.read(qaControllerProvider).hasError, isTrue);
      expect(
        container.read(qaControllerProvider).error,
        isA<PremiumRequiredException>(),
      );
      verifyNever(mockRepo.submitQuestion(any, any));
    });

    test('answerQuestion calls repository', () async {
      await container
          .read(qaControllerProvider.notifier)
          .answerQuestion(qaId: 'q1', answer: 'Ans');

      verify(mockRepo.submitAnswer('q1', 'Ans')).called(1);
    });

    test('answerQuestion fails when user is signed out', () async {
      final signedOutContainer = ProviderContainer(
        overrides: [
          qaRepositoryProvider.overrideWithValue(mockRepo),
          userIdProvider.overrideWith((ref) => null),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(isPremium: true, status: 'active'),
            ),
          ),
        ],
      );
      addTearDown(signedOutContainer.dispose);

      await signedOutContainer
          .read(qaControllerProvider.notifier)
          .answerQuestion(qaId: 'q1', answer: 'Ans');

      expect(signedOutContainer.read(qaControllerProvider).hasError, isTrue);
      verifyNever(mockRepo.submitAnswer(any, any));
    });

    test('askQuestion stores repository errors', () async {
      when(
        mockRepo.submitQuestion(any, any),
      ).thenThrow(Exception('backend down'));
      await container.read(subscriptionStreamProvider.future);

      await container
          .read(qaControllerProvider.notifier)
          .askQuestion('p1', 'What broke?');

      expect(container.read(qaControllerProvider).hasError, isTrue);
      expect(container.read(qaControllerProvider).error, isA<Exception>());
    });
  });

  group('QA stream providers', () {
    test('qaListProvider forwards repository stream', () async {
      final question = QAModel(
        id: 'q1',
        question: 'Question?',
        authorId: 'user_123',
        createdAt: DateTime.utc(2026, 3, 19),
      );
      when(mockRepo.watchQA('p1')).thenAnswer((_) => Stream.value([question]));

      final value = await container.read(qaListProvider('p1').future);
      expect(value.single.id, 'q1');
    });

    test('unansweredQaCountProvider counts null and empty answers', () async {
      final questions = [
        QAModel(
          id: 'q1',
          question: 'First?',
          authorId: 'user_123',
          createdAt: DateTime.utc(2026, 3, 19),
        ),
        QAModel(
          id: 'q2',
          question: 'Second?',
          authorId: 'user_123',
          answer: '',
          createdAt: DateTime.utc(2026, 3, 19),
        ),
        QAModel(
          id: 'q3',
          question: 'Third?',
          authorId: 'user_123',
          answer: 'Done',
          createdAt: DateTime.utc(2026, 3, 19),
        ),
      ];
      when(mockRepo.watchQA('p1')).thenAnswer((_) => Stream.value(questions));

      final count = await container.read(
        unansweredQaCountProvider('p1').future,
      );
      expect(count, 2);
    });
  });
}
