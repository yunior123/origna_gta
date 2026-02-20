import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/qa/qa_repository.dart';
import 'package:origna_gta/models/qa_model.dart';

final qaControllerProvider = StateNotifierProvider<QAController, AsyncValue<void>>((ref) {
  return QAController(ref.watch(qaRepositoryProvider), ref);
});

final qaListProvider = StreamProvider.family<List<QAModel>, String>((ref, productId) {
  final repo = ref.watch(qaRepositoryProvider);
  return repo.watchQA(productId);
});

class QAController extends StateNotifier<AsyncValue<void>> {
  final QARepository _repository;
  final Ref _ref;

  QAController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> answerQuestion({required String productId, required String qaId, required String answer}) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      if (userId == null) {
        throw Exception('User must be logged in to answer a question');
      }
      await _repository.submitAnswer(productId, qaId, userId, answer);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> askQuestion(String productId, String question) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      if (userId == null) {
        throw Exception('User must be logged in to ask a question');
      }

      // Premium gate: only premium subscribers can post questions
      final userProfile = _ref.read(userProfileProvider).valueOrNull;
      if (userProfile == null || !userProfile.isPremium) {
        throw const PremiumRequiredException(
          'Origna Premium required to ask questions. Upgrade to unlock Q&A, chat with sellers, and more.',
        );
      }

      await _repository.submitQuestion(productId, userId, question);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Thrown when a premium-only feature is accessed by a non-premium user.
class PremiumRequiredException implements Exception {
  final String message;
  const PremiumRequiredException(this.message);

  @override
  String toString() => message;
}
