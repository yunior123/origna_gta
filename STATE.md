# STATE.md — Audit Findings & Tasks (2026-03-22)

## Security Audit — Rust Backend

### P0 — Critical (fix immediately)
- [ ] `orignabase/crates/ob-handlers/src/payments/webhooks.rs:187` — Webhook HMAC comparison is NOT constant-time (timing attack). Use `subtle::ConstantTimeEq` or `hmac::Mac::verify_slice()`
- [ ] `orignabase/crates/ob-auth/src/rate_limit.rs:228` — SQL injection: `user_id` and `action` string-interpolated into SurrealQL. Use `query_bind_value` with `$user_id` params

### P1 — High (fix before launch)
- [ ] `orignabase/crates/ob-handlers/src/payments/webhooks.rs:164-188` — No webhook timestamp replay protection (reject events >300s old)
- [ ] `orignabase/crates/ob-handlers/src/payments/webhooks.rs:151-155` — Internal error details leaked in webhook response body
- [ ] `orignabase/crates/ob-auth/src/rate_limit.rs:54-73` — Auth rate limiter trusts X-Forwarded-For from ANY source (spoofable). Only trust from 127.0.0.1
- [ ] `orignabase/crates/ob-core/src/error.rs:51-57` — Database/Internal error details exposed in API responses. Return generic message
- [ ] `orignabase/crates/ob-auth/src/middleware.rs:50-89` — OB_TEST_MODE bypasses ALL auth validation. Verify never set in prod
- [ ] `orignabase/crates/ob-admin/src/routes.rs:150-152` — OB_TEST_MODE skips admin authorization entirely

### P2 — Medium
- [ ] `orignabase/crates/ob-admin/src/routes.rs:209` — Config key uses naive escape instead of parameterized query
- [ ] `orignabase/crates/ob-auth/src/rate_limit.rs:16-17` — EndpointRateLimiter is NotKeyed (global bucket, not per-IP)
- [ ] `orignabase/crates/ob-core/src/server.rs:56-58` — Empty CORS origins config silently denies all (silent outage risk)
- [ ] `orignabase/crates/ob-handlers/src/shared/validation.rs:19-28` — Price validation max ($1M) vs checkout max ($100K) mismatch
- [ ] `orignabase/crates/ob-handlers/src/shared/validation.rs:31-38` — Email validation too permissive (only checks @ and .)
- [ ] `orignabase/crates/ob-handlers/src/payments/webhooks.rs:199` — Webhook event ID validated as SurrealDB format but Stripe uses evt_xxx

## Cross-Stack Audit — Dart vs Rust Field Names

### P0 — Runtime Failures (7 mismatches)
- [ ] OrderStatus enums: Dart `pending/confirmed/shipped` vs Rust `PENDING_PAYMENT/PAYMENT_AUTHORIZED/SHIPPED` — completely different naming
- [ ] PaymentStatus enums: Dart `awaiting_payment` vs Rust `PENDING` — different names AND case
- [ ] Money: Dart `platformFeeTotalCents` vs Rust `platformFeeCents` — checkout writes wrong field
- [ ] Checkout: Dart `stripeSessionId` vs Rust `checkoutSessionId` — can't look up sessions
- [ ] Chat: Dart `text` vs Rust `messageText` — messages won't display
- [ ] Address: Dart `state` vs Rust `province` — addresses won't parse
- [ ] Product: Dart `name` vs Rust `title` — product names won't display

### P1 — Data Inconsistency (8 mismatches)
- [ ] `isAgeRestricted` vs `ageRestricted`
- [ ] `categoryId` vs `category`
- [ ] `maxUsesTotal` vs `maxUses` (coupons)
- [ ] `preferredLanguage` vs `language`
- [ ] Return window: 7 days (Dart) vs 30 days (Rust)
- [ ] Premium price: $7.86 (Dart) vs $9.99 (Rust)
- [ ] Authorization expiry: 6 days (Dart) vs 7 days (Rust)
- [ ] Support email: `support@orignagta.ca` (Dart) vs `support@orignaventures.ca` (Rust)

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
- [ ] `screens/productdetails_screen.dart` — 4 watches without select (full product, VM, ratings, profile)
- [ ] `screens/profile_screen.dart` — 3 watches without select
- [ ] `screens/seller_orders_screen.dart` — 2 watches without select
- [ ] `screens/checkout_screen.dart` — full profile watch
- [ ] `features/admin/admin_panel_screen.dart` — 4 watches without select
- [ ] ... 18+ more files

### P1 — Large files (22 files >500 lines)
- [ ] `screens/addproduct_screen.dart` — **3543 lines** (extract into sections)
- [ ] `screens/editproduct_screen.dart` — 1440 lines
- [ ] `screens/login_screen.dart` — 1168 lines
- [ ] `screens/cart_screen.dart` — 1134 lines
- [ ] ... 18 more files 500-1044 lines

### P2 — CachedNetworkImage missing dimensions (4)
- [ ] `widgets/modern_product_card.dart:142`
- [ ] `screens/product_card_screen.dart:157`
- [ ] `screens/productdetails_screen.dart:426`
- [ ] `screens/widgets/product_detail/product_reviews_section.dart:507`

### Fixed (from previous audits)
- ListView(children:[]) — 0 remaining
- CachedNetworkImage missing errorWidget — 0 remaining

## Logic Audit — Business Rules

### P0 — Money stored as double (VIOLATES integer cents rule)
- [ ] `lib/models/generated/product_models.dart:99` — `Product.price` is `double`, not int cents
- [ ] `lib/models/generated/product_models.dart:103` — `Product.compareAtPrice` is `double?`
- [ ] `lib/models/generated/product_models.dart:245` — `ProductVariant.price` is `double`
- [ ] `lib/models/generated/order_models.dart:529` — `OrderItem.subtotal` uses `price * quantity` in floating point
- [ ] `lib/models/generated/order_models.dart:595` — `Taxes` model uses `double gst/pst/hst/qst`
- [ ] `lib/utils/utils.dart:78,202` — `calculateDetailedTaxes` and `calculateTieredShipping` operate in doubles
- [ ] `lib/features/checkout/checkout_provider.dart:26-33` — checkout total computed as double
- [ ] Multiple double-to-cents conversions via `(price * 100).round()` — precision risk

### P0 — Return window contradiction
- [ ] `schema_constants.dart:151` — `returnWindowDays = 7` but error_codes.dart:149 says "30-day return window"
- [ ] `seller_profile_models.dart:54` — defaults `returnWindowDays` to 30 (unused in eligibility check)
- [ ] Decide: 7 or 30 days? Align constant, error message, and seller profile default

### P1 — Business logic in screens (MVVM violation)
- [ ] `screens/seller_orders_screen.dart:137,248-251` — revenue, platform fee calculated inline
- [ ] `screens/checkout_screen.dart:278-286` — tax and total inline in build()
- [ ] `screens/parts/checkout_summary_section.dart:248-255` — tax recalculated in widget
- [ ] `screens/parts/checkout_items_section.dart:16,198-202` — fee and subtotal inline

### P1 — Perishable not auto-linked to local delivery
- [ ] `features/products/add_product_viewmodel.dart:496` — togglePerishable doesn't set isLocalDeliveryOnly
- [ ] `features/products/edit_product_viewmodel.dart:236` — same gap

### Passing Rules
- Free shipping threshold: 7500 cents ($75 CAD) — correct
- Platform fee base: subtotalCents (not totalAmountCents) — correct
- Order state machine: no invalid skips — correct (evolved beyond spec)
- Stock decrement: server-side only — correct

## Test Coverage
- Baseline: 4258 pass, 149 skip, 106 fail
- Target: 95%+ coverage, 0 failures
- Status: fix agent running
