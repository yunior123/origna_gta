import 'dart:async';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/qa_model.dart';
import 'package:origna_gta/utils/utils.dart';

import 'qa_repository.dart';

/// OrignaBase Q&A repository — replaces legacy backend.
class OrignaBaseQARepository implements QARepository {
  final OrignaBase _ob;

  OrignaBaseQARepository(this._ob);

  String? get _currentUserId => _ob.auth.currentUserId;

  @override
  Future<void> submitAnswer(String qaId, String answer) async {
    final sellerId = _currentUserId;
    if (sellerId == null || sellerId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }

    await _ob.request(
      'POST',
      ApiEndpoints.productsQuestionsAnswer,
      body: {
        Fields.questionId: qaId,
        Fields.answerText: answer.trim(),
        Fields.userId: sellerId,
      },
    );
  }

  @override
  Future<void> submitQuestion(String productId, String question) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw OrignaBaseException('User not authenticated');
    }

    await _ob.request(
      'POST',
      ApiEndpoints.productsQuestionsAsk,
      body: {
        Fields.productId: productId,
        Fields.questionText: question.trim(),
        Fields.userId: userId,
      },
    );
  }

  @override
  Stream<List<QAModel>> watchQA(
    String productId, {
    int limit = 20,
    int offset = 0,
  }) {
    final controller = StreamController<List<QAModel>>();
    final questions = <String, QAModel>{};

    var query = _ob
        .collection(Collections.productQuestions)
        .where(Fields.productId, isEqualTo: productId)
        .orderBy(Fields.createdAt, descending: true)
        .limit(limit);
    if (offset > 0) {
      query = query.offset(offset);
    }
    query
        .get()
        .then((snapshot) {
          if (snapshot.isEmpty) {
            controller.add([]);
            return;
          }
          for (final doc in snapshot.docs) {
            questions[doc.id] = QAModel.fromMap(doc.id, doc.data);
          }
          controller.add(_sortedQuestions(questions));
        })
        .catchError((Object e, StackTrace st) {
          AppError.log(e, stackTrace: st, context: 'ob_qa.watchQA.init');
          controller.add(const <QAModel>[]);
        });

    // Realtime updates
    final realtime = RealtimeClient(_ob);
    realtime.connect();
    final sub = realtime
        .subscribe(Collections.productQuestions)
        .listen(
          (change) {
            final doc = change.document;
            final docProductId = doc.data[Fields.productId] as String?;
            if (docProductId != productId) return;

            switch (change.type) {
              case ChangeType.create:
              case ChangeType.update:
                questions[doc.id] = QAModel.fromMap(doc.id, doc.data);
                controller.add(_sortedQuestions(questions));
              case ChangeType.delete:
                questions.remove(doc.id);
                controller.add(_sortedQuestions(questions));
            }
          },
          onError: (Object e, StackTrace st) {
            AppError.log(e, stackTrace: st, context: 'ob_qa.watchQA.realtime');
          },
        );

    controller.onCancel = () {
      sub.cancel();
      realtime.disconnect();
    };

    return controller.stream;
  }

  List<QAModel> _sortedQuestions(Map<String, QAModel> questions) {
    final list = questions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
