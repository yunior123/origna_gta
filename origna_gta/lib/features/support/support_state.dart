/// Customer Support Agent — State
///
/// Holds the chat message list, loading flags, and escalation status.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_state.freezed.dart';

/// Category of support issue chosen by the user before the conversation starts.
enum SupportCategory {
  orderStatus,
  refundRequest,
  accountIssue,
  billingDispute,
  other,
}

/// Direction of a chat bubble.
enum MessageRole { user, agent }

/// A single message in the support chat.
class SupportMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  const SupportMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

/// Immutable state for [SupportViewModel].
@freezed
abstract class SupportState with _$SupportState {
  const factory SupportState({
    @Default([]) List<SupportMessage> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isEscalated,
    String? errorMessage,
  }) = _SupportState;
}
