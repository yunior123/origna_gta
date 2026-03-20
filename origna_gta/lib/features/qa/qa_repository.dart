import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/qa/orignabase_qa_repository.dart';
import 'package:origna_gta/models/qa_model.dart';

final qaRepositoryProvider = Provider<QARepository>((ref) {
  return OrignaBaseQARepository(ref.watch(orignabaseProvider));
});

abstract class QARepository {
  Future<void> submitAnswer(String qaId, String answer);
  Future<void> submitQuestion(String productId, String question);
  Stream<List<QAModel>> watchQA(String productId);
}
