import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/features/chat/chat_provider.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:orignabase/orignabase.dart';

@GenerateNiceMocks([MockSpec<ChatRepository>()])
import 'chat_coverage_test.mocks.dart';

void main() {
  group('ChatState', () {
    test('default state has all expected defaults', () {
      const state = ChatState();
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.chatId, isNull);
      expect(state.isOwnProduct, isFalse);
      expect(state.isPremiumRequired, isFalse);
    });

    test('copyWith preserves non-updated fields', () {
      const state = ChatState(
        isLoading: true,
        chatId: 'chat_1',
        isOwnProduct: true,
      );
      final updated = state.copyWith(isLoading: false);
      expect(updated.isLoading, isFalse);
      expect(updated.chatId, 'chat_1');
      expect(updated.isOwnProduct, isTrue);
    });

    test('copyWith clears error with clearError flag', () {
      const state = ChatState(errorMessage: 'error');
      final updated = state.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('copyWith sets isPremiumRequired', () {
      const state = ChatState();
      final updated = state.copyWith(isPremiumRequired: true);
      expect(updated.isPremiumRequired, isTrue);
    });

    test('copyWith sets errorMessage', () {
      const state = ChatState();
      final updated = state.copyWith(errorMessage: 'test error');
      expect(updated.errorMessage, 'test error');
    });

    test('copyWith sets chatId', () {
      const state = ChatState();
      final updated = state.copyWith(chatId: 'new_chat');
      expect(updated.chatId, 'new_chat');
    });

    test('copyWith sets isOwnProduct', () {
      const state = ChatState();
      final updated = state.copyWith(isOwnProduct: true);
      expect(updated.isOwnProduct, isTrue);
    });
  });

  group('ChatMessage data class', () {
    test('constructs with all fields', () {
      final msg = ChatMessage(
        id: 'm1',
        senderId: 'u1',
        senderDisplayName: 'Alice',
        text: 'Hello!',
        createdAt: DateTime(2026, 3, 1),
        isRead: false,
        deleted: false,
      );
      expect(msg.id, 'm1');
      expect(msg.senderId, 'u1');
      expect(msg.senderDisplayName, 'Alice');
      expect(msg.text, 'Hello!');
      expect(msg.isRead, isFalse);
      expect(msg.deleted, isFalse);
    });

    test('deleted defaults to false', () {
      final msg = ChatMessage(
        id: 'm1',
        senderId: 'u1',
        senderDisplayName: 'Alice',
        text: 'Hi',
        createdAt: DateTime.now(),
        isRead: true,
      );
      expect(msg.deleted, isFalse);
    });
  });

  group('ChatThread data class', () {
    test('constructs with required fields', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'Widget',
        buyerId: 'u1',
        sellerId: 'u2',
      );
      expect(thread.chatId, 'c1');
      expect(thread.productId, 'p1');
      expect(thread.productTitle, 'Widget');
      expect(thread.buyerId, 'u1');
      expect(thread.sellerId, 'u2');
      expect(thread.buyerUnreadCount, 0);
      expect(thread.sellerUnreadCount, 0);
    });

    test('optional fields default to null/zero', () {
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'Widget',
        buyerId: 'u1',
        sellerId: 'u2',
      );
      expect(thread.productImageUrl, isNull);
      expect(thread.lastMessage, isNull);
      expect(thread.lastMessageAt, isNull);
    });

    test('optional fields are set when provided', () {
      final now = DateTime(2026, 3, 15);
      final thread = ChatThread(
        chatId: 'c1',
        productId: 'p1',
        productTitle: 'Widget',
        productImageUrl: 'https://img.com/1.jpg',
        buyerId: 'u1',
        sellerId: 'u2',
        lastMessage: 'Hey!',
        lastMessageAt: now,
        buyerUnreadCount: 3,
        sellerUnreadCount: 1,
      );
      expect(thread.productImageUrl, 'https://img.com/1.jpg');
      expect(thread.lastMessage, 'Hey!');
      expect(thread.lastMessageAt, now);
      expect(thread.buyerUnreadCount, 3);
      expect(thread.sellerUnreadCount, 1);
    });
  });

  group('ChatViewModel - openChat', () {
    late MockChatRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockChatRepository();
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(status: 'active', isPremium: true),
            ),
          ),
        ],
      );
    });

    test('openChat sets isPremiumRequired when not premium', () async {
      final nonPremiumContainer = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(status: 'active', isPremium: false),
            ),
          ),
        ],
      );
      addTearDown(nonPremiumContainer.dispose);

      final notifier = nonPremiumContainer.read(
        chatViewModelProvider('p1').notifier,
      );
      await notifier.openChat();

      final state = nonPremiumContainer.read(chatViewModelProvider('p1'));
      expect(state.isPremiumRequired, isTrue);
      expect(state.chatId, isNull);
    });

    test('openChat sets isPremiumRequired when subscription is null', () async {
      final nullSubContainer = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(nullSubContainer.dispose);

      final notifier = nullSubContainer.read(
        chatViewModelProvider('p1').notifier,
      );
      await notifier.openChat();

      final state = nullSubContainer.read(chatViewModelProvider('p1'));
      expect(state.isPremiumRequired, isTrue);
    });

    test('openChat does not re-open if already has chatId', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();
      await notifier.openChat(); // second call should be no-op

      verify(mockRepo.getOrCreateChat('p1')).called(1);
    });

    test('openChat sets isOwnProduct when backend says so', () async {
      when(
        mockRepo.getOrCreateChat('p1'),
      ).thenThrow(OrignaBaseException('Cannot chat with yourself'));

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.isOwnProduct, isTrue);
    });

    test('openChat sets isPremiumRequired on premium error', () async {
      when(
        mockRepo.getOrCreateChat('p1'),
      ).thenThrow(OrignaBaseException('Premium membership required'));

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.isPremiumRequired, isTrue);
    });

    test('openChat sets generic error on other exception', () async {
      when(
        mockRepo.getOrCreateChat('p1'),
      ).thenThrow(OrignaBaseException('Some other error'));

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.errorMessage, 'Some other error');
    });

    test('openChat sets isLoading during call', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.isLoading, isFalse);
      expect(state.chatId, 'chat_123');
    });
  });

  group('ChatViewModel - sendMessage', () {
    late MockChatRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockChatRepository();
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(status: 'active', isPremium: true),
            ),
          ),
        ],
      );
    });

    test('sendMessage does nothing if chatId is null', () async {
      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.sendMessage('Hello');

      verifyNever(mockRepo.sendMessage(any, any));
    });

    test('sendMessage does nothing if text is empty', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();
      await notifier.sendMessage('');

      verifyNever(mockRepo.sendMessage(any, any));
    });

    test('sendMessage does nothing if text is whitespace', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();
      await notifier.sendMessage('   ');

      verifyNever(mockRepo.sendMessage(any, any));
    });

    test('sendMessage rejects messages exceeding max length', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      final longText = 'a' * 1001;
      await notifier.sendMessage(longText);

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.errorMessage, contains('maximum length'));
    });

    test('sendMessage handles OrignaBaseException with rate limit', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      when(
        mockRepo.sendMessage('chat_123', 'Hello world'),
      ).thenThrow(OrignaBaseException('rate limit exhausted'));

      await notifier.sendMessage('Hello world');

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.errorMessage, contains('slow down'));
    });

    test('sendMessage handles OrignaBaseException with premium', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      when(
        mockRepo.sendMessage('chat_123', 'Hello world'),
      ).thenThrow(OrignaBaseException('premium required'));

      await notifier.sendMessage('Hello world');

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.errorMessage, contains('Premium'));
    });

    test('sendMessage handles generic exception', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();

      when(
        mockRepo.sendMessage('chat_123', 'Hello world'),
      ).thenThrow(Exception('network error'));

      await notifier.sendMessage('Hello world');

      final state = container.read(chatViewModelProvider('p1'));
      expect(state.errorMessage, isNotNull);
    });
  });

  group('ChatViewModel - markRead', () {
    late MockChatRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockChatRepository();
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(
              const SubscriptionInfo(status: 'active', isPremium: true),
            ),
          ),
        ],
      );
    });

    test('markRead does nothing if chatId is null', () async {
      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.markRead();
      verifyNever(mockRepo.markRead(any));
    });

    test('markRead calls repository when chatId exists', () async {
      when(mockRepo.getOrCreateChat('p1')).thenAnswer((_) async => 'chat_123');

      final notifier = container.read(chatViewModelProvider('p1').notifier);
      await notifier.openChat();
      await notifier.markRead();

      verify(mockRepo.markRead('chat_123')).called(1);
    });
  });
}
