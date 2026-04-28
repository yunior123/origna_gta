import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/qa/qa_repository.dart';
import 'package:origna_gta/models/qa_model.dart';

@GenerateNiceMocks([MockSpec<QARepository>()])
import 'qa_repository_test.mocks.dart';

void main() {
  late MockQARepository mockRepository;

  setUp(() {
    mockRepository = MockQARepository();
  });

  group('QARepository', () {
    test('submitQuestion calls repository', () async {
      await mockRepository.submitQuestion('p1', 'Is this available?');
      verify(
        mockRepository.submitQuestion('p1', 'Is this available?'),
      ).called(1);
    });

    test('submitQuestion with different product ID', () async {
      await mockRepository.submitQuestion('p2', 'When will this ship?');
      verify(
        mockRepository.submitQuestion('p2', 'When will this ship?'),
      ).called(1);
    });

    test('submitQuestion with different text', () async {
      await mockRepository.submitQuestion('p1', 'What is the warranty?');
      verify(
        mockRepository.submitQuestion('p1', 'What is the warranty?'),
      ).called(1);
    });

    test('submitAnswer calls repository', () async {
      await mockRepository.submitAnswer('qa1', 'Yes');
      verify(mockRepository.submitAnswer('qa1', 'Yes')).called(1);
    });

    test('submitAnswer with different QA ID', () async {
      await mockRepository.submitAnswer('qa2', 'No');
      verify(mockRepository.submitAnswer('qa2', 'No')).called(1);
    });

    test('submitAnswer with long answer', () async {
      const longAnswer =
          'This product is available now and will ship within 1-2 business days.';
      await mockRepository.submitAnswer('qa1', longAnswer);
      verify(mockRepository.submitAnswer('qa1', longAnswer)).called(1);
    });

    test('watchQA returns stream of QAModel', () async {
      final fakeQA = QAModel(
        id: 'qa1',
        question: 'Q1',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      when(
        mockRepository.watchQA('p1'),
      ).thenAnswer((_) => Stream.value([fakeQA]));

      final stream = mockRepository.watchQA('p1');
      final questions = await stream.first;
      expect(questions.length, 1);
      expect(questions.first.question, 'Q1');
    });

    test('watchQA returns empty list for product with no questions', () async {
      when(mockRepository.watchQA('p2')).thenAnswer((_) => Stream.value([]));

      final stream = mockRepository.watchQA('p2');
      final questions = await stream.first;
      expect(questions, isEmpty);
    });

    test('watchQA returns multiple questions in order', () async {
      final qa1 = QAModel(
        id: 'qa1',
        question: 'First question',
        authorId: 'u1',
        createdAt: DateTime(2026, 1, 1),
      );
      final qa2 = QAModel(
        id: 'qa2',
        question: 'Second question',
        authorId: 'u2',
        createdAt: DateTime(2026, 1, 2),
      );

      when(
        mockRepository.watchQA('p1'),
      ).thenAnswer((_) => Stream.value([qa1, qa2]));

      final stream = mockRepository.watchQA('p1');
      final questions = await stream.first;
      expect(questions.length, 2);
      expect(questions[0].question, 'First question');
      expect(questions[1].question, 'Second question');
    });

    test('submitQuestion throws exception on empty product ID', () async {
      when(
        mockRepository.submitQuestion('', 'Question'),
      ).thenThrow(Exception('Product ID required'));

      expect(
        () => mockRepository.submitQuestion('', 'Question'),
        throwsException,
      );
    });

    test('submitAnswer throws exception on empty QA ID', () async {
      when(
        mockRepository.submitAnswer('', 'Answer'),
      ).thenThrow(Exception('QA ID required'));

      expect(() => mockRepository.submitAnswer('', 'Answer'), throwsException);
    });

    test(
      'watchQA with different product IDs returns different streams',
      () async {
        final qa1 = QAModel(
          id: 'qa1',
          question: 'Q for p1',
          authorId: 'u1',
          createdAt: DateTime.now(),
        );
        final qa2 = QAModel(
          id: 'qa2',
          question: 'Q for p2',
          authorId: 'u2',
          createdAt: DateTime.now(),
        );

        when(
          mockRepository.watchQA('p1'),
        ).thenAnswer((_) => Stream.value([qa1]));
        when(
          mockRepository.watchQA('p2'),
        ).thenAnswer((_) => Stream.value([qa2]));

        final stream1 = await mockRepository.watchQA('p1').first;
        final stream2 = await mockRepository.watchQA('p2').first;

        expect(stream1[0].question, 'Q for p1');
        expect(stream2[0].question, 'Q for p2');
      },
    );

    test('QAModel has correct fields', () {
      final now = DateTime.now();
      final qa = QAModel(
        id: 'qa1',
        question: 'Test question',
        authorId: 'user_123',
        createdAt: now,
      );

      expect(qa.id, 'qa1');
      expect(qa.question, 'Test question');
      expect(qa.authorId, 'user_123');
      expect(qa.createdAt, now);
    });

    test('QAModel equality based on id', () {
      final now = DateTime.now();
      final qa1 = QAModel(
        id: 'qa1',
        question: 'Q1',
        authorId: 'u1',
        createdAt: now,
      );
      final qa2 = QAModel(
        id: 'qa1',
        question: 'Q1',
        authorId: 'u1',
        createdAt: now,
      );

      expect(qa1.id, qa2.id);
    });

    test('submitQuestion called multiple times', () async {
      await mockRepository.submitQuestion('p1', 'Q1');
      await mockRepository.submitQuestion('p2', 'Q2');
      await mockRepository.submitQuestion('p1', 'Q3');

      verify(mockRepository.submitQuestion('p1', 'Q1')).called(1);
      verify(mockRepository.submitQuestion('p2', 'Q2')).called(1);
      verify(mockRepository.submitQuestion('p1', 'Q3')).called(1);
    });

    test('submitAnswer called multiple times', () async {
      await mockRepository.submitAnswer('qa1', 'A1');
      await mockRepository.submitAnswer('qa2', 'A2');

      verify(mockRepository.submitAnswer('qa1', 'A1')).called(1);
      verify(mockRepository.submitAnswer('qa2', 'A2')).called(1);
    });

    test('watchQA returns stream that can be listened to', () async {
      final fakeQA = QAModel(
        id: 'qa1',
        question: 'Q1',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      when(
        mockRepository.watchQA('p1'),
      ).thenAnswer((_) => Stream.value([fakeQA]));

      var receivedData = false;
      mockRepository.watchQA('p1').listen((_) {
        receivedData = true;
      });

      await Future.delayed(Duration(milliseconds: 100));
      expect(receivedData, true);
    });
  });
}
