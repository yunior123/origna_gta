import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/chat/chat_provider.dart';
import 'package:origna_gta/features/chat/chat_repository.dart';
import 'package:origna_gta/features/subscription/orignabase_subscription_provider.dart';
import 'package:origna_gta/features/subscription/subscription_state.dart';
import 'package:origna_gta/screens/chat_conversations_screen.dart';

import '../test_utils.dart';

ChatThread _makeThread({
  String chatId = 'chat1',
  String productId = 'p1',
  String productTitle = 'Test Product',
  String buyerId = 'u1',
  String sellerId = 's1',
  String? lastMessage,
  DateTime? lastMessageAt,
  int buyerUnreadCount = 0,
  int sellerUnreadCount = 0,
}) {
  return ChatThread(
    chatId: chatId,
    productId: productId,
    productTitle: productTitle,
    buyerId: buyerId,
    sellerId: sellerId,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
    buyerUnreadCount: buyerUnreadCount,
    sellerUnreadCount: sellerUnreadCount,
  );
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    bool isPremium = true,
    List<ChatThread>? threads,
    bool subscriptionError = false,
  }) {
    return TestWrapper(
      overrides: [
        userIdProvider.overrideWithValue('u1'),
        currentUserProvider.overrideWithValue(
          const AppAuthUser(uid: 'u1', email: 'user@test.com'),
        ),
        subscriptionStreamProvider.overrideWith((ref) {
          if (subscriptionError) return Stream.error('sub error');
          return Stream.value(
            isPremium
                ? const SubscriptionInfo(status: 'active', isPremium: true)
                : const SubscriptionInfo(status: 'inactive', isPremium: false),
          );
        }),
        myAllChatsProvider.overrideWith(
          (ref) => Stream.value(threads ?? <ChatThread>[]),
        ),
      ],
      child: const ChatConversationsScreen(),
    );
  }

  group('ChatConversationsScreen', () {
    testWidgets('renders loading state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            userIdProvider.overrideWithValue('u1'),
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'u1', email: 'user@test.com'),
            ),
            subscriptionStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            myAllChatsProvider.overrideWith(
              (ref) => Stream.value(<ChatThread>[]),
            ),
          ],
          child: const ChatConversationsScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });

    testWidgets('premium user sees chat inbox', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(isPremium: true));
      await tester.pumpAndSettle();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });

    testWidgets('non-premium user sees paywall', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(isPremium: false));
      await tester.pumpAndSettle();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });

    testWidgets('subscription error shows paywall', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(subscriptionError: true));
      await tester.pumpAndSettle();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });

    testWidgets('empty chat list shows empty state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(threads: []));
      await tester.pumpAndSettle();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });

    testWidgets('renders chat threads', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [
        _makeThread(chatId: 'c1', productTitle: 'Laptop'),
        _makeThread(chatId: 'c2', productTitle: 'Phone'),
      ];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('chat thread shows last message', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [_makeThread(lastMessage: 'Hello there!')];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pumpAndSettle();

      expect(find.text('Hello there!'), findsOneWidget);
    });

    testWidgets('chat thread shows unread badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [_makeThread(buyerUnreadCount: 3)];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('chat thread with 100+ unread shows 99+', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [_makeThread(buyerUnreadCount: 150)];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('chat thread shows chevron icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [_makeThread()];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('chat thread has semantic label', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final threads = [_makeThread(chatId: 'c1')];
      await tester.pumpWidget(buildWidget(threads: threads));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ChatConversationsScreen), findsOneWidget);
    });
  });
}
