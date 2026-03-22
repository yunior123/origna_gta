# STATE.md — Audit Findings & Tasks (2026-03-22)

## Security Audit — Rust Backend

### P0 — Critical (FIXED 2026-03-22)
- [x] Webhook HMAC: constant-time comparison via `mac.verify_slice()`
- [x] SQL injection: parameterized MFA rate limiter queries via `query_bind_value`
- [x] Webhook replay protection: reject >300s old timestamps
- [x] Webhook error response: generic message, no internal details leaked

### P1 — High (fix before launch)
- [ ] `ob-auth/src/rate_limit.rs:54-73` — Auth rate limiter trusts X-Forwarded-For from ANY source. Only trust from 127.0.0.1
- [ ] `ob-core/src/error.rs:51-57` — Database/Internal error details exposed in API responses. Return generic message
- [ ] `ob-auth/src/middleware.rs:50-89` — OB_TEST_MODE bypasses ALL auth validation. Verify never set in prod
- [ ] `ob-admin/src/routes.rs:150-152` — OB_TEST_MODE skips admin authorization entirely

### P2 — Medium
- [ ] `ob-admin/src/routes.rs:209` — Config key uses naive escape instead of parameterized query
- [ ] `ob-auth/src/rate_limit.rs:16-17` — EndpointRateLimiter is NotKeyed (global bucket, not per-IP)
- [ ] `ob-core/src/server.rs:56-58` — Empty CORS origins config silently denies all
- [ ] `ob-handlers/src/shared/validation.rs:19-28` — Price validation max ($1M) vs checkout max ($100K) mismatch
- [ ] `ob-handlers/src/shared/validation.rs:31-38` — Email validation too permissive
- [ ] `ob-handlers/src/payments/webhooks.rs:199` — Webhook event ID validated as SurrealDB format but Stripe uses evt_xxx

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

## Test Coverage (2026-03-22) — ALL GREEN
- Rust: **3,208 pass, 0 fail, 0 skip**
- Flutter (all): **4,953 pass, 0 fail, 0 skip**
- Live integration: **175 pass, 0 fail** (included in Flutter count)
- **Total: 8,161 tests, 0 failures, 0 skips**
- Test command: `flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden`

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
