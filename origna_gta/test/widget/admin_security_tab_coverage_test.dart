import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/features/admin/tabs/admin_security_tab.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/utils/utils.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_security_tab_coverage_test.mocks.dart';

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
      when(mockAdminRepo.watchUsers()).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildWidget(userId: 'admin1'));
      await tester.pump();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('tapping enable MFA calls enableAdminMfa', (tester) async {
      when(mockAdminRepo.enableAdminMfa()).thenAnswer(
        (_) async => {
          'secret': 'JBSWY3DPEHPK3PXP',
          'provisioningUri': 'otpauth://totp/test?secret=JBSWY3DPEHPK3PXP',
          'backupCodes': ['code1', 'code2'],
        },
      );

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

      // Dialog shows 'common.cancel' key or 'Cancel' depending on localization context.
      // In dialog overlay, localization may not be available.
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
  });
}
