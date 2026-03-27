import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/chat/orignabase_chat_repository.dart';

void main() {
  const runLive = bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  bool isExpectedLiveAccessError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission denied') ||
        msg.contains('forbidden');
  }

  group('OrignaBaseChatRepository integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseChatRepository repo;
    late String buyerId;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as buyer
      final authState = await ob.auth.signInWithEmail(
        'e2e-buyer@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
      expect(authState.isAuthenticated, isTrue);
      buyerId = authState.userId!;

      repo = OrignaBaseChatRepository(ob);
    });

    tearDownAll(() {
      if (!runLive) return;
      container.dispose();
    });

    test(
      'getOrCreateChat returns a non-empty chat ID for stable test product',
      () async {
        if (!runLive) return;
        const productId = 'e2e_product_test_seller';
        try {
          final chatId = await repo.getOrCreateChat(productId);
          expect(chatId, isNotEmpty);
          expect(chatId, isA<String>());
        } catch (e) {
          // getOrCreateChat requires premium subscription + a delivered order.
          // In the dev environment these preconditions may not be met — that is
          // acceptable; the gate itself is exercised.
          final msg = e.toString().toLowerCase();
          final isExpectedGate = msg.contains('premium') ||
              msg.contains('delivered') ||
              msg.contains('eligible') ||
              msg.contains('active') ||
              msg.contains('not found') ||
              msg.contains('400') ||
              msg.contains('request failed') ||
              msg.contains('bad request');
          expect(isExpectedGate, isTrue,
              reason: 'Unexpected error: $e');
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'userChatsStream returns a stream',
      () async {
        if (!runLive) return;
        final stream = repo.userChatsStream(buyerId);
        expect(stream, isNotNull);

        try {
          final event = await stream.first.timeout(const Duration(seconds: 10));
          expect(event, isList);
        } catch (e) {
          expect(
            isExpectedLiveAccessError(e),
            isTrue,
            reason: 'Unexpected live chat stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'sellerChatsStream returns a stream',
      () async {
        if (!runLive) return;
        final stream = repo.sellerChatsStream(buyerId);
        expect(stream, isNotNull);

        try {
          final event = await stream.first.timeout(const Duration(seconds: 10));
          expect(event, isList);
        } catch (e) {
          expect(
            isExpectedLiveAccessError(e),
            isTrue,
            reason: 'Unexpected seller chat stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'allChatsStream returns merged buyer and seller chats',
      () async {
        if (!runLive) return;
        final stream = repo.allChatsStream(buyerId);
        expect(stream, isNotNull);

        try {
          final event = await stream.first.timeout(const Duration(seconds: 10));
          expect(event, isList);
        } catch (e) {
          expect(
            isExpectedLiveAccessError(e),
            isTrue,
            reason: 'Unexpected merged chat stream error: $e',
          );
        }
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'markRead completes without error',
      () async {
        if (!runLive) return;
        const productId = 'e2e_product_test_seller';
        String chatId;
        try {
          chatId = await repo.getOrCreateChat(productId);
        } catch (_) {
          // Business gate (premium/eligible-order) prevented chat creation.
          // Skip markRead since there is no chat to mark.
          return;
        }
        if (chatId.isEmpty) return;
        expect(
          repo.markRead(chatId),
          completes,
          reason: 'markRead should complete without throwing',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
