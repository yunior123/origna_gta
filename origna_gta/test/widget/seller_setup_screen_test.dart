import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';
import 'package:origna_gta/screens/seller_setup_screen.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_button.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('SellerSetupRefreshScreen', () {
    Widget buildRefreshWidget() {
      return TestWrapper(child: const SellerSetupRefreshScreen());
    }

    testWidgets('renders refresh screen', (tester) async {
      await tester.pumpWidget(buildRefreshWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SellerSetupRefreshScreen), findsOneWidget);
    });

    testWidgets('renders refresh icon', (tester) async {
      await tester.pumpWidget(buildRefreshWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('renders continue setup button', (tester) async {
      await tester.pumpWidget(buildRefreshWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ModernButton), findsWidgets);
    });

    testWidgets('renders back to home button', (tester) async {
      await tester.pumpWidget(buildRefreshWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('SellerSetupCompleteScreen', () {
    Widget buildCompleteWidget({SellerAccountStatus? status}) {
      final effectiveStatus =
          status ??
          const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: true,
            detailsSubmitted: true,
          );

      return TestWrapper(
        overrides: [
          sellerAccountStatusProvider.overrideWith(
            (_) => Stream.value(effectiveStatus),
          ),
          refreshSellerStatusProvider(
            null,
          ).overrideWith((_) => Future.value(effectiveStatus)),
          currentUserProvider.overrideWithValue(
            AppAuthUser(uid: 'user1', email: 'test@test.com'),
          ),
          userProfileProvider.overrideWith(
            (_) => Stream.value(
              UserModel(
                uid: 'user1',
                email: 'test@test.com',
                name: 'Test',
                roles: [UserRole.seller],
                createdAt: DateTime.now(),
              ),
            ),
          ),
        ],
        child: const SellerSetupCompleteScreen(),
      );
    }

    testWidgets('renders completed state when account is complete', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: true,
            detailsSubmitted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SellerSetupCompleteScreen), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders pending verification state', (tester) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: false,
            detailsSubmitted: true,
            hasPendingRequirements: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SellerSetupCompleteScreen), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    });

    testWidgets('renders incomplete state', (tester) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: false,
            detailsSubmitted: false,
            hasPendingRequirements: true,
            pendingRequirements: ['external_account'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SellerSetupCompleteScreen), findsOneWidget);
    });

    testWidgets('completed state shows start selling button', (tester) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: true,
            detailsSubmitted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModernButton), findsWidgets);
    });

    testWidgets('pending state shows go to home button', (tester) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: false,
            detailsSubmitted: true,
            hasPendingRequirements: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModernButton), findsWidgets);
    });

    testWidgets('incomplete shows continue setup button', (tester) async {
      await tester.pumpWidget(
        buildCompleteWidget(
          status: const SellerAccountStatus(
            isSeller: true,
            chargesEnabled: false,
            detailsSubmitted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModernButton), findsWidgets);
    });

    testWidgets('renders with gradient background', (tester) async {
      await tester.pumpWidget(buildCompleteWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });
}
