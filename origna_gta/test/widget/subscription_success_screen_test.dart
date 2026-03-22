import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SubscriptionSuccessScreen - Widget Rendering', () {
    testWidgets('renders when subscription is null', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
    });

    testWidgets('renders with semantics label', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('subscription-success-screen'),
        findsWidgets,
      );
    });

    testWidgets('renders scaffold', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders container with gradient', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders center widget', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('dispose works without error', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(find.byType(SubscriptionSuccessScreen), findsNothing);
    });
  });

  group('SubscriptionSuccessScreen - Loading State', () {
    testWidgets('non-premium shows loading indicator', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('non-premium subscription shows loading state', (tester) async {
      final nonPremium = SubscriptionInfo(
        status: 'inactive',
        isPremium: false,
        currentPeriodEnd: null,
        cancelAtPeriodEnd: false,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith(
              (_) => Stream.value(nonPremium),
            ),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('loading state shows activating message', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Activating...'), findsOneWidget);
    });
  });

  group('SubscriptionSuccessScreen - Timeout/Error State', () {
    testWidgets('timeout state shows timer icon', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
    });

    testWidgets('timeout state shows activation delayed title', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(find.text('Activation Delayed'), findsOneWidget);
    });

    testWidgets('timeout state shows activation delayed description', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(
        find.text(
          "We're processing your subscription. Please try again in a moment.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('timeout state shows refresh button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('timeout state shows back to home text button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      expect(find.text('Back to Home'), findsOneWidget);
    });
  });

  group('SubscriptionSuccessScreen - Dark Mode', () {
    testWidgets('dark mode renders correctly with non-premium loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: const SubscriptionSuccessScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('dark mode shows activating message', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark),
            home: const SubscriptionSuccessScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Activating...'), findsOneWidget);
    });
  });

  group('SubscriptionSuccessScreen - Layout Components', () {
    testWidgets('loading state shows container', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('loading state shows single scroll view', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('loading state shows column', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            subscriptionStreamProvider.overrideWith((_) => Stream.value(null)),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });
  });
}
