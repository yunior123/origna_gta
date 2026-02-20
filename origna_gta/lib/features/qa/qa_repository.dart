import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/qa_model.dart';

final qaRepositoryProvider = Provider<QARepository>((ref) {
  return FirebaseQARepository(ref.watch(firestoreProvider));
});

class FirebaseQARepository implements QARepository {
  final FirebaseFirestore _firestore;

  FirebaseQARepository(this._firestore);

  @override
  Future<void> submitAnswer(String productId, String qaId, String sellerId, String answer) async {
    final docRef = _firestore.collection(Collections.products).doc(productId).collection(Collections.qa).doc(qaId);

    // We only update the answer fields
    await docRef.update({Fields.answerText: answer.trim(), Fields.answeredAt: FieldValue.serverTimestamp(), Fields.answeredBy: sellerId});
  }

  @override
  Future<void> submitQuestion(String productId, String buyerId, String question) async {
    final docRef = _firestore.collection(Collections.products).doc(productId).collection(Collections.qa).doc();

    final model = QAModel(id: docRef.id, question: question.trim(), authorId: buyerId, createdAt: DateTime.now());

    await docRef.set(model.toMap());
  }

  @override
  Stream<List<QAModel>> watchQA(String productId) {
    return _firestore
        .collection(Collections.products)
        .doc(productId)
        .collection(Collections.qa)
        .orderBy(Fields.createdAt, descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return [];
          return snapshot.docs.map((doc) => QAModel.fromMap(doc.id, doc.data())).toList();
        });
  }
}

abstract class QARepository {
  Future<void> submitAnswer(String productId, String qaId, String sellerId, String answer);
  Future<void> submitQuestion(String productId, String buyerId, String question);
  Stream<List<QAModel>> watchQA(String productId);
}
