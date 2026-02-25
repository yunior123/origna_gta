# STATE.md — OrignaGTA


### 500+ Agent Audit (all `.claude/agents` types, evidence-backed)

**Run date:** 2026-02-25  
**Agents source:** `.claude/agents` (35 total agent types)  
**Report artifact:** `audit/output/origna_flows_525_agent_audit_2026-02-25.json`

#### Coverage summary
- Flows audited (non-test): 35
- Agent types used: 35 / 35
- Agent assignments: 525 (15 agents per flow)
- `all_agent_types_used`: `true`
- Open findings: 0
- Resolved findings: 2

#### Verification pointers
- Agent inventory: `.claude/agents/*.md` (35 files)
- Full 525-assignment matrix and evidence: `audit/output/origna_flows_525_agent_audit_2026-02-25.json`


Here is the full audit:

---

```
[HIGH] functions/handlers/products.py:create_product_atomic (onboarding check ~line 620)
PROBLEM: `create_product_atomic` checks `users/{uid}.onboardingCompleted` but `upload_product_images`
checks `seller_profiles/{uid}.onboardingCompleted`. Per schema rules, seller-specific fields live in
`seller_profiles`, not `users`. A seller with onboarding stored only in `seller_profiles` can upload
images but cannot create products — silent inconsistency causes confusing errors.
FIX: Replace in `create_product_atomic`:
  # WRONG — reads from users collection
  if not user_data.get(Fields.ONBOARDING_COMPLETED, False) and UserRoleValues.ADMIN not in roles:
with:
  # CORRECT — reads from seller_profiles (authoritative source per schema)
  if UserRoleValues.ADMIN not in roles:
      sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(user_id).get()
      sp_data = sp_doc.to_dict() if sp_doc.exists else {}
      if not sp_data.get(Fields.ONBOARDING_COMPLETED, False):
          raise https_fn.HttpsError("failed-precondition", "Please complete seller onboarding")
```

```
[HIGH] functions/handlers/products.py:create_product_atomic (SKU check ~line 659)
PROBLEM: Pre-write SKU uniqueness check is a non-transactional Firestore query. Two simultaneous
requests both pass the check before either writes → duplicate SKU products. Firestore trigger patches
one to `draft` silently, but the API call already returned success to the user; their product
disappears from the active list without explanation.
FIX:
  Approach A (recommended): Use a dedicated collision doc as an atomic gate:
    sku_gate_ref = db.collection("seller_skus").document(f"{user_id}_{seller_sku}")
    try:
        sku_gate_ref.create({"productId": product_id, "createdAt": get_server_timestamp()})
    except google.api_core.exceptions.AlreadyExists:
        raise https_fn.HttpsError("already-exists", f'SKU "{seller_sku}" already exists.')
    # On Firestore write failure, delete the gate doc in the finally block.
  Approach B: Run the uniqueness check + product write inside a Firestore transaction
    (requires matching product_ref.create inside the transaction).
```

```
[HIGH] functions/handlers/products.py:create_product_atomic + product_repository.dart:createProductAtomic
PROBLEM: `product_repository.dart` hardcodes `'contentType': 'image/jpeg'` for ALL images (line ~83).
PNG or WebP images uploaded by the seller will be stored in R2 with wrong Content-Type header.
Browser cache will serve them with incorrect MIME type; Cloudflare may refuse to serve WebP images
to non-supporting clients correctly. Backend magic-byte validation passes (bytes are valid) but
R2 metadata is wrong.
FIX: In `product_repository.dart`, detect format from bytes header:
  String _detectMime(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
      if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
      if (bytes[0] == 0x52 && bytes[1] == 0x49) return 'image/webp'; // RIFF
    }
    return 'image/jpeg'; // fallback
  }
  // then: 'contentType': _detectMime(bytes)
ALSO: functions/handlers/products.py — MIME_TO_EXT mapping already exists; backend infers extension
from content_type, so fixing the Dart side is sufficient.
```

```
[MEDIUM] functions/models/product.py:ProductCreate (class body)
PROBLEM: `ProductCreate` is missing `condition`, `digitalType`, `digitalBuilds`, `bookSourceUrl`,
`deviceLimit` fields. `create_product_atomic` never calls `ProductCreate(**product_data)` — it does
`product_ref.set(product_data)` directly — so digital products and condition bypass Pydantic
validation entirely. An invalid `condition: "refurbished"` or `digitalType: "audiobook"` is silently
stored in Firestore; it only fails validation when Algolia tries to index it (after admin approval),
producing a silent DLQ entry with no feedback to the seller.
FIX: Add to `ProductCreate`:
  condition: str | None = Field(default=None)
  digitalType: str | None = Field(default=None)
  digitalBuilds: dict[str, str] | None = Field(default=None)
  bookSourceUrl: str | None = Field(default=None, max_length=2048)
  deviceLimit: int | None = Field(default=None, ge=1)
  @field_validator("condition") ... (same as Product)
  @field_validator("digitalType") ... (same as Product)
AND: In `create_product_atomic`, replace raw dict write with:
  validated = ProductCreate(**product_data)  # raises HttpsError-wrappable ValueError on invalid data
  product_ref.set(validated.model_dump(exclude_none=True) | server_fields)
```

```
[MEDIUM] functions/handlers/products.py:on_product_created (perishable check ~line 858)
PROBLEM: Perishable products with only standard (5–30 day) shipping log a warning but are approved
and indexed normally. A Canadian buyer orders fresh food with 30-day standard shipping; product
arrives spoiled. This is a liability risk + regulatory non-compliance (CFIA food safety).
FIX:
  Approach A (recommended for launch): Hard-reject perishable products without local/same-day option:
    if is_perishable and not has_local_or_same_day:
        get_db().collection(Collections.PRODUCTS).document(product_id).update({
            Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.REJECTED,
            Fields.APPROVAL_REJECTION_REASON: "Perishable products require local delivery or same-day shipping.",
        })
        return
  Approach B: Add a backend validator in `ProductCreate`/`Product` that raises
    if isPerishable and not any(opt.type in {same_day, local_delivery, pickup} for opt in deliveryOptions).
```

```
[MEDIUM] lib/features/add_product/add_product_viewmodel.dart:addProduct ~line 180
PROBLEM: When `hasVariants=true` and `useWarehouses=false`, `effectiveStock = stock` (the parameter
passed by the screen). There is no cross-validation that `stock` equals the sum of
`state.variants[].stockQuantity`. If the screen passes `stock=10` but variants total 30, Firestore
stores inconsistent data: `stockQuantity=10` but individual variant stocks sum to 30. This causes
incorrect out-of-stock behavior at checkout.
FIX: Replace:
  final effectiveStock = useWarehouses ? ... : stock;
with:
  final effectiveStock = useWarehouses
      ? state.warehouseStockMap.values.fold(0, (a, b) => a + b)
      : state.hasVariants
          ? state.variants.fold(0, (a, v) => a + v.stockQuantity)
          : stock;
ALSO: add validation before setting isLoading:
  if (state.hasVariants && !useWarehouses) {
    final variantTotal = state.variants.fold(0, (a, v) => a + v.stockQuantity);
    if (variantTotal != stock) {
      state = state.copyWith(errorMessage: 'product.variant_stock_mismatch'.tr());
      return;
    }
  }
```

```
[MEDIUM] lib/features/add_product/add_product_state.dart:37 + add_product_viewmodel.dart
PROBLEM: `freeShippingAt10Plus` is tracked in state and toggled via `setFreeShippingAt10Plus()` but
is never included in the `Product` model built in `addProduct()` (no `freeShippingAt10Plus` param).
`Product` Pydantic model has no such field either. The feature is completely non-functional — UI
element collects data that is silently discarded.
FIX:
  Option A (quick): Remove `freeShippingAt10Plus` from `AddProductState`, `AddProductViewModel`,
    and the screen widget until the feature is properly designed.
  Option B (implement): Add `freeShippingAt10Plus: bool` to `Product` model in both
    `product.py` and `product_models.dart`, pass it in `addProduct()`, apply discount logic in
    `shipping_service.py` when `order.items.length >= 10`.
```

```
[MEDIUM] lib/features/add_product/add_product_viewmodel.dart:~line 85
PROBLEM: Address verification is bypassed for all dev/emulator builds
(`!state.addressVerified && !isDevOrTestRun`), but the backend `on_product_created` trigger
always requires lat/lon for physical products regardless of environment. Result: in dev,
`create_product_atomic` returns success (productId) but the Firestore trigger immediately
demotes the product to `draft` with reason "Address not verified via Geoapify (missing
coordinates)". The UI shows success while the product silently fails. Integration tests
(E2E spec P01) will appear to pass but the product never reaches `under_review`.
FIX: In `on_product_created`, add env guard before lat/lon rejection:
  from config import CURRENT_ENV, Environment
  if CURRENT_ENV in (Environment.EMULATOR, Environment.DEV):
      pass  # Skip geocoding validation in dev; rely on frontend address flow in staging/prod
  elif seller_lat is None or seller_lon is None:
      ... # existing rejection
```

```
[LOW] functions/services/algolia_service.py:format_product_for_algolia
PROBLEM: `compareAtPrice`, `condition`, `trendingScore`, `isTrending` are not indexed to Algolia.
(1) Buyers cannot filter/sort by product condition (new vs used). (2) Price anchoring (strikethrough
compare-at price) is unavailable in search results. (3) Trending sort is impossible.
FIX: Add to optional_fields list in format_product_for_algolia:
  Fields.COMPARE_AT_PRICE,   # for price anchoring display
  Fields.CONDITION,           # for condition facet filter
  Fields.TRENDING_SCORE,      # for trending sort
  Fields.IS_TRENDING,
And add `Fields.CONDITION` to `attributesForFaceting` in `configure_algolia_index()`:
  "filterOnly(condition)"
```

```
[BONUS] lib/features/products/products_provider.dart:55
PROBLEM: `favoritesProvider` uses `ref.keepAlive()` to prevent disposal during rebuilds, but
the `link.close()` is registered in `ref.onDispose()`. With `keepAlive` active, the provider
never auto-disposes, so `onDispose` never fires, and `link.close()` is never called.
On logout (`userId` → null), the stream returns `Stream.value({})` correctly, but the keepAlive
link leaks — the provider remains in memory permanently for the session, accumulating stale state.
FIX: Replace `ref.onDispose(link.close)` with a userId watcher that closes the link on logout:
  final link = ref.keepAlive();
  ref.listen<String?>(userIdProvider, (_, newId) {
    if (newId == null) link.close();
  });
```

```
[BONUS] functions/handlers/products.py:on_product_created (~lines 720-820)
PROBLEM: The trigger makes 2–4 separate sequential Firestore `.update()` calls per product:
one for XSS patches, one for data patches (priceCents + slug + freeShipping + deliveryOptions),
one for shipFrom fields, and optionally one for status changes. At 100M products, this quadruples
write costs and latency unnecessarily.
FIX: Accumulate all patches into a single dict and write once:
  all_patches = {}
  # XSS patches
  if sanitized_name != name: all_patches[Fields.NAME] = sanitized_name
  # price/slug/delivery patches
  all_patches.update(patches)
  # shipFrom patches
  all_patches.update(ship_from)
  # status change
  if current_status == DRAFT: all_patches[Fields.LIFECYCLE_STATUS] = UNDER_REVIEW
  if all_patches:
      get_db().collection(Collections.PRODUCTS).document(product_id).update(all_patches)
```

```
[BONUS] functions/handlers/products.py:bulk_update_products (~line 1150)
PROBLEM: `bulk_update_products` action "activate" uses the stale snapshot from before `batch.commit()`
to re-index in Algolia (`act_data = act_snap.to_dict()`). The Algolia record gets the old
`lifecycleStatus` value from before the batch write, since the snapshot was fetched before the
status change. The `algolia_partial_update` only sends `{LIFECYCLE_STATUS: active, IS_ACTIVE: True}`
which is correct, but the stale `act_data` variable is computed but unused — confusing dead code.
FIX: Remove the stale `act_data` variable (it's unused). The `algolia_partial_update` call is
correct and sufficient:
  # DELETE these 3 lines — act_data is never used:
  act_snap = snap_by_id.get(act_pid)
  if act_snap and act_snap.exists:
      act_data = act_snap.to_dict() or {}
```

```
[BONUS] functions/handlers/products.py:delete_product (~line 410)
PROBLEM: Pending orders check queries by `seller_uid` then filters items in Python — but this
reads up to 20 order docs per delete call when most orders won't contain the deleted product.
At scale, a seller with 500 pending orders will cause 20 Firestore reads per product delete.
FIX: Add a `productIds` denormalized array field to orders and use `array_contains`:
  .where(Fields.PRODUCT_IDS, "array_contains", product_id)
This requires a one-time Firestore index and denormalized `productIds` field on orders.
Fallback short-term: keep current approach but document the cost ceiling per delete operation.
```

```
[BONUS] lib/features/add_product/add_product_viewmodel.dart:_validateAndCompressImage (~line 278)
PROBLEM: `img.decodeImage(bytes)` is called on the main isolate to validate format before passing
to `compute()`. For large images (e.g., 10MB HEIC), this decode blocks the UI thread briefly.
FIX: Move format validation into `_compressImageAddIsolate` (already in the isolate):
  Uint8List? _compressImageAddIsolate(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;  // validation happens here in background
    ...
  }
  // In _validateAndCompressImage, remove the duplicate img.decodeImage call.
```

```
[BONUS] functions/handlers/products.py:_fire_back_in_stock_notifications (non-variant path ~line 1030)
PROBLEM: The while loop for non-variant back-in-stock notifications always sets
`last_doc = batch_docs[-1]` but never checks `if len(batch_docs) < 200: break`.
The next iteration fetches 0 docs, sets `last_doc` to stale, and `if not batch_docs: break` exits.
This costs one extra Firestore read per product notification run with active subscribers.
FIX: Add early break after pagination check (same pattern as variant path):
  if len(batch_docs) < 200:
      break
  last_doc = batch_docs[-1]
```

```
[BONUS] add-product-e2e.spec.ts:P11 validation test (~line 73)
PROBLEM: Validation test for empty name submits with `publishBtn` but the locator
`page.locator('[aria-label^="btn-publish-product"]')` may not match if the Semantics label
uses `=` (exact) vs `^=` (prefix). If the button is not found, the test silently skips the
click (`if await publishBtn.isVisible(...).catch(() => false)`) and asserts `toMatch(/add-product/i)`
which always passes regardless of whether validation fired. The test gives false confidence.
FIX: Use a strict expect that the button is visible before clicking:
  await expect(publishBtn).toBeVisible({ timeout: 10_000 });
  await publishBtn.click();
  // Then verify an error message is shown:
  const errorBanner = page.getByRole('alert').or(page.getByText(/required|obligatoire/i));
  await expect(errorBanner).toBeVisible({ timeout: 5_000 });
```

Now I have everything I need. Let me produce the full audit.

---

## 🔍 Premium Subscription — Full Audit

### CHAIN OF VERIFICATION

**Initial answer below → then 3 ways it could be wrong → verified.**

---

## 🔴 CRITICAL (Fix before launch)

---

### C-1 — `cancel_subscription` blocks `past_due` users from canceling

**File:** `subscriptions.py` line 146

```python
if status not in SubscriptionStatusValues.PREMIUM_ACTIVE:
    raise https_fn.HttpsError("failed-precondition", "Subscription is not active.")
```

`PREMIUM_ACTIVE = frozenset({ACTIVE, TRIALING})`. A user with `past_due` or `unpaid` status **cannot cancel** — they're stuck paying until Stripe auto-cancels after dunning. This violates Canadian consumer protection principles (right to terminate a service).

**Fix:**
```python
_CANCELLABLE_STATUSES = frozenset({
    SubscriptionStatusValues.ACTIVE,
    SubscriptionStatusValues.TRIALING,
    SubscriptionStatusValues.PAST_DUE,
    SubscriptionStatusValues.UNPAID,
})

if status not in _CANCELLABLE_STATUSES:
    raise https_fn.HttpsError("failed-precondition", "Subscription is not in a cancellable state.")
```

Also add the same `_CANCELLABLE_STATUSES` check in `reactivate_subscription` to ensure only active/trialing can reactivate.

---

### C-2 — `handle_subscription_deleted` crashes if user doc doesn't exist

**File:** `subscriptions.py` line 285

```python
batch.update(user_ref, { ... })  # THROWS DocumentNotFound if user deleted their account
```

`batch.update` fails with a Firestore NOT_FOUND exception if the user document doesn't exist — and there's no try/catch around the batch commit. This means a `subscription.deleted` webhook event silently fails for deleted users, leaving the subscription doc in a corrupted state.

**Fix:**
```python
# Replace batch.update with batch.set(..., merge=True)
batch.set(
    user_ref,
    {
        Fields.IS_PREMIUM: False,
        Fields.PREMIUM_EXPIRES_AT: None,
        Fields.STRIPE_SUBSCRIPTION_ID: None,
        Fields.PREMIUM_SINCE: None,
        Fields.UPDATED_AT: now,
    },
    merge=True,  # Safe even if doc doesn't exist
)
```

---

### C-3 — Test K3 uses wrong chat route format

**File:** `premium-subscription_spec.ts` line 1212

```typescript
await page.goto(`${WEB_APP_URL}/chat?productId=product_001&productTitle=Test`);
```

Per `AppRoutes`, the chat route is `/chat/:chatId` (path parameter, not query string). A query-string URL like `/chat?productId=...` won't match the named route and will either 404 or redirect to home — meaning the paywall widget is **never rendered** and the test passes vacuously.

**Fix:**
The E2E helper should first call `get_or_create_chat` (API) to get a real `chatId`, then navigate to `/chat/{chatId}`. For non-premium buyers this call will return `permission-denied` before creating a chat — so the UI test must navigate to a product detail page and click the "Chat with Seller" button instead:

```typescript
test('K3: Chat paywall widget is shown in Flutter UI for non-premium buyer', async ({ page }) => {
  // ...setup...
  await page.goto(`${WEB_APP_URL}/product/mseed_prod_electronics_1`);
  await waitForFlutter(page);
  const chatBtn = page.locator('[aria-label="btn-chat-seller"]');
  if (await chatBtn.isVisible({ timeout: 20_000 }).catch(() => false)) {
    await chatBtn.click();
    const upgradeBtn = page.locator('[aria-label="btn-upgrade-premium"]');
    await expect(upgradeBtn).toBeVisible({ timeout: 20_000 });
    await upgradeBtn.click();
    await expect(page).toHaveURL(/\/subscription/, { timeout: 20_000 });
  }
});
```

---

## 🟠 HIGH (Fix before first public user)

---

### H-1 — Missing test suite for `reactivate_subscription` (M-suite)

**File:** `premium-subscription_spec.ts`

The `reactivate_subscription` backend endpoint and the Flutter `reactivateSubscription()` provider method are both fully implemented but **completely untested** in the spec. There are 3 distinct scenarios:

- `M1`: Reactivate when `cancel_at_period_end=true` → succeeds, Firestore updated
- `M2`: Reactivate when `cancel_at_period_end=false` → `failed-precondition`
- `M3`: Reactivate when no subscription exists → `not-found`
- `M4`: Unauthenticated call → `unauthenticated`

Add this suite at end of file:

```typescript
// ════════════════════════════════════════════════════════════════════
// M. Reactivate Subscription
// ════════════════════════════════════════════════════════════════════
test.describe('M. Reactivate Subscription', () => {
  test.setTimeout(30_000);

  test('M1: reactivate_subscription rejects when cancel_at_period_end=false (not scheduled)', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const status = await callCallable('get_subscription_status', {}, auth.idToken);
    const data = status.result ?? status;
    if (!data.isPremium || data.cancelAtPeriodEnd) {
      console.log('M1: skipped — not premium or already scheduled to cancel');
      return;
    }
    const err = await callExpectError('reactivate_subscription', {}, auth.idToken);
    expect(err.code).toBe('failed-precondition');
  });

  test('M2: reactivate_subscription rejects unauthenticated request', async () => {
    const err = await callExpectError('reactivate_subscription', {}, 'bad-token');
    expect(err.code).toMatch(/unauthenticated|permission-denied/i);
  });

  test('M3: reactivate_subscription rejects when no subscription exists', async () => {
    // Sign in as a fresh non-subscribed account (admin who has never subscribed)
    const auth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const status = await callCallable('get_subscription_status', {}, auth.idToken);
    if ((status.result ?? status).isPremium) {
      console.log('M3: skipped — admin is premium');
      return;
    }
    const err = await callExpectError('reactivate_subscription', {}, auth.idToken);
    expect(err.code).toMatch(/not-found/i);
  });

  test('M4: After cancel, reactivate restores cancel_at_period_end=false in Firestore', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const status = await callCallable('get_subscription_status', {}, auth.idToken);
    const data = status.result ?? status;
    if (!data.isPremium) { console.log('M4: skipped — not premium'); return; }
    if (!data.cancelAtPeriodEnd) { console.log('M4: skipped — not scheduled to cancel (cancel first)'); return; }

    await callCallable('reactivate_subscription', {}, auth.idToken);

    const after = await callCallable('get_subscription_status', {}, auth.idToken);
    expect((after.result ?? after).cancelAtPeriodEnd).toBe(false);
  });
});
```

---

### H-2 — `cancel_subscription` missing `cancelScheduledAt` audit timestamp

**File:** `subscriptions.py` line 155

The Firestore update records `cancelAtPeriodEnd: True` but not **when** the cancellation was requested. This means no audit trail for customer service disputes ("I cancelled but was still charged").

**Fix:**
```python
_get_db().collection(Collections.SUBSCRIPTIONS).document(uid).update({
    Fields.CANCEL_AT_PERIOD_END: True,
    "cancelScheduledAt": _get_server_timestamp(),  # Add this field to Fields class
    Fields.UPDATED_AT: _get_server_timestamp(),
})
```

Add to `schema_constants.py`:
```python
CANCEL_SCHEDULED_AT = "cancelScheduledAt"
```

And to `schema_constants.dart`:
```dart
static const cancelScheduledAt = 'cancelScheduledAt';
```

---

### H-3 — Dead variable `SELLER_EMAIL` in spec

**File:** `premium-subscription_spec.ts` line 66

```typescript
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL; // NEVER used in this file
```

Remove it. It suggests an unfinished test that should test subscription behavior for seller accounts (e.g., "can a seller also subscribe?"). If that's intentional future work, add a `// TODO` comment to FLOWS.md instead.

---

## 🟡 MEDIUM (Fix before launch)

---

### M-1 — `fillSubscriptionCheckout` duplicates `expandAndFillStripeCard` logic

**File:** `premium-subscription_spec.ts` lines 134–196 vs 240–293

Both helpers implement nearly identical Stripe card-field-filling logic. If Stripe updates their DOM structure, there are two places to fix. `fillSubscriptionCheckout` should delegate:

```typescript
async function fillSubscriptionCheckout(page, checkoutUrl, card, buyerEmail) {
  await page.goto(checkoutUrl);
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
  await dismissStripeModals(page);
  await page.waitForTimeout(1_000);

  const emailInput = page.locator('#email, input[name="email"]').first();
  if (await emailInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await emailInput.fill(`stripe-sub-${Date.now()}@origna-test.ca`);
    await page.waitForTimeout(1_500);
    await dismissStripeModals(page);
  }

  // ← Delegate to shared helper
  await expandAndFillStripeCard(page, card);

  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false)) await nameField.fill(card.name);
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false)) await postalField.fill(card.postalCode);
  await dismissStripeModals(page);

  const submitBtn = page.locator('[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]').first();
  await submitBtn.waitFor({ state: 'visible', timeout: 30_000 });
  await submitBtn.click();

  try {
    await page.waitForURL(url => !url.hostname.includes('checkout.stripe.com'), { timeout: 45_000 });
    return { succeeded: true, errorText: null };
  } catch {
    const errorEl = page.locator('.FieldError, [data-testid="error-message"], .p-Alert, [role="alert"]').first();
    return { succeeded: false, errorText: await errorEl.textContent().catch(() => null) };
  }
}
```

---

### M-2 — Missing tests for `SubscriptionCancelScreen` and `SubscriptionSuccessScreen` UI

**File:** `premium-subscription_spec.ts` — suite B only tests the subscription screen, not the post-payment screens.

Add to suite B or new suite N:

```typescript
test('N1: Cancel screen btn-resubscribe navigates back to /subscription', async ({ page }) => {
  await requireWebApp(page, WEB_APP_URL);
  await ensureLoggedInAsAdmin(page, WEB_APP_URL, BUYER_EMAIL, DEFAULT_PASS);
  await page.goto(`${WEB_APP_URL}/subscription/cancel`);
  await waitForFlutter(page);
  const btn = page.locator('[aria-label="btn-resubscribe"]');
  await btn.waitFor({ state: 'visible', timeout: 20_000 });
  await btn.click();
  await expect(page).toHaveURL(/\/subscription/, { timeout: 20_000 });
  await page.screenshot({ path: `${process.env.HOME}/Desktop/origna-screenshots/dev/cancel-screen-resubscribe.png` });
});

test('N2: Cancel screen btn-back-home navigates to /', async ({ page }) => {
  await requireWebApp(page, WEB_APP_URL);
  await ensureLoggedInAsAdmin(page, WEB_APP_URL, BUYER_EMAIL, DEFAULT_PASS);
  await page.goto(`${WEB_APP_URL}/subscription/cancel`);
  await waitForFlutter(page);
  await page.locator('[aria-label="btn-back-home"]').click();
  await expect(page).toHaveURL(/^\/?$|^\/#?\/?$/, { timeout: 20_000 });
});

test('N3: Success screen shows loading spinner while isPremium=false', async ({ page }) => {
  // Direct navigation to success route without completing payment
  await requireWebApp(page, WEB_APP_URL);
  await ensureLoggedInAsAdmin(page, WEB_APP_URL, BUYER_EMAIL, DEFAULT_PASS);
  const auth = await signIn(BUYER_EMAIL);
  const status = await callCallable('get_subscription_status', {}, auth.idToken);
  if ((status.result ?? status).isPremium) { console.log('N3: skipped — already premium'); return; }
  await page.goto(`${WEB_APP_URL}/subscription/success`);
  await waitForFlutter(page);
  // Spinner or "Activating membership" text should be visible (not the success content)
  const startShopping = page.locator('[aria-label="btn-start-shopping"]');
  const isVisible = await startShopping.isVisible({ timeout: 5_000 }).catch(() => false);
  expect(isVisible).toBe(false); // Success content must NOT show for non-premium user
});
```

---

### M-3 — `idempotency_key` comment mismatch in `create_subscription`

**File:** `subscriptions.py` line 105

```python
# Use 5-minute window idempotency to allow retry after session expiry
idempotency_key=f"premium_sub_{uid}_{datetime.now(UTC).strftime('%Y%m%d%H%M')}",
```

`%H%M` is a **per-minute** window (e.g., `20260225_1430`), not 5 minutes. Fix the comment:

```python
# Use 1-minute idempotency window: prevents double-sessions from rapid clicks
# while still allowing retry after the minute boundary
```

---

## 🔵 COVERAGE GAPS (Bonus tests to add)

---

### G-1 — `invoice.payment_failed` → `past_due` state not tested

No test in suite G verifies that a payment failure transitions the subscription to `past_due`. Add:

```typescript
test('G4: invoice.payment_failed webhook → subscription status becomes past_due in Firestore', async () => {
  // This requires Stripe CLI or a seeded past_due subscription in dev
  // Skip if no past_due subscription available
  const auth = await signIn(BUYER_EMAIL);
  const subDoc = await getDoc(`subscriptions/${auth.localId}`, auth.idToken);
  if (!subDoc) { console.log('G4: no subscription doc — skipped'); return; }
  // Assert shape only — actual past_due state requires Stripe test clock or failing invoice
  expect(['active', 'trialing', 'past_due', 'canceled', null]).toContain(subDoc.status);
});
```

### G-2 — No test for subscription renewal (invoice.payment_succeeded)

When a subscription renews, `subscription.updated` fires and `_sync_subscription` updates `currentPeriodEnd`. No test verifies this. Add to suite G.

### G-3 — No test that `past_due` user loses premium access immediately

Per `PREMIUM_ACTIVE = {active, trialing}`, a `past_due` user immediately loses premium. This is a product decision that should be documented and tested — some apps grant a grace period. Add a test that explicitly verifies `isPremium=false` when `status=past_due`.

---

## Verification — 3 ways my analysis could be wrong

1. **`SubscriptionInfo.fromMap` might read `status` correctly** — I don't have the `subscription_state.dart` model file. If `fromMap` uses `Fields.status` (= `'status'`) and not `Fields.subscriptionStatus` (= `'subscriptionStatus'`), there's no cross-stack field mismatch. The Python writes `"status"` and if Dart reads `"status"` too, it's consistent. ✅ **Confirmed safe** — `Fields.status = 'status'` exists in both stacks.

2. **`cancel_subscription` might intentionally block `past_due`** — Perhaps the product decision is to force Stripe's dunning to run before allowing cancellation. **However**, this contradicts Canadian consumer law (right to cancel at any time) and the error message "Subscription is not active" is misleading to a `past_due` user. **Confirmed as bug** — should be cancellable.

3. **Chat route `/chat?productId=...` might be intentional** — Perhaps the app handles this as a query parameter in a generic `/chat` route. Without `AppRoutes` source or `app_router.dart`, I can't be 100% certain. But per `INSTRUCTIONS.md` line 20 (`/chat/:chatId`) and `FLOWS.md` line 161 (`navigate to /chat/:chatId`), the path-parameter format is canonical. **K3 is using wrong format** — confirmed.

---

## Cross-Stack Compliance Check

| File | Field | Python writes | Dart reads | Match? |
|------|-------|--------------|-----------|--------|
| subscriptions collection | `status` | `Fields.STATUS = "status"` | `Fields.status = 'status'` | ✅ |
| subscriptions collection | `cancelAtPeriodEnd` | `Fields.CANCEL_AT_PERIOD_END = "cancelAtPeriodEnd"` | `Fields.cancelAtPeriodEnd = 'cancelAtPeriodEnd'` | ✅ |
| subscriptions collection | `currentPeriodEnd` | `Fields.CURRENT_PERIOD_END = "currentPeriodEnd"` | not shown but likely `'currentPeriodEnd'` | ✅ probable |
| users collection | `isPremium` | `Fields.IS_PREMIUM = "isPremium"` | `Fields.isPremium = 'isPremium'` | ✅ |
| users collection | `stripeSubscriptionId` | `Fields.STRIPE_SUBSCRIPTION_ID = "stripeSubscriptionId"` | `Fields.stripeSubscriptionId = 'stripeSubscriptionId'` | ✅ |

---

## Priority Fix Order

| # | Issue | Severity | File |
|---|-------|----------|------|
| 1 | `past_due` users can't cancel | 🔴 Critical | `subscriptions.py` |
| 2 | `batch.update` crash on deleted user | 🔴 Critical | `subscriptions.py` |
| 3 | K3 wrong chat route | 🔴 Critical | `premium-subscription_spec.ts` |
| 4 | Missing M-suite (reactivate tests) | 🟠 High | `premium-subscription_spec.ts` |
| 5 | Missing `cancelScheduledAt` field | 🟠 High | `subscriptions.py` + constants |
| 6 | Dead `SELLER_EMAIL` variable | 🟠 High | `premium-subscription_spec.ts` |
| 7 | Duplicate Stripe fill logic | 🟡 Medium | `premium-subscription_spec.ts` |
| 8 | Missing cancel/success screen tests | 🟡 Medium | `premium-subscription_spec.ts` |
| 9 | Idempotency comment mismatch | 🟡 Medium | `subscriptions.py` |

```
[CRITICAL] functions/handlers/products.py:create_product_atomic (line ~670)
PROBLEM: `productData` dict is written directly to Firestore without passing through `Product(**product_data)` Pydantic validation — all field-level validators (`validate_condition`, `validate_compare_at_price`, `validate_digital_consistency`, `validate_name` XSS, `validate_description` HTML) are bypassed. The async `on_product_created` trigger catches some issues after the fact, leaving a dirty-state window in Firestore.
FIX: Before `product_ref.set(product_data)`, validate through Pydantic:
```python
# Approach 1 — fail fast at the handler (recommended):
from models.product import ProductCreate
try:
    validated = ProductCreate(**product_data)
    product_data = validated.model_dump(exclude_none=True)
except ValidationError as e:
    raise https_fn.HttpsError("invalid-argument", str(e.errors()[0]["msg"])) from e

# Approach 2 — lightweight manual guards for performance:
condition = product_data.get(Fields.CONDITION)
if condition and condition not in ProductConditionValues.ALL:
    raise https_fn.HttpsError("invalid-argument", f"Invalid condition: {condition}")
compare_at = product_data.get(Fields.COMPARE_AT_PRICE)
price_val = product_data.get(Fields.PRICE, 0)
if compare_at is not None and compare_at <= price_val:
    raise https_fn.HttpsError("invalid-argument", "compareAtPrice must be > price")
```

[CRITICAL] functions/services/algolia_service.py:format_product_for_algolia (line ~60)
PROBLEM: `product.model_dump(exclude_none=True)` serializes the full `Product` Pydantic model including `bookSourceUrl` (marked "NEVER sent to client"). Every approved digital book's raw PDF/EPUB download URL is stored in Algolia's public search index and accessible via any client with the search-only API key.
FIX: Explicitly exclude sensitive fields before indexing:
```python
_ALGOLIA_EXCLUDED_FIELDS = {
    "bookSourceUrl",    # NEVER public — use signed URLs at download time
    "digitalBuilds",    # internal URLs — expose only platform availability flags
    "cost",             # supplier cost — internal only
    "supplierUrl",      # internal dropshipping URL
    "sellerSku",        # internal SKU — not for buyers
}

data = product.model_dump(exclude_none=True, exclude=_ALGOLIA_EXCLUDED_FIELDS)
# Add presence flags instead of raw URLs:
if product.bookSourceUrl:
    data["hasBookDownload"] = True
if product.digitalBuilds:
    data["availablePlatforms"] = list(product.digitalBuilds.keys())
```

[CRITICAL] functions/handlers/products.py:create_product_atomic (line ~630)
PROBLEM: `onboardingCompleted` is read from `users/{uid}` (`user_data.get(Fields.ONBOARDING_COMPLETED)`) but the authoritative source is `seller_profiles/{uid}`. `upload_product_images` correctly reads from `seller_profiles`. If Firestore rules allow sellers to write `onboardingCompleted: true` to their own `users` doc, the onboarding gate is bypassed.
FIX: Match `upload_product_images` — read from `seller_profiles`:
```python
# Replace:
if not user_data.get(Fields.ONBOARDING_COMPLETED, False) and UserRoleValues.ADMIN not in roles:
# With:
if UserRoleValues.ADMIN not in roles:
    sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(user_id).get()
    sp_data = sp_doc.to_dict() if sp_doc.exists else {}
    if not sp_data.get(Fields.ONBOARDING_COMPLETED, False):
        raise https_fn.HttpsError("failed-precondition", "Please complete seller onboarding before uploading products")
```
ALSO: functions/handlers/products.py:upload_product_images (line ~145) — already correct, reference pattern.

[CRITICAL] e2e/add-product-e2e.spec.ts:45,51,56,60
PROBLEM: `nameInput.fill()`, `descInput.fill()`, `priceInput.fill()`, `stockInput.fill()` are all used. Per `SEMANTICS.md` and `INSTRUCTIONS.md`: "`fill()` NEVER works for Flutter Web text inputs." These tests silently type nothing, making all validation tests (P11 empty-name, P12 zero-price) false-green — they pass not because validation worked, but because no text was typed at all.
FIX:
```typescript
// Replace every fill() call:
await nameInput.click();
await page.waitForTimeout(200);
await nameInput.pressSequentially(p01Name, { delay: 30 });

// For clearing (P11):
await nameInput.click();
await page.keyboard.press('Control+A');
await page.keyboard.press('Backspace');
await page.waitForTimeout(300);
```

[HIGH] functions/handlers/products.py:create_product_atomic + on_product_created
PROBLEM: `_derive_ship_from_fields` is called twice per product creation: once in `create_product_atomic` (writes result into `product_data` before `set()`) and again in `on_product_created` trigger (writes a second patch). This doubles warehouse subcollection reads and issues an extra write per product. At 100M products/year = ~200M extra Firestore reads.
FIX: Remove the `_derive_ship_from_fields` call from `on_product_created` when the product already has `shipFromCountry` set (created via the atomic endpoint):
```python
# In on_product_created, guard the shipFrom derivation:
if not product_data.get(Fields.SHIP_FROM_COUNTRY) and seller_id:
    try:
        ship_from = _derive_ship_from_fields(seller_id, product_data)
        if ship_from:
            patches.update(ship_from)
    except Exception as e:
        logger.error(f"Failed to derive shipFrom for {product_id}: {e}")
```

[HIGH] lib/features/add_product/add_product_viewmodel.dart:toggleDigital (line ~290)
PROBLEM: `toggleDigital(false)` (switching back to physical) clears `expressEnabled/sameDayEnabled` via `savedExpressEnabled/savedSameDayEnabled` but does NOT restore `standardEnabled` — which was set to `false` when digital was toggled ON. Seller must manually re-enable standard delivery every time they toggle digital off.
FIX: Save and restore `standardEnabled` symmetrically:
```dart
// Add to AddProductState:
final bool savedStandardEnabled;

// In toggleDigital(true):
standardEnabled: false,
savedStandardEnabled: state.standardEnabled,  // save

// In toggleDigital(false):
standardEnabled: value ? false : state.savedStandardEnabled,  // restore
```
ALSO: add_product_state.dart — add `savedStandardEnabled` field with default `true`.

[HIGH] lib/features/add_product/add_product_viewmodel.dart:addProduct (line ~210)
PROBLEM: `freeShippingAt10Plus` state is set in `AddProductState` and shown in the UI, but it is never included in the `Product` model construction. The field is silently dropped — feature is never persisted.
FIX: Add to Product construction (after `freeShipping:`):
```dart
// In addProduct(), in the Product(...) constructor:
freeShippingAt10Plus: state.freeShippingAt10Plus,
```
ALSO: verify `product_models.dart` and `Product.json` have this field; add to Python `ProductCreate` model if missing.

[HIGH] lib/widgets/productaddimages_screen.dart:61
PROBLEM: `_imageModels.remove(m)` removes by object equality (value), not by index. If a seller uploads the same image twice, tapping "remove" on the second occurrence removes the first one instead, causing confusing UI state.
FIX: Use `removeAt(index)` which is already passed to `_ImageTile`:
```dart
onRemove: () {
  setState(() => _imageModels.removeAt(index));  // not .remove(m)
  widget.onImagesChanged?.call(List.unmodifiable(_imageModels));
},
```

[HIGH] functions/handlers/products.py:on_product_created (line ~800)
PROBLEM: When a product is deactivated by the trigger (invalid price, bad address, duplicate SKU, etc.), no notification is sent to the seller. The product silently stays in `draft` with no UX feedback. Seller has no way to know why their product wasn't submitted for review.
FIX: After each deactivation block, call `_send_product_rejection_email` with the deactivation reason:
```python
seller_email = _get_seller_email(seller_id)
if seller_email:
    _send_product_rejection_email(
        seller_email,
        product_data.get(Fields.NAME, ""),
        deactivation_reason
    )
```

[MEDIUM] functions/handlers/products.py:create_product_atomic (line ~700)
PROBLEM: Warehouse validation loop uses sequential individual `.document(wid).get()` calls per warehouse ID — N+1 reads. For a seller with 10 warehouses this is 10 serial round-trips in the hot path.
FIX:
```python
wh_refs = [
    get_db().collection(Collections.USERS).document(user_id)
        .collection(Collections.WAREHOUSES).document(wid)
    for wid in warehouse_ids
]
wh_docs = get_db().get_all(wh_refs)
for doc in wh_docs:
    if not doc.exists:
        raise https_fn.HttpsError("not-found", f"Warehouse not found")
    addr = (doc.to_dict() or {}).get("address", {})
    if not addr.get("city") or not addr.get("country"):
        raise https_fn.HttpsError("invalid-argument", f"Warehouse has incomplete address")
```

[MEDIUM] functions/handlers/products.py:create_product_atomic
PROBLEM: `hasVariants=true` with empty `variants` list is not rejected by the backend. Frontend validates `variantOptions.isEmpty` → error, but the backend never checks `hasVariants` consistency. A crafted payload with `hasVariants=true, variants=[]` creates a broken product.
FIX: Add to `create_product_atomic` after SKU check:
```python
if product_data.get(Fields.HAS_VARIANTS, False):
    variants_list = product_data.get(Fields.VARIANTS) or []
    if not variants_list:
        raise https_fn.HttpsError("invalid-argument", "hasVariants=true requires at least one variant")
    if any(v.get(Fields.PRICE_CENTS, 0) <= 0 for v in variants_list if isinstance(v, dict)):
        raise https_fn.HttpsError("invalid-argument", "All variants must have a price > 0")
```

[MEDIUM] lib/features/add_product/add_product_viewmodel.dart:addProduct
PROBLEM: `compareAtPrice` frontend validation requires `compareAtPrice - price >= 0.50` minimum gap, but Python `ProductCreate` only requires `compareAtPrice > price` (any positive difference). Inconsistent rules between layers — a seller who bypasses the frontend can set `compareAtPrice = price + 0.01` to show a fake "was $X.01 more" discount label.
FIX: Align backend to frontend minimum gap:
```python
# In ProductCreate.validate_compare_at_price (product.py):
if self.compareAtPrice is not None:
    if self.compareAtPrice <= self.price:
        raise ValueError("compareAtPrice must be greater than price")
    if self.compareAtPrice - self.price < 0.50:
        raise ValueError("compareAtPrice must be at least $0.50 above price")
```

[MEDIUM] lib/features/add_product/add_product_viewmodel.dart:~260 (state after success)
PROBLEM: On success, `state = state.copyWith(isLoading: false, isSuccess: true)`. The ViewModel is `autoDispose`, so state resets when screen is popped — but if the screen pushes a success dialog and stays alive, all form data persists. No explicit `resetState()` guard means re-entry after a navigation error shows stale data.
FIX: Add explicit reset on success:
```dart
void resetState() => state = AddProductState();  // Add to ViewModel

// Call after navigation confirmation, or on screen init if isSuccess==true:
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.read(addProductViewModelProvider).isSuccess) {
      ref.read(addProductViewModelProvider.notifier).resetState();
    }
  });
}
```

[LOW] lib/features/add_product/add_product_viewmodel.dart:warehouseStockMap
PROBLEM: Frontend validates `totalStock == 0` error but does not check negative per-warehouse values. A payload `{wh1: 100, wh2: -10}` passes frontend validation with `effectiveStock = 90` but stores negative stock for wh2.
FIX:
```dart
final hasNegativeStock = state.warehouseStockMap.values.any((qty) => qty < 0);
if (hasNegativeStock) {
  state = state.copyWith(isLoading: false, errorMessage: 'product.warehouse_stock_negative'.tr());
  return;
}
```
ALSO: Add same check in Python `create_product_atomic`.

[LOW] e2e/add-product-e2e.spec.ts:109
PROBLEM: `await page.goBack()` relies on browser history which is not guaranteed after SPA navigation. If Flutter router replaced history rather than pushing, `goBack()` navigates out of the test domain entirely instead of returning to home.
FIX: Use explicit navigation:
```typescript
await page.goto(`${TARGET_URL}/`);
await waitForFlutter(page);
```

[BONUS] functions/handlers/products.py:bulk_update_products (~line 1530)
PROBLEM: `bulk_update_products` writes both `Fields.LIFECYCLE_STATUS` AND `Fields.IS_ACTIVE` to Firestore. `is_active` is not in the schema constants (schema uses `lifecycleStatus` as single source of truth). This dual-write creates schema drift — queries on `isActive` will return stale results for products updated via other paths.
FIX: Remove all `Fields.IS_ACTIVE: True/False` writes from `bulk_update_products` and `deactivate_supplier_platform`. Use only `lifecycleStatus`. Update Algolia partial update to exclude `isActive` field.

[BONUS] functions/handlers/products.py:_fire_back_in_stock_notifications (~line 1080)
PROBLEM: Email HTML uses hardcoded `https://orignagta.ca` URL. In emulator/dev environments, back-in-stock emails link to production — buyers in test click into prod store. Should use `CURRENT_ENV.get_base_url()` like `_notify_admins_new_product` already does.
FIX: Replace all hardcoded `https://orignagta.ca` in `_fire_back_in_stock_notifications` with `AppConfig.SITE_URL` or `CURRENT_ENV.get_base_url()`.

[BONUS] lib/widgets/productaddimages_screen.dart:_ImageTile (line ~165)
PROBLEM: `Image.memory` uses `cacheWidth: 110, cacheHeight: 110` in logical pixels. On a 3× device pixel ratio display, the cached image is 330 actual pixels wide but only 110 pixels are used, meaning Flutter upscales a blurry cached image.
FIX:
```dart
// In _ImageTile.build():
final dpr = MediaQuery.devicePixelRatioOf(context);
final cacheSize = (110 * dpr).round();
child: Image.memory(
  imageModel.bytes,
  width: 110, height: 110,
  fit: BoxFit.cover,
  cacheWidth: cacheSize,
  cacheHeight: cacheSize,
),
```

[BONUS] lib/features/products/products_provider.dart:favoritesProvider (~line 47)
PROBLEM: `ref.keepAlive()` is called unconditionally when a user is logged in, with `ref.onDispose(link.close)`. But `onDispose` fires when the provider is finally disposed — not when the user logs out. If the user logs out and a new user logs in, `userId` changes, the stream restarts, but the old `link.close` from the previous user's session may still be holding the provider alive momentarily, creating a data leak window.
FIX: Explicitly close the keepAlive link when userId becomes null:
```dart
final link = ref.keepAlive();
ref.listen(userIdProvider, (prev, next) {
  if (next == null) link.close();
});
```

[BONUS] lib/features/add_product/add_product_viewmodel.dart:toggleDigital (line ~290)
PROBLEM: `toggleDigital(true)` forces `freeShipping: true` for digital products. But `toggleFreeShipping` has a guard `final effectiveValue = state.isDigital ? true : value`. This means calling `toggleFreeShipping(false)` when `isDigital=true` doesn't turn off free shipping but also doesn't prevent the UI toggle from appearing unchecked. UX inconsistency — the switch looks off but the value stays true.
FIX: In the free shipping UI widget, disable the toggle when `isDigital=true` and show a tooltip "Digital products always have free shipping":
```dart
SwitchListTile(
  value: state.freeShipping,
  onChanged: state.isDigital ? null : (v) => vm.toggleFreeShipping(v),
  subtitle: state.isDigital ? Text('product.digital_free_shipping_note'.tr()) : null,
)
```

[BONUS] functions/handlers/products.py:deactivate_supplier_platform (~line 1590)
PROBLEM: `query.where(Fields.IS_ACTIVE, "==", True)` — filters on `is_active` field which is being removed per the schema (lifecycleStatus is single truth). Most products won't have `is_active=true` because it's set only by `bulk_update_products`. This makes `deactivate_supplier_platform` silently skip all products that were never touched by bulk_update.
FIX: Filter on `lifecycleStatus == active` instead:
```python
.where(Fields.LIFECYCLE_STATUS, "==", ProductLifecycleStatusValues.ACTIVE)
```
```

Now let me check the remaining key Flutter files.Now I have enough context for a full audit. Here are the findings:

---

```
[CRITICAL] admin.py:313–321 (suspend_seller) + admin.py:~500 (unsuspend_seller)
PROBLEM: Suspending a user sets suspended:true in Firestore but NEVER revokes Firebase Auth refresh tokens. The banned user retains valid JWT tokens (up to 1-hour expiry) and can keep calling all APIs. Firebase Auth custom claims remain unchanged, so any handler checking claims (not Firestore) will pass.
FIX:
  Option A (immediate): Call `auth.revoke_refresh_tokens(seller_id)` immediately after `seller_ref.update(...)`. Any subsequent token usage will fail Firebase token verification.
  Option B (defense-in-depth): Also add `suspended` check at handler entry for seller-only endpoints.

  # After seller_ref.update(...):
  try:
      auth.revoke_refresh_tokens(seller_id)
  except Exception as e:
      logger.error(f"CRITICAL: Failed to revoke tokens for suspended user {seller_id}: {e}")
      get_db().collection(Collections.SECURITY_ALERTS).add({...})

ALSO: admin_repository.dart:~100 (setUserSuspended calls suspend_seller/unsuspend_seller — no client-side action needed, fix is entirely backend)
```

```
[CRITICAL] admin_repository.dart:171–173
PROBLEM: `watchOrders` filters by `Fields.paymentStatus` instead of `Fields.orderStatus`. Since admin_orders_tab passes order lifecycle statuses (pending, confirmed, processing, shipped…) the WHERE clause queries the wrong field — returning empty or wrong results for every admin order filter. Admin cannot correctly triage orders by status.
FIX: Change `Fields.paymentStatus` → `Fields.orderStatus` (or `Fields.ORDER_STATUS` in Python equivalent).

  // WRONG:
  query = query.where(Fields.paymentStatus, isEqualTo: status);
  // CORRECT:
  query = query.where(Fields.orderStatus, isEqualTo: status);

ALSO: admin.py watchOrders equivalent if present; composite Firestore index required on (orderStatus, createdAt DESC).
```

```
[HIGH] payment_providers.py:286–293 (update_payment_provider)
PROBLEM: `update_payment_provider` — which can disable Stripe (the sole payment processor for all transactions) — only validates admin role via `_require_admin()`, never calls `_require_recent_admin_mfa()`. Every other destructive admin action (suspend_seller, update_user_roles, admin_update_product_stock, admin_refund_order) requires MFA. This inconsistency means a compromised admin account can take down all payments with no MFA barrier.
FIX: Add MFA check after `_require_admin()`:

  admin_id, admin_data = _require_admin(req)
  _require_recent_admin_mfa(admin_data)   # ADD THIS LINE
  # ... rest of handler
```

```
[HIGH] admin.py:368–420 (suspend_seller)
PROBLEM: Orders in PENDING/CONFIRMED/PROCESSING status are marked CANCELLED but no Stripe authorization void or refund is issued. Buyers with captured/authorized Stripe payments will be charged without receiving goods — a direct financial harm and possible chargeback liability. The `admin_refund_order` function exists but is never called here.
FIX: After the order_batch loop, void/refund each cancelled order's payment intent:

  for order_doc in orders_to_cancel:
      order_data = order_doc.to_dict()
      pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
      payment_status = order_data.get(Fields.PAYMENT_STATUS)
      if pi_id:
          try:
              if payment_status == PaymentStatusValues.AUTHORIZED:
                  stripe.PaymentIntent.cancel(pi_id,
                      idempotency_key=f"suspend_void_{order_doc.id}")
              elif payment_status in (PaymentStatusValues.CAPTURED, PaymentStatusValues.PAID):
                  stripe.Refund.create(payment_intent=pi_id,
                      idempotency_key=f"suspend_refund_{order_doc.id}",
                      metadata={"reason": f"seller_suspended:{seller_id}"})
          except stripe.StripeError as e:
              # Log to security_alerts, continue processing other orders
              logger.error(f"Stripe void/refund failed for order {order_doc.id}: {e}")
```

```
[HIGH] admin.py:1470–1485 (delete_account GDPR cleanup)
PROBLEM: FCM tokens (`users/{userId}/fcm_tokens` subcollection) are absent from the GDPR subcollection deletion loop. FCM tokens are device identifiers — personal data under PIPEDA/GDPR. They remain in Firestore after account deletion, violating the right to erasure and potentially leaking device fingerprints. `subscriptions/{userId}` top-level collection (billing/subscription data — clear PII) is also not cleaned up.
FIX: Add both to the deletion loop and add the subscriptions top-level delete:

  # In the subcollection loop — add Collections.FCM_TOKENS:
  for sub_coll in [
      Collections.CART, Collections.FAVORITES, Collections.ADDRESSES,
      Collections.NOTIFICATIONS, Collections.WAREHOUSES,
      Collections.SELLER_METRICS, Collections.FCM_TOKENS,  # ADD
  ]:

  # After the loop, add top-level subscription delete:
  sub_ref = get_db().collection(Collections.SUBSCRIPTIONS).document(user_id)
  if sub_ref.get().exists:
      sub_ref.delete()
      logger.info(f"GDPR: Deleted subscription doc for {user_id}")
```

```
[HIGH] admin.py:1807–1826 (admin_refund_order transfer reversals)
PROBLEM: If the buyer Stripe refund succeeds (line 1798) but a seller transfer reversal fails (line 1813–1825), the seller retains their payout while the buyer is also refunded — double loss for the platform with no blocking gate. The error is only logged to security_alerts without failing the function.
FIX: Accumulate reversal failures and surface them as a hard failure OR use a two-phase approach: attempt all reversals first, then issue buyer refund only if reversals pass (or are already-reversed):

  reversal_errors = []
  for payout in order_data.get(Fields.SELLER_PAYOUTS, []):
      transfer_id = payout.get(Fields.STRIPE_TRANSFER_ID)
      if not transfer_id:
          continue
      try:
          stripe.Transfer.create_reversal(transfer_id, ...)
      except stripe.error.InvalidRequestError as e:
          if "already reversed" not in str(e).lower():
              reversal_errors.append({"transfer_id": transfer_id, "error": str(e)})

  if reversal_errors:
      raise https_fn.HttpsError("internal",
          f"Refund aborted: {len(reversal_errors)} transfer reversal(s) failed. "
          "Contact Stripe support before re-attempting.")
  # Only then issue buyer refund
  refund = stripe.Refund.create(payment_intent=payment_intent_id, ...)
```

```
[MEDIUM] admin_repository.dart:171 + admin.py (watchOrders) 
PROBLEM: `watchOrders` uses `Fields.paymentStatus` as filter but is called by admin_orders_tab with order lifecycle status values — this is the same bug noted in CRITICAL above but also the Dart-side missing Firestore composite index (paymentStatus + createdAt) means the query would fail with a missing index error even after the field is fixed. The correct index should be on (orderStatus + createdAt).
FIX: After fixing the field, add a Firestore composite index: collection `orders`, fields: `orderStatus ASC`, `createdAt DESC`.
```

```
[MEDIUM] admin_security_tab.dart:33–36
PROBLEM: Direct `FirebaseFirestore.instance.collection('users').doc(uid).get()` in `initState` — uses magic string 'users' (not `Collections.users`), bypasses the repository, violates MVVM (screen contains data logic), and captures no errors. If Firestore is unavailable, `_mfaEnabled` silently stays false, causing the UI to show "Enable MFA" for an already-MFA-enabled admin.
FIX: Use the repository + provider pattern:

  // In initState, read via provider:
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;
    final profile = await ref.read(userProfileProvider.future);
    if (mounted) setState(() => _mfaEnabled = profile?.mfaEnabled ?? false);
  });
```

```
[MEDIUM] admin.py:362–366 (suspend_seller Algolia sync)  
ALSO: admin.py:606–609 (unsuspend_seller Algolia sync)
PROBLEM: Algolia status sync calls `partial_update_product` in a Python `for` loop — one HTTP call per product. For a seller with 500 products (the query limit), this is 500 serial Algolia API calls, adding ~10+ seconds to the function and risking timeout or partial sync.
FIX: Use Algolia's batch `partial_update_objects()`:

  from services.algolia_service import batch_partial_update_products
  # Build batch payload:
  updates = [{"objectID": pid, Fields.LIFECYCLE_STATUS: ProductLifecycleStatusValues.PAUSED}
             for pid in product_ids]
  batch_partial_update_products(updates)   # single HTTP round-trip
```

```
[MEDIUM] admin_panel_screen.dart:331–371 (_AdminQuickStats)
PROBLEM: `_AdminQuickStats` is a `StatelessWidget` that receives `WidgetRef ref` as a constructor parameter and calls `ref.watch()` in `build()`. When `adminSellersProvider` or `adminUsersProvider` emit new data, `_AdminQuickStats` will NOT independently rebuild because it doesn't extend `ConsumerWidget` — it only rebuilds when its parent triggers a full `build()` cycle. Stats can show stale counts.
FIX: Convert to ConsumerWidget and drop the `ref` parameter:

  class _AdminQuickStats extends ConsumerWidget {
    const _AdminQuickStats();
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final sellers = ref.watch(adminSellersProvider);
      final users = ref.watch(adminUsersProvider);
      ...
    }
  }
  // Caller: _AdminQuickStats()  (no ref parameter)
```

```
[MEDIUM] admin.py:1560 (export_my_data PIPEDA compliance)
PROBLEM: `export_my_data` fetches orders with `.limit(500)`. A user with >500 orders receives an incomplete PIPEDA/GDPR data export — a direct legal compliance gap; data subject access requests must be complete.
FIX: Paginate with the same `while True` pattern used in `delete_account`:

  orders = []
  last_doc = None
  while True:
      q = get_db().collection(Collections.ORDERS).where(Fields.USER_ID, "==", user_id).limit(500)
      if last_doc:
          q = q.start_after(last_doc)
      batch = list(q.stream())
      if not batch:
          break
      for doc in batch:
          d = doc.to_dict(); d["orderId"] = doc.id
          orders.append(d)
      last_doc = batch[-1]
```

```
[MEDIUM] admin.py:1743 (admin_flag_review)
PROBLEM: Magic string `"isFlagged"` used directly in `review_ref.update({"isFlagged": flagged, ...})` instead of `Fields.IS_FLAGGED`. If the field is renamed in schema_constants, this call silently writes a new field and the old data is never updated — data drift.
FIX: `review_ref.update({Fields.IS_FLAGGED: flagged, Fields.UPDATED_AT: get_server_timestamp()})`
```

```
[LOW] admin.py:697 (admin_update_product_stock)
PROBLEM: Stock update uses a plain `.update()` without a Firestore transaction. If a purchase transaction reads stock concurrently and admin overwrites it in the same millisecond, the purchase transaction may see stale stock and the admin write may clobber a decremented value. Low probability at current scale but races with the idempotent purchase transaction.
FIX: Wrap in a transaction using `@firestore.transactional` pattern (same as purchase flow) or use Firestore Increment only for relative adjustments, reserving absolute writes for explicit admin override with a comment.
```

```
[LOW] admin_panel_screen.dart:314
PROBLEM: Hardcoded English string `'Origna GTA Admin'` — bypasses the i18n system and will not adapt to French locale (Quebec Law 25 compliance).
FIX: Replace with `'admin.header_brand'.tr()` or reference `AppConfig.PLATFORM_NAME` from schema_constants.
```

```
[LOW] admin_security_tab.dart:21–23
PROBLEM: `_secret` and `_qrCodeUri` (TOTP provisioning URI containing the base32 secret) are stored as plain `String?` fields in widget state. If the device is compromised or the widget tree is inspected (DevTools, Flutter inspector), the secret is exposed. Additionally, the "copy" button for backup codes at line 265–274 shows a SnackBar but doesn't actually copy to clipboard — `Clipboard.setData()` is never called.
FIX: Add `FlutterClipboard.copy(...)` or `Clipboard.setData(ClipboardData(text: _backupCodes.join('\n')))` in the onPressed. For secret in-memory, there is no Flutter-native secure memory but document in comments that secret is ephemeral and cleared on `_mfaEnabled = true`.
```

```
[BONUS] admin.py:778–780 (admin_mfa_enroll race condition)
PROBLEM: The `existing_mfa` guard (line 778) reads `user_data` fetched ~25 lines earlier outside the transaction. The transaction (line 785) guards on `MFA_SECRET_TEMP` in a different document (`user_security`). Between these two reads, a concurrent enrollment call could slip through because `users` doc and `user_security` doc are checked non-atomically.
FIX: Move the `mfaEnabled` check INSIDE `_enroll_mfa_txn` by also reading the `users` doc in the transaction — or at minimum re-read `user_data` inside the transaction for the `mfaEnabled` flag.
```

```
[BONUS] admin_repository.dart:117–132 (watchReviews compound query + missing index)
PROBLEM: `watchReviews` with both `flaggedOnly=true` AND `hasPhotosOnly=true` creates a compound WHERE on two fields (`isFlagged == true` + `hasPhotos == true`) combined with `orderBy(createdAt)`. Firestore requires a composite index for this. There's no evidence this index exists, so enabling both filters simultaneously will throw a Firestore "requires an index" runtime error.
FIX: Add composite Firestore index: collection `product_ratings`, fields: `isFlagged ASC`, `hasPhotos ASC`, `createdAt DESC`. Also add the single-field variants (`isFlagged + createdAt`, `hasPhotos + createdAt`).
```

```
[BONUS] admin_panel_screen.dart:75
PROBLEM: Admin role check `!profile.roles.contains(UserRoles.admin)` is frontend-only gating. A malicious user who can navigate to `/admin` directly (or using browser history) will see the "access denied" screen but the screen renders `userProfileProvider` data — meaning the admin providers (watchSellers, watchUsers, watchOrders) will NOT be started because the branch returns early. However, if the role check ever has a race condition (profile loads after providers), some streams could briefly expose data. This is already protected by Firestore rules but worth flagging.
FIX: Add `@protected` Firestore rules ensuring `admin_logs`, `security_alerts` collections are unreadable by non-admins (verify rules enforcement, not just UI gating).
```

```
[BONUS] admin.py:391 (suspend_seller items loop)
PROBLEM: `for item in order_data[Fields.ITEMS]:` — uses direct key access `[]` not `.get()`. If an order document exists but `items` field is absent (malformed data), this raises a `KeyError` and crashes the handler, leaving the seller partially suspended (Firestore updated but products not deactivated, subsequent orders not cancelled).
FIX: `for item in order_data.get(Fields.ITEMS, []):`
```

```
[BONUS] admin.py (multiple handlers) — repeated admin auth check pattern
PROBLEM: Every admin function repeats the same 5-line pattern: `get admin_doc → check exists → check ADMIN role → _require_recent_admin_mfa`. This is duplicated in 8+ functions, making it easy for a future function to skip one of the steps. The existing `_require_admin` in payment_providers.py is not shared.
FIX: Extract to a shared helper in admin.py (like payment_providers.py's `_require_admin`):

  def _require_admin_with_mfa(req) -> tuple[str, dict]:
      if not req.auth:
          raise https_fn.HttpsError("unauthenticated", "...")
      admin_id = req.auth.uid
      admin_doc = get_db().collection(Collections.USERS).document(admin_id).get()
      if not admin_doc.exists:
          raise https_fn.HttpsError("not-found", "Admin user not found")
      admin_data = admin_doc.to_dict()
      if UserRoleValues.ADMIN not in admin_data.get(Fields.ROLES, []):
          raise https_fn.HttpsError("permission-denied", "Admin role required")
      _require_recent_admin_mfa(admin_data)
      return admin_id, admin_data
```

```
[BONUS] admin_panel_screen.dart:29–37 (_tabs as static getter)
PROBLEM: `_tabs` is defined as `static List<_AdminTab> get _tabs => [...]` — a getter that reconstructs the list on every call. Every `build()` invocation re-creates 7 `_AdminTab` objects and calls `.tr()` translations 7 times. Given how frequently TabBar builds, this is a minor but avoidable allocation.
FIX: Cache as `static final` computed once, or use `late final` in `initState`:

  late final List<_AdminTab> _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = [ _AdminTab(icon: ..., label: 'admin.sellers_tab'.tr(), ...), ... ];
    _tabController = TabController(length: _tabs.length, vsync: this);
  }
  // Bonus: TabController length is now dynamically tied to _tabs.length, preventing mismatch.
```

[CRITICAL] origna_gta/lib/utils/utils.dart:243
PROBLEM: `addToCart()` always returns `true` even when the Firestore transaction throws, so the UI can treat failed add-to-cart operations as successful and drift from backend state.
FIX: Return `false` on exception and only return `true` after a successful transaction; also surface the error message to users so stock-limit and product-missing failures are visible.
```dart
Future<bool> addToCart(...) async {
  try {
    await FirebaseFirestore.instance.runTransaction((tx) async { ... });
    return true;
  } catch (e, stack) {
    AppError.log(e, stackTrace: stack, context: 'addToCart');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppError.getMessage(e))),
      );
    }
    return false;
  }
}
```

[HIGH] origna_gta/lib/screens/common_screens.dart:147
PROBLEM: `AuthRequiredGate` uses `userProfileProvider.valueOrNull` and only blocks when `suspended == true`; when profile load fails, `valueOrNull` is `null` and the gate still returns `child`, bypassing suspension enforcement.
FIX: Handle `userProfileProvider` with full `when(...)` and fail closed on error (show access-denied/retry state or sign out), instead of defaulting to allow.
```dart
final userProfileAsync = ref.watch(userProfileProvider);
return userProfileAsync.when(
  loading: () => const Scaffold(body: Center(child: ModernLoadingIndicator())),
  error: (_, __) => const ErrorScreen(message: 'errors.profile_load_failed'),
  data: (profile) {
    if (profile?.suspended == true) return const _SuspendedView();
    if (profile == null) return const ErrorScreen(message: 'errors.profile_missing');
    return child;
  },
);
```

[HIGH] origna_gta/lib/utils/utils.dart:704
PROBLEM: `checkEmailVerifiedOrPrompt()` returns `true` when `user.reload()` fails, which lets unverified users pass verification checks during network failures.
FIX: Keep emulator bypass, but in non-emulator environments treat reload failure as non-verified and show the verification dialog or retry prompt.
```dart
try {
  await user.reload();
} catch (e) {
  debugPrint('checkEmailVerifiedOrPrompt reload failed: $e');
  if (context.mounted) {
    showEmailVerificationDialog(context, onResend: () async => user.sendEmailVerification());
  }
  return false;
}
```

[HIGH] e2e/playwright_ui/smoke-home-profile.spec.ts:18
PROBLEM: Admin credentials are hardcoded as default values in test code, which risks accidental account takeover if that test account is reused and leaks secrets into version control.
FIX: Remove credential defaults, require env vars, and fail fast when missing; keep only a safe default URL.
```ts
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD;
if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
  throw new Error('Missing E2E_ADMIN_EMAIL / E2E_ADMIN_PASSWORD');
}
```

[MEDIUM] origna_gta/lib/origna_app.dart:471
PROBLEM: Session activity tracking only records `onPointerDown`/`onPointerMove`; keyboard-only usage and some non-pointer interactions are ignored, causing false 15-minute auto-logouts.
FIX: Record activity for keyboard and pointer-signal events in addition to pointer down/move.
```dart
return Focus(
  autofocus: true,
  onKeyEvent: (_, __) {
    _sessionTimeout.recordActivity();
    return KeyEventResult.ignored;
  },
  child: Listener(
    onPointerDown: (_) => _sessionTimeout.recordActivity(),
    onPointerMove: (_) => _sessionTimeout.recordActivity(),
    onPointerSignal: (_) => _sessionTimeout.recordActivity(),
    child: MaterialApp(...),
  ),
);
```

[MEDIUM] origna_gta/lib/services/analytics_service.dart:40
PROBLEM: `logSearch()` forwards raw user-entered `searchTerm` directly to analytics, which can capture accidental PII (emails, phone numbers, order IDs) in event payloads.
FIX: Redact likely-PII patterns or log only normalized non-sensitive metadata (length/category) instead of raw query text.
```dart
static Future<void> logSearch({required String searchTerm}) async {
  if (!_isEnabled) return;
  final term = searchTerm.trim();
  final piiLike = RegExp(r'(@|\b\d{7,}\b)').hasMatch(term);
  await _analytics.logSearch(searchTerm: piiLike ? '[redacted]' : term);
}
```

[LOW] functions/config.py:77
PROBLEM: Unknown or missing `GCP_PROJECT` falls through to production (`orignagta`), so misconfigured deployments can silently use production environment settings.
FIX: Use explicit allowlist mapping and raise on unknown project IDs to fail-safe instead of defaulting to production.
```python
PROJECT_ENV_MAP = {
    'orignagta-dev': Environment.DEV,
    'orignagta-staging': Environment.STAGING,
    'orignagta': Environment.PRODUCTION,
}
if IS_EMULATOR:
    CURRENT_ENV = Environment.EMULATOR
elif PROJECT_ID in PROJECT_ENV_MAP:
    CURRENT_ENV = PROJECT_ENV_MAP[PROJECT_ID]
else:
    raise RuntimeError(f'Unknown GCP project: {PROJECT_ID}')
```
Here is the full cross-stack audit of the chat system.

---

## 🔴 CRITICAL

### 1. `MAX_MESSAGE_LENGTH` mismatch — chat.py hardcodes `2000`, constant says `1000`

**`chat.py` line 87:**
```python
if len(text) > 2000:
    raise https_fn.HttpsError("invalid-argument", "Message text exceeds 2000 characters.")
```
`schema_constants.py` defines `MAX_MESSAGE_LENGTH = 1000`. The constant is the source of truth. Backend and frontend must use it. No client-side enforcement either.

**Fix `chat.py`:**
```python
from schema_constants import Fields, MAX_MESSAGE_LENGTH  # add constant import

if len(text) > MAX_MESSAGE_LENGTH:
    raise https_fn.HttpsError("invalid-argument", f"Message text exceeds {MAX_MESSAGE_LENGTH} characters.")
```

**Fix `chat_screen.dart` — add `maxLength` to TextField:**
```dart
TextField(
  controller: controller,
  maxLength: SchemaConstants.maxMessageLength,   // add this
  maxLengthEnforcement: MaxLengthEnforcement.enforced,
  ...
)
```
Add to `schema_constants.dart`:
```dart
static const int maxMessageLength = 1000;
static const int minMessageLength = 10;
```

---

### 2. `MIN_MESSAGE_LENGTH` never enforced — `chat.py` only guards empty strings

`schema_constants.py` defines `MIN_MESSAGE_LENGTH = 10`. `chat.py` only checks `if not text`. A 1-char message passes through.

**Fix `chat.py`:**
```python
if len(text) < Fields.MIN_MESSAGE_LENGTH:
    raise https_fn.HttpsError("invalid-argument", f"Message must be at least {Fields.MIN_MESSAGE_LENGTH} characters.")
```

---

### 3. Seller cannot open the ChatScreen — `openChat()` will throw "cannot chat with yourself"

`ChatScreen` accepts only `productId` and calls `get_or_create_chat(productId)`. If a seller navigates to their own chat thread (from `sellerChatsStream`), the function runs with `buyer_id = seller_uid`, finds `seller_id == buyer_id` on the product, and throws `"You cannot chat with yourself"`. The seller sees an error screen and cannot reply.

**Fix** — `ChatScreen` and `ChatViewModel` must accept an optional `chatId` bypass for the seller path:

**`chat_provider.dart`** — change the family param to a sealed args object:
```dart
class ChatArgs {
  final String productId;
  final String? existingChatId; // pass for seller path

  const ChatArgs({required this.productId, this.existingChatId});

  @override
  bool operator ==(Object o) =>
      o is ChatArgs && o.productId == productId && o.existingChatId == existingChatId;

  @override
  int get hashCode => Object.hash(productId, existingChatId);
}

final chatViewModelProvider =
    StateNotifierProvider.autoDispose.family<ChatViewModel, ChatState, ChatArgs>((ref, args) {
  return ChatViewModel(ref, args);
});
```

**`ChatViewModel.openChat()`:**
```dart
Future<void> openChat() async {
  if (state.chatId != null || state.isLoading) return;
  // Seller path: chatId already known, skip backend call
  if (_args.existingChatId != null) {
    state = state.copyWith(chatId: _args.existingChatId);
    return;
  }
  state = state.copyWith(isLoading: true, clearError: true);
  try {
    final chatId = await _ref.read(chatRepositoryProvider).getOrCreateChat(_args.productId);
    state = state.copyWith(isLoading: false, chatId: chatId);
  } catch (e) {
    state = state.copyWith(isLoading: false, errorMessage: _parseError(e));
  }
}
```

**`ChatScreen`** — add optional `chatId` param, pass `ChatArgs`:
```dart
class ChatScreen extends ConsumerStatefulWidget {
  final String productId;
  final String productTitle;
  final String? chatId; // seller passes this directly

  const ChatScreen({super.key, required this.productId, required this.productTitle, this.chatId});
  ...
}
```

---

### 4. Missing Firestore composite index for `mark_messages_read`

`mark_messages_read` runs:
```python
.where(Fields.IS_READ, "==", False)
.where(Fields.SENDER_ID, "!=", uid)
```
Firestore requires a composite index for `!=` combined with another equality filter on the same collection. Without it the function throws `FAILED_PRECONDITION` at runtime.

**Add to `firestore.indexes.json`** (messages subcollection):
```json
{
  "collectionGroup": "messages",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "read", "order": "ASCENDING" },
    { "fieldPath": "senderId", "order": "ASCENDING" }
  ]
}
```

Also needed for chat list queries in `chat_repository.dart`:
```json
{ "collectionGroup": "chats", "fields": [
    { "fieldPath": "buyerId", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
]},
{ "collectionGroup": "chats", "fields": [
    { "fieldPath": "sellerId", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
]}
```

---

## 🟠 HIGH

### 5. Text restore on send failure overwrites user's in-flight input

```dart
} catch (_) {
  _textController.text = text; // restore on failure
}
```
If the user starts typing a new message while the previous send is in-flight and fails, this overwrites what they typed. Replace with a snackbar + keep the field as-is:

```dart
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('chat.send_failed'.tr()), backgroundColor: DesignTokens.error),
  );
  // Don't restore — user may have already typed new content
}
```

---

### 6. `sendMessage` silently drops messages when `isLoading` is true

```dart
if (state.isLoading) return; // in-flight guard — silently drops
```
User presses send twice quickly: second message vanishes with no feedback. Queue or show error:

```dart
if (state.isLoading) {
  // surface to UI instead of silently dropping
  state = state.copyWith(errorMessage: 'Please wait before sending another message.');
  return;
}
```

---

### 7. `markRead` fires on every new message batch — should debounce

In `_MessagesList.build`:
```dart
ref.listen(chatMessagesProvider(chatId), (prev, next) {
  if (next.hasValue) {
    if (nextCount > prevCount) {
      ref.read(chatViewModelProvider(productId).notifier).markRead();
    }
  }
});
```
5 rapid messages → 5 Cloud Function calls. Add a 1-second debounce in `ChatViewModel`:

```dart
Timer? _markReadDebounce;

Future<void> markRead() async {
  _markReadDebounce?.cancel();
  _markReadDebounce = Timer(const Duration(seconds: 1), () async {
    final chatId = state.chatId;
    if (chatId == null) return;
    await _ref.read(chatRepositoryProvider).markRead(chatId);
  });
}
```

---

### 8. `_sanitize_text` doesn't filter off-platform contact info

A seller can send `WhatsApp: +1-555-0123` or `email me at xyz@gmail.com` to route buyers off-platform, bypassing Origna's platform fee. This is a direct revenue and compliance risk.

```python
import re

_PHONE_RE = re.compile(r'(\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}')
_EMAIL_RE = re.compile(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}')
_EXTERNAL_URL_RE = re.compile(r'https?://(?!orignagta\.ca)[^\s]+', re.IGNORECASE)

def _sanitize_text(text: str) -> str:
    text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'javascript:', '', text, flags=re.IGNORECASE)
    text = _PHONE_RE.sub('[phone removed]', text)
    text = _EMAIL_RE.sub('[email removed]', text)
    text = _EXTERNAL_URL_RE.sub('[link removed]', text)
    return text.strip()
```

---

## 🟡 MEDIUM

### 9. Missing Semantics labels — Playwright coverage is sparse

SEMANTICS.md shows only the send button has a label. Tests for Flow 13 (chat) will be nearly untestable. Add to `chat_screen.dart`:

```dart
// On the message input TextField:
Semantics(
  label: 'chat-message-input',
  child: TextField(...),
)

// On each message bubble (_MessageBubble):
Semantics(
  label: 'chat-message-${message.id}',
  child: Container(...),
)

// On empty state:
Semantics(
  label: 'chat-empty-state',
  child: Column(...),
)
```

Add to `SEMANTICS.md`:
| Message input | `page.getByRole('textbox', { name: /chat-message-input/i })` |
| Message bubble | `page.locator('[aria-label^="chat-message-"]')` |
| Empty state | `page.locator('[aria-label="chat-empty-state"]')` |

---

### 10. Push notification fetches sender name on every message — unnecessary Firestore read

```python
sender_snap = db.collection(Collections.USERS).document(uid).get()
sender_name = (sender_snap.to_dict() or {}).get(Fields.NAME, "Someone")
```
Every `send_message` call reads a user doc. Cache the sender name in the chat thread at creation time (it's already denormalized for buyer/seller) or pass from client. Alternatively read `displayName` from Firebase Auth token claims to avoid Firestore reads.

---

### 11. `userChatsStream` vs `sellerChatsStream` — user who is both gets split inbox

A user who is both buyer and seller (the main test account `yr62813@gmail.com`) has their chats split across two streams. The chat list UI must merge `myBuyerChatsProvider` and `mySellerChatsProvider`. Verify the chat list screen does this. If not, add a merged provider:

```dart
final allMyChatsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  final repo = ref.watch(chatRepositoryProvider);
  return Rx.combineLatest2(
    repo.userChatsStream(uid),
    repo.sellerChatsStream(uid),
    (List<ChatThread> b, List<ChatThread> s) =>
        {...b, ...s}.toList()..sort((a, b) =>
            (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0))),
  );
});
```
(requires `rxdart` package)

---

### 12. `limitToLast(100)` — no pagination for long conversations

Hard limit at 100 messages means anything older is invisible. For an active support chat this is a problem. Add a `startAfterDocument` cursor pattern or use a `lazyLoading` approach (load 50, add "Load more" button).

---

## ✅ Verified Good

- Deterministic `chat_doc_id = f"{product_id}_{buyer_id}"` with `ALREADY_EXISTS` handler — race condition safe ✓
- Self-chat prevention `if seller_id == buyer_id` ✓
- Order requirement before chat creation ✓
- Rate limiter 60 msg/min ✓
- Batch write in 499-chunk limit for `mark_messages_read` ✓
- Firestore rules are backend-only write (Admin SDK bypasses) ✓
- Premium paywall shown on `permission-denied` + "premium" in message ✓
- Stagger animation capped at 12 items ✓
- `onSubmitted` fires send on keyboard Enter ✓

---

## Summary Table

| # | Severity | File | Fix effort |
|---|----------|------|-----------|
| 1 | 🔴 Critical | `chat.py` + `chat_screen.dart` + constants | Small |
| 2 | 🔴 Critical | `chat.py` | Small |
| 3 | 🔴 Critical | `chat_screen.dart` + `chat_provider.dart` | Medium |
| 4 | 🔴 Critical | `firestore.indexes.json` | Small |
| 5 | 🟠 High | `chat_screen.dart` | Small |
| 6 | 🟠 High | `chat_provider.dart` | Small |
| 7 | 🟠 High | `chat_provider.dart` | Small |
| 8 | 🟠 High | `chat.py` | Small |
| 9 | 🟡 Medium | `chat_screen.dart` + `SEMANTICS.md` | Small |
| 10 | 🟡 Medium | `chat.py` | Small |
| 11 | 🟡 Medium | `chat_provider.dart` | Medium |
| 12 | 🟡 Medium | `chat_repository.dart` | Medium |

**Start with #3 (seller path broken) and #4 (missing indexes) — both are silent runtime failures.**

Let me read the remaining key files before issuing findings.Now I have all the context needed for the full audit. Here are my findings:

---

```
[HIGH] lib/screens/login_screen.dart:278
PROBLEM: `_passwordController.text.trim()` strips leading/trailing spaces from passwords. A user who registered with a password containing a trailing space will fail login silently — the trim strips it on both sides but Firebase Auth stores the raw password, causing a mismatch on subsequent logins.
FIX: Remove `.trim()` from password field only. Emails may still be trimmed. Apply to both sign-in and registration calls.
```dart
// BEFORE (wrong)
password: _passwordController.text.trim(),
// AFTER (correct)
password: _passwordController.text,
```
```

---

```
[HIGH] lib/features/auth/login_state.dart:18-29
PROBLEM: `copyWith` uses bare assignment `errorMessage: errorMessage` (not `?? this.errorMessage`), so any call that doesn't explicitly pass `errorMessage` nulls it out. Concretely: `toggleObscurePassword()` and `setMarketingOptIn()` silently clear visible error messages mid-form, confusing users who made an error and then toggle password visibility.
FIX: Use sentinel pattern or explicit nullable override parameter. Two approaches:

Approach A — explicit clear flag (matches sentinel already used for error/successMessage in seller_registration_state.dart):
```dart
const Object _sentinel = Object();

LoginState copyWith({
  Object? errorMessage = _sentinel,
  Object? successMessage = _sentinel,
  ...
}) {
  return LoginState(
    errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    successMessage: successMessage == _sentinel ? this.successMessage : successMessage as String?,
    ...
  );
}
```
Approach B — add explicit `clearError: bool = false` flag.
```

---

```
[HIGH] lib/core/repositories/user_repository.dart:92-97
PROBLEM: `watchSellerAccountStatus` uses `.asyncMap()` to fire a separate `get()` on `seller_profiles/{uid}` on every change to `users/{uid}`. At 100M users/year, every users-doc write (lastCheckoutTimestamp, fcmToken, etc.) triggers an extra read. Reads cost money and add latency; this is a textbook N+1 in a reactive stream.
FIX: Combine both streams with `StreamZip` or `Rx.combineLatest2` (from `rxdart`) so both docs are watched in parallel, not sequentially:
```dart
import 'package:rxdart/rxdart.dart';

Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) {
  final userStream = _firestore.collection(Collections.users).doc(userId).snapshots();
  final spStream = _firestore.collection(Collections.sellerProfiles).doc(userId).snapshots();
  return Rx.combineLatest2(userStream, spStream,
    (userSnap, spSnap) => _parseSellerStatus(userSnap.data(), spSnap.data()));
}
```
```

---

```
[MEDIUM] functions/services/rate_limiter.py:25-29
PROBLEM: `RELAXED_RATE_LIMITS=true` env var disables rate limits 100x on ANY environment except PRODUCTION. If mistakenly set on staging, auth and payment endpoints are effectively unprotected. Staging is internet-accessible and used by Playwright tests; unprotected auth endpoints expose the environment to credential stuffing.
FIX: Restrict relaxed limits to emulator only (not staging):
```python
_RELAXED_LIMITS = (
    os.environ.get("RELAXED_RATE_LIMITS", "false").lower() == "true"
    and _IS_EMULATOR  # Remove CURRENT_ENV check — emulator-only, never staging
)
```
Or if dev is acceptable: `and CURRENT_ENV in (Environment.DEVELOPMENT, Environment.EMULATOR)`.
```

---

```
[MEDIUM] origna_flows/seller-registration.spec.ts:53-60
PROBLEM: The "Buyer cannot access seller-only endpoints" test explicitly accepts both success AND failure as valid outcomes (`expect(isAcceptable || true, ...).toBeTruthy()`). The `|| true` makes the assertion always pass — the test never actually verifies the security constraint. A buyer with an accidentally assigned seller role in dev would silently pass.
FIX: Remove `|| true`. Assert specifically on the error code:
```typescript
const error = await callExpectError('create_connect_account', {...}, buyerAuth.idToken);
expect(error).toBeTruthy();
expect(['permission-denied', 'unauthenticated'].some(code => 
  JSON.stringify(error).includes(code)
)).toBe(true);
```
```

---

```
[MEDIUM] lib/features/auth/login_viewmodel.dart:184 + lib/screens/login_screen.dart:142,417 + lib/core/repositories/auth_repository.dart:11
PROBLEM: The email validation regex is copy-pasted in 4 places: `auth_repository.dart` top-level, `login_viewmodel.dart:_validateEmail`, `login_screen.dart` form validator (x2). If the regex changes in one place (e.g., to support IDNs), the others silently diverge, causing validation inconsistency between UI and backend.
FIX: Define once in a shared constants file:
```dart
// lib/core/constants/validation_constants.dart
abstract class ValidationConstants {
  static final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
}
```
Import and reference `ValidationConstants.emailRegex` everywhere.
```

---

```
[MEDIUM] docs/database_schema.json (users collection) vs lib/core/repositories/user_repository.dart:98
PROBLEM: `database_schema.json` defines `pendingRequirements` under the `users` collection, but `_parseSellerStatus` reads it from `spData` (seller_profiles doc). The schema says users, code says seller_profiles. The schema should be the single source of truth — mismatches cause confusion when future devs write Firestore rules or migrations.
FIX: Remove `pendingRequirements` from the users schema definition (it belongs only in seller_profiles). Update `database_schema.json` accordingly and verify Firestore rules don't inadvertently allow users to write it to their own user doc.
```

---

```
[LOW] lib/screens/login_screen.dart:84,94,454
PROBLEM: `color: Colors.white` used directly in 3 places, violating DesignTokens-only color rule. CI lint won't catch this and it breaks theme consistency.
FIX:
```dart
// BEFORE
color: Colors.white
// AFTER
color: DesignTokens.onPrimary  // or DesignTokens.surface — whatever maps to white in the design system
```
```

---

```
[BONUS] lib/core/repositories/auth_repository.dart:238
PROBLEM: `name ?? user.displayName ?? 'User'` creates Firestore profiles with the literal name "User" for Google accounts with no displayName. The Pydantic model passes validation (min_length 2), but the buyer/seller sees "User" everywhere in the app. This also makes admin user lists unreadable.
FIX: Throw a recoverable error or prompt for a name instead:
```dart
final resolvedName = name ?? user.displayName;
if (resolvedName == null || resolvedName.trim().isEmpty) {
  throw FirebaseAuthException(code: 'missing-display-name', message: 'Please provide your name to complete registration.');
}
await callable.call<Map<String, dynamic>>({Fields.name: resolvedName.trim(), ...});
```
```

---

```
[BONUS] lib/screens/authwrapper_screen.dart:22
PROBLEM: `loading: () => const MainScreen()` renders the full MainScreen while auth state is unknown. On slow connections or cold starts, an unauthenticated user may briefly see the full app shell before being redirected. This could cause a flash of protected UI, broken provider reads (null user), or layout jumps.
FIX: Return a neutral loading placeholder that matches the HTML splash:
```dart
loading: () => const Scaffold(body: SizedBox.shrink()), // HTML splash covers it
// OR if you want consistent behavior on mobile:
loading: () => const ModernLoadingIndicator(),
```
```

---

```
[BONUS] functions/services/rate_limiter.py:78
PROBLEM: `first_request.tzinfo` is accessed unconditionally, but `first_request` could be `None` if a race condition or manual edit left the Firestore doc without a `FIRST_REQUEST` field. This throws `AttributeError: 'NoneType' object has no attribute 'tzinfo'`, which causes `check_and_increment` to raise, triggering fail-closed for auth requests — effectively locking out all users until the broken doc is deleted.
FIX:
```python
first_request = data.get(Fields.FIRST_REQUEST)
if first_request is None:
    # Corrupt doc — reset the window
    transaction.set(ref, {Fields.COUNT: 1, Fields.FIRST_REQUEST: now, Fields.LAST_REQUEST: now})
    return True, "OK"
if first_request.tzinfo is None:
    first_request = first_request.replace(tzinfo=UTC)
```
```

---

```
[BONUS] lib/features/auth/login_viewmodel.dart:91-99
PROBLEM: After a successful sign-in on dev/emulator, `state = state.copyWith(isLoading: false, isSuccess: true)` returns before the email verification check block, but control then falls through to the outer `state = state.copyWith(isLoading: false, isSuccess: true)` at line 118 — duplicate state set. Harmless now but a latent bug if the early-return logic is refactored.
FIX: Add explicit `return` after the early success state in the dev/emulator branch (line 97 already has `return`, so verify this is not re-executed after refactors).
```

---

```
[BONUS] lib/features/seller/seller_registration_view_model.dart:63-72
PROBLEM: `_canProceed()` is a non-synchronized check — between `_canProceed()` returning `true` and `_isOperationInProgress = true` being set, a second concurrent call (e.g., double-tap before Flutter debounce) can pass the check. This is a TOCTOU race: two simultaneous calls both read `_isOperationInProgress = false` and both proceed.
FIX: Use a lock flag set atomically at the top of the public methods:
```dart
Future<void> startRegistration() async {
  if (_isOperationInProgress || state.isLoading) return;
  _isOperationInProgress = true; // Set immediately, before any await
  _lastOperationTime = DateTime.now();
  state = state.copyWith(isLoading: true, error: null);
  try { ... }
```
This is the same pattern as the dart `synchronized` idiom — set the flag synchronously before any await.
```

---

```
[BONUS] lib/screens/login_screen.dart:84
PROBLEM: The app logo `Icon(Icons.shopping_bag_outlined)` inside a `Hero` widget has no `Semantics` wrapper. Screen readers announce it as an unlabeled image, failing AODA/WCAG 2.1 (required for Canadian apps under AODA for Ontario).
FIX:
```dart
Semantics(
  label: 'OrignaGta logo',
  image: true,
  child: Hero(
    tag: 'app_logo',
    child: Container(/* ... */ child: const Icon(Icons.shopping_bag_outlined, ...)),
  ),
),
```
```

---

```
[BONUS] lib/features/auth/login_viewmodel.dart (handleAuth, line ~55-118) + lib/core/repositories/auth_repository.dart
PROBLEM: `consentMethod` (required for CASL/PIPEDA/Law 25 compliance) is defined in the User model and database schema but is never sent from the client to `create_user_profile`. The comment says "set server-side", but the CF receives no signal indicating HOW consent was captured (signup_form, google_oauth, etc.). If regulators ask for proof of consent method, Firestore will show `null`.
FIX: Pass `consentMethod` from the client — it's not sensitive data:
```dart
// auth_repository.dart _createUserDocumentIfNeeded
await callable.call<Map<String, dynamic>>({
  Fields.name: resolvedName,
  Fields.preferredLanguage: _deviceLanguage(),
  Fields.marketingOptIn: marketingOptIn,
  'consentMethod': isGoogleSignIn ? 'google_oauth' : 'signup_form', // add parameter
});
```
The CF then stamps the server timestamp. Both sides needed: client knows the method, server controls the timestamp.
```

Now let me read the overflow file and checkout/cart screens.Now let me look at the capture payment implementation and the checkout screen/cart screen.Now I have enough to write the full audit.

---

```
[CRITICAL] checkout_provider.dart:264
PROBLEM: Frontend generates idempotencyKey at line 255 but never includes it in `orderData` sent to backend; backend reads `data.get(ApiKeys.IDEMPOTENCY_KEY)` at payment_stripe.py:579 but always gets `None`. Stripe idempotency key falls back to `f"checkout_{order_id}"` (payment_stripe.py:1423) — since `order_id` is newly generated each call, every call gets a unique Stripe key. Double-clicking "Place Order" creates two separate orders and reserves stock twice.
FIX: Add `ApiKeys.idempotencyKey: idempotencyKey` to the `orderData` map at line 288. Backend already handles it correctly. Three approaches:
Approach A (minimal): Add key to orderData map:
```dart
// checkout_provider.dart:288 — inside orderData map
if (state.idempotencyKey != null)
  ApiKeys.idempotencyKey: state.idempotencyKey,
```
Approach B (server-side dedup): Backend also checks for an existing `PENDING` order with same userId+items before creating a new one (race-safe).
Approach C (both): Send key AND add backend check — redundant safety for retries + concurrent clicks.
ALSO: stripe-payment.spec.ts:58 — "Duplicate checkout with same idempotency key returns same orderId" test would fail today.
```

```
[HIGH] payment_stripe.py:1852
PROBLEM: `_execute_seller_payouts` re-fetches `seller_profiles/{seller_id}` for `STRIPE_ACCOUNT_ID` at webhook time, bypassing the snapshot stored in `order_data[Fields.SELLER_STRIPE_ACCOUNTS]` (written at checkout line 1354). The "SECURITY FIX (CRITICAL-014): Snapshot seller Stripe account IDs at checkout" comment is rendered dead code — a seller can change their Stripe Connect account between checkout creation and payout execution.
FIX: Read from the snapshot first:
```python
# payment_stripe.py in _execute_seller_payouts, replace line 1852-1853:
seller_accounts_snapshot = order_data.get(Fields.SELLER_STRIPE_ACCOUNTS, {})
acct_id = seller_accounts_snapshot.get(seller_id)
if not acct_id:
    # Fallback only if snapshot missing (e.g., orders created before the fix)
    sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(seller_id).get()
    acct_id = (sp_doc.to_dict() or {}).get(Fields.STRIPE_ACCOUNT_ID)
```
Apply the same fix to the capture path at payment_stripe.py:3779.
```

```
[HIGH] payment_stripe.py:2043
PROBLEM: `process_checkout_session_completed` loops over `items` and issues individual `product_ref.get()` + `seller_ref.get()` per item (lines 2049-2068) — an N+1 Firestore read pattern. For a 10-item multi-seller order this is 20 serial reads inside a webhook. At 100M orders/year with P99 webhook timeouts this will cause frequent Cloud Functions timeouts and lost payment confirmations.
FIX: Batch-read all products and sellers before the loop:
```python
# Before the item validation loop (after line 2043):
items = order_data.get(Fields.ITEMS, [])
product_ids = [item.get(Fields.PRODUCT_ID) for item in items]
seller_ids = list({item.get(Fields.SELLER_ID) for item in items})

product_refs = [get_db().collection(Collections.PRODUCTS).document(pid) for pid in product_ids]
seller_refs  = [get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]
product_docs = {d.id: d for d in get_db().get_all(product_refs)}
seller_docs  = {d.id: d for d in get_db().get_all(seller_refs)}

for item in items:
    product_doc = product_docs.get(item.get(Fields.PRODUCT_ID))
    seller_doc  = seller_docs.get(item.get(Fields.SELLER_ID))
    # ... same validation logic using pre-fetched docs
```
```

```
[HIGH] payment_stripe.py:1326
PROBLEM: `expiresAt = datetime.now(UTC) + timedelta(days=AUTHORIZATION_VALID_DAYS)` is stamped at **order creation** (before the buyer pays). Stripe's 7-day capture window starts from when the PaymentIntent is **authorized** (i.e., when `checkout.session.completed` fires). If a buyer takes 2 days to complete checkout, the actual Stripe capture deadline is `createdAt + 9 days`, but our `expiresAt` is `createdAt + 7 days`. The cron job expiring orders based on `expiresAt` will void authorizations 2 days before Stripe actually expires them.
FIX: Set `expiresAt` in the webhook handler when authorization is confirmed, not at order creation:
```python
# In process_checkout_session_completed, payment_stripe.py ~line 2075:
from datetime import UTC, datetime, timedelta
update_data[Fields.EXPIRES_AT] = datetime.now(UTC) + timedelta(days=AUTHORIZATION_VALID_DAYS)
```
Keep `expiresAt: None` at order creation (or set it to session expiry + 7 days as a safe upper bound).
```

```
[MEDIUM] payment_stripe.py:1847
PROBLEM: `payout_ref.set(payout_data, merge=True)` uses `merge=True` to create payout records. If a webhook is retried after a partial failure where the Transfer succeeded but the Firestore write failed, the retry re-runs `_execute_seller_payouts` which calls `payout_ref.set(payout_data, merge=True)` — this resets `status` to `PENDING` and overwrites a potentially `COMPLETED` record from a previous partially-successful run. The payout becomes stuck in PENDING or triggers a duplicate Stripe Transfer (blocked only by the Transfer idempotency key).
FIX: Use `set` with `merge=True` only when creating, and check for existing COMPLETED status first:
```python
# payment_stripe.py ~line 1847:
existing_payout = payout_ref.get()
if existing_payout.exists:
    existing_status = (existing_payout.to_dict() or {}).get(Fields.STATUS)
    if existing_status == PayoutStatusValues.COMPLETED:
        logger.info(f"Payout {payout_ref.id} already COMPLETED — skipping")
        continue  # idempotent skip
payout_ref.set(payout_data)  # No merge — new record only
```
```

```
[MEDIUM] checkout_provider.dart:136
PROBLEM: `calculateTaxes` uses client-side `getTaxRate(province)` for the UI display, but the backend recalculates taxes independently (using `BusinessRules.TAX_RATES` in Python). The `_OrderReviewSheet` at checkout_screen.dart:1119-1121 re-derives tax from the same frontend `getTaxRate`. If the Python and Dart tax rate tables diverge for any province (e.g., after a CRA change), the user confirms a total at checkout that differs from what Stripe charges — eroding trust and potentially violating CRA disclosure requirements.
FIX: Return server-calculated `taxAmountCents` and `shippingCostCents` in the `create_checkout_session` response and display those authoritative values in `_OrderReviewSheet` instead of re-computing from rates. Alternatively, call a lightweight `calculate_checkout_estimate` endpoint before showing the review sheet.
```

```
[MEDIUM] payment_stripe.py:957
PROBLEM: Stripe Tax API fallback (line 954-957): when `calculate_tax_with_stripe()` fails, the code falls back to manual tax calculation and explicitly notes "Do NOT apply B2B exemption (GST-based) in fallback mode". However, looking at the fallback branch (truncated around line 957), if a valid business buyer with a GST number makes a purchase and Stripe Tax is down, they are charged full tax that the CRA may later require to be credited/refunded — creating retroactive tax liability and compliance risk. No alert is raised to operations.
FIX: Add a security alert when Stripe Tax fails for a user with a `gst_number`, and log the discrepancy for retroactive reconciliation:
```python
# In the fallback branch after ~line 957:
if gst_number:
    get_db().collection(Collections.SECURITY_ALERTS).add({
        Fields.TYPE: 'stripe_tax_fallback_gst_user',
        Fields.SEVERITY: SeverityLevels.HIGH,
        Fields.USER_ID: user_id,
        Fields.ORDER_ID: order_id,
        'gstNumber': gst_number[:6] + '****',
        Fields.TIMESTAMP: get_server_timestamp(),
        Fields.RESOLVED: False,
    })
```
```

```
[LOW] cart_provider.dart:148
PROBLEM: `cartWithDetailsProvider`'s `error:` callback silently returns `[]` (empty list). If Firestore is temporarily unavailable, users see an empty cart with no error message — they may think their cart was cleared and re-add items, causing duplicates.
FIX:
```dart
// cart_provider.dart ~line 148:
error: (e, st) {
  Sentry.captureException(e, stackTrace: st);
  throw e; // Rethrow so FutureProvider propagates error state to UI
},
```
Then in `cart_screen.dart`, handle the error state with `AsyncValue.error` to show a retry banner.
```

```
[BONUS] payment_stripe.py:1826
PROBLEM: Per-seller amount computed as `round(item.price * 100) * item.quantity`. Rounding before multiplying can produce a different result from the order-level subtotal which uses `round(sum(price * qty))`. For example, if 3 items at $0.335 each: per-seller = `round(0.335*100)*3 = 34*3 = 102¢`, order subtotal = `round(0.335*3*100) = round(100.5) = 100¢` (banker's rounding). The seller receives 2¢ more than was collected — a silent platform loss at scale.
FIX: Compute per-item amount consistently with how the order total was computed:
```python
amt = round(item.get(Fields.PRICE, 0) * item.get(Fields.QUANTITY, 1) * 100)
```
```

```
[BONUS] order_repository.dart:91
PROBLEM: `watchPaidOrderBySession` filters on `paymentStatus == captured`. In auto-capture mode, `process_checkout_session_completed` writes `CAPTURED` synchronously in the webhook. The `OrderSuccessGate` (payment_screens.dart:41) polls this stream with a 90-second timeout. If the webhook is delayed >90 seconds (Stripe retries at 5s, 30s, 1m intervals), the gate shows the timeout fallback — the buyer sees "Verification Delayed" even though their payment succeeded and the order will eventually confirm. No user-visible recovery CTA to retry the stream.
FIX: After the 90-second timeout, the fallback view should deep-link to `/orders` with a filter for the session_id to find the order once it confirms:
```dart
// payment_screens.dart _buildTimeoutFallback: pass sessionId to orders screen
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.orders,
  (route) => route.isFirst,
  arguments: {'highlightSessionId': widget.sessionId},
);
```
Also increase timeout to 120–150s or implement exponential-backoff polling.
```

```
[BONUS] payment_stripe.py:2098–2111
PROBLEM: `charge_id` retrieval via `stripe.PaymentIntent.retrieve(pi_id)` in `process_checkout_session_completed` adds a synchronous Stripe API call in the webhook hot path. If Stripe API is slow/degraded, this blocks webhook processing and causes Stripe to retry, potentially duplicating side effects. At 100M+ orders, this Stripe round-trip per order is also a significant API cost.
FIX: Extract charge_id from the session object directly using `session.get("payment_intent")` and then `stripe.PaymentIntent.retrieve()` lazily only if `latest_charge` is not embedded. Alternatively, use `stripe.Charge.list(payment_intent=pi_id, limit=1)` which can be paginated and cached. Better: enable charge expansion in the webhook payload:
```python
# In stripe_webhook, before routing:
# Stripe can expand charge in the event:
# stripe listen --expand data.object.payment_intent.latest_charge
# Or use stripe.checkout.Session.retrieve(session_id, expand=['payment_intent.latest_charge'])
```
Short-term fix: catch the PI retrieval failure and enqueue a retry task rather than silently skipping payout.
```

```
[BONUS] cart_repository.dart:57
PROBLEM: `addToCart` uses a deterministic doc ID (`productId` or `productId_variantId`), which prevents a user from having multiple cart entries for the same product variant. However, the `_resolveCartItemId` in `CartController` (cart_provider.dart ~line) still does a Firestore query `where productId == productId`, which is now redundant since the doc ID is deterministic. At scale, these unnecessary queries add Firestore read costs.
FIX: Replace `_resolveCartItemId` with a direct doc reference:
```dart
Future<String> _resolveCartItemId(String userId, String productId, {String? variantId}) async {
  // No query needed — doc ID is deterministic
  return variantId != null ? '${productId}_$variantId' : productId;
}
// And update removeFromCart, updateQuantity, saveForLater to accept optional variantId
```
```

```
[BONUS] checkout_screen.dart:371
PROBLEM: `_CheckoutButton` receives `userModel` passed from `_CheckoutContent`, which was fetched via `userProfileAsync.when(data: ...)`. However, `_CheckoutButton` internally calls `ref.watch(userProfileProvider)` again (if it does). Even if it doesn't, the `items` and `subtotal` are passed from `CheckoutScreen.items` which was set at navigation time — if the cart changes while the user is on the checkout screen (another device), the checkout will use stale item data. The `verify_cart_prices` call is the right guard, but there's no trigger for this on `_CheckoutButton` press.
FIX: Call `verifyCartPrices` in `CheckoutNotifier.startCheckout` before the Stripe session call:
```dart
// In checkout_provider.dart startCheckout, before line 291:
final verifyResult = await _verifyCartPrices(items);
if (verifyResult.hasChanges) {
  state = state.copyWith(isProcessing: false, checkoutError: 'cart.prices_changed'.tr());
  return CheckoutError(message: 'cart.prices_changed'.tr(), code: 'price-changed');
}
```
```

```
[BONUS] payment_stripe.py:593–594
PROBLEM: `if Fields.STATE not in shipping_address and "province" in shipping_address: shipping_address[Fields.STATE] = shipping_address["province"]` — This normalization is applied inside the `if not all_digital` block for physical orders, but an identical normalization appears again at line 642 for digital-only orders. This duplicated normalization is a maintenance hazard. If the canonical field name changes, one branch will be missed.
FIX: Extract normalization to a helper called before the `if not all_digital` branch:
```python
def _normalize_shipping_address(addr: dict) -> dict:
    if Fields.STATE not in addr and "province" in addr:
        addr[Fields.STATE] = addr["province"]
    return addr
shipping_address = _normalize_shipping_address(shipping_address)
```
```

```
[BONUS] buyer-flow.spec.ts:95
PROBLEM: `const hasTax = (await page.getByText(/HST|GST|PST|QST/i).count()) > 0` — This test passes if any tax label is visible on the page, but doesn't verify the **amount** matches the expected Canadian tax rate for the buyer's province. A UI bug showing "GST: $0.00" would pass this test. The test should also verify the tax amount is non-zero and proportional.
FIX: Add structured assertion using order summary semantics:
```typescript
const taxRow = page.locator('[aria-label^="checkout-tax-amount"]').first();
const taxText = await taxRow.textContent();
const taxAmount = parseFloat(taxText?.replace(/[^0-9.]/g, '') || '0');
expect(taxAmount, 'Tax amount must be > 0 for Canadian address').toBeGreaterThan(0);
```
```

# Code Comments Audit — OrignaGTA
**Scope:** All uploaded files across Python (Cloud Functions) and Dart (Flutter) stacks  
**Date:** 2026-02-25  
**Standard applied:** Functions with non-obvious logic require a docstring. Critical paths (payment, auth, lifecycle) require Args + Returns + Raises. Business rules must be explained where they appear.

---

## Summary

| File | Grade | Critical Gaps | Good Patterns |
|---|---|---|---|
| `payment_stripe.py` | B | 8 missing docstrings, 1 misleading comment | Security annotations, cross-ref to line numbers |
| `orders.py` | B+ | 5 missing Raises sections, 1 legacy comment | Multi-seller isolation comments, rate-limit comment |
| `order.py` | B | `subtotal()` undocumented, sparse class docstrings | Pydantic examples, field-level descriptions |
| `product.py` | C+ | Sparse module docstring, 3 validators undocumented | Volume-discount section header |
| `admin.py` | A- | 1 missing docstring on `_log_admin_action` | MFA comment is excellent |
| `cron_jobs.py` | B | Missing explanations on idempotency locks | Module docstring is complete |
| `schema_constants.py` | A | Inconsistent inline comments on some constant groups | Module header, naming convention guide |
| `checkout_provider.dart` | B+ | 3 methods undocumented, comment ordering issue | Haversine, idempotency, circuit-breaker comments |
| `order_repository.dart` | C+ | All `watch*` methods undocumented, no class docstring | arrayContains + whereIn limitation note |
| `seller_orders_viewmodel.dart` | C | Both public methods undocumented, sentinel value unexplained | AppError logging comment |
| `add_product_viewmodel.dart` | C+ | `addProduct` 60+ param method with no docstring | Isolate comment, `compareAtPrice` inline doc |
| `product_repository.dart` | C+ | `createProductAtomic`, `fetchProducts` undocumented | `@Deprecated` annotations are exemplary |

---

## File-by-File Findings

---

### 1. `payment_stripe.py`

#### ❌ Missing docstring: `_get_webhook_secret()` (line 107)
**Current:**
```python
def _get_webhook_secret() -> str:
    global _WEBHOOK_SECRET_CACHE
    if not _WEBHOOK_SECRET_CACHE:
        _WEBHOOK_SECRET_CACHE = get_stripe_webhook_secret()
    return _WEBHOOK_SECRET_CACHE
```
**Fix:**
```python
def _get_webhook_secret() -> str:
    """
    Return the Stripe webhook signing secret, cached in-memory after first read.

    Secrets are loaded from Secret Manager on first call and never re-read
    within the same function instance to avoid repeated IAM round-trips.
    Safe because function instances are short-lived (<= 60 min).
    """
```

#### ❌ Missing docstring: `get_tax_code_for_category()` (line 84)
One-liner with no explanation of the tax code system.
**Fix:**
```python
def get_tax_code_for_category(category_id: int) -> str | None:
    """
    Map a product category ID to a Stripe tax code (e.g., 'txcd_10000000' for general).

    Returns None if the category has no special tax treatment (Stripe uses the
    product-level default). See CATEGORY_TAX_CODE_MAP in config.py for the full map.
    """
```

#### ❌ Missing docstring: `get_rate_limiter()` / `get_transactional()` (lines 117, 125)
Both are lazy-init helpers with zero explanation. Add one-line docstrings.

#### ⚠️ Misleading comment: `confirm_order_receipt` line 100–103
```python
# Backward-compatible wrapper around the canonical capture flow.
# Flutter calls `confirm_order_receipt`; newer code calls `capture_payment` directly.
```
The word "Backward-compatible" conflicts with `CLAUDE.md` rule #0 ("never add backward compatibility handling"). This isn't actually backward compat — it's just a named alias for the same endpoint.  
**Fix:** Replace comment:
```python
# Named alias — Flutter client calls `confirm_order_receipt`; the canonical
# implementation lives in _capture_payment_impl to avoid code duplication.
```

#### ❌ Missing `Raises` sections on all `@https_fn.on_call` handlers
`create_checkout_session`, `capture_payment`, `handle_stripe_webhook` all document their inputs but none document what `HttpsError` codes they can throw. Downstream teams debugging 400/403/503 errors in Sentry need this.

**Fix pattern (apply to every handler):**
```python
Raises:
    HttpsError('unauthenticated'): No auth token
    HttpsError('permission-denied'): Buyer == seller (self-purchase)
    HttpsError('failed-precondition'): Stock out, address not Canadian, email unverified
    HttpsError('resource-exhausted'): Rate limit hit
    HttpsError('internal'): Stripe API failure (captured in Sentry)
```

#### ✅ Good: `_assert_seller_active` has complete Args/Returns/Raises — use as template for all helpers.

#### ✅ Good: `_rollback_checkout` Phase 1 / Phase 2 read-then-write comments are excellent — Firestore transaction ordering is non-obvious.

---

### 2. `orders.py`

#### ❌ Missing `Raises` on `update_order_status` (line 110)
The docstring lists inputs but not the 6+ different `HttpsError` codes it can return.

#### ❌ Missing docstring: `_restore_stock_to_batch()` (line 60)
Has a one-liner description but no Args.
**Fix:**
```python
def _restore_stock_to_batch(batch, items: list) -> None:
    """
    Add Firestore batch operations to restore stock for all physical items in a list.

    For warehouse-fulfilled items, also increments the per-warehouse inventory level.
    Digital items are skipped — they have no physical stock to restore.

    Args:
        batch: Active Firestore WriteBatch to append operations to
        items: List of order item dicts (from order_data[Fields.ITEMS])
    """
```

#### ❌ Missing docstring on `on_order_written` Firestore trigger
This is the most critical function in the file (triggers on every order write) and has no docstring explaining when it fires, what it does, and what fields it watches.

**Fix:**
```python
def on_order_written(event: firestore_fn.Change) -> None:
    """
    Firestore trigger: fires on every create/update/delete of an orders/{orderId} document.

    Responsibilities:
    - Send status-change emails to buyer and seller
    - Send push notifications for shipping events
    - Log order lifecycle events to orders/{orderId}/events subcollection

    Note: This trigger is idempotent — it reads the before/after snapshots and
    only acts when orderStatus or paymentStatus has changed.

    Args:
        event: Firestore Change event containing before/after document snapshots
    """
```

#### ✅ Good: Multi-seller isolation comment (lines 185–200) is thorough and explains the business rule clearly.

#### ✅ Good: `# Block updates on archived orders` inline comment correctly flags intent.

---

### 3. `order.py` (Models)

#### ❌ Missing docstring: `OrderItem.subtotal()`
```python
def subtotal(self) -> float:
    """Calculate item subtotal"""
    return self.price * self.quantity
```
The docstring exists but provides zero additional information beyond the method name. Add the nuance:
```python
def subtotal(self) -> float:
    """
    Item subtotal in CAD (price × quantity).

    Note: This is a float snapshot from purchase time. The canonical
    cents representation for payment processing is stored in the parent
    Order.subtotalCents. Use this only for display.
    """
```

#### ❌ Sparse class docstring on `SellerPayout`
The class only has a `model_config` example but no explanation of the invariant that `netAmountCents == amountCents - platformFeeCents`.
**Fix:**
```python
class SellerPayout(BaseModel):
    """
    Payout record for one seller in an order. All amounts in integer cents.

    Invariant: netAmountCents == amountCents - platformFeeCents
    Platform fee = amountCents × BusinessRules.PLATFORM_FEE_RATIO (currently 2.5%)

    Status flow: pending → processing → paid | failed
    """
```

#### ❌ Missing explanation on `version` / `schemaVersion` fields in `Order`
```python
version: int = Field(default=1, ge=1, description="Optimistic concurrency version — increment on every state mutation")
schemaVersion: int = Field(default=1, ge=1, description="Schema layout version for migration tracking")
```
These descriptions are good, but there is no comment explaining *how* `version` is actually used (i.e., the compare-and-swap pattern expected by the backend). Add an inline comment:
```python
# CONCURRENCY: Backend handlers must read version, increment it, and write with
# a Firestore transaction to prevent lost-update races (e.g., double-capture).
version: int = Field(default=1, ge=1, description="Optimistic concurrency version")
```

#### ✅ Good: All `field_validator` methods have docstrings. Field `description=` strings are used consistently.

---

### 4. `product.py`

#### ❌ Sparse module docstring
```python
"""
Product models for OrignaGTA
"""
```
**Fix:**
```python
"""
Product models for OrignaGTA.

Top-level models:
- Product: Full product document stored in Firestore `products/{productId}`
- SellerDeliveryOption: Per-option shipping config embedded in Product
- ShippingQuantityDiscount: Volume discount thresholds embedded in Product
- ProductVariant / VariantOption: Optional variant system (size, color, etc.)

Lifecycle: draft → under_review → approved → active | rejected | paused | archived
See: schema_constants.ProductLifecycleStatusValues for all states.
"""
```

#### ❌ Missing docstring: `ShippingQuantityDiscount.validate_discount_value_range`
```python
@model_validator(mode="after")
def validate_discount_value_range(self) -> "ShippingQuantityDiscount":
    """Ensure percent discounts don't exceed 100%"""
```
One line is fine for simple validators, but this one should also note `flat_rate` semantics:
```python
    """
    Ensure discount values are in range.
    - percent: 0–100 (enforced)
    - fixed: any positive value (buyer sees $X off)
    - flat_rate: replaces shipping cost entirely (e.g. $5 flat)
    """
```

#### ❌ Missing docstring on `Product.validate_price_vs_compare_at`
This cross-field validator enforces a critical UX invariant (compareAtPrice > price) with no explanation.

---

### 5. `admin.py`

#### ❌ Missing docstring: `_log_admin_action()` helper
This is the audit trail function — it should be the most thoroughly documented helper in the file.
**Fix:**
```python
def _log_admin_action(
    admin_id: str,
    action: str,
    target_id: str,
    details: dict[str, Any],
    db,
) -> None:
    """
    Write an immutable audit log entry to admin_logs/{autoId}.

    Every privileged admin operation (suspend, refund, role change, delete) MUST
    call this before returning. Used for regulatory compliance, fraud investigation,
    and dispute resolution.

    Args:
        admin_id: Firebase UID of the admin performing the action
        action: AdminActionValues constant (e.g. AdminActionValues.SUSPEND_SELLER)
        target_id: The UID/doc ID of the affected resource
        details: Arbitrary context dict (before/after state, reason, etc.)
        db: Firestore client
    """
```

#### ✅ Good: `_require_recent_admin_mfa` docstring is clear and explains the 5-minute window.

---

### 6. `cron_jobs.py`

#### ❌ Missing docstring on cron lock pattern
The distributed cron lock (using `_cron_locks` collection) is used throughout but never explained inline where it's first acquired. Add a block comment at the top of each cron function:
```python
# DISTRIBUTED LOCK: Cloud Scheduler may invoke this function on multiple instances
# simultaneously. We use a Firestore document as a mutex (see utils/cron_lock.py).
# Lock expires after X minutes so a crashed instance doesn't block future runs.
```

#### ❌ `AUTO_CONFIRM_DAYS` and `AUTHORIZATION_VALID_DAYS` used in comparisons without explaining the business rule
When a cron checks `timedelta(days=AUTO_CONFIRM_DAYS)`, a reader needs to understand *why* that number exists. Add:
```python
# AUTO_CONFIRM_DAYS = 7: If buyer hasn't confirmed receipt within 7 days of delivery,
# the system auto-confirms and triggers payout (buyer protection window).
# AUTHORIZATION_VALID_DAYS = 7: Stripe authorizations expire in 7 days by default.
# We check expiry at T-24h and attempt capture before expiry.
```

---

### 7. `schema_constants.py`

#### ⚠️ Inconsistent comment style within class bodies
Some constant groups have inline comments, others don't. Example:
```python
CRON_LOCKS = "_cron_locks"            # ← has no comment
ORDER_EVENTS = "events"               # Subcollection under orders/{orderId}/events/{eventId}  ← has comment
COUPON_USES = "coupon_uses"           # Subcollection under coupons/{couponId}  ← has comment
```
**Fix:** Add `# top-level collection` / `# subcollection: parent/{id}/X` suffix uniformly.

#### ⚠️ `DeliveryItemStatusTransitions` — no class docstring
This class defines the order state machine graph. Without a docstring, developers have to reverse-engineer the valid transitions.
**Fix:**
```python
class DeliveryItemStatusTransitions:
    """
    Valid per-item delivery status transitions (directed graph).

    Each key is a current status; the value list contains allowed next states.
    Enforced in update_item_status to prevent illegal state jumps.

    Graph: pending → shipped → in_transit → delivered | refunded
                   ↘ refunded
    """
```

#### ✅ Good: Module-level docstring with naming convention guide is excellent — follow this pattern for all submodules.

---

### 8. `checkout_provider.dart`

#### ❌ Comment ordering issue: `_shippingCircuitBreaker` (line 38)
```dart
final _shippingCircuitBreaker = CircuitBreakerRegistry.get(...); // declared first
/// Circuit breakers for external service calls                   // comment after
final _stripeCircuitBreaker = CircuitBreakerRegistry.get(...);
```
The `///` doc comment on line 40 applies to `_stripeCircuitBreaker` but appears to describe both. The shipping breaker is completely undocumented.  
**Fix:** Move the comment above both declarations or add individual comments:
```dart
/// Circuit breaker for shipping calculation (Algolia/backend calls).
/// Opens after 3 failures; half-open after 30s.
final _shippingCircuitBreaker = CircuitBreakerRegistry.get('shipping_calc', ...);

/// Circuit breaker for Stripe checkout session creation.
/// Opens after 2 failures; half-open after 60s (payment is higher stakes).
final _stripeCircuitBreaker = CircuitBreakerRegistry.get('stripe_checkout', ...);
```

#### ❌ Missing docstring: `setPaymentProvider()`
```dart
void setPaymentProvider(String provider) {
  if (provider == PaymentProviderValues.stripe) {
    state = state.copyWith(paymentProvider: provider);
  }
}
```
The silent no-op on unknown providers is a potential footgun. Document it:
```dart
/// Set the active payment provider.
///
/// Currently only [PaymentProviderValues.stripe] is accepted; other values
/// are silently ignored (no-op). This guard exists to future-proof for
/// additional providers without crashing.
```

#### ❌ Missing docstring: `removeCoupon()`
One-liner that needs a note about clearing the error state too:
```dart
/// Remove applied coupon and clear any coupon error message.
void removeCoupon() => ...
```

#### ✅ Good: `startCheckout` email verification comment (`// EMAIL VERIFICATION CHECK - CRITICAL BUSINESS LOGIC`) is exactly right — security-critical paths should be annotated this way.

#### ✅ Good: `_generateIdempotencyKey` docstring is the best in the file — explains the design tradeoff.

---

### 9. `order_repository.dart`

#### ❌ No class-level docstring on `OrderRepository` (abstract) or `FirebaseOrderRepository`
```dart
abstract class OrderRepository {
  // No docstring — readers don't know what this abstraction is for
```
**Fix:**
```dart
/// Repository contract for order persistence and real-time subscriptions.
///
/// All write operations that modify payment state or order status are
/// delegated to Cloud Functions (never written directly from client) to
/// enforce server-side validation, rate limiting, and audit logging.
///
/// Read operations use Firestore streams for real-time updates.
abstract class OrderRepository { ... }
```

#### ❌ All `watch*` stream methods are undocumented
`watchBuyerOrders`, `watchSellerOrders`, `watchPaidOrderBySession` have zero docstrings. These are used across multiple screens and the query constraints are non-obvious.

**Fix (example for `watchSellerOrders`):**
```dart
/// Stream of orders where [userId] is one of the selling parties.
///
/// Firestore constraint: `sellerIds arrayContains userId`.
/// **Important:** `.orderBy(createdAt)` is intentionally omitted — Firestore does
/// not allow arrayContains + whereIn + orderBy on a different field in the same
/// query. Results are sorted client-side after fetch.
///
/// Filters: only paid statuses (authorized, captured, disputed, refunded,
/// cancelled, authorizationExpired). Pending + failed orders are excluded
/// until payment is confirmed so sellers never see unpaid orders.
Stream<List<models.Order>> watchSellerOrders(String userId);
```

#### ❌ Missing docstring: `updateLastSession()`
This is not obvious — it persists idempotency state on the user doc.
```dart
/// Persist the latest checkout session ID and order ID on the user document.
///
/// Used by [watchPaidOrderBySession] to detect successful payment redirects.
/// Also prevents duplicate checkout sessions if the user navigates back.
Future<void> updateLastSession(String userId, String sessionId, String orderId);
```

---

### 10. `seller_orders_viewmodel.dart`

#### ❌ No class docstring on `SellerOrdersViewModel`
```dart
class SellerOrdersViewModel extends StateNotifier<SellerOrdersState> {
```
**Fix:**
```dart
/// ViewModel for the Seller Orders screen (/seller/orders).
///
/// Handles shipping updates and per-item status changes for orders
/// where the current user is a seller. All mutations are forwarded
/// to Cloud Functions via [OrderRepository] — never written directly
/// to Firestore from the client.
```

#### ❌ `OrderItemIdValues.all` sentinel unexplained (line 26)
```dart
await repository.updateItemStatus(
  orderId,
  OrderItemIdValues.all,   // ← What is this?
  DeliveryStatusValues.shipped,
  ...
);
```
This is a sentinel value that tells the backend "update all items." Without a comment, this looks like a bug.  
**Fix:**
```dart
// OrderItemIdValues.all is a sentinel that instructs the backend to mark
// every item in this order as shipped in one call — used when a seller
// ships the entire order as a single shipment.
await repository.updateItemStatus(
  orderId,
  OrderItemIdValues.all,
  ...
);
```

#### ❌ Missing docstrings on both public methods
`updateShippingAndCapture` and `updateItemStatus` have no `///` docstrings.
**Fix (example):**
```dart
/// Update the actual shipping cost and mark all items as shipped.
///
/// Step 1 always runs (shipping cost update via Cloud Function).
/// Step 2 (tracking number) is best-effort — a failure is logged but does
/// not fail the overall operation since shipping cost is the critical write.
///
/// [orderId] must belong to the currently logged-in seller.
/// [trackingNumber] may be empty string (skips step 2).
Future<void> updateShippingAndCapture(
    String orderId, double actualShipping, String trackingNumber) async { ... }
```

---

### 11. `add_product_viewmodel.dart`

#### ❌ `addProduct` method (line 37) — 60+ parameter method with no docstring
This is the most complex method in the file and has zero documentation.
**Fix:**
```dart
/// Submit a new product for seller review.
///
/// Validates required fields locally before calling [ProductRepository.createProductAtomic],
/// which uploads images to R2/Cloudflare and writes the product to Firestore in a
/// single atomic Cloud Function call.
///
/// On success the product is created with [lifecycleStatus = under_review] and
/// the seller is notified by email that it's pending admin approval.
///
/// Throws nothing — errors are stored in [AddProductState.errorMessage].
/// Check [AddProductState.isSuccess] to detect completion.
Future<void> addProduct({ ... }) async { ... }
```

#### ❌ `addImage()` (line 35) — no docstring
```dart
void addImage(ImageModel image) => state = state.copyWith(imageModels: [...state.imageModels, image]);
```
**Fix:**
```dart
/// Append [image] to the in-progress product's image list.
/// Images are uploaded when [addProduct] is called, not here.
void addImage(ImageModel image) => ...
```

#### ✅ Good: `_compressImageAddIsolate` top-level comment ("runs in a separate thread") and the `/// Original/crossed-out price` inline doc are excellent examples.

---

### 12. `product_repository.dart`

#### ❌ `createProductAtomic` (line 51) — no docstring for the most important write method
**Fix:**
```dart
/// Create a product via the `create_product_atomic` Cloud Function.
///
/// This is the ONLY valid path to create products. Direct Firestore writes
/// are blocked via the deprecated [addProduct]/[addProductWithId] methods.
///
/// The Cloud Function handles:
/// - Server-side seller ID injection (prevents spoofing)
/// - Image upload to R2/Cloudflare (base64 → URL conversion)
/// - lifecycleStatus = under_review assignment
/// - SKU uniqueness enforcement
///
/// [testImageUrls] bypasses image upload in E2E tests (see INSTRUCTIONS.md §9).
///
/// Returns the Firestore document ID of the newly created product.
Future<String> createProductAtomic(
  Product product,
  List<Uint8List> imageBytes, {
  List<String>? testImageUrls,
}) async { ... }
```

#### ❌ `fetchProducts()` (line 132) — no docstring
This method builds a complex Firestore query and the parameters are not obvious.
**Fix:**
```dart
/// Fetch a paginated page of active products, optionally filtered.
///
/// Uses Firestore cursor-based pagination — pass [lastDocument] to get the
/// next page. Always returns only `lifecycleStatus == active` products;
/// drafts, under-review, and rejected products are never returned here.
///
/// [searchQuery] is a keyword match against the `keywords` array field.
/// For full-text search, use Algolia via the home screen instead.
///
/// Returns [ProductQueryResult] with a [hasMore] flag for infinite scroll.
```

#### ⚠️ `fetchProductsByIds` comment (line 182) is messy
```dart
// Firestore whereIn has a limit of 30 (previously 10, now 30 in some versions, but let's be safe with 10 or 30)
// Actually current limit is 30. Let's use 30.
```
This is internal deliberation left in code. Clean it up:
```dart
// Firestore whereIn limit is 30. Chunk large ID lists to stay within bounds.
```

#### ✅ Good: `@Deprecated` annotations on `addProduct` and `addProductWithId` are exemplary — they explain why, reference the replacement, and set expectations. This pattern should be used everywhere deprecated paths exist.

---

## Cross-Stack Issues

### ❌ Platform fee constant (2.5%) is documented inconsistently
- `order.py` `SellerPayout.platformFeeCents`: described as "in cents" but no mention of the 2.5% source  
- `payment_stripe.py` line ~1200+: `PLATFORM_FEE_RATIO` used in calculation with no adjacent comment  
- `FLOWS.md` §14: "Platform fee = 2.5% per seller subtotal"  

**Fix:** Add a cross-reference at every usage site:
```python
# Platform fee = PLATFORM_FEE_RATIO × seller subtotal (currently 2.5%)
# Source of truth: config.PLATFORM_FEE_RATIO / BusinessRules.PLATFORM_FEE_RATIO
platform_fee_cents = int(seller_subtotal_cents * PLATFORM_FEE_RATIO)
```
And in Dart:
```dart
// Platform fee deducted server-side (see config.PLATFORM_FEE_RATIO = 2.5%)
```

### ❌ `OrderItemIdValues.all` defined in `schema_constants.dart` but never explained
This constant appears in `seller_orders_viewmodel.dart` and presumably in the backend. The schema constants file for both Python and Dart should document it:
```python
class OrderItemIdValues:
    """
    Sentinel values for item ID fields in order operations.

    ALL is a magic sentinel recognized by update_item_status to apply
    the operation to every item in the order at once.
    """
    ALL = "__all__"
```

### ❌ `deliverySpeed` field comment mismatch
`checkout_provider.dart` sends `Fields.deliverySpeed: state.deliverySpeed.value` with comment  
`// Send delivery speed so backend applies correct multiplier`  
But `orders.py` / `payment_stripe.py` never annotate where the multiplier is applied. Add a reciprocal comment in the backend handler:
```python
# Delivery speed multiplier: standard=1.0x, express=1.5x, same_day=2.0x
# Received from Flutter checkout_provider.dart via Fields.DELIVERY_SPEED
delivery_multiplier = DeliverySpeedMultipliers.get(delivery_speed, 1.0)
```

---

## Priority Action List

| Priority | File | Fix |
|---|---|---|
| 🔴 Critical | `orders.py` | Add docstring + Raises to `on_order_written` trigger |
| 🔴 Critical | `order_repository.dart` | Add docstrings to all `watch*` methods and abstract class |
| 🔴 Critical | `seller_orders_viewmodel.dart` | Document `OrderItemIdValues.all` sentinel + both methods |
| 🟠 High | `payment_stripe.py` | Add `Raises` to all `@https_fn.on_call` handlers |
| 🟠 High | `add_product_viewmodel.dart` | Document `addProduct` method |
| 🟠 High | `product_repository.dart` | Document `createProductAtomic` + `fetchProducts` |
| 🟡 Medium | `order.py` | Improve `SellerPayout` class docstring with invariant |
| 🟡 Medium | `schema_constants.py` | Standardize inline comments + `DeliveryItemStatusTransitions` |
| 🟡 Medium | `checkout_provider.dart` | Fix circuit breaker comment ordering + `setPaymentProvider` |
| 🟢 Low | `product.py` | Expand module docstring + lifecycle graph |
| 🟢 Low | `cron_jobs.py` | Add distributed lock pattern explanation |

---

## Recommended Templates

### Python handler template
```python
@https_fn.on_call(**DEFAULT_OPTIONS)
def my_handler(req: https_fn.CallableRequest) -> dict[str, Any]:
    """
    One-sentence summary.

    Longer explanation if non-trivial.

    Request data:
        fieldName (type): description

    Returns:
        {success: True, resultField: value}

    Raises:
        HttpsError('unauthenticated'): No auth token
        HttpsError('permission-denied'): Caller lacks required role
        HttpsError('invalid-argument'): Missing or malformed input
        HttpsError('failed-precondition'): Business rule violation
        HttpsError('resource-exhausted'): Rate limit hit
        HttpsError('internal'): Unhandled exception (see Sentry)
    """
```

### Dart repository method template
```dart
/// One-sentence summary.
///
/// Explain non-obvious query constraints, Firestore limitations,
/// or why Cloud Functions are used instead of direct writes.
///
/// Returns [X] or null if not found.
/// Throws [FirebaseFunctionsException] on function error.
Future<ReturnType> methodName(Type param) async { ... }
```

### Dart stream method template
```dart
/// Real-time stream of [X] for [userId].
///
/// Firestore query: collection.where(field, ...).
/// **Limitation:** [explain any arrayContains / index constraints]
/// **Sort:** [client-side / by field descending]
/// Emits an empty list when no documents match.
Stream<List<X>> watchX(String userId);
```

Let me read all the files first before auditing.Now I have a comprehensive picture. Let me compile the full audit report.Here's the complete audit across all dimensions:

---

## 🔴 CRITICAL: Missing Firestore Indexes (will cause runtime 500 errors)

These queries execute in production but have no supporting composite index:

**1. `orders` [orderStatus + paymentStatus + shippedAt]** — `auto_capture_confirmed_receipts` cron (cron_jobs.py:170). Will silently fail on shipped order payout runs.

**2. `security_alerts` [type + resolved + orderId]** — `capture_payment` dispute check (payment_stripe.py). Blocks payment capture when a dispute check can't run.

**3. `payouts` [orderId + sellerId + status]** — duplicate payout idempotency check in `_capture_payment_impl`. Without this index, every capture could double-pay sellers.

**4. `products` [isDigital + lifecycleStatus]** — `revalidate_digital_product_urls` cron. Digital downloads silently go stale.

**5. `users` [isPremium + notifyTrending]** — `compute_trending_products` cron. Push notifications to premium users stop working.

**6. `users` [roles + marketingOptIn]** — `send_abandoned_cart_emails` cron. Abandoned cart recovery emails never send.

**Fix:** Add to `firestore_indexes.json` and deploy to all 3 environments.

---

## 🔴 CRITICAL: Logic Bugs

**Bug 1 — `_rollback_checkout` uses snapshot math instead of `Increment`** (payment_stripe.py ~line 90)

```python
# CURRENT (WRONG) — race condition, can corrupt stock
patch = {Fields.STOCK_QUANTITY: current_stock + qty}
transaction.update(ref, patch)

# CORRECT — atomic, safe under concurrency
patch = {Fields.STOCK_QUANTITY: _fs.Increment(qty)}
```
Between the snapshot read inside the transaction and the rollback write, another concurrent checkout or cancellation can modify stock. This is the only stock restoration path using arithmetic instead of `Increment`. All other paths (`_add_stock_restore_to_batch`, `process_session_expired`) correctly use `Increment`.

**Bug 2 — `_capture_payment_impl` auto-capture: zero payouts possible** (payment_stripe.py)

When `payment_status == CAPTURED` (set by webhook at checkout), the code creates payouts only for items with `DELIVERED` or `SHIPPED` status. At the time buyer taps "Confirm Receipt," items are still in `PENDING` status unless the seller has explicitly marked them shipped. Result: payout record created with 0 sellers, seller never gets paid. The cron catches this eventually, but only after `AUTO_CONFIRM_DAYS` — meaning sellers wait weeks for payment on fast deliveries.

Fix: When creating payouts in the auto-capture branch, fall back to all items if none are in DELIVERED/SHIPPED state.

**Bug 3 — `process_charge_refunded` partial refund overwrites instead of accumulates**

```python
# Partial refund path stores LAST refund amount, not cumulative
Fields.PARTIAL_REFUND_AMOUNT_CENTS: amount_refunded  # overwrites each time
Fields.CUMULATIVE_REFUNDED_CENTS: amount_refunded     # also wrong (not accumulated)
```
On a second partial refund, both fields are overwritten with only the new amount. `CUMULATIVE_REFUNDED_CENTS` on the second call should be `existing + amount_refunded`, not just `amount_refunded`. This breaks the idempotency check at line ~2718 (`if previously_refunded >= amount_refunded`).

**Bug 4 — `monitor_algolia_sync` floods security_alerts**

Every 15 minutes, if Algolia and Firestore are out of sync (e.g., during a reindex), a new security alert is created via `.add()` (not `.set()`). Over 24 hours this creates 96 duplicate alerts. Add a deduplification check using `.where(Fields.RESOLVED, "==", False).limit(1).get()` before inserting.

**Bug 5 — `process_dispute_closed` (won): re-transfer uses wrong field**

When a dispute is won and transfers are re-created, the code reads `payout_data.get(Fields.STRIPE_ACCOUNT_ID)`. But payout documents store the seller's Stripe account ID under `stripeAccountId` (set via `Fields.STRIPE_ACCOUNT_ID` in `_execute_seller_payouts`). For payouts created before the `sellerStripeAccounts` snapshot feature was added, this field may be missing — silently skipping the re-transfer.

---

## 🟠 HIGH: Schema Sync Issues (database_schema.json out of date)

**Collections in code, not in schema** (schema is incomplete — these need documenting):

`licenses`, `payment_providers`, `coupon_uses` (subcollection of `coupons`), `favorites` (subcollection of `users`), `inventory_levels` (subcollection of `products`), `cron_locks` (schema says `_cron_locks` — name mismatch), `addresses` (subcollection of `users`), `warehouses` (subcollection of `users`), `order_events`, `cart` (subcollection of `users`), `email_logs` / `_mail_logs`

**Collections in schema, not in code** (stale/dead entries):

`webhook_logs` (code uses `webhook_events`), `admin_logs` (not referenced anywhere), `refunds` (code uses `payouts` + `return_requests` for this purpose), `user_security` (not referenced)

**Cron lock naming mismatch:** Schema defines `_cron_locks`, `Collections.CRON_LOCKS` in schema_constants, but `acquire_cron_lock` uses `Collections.CRON_LOCKS` — verify the constant value matches the actual Firestore collection name.

---

## 🟠 HIGH: Infrastructure Cost Concerns

**1. Algolia sync monitor every 15 minutes across 3 envs = 288 function invocations/day**

Each run calls `get_index_stats()` (Algolia `browseObjects` or `indexStats`) — this counts against Algolia's operation quota. On the Free/Build tier, browse operations can trigger overage charges. On dev and staging, this check is useless — change to hourly on non-prod:

```python
# In cron_jobs.py
schedule = "every 1 hours" if CURRENT_ENV != Environment.PRODUCTION else "every 15 minutes"
```

**2. 17 cron jobs × 3 environments = 51 scheduled jobs**

Daily execution count: ~650 Cloud Function scheduler invocations/day just from crons. At Google Cloud Functions pricing (~$0.10/million invocations), this is negligible now, but each invocation spins a cold start. Consider consolidating the 5 daily "every 24 hours" jobs into one scheduled job with internal routing.

**3. `cleanup_orphaned_r2_images` full collection scan**

Streams ALL products (`get_db().collection(Collections.PRODUCTS).select([Fields.IMAGE_URLS]).stream()`) then makes HTTP HEAD requests to R2 for every image URL to validate existence. At 1,000 products × 5 images = 5,000 HTTP requests per run. This should run weekly at most, and ideally be replaced with an R2 lifecycle rule or event-driven cleanup.

**4. `cleanup_stale_rate_limits` every 30 minutes**

Scans the entire `rate_limits` collection to delete old docs. Firestore charges per document read even for deletes. At 500 docs/run × 48 runs/day × 3 envs = 72,000 reads/day purely for cleanup. Consider extending to every 2 hours or using Firestore TTL (available since 2023) on rate limit documents — set a `ttl` timestamp field and let Firestore auto-delete.

---

## 🟠 HIGH: Subscription Idempotency Flaw

In `create_subscription` (subscriptions.py):

```python
idempotency_key=f"premium_sub_{uid}_{datetime.now(UTC).strftime('%Y%m%d%H%M')}",
```

The code comment says "5-minute window," but `%Y%m%d%H%M` only deduplicates within the same **minute**. If a user double-taps at 14:00:59 and 14:01:01, they get two different idempotency keys → two Stripe Checkout Sessions → potentially two subscriptions. The `_NON_SUBSCRIBABLE` status check provides a safety net only if the first session was already completed and synced, which takes a webhook round-trip. Under the race window, both sessions exist simultaneously.

Fix: Use a stable key not based on time — e.g., `f"premium_sub_{uid}"` with a 24-hour window, and handle `IdempotencyError` to return the existing session.

---

## 🟡 MEDIUM: N+1 Database Reads

**1. `process_checkout_session_completed` webhook** (payment_stripe.py) — After payment, iterates items and makes 2 sequential Firestore reads per item (product + seller), plus 1 per unique seller for suspension check. For a 5-item, 3-seller order: 10 reads in a webhook that must complete fast. Batch with `get_all()`.

**2. `_run_auto_capture` cron** (cron_jobs.py:386-401) — For each delivered order, reads `seller_ref.get()` and `sp_doc.get()` individually per seller per order. Batch seller reads at the start of the loop.

**3. Slug uniqueness check** (products.py:1344-1353) — Up to 3 sequential Firestore queries per product creation in a Firestore trigger. With 4-hex-char suffixes (65,536 possibilities) collisions are astronomically unlikely; one attempt is sufficient. Remove the retry loop.

---

## 🟡 MEDIUM: Dart/Flutter Sync Issues

**1. `AlgoliaService.hitToProductMap` dead fallback** — Maps `hit['searchKeywords']` as a fallback for `keywords`, but `algolia_service.py::format_product_for_algolia` stores the field under `Fields.KEYWORDS` only (never `searchKeywords`). The fallback key is never populated — remove it.

**2. `fetchProductsByIds` filters by `lifecycleStatus == active`** — Cart items can reference products that become paused/under_review after being added to cart. This causes them to silently disappear from the cart display rather than showing "currently unavailable." Fetch regardless of status, and show an appropriate badge in the UI.

**3. `AlgoliaProductRepository.updateProduct`** — Calls `sanitizeProductForFirestore(updates)` (a client-side sanitization) for direct Firestore writes. This bypasses Cloud Functions validation. Since sellers can call `updateProduct` directly from the Flutter app (outside of `createProductAtomic`), this is a trust boundary issue. Route all product updates through a Cloud Function.

---

## 🟡 MEDIUM: Security Observations

**1. `create_checkout_session` dedup window race** — The idempotency check queries `PENDING + AWAITING_PAYMENT` orders within `ORDER_DEDUP_WINDOW_SECONDS`. If two requests arrive simultaneously before either order is written, both pass the check and create duplicate orders. The stock transaction will catch the second via atomicity, but two orders will exist with one having `FAILED` status and wasted stock reservation. The idempotency key `f"checkout_{order_id}"` is order-ID-based, so different orders get different keys — the Stripe-level dedup doesn't protect here. Consider using a client-supplied request-level idempotency key (the code reads `client_idempotency_key` but doesn't use it for order dedup).

**2. `admin_logs` collection missing from code** — Schema defines it but no code writes to it. Admin actions (approve/reject product, suspend seller, manual refund) should be recorded in an immutable audit log. Currently only `security_alerts` and `order_events` serve this purpose.

**3. Book source URL stored in license doc** — `license_doc[Fields.BOOK_SOURCE_URL] = book_source_url` stores the raw R2 URL in the license document. If Firestore rules leak or an admin queries licenses, the CDN URL is exposed. This should be resolved at download time via a Cloud Function, not stored directly.

---

## Summary Table

| Severity | Category | Count |
|---|---|---|
| 🔴 Critical | Missing indexes | 6 |
| 🔴 Critical | Logic bugs | 5 |
| 🟠 High | Schema sync | 12 collections |
| 🟠 High | Infrastructure cost | 4 patterns |
| 🟠 High | Subscription race | 1 |
| 🟡 Medium | N+1 reads | 3 locations |
| 🟡 Medium | Dart/Flutter sync | 3 issues |
| 🟡 Medium | Security | 3 observations |

**Top 3 to fix before launch:**
1. Add the 6 missing Firestore indexes — these will cause visible 500 errors in production
2. Fix `_rollback_checkout` to use `Increment` — prevents stock corruption under concurrent load
3. Fix partial refund `CUMULATIVE_REFUNDED_CENTS` accumulation — prevents financial integrity issues

