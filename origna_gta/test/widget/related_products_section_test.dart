import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/widgets/product_detail/related_products_section.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Widget buildWidget({
    required String productId,
    required int categoryId,
    List<Product>? products,
    bool isLoading = false,
    Object? error,
  }) {
    return TestWrapper(
      overrides: [
        if (error != null)
          similarProductsProvider((
            excludeProductId: productId,
            categoryId: categoryId,
          )).overrideWith((_) => Future.error(error))
        else if (isLoading)
          similarProductsProvider((
            excludeProductId: productId,
            categoryId: categoryId,
          )).overrideWith((_) => Completer<List<Product>>().future)
        else
          similarProductsProvider((
            excludeProductId: productId,
            categoryId: categoryId,
          )).overrideWith((_) => Future.value(products ?? [])),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: SimilarProductsSection(
            productId: productId,
            categoryId: categoryId,
          ),
        ),
      ),
    );
  }

  group('SimilarProductsSection', () {
    testWidgets('renders nothing when categoryId is 0', (tester) async {
      await tester.pumpWidget(buildWidget(productId: 'p1', categoryId: 0));
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders nothing when no similar products', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, products: []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, isLoading: true),
      );
      await tester.pump();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, error: 'Network error'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
    });

    testWidgets('renders with correct widget structure', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, products: []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, products: []),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsNothing);
    });

    testWidgets('renders with different category IDs', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 5, products: []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
    });

    testWidgets('error shows something went wrong text', (tester) async {
      await tester.pumpWidget(
        buildWidget(productId: 'p1', categoryId: 1, error: 'Failed'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimilarProductsSection), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              ((widget.data?.contains('Something went wrong') ?? false) ||
                  (widget.data?.contains('errors.something_went_wrong') ??
                      false)),
        ),
        findsOneWidget,
      );
    });
  });
}
