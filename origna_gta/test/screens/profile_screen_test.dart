import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/core/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:origna_gta/models/models.dart';
import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<User>()])
import 'profile_screen_test.mocks.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  late MockUser mockUser;
  late UserModel testUserModel;

  setUp(() {
    mockUser = MockUser();
    when(mockUser.uid).thenReturn('test_user_123');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    
    testUserModel = UserModel(
      uid: 'test_user_123',
      name: 'Test User',
      email: 'test@example.com',
      roles: ['buyer'],
      isPremium: false,
      createdAt: DateTime.now(),
    );
  });

  group('ProfileScreen Smoke Test', () {
    testWidgets('renders profile for authenticated user', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith((ref) => Stream.value(testUserModel)),
            subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
          ],
          child: const ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings').at(0), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byKey(const Key('profile_my_orders_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_sign_out_button')), findsOneWidget);
    });

    testWidgets('renders sign in prompt for unauthenticated user', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in to see profile'), findsOneWidget);
      expect(find.byKey(const Key('profile_sign_in_button')), findsOneWidget);
    });

    testWidgets('renders loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith((ref) => const Stream.empty()),
            subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const ProfileScreen(),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing); // ModernLoadingIndicator is used
    });
  });
}
