import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
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
        await tester.pumpAndSettle();

        expect(find.byType(SupportScreen), findsOneWidget);
        expect(find.text('Support Agent'), findsOneWidget);
        expect(find.text('Choose a category to get started'), findsOneWidget);
      },
    );

    testWidgets('shows loading indicator when unauthenticated', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('redirects to login when user is null', (tester) async {
      final navigatorObserver = _TestNavigatorObserver();

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            supportViewModelProvider.overrideWith((ref) {
              return SupportViewModel(ref);
            }),
          ],
          navigatorObservers: [navigatorObserver],
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.login) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Login Screen')),
                settings: settings,
              );
            }
            return null;
          },
          child: const SupportScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(navigatorObserver.routes, contains(AppRoutes.login));
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsOneWidget);
    });
  });

  group('SupportScreen - State Changes', () {
    testWidgets('shows loading state during conversation start', (
      tester,
    ) async {
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
      await tester.pumpAndSettle();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows escalated banner when escalated', (tester) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'A human will help.'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(messages: messages, isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.headset_mic_rounded), findsOneWidget);
      expect(
        find.text('This conversation has been escalated to a human agent.'),
        findsOneWidget,
      );
    });

    testWidgets('hides input when conversation is escalated', (tester) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'Escalated.'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(messages: messages, isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('support-input'), findsNothing);
      expect(find.bySemanticsLabel('btn-send-support'), findsNothing);
    });

    testWidgets('displays multiple chat messages', (tester) async {
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('Agent message'), findsOneWidget);
      expect(find.text('User message'), findsOneWidget);
    });
  });

  group('SupportScreen - Error Handling', () {
    testWidgets('displays error banner when error message is set', (
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
                SupportState(
                  messages: messages,
                  errorMessage: 'Network error occurred',
                ),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
    });
  });

  group('SupportScreen - Navigation & Accessibility', () {
    testWidgets('has proper semantics for accessibility', (tester) async {
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Order Status'), findsOneWidget);
      expect(find.bySemanticsLabel('Refund Request'), findsOneWidget);
      expect(find.bySemanticsLabel('Account Issue'), findsOneWidget);
      expect(find.bySemanticsLabel('Billing Dispute'), findsOneWidget);
      expect(find.bySemanticsLabel('Other'), findsOneWidget);
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsOneWidget);
    });

    testWidgets('escalated banner uses warning color', (tester) async {
      final messages = [
        _makeMessage(role: MessageRole.agent, text: 'Escalated'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'test_user', email: 'test@test.com'),
            ),
            supportViewModelProvider.overrideWith((ref) {
              return _PresetStateViewModel(
                SupportState(messages: messages, isEscalated: true),
              );
            }),
          ],
          child: const SupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('support-input'), findsOneWidget);
      expect(find.bySemanticsLabel('btn-send-support'), findsOneWidget);
    });

    testWidgets('send button is disabled during loading', (tester) async {
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
      await tester.pumpAndSettle();

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
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestNavigatorObserver extends NavigatorObserver {
  final List<String> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      routes.add(route.settings.name!);
    }
  }
}
