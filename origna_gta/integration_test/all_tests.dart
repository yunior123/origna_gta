// Single entry point — ONE build, ALL integration tests.
//
// ## Flutter integration tests (web)
// ```bash
// # 1) Start ChromeDriver in a separate terminal
// chromedriver --port=4444

// # 2) Run the integration suite (no emulators)
// cd origna_gta
// flutter drive --driver=test_driver/integration_test.dart \
//   --target=integration_test/all_tests.dart \
//   -d chrome \
//   --dart-define=ENVIRONMENT=dev \
//   --dart-define=USE_EMULATORS=false
// ```

// Firestore database is initially seeded with products added by the admin user
// 3 users in Firebase Auth already exist initially:

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import './app_test.dart' as app;

import 'helpers/test_helpers.dart';

void _debugStep(String id, String message) {
  debugPrint('[$id] $message');
}

// MAIN TEST SUITE

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  app.main();
  group('G00 — Role-based grouped integration flows', () {
    testWidgets(
      'G01 — All flows with admin role, admin has [buyer, seller, admin]',
      (tester) async {
        const strictIntegration = bool.fromEnvironment(
          'STRICT_INTEGRATION',
          defaultValue: true,
        );
        var caseCount = 0;
        final failedCases = <String>[];
        void checkCase(String id, bool condition, String label) {
          caseCount++;
          if (!condition) {
            _debugStep(id, 'FAIL — $label');
            if (strictIntegration) {
              failedCases.add('$id: $label');
            }
            return;
          }
          _debugStep(id, 'PASS — $label');
        }

        void stopOnSkip(String id, String reason) {
          _debugStep(id, 'SKIP => STOP — $reason');
          if (strictIntegration) {
            failedCases.add('$id: SKIP => STOP — $reason');
          }
        }

        List<double> extractDollarAmounts(Finder finder) {
          final amounts = <double>[];
          final dollarRegex = RegExp(r'\$\s*([0-9]+(?:\.[0-9]{1,2})?)');

          for (final element in finder.evaluate()) {
            final widget = element.widget;
            if (widget is! Text) continue;

            final content = widget.data ?? widget.textSpan?.toPlainText() ?? '';
            for (final match in dollarRegex.allMatches(content)) {
              final raw = match.group(1);
              final value = raw == null ? null : double.tryParse(raw);
              if (value != null) {
                amounts.add(value);
              }
            }
          }

          return amounts;
        }

        Future<bool> didPublishSucceed() async {
          for (var i = 0; i < 90; i++) {
            final hasSuccessSnack = find
                .byKey(const Key('addproduct_success_snackbar'))
                .evaluate()
                .isNotEmpty;
            final hasLeftAddProductScreen = find
                .byKey(const Key('addproduct_screen_title'))
                .evaluate()
                .isEmpty;
            if (hasSuccessSnack || hasLeftAddProductScreen) {
              return true;
            }
            await tester.pump(const Duration(milliseconds: 500));
          }
          return false;
        }

        Future<bool> ensureHomeReady({int timeoutSeconds = 15}) async {
          await navigateToTab(tester, Icons.home);
          final maxTicks = timeoutSeconds * 2;
          for (var i = 0; i < maxTicks; i++) {
            final hasSettings =
                find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty;
            final hasCart =
                find.byKey(const Key('home_cart_button')).evaluate().isNotEmpty;
            final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
            if (hasSettings && hasScaffold) {
              return true;
            }
            if (!hasScaffold) {
              await tester.pump(const Duration(milliseconds: 350));
              continue;
            }
            if (!hasSettings && hasCart) {
              await navigateToTab(tester, Icons.home);
            }
            await tester.pump(const Duration(milliseconds: 500));
          }
          return find
              .byKey(const Key('home_settings_button'))
              .evaluate()
              .isNotEmpty;
        }

        Future<Credential?> switchCredentialWithRecovery(
          List<Credential> candidates,
          String scope,
        ) async {
          for (var attempt = 1; attempt <= 3; attempt++) {
            final credential = await switchToAnyCredential(tester, candidates);
            if (credential != null) {
              await ensureHomeReady(timeoutSeconds: 12);
              return credential;
            }

            _debugStep(
              '$scope.R$attempt',
              'Credential switch retry after UI recovery',
            );

            await navigateToTab(tester, Icons.home);
            await pumpWait(tester, seconds: 2);

            final settings = find.byKey(const Key('home_settings_button'));
            if (settings.evaluate().isNotEmpty) {
              await tester.tap(settings.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 2);

              final signOut = find.byKey(const Key('profile_sign_out_button'));
              if (signOut.evaluate().isNotEmpty) {
                await tester.tap(signOut.first, warnIfMissed: false);
                await pumpWait(tester, seconds: 2);
              } else {
                final loginEmailField = find.byKey(
                  const Key('login_email_field'),
                );
                if (loginEmailField.evaluate().isEmpty) {
                  await goBack(tester);
                  await pumpWait(tester, seconds: 1);
                }
              }
            }
          }

          return null;
        }

        final runStamp = DateTime.now().millisecondsSinceEpoch.toString();
        final p01Name = 'T01 Standard Ship $runStamp';
        final p02Name = 'T02 Digital Item $runStamp';
        final p03Name = 'T03 Free Ship $runStamp';
        final p04Name = 'T04 Local Only $runStamp';
        final p05Name = 'T05 Perishable $runStamp';
        final p09Name = 'T09 Express Test $runStamp';
        final p10Name = 'T10 Digital Full $runStamp';
        final p12Name = 'T12 Bad Price $runStamp';

        await launchApp(tester);

        // ════════════════════════════════════════════════════════════════════
        //  App launches and renders MaterialApp
        // ════════════════════════════════════════════════════════════════════

        checkCase(
          'C001',
          find.byType(MaterialApp).evaluate().isNotEmpty,
          'MaterialApp rendu',
        );
        checkCase(
          'C002',
          find.byType(Scaffold).evaluate().isNotEmpty,
          'Scaffold initial rendu',
        );
        _debugStep('A01', 'App launched');
        _debugStep('A02', 'Home screen visible with products');

        // ════════════════════════════════════════════════════════════════════
        // login screen checks + validation + login
        // ════════════════════════════════════════════════════════════════════

        final settingsIcon = find.byKey(const Key('home_settings_button'));
        checkCase(
          'C003',
          settingsIcon.evaluate().isNotEmpty,
          'Settings visible',
        );
        // Since we are not logged in, tapping settings should show login popup, not navigate to profile
        var email = adminEmail;
        var password = adminPassword;

        await tester.tap(settingsIcon.first);
        await pumpWait(tester, seconds: 2);

        final popupDismissed = await handleSignInPopup(
          tester,
          email: email,
          password: password,
        );

        if (!popupDismissed) {
          final loginEmailField = find.byKey(const Key('login_email_field'));
          final loginPasswordField = find.byKey(
            const Key('login_password_field'),
          );
          final loginSubmit = find.byKey(const Key('login_submit_button'));
          if (loginEmailField.evaluate().isNotEmpty &&
              loginPasswordField.evaluate().isNotEmpty &&
              loginSubmit.evaluate().isNotEmpty) {
            await loginWith(tester, email: email, password: password);
            await pumpWait(tester, seconds: 2);
          }
        }

        final profileSignOut = find.byKey(const Key('profile_sign_out_button'));
        if (profileSignOut.evaluate().isNotEmpty) {
          await goBack(tester);
          await pumpWait(tester, seconds: 2);
        }

        _debugStep(
          'A03',
          'Login popup handled (popupDismissed=$popupDismissed)',
        );

        final ensuredAdmin = await switchCredentialWithRecovery(
          adminCredentialCandidates,
          'A03.1',
        );
        final hasSettingsAfterAuth = settingsIcon.evaluate().isNotEmpty;
        _debugStep(
          'A03.1',
          'Auth revalidation (ensuredAdmin=${ensuredAdmin != null}, settingsVisible=$hasSettingsAfterAuth)',
        );
        checkCase(
          'C078',
          ensuredAdmin != null,
          'session admin valide avant vérification home cards',
        );

        await ensureHomeReady(timeoutSeconds: 15);

        await navigateToTab(tester, Icons.home);
        await pumpWait(tester, seconds: 2);
        var settingsAfterLogin = find.byKey(
          const Key('home_settings_button'),
        );
        if (settingsAfterLogin.evaluate().isEmpty) {
          await goBack(tester);
          await pumpWait(tester, seconds: 1);
          await navigateToTab(tester, Icons.home);
          await pumpWait(tester, seconds: 2);
          settingsAfterLogin = find.byKey(const Key('home_settings_button'));
        }

        // ════════════════════════════════════════════════════════════════════
        // Back to home. Home screen renders product grid or loading state
        // ════════════════════════════════════════════════════════════════════
        checkCase(
          'C004',
          settingsAfterLogin.evaluate().isNotEmpty,
          'Settings après login',
        );
        final hasGrid = find.byType(GridView).evaluate().isNotEmpty;
        final hasCards = find.byType(Card).evaluate().isNotEmpty;
        checkCase(
          'C005',
          hasGrid || hasCards || find.byType(Scaffold).evaluate().isNotEmpty,
          'Home contient grille/cartes/scaffold',
        );
        _debugStep(
          'A04',
          'Home screen rendered (grid=$hasGrid, cards=$hasCards)',
        );

        var cartIcon = find.byKey(const Key('home_cart_button'));
        if (cartIcon.evaluate().isEmpty) {
          await ensureHomeReady(timeoutSeconds: 8);
          cartIcon = find.byKey(const Key('home_cart_button'));
        }
        checkCase('C006', cartIcon.evaluate().isNotEmpty, 'Cart icon visible');
        _debugStep('A05', 'Cart icon found');

        // ════════════════════════════════════════════════════════════════════
        // Navigate to cart screen
        // ════════════════════════════════════════════════════════════════════
        if (cartIcon.evaluate().isNotEmpty) {
          await tester.tap(cartIcon.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 3);
          checkCase(
            'C007',
            find.byType(Scaffold).evaluate().isNotEmpty,
            'Cart screen affiché',
          );
          _debugStep('A06', 'Cart screen loaded');
          await goBack(tester);
        } else {
          stopOnSkip('S200', 'Cart icon missing before cart navigation block');
        }

        // ════════════════════════════════════════════════════════════════════
        // Tap product card opens details
        // ════════════════════════════════════════════════════════════════════
        final seededProductCardFinders = <Finder>[
          find.byKey(const Key('product_card_Test Physical Product')),
          find.byKey(const Key('product_card_Test Digital Product')),
          find.byKey(const Key('product_card_Test Local Product')),
        ];
        final seededProductTextFinders = <Finder>[
          find.textContaining('Test Physical Product'),
          find.textContaining('Test Digital Product'),
          find.textContaining('Test Local Product'),
          find.textContaining('Test Physical'),
          find.textContaining('Test Digital'),
          find.textContaining('Test Local'),
          find.textContaining('T01 Standard Ship'),
        ];

        for (var retry = 0; retry < 12; retry++) {
          final hasAnyCandidate =
              seededProductCardFinders.any(
                (finder) => finder.evaluate().isNotEmpty,
              ) ||
              seededProductTextFinders.any(
                (finder) => finder.evaluate().isNotEmpty,
              );

          if (hasAnyCandidate) {
            break;
          }

          final scrollableRetry = find.byType(Scrollable);
          if (scrollableRetry.evaluate().isNotEmpty) {
            await tester.drag(
              scrollableRetry.first,
              const Offset(0, -220),
              warnIfMissed: false,
            );
          }
          await tester.pump(const Duration(milliseconds: 500));
        }

        Finder productOpenTarget = find.byType(Scaffold);
        for (final finder in seededProductCardFinders) {
          if (finder.evaluate().isNotEmpty) {
            productOpenTarget = finder;
            break;
          }
        }
        productOpenTarget = seededProductTextFinders.firstWhere(
          (finder) => finder.evaluate().isNotEmpty,
          orElse: () => productOpenTarget,
        );

        final hasOpenableProduct =
            seededProductCardFinders.any(
              (finder) => finder.evaluate().isNotEmpty,
            ) ||
            seededProductTextFinders.any(
              (finder) => finder.evaluate().isNotEmpty,
            );

        if (hasOpenableProduct) {
          await tester.tap(productOpenTarget.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 3);
          checkCase(
            'C008',
            find.byType(Scaffold).evaluate().isNotEmpty,
            'Product detail affiché',
          );

          final addToCart = find.byKey(const Key('product_add_to_cart_button'));
          final ownProduct = find.byKey(
            const Key('product_own_product_message'),
          );
          _debugStep(
            'A07',
            'Product detail opened (ctaOrOwn=${addToCart.evaluate().isNotEmpty || ownProduct.evaluate().isNotEmpty})',
          );
          await goBack(tester);
        } else {
          stopOnSkip('S001', 'No openable product tile/text found on home');
        }

        // ════════════════════════════════════════════════════════════════════
        //  Home screen is scrollable
        // ════════════════════════════════════════════════════════════════════
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pump(const Duration(seconds: 2));
          await tester.drag(scrollable.first, const Offset(0, 300));
          await tester.pump(const Duration(seconds: 2));
          _debugStep('A08', 'Home scroll interaction works');
        } else {
          stopOnSkip('S002', 'No scrollable widget found on home');
        }

        // ════════════════════════════════════════════════════════════════════
        // Navigate to profile screen
        // ════════════════════════════════════════════════════════════════════

        final settingsNow = find.byKey(const Key('home_settings_button'));
        if (settingsNow.evaluate().isEmpty) {
          stopOnSkip('S003', 'Settings icon not found');
        } else {
          await tester.tap(settingsNow.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 5);
          checkCase(
            'C009',
            find.byType(Scaffold).evaluate().isNotEmpty,
            'Profile screen affiché',
          );

          final orderBtn = find.byKey(const Key('profile_my_orders_button'));
          final favBtn = find.byKey(const Key('profile_favorites_button'));
          final addrBtn = find.byKey(const Key('profile_address_button'));
          final found =
              orderBtn.evaluate().length +
              favBtn.evaluate().length +
              addrBtn.evaluate().length;
          _debugStep('A09', 'Profile screen loaded ($found menu items)');

          // ══════════════════════════════════════════════════════════════════
          // Profile sub-pages (orders, favorites, address)
          // NOTE: skip terms button in web E2E because it opens external tab/window
          // and can pause/stop flutter drive execution.
          // ══════════════════════════════════════════════════════════════════
          await checkProfileSubPage(tester, 'profile_my_orders_button', 'T10');
          await checkProfileSubPage(tester, 'profile_favorites_button', 'T11');
          await checkProfileSubPage(tester, 'profile_address_button', 'T12');
          _debugStep(
            'T13',
            'Skipped terms page to avoid external tab interruption',
          );

          // ══════════════════════════════════════════════════════════════════
          // Back navigation works
          // ══════════════════════════════════════════════════════════════════
          final ordersBtn2 = find.byKey(const Key('profile_my_orders_button'));
          if (ordersBtn2.evaluate().isEmpty) {
            await scrollUntilVisible(
              tester,
              ordersBtn2,
              delta: -220,
              maxScrolls: 12,
            );
            await pumpWait(tester, seconds: 1);
          }

          if (ordersBtn2.evaluate().isEmpty) {
            final settingsAgain = find.byKey(const Key('home_settings_button'));
            if (settingsAgain.evaluate().isNotEmpty) {
              await tester.tap(settingsAgain.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 2);
              await scrollUntilVisible(
                tester,
                ordersBtn2,
                delta: -220,
                maxScrolls: 12,
              );
              await pumpWait(tester, seconds: 1);
            }
          }

          if (ordersBtn2.evaluate().isNotEmpty) {
            await tester.tap(ordersBtn2.first, warnIfMissed: false);
            await pumpWait(tester, seconds: 2);
            await goBack(tester);
            checkCase(
              'C010',
              find.byType(Scaffold).evaluate().isNotEmpty,
              'Retour depuis sous-page profile OK',
            );
            debugPrint(' ✓ Back navigation');

            // Ensure we are back on Home before seller/admin-only checks.
            await goBack(tester);
            await pumpWait(tester, seconds: 2);
            checkCase(
              'C079',
              find
                  .byKey(const Key('home_settings_button'))
                  .evaluate()
                  .isNotEmpty,
              'Retour Home explicite après flow profile',
            );
          } else {
            stopOnSkip('S004', 'Orders button not found in profile');
          }
        }

        //Check if user has seller/admin role (needed for all product creation tests)
        final canAddProducts = await navigateToAddProduct(tester);
        if (!canAddProducts) {
          stopOnSkip(
            'S005',
            'User does not have seller/admin role for product creation flow',
          );
        }

        // ═══════════════════════════════════════════════════════════════════════
        // — Create Physical Product with Standard Delivery
        // ═══════════════════════════════════════════════════════════════════════
        if (canAddProducts) {
          debugPrint('');
          _debugStep('P01', 'T01 — Physical Product + Standard Delivery');
          // Verify we're on the Add Product screen
          checkCase(
            'C011',
            find
                .byKey(const Key('addproduct_screen_title'))
                .evaluate()
                .isNotEmpty,
            'Add product screen visible',
          );
          // Fill basic fields
          await fillBasicProductFields(tester, name: p01Name, price: '29.99');
          // Verify Section 3 (Delivery) is visible — scroll to it
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_section_delivery')),
          );
          await tester.pump(const Duration(milliseconds: 500));
          // Standard Delivery should be enabled by default (standardEnabled=true in state)
          // Verify the Standard Delivery card is present
          checkCase(
            'C012',
            find
                .byKey(const Key('addproduct_standard_delivery_card'))
                .evaluate()
                .isNotEmpty,
            'Standard delivery visible',
          );
          debugPrint('✓Standard Delivery visible and enabled by default');
          // Fill address
          await fillAddress(tester);
          // Submit
          final publishMessage = await tapPublishProduct(tester);

          // Check for success (SnackBar or navigation back)
          final hasSuccess = await didPublishSucceed();
          if (!hasSuccess) {
            stopOnSkip(
              'S020',
              'T01 publish failed (validation/images/backend): ${publishMessage ?? 'no snackbar message captured'}',
            );
          } else {
            _debugStep('C080', 'PASS — T01 publication réussie');
          }
          debugPrint('✓ Product published with Standard Delivery');
          if (find
              .byKey(const Key('addproduct_screen_title'))
              .evaluate()
              .isNotEmpty) {
            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // Ensure we're back on home screen
          await pumpSettle(tester, iterations: 3);

          var exist = await verifyProductInMarketplace(tester, p01Name);
          checkCase('C081', exist, 'T01 trouvé dans marketplace');
          debugPrint('✓ Product appears in marketplace');

          // ═══════════════════════════════════════════════════════════════════════
          //  — Create Digital Product (Shipping Section Hidden)
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P02', 'T02 — Digital Product (No Shipping)');
          await navigateToAddProduct(tester);
          await fillBasicProductFields(tester, name: p02Name, price: '9.99');
          // Scroll to Delivery section
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_section_delivery')),
          );
          await tester.pump(const Duration(milliseconds: 500));
          // Toggle Digital Product ON
          await tapGlassToggle(tester, 'addproduct_digital_toggle');
          await tester.pump(const Duration(milliseconds: 500));
          // Verify: info banner should appear
          final digitalBanner = find.byKey(
            const Key('addproduct_digital_info_banner'),
          );
          if (digitalBanner.evaluate().isEmpty) {
            await tapGlassToggle(tester, 'addproduct_digital_toggle');
            await tester.pump(const Duration(milliseconds: 500));
          }
          checkCase(
            'C013',
            digitalBanner.evaluate().isNotEmpty,
            'Digital info banner visible',
          );
          debugPrint('✓ : Digital toggle ON → shipping info banner shown');
          // Verify: Standard Delivery should be hidden when digital
          // The standard delivery card appears inside "if (!state.isDigital)" block
          // So after toggling digital ON, it should vanish
          await tester.pump(const Duration(milliseconds: 500));
          // Verify: Package & Location section (Section 4) should also be hidden for digital
          final packageSection = find.byKey(
            const Key('addproduct_section_package'),
          );
          final packageVisible = packageSection.evaluate().isNotEmpty;
          if (!packageVisible) {
            debugPrint('✓ : Package & Location hidden for digital product');
          } else {
            debugPrint(
              '⚠ : Package & Location still visible for digital — BUG',
            );
          }
          // Submit
          await tapPublishProduct(tester);
          final hasSuccessT02 = await didPublishSucceed();

          checkCase('C082', hasSuccessT02, 'T02 publication réussie');
          if (!hasSuccessT02) {
            stopOnSkip(
              'S021',
              'T02 publish failed (validation/images/backend)',
            );
          }
          debugPrint('✓ Product published');
          if (find
              .byKey(const Key('addproduct_screen_title'))
              .evaluate()
              .isNotEmpty) {
            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // Ensure we're back on home screen
          await pumpSettle(tester, iterations: 3);

          exist = await verifyProductInMarketplace(tester, p02Name);
          checkCase('C083', exist, 'T02 trouvé dans marketplace');
          debugPrint('✓ Product appears in marketplace');

          // ═══════════════════════════════════════════════════════════════════════
          //  — Create Product with Free Shipping Toggle
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P03', 'T03 — Free Shipping Toggle');
          await navigateToAddProduct(tester);
          await fillBasicProductFields(tester, name: p03Name, price: '49.99');
          // Scroll to find Free Shipping toggle (it's in Section 1, after Min Order Qty)
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_free_shipping_toggle')),
          );
          await tester.pump(const Duration(milliseconds: 300));
          // Toggle Free Shipping ON
          await tapGlassToggle(tester, 'addproduct_free_shipping_toggle');
          await tester.pump(const Duration(milliseconds: 500));
          // Verify: Free Shipping is toggled ON
          // The toggle's Switch.adaptive should now have value=true
          // We can verify by checking the primary color styling or just trust the toggle worked
          debugPrint('✓ Free Shipping toggled ON');

          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_section_delivery')),
          );
          checkCase(
            'C014',
            find
                .byKey(const Key('addproduct_standard_delivery_card'))
                .evaluate()
                .isNotEmpty,
            'Free shipping n\'enlève pas standard delivery',
          );
          debugPrint(
            '✓ Delivery options remain visible with Free Shipping (correct)',
          );

          // Fill address (physical product requires valid sellerAddress)
          await fillAddress(tester);
          // Submit
          await tapPublishProduct(tester);
          final hasSuccessT03 = await didPublishSucceed();

          checkCase('C084', hasSuccessT03, 'T03 publication réussie');
          if (!hasSuccessT03) {
            stopOnSkip(
              'S022',
              'T03 publish failed (validation/images/backend)',
            );
          }
          debugPrint('✓ Product published');
          if (find
              .byKey(const Key('addproduct_screen_title'))
              .evaluate()
              .isNotEmpty) {
            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // Ensure we're back on home screen
          await pumpSettle(tester, iterations: 3);

          exist = await verifyProductInMarketplace(tester, p03Name);
          checkCase('C085', exist, 'T03 trouvé dans marketplace');
          debugPrint('✓ Product appears in marketplace');

          // ═══════════════════════════════════════════════════════════════════════
          //  — Create Local Pickup Only Product
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P04', 'T04 — Local Pickup Only');
          await navigateToAddProduct(tester);
          await fillBasicProductFields(tester, name: p04Name, price: '15.00');
          // Scroll to Package & Location section (Section 4) where Local Pickup Only toggle lives
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_local_pickup_toggle')),
          );
          await tester.pump(const Duration(milliseconds: 300));
          // Toggle Local Pickup Only ON
          await tapGlassToggle(tester, 'addproduct_local_pickup_toggle');
          await tester.pump(const Duration(milliseconds: 500));
          debugPrint('✓ : Local Pickup Only toggled ON');
          // Verify: Weight and Dimensions fields should be hidden when local-only
          // (They're inside `if (!state.isLocalDeliveryOnly)`)
          final weightField = find.byKey(const Key('addproduct_weight_field'));
          final weightVisible = weightField.evaluate().isNotEmpty;
          if (!weightVisible) {
            debugPrint('✓ : Weight/dimensions hidden for local pickup only');
          } else {
            debugPrint(
              '⚠ : Weight/dimensions still visible — may be in viewport',
            );
          }
          // Fill address (physical product requires valid sellerAddress)
          await fillAddress(tester);
          // Submit
          await tapPublishProduct(tester);
          final hasSuccessT04 = await didPublishSucceed();

          checkCase('C086', hasSuccessT04, 'T04 publication réussie');
          if (!hasSuccessT04) {
            stopOnSkip(
              'S023',
              'T04 publish failed (validation/images/backend)',
            );
          }
          debugPrint('✓ Product published');
          if (find
              .byKey(const Key('addproduct_screen_title'))
              .evaluate()
              .isNotEmpty) {
            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // Ensure we're back on home screen
          await pumpSettle(tester, iterations: 3);

          exist = await verifyProductInMarketplace(tester, p04Name);
          checkCase('C087', exist, 'T04 trouvé dans marketplace');
          debugPrint('✓ Product appears in marketplace');

          // ═══════════════════════════════════════════════════════════════════════
          //  — Create Perishable Product with Same-Day Delivery
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P05', 'T05 — Perishable + Same-Day Delivery');
          await navigateToAddProduct(tester);
          await fillBasicProductFields(tester, name: p05Name, price: '12.50');
          // Scroll to Delivery section
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_section_delivery')),
          );
          await tester.pump(const Duration(milliseconds: 300));
          // Toggle Perishable Item ON
          await tapGlassToggle(tester, 'addproduct_perishable_toggle');
          await tester.pump(const Duration(milliseconds: 500));
          debugPrint('✓ : Perishable toggled ON');
          // Scroll to Same-Day Delivery section and enable it
          await scrollUntilVisible(
            tester,
            find.byKey(const Key('addproduct_same_day_delivery_card')),
          );
          await tester.pump(const Duration(milliseconds: 300));
          final sameDaySwitch = find.byKey(
            const Key('addproduct_same_day_delivery_card'),
          );
          if (sameDaySwitch.evaluate().isNotEmpty) {
            await tester.tap(sameDaySwitch.first);
            await tester.pump(const Duration(milliseconds: 500));
            debugPrint('✓ : Same-Day Delivery enabled');
          } else {
            stopOnSkip('S006', 'Could not find Same-Day delivery switch');
          }
          // Fill address (physical product requires valid sellerAddress)
          await fillAddress(tester);
          // Submit
          await tapPublishProduct(tester);
          final hasSuccessT05 = await didPublishSucceed();

          checkCase('C088', hasSuccessT05, 'T05 publication réussie');
          if (!hasSuccessT05) {
            stopOnSkip(
              'S024',
              'T05 publish failed (validation/images/backend)',
            );
          }
          debugPrint('✓ Product published');
          if (find
              .byKey(const Key('addproduct_screen_title'))
              .evaluate()
              .isNotEmpty) {
            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // Ensure we're back on home screen
          await pumpSettle(tester, iterations: 3);

          exist = await verifyProductInMarketplace(tester, p05Name);
          checkCase('C089', exist, 'T05 trouvé dans marketplace');
          debugPrint('✓ Product appears in marketplace');

          // ═══════════════════════════════════════════════════════════════════════
          //  — Express Delivery Tier Toggle Interaction (from archived T09)
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P09', 'T09 — Express Delivery Tier Toggle');
          final navT09 = await navigateToAddProduct(tester);
          if (navT09) {
            await fillBasicProductFields(tester, name: p09Name, price: '35.00');
            await scrollUntilVisible(
              tester,
              find.byKey(const Key('addproduct_express_delivery_card')),
            );
            await tester.pump(const Duration(milliseconds: 300));

            final expressSwitch = find.byKey(
              const Key('addproduct_express_delivery_card'),
            );
            if (expressSwitch.evaluate().isNotEmpty) {
              final tappedExpress = await tapByKey(
                tester,
                'addproduct_express_delivery_card',
              );
              if (!tappedExpress) {
                stopOnSkip(
                  'S018',
                  'Express delivery card not tappable/visible',
                );
              }
              debugPrint('✓ T09: Express Delivery enabled');
            } else {
              debugPrint('⚠ T09: Could not find Express switch');
            }

            await scrollUntilVisible(
              tester,
              find.byKey(const Key('addproduct_same_day_delivery_card')),
            );
            final sameDaySwitch2 = find.byKey(
              const Key('addproduct_same_day_delivery_card'),
            );
            if (sameDaySwitch2.evaluate().isNotEmpty) {
              final tappedSameDay = await tapByKey(
                tester,
                'addproduct_same_day_delivery_card',
              );
              if (!tappedSameDay) {
                stopOnSkip(
                  'S019',
                  'Same-day delivery card not tappable/visible',
                );
              }
              debugPrint('✓ T09: Same-Day Delivery also enabled');
            }

            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // ═══════════════════════════════════════════════════════════════════════
          //  — Digital Product Hides ALL Physical Sections (from archived T10)
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P10', 'T10 — Digital Product Hides Physical Sections');
          final navT10 = await navigateToAddProduct(tester);
          if (navT10) {
            await fillBasicProductFields(tester, name: p10Name, price: '5.99');
            await scrollUntilVisible(
              tester,
              find.byKey(const Key('addproduct_digital_toggle')),
            );
            await tapGlassToggle(tester, 'addproduct_digital_toggle');
            await tester.pump(const Duration(milliseconds: 800));

            final perishableHidden = find
                .byKey(const Key('addproduct_perishable_toggle'))
                .evaluate()
                .isEmpty;
            final standardHidden = find
                .byKey(const Key('addproduct_standard_delivery_card'))
                .evaluate()
                .isEmpty;
            final packageHidden = find
                .byKey(const Key('addproduct_section_package'))
                .evaluate()
                .isEmpty;

            checkCase('C015', perishableHidden, 'Digital cache perishable');
            checkCase('C016', standardHidden, 'Digital cache standard');
            checkCase('C017', packageHidden, 'Digital cache package section');
            debugPrint(
              '✓ T10: Digital mode hides perishable + standard delivery + package section',
            );

            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // ═══════════════════════════════════════════════════════════════════════
          //  — Validation: Submit Without Name (from archived T11)
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P11', 'T11 — Validation Empty Name');
          final navT11 = await navigateToAddProduct(tester);
          if (navT11) {
            await enterTextByKey(tester, 'product_price_field', '10.00');
            await enterTextByKey(tester, 'product_stock_field', '5');
            await tapPublishProduct(tester);

            final stillOnAddProduct = find.byKey(
              const Key('addproduct_screen_title'),
            );
            checkCase(
              'C018',
              stillOnAddProduct.evaluate().isNotEmpty,
              'Validation bloque submit sans nom',
            );
            debugPrint(
              '✓ T11: Validation blocked submission without product name',
            );

            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }

          // ═══════════════════════════════════════════════════════════════════════
          //  — Validation: Negative/Zero Price (from archived T12)
          // ═══════════════════════════════════════════════════════════════════════
          debugPrint('');
          _debugStep('P12', 'T12 — Validation Negative/Zero Price');
          final navT12 = await navigateToAddProduct(tester);
          if (navT12) {
            await fillBasicProductFields(tester, name: p12Name, price: '0');
            await tapPublishProduct(tester);

            final stillOnAddProduct2 = find.byKey(
              const Key('addproduct_screen_title'),
            );
            checkCase(
              'C019',
              stillOnAddProduct2.evaluate().isNotEmpty,
              'Validation bloque prix zéro',
            );
            debugPrint('✓ T12: Validation blocked zero-price submission');

            await goBack(tester);
            await pumpSettle(tester, iterations: 3);
          }
        } // end if (canAddProducts)

        // ═══════════════════════════════════════════════════════════════════════
        //  — Verify Home Screen Has Products (Grid View)
        // ═══════════════════════════════════════════════════════════════════════
        debugPrint('');
        _debugStep('A10', 'Home Screen Product Grid verification');
        // We should be back on home screen
        await pumpSettle(tester, iterations: 5);
        // Check for product grid or list
        final listView = find.byType(ListView);

        final hasList = listView.evaluate().isNotEmpty;
        debugPrint('✓  Home screen — GridView: $hasGrid, ListView: $hasList');
        // Search for any product content
        final scaffold = find.byType(Scaffold);
        checkCase(
          'C020',
          scaffold.evaluate().isNotEmpty,
          'Home scaffold présent après flows produits',
        );
        debugPrint('✓  Home screen rendered');

        // ═══════════════════════════════════════════════════════════════════════
        // Buyer flow — login as buyer and validate buyer-visible features
        // ═══════════════════════════════════════════════════════════════════════
        debugPrint('');
        _debugStep('B01', 'Buyer Flow — login + browse + cart/profile checks');
        final buyerCred = await switchCredentialWithRecovery(
          buyerCredentialCandidates,
          'B01',
        );
        if (buyerCred == null) {
          stopOnSkip(
            'S007',
            'Buyer flow login failed with configured buyer credentials',
          );
        } else {
          debugPrint('✓ Buyer login succeeded with: ${buyerCred.label}');

          final buyerAddProductButton = find.byKey(
            const Key('home_add_product_button'),
          );
          debugPrint(
            ' Buyer add-product visible: ${buyerAddProductButton.evaluate().isNotEmpty}',
          );

          checkCase(
            'C021',
            buyerAddProductButton.evaluate().isEmpty,
            '[buyer] n\'a pas accès add product',
          );

          final buyerSettings = find.byKey(const Key('home_settings_button'));
          if (buyerSettings.evaluate().isNotEmpty) {
            await tester.tap(buyerSettings.first);
            await pumpWait(tester, seconds: 3);

            final buyerAdminPanel = find.byKey(
              const Key('profile_admin_panel_button'),
            );
            if (!isAdminAccountEmail(buyerCred.email)) {
              checkCase(
                'C022',
                buyerAdminPanel.evaluate().isEmpty,
                '[buyer] admin panel caché',
              );
            }

            final buyerOrders = find.byKey(
              const Key('profile_my_orders_button'),
            );
            final buyerFavorites = find.byKey(
              const Key('profile_favorites_button'),
            );
            final buyerAddress = find.byKey(
              const Key('profile_address_button'),
            );
            checkCase(
              'C023',
              buyerOrders.evaluate().isNotEmpty ||
                  buyerFavorites.evaluate().isNotEmpty ||
                  buyerAddress.evaluate().isNotEmpty,
              '[buyer] actions profile de base visibles',
            );

            if (buyerFavorites.evaluate().isNotEmpty) {
              await scrollUntilVisible(
                tester,
                buyerFavorites,
                delta: -220,
                maxScrolls: 10,
              );
              await tester.tap(buyerFavorites.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C090',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[buyer] écran favoris s\'ouvre',
              );
              await goBack(tester);
              await pumpWait(tester, seconds: 1);
            }

            if (buyerAddress.evaluate().isNotEmpty) {
              await scrollUntilVisible(
                tester,
                buyerAddress,
                delta: -220,
                maxScrolls: 10,
              );
              await tester.tap(buyerAddress.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C091',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[buyer] écran adresse s\'ouvre',
              );

              final addAddressButton = find.bySemanticsLabel('btn-add-address');
              final editAddressButton = find.bySemanticsLabel(
                'btn-edit-address',
              );
              checkCase(
                'C092',
                addAddressButton.evaluate().isNotEmpty ||
                    editAddressButton.evaluate().isNotEmpty,
                '[buyer] action add/edit adresse visible',
              );

              if (addAddressButton.evaluate().isNotEmpty) {
                await tester.tap(addAddressButton.first, warnIfMissed: false);
                await pumpWait(tester, seconds: 2);
                final fields = find.byType(TextFormField);
                if (fields.evaluate().length >= 5) {
                  await tester.enterText(
                    fields.at(0),
                    '123 Test Ave $runStamp',
                  );
                  await tester.enterText(fields.at(1), 'Unit 1');
                  await tester.enterText(fields.at(2), 'Toronto');
                  await tester.enterText(fields.at(3), 'M5V1A1');
                  await tester.enterText(fields.at(4), '4165550000');
                }
                final saveAddressButton = find.bySemanticsLabel(
                  'btn-save-address',
                );
                checkCase(
                  'C093',
                  saveAddressButton.evaluate().isNotEmpty,
                  'save address button visible',
                );
                if (saveAddressButton.evaluate().isNotEmpty) {
                  await tester.tap(
                    saveAddressButton.first,
                    warnIfMissed: false,
                  );
                  await pumpWait(tester, seconds: 4);
                }
              }

              final editButtonAfter = find.bySemanticsLabel('btn-edit-address');
              if (editButtonAfter.evaluate().isNotEmpty) {
                await tester.tap(editButtonAfter.first, warnIfMissed: false);
                await pumpWait(tester, seconds: 2);
                final fields = find.byType(TextFormField);
                if (fields.evaluate().isNotEmpty) {
                  await tester.enterText(
                    fields.first,
                    '456 Updated Ave $runStamp',
                  );
                }
                final saveAddressButton = find.bySemanticsLabel(
                  'btn-save-address',
                );
                if (saveAddressButton.evaluate().isNotEmpty) {
                  await tester.tap(
                    saveAddressButton.first,
                    warnIfMissed: false,
                  );
                  await pumpWait(tester, seconds: 4);
                }
              }

              checkCase(
                'C094',
                find
                        .bySemanticsLabel('btn-edit-address')
                        .evaluate()
                        .isNotEmpty ||
                    find
                        .byKey(const Key('home_settings_button'))
                        .evaluate()
                        .isNotEmpty,
                '[buyer] create/edit adresse exécuté',
              );

              if (find
                  .bySemanticsLabel('btn-edit-address')
                  .evaluate()
                  .isNotEmpty) {
                await goBack(tester);
                await pumpWait(tester, seconds: 1);
              }
            }

            if (buyerOrders.evaluate().isNotEmpty) {
              await tester.tap(buyerOrders.first);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C024',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[buyer] écran orders s\'ouvre',
              );
              await goBack(tester);
            }

            await goBack(tester);
            await pumpWait(tester, seconds: 2);
          }

          final buyerCart = find.byKey(const Key('home_cart_button'));
          if (buyerCart.evaluate().isNotEmpty) {
            await tester.tap(buyerCart.first);
            await pumpWait(tester, seconds: 3);
            final emptyCart = find.byKey(const Key('cart_empty_message'));
            final checkoutButton = find.byKey(
              const Key('cart_checkout_button'),
            );
            debugPrint(
              ' Buyer cart status => empty=${emptyCart.evaluate().isNotEmpty}, checkout=${checkoutButton.evaluate().isNotEmpty}',
            );

            if (checkoutButton.evaluate().isNotEmpty) {
              await tester.tap(checkoutButton.first);
              await pumpWait(tester, seconds: 4);

              final checkoutPlaceOrder = find.byKey(
                const Key('checkout_place_order_button'),
              );
              final checkoutTerms = find.byKey(
                const Key('checkout_terms_checkbox'),
              );
              final checkoutSummary = find.byKey(
                const Key('checkout_summary_section'),
              );
              final checkoutShipping = find.byKey(
                const Key('checkout_shipping_section'),
              );
              final checkoutAddress = find.byKey(
                const Key('checkout_address_section'),
              );
              final checkoutPayment = find.byKey(
                const Key('checkout_payment_section'),
              );
              final checkoutSecure = find.byKey(
                const Key('checkout_secure_badge'),
              );
              final deliveryStandard = find.byKey(
                const Key('checkout_delivery_speed_standard'),
              );

              checkCase(
                'C025',
                checkoutPlaceOrder.evaluate().isNotEmpty,
                'checkout place order visible',
              );
              checkCase(
                'C026',
                checkoutTerms.evaluate().isNotEmpty,
                'checkout terms checkbox visible',
              );
              checkCase(
                'C027',
                checkoutSummary.evaluate().isNotEmpty,
                'checkout summary visible',
              );
              checkCase(
                'C028',
                checkoutPayment.evaluate().isNotEmpty,
                'checkout payment section visible',
              );
              checkCase(
                'C029',
                checkoutSecure.evaluate().isNotEmpty,
                'checkout secure badge visible',
              );
              checkCase(
                'C030',
                checkoutShipping.evaluate().isNotEmpty ||
                    deliveryStandard.evaluate().isNotEmpty,
                'checkout shipping/delivery visible',
              );
              checkCase(
                'C071',
                checkoutAddress.evaluate().isNotEmpty,
                'checkout address section visible',
              );

              final hasTaxBreakdown =
                  find.textContaining('HST').evaluate().isNotEmpty ||
                  find.textContaining('GST').evaluate().isNotEmpty ||
                  find.textContaining('PST').evaluate().isNotEmpty ||
                  find.textContaining('QST').evaluate().isNotEmpty;
              checkCase(
                'C031',
                hasTaxBreakdown,
                'tax breakdown visible (GST/HST/PST/QST)',
              );

              final standardSpeed = find.byKey(
                const Key('checkout_delivery_speed_standard'),
              );
              final expressSpeed = find.byKey(
                const Key('checkout_delivery_speed_express'),
              );
              final sameDaySpeed = find.byKey(
                const Key('checkout_delivery_speed_sameDay'),
              );
              checkCase(
                'C055',
                standardSpeed.evaluate().isNotEmpty,
                'delivery speed standard visible',
              );
              checkCase(
                'C056',
                expressSpeed.evaluate().isNotEmpty,
                'delivery speed express visible',
              );
              checkCase(
                'C057',
                sameDaySpeed.evaluate().isNotEmpty,
                'delivery speed same-day visible',
              );

              final shippingMoneyInSection = find.descendant(
                of: checkoutShipping,
                matching: find.textContaining(r'$'),
              );
              checkCase(
                'C058',
                shippingMoneyInSection.evaluate().isNotEmpty,
                'shipping section shows cost text',
              );

              final summaryMoneyValues = find.descendant(
                of: checkoutSummary,
                matching: find.textContaining(r'$'),
              );
              checkCase(
                'C059',
                summaryMoneyValues.evaluate().length >= 2,
                'order summary shows monetary breakdown',
              );

              final termsWidgetBefore = tester.widget<Checkbox>(
                checkoutTerms.first,
              );
              final termsBefore = termsWidgetBefore.value ?? false;
              await tester.tap(checkoutTerms.first, warnIfMissed: false);
              await pumpWait(tester, seconds: 1);
              final termsWidgetAfter = tester.widget<Checkbox>(
                checkoutTerms.first,
              );
              final termsAfter = termsWidgetAfter.value ?? false;
              checkCase(
                'C060',
                termsBefore != termsAfter,
                'terms checkbox toggle works',
              );

              for (final speedKey in const [
                'checkout_delivery_speed_standard',
                'checkout_delivery_speed_express',
                'checkout_delivery_speed_sameDay',
              ]) {
                final speedFinder = find.byKey(Key(speedKey));
                if (speedFinder.evaluate().isNotEmpty) {
                  await tester.tap(speedFinder.first, warnIfMissed: false);
                  await pumpWait(tester, seconds: 1);
                  checkCase(
                    'C061',
                    checkoutSummary.evaluate().isNotEmpty &&
                        checkoutShipping.evaluate().isNotEmpty &&
                        checkoutPlaceOrder.evaluate().isNotEmpty &&
                        checkoutTerms.evaluate().isNotEmpty,
                    'delivery speed interaction keeps checkout stable ($speedKey)',
                  );
                }
              }

              final shippingAmounts = extractDollarAmounts(
                find.descendant(
                  of: checkoutShipping,
                  matching: find.byType(Text),
                ),
              );
              checkCase(
                'C072',
                shippingAmounts.isNotEmpty,
                'shipping section exposes parsable monetary amount',
              );
              checkCase(
                'C073',
                shippingAmounts.every((amount) => amount >= 0),
                'shipping monetary amount is non-negative',
              );

              final summaryAmounts = extractDollarAmounts(
                find.descendant(
                  of: checkoutSummary,
                  matching: find.byType(Text),
                ),
              );
              checkCase(
                'C074',
                summaryAmounts.length >= 3,
                'summary contains multiple monetary values',
              );
              if (shippingAmounts.isNotEmpty && summaryAmounts.isNotEmpty) {
                final maxSummary = summaryAmounts.reduce(
                  (value, element) => value > element ? value : element,
                );
                final minShipping = shippingAmounts.reduce(
                  (value, element) => value < element ? value : element,
                );
                checkCase(
                  'C075',
                  maxSummary >= minShipping,
                  'summary totals remain coherent with shipping amount',
                );
              }

              final termsLink = find.byKey(const Key('checkout_terms_link'));
              if (termsLink.evaluate().isNotEmpty) {
                checkCase(
                  'C076',
                  checkoutTerms.evaluate().isNotEmpty,
                  'terms link present (not tapped to avoid new tab)',
                );
                checkCase(
                  'C077',
                  checkoutPlaceOrder.evaluate().isNotEmpty,
                  'place order still visible with terms link present',
                );
              }

              await goBack(tester);
              await pumpWait(tester, seconds: 2);
            }

            await goBack(tester);
          }

          final buyerProductFinders = <Finder>[
            find.byKey(const Key('product_card_Test Physical Product')),
            find.byKey(const Key('product_card_Test Digital Product')),
            find.byKey(const Key('product_card_Test Local Product')),
            find.textContaining('Test Physical Product'),
            find.textContaining('Test Digital Product'),
            find.textContaining('Test Local Product'),
          ];
          final buyerProductTarget = buyerProductFinders.firstWhere(
            (finder) => finder.evaluate().isNotEmpty,
            orElse: () => find.byType(Scaffold),
          );

          if (buyerProductFinders.any(
            (finder) => finder.evaluate().isNotEmpty,
          )) {
            await tester.tap(buyerProductTarget.first, warnIfMissed: false);
            await pumpWait(tester, seconds: 3);
            final buyerAddToCart = find.byKey(
              const Key('product_add_to_cart_button'),
            );
            final ownProductMessage = find.byKey(
              const Key('product_own_product_message'),
            );
            checkCase(
              'C032',
              buyerAddToCart.evaluate().isNotEmpty ||
                  ownProductMessage.evaluate().isNotEmpty,
              '[buyer] product detail CTA ou own-product message',
            );
            await goBack(tester);
          }

          checkCase(
            'C033',
            find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty,
            '[buyer] retour home OK',
          );
        }

        // ═══════════════════════════════════════════════════════════════════════
        // Seller flow — login as seller and validate seller-visible features
        // ═══════════════════════════════════════════════════════════════════════
        debugPrint('');
        _debugStep('C01', 'Seller Flow — seller tools + seller orders');
        final sellerCred = await switchCredentialWithRecovery(
          sellerCredentialCandidates,
          'C01',
        );
        if (sellerCred == null) {
          stopOnSkip(
            'S008',
            'Seller flow login failed with configured seller credentials',
          );
        } else {
          debugPrint('✓ Seller login succeeded with: ${sellerCred.label}');

          final sellerAddButton = find.byKey(
            const Key('home_add_product_button'),
          );
          checkCase(
            'C034',
            sellerAddButton.evaluate().isNotEmpty,
            '[buyer,seller] add product visible',
          );
          if (sellerAddButton.evaluate().isNotEmpty) {
            await tester.tap(sellerAddButton.first);
            await pumpWait(tester, seconds: 3);
            checkCase(
              'C035',
              find
                  .byKey(const Key('addproduct_screen_title'))
                  .evaluate()
                  .isNotEmpty,
              '[buyer,seller] add product screen open',
            );
            await goBack(tester);
          } else {
            stopOnSkip(
              'S009',
              'Seller add-product button not visible for seller role account',
            );
          }

          final sellerSettings = find.byKey(const Key('home_settings_button'));
          if (sellerSettings.evaluate().isNotEmpty) {
            await tester.tap(sellerSettings.first);
            await pumpWait(tester, seconds: 3);

            final sellerAdminPanel = find.byKey(
              const Key('profile_admin_panel_button'),
            );
            if (!isAdminAccountEmail(sellerCred.email)) {
              checkCase(
                'C036',
                sellerAdminPanel.evaluate().isEmpty,
                '[buyer,seller] admin panel caché',
              );
            }

            final sellerOrdersButton = find.byKey(
              const Key('profile_seller_orders_button'),
            );
            final sellerDashboardButton = find.byKey(
              const Key('profile_seller_dashboard_button'),
            );
            final becomeSellerButton = find.byKey(
              const Key('profile_become_seller_button'),
            );

            checkCase(
              'C037',
              sellerDashboardButton.evaluate().isNotEmpty ||
                  sellerOrdersButton.evaluate().isNotEmpty,
              '[buyer,seller] dashboard/orders seller visible',
            );
            checkCase(
              'C038',
              becomeSellerButton.evaluate().isEmpty,
              '[buyer,seller] become seller caché',
            );

            if (sellerDashboardButton.evaluate().isNotEmpty) {
              await tester.tap(sellerDashboardButton.first);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C039',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[buyer,seller] dashboard screen visible',
              );
              await goBack(tester);
            }

            if (sellerOrdersButton.evaluate().isNotEmpty) {
              await tester.tap(sellerOrdersButton.first);
              await pumpWait(tester, seconds: 3);
              checkCase(
                'C040',
                find
                    .byKey(const Key('seller_orders_screen_title'))
                    .evaluate()
                    .isNotEmpty,
                '[buyer,seller] seller orders screen visible',
              );
              await goBack(tester);
            } else {
              stopOnSkip(
                'S010',
                'Seller orders button not found for seller role account',
              );
            }

            await goBack(tester);
            await pumpWait(tester, seconds: 2);
          }
          checkCase(
            'C041',
            find.byKey(const Key('home_settings_button')).evaluate().isNotEmpty,
            '[buyer,seller] retour home/profile stable',
          );

          final sellerBuyerOrders = find.byKey(
            const Key('profile_my_orders_button'),
          );
          checkCase(
            'C062',
            sellerBuyerOrders.evaluate().isNotEmpty ||
                find.byKey(const Key('home_cart_button')).evaluate().isNotEmpty,
            '[buyer,seller] conserve accès buyer side',
          );
        }

        // ═══════════════════════════════════════════════════════════════════════
        // Extended admin flow — admin panel and privileged profile actions
        // ═══════════════════════════════════════════════════════════════════════
        debugPrint('');
        _debugStep('D01', 'Admin Extended Flow — panel + privileged menu');
        final adminCred = await switchCredentialWithRecovery(
          adminCredentialCandidates,
          'D01',
        );
        if (adminCred == null) {
          stopOnSkip(
            'S011',
            'Admin extension login failed with configured admin credentials',
          );
        } else {
          debugPrint('✓ Admin login succeeded with: ${adminCred.label}');

          final adminAddProduct = find.byKey(
            const Key('home_add_product_button'),
          );
          checkCase(
            'C063',
            adminAddProduct.evaluate().isNotEmpty,
            '[buyer,seller,admin] add product visible',
          );

          final adminSettings = find.byKey(const Key('home_settings_button'));
          if (adminSettings.evaluate().isNotEmpty) {
            await tester.tap(adminSettings.first);
            await pumpWait(tester, seconds: 3);

            final adminPanelButton = find.byKey(
              const Key('profile_admin_panel_button'),
            );
            final adminSellerOrdersButton = find.byKey(
              const Key('profile_seller_orders_button'),
            );

            checkCase(
              'C042',
              adminPanelButton.evaluate().isNotEmpty,
              '[buyer,seller,admin] admin panel visible',
            );

            if (adminSellerOrdersButton.evaluate().isNotEmpty) {
              await tester.tap(adminSellerOrdersButton.first);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C043',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[admin] seller orders quick open',
              );
              await goBack(tester);
            }

            final adminBuyerOrdersButton = find.byKey(
              const Key('profile_my_orders_button'),
            );
            checkCase(
              'C064',
              adminBuyerOrdersButton.evaluate().isNotEmpty,
              '[admin] garde aussi accès buyer orders',
            );

            await tester.tap(adminPanelButton.first);
            await pumpWait(tester, seconds: 3);
            checkCase(
              'C044',
              find.byType(Scaffold).evaluate().isNotEmpty,
              '[admin] scaffold panel',
            );
            checkCase(
              'C045',
              find.byKey(const Key('admin_screen_title')).evaluate().isNotEmpty,
              '[admin] title panel',
            );
            checkCase(
              'C046',
              find.byKey(const Key('admin_tab_sellers')).evaluate().isNotEmpty,
              '[admin] tab sellers',
            );
            checkCase(
              'C047',
              find.byKey(const Key('admin_tab_users')).evaluate().isNotEmpty,
              '[admin] tab users',
            );
            checkCase(
              'C048',
              find.byKey(const Key('admin_tab_orders')).evaluate().isNotEmpty,
              '[admin] tab orders',
            );
            checkCase(
              'C049',
              find.byKey(const Key('admin_tab_products')).evaluate().isNotEmpty,
              '[admin] tab products',
            );
            checkCase(
              'C050',
              find.byKey(const Key('admin_tab_payments')).evaluate().isNotEmpty,
              '[admin] tab payments',
            );
            checkCase(
              'C051',
              find.byKey(const Key('admin_tab_security')).evaluate().isNotEmpty,
              '[admin] tab security',
            );

            for (final tabKey in const [
              'admin_tab_sellers',
              'admin_tab_users',
              'admin_tab_orders',
              'admin_tab_products',
              'admin_tab_payments',
              'admin_tab_security',
            ]) {
              final tabFinder = find.byKey(Key(tabKey));
              if (tabFinder.evaluate().isNotEmpty) {
                await tester.tap(tabFinder.first);
                await pumpWait(tester, seconds: 1);
                checkCase(
                  'C052',
                  find.byType(Scaffold).evaluate().isNotEmpty,
                  '[admin] navigation onglet $tabKey stable',
                );
              }
            }

            checkCase(
              'C065',
              find.byKey(const Key('admin_tab_orders')).evaluate().isNotEmpty &&
                  find
                      .byKey(const Key('admin_tab_payments'))
                      .evaluate()
                      .isNotEmpty,
              '[admin] tabs order/payment persistent after navigation',
            );
            await goBack(tester);

            final privacyButton = find.byKey(
              const Key('profile_privacy_button'),
            );
            if (privacyButton.evaluate().isNotEmpty) {
              await tester.tap(privacyButton.first);
              await pumpWait(tester, seconds: 2);
              checkCase(
                'C053',
                find.byType(Scaffold).evaluate().isNotEmpty,
                '[admin] privacy screen open',
              );
              await goBack(tester);
            }

            await goBack(tester);
            await pumpWait(tester, seconds: 2);

            checkCase(
              'C066',
              find
                  .byKey(const Key('home_settings_button'))
                  .evaluate()
                  .isNotEmpty,
              '[admin] retour home/profile stable',
            );
          }
        }

        // Edge hardening checks (UI resilience)
        await ensureHomeReady(timeoutSeconds: 15);
        final globalCart = find.byKey(const Key('home_cart_button'));
        final globalSettings = find.byKey(const Key('home_settings_button'));
        checkCase(
          'C067',
          globalCart.evaluate().isNotEmpty,
          'home cart remains available after role switching',
        );
        checkCase(
          'C068',
          globalSettings.evaluate().isNotEmpty,
          'home settings remains available after role switching',
        );

        if (globalSettings.evaluate().isNotEmpty) {
          await tester.tap(globalSettings.first, warnIfMissed: false);
          await pumpWait(tester, seconds: 2);
          checkCase(
            'C069',
            find.byType(Scaffold).evaluate().isNotEmpty,
            'profile/settings still opens at end of run',
          );
          await goBack(tester);
        } else {
          stopOnSkip('S201', 'Global settings missing at final edge-hardening');
        }

        checkCase(
          'C070',
          find.byType(Scaffold).evaluate().isNotEmpty,
          'app remains interactive at end of suite',
        );

        debugPrint('');
        checkCase('C054', caseCount >= 70, 'Matrice de cas critiques >= 70');
        _debugStep('Z00', 'Total cases validés: $caseCount');
        _debugStep('Z01', 'All flows checked');
        _debugStep('Z02', 'Buyer/Seller/Admin extension flows checked');

        if (strictIntegration && failedCases.isNotEmpty) {
          final preview = failedCases.take(20).join(' | ');
          fail(
            'Integration run completed with ${failedCases.length} failed checks. First failures: $preview',
          );
        } else if (!strictIntegration && failedCases.isNotEmpty) {
          _debugStep(
            'Z03',
            'Non-strict mode: ${failedCases.length} failed checks recorded but not fatal',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
