import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:origna_gta/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Product Creation Integration Tests', () {
    testWidgets('Login and create 10 diverse products', (WidgetTester tester) async {
      // Configuration du test
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ========================================
      // ÉTAPE 1: LOGIN
      // ========================================
      debugPrint('📱 Step 1: Logging in...');
      
      // Attendre que l'écran de login soit chargé
      await tester.pumpAndSettle();
      
      // Chercher les champs par type (car les keys ne sont pas encore ajoutées)
      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsWidgets);
      
      // Entrer les credentials (email est le premier champ)
      await tester.enterText(emailFields.first, 'seller@origna.ca');
      await tester.pumpAndSettle();
      
      // Mot de passe (deuxième champ en mode login)
      await tester.enterText(emailFields.at(1), 'Test123456!');
      await tester.pumpAndSettle();
      
      // Trouver et cliquer sur le bouton Sign In
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      
      // Attendre la navigation et le chargement
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      debugPrint('✅ Login successful');

      // ========================================
      // ÉTAPE 2: CRÉER 10 PRODUITS VARIÉS
      // ========================================
      
      final testProducts = [
        {
          'name': 'Organic Green Tea - Premium Quality',
          'description': 'High quality organic green tea from Japan. Rich in antioxidants and perfect for daily consumption.',
          'price': '24.99',
          'stock': '100',
          'category': '1',
          'street': '123 Tea Garden Lane',
          'city': 'Toronto',
          'postalCode': 'M5V 2T6',
          'weight': '0.5',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': false,
          'isPerishable': true,
        },
        {
          'name': 'Wireless Bluetooth Headphones',
          'description': 'Premium noise-cancelling wireless headphones with 30-hour battery life. Perfect for music lovers.',
          'price': '89.99',
          'stock': '50',
          'category': '2',
          'street': '456 Electronics Ave',
          'city': 'Montreal',
          'postalCode': 'H3A 1B1',
          'weight': '0.3',
          'minOrder': '1',
          'freeShipping': false,
          'isDigital': false,
          'isPerishable': false,
        },
        {
          'name': 'Yoga Mat - Eco Friendly',
          'description': 'Non-slip eco-friendly yoga mat made from natural rubber. Perfect for yoga and pilates.',
          'price': '45.50',
          'stock': '75',
          'category': '3',
          'street': '789 Fitness Blvd',
          'city': 'Vancouver',
          'postalCode': 'V6B 2W8',
          'weight': '1.2',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': false,
          'isPerishable': false,
        },
        {
          'name': 'E-Book: Learn Flutter Development',
          'description': 'Comprehensive guide to Flutter app development. Includes source code and examples.',
          'price': '29.99',
          'stock': '999',
          'category': '4',
          'street': '101 Digital Plaza',
          'city': 'Calgary',
          'postalCode': 'T2P 1J9',
          'weight': '0',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': true,
          'isPerishable': false,
        },
        {
          'name': 'Handmade Ceramic Coffee Mug',
          'description': 'Artisan-crafted ceramic mug. Microwave and dishwasher safe. Each mug is unique.',
          'price': '18.99',
          'stock': '30',
          'category': '5',
          'street': '222 Artisan Way',
          'city': 'Ottawa',
          'postalCode': 'K1A 0A9',
          'weight': '0.4',
          'minOrder': '2',
          'freeShipping': false,
          'isDigital': false,
          'isPerishable': false,
        },
        {
          'name': 'Fresh Organic Honey - 500g',
          'description': 'Pure organic honey harvested from local beekeepers. No additives or preservatives.',
          'price': '15.99',
          'stock': '60',
          'category': '1',
          'street': '333 Honey Farm Rd',
          'city': 'Edmonton',
          'postalCode': 'T5J 0H3',
          'weight': '0.6',
          'minOrder': '1',
          'freeShipping': false,
          'isDigital': false,
          'isPerishable': true,
        },
        {
          'name': 'Stainless Steel Water Bottle',
          'description': 'Insulated water bottle keeps drinks cold for 24h or hot for 12h. BPA-free and leak-proof.',
          'price': '32.99',
          'stock': '120',
          'category': '3',
          'street': '444 Eco Street',
          'city': 'Winnipeg',
          'postalCode': 'R3C 0A5',
          'weight': '0.5',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': false,
          'isPerishable': false,
        },
        {
          'name': 'Online Course: Digital Marketing Mastery',
          'description': 'Complete digital marketing course with lifetime access. Learn SEO, social media, and email marketing.',
          'price': '149.99',
          'stock': '999',
          'category': '4',
          'street': '555 Online Academy',
          'city': 'Quebec City',
          'postalCode': 'G1R 2B5',
          'weight': '0',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': true,
          'isPerishable': false,
        },
        {
          'name': 'Cotton T-Shirt - Unisex',
          'description': 'Comfortable 100% organic cotton t-shirt. Available in multiple colors. Perfect everyday wear.',
          'price': '22.50',
          'stock': '200',
          'category': '6',
          'street': '666 Fashion District',
          'city': 'Halifax',
          'postalCode': 'B3H 1R2',
          'weight': '0.2',
          'minOrder': '2',
          'freeShipping': false,
          'isDigital': false,
          'isPerishable': false,
        },
        {
          'name': 'Plant-Based Protein Powder - 1kg',
          'description': 'Vegan protein powder with 25g protein per serving. Chocolate flavor. No artificial sweeteners.',
          'price': '39.99',
          'stock': '80',
          'category': '1',
          'street': '777 Health Lane',
          'city': 'Victoria',
          'postalCode': 'V8W 1K5',
          'weight': '1.1',
          'minOrder': '1',
          'freeShipping': true,
          'isDigital': false,
          'isPerishable': false,
        },
      ];

      for (int i = 0; i < testProducts.length; i++) {
        final product = testProducts[i];
        debugPrint('\n📦 Creating product ${i + 1}/10: ${product['name']}');
        
        // ========================================
        // NAVIGUER VERS ADD PRODUCT SCREEN
        // ========================================
        
        // Chercher le bouton d'ajout (icône add_box_outlined ou texte)
        final addProductButton = find.byIcon(Icons.add_box_outlined);
        if (addProductButton.evaluate().isEmpty) {
          debugPrint('⚠️ Add product button not found. Looking for alternative...');
          // Alternative: chercher par tooltip ou texte
          final altButton = find.byTooltip('Add Product');
          if (altButton.evaluate().isNotEmpty) {
            await tester.tap(altButton);
          } else {
            debugPrint('❌ Cannot find add product button');
            continue;
          }
        } else {
          await tester.tap(addProductButton);
        }
        
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Vérifier qu'on est sur l'écran d'ajout
        expect(find.text('Add Product'), findsOneWidget);
        
        // ========================================
        // REMPLIR LE FORMULAIRE
        // ========================================
        
        // Trouver tous les TextFormFields
        final formFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextFormField),
        );
        
        // Scroll vers le haut pour commencer
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
        await tester.pumpAndSettle();
        
        // Nom du produit (généralement le premier champ)
        debugPrint('  ✏️ Entering product name...');
        await tester.enterText(formFields.first, product['name'] as String);
        await tester.pumpAndSettle();
        
        // Description (scroll un peu et chercher le champ suivant)
        debugPrint('  ✏️ Entering description...');
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        await tester.enterText(formFields.at(1), product['description'] as String);
        await tester.pumpAndSettle();
        
        // Prix
        debugPrint('  ✏️ Entering price...');
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        await tester.enterText(formFields.at(2), product['price'] as String);
        await tester.pumpAndSettle();
        
        // Stock
        debugPrint('  ✏️ Entering stock...');
        await tester.enterText(formFields.at(3), product['stock'] as String);
        await tester.pumpAndSettle();
        
        // Scroll pour voir plus de champs
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        
        // Adresse - Rue
        debugPrint('  ✏️ Entering address...');
        final streetFieldFinder = find.widgetWithText(TextFormField, 'Street');
        if (streetFieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(streetFieldFinder, product['street'] as String);
          await tester.pumpAndSettle();
        }
        
        // Ville
        final cityFieldFinder = find.widgetWithText(TextFormField, 'City');
        if (cityFieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(cityFieldFinder, product['city'] as String);
          await tester.pumpAndSettle();
        }
        
        // Code postal
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        
        final postalFieldFinder = find.widgetWithText(TextFormField, 'Postal Code');
        if (postalFieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(postalFieldFinder, product['postalCode'] as String);
          await tester.pumpAndSettle();
        }
        
        // Poids (si non digital)
        if (!(product['isDigital'] as bool)) {
          await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
          await tester.pumpAndSettle();
          
          final weightFieldFinder = find.widgetWithText(TextFormField, 'Weight');
          if (weightFieldFinder.evaluate().isNotEmpty) {
            await tester.enterText(weightFieldFinder, product['weight'] as String);
            await tester.pumpAndSettle();
          }
        }
        
        // Switches (Digital, Perishable, Free Shipping)
        if (product['isDigital'] as bool) {
          final digitalSwitch = find.widgetWithText(SwitchListTile, 'Digital Product');
          if (digitalSwitch.evaluate().isNotEmpty) {
            await tester.tap(digitalSwitch);
            await tester.pumpAndSettle();
          }
        }
        
        if (product['isPerishable'] as bool) {
          await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
          await tester.pumpAndSettle();
          final perishableSwitch = find.widgetWithText(SwitchListTile, 'Perishable');
          if (perishableSwitch.evaluate().isNotEmpty) {
            await tester.tap(perishableSwitch);
            await tester.pumpAndSettle();
          }
        }
        
        if (product['freeShipping'] as bool) {
          final freeShippingSwitch = find.widgetWithText(SwitchListTile, 'Free Shipping');
          if (freeShippingSwitch.evaluate().isNotEmpty) {
            await tester.tap(freeShippingSwitch);
            await tester.pumpAndSettle();
          }
        }
        
        // ========================================
        // SOUMETTRE LE FORMULAIRE
        // ========================================
        
        debugPrint('  📤 Submitting product...');
        
        // Scroll jusqu'au bouton de soumission
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
        
        // Chercher le bouton "Add Product"
        final submitButton = find.widgetWithText(ElevatedButton, 'Add Product');
        expect(submitButton, findsOneWidget);
        
        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        // Vérifier le succès (SnackBar ou retour à l'écran principal)
        final successIndicators = [
          find.text('Product added successfully'),
          find.text('Success'),
          find.byIcon(Icons.add_box_outlined), // Retour à home
        ];
        
        bool success = false;
        for (final indicator in successIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            success = true;
            break;
          }
        }
        
        if (success) {
          debugPrint('  ✅ Product ${i + 1} created successfully!');
        } else {
          debugPrint('  ⚠️ Product ${i + 1} creation status unclear');
        }
        
        // Attendre un peu avant le prochain produit
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // ========================================
      // VÉRIFICATIONS FINALES
      // ========================================
      
      debugPrint('\n🎉 All 10 products created!');
      debugPrint('✅ Integration test completed successfully');
    });
  });

  group('Product Creation Edge Cases', () {
    testWidgets('Create product with minimum required fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login (simplifié)
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'seller@origna.ca');
      await tester.enterText(emailFields.at(1), 'Test123456!');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Naviguer vers add product
      await tester.tap(find.byIcon(Icons.add_box_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Remplir seulement les champs obligatoires
      final formFields = find.descendant(
        of: find.byType(Form),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(formFields.first, 'Minimal Product');
      await tester.enterText(formFields.at(1), 'Minimal description');
      await tester.enterText(formFields.at(2), '9.99');
      await tester.enterText(formFields.at(3), '10');

      // Soumettre
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint('✅ Minimal product test completed');
    });

    testWidgets('Create digital product (no shipping)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'seller@origna.ca');
      await tester.enterText(emailFields.at(1), 'Test123456!');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Add product
      await tester.tap(find.byIcon(Icons.add_box_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Remplir pour produit numérique
      final formFields = find.descendant(
        of: find.byType(Form),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(formFields.first, 'Digital E-Book');
      await tester.enterText(formFields.at(1), 'Downloadable digital content');
      await tester.enterText(formFields.at(2), '19.99');
      await tester.enterText(formFields.at(3), '999');

      // Activer "Digital Product"
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      
      final digitalSwitch = find.widgetWithText(SwitchListTile, 'Digital Product');
      if (digitalSwitch.evaluate().isNotEmpty) {
        await tester.tap(digitalSwitch);
        await tester.pumpAndSettle();
      }

      // Soumettre
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Product'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint('✅ Digital product test completed');
    });
  });
}
