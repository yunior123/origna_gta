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

---

## About Me (Yunior Rodriguez Osorio)

**Solo founder-developer** building OrignaGta. Staff engineer level, self-taught.
- **Action over discussion** — "just do it, show me the result"
- Short, direct, bullet points. No filler. Pick best solution and do it.
- Fix errors silently. Don't apologize. Be his **second brain**.

---

## PROJECT

**OrignaGta** — Canada-only e-commerce marketplace. Scale: 100M+ users/year. Launch: March 2026.

**Tech:** Flutter (Web/Android/iOS) + Firebase + Stripe Connect Express + R2 Cloudflare + Geoapify + Algolia + Sentry + Mailjet + Riverpod

---

## ARCHITECTURE (NON-NEGOTIABLE)

1. MVVM only. Frontend = no business logic.
2. APIs replaceable by editing service files only
3. Idempotency required for all payments/transfers
4. Canada-only enforced backend-first
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

### Key Architecture
- **Stripe Connect Express** — direct charges, manual capture, 2.5% platform fee
- **Canada-only** — backend-first postal code/province validation
- **R2 Cloudflare** for images, **Algolia** for search, **Mailjet** for email, **Sentry** for errors
- **Riverpod** for state (NOT Provider, NOT Bloc)

### Payment Pipeline
`checkout_provider.dart` → `create_payment_intent` → `payment_stripe.py` (manual capture) → seller confirms → `capture_payment` → Stripe Connect transfer after delivery

### Order Lifecycle
`pending → confirmed → processing → shipped → in_transit → delivered` (happy path)
Cancel/refund: restore stock + refund/void. Cron: 7-day auto-confirm, auth expiry.

### Add Product Flow
→ **Full knowledge in `.claude/skills/add-product-flow/SKILL.md`**
Sentinel `copyWith`, image sync callback, free shipping cascade, digital product guards, postal code normalization, stale coordinates, double-submit guard.

**Fixed Issues (2026-02-08):**
- Inventory config now ALWAYS created (was null when using defaults)
- Apartment field UI added (controller existed but no TextField)
- Discount tier validation: 5+ items discount must be ≥ 3+ items discount
- Free shipping toggle hidden for digital products (forced true anyway)

### Home Screen Shimmer Bug
`_onScroll` → `loadProducts()` every pixel when empty → infinite loop. Fix: guard with `products.isNotEmpty` + `hasMore=false` on 0 results.

### Algolia Search Architecture
- **`AlgoliaService.isAvailable`** — detects empty credentials at init. Emulator has no Algolia keys → `isAvailable=false` → all queries route to Firestore.
- **`EnvConfig().algoliaIndexName`** — `products_emulator` in emulator, `products` in prod. Used by AlgoliaService.create().
- **Routing**: text search + available → Algolia (5s timeout, Firestore fallback). Category-only or browse → always Firestore (cursor pagination).
- **Facet filters**: `categoryId` applied via `FilterGroup.facet` in Algolia when both text + category present.
- **`productRepositoryProvider`** — always returns `AlgoliaProductRepository` (no dead try/catch). Graceful degradation is built into the repository itself.
- Full decision table in `.github/copilot-skills.md`.

### .claude/ Infrastructure
- **5 agents**: logic-auditor, cross-stack-auditor, payment-auditor, schema-sync-checker, order-lifecycle-auditor
- **7 rules** (path-scoped): flutter, backend, payments, orders, firestore, testing, security
- **9+ skills**: audit-workflow, design-tokens, e2e-test-suites, email-system, full-stack-audit, read-workflow, shipping-costs, ux-info-buttons, widget-finders
- **5 hooks**: validate-schema-sync, validate-payment, validate-orders, protect-production, verify-logic-on-stop (Stop gate)
- **15+ commands**: plan-task, execute-plan, pause-work, resume-work, investigate, create-skill, audit-workflow, check-schema-sync, cross-stack-check, commit-push, deploy, test-all, fix-tests, optimize-db, clear-context
- **Quality tools**: ruff (Python linting), dart analyze (Dart), universal-ctags (symbol extraction)
- **Symbol Map**: `docs/SYMBOL_MAP.md` — auto-generated via `scripts/generate-symbol-map.sh`

---

## TODO (Active)

- Cart screen: plus button rebuilds unnecessary widgets
- Ensure schema constants are widely used
- Update json schema constants when database schema changes
- ChromeDriver compatibility for Flutter web integration tests

### ✅ Fixed 2026-02-08
- ~~Add Product: `_inventoryManaged`, `_trackQuantity`, `_allowBackorder` now always persisted to Firestore~~
- ~~Add Product: `_apartmentController` UI field added (Apartment/Unit optional)~~
- ~~Add Product: Discount tiers now validate 5+ ≥ 3+ (shows error if invalid)~~
- ~~Add Product: Free Shipping toggle hidden for digital products~~
