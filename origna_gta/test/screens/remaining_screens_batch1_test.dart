import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/notifications_screen.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/ordersuccess_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import '../test_utils.dart';


void main() {
  setUpAll(() {
    initTestMocks();
  });
  late AppAuthUser mockUser;

  setUp(() {
    mockUser = const AppAuthUser(uid: 'test_user_123', email: 'test@example.com');
  });

  group('Remaining Screens Batch 1 Smoke Tests', () {
    testWidgets('renders notifications screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
          ],
          child: const NotificationsScreen(),
        ),
      );
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('renders favorites screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            favoritesProvider.overrideWith((ref) => Stream.value(<String>{})),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('renders order success screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
          ],
          child: const OrderSuccessScreen(orderId: 'order_123'),
        ),
      );
      await tester.pump();
      // Add enough time for mascot jump timers to complete
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(OrderSuccessScreen), findsOneWidget);
    });
  });
}
