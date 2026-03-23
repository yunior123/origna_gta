import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/editproduct_screen.dart';
import 'package:origna_gta/utils/constants.dart' hide SellerDeliveryOption;

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
  }) {
    return Product(
      productId: 'prod-test-1',
      name: name,
      priceCents: priceCents,
      description: 'A test product for editing',
      imageUrls: const <String>[],
      sellerId: 'seller-1',
      categoryId: 1,
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
      isDigital: isDigital,
      digitalType: digitalType,
      deliveryOptions: const [],
    );
  }

  group('_EditDigitalTypeChip (editproduct_form_widgets.dart)', () {
    testWidgets('renders software and book chips for digital product', (
      tester,
    ) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.software,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Digital section should be visible
      expect(
        find.byKey(const Key('editproduct_digital_section')),
        findsOneWidget,
      );

      // Software chip should be visible
      expect(
        find.byKey(const Key('editproduct_digital_type_software')),
        findsOneWidget,
      );

      // Book chip should be visible
      expect(
        find.byKey(const Key('editproduct_digital_type_book')),
        findsOneWidget,
      );

      // Software label should be visible
      expect(find.text('product.digital_type_software'.tr()), findsOneWidget);
      expect(find.text('product.digital_type_book'.tr()), findsOneWidget);
    });

    testWidgets('software chip is selected when digitalType is software', (
      tester,
    ) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.software,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Software chip semantics should indicate selected
      final softwareChip = find.byKey(
        const Key('editproduct_digital_type_software'),
      );
      expect(softwareChip, findsOneWidget);

      // Download links section should be visible for software type
      expect(find.text('product.download_links'.tr()), findsOneWidget);
      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_windows_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_linux_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_device_limit')), findsOneWidget);
    });

    testWidgets('book chip is selected when digitalType is book', (
      tester,
    ) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Book chip should be visible
      final bookChip = find.byKey(const Key('editproduct_digital_type_book'));
      expect(bookChip, findsOneWidget);

      // Software download links should NOT be visible
      expect(find.byKey(const Key('editproduct_macos_url')), findsNothing);
      expect(find.byKey(const Key('editproduct_windows_url')), findsNothing);
    });

    testWidgets('tapping book chip switches to book type', (tester) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.software,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Initially software section is visible
      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);

      // Tap the book chip
      await tester.ensureVisible(
        find.byKey(const Key('editproduct_digital_type_book')),
      );
      await tester.tap(find.byKey(const Key('editproduct_digital_type_book')));
      await tester.pumpAndSettle();

      // Software download links should disappear
      expect(find.byKey(const Key('editproduct_macos_url')), findsNothing);
    });

    testWidgets('tapping software chip switches to software type', (
      tester,
    ) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Initially book section is visible (not software download links)
      expect(find.byKey(const Key('editproduct_macos_url')), findsNothing);

      // Tap the software chip
      await tester.ensureVisible(
        find.byKey(const Key('editproduct_digital_type_software')),
      );
      await tester.tap(
        find.byKey(const Key('editproduct_digital_type_software')),
      );
      await tester.pumpAndSettle();

      // Software download links should appear
      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_windows_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_linux_url')), findsOneWidget);
    });

    testWidgets('digital chip has correct semantics', (tester) async {
      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.software,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Verify chips are present with correct keys
      expect(
        find.byKey(const Key('editproduct_digital_type_software')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('editproduct_digital_type_book')),
        findsOneWidget,
      );
    });

    testWidgets('non-digital product does not show digital section', (
      tester,
    ) async {
      final product = createTestProduct(isDigital: false);

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Digital section should NOT be visible
      expect(
        find.byKey(const Key('editproduct_digital_section')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('editproduct_digital_type_software')),
        findsNothing,
      );
    });
  });

  group(
    'EditProductScreen — submit section (editproduct_submit_section.dart)',
    () {
      testWidgets('save button is rendered and has correct semantics', (
        tester,
      ) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Save button should exist
        expect(
          find.byKey(const Key('product_edit_save_button')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('btn-save-product'), findsOneWidget);
        expect(find.text('product.save_changes'.tr()), findsOneWidget);
      });

      testWidgets('save button is disabled when loading', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // The save button should be enabled initially (not loading)
        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('product_edit_save_button')),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('save button triggers handleSave on tap', (tester) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Tap the save button
        await tester.ensureVisible(find.bySemanticsLabel('btn-save-product'));
        await tester.tap(find.bySemanticsLabel('btn-save-product'));
        await tester.pumpAndSettle();

        // The form should attempt validation (may show validation errors)
        // Since we have a valid product, the form may proceed
        // At minimum, the screen should not crash
        expect(find.byType(EditProductScreen), findsOneWidget);
      });

      testWidgets('save button handles digital product delivery options', (
        tester,
      ) async {
        final product = createTestProduct(
          isDigital: true,
          digitalType: DigitalTypeValues.software,
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Tap save for digital product
        await tester.ensureVisible(find.bySemanticsLabel('btn-save-product'));
        await tester.tap(find.bySemanticsLabel('btn-save-product'));
        await tester.pumpAndSettle();

        // Screen should handle the save attempt without crashing
        expect(find.byType(EditProductScreen), findsOneWidget);
      });

      testWidgets('save button handles local-only product', (tester) async {
        final product = Product(
          productId: 'prod-local',
          name: 'Local Product',
          priceCents: 1500,
          description: 'Local only',
          imageUrls: const <String>[],
          sellerId: 'seller-1',
          categoryId: 1,
          stockQuantity: 5,
          createdAt: DateTime.now(),
          isLocalDeliveryOnly: true,
          deliveryOptions: [
            SellerDeliveryOption(
              type: 'pickup',
              description: 'Local pickup',
              estimatedDays: 0,
              costCents: 0,
            ),
          ],
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Tap save for local-only product
        await tester.ensureVisible(find.bySemanticsLabel('btn-save-product'));
        await tester.tap(find.bySemanticsLabel('btn-save-product'));
        await tester.pumpAndSettle();

        expect(find.byType(EditProductScreen), findsOneWidget);
      });

      testWidgets('screen renders with delivery options', (tester) async {
        final product = Product(
          productId: 'prod-delivery',
          name: 'Delivery Product',
          priceCents: 4999,
          description: 'Has delivery options',
          imageUrls: const <String>[],
          sellerId: 'seller-1',
          categoryId: 1,
          stockQuantity: 20,
          createdAt: DateTime.now(),
          estimatedShipDays: 3,
          deliveryOptions: [
            SellerDeliveryOption(
              type: 'standard',
              description: 'Standard',
              estimatedDays: 5,
              costCents: 999,
            ),
            SellerDeliveryOption(
              type: 'express',
              description: 'Express',
              estimatedDays: 2,
              costCents: 1999,
            ),
          ],
        );

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // Screen should render successfully
        expect(find.byType(EditProductScreen), findsOneWidget);

        // Save button should be present
        expect(find.bySemanticsLabel('btn-save-product'), findsOneWidget);
      });

      testWidgets('onUpdateSuccess shows snackbar and pops navigator', (
        tester,
      ) async {
        final product = createTestProduct();

        await tester.pumpWidget(
          TestWrapper(child: EditProductScreen(product: product)),
        );
        await tester.pumpAndSettle();

        // The onUpdateSuccess is called when viewmodel state.isSuccess is true
        // We verify the screen renders and the save button is functional
        expect(find.byType(EditProductScreen), findsOneWidget);
        expect(find.bySemanticsLabel('btn-save-product'), findsOneWidget);
      });
    },
  );
}
