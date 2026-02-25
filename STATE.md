# STATE.md

Here is the complete audit of all five E2E test spec files.

---

**[CRITICAL] buyer-flow_spec.ts:37**
PROBLEM: `ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD)` logs in with buyer credentials using a function named `ensureLoggedInAsAdmin` — if that helper performs role grants or admin-specific setup (highly likely given the name), every buyer-flow test runs with corrupted auth state and the coverage is invalid.
FIX: Create and use a dedicated `ensureLoggedInAsBuyer` helper; audit `flutter-helpers.ts` to confirm `ensureLoggedInAsAdmin` does not grant elevated roles.

**[CRITICAL] buyer-flow_spec.ts:61**
PROBLEM: `expect(saveVisible || true).toBeTruthy()` — `|| true` makes the assertion unconditionally pass; the save-address button visibility is never actually tested. Same pattern on line ~82: `expect(hasTax || true).toBeTruthy()`.
FIX: Remove `|| true` from both assertions. For mandatory elements use `expect(element).toBeVisible()`; for optional ones assert the specific condition or remove the assertion entirely.

**[CRITICAL] payment-edge-cases_spec.ts:87**
PROBLEM: The 3DS test ends with `expect(page.url()).toBeTruthy()` — any non-empty URL string (including `'about:blank'`) passes. The test provides zero signal: it will green even if the page crashed, the card was silently declined, or 3DS never appeared.
FIX: After 3DS completion assert the redirect: `await expect(page).toHaveURL(/payment-success|orignagta/, { timeout: 30_000 })` and verify the order document's `paymentStatus` is `'captured'` via `readDoc`.

**[CRITICAL] payment-edge-cases_spec.ts (missing test)**
PROBLEM: No test verifies that `stockQuantity` is NOT decremented after a declined card — this is a critical business invariant and directly related to the CRITICAL audit finding that stock restoration in `process_payment_intent_failed` is broken.
FIX:
```typescript
test('Stock not decremented after declined card', async ({ page }) => {
  const stockBefore = await getProductStock(product.id, buyerAuth.idToken);
  // ... fill declined card, submit ...
  await page.waitForTimeout(15_000);
  const stockAfter = await getProductStock(product.id, buyerAuth.idToken);
  expect(stockAfter).toBe(stockBefore);
});
```

**[CRITICAL] checkout-validation_spec.ts (missing test)**
PROBLEM: No test verifies self-purchase prevention — a user whose UID matches a product's `sellerId` should be rejected server-side, but there is no test for this. This is checklist item #3.
FIX:
```typescript
test('Rejects self-purchase (buyer is the seller)', async () => {
  // Use a product where sellerId === buyerAuth.localId
  const { data } = await buildCheckoutPayload(sellerAuth.localId, sellerOwnProductId, 1, sellerAuth.idToken);
  const error = await callExpectError('create_checkout_session', data, sellerAuth.idToken);
  expect(error.code).toBe('failed-precondition');
});
```

**[CRITICAL] checkout-validation_spec.ts (missing test)**
PROBLEM: No test for invalid province code (e.g., `state: 'XX'`) — directly maps to the [BONUS] audit finding. Backend silently falls back to Ontario 13% tax for unknown province codes, meaning a buyer in `'XX'` province pays wrong tax and their address passes checkout validation.
FIX:
```typescript
test('Rejects invalid province code', async () => {
  const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
  data.shippingAddress.state = 'XX';
  const error = await callExpectError('create_checkout_session', data, buyerAuth.idToken);
  expect(error.code).toBe('invalid-argument');
});
```

---

**[HIGH] stripe-payment_spec.ts:21,29,39,51**
PROBLEM: `invalidateProductCache()` is called without `await` in all four tests — if the function is async, the promise is silently discarded and the cache may not be invalidated before `getTestProduct` runs, causing all tests to operate on a stale/same cached product and race on its stock.
FIX: `await invalidateProductCache()` in every call site.

**[HIGH] stripe-payment_spec.ts:27**
PROBLEM: `waitForOrderStatus` followed by `page.waitForTimeout(5_000)` (line ~33 in `Order document` test) — fixed 5-second sleep to wait for webhook delivery is flaky: too short on slow CI, wasteful on fast hardware. The test also does not check `chargeId`, `stripeSessionId`, or that `platformFeeRatio` was stored on the order doc (critical for the [CRITICAL] fee rate bug).
FIX: Remove `page.waitForTimeout(5_000)`. Use `waitForOrderStatus` consistently. Add assertions: `expect(order.platformFeeRatio).toBe(0.025)` and `expect(order.stripeSessionId).toBeTruthy()`.

**[HIGH] stripe-payment_spec.ts (missing test)**
PROBLEM: No idempotency test — calling `create_checkout_session` twice with the same `idempotencyKey` must not create two orders. Checklist item #2 is completely uncovered.
FIX:
```typescript
test('Duplicate checkout session with same idempotency key does not create two orders', async () => {
  const { data, idempotencyKey } = await buildCheckoutPayload(...);
  const r1 = await callOk('create_checkout_session', data, auth.idToken);
  const r2 = await callOk('create_checkout_session', data, auth.idToken); // same key
  expect(r1.orderId).toBe(r2.orderId);
});
```

**[HIGH] checkout-validation_spec.ts:all error tests**
PROBLEM: Every error assertion uses `expect(error.code).not.toBe('unexpected-success')` — this passes even if the function throws a generic 500 (network error, unhandled exception). It provides no signal about *which* validation fired. A backend crashing for an unrelated reason would be indistinguishable from intentional rejection.
FIX: Assert the specific expected code: `expect(error.code).toBe('invalid-argument')` for input validation errors, `'failed-precondition'` for business rule violations. This makes failures diagnostic.

**[HIGH] payment-edge-cases_spec.ts:62**
PROBLEM: The declined card test asserts `page.url().includes('checkout.stripe.com')` — this is true from the moment the page loads, before the card is even submitted. There's no assertion that a visible error message appeared (e.g., "Your card was declined").
FIX:
```typescript
const errorEl = page.locator('[data-testid="error-message"], .Alert--error, text=/declined|card number is incorrect/i').first();
await expect(errorEl).toBeVisible({ timeout: 15_000 });
```

**[HIGH] payment-edge-cases_spec.ts (missing test)**
PROBLEM: No test verifies the Firestore order `paymentStatus` after a declined card — backend should set it to `'payment_failed'` (or leave it `'awaiting_payment'`), not `'captured'`. This would catch a regression where the backend incorrectly marks failed payments as successful.
FIX: After the declined card submission, poll `readDoc(`orders/${result.orderId}`)` and assert `order.paymentStatus !== 'captured'`.

**[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')**
PROBLEM: The test creates a product via `writeDoc` with only `price: 10.00` but no `priceCents: 1000` field. The backend's `verify_cart_prices` may read `priceCents` (integer cents, the canonical field per schema), find it missing (`null`), and either crash or silently accept any client price, making this test not actually exercise price validation.
FIX: Add `priceCents: 1000` to the `toFirestoreFields({...})` payload, or use the product-creation Cloud Function instead of direct Firestore write.

**[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')**
PROBLEM: Created test product is never deleted — `afterAll` cleanup is absent. In a dev environment shared by the whole team, this leaks a permanent `test_ship_stock_{timestamp}` product into the `products` collection on every test run.
FIX:
```typescript
test.afterAll(async () => {
  await deleteDoc(`products/${productId}`, adminAuth.idToken);
});
```

---

**[MEDIUM] buyer-flow_spec.ts (one monolithic test)**
PROBLEM: The entire buyer journey is one `test()` block — if the settings button click fails at step B01, all subsequent 15+ assertions are skipped with no failure output. Playwright reports a single "failed test" with no granularity on which step broke.
FIX: Split into individual `test()` cases: `'Profile page navigates correctly'`, `'Address management works'`, `'Cart navigates to checkout'`, etc., each with independent setup.

**[MEDIUM] buyer-flow_spec.ts:optional steps pattern**
PROBLEM: Critical user-facing elements (My Orders, Cart button, checkout button) are wrapped in `if (await element.isVisible().catch(() => false))` — if these elements are absent due to a bug, the test silently passes without exercising those paths. The test provides false green coverage.
FIX: For mandatory elements: `await expect(menuOrders).toBeVisible()` with no `if` wrapping. Reserve the `if` pattern only for genuinely optional UI (e.g., cookie banners, promotional modals).

**[MEDIUM] buyer-flow_spec.ts:end**
PROBLEM: `performSignOut` is called but there's no assertion that the sign-out succeeded — no check that the page redirected to login, no attempt to access a protected route afterward, and no token invalidation check.
FIX: After `performSignOut`, assert `await expect(page).toHaveURL(/login|sign-in/, { timeout: 15_000 })` and verify that `readDoc('orders/any', invalidated token)` returns an auth error.

**[MEDIUM] stripe-payment_spec.ts:test('Stock decremented…')**
PROBLEM: `expect(stockAfter).toBeLessThan(stockBefore)` passes even if stock dropped by 5 instead of 1 (the ordered quantity). A bug that over-decrements stock would not be caught.
FIX: `expect(stockAfter).toBe(stockBefore - 1)` — assert the exact delta equals the ordered quantity.

**[MEDIUM] checkout-validation_spec.ts (missing tests)**
PROBLEM: Missing coverage for: (a) `quantity: 999` exceeding `ValidationLimits.MAX_ITEM_QUANTITY = 100`, (b) `country: 'United States'` bypassing the Canada-only buyer check (checklist item #7), (c) `quantity: -1` (negative quantity).
FIX: Add three tests, each with `expect(error.code).toBe('invalid-argument')`.

**[MEDIUM] shipping-calculation_spec.ts:Ontario tax range**
PROBLEM: Tax range `10%–16%` is too loose — Ontario HST is exactly 13%. A bug applying BC's 12% (GST+PST) or PE's 15% (HST) would pass the assertion. The test masks province-selection bugs.
FIX: `expect(order.taxAmountCents).toBeCloseTo(taxableBase * 0.13, -1)` — allow ±1 cent rounding but pin to the correct rate.

**[MEDIUM] shipping-calculation_spec.ts (missing tests)**
PROBLEM: No test for (a) Quebec (QST+GST = 14.975%), (b) Alberta (GST only = 5%), (c) free shipping threshold — orders above `BusinessRules.FREE_SHIPPING_THRESHOLD_CENTS` ($75) should have `shippingCostCents = 0` for standard delivery. Three core business rules are fully uncovered.
FIX: Add one test per province scenario and one for the free shipping threshold: `expect(order.shippingCostCents).toBe(0)` for a $100 order.

**[MEDIUM] payment-edge-cases_spec.ts:3DS iframe**
PROBLEM: `threeDSFrame.locator(...).click()` is wrapped in `try { ... } catch { }` with silent swallowing — if the 3DS challenge appeared but the click failed, the test continues without completing authentication. The frame selector `iframe[name*="stripe-challenge"]` may also not match Stripe's actual iframe name, meaning 3DS is never completed in any environment.
FIX: Log the catch: `} catch (e) { console.warn('3DS frame not found or click failed:', e); }`. Add a separate test that explicitly asserts 3DS challenge appearance: `await expect(threeDSFrame.locator('#test-source-authorize-3ds')).toBeVisible({ timeout: 15_000 })`.

---

**[LOW] stripe-payment_spec.ts (missing test)**
PROBLEM: No test for `source_transaction` correctness (checklist item #4) — after payment, the payout transfer's `source_transaction` must be a `ch_xxx` charge ID, not the `pi_xxx` PaymentIntent ID. This is never verified.
FIX: After order reaches `'confirmed'` status, read the `payouts` collection for the order and assert `payout.stripeTransferId` starts with `'tr_'` and is non-null. The actual `source_transaction` check requires Stripe API access — add a test that retrieves the transfer from Stripe and asserts `transfer.source_transaction.startsWith('ch_')`.

**[LOW] stripe-payment_spec.ts (missing test)**
PROBLEM: No test verifying `platformFeeRatio` is stored on the order document at checkout time (required to fix the [CRITICAL] fee rate bug). If the field is absent, `_execute_seller_payouts` silently falls back to the global config.
FIX: In `'Order document has correct structure'`, add `expect(order.platformFeeRatio).toBe(0.025)`.

**[LOW] buyer-flow_spec.ts:scroll**
PROBLEM: `page.mouse.wheel(0, 220)` uses a fixed 220px scroll — product card height varies by screen size and Flutter rendering. On a 1080p screen this may scroll less than one card; on a mobile viewport it may overshoot. Tests scroll up to 6 times with no guarantee of finding cards.
FIX: `await page.evaluate(() => window.scrollBy(0, window.innerHeight * 0.8))` per iteration, or use `await page.locator('[aria-label^="product-card-"]').first().waitFor({ timeout: 10_000 })` before attempting the click.

**[LOW] checkout-validation_spec.ts:beforeAll product reuse**
PROBLEM: `productId` is set once in `beforeAll` and reused across 8 tests. If the product's stock is exhausted mid-suite (e.g., a test accidentally completes payment), subsequent tests get stock-exhaustion errors instead of their intended validation errors, causing confusing failures.
FIX: Use `getTestProduct` per test or ensure `callExpectError` never creates a paid order. Alternatively mock the product with `stockQuantity: 1000` via `writeDoc` in `beforeAll`.

**[LOW] payment-edge-cases_spec.ts:email per test**
PROBLEM: Each edge-case test fills a unique email (`test-decline-${Date.now()}@origna-test.ca`) to Stripe's email field — but the checkout session was created with the buyer's real email attached to the Stripe customer. Stripe's hosted page may ignore the email input for returning customers, meaning the `email.fill()` call is silently a no-op and the test is not actually testing the email-as-new-customer path.
FIX: Remove the email-fill step from edge case tests since the session already has an associated Stripe customer; or explicitly test guest checkout with a session created without a `customer` ID.

**[BONUS] All specs**
PROBLEM: No test covers the cart-cleared-after-order-creation invariant (checklist item #10) — after a successful payment, `users/{userId}/cart` should be empty. A bug that preserves cart items after checkout would go undetected.
FIX: After `waitForOrderStatus(orderId, ['confirmed'])`, read `users/{buyerId}/cart` and `expect(cartItems.length).toBe(0)`.

**[BONUS] All specs**
PROBLEM: No test for the `expiresAt` field being present on the order document (7-day authorization window, checklist item #5). Per the audit, this field is set even in auto-capture mode (dead code finding), but its value should still be within 7 days of `createdAt`.
FIX: In `'Order document has correct structure'`: `const delta = order.expiresAt._seconds - order.createdAt._seconds; expect(delta).toBeLessThanOrEqual(7 * 86400);`

**[BONUS] shipping-calculation_spec.ts:Multiple quantity test**
PROBLEM: Two separate `callOk('create_checkout_session', ...)` calls are made to compare qty=1 vs qty=2. Any price change, rate-limit, or cold-start latency between the two calls can produce a non-2× ratio, making the test flaky.
FIX: Compute the expected subtotal mathematically from the known product price (`10.00`): `expect(order1.subtotalCents).toBe(1000); expect(order2.subtotalCents).toBe(2000)` — no cross-order ratio needed.

**[BONUS] All specs**
PROBLEM: No test for the `currency` field at the Stripe API level — all tests verify `order.currency === 'cad'` in Firestore, but never assert the Stripe PaymentIntent was created in CAD. A bug that creates the intent in USD would not be caught by these tests.
FIX: Retrieve the Stripe PaymentIntent via the Stripe test API using `order.stripePaymentIntentId` and assert `pi.currency === 'cad'`.

**[BONUS] checkout-validation_spec.ts**
PROBLEM: No rate-limiting test despite the comment `// Needs extra time for rate limit retries`. `BusinessRules.CHECKOUT_RATE_LIMIT = 5` per minute — this should be enforced. The test file promises coverage it does not deliver.
FIX: Add a test that fires 6 rapid `create_checkout_session` calls in succession and asserts the 6th returns `'resource-exhausted'` or `'too-many-requests'`.

Here is the complete audit of all five E2E test spec files.

---

**[CRITICAL] buyer-flow_spec.ts:37**
PROBLEM: `ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD)` logs in with buyer credentials using a function named `ensureLoggedInAsAdmin` — if that helper performs role grants or admin-specific setup (highly likely given the name), every buyer-flow test runs with corrupted auth state and the coverage is invalid.
FIX: Create and use a dedicated `ensureLoggedInAsBuyer` helper; audit `flutter-helpers.ts` to confirm `ensureLoggedInAsAdmin` does not grant elevated roles.

**[CRITICAL] buyer-flow_spec.ts:61**
PROBLEM: `expect(saveVisible || true).toBeTruthy()` — `|| true` makes the assertion unconditionally pass; the save-address button visibility is never actually tested. Same pattern on line ~82: `expect(hasTax || true).toBeTruthy()`.
FIX: Remove `|| true` from both assertions. For mandatory elements use `expect(element).toBeVisible()`; for optional ones assert the specific condition or remove the assertion entirely.

**[CRITICAL] payment-edge-cases_spec.ts:87**
PROBLEM: The 3DS test ends with `expect(page.url()).toBeTruthy()` — any non-empty URL string (including `'about:blank'`) passes. The test provides zero signal: it will green even if the page crashed, the card was silently declined, or 3DS never appeared.
FIX: After 3DS completion assert the redirect: `await expect(page).toHaveURL(/payment-success|orignagta/, { timeout: 30_000 })` and verify the order document's `paymentStatus` is `'captured'` via `readDoc`.

**[CRITICAL] payment-edge-cases_spec.ts (missing test)**
PROBLEM: No test verifies that `stockQuantity` is NOT decremented after a declined card — this is a critical business invariant and directly related to the CRITICAL audit finding that stock restoration in `process_payment_intent_failed` is broken.
FIX:
```typescript
test('Stock not decremented after declined card', async ({ page }) => {
  const stockBefore = await getProductStock(product.id, buyerAuth.idToken);
  // ... fill declined card, submit ...
  await page.waitForTimeout(15_000);
  const stockAfter = await getProductStock(product.id, buyerAuth.idToken);
  expect(stockAfter).toBe(stockBefore);
});
```

**[CRITICAL] checkout-validation_spec.ts (missing test)**
PROBLEM: No test verifies self-purchase prevention — a user whose UID matches a product's `sellerId` should be rejected server-side, but there is no test for this. This is checklist item #3.
FIX:
```typescript
test('Rejects self-purchase (buyer is the seller)', async () => {
  // Use a product where sellerId === buyerAuth.localId
  const { data } = await buildCheckoutPayload(sellerAuth.localId, sellerOwnProductId, 1, sellerAuth.idToken);
  const error = await callExpectError('create_checkout_session', data, sellerAuth.idToken);
  expect(error.code).toBe('failed-precondition');
});
```

**[CRITICAL] checkout-validation_spec.ts (missing test)**
PROBLEM: No test for invalid province code (e.g., `state: 'XX'`) — directly maps to the [BONUS] audit finding. Backend silently falls back to Ontario 13% tax for unknown province codes, meaning a buyer in `'XX'` province pays wrong tax and their address passes checkout validation.
FIX:
```typescript
test('Rejects invalid province code', async () => {
  const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
  data.shippingAddress.state = 'XX';
  const error = await callExpectError('create_checkout_session', data, buyerAuth.idToken);
  expect(error.code).toBe('invalid-argument');
});
```

---

**[HIGH] stripe-payment_spec.ts:21,29,39,51**
PROBLEM: `invalidateProductCache()` is called without `await` in all four tests — if the function is async, the promise is silently discarded and the cache may not be invalidated before `getTestProduct` runs, causing all tests to operate on a stale/same cached product and race on its stock.
FIX: `await invalidateProductCache()` in every call site.

**[HIGH] stripe-payment_spec.ts:27**
PROBLEM: `waitForOrderStatus` followed by `page.waitForTimeout(5_000)` (line ~33 in `Order document` test) — fixed 5-second sleep to wait for webhook delivery is flaky: too short on slow CI, wasteful on fast hardware. The test also does not check `chargeId`, `stripeSessionId`, or that `platformFeeRatio` was stored on the order doc (critical for the [CRITICAL] fee rate bug).
FIX: Remove `page.waitForTimeout(5_000)`. Use `waitForOrderStatus` consistently. Add assertions: `expect(order.platformFeeRatio).toBe(0.025)` and `expect(order.stripeSessionId).toBeTruthy()`.

**[HIGH] stripe-payment_spec.ts (missing test)**
PROBLEM: No idempotency test — calling `create_checkout_session` twice with the same `idempotencyKey` must not create two orders. Checklist item #2 is completely uncovered.
FIX:
```typescript
test('Duplicate checkout session with same idempotency key does not create two orders', async () => {
  const { data, idempotencyKey } = await buildCheckoutPayload(...);
  const r1 = await callOk('create_checkout_session', data, auth.idToken);
  const r2 = await callOk('create_checkout_session', data, auth.idToken); // same key
  expect(r1.orderId).toBe(r2.orderId);
});
```

**[HIGH] checkout-validation_spec.ts:all error tests**
PROBLEM: Every error assertion uses `expect(error.code).not.toBe('unexpected-success')` — this passes even if the function throws a generic 500 (network error, unhandled exception). It provides no signal about *which* validation fired. A backend crashing for an unrelated reason would be indistinguishable from intentional rejection.
FIX: Assert the specific expected code: `expect(error.code).toBe('invalid-argument')` for input validation errors, `'failed-precondition'` for business rule violations. This makes failures diagnostic.

**[HIGH] payment-edge-cases_spec.ts:62**
PROBLEM: The declined card test asserts `page.url().includes('checkout.stripe.com')` — this is true from the moment the page loads, before the card is even submitted. There's no assertion that a visible error message appeared (e.g., "Your card was declined").
FIX:
```typescript
const errorEl = page.locator('[data-testid="error-message"], .Alert--error, text=/declined|card number is incorrect/i').first();
await expect(errorEl).toBeVisible({ timeout: 15_000 });
```

**[HIGH] payment-edge-cases_spec.ts (missing test)**
PROBLEM: No test verifies the Firestore order `paymentStatus` after a declined card — backend should set it to `'payment_failed'` (or leave it `'awaiting_payment'`), not `'captured'`. This would catch a regression where the backend incorrectly marks failed payments as successful.
FIX: After the declined card submission, poll `readDoc(`orders/${result.orderId}`)` and assert `order.paymentStatus !== 'captured'`.

**[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')**
PROBLEM: The test creates a product via `writeDoc` with only `price: 10.00` but no `priceCents: 1000` field. The backend's `verify_cart_prices` may read `priceCents` (integer cents, the canonical field per schema), find it missing (`null`), and either crash or silently accept any client price, making this test not actually exercise price validation.
FIX: Add `priceCents: 1000` to the `toFirestoreFields({...})` payload, or use the product-creation Cloud Function instead of direct Firestore write.

**[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')**
PROBLEM: Created test product is never deleted — `afterAll` cleanup is absent. In a dev environment shared by the whole team, this leaks a permanent `test_ship_stock_{timestamp}` product into the `products` collection on every test run.
FIX:
```typescript
test.afterAll(async () => {
  await deleteDoc(`products/${productId}`, adminAuth.idToken);
});
```

---

**[MEDIUM] buyer-flow_spec.ts (one monolithic test)**
PROBLEM: The entire buyer journey is one `test()` block — if the settings button click fails at step B01, all subsequent 15+ assertions are skipped with no failure output. Playwright reports a single "failed test" with no granularity on which step broke.
FIX: Split into individual `test()` cases: `'Profile page navigates correctly'`, `'Address management works'`, `'Cart navigates to checkout'`, etc., each with independent setup.

**[MEDIUM] buyer-flow_spec.ts:optional steps pattern**
PROBLEM: Critical user-facing elements (My Orders, Cart button, checkout button) are wrapped in `if (await element.isVisible().catch(() => false))` — if these elements are absent due to a bug, the test silently passes without exercising those paths. The test provides false green coverage.
FIX: For mandatory elements: `await expect(menuOrders).toBeVisible()` with no `if` wrapping. Reserve the `if` pattern only for genuinely optional UI (e.g., cookie banners, promotional modals).

**[MEDIUM] buyer-flow_spec.ts:end**
PROBLEM: `performSignOut` is called but there's no assertion that the sign-out succeeded — no check that the page redirected to login, no attempt to access a protected route afterward, and no token invalidation check.
FIX: After `performSignOut`, assert `await expect(page).toHaveURL(/login|sign-in/, { timeout: 15_000 })` and verify that `readDoc('orders/any', invalidated token)` returns an auth error.

**[MEDIUM] stripe-payment_spec.ts:test('Stock decremented…')**
PROBLEM: `expect(stockAfter).toBeLessThan(stockBefore)` passes even if stock dropped by 5 instead of 1 (the ordered quantity). A bug that over-decrements stock would not be caught.
FIX: `expect(stockAfter).toBe(stockBefore - 1)` — assert the exact delta equals the ordered quantity.

**[MEDIUM] checkout-validation_spec.ts (missing tests)**
PROBLEM: Missing coverage for: (a) `quantity: 999` exceeding `ValidationLimits.MAX_ITEM_QUANTITY = 100`, (b) `country: 'United States'` bypassing the Canada-only buyer check (checklist item #7), (c) `quantity: -1` (negative quantity).
FIX: Add three tests, each with `expect(error.code).toBe('invalid-argument')`.

**[MEDIUM] shipping-calculation_spec.ts:Ontario tax range**
PROBLEM: Tax range `10%–16%` is too loose — Ontario HST is exactly 13%. A bug applying BC's 12% (GST+PST) or PE's 15% (HST) would pass the assertion. The test masks province-selection bugs.
FIX: `expect(order.taxAmountCents).toBeCloseTo(taxableBase * 0.13, -1)` — allow ±1 cent rounding but pin to the correct rate.

**[MEDIUM] shipping-calculation_spec.ts (missing tests)**
PROBLEM: No test for (a) Quebec (QST+GST = 14.975%), (b) Alberta (GST only = 5%), (c) free shipping threshold — orders above `BusinessRules.FREE_SHIPPING_THRESHOLD_CENTS` ($75) should have `shippingCostCents = 0` for standard delivery. Three core business rules are fully uncovered.
FIX: Add one test per province scenario and one for the free shipping threshold: `expect(order.shippingCostCents).toBe(0)` for a $100 order.

**[MEDIUM] payment-edge-cases_spec.ts:3DS iframe**
PROBLEM: `threeDSFrame.locator(...).click()` is wrapped in `try { ... } catch { }` with silent swallowing — if the 3DS challenge appeared but the click failed, the test continues without completing authentication. The frame selector `iframe[name*="stripe-challenge"]` may also not match Stripe's actual iframe name, meaning 3DS is never completed in any environment.
FIX: Log the catch: `} catch (e) { console.warn('3DS frame not found or click failed:', e); }`. Add a separate test that explicitly asserts 3DS challenge appearance: `await expect(threeDSFrame.locator('#test-source-authorize-3ds')).toBeVisible({ timeout: 15_000 })`.

---

**[LOW] stripe-payment_spec.ts (missing test)**
PROBLEM: No test for `source_transaction` correctness (checklist item #4) — after payment, the payout transfer's `source_transaction` must be a `ch_xxx` charge ID, not the `pi_xxx` PaymentIntent ID. This is never verified.
FIX: After order reaches `'confirmed'` status, read the `payouts` collection for the order and assert `payout.stripeTransferId` starts with `'tr_'` and is non-null. The actual `source_transaction` check requires Stripe API access — add a test that retrieves the transfer from Stripe and asserts `transfer.source_transaction.startsWith('ch_')`.

**[LOW] stripe-payment_spec.ts (missing test)**
PROBLEM: No test verifying `platformFeeRatio` is stored on the order document at checkout time (required to fix the [CRITICAL] fee rate bug). If the field is absent, `_execute_seller_payouts` silently falls back to the global config.
FIX: In `'Order document has correct structure'`, add `expect(order.platformFeeRatio).toBe(0.025)`.

**[LOW] buyer-flow_spec.ts:scroll**
PROBLEM: `page.mouse.wheel(0, 220)` uses a fixed 220px scroll — product card height varies by screen size and Flutter rendering. On a 1080p screen this may scroll less than one card; on a mobile viewport it may overshoot. Tests scroll up to 6 times with no guarantee of finding cards.
FIX: `await page.evaluate(() => window.scrollBy(0, window.innerHeight * 0.8))` per iteration, or use `await page.locator('[aria-label^="product-card-"]').first().waitFor({ timeout: 10_000 })` before attempting the click.

**[LOW] checkout-validation_spec.ts:beforeAll product reuse**
PROBLEM: `productId` is set once in `beforeAll` and reused across 8 tests. If the product's stock is exhausted mid-suite (e.g., a test accidentally completes payment), subsequent tests get stock-exhaustion errors instead of their intended validation errors, causing confusing failures.
FIX: Use `getTestProduct` per test or ensure `callExpectError` never creates a paid order. Alternatively mock the product with `stockQuantity: 1000` via `writeDoc` in `beforeAll`.

**[LOW] payment-edge-cases_spec.ts:email per test**
PROBLEM: Each edge-case test fills a unique email (`test-decline-${Date.now()}@origna-test.ca`) to Stripe's email field — but the checkout session was created with the buyer's real email attached to the Stripe customer. Stripe's hosted page may ignore the email input for returning customers, meaning the `email.fill()` call is silently a no-op and the test is not actually testing the email-as-new-customer path.
FIX: Remove the email-fill step from edge case tests since the session already has an associated Stripe customer; or explicitly test guest checkout with a session created without a `customer` ID.

**[BONUS] All specs**
PROBLEM: No test covers the cart-cleared-after-order-creation invariant (checklist item #10) — after a successful payment, `users/{userId}/cart` should be empty. A bug that preserves cart items after checkout would go undetected.
FIX: After `waitForOrderStatus(orderId, ['confirmed'])`, read `users/{buyerId}/cart` and `expect(cartItems.length).toBe(0)`.

**[BONUS] All specs**
PROBLEM: No test for the `expiresAt` field being present on the order document (7-day authorization window, checklist item #5). Per the audit, this field is set even in auto-capture mode (dead code finding), but its value should still be within 7 days of `createdAt`.
FIX: In `'Order document has correct structure'`: `const delta = order.expiresAt._seconds - order.createdAt._seconds; expect(delta).toBeLessThanOrEqual(7 * 86400);`

**[BONUS] shipping-calculation_spec.ts:Multiple quantity test**
PROBLEM: Two separate `callOk('create_checkout_session', ...)` calls are made to compare qty=1 vs qty=2. Any price change, rate-limit, or cold-start latency between the two calls can produce a non-2× ratio, making the test flaky.
FIX: Compute the expected subtotal mathematically from the known product price (`10.00`): `expect(order1.subtotalCents).toBe(1000); expect(order2.subtotalCents).toBe(2000)` — no cross-order ratio needed.

**[BONUS] All specs**
PROBLEM: No test for the `currency` field at the Stripe API level — all tests verify `order.currency === 'cad'` in Firestore, but never assert the Stripe PaymentIntent was created in CAD. A bug that creates the intent in USD would not be caught by these tests.
FIX: Retrieve the Stripe PaymentIntent via the Stripe test API using `order.stripePaymentIntentId` and assert `pi.currency === 'cad'`.

**[BONUS] checkout-validation_spec.ts**
PROBLEM: No rate-limiting test despite the comment `// Needs extra time for rate limit retries`. `BusinessRules.CHECKOUT_RATE_LIMIT = 5` per minute — this should be enforced. The test file promises coverage it does not deliver.
FIX: Add a test that fires 6 rapid `create_checkout_session` calls in succession and asserts the 6th returns `'resource-exhausted'` or `'too-many-requests'`.


================================================================================
  OrignaGTA — Admin Panel Security Audit
  Enhanced Findings & Multi-Approach Remediation Guide
  Version: 2.0 (Research-Augmented)   |   Classification: CONFIDENTIAL
================================================================================

Scope:
  admin.py · admin_repository.dart · admin_orders_tab.dart
  admin_reviews_tab.dart · admin_providers.dart · firestore.rules

Sources cross-referenced:
  Stripe Connect Docs · Firebase/Firestore Official Docs · Firebase GitHub Issues
  Stack Overflow · DEV Community · Medium engineering blogs

┌──────────────────────────┬───────┐
│ Severity                 │ Count │
├──────────────────────────┼───────┤
│ CRITICAL                 │   4   │
│ HIGH                     │   7   │
│ MEDIUM                   │   3   │
│ BONUS / ADVISORY         │   7   │
│ TOTAL                    │  21   │
└──────────────────────────┴───────┘

Critical findings must be resolved before the next production deployment.
High findings should be resolved in the current sprint.
Medium findings should be addressed within 1–2 sprints.


================================================================================
  CRITICAL FINDINGS
================================================================================

--------------------------------------------------------------------------------
[C-1]  Seller Suspension Uses Deprecated IS_ACTIVE Field
Severity : CRITICAL
File     : admin.py · suspend_seller() ~line 200
--------------------------------------------------------------------------------

ROOT CAUSE
  suspend_seller() queries products with IS_ACTIVE == True and sets IS_ACTIVE = False.
  The schema has fully migrated to lifecycleStatus — products on the new system are never
  deactivated when their seller is suspended. Suspended sellers' products remain live,
  searchable, and purchasable.

PRIMARY FIX
  Replace the IS_ACTIVE query/update with lifecycleStatus:

    .where(Fields.LIFECYCLE_STATUS, "in",
           [ProductLifecycleStatusValues.ACTIVE, ProductLifecycleStatusValues.APPROVED])
    batch.update(ref, {
        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED,
        Fields.SUSPENDED_AT: server_ts()
    })

  After the batch commit, immediately invalidate Algolia:

    algolia_index.partial_update_objects([
        {"objectID": pid, "lifecycleStatus": "paused"} for pid in product_ids
    ])

  Add a compensating Cloud Task or Pub/Sub message to reconcile products updated
  after the batch window closes.

ALTERNATIVE APPROACHES

  ALT A — Firestore onWrite trigger (event-driven):
    Deploy a Firestore trigger on users/{uid} that fires whenever suspendedAt is set.
    The trigger fans out the product status update independently, decoupling it from the
    HTTPS callable. This prevents timeouts on accounts with large catalogues.

  ALT B — Collection-group query with cursor-based batching:
    Query collectionGroup("products") where sellerId == target AND lifecycleStatus in
    [active, approved]. Use a cursor-based batch loop for accounts exceeding Firestore's
    500-write-per-batch limit. Safer at scale than a single large batch.

  ALT C — Soft-lock via Firestore Security Rules (defence in depth):
    Add a rule that blocks reads on products where lifecycleStatus == "paused" OR
    sellerId is in a suspendedSellers denormalized set document. Not a replacement for
    the data fix, but a safety net that prevents accidental reads.


--------------------------------------------------------------------------------
[C-2]  Admin Refund Does Not Reverse Seller Stripe Transfers
Severity : CRITICAL
File     : admin.py · admin_refund_order() ~line 790
--------------------------------------------------------------------------------

ROOT CAUSE
  stripe.Refund.create() is called to refund the customer, but
  stripe.Transfer.create_reversal() is never called on the corresponding seller
  transfers. As confirmed by the Stripe Connect documentation, refunding a charge has
  NO impact on any associated transfers — it is the platform's explicit responsibility
  to reconcile this. The platform absorbs 100% of the refund cost while sellers retain
  their payouts.

PRIMARY FIX
  For separate charges and transfers (most likely marketplace setup):

    refund = stripe.Refund.create(
        payment_intent=order_data[Fields.PAYMENT_INTENT_ID],
        idempotency_key=f"admin_refund_{order_id}"
    )
    for payout in order_data.get(Fields.SELLER_PAYOUTS, []):
        transfer_id = payout.get(Fields.STRIPE_TRANSFER_ID)
        if not transfer_id:
            continue
        try:
            stripe.Transfer.create_reversal(
                transfer_id,
                amount=payout.get(Fields.PAYOUT_AMOUNT),  # supports partial reversal
                idempotency_key=f"reversal_{order_id}_{payout[Fields.SELLER_ID]}"
            )
        except stripe.error.InvalidRequestError as e:
            # Connected account may have insufficient balance
            get_db().collection(Collections.ALERTS).add({
                Fields.TYPE: "reversal_failed",
                Fields.TRANSFER_ID: transfer_id,
                Fields.ORDER_ID: order_id,
                Fields.ERROR: str(e),
                Fields.TIMESTAMP: server_ts()
            })

  For destination charges: pass reverse_transfer=True directly on stripe.Refund.create().
  Stripe will atomically pull funds back from the connected account. This is the simpler
  path and requires no separate Transfer.create_reversal() call.

  IMPORTANT: A transfer reversal only succeeds if the connected account has sufficient
  available balance. Always catch stripe.error.InvalidRequestError and record a
  REVERSAL_FAILED alert if the reversal cannot be processed immediately.

ALTERNATIVE APPROACHES

  ALT A — Webhook-driven reconciliation:
    Listen to the charge.refunded Stripe webhook event. On receipt, look up the associated
    order, compute the pro-rata reversal amount per seller, and enqueue reversals via a
    Cloud Task with exponential back-off. Decouples the reversal from the synchronous admin
    action and handles retries automatically. Best for high-volume platforms.

  ALT B — Stripe Balance Reserves:
    For high-volume platforms, enable connected_reserves on connected accounts. Stripe can
    automatically debit a negative balance from the seller's future payouts when an immediate
    reversal fails due to insufficient account balance. Requires Stripe account manager
    enablement.

  ALT C — Stripe Funds Segregation (private preview):
    Allocates funds at transfer time, allowing clean accounting separation and automatic
    debit from allocated funds on refund. Contact your Stripe account manager to request
    access.


--------------------------------------------------------------------------------
[C-3]  Refund Transitions Order to CANCELLED (Invalid State)
Severity : CRITICAL
File     : admin.py · admin_refund_order() ~line 815
--------------------------------------------------------------------------------

ROOT CAUSE
  The refund handler sets orderStatus = CANCELLED when processing a delivered-order refund.
  The state machine only permits delivered → [disputed]. CANCELLED is not a valid successor
  of delivered. This violates both OrderStatusValues.validTransitions and the Firestore
  security rule that validates state transitions. The Firestore write will be rejected in
  production.

PRIMARY FIX
  Change the target status to the purpose-built REFUNDED terminal state:

    Fields.ORDER_STATUS:   OrderStatusValues.REFUNDED,
    Fields.PAYMENT_STATUS: PaymentStatusValues.REFUNDED,
    Fields.REFUNDED_AT:    get_server_timestamp(),
    Fields.REFUNDED_BY:    admin_id,
    Fields.REFUND_REASON:  reason,

  Update the validTransitions map to explicitly allow:
    delivered  → refunded
    disputed   → refunded

  Add a Firestore security rule assertion so the new status must appear in the allowed
  successors list of the current status, evaluated server-side.

ALTERNATIVE APPROACHES

  ALT A — State machine library:
    Replace the hand-rolled validTransitions dict with python-statemachine or transitions.
    Illegal transitions raise exceptions rather than silently succeeding. Decorators/guards
    make the allowed paths self-documenting and testable.

  ALT B — Firestore rule enforcement (second layer):
    Encode the entire state graph directly in firestore.rules:

      function isValidTransition(from, to) {
        return (from == "delivered" && to in ["disputed", "refunded"])
            || (from == "disputed" && to in ["refunded"])
            || ...
      }

  ALT C — Event sourcing:
    Model order lifecycle as an append-only events sub-collection rather than a mutable
    status field. Current status is derived by folding the event log. Illegal transitions
    become structurally impossible because you never overwrite state.


--------------------------------------------------------------------------------
[C-4]  Missing easy_localization Import — Compile Failure
Severity : CRITICAL
File     : admin_orders_tab.dart · entire file
--------------------------------------------------------------------------------

ROOT CAUSE
  All tr() extension calls (.tr(), .tr(args: [...])) depend on the easy_localization
  package. The import is absent, causing every localised string in the file to fail with
  "The method 'tr' isn't defined". The file will not compile.

PRIMARY FIX
  Add the missing import at the top of the file:

    import 'package:easy_localization/easy_localization.dart';

  Enable the avoid_relative_lib_imports lint rule in analysis_options.yaml.
  Enable unused_import and sort_directives lints to keep the import block clean.

ALTERNATIVE APPROACHES

  ALT A — Barrel file:
    Create a shared admin_imports.dart that re-exports easy_localization, common widgets,
    and schema constants. Every admin tab file has a single import of this barrel, making
    the omission structurally impossible.

  ALT B — CI guard:
    Add dart analyze --fatal-infos as a required CI step before any build. The missing
    import fails CI before it reaches a device.

  ALT C — IDE file templates:
    Configure VS Code / IntelliJ file templates for new admin tabs to auto-include the
    standard import block, preventing recurrence for all future files.


================================================================================
  HIGH FINDINGS
================================================================================

--------------------------------------------------------------------------------
[H-1]  Admin Can Suspend Another Admin Account
Severity : HIGH
File     : admin.py · suspend_seller() ~line 155
--------------------------------------------------------------------------------

ROOT CAUSE
  The function guards against self-suspension (admin_id == seller_id) but does not prevent
  one admin from suspending another. A compromised or rogue admin session can lock out
  other administrators — a privilege escalation and operational sabotage vector.

PRIMARY FIX
  After fetching seller_data, add a role check before any suspension logic:

    if UserRoleValues.ADMIN in seller_data.get(Fields.ROLES, []):
        raise https_fn.HttpsError(
            "permission-denied",
            "Cannot suspend an admin account via this endpoint."
        )

  Emit an admin_log entry for the attempt regardless of outcome — failed suspension
  attempts against admin accounts are a meaningful security signal worth alerting on.

ALTERNATIVE APPROACHES

  ALT A — Hierarchical role model:
    Replace the flat [admin, seller, buyer] model with a RBAC hierarchy:
    super_admin > admin > seller > buyer. A caller may only act on roles strictly below
    their own level. Enforced by a single rank-comparison function rather than scattered
    explicit checks throughout the codebase.

  ALT B — Firestore rule guard:
    Add a Firestore rule on admin_actions that prevents recording a suspension against
    a user whose roles array contains "admin":
      allow write: if !("admin" in get(targetUserRef).data.roles);

  ALT C — Two-admin approval:
    For destructive admin actions (suspending a high-privilege account), require a second
    admin to confirm within a TTL window. Store a pending_action document; the second
    admin's confirmation triggers the actual execution. Prevents single-admin abuse.


--------------------------------------------------------------------------------
[H-2]  Unsuspend Also Uses Deprecated IS_ACTIVE Field
Severity : HIGH
File     : admin.py · unsuspend_seller() ~line 290
--------------------------------------------------------------------------------

ROOT CAUSE
  Mirror image of C-1: unsuspend_seller() queries products where IS_ACTIVE == False AND
  suspendedAt != null, then sets IS_ACTIVE = True. Products managed under lifecycleStatus
  remain paused indefinitely after unsuspension — sellers come back but their inventory
  is still hidden from buyers.

PRIMARY FIX
  Mirror the C-1 fix symmetrically:

    .where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.PAUSED)
    .where(Fields.SUSPENDED_AT, "!=", None)
    batch.update(ref, {
        Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ACTIVE,
        Fields.SUSPENDED_AT:     DELETE_SENTINEL,
        Fields.RESTORED_AT:      server_ts()
    })

  Sync restored products back to Algolia immediately after the batch commit.

ALTERNATIVE APPROACHES

  ALT A — Atomic suspension token:
    Store a suspension_token on each product at suspend time. On unsuspend, query products
    WHERE suspension_token == expected_token and clear it. Idempotent and immune to
    dual-field sync drift.

  ALT B — Event-driven via Firestore trigger:
    A Firestore onWrite trigger on users/{uid} that reacts to suspendedAt being deleted
    (FieldValue.delete()) fans out the product restoration, making the lifecycle transition
    reliable at scale without relying on the callable's execution window.


--------------------------------------------------------------------------------
[H-3]  MFA Enrollment Race Condition (TOCTOU)
Severity : HIGH
File     : admin.py · admin_mfa_enroll() ~line 430
--------------------------------------------------------------------------------

ROOT CAUSE
  Classic time-of-check-to-time-of-use: reads mfa_enabled, branches if false, then writes
  mfa_secret_temp. Two concurrent calls both read mfa_enabled = False before either writes.
  Both generate distinct TOTP secrets. The second write silently overwrites the first,
  orphaning the QR code shown in tab 1. Documented as a standard Firestore race condition
  requiring a transaction to resolve.
  Note: Firestore's Python server SDK uses pessimistic concurrency — transactions acquire
  read locks, blocking concurrent writes until the transaction releases.

PRIMARY FIX
  Wrap the read-check-write inside a Firestore transaction:

    @firestore.transactional
    def _enroll_mfa_txn(txn, security_ref):
        doc  = security_ref.get(transaction=txn)
        data = doc.to_dict() or {}
        if data.get(Fields.MFA_ENABLED) or data.get(Fields.MFA_SECRET_TEMP):
            raise https_fn.HttpsError(
                "failed-precondition",
                "MFA already enabled or enrollment already in progress."
            )
        new_secret = pyotp.random_base32()
        txn.update(security_ref, {
            Fields.MFA_SECRET_TEMP:       new_secret,
            Fields.MFA_ENROLL_STARTED_AT: server_ts()
        })
        return new_secret

    secret = _enroll_mfa_txn(db.transaction(), security_ref)

  Add a TTL-based expiry: if mfa_enroll_started_at is older than 15 minutes and
  mfa_enabled is still False, treat the enrollment as abandoned and allow a new one.

ALTERNATIVE APPROACHES

  ALT A — Firestore document lock pattern (from QuintoAndar engineering blog):
    Create a separate mfa_locks/{uid} document as a semaphore. The transaction tries to
    set locked: true with a TTL; if it already exists and is non-expired, raise. Separates
    the lock from the data document and makes lock expiry easier to reason about.

  ALT B — Cloud Tasks idempotency (named tasks):
    Issue a deduplicated Cloud Task with ID "mfa_enroll_{uid}" for the enrollment.
    Cloud Tasks guarantees at-most-once delivery for named tasks, inherently solving the
    race without application-level locking. Requires migrating to an async enrollment flow.

  ALT C — Client nonce + create() optimistic concurrency:
    Generate a client nonce before calling the function. The function uses create() (not
    set/update) on a document keyed by the nonce. Firestore rejects duplicate document
    creation, providing optimistic concurrency without a full transaction.


--------------------------------------------------------------------------------
[H-4]  Account Deletion Leaves Products Live via lifecycleStatus
Severity : HIGH
File     : admin.py · delete_account() ~line 660
--------------------------------------------------------------------------------

ROOT CAUSE
  delete_account() anonymises products by setting IS_ACTIVE = False but does not update
  lifecycleStatus. Products remain in Algolia and are visible/purchasable via
  lifecycleStatus = active. GDPR-motivated deletions and abuse-driven account removals
  both leave live inventory from deleted accounts.

PRIMARY FIX
  In the product-anonymisation batch, add:

    Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.ARCHIVED,
    Fields.ARCHIVED_REASON:  "account_deleted",
    Fields.ARCHIVED_AT:      server_ts()

  After the batch commit, call algolia_index.delete_objects(product_ids) to remove
  records from search. For GDPR compliance, also delete or anonymise user-generated
  content (reviews, messages) per your data retention policy. Log the deletion event to
  a GDPR_AUDIT_LOG collection with a hash of the original uid for compliance traceability.

ALTERNATIVE APPROACHES

  ALT A — Soft-delete with retention window:
    Set lifecycleStatus = pending_deletion with a deletion_scheduled_at timestamp 30 days
    out. A scheduled Cloud Function sweeps and permanently removes/anonymises after the
    window. Allows recovery from accidental deletions.

  ALT B — Pub/Sub fan-out:
    Publish an account.deleted event to a Pub/Sub topic. Separate subscribers handle
    product archival, Algolia cleanup, review anonymisation, and GDPR audit logging
    independently. Keeps delete_account() thin; each concern is independently testable.

  ALT C — Firestore rule guard (defence in depth):
    Add a rule that blocks all reads on products where lifecycleStatus == "pending_deletion"
    OR sellerId is in a deletedUsers denormalized set, as a safety net.


--------------------------------------------------------------------------------
[H-5]  hasPhotosOnly Filter Applied Client-Side (Wasteful Reads)
Severity : HIGH
File     : admin_repository.dart · watchReviews() ~line 160
--------------------------------------------------------------------------------

ROOT CAUSE
  When hasPhotosOnly is true, all 100 reviews are fetched from Firestore and the filter
  is applied in Dart. At scale this wastes 100 reads to surface a handful of results.
  Additionally, the field name 'isFlagged' is used as a magic string (also see M-2).
  Note: As confirmed by multiple Firebase GitHub issues and Stack Overflow answers,
  Firestore cannot natively filter "array is not empty" — a denormalized boolean field
  is the canonical solution.

PRIMARY FIX
  1. Add a denormalized boolean field to each review document at write time:
       Fields.HAS_PHOTOS: reviewImageUrls.isNotEmpty

  2. Query server-side when the filter is active:
       if (filters.hasPhotosOnly)
           query = query.where(Fields.HAS_PHOTOS, isEqualTo: true);

  3. Create a composite Firestore index on (isFlagged, hasPhotos, createdAt).

  4. Replace the magic string 'isFlagged' with Fields.isFlagged.

ALTERNATIVE APPROACHES

  ALT A — Algolia facets:
    If reviews are already indexed in Algolia, add hasPhotos as a facet attribute and
    route the hasPhotosOnly query through Algolia rather than Firestore. Facet filtering
    is O(1) and carries no per-document read cost.

  ALT B — Cursor-based early-exit pagination:
    Replace the limit(100) query with a cursor-based paginator that stops once enough
    photo-having results are found. Reduces reads in the common case without schema changes.
    Best as a short-term fix before the denormalized field is deployed.


--------------------------------------------------------------------------------
[H-6]  Magic Strings in Callable Payloads
Severity : HIGH
File     : admin_repository.dart · deleteReview / flagReview / refundOrder ~lines 195-215
--------------------------------------------------------------------------------

ROOT CAUSE
  Multiple callable payloads use raw string literals: 'reviewId', 'flagged', 'orderId',
  'reason'. These bypass compile-time safety, won't be caught by IDE refactoring, and
  can silently drift from the Python backend's field names.

PRIMARY FIX
  Dart — add to schema_constants.dart:
    static const reviewId = 'reviewId';
    static const flagged  = 'flagged';
    static const orderId  = 'orderId';
    static const reason   = 'reason';

  Python — mirror in schema_constants.py:
    REVIEW_ID = "reviewId"
    FLAGGED   = "flagged"
    ORDER_ID  = "orderId"   # verify against H-7 casing decision
    REASON    = "reason"

  Update all call sites. Any future rename triggers a compile error in Dart and a
  grep-findable diff in Python.

ALTERNATIVE APPROACHES

  ALT A — Protobuf / code generation:
    Define callable request/response schemas as .proto files. Generate Python + Dart code
    from them. Field names are guaranteed in sync — single source of truth.

  ALT B — JSON Schema validation middleware:
    Define a JSON Schema for each callable payload. Validate incoming data in Python against
    the schema at the top of each handler. Validation errors return a structured 400 with
    the offending field name, making mismatches immediately obvious.

  ALT C — Integration test suite:
    Add a Dart integration test that calls each Cloud Function with the current constants
    and asserts a non-error response. Any constant drift breaks the test before production.


--------------------------------------------------------------------------------
[H-7]  Cross-Stack Field Name Mismatch: sellerId vs seller_id
Severity : HIGH
File     : admin_repository.dart · setUserSuspended() ~line 75
           admin.py · suspend_seller()
--------------------------------------------------------------------------------

ROOT CAUSE
  Dart sends payload key Fields.sellerId = 'sellerId' (camelCase). Python reads
  data.get(Fields.SELLER_ID) where SELLER_ID = 'seller_id' (snake_case). The keys don't
  match; Python receives seller_id = None and raises 400 invalid-argument.
  This is a live breakage — suspend_seller is non-functional as shipped.

PRIMARY FIX
  Option 1: Align the Python constant to match Dart (least churn):
    # schema_constants.py
    SELLER_ID = "sellerId"   # was "seller_id"

  Option 2: Align Dart to Python's snake_case:
    // schema_constants.dart
    static const sellerId = 'seller_id';   // was 'sellerId'

  After choosing, audit ALL callable payloads for the same camelCase/snake_case split.
  Add a CI step: dart run bin/validate_constants.dart that parses both constant files
  and asserts every key maps to the same string value.

ALTERNATIVE APPROACHES

  ALT A — humps middleware (most pragmatic, zero constant churn):
    Add a Python decorator on every callable that normalises incoming payload keys from
    camelCase to snake_case automatically. Common pattern in Firebase + Flutter stacks:

      from humps import decamelize
      data = decamelize(data)  # sellerId → seller_id, orderId → order_id ...

  ALT B — Shared JSON constant file (single source of truth):
    Maintain a callable_fields.json that lists every field name exactly once. A pre-commit
    hook generates both schema_constants.dart and schema_constants.py from this file.
    Divergence becomes structurally impossible.

  ALT C — Typed callable SDK:
    Use the Firebase Extensions typed callable pattern where both sides agree on a JSON
    Schema with built-in camelCase ↔ snake_case translation in the generated adapter.


================================================================================
  MEDIUM FINDINGS
================================================================================

--------------------------------------------------------------------------------
[M-1]  Shipped Orders Cannot Be Refunded
Severity : MEDIUM
File     : admin.py · admin_refund_order() · _REFUNDABLE_STATUSES
--------------------------------------------------------------------------------

ROOT CAUSE
  _REFUNDABLE_STATUSES excludes OrderStatusValues.SHIPPED. Admins cannot issue a refund
  for an order in transit — even if payment was captured and seller transfers have occurred.
  Creates a real operational gap for disputed shipped-but-unreceived orders.

PRIMARY FIX
  Add SHIPPED to the refundable set:

    _REFUNDABLE_STATUSES = frozenset({
        OrderStatusValues.PAID,
        OrderStatusValues.PROCESSING,
        OrderStatusValues.SHIPPED,   # ← add
        OrderStatusValues.DELIVERED,
    })

  For SHIPPED refunds, ensure the transfer reversal logic (C-2 fix) runs — the seller
  has likely already been paid out. Log a SHIPPED_REFUND_MANUAL_REVIEW alert so operations
  can attempt carrier package recall.

ALTERNATIVE APPROACHES

  ALT A — Partial refund for shipped orders:
    Expose a partial_refund amount field with a maximum of the order subtotal. Gives admins
    flexibility while protecting against over-refunding unrecoverable shipping costs.

  ALT B — Route through dispute flow:
    Route shipped refund requests through delivered → disputed → refunded. Leverages an
    existing state path and ensures the dispute is logged for seller accountability tracking.

  ALT C — Seller consent flag:
    For high-value shipped orders, require seller confirmation before issuing a refund.
    Store a pending_seller_consent flag, send a push notification, and auto-approve after
    a 48-hour TTL if no response.


--------------------------------------------------------------------------------
[M-2]  isFlagged Field Missing from Schema Constants
Severity : MEDIUM
File     : admin_reviews_tab.dart · _ReviewCard ~line 65   |   database_schema.json
--------------------------------------------------------------------------------

ROOT CAUSE
  review['isFlagged'] is a magic string not present in Fields constants or
  database_schema.json. If renamed or mistyped, the UI silently treats all reviews as
  unflagged. No compile-time or schema-validation protection exists.

PRIMARY FIX
  schema_constants.dart:
    static const isFlagged = 'isFlagged';
    static const hasPhotos  = 'hasPhotos';   // also needed for H-5

  schema_constants.py:
    IS_FLAGGED = "isFlagged"
    HAS_PHOTOS = "hasPhotos"

  database_schema.json (under product_ratings):
    "isFlagged": { "type": "boolean", "default": false, "indexed": true },
    "hasPhotos":  { "type": "boolean", "default": false, "indexed": true }

  _ReviewCard widget:
    review[Fields.isFlagged] ?? false

ALTERNATIVE APPROACH
  Generate a Freezed ReviewModel using json_serializable. isFlagged becomes a typed
  property with a default value. The JSON key is declared once in
  @JsonKey(name: 'isFlagged'), making magic string access impossible at compile time.


--------------------------------------------------------------------------------
[M-3]  Role Sync Failure Creates Silent Permanent Desync
Severity : MEDIUM
File     : admin.py · update_user_roles() ~line 130
--------------------------------------------------------------------------------

ROOT CAUSE
  The function updates Firestore roles before syncing Firebase Auth custom claims. If
  set_custom_user_claims() fails and the subsequent Firestore revert also fails, the system
  reaches an unrecoverable split-brain: Firestore says role X, Auth token still says old
  role Y. The mismatch is logged CRITICAL but no alert is created and no on-call page fires.
  Per Firebase documentation, Auth custom claims are the source of truth for security rules
  — a desync means Firestore rules enforcement is wrong until a manual fix.

PRIMARY FIX
  In the revert failure catch block, write a SECURITY_ALERTS document and trigger an alert:

    get_db().collection(Collections.SECURITY_ALERTS).add({
        Fields.TYPE:             "role_sync_failure",
        Fields.SEVERITY:         SeverityLevels.CRITICAL,
        Fields.USER_ID:          target_user_id,
        Fields.TIMESTAMP:        get_server_timestamp(),
        Fields.RESOLVED:         False,
        Fields.FIRESTORE_ROLES:  new_roles,
        Fields.AUTH_CLAIMS:      old_claims_roles,
    })

  Set up a Firestore onWrite trigger on SECURITY_ALERTS to push a PagerDuty/Slack webhook.
  Consider inverting the write order: update Auth claims first, only update Firestore if
  Auth succeeds. Auth is the authoritative source; Firestore is a cache.

ALTERNATIVE APPROACHES

  ALT A — FirebaseExtended/firestore-auth-claims extension:
    This Firebase experimental extension auto-syncs a Firestore collection to Auth custom
    claims via a Cloud Function trigger. Replacing the manual dual-write with this extension
    eliminates the sync gap entirely — Firestore is the single source of truth.
    https://github.com/FirebaseExtended/experimental-extensions

  ALT B — Auth-first write order (recommended by Firebase docs):
    Write custom claims to Auth SDK first; then write roles to Firestore. If the Firestore
    write fails, Auth is already correct (it's the enforcement source); Firestore is just a
    cache that can be reconciled by a nightly consistency-check job. This is the pattern
    recommended in firebase.google.com/docs/auth/admin/custom-claims.

  ALT C — Idempotent reconciliation job:
    Deploy a Cloud Scheduler job (every 5 minutes) that queries users where
    firestore_roles != auth_roles and re-applies the correct claims. Defence-in-depth
    measure that self-heals any desync regardless of root cause.


================================================================================
  BONUS / ADVISORY FINDINGS
================================================================================

--------------------------------------------------------------------------------
[B-1]  Model Import Mismatch — admin_providers.dart
--------------------------------------------------------------------------------

  Providers import OrderModel, ProductModel, UserModel from utils/utils.dart rather than
  from the generated Freezed model files. This can cause type mismatches at runtime when
  models evolve independently.

  Primary fix: Import from:
    'models/generated/order_models.dart'
    'models/generated/product_models.dart'
    'models/generated/user_models.dart'

  Alternative: Create a models.dart barrel file that re-exports all generated models.
  Providers import from 'models.dart' only. Future model moves require a single-file change.


--------------------------------------------------------------------------------
[B-2]  BuildContext Captured Across Async Gap — admin_orders_tab.dart
--------------------------------------------------------------------------------

  The _showRefundDialog method captures BuildContext before an await. While a mounted
  check exists, the Dart lint rule use_build_context_synchronously enforces this at
  analysis time rather than relying on manual discipline. Flutter 3.7+ exposes
  context.mounted natively.

  Primary fix:
    Enable use_build_context_synchronously in analysis_options.yaml.
    After every await, guard with:
      if (!context.mounted) return;

  Alternative (from flutter/flutter GitHub issue #110694):
    Extract the async logic into a callback passed to the dialog. The callback is invoked
    synchronously from within the dialog (which is mounted), eliminating the async gap
    entirely. This is the cleaner architectural approach for stateless widgets.

    // Pattern:
    showDialog(builder: (ctx) => RefundDialog(
      onConfirm: () async {
        await refundOrder(...);
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(...);
      }
    ));


--------------------------------------------------------------------------------
[B-3]  Multi-Seller Order Cancellation Cancels All Sellers
--------------------------------------------------------------------------------
  File: admin.py · suspend_seller() ~line 270

  When suspending a seller, the order-cancellation loop calls cancel_order() on every
  order containing that seller's items — including multi-seller orders. This cancels items
  belonging to non-suspended sellers and may trigger unwarranted refunds.

  Primary fix: Check if an order has multiple sellers. For multi-seller orders, call
  cancel_seller_items(order_id, seller_id) to cancel only the suspended seller's line
  items and issue a partial refund.

  Alternative: Model each seller's items within an order as a sub-order (sub-collection).
  Cancellation targets a sub-order, not the root order document. Makes partial fulfilment
  and partial cancellation structurally clean — a more fundamental but correct data model.


--------------------------------------------------------------------------------
[B-4]  MFA Disable Lacks Audit Log & Email Alert
--------------------------------------------------------------------------------
  File: admin.py · admin_mfa_disable() ~line 530

  admin_mfa_disable() does not write an audit log entry or send a notification to the
  affected user. Disabling MFA is a high-value action — silent disables are a red flag
  in any security audit.

  Primary fix: Write an admin_log entry with:
    action: "mfa_disabled", actor: admin_id, target: user_id, timestamp
  Send a transactional email to the user's registered address notifying them of the change.

  Alternative (per NIST 800-63B guidance): Require a fresh TOTP code specifically for
  the MFA disable action (call _require_recent_admin_mfa with a short window, e.g. 60 sec).
  Proves active possession of the authenticator at the moment of disable — the gold
  standard for MFA self-service flows.


--------------------------------------------------------------------------------
[B-5]  Deprecated deliveryStatus Allowed in Firestore Rules
--------------------------------------------------------------------------------
  File: firestore.rules · orders ~line 305

  The admin update rule whitelists 'deliveryStatus' in affectedKeys. The schema marks
  deliveryStatus as DEPRECATED (use status on items). Allows admin client writes to a
  deprecated field, creating a maintenance trap and potential for stale data persistence.

  Fix: Remove 'deliveryStatus' from the admin update rule's allowed keys.
  Run a one-time migration script to delete or rename any existing deliveryStatus fields
  in the orders collection before removing the rule allowance.


--------------------------------------------------------------------------------
[B-6]  Unused _buildDetailRow — FALSE ALARM
--------------------------------------------------------------------------------
  File: admin_orders_tab.dart · _AdminOrderCard ~line 155

  Initial analysis flagged _buildDetailRow as unused. After reviewing the full widget,
  it IS called within _viewOrderDetails. No action required.


--------------------------------------------------------------------------------
[B-7]  Riverpod Family with Dart Record Keys — NO ACTION REQUIRED
--------------------------------------------------------------------------------
  File: admin_reviews_tab.dart · _AdminReviewsTabState ~line 18

  ref.watch(adminReviewsProvider(({flaggedOnly: bool, hasPhotosOnly: bool}))) uses a Dart
  record as the family key. This is correct and safe. Per dart.dev/language/records:
  "Two records are equal if they have the same shape and all corresponding fields are equal."
  Dart records have structural (value) equality since Dart 3.0. Riverpod .family uses ==
  for cache keying — the implementation is correct. No fix needed.


================================================================================
  REMEDIATION PRIORITY MATRIX
================================================================================

  ID   | Severity  | Fix Theme                     | Effort | Impact
  -----|-----------|-------------------------------|--------|---------------------
  C-4  | CRITICAL  | Add import (1 line)           | XS     | Compile blocker
  C-3  | CRITICAL  | Fix order state               | XS     | Write rejection
  H-7  | HIGH      | Fix key casing                | XS     | Live breakage
  C-2  | CRITICAL  | Stripe transfer reversal      | S      | Revenue loss
  C-1  | CRITICAL  | lifecycleStatus on suspend    | S      | Suspended seller live
  H-2  | HIGH      | lifecycleStatus on unsuspend  | S      | Inventory hidden
  H-1  | HIGH      | Admin-on-admin guard          | S      | Privilege escalation
  H-3  | HIGH      | Firestore transaction (MFA)   | M      | Race condition
  H-6  | HIGH      | Magic string constants        | M      | Schema drift risk
  M-3  | MEDIUM    | Role sync alert               | S      | Silent desync
  M-2  | MEDIUM    | isFlagged schema constant     | XS     | Silent null
  H-4  | HIGH      | Archive on account delete     | S      | GDPR / ghost listing
  M-1  | MEDIUM    | SHIPPED refund support        | M      | Ops gap
  H-5  | HIGH      | Server-side photo filter      | M      | Cost / perf

  Effort key: XS = <30 min  |  S = 30 min–2 h  |  M = 2–6 h


================================================================================
  KEY REFERENCES & SOURCES CONSULTED
================================================================================

  - Stripe Connect Docs — Handle refunds and disputes
    stripe.com/connect/marketplace/tasks/refunds-disputes

  - Stripe API Reference — Transfer Reversals
    stripe.com/api/transfer_reversals

  - Stripe Docs — Separate charges and transfers:
    "refunding a charge has no impact on associated transfers"
    stripe.com/connect/separate-charges-and-transfers

  - Firebase Firestore — Transactions and batched writes
    firebase.google.com/docs/firestore/manage-data/transactions

  - Firebase Firestore — Transaction data contention (pessimistic vs optimistic)
    firebase.google.com/docs/firestore/transaction-data-contention

  - Medium / QuintoAndar Engineering — Race Conditions in Firestore: How to Solve it?

  - Medium / Cody Zuschlag — Lock down with Cloud Firestore: atomic lock pattern

  - Firebase Auth — Control Access with Custom Claims and Security Rules
    firebase.google.com/docs/auth/admin/custom-claims

  - DEV.to / oddbit — How to Keep Your Custom Claims in Sync with Firestore

  - Firebase Developers / Doug Stevenson — Patterns for security with Firebase:
    supercharged custom claims

  - FirebaseExtended/experimental-extensions — firestore-auth-claims auto-sync
    github.com/FirebaseExtended/experimental-extensions

  - dart.dev — use_build_context_synchronously lint rule documentation

  - flutter/flutter GitHub Issue #110694 — BuildContext across async gaps

  - KindaCode / OnlyFlutter — Solving "Don't use BuildContexts across async gaps" (2024)

  - Firebase Docs — Add TOTP multi-factor authentication
    firebase.google.com/docs/auth/web/totp-mfa

  - NIST SP 800-63B — Digital Identity Guidelines: Authentication & Lifecycle Management

  - Stripe Docs — Revenue Recognition for separate charges and transfers


================================================================================
  END OF REPORT
================================================================================

[CRITICAL] functions/handlers/payment_stripe.py:~1050
PROBLEM: Platform loses money on coupon redemptions — _execute_seller_payouts calculates seller amounts from actual_subtotal_cents (pre-discount) while platform only collected discounted_subtotal_cents, causing the platform to pay out more than it received.
FIX: Apply discount ratio to seller amounts: discount_ratio = discounted_subtotal_cents / actual_subtotal_cents; sellers_total[sid] = round(amt * discount_ratio).
[CRITICAL] functions/handlers/payment_stripe.py:~1050 + ~2850
PROBLEM: _execute_seller_payouts reads PLATFORM_FEE_RATIO global instead of order_data.get('platformFeeRatio'), so any config change between checkout and payout applies the wrong fee rate.
FIX: stored_fee_rate = order_data.get(Fields.PLATFORM_FEE_RATIO, PLATFORM_FEE_RATIO); platform_fee_cents = round(amount_cents * stored_fee_rate).
[CRITICAL] functions/handlers/payment_stripe.py:~3450
PROBLEM: create_account_link reads Stripe account ID from user_data.get(Fields.STRIPE_ACCOUNT_ID) (users doc), but create_connect_account stores it in seller_profiles/{uid} — always returns None, breaking onboarding links.
FIX:
pythonsp_doc = get_db().collection(Collections.SELLER_PROFILES).document(user_id).get()
account_id = (sp_doc.to_dict() or {}).get(Fields.STRIPE_ACCOUNT_ID)
[CRITICAL] functions/handlers/payment_stripe.py:~1800
PROBLEM: process_payment_intent_failed and process_payment_intent_canceled restore STOCK_QUANTITY via Increment() but skip warehouseStock map and inventoryLevels subcollection — causing permanent inventory desync after any payment failure.
FIX: Replace manual Increment() calls with the existing _add_stock_restore_to_batch() helper which handles all three stock fields atomically.

[HIGH] functions/handlers/payment_stripe.py:~450
PROBLEM: Price validation uses abs(db_price - client_price) > 0.01 on floats — floating-point precision errors (e.g., 19.99 stored as 19.989999999) can cause valid prices to fail validation.
FIX:
pythondb_price_cents = round(product_data.get(Fields.PRICE, 0) * 100)
client_price_cents = round(client_price * 100)
if abs(db_price_cents - client_price_cents) > 1:
    raise HttpsError(...)
[HIGH] functions/handlers/payment_stripe.py:~2200
PROBLEM: Dispute reversal calls stripe.Transfer.create_reversal(transfer_id, amount=reversal_amount_cents) without guarding reversal_amount_cents > 0 — zero-amount Stripe API calls return errors and waste quota/budget.
FIX: if reversal_amount_cents <= 0: logger.warning(...); continue.
[HIGH] origna_gta/lib/features/checkout/checkout_provider.dart:~280
PROBLEM: _generateIdempotencyKey uses Random.secure() with manual base64 encoding — on some Flutter Web platforms Random.secure() is not cryptographically random and produces predictable output.
FIX: Use const Uuid().v4() from the uuid package which uses platform-native CSPRNG.
[HIGH] functions/handlers/orders.py:~850
PROBLEM: approve_shipping_cost rejection path calls stripe.Refund.create() without checking if paymentStatus is already refunded or partially_refunded, risking double-refund attempt.
FIX:
pythonif order_data.get(Fields.PAYMENT_STATUS) in (PaymentStatusValues.REFUNDED, PaymentStatusValues.PARTIALLY_REFUNDED):
    raise HttpsError('failed-precondition', 'Order already refunded')

[MEDIUM] origna_gta/lib/features/checkout/checkout_screen.dart:~520
PROBLEM: _OrderSummary calculates displayed tax on full subtotal + shippingCost without applying coupon discount — buyer sees inflated tax estimate (e.g., 10% coupon on $100 order shows tax on $100 not $90).
FIX:
dartfinal discountDollars = ref.watch(checkoutProvider.select((s) => s.couponDiscountCents)) / 100.0;
final effectiveSubtotal = (subtotal - discountDollars).clamp(0.0, double.infinity);
final taxableAmount = effectiveSubtotal + shippingCost;
[MEDIUM] functions/handlers/payment_stripe.py:~1400
PROBLEM: Stock reservation transaction decrements availableQuantity in inventoryLevels subcollection but never validates new_avail >= 0 when allowBackorder = false, allowing inventory to go negative under concurrent requests.
FIX: After decrement: if new_avail < 0 and not allow_backorder: raise HttpsError('resource-exhausted', 'Insufficient stock').
[MEDIUM] functions/handlers/payment_stripe.py:~200
PROBLEM: verify_cart_prices compares prices using round(db_price, 2) — Python float rounding is not equivalent to integer cent comparison, causing false positives/negatives on edge values like $9.995.
FIX: Same cents-based comparison as the HIGH finding above: round(price * 100) on both sides.
[MEDIUM] origna_gta/lib/features/checkout/checkout_provider.dart:~180
PROBLEM: calculateShipping calls getTaxRate(state.address.state) with no validation that state.address.state is a valid Canadian province — invalid input silently falls back to Ontario rate (13%), potentially under/over-charging tax.
FIX: if (!BusinessRules.validProvinces.contains(state.address.state)) throw Exception('Invalid province code: ${state.address.state}');
[MEDIUM] functions/handlers/orders.py:~1200
PROBLEM: refund_order_item calculates proportional shipping refund from base shipping cost, not accounting for delivery speed surcharges (express/same-day) already paid — under-refunding buyers on expedited orders.
FIX: Use order_data.get(Fields.SHIPPING_COST_CENTS) (full paid amount including surcharge) as the base for proportional calculation.

[LOW] functions/handlers/payment_stripe.py:~600
PROBLEM: AUTHORIZATION_VALID_DAYS and expires_at are written to every order, but in auto-capture mode payment is captured immediately — dead code creates confusion and wastes Firestore writes.
FIX: Only set expires_at when capture_method == 'manual'; remove from auto-capture path or document clearly with # N/A in auto-capture mode.
[LOW] origna_gta/lib/features/checkout/checkout_screen.dart:~850
PROBLEM: _CheckoutButton._startCheckout() is async but the calling code doesn't check context.mounted after await before calling messenger.showSnackBar(...) — causes "setState after dispose" crash if user navigates away during checkout.
FIX: Add if (!context.mounted) return; immediately after every await in _startCheckout.
[LOW] functions/handlers/payment_stripe.py:~3100
PROBLEM: get_stripe_webhook_secret() fetches from Secret Manager on every webhook invocation — at 100M+ users scale this wastes Secret Manager quota ($0.03/10k reads) and adds latency.
FIX:
python_WEBHOOK_SECRET: str | None = None
def _get_webhook_secret() -> str:
    global _WEBHOOK_SECRET
    if not _WEBHOOK_SECRET:
        _WEBHOOK_SECRET = get_stripe_webhook_secret()
    return _WEBHOOK_SECRET
[LOW] origna_gta/lib/screens/payment_screens.dart:~35
PROBLEM: OrderSuccessGate._timeoutDuration = Duration(seconds: 45) — Stripe webhook retries can take minutes; 45s timeout shows "verification delayed" to buyers whose payments are actively processing.
FIX: Increase to Duration(seconds: 90) and add exponential-backoff polling in watchPaidOrderBySession.

[BONUS] functions/handlers/payment_stripe.py:~2500
PROBLEM: process_dispute_created sends Mailjet email synchronously inside webhook handler — if Mailjet is slow/down, Stripe's 30s webhook timeout is exceeded, causing Stripe to retry and creating duplicate dispute emails.
FIX: Write to email_queue Firestore collection and process via a separate Cloud Function trigger: get_db().collection('email_queue').add({...}).
[BONUS] origna_gta/lib/features/cart/cart_provider.dart:~_cartProductsBatchProvider
PROBLEM: _cartProductsBatchProvider batches in 30-item chunks but wraps the entire loop in no error handling — if any single chunk's firestore.collection().get() throws, the entire cart shows as empty with no user feedback.
FIX:
darttry {
  final snapshot = await firestore.collection(Collections.products).where(...).get();
  for (final doc in snapshot.docs) { if (doc.exists) cache[doc.id] = doc.data(); }
} catch (e, st) {
  Sentry.captureException(e, stackTrace: st);
  // Continue — partial cache is better than empty cart
}
[BONUS] functions/handlers/orders.py:~450
PROBLEM: update_item_status allows sellers to mark items as SHIPPED without requiring trackingNumber — buyers cannot track their shipment, and Stripe may flag seller for non-delivery.
FIX: if new_status == DeliveryStatusValues.SHIPPED and not data.get(Fields.TRACKING_NUMBER): raise HttpsError('invalid-argument', 'Tracking number required for shipped status').
[BONUS] origna_gta/lib/features/checkout/checkout_screen.dart:~1100
PROBLEM: _TermsText checkbox acceptance is stored only in ephemeral provider state — user must re-accept T&C every checkout session; CASL/PIPEDA require a timestamped record of acceptance.
FIX: On acceptance, write {Fields.termsAcceptedAt: FieldValue.serverTimestamp(), Fields.termsVersion: '1.0'} to users/{uid} doc via backend, and check this field at checkout start.
[BONUS] functions/handlers/payment_stripe.py:~1650
PROBLEM: _execute_seller_payouts writes payout record with PENDING status before calling stripe.Transfer.create() — if Stripe succeeds but the subsequent Firestore status update fails, the payout doc stays PENDING forever with no reconciliation.
FIX: Use Firestore transaction to atomically update payout status + store stripeTransferId, or add a cron job to reconcile PENDING payouts older than 5 minutes against Stripe's Transfer API.
[BONUS] origna_gta/lib/features/checkout/checkout_provider.dart:~95
PROBLEM: calculateShipping circuit breaker uses 'searchDefault' config (5 failures in 60s) — shipping calculation is far more payment-critical than search and should have higher thresholds to avoid unnecessary open-circuit failures.
FIX: CircuitBreakerRegistry.get('shipping_calc', config: CircuitBreakerConfig(failureThreshold: 10, timeout: Duration(seconds: 120))).
[BONUS] functions/handlers/payment_stripe.py:~800
PROBLEM: create_checkout_session validates postal code format with regex but never validates that state_code is in BusinessRules.VALID_PROVINCES — buyers can submit "XX" as province, hitting the Ontario tax fallback silently.
FIX: if state_code not in BusinessRules.VALID_PROVINCES: raise HttpsError('invalid-argument', f'Invalid province: {state_code}').
[BONUS] origna_gta/lib/screens/payment_screens.dart:~160
PROBLEM: PaymentCanceledScreen navigates to AppRoutes.home via pushNamedAndRemoveUntil — if user was mid-flow (product → cart → checkout → cancel), they lose the navigation stack and can't return to cart.
FIX: Use Navigator.of(context).pop() if there is a previous route, falling back to pushNamedAndRemoveUntil(AppRoutes.home, ...) only when stack is empty.
[BONUS] functions/handlers/orders.py:~1850
PROBLEM: on_order_status_changed Firestore trigger sends Mailjet emails synchronously in the trigger body — slow Mailjet responses cause Cloud Function timeout (540s max), blocking Firestore writes and causing retrigger loops.
FIX: Write to email_queue collection; process with a separate on_document_created trigger on email_queue.
[BONUS] origna_gta/lib/features/cart/cart_repository.dart:~addToCart
PROBLEM: addToCart creates cart items with deterministic doc IDs (productId or ${productId}_${variantId}) but does not verify the variant exists in the product's variants array before creating the cart item — orphaned cart items with invalid variantId pass silently through to checkout.
FIX: Before the transaction, fetch the product doc and validate variantId exists in product_data['variants']; throw if not found.
[BONUS] origna_gta/lib/screens/cartitem_screen.dart:~_saveForLater
PROBLEM: _saveForLater writes Fields.savedAt ("savedAt") to the favorites subcollection, but the schema defines the field as Fields.dateFavorited ("dateFavorited") — favorites Firestore rules/queries that filter on dateFavorited will never see these items.
FIX: Replace Fields.savedAt with Fields.dateFavorited: {Fields.productId: productId, Fields.dateFavorited: FieldValue.serverTimestamp()}.
[BONUS] origna_gta/lib/screens/cartitem_screen.dart:~_saveForLater
PROBLEM: _saveForLater calls FirebaseFirestore.instance directly from a screen widget — violates MVVM. No error handling for the cart removal race condition (favorite write succeeds, cart remove fails → item duplicated).
FIX: Add await to removeFromCart call and wrap both operations in a try-catch with rollback (delete the favorites doc if cart removal fails): move logic to CartController.saveForLater().
[BONUS] origna_gta/lib/screens/cartitem_screen.dart:~100
PROBLEM: 'Digital product — instant delivery' and 'Saved for later' are hardcoded English strings — not wrapped in .tr(), breaking Quebec Bill 96 French compliance.
FIX: Add translation keys cart.digital_instant_delivery and cart.saved_for_later to all .arb files and use .tr().
[BONUS] functions/services/shipping_service.py:~_TAX_RATES_CACHE
PROBLEM: _TAX_RATES_CACHE (flat combined rates) is a second source of truth for tax rates alongside BusinessRules.TAX_RATES (component breakdown) — NS is 0.14 in both but any future CRA update needs to be applied in two places; they will inevitably diverge.
FIX: Derive _TAX_RATES_CACHE from BusinessRules.TAX_RATES at module load:
python_TAX_RATES_CACHE = {prov: sum(v/100 for v in rates.values()) for prov, rates in BusinessRules.TAX_RATES.items()}
[BONUS] origna_gta/lib/features/cart/cart_provider.dart:~cartItemDetailProvider
PROBLEM: cartItemDetailProvider family key is productId (String) only — if the same product has two different variants in the cart, the second variant's cartItemDetailProvider(productId) returns the first variant's data (wrong variant title/options/sku displayed).
FIX: Change family key to the cart item's doc ID (which is already productId_variantId): cartItemDetailProvider = FutureProvider.family<..., String>((ref, cartItemDocId) {...}).
[BONUS] origna_gta/lib/core/repositories/order_repository.dart:~watchBuyerOrders
PROBLEM: watchBuyerOrders uses a whereIn on paymentStatus with 6 values + orderBy(createdAt) — requires a composite Firestore index on (userId, paymentStatus, createdAt). This index IS listed in the schema but the whereIn + orderBy on different fields requires Firestore to also have the index explicitly declared; missing index causes silent runtime failures in production.
ALSO: watchSellerOrders has the same pattern on (sellerIds arrayContains, paymentStatus whereIn, createdAt orderBy).
FIX: Verify firestore.indexes.json contains both composite indexes. The whereIn on an array field (sellerIds) combined with orderBy is not supported by Firestore; the sellerIds query must drop the orderBy and sort client-side, or use a separate query per status.
[BONUS] origna_gta/lib/screens/ordersuccess_screen.dart (no issues found outside scope)
PROBLEM: OrderSuccessScreen has no Sentry breadcrumb or analytics event on successful order — platform loses conversion funnel data and cannot monitor payment success rates.
FIX: Add Sentry.addBreadcrumb(Breadcrumb(message: 'order_success', data: {'orderId': orderId})) and fire a purchase analytics event in initState of a ConsumerStatefulWidget.stripe-payment.spec.ts91 lignestscheckout-validation.spec.ts116 lignestspayment-edge-cases.spec.ts149 lignestsshipping-calculation.spec.ts107 lignests00:00Audited five test suites for coverage gaps and reliability issuesAudited five test suites for coverage gaps and reliability issuesThe user has uploaded E2E test spec files for the OrignaGTA checkout/payment flow. I need to audit these test files for issues - missing coverage, incorrect assertions, flawed test design, etc.
Let me review each file carefully.List uploaded test filesScriptRead buyer-flow specScriptNow I have all 5 test files. Let me analyze each one for issues across:

Missing test coverage
Incorrect/weak assertions
Flawed test design (shared state, bad isolation, timing issues)
Security test gaps
Missing audit checklist items
Test reliability issues
Logic errors

Let me go through each carefully.
stripe-payment_spec.ts

invalidateProductCache() called without await - If this is async, it returns a silently ignored promise.
waitForOrderStatus called without verifying stripeSessionId - The test verifies stripePaymentIntentId but not stripeSessionId, chargeId, or that payout records exist.
paymentStatus === 'captured' is checked but orderStatus isn't verified - The test waits for ['confirmed', 'processing'] but never asserts what the final status actually is, only checking payment status.
fillStripeCheckout followed by a hardcoded 5-second delay - This is brittle and doesn't actually wait for the redirect or order to appear.
stockDecremented test only checks that stock decreased - It doesn't verify the exact amount or that it matches the order quantity.
Missing tests for self-purchase prevention, idempotency, platformFeeRatio storage, and expiresAt field - Several critical features and audit findings have no coverage.
invalidateProductCache isn't awaited, so all tests in the suite could race on the same product's stock - This creates unpredictable test interactions.
The 5-second timeout is unreliable for webhook firing - Slower environments will fail intermittently.

Now looking at the checkout-validation spec, there's a shared productId across all tests that could cause stock depletion to mask validation failures. Missing tests include self-purchase prevention, invalid province codes, and quantity limits exceeding both stock and the MAX_ITEM_QUANTITY cap.
Also need tests for non-Canadian countries, non-numeric postal codes, and the callExpectError assertion is too loose—it passes on any error, not just validation-specific ones. The rate limit test needs extra time to complete.
The subtotal mismatch test adds $999 which is a significant amount, and the negative price test doesn't verify that negative prices combined with positive items don't bypass validation—both need more specific error code assertions rather than just checking for "unexpected-success".
Looking at the payment edge cases spec, there's a mismatch where the 3DS test creates a buyerAuth session for one customer email but then tries to use different emails in each test, which could cause Stripe to behave unexpectedly. The 3DS assertion just checks that the page URL is truthy, which passes even if 3DS completely fails. Similarly, the declined card test only verifies the URL contains 'checkout.stripe.com', which doesn't actually confirm the card was declined.
Beyond these assertion issues, I'm noticing several critical gaps: there's no verification that the order's paymentStatus stays in a failed state after a declined card, no test for what happens when a user abandons the 3DS modal, and no checks that stock isn't decremented or gets restored after payment failures. The dismissStripeModals helper also might not handle all possible Stripe UI states like cookie banners that could block the flow.
The 3DS test silently catches errors when clicking the completion button inside the iframe, so there's no actual verification the authentication succeeded. I'm also missing tests for edge cases like submitting the same checkout session twice after it's already paid, or visiting an expired Stripe URL.
Looking at the shipping calculation tests now, I see the product creation is writing directly to Firestore with admin credentials, but it might not have the priceCents field properly computed if the schema expects that to be set during write time.
The test product never gets cleaned up afterward, which pollutes the database at scale. There's also a potential issue where if the buyer UID happens to match TEST_UIDS.SELLER, the self-purchase prevention will incorrectly reject the order. The tax assertion is too permissive at 10–16% when Ontario HST should be exactly 13%, which could hide bugs like wrong province calculations or double-taxation.
Several provinces aren't tested: Alberta with its 0% PST and 5% GST, and Quebec with its unique 9.975% QST combined with GST for 14.975% total. There's also no validation that shipping costs stay non-negative or that the free shipping threshold kicks in correctly for orders over $75. The test setup has a race condition where invalidateProductCache() is called without awaiting it, and the multiple quantity test actually creates separate orders instead of testing a single order with multiple items.
In the buyer-flow spec, there's a semantic issue where ensureLoggedInAsAdmin is being used to log in as a buyer, suggesting it was copy-pasted from admin tests without proper renaming.
There are also two dead assertions with || true operators that make the save visibility and tax display checks always pass regardless of actual state. The entire test is structured as one monolithic block, so any early failure silently skips all subsequent steps instead of failing cleanly. Navigation also relies on brittle page.goBack() calls instead of more reliable methods.
Optional element checks are swallowing failures—if a mandatory UI element like "My Orders" isn't visible due to a bug, the test just skips that step rather than failing. The settings button is only checked for being attached to the DOM rather than actually visible on screen. And there's no verification that the sign-out actually completes successfully.
The test timeout of 5 minutes is way too generous for a flow that should run in under 90 seconds, which masks performance issues. The scroll logic uses a fixed pixel amount that breaks across different screen sizes. Most critically, the test never actually completes a purchase—it navigates to checkout but then backs out, leaving the entire order placement flow untested.
Also, there's no check that cart items persist across sessions, which is a fundamental buyer expectation.Afficher plusTerminéHere is the complete audit of all five E2E test spec files.

[CRITICAL] buyer-flow_spec.ts:37
PROBLEM: ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD) logs in with buyer credentials using a function named ensureLoggedInAsAdmin — if that helper performs role grants or admin-specific setup (highly likely given the name), every buyer-flow test runs with corrupted auth state and the coverage is invalid.
FIX: Create and use a dedicated ensureLoggedInAsBuyer helper; audit flutter-helpers.ts to confirm ensureLoggedInAsAdmin does not grant elevated roles.
[CRITICAL] buyer-flow_spec.ts:61
PROBLEM: expect(saveVisible || true).toBeTruthy() — || true makes the assertion unconditionally pass; the save-address button visibility is never actually tested. Same pattern on line ~82: expect(hasTax || true).toBeTruthy().
FIX: Remove || true from both assertions. For mandatory elements use expect(element).toBeVisible(); for optional ones assert the specific condition or remove the assertion entirely.
[CRITICAL] payment-edge-cases_spec.ts:87
PROBLEM: The 3DS test ends with expect(page.url()).toBeTruthy() — any non-empty URL string (including 'about:blank') passes. The test provides zero signal: it will green even if the page crashed, the card was silently declined, or 3DS never appeared.
FIX: After 3DS completion assert the redirect: await expect(page).toHaveURL(/payment-success|orignagta/, { timeout: 30_000 }) and verify the order document's paymentStatus is 'captured' via readDoc.
[CRITICAL] payment-edge-cases_spec.ts (missing test)
PROBLEM: No test verifies that stockQuantity is NOT decremented after a declined card — this is a critical business invariant and directly related to the CRITICAL audit finding that stock restoration in process_payment_intent_failed is broken.
FIX:
typescripttest('Stock not decremented after declined card', async ({ page }) => {
  const stockBefore = await getProductStock(product.id, buyerAuth.idToken);
  // ... fill declined card, submit ...
  await page.waitForTimeout(15_000);
  const stockAfter = await getProductStock(product.id, buyerAuth.idToken);
  expect(stockAfter).toBe(stockBefore);
});
[CRITICAL] checkout-validation_spec.ts (missing test)
PROBLEM: No test verifies self-purchase prevention — a user whose UID matches a product's sellerId should be rejected server-side, but there is no test for this. This is checklist item #3.
FIX:
typescripttest('Rejects self-purchase (buyer is the seller)', async () => {
  // Use a product where sellerId === buyerAuth.localId
  const { data } = await buildCheckoutPayload(sellerAuth.localId, sellerOwnProductId, 1, sellerAuth.idToken);
  const error = await callExpectError('create_checkout_session', data, sellerAuth.idToken);
  expect(error.code).toBe('failed-precondition');
});
[CRITICAL] checkout-validation_spec.ts (missing test)
PROBLEM: No test for invalid province code (e.g., state: 'XX') — directly maps to the [BONUS] audit finding. Backend silently falls back to Ontario 13% tax for unknown province codes, meaning a buyer in 'XX' province pays wrong tax and their address passes checkout validation.
FIX:
typescripttest('Rejects invalid province code', async () => {
  const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
  data.shippingAddress.state = 'XX';
  const error = await callExpectError('create_checkout_session', data, buyerAuth.idToken);
  expect(error.code).toBe('invalid-argument');
});

[HIGH] stripe-payment_spec.ts:21,29,39,51
PROBLEM: invalidateProductCache() is called without await in all four tests — if the function is async, the promise is silently discarded and the cache may not be invalidated before getTestProduct runs, causing all tests to operate on a stale/same cached product and race on its stock.
FIX: await invalidateProductCache() in every call site.
[HIGH] stripe-payment_spec.ts:27
PROBLEM: waitForOrderStatus followed by page.waitForTimeout(5_000) (line ~33 in Order document test) — fixed 5-second sleep to wait for webhook delivery is flaky: too short on slow CI, wasteful on fast hardware. The test also does not check chargeId, stripeSessionId, or that platformFeeRatio was stored on the order doc (critical for the [CRITICAL] fee rate bug).
FIX: Remove page.waitForTimeout(5_000). Use waitForOrderStatus consistently. Add assertions: expect(order.platformFeeRatio).toBe(0.025) and expect(order.stripeSessionId).toBeTruthy().
[HIGH] stripe-payment_spec.ts (missing test)
PROBLEM: No idempotency test — calling create_checkout_session twice with the same idempotencyKey must not create two orders. Checklist item #2 is completely uncovered.
FIX:
typescripttest('Duplicate checkout session with same idempotency key does not create two orders', async () => {
  const { data, idempotencyKey } = await buildCheckoutPayload(...);
  const r1 = await callOk('create_checkout_session', data, auth.idToken);
  const r2 = await callOk('create_checkout_session', data, auth.idToken); // same key
  expect(r1.orderId).toBe(r2.orderId);
});
[HIGH] checkout-validation_spec.ts:all error tests
PROBLEM: Every error assertion uses expect(error.code).not.toBe('unexpected-success') — this passes even if the function throws a generic 500 (network error, unhandled exception). It provides no signal about which validation fired. A backend crashing for an unrelated reason would be indistinguishable from intentional rejection.
FIX: Assert the specific expected code: expect(error.code).toBe('invalid-argument') for input validation errors, 'failed-precondition' for business rule violations. This makes failures diagnostic.
[HIGH] payment-edge-cases_spec.ts:62
PROBLEM: The declined card test asserts page.url().includes('checkout.stripe.com') — this is true from the moment the page loads, before the card is even submitted. There's no assertion that a visible error message appeared (e.g., "Your card was declined").
FIX:
typescriptconst errorEl = page.locator('[data-testid="error-message"], .Alert--error, text=/declined|card number is incorrect/i').first();
await expect(errorEl).toBeVisible({ timeout: 15_000 });
[HIGH] payment-edge-cases_spec.ts (missing test)
PROBLEM: No test verifies the Firestore order paymentStatus after a declined card — backend should set it to 'payment_failed' (or leave it 'awaiting_payment'), not 'captured'. This would catch a regression where the backend incorrectly marks failed payments as successful.
FIX: After the declined card submission, poll readDoc(orders/${result.orderId}) and assert order.paymentStatus !== 'captured'.
[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')
PROBLEM: The test creates a product via writeDoc with only price: 10.00 but no priceCents: 1000 field. The backend's verify_cart_prices may read priceCents (integer cents, the canonical field per schema), find it missing (null), and either crash or silently accept any client price, making this test not actually exercise price validation.
FIX: Add priceCents: 1000 to the toFirestoreFields({...}) payload, or use the product-creation Cloud Function instead of direct Firestore write.
[HIGH] shipping-calculation_spec.ts:test('Multiple quantity…')
PROBLEM: Created test product is never deleted — afterAll cleanup is absent. In a dev environment shared by the whole team, this leaks a permanent test_ship_stock_{timestamp} product into the products collection on every test run.
FIX:
typescripttest.afterAll(async () => {
  await deleteDoc(`products/${productId}`, adminAuth.idToken);
});

[MEDIUM] buyer-flow_spec.ts (one monolithic test)
PROBLEM: The entire buyer journey is one test() block — if the settings button click fails at step B01, all subsequent 15+ assertions are skipped with no failure output. Playwright reports a single "failed test" with no granularity on which step broke.
FIX: Split into individual test() cases: 'Profile page navigates correctly', 'Address management works', 'Cart navigates to checkout', etc., each with independent setup.
[MEDIUM] buyer-flow_spec.ts:optional steps pattern
PROBLEM: Critical user-facing elements (My Orders, Cart button, checkout button) are wrapped in if (await element.isVisible().catch(() => false)) — if these elements are absent due to a bug, the test silently passes without exercising those paths. The test provides false green coverage.
FIX: For mandatory elements: await expect(menuOrders).toBeVisible() with no if wrapping. Reserve the if pattern only for genuinely optional UI (e.g., cookie banners, promotional modals).
[MEDIUM] buyer-flow_spec.ts:end
PROBLEM: performSignOut is called but there's no assertion that the sign-out succeeded — no check that the page redirected to login, no attempt to access a protected route afterward, and no token invalidation check.
FIX: After performSignOut, assert await expect(page).toHaveURL(/login|sign-in/, { timeout: 15_000 }) and verify that readDoc('orders/any', invalidated token) returns an auth error.
[MEDIUM] stripe-payment_spec.ts:test('Stock decremented…')
PROBLEM: expect(stockAfter).toBeLessThan(stockBefore) passes even if stock dropped by 5 instead of 1 (the ordered quantity). A bug that over-decrements stock would not be caught.
FIX: expect(stockAfter).toBe(stockBefore - 1) — assert the exact delta equals the ordered quantity.
[MEDIUM] checkout-validation_spec.ts (missing tests)
PROBLEM: Missing coverage for: (a) quantity: 999 exceeding ValidationLimits.MAX_ITEM_QUANTITY = 100, (b) country: 'United States' bypassing the Canada-only buyer check (checklist item #7), (c) quantity: -1 (negative quantity).
FIX: Add three tests, each with expect(error.code).toBe('invalid-argument').
[MEDIUM] shipping-calculation_spec.ts:Ontario tax range
PROBLEM: Tax range 10%–16% is too loose — Ontario HST is exactly 13%. A bug applying BC's 12% (GST+PST) or PE's 15% (HST) would pass the assertion. The test masks province-selection bugs.
FIX: expect(order.taxAmountCents).toBeCloseTo(taxableBase * 0.13, -1) — allow ±1 cent rounding but pin to the correct rate.
[MEDIUM] shipping-calculation_spec.ts (missing tests)
PROBLEM: No test for (a) Quebec (QST+GST = 14.975%), (b) Alberta (GST only = 5%), (c) free shipping threshold — orders above BusinessRules.FREE_SHIPPING_THRESHOLD_CENTS ($75) should have shippingCostCents = 0 for standard delivery. Three core business rules are fully uncovered.
FIX: Add one test per province scenario and one for the free shipping threshold: expect(order.shippingCostCents).toBe(0) for a $100 order.
[MEDIUM] payment-edge-cases_spec.ts:3DS iframe
PROBLEM: threeDSFrame.locator(...).click() is wrapped in try { ... } catch { } with silent swallowing — if the 3DS challenge appeared but the click failed, the test continues without completing authentication. The frame selector iframe[name*="stripe-challenge"] may also not match Stripe's actual iframe name, meaning 3DS is never completed in any environment.
FIX: Log the catch: } catch (e) { console.warn('3DS frame not found or click failed:', e); }. Add a separate test that explicitly asserts 3DS challenge appearance: await expect(threeDSFrame.locator('#test-source-authorize-3ds')).toBeVisible({ timeout: 15_000 }).

[LOW] stripe-payment_spec.ts (missing test)
PROBLEM: No test for source_transaction correctness (checklist item #4) — after payment, the payout transfer's source_transaction must be a ch_xxx charge ID, not the pi_xxx PaymentIntent ID. This is never verified.
FIX: After order reaches 'confirmed' status, read the payouts collection for the order and assert payout.stripeTransferId starts with 'tr_' and is non-null. The actual source_transaction check requires Stripe API access — add a test that retrieves the transfer from Stripe and asserts transfer.source_transaction.startsWith('ch_').
[LOW] stripe-payment_spec.ts (missing test)
PROBLEM: No test verifying platformFeeRatio is stored on the order document at checkout time (required to fix the [CRITICAL] fee rate bug). If the field is absent, _execute_seller_payouts silently falls back to the global config.
FIX: In 'Order document has correct structure', add expect(order.platformFeeRatio).toBe(0.025).
[LOW] buyer-flow_spec.ts:scroll
PROBLEM: page.mouse.wheel(0, 220) uses a fixed 220px scroll — product card height varies by screen size and Flutter rendering. On a 1080p screen this may scroll less than one card; on a mobile viewport it may overshoot. Tests scroll up to 6 times with no guarantee of finding cards.
FIX: await page.evaluate(() => window.scrollBy(0, window.innerHeight * 0.8)) per iteration, or use await page.locator('[aria-label^="product-card-"]').first().waitFor({ timeout: 10_000 }) before attempting the click.
[LOW] checkout-validation_spec.ts:beforeAll product reuse
PROBLEM: productId is set once in beforeAll and reused across 8 tests. If the product's stock is exhausted mid-suite (e.g., a test accidentally completes payment), subsequent tests get stock-exhaustion errors instead of their intended validation errors, causing confusing failures.
FIX: Use getTestProduct per test or ensure callExpectError never creates a paid order. Alternatively mock the product with stockQuantity: 1000 via writeDoc in beforeAll.
[LOW] payment-edge-cases_spec.ts:email per test
PROBLEM: Each edge-case test fills a unique email (test-decline-${Date.now()}@origna-test.ca) to Stripe's email field — but the checkout session was created with the buyer's real email attached to the Stripe customer. Stripe's hosted page may ignore the email input for returning customers, meaning the email.fill() call is silently a no-op and the test is not actually testing the email-as-new-customer path.
FIX: Remove the email-fill step from edge case tests since the session already has an associated Stripe customer; or explicitly test guest checkout with a session created without a customer ID.
[BONUS] All specs
PROBLEM: No test covers the cart-cleared-after-order-creation invariant (checklist item #10) — after a successful payment, users/{userId}/cart should be empty. A bug that preserves cart items after checkout would go undetected.
FIX: After waitForOrderStatus(orderId, ['confirmed']), read users/{buyerId}/cart and expect(cartItems.length).toBe(0).
[BONUS] All specs
PROBLEM: No test for the expiresAt field being present on the order document (7-day authorization window, checklist item #5). Per the audit, this field is set even in auto-capture mode (dead code finding), but its value should still be within 7 days of createdAt.
FIX: In 'Order document has correct structure': const delta = order.expiresAt._seconds - order.createdAt._seconds; expect(delta).toBeLessThanOrEqual(7 * 86400);
[BONUS] shipping-calculation_spec.ts:Multiple quantity test
PROBLEM: Two separate callOk('create_checkout_session', ...) calls are made to compare qty=1 vs qty=2. Any price change, rate-limit, or cold-start latency between the two calls can produce a non-2× ratio, making the test flaky.
FIX: Compute the expected subtotal mathematically from the known product price (10.00): expect(order1.subtotalCents).toBe(1000); expect(order2.subtotalCents).toBe(2000) — no cross-order ratio needed.
[BONUS] All specs
PROBLEM: No test for the currency field at the Stripe API level — all tests verify order.currency === 'cad' in Firestore, but never assert the Stripe PaymentIntent was created in CAD. A bug that creates the intent in USD would not be caught by these tests.
FIX: Retrieve the Stripe PaymentIntent via the Stripe test API using order.stripePaymentIntentId and assert pi.currency === 'cad'.
[BONUS] checkout-validation_spec.ts
PROBLEM: No rate-limiting test despite the comment // Needs extra time for rate limit retries. BusinessRules.CHECKOUT_RATE_LIMIT = 5 per minute — this should be enforced. The test file promises coverage it does not deliver.
FIX: Add a test that fires 6 rapid create_checkout_session calls in succession and asserts the 6th returns 'resource-exhausted' or 'too-many-requests'.


Strategized improvements for documentation gaps and business rules
Strategized improvements for documentation gaps and business rules
Let me research all the coverage gaps and business rules deeply before writing the answer.

Synthesized research to enhance documentation gaps and business logic
Synthesized research to enhance documentation gaps and business logic
Here's the full pro-level breakdown. Everything below is sourced from current industry research, Playwright docs, Firebase internals, and fraud pattern analysis.
INSTRUCTIONS.md — Section 6 & 8 Deep Audit + Improvements
SECTION 6 — Coverage Gaps: Improved + Extended
6.1 Return Request Flow — Upgraded
What the doc has: Basic happy path (requested → approved → label_issued → received → refunded → rejected).
What's missing / improved:
New adversarial scenarios to add:
Component stripping attack — buyer returns electronics with valuable parts removed (GPU, RAM) claiming "item arrived broken." Test: seller receives return, photos don't match original, seller disputes. Admin mediates.
Wardrobing — buyer returns clothing after wearing once. Test: return arrives visibly used, seller rejects condition. Firestore returnCondition field must be validated.
Double-refund race condition — buyer submits two return requests simultaneously on the same order via two tabs or two network requests. The Cloud Function must be idempotent. Test: only one returns document gets created, second call returns the existing one instead of creating a duplicate.
Return window edge case — buyer submits return exactly on day 30 at 23:59:59. Test: it passes. Day 31 00:00:01 — it's rejected. Use page.clock.install() from Playwright's new clock API to simulate this without actually waiting.
Return after seller is suspended — what happens? Admin must be able to process refund manually.
Refund to original payment method vs store credit — test both paths exist and correct amount is sent.
Digital product return — must be blocked. License should not be revocable via return flow (digital goods are explicitly non-returnable). Test: "Request Return" button is hidden/disabled for digital orders.
Alternative test approaches:
typescript
// APPROACH A: Playwright clock injection to simulate return window
await page.clock.install({ time: new Date('2026-03-01T00:00:00') });
// ... place order
await page.clock.fastForward('31d'); // simulate 31 days later
// Assert: return button is hidden

// APPROACH B: Firestore direct seeding (faster, avoids full checkout flow)
await writeDoc('orders/test-return-order', {
  orderStatus: 'delivered',
  deliveredAt: Timestamp.fromDate(daysAgo(29)), // 29 days ago = still in window
  buyerId: ADMIN_UID,
  sellerId: 'mseed_seller_1',
});
await writeDoc('orders/test-return-order-expired', {
  orderStatus: 'delivered',
  deliveredAt: Timestamp.fromDate(daysAgo(31)), // expired
});
6.2 Coupon / Promo Codes — Upgraded
What's missing:
Per-user usage enforcement — same user tries WELCOME10 twice on two different orders. Second use must be rejected. Test verifies usages/{uid} subcollection or counter is updated atomically.
Minimum order not met — SAVE5NOW requires $30 minimum. Test: cart total = $25, apply → error shown. Add item → total = $35, apply → accepted.
Coupon applied then item removed — cart drops below minimum after coupon is applied. Test: warning shown, "Place Order" disabled.
Race condition on usage limit — two users simultaneously apply the last use of a limited coupon (e.g., max 1 global use). Test: only one succeeds. Cloud Function must use Firestore transaction to atomically check-and-increment usage counter. This is the exact scenario Firestore transactions were built for — the doc currently has no test for it.
Percentage discount + tax interaction — 10% off a $100 item. Is tax calculated on $90 (post-discount) or $100 (pre-discount)? CRA rules say discount applies before GST/HST. Test verifies this order.
Seller-specific coupon — coupon only valid for products from seller_1. Test: cart with seller_2 only product → coupon rejected. Mixed cart → discount applies only to seller_1 portion.
Alternative approaches:
typescript
// APPROACH A: Full UI flow (most realistic, tests complete stack)
await navigate('/checkout');
const couponField = page.getByRole('textbox', { name: /coupon/i });
await couponField.click();
await couponField.pressSequentially('WELCOME10', { delay: 30 });
await page.getByRole('button', { name: /apply/i }).click();
await expect(page.locator('[aria-label="discount-amount"]')).toBeVisible();

// APPROACH B: Backend-first (faster, tests CF independently)
const result = await callOk('/validateCoupon', {
  code: 'WELCOME10', cartTotal: 50, userId: ADMIN_UID
});
expect(result.discountAmount).toBe(5);

// APPROACH C: Firestore transaction race simulation (adversarial)
await Promise.all([
  callOk('/validateCoupon', { code: 'LAST_USE_CODE', cartTotal: 50, userId: 'user_a' }),
  callOk('/validateCoupon', { code: 'LAST_USE_CODE', cartTotal: 50, userId: 'user_b' }),
]);
// Verify usage count = 1 in Firestore, not 2
const coupon = await getDoc('coupons/LAST_USE_CODE');
expect(coupon.usageCount).toBe(1);
6.3 Product Q&A — Upgraded
What's missing:
Seller answers their own product — happy path. But also test: seller tries to answer another seller's product Q&A → permission denied (Firestore rules + Cloud Function check).
Admin can answer any product — admin answers as neutral party.
Question moderation — buyer posts question with profanity/spam. If there's any content filtering, test it. If not, document it as a future gap.
Unauthenticated user can read Q&A — Q&A is public content. Verify Firestore rules allow read without auth but require auth for write.
Question pagination — product with 20+ questions. Test that load-more works and doesn't refetch existing items.
Duplicate question prevention — buyer asks same question twice. Test: second submit shows "You already asked this question."
Malformed input — empty question string, question with only whitespace, question >500 chars. All should be validated client-side and backend-enforced.
6.4 Admin Product Lifecycle — Upgraded
What's missing:
Bulk approve/reject — admin approves 5 products in one action. Test: all 5 move to active. Verify no partial states.
Product approved → seller suspended afterward — product should auto-move to suspended or be hidden. Test verifies buyers can't see it.
Admin rejects then product re-submitted — seller edits rejected product and resubmits. Status moves back to under_review. Test the cycle: draft → under_review → rejected → draft (edit) → under_review → approved → active.
Admin view filters — test tab for each lifecycle state: draft, under_review, approved, active, rejected, archived, suspended. Each tab must show correct count and correct products.
Rejection reason stored + visible to seller — after rejection, seller navigates to /seller/products, sees rejected product with reason displayed. Test the Firestore field rejectionReason is rendered.
Price manipulation during review — seller changes price while product is under_review. Test: price update is allowed (seller can still edit) but doesn't auto-approve.
6.5 Seller Metrics Dashboard — Upgraded
New scenarios entirely missing from doc:
Zero-state dashboard — brand new seller with no sales. All metrics show 0 or empty state gracefully (no crashes, no NaN in percentages).
Metrics aggregation lag — order completes at T+0, metrics update via Cloud Function trigger. Test: after order confirmed, wait for metrics to update (eventual consistency). Use Playwright's expect.poll() rather than fixed sleep:
typescript
await expect.poll(async () => {
  const metrics = await getDoc(`seller_metrics/${SELLER_UID}`);
  return metrics.totalRevenue;
}, { timeout: 10000 }).toBeGreaterThan(0);
Admin global metrics view — admin sees platform-wide GMV, total orders, platform fees. Test that non-admin cannot access this route or API.
Suspicious spike detection — seller gets 50 orders in 1 minute from same IP. Test that a security alert is created in security_alerts collection. This is your fraud ring detection signal.
6.6 Address Book — Upgraded
What's missing:
Non-Canadian address rejected — attempt to save address with US zip code (e.g., 10001). Must fail with "Canadian addresses only."
Postal code format validation — Canadian postal codes are A1A 1A1 format. Test malformed variants: 12345, AAA, A1A1A1 (no space), A1A 1A (too short). Also test that lowercase is auto-corrected to uppercase.
Province/postal code mismatch — postal code starting with M (Ontario) but province selected as Quebec. This should fail or warn.
Delete default address — buyer deletes their only/default address. What happens? Test: if it's the only address, delete is blocked with "You need at least one address to checkout." If non-default, deletion works and next address becomes default.
Address used in active order — buyer tries to delete address that is attached to a confirmed or shipped order. Test: deletion blocked with appropriate message.
Geoapify autocomplete — type "100 King" → autocomplete suggestions appear → select one → all fields auto-fill. Test the ARIA label for the autocomplete dropdown is reachable with Flutter selectors.
Maximum address limit — platform may cap at 10 addresses per user. Test: adding 11th address → error shown.
6.7 Chat (Premium) — Upgraded
What's missing (based on reviewing chat_repository.dart and chat_provider.dart):
sellerChatsStream and userChatsStream are separate queries. A user who is both buyer and seller sees two separate stream lists. Test: admin user (buyer + seller) navigates to chat list, sees both buyer-side and seller-side threads correctly grouped.
Rate limiting — resource-exhausted error is already handled in _parseError. Test: spam 10+ messages rapidly → UI shows "Too many messages. Please slow down." and subsequent sends are blocked until cooldown.
Message ordering — 100 messages loaded with limitToLast(100). Test: messages render oldest-first (ascending). Send new message → it appears at bottom without scroll jump.
markRead called on navigation — when buyer opens chat, markRead must be called. Test: buyerUnreadCount in Firestore drops to 0 after entering chat. Verify with getDoc.
Chat with inactive/deleted product — product is archived after chat is opened. Test: chat still works (conversation persists), but product link shows "Product no longer available."
Non-premium error message — permission-denied with "premium" in message → correct UX string shown: "A Premium membership is required to chat with sellers." This string is already in _parseError. Test it renders in the UI via aria-label.
Seller cannot initiate chat — test that chat can only be initiated by buyer (getOrCreateChat called from buyer side). Seller trying to create a new chat with a buyer directly (without existing thread) is blocked.
Empty message blocked — text.trim().isEmpty check in sendMessage. Test: send button disabled when input is blank.
6.8 Digital Product Activation — Upgraded
What's missing:
License format validation — XXXX-XXXX-XXXX-XXXX format. Test: malformed activation key rejected with clear error.
License tied to UID — test that another buyer trying to activate a license they didn't purchase gets permission-denied.
Re-download after session expiry — buyer logs out, logs back in, download still works. License remains active.
Software vs book distinction — software license has platform restriction (e.g., Windows only). Test: wrong platform → rejected with "License not valid for this platform."
License revocation on order dispute — if order enters disputed state, license access should be suspended. Test: license status → suspended, download blocked.
Concurrent activation attempts — two devices try to activate same single-device license simultaneously. Firestore transaction must enforce single activation. Test race condition.
SECTION 8 — Business Rules: Improved + Extended
8.1 Payment + Stripe — Upgraded
Price tampering — currently in doc, needs stronger test coverage:
The existing doc says "test price tampering." Here's the actual adversarial test pattern you need:
typescript
// ADVERSARIAL: Client-side price injection
// 1. Buyer adds product ($100) to cart
// 2. Intercept the checkout Cloud Function call using Playwright's route interception
// 3. Modify the payload to change price to $0.01 before it hits the function
await page.route('**/createCheckoutSession', async route => {
  const request = route.request();
  const body = JSON.parse(request.postData() || '{}');
  body.items[0].price = 1; // tamper to $0.01
  await route.continue({ postData: JSON.stringify(body) });
});
// 4. Assert: Cloud Function re-reads price from Firestore, ignores client price
// 5. Assert: Stripe session created with $100, not $0.01
// 6. Assert: Error shown to buyer if Cloud Function rejects entirely
Authorization capture window (7 days): Use page.clock to simulate this:
typescript
await page.clock.install({ time: orderCreatedAt });
await page.clock.fastForward('8d'); // simulate 8 days
// Assert: payment_intent status = 'expired', order moves to 'expired' status
// Assert: buyer notified, seller notified, stock restored
Idempotency — double-click protection:
typescript
// APPROACH A: UI-level (click submit twice very fast)
const placeOrderBtn = page.locator('[aria-label="btn-place-order"]');
await Promise.all([placeOrderBtn.click(), placeOrderBtn.click()]);
// Assert: exactly 1 order in Firestore, not 2

// APPROACH B: Direct CF call with same idempotency key
await Promise.all([
  callOk('/createCheckoutSession', { ...payload, idempotencyKey: 'key-123' }),
  callOk('/createCheckoutSession', { ...payload, idempotencyKey: 'key-123' }),
]);
// Assert: Stripe PaymentIntents list shows 1 intent, not 2
Missing from current doc — Stripe webhook replay attacks: Stripe can retry a webhook up to 3 days. Your Cloud Function must be idempotent on webhook events. Test:
typescript
// Send same webhook event twice with same event ID
await callOk('/stripeWebhook', { ...event, id: 'evt_test_123' });
await callOk('/stripeWebhook', { ...event, id: 'evt_test_123' }); // replay
// Assert: order status updated once, not twice. No duplicate payouts.
Missing — Stripe Connect payout failure: What happens if the seller's Stripe Express account is deauthorized between order and payout? Test: Cloud Function catches payout error, creates payout_failures document, admin is alerted, order stays in captured with payoutStatus: failed.
8.2 Canadian Compliance — Upgraded
GST/HST per-province — currently not granular enough:
Canada has three tax regimes that must be tested separately:
Province	Tax Type	Rate	Test
ON, BC, NS, NB, PEI, NL	HST	13–15%	Most common case
AB, SK, MB, QC, YT, NT, NU	GST only	5%	QC collects own QST
QC	GST + QST	5% + 9.975%	Must show separately
Tests needed:
Buyer with Ontario address → HST 13% shown
Buyer with Alberta address → GST 5% shown
Buyer with Quebec address → GST 5% + QST 9.975% shown separately (QSPA requirement)
Digital product (no PST) vs physical product — digital products are subject to GST/HST but rules differ for PST
CASL consent:
Test: during signup, checkbox for "I agree to receive commercial emails" is present and unchecked by default
Test: user can complete registration without checking it (consent optional for transactional emails)
Test: checked consent → users/{uid}.emailConsent = true in Firestore
Test: unchecked → emailConsent = false, user still receives transactional emails (order confirmations) but not marketing
French content for Quebec (if lang=fr):
typescript
// Set browser locale to fr-CA
const context = await browser.newContext({ locale: 'fr-CA' });
const page = await context.newPage();
// Assert: error messages, button labels, etc. are in French
// This requires your i18n keys to be tested — see SEMANTICS.md for the keys
8.3 Stock Management — Upgraded
Oversell prevention via Firestore atomic transaction:
The current doc says "test concurrent purchase does not oversell" but gives no implementation guidance. Here's the precise adversarial pattern:
typescript
// ADVERSARIAL: Last-unit race condition
// Seed product with stock = 1
await writeDoc('products/race-product', { stock: 1, ...productData });

// Two buyers simultaneously try to purchase the last unit
const [result1, result2] = await Promise.allSettled([
  callOk('/createCheckoutSession', { productId: 'race-product', buyerId: 'buyer_a' }),
  callOk('/createCheckoutSession', { productId: 'race-product', buyerId: 'buyer_b' }),
]);

// Assert: exactly one succeeds, one fails with 'out_of_stock' error
const succeeded = [result1, result2].filter(r => r.status === 'fulfilled');
const failed = [result1, result2].filter(r => r.status === 'rejected');
expect(succeeded).toHaveLength(1);
expect(failed).toHaveLength(1);

// Assert: Firestore stock = 0, not -1
const product = await getDoc('products/race-product');
expect(product.stock).toBe(0);
Two alternative implementation strategies in Cloud Function (document for future devs):
Strategy A — Firestore Transaction (current likely approach):
python
@firestore.transactional
def reserve_stock(transaction, product_ref, quantity):
    snapshot = product_ref.get(transaction=transaction)
    current_stock = snapshot.get('stock')
    if current_stock < quantity:
        raise Exception('out_of_stock')
    transaction.update(product_ref, {'stock': current_stock - quantity})
Strategy B — FieldValue.increment with post-check (simpler but slightly less safe):
python
# Decrement first, then validate — simpler code but requires compensating transaction on failure
product_ref.update({'stock': firestore.Increment(-quantity)})
snapshot = product_ref.get()
if snapshot.get('stock') < 0:
    # Compensate: restore stock and abort
    product_ref.update({'stock': firestore.Increment(quantity)})
    raise Exception('out_of_stock')
Strategy A is preferred. Strategy B has a window where stock goes negative before correction.
Low stock warning — precise threshold test:
typescript
await writeDoc('products/low-stock-product', { stock: 4 }); // < 5 = low stock
// Assert: product detail shows low stock warning badge
await writeDoc('products/low-stock-product', { stock: 5 }); // = 5 = NOT low stock
// Assert: warning badge absent
8.4 Admin Security — Upgraded
What the current doc says (and what's wrong with it):
"Admin cannot bypass seller permission for other sellers' products — Use SELLER trying to update ADMIN's product (not vice versa — admin bypasses)"
This is partially correct but incomplete. There are actually three distinct permission checks to test:
Seller A trying to update Seller B's product → permission-denied (both at Firestore rules level and Cloud Function level)
Buyer trying to update any seller's product → permission-denied
Admin updating any product → allowed (admin bypasses seller restriction)
Unauthenticated request to any write endpoint → unauthenticated
Missing attack vectors:
IDOR (Insecure Direct Object Reference) — buyer guesses order ID of another buyer's order and tries to read it directly. Firestore rules must enforce buyerId == request.auth.uid. Test:
typescript
// Create order for user_a
await writeDoc('orders/private-order-123', { buyerId: 'user_a', ... });
// Login as user_b (admin account logged out, regular buyer logged in)
// Try to fetch the order directly
const response = await callOk('/getOrder', { orderId: 'private-order-123' });
// Assert: permission denied, order data not returned
Token forgery — client sends request with manually crafted custom claims { role: 'admin' }. Firebase Auth tokens are signed — this can't succeed. But test it anyway with a malformed bearer token. Assert: Cloud Function rejects with unauthenticated.
Admin action audit trail — every admin action (approve product, suspend seller, manual refund) must create an entry in admin_audit_log collection. Test: approve product → check audit log entry created with adminId, action, targetId, timestamp. Without this you have no forensic trail.
Rate limiting on auth endpoints — test that 10 rapid failed login attempts triggers a lockout or CAPTCHA. Firebase Auth has built-in rate limiting, but test that your app surfaces it correctly with a friendly error message rather than a generic failure.
Firestore rules tested without auth token (raw REST):
typescript
// APPROACH: Direct Firestore REST API call without Authorization header
const response = await fetch(
  `https://firestore.googleapis.com/v1/projects/orignagta-dev/databases/(default)/documents/orders/test-order`,
  { method: 'GET' } // no auth
);
expect(response.status).toBe(403); // must be denied
This is the most important test — it verifies your rules are actually deployed and working, not just passing locally in emulator.
8.5 New Business Rule: Platform Fee Integrity (missing entirely)
This is not in Section 8 but must be added. The platform fee (2.5% per seller) is Stripe Connect's application_fee_amount. A malicious actor could try to bypass this in several ways:
Direct Stripe API call — buyer calls Stripe directly with their own API key to create a PaymentIntent without your platform fee. Defense: all payment intents must be created server-side by Cloud Function only. Firestore rule prevents direct order creation by client.
Fee calculation rounding — $3.99 × 2.5% = $0.09975 → rounds to $0.10 CAD. Test that rounding is consistent and always in platform's favor (ceiling), not against it.
Multi-seller cart fee — 2 sellers, seller_1 subtotal $50 (fee $1.25), seller_2 subtotal $30 (fee $0.75). Total platform fee = $2.00. Test Stripe Connect transfer_group correctly attributes per-seller fees.
Quick Reference: What to add to INSTRUCTIONS.md
Here's the priority order for implementation:
Priority	Gap	Why
🔴 P0	Stock race condition test	Revenue loss, oversell = legal/customer issue
🔴 P0	Price tampering via route interception	Direct financial attack
🔴 P0	Stripe webhook idempotency	Double payout risk
🔴 P0	IDOR on orders/addresses	Privacy breach, Canadian PIPEDA violation
🟡 P1	Return window clock injection	Complex to get right, page.clock is the right tool
🟡 P1	Coupon race condition	Minor revenue loss but reputation damage
🟡 P1	Chat markRead + unread count	Core UX, currently untested
🟡 P1	Tax per-province	Legal compliance, CRA audit risk
🟢 P2	Admin audit log	Forensics/compliance
🟢 P2	Digital product license race	Rare but possible
🟢 P2	Seller metrics zero-state	UX polish
New utility to add to api-helpers.ts
Add this — it's missing and will be used by the adversarial tests above:
typescript
/**
 * Simulate concurrent calls to test race conditions and idempotency.
 * Returns [successes, failures] counts.
 */
export async function simulateConcurrent(
  fn: () => Promise<unknown>,
  concurrency: number
): Promise<{ succeeded: number; failed: number; errors: string[] }> {
  const results = await Promise.allSettled(
    Array.from({ length: concurrency }, fn)
  );
  const succeeded = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected').length;
  const errors = results
    .filter((r): r is PromiseRejectedResult => r.status === 'rejected')
    .map(r => r.reason?.message ?? String(r.reason));
  return { succeeded, failed, errors };
}

/**
 * Poll Firestore until condition is true (eventual consistency helper).
 * Drop-in for expect.poll when you need the raw value.
 */
export async function pollDoc<T>(
  path: string,
  condition: (data: T) => boolean,
  { timeout = 10000, interval = 500 } = {}
): Promise<T> {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const data = await getDoc(path) as T;
    if (condition(data)) return data;
    await new Promise(r => setTimeout(r, interval));
  }
  throw new Error(`pollDoc timeout: condition not met for ${path}`);
}
Bottom line: The existing INSTRUCTIONS.md covers happy paths well. What it's missing is the entire adversarial layer — race conditions, IDOR, tampered payloads, replay attacks, return fraud patterns, and Canadian tax compliance specifics. Those gaps are P0/P1 for a marketplace handling real money under Canadian law.
