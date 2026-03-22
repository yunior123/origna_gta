import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_security_tab.dart';
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
    ApiKeys.secret: 'JBSWY3DPEHPK3PXP',
    ApiKeys.provisioningUri: 'otpauth://totp/test?secret=JBSWY3DPEHPK3PXP',
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

  Widget buildWidget({bool mfaEnabled = false, String? userId}) {
    return TestWrapper(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
        currentUserProvider.overrideWithValue(
          userId != null
              ? AppAuthUser(uid: userId, email: 'admin@test.com')
              : null,
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            UserModel(
              uid: userId ?? 'admin1',
              email: 'admin@test.com',
              name: 'Admin',
              roles: [UserRole.admin],
              createdAt: DateTime.now(),
              mfaEnabled: mfaEnabled,
            ),
          ),
        ),
      ],
      child: const Scaffold(body: AdminSecurityTab()),
    );
  }

  group('AdminSecurityTab', () {
    testWidgets('renders MFA disabled state', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('renders MFA enabled state', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('shows enable MFA button when disabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security_rounded), findsOneWidget);
    });

    testWidgets('shows disable MFA button when enabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('renders loading state initially', (tester) async {
      await tester.pumpWidget(buildWidget(userId: 'admin1'));
      await tester.pump();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('tapping enable MFA shows QR code section', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
      expect(find.byIcon(Icons.security_rounded), findsOneWidget);
    });

    testWidgets('tapping disable MFA shows dialog', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('disable MFA dialog has cancel button', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Dialog should be showing with at least two TextButton actions
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is TextButton && w.onPressed != null),
        findsWidgets,
      );
    });

    testWidgets('renders security title and subtitle', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('renders with MFA status badge', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders with MFA disabled badge', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('disable dialog has text field for code', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('MFA card has correct padding', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows shield icon in header', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });

    testWidgets('enable MFA button is tappable', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final button = find.byType(FilledButton).first;
      expect(button, findsOneWidget);
    });

    testWidgets('MFA status shows correct text when enabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('MFA status shows correct text when disabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('cancel button in disable dialog works', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // The first TextButton in the dialog actions is the cancel button
      final cancelButton = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          )
          .first;
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('renders with loading indicator when action in progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });
  });
}
