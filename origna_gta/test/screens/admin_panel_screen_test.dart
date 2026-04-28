import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/admin/admin_panel_screen.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';

class _TestAdminRepository implements AdminRepository {
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
    ApiKeys.backupCodes: ['code1'],
  };

  @override
  Future<UserModel?> fetchUserById(String userId) async => null;

  @override
  Future<void> flagReview(String reviewId, {required bool flagged}) async {}

  @override
  Future<Map<String, dynamic>> getPaymentProviders() async => {
    'providers': {
      'stripe': {'enabled': true, 'configured': true, 'missingKeys': []},
    },
    'enabledProviders': ['stripe'],
  };

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

  @override
  Stream<List<OrderModel>> watchOrders({String? status, int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<ProductModel>> watchPendingReviewProducts({int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<ProductModel>> watchProducts({
    int limit = 50,
    String? sellerId,
  }) => Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> watchReviews({
    bool flaggedOnly = false,
    bool hasPhotosOnly = false,
    int limit = 50,
  }) => Stream.value([]);

  @override
  Stream<List<UserModel>> watchSellers({int limit = 50}) => Stream.value([]);

  @override
  Stream<List<UserModel>> watchUsers({int limit = 50}) => Stream.value([]);
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  testWidgets('builds without error with mocked providers', (tester) async {
    final profile = UserModel(
      uid: 'admin_1',
      email: 'admin@test.com',
      name: 'Admin',
      roles: const [UserRole.admin],
      createdAt: DateTime(2026, 3, 1),
    );

    await tester.pumpWidget(
      TestWrapper(
        overrides: [
          adminRepositoryProvider.overrideWithValue(_TestAdminRepository()),
          currentUserProvider.overrideWithValue(
            const AppAuthUser(uid: 'admin_1', email: 'admin@test.com'),
          ),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: const AdminPanelScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AdminPanelScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
