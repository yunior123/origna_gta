import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/screens/seller_integration_screen.dart';

import '../test_utils.dart';

void main() {
  setUp(() {
    initTestMocks();
  });

  Widget createTestWidget() {
    return TestWrapper(child: const SellerIntegrationScreen());
  }

  group('SellerIntegrationScreen Widget Tests', () {
    testWidgets('renders screen title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.title'.tr()), findsOneWidget);
    });

    testWidgets('shows intro card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.intro_title'.tr()), findsOneWidget);
    });

    testWidgets('shows how it works card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('seller_integration.how_it_works_title'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows book integration card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.book_title'.tr()), findsOneWidget);
    });

    testWidgets('shows error codes card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.error_title'.tr()), findsOneWidget);
    });

    testWidgets('shows security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('seller_integration.security_title'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows code blocks with copy functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsWidgets);
    });

    testWidgets('shows step rows in intro', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.intro_step1'.tr()), findsOneWidget);
      expect(find.text('seller_integration.intro_step2'.tr()), findsOneWidget);
    });

    testWidgets('shows body text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('seller_integration.intro_p1'.tr()), findsOneWidget);
    });

    testWidgets('shows step rows in security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('seller_integration.security_step1'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows integration icon in intro card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.integration_instructions_outlined),
        findsOneWidget,
      );
    });

    testWidgets('shows lock icon in how it works card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    });

    testWidgets('shows shield icon in security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });
  });
}
