# STATE.md — Audit Findings & Tasks (2026-03-22)

## Security Audit — Rust Backend

### P0 — Critical (FIXED 2026-03-22)
- [x] Webhook HMAC: constant-time comparison via `mac.verify_slice()`
- [x] SQL injection: parameterized MFA rate limiter queries via `query_bind_value`
- [x] Webhook replay protection: reject >300s old timestamps
- [x] Webhook error response: generic message, no internal details leaked

### P1 — FIXED 2026-03-22
- [x] rate_limit.rs: XFF only trusted from 127.0.0.1 (Caddy proxy)
- [x] error.rs: Generic "Internal server error" for Database/Internal/Config variants
- [x] middleware.rs: Warn on OB_TEST_MODE bypass, panic if ENVIRONMENT=production
- [x] admin routes.rs: Hard-reject admin bypass in production mode

### P2 — FIXED 2026-03-22
- [x] Admin config: parameterized query (was naive string escape)
- [x] Rate limiter: confirmed already per-IP keyed (DashMap<IpAddr>)
- [x] CORS: warning log on empty allowed_origins
- [x] Price validation: max aligned to $100K (was $1M)
- [x] Email validation: proper regex
- [x] Webhook event ID: removed SurrealDB format check for Stripe evt_xxx

## Cross-Stack Audit — Dart vs Rust Field Names

### P0 — FIXED 2026-03-22 (17 Rust files aligned to Dart)
- [x] OrderStatus: lowercase (`pending`, `confirmed`, `shipped`, etc.)
- [x] PaymentStatus: `awaiting_payment`, `authorized`, `captured`, `partially_refunded`
- [x] `platformFeeTotalCents` (was `platformFeeCents`)
- [x] `stripeSessionId` (was `checkoutSessionId`)
- [x] `text` for chat (was `messageText`)
- [x] `state` for address (was `province`)
- [x] `name` for product (was `title`)
- [x] `categoryId` (was `category`), `preferredLanguage` (was `language`), `maxUsesTotal` (was `maxUses`)
- [x] Business rules aligned: returnWindow=30d, premium=$7.86, authExpiry=6d, support=support@orignagta.ca
- [x] Serde aliases for backward compat with old DB values

### P1 — Data Inconsistency (remaining)
- [x] Return window: aligned to 30 days everywhere
- [x] Premium price: aligned to $7.86
- [x] Authorization expiry: aligned to 6 days
- [x] Support email: aligned to support@orignagta.ca
- [ ] `isAgeRestricted` vs `ageRestricted` — minor, non-blocking

### P2 — Missing Definitions
- [ ] 5 Rust collections missing from Dart (reviews, buyer_addresses, download_sessions, disputes, meilisearch_sync_failures)
- [ ] Rust `shippingCarrier` schema constant unused — handlers write `carrier` inline
- [ ] Rust `unreadCount` schema constant unused — handlers write `buyerUnreadCount`/`sellerUnreadCount`

## Performance Audit — Flutter

### P0 — setState() in screens (92 calls across 30 files)
- [ ] `screens/seller_setup_screen.dart` — 8 setState() calls
- [ ] `screens/return_request_screen.dart` — 6 setState()
- [ ] `screens/productaddimages_screen.dart` — 5 setState()
- [ ] `widgets/rating_dialog.dart` — 5 setState()
- [ ] `screens/parts/profile_settings_section.dart` — 5 setState()
- [ ] `widgets/order_widgets.dart` — 4 setState()
- [ ] ... 24 more files with 1-4 setState() each

### P1 — ref.watch() without .select() (154 in UI)
- [ ] `screens/productdetails_screen.dart` — 4 watches without select
- [ ] `screens/profile_screen.dart` — 3 watches without select
- [ ] ... 18+ more files

### P1 — Large files (22 files >500 lines)
- [ ] `screens/addproduct_screen.dart` — **3543 lines** (extract into sections)
- [ ] `screens/editproduct_screen.dart` — 1440 lines
- [ ] `screens/login_screen.dart` — 1168 lines
- [ ] ... 18 more files 500-1044 lines

### P2 — CachedNetworkImage missing dimensions (4)
- [ ] `widgets/modern_product_card.dart:142`
- [ ] `screens/product_card_screen.dart:157`
- [ ] `screens/productdetails_screen.dart:426`
- [ ] `screens/widgets/product_detail/product_reviews_section.dart:507`

### Fixed (from previous audits)
- [x] ListView(children:[]) — 0 remaining
- [x] CachedNetworkImage missing errorWidget — 0 remaining

## Logic Audit — Business Rules

### P0 — Money stored as double (DEFERRED — needs freezed rebuild)
- [ ] `lib/models/generated/product_models.dart:99` — `Product.price` is `double`, not int cents
- [ ] `lib/models/generated/order_models.dart:529` — `OrderItem.subtotal` uses double arithmetic
- [ ] `lib/models/generated/order_models.dart:595` — `Taxes` model uses `double gst/pst/hst/qst`
- [ ] `lib/utils/utils.dart:78,202` — tax/shipping functions operate in doubles
- [ ] `lib/features/checkout/checkout_provider.dart:26-33` — checkout total as double

### P0 — FIXED 2026-03-22
- [x] Return window: changed from 7 to 30 days (aligned Dart + Rust + error messages)
- [x] Perishable auto-links local delivery when toggled on
- [x] UserRole enum vs UserRoles string mismatch (critical app bug in 15 files)

### P1 — Business logic in screens (MVVM violation)
- [ ] `screens/seller_orders_screen.dart:137,248-251` — revenue, platform fee inline
- [ ] `screens/checkout_screen.dart:278-286` — tax and total inline
- [ ] `screens/parts/checkout_summary_section.dart:248-255` — tax in widget
- [ ] `screens/parts/checkout_items_section.dart:16,198-202` — fee/subtotal inline

## Test Coverage (2026-03-22) — ALL GREEN, ZERO SKIPS
- [x] Rust: **3,208 pass, 0 fail, 0 skip**
- [x] Flutter app: **4,953 pass, 0 fail, 0 skip**
- [x] OrignaBase SDK: **538 pass, 0 fail, 0 skip**
- [x] **Total: 8,699 tests, 0 failures, 0 skips**
- [x] Stress tests: k6 auth storm (983 reqs, 0% fail) + large payloads (520 reqs, avg 217ms, 0% fail)
- Test command: `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden`

## Stripe Webhook Audit (2026-03-22)

### Gaps — FIXED 2026-03-22 (6 handlers + 20 tests added)
- [x] `checkout.session.completed` — confirms order, decrements stock, marks coupon
- [x] `charge.dispute.created` — flags order as disputed, creates disputes record
- [x] `checkout.session.expired` — expires order, releases stock/coupons
- [x] `checkout.session.async_payment_succeeded` / `async_payment_failed`
- [x] `account.updated` — syncs Stripe Connect seller status
- [ ] Prod endpoint: update from `*` to explicit list via Stripe Dashboard (live key required)

### Verified OK
- [x] Webhook secrets match across vault, VPS .env, and MEMORY.md (all 3 envs)
- [x] Delivery test: payment_intent.succeeded received + verified + parsed
- [x] HMAC signature verification, replay protection, constant-time comparison
- [x] Idempotency dedup via webhook_events collection
- [x] Stripe CLI guide: `docs/stripe-cli-guide.md`

## Infrastructure
- [x] Monorepo unified (orignabase inside origna_gta)
- [x] Pipeline fixed (4 workflows, separate orignabase checkout removed)
- [x] Rust CI added (ci-rust.yml)
- [x] ob-mcp: production JWT auth
- [x] Secret vault (macOS Keychain, 14 keys)
- [x] Agent email (Resend, send-email CLI)
- [x] Agent card (AgentCard.sh, MCP server)
- [x] rust-analyzer installed
- [x] 15 agents: maxTurns + memory
- [x] Dart format PostToolUse hook
- [x] Firebase remnants cleaned (google-services.json deleted)
- [x] Dev DB wiped + reseeded with new schema
- [ ] GitHub Actions billing — fix at github.com/settings/billing
- [ ] Resend domain verification (orignagta.ca)
