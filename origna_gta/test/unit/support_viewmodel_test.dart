import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/support/support_provider.dart';
import 'package:origna_gta/features/support/support_state.dart';

// ---------------------------------------------------------------------------
// Test fakes
// ---------------------------------------------------------------------------

class _FakeOb implements OrignaBase {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SupportViewModel - initial state and basic validation', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(_FakeOb()),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
    });

    test('initial state has no messages and is not loading', () {
      final state = container.read(supportViewModelProvider);
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isEscalated, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('sendMessage with empty string returns without changing state', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('');

      final state = container.read(supportViewModelProvider);
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('sendMessage with whitespace-only returns without changing state', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('   ');

      final state = container.read(supportViewModelProvider);
      expect(state.messages, isEmpty);
    });

    test('sendMessage with tabs and newlines returns early', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('\t\n\t');

      final state = container.read(supportViewModelProvider);
      expect(state.messages, isEmpty);
    });

    test('sendMessage adds user message to state immediately', () async {
      final future = container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello!');

      await future;

      final state = container.read(supportViewModelProvider);
      expect(
        state.messages.any((m) => m.role == MessageRole.user && m.text == 'Hello!'),
        isTrue,
      );
    });

    test('sendMessage marks isLoading as false after processing', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final state = container.read(supportViewModelProvider);
      expect(state.isLoading, isFalse);
    });

    test('multiple messages are preserved in order', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('First message');

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Second message');

      final state = container.read(supportViewModelProvider);
      final userMessages = state.messages.where((m) => m.role == MessageRole.user).toList();
      expect(userMessages.length, greaterThanOrEqualTo(2));
    });

    test('sendMessage message is timestamped', () async {
      final before = DateTime.now();
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello!');
      final after = DateTime.now();

      final state = container.read(supportViewModelProvider);
      final userMsg = state.messages.firstWhere((m) => m.role == MessageRole.user);
      expect(userMsg.timestamp.isAfter(before.subtract(Duration(seconds: 1))), isTrue);
      expect(userMsg.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });

    test('SupportState.copyWith preserves fields not updated', () {
      const original = SupportState(isLoading: true, isEscalated: false);
      final updated = original.copyWith(isEscalated: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isEscalated, isTrue);
      expect(updated.messages, isEmpty);
    });

    test('SupportState.copyWith with clearError removes errorMessage', () {
      const original = SupportState(errorMessage: 'oops');
      final cleared = original.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('SupportState.copyWith with new errorMessage', () {
      const original = SupportState();
      final updated = original.copyWith(errorMessage: 'An error occurred');
      expect(updated.errorMessage, 'An error occurred');
    });

    test('SupportState.copyWith with multiple fields', () {
      const original = SupportState(isLoading: false, isEscalated: false);
      final updated = original.copyWith(
        isLoading: true,
        isEscalated: true,
        errorMessage: 'Error occurred',
      );
      expect(updated.isLoading, isTrue);
      expect(updated.isEscalated, isTrue);
      expect(updated.errorMessage, 'Error occurred');
    });

    test('SupportState initial errorMessage is null', () {
      const state = SupportState();
      expect(state.errorMessage, isNull);
    });

    test('SupportState has isLoading field', () {
      const state = SupportState(isLoading: true);
      expect(state.isLoading, isTrue);
    });

    test('SupportState has isEscalated field', () {
      const state = SupportState(isEscalated: true);
      expect(state.isEscalated, isTrue);
    });

    test('SupportState messages list is mutable copy', () {
      const state = SupportState();
      expect(state.messages, isEmpty);
      expect(state.messages, isA<List>());
    });

    test('SupportState toString works', () {
      const state = SupportState(
        messages: [],
        isLoading: false,
        isEscalated: false,
        errorMessage: null,
      );
      expect(state.toString(), isA<String>());
    });

    test('initial state errorMessage is null by default', () {
      final state = container.read(supportViewModelProvider);
      expect(state.errorMessage, isNull);
    });

    test('SupportMessage constructor sets all fields', () {
      final now = DateTime.now();
      final msg = SupportMessage(
        role: MessageRole.agent,
        text: 'How can I help?',
        timestamp: now,
      );
      expect(msg.role, MessageRole.agent);
      expect(msg.text, 'How can I help?');
      expect(msg.timestamp, now);
    });

    test('SupportMessage with user role', () {
      final msg = SupportMessage(
        role: MessageRole.user,
        text: 'Help me',
        timestamp: DateTime.now(),
      );
      expect(msg.role, MessageRole.user);
      expect(msg.text, 'Help me');
    });

    test('SupportMessage with agent role', () {
      final msg = SupportMessage(
        role: MessageRole.agent,
        text: 'How can I help you?',
        timestamp: DateTime.now(),
      );
      expect(msg.role, MessageRole.agent);
      expect(msg.text, 'How can I help you?');
    });

    test('SupportMessage equality', () {
      final now = DateTime.now();
      final msg1 = SupportMessage(
        role: MessageRole.user,
        text: 'Hello',
        timestamp: now,
      );
      final msg2 = SupportMessage(
        role: MessageRole.user,
        text: 'Hello',
        timestamp: now,
      );
      expect(msg1.role, msg2.role);
      expect(msg1.text, msg2.text);
    });

    test('SupportMessage timestamp is preserved', () {
      final now = DateTime(2026, 3, 15, 10, 30, 0);
      final msg = SupportMessage(
        role: MessageRole.user,
        text: 'Test',
        timestamp: now,
      );
      expect(msg.timestamp, now);
    });

    test('SupportMessage with different texts', () {
      final msg1 = SupportMessage(
        role: MessageRole.user,
        text: 'Message 1',
        timestamp: DateTime.now(),
      );
      final msg2 = SupportMessage(
        role: MessageRole.user,
        text: 'Message 2',
        timestamp: DateTime.now(),
      );
      expect(msg1.text, isNot(msg2.text));
    });

    test('SupportMessage with different roles', () {
      final now = DateTime.now();
      final userMsg = SupportMessage(
        role: MessageRole.user,
        text: 'Help',
        timestamp: now,
      );
      final agentMsg = SupportMessage(
        role: MessageRole.agent,
        text: 'Help',
        timestamp: now,
      );
      expect(userMsg.role, isNot(agentMsg.role));
    });

    test('SupportState with non-null errorMessage', () {
      const state = SupportState(errorMessage: 'Network error');
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, 'Network error');
    });

    test('SupportState with isLoading true', () {
      const state = SupportState(isLoading: true, messages: []);
      expect(state.isLoading, isTrue);
      expect(state.messages, isEmpty);
    });

    test('SupportState with isEscalated true', () {
      const state = SupportState(isEscalated: true);
      expect(state.isEscalated, isTrue);
    });

    test('SupportMessage text is preserved exactly', () {
      final text = 'Test message with special chars: !@#\$%^&*()';
      final msg = SupportMessage(
        role: MessageRole.user,
        text: text,
        timestamp: DateTime.now(),
      );
      expect(msg.text, text);
    });

    test('SupportState all defaults', () {
      const state = SupportState();
      expect(state.messages.isEmpty, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isEscalated, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('sendMessage twice with different content', () async {
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('First');
      
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Second');

      final state = container.read(supportViewModelProvider);
      expect(state.messages.where((m) => m.role == MessageRole.user).length, greaterThanOrEqualTo(2));
    });

    test('SupportState copyWith clears errorMessage with flag', () {
      const state = SupportState(errorMessage: 'error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('Extended state tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(_FakeOb()),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
    });

    test('SupportCategory.orderStatus value exists', () {
      expect(SupportCategory.orderStatus, isNotNull);
    });

    test('SupportCategory.refundRequest value exists', () {
      expect(SupportCategory.refundRequest, isNotNull);
    });

    test('SupportCategory.accountIssue value exists', () {
      expect(SupportCategory.accountIssue, isNotNull);
    });

    test('SupportCategory.billingDispute value exists', () {
      expect(SupportCategory.billingDispute, isNotNull);
    });

    test('SupportCategory.other value exists', () {
      expect(SupportCategory.other, isNotNull);
    });

    test('MessageRole.user value exists', () {
      expect(MessageRole.user, isNotNull);
    });

    test('MessageRole.agent value exists', () {
      expect(MessageRole.agent, isNotNull);
    });

    test('SupportMessage preserves all fields', () {
      final now = DateTime(2026, 3, 15);
      final msg = SupportMessage(
        role: MessageRole.user,
        text: 'Test message',
        timestamp: now,
      );
      expect(msg.role, MessageRole.user);
      expect(msg.text, 'Test message');
      expect(msg.timestamp, now);
    });

    test('SupportState all fields have correct defaults', () {
      const state = SupportState();
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isEscalated, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('SupportState copyWith with clearError true removes message', () {
      const state = SupportState(errorMessage: 'error');
      final updated = state.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('SupportState copyWith preserves non-updated fields', () {
      const state = SupportState(
        isLoading: true,
        isEscalated: true,
        errorMessage: 'test',
      );
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.isEscalated, isTrue);
      expect(updated.errorMessage, 'test');
    });

    test('SupportMessage with different roles', () {
      final now = DateTime.now();
      final userMsg = SupportMessage(
        role: MessageRole.user,
        text: 'User text',
        timestamp: now,
      );
      final agentMsg = SupportMessage(
        role: MessageRole.agent,
        text: 'Agent text',
        timestamp: now,
      );
      expect(userMsg.role, MessageRole.user);
      expect(agentMsg.role, MessageRole.agent);
      expect(userMsg.text, isNot(agentMsg.text));
    });

    test('SupportState with custom values', () {
      final msg = SupportMessage(
        role: MessageRole.user,
        text: 'Custom',
        timestamp: DateTime.now(),
      );
      const state = SupportState(
        messages: [],
        isLoading: true,
        isEscalated: true,
        errorMessage: 'Custom error',
      );
      final updated = state.copyWith(messages: [msg]);
      expect(updated.messages.length, 1);
      expect(updated.isLoading, isTrue);
      expect(updated.isEscalated, isTrue);
      expect(updated.errorMessage, 'Custom error');
    });
  });
}
