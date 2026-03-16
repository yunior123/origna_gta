---
name: stripe-payment-spec-audit-2026-03-16
description: Payment pipeline audit findings for stripe-payment.spec.ts and Flutter checkout layer
type: project
---

Audit performed 2026-03-16 on stripe-payment.spec.ts + checkout Flutter layer.

**Why:** Routine pre-ship payment audit. Real money + real users involved.

**How to apply:** Reference before any future changes to checkout_screen.dart, orignabase_checkout_provider.dart, or stripe-payment.spec.ts.

## Critical Findings
- None in the spec file itself. No Stripe secret keys found anywhere in lib/ or e2e/.

## Warnings Found

### W1 — Float money in checkout_screen.dart (display layer bleeds into logic)
`checkout_screen.dart` lines 142, 258–259, 390, 967, 1503, 1572 use `double subtotal` / `double total` as widget constructor parameters. The `_CheckoutButton` receives `double total` and passes it to `startCheckout(subtotal: double)`. The provider converts at line 361: `(subtotal * 100).round()`. This is the correct boundary BUT `Fields.price: item.price` at line 345 passes the raw float price per item to the backend — the backend must re-derive cents from this float, creating a rounding risk for items with non-round prices (e.g. $9.99 → float multiplication error).

### W2 — `Fields.price` in order items payload is a float, not cents
`orignabase_checkout_provider.dart:345` sends `Fields.price: item.price` where `item.price` is a `double` (dollars). The Dart model `CartItemDetailModel.price` is a float. Correct pattern is `Fields.priceCents: item.priceCents` (integer). The backend must guard against this.

### W3 — `buildMultiSellerPayload` uses `product.price * quantity` float accumulation
`api-helpers.ts:1763` — `subtotal += product.price * quantity` uses float accumulation across loop iterations, then `Math.round(subtotal * 100)` at line 1769. Multiple items with non-round prices will accumulate rounding error before the final round(). Should be `subtotal += (product.priceCents ?? Math.round(product.price * 100)) * quantity` and skip the outer round.

### W4 — Test confirms order on 'processing' status — spec allows non-webhook confirmation path
`stripe-payment.spec.ts:35,51,79,122,143` — `waitForOrderStatus` accepts `['confirmed', 'processing']`. The rules require order confirmation ONLY via `payment_intent.succeeded` webhook. If `processing` is a valid non-terminal state that appears before webhook fires, this is fine. But if `processing` can be set by redirect alone, this is a CRITICAL. Needs backend clarification.

### W5 — `order.platformFeeRatio` asserted as hardcoded 0.025
`stripe-payment.spec.ts:62` — hardcodes the expected platform fee ratio as a magic number `0.025`. Should reference a shared constant (e.g. `BusinessRules.PLATFORM_FEE_RATIO`). If the fee rate changes, this test will fail silently in CI until someone notices.

## OK
- No Stripe secret keys (sk_*, whsec_*) anywhere in lib/ or e2e/.
- Idempotency keys present and correctly formatted in both the spec (lines 75, 109) and the Flutter provider (line 367).
- `subtotalCents` sent as integer cents from provider: `(subtotal * 100).round()` — correct.
- Checkout session created server-side via OrignaBase, not direct Stripe API call.
- `waitForOrderStatus` polls on `orderStatus` field, not on redirect URL alone.
- Checkout URL validated to contain `checkout.stripe.com` (lines 33, 96, 99).
- Duplicate idempotency key test verifies same orderId returned (line 114).
- `TEST_ACCOUNTS` centralizes credentials — no hardcoded emails/passwords in spec.
- `shippingCostCents` / `taxAmountCents` / `totalAmountCents` / `subtotalCents` all use integer cents in the order document assertions.
