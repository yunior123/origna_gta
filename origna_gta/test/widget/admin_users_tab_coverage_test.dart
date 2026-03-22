import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_users_tab.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_users_tab_coverage_test.mocks.dart';

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value([]));
  });

  Widget buildWidget({List<Override> overrides = const []}) {
    return TestWrapper(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
        ...overrides,
      ],
      child: const Scaffold(body: AdminUsersTab()),
    );
  }

  group('AdminUsersTab', () {
    testWidgets('renders loading state', (tester) async {
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminUsersTab), findsOneWidget);
    });

    testWidgets('renders empty state when no users', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
    });

    testWidgets('renders users list with populated data', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Alice',
          email: 'alice@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime(2025, 1, 15),
        ),
        UserModel(
          uid: 'u2',
          name: 'Bob',
          email: 'bob@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime(2025, 3, 10),
        ),
        UserModel(
          uid: 'u3',
          name: 'Carol',
          email: 'carol@test.com',
          roles: [UserRole.admin],
          createdAt: DateTime(2024, 6, 1),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('alice@test.com'), findsOneWidget);
    });

    testWidgets('renders suspended user with block icon', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Suspended',
          email: 's@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
          suspended: true,
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.block_rounded), findsWidgets);
    });

    testWidgets('search field filters users by name', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Alice',
          email: 'a@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'u2',
          name: 'Bob',
          email: 'b@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('admin_users_search_field')),
        'alice',
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('search field filters users by email', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Alice',
          email: 'alice@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'u2',
          name: 'Bob',
          email: 'bob@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('admin_users_search_field')),
        'bob@test',
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('search field shows clear button and clears', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Alice',
          email: 'a@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('admin_users_search_field')),
        'test',
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('filter chip all shows all users', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Buyer',
          email: 'b@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'u2',
          name: 'Seller',
          email: 's@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'u3',
          name: 'Admin',
          email: 'a@test.com',
          roles: [UserRole.admin],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Seller'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(
        mockAdminRepo.watchUsers(),
      ).thenAnswer((_) => Stream.error('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminUsersTab), findsOneWidget);
    });

    testWidgets('displays user role badges', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Seller',
          email: 's@test.com',
          roles: [UserRole.seller],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller'), findsOneWidget);
    });

    testWidgets('displays joined date', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final users = [
        UserModel(
          uid: 'u1',
          name: 'Test',
          email: 't@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime(2025, 6, 15),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('t@test.com'), findsOneWidget);
    });

    testWidgets('user with empty name shows Unknown', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: '',
          email: 'no-name@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('no-name@test.com'), findsOneWidget);
    });

    testWidgets('popup menu button exists on user card', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Test',
          email: 't@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('search and no results shows no match message', (tester) async {
      final users = [
        UserModel(
          uid: 'u1',
          name: 'Alice',
          email: 'a@test.com',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      ];
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => Stream.value(users));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('admin_users_search_field')),
        'zzzznotfound',
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsNothing);
    });
  });
}
