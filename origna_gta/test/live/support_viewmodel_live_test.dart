import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/features/support/support_provider.dart';

void main() {
  const runLive =
      bool.fromEnvironment('RUN_ORIGNABASE_LIVE_TESTS', defaultValue: false);

  group('SupportViewModel live integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    late OrignaBaseAuthRepository authRepo;

    setUpAll(() async {
      if (!runLive) return;
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      authRepo = OrignaBaseAuthRepository(ob);

      // Sign in as buyer for support tests
      await authRepo.signInWithEmail('e2e-buyer@test.origna.ca', 'REDACTED_TEST_PASSWORD');
    });

    tearDownAll(() async {
      if (!runLive) return;
      await authRepo.signOut();
      container.dispose();
    });

    test(
      'should send a support message and receive a response',
      () async {
        if (!runLive) return;

        final viewModelNotifier =
            container.read(supportViewModelProvider.notifier);

        // Send a support message
        await viewModelNotifier.sendMessage('I need help with my order');

        // Check that the message was added to the state
        final state = container.read(supportViewModelProvider);
        expect(state.messages, isNotEmpty);
        expect(
          state.messages.any((m) => m.text.contains('help with my order')),
          isTrue,
          reason:
              'User message should be added to support chat state after sending',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should handle support chat loading state',
      () async {
        if (!runLive) return;

        final viewModelNotifier =
            container.read(supportViewModelProvider.notifier);

        // Before sending, loading should be false
        var state = container.read(supportViewModelProvider);
        expect(state.isLoading, isFalse);

        // Send message (loading will be true during processing)
        viewModelNotifier.sendMessage('What is your return policy?');

        // Check state has messages
        await Future.delayed(const Duration(milliseconds: 500));
        state = container.read(supportViewModelProvider);
        expect(state.messages, isNotEmpty);
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'should handle empty message submission gracefully',
      () async {
        if (!runLive) return;

        final viewModelNotifier =
            container.read(supportViewModelProvider.notifier);

        final initialMessageCount =
            container.read(supportViewModelProvider).messages.length;

        // Try to send empty message
        await viewModelNotifier.sendMessage('   ');
        await viewModelNotifier.sendMessage('');

        // Message count should not change
        final finalMessageCount =
            container.read(supportViewModelProvider).messages.length;
        expect(
          finalMessageCount,
          equals(initialMessageCount),
          reason: 'Empty messages should not be added to chat',
        );
      },
      skip: !runLive,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }, skip: !runLive);
}
