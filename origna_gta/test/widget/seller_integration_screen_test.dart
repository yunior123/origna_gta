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
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('seller_integration.title'.tr()), findsOneWidget);
    });

    testWidgets('shows intro card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('seller_integration.intro_title'.tr()), findsOneWidget);
    });

    testWidgets('shows how it works card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('seller_integration.how_it_works_title'.tr()),
        findsOneWidget,
      );
    });

    testWidgets('shows book integration card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Documentation'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Documentation'), findsOneWidget);
    });

    testWidgets('shows error codes card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Common Error Codes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Common Error Codes'), findsOneWidget);
    });

    testWidgets('shows security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Security Best Practices'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Security Best Practices'), findsOneWidget);
    });

    testWidgets('shows code blocks with copy functionality', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.copy), findsWidgets);
    });

    testWidgets('shows step rows in intro', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('seller_integration.intro_step1'.tr()), findsOneWidget);
      expect(find.text('seller_integration.intro_step2'.tr()), findsOneWidget);
    });

    testWidgets('shows body text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('seller_integration.intro_p1'.tr()), findsOneWidget);
    });

    testWidgets('shows step rows in security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.text('Always use HTTPS for API calls'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Always use HTTPS for API calls'), findsOneWidget);
    });

    testWidgets('shows integration icon in intro card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byIcon(Icons.integration_instructions_outlined),
        findsOneWidget,
      );
    });

    testWidgets('shows lock icon in how it works card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
    });

    testWidgets('shows shield icon in security card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byIcon(Icons.shield_outlined),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('renders preview endpoints when injected', (tester) async {
      await tester.pumpWidget(TestWrapper(
        child: const SellerIntegrationScreen(
          previewActivateEndpoint:
              'https://api.dev.orignagta.ca/api/digital/activate-license',
          previewVerifyEndpoint:
              'https://api.dev.orignagta.ca/api/digital/verify-license',
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text(
          'https://api.dev.orignagta.ca/api/digital/activate-license',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'https://api.dev.orignagta.ca/api/digital/verify-license',
        ),
        findsOneWidget,
      );
    });
  });
}
