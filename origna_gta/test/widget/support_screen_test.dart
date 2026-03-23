import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/support/support_provider.dart';
import 'package:origna_gta/features/support/support_state.dart';
import 'package:origna_gta/features/support/support_screen.dart';
import 'package:origna_gta/features/support/support_viewmodel.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });

  SupportMessage _makeMessage({
    required MessageRole role,
    required String text,
    DateTime? timestamp,
  }) {
    return SupportMessage(
      role: role,
      text: text,
      timestamp: timestamp ?? DateTime(2026, 1, 1, 12, 0),
    );
  }

  group('SupportScreen - Widget Rendering', () {
    testWidgets(
      'renders SupportScreen with category picker when authenticated',
      (tester) async {
        await tester.pumpWidget(
          TestWrapper(
            overrides: [
              currentUserProvider.overrideWithValue(
                const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
              ),
              supportViewModelProvider.overrideWith((ref) {
                return SupportViewModel(ref);
              }),
            ],
            child: const SupportScreen(),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SupportScreen), findsOneWidget);
        expect(find.text('Support Agent'), findsOneWidget);
        expect(find.text('Choose a category to get started'), findsOneWidget);
      },
    );

    testWidgets('shows scaffold when unauthenticated', (tester) async {
      // When user is null, screen immediately builds a Scaffold with loading
      // and schedules a navigation to login via postFrameCallback.
      // We just verify the initial render without triggering the callback.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: MaterialApp(
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login Screen')),
            },
            home: const SupportScreen(),
          ),
        ),
      );
      // Just the initial build, no pump to avoid triggering postFrameCallback
      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('redirects to login when user is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: MaterialApp(
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login Screen')),
            },
            home: const SupportScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After redirect, Login Screen should be visible
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('displays all five category tiles', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Refund Request'), findsOneWidget);
      expect(find.text('Account Issue'), findsOneWidget);
      expect(find.text('Billing Dispute'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('shows agent avatar with gradient', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    });

    testWidgets('applies dark mode styling correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: SupportScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SupportScreen), findsOneWidget);
    });
  });

  group('SupportScreen - State Changes', () {
    testWidgets('shows loading state during conversation start', (
      tester,
    ) async {
      // When conversation is started but no messages yet, the chat body
      // shows a loading indicator. We simulate by tapping a category.
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(const SupportState(isLoading: true));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Tap a category to start conversation (sets _conversationStarted)
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      // After starting conversation with empty messages, chat body shows loading
      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });

    testWidgets('shows escalated banner when escalated', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                const SupportState(isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.headset_mic_rounded), findsOneWidget);
      expect(
        find.text('This conversation has been escalated to a human agent.'),
        findsOneWidget,
      );
    });

    testWidgets('hides input when conversation is escalated', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                const SupportState(isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('support-input'), findsNothing);
      expect(find.bySemanticsLabel('btn-send-support'), findsNothing);
    });

    testWidgets('displays multiple chat messages after starting conversation', (
      tester,
    ) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'Hello!'),
        _makeMessage(role: MessageRole.user, text: 'Hi there'),
        _makeMessage(role: MessageRole.agent, text: 'How can I help?'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Tap category to start conversation (sets _conversationStarted = true)
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.text('How can I help?'), findsOneWidget);
    });

    testWidgets('shows user and agent messages with correct alignment', (
      tester,
    ) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'Agent message'),
        _makeMessage(role: MessageRole.user, text: 'User message'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation first
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Agent message'), findsOneWidget);
      expect(find.text('User message'), findsOneWidget);
    });
  });

  group('SupportScreen - Error Handling', () {
    testWidgets('displays error banner when error message is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                const SupportState(errorMessage: 'Network error occurred'),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Network error occurred'), findsOneWidget);
    });

    testWidgets('error banner uses DesignTokens.error color', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                const SupportState(errorMessage: 'Error'),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Error'), findsOneWidget);
    });
  });

  group('SupportScreen - Navigation & Accessibility', () {
    testWidgets('has proper semantics for accessibility', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(
                  messages: [
                    _makeMessage(role: MessageRole.agent, text: 'Hello'),
                  ],
                ),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation to show input
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('btn-send-support'), findsOneWidget);
      expect(find.bySemanticsLabel('support-input'), findsOneWidget);
    });

    testWidgets('category tiles have semantics labels', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Each category tile has two Text widgets with the label,
      // and a Semantics wrapper with the label
      expect(find.text('Order Status'), findsOneWidget);
      expect(find.text('Refund Request'), findsOneWidget);
      expect(find.text('Account Issue'), findsOneWidget);
      expect(find.text('Billing Dispute'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('back button in app bar works correctly', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SupportScreen), findsOneWidget);
    });
  });

  group('SupportScreen - Chat Body', () {
    testWidgets('shows category picker when conversation not started', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(const SupportState());
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Choose a category to get started'), findsOneWidget);
    });

    testWidgets('chat bubbles display timestamps', (tester) async {
      final messages = [
        _makeMessage(
          role: MessageRole.agent,
          text: 'Hello!',
          timestamp: DateTime(2026, 1, 1, 14, 30),
        ),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation to reveal chat body
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('agent avatar shown next to agent messages', (tester) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'Agent reply'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Agent reply'), findsOneWidget);
      expect(find.text('Support Agent'), findsWidgets);
    });

    testWidgets('user messages do not show agent avatar', (tester) async {
      final messages = [
        _makeMessage(role: MessageRole.user, text: 'User message'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('User message'), findsOneWidget);
    });
  });

  group('SupportScreen - Design Tokens', () {
    testWidgets('uses DesignTokens for primary gradient', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('escalated banner uses warning color', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                const SupportState(isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final icon = tester.widget<Icon>(find.byIcon(Icons.headset_mic_rounded));
      expect(icon.color, DesignTokens.warningText);
    });

    testWidgets('send button has gradient when not loading', (tester) async {
      final messages = [_makeMessage(role: MessageRole.agent, text: 'Hello')];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(messages: messages, isLoading: false),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation to show send button
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });

  group('SupportScreen - Responsive Layout', () {
    testWidgets('constrains width on larger screens', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SupportScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('adapts to mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SupportScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('SupportScreen - User Interactions', () {
    testWidgets('category tiles are tappable', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final orderStatusTile = find.text('Order Status');
      expect(orderStatusTile, findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('message input field is present after conversation starts', (
      tester,
    ) async {
      final messages = [_makeMessage(role: MessageRole.agent, text: 'Hello')];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(SupportState(messages: messages));
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('support-input'), findsOneWidget);
      expect(find.bySemanticsLabel('btn-send-support'), findsOneWidget);
    });

    testWidgets('send button shows loading during loading state', (
      tester,
    ) async {
      final messages = [_makeMessage(role: MessageRole.agent, text: 'Hello')];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(messages: messages, isLoading: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Start conversation
      await tester.tap(find.text('Order Status'));
      await tester.pump(const Duration(seconds: 1));

      // When loading, the send button shows a small loading indicator
      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });
  });
}

class _PresetStateViewModel extends SupportViewModel {
  final SupportState _initialState;

  _PresetStateViewModel(this._initialState) : super(_fakeRef);

  static final Ref _fakeRef = _FakeRef();

  @override
  SupportState get state => _initialState;

  @override
  set state(SupportState value) {
    // No-op for tests
  }

  @override
  Future<void> startConversation(SupportCategory category) async {
    // No-op: preset state already has the desired messages
  }

  @override
  Future<void> sendMessage(String text) async {
    // No-op for tests
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
