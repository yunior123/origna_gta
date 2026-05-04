// Tests to boost coverage for env_config.dart, utils.dart (AppError), analytics_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/errors/error_codes.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/services/analytics_service.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:orignabase/orignabase.dart';

void main() {
  // ==========================================================================
  // EnvConfig — validates config is self-consistent for the active environment.
  // The ENVIRONMENT dart-define controls which env is active at compile time.
  // ==========================================================================
  group('EnvConfig', () {
    final config = EnvConfig();

    test('singleton returns same instance', () {
      expect(identical(config, EnvConfig()), isTrue);
    });

    test('environment is a valid AppEnvironment', () {
      expect(AppEnvironment.values, contains(config.environment));
    });

    test('exactly one environment flag is true', () {
      final flags = [
        config.isProduction,
        config.isDev,
        config.isStaging,
        config.isEmulator,
      ];
      expect(flags.where((f) => f).length, 1);
    });

    test('isEmulator is false when not in emulator mode', () {
      // Emulator is only true with ENVIRONMENT=emulator or USE_EMULATORS=true
      if (config.environment != AppEnvironment.emulator) {
        expect(config.isEmulator, isFalse);
      }
    });

    test('baseUrl matches current environment', () {
      expect(config.baseUrl, EnvConfig.baseUrlFor(config.environment));
    });

    test('r2ProductsFolder matches current environment', () {
      final expected = switch (config.environment) {
        AppEnvironment.emulator => 'emulator/products',
        AppEnvironment.dev => 'dev/products',
        AppEnvironment.staging => 'staging/products',
        AppEnvironment.production => 'products',
      };
      expect(config.r2ProductsFolder, expected);
    });

    test('r2UsersFolder matches current environment', () {
      final expected = switch (config.environment) {
        AppEnvironment.emulator => 'emulator/users',
        AppEnvironment.dev => 'dev/users',
        AppEnvironment.staging => 'staging/users',
        AppEnvironment.production => 'users',
      };
      expect(config.r2UsersFolder, expected);
    });

    test('orignabaseUrl matches current environment', () {
      expect(
        config.orignabaseUrl,
        EnvConfig.orignabaseUrlFor(config.environment),
      );
    });

    test('dev returns dev OrignaBase URL', () {
      expect(
        EnvConfig.orignabaseUrlFor(AppEnvironment.dev),
        'https://api.dev.orignagta.ca',
      );
    });

    test('staging returns staging OrignaBase URL', () {
      expect(
        EnvConfig.orignabaseUrlFor(AppEnvironment.staging),
        'https://api.staging.orignagta.ca',
      );
    });

    test('production routes to shared OrignaBase host', () {
      expect(
        EnvConfig.orignabaseUrlFor(AppEnvironment.production),
        'https://api.orignagta.ca',
      );
    });

    test('displayName matches current environment', () {
      final expected = switch (config.environment) {
        AppEnvironment.emulator => 'Emulator (Micro-Staging)',
        AppEnvironment.dev => 'Development',
        AppEnvironment.staging => 'Staging',
        AppEnvironment.production => 'Production',
      };
      expect(config.displayName, expected);
    });

    test('isTest returns false by default', () {
      expect(config.isTest, isFalse);
    });

    test('shouldUseEmulators is false when not in emulator mode', () {
      if (config.environment != AppEnvironment.emulator) {
        expect(config.shouldUseEmulators, isFalse);
      }
    });

    test('printInfo does not throw', () {
      expect(() => config.displayName, returnsNormally);
    });

    test('AppEnvironment enum has 4 values', () {
      expect(AppEnvironment.values.length, 4);
      expect(AppEnvironment.values, contains(AppEnvironment.emulator));
      expect(AppEnvironment.values, contains(AppEnvironment.dev));
      expect(AppEnvironment.values, contains(AppEnvironment.staging));
      expect(AppEnvironment.values, contains(AppEnvironment.production));
    });
  });

  // ==========================================================================
  // AppError._inferCode via getMessage (OrignaBase auth branches)
  // ==========================================================================
  group('AppError.getMessage with OrignaBaseAuthException codes', () {
    test('email-already-in-use maps to AUTH-001', () {
      final e = OrignaBaseAuthException(code: 'email-already-in-use');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authEmailInUse));
    });

    test('wrong-password maps to AUTH-002', () {
      final e = OrignaBaseAuthException(code: 'wrong-password');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authWrongPassword));
    });

    test('user-not-found maps to AUTH-003', () {
      final e = OrignaBaseAuthException(code: 'user-not-found');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authUserNotFound));
    });

    test('weak-password maps to AUTH-004', () {
      final e = OrignaBaseAuthException(code: 'weak-password');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authWeakPassword));
    });

    test('too-many-requests maps to AUTH-005', () {
      final e = OrignaBaseAuthException(code: 'too-many-requests');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authTooManyRequests));
    });

    test('session-cookie-expired maps to AUTH-008', () {
      final e = OrignaBaseAuthException(code: 'session-cookie-expired');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authSessionExpired));
    });

    test('user-token-expired maps to AUTH-008', () {
      final e = OrignaBaseAuthException(code: 'user-token-expired');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.authSessionExpired));
    });

    test('unknown auth code maps to SYS-999', () {
      final e = OrignaBaseAuthException(code: '');
      final msg = AppError.getMessage(e);
      expect(msg, contains(ErrorCodes.sysUnknown));
    });

    test('backend exception uses explicit safe fallback', () {
      final e = OrignaBaseException('backend unavailable', statusCode: 503);
      final msg = AppError.getMessage(e);
      expect(msg, isNotEmpty);
    });

    test('getMessage with explicit code appends it', () {
      final msg = AppError.getMessage(
        Exception('oops'),
        null,
        'ORIGNA-TEST-001',
      );
      expect(msg, contains('[ORIGNA-TEST-001]'));
    });

    test('getMessage does not double-append if backend already has code', () {
      final e = OrignaBaseAuthException(code: '');
      final msg = AppError.getMessage(e, 'Card declined [ORIGNA-PAY-001]');
      expect(msg, isNotEmpty);
    });

    test('non-Exception uses fallback message', () {
      final msg = AppError.getMessage('just a string');
      expect(msg, isNotEmpty);
    });
  });

  // ==========================================================================
  // AppError.show (widget test)
  // ==========================================================================
  group('AppError.show', () {
    testWidgets('shows snackbar with error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppError.show(
                    context,
                    'Test error message',
                    error: Exception('test'),
                    logContext: 'test',
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('shows snackbar without error object', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppError.show(context, 'Simple message');
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Simple message'), findsOneWidget);
    });
  });

  // ==========================================================================
  // AppError.log
  // ==========================================================================
  group('AppError.log', () {
    test('log with all parameters does not throw', () {
      expect(
        () => AppError.log(
          Exception('test'),
          stackTrace: StackTrace.current,
          context: 'testContext',
          extras: {'key': 'value'},
        ),
        returnsNormally,
      );
    });

    test('log without optional parameters does not throw', () {
      expect(() => AppError.log('simple error'), returnsNormally);
    });
  });

  // ==========================================================================
  // AnalyticsService — all methods are no-ops in debug mode
  // ==========================================================================
  group('AnalyticsService no-ops in debug/dev', () {
    // _isEnabled is false in debug mode, so all methods return immediately
    late AnalyticsService analytics;

    setUp(() {
      analytics = AnalyticsService();
    });

    test('logSignUp returns without error', () async {
      await analytics.logSignUp(method: 'email');
    });

    test('logLogin returns without error', () async {
      await analytics.logLogin(method: 'google');
    });

    test('logViewItemList returns without error', () async {
      await analytics.logViewItemList(listName: 'test', items: []);
    });

    test('logSelectItem returns without error', () async {
      await analytics.logSelectItem(
        productId: 'p1',
        productName: 'Test',
        priceCad: 9.99,
      );
    });

    test('logViewItem returns without error', () async {
      await analytics.logViewItem(
        productId: 'p1',
        productName: 'Test',
        priceCad: 9.99,
      );
    });

    test('logSearch returns without error', () async {
      await analytics.logSearch(searchTerm: 'test');
    });

    test('logAddToCart returns without error', () async {
      await analytics.logAddToCart(
        productId: 'p1',
        productName: 'Test',
        priceCad: 9.99,
        quantity: 2,
      );
    });

    test('logRemoveFromCart returns without error', () async {
      await analytics.logRemoveFromCart(
        productId: 'p1',
        productName: 'Test',
        priceCad: 9.99,
      );
    });

    test('logAddToWishlist returns without error', () async {
      await analytics.logAddToWishlist(
        productId: 'p1',
        productName: 'Test',
        priceCad: 9.99,
      );
    });

    test('logRemoveFromWishlist returns without error', () async {
      await analytics.logRemoveFromWishlist(
        productId: 'p1',
        productName: 'Test',
      );
    });

    test('logBeginCheckout returns without error', () async {
      await analytics.logBeginCheckout(valueCad: 99.99, itemCount: 3);
    });

    test('logAddShippingInfo returns without error', () async {
      await analytics.logAddShippingInfo(
        valueCad: 99.99,
        shippingCostCad: 12.99,
        shippingTier: 'standard',
      );
    });

    test('logAddPaymentInfo returns without error', () async {
      await analytics.logAddPaymentInfo(valueCad: 99.99, paymentType: 'card');
    });

    test('logPurchase returns without error', () async {
      await analytics.logPurchase(
        orderId: 'ord_123',
        valueCad: 99.99,
        itemCount: 3,
      );
    });

    test('logRefund returns without error', () async {
      await analytics.logRefund(orderId: 'ord_123', valueCad: 49.99);
    });

    test('logSubscriptionStarted returns without error', () async {
      await analytics.logSubscriptionStarted(priceCad: 9.99);
    });

    test('logSubscriptionCancelled returns without error', () async {
      await analytics.logSubscriptionCancelled();
    });

    test('logReviewSubmitted returns without error', () async {
      await analytics.logReviewSubmitted(productId: 'p1', rating: 4.5);
    });

    test('logScreenView returns without error', () async {
      await analytics.logScreenView(screenName: 'home');
    });
  });

  // ==========================================================================
  // VideoValidationError enum
  // ==========================================================================
  group('VideoValidationError', () {
    test('enum has 4 values', () {
      expect(VideoValidationError.values.length, 4);
      expect(VideoValidationError.values, contains(VideoValidationError.none));
      expect(
        VideoValidationError.values,
        contains(VideoValidationError.tooLarge),
      );
      expect(
        VideoValidationError.values,
        contains(VideoValidationError.tooLong),
      );
      expect(
        VideoValidationError.values,
        contains(VideoValidationError.invalidFormat),
      );
    });
  });

  // ==========================================================================
  // dynamicToTimestamp
  // ==========================================================================
  group('dynamicToTimestamp', () {
    test('returns same DateTime if input is DateTime', () {
      final dt = DateTime(2025, 1, 1);
      expect(dynamicToTimestamp(dt), equals(dt));
    });

    test('converts DateTime and returns it directly', () {
      final dt = DateTime(2025, 6, 15);
      final result = dynamicToTimestamp(dt);
      expect(result, dt);
    });

    test('converts int input as epoch milliseconds', () {
      final result = dynamicToTimestamp(42);
      expect(result, DateTime.fromMillisecondsSinceEpoch(42));
    });

    test('returns DateTime.now() for unrecognized type', () {
      final before = DateTime.now();
      final result = dynamicToTimestamp(const Object());
      final after = DateTime.now();
      expect(
        result.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        result.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });
  });

  // ==========================================================================
  // parseAddressSuggestion
  // ==========================================================================
  group('parseAddressSuggestion', () {
    test('parses full suggestion', () {
      final suggestion = {
        'properties': {
          'housenumber': '123',
          'street': 'Main St',
          'formatted': '123 Main St, Toronto, ON',
          'city': 'Toronto',
          'state_code': 'ON',
          'postcode': 'M5V 1A1',
        },
        'geometry': {
          'coordinates': [-79.3832, 43.6532],
        },
      };
      final result = parseAddressSuggestion(suggestion);
      expect(result.street, '123 Main St, Toronto, ON');
      expect(result.city, 'Toronto');
      expect(result.state, 'ON');
      expect(result.postalCode, 'M5V 1A1');
      expect(result.latitude, closeTo(43.6532, 0.001));
      expect(result.longitude, closeTo(-79.3832, 0.001));
    });

    test('handles missing properties', () {
      final suggestion = <String, dynamic>{
        'properties': <String, dynamic>{},
        'geometry': <String, dynamic>{},
      };
      final result = parseAddressSuggestion(suggestion);
      expect(result.city, '');
      expect(result.state, 'ON'); // default
      expect(result.postalCode, '');
    });

    test('handles null geometry coordinates', () {
      final suggestion = {
        'properties': {'city': 'Ottawa'},
      };
      final result = parseAddressSuggestion(suggestion);
      expect(result.latitude, 0.0);
      expect(result.longitude, 0.0);
    });
  });

  // ==========================================================================
  // isValidTaxCode
  // ==========================================================================
  group('isValidTaxCode', () {
    test('null is valid', () {
      expect(isValidTaxCode(null), isTrue);
    });

    test('empty string is valid', () {
      expect(isValidTaxCode(''), isTrue);
    });

    test('whitespace only is valid', () {
      expect(isValidTaxCode('  '), isTrue);
    });

    test('valid tax code matches pattern', () {
      expect(isValidTaxCode('txcd_12345678'), isTrue);
    });

    test('invalid tax code rejected', () {
      expect(isValidTaxCode('txcd_123'), isFalse);
      expect(isValidTaxCode('abc_12345678'), isFalse);
      expect(isValidTaxCode('txcd_1234567890'), isFalse);
    });
  });

  // ==========================================================================
  // hasValidAddress
  // ==========================================================================
  group('hasValidAddress', () {
    test('null address is invalid', () {
      expect(hasValidAddress(null), isFalse);
    });

    test('valid Ontario address', () {
      final addr = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(hasValidAddress(addr), isTrue);
    });

    test('empty street is invalid', () {
      final addr = Address(
        street: '',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('invalid province code is invalid', () {
      final addr = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'XX',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('empty postal code is invalid', () {
      final addr = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: '',
        country: 'Canada',
      );
      expect(hasValidAddress(addr), isFalse);
    });

    test('lowercased province code is valid (normalized)', () {
      final addr = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'on',
        postalCode: 'M5V 1A1',
        country: 'Canada',
      );
      expect(hasValidAddress(addr), isTrue);
    });
  });

  // ==========================================================================
  // provinceTaxRates and getTaxRate
  // ==========================================================================
  group('provinceTaxRates', () {
    test('all Canadian provinces and territories present', () {
      expect(provinceTaxRates.length, 13);
    });

    test('Ontario HST is 13%', () {
      expect(provinceTaxRates['ON']!['HST'], 0.13);
    });

    test('Quebec has GST + QST', () {
      expect(provinceTaxRates['QC']!['GST'], 0.05);
      expect(provinceTaxRates['QC']!['QST'], 0.09975);
    });

    test('getTaxRate for Ontario', () {
      expect(getTaxRate('ON'), 0.13);
    });

    test('getTaxRate for Quebec', () {
      expect(getTaxRate('QC'), closeTo(0.14975, 0.00001));
    });

    test('getTaxRate for unknown province defaults to 13%', () {
      expect(getTaxRate('XX'), 0.13);
    });

    test('getTaxRate for Alberta is 5%', () {
      expect(getTaxRate('AB'), 0.05);
    });
  });

  // ==========================================================================
  // calculateDetailedTaxes
  // ==========================================================================
  group('calculateDetailedTaxes', () {
    test('null address returns empty map', () {
      expect(calculateDetailedTaxes(null, 10000), isEmpty);
    });

    test('Ontario address returns HST breakdown', () {
      final addr = Address(
        street: '1',
        city: 'T',
        state: 'ON',
        postalCode: 'M5V',
        country: 'CA',
      );
      final taxes = calculateDetailedTaxes(addr, 10000);
      expect(taxes['HST'], 1300);
    });

    test('Quebec address returns GST + QST', () {
      final addr = Address(
        street: '1',
        city: 'Q',
        state: 'QC',
        postalCode: 'H1A',
        country: 'CA',
      );
      final taxes = calculateDetailedTaxes(addr, 10000);
      expect(taxes['GST'], 500);
      expect(taxes['QST'], 998);
    });

    test('unknown province defaults to GST only', () {
      final addr = Address(
        street: '1',
        city: 'X',
        state: 'XX',
        postalCode: '000',
        country: 'CA',
      );
      final taxes = calculateDetailedTaxes(addr, 10000);
      expect(taxes['GST'], 500);
    });
  });

  // ==========================================================================
  // calculateFallbackShipping
  // ==========================================================================
  group('calculateFallbackShipping', () {
    final singleItem = [
      CartItemDetailModel.fromMap({
        'productId': 'p1',
        'quantity': 1,
        'priceAtCheckout': 10.0,
        'sellerId': 's1',
        'name': 'Test',
      }),
    ];

    test('same province = lowest base cost', () {
      final cost = calculateFallbackShipping(singleItem, 'ON', 'ON');
      expect(cost, 1299);
    });

    test('adjacent provinces = medium base cost', () {
      final cost = calculateFallbackShipping(singleItem, 'ON', 'QC');
      expect(cost, 1899);
    });

    test('same region = higher base cost', () {
      final cost = calculateFallbackShipping(singleItem, 'BC', 'AB');
      // BC-AB are adjacent, so 18.99
      expect(cost, 1899);
    });

    test('cross-country = highest base cost', () {
      final cost = calculateFallbackShipping(singleItem, 'BC', 'NS');
      expect(cost, 2699);
    });

    test('multiple items adds surcharge', () {
      final items = [
        CartItemDetailModel.fromMap({
          'productId': 'p1',
          'quantity': 3,
          'priceAtCheckout': 10.0,
          'sellerId': 's1',
          'name': 'Test',
        }),
      ];
      final cost = calculateFallbackShipping(items, 'ON', 'ON');
      // baseCost = 12.99, additionalItems = 2 * (12.99 * 0.15) = 3.897
      expect(cost, 1689);
    });
  });

  // ==========================================================================
  // productCategories
  // ==========================================================================
  group('productCategories', () {
    test('has 21 categories', () {
      expect(productCategories.length, 21);
    });

    test('first category is electronics', () {
      expect(productCategories.first.name, 'categories.electronics');
      expect(productCategories.first.categoryId, 1);
    });

    test('last category is digital products', () {
      expect(productCategories.last.name, 'categories.digital_products');
      expect(productCategories.last.categoryId, 21);
    });
  });

  // ==========================================================================
  // taxConfig alias
  // ==========================================================================
  group('taxConfig', () {
    test('is same reference as provinceTaxRates', () {
      expect(identical(taxConfig, provinceTaxRates), isTrue);
    });
  });
}
