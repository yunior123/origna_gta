# OrignaGTA — Error Code Reference

Format: `ORIGNA-{DOMAIN}-{NUMBER}`

Internal support event IDs use a separate format such as `SE-20260423-014587`.
These are stored in the internal `error_events` collection and linked to the
user-facing `ORIGNA-*` code, stack trace, environment, auth context, route or
action, and support metadata.

Users see codes appended to error messages, e.g.:
> "Card declined [ORIGNA-PAY-001]"

They can quote the code when contacting **support@orignagta.ca** for faster resolution.

---

## AUTH — Authentication

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-AUTH-001` | `authEmailInUse` | This email address is already registered. |
| `ORIGNA-AUTH-002` | `authWrongPassword` | Incorrect password. |
| `ORIGNA-AUTH-003` | `authUserNotFound` | No account found with this email. |
| `ORIGNA-AUTH-004` | `authWeakPassword` | Password must be at least 8 characters. |
| `ORIGNA-AUTH-005` | `authTooManyRequests` | Too many attempts. Please wait and try again. |
| `ORIGNA-AUTH-006` | `authGoogleSignInFailed` | Google sign-in failed. |
| `ORIGNA-AUTH-007` | `authAppleSignInFailed` | Apple sign-in failed. |
| `ORIGNA-AUTH-008` | `authSessionExpired` | Your session expired. Please sign in again. |
| `ORIGNA-AUTH-009` | `authMfaRequired` | Two-factor authentication required. |
| `ORIGNA-AUTH-010` | `authEmailNotVerified` | Please verify your email before continuing. |
| `ORIGNA-AUTH-011` | `authInvalidCredential` | Invalid email or password. |
| `ORIGNA-AUTH-012` | `authAccountDisabled` | This account has been disabled. |

---

## PAY — Payments & Stripe

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-PAY-001` | `payCardDeclined` | Your card was declined. |
| `ORIGNA-PAY-002` | `payInsufficientFunds` | Insufficient funds on your card. |
| `ORIGNA-PAY-003` | `payExpiredCard` | Your card has expired. |
| `ORIGNA-PAY-004` | `payInvalidCard` | Invalid card details. |
| `ORIGNA-PAY-005` | `payAmountMismatch` | Order amount changed during checkout. |
| `ORIGNA-PAY-006` | `payCheckoutExpired` | Checkout session expired. Please restart. |
| `ORIGNA-PAY-007` | `payRefundFailed` | Refund could not be processed. |
| `ORIGNA-PAY-008` | `paySellerSuspended` | This seller account is currently suspended. |
| `ORIGNA-PAY-009` | `payProductUnavailable` | One or more products are no longer available. |
| `ORIGNA-PAY-010` | `payAsyncPending` | Payment is being processed. |
| `ORIGNA-PAY-011` | `payStripeRedirectFailed` | Could not open payment page. |
| `ORIGNA-PAY-012` | `payBiometricFailed` | Biometric authentication failed. |
| `ORIGNA-PAY-013` | `payCouponInvalid` | Coupon code is not valid. |
| `ORIGNA-PAY-014` | `payCouponExpired` | This coupon has expired. |

---

## ORD — Orders

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-ORD-001` | `ordNotFound` | Order not found. |
| `ORIGNA-ORD-002` | `ordCancelNotAllowed` | This order cannot be cancelled at this stage. |
| `ORIGNA-ORD-003` | `ordAlreadyCancelled` | Order is already cancelled. |
| `ORIGNA-ORD-004` | `ordReturnWindowExpired` | The 30-day return window has closed. |
| `ORIGNA-ORD-005` | `ordReturnNotAllowed` | This order is not eligible for return. |
| `ORIGNA-ORD-006` | `ordStatusInvalid` | Invalid order status transition. |
| `ORIGNA-ORD-007` | `ordBiometricFailed` | Biometric confirmation failed. |
| `ORIGNA-ORD-008` | `ordConfirmFailed` | Failed to confirm receipt. |
| `ORIGNA-ORD-009` | `ordDownloadFailed` | Failed to download digital product. |

---

## CART — Cart & Checkout Validation

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-CART-001` | `cartEmpty` | Your cart is empty. |
| `ORIGNA-CART-002` | `cartItemsChanged` | Some cart items have changed. Please review. |
| `ORIGNA-CART-003` | `cartItemsRemoved` | Unavailable items were removed from your cart. |
| `ORIGNA-CART-004` | `cartPriceChanged` | Prices have changed. Please review your cart. |
| `ORIGNA-CART-005` | `cartStockChanged` | Stock levels have changed. |
| `ORIGNA-CART-006` | `cartAddressRequired` | A delivery address is required. |
| `ORIGNA-CART-007` | `cartAddressInvalid` | The delivery address is invalid. |

---

## SHIP — Shipping

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-SHIP-001` | `shipCostCalcFailed` | Could not calculate shipping cost. |
| `ORIGNA-SHIP-002` | `shipAddressInvalid` | Invalid shipping address. |
| `ORIGNA-SHIP-003` | `shipProviderUnavailable` | Shipping service temporarily unavailable. |
| `ORIGNA-SHIP-004` | `shipApprovalExpired` | Shipping approval window has expired. |
| `ORIGNA-SHIP-005` | `shipCostTooHigh` | Shipping cost exceeds the allowed maximum. |

---

## PROD — Products

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-PROD-001` | `prodNotFound` | Product not found. |
| `ORIGNA-PROD-002` | `prodOutOfStock` | This product is out of stock. |
| `ORIGNA-PROD-003` | `prodNotAvailable` | This product is not currently available. |
| `ORIGNA-PROD-004` | `prodImageUploadFailed` | Image upload failed. |
| `ORIGNA-PROD-005` | `prodInvalidCategory` | Invalid product category. |
| `ORIGNA-PROD-006` | `prodVideoTooLarge` | Video exceeds the 100 MB size limit. |
| `ORIGNA-PROD-007` | `prodVideoTooLong` | Video exceeds the 1-minute duration limit. |
| `ORIGNA-PROD-008` | `prodVideoInvalidFormat` | Unsupported video format. |
| `ORIGNA-PROD-009` | `prodVideoUploadFailed` | Video upload failed. |

---

## SELL — Seller Account

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-SELL-001` | `sellOnboardingIncomplete` | Please complete seller onboarding first. |
| `ORIGNA-SELL-002` | `sellPayoutsDisabled` | Payouts are currently disabled for your account. |
| `ORIGNA-SELL-003` | `sellAccountSuspended` | Your seller account is suspended. |
| `ORIGNA-SELL-004` | `sellStripeNotConnected` | Connect your Stripe account to receive payouts. |
| `ORIGNA-SELL-005` | `sellVerificationFailed` | Seller verification failed. |

---

## PERM — Permissions

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-PERM-001` | `permUnauthorized` | You are not authorised to perform this action. |
| `ORIGNA-PERM-002` | `permSellerRequired` | A seller account is required. |
| `ORIGNA-PERM-003` | `permAdminRequired` | Admin access required. |
| `ORIGNA-PERM-004` | `permPremiumRequired` | Origna Premium is required for this feature. |
| `ORIGNA-PERM-005` | `permSelfPurchaseBlocked` | You cannot purchase your own products. |

---

## PREM — Premium Subscription

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-PREM-001` | `premFeatureGated` | Upgrade to Origna Premium to unlock this feature. |
| `ORIGNA-PREM-002` | `premSubscriptionFailed` | Premium subscription could not be activated. |
| `ORIGNA-PREM-003` | `premTrialExpired` | Your free trial has ended. |

---

## ADMIN — Admin Panel

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-ADMIN-001` | `adminMfaFailed` | Admin MFA verification failed. |
| `ORIGNA-ADMIN-002` | `adminRoleUpdateFailed` | Could not update user roles. |
| `ORIGNA-ADMIN-003` | `adminSuspendFailed` | Account suspension action failed. |
| `ORIGNA-ADMIN-004` | `adminProductModerateFailed` | Product moderation action failed. |
| `ORIGNA-ADMIN-005` | `adminRefundFailed` | Admin refund could not be processed. |

---

## SYS — System / Infrastructure

| Code | Constant | Description |
|------|----------|-------------|
| `ORIGNA-SYS-001` | `sysNetworkError` | Network error. Check your connection. |
| `ORIGNA-SYS-002` | `sysServerError` | Server error. Our team has been notified. |
| `ORIGNA-SYS-003` | `sysTimeout` | Request timed out. Please try again. |
| `ORIGNA-SYS-004` | `sysServiceDegraded` | Service is temporarily degraded. |
| `ORIGNA-SYS-999` | `sysUnknown` | An unexpected error occurred. |

---

## Usage

### Dart (in ViewModels / Services)

```dart
// Attach a known code to a user-facing message
final msg = AppError.getMessage(error, fallback, ErrorCodes.payCardDeclined);
AppError.show(context, msg);

// Look up description for any code
final desc = ErrorCodes.describe('ORIGNA-PAY-001');
// → "Your card was declined."
```

### Backend (OrignaBase / Rust)

Append the code in the error message body so the Flutter SDK surfaces it automatically:
```
"Card declined [ORIGNA-PAY-001]"
```
`AppError.getMessage()` detects the `[ORIGNA-*]` pattern and avoids double-coding.

### Internal Error Events

- Collection: `error_events`
- Primary fields:
  - `internalEventId` — support/debug event ID such as `SE-20260423-014587`
  - `errorCode` — user-facing `ORIGNA-*` code
  - `userFacingMessage` — sanitized message shown to the user
  - `errorType` / `errorMessage` / `stackTrace`
  - `environment` / `source` / `routeOrAction` / `severity` / `status`
  - `userId` / `email`
  - `metadata` / `fingerprint` / `createdAt`
- Recommended flow:
  - capture the exception in Sentry
  - persist an `error_events` row with the same fingerprint and a durable internal event ID
  - show only the sanitized `ORIGNA-*` code to the user
  - if the UI collects feedback, attach `associatedEventId` from Sentry plus the user's contact details and reproduction notes
- Write path:
  - `AppError.log()` captures to Sentry and best-effort persists a structured
    event through `ErrorEventService`
  - top-level unhandled Flutter and zone errors also flow through `AppError.log()`

### Official References

- Stripe Checkout: `https://docs.stripe.com/payments/checkout`
- Postal Send API v3.1: `https://dev.postal.com/email/guides/send-api-v31/`
- PostgreSQL JSON/JSONB: `https://www.postgresql.org/docs/current/datatype-json.html`
- Sentry Flutter SDK: `https://docs.sentry.io/platforms/dart/guides/flutter/`
- Sentry user feedback: `https://docs.sentry.io/platforms/dart/guides/flutter/user-feedback`

---

*Last updated: 2026-04-23 — 9 domains, 54 codes, internal error-event pipeline documented*
