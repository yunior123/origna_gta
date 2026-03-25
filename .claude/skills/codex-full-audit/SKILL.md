# Codex Full Codebase Audit

Use when asked to "run full audit", "codex audit", "audit everything before deploy", "comprehensive codebase review", or "pre-release audit". This is the nuclear option — a 6-phase, multi-skill audit of the entire OrignaGTA monorepo.

## Instructions for Codex

You are auditing the OrignaGTA monorepo — a Canadian multi-vendor e-commerce marketplace. Flutter frontend + Rust/OrignaBase backend + SurrealDB + Meilisearch + Stripe payments.

**REAL MONEY IS AT STAKE.** Stripe processes live payments. Any bug in checkout, webhooks, refunds, or platform fees = financial loss. Be ruthlessly critical on payment flows.

**Rules:**
- Every finding MUST include `file:line` evidence — no vague claims
- Classify: P0 (critical, fix before deploy), P1 (high, fix this sprint), P2 (medium), P3 (low)
- Read the actual code — don't guess from file names
- If a skill exists for a domain, use it
- Check BOTH Dart and Rust sides for cross-stack consistency

---

## Phase 1: Payment & Money (CRITICAL)

**Skills to invoke:** `/stripe-audit`, `/concurrency-audit`

**Files to audit:**
- `orignabase/crates/ob-handlers/src/payments/checkout.rs` (2,498 LOC)
- `orignabase/crates/ob-handlers/src/payments/webhooks.rs` (2,848 LOC)
- `orignabase/crates/ob-handlers/src/payments/capture.rs` (848 LOC)
- `orignabase/crates/ob-handlers/src/payments/connect.rs` (910 LOC)
- `orignabase/crates/ob-handlers/src/orders/refunds.rs` (2,636 LOC)
- `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
- `origna_gta/lib/screens/widgets/product_detail/fbt_section.dart` (NEW — FBT adds items to cart)

**Mandatory checks:**
- [ ] HMAC-SHA256 webhook signature verification uses constant-time comparison (not `==`)
- [ ] Webhook replay protection rejects events >300s old
- [ ] Webhook deduplication checks `webhook_events` collection BEFORE processing
- [ ] All monetary values are integer cents — grep for `double` or `float` near money fields
- [ ] Platform fee = `platformFeeTotalCents / subtotalCents` (NOT totalAmountCents)
- [ ] Stripe Checkout Session includes `metadata["order_id"]` (snake_case key)
- [ ] Idempotency keys on ALL Stripe API calls (format: `{order_id}-{action}`)
- [ ] Order confirmation ONLY on webhook `payment_intent.succeeded` — NEVER on redirect URL alone
- [ ] Refund atomicity: stock restoration + order status update + Stripe refund in single transaction
- [ ] FBT "Add all to Cart" creates individual cart items (not one combined line item)
- [ ] No Stripe secret keys in Flutter code or dart-define variables
- [ ] Province-based tax calculation matches Canadian tax rates
- [ ] Free shipping threshold: exactly 7500 cents ($75 CAD)

---

## Phase 2: Order Lifecycle & Returns

**Skills to invoke:** `/flow-audit`, `/shipping-tracking-audit`

**Files to audit:**
- `orignabase/crates/ob-handlers/src/orders/status.rs` (3,341 LOC)
- `orignabase/crates/ob-handlers/src/orders/returns.rs` (2,956 LOC)
- `orignabase/crates/ob-handlers/src/orders/shipping.rs` (2,090 LOC)
- `orignabase/crates/ob-handlers/src/shipping_calc/mod.rs`
- `origna_gta/lib/features/orders/buyer_orders_viewmodel.dart`
- `origna_gta/lib/features/orders/seller_orders_viewmodel.dart`

**Mandatory checks:**
- [ ] State machine: pending → confirmed → shipped → delivered (no skips)
- [ ] Terminal states: `delivered` and `cancelled` cannot transition further
- [ ] Stock decrement on `confirmed` (atomic, not read-then-write)
- [ ] Stock restore on `cancelled` (after confirmed) via atomic increment
- [ ] Stock restore on return `approved`
- [ ] 30-day return window from `deliveredAt` timestamp
- [ ] Cancellation: buyer only from `pending`, seller from `pending` or `confirmed`
- [ ] Seller cancellation requires reason
- [ ] Perishable items: ≤50km local delivery only, no cross-province
- [ ] Digital items: instant delivery, no shipping cost
- [ ] Multi-seller orders: one order per seller, independent state machines
- [ ] Notification sent on EVERY state transition (check push + email)
- [ ] Perishable confirmed → URGENT notification to seller (24h deadline)
- [ ] Tracking number flow: seller adds → buyer sees in order detail

---

## Phase 3: Auth & Security

**Skills to invoke:** `/auth-coverage-audit`, `/security-review`, `/pentest-swarm`

**Files to audit:**
- `orignabase/crates/ob-auth/src/jwt.rs`
- `orignabase/crates/ob-auth/src/totp.rs`
- `orignabase/crates/ob-auth/src/password.rs`
- `orignabase/crates/ob-auth/src/rate_limit.rs`
- `orignabase/crates/ob-auth/src/turnstile.rs`
- `orignabase/crates/ob-auth/src/oauth.rs`
- `orignabase/crates/ob-auth/src/middleware.rs`
- `orignabase/crates/ob-auth/src/key_rotation.rs`

**Mandatory checks:**
- [ ] JWT RS256 signing (not HS256 — which would share the key)
- [ ] JWT expiry < 1 hour, refresh token expiry < 7 days
- [ ] JWT refresh: old token invalidated after refresh
- [ ] Key rotation: new keys don't invalidate existing valid tokens
- [ ] bcrypt rounds >= 12
- [ ] MFA TOTP: secret stored encrypted, not plaintext
- [ ] MFA recovery codes: one-time use, hashed in DB
- [ ] Rate limiting on auth endpoints (stricter than normal)
- [ ] Turnstile validation on register + login + checkout (not skippable)
- [ ] OAuth state parameter for CSRF protection
- [ ] No `userId` from client trusted — always derive from JWT
- [ ] Row-level security in SurrealDB PERMISSIONS clauses
- [ ] Admin actions logged with `adminUid`
- [ ] No PII (emails, phones, addresses) in logs

---

## Phase 4: New Features (Built This Session)

**Skills to invoke:** `/new-features-audit`, `/food-expert`, `/product-specs-expert`

**Files to audit:**
- `orignabase/crates/ob-handlers/src/shared/nutrition.rs`
- `orignabase/crates/ob-handlers/src/shared/specs.rs`
- `orignabase/crates/ob-handlers/src/cron/mod.rs` (co-purchase function)
- `orignabase/crates/ob-handlers/src/rest_api.rs` (recommendations endpoint)
- `origna_gta/lib/models/generated/product_models.dart` (NutritionFacts, FoodMetadata, ProductSpec, ProductSpecs)
- `origna_gta/lib/utils/nutrition_helper.dart`
- `origna_gta/lib/utils/spec_templates.dart`
- `origna_gta/lib/screens/widgets/product_detail/nutrition_facts_section.dart`
- `origna_gta/lib/screens/widgets/product_detail/product_specs_section.dart`
- `origna_gta/lib/screens/widgets/product_detail/fbt_section.dart`
- `origna_gta/lib/screens/widgets/product_detail/seller_products_section.dart`
- `origna_gta/lib/features/products/recommendations_provider.dart`

**Mandatory checks:**
- [ ] NutritionFacts: all 13 Health Canada mandatory nutrients present
- [ ] FOP thresholds match Health Canada: sat fat >= 3000mg, sugars >= 15000mg, sodium >= 345mg
- [ ] FOP computed server-side (not trusting client values)
- [ ] Allergens validated against 11 Canadian priority categories
- [ ] Spec validation: max 50 specs, key 1-64 chars, value 1-500 chars
- [ ] Spec valueType validated: only "text", "number", "boolean"
- [ ] Co-purchase cron: handles empty orders gracefully
- [ ] Co-purchase cron: handles single-item orders (no pairs to compute)
- [ ] Co-purchase cron: doesn't crash on missing productId in order items
- [ ] Recommendations endpoint: 3-tier fallback (co-purchase → bundled → category)
- [ ] bundledProductIds: max 5, validated server-side
- [ ] All 20 non-food categories have spec templates (no category missing)
- [ ] Nutrition/specs sections render correctly for null data (no crash)
- [ ] FBT section: hidden when no bundled products AND no co-purchase data

---

## Phase 5: Notifications & Subscriptions

**Skills to invoke:** `/notification-audit`, `/subscription-audit`

**Files to audit:**
- `orignabase/crates/ob-notifications/src/routes.rs`
- `orignabase/crates/ob-handlers/src/push/mod.rs`
- `orignabase/crates/ob-handlers/src/email/helpers.rs`
- `orignabase/crates/ob-handlers/src/payments/subscriptions.rs` (3,198 LOC)
- `orignabase/crates/ob-handlers/src/native_triggers.rs`

**Mandatory checks:**
- [ ] FCM tokens: cleaned up on 404/410 responses (stale tokens)
- [ ] Push rate limit: max 20 notifications per user per day
- [ ] Email: no user-controlled content injected into HTML templates (XSS)
- [ ] Email: PII not logged
- [ ] Subscription webhook: handles `invoice.payment_failed` with grace period
- [ ] Subscription cancel: premium features disabled immediately or at period end?
- [ ] Premium status: propagated correctly to Flutter (check provider)
- [ ] Subscription price: $7.86 CAD hardcoded or configurable?

---

## Phase 6: Cross-Stack Integrity

**Skills to invoke:** `/check-schema-sync`, `/coding-standards`

**Files to compare:**
- `origna_gta/lib/core/schema/schema_constants.dart` vs `orignabase/crates/ob-handlers/src/shared/schema.rs`
- Product model (Dart) vs product CRUD (Rust)
- Order model (Dart) vs order status (Rust)

**Mandatory checks:**
- [ ] Field name consistency: every field in Dart `Fields` class has matching Rust `fields` constant
- [ ] Timestamp field names: `createdAt` for orders/users, `dateCreated` for products, `timestamp` for webhooks
- [ ] OrderStatus values: lowercase in both (pending, confirmed, shipped, delivered, cancelled)
- [ ] Money fields: ALL integer cents in BOTH stacks (grep for `double` near price/amount)
- [ ] Meilisearch filterable attributes match what Flutter expects to filter on
- [ ] New fields (nutritionFacts, foodMetadata, specs, bundledProductIds) present in BOTH Dart model and Rust CRUD
- [ ] Translation keys: every `.tr()` call has matching key in both en.json and fr.json

---

## Output Format

```markdown
## P0 CRITICAL — Fix Before Deploy
- [file:line] Finding description
  Evidence: exact code snippet
  Risk: what can go wrong
  Fix: specific code change

## P1 HIGH — Fix This Sprint
...

## P2 MEDIUM — Fix Next Sprint
...

## P3 LOW — Backlog
...

## COVERAGE GAPS
- Areas with insufficient test coverage
- Suggested test additions

## POSITIVE FINDINGS
- Well-implemented patterns worth noting
```

---

## How to Run

```bash
delegate codex "Read .claude/skills/codex-full-audit/SKILL.md and execute all 6 phases. Use the listed skills for each phase. Be ruthlessly critical on payment flows — real money is at stake. Report ALL findings with file:line evidence in P0/P1/P2/P3 format."
```

Or invoke individual phases:
```bash
delegate codex "Run Phase 1 (Payment & Money) from .claude/skills/codex-full-audit/SKILL.md"
delegate codex "Run Phase 4 (New Features) from .claude/skills/codex-full-audit/SKILL.md"
```
