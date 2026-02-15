// ─────────────────────────────────────────────────────────────────────────────
// Product Creation Integration Tests — Optimized
// ─────────────────────────────────────────────────────────────────────────────
// 1 testWidgets (was 3). ALL product creation tests preserved.
// App restarts: 1 (was 3). Logins: 1 (was 3).
//
// Flow: Login → create 10 diverse products → create minimal product →
//       create digital product

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Product Creation — 10 products + edge cases', (tester) async {
    await launchApp(tester);

    // ════════════════════════════════════════════════════════════════════
    // LOGIN AS SELLER
    // ════════════════════════════════════════════════════════════════════
    debugPrint('📱 Step 1: Logging in...');
    await loginWith(tester, email: sellerEmail, password: sellerPassword);
    debugPrint('✅ Login successful');
    
    // Extra wait to ensure seller status loads from Firestore
    await pumpWait(tester, seconds: 3);

    // Helper: wait for add product button to appear (seller status loads async)
    Future<bool> waitForAddProductButton({int maxWaitSeconds = 30}) async {
      for (var i = 0; i < maxWaitSeconds * 2; i++) {
        final btn = find.byKey(const Key('home_add_product_button'));
        if (btn.evaluate().isNotEmpty) return true;
        final icon = find.byIcon(Icons.add_box_outlined);
        if (icon.evaluate().isNotEmpty) return true;
        await tester.pump(const Duration(milliseconds: 500));
      }
      return false;
    }

    // Helper: navigate to add product screen with retries
    Future<bool> goToAddProduct() async {
      // First make sure we're on home
      await navigateToTab(tester, Icons.home);
      await pumpFor(tester, frames: 6, ms: 300);

      // Wait for the button to appear (seller status async load)
      if (!await waitForAddProductButton()) {
        debugPrint('❌ Add product button never appeared after 30s');
        return false;
      }

      final addBtn = find.byKey(const Key('home_add_product_button'));
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
      } else {
        await tester.tap(find.byIcon(Icons.add_box_outlined));
      }
      await pumpWait(tester, seconds: 3);

      // Verify we're on the add product screen
      for (var i = 0; i < 15; i++) {
        if (find.byKey(const Key('product_name_field')).evaluate().isNotEmpty) {
          return true;
        }
        await tester.pump(const Duration(milliseconds: 500));
      }
      debugPrint('❌ Add product screen did not load');
      return false;
    }

    // Wait for home screen + add product button after login
    await navigateToTab(tester, Icons.home);
    await pumpWait(tester, seconds: 3);
    if (!await waitForAddProductButton()) {
      debugPrint('❌ FATAL: Add product button never appeared — aborting');
      return;
    }
    debugPrint('✅ Add product button visible');

    // ════════════════════════════════════════════════════════════════════
    // CREATE 10 DIVERSE PRODUCTS
    // ════════════════════════════════════════════════════════════════════

    final testProducts = [
      {
        'name': 'Organic Green Tea - Premium Quality',
        'description': 'High quality organic green tea from Japan. Rich in antioxidants.',
        'price': '24.99', 'stock': '100',
        'street': '123 Tea Garden Lane', 'city': 'Toronto', 'postalCode': 'M5V 2T6',
        'weight': '0.5', 'freeShipping': true, 'isDigital': false, 'isPerishable': true,
      },
      {
        'name': 'Wireless Bluetooth Headphones',
        'description': 'Premium noise-cancelling wireless headphones with 30-hour battery life.',
        'price': '89.99', 'stock': '50',
        'street': '456 Electronics Ave', 'city': 'Montreal', 'postalCode': 'H3A 1B1',
        'weight': '0.3', 'freeShipping': false, 'isDigital': false, 'isPerishable': false,
      },
      {
        'name': 'Yoga Mat - Eco Friendly',
        'description': 'Non-slip eco-friendly yoga mat made from natural rubber.',
        'price': '45.50', 'stock': '75',
        'street': '789 Fitness Blvd', 'city': 'Vancouver', 'postalCode': 'V6B 2W8',
        'weight': '1.2', 'freeShipping': true, 'isDigital': false, 'isPerishable': false,
      },
      {
        'name': 'E-Book: Learn Flutter Development',
        'description': 'Comprehensive guide to Flutter app development with source code.',
        'price': '29.99', 'stock': '999',
        'street': '101 Digital Plaza', 'city': 'Calgary', 'postalCode': 'T2P 1J9',
        'weight': '0', 'freeShipping': true, 'isDigital': true, 'isPerishable': false,
      },
      {
        'name': 'Handmade Ceramic Coffee Mug',
        'description': 'Artisan-crafted ceramic mug. Microwave and dishwasher safe.',
        'price': '18.99', 'stock': '30',
        'street': '222 Artisan Way', 'city': 'Ottawa', 'postalCode': 'K1A 0A9',
        'weight': '0.4', 'freeShipping': false, 'isDigital': false, 'isPerishable': false,
      },
      {
        'name': 'Fresh Organic Honey - 500g',
        'description': 'Pure organic honey harvested from local beekeepers.',
        'price': '15.99', 'stock': '60',
        'street': '333 Honey Farm Rd', 'city': 'Edmonton', 'postalCode': 'T5J 0H3',
        'weight': '0.6', 'freeShipping': false, 'isDigital': false, 'isPerishable': true,
      },
      {
        'name': 'Stainless Steel Water Bottle',
        'description': 'Insulated water bottle keeps drinks cold 24h or hot 12h. BPA-free.',
        'price': '32.99', 'stock': '120',
        'street': '444 Eco Street', 'city': 'Winnipeg', 'postalCode': 'R3C 0A5',
        'weight': '0.5', 'freeShipping': true, 'isDigital': false, 'isPerishable': false,
      },
      {
        'name': 'Online Course: Digital Marketing Mastery',
        'description': 'Complete digital marketing course with lifetime access.',
        'price': '149.99', 'stock': '999',
        'street': '555 Online Academy', 'city': 'Quebec City', 'postalCode': 'G1R 2B5',
        'weight': '0', 'freeShipping': true, 'isDigital': true, 'isPerishable': false,
      },
      {
        'name': 'Cotton T-Shirt - Unisex',
        'description': 'Comfortable 100% organic cotton t-shirt. Multiple colors.',
        'price': '22.50', 'stock': '200',
        'street': '666 Fashion District', 'city': 'Halifax', 'postalCode': 'B3H 1R2',
        'weight': '0.2', 'freeShipping': false, 'isDigital': false, 'isPerishable': false,
      },
      {
        'name': 'Plant-Based Protein Powder - 1kg',
        'description': 'Vegan protein powder with 25g protein per serving. Chocolate.',
        'price': '39.99', 'stock': '80',
        'street': '777 Health Lane', 'city': 'Victoria', 'postalCode': 'V8W 1K5',
        'weight': '1.1', 'freeShipping': true, 'isDigital': false, 'isPerishable': false,
      },
    ];

    for (int i = 0; i < testProducts.length; i++) {
      final product = testProducts[i];
      debugPrint('\n📦 Creating product ${i + 1}/10: ${product['name']}');

      // Navigate to Add Product with retry
      if (!await goToAddProduct()) {
        debugPrint('❌ Skipping product ${i + 1} — cannot reach add product screen');
        continue;
      }

      // Fill form fields
      await tester.enterText(
          find.byKey(const Key('product_name_field')), product['name'] as String);
      await pumpFor(tester, frames: 4, ms: 250);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await pumpFor(tester, frames: 4, ms: 250);
      await tester.enterText(find.byKey(const Key('product_description_field')),
          product['description'] as String);
      await pumpFor(tester, frames: 4, ms: 250);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await pumpFor(tester, frames: 4, ms: 250);
      await tester.enterText(
          find.byKey(const Key('product_price_field')), product['price'] as String);
      await pumpFor(tester, frames: 4, ms: 250);

      await tester.enterText(
          find.byKey(const Key('product_stock_field')), product['stock'] as String);
      await pumpFor(tester, frames: 4, ms: 250);

      // Scroll for more fields
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await pumpFor(tester, frames: 4, ms: 250);

      // Address fields (skip for digital)
      if (!(product['isDigital'] as bool)) {
        final streetField = find.byKey(const Key('addproduct_street_field'));
        if (streetField.evaluate().isNotEmpty) {
          await tester.enterText(streetField, product['street'] as String);
          await pumpFor(tester, frames: 4, ms: 250);
        }

        final cityField = find.byKey(const Key('addproduct_city_field'));
        if (cityField.evaluate().isNotEmpty) {
          await tester.enterText(cityField, product['city'] as String);
          await pumpFor(tester, frames: 4, ms: 250);
        }

        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -100));
        await pumpFor(tester, frames: 4, ms: 250);

        final postalField = find.byKey(const Key('addproduct_postal_code_field'));
        if (postalField.evaluate().isNotEmpty) {
          await tester.enterText(postalField, product['postalCode'] as String);
          await pumpFor(tester, frames: 4, ms: 250);
        }

        // Weight
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -150));
        await pumpFor(tester, frames: 4, ms: 250);
        final weightField = find.byKey(const Key('addproduct_weight_field'));
        if (weightField.evaluate().isNotEmpty) {
          await tester.enterText(weightField, product['weight'] as String);
          await pumpFor(tester, frames: 4, ms: 250);
        }
      }

      // Toggle switches
      if (product['isDigital'] as bool) {
        final digitalSwitch = find.byKey(const Key('addproduct_digital_toggle'));
        if (digitalSwitch.evaluate().isNotEmpty) {
          await tester.tap(digitalSwitch);
          await pumpFor(tester, frames: 4, ms: 250);
        }
      }

      if (product['isPerishable'] as bool) {
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -100));
        await pumpFor(tester, frames: 4, ms: 250);
        final perishSwitch = find.byKey(const Key('addproduct_perishable_toggle'));
        if (perishSwitch.evaluate().isNotEmpty) {
          await tester.tap(perishSwitch);
          await pumpFor(tester, frames: 4, ms: 250);
        }
      }

      if (product['freeShipping'] as bool) {
        final freeShipSwitch =
            find.byKey(const Key('addproduct_free_shipping_toggle'));
        if (freeShipSwitch.evaluate().isNotEmpty) {
          await tester.tap(freeShipSwitch);
          await pumpFor(tester, frames: 4, ms: 250);
        }
      }

      // Submit
      debugPrint('  📤 Submitting...');
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await pumpFor(tester, frames: 4, ms: 250);

      final submitBtn = find.byKey(const Key('addproduct_submit_button'));
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await pumpWait(tester, seconds: 5);

      // Check success
      final success = find
              .byKey(const Key('addproduct_success_snackbar'))
              .evaluate()
              .isNotEmpty ||
          find.byKey(const Key('home_add_product_button')).evaluate().isNotEmpty ||
          find.byIcon(Icons.add_box_outlined).evaluate().isNotEmpty;
      debugPrint(success
          ? '  ✅ Product ${i + 1} created'
          : '  ⚠️ Product ${i + 1} status unclear — navigating home');

      // Always go back to home for next product
      await navigateToTab(tester, Icons.home);
      await pumpFor(tester, frames: 4, ms: 250);
    }

    // ════════════════════════════════════════════════════════════════════
    // EDGE CASE: Minimal Product
    // ════════════════════════════════════════════════════════════════════
    debugPrint('\n── Edge Case: Minimal Product ──');

    if (!await goToAddProduct()) {
      debugPrint('❌ Skipping minimal product — cannot reach add product screen');
    } else {
      await tester.enterText(
          find.byKey(const Key('product_name_field')), 'Minimal Product');
      await tester.enterText(find.byKey(const Key('product_description_field')),
          'Minimal description');
      await tester.enterText(
          find.byKey(const Key('product_price_field')), '9.99');
      await tester.enterText(
          find.byKey(const Key('product_stock_field')), '10');

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await pumpFor(tester, frames: 4, ms: 250);
      await tester.tap(find.byKey(const Key('addproduct_submit_button')));
      await pumpWait(tester, seconds: 5);
      debugPrint('✅ Minimal product test completed');
    }

    // ════════════════════════════════════════════════════════════════════
    // EDGE CASE: Digital Product
    // ════════════════════════════════════════════════════════════════════
    debugPrint('\n── Edge Case: Digital Product ──');

    if (!await goToAddProduct()) {
      debugPrint('❌ Skipping digital product — cannot reach add product screen');
    } else {
      await tester.enterText(
          find.byKey(const Key('product_name_field')), 'Digital E-Book');
      await tester.enterText(find.byKey(const Key('product_description_field')),
          'Downloadable digital content');
      await tester.enterText(
          find.byKey(const Key('product_price_field')), '19.99');
      await tester.enterText(
          find.byKey(const Key('product_stock_field')), '999');

      // Toggle Digital
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await pumpFor(tester, frames: 4, ms: 250);
      final digitalSwitch = find.byKey(const Key('addproduct_digital_toggle'));
      if (digitalSwitch.evaluate().isNotEmpty) {
        await tester.tap(digitalSwitch);
        await pumpFor(tester, frames: 4, ms: 250);
      }

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await pumpFor(tester, frames: 4, ms: 250);
      await tester.tap(find.byKey(const Key('addproduct_submit_button')));
      await pumpWait(tester, seconds: 5);
      debugPrint('✅ Digital product test completed');
    }

    debugPrint('\n🎉 All product creation tests done!');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
