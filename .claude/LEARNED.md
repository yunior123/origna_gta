# Learned Knowledge Archive

> Historical debugging notes and patterns discovered during development.
> Moved from CLAUDE.md to save tokens. AI agents: load on-demand only.

---

## E2E Testing Infrastructure (Feb 2026)

- **Solo developer** — AI agents are the QA team
- **279 E2E tests** (9 Playwright files) + 288 backend pytest tests
- **`e2e/api-helpers.ts`** — canonical shared module (40+ exports). Never duplicate helpers.
  - `signIn()` — fail-fast, throws if no idToken. Returns `{idToken, localId, ...}` NOT `.token`
  - `ensureSeedData()` — validates emulators have seeded data
  - `fillStripeCheckout()` — handles Stripe Link popup + 3DS iframe
  - `callOk()` throws on error; `callExpectError()` normalizes gRPC codes
  - `patchDoc()` — auto-uses `updateMask.fieldPaths` (prevents full-doc replace)
  - `normalizeErrorCode()` — maps PERMISSION_DENIED → permission-denied, etc.
- **Auth Emulator starts with 0 users** — MUST run `npx ts-node mega-seed.ts` before tests
- **mega-seed.ts** — seeds 76 users, 30 products, cart items, 8 pre-seeded orders
- **Rate limiter bypass** — 100x multiplier when `FUNCTIONS_EMULATOR=true`
- **Firestore REST PATCH** — MUST use `updateMask.fieldPaths` or it replaces entire doc
- **`Bearer owner`** — bypasses all Firestore security rules in emulator
- **seed-uid-map.json** — maps email → UID, must be regenerated when switching seed scripts

### E2E Results (Feb 2026 — Final)
- 266 passed / 0 failed / 1 flaky / 12 intentionally skipped (20.7 min)
- 7 progressive runs: 200 → 243 → 252 → 258 → 262 → 264 → 266

### 12 Root Causes Fixed
1. SERVER_TIMESTAMP in arrays (8 locations) → use `datetime.now(timezone.utc)`
2. Auto-capture paymentStatus always 'captured', never 'authorized'
3. Sellers CANNOT mark delivered — admin/cron only
4. Multi-seller orders block `update_order_status` → use `update_item_status`
5. `_capture_payment_impl` extraction (avoid CallableRequest mismatch)
6. Yahoo product missing isActive boolean
7. signIn returns `{idToken}` not `{token}`
8. Missing payout records in auto-capture idempotent path
9. Rating test pollution (clean existing ratings before test)
10. Webhook URL project ID: `orignagta` (no hyphen)
11. Stock field: `stockQuantity` not `stock`
12. Auto-promote to SHIPPED when all items shipped

---

## Flutter Web Semantics for Playwright (Feb 2026)

- Flutter Web CanvasKit renders to `<canvas>` — standard Playwright locators won't work
- `<flt-semantics>` parallel DOM tree with ARIA attributes
- `SemanticsBinding.instance.ensureSemantics()` in main.dart = always-on semantics
- `flutter-helpers.ts` (280 lines) — canonical selectors
- ModernTextField: renders label as separate Text widget, uses hintText in InputDecoration
- ModernButton: auto-wraps with `Semantics(button: true, label: widget.label)`
- Login form: 2 textboxes (login) / 3 textboxes (signup) — detect with `getByRole('textbox').count()`

### Semantic Labels Per Screen
- **login**: `checkbox-accept-terms`, `btn-forgot-password`, `btn-toggle-auth-mode`
- **home**: `input-home-search`, `btn-clear-search`, `btn-home-privacy-policy`
- **profile**: `btn-sign-in`, `btn-delete-account`, `menu-my-orders`
- **seller_registration**: `chk-seller-terms`, `btn-seller-action`
- **addproduct**: `btn-publish-product`; fields: 'Product Name', 'Description', 'Price (CAD)', 'Stock'
- **product_card**: `product-card-{id}`, `btn-favorite-{id}`, `btn-add-to-cart-{id}`
- **cart**: `btn-info-service-fee`, `btn-info-tax-estimate`; button: 'Proceed to Checkout'
- **checkout**: `btn-edit-address`, `btn-place-order`, `chk-terms-accepted`
- **orders**: `btn-confirm-receipt`, `btn-rate`, `btn-pending-approvals`

---

## Algolia Search Architecture

- `AlgoliaService.isAvailable` — detects empty credentials → routes to Firestore
- `EnvConfig().algoliaIndexName` — `products_emulator` vs `products`
- Text search + available → Algolia (5s timeout, Firestore fallback)
- Category-only/browse → always Firestore (cursor pagination)
- `productRepositoryProvider` → always `AlgoliaProductRepository` (graceful degradation built-in)

---

## Canadian Law Compliance (Feb 2026)

- Full audit: `docs/CANADIAN_LAW_COMPLIANCE_AUDIT.md`
- 12 Canadian laws apply: PIPEDA, Quebec Law 25, CASL, Competition Act, etc.
- Tax rates verified correct for all 13 provinces/territories
- **Top 3 CRITICAL before launch**: GST/HST reg on receipts, CASL email compliance, French for Quebec
- CASL fines up to $10M — emails need physical address + unsubscribe + consent tracking
- Quebec Law 25 — privacy officer + PIA + granular consent
- Bill 96 (Quebec) — French required for consumer content, fines $3K-$30K
- Schema fields needed: `emailConsent`, `consentTimestamp`, `consentMethod`, `marketingOptIn`

---

## .claude/ Infrastructure Summary

- 5 agents, 7 rules, 20 skills, 5 hooks, 15+ commands
- Quality tools: ruff, dart analyze, universal-ctags
- Symbol Map: `docs/SYMBOL_MAP.md` via `scripts/generate-symbol-map.sh`

---

## Logic Failures Fixed (E2E)

- D.2: No `add_product` callable — products via Firestore write + trigger
- G.3: `update_user_role` → `update_user_roles` with `{add, remove, reason}`
- G.4: `delete_user_data` → `delete_account`
- F.1: `callExpectError` didn't normalize gRPC codes
- A.3: `order.subtotal` → `order.subtotalCents` (Firestore stores cents)
- B.4: `mark_shipped` — tolerant assertions for multi-seller shipping gate
- E.2: Double cancel — stock restoration uses `STOCK_RESTORED` flag
