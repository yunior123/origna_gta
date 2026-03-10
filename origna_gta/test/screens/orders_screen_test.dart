import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/orders_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  const signedInUser = AppAuthUser(
    uid: 'test_user_123',
    email: 'test@example.com',
    emailVerified: true,
  );

  group('OrdersScreen Smoke Test', () {
    testWidgets('renders orders screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(signedInUser),
            buyerOrdersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const OrdersScreen(),
        ),
      );

      // Use pump() because of infinite animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('My Orders'), findsOneWidget);
    });
  });
}
