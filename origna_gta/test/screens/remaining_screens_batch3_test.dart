import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/subscription_screen.dart';
import 'package:origna_gta/screens/subscription_success_screen.dart';
import 'package:origna_gta/screens/subscription_cancel_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  late AppAuthUser mockUser;

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
    );
  });

  group('Remaining Screens Batch 3 Smoke Tests', () {
    testWidgets('renders subscription screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const SubscriptionScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });

    testWidgets('renders subscription success screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: const SubscriptionSuccessScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
    });

    testWidgets('renders subscription cancel screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: const SubscriptionCancelScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SubscriptionCancelScreen), findsOneWidget);
    });
  });
}
