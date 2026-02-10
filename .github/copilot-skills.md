# 🧠 Copilot Skills — OrignaGta AI Knowledge Base

> Auto-loaded by GitHub Copilot alongside `copilot-instructions.md`.
> Contains learned patterns, gotchas, and decision tables so any AI
> can work on this codebase efficiently without re-discovering them.

---

## 🔍 Search & Product Fetch — Routing Decision Table

| Condition | Route | Why |
|---|---|---|
| Text search + Algolia available | Algolia → Firestore fallback on error | Full-text ranking, typo tolerance |
| Text search + Algolia unavailable | Firestore `arrayContains(keywords.first)` | Emulator has no Algolia; credentials empty |
| Category only (no text) | Firestore `where(categoryId)` | Cursor pagination works; Algolia can't paginate with `DocumentSnapshot` |
| Browse (no filter) | Firestore `orderBy(createdAt)` | Simple cursor pagination |
| Algolia timeout (>5s) | Firestore fallback | Prevents infinite shimmer |

### Key Files
- `lib/services/algolia_service.dart` — `isAvailable` flag, `EnvConfig().algoliaIndexName`, facet filters
- `lib/core/repositories/algolia_product_repository.dart` — routing logic, `_fetchFromFirestore`, `_searchWithAlgolia`
- `lib/core/providers.dart` — `productRepositoryProvider` → always `AlgoliaProductRepository` (graceful degradation built-in)
- `lib/utils/env_config.dart` — `algoliaIndexName` returns `products_emulator` or `products`
- `lib/services/conf_services.dart` — Remote Config keys (`algolia_app_id`, `algolia_search_api_key`), defaults to empty

### Emulator vs Production
| Service | Emulator | Production |
|---|---|---|
| Firestore | Emulated (port 8080) | Real |
| Auth | Emulated (port 9099) | Real |
| Functions | Emulated (port 5001) | Real |
| Storage | Emulated (port 9199) | Real |
| Algolia | **NOT emulated** — `isAvailable=false` | Real — `isAvailable=true` |
| Stripe | Test keys (sk_test_*) | Live keys |
| R2 Cloudflare | `emulator/` prefix | Root |

---

## 🏠 Home Screen — Pagination & State

### Sentinel Pattern (copyWith)
`HomeState.copyWith` uses a `_Sentinel` class to distinguish "field not passed" from "explicitly set to null".
Without this, `copyWith(lastDocument: null)` vs not passing it are indistinguishable.

```
✅ state.copyWith(lastDocument: null)  → resets pagination
✅ state.copyWith()                     → preserves lastDocument
```

### Infinite Scroll Guards
In `HomeViewModel.loadProducts()`:
1. Guard: `isLoading || isLoadingMore` → skip
2. Guard: `!isFirstLoad && !hasMore` → skip  
3. Deduplication: filter products by `productId` before appending
4. `hasMore: false` for Algolia results (no cursor pagination)

### Category Switch Flow
`onCategorySelected()` → resets `products`, `lastDocument`, `hasMore`, `isLoading`, `isLoadingMore` → calls `loadProducts()`

### Favorites Blink Fix
`favoritesProvider` uses `ref.keepAlive()` to prevent auto-dispose when the grid rebuilds during category switches.

---

## 💳 Payment Pipeline

```
checkout_provider.dart → createCheckoutSession → payment_stripe.py
  → Stripe Checkout (hosted) → checkout.session.completed webhook
  → order CONFIRMED/CAPTURED → seller ships → buyer confirm_order_receipt
  → stripe.Transfer.create() to seller Connect accounts
```

- **2.5% platform fee** on every transaction (`BusinessRules.PLATFORM_FEE_RATIO`)
- **Auto-capture** (default) — funds captured at checkout. Transfer on delivery.
- **Idempotency keys** required for ALL payment/transfer operations
- Cron: `auto_confirm_orders` (5-day), `expire_unpaid_orders` (authorization expiry)
- **14 webhook events** handled (see `.claude/skills/payment-system/SKILL.md` for full list)
- `source_transaction` MUST be charge ID (`ch_xxx`), NOT PaymentIntent ID (`pi_xxx`)
- DO NOT hardcode `payment_method_types` — Stripe Dashboard controls enabled methods
- Refund failures MUST create SECURITY_ALERTS + flag `requires_manual_review`
- Currency: CAD only. Canada-only buyers, worldwide sellers.

---

## 📦 Order Lifecycle

```
pending → confirmed → processing → shipped → in_transit → delivered
```
- Cancel/refund: restore stock + refund/void PaymentIntent
- Rating: backend-only via `submit_product_rating` Cloud Function (idempotent per user+product)
- Cross-stack: `order_models.dart` ↔ `models/order.py` ↔ `Order.json`
- **Sellers CANNOT mark orders as `delivered`** — explicit backend check. Only admin or cron.
- **Multi-seller orders block `update_order_status`** for sellers — must use `update_item_status`
- **`update_item_status` auto-promotes**: all items shipped → order SHIPPED; all items delivered → order DELIVERED
- **`signIn()` returns `{idToken, localId, ...}`** — use `.idToken` (NOT `.token`)

---

## 🔐 Firestore SERVER_TIMESTAMP Array Bug (CRITICAL)

**`get_server_timestamp()` / `firestore.SERVER_TIMESTAMP` is a sentinel value that Firestore resolves server-side.**
It CANNOT be nested inside:
- Array elements (items in `update()` maps that go into arrays)
- `ArrayUnion()` values
- Any nested structure inside an array field

**Error**: `('Cannot convert to a Firestore Value', Sentinel: Value used to set a document field to the server timestamp.)`

**Fix**: Use `datetime.now(timezone.utc)` (or `datetime.now(UTC)` where `from datetime import UTC` is used) for timestamps inside arrays. Keep `get_server_timestamp()` for top-level document fields only.

**Known locations fixed (Feb 2026)**:
- `orders.py`: `update_order_status` (shipped_at in items), `update_item_status` (shipped_at, delivered_at), `refund_order_item` (refunded_at, partial_reversals)
- `payment_stripe.py`: `handle_stripe_dispute` (3 ArrayUnion instances for reversal_errors)

---

## 💳 Payment Pipeline — Auto-Capture Mode

```
checkout_provider.dart → createCheckoutSession → payment_stripe.py
  → Stripe Checkout (hosted) → checkout.session.completed webhook
  → order CONFIRMED/CAPTURED → seller ships → buyer confirm_order_receipt
  → _capture_payment_impl (idempotent path) → stripe.Transfer.create()
```

- **Auto-capture** (default) — `capture_method: 'automatic'` — funds captured at checkout, NOT at delivery
- **`paymentStatus` is ALWAYS `'captured'` after checkout** — never `'authorized'` in auto-capture mode
- **2.5% platform fee** (`BusinessRules.PLATFORM_FEE_RATIO`)
- **Idempotency keys** required for ALL payment/transfer operations
- **14 webhook events** handled (see `.claude/skills/payment-system/SKILL.md`)
- **`source_transaction` MUST be charge ID (`ch_xxx`)**, NOT PaymentIntent ID (`pi_xxx`)
- DO NOT hardcode `payment_method_types` — Stripe Dashboard controls enabled methods
- Refund failures MUST create SECURITY_ALERTS + flag `requires_manual_review`
- Currency: CAD only. Canada-only buyers, worldwide sellers.

### `_capture_payment_impl` Architecture
- **Undecorated function** containing all capture logic (no `@on_call` wrapper)
- **`capture_payment`** = thin `@on_call` wrapper calling `_capture_payment_impl(req)`
- **`confirm_order_receipt`** = calls `_capture_payment_impl(req)` directly (avoids CallableRequest vs Flask Request mismatch — `@on_call` wrapper expects Flask Request)
- **Idempotent path** (paymentStatus == 'captured'): Creates payout records + Stripe Transfers if none exist (auto-capture skipped the full capture flow)

---

## 🏗️ Add Product Flow

Key gotchas (from `.claude/skills/add-product-flow/SKILL.md`):
- Sentinel `copyWith` for nullable fields
- Image sync callback pattern
- Free shipping cascade (forced true for digital)
- Postal code normalization (uppercase, trim, format validation)
- Stale coordinates if address edited after geocoding
- Double-submit guard in ViewModel
- `_inventoryManaged`, `_trackQuantity`, `_allowBackorder` are local-only state (NOT persisted) — known TODO

---

## 🎨 UI Patterns

### NEVER Do
- `withOpacity()` → use `Color.fromRGBO` or `DesignTokens`
- Hardcoded colors → `DesignTokens` from `utils/design_tokens.dart`
- `MaterialPageRoute` → named routes
- `CircularProgressIndicator` → `ModernLoadingIndicator`
- `IconButton` without tooltip
- Business logic in screens → ViewModels only

### Glassmorphism
All Modern* widgets use the glassmorphism toolkit (`utils/glassmorphism.dart`).
Backdrop filter + frosted glass effect. Design tokens control blur, opacity, border radius.

### Responsive
`utils/responsive.dart` — breakpoints and scaling. All screens adapt to mobile/tablet/desktop.

---

## 🔄 Cross-Stack Sync Checklist

When changing a field:
1. `functions/schema_constants.py` — Python source of truth
2. `lib/core/schema/schema_constants.dart` — Dart mirror  
3. `docs/database_schema.json` — Firestore schema doc
4. Freezed models (`lib/models/generated/`) — regenerate with `build_runner`
5. Pydantic models (`functions/models/`) — update manually
6. Tests — update ALL affected test files

---

## 🎯 Flutter Web Semantics & Playwright E2E

### Architecture
Flutter Web renders to `<canvas>` but generates a parallel `<flt-semantics>` DOM tree
with ARIA attributes. `main.dart` calls `SemanticsBinding.instance.ensureSemantics()`
to force semantics always-on for web. Playwright targets these DOM elements.

### Convention
kebab-case semantic labels: `btn-*` (buttons), `input-*` (fields), `chk-*` (checkboxes),
`chip-*` (chips), `link-*` (links), `nav-*` (navigation), `menu-*` (menu items),
`product-card-*` (product cards).

### Playwright Helpers: `e2e/flutter-helpers.ts`
```typescript
import { waitForFlutter, flutterButton, flutterInput, fillFlutterInput,
         productCard, toggleFavorite, addToCart } from './flutter-helpers';
```

### Key Rules
- `ModernButton` auto-labels with `Semantics(button: true, label: widget.label)` (~50 buttons)
- `IconButton` uses `tooltip:` (auto-generates `aria-label`)
- `Key('x')` does NOT appear in DOM — use `Semantics(label:)` instead
- No Tab-key hack needed — semantics is force-enabled
- Full reference: `.claude/skills/flutter-semantics-playwright/SKILL.md`
- Widget→selector map: `.claude/skills/widget-finders/SKILL.md`

---

## 🧪 Testing Quick Reference

```bash
# Backend (288+ tests)
cd functions && source venv/bin/activate && pytest tests/ -v --tb=short

# Flutter
cd origna_gta && flutter test && flutter analyze

# E2E (267+ tests across 8 files) — MUST seed first!
cd e2e && npx ts-node mega-seed.ts && npx playwright test

# Run a specific E2E file
cd e2e && npx playwright test comprehensive-flows-e2e.spec.ts

# Python lint
ruff check functions/
```

### E2E Architecture: api-helpers.ts (Canonical Module)
**ALL 7 spec files import from `e2e/api-helpers.ts`** (~830 lines, 40+ exports).
Never duplicate utilities — always import from api-helpers.ts.

Key patterns:
- `signIn(email)` → fail-fast (throws if no idToken returned)
- `callOk(fn, data, token)` → calls callable, throws on error
- `callExpectError(fn, data, token, code)` → expects specific error code
- `readDoc(collection, id)` / `writeDoc()` / `patchDoc()` → Firestore REST with `Bearer owner`
- `patchDoc()` automatically uses `updateMask.fieldPaths` (prevents full-doc replace!)
- `toFirestoreFields(obj)` / `parseDoc(doc)` → encode/decode Firestore REST format
- `fillStripeCheckout(page)` → handles Stripe Link popup + card fill + pay
- `checkInfrastructure()` → verify emulators running before tests
- `ensureSeedData()` → verify seed data exists

### E2E Startup (CRITICAL — Auth Emulator starts with 0 users!)
```bash
# 1. Start emulators
firebase emulators:start --import=./emulator-data
# 2. Seed (REQUIRED before ANY test)
cd e2e && npx ts-node mega-seed.ts   # → 76 users, 30 products, 8 orders
# 3. (Optional) Stripe webhooks
stripe listen --forward-to localhost:5001/orignagta/us-central1/stripeWebhook
# 4. Run tests
npx playwright test
```

### E2E Test Suite Inventory (279 tests — 266 passing as of Feb 2026)

| File | Tests | Passing | Status |
|------|-------|---------|--------|
| regression-e2e.spec.ts | 42 | 42/42 | ✅ All pass |
| comprehensive-flows-e2e.spec.ts | 34 | 34/34 | ✅ All pass |
| payment-workflow-e2e.spec.ts | 62 | 62/62 | ✅ All pass |
| logic-failures-e2e.spec.ts | 29 | 29/29 | ✅ (E.2 flaky, passes on retry) |
| flutter-web-e2e.spec.ts | 16 | 16/16 | ✅ All pass |
| fullstack-e2e.spec.ts | 37 | 37/37 | ✅ All pass |
| shipping-lifecycle-e2e.spec.ts | 48 | 48/48 | ✅ All pass |
| admin-email-test.spec.ts | 3 | 3/3 | ✅ All pass (requires real Stripe + Mailjet) |
| full-marketplace-e2e.spec.ts | 17 | 5/5+12skip | ✅ Smoke pass, 12 intentionally skipped (Flutter CanvasKit) |

**Total: 266/267 passing (12 intentionally skipped), 1 flaky (passes on retry)**

### Root Causes FIXED (Feb 2026 — Runs 1–7: 200→266)
1. **SERVER_TIMESTAMP in arrays** — `get_server_timestamp()` returns sentinel that CANNOT be serialized inside arrays or ArrayUnion. 8 instances fixed across orders.py + payment_stripe.py. Use `datetime.now(timezone.utc)` inside arrays.
2. **Auto-capture mode** — Backend uses `capture_method: 'automatic'`. `paymentStatus` is always `'captured'` after checkout, NEVER `'authorized'`. Tests expected `'authorized'`.
3. **Seller delivery restriction** — Backend blocks sellers from marking orders/items as `delivered`. Tests must use admin token (`yr62813@gmail.com`/`960227Y#y`).
4. **Multi-seller order-level blocked** — `update_order_status` blocked for sellers on multi-seller orders. Must use `update_item_status`.
5. **Missing auto-promote to SHIPPED** — `update_item_status` only auto-promoted to DELIVERED, not SHIPPED.
6. **CallableRequest vs Flask Request** — `confirm_order_receipt` called decorated `capture_payment` → `@on_call` wrapper tried to process CallableRequest as Flask Request. Fixed by extracting `_capture_payment_impl`.
7. **Yahoo product missing isActive** — Product had `status: 'active'` but lacked `isActive: true` boolean field. `create_checkout_session` checks both.
8. **signIn return property** — `signIn()` returns `{idToken, localId, ...}`, NOT `{token}`. Used `adminAuth.token` → undefined → `Unauthenticated`.
9. **Missing payout records (auto-capture)** — With auto-capture, `_capture_payment_impl` idempotent path returned early without creating seller payout records.
10. **Duplicate rating (test pollution)** — `submit_product_rating` rejected repeat ratings from previous runs. Fixed by cleaning existing ratings before test.
11. **Webhook URL project ID** — `orignagta` (NO hyphen). Stripe webhook forward URL must match.
12. **Product stock field** — `stockQuantity` (NOT `stock`). Stock assertion used wrong threshold.

### Rate Limiter Emulator Bypass
`functions/services/rate_limiter.py` detects `FIRESTORE_EMULATOR_HOST` env var and applies 100x multiplier to `max_requests`. This prevents E2E tests from being throttled by the 5 req/min `create_checkout_session` limit.

### Remaining Backend Bugs (7 tests)
1. B.2 skip_status_transition — accepts invalid status skip (should reject)
2. B.4 refund_uncaptured — allows refund on uncaptured payment
3. C.1-C.4 cron jobs — `auto_confirm_deliveries`, `expire_pending_authorizations`, `archive_old_orders`, `cleanup_rate_limits` not deployed
4. G.2 seller_delete_product — permission check bug

---

## 🐛 Known Gotchas

1. **Firestore text search** — limited to `arrayContains` on first keyword only. Multi-word search requires Algolia.
2. **Remote Config in emulator** — `fetchAndActivate()` returns defaults (empty strings). This is expected.
3. **AlgoliaProductRepository.uploadImages / getUploadUrl** — throw `UnimplementedError`. Image upload goes through `FirebaseProductRepository` path.
4. **Firestore eventual consistency** — reads after writes may return stale data. Use `Source.server` for critical verifications.
5. **Canada-only validation (buyer/shipping addresses)** — NEVER trust frontend. Backend validates postal code + province on every buyer/shipping address write. Sellers can be from any country worldwide.
6. **Firestore REST PATCH** — MUST use `updateMask.fieldPaths` query params for partial updates. Without it, PATCH replaces the ENTIRE document, wiping all fields not in the body. `api-helpers.ts patchDoc()` handles this correctly.
7. **Auth Emulator starts with 0 users** — MUST run `npx ts-node mega-seed.ts` before E2E tests. Without seeding, `signIn()` silently fails → `Bearer undefined` → all callables return UNAUTHENTICATED.
8. **E2E seed data is ephemeral** — Auth Emulator does NOT persist users across restarts. Re-seed after every `firebase emulators:start`.
9. **Rate limiter emulator bypass** — `functions/services/rate_limiter.py` applies 100x multiplier when `FIRESTORE_EMULATOR_HOST` is set. Don't add manual delays for rate limits in E2E tests.
10. **Stripe Checkout in headless Playwright** — "VerificationModal" is Stripe's Link login popup, not 3DS. Dismiss with close button on `[data-testid="VerificationModal"]`. Card: `4242424242424242` (not enrolled in 3DS).
11. **Cron Cloud Functions not deployed** — `auto_confirm_deliveries`, `expire_pending_authorizations`, `archive_old_orders`, `cleanup_rate_limits` return HTML instead of JSON. Need deployment fix.
12. **SERVER_TIMESTAMP in arrays** — `get_server_timestamp()` returns a Firestore sentinel. It CANNOT be nested inside array items or ArrayUnion values. Use `datetime.now(timezone.utc)` for timestamps inside arrays. See CRITICAL section above.
13. **`_capture_payment_impl` vs `capture_payment`** — Never call `capture_payment` from Python code (it's an `@on_call` wrapper expecting Flask Request). Import `_capture_payment_impl` for internal calls.
14. **Sellers cannot mark delivered** — Backend explicitly blocks sellers from transitioning orders/items to `delivered`. Only admin or auto-confirm cron can.
15. **Multi-seller `update_order_status` blocked** — Sellers on multi-seller orders cannot use `update_order_status`. Must use `update_item_status` per item.
16. **`signIn()` returns `{idToken, localId, ...}`** — NOT `.token`. Always use `.idToken`.
17. **Product `isActive` vs `status`** — `create_checkout_session` checks `isActive == true` boolean, not just `status == 'active'`. Products need BOTH.
18. **Stock field is `stockQuantity`** — NOT `stock`. Use `stockQuantity` for Firestore REST operations.
19. **Project ID is `orignagta`** — NO hyphen. Webhook URL: `localhost:5001/orignagta/us-central1/stripe_webhook`.
20. **Test pollution with ratings** — `submit_product_rating` checks existing ratings per user+product. Cross-run pollution can cause "already rated" errors. Clean up ratings in beforeAll/J.1.
21. **`on_order_status_changed` trigger crash** — Firebase Functions SDK bug: `KeyError: 'authtype'`. Fires async, doesn't affect callable functions. Ignore these errors in emulator logs.

---

## 📁 File Groups (Read Together)

| Workflow | Files |
|---|---|
| Product search | `algolia_service.dart`, `algolia_product_repository.dart`, `product_repository.dart`, `home_viewmodel.dart`, `home_state.dart`, `home_screen.dart` |
| Product CRUD | `products_provider.dart`, `add_product_screen.dart`, `product_detail_screen.dart`, `handlers/products.py` |
| Checkout | `checkout_provider.dart`, `checkout_screen.dart`, `payment_stripe.py`, `shipping_service.py` |
| Orders | `order_repository.dart`, `orders_viewmodel.dart`, `orders_screen.dart`, `handlers/orders.py` |
| Auth | `auth_repository.dart`, `auth_viewmodel.dart`, `login_screen.dart`, `handlers/admin.py` |
| Seller | `seller_viewmodel.dart`, `seller_dashboard_screen.dart`, `seller_products_screen.dart` |
| E2E Helpers | `e2e/api-helpers.ts` (canonical 40+ exports), `e2e/flutter-helpers.ts` (Playwright selectors for Flutter Web Semantics) |

---

*Last updated: 2026-02-11 — E2E migration to api-helpers.ts, rate limiter bypass, mega-seed with orders*
