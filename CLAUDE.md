# CLAUDE.md

## ⚠️ PRIORITY #1 — ABSOLUTE

**Logic correctness above ALL. NOTHING is more important.**
- Create 50+ adversarial break scenarios for every code change
- Think like a malicious seller, a malicious buyer, a race condition
- Trace every code path. If logic is wrong, don't move on.

---

## RULES

0. **Logic first** — stress-test with 50+ adversarial scenarios before shipping
1. **Ask before running subagents** — don't launch agents without user consent
2. **Hide thinking** — show only actions and results. Save tokens.
3. **"save"/"remember"** → persist to CLAUDE.md LEARNED section immediately
4. **Match Yunior's language** — respond in whichever language he uses
5. **No new markdown files** unless explicitly asked
6. **Consult @docs/WORKFLOW_INDEX.md** before editing ANY file
7. **Cross-stack impact check** after every edit — Python ↔ Dart ↔ Schema
8. **Use `/pause-work` before ending** a long task — saves state for resume
9. **Delegate investigation** to subagents — preserve main context for action
10. **Use constants instead of magic strings all over, strong json schema contract.

---

## About Me (Yunior Rodriguez Osorio)

**Solo founder-developer** building OrignaGta. Staff engineer level, self-taught.
- **Action over discussion** — "just do it, show me the result"
- Short, direct, bullet points. No filler. Pick best solution and do it.
- Fix errors silently. Don't apologize. Be his **second brain**.

---

## PROJECT

**OrignaGta** — E-commerce marketplace serving Canadian buyers, with sellers worldwide. Scale: 100M+ users/year. Launch: March 2026.

**Tech:** Flutter (Web/Android/iOS) + Firebase + Stripe Connect Express + R2 Cloudflare + Geoapify + Algolia + Sentry + Mailjet + Riverpod

---

## ARCHITECTURE (NON-NEGOTIABLE)

1. MVVM only. Frontend = no business logic.
2. APIs replaceable by editing service files only
3. Idempotency required for all payments/transfers
4. Buyer addresses/shipping Canada-only enforced backend-first (sellers can be worldwide)
5. Assume eventual consistency. Minimize DB reads/writes.
6. **Changing one line → update EVERY file that line impacts** (Tests, Rules, Indexes, Schema, Deploy)

---

## CROSS-STACK MAP

| Concept | Frontend (Dart) | Backend (Python) | Schema |
|---------|-----------------|-------------------|--------|
| Schema constants | `lib/core/schema/schema_constants.dart` | `functions/schema_constants.py` | `docs/database_schema.json` |
| Order model | `lib/models/generated/order_models.dart` | `functions/models/order.py` | `docs/json_schemas/individual/Order.json` |
| Product model | `lib/models/generated/product_models.dart` | `functions/models/product.py` | `docs/json_schemas/individual/Product.json` |
| User model | `lib/models/generated/user_models.dart` | `functions/models/user.py` | `docs/json_schemas/individual/User.json` |
| Payment flow | `lib/features/checkout/checkout_provider.dart` | `functions/handlers/payment_stripe.py` | — |
| Order lifecycle | `lib/features/orders/*.dart` | `functions/handlers/orders.py` | `docs/diagrams/state-order-lifecycle.puml` |
| Shipping | `lib/features/checkout/checkout_provider.dart` | `functions/shipping_service.py` | — |
| Products | `lib/features/products/*.dart` | `functions/handlers/products.py` | — |
| Auth/Seller | `lib/features/auth/*.dart`, `lib/features/seller/*.dart` | `functions/handlers/admin.py` | — |

---

## @IMPORTS — Deep Context (loaded on demand)

@docs/WORKFLOW_INDEX.md
@docs/REPO_MAP.md
@docs/AGENT_GUIDE.md
@docs/ENVIRONMENT.md
@docs/SYMBOL_MAP.md

---

## AGENT RULES (MANDATORY)

- **Before editing 3+ files** → run `logic-auditor` FIRST
- **After editing payment files** → run `payment-auditor` IMMEDIATELY
- **After editing schema_constants** → run `schema-sync-checker` IMMEDIATELY
- **After editing order handler** → run `order-lifecycle-auditor` IMMEDIATELY
- **Any CRITICAL findings** → fix before committing. 0 CRITICAL → proceed.

See @docs/AGENT_GUIDE.md for full agent usage guide, workflow chunking, and session management.

---

## WORKFLOW COMMANDS

| Command | Purpose |
|---------|---------|
| `/plan-task [description]` | Break complex task into phases with verification |
| `/execute-plan` | Execute current plan phase-by-phase |
| `/pause-work` | Save current progress + state for later resume |
| `/resume-work` | Restore state and continue where you left off |
| `/investigate [topic]` | Delegate research to a subagent |
| `/create-skill [name]` | Capture current approach as a reusable skill |
| `/audit-workflow [name]` | Full logic audit on a workflow |
| `/check-schema-sync` | Verify all 6 schema layers in sync |
| `/cross-stack-check` | Compare all frontend ↔ backend pairs |
| `/commit-push [msg]` | Stage, commit, push with smart message |
| `/test-all` | Run all test suites |
| `/deploy [env]` | Full deploy pipeline |
| `/clear-context` | Pre-clear safety checklist + context hygiene |

---

## LEARNED (Persistent Knowledge)
Be serious, audit logic, json schema, use logic, cross stack agents, check the hole logic of the project in parallel, add all issues to tasks list. no hardcoded values no magic strings, this is serious, they nuke entire projects. Most of the bugs are related to logic, incomplete work, hardcoded values instead of constants or enums. Verify the payment system backend and frontend, thats important.

### E2E Testing Infrastructure (Feb 2026)
- **Solo developer** — Yunior is building this alone. AI agents (Copilot, Claude, Gemini) are the QA team. All E2E scenarios MUST be fully covered by automated tests — no manual testing is feasible.
- **267 E2E tests** across 8 Playwright files + 288 backend pytest tests
- **`e2e/api-helpers.ts`** — **CANONICAL** shared module for ALL E2E test helpers (created Feb 2026). All spec files import from here. NEVER duplicate helpers in spec files.
  - **Fail-fast `signIn()`** — throws immediately if auth emulator returns no `idToken` (missing seed data). Prevents cascading "Unauthenticated" failures.
  - **`ensureSeedData()`** — validates Auth + Firestore emulators have seeded users before tests run. Call in `test.beforeAll` for fast failure diagnosis.
  - **`fillStripeCheckout()`** — handles Stripe "Link" login popup, 3DS iframe, and generic modal overlay dismissal in headless Chromium.
  - **`callCallable()`** returns raw body; **`callOk()`** throws on error; **`callExpectError()`** normalizes gRPC status codes (PERMISSION_DENIED→permission-denied, etc.) and returns the error for assertion.
  - **`patchDoc()`** supports both `(path, fields)` and `(collection, docId, fields)` signatures.
  - **`normalizeErrorCode()`** — maps Firebase emulator gRPC statuses (PERMISSION_DENIED, FAILED_PRECONDITION, NOT_FOUND, etc.) to Firebase-style codes (permission-denied, failed-precondition, not-found). Critical because emulators return `error.status` NOT `error.code`.
  - **Additional helpers**: `getOrder()`, `getProductStock()`, `uid()`, `queryFirestore()` for cross-spec convenience.
- **Root cause of ~61 "Unauthenticated" failures**: Auth Emulator had 0 users (emulator restarted without `--import`). `signIn()` silently returned no `idToken` → `Bearer undefined` → token rejected. NOT a protocol or project ID mismatch.
- **Root cause of error code assertion failures**: Firebase v2 callable emulator returns `{ error: { status: "PERMISSION_DENIED" } }` but tests asserted `error.code === "permission-denied"`. Fixed by `normalizeErrorCode()` in `callExpectError()`.
- **E2E Test Results (Feb 2026 — Run 7 FINAL)**:
  - **266 passed / 0 failed / 1 flaky / 12 intentionally skipped** (20.7 min)
  - Total: **279 tests** across 9 spec files
  - 7 progressive runs: 200 → 243 → 252 → 258 → 262 → 264 → 266 passed
  - **12 root causes fixed**: SERVER_TIMESTAMP in arrays (8 locations), auto-capture paymentStatus, seller delivery restriction, multi-seller order-level block, auto-promote SHIPPED, `_capture_payment_impl` extraction, Yahoo product isActive, signIn idToken property, payout records in idempotent path, rating test pollution, webhook URL project ID, stock field name
  - **CRITICAL BUG discovered**: `get_server_timestamp()` (Firestore sentinel) CANNOT be nested in arrays or `ArrayUnion()`. Use `datetime.now(timezone.utc)` instead. 8 locations fixed in orders.py + payment_stripe.py.
  - **Architecture fix**: Extracted `_capture_payment_impl(req)` (undecorated) from `capture_payment` so `confirm_order_receipt` can call it without Flask/CallableRequest mismatch.
  - **Auto-capture mode**: `paymentStatus` is always `'captured'` after checkout — never `'authorized'`.
  - See `.claude/skills/e2e-debugging/SKILL.md` for complete debugging methodology.
- **`mega-seed.ts`** — seeds 76 users, 30 products, cart items, AND 8 pre-seeded orders (`order_test_001`-`008`) for regression tests. MUST run after emulators start: `cd e2e && npx ts-node mega-seed.ts`
- **Rate limiter emulator bypass** — `services/rate_limiter.py` multiplies `max_requests` by 100x when `FUNCTIONS_EMULATOR=true`. Prevents test throttling while keeping production limits strict.
- **Firestore REST PATCH** — MUST use `updateMask.fieldPaths` query params for partial updates, otherwise it REPLACES the entire document (wiping all fields not included in the PATCH body)
- **`Bearer owner`** — bypasses ALL Firestore/Auth security rules in emulator mode. Use for tooling scripts only.
- **Auth Emulator** — does NOT support GET on `/emulator/v1/projects/{id}/accounts`. To list users, query Firestore `/users` collection via REST with `Bearer owner` instead.
- **`seed-uid-map.json`** — maps email → Firebase Auth UID for `seed-orders.py`. MUST be regenerated when switching between `mega-seed.ts` (76 users) and `seed-emulator.ts` (25 users). Stale UIDs cause order seed failures and cascading test breaks.
- **Test ordering** — tests within a file run sequentially and modify shared Firestore data. If test C modifies a document, test G must restore it before asserting.
- **Stripe Checkout UI in headless** — "VerificationModal" overlay is likely Stripe's "Link" login popup (NOT 3DS — card 4242424242424242 is not enrolled). `fillStripeCheckout()` in `api-helpers.ts` handles this with modal dismissal logic.
- **patchDoc() in E2E** — must construct `updateMask.fieldPaths` from all fields being patched, not rely on Firestore's default merge behavior (REST API ≠ SDK).

### Flutter Web Semantics for Playwright E2E (Feb 2026)
- **Root cause of 12 permanently skipped tests**: Flutter Web CanvasKit renders to `<canvas>`, NOT DOM. Standard Playwright locators (`getByRole`, `getByLabel`, `getByText`) cannot interact with Flutter widgets rendered on canvas.
- **Solution**: Flutter generates a parallel `<flt-semantics>` DOM tree with ARIA attributes when semantics is active. `SemanticsBinding.instance.ensureSemantics()` in `main.dart` makes semantics always-on for web → no Tab key hack needed.
- **`flutter-helpers.ts`** (280 lines) — canonical helpers for Flutter Web semantics: `waitForFlutter()`, `flutterButton(page, label)`, `flutterInput(page, label)`, `flutterCheckbox(page, label)`, `flutterByLabel()`, `flutterByExactLabel()`, `productCard(page, id)`, `addToCart()`, `fillFlutterInput()`, `clickFlutterButton()`, `waitForSemanticLabel()`, `navigateToRoute()`.
- **ModernTextField caveat**: Does NOT use `InputDecoration.labelText` — renders label as a separate `Text()` widget above the field and uses `hintText` in InputDecoration. This means `getByRole('textbox', {name: 'Email'})` WON'T work. **Workaround**: use positional `getByRole('textbox').first()` / `.nth(1)` or `page.locator('flt-semantics input')`.
- **ModernButton**: Auto-wraps with `Semantics(button: true, label: widget.label)` → `flutterButton(page, 'Sign In')` works.
- **Login form pattern**: In login mode, 2 textboxes (email + password). In signup mode, 3 textboxes (name + email + password). Use `getByRole('textbox').count()` to detect mode.
- **Rewritten tests**: `full-marketplace-e2e.spec.ts` — 12 tests now use semantics + API hybrid approach. Removed `RUN_FULL_E2E` gate. Kept conditional skip for `!infra.webApp` + `!emuInfra.auth`.
- **J.2 NOT actually skipped**: `comprehensive-flows-e2e.spec.ts` test "Digital product has zero shipping cost" has `if (!PRODUCT_DIGITAL) { test.skip(...) }` but `PRODUCT_DIGITAL = 'product_010'` (truthy) → skip NEVER triggers. Product IS seeded with `isDigital: true` in mega-seed.
- **Test credentials updated**: `full-marketplace-e2e.spec.ts` now uses `TEST_ACCOUNTS.SELLER1_EMAIL` / `TEST_ACCOUNTS.BUYER1_EMAIL` / `TEST_ACCOUNTS.ADMIN_EMAIL` from api-helpers (matching mega-seed), NOT the old hardcoded emails.
- **Semantic labels per screen** (for writing new E2E tests):
  - **login_screen**: `checkbox-accept-terms`, `btn-forgot-password`, `btn-toggle-auth-mode`; buttons: `'Sign In'`, `'Create Account'`, `'Google'`; hints: `'you@example.com'`, `'••••••••'`
  - **home_screen**: `input-home-search`, `btn-clear-search`, `btn-home-privacy-policy`, `btn-home-terms-of-service`; tooltips: `'Add product'`, `'Shopping cart'`, `'Settings'`
  - **profile_screen**: `btn-sign-in`, `btn-delete-account`, `menu-my-orders`, `menu-addresses`; `link-email-support`, `link-website`; button: `'Sign Out'`
  - **seller_registration**: `chk-seller-terms`, `btn-seller-action`; buttons: `'Start Seller Registration'`, `'Retry Stripe Setup'`, `'Go to Dashboard'`
  - **addproduct_screen**: `btn-publish-product`; TextFormField labelText: `'Product Name'`, `'Description'`, `'Price (CAD)'`, `'Stock'`
  - **product_card**: `product-card-{productId}`, `btn-favorite-{productId}`, `btn-add-to-cart-{productId}`
  - **productdetails**: `btn-product-qty-minus`, `btn-product-qty-plus`; button: `'Add to Cart'`
  - **cart_screen**: `btn-info-service-fee`, `btn-info-tax-estimate`, `btn-delivery-instructions`; button: `'Proceed to Checkout'`
  - **checkout_screen**: `btn-edit-address`, `btn-place-order`, `btn-add-address`, `chk-terms-accepted`, `link-terms-conditions`, `btn-delivery-speed-standard`/`express`/`sameDay`
  - **orders_screen**: `btn-confirm-receipt`, `btn-rate`, `btn-pending-approvals`
- **E2E Test Results updated**: 279 tests → 12 no longer permanently skipped, now conditional on infra.

- **E2E logic-failures fixes applied**:
  - **D.2**: No `add_product` callable — products created via Firestore write + `on_product_created` trigger. Test rewritten to verify trigger deactivates product for suspended sellers.
  - **G.3**: `update_user_role` → `update_user_roles` with `{add: ['seller'], remove: [], reason: '...'}` payload.
  - **G.4**: `delete_user_data` → `delete_account`.
  - **F.1**: `refund_order_item` was correct but `callExpectError` didn't normalize gRPC codes. Fixed by `normalizeErrorCode()`.
  - **A.3**: `order.subtotal` → `order.subtotalCents`, `order.platformFee` → `order.platformFeeCents` (Firestore stores cents).
  - **B.4**: `mark_shipped` — added tolerant assertions for multi-seller shipping gate.
  - **E.2**: Double cancel — stock restoration uses `STOCK_RESTORED` flag, second cancel rejected by state machine.

### Algolia Search Architecture
- **`AlgoliaService.isAvailable`** — detects empty credentials at init. Emulator has no Algolia keys → `isAvailable=false` → all queries route to Firestore.
- **`EnvConfig().algoliaIndexName`** — `products_emulator` in emulator, `products` in prod. Used by AlgoliaService.create().
- **Routing**: text search + available → Algolia (5s timeout, Firestore fallback). Category-only or browse → always Firestore (cursor pagination).
- **Facet filters**: `categoryId` applied via `FilterGroup.facet` in Algolia when both text + category present.
- **`productRepositoryProvider`** — always returns `AlgoliaProductRepository` (no dead try/catch). Graceful degradation is built into the repository itself.
- Full decision table in `.github/copilot-skills.md`.

### Canadian Law Compliance (Audit Feb 2026)
- **Full audit**: `docs/CANADIAN_LAW_COMPLIANCE_AUDIT.md` — 10 critical, 12 moderate, 7 low issues
- **Skill**: `.claude/skills/canadian-law-compliance/SKILL.md` — quick reference for all agents
- **12 Canadian laws apply**: PIPEDA, Quebec Law 25, CASL, Competition Act, Excise Tax Act, Ontario CPA, Quebec CPA, ACA, AODA, Charter of French Language, Official Languages Act, CCPSA
- **Tax rates verified correct** — all 13 provinces/territories match CRA (NS=14% HST updated)
- **Top 3 CRITICAL before launch**: (1) GST/HST reg number on receipts, (2) CASL email compliance (address + unsubscribe), (3) French language for Quebec users
- **CASL fines up to $10M** — all emails need physical address + unsubscribe link + consent tracking
- **Quebec Law 25** — must designate privacy officer + publish contact, mandatory PIA, granular consent
- **PIPEDA** — mandatory breach notification since 2018, must have data breach response plan
- **Bill C-56 (June 2024)** — drip pricing banned, but govt taxes exempt; still add "+ applicable taxes" to prices
- **AODA/ACA** — WCAG 2.1 AA required, semantics exist but no formal audit done
- **Bill 96 (Quebec)** — all consumer-facing content must be available in French, fines $3K-$30K/violation
- **Ontario CPA** — order confirmation emails must include: full supplier name, itemized price, delivery date, cancellation rights, contact info
- **Schema fields needed**: `emailConsent`, `consentTimestamp`, `consentMethod`, `marketingOptIn` in user docs
- **Email templates need**: physical address footer, unsubscribe link, `List-Unsubscribe` header, GST/HST number

### .claude/ Infrastructure
- **5 agents**: logic-auditor, cross-stack-auditor, payment-auditor, schema-sync-checker, order-lifecycle-auditor
- **7 rules** (path-scoped): flutter, backend, payments, orders, firestore, testing, security
- **10+ skills**: audit-workflow, design-tokens, e2e-test-suites, **e2e-debugging**, email-system, full-stack-audit, read-workflow, shipping-costs, ux-info-buttons, widget-finders, **canadian-law-compliance**, payment-system
- **5 hooks**: validate-schema-sync, validate-payment, validate-orders, protect-production, verify-logic-on-stop (Stop gate)
- **15+ commands**: plan-task, execute-plan, pause-work, resume-work, investigate, create-skill, audit-workflow, check-schema-sync, cross-stack-check, commit-push, deploy, test-all, fix-tests, optimize-db, clear-context
- **Quality tools**: ruff (Python linting), dart analyze (Dart), universal-ctags (symbol extraction)
- **Symbol Map**: `docs/SYMBOL_MAP.md` — auto-generated via `scripts/generate-symbol-map.sh`

---
