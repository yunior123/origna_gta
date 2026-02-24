#!/usr/bin/env python3
"""
collect_flow_files.py — Copies relevant source files for each workflow
into Desktop/origna_flows/<flow_name>/ for AI review.

Rules:
  - CLAUDE.md is prepended to every flow for AI context.
  - Max 18 primary files per flow folder (+ INSTRUCTIONS.md + optional _overflow.md = 20 total).
  - Extra files are concatenated into _overflow.md.
  - Total combined content is capped at MAX_TOTAL_BYTES to respect Claude.ai's context limit.

Usage:
    python scripts/collect_flow_files.py
"""

import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DESKTOP = Path.home() / "Desktop" / "origna_flows"
MAX_FILES_PER_FLOW = 18  # includes CLAUDE.md; +INSTRUCTIONS.md +_overflow.md = 20 total max
MAX_TOTAL_BYTES = 700_000  # 700 KB ≈ 175K tokens — safely under Claude Sonnet 4.6's 200K token context on claude.ai

# CLAUDE.md is auto-injected into every flow as the first file
_CLAUDE = "CLAUDE.md"

_COMMON_FOOTER = """
---

## 📋 Required Output Format

**Be maximally concise. Every word must save the engineer tokens, not cost them.**

For each finding, output exactly this block — nothing more:

```
[SEVERITY] file/path.ext:LINE_NUMBER
PROBLEM: one sentence — what is wrong and why it matters.
FIX: one sentence — exact change needed (field name, method, value, logic) plus code snippet demonstrating the fix.
```

Severity levels: `[CRITICAL]` · `[HIGH]` · `[MEDIUM]` · `[LOW]` · `[BONUS]`

**Rules for your response:**
- No prose intros, no summaries, no "Overall the code looks good…" filler.
- No restating the audit checklist back.
- One block per finding. Stack multiple findings with a blank line between them.
- If a finding spans multiple files, list the primary file first, then add `ALSO: file2.ext:LINE`.
- If no issues found for a checklist item, skip it entirely — do NOT write "✅ No issues".
- Use `[BONUS]` for findings outside the checklist scope.
- Line numbers are mandatory. If uncertain, give the nearest anchor (function name + offset).
- Ultrathink, make sure the proposed fixes do not contradict themselves, provide code snippets with the proposed solutions, verify that the proposed fixes are real.

**Example output:**
```
[CRITICAL] functions/handlers/payment_stripe.py:312
PROBLEM: uses client-sent `amount` instead of re-fetching price from Firestore.
FIX: replace `amount = request.data["amount"]` with Firestore lookup `product_doc.get("priceCents")`.

[HIGH] origna_gta/lib/features/checkout/checkout_provider.dart:87
PROBLEM: sellerId == buyerId check only on frontend; backend handler missing the guard.
FIX: add `if order.seller_id == order.buyer_id: raise HttpsError(...)` in create_order handler.
```

---

## 🎁 Bonus Fixes — Report ALL of Them
Spot issues beyond the checklist? Report **every single one** with `[BONUS]` — no cap, no filtering.
Do NOT stop at a handful. If you see 20 bonus issues, output all 20. Same format, same conciseness.
Examples: architectural smells, race conditions, missing indexes, N+1 queries, scalability gaps, missing null checks, anti-patterns, hardcoded values, missing error handling, inconsistent naming, performance issues, accessibility gaps, security edge cases.

---

## 📌 Project Context
- **Stack**: Flutter/Riverpod · Python Cloud Functions/Pydantic · Firestore · Stripe Connect Express · Algolia
- **Buyers**: Canada-only (backend-enforced). **Sellers**: worldwide. **Currency**: CAD only.
- **Scale**: 100M+ users/year. No migrations — schema must be correct at launch (March 2026).
- **No legacy code.** MVVM: screens = zero logic. Riverpod StateNotifier only.
- See `CLAUDE.md` for full rules and anti-patterns.

---

## 🤖 Specialized Agent Playbooks

> These are the exact patterns our specialized audit agents use. Apply ALL of them to the files in this flow.

### 🔐 Security Auditor Patterns
1. **Unauthenticated calls** — Every `@on_call` function must check `context.auth`; unauthenticated = raise `HttpsError('unauthenticated')`.
2. **Firestore rules vs handler auth** — Rules are defense-in-depth; the handler must also validate auth. A rule `allow write: if request.auth != null` is NOT enough if the handler skips UID checks.
3. **Self-purchase bypass** — `buyer_uid != seller_uid` enforced in the backend handler, NOT just frontend.
4. **Price tampering** — Backend re-fetches `priceCents` from Firestore; client-sent price NEVER trusted. Tolerance ±$0.01.
5. **Webhook HMAC** — `stripe.Webhook.construct_event()` called with raw body; webhook secret from Secret Manager, not env var.
6. **Role escalation** — Users cannot write `isAdmin=true`, `isSeller=true` to their own doc. Rules AND handler must block this.
7. **Collection-specific rules** — Verify these collections have tight rules: `stock_notifications` (owner-only), `product_questions` (seller-answer-only), `seller_metrics` (no client writes), `addresses` (owner CRUD only), `user_security` (backend-only, `allow read: if false`).
8. **Input sanitization** — User text stored in Firestore must be length-limited; no raw HTML rendered (no `HtmlWidget`, `InAppWebView` rendering user content).
9. **Session timeout** — `SessionTimeoutService` 15-minute inactivity; verify it fires on the correct user interaction events.
10. **Circuit breaker** — `CircuitBreakerConfig` thresholds; open circuit doesn't silently swallow errors visible to user.

### 💳 Payment Auditor Patterns
1. **Auto-capture** — `paymentStatus` is always `'captured'` immediately at checkout. There is NO manual capture step. Flag any code that assumes authorization-only flow.
2. **Platform fee** — Exactly 2.5% (`BusinessRules.PLATFORM_FEE_RATIO`). Verify the formula: `fee = round(total * 0.025)`. Applied to post-discount amount.
3. **`source_transaction`** — Must be charge ID (`ch_xxx`), NEVER PaymentIntent ID (`pi_xxx`). Wrong ID causes transfer failures.
4. **Idempotency keys** — Every Stripe API call (charge, refund, transfer) uses an idempotency key derived from order/event IDs.
5. **Webhook dedup** — `webhook_events` collection stores `event_id`; handler returns early if already processed.
6. **Dispute auto-reversal** — `handle_dispute_created()` must reverse all associated transfers immediately.
7. **Refund failures** — On Stripe refund failure: create `SECURITY_ALERTS` doc + set `requires_manual_review=true` on order. Never silently swallow.
8. **3DS** — `requires_action` state triggers email to buyer with payment link; order stays `pending`.
9. **CAD-only** — All Stripe amounts in CAD cents (`currency='cad'`). No other currency allowed.
10. **Stripe Connect** — `transfer_data.destination` = seller's Stripe account ID from `seller_profiles/{uid}.stripeAccountId`.

### 🔄 Cross-Stack Auditor Patterns
1. **camelCase ↔ snake_case** — Dart sends `camelCase` JSON keys; Python expects `snake_case`. Mismatch = silent `None` in Python, `null` in Dart.
2. **Error response parsing** — Frontend must handle ALL backend error codes, not just success. If backend returns `{'error': 'out_of_stock'}`, frontend must surface it.
3. **Enum parity** — Every `OrderStatus`, `ProductCondition`, `ShippingType`, etc. value must exist in BOTH `schema_constants.py` AND `schema_constants.dart` with identical string values.
4. **Money format** — All money stored as `int` cents in Firestore and Python. Dart model has `int` cents fields + computed dollar getters. Never store dollar floats.
5. **Timestamp handling** — Firestore `Timestamp` → Python `datetime` → Dart `DateTime`. Verify `.toDate()` / `.fromDate()` conversions are not lost.
6. **Optional vs required** — A field `Optional[str]` in Python must map to `String?` in Dart. Mismatches cause runtime null errors.
7. **Response format** — If backend returns `{'success': true, 'orderId': '...'}`, the Dart code must parse exactly those keys. Check for key name drift.

### 🧠 Logic Auditor Patterns
1. **Race conditions** — Two users buying the last unit simultaneously: stock decrement must use Firestore transaction (`@firestore.transaction`), not a read-then-write.
2. **State machine violations** — One-way only. Terminal states (`delivered`, `refunded`, `cancelled`) cannot transition. Check every `update_order_status` call site.
3. **Double-processing** — Cron jobs and webhooks running concurrently on the same order: idempotency check at the START of every handler.
4. **Missing null guards** — Any `doc.get('field')` in Python without a default, or `.field!` in Dart without a null check, is a crash waiting to happen.
5. **Firestore read cost** — N+1 queries (reading a doc per list item) at scale = expensive. Look for loops that call `db.collection().document().get()`.
6. **Auth state race** — `BuildContext` captured before `await`; check `mounted` after every async call before using context.
7. **Stale provider state** — `ref.read()` in build = stale data. `ref.watch()` in event handler = extra rebuilds. Both are bugs.

### 🖼️ Frontend Auditor Patterns
1. **Async provider handling** — Every `ref.watch(asyncProvider)` must use `.when(data:, loading:, error:)`. Using `.value!` crashes on null.
2. **`ref.watch` in callbacks** — `onPressed: () { ref.watch(...) }` is wrong → use `ref.read(...)` in callbacks. `ref.watch` only in `build`.
3. **Premium gate consistency** — ALL premium-gated features use the same provider. Direct `user.isPremium` checks (not the subscription stream) can be stale.
4. **`withOpacity()` DEPRECATED** — Use `Color.withValues(alpha: x)` instead. Every `withOpacity()` call is a lint warning.
5. **`EnvConfig()` not `EnvConfig.instance`** — The singleton is accessed via constructor. Wrong access pattern = null or default values.
6. **`BuildContext` after async** — Resolve `context` before `await`. After `await`, check `if (!mounted) return;`.
7. **`MaterialPageRoute` banned** — Use named routes only. Direct `MaterialPageRoute` push breaks deep links and back navigation.
8. **`CircularProgressIndicator` banned** — Use `ModernLoadingIndicator`. Raw progress indicators break the design system.
9. **`IconButton` without tooltip** — Every `IconButton` needs a `tooltip:` parameter for accessibility.
10. **Hardcoded colors** — All colors from `DesignTokens`. No `Color(0xFF...)`, no `Colors.*`.

### 📐 Schema Sync Checker Patterns
1. **6-layer sync** — `database_schema.json` → `schema_constants.py` → `schema_constants.dart` → Pydantic models → Freezed models → `firestore.rules`. All 6 must agree.
2. **No magic strings** — Field names referenced in handlers must use `SchemaConstants.fieldName`, not `'field_name'` string literals.
3. **`createdAt`/`updatedAt`** — Every Firestore document must have both timestamps. Check model definitions.
4. **Money as cents** — Any field ending in `Cents`, `Amount`, `Price`, `Fee`, `Total` must be `int` in both Python and Dart.
5. **Seller-specific fields** — Fields like `stripeAccountId`, `commissionRateBps`, `businessName` live in `seller_profiles/{uid}`, NOT in `users/{uid}`.
6. **MFA secrets** — `mfaSecret`, `mfaBackupCodes` live in `user_security/{uid}` (backend-only). `users` doc only has `mfaEnabled` bool.

### 📦 Order Lifecycle Auditor Patterns
State machine: `pending → confirmed → processing → shipped → in_transit → delivered` (+ `cancelled`, `failed`, `expired`, `refunded`, `partially_refunded`)
1. **One-way transitions** — No backward transitions. Terminal states are final.
2. **Per-transition checklist** — For each transition verify: ① handler validates it ② Firestore rules allow it ③ correct payment action fires ④ stock action fires ⑤ email sent ⑥ timestamp recorded.
3. **Sellers cannot mark delivered** — Only cron (`auto_confirm_delivery`) or admin can set `delivered`. Flag any seller-accessible path to `delivered`.
4. **Cancel = stock restore + refund/void** — Both must happen atomically. If stock restored but refund fails, order data is corrupted.
5. **`deliveryStatus` DEPRECATED** — Use `status` only. Any remaining `deliveryStatus` references are bugs.
6. **Item-level status** — `orderItem.status` must be updated alongside `order.status` for multi-item orders.

### 🔄 Order Lifecycle Auditor Patterns (cron-specific)
- **Auto-confirm** — 7 days after `shippedAt` timestamp; uses Firestore server timestamp comparison.
- **Expired authorizations** — Within 7-day Stripe window; cancels order + voids auth + restores stock.
- **Idempotency** — Cron re-run on same batch: each record checks state before acting; no double-processing.

### 💰 Premium Auditor Patterns
1. **Webhook → isPremium sync** — `checkout.session.completed` must atomically update BOTH subscription doc AND `user.isPremium`. If webhook fails mid-way, isPremium can be stale.
2. **Frontend uses stream, not cache** — `PremiumPaywallWidget` must watch `subscriptionStreamProvider` (real-time), not `user.isPremium` alone (stale cache).
3. **Client-side bypass impossible** — Backend endpoints that serve premium features must re-validate subscription status server-side; never trust `user.isPremium` from a client-sent payload.
4. **Webhook idempotency** — Duplicate `customer.subscription.updated` events must not double-flip isPremium. Check `webhook_events` dedup.
5. **Cancellation timing** — Cancellation should set `cancelAtPeriodEnd=true`; isPremium stays true until period ends, then cron flips it. Immediate revocation is a UX bug.
6. **Reactivation flow** — Reactivation must update subscription doc status → isPremium = true in the SAME transaction. A reactivated user seeing a paywall is a revenue loss.
7. **Expiry race condition** — If subscription expires exactly at checkout time, order must fail gracefully, not proceed at premium price.

### 💸 Cost Monitor Patterns
1. **Secret Manager per-invocation** — Secrets (`get_secret_*()`) must be cached in module-level globals. Re-fetching per request = $0.03/10k calls at scale.
2. **Algolia over-indexing** — Only reindex when searchable fields change (name, description, price, category). Stock-only updates must use `partial_update_object`, never full `save_object`.
3. **Stripe Tax caching** — `calculate_tax_with_stripe()` costs $0.50/call. Cache results per province + tax_code combo for the session; tax rates don't change hourly.
4. **Firestore N+1** — Any loop calling `db.collection().document().get()` per item is an N+1. Use `get_all()` batch reads.
5. **Geoapify caching** — Geocoding results must be cached on the address doc (`latitude`/`longitude` fields). Same address = same coordinates; never re-geocode.
6. **Mailjet volume** — Free tier = 200/day. Combine order confirmation + receipt into 1 email. Seller notifications should batch (daily digest) not per-event.
7. **R2 orphan cleanup** — Deleted/archived product images must be removed from Cloudflare R2. Orphaned images accumulate storage cost silently.
8. **Cloud Function memory** — Default 256MB is wasteful for lightweight handlers. Audit each function's actual peak memory and right-size.

### 🏆 Rival Agent Patterns
1. **Standard checkout features** — Amazon/Shopify baseline: save-for-later, quantity limits with stock validation, address autocomplete, free-shipping threshold display. Flag missing items.
2. **Order tracking UX** — Competitors show a timeline (placed → confirmed → shipped → delivered). Our order detail must have equivalent visual status timeline.
3. **Seller trust signals** — eBay/Etsy: verified seller badge, response rate, avg ship time, positive feedback %. Flag if seller profile page lacks these.
4. **Abandoned cart** — Shopify/Amazon send reminder after 1h + 24h. Check if we have any abandoned cart recovery (email or push).
5. **Product discovery** — Competitors show "Customers also bought" / "Similar items". Flag if product detail page lacks recommendations.
6. **Review system completeness** — Amazon standard: star histogram, photo reviews, verified purchase badge, sort by helpful/recent. Flag missing components.
7. **Buyer protection visibility** — AliExpress/eBay prominently show buyer protection policy at checkout. Flag if we don't surface our dispute/refund policy before payment.
8. **Mobile-first friction** — Temu/Shein optimize for <3 taps to checkout. Count taps from product detail → order confirmed; flag if >5.
9. **Price anchoring** — Compare-at price (strikethrough) shown on product card/detail. Flag if `comparePriceCents` field exists but isn't displayed.
10. **Wishlist / Save for later** — Every major platform has this. Flag if missing or incomplete.

### 🎨 UI/UX Expert Patterns
1. **DesignTokens only** — No `Color(0xFF...)`, no `Colors.*`, no `withOpacity()`. Every visual property from `DesignTokens`. `withOpacity()` → `Color.withValues(alpha:)`.
2. **Loading = shimmer** — `CircularProgressIndicator` banned. Use `ShimmerLoading` for async content. `ModernLoadingIndicator` for page-level loads.
3. **8pt spacing grid** — All padding/margin must be multiples of 4 (preferably 8). Misaligned spacing breaks visual rhythm.
4. **Staggered list entrance** — Lists loaded async must use `StaggeredList` or `AnimatedListItem`. Content appearing instantly without animation feels cheap.
5. **Empty states designed** — Every list/collection that can be empty must have: icon + message + CTA (e.g. "No orders yet → Start Shopping"). Raw empty list = unfinished.
6. **`MaterialPageRoute` banned** — Use `SlidePageRoute` / named routes. Raw `MaterialPageRoute` breaks deep links and looks dated.
7. **`IconButton` needs tooltip** — Every `IconButton` must have `tooltip:` for accessibility AND to appear in screen reader audits.
8. **Responsive at 4 breakpoints** — 320px / 480px / 768px / 1024px+. Use `ResponsiveLayout` widget. Fixed-width containers that overflow on mobile are CRITICAL.
9. **Glass effects placement** — `GlassAppBar`, `GlassCard` for nav/floating elements only. Never wrap body text or list items in glass — it kills readability.
10. **Semantic labels on images** — Every `Image` must be wrapped in `Semantics(label: '...')`. Decorative images use `ExcludeSemantics`.
"""

# ── Per-flow audit instructions ─────────────────────────────────────────────
FLOW_INSTRUCTIONS: dict[str, str] = {
    "checkout_payment": """\
# Audit: Checkout & Payment Flow

## What to Audit
1. **Price integrity** — backend must re-fetch prices from Firestore; never trust client-sent amounts (±$0.01 tolerance).
2. **Idempotency** — every payment/capture/transfer operation must be idempotent (check event_id dedup, Stripe idempotency keys).
3. **Self-purchase prevention** — `sellerId != buyerId` enforced server-side, not just frontend.
4. **Stripe Connect** — verify `source_transaction` uses charge ID (`ch_xxx`), NOT PaymentIntent (`pi_xxx`).
5. **Authorization → Capture window** — 7-day window respected; expired authorizations handled.
6. **Platform fee** — 2.5% fee calculation (`BusinessRules.PLATFORM_FEE_RATIO`) applied correctly.
7. **Canada-only buyers** — postal code + province validated server-side at checkout.
8. **Race conditions** — concurrent checkout for same product/stock; stock decrement atomicity.
9. **Error paths** — payment failure, partial capture failure, Stripe webhook delivery failure.
10. **Cart → Order transition** — cart cleared atomically after order creation; no double-orders.
""",

    "order_lifecycle": """\
# Audit: Order Lifecycle & State Machine

## What to Audit
1. **State machine completeness** — all valid transitions covered; invalid transitions rejected.
2. **Cron timing** — auto-confirm window correct; expired authorizations voided on schedule.
3. **Idempotency** — status update handlers safe to replay (webhook retries, duplicate events).
4. **Shipping approval** — seller approval step cannot be bypassed; buyer cannot mark shipped.
5. **Capture timing** — capture only triggered after seller marks shipped + approval window.
6. **Refund correctness** — full/partial refund amounts, platform fee reversal, seller payout reversal.
7. **Email triggers** — correct email sent at each status transition; no duplicate sends.
8. **Stock restoration** — stock returned to correct warehouse on cancellation/return.
9. **Cross-stack sync** — OrderStatus enums identical in Dart, Python, and schema_constants.
10. **Dispute handling** — `handle_dispute_created()` reverses transfers correctly.
""",

    "product_lifecycle": """\
# Audit: Product Lifecycle (CRUD + Algolia)

## What to Audit
1. **SKU deduplication** — `sellerId + sellerSku` uniqueness enforced at repo layer AND via trigger.
2. **Algolia sync** — product indexed/updated/deleted in Algolia atomically with Firestore write.
3. **Stock management** — `stockQuantity` = sum of all warehouse quantities; atomic decrement.
4. **Warehouse assignment** — products require either `sellerAddress` OR `warehouseIds`; both/neither = invalid.
5. **Image upload** — R2 upload permissions, orphan image cleanup on product delete.
6. **`isActive` flag** — correctly toggled; inactive products excluded from search results.
7. **Seller authorization** — seller can only edit/delete their own products.
8. **`shipFromCity/Province/Country`** — correctly denormalized from primary warehouse at write time.
9. **Cross-stack field names** — Product model fields identical across Dart/Python/JSON schema.
10. **Price validation** — price bounds, currency (CAD only), no negative values.
""",

    "add_product": """\
# Audit: Add Product Flow

## What to Audit
1. **Warehouse vs. address logic** — if `selectedWarehouseIds` non-empty → `useWarehouses=true`, `sellerAddress=null`, `stockQuantity=sum(warehouseStockMap)`.
2. **Form validation** — required fields enforced before submission; no silent failures.
3. **SKU uniqueness check** — pre-write query throws before Firestore write; trigger as safety net.
4. **Image upload sequencing** — images uploaded before product doc written; partial upload handled.
5. **Algolia indexing** — product indexed immediately after creation with correct fields.
6. **State management** — `AddProductState` reset correctly on success/cancel; no stale state.
7. **Backend validation** — all frontend validation duplicated server-side.
8. **`shipFromCity/Province/Country`** — denormalized correctly from primary warehouse.
9. **Error UX** — all error states surfaced to user; no silent swallowed exceptions.
10. **Category/condition enums** — only valid schema constant values accepted.
""",

    "auth_seller_onboarding": """\
# Audit: Auth & Seller Onboarding

## What to Audit
1. **Rate limiting** — login/signup endpoints rate-limited; `RELAXED_RATE_LIMITS` only for dev/emulator.
2. **User doc creation** — only via `create_user_profile` CF (idempotent); no direct client Firestore writes.
3. **Stripe Connect Express** — onboarding URL generated correctly; account status polled safely.
4. **Seller role assignment** — `isSeller` flag set only after Stripe onboarding complete; not self-assignable.
5. **MFA** — secrets stored in `user_security/{uid}` (backend-only); `users` doc has only `mfaEnabled` flag.
6. **Consent capture** — `ConsentMethodValues` stored at signup; CASL/PIPEDA compliance.
7. **Auth state** — `AuthWrapper` correctly redirects based on auth + onboarding state.
8. **Admin role** — cannot be self-assigned; only assigned by existing admin.
9. **Session timeout** — expired sessions handled gracefully.
10. **Seller profile isolation** — seller fields in `seller_profiles/{uid}`, not `users` doc.
""",

    "email_notifications": """\
# Audit: Email Notifications

## What to Audit
1. **Trigger correctness** — every order status transition triggers the right email to the right recipient.
2. **Duplicate send prevention** — emails not sent twice on webhook retry or cron re-run.
3. **Template accuracy** — order totals, shipping info, and links in email templates are correct.
4. **Seller vs. buyer routing** — correct email address used for each; no cross-user leakage.
5. **CASL compliance** — transactional emails compliant; no marketing emails without consent.
6. **Failure handling** — Mailjet failure logged; order not rolled back due to email failure.
7. **Language support** — email language respects user `language` preference (`en`/`fr`).
8. **Refund/dispute emails** — triggered correctly with accurate amounts.
9. **Cron-triggered emails** — auto-confirm and expiry emails sent exactly once.
10. **No PII leakage** — emails do not expose sensitive data (payment details, raw IDs).
""",

    "cron_jobs": """\
# Audit: Cron Jobs

## What to Audit
1. **Idempotency** — every cron handler safe to run multiple times without side effects.
2. **Auto-confirm timing** — confirmation window correct; no premature or missed confirmations.
3. **Expired authorization voiding** — Stripe auth cancellation triggered within 7-day window.
4. **Rate limiter cleanup** — stale rate limit records purged without affecting active limits.
5. **Archive logic** — old orders archived at correct age; no active orders archived.
6. **Error isolation** — one failing record does not abort the entire cron batch.
7. **Concurrency** — cron does not conflict with real-time order updates (Firestore transactions).
8. **Logging** — each cron run logged with count of affected records.
9. **Backfill safety** — cron re-run after downtime does not double-process records.
10. **Stock restoration** — expired/cancelled orders restore stock to correct warehouse.
""",

    "search_discovery": """\
# Audit: Search & Discovery

## What to Audit
1. **Algolia index freshness** — product updates reflected in index within acceptable latency.
2. **Inactive product filtering** — `isActive=false` products excluded from all search results.
3. **Canada buyer filtering** — products not shippable to Canada hidden from buyer search.
4. **Relevance config** — searchable attributes, ranking, and facets correctly configured per environment.
5. **Index environment isolation** — emulator/dev/staging/prod use separate Algolia indices.
6. **Algolia API key scoping** — search key has no write permissions; write key server-side only.
7. **Product card data** — `shipFromCity/Province/Country` + smart multi-location label displayed correctly.
8. **Pagination** — infinite scroll / pagination handles empty pages and end-of-results correctly.
9. **Race condition** — product deleted from Firestore but still in Algolia index = handled gracefully.
10. **Search on product delete** — Algolia record deleted synchronously when product removed.
""",

    "security": """\
# Audit: Security

## What to Audit
1. **Firestore rules** — every collection has correct read/write rules; no wildcards granting unintended access.
2. **Unauthenticated access** — no authenticated data accessible without valid Firebase token.
3. **Rate limiting** — all sensitive endpoints protected; limits per IP + UID.
4. **Input sanitization** — all user input sanitized server-side; no XSS/injection vectors.
5. **Self-purchase bypass** — `sellerId != buyerId` enforced; cannot be bypassed via API.
6. **Price tampering** — client-sent price ignored; backend re-fetches from Firestore.
7. **Role escalation** — users cannot self-assign `admin` or `seller` roles.
8. **Webhook HMAC** — Stripe webhook signature verified before processing; raw body used.
9. **Storage rules** — R2/Cloud Storage rules restrict access to owner only.
10. **Admin collection access** — `user_security`, `webhook_events`, `rate_limits` inaccessible to clients.
""",

    "schema_consistency": """\
# Audit: Schema Consistency (6-Layer Sync)

## What to Audit
1. **Field name parity** — every field in `schema_constants.py` has exact match in `schema_constants.dart`.
2. **Enum value parity** — all enum values identical across Python, Dart, and JSON schemas.
3. **Collection name parity** — `Collections.*` constants identical across Python and Dart.
4. **Pydantic ↔ Freezed parity** — every Pydantic model field has corresponding Freezed field with same name/type.
5. **JSON schema completeness** — `docs/json_schemas/individual/` schemas cover all fields in models.
6. **`database_schema.json`** — top-level schema matches actual Firestore structure.
7. **Money fields** — all money stored as cents (`int`); no dollar floats in any model or schema.
8. **Timestamp fields** — `createdAt`/`updatedAt` present on all documents; correct Firestore Timestamp type.
9. **Optional vs required** — nullable fields consistent across Dart (`?`) and Python (`Optional`).
10. **No magic strings** — no hardcoded field names in handlers; all reference schema constants.
""",

    "seller_profile_warehouses": """\
# Audit: Seller Profile & Warehouses

## What to Audit
1. **Seller profile isolation** — seller-specific fields in `seller_profiles/{uid}`; `users` doc has only `isSeller` flag.
2. **Warehouse sub-collection** — warehouses at `users/{sellerId}/warehouses/{warehouseId}`; correct access rules.
3. **Default warehouse** — exactly one warehouse can be `isDefault=true` per seller; enforced atomically.
4. **Commission basis points** — `commissionRateBps` stored correctly (250 = 2.50%); never stored as float.
5. **Stripe Connect status** — `payoutsEnabled` flag synced from Stripe account status.
6. **Seller cannot sell without onboarding** — products cannot be listed until Stripe onboarding complete.
7. **Warehouse deletion** — cannot delete warehouse assigned to active products; reassignment required.
8. **`shipFromCountries`** — deduped list of countries across all warehouse IDs updated on warehouse change.
9. **Address validation** — warehouse address must be valid; country/province fields required.
10. **Firestore rules** — sellers can only read/write their own `seller_profiles` and `warehouses`.
""",

    "subscription_premium": """\
# Audit: Subscription & Premium Features

## What to Audit
1. **`isPremium` cache consistency** — Firestore `isPremium` flag synced from Stripe subscription status webhook.
2. **Paywall bypass prevention** — premium features gated server-side, not just frontend `isPremium` check.
3. **Subscription expiry** — expired subscriptions downgrade access correctly; no grace period exploit.
4. **Reactivation flow** — cancelled → reactivated subscription restores access atomically.
5. **Stripe webhook dedup** — `customer.subscription.*` events deduplicated via `webhook_events` collection.
6. **Cancel at period end** — cancellation defers until end of billing period; access not immediately revoked.
7. **Cron cleanup** — expired subscriptions identified and flagged by cron; no stale `isPremium=true`.
8. **Seller vs buyer premium** — correct premium tier applied per user role.
9. **Paywall widget** — `PremiumPaywallWidget` correctly shown/hidden based on subscription state.
10. **No double charge** — resubscription flow does not charge twice for overlapping periods.
""",

    "chat_messaging": """\
# Audit: Chat & Messaging

## What to Audit
1. **Access control** — only the buyer and seller of an order can access their chat thread; no cross-user read.
2. **Firestore rules** — chat documents unreadable by third parties including admins (unless flagged).
3. **Message ordering** — messages ordered by server timestamp, not client timestamp (prevents reordering).
4. **Spam prevention** — rate limiting on message sends; no flood attacks.
5. **File/image attachments** — if supported, attachment URLs scoped to chat participants only.
6. **Notification trigger** — new message triggers push/in-app notification to recipient only.
7. **Thread creation** — chat thread created only after order exists; no orphan threads.
8. **Message persistence** — messages not deletable by sender after delivery (dispute evidence).
9. **Blocked users** — if blocking supported, messages from blocked users not delivered.
10. **PII in messages** — no sensitive data (payment info, addresses) exposed via chat API.
""",

    "return_requests": """\
# Audit: Return Requests

## What to Audit
1. **Return state machine** — all valid transitions; invalid transitions (e.g., approve already-rejected) blocked.
2. **Return window** — return request only allowed within policy window after delivery confirmation.
3. **Refund calculation** — refund amount correct (order total minus platform fee); no under/over-refund.
4. **Stock restoration** — stock restored to correct warehouse only after return physically confirmed.
5. **Seller authorization** — only the seller of the order can approve/reject the return.
6. **Buyer authorization** — only the buyer can initiate a return for their own order.
7. **Stripe refund idempotency** — refund not issued twice on webhook retry.
8. **Email triggers** — buyer notified on approval/rejection; seller notified on new return request.
9. **Cross-stack model parity** — `ReturnRequest` fields identical in Dart and Python models.
10. **Dispute escalation** — unresolved returns escalate correctly; admin intervention path exists.
""",

    "admin_panel": """\
# Audit: Admin Panel

## What to Audit
1. **Role enforcement** — every admin endpoint validates `admin` role server-side; not just UI gating.
2. **Audit logging** — all admin actions (ban, refund, role change) logged with actor UID + timestamp.
3. **User ban** — banned user cannot authenticate; active sessions invalidated.
4. **Product moderation** — admin can deactivate any product; seller notified.
5. **Order intervention** — admin can force-cancel/refund orders; idempotency maintained.
6. **Seller verification** — seller approval flow cannot be self-bypassed.
7. **Payment provider management** — `payment_providers` collection write-protected; admin-only.
8. **Security tab** — security alerts surfaced correctly; `requires_manual_review` flag actionable.
9. **Data export / GDPR** — GDPR delete request handled correctly; all user data purged.
10. **Admin self-protection** — admin cannot demote themselves or delete their own account via panel.
""",

    "profile_address": """\
# Audit: Profile & Address Management

## What to Audit
1. **Canada-only validation** — buyer shipping addresses must be in Canada; non-CA addresses rejected server-side.
2. **Address format** — postal code format validated (A1A 1A1); province code in allowed list.
3. **Default address** — exactly one address can be default; setting new default atomically clears old one.
4. **Address deletion** — cannot delete address used in an active/pending order.
5. **Profile update authorization** — users can only update their own profile.
6. **Sensitive field protection** — email/UID not updatable via profile update endpoint.
7. **`users` doc vs `seller_profiles`** — profile update does not accidentally overwrite seller-only fields.
8. **Consent update** — language preference and marketing consent updates stored with `consentMethod`.
9. **Cross-stack field names** — `Address` model fields identical in Dart and Python; no collision with legacy `models.dart`.
10. **Geoapify integration** — address autocomplete does not expose API key client-side.
""",

    "notifications": """\
# Audit: Notifications

## What to Audit
1. **Notification deduplication** — same event does not trigger duplicate notifications.
2. **Recipient targeting** — notification sent to correct user (buyer vs seller) for each event type.
3. **Push token management** — stale/invalid FCM tokens removed; no errors on send to invalid token.
4. **In-app notification state** — read/unread state persisted correctly per user.
5. **Permission gating** — notifications only sent to users who granted permission.
6. **Order event coverage** — all order status transitions trigger appropriate notification.
7. **Rate limiting** — notification floods prevented; per-user notification throttling.
8. **Firestore rules** — users can only read their own notifications; cannot write notification docs directly.
9. **Notification on admin action** — seller notified when product deactivated by admin.
10. **Silent data messages vs display messages** — correct notification type used for background vs foreground.
""",

    "digital_products": """\
# Audit: Digital Products

## What to Audit
1. **Download access control** — download URL only accessible after payment captured; not at authorization.
2. **URL expiry** — signed download URLs expire; cannot be shared after expiry.
3. **Delivery trigger** — digital delivery triggered by correct order status (captured, not just authorized).
4. **No physical shipping** — digital products must not trigger shipping flow or shipping cost calculation.
5. **Stock management** — digital products: unlimited stock (or no stock decrement); no warehouse assignment.
6. **Refund policy** — digital product refund rules enforced (e.g., no refund after download).
7. **File storage security** — digital files in R2 with access restricted to buyer post-purchase only.
8. **Order model** — `isDigital` flag correctly set and used in order handling across stack.
9. **Algolia indexing** — digital products correctly tagged; filterable by type in search.
10. **Cross-stack parity** — digital product fields consistent in Dart/Python/schema.
""",

    "coupons_discounts": """\
# Audit: Coupons & Discounts

## What to Audit
1. **Server-side validation** — coupon code validated backend; client-computed discount never trusted.
2. **Usage limits** — per-coupon and per-user usage limits enforced atomically (no race condition double-use).
3. **Expiry enforcement** — expired coupons rejected server-side; not just UI check.
4. **Discount calculation** — percentage vs fixed discount applied correctly; floor at $0 (no negative totals).
5. **Stacking prevention** — multiple coupons cannot be stacked unless explicitly allowed.
6. **Seller-scoped coupons** — coupon only valid for the seller's products if scoped; not cross-seller.
7. **Cart update on removal** — removing coupon from cart recalculates totals atomically.
8. **Stripe integration** — discount reflected correctly in Stripe PaymentIntent amount.
9. **Audit trail** — coupon usage recorded per order for fraud detection.
10. **Platform fee on discounted price** — platform fee calculated on post-discount amount, not original price.
""",

    "product_qa_ratings": """\
# Audit: Product Q&A & Ratings

## What to Audit
1. **Rating eligibility** — only buyers who completed a purchase (order captured) can rate a product.
2. **One rating per order** — buyer cannot submit multiple ratings for the same order/product.
3. **Rating manipulation** — seller cannot rate their own product; admin cannot inflate ratings.
4. **Average recalculation** — product average rating updated atomically on new rating submission.
5. **Q&A authorization** — anyone can ask; only the seller of that product can officially answer.
6. **Moderation** — admin can remove abusive Q&A entries; seller cannot delete buyer questions.
7. **Firestore rules** — ratings/Q&A documents writable only by eligible users.
8. **Cross-stack parity** — `Ratings` model fields identical in Dart/Python/JSON schema.
9. **Algolia sync** — average rating indexed in Algolia for sort-by-rating feature.
10. **Review content safety** — no PII or payment info in review text; length limits enforced.
""",

    "favorites_seller_products": """\
# Audit: Favorites & Seller Product Listing

## What to Audit
1. **Favorites ownership** — users can only read/write their own favorites; no cross-user access.
2. **Deleted product in favorites** — favorited product deleted by seller handled gracefully (no crash, stale entry cleaned).
3. **Inactive product filtering** — inactive/suspended products excluded from seller product listing and favorites.
4. **Seller product authorization** — seller can only see/manage their own products in seller panel.
5. **Favorites count** — if favorites count stored on product, updated atomically; not trusted from client.
6. **Pagination** — both favorites and seller product list paginate correctly; no N+1 queries.
7. **Algolia vs Firestore** — seller product list reads from Firestore (authoritative); search uses Algolia.
8. **Firestore rules** — `favorites` sub-collection restricted to owner; no public read.
9. **Product card data** — all required fields present for card rendering; no null crashes.
10. **Remove from favorites on product delete** — orphan favorites cleaned up on product deletion.
""",

    "app_bootstrap": """\
# Audit: App Bootstrap & Configuration

## What to Audit
1. **Environment detection** — correct Firebase project, Algolia index, and R2 prefix per environment (emulator/dev/staging/prod).
2. **Route guards** — `authwrapper_screen` correctly routes unauthenticated, unverified, and authenticated users.
3. **Provider initialization** — Riverpod providers initialized in correct order; no uninitialized access at startup.
4. **Session timeout** — 15-minute inactivity timeout fires correctly; auth state cleaned up on sign-out.
5. **Analytics** — events logged without PII; analytics disabled in emulator/dev.
6. **Cloud Function registration** — all handlers registered in `main.py`; no orphan functions.
7. **Config secrets** — no API keys or secrets hardcoded in frontend; all from `--dart-define` or CF environment.
8. **Function options** — memory/timeout/region set correctly per handler sensitivity; payment handlers have higher timeout.
9. **Deferred widgets** — deferred loading does not block critical path screens.
10. **CORS** — backend CORS config includes all hosting domains; no missing origin.
""",

    "legal_compliance": """\
# Audit: Legal & Compliance (PIPEDA, CASL, Quebec Law 25, Bill 96)

## What to Audit
1. **CASL consent** — marketing emails require explicit opt-in; `consentMethod` stored at signup.
2. **PIPEDA / Quebec Law 25** — privacy policy accessible; granular consent collected; user data deletion path exists.
3. **Bill 96 (Quebec)** — French language available for all consumer-facing content; `language` preference respected.
4. **Terms acceptance** — terms/privacy acceptance recorded with version + timestamp before checkout.
5. **Physical address on emails** — all outbound emails include sender's physical address + unsubscribe link.
6. **Terms screen accuracy** — displayed terms text matches actual stored version; no stale cached content.
7. **Unsubscribe flow** — `unsubscribe` link in email leads to functional opt-out; preference persisted in Firestore.
8. **Language selector** — language switch updates `language` field in user doc and email preferences.
9. **Privacy policy screen** — loads current policy; version displayed; no hardcoded old text.
10. **Minor protection** — no mechanism for minors to register; age confirmation at signup if required.
""",

    "design_system": """\
# Audit: Design System & UI Components

## What to Audit
1. **No hardcoded colors** — zero `Color(0x...)` or named colors outside `DesignTokens`; no `withOpacity()` usage.
2. **Modern widget consistency** — all buttons use `ModernButton`, all inputs use `ModernTextField`; no raw `ElevatedButton`/`TextField`.
3. **Loading states** — all async operations use `ModernLoadingIndicator`; no raw `CircularProgressIndicator`.
4. **Glassmorphism correctness** — blur, opacity, and border values from `glassmorphism.dart` constants; not hardcoded.
5. **Responsive layout** — `ResponsiveLayout` breakpoints used for all multi-column layouts; no magic pixel values.
6. **Animation performance** — animations use `RepaintBoundary`; no janky rebuild-heavy animations.
7. **Accessibility** — all interactive widgets have `tooltip` or `Semantics` label; contrast ratios meet WCAG AA.
8. **AppBar consistency** — `ModernAppBar`/`CustomAppBar` used everywhere; no raw `AppBar`.
9. **Mascot integration** — mascot provider correctly scoped; no memory leaks from animation controllers.
10. **Deferred widget** — deferred loading fallback shown correctly; no blank flash or null errors.
""",

    "stock_notifications": """\
# Audit: Stock Notifications & Product Variants

## What to Audit
1. **Notify-me eligibility** — stock notification only registered when product is genuinely out of stock; no false triggers.
2. **Duplicate registration prevention** — user cannot register the same product twice for stock alerts.
3. **Notification send timing** — alert sent when stock restored to > 0; not on partial restock below threshold.
4. **Variant stock isolation** — notifications scoped to correct variant (size/color); not fired for unrelated variants.
5. **Firestore rules** — `stock_notifications` collection writable only by authenticated buyer; readable only by owner + admin.
6. **Cleanup on purchase** — stock notification entry removed after buyer purchases the notified product.
7. **Cleanup on product delete** — orphan notifications cleaned up when product deleted.
8. **Variant model parity** — `variant_models.dart` fields consistent with Python product model variant structure.
9. **Stock decrement atomicity** — variant stock decremented atomically on purchase; no race condition oversell.
10. **Email trigger** — stock notification email template includes correct product/variant info and direct link.
""",

    "supplier_integration": """\
# Audit: Supplier Integration & Platform Config

## What to Audit
1. **CAD-only selling price** — supplier cost currencies are internal only; all listed prices forced to CAD.
2. **Supplier config extensibility** — new supplier can be added to `supplierPlatforms` map without code changes.
3. **No supplier API keys in frontend** — all external supplier API calls go through backend; keys not in Dart code.
4. **Product import flow** — imported supplier product data mapped correctly to `Product` model fields.
5. **Delivery day estimates** — `minDeliveryDays`/`maxDeliveryDays` from supplier config propagate to shipping display.
6. **Supplier deactivation** — deactivating a supplier platform hides its products from search gracefully.
7. **Cross-stack supplier field names** — supplier fields consistent in Dart config, Python model, and Firestore schema.
8. **Image import** — supplier product images imported to R2 with correct env prefix; original URLs not stored publicly.
9. **SKU collision prevention** — imported products use `sellerSku = supplierSku`; dedup enforced across imports.
10. **Seller authorization** — seller can only import products for their own account; no cross-seller imports.
""",
}

# ── Workflow → files map ────────────────────────────────────────────────────
# Do NOT include CLAUDE.md here — it is injected automatically.
FLOWS: dict[str, list[str]] = {
    "checkout_payment": [
        # Frontend
        "origna_gta/lib/features/cart/cart_provider.dart",
        "origna_gta/lib/features/checkout/checkout_provider.dart",
        "origna_gta/lib/features/checkout/checkout_state.dart",
        "origna_gta/lib/screens/cart_screen.dart",
        "origna_gta/lib/screens/cartitem_screen.dart",
        "origna_gta/lib/screens/checkout_screen.dart",
        "origna_gta/lib/screens/payment_screens.dart",
        "origna_gta/lib/core/repositories/cart_repository.dart",
        "origna_gta/lib/core/repositories/order_repository.dart",
        "origna_gta/lib/screens/ordersuccess_screen.dart",
        # Backend
        "functions/handlers/payment_stripe.py",
        "functions/handlers/orders.py",
        "functions/services/shipping_service.py",
        "functions/schema_constants.py",
        # Schema / Rules
        "docs/database_schema.json",
        "firestore.rules",
        "docs/json_schemas/individual/Order.json",
        "docs/json_schemas/individual/OrderCreate.json",
        "docs/json_schemas/individual/OrderItem.json",
        "origna_gta/lib/core/schema/schema_constants.dart",
    ],

    "order_lifecycle": [
        # Frontend
        "origna_gta/lib/features/orders/seller_orders_viewmodel.dart",
        "origna_gta/lib/features/orders/seller_orders_state.dart",
        "origna_gta/lib/features/orders/buyer_orders_viewmodel.dart",
        "origna_gta/lib/features/orders/orders_provider.dart",
        "origna_gta/lib/features/orders/shipping_approval_viewmodel.dart",
        "origna_gta/lib/screens/orders_screen.dart",
        "origna_gta/lib/screens/seller_orders_screen.dart",
        "origna_gta/lib/screens/shipping_approval_screen.dart",
        # Backend
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/handlers/cron_jobs.py",
        "functions/services/email_service.py",
        # Models
        "origna_gta/lib/models/generated/order_models.dart",
        "origna_gta/lib/models/generated/base_models.dart",
        "functions/models/order.py",
        "functions/models/order_event.py",
        "functions/models/base.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/Order.json",
        "docs/json_schemas/individual/OrderItem.json",
        "docs/json_schemas/individual/OrderStatusEnum.json",
        "docs/json_schemas/individual/PaymentStatusEnum.json",
        "docs/json_schemas/individual/ShippingApprovalStatusEnum.json",
        "firestore.rules",
    ],

    "product_lifecycle": [
        # Frontend
        "origna_gta/lib/features/products/add_product_viewmodel.dart",
        "origna_gta/lib/features/products/add_product_state.dart",
        "origna_gta/lib/features/products/edit_product_viewmodel.dart",
        "origna_gta/lib/features/products/edit_product_state.dart",
        "origna_gta/lib/features/products/product_detail_viewmodel.dart",
        "origna_gta/lib/features/products/product_actions_viewmodel.dart",
        "origna_gta/lib/features/products/products_provider.dart",
        "origna_gta/lib/features/products/product_rating_viewmodel.dart",
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/editproduct_screen.dart",
        "origna_gta/lib/screens/productdetails_screen.dart",
        "origna_gta/lib/screens/product_card_screen.dart",
        "origna_gta/lib/screens/productaddimages_screen.dart",
        "origna_gta/lib/core/repositories/product_repository.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/services/algolia_service.py",
        "functions/models/product.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/Product.json",
        "origna_gta/lib/models/generated/product_models.dart",
    ],

    "add_product": [
        # Core UI + ViewModel
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/productaddimages_screen.dart",
        "origna_gta/lib/features/products/add_product_viewmodel.dart",
        "origna_gta/lib/features/products/add_product_state.dart",
        # Warehouse support
        "origna_gta/lib/features/seller/warehouses_viewmodel.dart",
        # Repository + providers
        "origna_gta/lib/core/repositories/product_repository.dart",
        "origna_gta/lib/features/products/products_provider.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/services/algolia_service.py",
        "functions/services/shipping_service.py",
        "functions/models/product.py",
        # Constants + schema
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "origna_gta/lib/models/generated/product_models.dart",
        "docs/json_schemas/individual/Product.json",
    ],

    "auth_seller_onboarding": [
        # Frontend
        "origna_gta/lib/features/auth/auth_provider.dart",
        "origna_gta/lib/features/auth/login_viewmodel.dart",
        "origna_gta/lib/features/auth/login_state.dart",
        "origna_gta/lib/features/seller/seller_registration_view_model.dart",
        "origna_gta/lib/features/seller/seller_registration_state.dart",
        "origna_gta/lib/features/seller/seller_account_status_viewmodel.dart",
        "origna_gta/lib/screens/login_screen.dart",
        "origna_gta/lib/screens/seller_registration_screen.dart",
        "origna_gta/lib/screens/seller_setup_screen.dart",
        "origna_gta/lib/screens/authwrapper_screen.dart",
        "origna_gta/lib/core/repositories/auth_repository.dart",
        "origna_gta/lib/core/repositories/user_repository.dart",
        # Backend
        "functions/handlers/admin.py",
        "functions/handlers/payment_stripe.py",
        "functions/models/user.py",
        "functions/services/rate_limiter.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/User.json",
        "firestore.rules",
    ],

    "email_notifications": [
        "functions/services/email_service.py",
        "functions/services/pdf_invoice_service.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/handlers/cron_jobs.py",
        "functions/schema_constants.py",
    ],

    "cron_jobs": [
        "functions/handlers/cron_jobs.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/schema_constants.py",
        "docs/database_schema.json",
    ],

    "search_discovery": [
        # Frontend
        "origna_gta/lib/features/home/home_viewmodel.dart",
        "origna_gta/lib/features/home/home_state.dart",
        "origna_gta/lib/screens/home_screen.dart",
        "origna_gta/lib/core/repositories/algolia_product_repository.dart",
        "origna_gta/lib/services/algolia_service.dart",
        "origna_gta/lib/widgets/modern_product_card.dart",
        # Backend
        "functions/services/algolia_service.py",
        "functions/handlers/products.py",
        "functions/schema_constants.py",
        "functions/configure_algolia_indices.py",
    ],

    "security": [
        "firestore.rules",
        "storage.rules",
        "functions/services/rate_limiter.py",
        "functions/utils/helpers.py",
        "functions/utils/crypto_utils.py",
        "functions/utils/function_options.py",
        "functions/handlers/admin.py",
        "origna_gta/lib/core/repositories/auth_repository.dart",
        "origna_gta/lib/features/auth/auth_provider.dart",
        "origna_gta/lib/services/session_timeout_service.dart",
        "origna_gta/lib/utils/circuit_breaker.dart",
        "functions/schema_constants.py",
        "docs/database_schema.json",
    ],

    "schema_consistency": [
        "docs/database_schema.json",
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "functions/models/base.py",
        "functions/models/order.py",
        "functions/models/product.py",
        "functions/models/user.py",
        "functions/models/seller_profile.py",
        "origna_gta/lib/models/generated/base_models.dart",
        "origna_gta/lib/models/generated/order_models.dart",
        "origna_gta/lib/models/generated/product_models.dart",
        "origna_gta/lib/models/generated/user_models.dart",
        "origna_gta/lib/models/generated/seller_profile_models.dart",
        "origna_gta/lib/models/generated/models.dart",
        "origna_gta/lib/models/models.dart",
        "origna_gta/lib/models/enum_extensions.dart",
        "origna_gta/lib/utils/constants.dart",
        # Individual JSON schemas
        "docs/json_schemas/individual/Order.json",
        "docs/json_schemas/individual/OrderCreate.json",
        "docs/json_schemas/individual/OrderItem.json",
        "docs/json_schemas/individual/OrderStatusEnum.json",
        "docs/json_schemas/individual/PaymentStatusEnum.json",
        "docs/json_schemas/individual/Product.json",
        "docs/json_schemas/individual/ProductCreate.json",
        "docs/json_schemas/individual/Ratings.json",
        "docs/json_schemas/individual/Taxes.json",
        "docs/json_schemas/individual/User.json",
        "docs/json_schemas/individual/UserCreate.json",
        "docs/json_schemas/individual/UserRole.json",
        "docs/json_schemas/individual/Address.json",
        "docs/json_schemas/individual/AddressDetails.json",
        "docs/json_schemas/individual/SellerDeliveryOption.json",
        "docs/json_schemas/individual/SellerPayout.json",
        "docs/json_schemas/individual/ShippingApprovalStatusEnum.json",
        "docs/json_schemas/individual/DeliveryStatusEnum.json",
        "firestore.rules",
    ],

    # ── NEW FLOWS ─────────────────────────────────────────────────────────────

    "seller_profile_warehouses": [
        # Seller profile
        "origna_gta/lib/features/seller/seller_registration_view_model.dart",
        "origna_gta/lib/features/seller/seller_registration_state.dart",
        "origna_gta/lib/features/seller/seller_account_status_viewmodel.dart",
        "origna_gta/lib/features/seller/warehouses_viewmodel.dart",
        "origna_gta/lib/screens/seller_registration_screen.dart",
        "origna_gta/lib/screens/seller_setup_screen.dart",
        "origna_gta/lib/screens/seller/seller_warehouses_screen.dart",
        "origna_gta/lib/screens/seller_integration_screen.dart",
        "origna_gta/lib/models/generated/seller_profile_models.dart",
        # Backend
        "functions/models/seller_profile.py",
        "functions/handlers/admin.py",
        "functions/handlers/payment_stripe.py",
        # Schema
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "subscription_premium": [
        # Frontend
        "origna_gta/lib/features/subscription/subscription_provider.dart",
        "origna_gta/lib/features/subscription/subscription_state.dart",
        "origna_gta/lib/screens/subscription_screen.dart",
        "origna_gta/lib/screens/subscription_cancel_screen.dart",
        "origna_gta/lib/screens/subscription_success_screen.dart",
        "origna_gta/lib/widgets/premium_paywall_widget.dart",
        # Backend
        "functions/handlers/subscriptions.py",
        "functions/handlers/payment_stripe.py",
        "functions/handlers/cron_jobs.py",
        "functions/utils/premium_check.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "chat_messaging": [
        # Frontend
        "origna_gta/lib/features/chat/chat_provider.dart",
        "origna_gta/lib/features/chat/chat_repository.dart",
        "origna_gta/lib/screens/chat_screen.dart",
        # Backend
        "functions/handlers/chat.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "return_requests": [
        # Frontend
        "origna_gta/lib/models/generated/return_request_models.dart",
        "origna_gta/lib/features/orders/buyer_orders_viewmodel.dart",
        "origna_gta/lib/features/orders/seller_orders_viewmodel.dart",
        "origna_gta/lib/screens/orders_screen.dart",
        "origna_gta/lib/screens/seller_orders_screen.dart",
        # Backend
        "functions/models/return_request.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/services/email_service.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "admin_panel": [
        # Frontend screens
        "origna_gta/lib/features/admin/admin_panel_screen.dart",
        "origna_gta/lib/features/admin/admin_actions_viewmodel.dart",
        "origna_gta/lib/features/admin/admin_providers.dart",
        "origna_gta/lib/features/admin/admin_repository.dart",
        "origna_gta/lib/features/admin/tabs/admin_orders_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_products_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_sellers_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_users_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_reviews_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_security_tab.dart",
        "origna_gta/lib/features/admin/tabs/admin_payment_providers_tab.dart",
        # Backend
        "functions/handlers/admin.py",
        "functions/handlers/payment_providers.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "profile_address": [
        # Frontend
        "origna_gta/lib/features/profile/profile_viewmodel.dart",
        "origna_gta/lib/features/profile/profile_state.dart",
        "origna_gta/lib/features/profile/profile_provider.dart",
        "origna_gta/lib/features/profile/address_viewmodel.dart",
        "origna_gta/lib/features/profile/address_state.dart",
        "origna_gta/lib/features/profile/address_management_viewmodel.dart",
        "origna_gta/lib/screens/profile_screen.dart",
        "origna_gta/lib/screens/addressmanagement_screen.dart",
        "origna_gta/lib/screens/editaddress_screen.dart",
        "origna_gta/lib/core/repositories/user_repository.dart",
        "origna_gta/lib/core/repositories/location_repository.dart",
        # Backend
        "functions/handlers/users.py",
        "functions/handlers/addresses.py",
        "functions/models/user.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "origna_gta/lib/models/generated/user_models.dart",
        "docs/json_schemas/individual/User.json",
        "docs/json_schemas/individual/Address.json",
        "docs/json_schemas/individual/AddressDetails.json",
        "firestore.rules",
    ],

    "notifications": [
        # Frontend
        "origna_gta/lib/features/notifications/notification_provider.dart",
        "origna_gta/lib/services/notification_service.dart",
        # Backend
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/services/email_service.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "digital_products": [
        # Backend
        "functions/handlers/digital.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/models/product.py",
        "functions/models/order.py",
        # Frontend
        "origna_gta/lib/models/generated/product_models.dart",
        "origna_gta/lib/models/generated/order_models.dart",
        "origna_gta/lib/screens/productdetails_screen.dart",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/json_schemas/individual/Product.json",
        "docs/json_schemas/individual/Order.json",
        "firestore.rules",
    ],

    "coupons_discounts": [
        # Backend
        "functions/handlers/coupons.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        # Frontend
        "origna_gta/lib/features/cart/cart_provider.dart",
        "origna_gta/lib/features/checkout/checkout_provider.dart",
        "origna_gta/lib/screens/cart_screen.dart",
        "origna_gta/lib/screens/checkout_screen.dart",
        "origna_gta/lib/core/repositories/cart_repository.dart",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "product_qa_ratings": [
        # Q&A
        "origna_gta/lib/features/qa/qa_provider.dart",
        "origna_gta/lib/features/qa/qa_repository.dart",
        "origna_gta/lib/models/qa_model.dart",
        # Ratings
        "origna_gta/lib/features/products/product_rating_viewmodel.dart",
        "origna_gta/lib/widgets/rating_dialog.dart",
        "origna_gta/lib/widgets/rating_histogram.dart",
        "origna_gta/lib/screens/productdetails_screen.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/handlers/orders.py",
        # Schema / Rules
        "docs/json_schemas/individual/Ratings.json",
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    "favorites_seller_products": [
        # Frontend
        "origna_gta/lib/screens/favorites_screen.dart",
        "origna_gta/lib/features/seller/seller_products_viewmodel.dart",
        "origna_gta/lib/screens/seller_products_screen.dart",
        "origna_gta/lib/core/repositories/product_repository.dart",
        "origna_gta/lib/widgets/modern_product_card.dart",
        # Backend
        "functions/handlers/products.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "firestore.rules",
    ],

    # ── NEW FLOWS ─────────────────────────────────────────────────────────────

    "app_bootstrap": [
        # App entry & routing
        "origna_gta/lib/main.dart",
        "origna_gta/lib/origna_app.dart",
        "origna_gta/lib/core/routes.dart",
        "origna_gta/lib/screens/main_screen.dart",
        "origna_gta/lib/screens/common_screens.dart",
        "origna_gta/lib/screens/authwrapper_screen.dart",
        # Config & providers
        "origna_gta/lib/utils/env_config.dart",
        "origna_gta/lib/core/providers.dart",
        "origna_gta/lib/services/conf_services.dart",
        "origna_gta/lib/services/analytics_service.dart",
        "origna_gta/lib/services/session_timeout_service.dart",
        "origna_gta/lib/utils/utils.dart",
        # Backend entry
        "functions/main.py",
        "functions/config.py",
        "functions/utils/function_options.py",
    ],

    "legal_compliance": [
        # Screens
        "origna_gta/lib/screens/privacy_policy_screen.dart",
        "origna_gta/lib/screens/terms_screen.dart",
        "origna_gta/lib/screens/terms_of_service_screen.dart",
        "origna_gta/lib/features/terms/terms_provider.dart",
        "origna_gta/lib/widgets/legal_screen_body.dart",
        "origna_gta/lib/widgets/language_selector.dart",
        # Auth (consent capture)
        "origna_gta/lib/screens/login_screen.dart",
        "functions/handlers/users.py",
        "functions/services/email_service.py",
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
    ],

    "design_system": [
        # Tokens & utilities
        "origna_gta/lib/utils/design_tokens.dart",
        "origna_gta/lib/utils/glassmorphism.dart",
        "origna_gta/lib/utils/responsive_layout.dart",
        "origna_gta/lib/utils/animations.dart",
        "origna_gta/lib/utils/deferred_widget.dart",
        # Modern widget library
        "origna_gta/lib/widgets/modern_button.dart",
        "origna_gta/lib/widgets/modern_card.dart",
        "origna_gta/lib/widgets/modern_textfield.dart",
        "origna_gta/lib/widgets/modern_loading_indicator.dart",
        "origna_gta/lib/widgets/modern_appbar.dart",
        "origna_gta/lib/widgets/custom_app_bar.dart",
        "origna_gta/lib/widgets/animations.dart",
        # Mascot
        "origna_gta/lib/widgets/mascot/canadian_moose.dart",
        "origna_gta/lib/widgets/mascot/mascot_provider.dart",
        "origna_gta/lib/widgets/mascot/moose_provider.dart",
        "origna_gta/lib/widgets/mascot/shop_mascot.dart",
        "origna_gta/lib/widgets/mascot/mascot_preview.dart",
    ],

    "stock_notifications": [
        # Frontend
        "origna_gta/lib/features/products/stock_notification_provider.dart",
        "origna_gta/lib/features/products/variant_models.dart",
        "origna_gta/lib/features/products/products_provider.dart",
        "origna_gta/lib/screens/productdetails_screen.dart",
        "origna_gta/lib/core/repositories/product_repository.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/handlers/orders.py",
        "functions/services/email_service.py",
        # Schema / Rules
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/database_schema.json",
        "docs/json_schemas/individual/Product.json",
        "firestore.rules",
    ],

    "supplier_integration": [
        # Supplier config
        "origna_gta/lib/core/config/supplier_config.dart",
        # Product flow (supplier products imported as listings)
        "origna_gta/lib/features/products/add_product_viewmodel.dart",
        "origna_gta/lib/features/products/add_product_state.dart",
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/core/repositories/product_repository.dart",
        "functions/handlers/products.py",
        "functions/models/product.py",
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "docs/json_schemas/individual/Product.json",
    ],
}


def copy_flow(flow_name: str, file_paths: list[str]) -> tuple[int, int, int]:
    """Copy files for a flow into Desktop/origna_flows/<flow_name>/. Returns (copied, missing, total_bytes).

    - Writes INSTRUCTIONS.md (does NOT count toward MAX_FILES_PER_FLOW).
    - CLAUDE.md is always prepended as the first file.
    - If total files exceed MAX_FILES_PER_FLOW, excess files are concatenated into _overflow.md.
    - Total content is capped at MAX_TOTAL_BYTES to respect Claude.ai's context limit.
    - Folder will have at most 20 files: 18 primary + INSTRUCTIONS.md + _overflow.md.
    """
    dest_root = DESKTOP / flow_name
    if dest_root.exists():
        shutil.rmtree(dest_root)
    dest_root.mkdir(parents=True)

    # Write INSTRUCTIONS.md (not counted in file limit)
    instructions_body = FLOW_INSTRUCTIONS.get(flow_name, "")
    instructions_text = instructions_body + _COMMON_FOOTER
    (dest_root / "INSTRUCTIONS.md").write_text(instructions_text, encoding="utf-8")

    total_bytes = len(instructions_text.encode("utf-8"))

    # Always prepend CLAUDE.md
    all_files = [_CLAUDE] + [f for f in file_paths if f != _CLAUDE]

    # Split into normal (first MAX_FILES_PER_FLOW) and overflow
    primary = all_files[:MAX_FILES_PER_FLOW]
    overflow = list(all_files[MAX_FILES_PER_FLOW:])

    copied = 0
    missing = 0
    deferred: list[str] = []  # primary files bumped to overflow due to size limit

    for rel in primary:
        src = REPO_ROOT / rel
        if not src.exists():
            print(f"  ⚠️  MISSING: {rel}")
            missing += 1
            continue
        file_bytes = src.stat().st_size
        # Always include CLAUDE.md; defer others if size cap would be exceeded
        if rel != _CLAUDE and total_bytes + file_bytes > MAX_TOTAL_BYTES:
            deferred.append(rel)
            continue
        dest = dest_root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        total_bytes += file_bytes
        copied += 1

    # Concatenate overflow + deferred files into _overflow.md
    all_overflow = deferred + overflow
    if all_overflow:
        overflow_parts: list[str] = []
        for rel in all_overflow:
            src = REPO_ROOT / rel
            if not src.exists():
                print(f"  ⚠️  MISSING (overflow): {rel}")
                missing += 1
                continue
            try:
                content = src.read_text(encoding="utf-8", errors="replace")
            except Exception as e:
                content = f"[Error reading file: {e}]"
            header = f"## FILE: {rel}\n\n```\n"
            footer = "\n```\n"
            chunk_bytes = len((header + content + footer).encode("utf-8"))
            if total_bytes + chunk_bytes > MAX_TOTAL_BYTES:
                # Truncate content to fit within remaining budget
                header_b = header.encode("utf-8")
                trunc_footer = b"\n[TRUNCATED -- size limit reached]\n```\n"
                remaining = MAX_TOTAL_BYTES - total_bytes - len(header_b) - len(trunc_footer)
                if remaining < 20:
                    break  # no room left — stop adding overflow files
                truncated = content.encode("utf-8")[:remaining].decode("utf-8", errors="ignore")
                part = header + truncated + "\n[TRUNCATED — size limit reached]\n```\n"
                overflow_parts.append(part)
                total_bytes += len(part.encode("utf-8"))
                copied += 1
                break  # stop after truncated entry
            overflow_parts.append(f"## FILE: {rel}\n\n```\n{content}\n```\n")
            total_bytes += chunk_bytes
            copied += 1

        if overflow_parts:
            overflow_md = dest_root / "_overflow.md"
            overflow_md.write_text(
                f"# Overflow files for flow: {flow_name}\n\n"
                + "\n---\n\n".join(overflow_parts),
                encoding="utf-8",
            )

    folder_files = sum(1 for f in dest_root.rglob("*") if f.is_file())  # actual files to upload to Claude.ai
    return copied, missing, total_bytes, folder_files


def main() -> None:
    print(f"📂 Output: {DESKTOP}\n")
    total_copied = 0
    total_missing = 0

    for flow, files in FLOWS.items():
        copied, missing, flow_bytes, folder_files = copy_flow(flow, files)
        status = "✅" if missing == 0 else "⚠️ "
        size_kb = flow_bytes / 1024
        size_note = f"  📦 {size_kb:.0f} KB" + ("  ⚠️ NEAR LIMIT" if flow_bytes > MAX_TOTAL_BYTES * 0.95 else "")
        print(f"{status} {flow:<35}  {folder_files}/20 files  ({missing} missing){size_note}")
        total_copied += copied
        total_missing += missing

    print(f"\nDone — {total_copied} files copied, {total_missing} missing across {len(FLOWS)} flows.")
    print(f"📁 Open: {DESKTOP}")
    print(f"ℹ️  Size cap: {MAX_TOTAL_BYTES // 1024} KB per flow  |  Max files: {MAX_FILES_PER_FLOW} primary + INSTRUCTIONS.md + _overflow.md = 20 total")


if __name__ == "__main__":
    main()
