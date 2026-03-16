/// Customer Support Agent — State
///
/// Holds the chat message list, loading flags, and escalation status.
library;

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
class SupportState {
  final List<SupportMessage> messages;
  final bool isLoading;
  final bool isEscalated;
  final String? errorMessage;

  const SupportState({
    this.messages = const [],
    this.isLoading = false,
    this.isEscalated = false,
    this.errorMessage,
  });

  SupportState copyWith({
    List<SupportMessage>? messages,
    bool? isLoading,
    bool? isEscalated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isEscalated: isEscalated ?? this.isEscalated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
