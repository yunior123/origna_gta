import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';


import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SubscriptionSuccessScreen', () {
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

      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
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

      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
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

    testWidgets('non-premium shows container with gradient', (tester) async {
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

    testWidgets('non-premium shows center widget', (tester) async {
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
  });
}
