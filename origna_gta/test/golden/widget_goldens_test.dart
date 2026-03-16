import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_card.dart';

// Golden tests require platform-specific rendering — skip in CI (Ubuntu renders differently from macOS).
// Run locally to regenerate: flutter test test/golden/ --update-goldens
@Tags(['golden'])
library;

void main() {
  group('Golden Tests', () {
    testWidgets('ModernButton primary golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernButton(
                label: 'Add to Cart',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernButton),
        matchesGoldenFile('goldens/modern_button_primary.png'),
      );
    });

    testWidgets('ModernButton outlined golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernButton(
                label: 'Cancel',
                onPressed: () {},
                isOutlined: true,
                isPrimary: false,
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernButton),
        matchesGoldenFile('goldens/modern_button_outlined.png'),
      );
    });

    testWidgets('ModernButton loading golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernButton(
                label: 'Loading...',
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernButton),
        matchesGoldenFile('goldens/modern_button_loading.png'),
      );
    });

    testWidgets('ModernButton disabled golden', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernButton(
                label: 'Disabled',
                onPressed: null,
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernButton),
        matchesGoldenFile('goldens/modern_button_disabled.png'),
      );
    });

    testWidgets('ModernButton with icon golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernButton(
                label: 'Search',
                onPressed: () {},
                icon: Icons.search,
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernButton),
        matchesGoldenFile('goldens/modern_button_icon.png'),
      );
    });

    testWidgets('ModernCard golden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ModernCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Product Name'),
                        const SizedBox(height: 8),
                        const Text('\$29.99'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(ModernCard),
        matchesGoldenFile('goldens/modern_card.png'),
      );
    });
  });
}
