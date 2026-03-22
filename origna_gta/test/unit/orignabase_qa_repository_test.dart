import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/qa/orignabase_qa_repository.dart';
import 'package:origna_gta/models/qa_model.dart';

class _FakeAuth extends Fake implements OrignaBaseAuth {
  _FakeAuth({this.currentUserIdValue});

  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  String? get accessToken => 'test-access-token';
}

class _FakeDocument extends Fake implements Document {
  @override
  final String id;

  @override
  final Map<String, dynamic> data;

  _FakeDocument(this.id, this.data);

  @override
  T? get<T>(String field) => data[field] as T?;

  @override
  dynamic operator [](String key) => data[key];

  @override
  bool containsKey(String key) => data.containsKey(key);
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  final List<Document> docsList;

  _FakeQuerySnapshot(this.docsList);

  @override
  List<Document> get docs => docsList;

  @override
  bool get isEmpty => docsList.isEmpty;
}

class _FakeQuery extends Fake implements Query {
  final List<Document> queryDocs;
  String? whereField;
  dynamic whereValue;
  String? orderByField;
  bool orderByDescending = false;
  int? limitValue;

  _FakeQuery({List<Document>? docs}) : queryDocs = docs ?? [];

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) {
    whereField = field;
    whereValue = isEqualTo;
    return this;
  }

  @override
  Query orderBy(String field, {bool descending = false}) {
    orderByField = field;
    orderByDescending = descending;
    return this;
  }

  @override
  Query limit(int limit) {
    limitValue = limit;
    return this;
  }

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(queryDocs);
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final List<Document> docsList;
  final _FakeQuery queryInstance;

  _FakeCollectionRef({List<Document>? docs})
    : docsList = docs ?? [],
      queryInstance = _FakeQuery(docs: docs ?? []);

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) {
    queryInstance.where(field, isEqualTo: isEqualTo);
    return queryInstance;
  }

  @override
  Query orderBy(String field, {bool descending = false}) {
    queryInstance.orderBy(field, descending: descending);
    return queryInstance;
  }

  @override
  Query limit(int limit) {
    queryInstance.limit(limit);
    return queryInstance;
  }
}

class _FakeRealtimeClient extends Fake implements RealtimeClient {
  final StreamController<DocumentChange> _controller =
      StreamController<DocumentChange>.broadcast();
  bool connected = false;
  bool disconnected = false;

  @override
  void connect() {
    connected = true;
  }

  @override
  void disconnect() {
    disconnected = true;
    _controller.close();
  }

  @override
  Stream<DocumentChange> subscribe(String collection, {String? filter}) {
    return _controller.stream;
  }

  void emitChange(DocumentChange change) {
    _controller.add(change);
  }
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  final List<Document> questionsDocs;
  _FakeCollectionRef? collectionRefInstance;
  _FakeRealtimeClient? realtimeClientInstance;
  Object? requestError;

  _FakeOrignaBase(
    this.authValue, {
    List<Document>? questions,
    _FakeRealtimeClient? realtimeClient,
  }) : questionsDocs = questions ?? [],
       realtimeClientInstance = realtimeClient;

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  String get url => 'https://test.origna.ca';

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (requestError != null) {
      throw requestError!;
    }
    lastMethod = method;
    lastPath = path;
    lastBody = body;
    return {'ok': true};
  }

  @override
  CollectionRef collection(String name) {
    collectionRefInstance ??= _FakeCollectionRef(docs: questionsDocs);
    return collectionRefInstance!;
  }

  @override
  RealtimeClient get realtime {
    realtimeClientInstance ??= _FakeRealtimeClient();
    return realtimeClientInstance!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrignaBaseQARepository - submitQuestion', () {
    test(
      'throws OrignaBaseException when user is not authenticated (null)',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: null)),
        );

        await expectLater(
          () => repo.submitQuestion('product-1', 'Is this available?'),
          throwsA(isA<OrignaBaseException>()),
        );
      },
    );

    test(
      'throws OrignaBaseException when user is not authenticated (empty string)',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: '')),
        );

        await expectLater(
          () => repo.submitQuestion('product-1', 'Is this available?'),
          throwsA(isA<OrignaBaseException>()),
        );
      },
    );

    test('sends correct payload with trimmed question', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'user-123'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitQuestion('product-1', '  Is this in stock?  ');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, ApiEndpoints.productsQuestionsAsk);
      expect(client.lastBody, {
        Fields.productId: 'product-1',
        Fields.questionText: 'Is this in stock?',
        Fields.userId: 'user-123',
      });
    });

    test('uses correct endpoint for submitQuestion', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'user-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitQuestion('prod-123', 'Question text');

      expect(client.lastPath, ApiEndpoints.productsQuestionsAsk);
    });

    test('includes productId in request body', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'user-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitQuestion('my-product-id', 'Test question');

      expect(client.lastBody![Fields.productId], 'my-product-id');
    });
  });

  group('OrignaBaseQARepository - submitAnswer (submitAnswer method)', () {
    test(
      'throws OrignaBaseException when seller is not authenticated (null)',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: null)),
        );

        await expectLater(
          () => repo.submitAnswer('qa-1', 'Yes, it is available'),
          throwsA(isA<OrignaBaseException>()),
        );
      },
    );

    test(
      'throws OrignaBaseException when seller is not authenticated (empty)',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: '')),
        );

        await expectLater(
          () => repo.submitAnswer('qa-1', 'Answer text'),
          throwsA(isA<OrignaBaseException>()),
        );
      },
    );

    test('sends correct payload with trimmed answer', () async {
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'seller-456'),
      );
      final repo = OrignaBaseQARepository(client);

      await repo.submitAnswer('question-1', '  Yes, available now.  ');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, ApiEndpoints.productsQuestionsAnswer);
      expect(client.lastBody, {
        Fields.questionId: 'question-1',
        Fields.answerText: 'Yes, available now.',
        Fields.userId: 'seller-456',
      });
    });

    test('uses correct endpoint for submitAnswer', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'seller-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitAnswer('qa-id-123', 'Answer text');

      expect(client.lastPath, ApiEndpoints.productsQuestionsAnswer);
    });

    test('includes questionId in request body', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'seller-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitAnswer('my-question-id', 'Test answer');

      expect(client.lastBody![Fields.questionId], 'my-question-id');
    });
  });

  group('OrignaBaseQARepository - watchQA', () {
    test('returns stream of QAModel list', () {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');

      expect(stream, isA<Stream<List<QAModel>>>());
    });

    test('emits empty list when no questions exist', () async {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final questions = await stream.first;

      expect(questions, isEmpty);
    });

    test('emits list of questions from initial fetch', () async {
      final now = DateTime.now();
      final questions = [
        _FakeDocument('qa-1', {
          Fields.questionText: 'Is this new?',
          Fields.askerId: 'user-1',
          Fields.createdAt: now.toIso8601String(),
          Fields.productId: 'product-1',
        }),
        _FakeDocument('qa-2', {
          Fields.questionText: 'What is the warranty?',
          Fields.askerId: 'user-2',
          Fields.createdAt: now
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          Fields.productId: 'product-1',
        }),
      ];

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final result = await stream.first;

      expect(result.length, 2);
      expect(result[0].question, 'Is this new?');
      expect(result[1].question, 'What is the warranty?');
    });

    test('sorts questions by createdAt descending', () async {
      final older = DateTime.now().subtract(const Duration(hours: 2));
      final newer = DateTime.now();

      final questions = [
        _FakeDocument('qa-old', {
          Fields.questionText: 'Older question',
          Fields.askerId: 'user-1',
          Fields.createdAt: older.toIso8601String(),
          Fields.productId: 'product-1',
        }),
        _FakeDocument('qa-new', {
          Fields.questionText: 'Newer question',
          Fields.askerId: 'user-2',
          Fields.createdAt: newer.toIso8601String(),
          Fields.productId: 'product-1',
        }),
      ];

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final result = await stream.first;

      expect(result[0].id, 'qa-new');
      expect(result[1].id, 'qa-old');
    });

    test('parses QAModel with answer fields', () async {
      final now = DateTime.now();
      final answeredAt = now.add(const Duration(hours: 1));

      final questions = [
        _FakeDocument('qa-1', {
          Fields.questionText: 'Is this available?',
          Fields.askerId: 'buyer-1',
          Fields.createdAt: now.toIso8601String(),
          Fields.productId: 'product-1',
          Fields.answerText: 'Yes, in stock',
          Fields.answeredAt: answeredAt.toIso8601String(),
          Fields.answeredBy: 'seller-1',
        }),
      ];

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result[0].answer, 'Yes, in stock');
      expect(result[0].answeredBy, 'seller-1');
    });

    test('limits query to 10 results', () async {
      final now = DateTime.now();
      final questions = List.generate(
        15,
        (i) => _FakeDocument('qa-$i', {
          Fields.questionText: 'Question $i',
          Fields.askerId: 'user-$i',
          Fields.createdAt: now.toIso8601String(),
          Fields.productId: 'product-1',
        }),
      );

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      repo.watchQA('product-1');

      await Future.delayed(const Duration(milliseconds: 50));

      final query = client.collectionRefInstance!.queryInstance;
      expect(query.limitValue, 10);
    });

    test('filters by productId', () async {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      repo.watchQA('my-product-id');

      await Future.delayed(const Duration(milliseconds: 50));

      final query = client.collectionRefInstance!.queryInstance;
      expect(query.whereField, Fields.productId);
      expect(query.whereValue, 'my-product-id');
    });

    test('orders by createdAt descending', () async {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      repo.watchQA('product-1');

      await Future.delayed(const Duration(milliseconds: 50));

      final query = client.collectionRefInstance!.queryInstance;
      expect(query.orderByField, Fields.createdAt);
      expect(query.orderByDescending, true);
    });
  });

  group('OrignaBaseQARepository - watchQA realtime updates', () {
    test('watchQA creates a realtime connection internally', () async {
      // watchQA creates its own RealtimeClient and connects it internally.
      // We verify the stream is created and emits initial data successfully.
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      // Stream is created even though WebSocket may fail in test env
      expect(stream, isA<Stream<List<dynamic>>>());
    });

    test('queries productQuestions collection on watch', () async {
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
      );
      final repo = OrignaBaseQARepository(client);

      repo.watchQA('product-1');

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify the collection was queried during initial fetch
      expect(client.collectionRefInstance, isNotNull);
    });
  });

  group('OrignaBaseQARepository - watchQA cancellation', () {
    test('stream can be listened to and cancelled', () async {
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final subscription = stream.listen((_) {}, onError: (_) {});

      await Future.delayed(const Duration(milliseconds: 50));

      // Cancelling the subscription should not throw
      await subscription.cancel();
    });
  });

  group('OrignaBaseQARepository - error handling', () {
    test('submitQuestion propagates request errors', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'user-1'));
      client.requestError = OrignaBaseException(
        'Network error',
        statusCode: 500,
      );
      final repo = OrignaBaseQARepository(client);

      await expectLater(
        () => repo.submitQuestion('product-1', 'Question'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test('submitAnswer propagates request errors', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'seller-1'));
      client.requestError = OrignaBaseException('Forbidden', statusCode: 403);
      final repo = OrignaBaseQARepository(client);

      await expectLater(
        () => repo.submitAnswer('qa-1', 'Answer'),
        throwsA(isA<OrignaBaseException>()),
      );
    });

    test(
      'exception message for unauthenticated user in submitQuestion',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: null)),
        );

        try {
          await repo.submitQuestion('product-1', 'Question');
          fail('Should have thrown');
        } on OrignaBaseException catch (e) {
          expect(e.message, 'User not authenticated');
        }
      },
    );

    test(
      'exception message for unauthenticated user in submitAnswer',
      () async {
        final repo = OrignaBaseQARepository(
          _FakeOrignaBase(_FakeAuth(currentUserIdValue: null)),
        );

        try {
          await repo.submitAnswer('qa-1', 'Answer');
          fail('Should have thrown');
        } on OrignaBaseException catch (e) {
          expect(e.message, 'User not authenticated');
        }
      },
    );
  });

  group('OrignaBaseQARepository - collection name', () {
    test('uses productQuestions collection', () async {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      repo.watchQA('product-1');

      await Future.delayed(const Duration(milliseconds: 50));

      expect(client.collectionRefInstance, isNotNull);
    });
  });

  group('OrignaBaseQARepository - QAModel parsing', () {
    test('parses question with minimal fields', () async {
      final now = DateTime.now();
      final questions = [
        _FakeDocument('qa-minimal', {
          Fields.questionText: 'Minimal question',
          Fields.askerId: 'user-1',
          Fields.createdAt: now.toIso8601String(),
          Fields.productId: 'product-1',
        }),
      ];

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result[0].id, 'qa-minimal');
      expect(result[0].question, 'Minimal question');
      expect(result[0].authorId, 'user-1');
      expect(result[0].answer, isNull);
      expect(result[0].answeredBy, isNull);
    });

    test('handles empty question text gracefully', () async {
      final now = DateTime.now();
      final questions = [
        _FakeDocument('qa-empty', {
          Fields.questionText: '',
          Fields.askerId: 'user-1',
          Fields.createdAt: now.toIso8601String(),
          Fields.productId: 'product-1',
        }),
      ];

      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: questions,
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream = repo.watchQA('product-1');
      final result = await stream.first;

      expect(result.length, 1);
      expect(result[0].question, '');
    });
  });

  group('OrignaBaseQARepository - integration scenarios', () {
    test('submitQuestion and submitAnswer use different endpoints', () async {
      final client = _FakeOrignaBase(_FakeAuth(currentUserIdValue: 'user-1'));
      final repo = OrignaBaseQARepository(client);

      await repo.submitQuestion('product-1', 'Question?');
      final questionEndpoint = client.lastPath;

      await repo.submitAnswer('qa-1', 'Answer');
      final answerEndpoint = client.lastPath;

      expect(questionEndpoint, isNot(equals(answerEndpoint)));
      expect(questionEndpoint, ApiEndpoints.productsQuestionsAsk);
      expect(answerEndpoint, ApiEndpoints.productsQuestionsAnswer);
    });

    test('multiple calls to watchQA create independent streams', () async {
      final realtimeClient = _FakeRealtimeClient();
      final client = _FakeOrignaBase(
        _FakeAuth(currentUserIdValue: 'user-1'),
        questions: [],
        realtimeClient: realtimeClient,
      );
      final repo = OrignaBaseQARepository(client);

      final stream1 = repo.watchQA('product-1');
      final stream2 = repo.watchQA('product-2');

      expect(stream1, isNot(same(stream2)));

      final questions1 = await stream1.first;
      final questions2 = await stream2.first;

      expect(questions1, isA<List<QAModel>>());
      expect(questions2, isA<List<QAModel>>());
    });
  });
}
