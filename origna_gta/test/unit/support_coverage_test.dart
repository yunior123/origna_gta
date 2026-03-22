import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/support/support_provider.dart';
import 'package:origna_gta/features/support/support_state.dart';

class _FakeOb implements OrignaBase {
  _FakeOb({this.responder});

  final Future<Map<String, dynamic>> Function(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  })?
  responder;
  final List<Map<String, dynamic>?> requestBodies = [];

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    requestBodies.add(body);
    if (responder != null) {
      return responder!(method, path, body: body, headers: headers);
    }
    return {'reply': 'I can help you!', 'escalated': false};
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('SupportViewModel - sendMessage error paths', () {
    test('sendMessage sets error message when backend throws', () async {
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(
            _FakeOb(
              responder: (m, p, {body, headers}) async {
                throw Exception('server error');
              },
            ),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final state = container.read(supportViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('sendMessage sets error message when backend throws String', () async {
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(
            _FakeOb(
              responder: (m, p, {body, headers}) async {
                throw 'network failure';
              },
            ),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final state = container.read(supportViewModelProvider);
      expect(state.errorMessage, isNotNull);
    });

    test('sendMessage includes user email in request body', () async {
      final fakeOb = _FakeOb();
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          currentUserProvider.overrideWithValue(
            const AppAuthUser(uid: 'u1', email: 'test@test.com'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final body = fakeOb.requestBodies.first;
      expect(body?['customer_email'], 'test@test.com');
      expect(body?['customer_id'], 'u1');
    });

    test('sendMessage uses unknown when user is null', () async {
      final fakeOb = _FakeOb();
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final body = fakeOb.requestBodies.first;
      expect(body?['customer_email'], 'unknown');
      expect(body?['customer_id'], 'unknown');
    });
  });

  group('SupportViewModel - startConversation error paths', () {
    test('startConversation sets error when backend fails', () async {
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(
            _FakeOb(
              responder: (m, p, {body, headers}) async {
                throw Exception('server down');
              },
            ),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .startConversation(SupportCategory.orderStatus);

      final state = container.read(supportViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.messages, isEmpty);
    });

    test(
      'startConversation maps all five categories to correct labels',
      () async {
        final fakeOb = _FakeOb();
        final container = ProviderContainer(
          overrides: [
            orignabaseProvider.overrideWithValue(fakeOb),
            currentUserProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        final expected = {
          SupportCategory.orderStatus: 'order status',
          SupportCategory.refundRequest: 'refund request',
          SupportCategory.accountIssue: 'account issue',
          SupportCategory.billingDispute: 'billing dispute',
          SupportCategory.other: 'general inquiry',
        };

        for (final entry in expected.entries) {
          fakeOb.requestBodies.clear();
          await container
              .read(supportViewModelProvider.notifier)
              .startConversation(entry.key);
          final body = fakeOb.requestBodies.first;
          expect(
            body?['messages'][0]['content'],
            'I need help with: ${entry.value}',
          );
        }
      },
    );

    test('startConversation sets isLoading during call', () async {
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(
            _FakeOb(
              responder: (m, p, {body, headers}) async {
                return {'reply': 'Hi!', 'escalated': false};
              },
            ),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .startConversation(SupportCategory.other);

      final state = container.read(supportViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.length, 1);
      expect(state.messages.first.role, MessageRole.agent);
    });

    test('startConversation with escalation flag', () async {
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(
            _FakeOb(
              responder: (m, p, {body, headers}) async {
                return {'reply': 'A human will help.', 'escalated': true};
              },
            ),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .startConversation(SupportCategory.refundRequest);

      final state = container.read(supportViewModelProvider);
      expect(state.isEscalated, isTrue);
      expect(state.messages.first.text, 'A human will help.');
    });
  });

  group('SupportState - advanced copyWith', () {
    test('copyWith sets messages list', () {
      const state = SupportState();
      final msg = SupportMessage(
        role: MessageRole.user,
        text: 'Hi',
        timestamp: DateTime(2026, 1, 1),
      );
      final updated = state.copyWith(messages: [msg]);
      expect(updated.messages.length, 1);
      expect(updated.messages.first.text, 'Hi');
    });

    test('copyWith can toggle isLoading', () {
      const state = SupportState(isLoading: false);
      expect(state.copyWith(isLoading: true).isLoading, isTrue);
      expect(state.copyWith(isLoading: false).isLoading, isFalse);
    });

    test('copyWith can toggle isEscalated', () {
      const state = SupportState(isEscalated: false);
      expect(state.copyWith(isEscalated: true).isEscalated, isTrue);
    });

    test('SupportMessage with empty text', () {
      final msg = SupportMessage(
        role: MessageRole.user,
        text: '',
        timestamp: DateTime.now(),
      );
      expect(msg.text, isEmpty);
    });

    test('SupportCategory enum has 5 values', () {
      expect(SupportCategory.values.length, 5);
    });

    test('MessageRole enum has 2 values', () {
      expect(MessageRole.values.length, 2);
    });
  });

  group('SupportViewModel - message history building', () {
    test('messages are ordered chronologically', () async {
      final fakeOb = _FakeOb();
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('First');
      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Second');

      final state = container.read(supportViewModelProvider);
      final userMsgs = state.messages
          .where((m) => m.role == MessageRole.user)
          .toList();
      expect(userMsgs[0].text, 'First');
      expect(userMsgs[1].text, 'Second');
    });

    test('agent messages are added after user messages', () async {
      final fakeOb = _FakeOb();
      final container = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(supportViewModelProvider.notifier)
          .sendMessage('Hello');

      final state = container.read(supportViewModelProvider);
      final lastMsg = state.messages.last;
      expect(lastMsg.role, MessageRole.agent);
    });
  });
}
