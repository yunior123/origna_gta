import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/core/providers.dart';
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

  group('SellerSetupScreen Smoke Test', () {
    testWidgets('renders seller setup complete screen correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: const SellerSetupCompleteScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SellerSetupCompleteScreen), findsOneWidget);
    });

    testWidgets('renders seller setup refresh screen correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [currentUserProvider.overrideWithValue(mockUser)],
          child: const SellerSetupRefreshScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SellerSetupRefreshScreen), findsOneWidget);
    });
  });
}
