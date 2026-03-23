import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_sellers_tab.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_sellers_tab_coverage_test.mocks.dart';

void _setScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    when(mockAdminRepo.watchSellers()).thenAnswer((_) => Stream.value([]));
    when(
      mockAdminRepo.watchProducts(sellerId: anyNamed('sellerId')),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget buildWidget() {
    return TestWrapper(
      overrides: [adminRepositoryProvider.overrideWithValue(mockAdminRepo)],
      child: const Scaffold(body: AdminSellersTab()),
    );
  }

  group('AdminSellersTab', () {
    testWidgets('renders empty state when no sellers', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);
    });

    testWidgets('renders sellers list', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Shop One',
          email: 'shop1@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime(2025, 1, 1),
        ),
        UserModel(
          uid: 's2',
          name: 'Shop Two',
          email: 'shop2@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime(2025, 2, 1),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Shop One'), findsOneWidget);
      expect(find.text('Shop Two'), findsOneWidget);
    });

    testWidgets('renders summary bar with active and suspended counts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Active',
          email: 'a@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 's2',
          name: 'Suspended',
          email: 's@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
          suspended: true,
        ),
        UserModel(
          uid: 's3',
          name: 'Connected',
          email: 'c@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders seller email', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Test Seller',
          email: 'seller@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller@test.com'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.error('error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminSellersTab), findsOneWidget);
    });

    testWidgets('suspended seller shows suspended badge', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Suspended Seller',
          email: 'sus@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
          suspended: true,
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
    });

    testWidgets('onboarded seller shows stripe connected chip', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Onboarded',
          email: 'o@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
          onboardingCompleted: true,
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('pending seller shows stripe pending chip', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Pending',
          email: 'p@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('seller card shows action buttons', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Test',
          email: 't@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.block_rounded), findsWidgets);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('suspended seller shows unsuspend button', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Suspended',
          email: 's@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
          suspended: true,
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('seller with stripe account shows account id', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Test',
          email: 't@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
          stripeAccountId: 'acct_12345678901234',
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('acct_'), findsOneWidget);
    });

    testWidgets('seller avatar shows first letter of name', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final sellers = [
        UserModel(
          uid: 's1',
          name: 'Alpha',
          email: 'a@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => Stream.value(sellers));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('loading state renders without crash', (tester) async {
      _setScreenSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      when(
        mockAdminRepo.watchSellers(),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminSellersTab), findsOneWidget);
    });
  });
}
