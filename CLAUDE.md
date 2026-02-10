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
  - **`callCallable()`** returns raw body; **`callOk()`** throws on error; **`callExpectError()`** returns the error for assertion.
  - **`patchDoc()`** supports both `(path, fields)` and `(collection, docId, fields)` signatures.
- **Root cause of ~61 "Unauthenticated" failures**: Auth Emulator had 0 users (emulator restarted without `--import`). `signIn()` silently returned no `idToken` → `Bearer undefined` → token rejected. NOT a protocol or project ID mismatch.
- **Firestore REST PATCH** — MUST use `updateMask.fieldPaths` query params for partial updates, otherwise it REPLACES the entire document (wiping all fields not included in the PATCH body)
- **`Bearer owner`** — bypasses ALL Firestore/Auth security rules in emulator mode. Use for tooling scripts only.
- **Auth Emulator** — does NOT support GET on `/emulator/v1/projects/{id}/accounts`. To list users, query Firestore `/users` collection via REST with `Bearer owner` instead.
- **`seed-uid-map.json`** — maps email → Firebase Auth UID for `seed-orders.py`. MUST be regenerated when switching between `mega-seed.ts` (75 users) and `seed-emulator.ts` (25 users). Stale UIDs cause order seed failures and cascading test breaks.
- **Rate limiting** — `create_checkout_session` has 5 req/min rate limit. Tests that call it multiple times need delays (65s+) between suites.
- **Test ordering** — tests within a file run sequentially and modify shared Firestore data. If test C modifies a document, test G must restore it before asserting.
- **Stripe Checkout UI in headless** — "VerificationModal" overlay is likely Stripe's "Link" login popup (NOT 3DS — card 4242424242424242 is not enrolled). `fillStripeCheckout()` in `api-helpers.ts` handles this with modal dismissal logic.
- **patchDoc() in E2E** — must construct `updateMask.fieldPaths` from all fields being patched, not rely on Firestore's default merge behavior (REST API ≠ SDK).

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
- **10+ skills**: audit-workflow, design-tokens, e2e-test-suites, email-system, full-stack-audit, read-workflow, shipping-costs, ux-info-buttons, widget-finders, **canadian-law-compliance**
- **5 hooks**: validate-schema-sync, validate-payment, validate-orders, protect-production, verify-logic-on-stop (Stop gate)
- **15+ commands**: plan-task, execute-plan, pause-work, resume-work, investigate, create-skill, audit-workflow, check-schema-sync, cross-stack-check, commit-push, deploy, test-all, fix-tests, optimize-db, clear-context
- **Quality tools**: ruff (Python linting), dart analyze (Dart), universal-ctags (symbol extraction)
- **Symbol Map**: `docs/SYMBOL_MAP.md` — auto-generated via `scripts/generate-symbol-map.sh`

---
