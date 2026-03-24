import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Product createTestProduct({
    bool isDigital = false,
    String? digitalType,
    String name = 'Test Product',
    int priceCents = 2999,
    int stockQuantity = 10,
    String lifecycleStatus = ProductLifecycleStatusValues.active,
    String? approvalRejectionReason,
    List<String> imageUrls = const [],
  }) {
    return Product(
      productId: 'prod-test-1',
      name: name,
      priceCents: priceCents,
      description: 'A test product for editing',
      imageUrls: imageUrls,
      sellerId: 'seller-1',
      categoryId: 1,
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
      isDigital: isDigital,
      digitalType: digitalType,
      lifecycleStatus: lifecycleStatus,
      approvalRejectionReason: approvalRejectionReason,
    );
  }

  group('EditProductScreen — Shared Widgets', () {
    group('section titles', () {
      testWidgets('screen renders all section titles', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditProductScreen), findsOneWidget);
        // Core sections should be visible
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.text('Images'), findsOneWidget);
        expect(find.text('Shipping & Delivery'), findsOneWidget);
      });
    });

    group('approval status banner', () {
      testWidgets('active product shows no approval banner', (tester) async {
        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.active,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rejected'), findsNothing);
      });

      testWidgets('approved product shows no approval banner', (tester) async {
        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.approved,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rejected'), findsNothing);
      });

      testWidgets('rejected product shows rejection banner with reason', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.rejected,
          approvalRejectionReason: 'Inappropriate content',
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rejected'), findsOneWidget);
        expect(find.text('Inappropriate content'), findsOneWidget);

        tester.view.resetPhysicalSize();
      });

      testWidgets('rejected product without reason shows generic message', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.rejected,
          approvalRejectionReason: null,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rejected'), findsOneWidget);
        expect(find.text('Generic rejection'), findsOneWidget);

        tester.view.resetPhysicalSize();
      });

      testWidgets('under review product shows review banner', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.underReview,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Under review'), findsOneWidget);
        expect(find.text('Review note'), findsOneWidget);

        tester.view.resetPhysicalSize();
      });

      testWidgets('draft product shows under review banner', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          lifecycleStatus: ProductLifecycleStatusValues.draft,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Under review'), findsOneWidget);

        tester.view.resetPhysicalSize();
      });
    });

    group('tappable info hint', () {
      testWidgets('screen renders without info hint errors', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Screen should render without errors
        expect(find.byType(EditProductScreen), findsOneWidget);

        tester.view.resetPhysicalSize();
      });
    });

    group('image grid', () {
      testWidgets('product with no images does not show image grid', (
        tester,
      ) async {
        final product = createTestProduct(imageUrls: []);

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Remove image'), findsNothing);
      });

      testWidgets('product with images shows remove icon', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          imageUrls: ['https://example.com/img1.jpg'],
        );

        // Suppress network image errors in test environment
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('NetworkImageLoadException')) return;
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // The remove icon button should be present
        expect(find.byIcon(Icons.remove_circle), findsOneWidget);

        FlutterError.onError = originalOnError;
        tester.view.resetPhysicalSize();
      });
    });

    group('URL field widget', () {
      testWidgets('URL fields accept text input', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          isDigital: true,
          digitalType: DigitalTypeValues.software,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('editproduct_macos_url')),
          'https://example.com/download',
        );
        await tester.pump();

        expect(find.text('https://example.com/download'), findsOneWidget);

        tester.view.resetPhysicalSize();
      });

      testWidgets('empty URL field does not crash', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct(
          isDigital: true,
          digitalType: DigitalTypeValues.software,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        final macosField = find.byKey(const Key('editproduct_macos_url'));
        await tester.enterText(macosField, 'https://example.com');
        await tester.pump();
        await tester.enterText(macosField, '');
        await tester.pump();

        expect(find.byType(EditProductScreen), findsOneWidget);

        tester.view.resetPhysicalSize();
      });
    });

    group('address suggestions', () {
      testWidgets('screen renders without errors', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;

        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditProductScreen), findsOneWidget);

        tester.view.resetPhysicalSize();
      });
    });

    group('save button shared widget', () {
      testWidgets('save button renders with correct semantics', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('product_edit_save_button')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('btn-save-product'), findsOneWidget);
      });

      testWidgets('save button is enabled initially', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('product_edit_save_button')),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('tapping save does not crash', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.bySemanticsLabel('btn-save-product'));
        await tester.tap(find.bySemanticsLabel('btn-save-product'));
        await tester.pumpAndSettle();

        expect(find.byType(EditProductScreen), findsOneWidget);
      });
    });
  });
}
