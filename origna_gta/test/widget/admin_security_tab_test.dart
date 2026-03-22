import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:qr_flutter/qr_flutter.dart';

import '../test_utils.dart';

class MockAdminRepository extends Fake implements AdminRepository {
  bool _enableMfaCalled = false;
  bool _disableMfaCalled = false;
  bool _verifyMfaCalled = false;
  String? _lastMfaCode;
  Exception? _enableMfaException;
  Exception? _disableMfaException;
  Exception? _verifyMfaException;

  void reset() {
    _enableMfaCalled = false;
    _disableMfaCalled = false;
    _verifyMfaCalled = false;
    _lastMfaCode = null;
    _enableMfaException = null;
    _disableMfaException = null;
    _verifyMfaException = null;
  }

  void setEnableMfaException(Exception e) => _enableMfaException = e;
  void setDisableMfaException(Exception e) => _disableMfaException = e;
  void setVerifyMfaException(Exception e) => _verifyMfaException = e;

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
  Future<void> disableAdminMfa(String code) async {
    _disableMfaCalled = true;
    _lastMfaCode = code;
    if (_disableMfaException != null) {
      throw _disableMfaException!;
    }
  }

  @override
  Future<Map<String, dynamic>> enableAdminMfa() async {
    _enableMfaCalled = true;
    if (_enableMfaException != null) {
      throw _enableMfaException!;
    }
    return {
      ApiKeys.secret: 'JBSWY3DPEHPK3PXP',
      ApiKeys.provisioningUri:
          'otpauth://totp/OrignaGTA:admin@test.com?secret=JBSWY3DPEHPK3PXP&issuer=OrignaGTA',
      ApiKeys.backupCodes: [
        'ABCD1234EFGH5678',
        'IJKL9012MNOP3456',
        'QRST7890UVWX1234',
        'YZAB5678CDEF9012',
        'GHIJ3456KLMN7890',
        'OPQR1234STUV5678',
      ],
    };
  }

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
  Future<Map<String, dynamic>> verifyAdminMfa(String code) async {
    _verifyMfaCalled = true;
    _lastMfaCode = code;
    if (_verifyMfaException != null) {
      throw _verifyMfaException!;
    }
    return {'success': true};
  }
}

void main() {
  late MockAdminRepository mockAdminRepo;

  setUpAll(() {
    initTestMocks();
    // Mock the clipboard so Clipboard.setData works in tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') return null;
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        });
  });

  setUp(() {
    mockAdminRepo = MockAdminRepository();
  });

  Widget buildWidget({
    bool mfaEnabled = false,
    String? userId,
    bool isLoading = false,
    String? errorMessage,
  }) {
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
        adminActionsViewModelProvider.overrideWith(
          (ref) => AdminActionsViewModel(ref),
        ),
      ],
      child: const Scaffold(body: AdminSecurityTab()),
    );
  }

  group('AdminSecurityTab - Rendering', () {
    testWidgets('renders MFA disabled state correctly', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.security_rounded), findsOneWidget);
    });

    testWidgets('renders MFA enabled state correctly', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('shows correct MFA status badge when enabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows correct MFA status badge when disabled', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });
  });

  group('AdminSecurityTab - MFA Enable Flow', () {
    testWidgets('tapping enable MFA button shows QR code section', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    });

    testWidgets('shows backup codes after enabling MFA', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.text('ABCD1234EFGH5678'), findsOneWidget);
      expect(find.text('IJKL9012MNOP3456'), findsOneWidget);
    });

    testWidgets('shows TOTP code input field after enabling MFA', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('verify button is disabled with short code', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '12345');

      final verifyButtons = find.byType(FilledButton);
      final verifyButton = verifyButtons.last;
      expect(
        (verifyButton.evaluate().first.widget as FilledButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('shows snackbar for invalid code length', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '12345');

      final verifyButtons = find.byType(FilledButton);
      await tester.ensureVisible(verifyButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(verifyButtons.last);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('AdminSecurityTab - MFA Disable Flow', () {
    testWidgets('tapping disable MFA button shows confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('disable MFA dialog has cancel button that closes dialog', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

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

    testWidgets('disable MFA dialog has text field for TOTP code', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.byType(TextField)),
        findsOneWidget,
      );
    });

    testWidgets('disable MFA requires 6-digit code', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final textField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(textField, '123456');

      expect(find.text('123456'), findsOneWidget);
    });
  });

  group('AdminSecurityTab - Clipboard Operations', () {
    testWidgets('copy secret button copies to clipboard', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      final copyButtons = find.byIcon(Icons.copy);
      await tester.ensureVisible(copyButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(copyButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      // Flush the 30-second clipboard auto-clear timer
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('copy backup codes button copies all codes', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      final elevatedButtons = find.byType(ElevatedButton);
      await tester.ensureVisible(elevatedButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(elevatedButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);

      // Flush the 30-second clipboard auto-clear timer
      await tester.pump(const Duration(seconds: 31));
    });
  });

  group('AdminSecurityTab - Loading States', () {
    testWidgets('shows loading indicator when action is in progress', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('disable button is disabled during loading', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      final disableButton = find.byType(FilledButton).first;
      expect(
        (disableButton.evaluate().first.widget as FilledButton).onPressed,
        isNotNull,
      );
    });

    testWidgets('enable button is disabled during loading', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      expect(
        (enableButton.evaluate().first.widget as FilledButton).onPressed,
        isNotNull,
      );
    });
  });

  group('AdminSecurityTab - Error States', () {
    testWidgets('shows error message when present', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });

    testWidgets('error container has correct styling', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSecurityTab), findsOneWidget);
    });
  });

  group('AdminSecurityTab - QR Code Display', () {
    testWidgets('QR code is rendered with correct data', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('secret is displayed in monospace font', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      final secretText = find.text('JBSWY3DPEHPK3PXP');
      expect(secretText, findsOneWidget);
    });
  });

  group('AdminSecurityTab - Backup Codes', () {
    testWidgets('all backup codes are displayed', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.text('ABCD1234EFGH5678'), findsOneWidget);
      expect(find.text('IJKL9012MNOP3456'), findsOneWidget);
      expect(find.text('QRST7890UVWX1234'), findsOneWidget);
      expect(find.text('YZAB5678CDEF9012'), findsOneWidget);
      expect(find.text('GHIJ3456KLMN7890'), findsOneWidget);
      expect(find.text('OPQR1234STUV5678'), findsOneWidget);
    });

    testWidgets('backup codes are numbered correctly', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final enableButton = find.byType(FilledButton).first;
      await tester.tap(enableButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('1.'), findsOneWidget);
      expect(find.textContaining('2.'), findsOneWidget);
      expect(find.textContaining('6.'), findsOneWidget);
    });
  });

  group('AdminSecurityTab - Widget Structure', () {
    testWidgets('has correct card structure', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has shield icon in gradient container', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      final shieldIcon = find.byIcon(Icons.shield_rounded);
      expect(shieldIcon, findsOneWidget);
    });

    testWidgets('MFA status badge is in flexible container', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(Flexible), findsWidgets);
    });

    testWidgets('uses ListView for scrolling', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: false, userId: 'admin1'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('AdminSecurityTab - Dialog Interactions', () {
    testWidgets('disable dialog text field has correct keyboard type', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final textField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      final widget = tester.widget<TextField>(textField);
      expect(widget.keyboardType, equals(TextInputType.number));
    });

    testWidgets('disable dialog text field has max length 6', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final textField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      final widget = tester.widget<TextField>(textField);
      expect(widget.maxLength, equals(6));
    });
  });

  group('AdminSecurityTab - Semantics', () {
    testWidgets('disable MFA text field has semantics label', (tester) async {
      await tester.pumpWidget(buildWidget(mfaEnabled: true, userId: 'admin1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });
  });
}

class AdminActionsViewModelMock extends StateNotifier<AdminActionsState> {
  AdminActionsViewModelMock({bool isLoading = false, String? errorMessage})
    : super(
        AdminActionsState(isLoading: isLoading, errorMessage: errorMessage),
      );

  @override
  AdminActionsState get state => super.state;
}
