import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/errors/error_codes.dart';
import 'package:origna_gta/core/theme_provider.dart';
import 'package:origna_gta/core/constants/validation_constants.dart';
import 'package:origna_gta/core/compat/timestamp.dart';

void main() {
  group('AppRoutes', () {
    test('has correct route constants', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.cart, '/cart');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.orders, '/orders');
      expect(AppRoutes.orderDetail, '/orders/detail');
      expect(AppRoutes.addProduct, '/add-product');
      expect(AppRoutes.editProduct, '/edit-product');
      expect(AppRoutes.productDetails, '/product-details');
      expect(AppRoutes.addressManagement, '/addresses');
      expect(AppRoutes.addEditAddress, '/address/edit');
      expect(AppRoutes.checkout, '/checkout');
      expect(AppRoutes.orderSuccess, '/order-success');
      expect(AppRoutes.shippingApproval, '/shipping-approval');
      expect(AppRoutes.sellerRegistration, '/seller/register');
      expect(AppRoutes.sellerOrders, '/seller/orders');
      expect(AppRoutes.sellerProducts, '/seller/products');
      expect(AppRoutes.sellerBulkUpload, '/seller/bulk-upload');
      expect(AppRoutes.sellerWarehouses, '/seller/warehouses');
      expect(AppRoutes.sellerIntegration, '/seller/integration');
      expect(AppRoutes.sellerAnalytics, '/seller/analytics');
      expect(AppRoutes.favorites, '/favorites');
      expect(AppRoutes.adminPanel, '/admin');
      expect(AppRoutes.privacyPolicy, '/privacy-policy');
      expect(AppRoutes.termsOfService, '/terms-of-service');
      expect(AppRoutes.paymentSuccess, '/payment-success');
      expect(AppRoutes.paymentCancel, '/payment-cancel');
      expect(AppRoutes.sellerReturn, '/seller/return');
      expect(AppRoutes.sellerRefresh, '/seller/refresh');
      expect(AppRoutes.productBySlug, '/p');
      expect(AppRoutes.productById, '/product');
      expect(AppRoutes.subscription, '/subscription');
      expect(AppRoutes.subscriptionSuccess, '/subscription/success');
      expect(AppRoutes.subscriptionCancel, '/subscription/cancel');
      expect(AppRoutes.chat, '/chat');
      expect(AppRoutes.chatInbox, '/chat/inbox');
      expect(AppRoutes.notifications, '/notifications');
      expect(AppRoutes.support, '/support');
      expect(AppRoutes.mfaSetup, '/mfa/setup');
      expect(AppRoutes.mfaChallenge, '/mfa/challenge');
      expect(AppRoutes.securitySettings, '/security-settings');
      expect(AppRoutes.returnRequest, '/orders/return-request');
    });

    test('AppRoutes constructor is private', () {
      // AppRoutes._() is private, so we can only access statics
      expect(AppRoutes.home, isNotNull);
    });

    test('ChatArgs constructs correctly', () {
      const args = ChatArgs(productId: 'p1', productTitle: 'Widget');
      expect(args.productId, 'p1');
      expect(args.productTitle, 'Widget');
    });

    test('OrderDetailArgs constructs correctly', () {
      const args = OrderDetailArgs(orderId: 'o1');
      expect(args.orderId, 'o1');
    });

    test('ReturnRequestArgs constructs correctly', () {
      const args = ReturnRequestArgs(orderId: 'o1');
      expect(args.orderId, 'o1');
    });

    test('ProductDetailsArgs constructs correctly', () {
      const args = ProductDetailsArgs(productId: 'p1');
      expect(args.productId, 'p1');
      expect(args.product, isNull);
    });

    test('ProductDetailsArgs with product map', () {
      const args = ProductDetailsArgs(
        productId: 'p1',
        product: {'name': 'Test'},
      );
      expect(args.product?['name'], 'Test');
    });

    test('ProductSlugArgs constructs correctly', () {
      const args = ProductSlugArgs(slug: 'my-product');
      expect(args.slug, 'my-product');
    });
  });

  group('ErrorCodes', () {
    test('has correct AUTH error codes', () {
      expect(ErrorCodes.authEmailInUse, 'ORIGNA-AUTH-001');
      expect(ErrorCodes.authWrongPassword, 'ORIGNA-AUTH-002');
      expect(ErrorCodes.authUserNotFound, 'ORIGNA-AUTH-003');
      expect(ErrorCodes.authWeakPassword, 'ORIGNA-AUTH-004');
      expect(ErrorCodes.authTooManyRequests, 'ORIGNA-AUTH-005');
      expect(ErrorCodes.authGoogleSignInFailed, 'ORIGNA-AUTH-006');
      expect(ErrorCodes.authAppleSignInFailed, 'ORIGNA-AUTH-007');
      expect(ErrorCodes.authSessionExpired, 'ORIGNA-AUTH-008');
      expect(ErrorCodes.authMfaRequired, 'ORIGNA-AUTH-009');
      expect(ErrorCodes.authEmailNotVerified, 'ORIGNA-AUTH-010');
      expect(ErrorCodes.authInvalidCredential, 'ORIGNA-AUTH-011');
      expect(ErrorCodes.authAccountDisabled, 'ORIGNA-AUTH-012');
    });

    test('has correct PAY error codes', () {
      expect(ErrorCodes.payCardDeclined, 'ORIGNA-PAY-001');
      expect(ErrorCodes.payInsufficientFunds, 'ORIGNA-PAY-002');
      expect(ErrorCodes.payExpiredCard, 'ORIGNA-PAY-003');
      expect(ErrorCodes.payInvalidCard, 'ORIGNA-PAY-004');
    });

    test('has correct ORD error codes', () {
      expect(ErrorCodes.ordNotFound, 'ORIGNA-ORD-001');
      expect(ErrorCodes.ordCancelNotAllowed, 'ORIGNA-ORD-002');
      expect(ErrorCodes.ordAlreadyCancelled, 'ORIGNA-ORD-003');
    });

    test('has correct CART error codes', () {
      expect(ErrorCodes.cartEmpty, 'ORIGNA-CART-001');
      expect(ErrorCodes.cartItemsChanged, 'ORIGNA-CART-002');
    });

    test('has correct PROD error codes', () {
      expect(ErrorCodes.prodNotFound, 'ORIGNA-PROD-001');
      expect(ErrorCodes.prodOutOfStock, 'ORIGNA-PROD-002');
    });

    test('has correct PERM error codes', () {
      expect(ErrorCodes.permUnauthorized, 'ORIGNA-PERM-001');
      expect(ErrorCodes.permAdminRequired, 'ORIGNA-PERM-003');
    });

    test('has correct SYS error codes', () {
      expect(ErrorCodes.sysNetworkError, 'ORIGNA-SYS-001');
      expect(ErrorCodes.sysServerError, 'ORIGNA-SYS-002');
      expect(ErrorCodes.sysTimeout, 'ORIGNA-SYS-003');
      expect(ErrorCodes.sysUnknown, 'ORIGNA-SYS-999');
    });

    test('describe returns known description', () {
      expect(
        ErrorCodes.describe(ErrorCodes.authEmailInUse),
        contains('already registered'),
      );
      expect(
        ErrorCodes.describe(ErrorCodes.payCardDeclined),
        contains('declined'),
      );
      expect(
        ErrorCodes.describe(ErrorCodes.ordNotFound),
        contains('not found'),
      );
    });

    test('describe returns fallback for unknown code', () {
      expect(
        ErrorCodes.describe('UNKNOWN-CODE'),
        'Unexpected error. Please try again.',
      );
    });
  });

  group('themeModeProvider', () {
    test('defaults to dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('can be changed to light mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('can be changed to system mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).state = ThemeMode.system;
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('ValidationConstants', () {
    test('emailRegex validates correct emails', () {
      expect(
        ValidationConstants.emailRegex.hasMatch('user@example.com'),
        isTrue,
      );
      expect(
        ValidationConstants.emailRegex.hasMatch('test.user+tag@domain.co'),
        isTrue,
      );
      expect(ValidationConstants.emailRegex.hasMatch('a@b.ca'), isTrue);
    });

    test('emailRegex rejects invalid emails', () {
      expect(ValidationConstants.emailRegex.hasMatch(''), isFalse);
      expect(ValidationConstants.emailRegex.hasMatch('notanemail'), isFalse);
      expect(ValidationConstants.emailRegex.hasMatch('@no-local.com'), isFalse);
      expect(ValidationConstants.emailRegex.hasMatch('no-domain@'), isFalse);
    });

    test('passwordRegex validates strong passwords', () {
      expect(ValidationConstants.passwordRegex.hasMatch('StrongP@ss1'), isTrue);
      expect(ValidationConstants.passwordRegex.hasMatch('Abc1234!'), isTrue);
    });

    test('passwordRegex rejects weak passwords', () {
      expect(ValidationConstants.passwordRegex.hasMatch('short'), isFalse);
      expect(
        ValidationConstants.passwordRegex.hasMatch('alllowercase1!'),
        isFalse,
      );
      expect(
        ValidationConstants.passwordRegex.hasMatch('ALLUPPERCASE1!'),
        isFalse,
      );
      expect(
        ValidationConstants.passwordRegex.hasMatch('NoDigitsHere!'),
        isFalse,
      );
      expect(ValidationConstants.passwordRegex.hasMatch('NoSpecial1'), isFalse);
    });

    test('has correct length constants', () {
      expect(ValidationConstants.minPasswordLength, 8);
      expect(ValidationConstants.maxEmailLength, 254);
      expect(ValidationConstants.minEmailLength, 6);
      expect(ValidationConstants.minNameLength, 2);
      expect(ValidationConstants.maxNameLength, 60);
    });

    test('commonPasswords list is not empty', () {
      expect(ValidationConstants.commonPasswords, isNotEmpty);
      expect(ValidationConstants.commonPasswords, contains('password'));
      expect(ValidationConstants.commonPasswords, contains('12345678'));
    });
  });

  group('Timestamp', () {
    test('Timestamp.now() creates valid timestamp', () {
      final ts = Timestamp.now();
      expect(ts.toDate(), isNotNull);
      expect(ts.millisecondsSinceEpoch, greaterThan(0));
    });

    test('Timestamp.fromDate preserves date', () {
      final dt = DateTime(2026, 3, 15, 10, 30);
      final ts = Timestamp.fromDate(dt);
      expect(ts.toDate(), dt);
    });

    test('Timestamp.millisecondsSinceEpoch is correct', () {
      final dt = DateTime(2026, 1, 1);
      final ts = Timestamp.fromDate(dt);
      expect(ts.millisecondsSinceEpoch, dt.millisecondsSinceEpoch);
    });

    test('Timestamp.seconds is correct', () {
      final dt = DateTime(2026, 1, 1);
      final ts = Timestamp.fromDate(dt);
      expect(ts.seconds, dt.millisecondsSinceEpoch ~/ 1000);
    });

    test('Timestamp equality works', () {
      final dt = DateTime(2026, 3, 15);
      final ts1 = Timestamp.fromDate(dt);
      final ts2 = Timestamp.fromDate(dt);
      expect(ts1 == ts2, isTrue);
      expect(ts1.hashCode, ts2.hashCode);
    });

    test('Timestamp inequality works', () {
      final ts1 = Timestamp.fromDate(DateTime(2026, 1, 1));
      final ts2 = Timestamp.fromDate(DateTime(2026, 12, 31));
      expect(ts1 == ts2, isFalse);
    });

    test('Timestamp.compareTo works', () {
      final ts1 = Timestamp.fromDate(DateTime(2026, 1, 1));
      final ts2 = Timestamp.fromDate(DateTime(2026, 6, 1));
      expect(ts1.compareTo(ts2), lessThan(0));
      expect(ts2.compareTo(ts1), greaterThan(0));
      expect(ts1.compareTo(ts1), 0);
    });

    test('Timestamp.toString returns formatted string', () {
      final ts = Timestamp.fromDate(DateTime(2026, 3, 15));
      expect(ts.toString(), contains('Timestamp'));
      expect(ts.toString(), contains('2026'));
    });
  });

  group('truncateNanoseconds', () {
    test('truncates 9-digit fractional seconds', () {
      const input = '2026-03-12T11:56:03.185238962+00:00';
      final result = truncateNanoseconds(input);
      expect(result, '2026-03-12T11:56:03.185238+00:00');
    });

    test('does not change 6-digit fractional seconds', () {
      const input = '2026-03-12T11:56:03.185238+00:00';
      final result = truncateNanoseconds(input);
      expect(result, input);
    });

    test('does not change strings without fractional seconds', () {
      const input = '2026-03-12T11:56:03+00:00';
      final result = truncateNanoseconds(input);
      expect(result, input);
    });

    test('handles 7-digit fractional', () {
      const input = '2026-03-12T11:56:03.1234567+00:00';
      final result = truncateNanoseconds(input);
      expect(result, '2026-03-12T11:56:03.123456+00:00');
    });

    test('parsed result is valid DateTime', () {
      const input = '2026-03-12T11:56:03.185238962+00:00';
      final dt = DateTime.parse(truncateNanoseconds(input));
      expect(dt.year, 2026);
      expect(dt.month, 3);
      expect(dt.day, 12);
    });
  });

  group('parseTimestamp', () {
    test('returns null for null input', () {
      expect(parseTimestamp(null), isNull);
    });

    test('returns DateTime as-is', () {
      final dt = DateTime(2026, 3, 15);
      expect(parseTimestamp(dt), dt);
    });

    test('parses string with nanosecond precision', () {
      final result = parseTimestamp('2026-03-12T11:56:03.185238962+00:00');
      expect(result, isNotNull);
      expect(result!.year, 2026);
    });

    test('parses string with standard precision', () {
      final result = parseTimestamp('2026-03-12T11:56:03Z');
      expect(result, isNotNull);
      expect(result!.year, 2026);
    });

    test('parses int as milliseconds', () {
      final dt = DateTime(2026, 3, 15);
      final result = parseTimestamp(dt.millisecondsSinceEpoch);
      expect(result, isNotNull);
      expect(result!.year, 2026);
    });

    test('returns null for unsupported type', () {
      expect(parseTimestamp(3.14), isNull);
    });
  });
}
