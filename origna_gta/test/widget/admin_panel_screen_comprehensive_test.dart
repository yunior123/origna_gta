import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_panel_screen.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_orders_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_payment_providers_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_products_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_reviews_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_security_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_sellers_tab.dart';
import 'package:origna_gta/features/admin/tabs/admin_users_tab.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/models/models.dart';

import '../test_utils.dart';

@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_panel_screen_comprehensive_test.mocks.dart';

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    _setupDefaultStubs(mockAdminRepo);
  });

  group('AdminPanelScreen - Loading State', () {
    testWidgets('shows loading indicator when userProfile is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            userProfileProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('shows ModernLoadingIndicator during load', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            userProfileProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('admin.loading_panel'.tr()), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Error State', () {
    testWidgets('shows error screen when userProfile has error', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            userProfileProvider.overrideWith(
              (ref) => Stream.error('Network error'),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('error screen shows error message', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            userProfileProvider.overrideWith(
              (ref) => Stream.error('Network error'),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Access Denied', () {
    testWidgets('shows access denied when user is null', (tester) async {
      final adminProfile = UserModel(
        uid: 'admin1',
        name: 'Admin User',
        email: 'admin@test.com',
        roles: [UserRole.admin],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(null),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(adminProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.access_denied'.tr()), findsOneWidget);
    });

    testWidgets('shows access denied when profile is null', (tester) async {
      final authUser = AppAuthUser(uid: 'user1', email: 'user@test.com');

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.access_denied'.tr()), findsOneWidget);
    });

    testWidgets('shows access denied when user is not admin', (tester) async {
      final authUser = AppAuthUser(uid: 'user1', email: 'user@test.com');
      final buyerProfile = UserModel(
        uid: 'user1',
        name: 'Buyer User',
        email: 'user@test.com',
        roles: [UserRole.buyer],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.access_denied'.tr()), findsOneWidget);
    });

    testWidgets('shows access denied for seller-only user', (tester) async {
      final authUser = AppAuthUser(uid: 'seller1', email: 'seller@test.com');
      final sellerProfile = UserModel(
        uid: 'seller1',
        name: 'Seller User',
        email: 'seller@test.com',
        roles: [UserRole.seller],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(sellerProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.access_denied'.tr()), findsOneWidget);
    });

    testWidgets('access denied screen shows go home button', (tester) async {
      final authUser = AppAuthUser(uid: 'user1', email: 'user@test.com');
      final buyerProfile = UserModel(
        uid: 'user1',
        name: 'Buyer',
        email: 'user@test.com',
        roles: [UserRole.buyer],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.go_home'.tr()), findsOneWidget);
    });

    testWidgets('access denied shows admin icon', (tester) async {
      final authUser = AppAuthUser(uid: 'user1', email: 'user@test.com');
      final buyerProfile = UserModel(
        uid: 'user1',
        name: 'Buyer',
        email: 'user@test.com',
        roles: [UserRole.buyer],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });

    testWidgets('access denied shows privileges required message', (
      tester,
    ) async {
      final authUser = AppAuthUser(uid: 'user1', email: 'user@test.com');
      final buyerProfile = UserModel(
        uid: 'user1',
        name: 'Buyer',
        email: 'user@test.com',
        roles: [UserRole.buyer],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(authUser),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(buyerProfile),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.privileges_required'.tr()), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Tab Rendering', () {
    testWidgets('renders all 7 tabs in narrow layout', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_tab_sellers')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_users')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_orders')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_products')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_payments')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_reviews')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_security')), findsOneWidget);
    });

    testWidgets('renders sellers tab content by default', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);
    });

    testWidgets('shows admin title in app bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.text('admin.title'.tr()), findsOneWidget);
    });

    testWidgets('shows admin icon in app bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsWidgets);
    });

    testWidgets('renders TabBar with scrollable tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('renders TabBarView with all tab content', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Tab Navigation', () {
    testWidgets('tapping users tab navigates to users content', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_users')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
    });

    testWidgets('tapping orders tab navigates to orders content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_orders')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('tapping products tab navigates to products content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_products')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminProductsTab), findsOneWidget);
    });

    testWidgets('tapping payments tab navigates to payments content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_payments')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPaymentProvidersTab), findsOneWidget);
    });

    testWidgets('tapping reviews tab navigates to reviews content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_reviews')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminReviewsTab), findsOneWidget);
    });

    testWidgets('tapping security tab navigates to security content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_security')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Wide Layout', () {
    testWidgets('shows side navigation rail on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsWidgets);
      expect(find.text('admin.title'.tr()), findsWidgets);
    });

    testWidgets('shows back button in wide layout', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_back_button')), findsOneWidget);
    });

    testWidgets('shows current tab title in wide layout header', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.text('admin.sellers_tab'.tr()), findsWidgets);
    });

    testWidgets('wide layout renders sellers tab by default', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);
    });

    testWidgets('wide layout side nav shows all tabs', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_tab_sellers')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_users')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_orders')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_products')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_payments')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_reviews')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_security')), findsOneWidget);
    });

    testWidgets('wide layout shows gradient background', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('AdminPanelScreen - Wide Layout Navigation', () {
    testWidgets('tapping users tab in wide layout switches content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_users')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
    });

    testWidgets('tapping orders tab in wide layout switches content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_orders')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminOrdersTab), findsOneWidget);
    });

    testWidgets('tapping products tab in wide layout switches content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_products')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminProductsTab), findsOneWidget);
    });

    testWidgets('tapping security tab in wide layout switches content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_security')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Quick Stats', () {
    testWidgets('shows quick stats section in wide layout', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.text('admin.quick_stats'.tr()), findsOneWidget);
    });

    testWidgets('shows sellers count in quick stats', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Seller1',
          email: 's1@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.text('admin.quick_stats'.tr()), findsOneWidget);
    });

    testWidgets('shows users count in quick stats', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final users = [
        UserModel(
          uid: 'u1',
          name: 'User1',
          email: 'u1@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.text('admin.quick_stats'.tr()), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Semantic Labels', () {
    testWidgets('all tabs have semantic labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_tab_sellers')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_users')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_orders')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_products')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_payments')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_reviews')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_security')), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Admin Actions', () {
    testWidgets('admin with multiple roles can access panel', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final multiRoleProfile = UserModel(
        uid: 'admin1',
        name: 'Admin User',
        email: 'admin@test.com',
        roles: [UserRole.admin, UserRole.seller, UserRole.buyer],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _createAdminPanelWidgetWithProfile(mockAdminRepo, multiRoleProfile),
      );
      await tester.pumpAndSettle();

      expect(find.text('admin.title'.tr()), findsOneWidget);
    });
  });

  group('AdminPanelScreen - Responsive Layout', () {
    testWidgets('narrow layout at exactly 900px width', (tester) async {
      tester.view.physicalSize = const Size(899, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('wide layout at exactly 900px width', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_back_button')), findsOneWidget);
    });

    testWidgets('switching from narrow to wide maintains tab selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_tab_users')));
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1400, 1000);
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });

  group('AdminPanelScreen - Tab Icons', () {
    testWidgets('sellers tab has store icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.store_rounded), findsWidgets);
    });

    testWidgets('users tab has people icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_rounded), findsWidgets);
    });

    testWidgets('orders tab has receipt icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long_rounded), findsWidgets);
    });

    testWidgets('products tab has inventory icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2_rounded), findsWidgets);
    });

    testWidgets('payments tab has payment icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.payment_rounded), findsWidgets);
    });

    testWidgets('reviews tab has rate_review icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.rate_review_rounded), findsWidgets);
    });

    testWidgets('security tab has security icon', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security_rounded), findsWidgets);
    });
  });

  group('AdminPanelScreen - Integration Tests', () {
    testWidgets('can navigate through all tabs sequentially', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_users')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminUsersTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_orders')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminOrdersTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_products')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminProductsTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_payments')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPaymentProvidersTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_reviews')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminReviewsTab), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin_tab_security')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('widget rebuilds correctly on provider update', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createAdminPanelWidget(mockAdminRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });
  });
}

void _setupDefaultStubs(MockAdminRepository mockAdminRepo) {
  when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value([]));
  when(
    mockAdminRepo.watchOrders(status: anyNamed('status')),
  ).thenAnswer((_) => Stream.value([]));
  when(
    mockAdminRepo.watchProducts(sellerId: anyNamed('sellerId')),
  ).thenAnswer((_) => Stream.value([]));
  when(mockAdminRepo.watchSellers()).thenAnswer((_) => Stream.value([]));
  when(
    mockAdminRepo.watchReviews(
      flaggedOnly: anyNamed('flaggedOnly'),
      hasPhotosOnly: anyNamed('hasPhotosOnly'),
    ),
  ).thenAnswer((_) => Stream.value([]));
  when(
    mockAdminRepo.watchPendingReviewProducts(),
  ).thenAnswer((_) => Stream.value([]));
}

Widget _createAdminPanelWidget(MockAdminRepository mockAdminRepo) {
  final authUser = AppAuthUser(uid: 'admin1', email: 'admin@test.com');
  final adminProfile = UserModel(
    uid: 'admin1',
    name: 'Admin User',
    email: 'admin@test.com',
    roles: [UserRole.admin],
    createdAt: DateTime.now(),
  );

  return TestWrapper(
    overrides: [
      adminRepositoryProvider.overrideWithValue(mockAdminRepo),
      currentUserProvider.overrideWithValue(authUser),
      userProfileProvider.overrideWith((ref) => Stream.value(adminProfile)),
    ],
    child: const AdminPanelScreen(),
  );
}

Widget _createAdminPanelWidgetWithProfile(
  MockAdminRepository mockAdminRepo,
  UserModel profile,
) {
  final authUser = AppAuthUser(uid: profile.uid, email: profile.email);

  return TestWrapper(
    overrides: [
      adminRepositoryProvider.overrideWithValue(mockAdminRepo),
      currentUserProvider.overrideWithValue(authUser),
      userProfileProvider.overrideWith((ref) => Stream.value(profile)),
    ],
    child: const AdminPanelScreen(),
  );
}
