/// Customer Support Resolution Agent — ViewModel
///
/// Proxies AI support chat through OrignaBase backend endpoint `/api/support/chat`.
/// The backend handles Claude API calls server-side — no API keys in the client.
///
/// Tools available server-side:
///   • lookup_order     — fetches order details
///   • process_refund   — triggers a refund via /api/orders/refunds/item
///   • escalate_to_human — emails support@orignaventures.ca and marks chat escalated
///
/// 80%+ first-contact resolution target:
///   Greet → Categorise → Use tool(s) → Resolve or escalate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/support/support_state.dart';
import 'package:origna_gta/utils/utils.dart';

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// Riverpod StateNotifier for the support chat.
class SupportViewModel extends StateNotifier<SupportState> {
  final Ref _ref;

  SupportViewModel(this._ref) : super(const SupportState());

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Send a user message and get an agent response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = SupportMessage(
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _runAgentTurn();
    } catch (e, stack) {
      AppError.log(
        e,
        stackTrace: stack,
        context: 'SupportViewModel.sendMessage',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'support.error_generic'),
      );
    }
  }

  /// Start the conversation with an initial greeting from the agent.
  Future<void> startConversation(SupportCategory category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categoryLabel = _categoryToLabel(category);
      final openingUserMsg = 'I need help with: $categoryLabel';

      final agentReply = await _callSupportChat([
        {'role': 'user', 'content': openingUserMsg},
      ]);

      state = state.copyWith(
        messages: [
          SupportMessage(
            role: MessageRole.agent,
            text: agentReply,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    } catch (e, stack) {
      AppError.log(
        e,
        stackTrace: stack,
        context: 'SupportViewModel.startConversation',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'support.error_generic'),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Internal — agent turn via OrignaBase backend
  // --------------------------------------------------------------------------

  Future<void> _runAgentTurn() async {
    final history = _buildChatHistory();
    final agentReply = await _callSupportChat(history);

    if (agentReply.trim().isNotEmpty) {
      final agentMsg = SupportMessage(
        role: MessageRole.agent,
        text: agentReply.trim(),
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, agentMsg],
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // --------------------------------------------------------------------------
  // OrignaBase support chat endpoint
  // --------------------------------------------------------------------------

  /// Builds message history from current [state.messages].
  List<Map<String, dynamic>> _buildChatHistory() {
    return state.messages.map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();
  }

  /// Call OrignaBase `/api/support/chat` endpoint.
  /// The backend handles all Claude API communication server-side.
  /// Returns the agent's text reply.
  Future<String> _callSupportChat(List<Map<String, dynamic>> messages) async {
    final ob = _ref.read(orignabaseProvider);
    final user = _ref.read(currentUserProvider);

    final response = await ob.request(
      'POST',
      ApiEndpoints.supportChat,
      body: {
        'messages': messages,
        // Send both casing variants while dev catches up on the server DTO.
        'customerEmail': user?.email ?? 'unknown',
        'customer_email': user?.email ?? 'unknown',
        'customerId': user?.uid ?? 'unknown',
        'customer_id': user?.uid ?? 'unknown',
      },
    );

    // Check if the backend flagged escalation
    if (response['escalated'] == true) {
      state = state.copyWith(isEscalated: true);
    }

    return response['reply'] as String? ?? '';
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _categoryToLabel(SupportCategory category) {
    switch (category) {
      case SupportCategory.orderStatus:
        return 'order status';
      case SupportCategory.refundRequest:
        return 'refund request';
      case SupportCategory.accountIssue:
        return 'account issue';
      case SupportCategory.billingDispute:
        return 'billing dispute';
      case SupportCategory.other:
        return 'general inquiry';
    }
  }
}
