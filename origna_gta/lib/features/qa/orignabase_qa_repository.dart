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
    Timer? refreshTimer;

    var query = _ob
        .collection(Collections.productQuestions)
        .where(Fields.productId, isEqualTo: productId)
        .orderBy(Fields.createdAt, descending: true)
        .limit(limit);
    if (offset > 0) {
      query = query.offset(offset);
    }

    Future<void> fetchCollectionFallback() async {
      final snapshot = await query.get();
      questions.clear();
      for (final doc in snapshot.docs) {
        questions[doc.id] = QAModel.fromMap(doc.id, doc.data);
      }
    }

    Future<void> fetchAndEmit(String context) async {
      try {
        var loadedFromApi = false;
        try {
          final response = await _ob.request(
            'POST',
            ApiEndpoints.productsQuestionsList,
            body: {
              Fields.productId: productId,
              'limit': limit,
              'offset': offset,
            },
          );
          final data = response['data'];
          final result = response['result'];
          final rawQuestions =
              response['questions'] ??
              (data is Map ? data['questions'] : null) ??
              (result is Map ? result['questions'] : null);
          if (rawQuestions is! List) {
            throw OrignaBaseException('Invalid product questions response');
          }
          questions.clear();
          for (final raw in rawQuestions) {
            if (raw is! Map) continue;
            final data = raw.map((key, value) => MapEntry(key.toString(), value));
            final id =
                data[Fields.questionId] as String? ??
                data['id'] as String? ??
                data['_id'] as String? ??
                '';
            if (id.isEmpty) continue;
            questions[id] = QAModel.fromMap(id, data);
          }
          loadedFromApi = true;
        } catch (e, st) {
          AppError.log(
            e,
            stackTrace: st,
            context: '$context.api',
            extras: {'productId': productId},
          );
        }
        if (!loadedFromApi) {
          await fetchCollectionFallback();
        }
        if (!controller.isClosed) {
          controller.add(_sortedQuestions(questions));
        }
      } catch (e, st) {
        AppError.log(e, stackTrace: st, context: context);
        if (!controller.isClosed) {
          controller.add(_sortedQuestions(questions));
        }
      }
    }

    unawaited(fetchAndEmit('ob_qa.watchQA.init'));
    refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(fetchAndEmit('ob_qa.watchQA.poll'));
    });

    // Realtime updates
    final realtime = RealtimeClient(_ob);
    realtime.connect();
    final sub = realtime
        .subscribe(Collections.productQuestions)
        .listen(
          (change) {
            final doc = change.document;
            final docProductId =
                doc.data[Fields.productId] as String? ??
                doc.data['product_id'] as String?;
            if (docProductId != productId) return;

            switch (change.type) {
              case ChangeType.create:
              case ChangeType.update:
                unawaited(fetchAndEmit('ob_qa.watchQA.realtime'));
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
      refreshTimer?.cancel();
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
