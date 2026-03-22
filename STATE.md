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
- [x] Dev DB wiped + reseeded with new schema
- [ ] GitHub Actions billing — fix at github.com/settings/billing
- [ ] Resend domain verification (orignagta.ca)

---

## Full Codebase Audit (2026-03-22) — 32 Agents

### 🔴 SECURITY AUDIT — Critical Findings

#### P0 — IMMEDIATE ACTION REQUIRED

| Issue | Location | Severity |
|-------|----------|----------|
| [ ] **Live secrets committed to repo** | `orignabase/secrets-prod.json` | CRITICAL |
| [ ] **Firebase config still present** | `origna_gta/android/app/google-services.json` | CRITICAL |
| [ ] **Hardcoded Turnstile keys** | `scripts/deploy_web.sh:25-28` | HIGH |

**secrets-prod.json contains:** Stripe live key, Stripe webhook secret, Mailjet API credentials, Cloudflare Turnstile secret, R2 access/secret keys, Sentry DSN, Geoapify API key

**Action:** Rotate ALL exposed secrets immediately. Use BFG Repo-Cleaner to remove from git history.

#### P0 — Translation Files (Firebase References)
- [ ] `assets/translations/en.json:31,45,1503` — "Firebase secrets", "Firebase Auth" in privacy policy
- [ ] `assets/translations/fr.json:31,45,1503` — Same in French

---

### 🔴 ARCHITECTURE VIOLATIONS

#### P0 — MVVM Violations (setState in screens)

| File | setState Count | Lines |
|------|----------------|-------|
| [ ] `screens/seller_setup_screen.dart` | 8 | 467-513 |
| [ ] `screens/return_request_screen.dart` | 6 | 401-437 |
| [ ] `widgets/rating_dialog.dart` | 5 | 137-298 |
| [ ] `screens/parts/profile_settings_section.dart` | 5 | 345-414 |
| [ ] `screens/productaddimages_screen.dart` | 5 | - |
| [ ] `screens/mfa_challenge_screen.dart` | 3 | 44-78 |
| [ ] `screens/common_screens.dart` | 4 | 684-760 |
| [ ] `widgets/order_widgets.dart` | 4 | 724-2522 |
| [ ] `screens/shipping_approval_screen.dart` | 2 | 434-450 |
| [ ] `screens/parts/home_recent_products.dart` | 6 | 77-110 |
| [ ] `screens/parts/checkout_payment_section.dart` | 2 | 200-205 |
| [ ] Total across 30+ files | **81** | - |

#### P0 — Business Logic in Screens (async methods)

30+ async `Future<void>` methods with business logic in screens:
- [ ] `mfa_challenge_screen.dart` — `_submit()`
- [ ] `shipping_approval_screen.dart` — `_handleApproval()`
- [ ] `return_request_screen.dart` — `_submitReturn()`
- [ ] `seller_warehouses_screen.dart` — `_submit()`
- [ ] Direct repository calls in screens (should be ViewModels)

#### P0 — God Files (>1000 lines)

| File | Lines | Issue |
|------|-------|-------|
| [ ] `screens/addproduct_screen.dart` | 3543 | CRITICAL — extract into sections |
| [ ] `core/schema/schema_constants.dart` | 2401 | Large but acceptable |
| [ ] `screens/editproduct_screen.dart` | 1440 | Extract components |
| [ ] `screens/login_screen.dart` | 1168 | Extract auth logic |
| [ ] `screens/cart_screen.dart` | 1134 | Extract sections |
| [ ] `screens/seller_orders_screen.dart` | 990 | Extract order cards |

---

### 🟠 DESIGN TOKENS & COLORS

#### P1 — Direct Color Usage (not DesignTokens)

| File | Issue | Count |
|------|-------|-------|
| [ ] `screens/parts/profile_header.dart` | 15+ `Colors.white` | Lines 41-780 |
| [ ] `screens/addproduct_screen.dart` | 5+ `Colors.white` | Lines 129-3441 |
| [ ] `screens/parts/profile_settings_section.dart` | 5+ `Colors.white` | Lines 25-523 |
| [ ] `screens/login_screen.dart` | 8+ `Colors.white/black` | Lines 152-875 |
| [ ] Total violations | **35+** | - |

**Note:** Mascot and preview hex colors are acceptable (custom painting).

---

### 🟠 MONEY HANDLING — FIXED 2026-03-22

- [x] Product.price → Product.priceCents (int)
- [x] Product.compareAtPrice → compareAtPriceCents (int)
- [x] OrderItem.price → priceCents (int), subtotalCents getter
- [x] Taxes gst/pst/hst/qst → gstCents/pstCents/hstCents/qstCents (int)
- [x] ProductCreate.price → priceCents (int)
- [x] Backward compat fromMap: converts double dollars to int cents

**Violations:** 35+ occurrences of `double` for money values. Most have `*Cents` counterparts for arithmetic.

#### P1 — Price Display Not Using cents/100 Pattern

| File | Issue |
|------|-------|
| [ ] `features/admin/tabs/admin_orders_tab.dart:98` | `total.toStringAsFixed(2)` |
| [ ] `widgets/modern_product_card.dart:269` | `widget.price.toStringAsFixed(2)` |
| [ ] `widgets/order_widgets.dart:1201` | `order.total.toStringAsFixed(2)` |
| [ ] `screens/seller_orders_screen.dart:215` | `totalRevenue.toStringAsFixed(2)` |
| [ ] Total violations | **40+** |

---

### 🟠 FREEZED MIGRATION

#### P1 — State Classes Missing @freezed (22 total)

| State Class | File | Lines |
|-------------|------|-------|
| [ ] `AddProductState` | `features/products/` | 254 |
| [ ] `EditProductState` | `features/products/` | 170 |
| [ ] `CheckoutState` | `features/checkout/` | 171 |
| [ ] `HomeState` | `features/home/` | 121 |
| [ ] `SellerOrdersState` | `features/orders/` | 24 |
| [ ] `ProfileState` | `features/profile/` | 29 |
| [ ] `LoginState` | `features/auth/` | 55 |
| [ ] `MfaState` | `features/auth/` | 50 |
| [ ] `SupportState` | `features/support/` | 59 |
| [ ] `SubscriptionState` | `features/subscription/` | 33 |
| [ ] `ShippingApprovalState` | `features/orders/` | 16 |
| [ ] `BuyerOrdersState` | `features/orders/` | 23 |
| [ ] `AdminActionsState` | `features/admin/` | 22 |
| [ ] `ChatState` | `features/chat/` | 84 |
| [ ] `ProductDetailState` | `features/products/` | 60 |
| [ ] `ProductRatingState` | `features/products/` | 20 |
| [ ] `ProductActionsState` | `features/products/` | 16 |
| [ ] `SellerProductsState` | `features/seller/` | 92 |
| [ ] `WarehousesState` | `features/seller/` | 47 |
| [ ] `SellerRegistrationState` | `features/seller/` | 28 |
| [ ] `AddressState` | `features/profile/` | 59 |
| [ ] `SellerMetrics` | `product_detail_viewmodel.dart` | 20 |

**Pattern:** All use manual `copyWith` with sentinel pattern — should migrate to freezed.

---

### 🟠 SEMANTICS & ACCESSIBILITY

#### P1 — Missing Semantics for E2E Tests

| Category | Issue | Files |
|----------|-------|-------|
| [ ] `btn-*` labels | Missing on PopupMenuButtons, TextButtons in dialogs | 10+ files |
| [ ] `input-*` labels | Missing on TextFields | 15+ files |
| [ ] `product-card-*` | Missing on product cards | 5+ files |
| [ ] Dialog buttons | Missing semantics in confirmation dialogs | 8+ files |
| [ ] GestureDetectors | Missing `button: true` semantics | 10+ files |

**Specific violations:**
- `checkout_payment_section.dart:173,252` — TextField, ChoiceChip
- `seller_products_screen.dart:172,232,311,420` — Multiple missing
- `admin_products_tab.dart:41,206,285,526,600,744,876,939` — Admin panel
- `return_request_screen.dart:188` — TextField
- `mfa_challenge_screen.dart:205,225` — MFA code fields
- `rating_dialog.dart:77` — Review field

---

### 🟠 PAGINATION

#### P1 — Unpaginated Queries (15+ issues)

| Repository | Method | Issue |
|------------|--------|-------|
| [ ] `orignabase_user_repository.dart` | `watchAddresses()` | NO LIMIT — fetches ALL |
| [ ] `orignabase_order_repository.dart` | `fetchReturnRequests()` | NO LIMIT — fetches ALL |
| [ ] `orignabase_product_repository.dart` | `watchFavorites()` | Fixed 50 limit, no cursor |
| [ ] `orignabase_chat_repository.dart` | `_fetchMessages()` | Fixed 100 limit, no cursor |
| [ ] `orignabase_chat_repository.dart` | `_watchThreads()` | Fixed 50 limit |
| [ ] `notification_repository.dart` | `watchNotifications()` | Fixed 50 limit |
| [ ] `orignabase_qa_repository.dart` | `watchQA()` | Fixed 10 limit |
| [ ] Admin: all `watch*()` methods | - | No cursor pagination |

**Good pagination:** `product_search_helpers.dart` has proper cursor-based pagination.

---

### 🟡 STATE MANAGEMENT

#### P2 — Missing .select() Optimization (6 files)

| File | Issue |
|------|-------|
| [ ] `product_info_section.dart:25` | `subscriptionStreamProvider.valueOrNull` |
| [ ] `productdetails_screen.dart:95` | `userProfileProvider.valueOrNull` |
| [ ] `admin_panel_screen.dart:79` | Full providers without select |
| [ ] `cart_screen.dart:30` | `currentUserProvider` without select |
| [ ] `home_hero_section.dart:7-16` | 3 watches to same provider |

---

### 🟡 LOCALIZATION (L10N)

#### P2 — Hardcoded Strings Instead of .tr()

| Location | Issue | Count |
|----------|-------|-------|
| [ ] `models/enum_extensions.dart` | All `displayText` getters hardcoded English | 30+ |
| [ ] `models/enum_extensions.dart:332-378` | ReturnStatusConfig labels hardcoded | 8 |
| [ ] `widgets/promotions/standalone_promo_widget.dart:77` | `'Shop Now'` | 1 |
| [ ] `widgets/language_selector.dart:75,79` | `'English'`, `'Français'` | 2 |

**Fix:** Replace hardcoded strings with `'key'.tr()` using existing translation keys.

---

### 🟡 CODE DUPLICATION

#### P2 — Duplicate Widgets (Extract to shared/)

| Widget | Locations |
|--------|-----------|
| [ ] `_TrendingBadge` | `modern_product_card.dart:337-363`, `product_card_screen.dart:975-1021` |
| [ ] `_CartBadge` | `home_hero_section.dart`, `custom_app_bar.dart` |
| [ ] `_QuantityButton` | `product_actions_section.dart:273`, `cartitem_screen.dart:488` |
| [ ] `_buildFilterChip` | `admin_orders_tab.dart`, `home_hero_section.dart` |
| [ ] Skeleton loaders | 5+ different implementations |

#### P2 — Duplicate ViewModel Logic

| Methods | Files |
|---------|-------|
| Image compression | `add_product_viewmodel.dart`, `edit_product_viewmodel.dart` |
| Address handling | `add_product_viewmodel.dart`, `edit_product_viewmodel.dart`, `address_viewmodel.dart` |

---

### 🟡 DEPENDENCY INJECTION

#### P2 — Static AnalyticsService (Not Injectable)

| Issue | Files Affected |
|-------|----------------|
| [ ] `AnalyticsService` uses static methods | 8+ files call `AnalyticsService.logXxx()` |
| [ ] Tests cannot verify/mocks analytics calls | All test files |

**Fix:** Convert to provider-based `analyticsServiceProvider`.

#### P2 — Singleton Without Test Support

| Service | Issue |
|---------|-------|
| [ ] `SessionTimeoutService` | No `@visibleForTesting` override |
| [ ] `EnvConfig` | Duplicate providers (`providers.dart`, `orignabase_provider.dart`) |
| [ ] `CartController` | No interface (concrete class) |

---

### 🟡 IMPORTS

#### P3 — Relative Imports (Generated Files)

| File | Issue |
|------|-------|
| [ ] `models/generated/order_models.dart:7-8` | `../../core/compat/`, `../../core/schema/` |
| [ ] `models/generated/seller_profile_models.dart:7` | `../../core/schema/` |
| [ ] `models/generated/user_models.dart:8` | `../../core/schema/` |
| [ ] `models/generated/product_models.dart:7` | `../../core/schema/` |

**Note:** These are generated files — pattern acceptable but should use `package:` imports.

---

### 🟢 GOOD PRACTICES FOUND

| Category | Status |
|----------|--------|
| No deprecated Flutter widgets (`FlatButton`, `WillPopScope`) | ✅ |
| No `print()` in production lib code | ✅ |
| Proper `AppLogger` usage | ✅ |
| Proper `AppError` for domain errors | ✅ |
| Proper loading/error/success state handling | ✅ |
| Good use of `.select()` (82 occurrences) | ✅ |
| Comprehensive schema constants | ✅ |
| Auth tokens handled securely | ✅ |
| Input validation strong | ✅ |
| Proper SnackBar for transient errors | ✅ |

---

### 📋 REMEDIATION PRIORITY ORDER

1. **P0 — IMMEDIATE:** Rotate all secrets in `secrets-prod.json`
2. **P0 — IMMEDIATE:** Delete `google-services.json`, update translations
3. **P0 — HIGH:** Create ViewModels for screens with `setState`/async logic
4. **P0 — HIGH:** Migrate money fields from `double` to `int` cents
5. **P1 — HIGH:** Add Semantics labels for E2E test compatibility
6. **P1 — HIGH:** Add pagination to unbounded queries
7. **P1 — HIGH:** Migrate state classes to freezed
8. **P2 — MEDIUM:** Convert AnalyticsService to provider-based
9. **P2 — MEDIUM:** Fix hardcoded enum displayText to use .tr()
10. **P2 — MEDIUM:** Extract duplicate widgets to shared/
11. **P3 — LOW:** Fix relative imports in generated models
12. **P3 — LOW:** Consolidate EnvConfig providers

(End of file)
