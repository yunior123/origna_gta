import 'package:orignabase/orignabase.dart' show FieldValue;
import 'package:origna_gta/core/schema/schema_constants.dart';

DateTime? _parseDt(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  final dynamic maybeDate = value;
  if (maybeDate is! String && maybeDate is! int) {
    try {
      final converted = maybeDate.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {}
  }
  return null;
}

/// Documentation for QAModel
class QAModel {
  final String id;
  final String question;
  final String authorId;
  final DateTime createdAt;
  final String? answer;
  final DateTime? answeredAt;
  final String? answeredBy;

  const QAModel({required this.id, required this.question, required this.authorId, required this.createdAt, this.answer, this.answeredAt, this.answeredBy});

  factory QAModel.fromMap(String id, Map<String, dynamic> map) {
    return QAModel(
      id: id,
      question: map[Fields.questionText] ?? map['question'] ?? '',
      authorId: map[Fields.askerId] ?? map['authorId'] ?? '',
      createdAt: _parseDt(map[Fields.createdAt]) ?? DateTime.now(),
      answer: map[Fields.answerText] ?? map['answer'],
      answeredAt: _parseDt(map[Fields.answeredAt]),
      answeredBy: map[Fields.answeredBy],
    );
  }

  QAModel copyWith({String? id, String? question, String? authorId, DateTime? createdAt, String? answer, DateTime? answeredAt, String? answeredBy}) {
    return QAModel(
      id: id ?? this.id,
      question: question ?? this.question,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
      answeredBy: answeredBy ?? this.answeredBy,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{Fields.questionText: question, Fields.askerId: authorId, Fields.createdAt: FieldValue.serverTimestamp()};

    if (answer != null) {
      map[Fields.answerText] = answer;
      map[Fields.answeredAt] = answeredAt?.toIso8601String() ?? FieldValue.serverTimestamp();
      if (answeredBy != null) map[Fields.answeredBy] = answeredBy;
    }

    return map;
  }
}
