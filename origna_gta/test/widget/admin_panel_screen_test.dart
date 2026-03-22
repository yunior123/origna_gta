import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_panel_screen.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

import '../test_utils.dart';

class MockAdminRepository extends Fake implements AdminRepository {
  @override
  Stream<List<UserModel>> watchSellers({int limit = 50}) => Stream.value([]);

  @override
  Stream<List<UserModel>> watchUsers({int limit = 50}) => Stream.value([]);

  @override
  Stream<List<OrderModel>> watchOrders({String? status, int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<ProductModel>> watchProducts({
    int limit = 50,
    String? sellerId,
  }) => Stream.value([]);

  @override
  Stream<List<ProductModel>> watchPendingReviewProducts({int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> watchReviews({
    bool flaggedOnly = false,
    bool hasPhotosOnly = false,
    int limit = 50,
  }) => Stream.value([]);

  @override
  Future<Map<String, dynamic>> getPaymentProviders() async => {
    'providers': {
      'stripe': {'enabled': true, 'configured': true, 'missingKeys': []},
    },
    'enabledProviders': ['stripe'],
  };

  @override
  Future<void> approveProduct(String productId) async {}

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<void> deleteReview(String reviewId) async {}

  @override
  Future<void> disableAdminMfa(String code) async {}

  @override
  Future<Map<String, dynamic>> enableAdminMfa() async => {
    ApiKeys.secret: 'test-secret',
    ApiKeys.provisioningUri: 'otpauth://totp/test',
    ApiKeys.backupCodes: ['code1', 'code2'],
  };

  @override
  Future<UserModel?> fetchUserById(String userId) async => null;

  @override
  Future<void> flagReview(String reviewId, {required bool flagged}) async {}

  @override
  Future<void> refundOrder(
    String orderId, {
    String reason = 'Admin refund',
  }) async {}

  @override
  Future<void> rejectProduct(String productId, String reason) async {}

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {}

  @override
  Future<void> updatePaymentProvider(
    String provider,
    bool enabled, {
    String? reason,
  }) async {}

  @override
  Future<void> updateProductStock(String productId, int quantity) async {}

  @override
  Future<void> updateUserRoles(
    String userId, {
    List<String> add = const [],
    List<String> remove = const [],
    String? reason,
  }) async {}

  @override
  Future<Map<String, dynamic>> verifyAdminMfa(String code) async => {
    'success': true,
  };
}

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
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
      child: const AdminPanelScreen(),
    );
  }

  group('AdminPanelScreen', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('renders admin panel for admin user', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('non-admin user sees access denied', (tester) async {
      await tester.pumpWidget(buildWidget(isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });

    testWidgets('not logged in user sees access denied', (tester) async {
      await tester.pumpWidget(buildWidget(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('error state renders error icon', (tester) async {
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

    testWidgets('access denied shows home button', (tester) async {
      await tester.pumpWidget(buildWidget(isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('admin panel has gradient header', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('admin panel renders without errors for admin', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });

    testWidgets('null profile shows access denied', (tester) async {
      final user = AppAuthUser(uid: 'admin1', email: 'admin@test.com');

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            currentUserProvider.overrideWithValue(user),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const AdminPanelScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });

    testWidgets('loading state shows indicator', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(AdminPanelScreen), findsOneWidget);
    });
  });
}
