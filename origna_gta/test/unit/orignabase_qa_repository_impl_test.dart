import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/qa/orignabase_qa_repository.dart';

class _FakeAuth extends Fake implements OrignaBaseAuth {
  _FakeAuth({this.currentUserIdValue});

  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  _FakeOrignaBase(this.authValue);

  final _FakeAuth authValue;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastMethod = method;
    lastPath = path;
    lastBody = body;
    return {'ok': true};
  }
}

void main() {
  group('OrignaBaseQARepository', () {
    test('submitQuestion throws when user is not authenticated', () async {
      final repo = OrignaBaseQARepository(
        _FakeOrignaBase(_FakeAuth(currentUserIdValue: null)),
      );

      await expectLater(
        () => repo.submitQuestion('p1', 'Question'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('submitAnswer throws when user is not authenticated', () async {
      final repo = OrignaBaseQARepository(
        _FakeOrignaBase(_FakeAuth(currentUserIdValue: '')),
      );

      await expectLater(
        () => repo.submitAnswer('q1', 'Answer'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('submitQuestion trims and sends the expected payload', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'buyer-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitQuestion('product-1', '  Is this in stock?  ');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, ApiEndpoints.productsQuestionsAsk);
      expect(client.lastBody, {
        Fields.productId: 'product-1',
        Fields.questionText: 'Is this in stock?',
        Fields.userId: 'buyer-1',
      });
    });

    test('submitAnswer trims and sends the expected payload', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'seller-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitAnswer('question-1', '  Yes, available now.  ');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, ApiEndpoints.productsQuestionsAnswer);
      expect(client.lastBody, {
        Fields.questionId: 'question-1',
        Fields.answerText: 'Yes, available now.',
        Fields.userId: 'seller-1',
      });
    });
  });
}
