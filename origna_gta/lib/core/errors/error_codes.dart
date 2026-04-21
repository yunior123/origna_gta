/// Standardized error codes for OrignaGTA.
/// Format: ORIGNA-{DOMAIN}-{NUMBER}
///
/// Users see these codes appended to error messages, e.g.:
///   "Card declined [ORIGNA-PAY-001]"
/// They can quote the code when contacting support@orignagta.ca
///
/// Full table: docs/ERROR_CODES.md
abstract final class ErrorCodes {
  // ── AUTH domain ──────────────────────────────────────────────────────────
  static const authEmailInUse = 'ORIGNA-AUTH-001';
  static const authWrongPassword = 'ORIGNA-AUTH-002';
  static const authUserNotFound = 'ORIGNA-AUTH-003';
  static const authWeakPassword = 'ORIGNA-AUTH-004';
  static const authTooManyRequests = 'ORIGNA-AUTH-005';
  static const authGoogleSignInFailed = 'ORIGNA-AUTH-006';
  static const authAppleSignInFailed = 'ORIGNA-AUTH-007';
  static const authSessionExpired = 'ORIGNA-AUTH-008';
  static const authMfaRequired = 'ORIGNA-AUTH-009';
  static const authEmailNotVerified = 'ORIGNA-AUTH-010';
  static const authInvalidCredential = 'ORIGNA-AUTH-011';
  static const authAccountDisabled = 'ORIGNA-AUTH-012';

  // ── PAY domain (Stripe / payments) ───────────────────────────────────────
  static const payCardDeclined = 'ORIGNA-PAY-001';
  static const payInsufficientFunds = 'ORIGNA-PAY-002';
  static const payExpiredCard = 'ORIGNA-PAY-003';
  static const payInvalidCard = 'ORIGNA-PAY-004';
  static const payAmountMismatch = 'ORIGNA-PAY-005';
  static const payCheckoutExpired = 'ORIGNA-PAY-006';
  static const payRefundFailed = 'ORIGNA-PAY-007';
  static const paySellerSuspended = 'ORIGNA-PAY-008';
  static const payProductUnavailable = 'ORIGNA-PAY-009';
  static const payAsyncPending = 'ORIGNA-PAY-010';
  static const payStripeRedirectFailed = 'ORIGNA-PAY-011';
  static const payBiometricFailed = 'ORIGNA-PAY-012';
  static const payCouponInvalid = 'ORIGNA-PAY-013';
  static const payCouponExpired = 'ORIGNA-PAY-014';

  // ── ORD domain (orders) ───────────────────────────────────────────────────
  static const ordNotFound = 'ORIGNA-ORD-001';
  static const ordCancelNotAllowed = 'ORIGNA-ORD-002';
  static const ordAlreadyCancelled = 'ORIGNA-ORD-003';
  static const ordReturnWindowExpired = 'ORIGNA-ORD-004';
  static const ordReturnNotAllowed = 'ORIGNA-ORD-005';
  static const ordStatusInvalid = 'ORIGNA-ORD-006';
  static const ordBiometricFailed = 'ORIGNA-ORD-007';
  static const ordConfirmFailed = 'ORIGNA-ORD-008';
  static const ordDownloadFailed = 'ORIGNA-ORD-009';

  // ── CART domain (cart & checkout validation) ──────────────────────────────
  static const cartEmpty = 'ORIGNA-CART-001';
  static const cartItemsChanged = 'ORIGNA-CART-002';
  static const cartItemsRemoved = 'ORIGNA-CART-003';
  static const cartPriceChanged = 'ORIGNA-CART-004';
  static const cartStockChanged = 'ORIGNA-CART-005';
  static const cartAddressRequired = 'ORIGNA-CART-006';
  static const cartAddressInvalid = 'ORIGNA-CART-007';

  // ── SHIP domain (shipping) ────────────────────────────────────────────────
  static const shipCostCalcFailed = 'ORIGNA-SHIP-001';
  static const shipAddressInvalid = 'ORIGNA-SHIP-002';
  static const shipProviderUnavailable = 'ORIGNA-SHIP-003';
  static const shipApprovalExpired = 'ORIGNA-SHIP-004';
  static const shipCostTooHigh = 'ORIGNA-SHIP-005';

  // ── PROD domain (products) ────────────────────────────────────────────────
  static const prodNotFound = 'ORIGNA-PROD-001';
  static const prodOutOfStock = 'ORIGNA-PROD-002';
  static const prodNotAvailable = 'ORIGNA-PROD-003';
  static const prodImageUploadFailed = 'ORIGNA-PROD-004';
  static const prodInvalidCategory = 'ORIGNA-PROD-005';
  static const prodVideoTooLarge = 'ORIGNA-PROD-006';
  static const prodVideoTooLong = 'ORIGNA-PROD-007';
  static const prodVideoInvalidFormat = 'ORIGNA-PROD-008';
  static const prodVideoUploadFailed = 'ORIGNA-PROD-009';

  // ── SELL domain (seller account) ─────────────────────────────────────────
  static const sellOnboardingIncomplete = 'ORIGNA-SELL-001';
  static const sellPayoutsDisabled = 'ORIGNA-SELL-002';
  static const sellAccountSuspended = 'ORIGNA-SELL-003';
  static const sellStripeNotConnected = 'ORIGNA-SELL-004';
  static const sellVerificationFailed = 'ORIGNA-SELL-005';

  // ── PERM domain (permissions) ─────────────────────────────────────────────
  static const permUnauthorized = 'ORIGNA-PERM-001';
  static const permSellerRequired = 'ORIGNA-PERM-002';
  static const permAdminRequired = 'ORIGNA-PERM-003';
  static const permPremiumRequired = 'ORIGNA-PERM-004';
  static const permSelfPurchaseBlocked = 'ORIGNA-PERM-005';

  // ── PREM domain (premium subscription) ───────────────────────────────────
  static const premFeatureGated = 'ORIGNA-PREM-001';
  static const premSubscriptionFailed = 'ORIGNA-PREM-002';
  static const premTrialExpired = 'ORIGNA-PREM-003';

  // ── ADMIN domain (admin panel operations) ────────────────────────────────
  static const adminMfaFailed = 'ORIGNA-ADMIN-001';
  static const adminRoleUpdateFailed = 'ORIGNA-ADMIN-002';
  static const adminSuspendFailed = 'ORIGNA-ADMIN-003';
  static const adminProductModerateFailed = 'ORIGNA-ADMIN-004';
  static const adminRefundFailed = 'ORIGNA-ADMIN-005';

  // ── SYS domain (system / infrastructure) ─────────────────────────────────
  static const sysNetworkError = 'ORIGNA-SYS-001';
  static const sysServerError = 'ORIGNA-SYS-002';
  static const sysTimeout = 'ORIGNA-SYS-003';
  static const sysServiceDegraded = 'ORIGNA-SYS-004';
  static const sysUnknown = 'ORIGNA-SYS-999';

  // ── Description table (used by AppError.describe()) ──────────────────────
  /// Returns a short human-readable description for a given code.
  /// Used in support UIs and error dialogs.
  static String describe(String code) =>
      _descriptions[code] ?? 'Unexpected error. Please try again.';

  static const Map<String, String> _descriptions = {
    // AUTH
    authEmailInUse: 'This email address is already registered.',
    authWrongPassword: 'Incorrect password.',
    authUserNotFound: 'No account found with this email.',
    authWeakPassword: 'Password must be at least 8 characters.',
    authTooManyRequests: 'Too many attempts. Please wait and try again.',
    authGoogleSignInFailed: 'Google sign-in failed.',
    authAppleSignInFailed: 'Apple sign-in failed.',
    authSessionExpired: 'Your session expired. Please sign in again.',
    authMfaRequired: 'Two-factor authentication required.',
    authEmailNotVerified: 'Please verify your email before continuing.',
    authInvalidCredential: 'Invalid email or password.',
    authAccountDisabled: 'This account has been disabled.',
    // PAY
    payCardDeclined: 'Your card was declined.',
    payInsufficientFunds: 'Insufficient funds on your card.',
    payExpiredCard: 'Your card has expired.',
    payInvalidCard: 'Invalid card details.',
    payAmountMismatch: 'Order amount changed during checkout.',
    payCheckoutExpired: 'Checkout session expired. Please restart.',
    payRefundFailed: 'Refund could not be processed.',
    paySellerSuspended: 'This seller account is currently suspended.',
    payProductUnavailable: 'One or more products are no longer available.',
    payAsyncPending: 'Payment is being processed.',
    payStripeRedirectFailed: 'Could not open payment page.',
    payBiometricFailed: 'Biometric authentication failed.',
    payCouponInvalid: 'Coupon code is not valid.',
    payCouponExpired: 'This coupon has expired.',
    // ORD
    ordNotFound: 'Order not found.',
    ordCancelNotAllowed: 'This order cannot be cancelled at this stage.',
    ordAlreadyCancelled: 'Order is already cancelled.',
    ordReturnWindowExpired: 'The 30-day return window has closed.',
    ordReturnNotAllowed: 'This order is not eligible for return.',
    ordStatusInvalid: 'Invalid order status transition.',
    ordBiometricFailed: 'Biometric confirmation failed.',
    ordConfirmFailed: 'Failed to confirm receipt.',
    ordDownloadFailed: 'Failed to download digital product.',
    // CART
    cartEmpty: 'Your cart is empty.',
    cartItemsChanged: 'Some cart items have changed. Please review.',
    cartItemsRemoved: 'Unavailable items were removed from your cart.',
    cartPriceChanged: 'Prices have changed. Please review your cart.',
    cartStockChanged: 'Stock levels have changed.',
    cartAddressRequired: 'A delivery address is required.',
    cartAddressInvalid: 'The delivery address is invalid.',
    // SHIP
    shipCostCalcFailed: 'Could not calculate shipping cost.',
    shipAddressInvalid: 'Invalid shipping address.',
    shipProviderUnavailable: 'Shipping service temporarily unavailable.',
    shipApprovalExpired: 'Shipping approval window has expired.',
    shipCostTooHigh: 'Shipping cost exceeds the allowed maximum.',
    // PROD
    prodNotFound: 'Product not found.',
    prodOutOfStock: 'This product is out of stock.',
    prodNotAvailable: 'This product is not currently available.',
    prodImageUploadFailed: 'Image upload failed.',
    prodInvalidCategory: 'Invalid product category.',
    prodVideoTooLarge: 'Video exceeds the 100 MB size limit.',
    prodVideoTooLong: 'Video exceeds the 1-minute duration limit.',
    prodVideoInvalidFormat: 'Unsupported video format.',
    prodVideoUploadFailed: 'Video upload failed.',
    // SELL
    sellOnboardingIncomplete: 'Please complete seller onboarding first.',
    sellPayoutsDisabled: 'Payouts are currently disabled for your account.',
    sellAccountSuspended: 'Your seller account is suspended.',
    sellStripeNotConnected: 'Connect your Stripe account to receive payouts.',
    sellVerificationFailed: 'Seller verification failed.',
    // PERM
    permUnauthorized: 'You are not authorised to perform this action.',
    permSellerRequired: 'A seller account is required.',
    permAdminRequired: 'Admin access required.',
    permPremiumRequired: 'Origna Premium is required for this feature.',
    permSelfPurchaseBlocked: 'You cannot purchase your own products.',
    // PREM
    premFeatureGated: 'Upgrade to Origna Premium to unlock this feature.',
    premSubscriptionFailed: 'Premium subscription could not be activated.',
    premTrialExpired: 'Your free trial has ended.',
    // ADMIN
    adminMfaFailed: 'Admin MFA verification failed.',
    adminRoleUpdateFailed: 'Could not update user roles.',
    adminSuspendFailed: 'Account suspension action failed.',
    adminProductModerateFailed: 'Product moderation action failed.',
    adminRefundFailed: 'Admin refund could not be processed.',
    // SYS
    sysNetworkError: 'Network error. Check your connection.',
    sysServerError: 'Server error. Our team has been notified.',
    sysTimeout: 'Request timed out. Please try again.',
    sysServiceDegraded: 'Service is temporarily degraded.',
    sysUnknown: 'An unexpected error occurred.',
  };
}
