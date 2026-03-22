import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/errors/error_codes.dart';
import 'package:origna_gta/utils/error_messages.dart';

void main() {
  group('ErrorMessages', () {
    group('format', () {
      test('formats auth error codes correctly', () {
        final msg = ErrorMessages.format(ErrorCodes.authEmailInUse);
        expect(msg, contains(ErrorCodes.authEmailInUse));
        expect(msg, contains('Error'));
        expect(msg, contains('already registered'));
      });

      test('formats pay error codes correctly', () {
        final msg = ErrorMessages.format(ErrorCodes.payCardDeclined);
        expect(msg, 'Error [ORIGNA-PAY-001]: Your card was declined.');
      });

      test('formats ord error codes correctly', () {
        final msg = ErrorMessages.format(ErrorCodes.ordNotFound);
        expect(msg, 'Error [ORIGNA-ORD-001]: Order not found.');
      });

      test('formats cart error codes correctly', () {
        final msg = ErrorMessages.format(ErrorCodes.cartEmpty);
        expect(msg, 'Error [ORIGNA-CART-001]: Your cart is empty.');
      });

      test('formats sys error codes correctly', () {
        final msg = ErrorMessages.format(ErrorCodes.sysNetworkError);
        expect(
          msg,
          'Error [ORIGNA-SYS-001]: Network error. Check your connection.',
        );
      });

      test('formats unknown codes with fallback', () {
        final msg = ErrorMessages.format('UNKNOWN-CODE');
        expect(
          msg,
          'Error [UNKNOWN-CODE]: Unexpected error. Please try again.',
        );
      });

      test('includes code in brackets', () {
        final msg = ErrorMessages.format(ErrorCodes.permUnauthorized);
        expect(msg, contains('[ORIGNA-PERM-001]'));
      });

      test('formats all auth domain codes', () {
        final authCodes = [
          ErrorCodes.authEmailInUse,
          ErrorCodes.authWrongPassword,
          ErrorCodes.authUserNotFound,
          ErrorCodes.authWeakPassword,
          ErrorCodes.authTooManyRequests,
          ErrorCodes.authGoogleSignInFailed,
          ErrorCodes.authAppleSignInFailed,
          ErrorCodes.authSessionExpired,
          ErrorCodes.authMfaRequired,
          ErrorCodes.authEmailNotVerified,
          ErrorCodes.authInvalidCredential,
          ErrorCodes.authAccountDisabled,
        ];

        for (final code in authCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all pay domain codes', () {
        final payCodes = [
          ErrorCodes.payCardDeclined,
          ErrorCodes.payInsufficientFunds,
          ErrorCodes.payExpiredCard,
          ErrorCodes.payInvalidCard,
          ErrorCodes.payAmountMismatch,
          ErrorCodes.payCheckoutExpired,
          ErrorCodes.payRefundFailed,
          ErrorCodes.paySellerSuspended,
          ErrorCodes.payProductUnavailable,
          ErrorCodes.payAsyncPending,
          ErrorCodes.payStripeRedirectFailed,
          ErrorCodes.payBiometricFailed,
          ErrorCodes.payCouponInvalid,
          ErrorCodes.payCouponExpired,
        ];

        for (final code in payCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all ord domain codes', () {
        final ordCodes = [
          ErrorCodes.ordNotFound,
          ErrorCodes.ordCancelNotAllowed,
          ErrorCodes.ordAlreadyCancelled,
          ErrorCodes.ordReturnWindowExpired,
          ErrorCodes.ordReturnNotAllowed,
          ErrorCodes.ordStatusInvalid,
          ErrorCodes.ordBiometricFailed,
          ErrorCodes.ordConfirmFailed,
          ErrorCodes.ordDownloadFailed,
        ];

        for (final code in ordCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all cart domain codes', () {
        final cartCodes = [
          ErrorCodes.cartEmpty,
          ErrorCodes.cartItemsChanged,
          ErrorCodes.cartItemsRemoved,
          ErrorCodes.cartPriceChanged,
          ErrorCodes.cartStockChanged,
          ErrorCodes.cartAddressRequired,
          ErrorCodes.cartAddressInvalid,
        ];

        for (final code in cartCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all ship domain codes', () {
        final shipCodes = [
          ErrorCodes.shipCostCalcFailed,
          ErrorCodes.shipAddressInvalid,
          ErrorCodes.shipProviderUnavailable,
          ErrorCodes.shipApprovalExpired,
          ErrorCodes.shipCostTooHigh,
        ];

        for (final code in shipCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all prod domain codes', () {
        final prodCodes = [
          ErrorCodes.prodNotFound,
          ErrorCodes.prodOutOfStock,
          ErrorCodes.prodNotAvailable,
          ErrorCodes.prodImageUploadFailed,
          ErrorCodes.prodInvalidCategory,
          ErrorCodes.prodVideoTooLarge,
          ErrorCodes.prodVideoTooLong,
          ErrorCodes.prodVideoInvalidFormat,
          ErrorCodes.prodVideoUploadFailed,
        ];

        for (final code in prodCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all sell domain codes', () {
        final sellCodes = [
          ErrorCodes.sellOnboardingIncomplete,
          ErrorCodes.sellPayoutsDisabled,
          ErrorCodes.sellAccountSuspended,
          ErrorCodes.sellStripeNotConnected,
          ErrorCodes.sellVerificationFailed,
        ];

        for (final code in sellCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all perm domain codes', () {
        final permCodes = [
          ErrorCodes.permUnauthorized,
          ErrorCodes.permSellerRequired,
          ErrorCodes.permAdminRequired,
          ErrorCodes.permPremiumRequired,
          ErrorCodes.permSelfPurchaseBlocked,
        ];

        for (final code in permCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all prem domain codes', () {
        final premCodes = [
          ErrorCodes.premFeatureGated,
          ErrorCodes.premSubscriptionFailed,
          ErrorCodes.premTrialExpired,
        ];

        for (final code in premCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all admin domain codes', () {
        final adminCodes = [
          ErrorCodes.adminMfaFailed,
          ErrorCodes.adminRoleUpdateFailed,
          ErrorCodes.adminSuspendFailed,
          ErrorCodes.adminProductModerateFailed,
          ErrorCodes.adminRefundFailed,
        ];

        for (final code in adminCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });

      test('formats all sys domain codes', () {
        final sysCodes = [
          ErrorCodes.sysNetworkError,
          ErrorCodes.sysServerError,
          ErrorCodes.sysTimeout,
          ErrorCodes.sysServiceDegraded,
          ErrorCodes.sysUnknown,
        ];

        for (final code in sysCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains(code));
          expect(msg, contains('Error'));
        }
      });
    });

    group('unknown', () {
      test('returns formatted sysUnknown code', () {
        final msg = ErrorMessages.unknown();
        expect(msg, 'Error [ORIGNA-SYS-999]: An unexpected error occurred.');
      });

      test('contains sysUnknown code', () {
        final msg = ErrorMessages.unknown();
        expect(msg, contains(ErrorCodes.sysUnknown));
      });
    });

    group('format consistency', () {
      test('format always starts with Error', () {
        final allCodes = [
          ErrorCodes.authEmailInUse,
          ErrorCodes.payCardDeclined,
          ErrorCodes.ordNotFound,
          ErrorCodes.cartEmpty,
          ErrorCodes.shipCostCalcFailed,
          ErrorCodes.prodNotFound,
          ErrorCodes.sellOnboardingIncomplete,
          ErrorCodes.permUnauthorized,
          ErrorCodes.premFeatureGated,
          ErrorCodes.adminMfaFailed,
          ErrorCodes.sysNetworkError,
        ];

        for (final code in allCodes) {
          final msg = ErrorMessages.format(code);
          expect(msg.startsWith('Error'), isTrue);
        }
      });

      test('format always contains code in brackets', () {
        final codes = [
          'ORIGNA-AUTH-001',
          'ORIGNA-PAY-001',
          'ORIGNA-ORD-001',
          'ORIGNA-CART-001',
          'CUSTOM-CODE',
        ];

        for (final code in codes) {
          final msg = ErrorMessages.format(code);
          expect(msg, contains('[$code]'));
        }
      });
    });
  });
}
