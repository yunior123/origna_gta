import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/profile_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/core/theme_provider.dart';
import 'package:origna_gta/features/profile/profile_viewmodel.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../test_utils.dart';

/// Creates a provider override that returns a viewmodel with the given state.
Override _overrideProfileState([ProfileState? profileState]) {
  return profileViewModelProvider.overrideWith((ref) {
    final vm = OrignaBaseProfileViewModel(ref);
    if (profileState != null) {
      // ignore: invalid_use_of_protected_member
      vm.state = profileState;
    }
    return vm;
  });
}

const _animationDuration = Duration(seconds: 1);

void main() {
  setUpAll(() {
    initTestMocks();
  });

  late AppAuthUser mockUser;
  late UserModel buyerUserModel;
  late UserModel premiumUserModel;

  setUp(() {
    mockUser = const AppAuthUser(
      uid: 'test_user_123',
      email: 'test@example.com',
      emailVerified: true,
    );

    buyerUserModel = UserModel(
      uid: 'test_user_123',
      name: 'Test User',
      email: 'test@example.com',
      roles: const [UserRole.buyer],
      isPremium: false,
      createdAt: DateTime(2026, 1, 1),
    );

    premiumUserModel = UserModel(
      uid: 'test_user_123',
      name: 'Premium User',
      email: 'premium@example.com',
      roles: const [UserRole.buyer],
      isPremium: true,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    AppAuthUser? currentUser,
    UserModel? userProfile,
    SubscriptionInfo? subscription,
    ThemeMode themeMode = ThemeMode.light,
    ProfileState? profileState,
    List<Override> overrides = const [],
    Route<dynamic>? Function(RouteSettings)? onGenerateRoute,
  }) async {
    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          currentUserProvider.overrideWithValue(currentUser),
          userProfileProvider.overrideWith((ref) => Stream.value(userProfile)),
          subscriptionStreamProvider.overrideWith(
            (ref) => Stream.value(subscription),
          ),
          themeModeProvider.overrideWith((ref) => themeMode),
          _overrideProfileState(profileState),
          ...overrides,
        ],
        onGenerateRoute: onGenerateRoute,
        child: const ProfileScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(_animationDuration);
  }

  group('ProfileScreen - Profile Display', () {
    testWidgets('displays user name and email in profile header', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('displays user initials in avatar', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('T'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('displays loading state while profile loads', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith(
              (ref) =>
                  Stream.value(null).asyncExpand((_) => Stream.value(null)),
            ),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsWidgets);
    });

    testWidgets('displays premium badge for premium users', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      final premiumSub = SubscriptionInfo(status: 'active', isPremium: true);
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: premiumUserModel,
        subscription: premiumSub,
      );

      expect(find.byIcon(Icons.workspace_premium), findsAtLeast(1));
      expect(find.text('Active'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('displays profile completion bar for incomplete profiles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('Profile Completion'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Settings Navigation', () {
    testWidgets('navigates to address management when address button tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('ADDRESS_SCREEN')),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_address_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.addressManagement));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to terms of service when terms button tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_terms_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.termsOfService));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to privacy policy when privacy button tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_privacy_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.privacyPolicy));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('theme toggle changes theme mode', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerUserModel),
            ),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
            _overrideProfileState(),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(_animationDuration);

      final themePills = find.byIcon(Icons.dark_mode_rounded);
      await tester.tap(themePills.last);
      await tester.pump();

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to subscription when premium section tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.text('Premium'));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.subscription));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Address Management', () {
    testWidgets('shows address menu item with correct icon', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      final addressButton = find.byKey(const Key('profile_address_button'));
      expect(addressButton, findsOneWidget);
      expect(
        find.descendant(
          of: addressButton,
          matching: find.byIcon(Icons.location_on_outlined),
        ),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('address button has correct semantics label', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      final addressButton = find.byKey(const Key('profile_address_button'));
      expect(addressButton, findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('address menu item shows correct subtitle', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      // MockAssetLoader returns "Manage address" for this key
      expect(find.text('Manage address'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Order History Link', () {
    testWidgets('shows my orders menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_my_orders_button')), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to orders screen when my orders tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_my_orders_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.orders));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('my orders has correct icon', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      final ordersButton = find.byKey(const Key('profile_my_orders_button'));
      expect(
        find.descendant(
          of: ordersButton,
          matching: find.byIcon(Icons.shopping_bag_outlined),
        ),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('my orders shows view purchases subtitle', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('View your purchases'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Sign Out', () {
    testWidgets('shows sign out button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_sign_out_button')), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('sign out button has correct semantics', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      final signOutButton = find.byKey(const Key('profile_sign_out_button'));
      expect(signOutButton, findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Delete Account', () {
    testWidgets('shows delete account button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(
        find.byKey(const Key('profile_delete_account_button')),
        findsOneWidget,
      );
      expect(find.text('Delete Account'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('opens delete account dialog when tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      await tester.ensureVisible(
        find.byKey(const Key('profile_delete_account_button')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('profile_delete_account_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('This action is irreversible.'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Premium Features', () {
    testWidgets('premium users see notifications menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      final premiumSub = SubscriptionInfo(status: 'active', isPremium: true);
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: premiumUserModel,
        subscription: premiumSub,
      );

      expect(
        find.byKey(const Key('profile_notifications_button')),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('non-premium users do not see notifications menu item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(
        find.byKey(const Key('profile_notifications_button')),
        findsNothing,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('premium section shows upgrade prompt for non-premium', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('Upgrade to premium'), findsOneWidget);
      expect(find.text('Active'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Export Data', () {
    testWidgets('shows export data menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_export_button')), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('export data shows loading indicator when exporting', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerUserModel),
            ),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
            _overrideProfileState(ProfileState(isLoading: true)),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(_animationDuration);

      final exportButton = find.byKey(const Key('profile_export_button'));
      expect(exportButton, findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Messages and Favorites', () {
    testWidgets('shows messages menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_messages_button')), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows favorites menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_favorites_button')), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to chat inbox when messages tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_messages_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.chatInbox));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to favorites when favorites tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_favorites_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.favorites));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Language Settings', () {
    testWidgets('shows language menu item', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_language_button')), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('language shows current locale', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('English'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Support Section', () {
    testWidgets('shows support section header', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('Support'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows app info section', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.text('App Info'), findsOneWidget);
      expect(find.text('Origna GTA'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows rate app and share app buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_rate_app_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_share_app_button')), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows get help button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(find.byKey(const Key('profile_get_help_button')), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Seller Features', () {
    testWidgets('shows become a seller for buyer users', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      if (FeatureFlags.kSellerOnboardingEnabled) {
        expect(
          find.byKey(const Key('profile_become_seller_button')),
          findsOneWidget,
        );
        expect(find.text('Become a Seller'), findsOneWidget);
      } else {
        expect(
          find.byKey(const Key('profile_become_seller_button')),
          findsNothing,
        );
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('does not show seller orders for buyer users', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
      );

      expect(
        find.byKey(const Key('profile_seller_orders_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('profile_seller_dashboard_button')),
        findsNothing,
      );

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('navigates to seller registration when become seller tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      if (!FeatureFlags.kSellerOnboardingEnabled) {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        return;
      }

      String? navigatedRoute;
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: buyerUserModel,
        onGenerateRoute: (settings) {
          navigatedRoute = settings.name;
          return MaterialPageRoute(
            builder: (_) => const Scaffold(),
            settings: settings,
          );
        },
      );

      await tester.tap(find.byKey(const Key('profile_become_seller_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.sellerRegistration));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ProfileScreen - Unauthenticated State', () {
    testWidgets('shows sign in prompt when not logged in', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
          ],
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to see profile'), findsOneWidget);
      expect(find.byKey(const Key('profile_sign_in_button')), findsOneWidget);
    });

    testWidgets('sign in button navigates to login', (tester) async {
      String? navigatedRoute;
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            subscriptionStreamProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            themeModeProvider.overrideWith((ref) => ThemeMode.light),
          ],
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.login) {
              navigatedRoute = settings.name;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('LOGIN')),
                settings: settings,
              );
            }
            return null;
          },
          child: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_sign_in_button')));
      await tester.pump();
      await tester.pump();

      expect(navigatedRoute, equals(AppRoutes.login));
    });
  });

  group('ProfileScreen - Profile Completion States', () {
    testWidgets('shows 50% completion with address', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      final userWithAddress = UserModel(
        uid: 'test_user_123',
        name: 'Test User',
        email: 'test@example.com',
        roles: const [UserRole.buyer],
        isPremium: false,
        createdAt: DateTime(2026, 1, 1),
        address: Address(
          street: '123 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 1A1',
          country: 'Canada',
        ),
      );

      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: userWithAddress,
      );

      expect(find.text('50%'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('hides completion bar when 100% complete', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      final completeUser = UserModel(
        uid: 'test_user_123',
        name: 'Complete User',
        email: 'complete@example.com',
        roles: const [UserRole.buyer],
        isPremium: true,
        notifyNewProducts: true,
        notifyTrending: true,
        createdAt: DateTime(2026, 1, 1),
        address: Address(
          street: '123 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 1A1',
          country: 'Canada',
        ),
      );

      final premiumSub = SubscriptionInfo(status: 'active', isPremium: true);
      await pumpProfileScreen(
        tester,
        currentUser: mockUser,
        userProfile: completeUser,
        subscription: premiumSub,
      );

      expect(find.text('Profile Completion'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
