# Cross-Stack Auditor Memory

## Verified Field Mappings (2026-03-01)
- checkout: `subtotalCents` in Python (`ApiKeys.SUBTOTAL_CENTS`) = `subtotalCents` in Dart (`ApiKeys.subtotalCents`) -- OK
- checkout: `idempotencyKey` in Python = `idempotencyKey` in Dart -- OK
- checkout: `checkoutUrl` in both -- OK
- checkout: `sessionId` in both -- OK
- checkout: `orderId` (Fields) in both -- OK
- checkout: `taxAmountCents` (Fields) in both -- OK
- checkout: `shippingAddress` (Fields) in both -- OK
- checkout: `items` (Fields) in both -- OK
- subscription: `checkoutUrl` string key in both -- OK
- subscription: `Fields.status` / `Fields.STATUS` both = "status" -- OK
- subscription: `cancelAtPeriodEnd` / `CANCEL_AT_PERIOD_END` both = "cancelAtPeriodEnd" -- OK
- orders: `ApiKeys.newStatus` / `ApiKeys.NEW_STATUS` both = "newStatus" -- OK
- DeliveryStatusValues, DeliveryItemStatusTransitions, OrderStatusValues -- all aligned
- PaymentStatusValues -- all aligned except `voided` missing from Python `ALL` set
- Tax rates (BusinessRules) -- all 13 provinces match between Dart and Python

## Known Mismatches Found (2026-03-01)
1. SecurityAlertTypes.refundFailed: Dart = 'refund_failed' (line 1483), Python = 'refund.failed' (line 1158) -- VALUE MISMATCH
2. Fields.newRoles: Dart = 'newRoles' (line 1035), Python = 'new_roles' (line 784) -- CASE MISMATCH
3. BusinessRules.trendingFavoriteWeight: Dart = 1 (line 163), Python = 2 (line 1622) -- VALUE MISMATCH
4. PaymentStatusValues.voided: present in Dart (line 1302), MISSING from Python `ALL` frozenset (line 1000-1018)
5. FilterValues: Dart has {recent, popular, price_low_to_high, price_high_to_low, top_rated}, Python only has {all: "all"} -- scope divergence
6. Fields.sellerRating/sellerRatingCount: present in Python (lines 423-424), MISSING from Dart Fields class
7. Collections.platformDebt: present in Python (line 92), MISSING from Dart Collections class

## Patterns That Frequently Cause Bugs
- SecurityAlertTypes string literals: Dart uses underscore separator, Python uses dot for some (refundFailed)
- Field name casing: Python uses snake_case for Firestore values sometimes (new_roles vs newRoles)
- Business constants: numeric values can drift between the two files silently
