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
  group('SupportViewModel — initial state and basic validation', () {
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

    test('sendMessage adds user message to state immediately', () async {
      // We expect the message to be added even if the API call fails
      final future = container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello!');

      // Message should be in state before the API round-trip completes
      // (allow some async processing)
      await future;

      final state = container.read(supportViewModelProvider);
      // At least the user message should have been added
      expect(
        state.messages.any((m) => m.role == MessageRole.user && m.text == 'Hello!'),
        isTrue,
      );
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
  });
}
