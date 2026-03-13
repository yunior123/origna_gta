import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/chat/chat_provider.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orignabase/orignabase.dart';

import 'package:origna_gta/features/subscription/subscription_provider.dart';

@GenerateNiceMocks([MockSpec<ChatRepository>()])
import 'chat_viewmodel_test.mocks.dart';

void main() {
  late MockChatRepository mockRepo;
  late ProviderContainer container;
  const productId = 'prod_123';

  setUp(() {
    mockRepo = MockChatRepository();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockRepo),
        subscriptionStreamProvider.overrideWith((ref) => Stream.value(
          const SubscriptionInfo(status: 'active', isPremium: true),
        )),
      ],
    );
  });

  group('ChatViewModel', () {
    test('openChat sets chatId on success', () async {
      when(mockRepo.getOrCreateChat(productId)).thenAnswer((_) async => 'chat_456');
      
      final viewModel = container.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      expect(container.read(chatViewModelProvider(productId)).chatId, 'chat_456');
      expect(container.read(chatViewModelProvider(productId)).isLoading, isFalse);
    });

    test('openChat sets isPremiumRequired when not premium', () async {
      // Re-create container with non-premium override
      final nonPremiumContainer = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith((ref) => Stream.value(
            const SubscriptionInfo(status: 'inactive', isPremium: false),
          )),
        ],
      );
      
      final viewModel = nonPremiumContainer.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      expect(nonPremiumContainer.read(chatViewModelProvider(productId)).isPremiumRequired, isTrue);
      expect(nonPremiumContainer.read(chatViewModelProvider(productId)).chatId, isNull);
      verifyNever(mockRepo.getOrCreateChat(any));
    });

    test('openChat sets isOwnProduct true on self-chat error', () async {
      when(mockRepo.getOrCreateChat(productId)).thenThrow(
        OrignaBaseException('cannot chat with yourself', statusCode: 403),
      );
      
      final viewModel = container.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      expect(container.read(chatViewModelProvider(productId)).isOwnProduct, isTrue);
      expect(container.read(chatViewModelProvider(productId)).errorMessage, isNull);
    });

    test('sendMessage calls repository with trimmed text', () async {
      when(mockRepo.getOrCreateChat(productId)).thenAnswer((_) async => 'chat_456');
      final viewModel = container.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      await viewModel.sendMessage('  Hello World  ');

      verify(mockRepo.sendMessage('chat_456', 'Hello World')).called(1);
    });

    test('sendMessage validates min length', () async {
      when(mockRepo.getOrCreateChat(productId)).thenAnswer((_) async => 'chat_456');
      final viewModel = container.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      await viewModel.sendMessage('a'); // Assuming min is > 1

      expect(container.read(chatViewModelProvider(productId)).errorMessage, contains('too short'));
      verifyNever(mockRepo.sendMessage(any, any));
    });

    test('markRead calls repository', () async {
      when(mockRepo.getOrCreateChat(productId)).thenAnswer((_) async => 'chat_456');
      final viewModel = container.read(chatViewModelProvider(productId).notifier);
      await viewModel.openChat();

      await viewModel.markRead();

      verify(mockRepo.markRead('chat_456')).called(1);
    });
  });
}
