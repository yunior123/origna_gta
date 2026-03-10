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
      verify(mockRepository.submitQuestion('p1', 'Is this available?')).called(1);
    });

    test('submitAnswer calls repository', () async {
      await mockRepository.submitAnswer('qa1', 'Yes');
      verify(mockRepository.submitAnswer('qa1', 'Yes')).called(1);
    });

    test('watchQA returns stream of QAModel', () async {
      final fakeQA = QAModel(
        id: 'qa1',
        question: 'Q1',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      when(mockRepository.watchQA('p1')).thenAnswer((_) => Stream.value([fakeQA]));

      final stream = mockRepository.watchQA('p1');
      final questions = await stream.first;
      expect(questions.length, 1);
      expect(questions.first.question, 'Q1');
    });
  });
}
