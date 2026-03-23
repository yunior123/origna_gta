import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_state.freezed.dart';

/// Chat state used by the ChatViewModel.
@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default(false) bool isLoading,
    String? errorMessage,
    String? chatId,
    @Default(false) bool isOwnProduct,
    @Default(false) bool isPremiumRequired,
  }) = _ChatState;
}
