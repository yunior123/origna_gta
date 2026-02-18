# CLAUDE.md

## RULES

0. **Logic first** — 50+ adversarial scenarios before shipping. Think: malicious seller, buyer, race conditions.
1. **No subagents without consent** — ask first
2. **Save tokens** — show only actions and results
3. **"save"/"remember"** → persist to `.claude/LEARNED.md`
4. **Match Yunior's language** — respond in whichever language he uses
5. **No new markdown files** unless asked
6. **Cross-stack check** after every edit — Python ↔ Dart ↔ Schema
7. **No magic strings** — use constants from schema_constants. No hardcoded values.
8. **Changing one line → update EVERY file that line impacts** (Tests, Rules, Indexes, Schema)

---

## PROJECT

**OrignaGta** — E-commerce marketplace, Canadian buyers, worldwide sellers. 100M+ users/year. Launch: March 2026. Solo founder-developer (Yunior) — action over discussion, short/direct, fix silently.

**Tech:** Flutter/Riverpod + Python Cloud Functions/Pydantic + Firestore + Stripe Connect Express + Algolia + R2/Cloudflare + Sentry + Mailjet

---

## ARCHITECTURE (NON-NEGOTIABLE)

- MVVM w/ Riverpod only (NEVER Provider/Bloc). Screens = 0 logic.
- Idempotency for all payments/transfers
- Canada-only buyers enforced backend-first (sellers worldwide)
- Eventual consistency — minimize DB reads/writes

---

## CROSS-STACK MAP

| Concept | Frontend (Dart) | Backend (Python) | Schema |
|---|---|---|---|
| Constants | `lib/core/schema/schema_constants.dart` | `functions/schema_constants.py` | `docs/database_schema.json` |
| Order | `lib/models/generated/order_models.dart` | `functions/models/order.py` | `docs/json_schemas/individual/Order.json` |
| Product | `lib/models/generated/product_models.dart` | `functions/models/product.py` | `docs/json_schemas/individual/Product.json` |
| User | `lib/models/generated/user_models.dart` | `functions/models/user.py` | `docs/json_schemas/individual/User.json` |
| Payment | `lib/features/checkout/checkout_provider.dart` | `functions/handlers/payment_stripe.py` | — |
| Orders | `lib/features/orders/*.dart` | `functions/handlers/orders.py` | — |

**Deep context (read when needed, NOT auto-loaded):** `docs/WORKFLOW_INDEX.md`, `docs/REPO_MAP.md`, `docs/AGENT_GUIDE.md`, `docs/SYMBOL_MAP.md`

---

## AGENT RULES

- **3+ file edits** → run `logic-auditor` FIRST
- **Payment files** → `payment-auditor` IMMEDIATELY after
- **schema_constants** → `schema-sync-checker` IMMEDIATELY after
- **Order handler** → `order-lifecycle-auditor` IMMEDIATELY after
- **CRITICAL findings** → fix before committing

---

## KEY GOTCHAS (from `.claude/LEARNED.md`)

- `get_server_timestamp()` CANNOT be nested in arrays/ArrayUnion → use `datetime.now(timezone.utc)`
- `_capture_payment_impl` (undecorated) for internal calls, NOT `capture_payment` (has @on_call wrapper)
- `paymentStatus` always `'captured'` (auto-capture mode), never `'authorized'`
- Sellers CANNOT mark delivered — admin/cron only
- Multi-seller orders → must use `update_item_status`, not `update_order_status`
- `signIn()` returns `{idToken}` not `{token}`
- Stock field: `stockQuantity` not `stock`
- Project ID: `orignagta` (no hyphen)
- `source_transaction` MUST be charge ID (`ch_xxx`), NOT PaymentIntent (`pi_xxx`)
- Auth Emulator starts with 0 users — MUST seed before tests
- `patchDoc()` needs `updateMask.fieldPaths` or it replaces entire doc

**Full history:** `.claude/LEARNED.md`

---
