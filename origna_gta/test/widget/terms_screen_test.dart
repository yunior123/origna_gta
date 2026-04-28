import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/terms/terms_provider.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';
import 'package:flutter/material.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  group('TermsScreen', () {
    testWidgets('renders seeded terms content from provider', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            termsProvider.overrideWith(
              (ref) async => '''
1. ACCEPTANCE OF TERMS
These are the preview-safe terms.

2. PRIVACY
We protect buyer and seller data.
''',
            ),
          ],
          child: const TermsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Acceptance of Terms'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('shows loading state while terms are pending', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        TestWrapper(
          overrides: [termsProvider.overrideWith((ref) => completer.future)],
          child: const TermsScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows error state when terms provider fails', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            termsProvider.overrideWith(
              (ref) => Future<String>.error(Exception('terms failed')),
            ),
          ],
          child: const TermsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
