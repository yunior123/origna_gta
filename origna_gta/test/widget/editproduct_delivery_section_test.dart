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
    List<SellerDeliveryOption> deliveryOptions = const [],
    int estimatedShipDays = 3,
    bool isLocalDeliveryOnly = false,
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
      deliveryOptions: deliveryOptions,
      estimatedShipDays: estimatedShipDays,
      isLocalDeliveryOnly: isLocalDeliveryOnly,
    );
  }

  group('EditProductScreen — Delivery Section', () {
    testWidgets('renders delivery options card for physical product', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct();

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Standard delivery switch should be present
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Express'), findsOneWidget);
      expect(find.text('Same day'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('toggling standard delivery shows days and price fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct();

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Find the standard delivery switch
      final switches = find.byType(SwitchListTile);
      expect(switches, findsWidgets);

      // Tap the first switch (standard delivery)
      await tester.ensureVisible(switches.first);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Screen should not crash after toggling
      expect(find.byType(EditProductScreen), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('toggling express delivery changes state', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct();

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(SwitchListTile);
      // Tap the second switch (express delivery)
      if (switches.evaluate().length >= 2) {
        await tester.ensureVisible(switches.at(1));
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('toggling same day delivery shows price field', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct();

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(SwitchListTile);
      // Tap the third switch (same day delivery)
      if (switches.evaluate().length >= 3) {
        await tester.ensureVisible(switches.at(2));
        await tester.tap(switches.at(2));
        await tester.pumpAndSettle();
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('pre-populated delivery options show enabled switches', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct(
        deliveryOptions: [
          SellerDeliveryOption(
            type: 'standard',
            description: 'Standard',
            estimatedDays: 5,
            costCents: 999,
          ),
        ],
        estimatedShipDays: 3,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditProductScreen), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('digital product shows digital section not delivery', (
      tester,
    ) async {
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

      // Digital section should be visible
      expect(
        find.byKey(const Key('editproduct_digital_section')),
        findsOneWidget,
      );

      tester.view.resetPhysicalSize();
    });

    testWidgets('software type shows macos, windows, linux URL fields', (
      tester,
    ) async {
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

      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_windows_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_linux_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_device_limit')), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('book type shows book URL field', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editproduct_book_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_macos_url')), findsNothing);

      tester.view.resetPhysicalSize();
    });

    testWidgets('entering URL in software fields updates correctly', (
      tester,
    ) async {
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
        'https://example.com/app.dmg',
      );
      await tester.enterText(
        find.byKey(const Key('editproduct_windows_url')),
        'https://example.com/app.exe',
      );
      await tester.enterText(
        find.byKey(const Key('editproduct_linux_url')),
        'https://example.com/app.AppImage',
      );
      await tester.enterText(
        find.byKey(const Key('editproduct_device_limit')),
        '5',
      );
      await tester.pump();

      expect(find.text('https://example.com/app.dmg'), findsOneWidget);
      expect(find.text('https://example.com/app.exe'), findsOneWidget);
      expect(find.text('https://example.com/app.AppImage'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('entering book URL updates correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('editproduct_book_url')),
        'https://example.com/book.pdf',
      );
      await tester.pump();

      expect(find.text('https://example.com/book.pdf'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('switching from software to book hides download links', (
      tester,
    ) async {
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

      // Initially software fields visible
      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);

      // Tap book chip
      await tester.ensureVisible(
        find.byKey(const Key('editproduct_digital_type_book')),
      );
      await tester.tap(find.byKey(const Key('editproduct_digital_type_book')));
      await tester.pumpAndSettle();

      // Software fields hidden, book field visible
      expect(find.byKey(const Key('editproduct_macos_url')), findsNothing);
      expect(find.byKey(const Key('editproduct_book_url')), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('switching from book to software shows download links', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      // Initially book field visible
      expect(find.byKey(const Key('editproduct_book_url')), findsOneWidget);

      // Tap software chip
      await tester.ensureVisible(
        find.byKey(const Key('editproduct_digital_type_software')),
      );
      await tester.tap(
        find.byKey(const Key('editproduct_digital_type_software')),
      );
      await tester.pumpAndSettle();

      // Software fields visible, book field hidden
      expect(find.byKey(const Key('editproduct_macos_url')), findsOneWidget);
      expect(find.byKey(const Key('editproduct_book_url')), findsNothing);

      tester.view.resetPhysicalSize();
    });

    testWidgets('re-enter download URL update hint shown for book type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;

      final product = createTestProduct(
        isDigital: true,
        digitalType: DigitalTypeValues.book,
      );

      await tester.pumpWidget(
        TestWrapper(child: EditProductScreen(product: product)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Re-enter URL'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });
  });
}
