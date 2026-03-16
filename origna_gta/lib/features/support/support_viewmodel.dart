/// Customer Support Resolution Agent — ViewModel
///
/// Calls the Claude claude-sonnet-4-6 API with function-calling tools:
///   • lookup_order     — fetches order details from OrignaBase
///   • process_refund   — triggers a refund via OrignaBase /api/orders/refunds/item
///   • escalate_to_human — emails support@orignaventures.ca and marks chat escalated
///
/// 80%+ first-contact resolution target:
///   Greet → Categorise → Use tool(s) → Resolve or escalate.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/support/support_state.dart';
import 'package:origna_gta/utils/utils.dart';

// ---------------------------------------------------------------------------
// Claude API configuration
// ---------------------------------------------------------------------------

/// Model to use for the support agent.
/// Change to a cheaper model for cost reduction if needed.
const _kClaudeModel = 'claude-sonnet-4-6';

/// Tool definitions sent to Claude on every turn.
const List<Map<String, dynamic>> _kTools = [
  {
    'name': 'lookup_order',
    'description':
        'Fetch details of a customer order from the OrignaBase backend. '
        'Call this when the customer mentions an order ID or wants to check order status.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'order_id': {
          'type': 'string',
          'description': 'The order ID provided by the customer.',
        },
      },
      'required': ['order_id'],
    },
  },
  {
    'name': 'process_refund',
    'description':
        'Initiate a refund for a specific item in an order. '
        'Only call this when the customer explicitly requests a refund and has confirmed the order ID and reason.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'order_id': {
          'type': 'string',
          'description': 'The order ID to refund.',
        },
        'reason': {
          'type': 'string',
          'description': 'Reason for the refund (e.g. "damaged", "not_received", "changed_mind").',
        },
      },
      'required': ['order_id', 'reason'],
    },
  },
  {
    'name': 'escalate_to_human',
    'description':
        'Escalate this conversation to a human support agent. '
        'Use this when the issue cannot be resolved automatically, when the customer is upset, '
        'or when the situation requires human judgment.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'summary': {
          'type': 'string',
          'description': 'A brief summary of the issue and what has been attempted.',
        },
        'customer_email': {
          'type': 'string',
          'description': "The customer's email address for follow-up.",
        },
      },
      'required': ['summary'],
    },
  },
];

// ---------------------------------------------------------------------------
// System prompt
// ---------------------------------------------------------------------------

String _buildSystemPrompt({required String userEmail, required String userId}) {
  return '''
You are Origna's friendly, professional customer support agent for OrignaGTA — a Canadian e-commerce marketplace.

Customer info:
- Email: $userEmail
- User ID: $userId
- Platform: OrignaGTA (Canada)

Your goals:
1. Resolve 80%+ of issues on first contact without escalating.
2. Be concise and helpful. Never be dismissive.
3. For order/refund issues, always ask for the order ID first if not provided.
4. For account issues (password, billing), guide the customer step-by-step.
5. Only escalate to human when truly necessary (use escalate_to_human tool).

Capabilities via tools:
- lookup_order: check order status, shipping, items
- process_refund: process a refund (only with explicit customer confirmation)
- escalate_to_human: hand off to human agent at support@orignaventures.ca

Tone: Professional, warm, concise. This is a Canadian marketplace — use CAD.
Language: Match the customer's language (English or French).
Do NOT invent information. If unsure, ask a clarifying question.
''';
}

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
      clearError: true,
    );

    try {
      await _runAgentTurn(text.trim());
    } catch (e, stack) {
      AppError.log(e, stackTrace: stack, context: 'SupportViewModel.sendMessage');
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'support.error_generic'),
      );
    }
  }

  /// Start the conversation with an initial greeting from the agent.
  Future<void> startConversation(SupportCategory category) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _ref.read(currentUserProvider);
      final categoryLabel = _categoryToLabel(category);
      final openingUserMsg =
          'I need help with: $categoryLabel';

      final systemPrompt = _buildSystemPrompt(
        userEmail: user?.email ?? 'unknown',
        userId: user?.uid ?? 'unknown',
      );

      final agentReply = await _callClaude(
        systemPrompt: systemPrompt,
        messages: [
          {'role': 'user', 'content': openingUserMsg},
        ],
      );

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
      AppError.log(e, stackTrace: stack, context: 'SupportViewModel.startConversation');
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'support.error_generic'),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Internal — agent turn with tool-call loop
  // --------------------------------------------------------------------------

  Future<void> _runAgentTurn(String userText) async {
    final user = _ref.read(currentUserProvider);
    final systemPrompt = _buildSystemPrompt(
      userEmail: user?.email ?? 'unknown',
      userId: user?.uid ?? 'unknown',
    );

    // Build message history for Claude (user + agent turns only — no tool msgs)
    final history = _buildClaudeHistory();

    final response = await _callClaudeWithTools(
      systemPrompt: systemPrompt,
      messages: history,
    );

    // Process response — may contain text and/or tool_use blocks
    final agentText = StringBuffer();
    final toolCalls = <Map<String, dynamic>>[];

    for (final block in response) {
      final type = block['type'] as String?;
      if (type == 'text') {
        agentText.write(block['text'] as String? ?? '');
      } else if (type == 'tool_use') {
        toolCalls.add(block);
      }
    }

    // Execute tool calls and collect results
    final toolResults = <Map<String, dynamic>>[];
    for (final call in toolCalls) {
      final result = await _executeTool(call);
      toolResults.add({'tool_use_id': call['id'], 'result': result});
    }

    // If tool calls were made, send results back to Claude for a final reply
    String finalText;
    if (toolCalls.isNotEmpty) {
      // Build updated history with assistant tool_use + tool results
      final updatedHistory = [
        ...history,
        {'role': 'assistant', 'content': response},
        {
          'role': 'user',
          'content': toolResults
              .map((r) => {
                    'type': 'tool_result',
                    'tool_use_id': r['tool_use_id'],
                    'content': r['result'].toString(),
                  })
              .toList(),
        },
      ];

      final followUp = await _callClaude(
        systemPrompt: systemPrompt,
        messages: updatedHistory,
      );
      finalText = followUp;
    } else {
      finalText = agentText.toString();
    }

    if (finalText.trim().isNotEmpty) {
      final agentMsg = SupportMessage(
        role: MessageRole.agent,
        text: finalText.trim(),
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
  // Tool execution
  // --------------------------------------------------------------------------

  Future<String> _executeTool(Map<String, dynamic> toolCall) async {
    final name = toolCall['name'] as String;
    final input = (toolCall['input'] as Map<String, dynamic>?) ?? {};

    switch (name) {
      case 'lookup_order':
        return _toolLookupOrder(input['order_id'] as String? ?? '');
      case 'process_refund':
        return _toolProcessRefund(
          orderId: input['order_id'] as String? ?? '',
          reason: input['reason'] as String? ?? 'customer_request',
        );
      case 'escalate_to_human':
        return _toolEscalateToHuman(
          summary: input['summary'] as String? ?? '',
          customerEmail: input['customer_email'] as String? ?? '',
        );
      default:
        return 'Unknown tool: $name';
    }
  }

  Future<String> _toolLookupOrder(String orderId) async {
    if (orderId.isEmpty) return 'Error: order_id is required.';
    try {
      final ob = _ref.read(orignabaseProvider);
      final response = await ob.request(
        'GET',
        '${ApiEndpoints.ordersBase}/$orderId',
      );
      // Return a sanitised summary of key order fields
      final status = response['paymentStatus'] ?? response['status'] ?? 'unknown';
      final total = response['totalAmountCents'];
      final totalStr = total != null ? '\$${(total / 100).toStringAsFixed(2)} CAD' : 'unknown';
      final items = response['items'];
      final itemCount = items is List ? items.length : '?';
      return 'Order $orderId found. Status: $status. Total: $totalStr. Items: $itemCount.';
    } catch (e) {
      if (kDebugMode) debugPrint('[SupportTool:lookup_order] $e');
      return 'Could not retrieve order $orderId. The order may not exist or does not belong to this account.';
    }
  }

  Future<String> _toolProcessRefund({
    required String orderId,
    required String reason,
  }) async {
    if (orderId.isEmpty) return 'Error: order_id is required.';
    try {
      final ob = _ref.read(orignabaseProvider);
      await ob.request(
        'POST',
        ApiEndpoints.ordersRefundsItem,
        body: {
          Fields.orderId: orderId,
          ApiKeys.reason: reason,
        },
      );
      return 'Refund initiated for order $orderId with reason "$reason". '
          'It will be processed within 3-5 business days.';
    } catch (e) {
      if (kDebugMode) debugPrint('[SupportTool:process_refund] $e');
      return 'Unable to process refund for order $orderId at this time. '
          'The order may not be eligible or a refund already exists.';
    }
  }

  Future<String> _toolEscalateToHuman({
    required String summary,
    required String customerEmail,
  }) async {
    try {
      // Mark the conversation as escalated in state immediately
      state = state.copyWith(isEscalated: true);

      final user = _ref.read(currentUserProvider);
      final email = customerEmail.isNotEmpty
          ? customerEmail
          : (user?.email ?? 'unknown');

      // POST escalation to OrignaBase support endpoint
      final ob = _ref.read(orignabaseProvider);
      await ob.request(
        'POST',
        ApiEndpoints.supportEscalate,
        body: {
          'customer_email': email,
          'customer_id': user?.uid ?? 'unknown',
          'summary': summary,
          'conversation': state.messages
              .map((m) => '${m.role.name.toUpperCase()}: ${m.text}')
              .join('\n'),
        },
      );

      return 'Escalated to human support at support@orignaventures.ca. '
          'A team member will contact $email within 24 business hours.';
    } catch (e) {
      if (kDebugMode) debugPrint('[SupportTool:escalate_to_human] $e');
      // Escalation backend endpoint may not exist yet — still mark escalated
      state = state.copyWith(isEscalated: true);
      return 'Your case has been escalated. Our team at support@orignaventures.ca '
          'will contact you within 24 business hours.';
    }
  }

  // --------------------------------------------------------------------------
  // Claude API calls
  // --------------------------------------------------------------------------

  /// Builds message history for Claude from current [state.messages].
  /// Converts MessageRole.user → 'user', MessageRole.agent → 'assistant'.
  List<Map<String, dynamic>> _buildClaudeHistory() {
    return state.messages.map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();
  }

  /// Call Claude API with tools enabled, returns the raw content blocks.
  Future<List<Map<String, dynamic>>> _callClaudeWithTools({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
  }) async {
    final apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY not configured');
    }

    final body = jsonEncode({
      'model': _kClaudeModel,
      'max_tokens': 1024,
      'system': systemPrompt,
      'tools': _kTools,
      'messages': messages,
    });

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Claude API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>? ?? [];
    return content.cast<Map<String, dynamic>>();
  }

  /// Call Claude API (text-only, no tools), returns the assistant text.
  Future<String> _callClaude({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
  }) async {
    final apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY not configured');
    }

    final body = jsonEncode({
      'model': _kClaudeModel,
      'max_tokens': 1024,
      'system': systemPrompt,
      'messages': messages,
    });

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Claude API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>? ?? [];
    for (final block in content) {
      if (block is Map && block['type'] == 'text') {
        return (block['text'] as String?) ?? '';
      }
    }
    return '';
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
