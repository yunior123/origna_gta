import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_panel_screen.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_panel_screen_coverage_test.mocks.dart';

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    when(mockAdminRepo.watchSellers()).thenAnswer((_) => Stream.value([]));
    when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.watchOrders(status: anyNamed('status')),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.watchProducts(sellerId: anyNamed('sellerId')),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.watchPendingReviewProducts(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.watchReviews(
        flaggedOnly: anyNamed('flaggedOnly'),
        hasPhotosOnly: anyNamed('hasPhotosOnly'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(mockAdminRepo.getPaymentProviders()).thenAnswer(
      (_) async => {
        'providers': {
          'stripe': {'enabled': true, 'configured': true, 'missingKeys': []},
        },
        'enabledProviders': ['stripe'],
      },
    );
  });

  Widget buildWidget({
    bool isAdmin = true,
    bool isLoggedIn = true,
    double screenWidth = 400,
  }) {
    final user = isLoggedIn
        ? AppAuthUser(uid: 'admin1', email: 'admin@test.com')
        : null;
    final profile = isLoggedIn
        ? UserModel(
            uid: 'admin1',
            email: 'admin@test.com',
            name: 'Admin User',
            roles: isAdmin
                ? [UserRole.admin, UserRole.buyer]
                : [UserRole.buyer],
            createdAt: DateTime.now(),
          )
        : null;

    return TestWrapper(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
        currentUserProvider.overrideWithValue(user),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
      child: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQueryData(size: Size(screenWidth, 800)),
            child: const AdminPanelScreen(),
          );
        },
      ),
    );
  }

  group('AdminPanelScreen', () {
    testWidgets('renders loading state', (tester) async {
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('renders admin panel for admin user on narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(screenWidth: 400));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('renders admin panel for admin user on wide screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(screenWidth: 1200));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('non-admin user sees access denied', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('not logged in user sees access denied', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('narrow layout has tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(screenWidth: 400));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('wide layout has navigation rail items', (tester) async {
      tester.view.physicalSize = const Size(2000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(screenWidth: 1200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_tab_sellers')), findsOneWidget);
      expect(find.byKey(const Key('admin_tab_users')), findsOneWidget);
    });

    testWidgets('wide layout has back button', (tester) async {
      tester.view.physicalSize = const Size(2000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(screenWidth: 1200));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_back_button')), findsOneWidget);
    });

    testWidgets('error state renders error icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = AppAuthUser(uid: 'admin1', email: 'admin@test.com');

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(user),
            userProfileProvider.overrideWith(
              (ref) => Stream.error('profile error'),
            ),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
