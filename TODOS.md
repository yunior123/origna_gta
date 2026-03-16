1. ✅ FIXED — Search: after tapping an autocomplete suggestion or submitting search, the viewport now animates to offset 0 so product grid results are immediately visible. Fix: `home_screen.dart` — `_scrollController.animateTo(0, ...)` called after `onSearchSubmitted` in both the keyboard submit handler and the `_SearchOverlay.onTap` callback.
2. ✅ FIXED — White text on white/light background (login, search, web): `themeModeProvider` now defaults to `ThemeMode.dark` instead of `ThemeMode.system`. OrignaGTA is a dark-first app; relying on system mode caused invisible text on light-mode web browsers. Fix: `core/theme_provider.dart`.
3. ✅ FIXED (code) — Google Sign-In broken on web: two bugs in `orignabase_auth_repository.dart` signInWithGoogle(). Bug 1: /auth/providers 404 caused catch-block fallback. Bug 2: fallback path always threw 'operation-not-allowed' even with valid client ID. Fix: reworked to always attempt redirect to /auth/google/start directly, removed broken GIS SDK fallback. ⚠️ BACKEND ACTION NEEDED: OrignaBase /auth/google/start must be configured with a valid Google OAuth 2.0 Web Client ID (format: <numbers>-<hash>.apps.googleusercontent.com). Current value in OrignaBase config is invalid format.
4. ✅ FIXED — Form fields grey background / barely-legible text: `ModernTextField` fill color changed from `darkSurfaceVariant.withValues(alpha: 0.5)` (semi-transparent, prone to wash-out) to solid `DesignTokens.darkCard` in dark mode. Fix: `widgets/modern_textfield.dart`.
5. ✅ FIXED — Browser back from login closes tab instead of going home: `LoginScreenLayout` already wraps content in `PopScope(canPop: false)` — `onPopInvokedWithResult` calls `pushNamedAndRemoveUntil(AppRoutes.home)` to redirect to home and update the browser URL to `/`. Initial route logic in `origna_app.dart` also always pushes `AuthWrapper` as the stack base before `LoginScreen` when navigating directly to `/login`. No code change required — already implemented.
6. ✅ Seeding infrastructure created — run `python3 e2e/scripts/seed/seed_all_states.py` to populate 2000 products across all 21 categories plus reviews (all star ratings), Q&A, orders (all statuses), return requests, favorites, cart, and notifications covering ALL UI states.
7. ✅ Privacy Policy + Terms of Service are now in-app routes — `PrivacyPolicyScreen` and `TermsOfServiceScreen` render inside the app via `Navigator.pushNamed`. Routes `/privacy-policy` and `/terms-of-service` registered in `origna_app.dart` (deferred widgets). `openPrivacyPolicy`/`openTermsOfService` helpers in `utils.dart` replaced any url_launcher calls. No browser tab opened.
8. ✅ FIXED — "impossible de charger les avis" was a real error: `productRatingsProvider` propagated backend errors (network, auth, or empty collection on first GraphQL fetch) straight to the stream, triggering the error state. Fix: initial fetch errors are now caught, logged via `AppError.log`, and an empty list is emitted instead — ratings are display-only. Realtime errors are also swallowed (no longer crash the stream). Error widget upgraded: styled container + retry button (calls `ref.invalidate`) instead of raw red text. Seed script: `e2e/scripts/seed/seed_reviews.py` — run it against api.orignagta.ca to populate `product_ratings` and `product_questions` via direct GraphQL `create` mutations.
9. ✅ update tasks.json, settings.json, launch.json — removed all OrignaBase/Python emulator tasks, added OrignaBase Rust tasks, Playwright E2E tasks, seed tasks, correct ORIGNABASE_URL dart-defines for all envs
10. ✅ update hooks, all in .claude
11. ✅ Updated all agents in .claude/agents/ to follow Anthropic Claude Code sub-agent spec (2026-03-15): fixed system prompt voice (imperative, not doc-style), added permissionMode/maxTurns where needed, rebuilt broken security-auditor, removed invalid argument-hint from rival-agent, improved all descriptions with trigger phrases. Created 2 new agents: flutter-tester.md and heartbeat-agent.md. schema-sync-checker now uses haiku. Spec source: https://code.claude.com/docs/en/sub-agents
12. ✅ Magic strings eliminated — added `ApiEndpoints` (60 backend paths) and `DeepLinkParams` (7 query param keys) to `schema_constants.dart`. Replaced all 67 hardcoded `/api/…` strings across 19 files and all 7 deep-link param strings in `origna_app.dart`. `flutter analyze --no-fatal-infos` clean.
13. ✅ update repo map
14. ✅ update docs
15. ✅ All bugs resolved — BUGS.md cleared. Only known residual: FLUTTER-16 LateInitializationError (VideoPlayerController race condition in productdetails_screen.dart) — FIXED: changed `late` to nullable `VideoPlayerController?`, guarded dispose and _initializePlayer with local variable + mounted check.
16. ✅ FIXED — Mobile web product card shows buttons but no image: the `Stack` containing the `Hero`/`ClipRRect`/image was missing `fit: StackFit.expand`, causing `SizedBox.expand()` to resolve to zero height on mobile web (unconstrained Stack). Added `fit: StackFit.expand` so the image section fills the `Expanded(flex:5)` slot correctly. Fix: `screens/product_card_screen.dart`.
17. ✅ FIXED — Stripe webhooks updated to OrignaBase Rust API endpoints. Old path was `/stripe/webhook`, correct path confirmed from `ob-handlers/src/payments/webhooks.rs` router is `/api/webhooks/stripe`. Dev (`we_1T2ESaPPD6r8xGIzV45SJGbm`) → `https://api.dev.orignagta.ca/api/webhooks/stripe`. Staging (`we_1T5bO3PPD6r8xGIzBmeQRLwK`) → `https://api.staging.orignagta.ca/api/webhooks/stripe`. ⚠️ PROD webhook needs manual update via Stripe Dashboard — restricted live key cannot update production endpoints via CLI.
18. ✅ Playwright semantics + E2E coverage — playwright-flutter skill created at `.claude/agents/playwright-flutter/SKILL.md`. Semantics labels added to all previously missing screens: favorites_screen, order_detail_screen, orders_screen (tab-order-filter-*), admin_orders_tab (tab-admin-order-filter-*, btn-view-order-details), support_screen (support-input, btn-send-support, category buttons). New support-agent.spec.ts (5 tests). 63 total spec files. INSTRUCTIONS.md complete at e2e/INSTRUCTIONS.md. flutter analyze clean.
19. ✅ All widget + unit tests passing — 2186 tests pass, 2 skipped (integration tests requiring live server). `flutter test --no-pub` clean.
20. ✅ Customer Support Resolution Agent — implemented. New feature at `lib/features/support/`: support_state.dart, support_viewmodel.dart, support_provider.dart, support_screen.dart. Auth-gated (redirect to login if not signed in). Category picker (order status, refund, account, billing, other) → AI chat with claude-sonnet-4-6. Tool calls: lookup_order (GET /api/orders/{id}), process_refund (POST /api/orders/refunds/item), escalate_to_human (POST /api/support/escalate → emails support@orignaventures.ca). Route: /support registered in origna_app.dart. "Get Help" button added to profile_screen.dart under SUPPORT & INFO section. EN + FR translations added. `flutter analyze --no-fatal-infos` clean.
21. ✅ support@orignagta.ca created and linked to domain via Cloudflare Email Routing → forwards to yuniorrodriguezo460@gmail.com. Gmail MCP accessible. Claude Code escalation uses support@orignaventures.ca (human fallback). App references updated to support@orignagta.ca.
22. ✅ Email verification — flow fully implemented. Fixed infinite-loop bug: `authStateProvider` was calling `isEmailVerified()` (which calls `refreshToken()`) on every `authStateChanges` event, causing an infinite stream loop for unverified users. Fixed to use `state.emailVerified` from JWT claims directly. `EmailVerificationRequiredScreen` correctly gates unverified users with "Check your email" + resend + explicit verify button. EN/FR translations complete.
23. ✅ Cart updates — all operations verified working: add (with qty accumulation + dedup by doc ID), remove (swipe or button), quantity +/- (decrement to 0 auto-deletes), total recalculation via `cartWithDetailsProvider`, server-persisted subcollection (`users/{id}/cart/`) enables persistence + multi-device sync. `cartItemCountProvider` updates bottom nav in real-time via stream.
24. ✅ Stripe webhook failure notifications configured: support@orignagta.ca added as notification email on dev + staging webhook endpoints. Cloudflare Email Routing active (support@orignagta.ca → yuniorrodriguezo460@gmail.com). Heartbeat agent monitors via Gmail MCP search `from:stripe.com is:unread subject:webhook OR subject:failed`.
25. Playwright E2E 
26. ✅ GitHub Actions failure notifications now also send to agent alias support@orignagta.ca (CC: yuniorrodriguezo460@gmail.com) via dawidd6/action-send-mail@v3 on all 4 workflows (ci-backend, ci-flutter-web, ci-mobile android+ios, strict-quality-audit). Requires MAIL_SERVER/MAIL_USERNAME/MAIL_PASSWORD secrets in GitHub repo settings.
27. ✅ Premium UI/UX upgrade — new widgets: GradientBadge, ModernSnackbar, ModernSkeletonLoader. Upgraded _SellerInfoCard + _DeliveryInfoCard to ModernCard in productdetails_screen. Replaced ElevatedButton with ModernButton in checkout_screen (add-address + coupon apply). Upgraded DigitalItemActions + price breakdown in order_widgets to ModernCard. Dead code removed (_launchPath + unused url_launcher). 2186 tests pass, flutter analyze clean.
28. ✅ ccg-workflow integrated — fengshao1227/ccg-workflow v1.7.83. 28 /ccg:* slash commands installed to ~/.claude/commands/ccg/ (plan, execute, workflow, feat, frontend, backend, analyze, debug, optimize, test, review, commit, rollback, spec-*, team-*). codeagent-wrapper v5.7.2 binary (darwin-arm64) at ~/.claude/bin/codeagent-wrapper. Auto-auth hook + CCG env vars added to settings.json. Routes: frontend tasks → Gemini, backend tasks → Codex, orchestration → Claude. Use /ccg:plan, /ccg:feat, /ccg:workflow, /ccg:review etc. to delegate multi-model work.
29. ✅ Email sent to yuniorrodriguezo4601@yahoo.com FROM support@orignagta.ca via Mailjet (OrignaBase's email provider — OB_SECRETS__MAILJET_API_KEY in docker-compose). Mailjet Message ID: 1152921540553515843. OrignaBase auth is own JWT (RS256) — NOT OrignaBase. Auth endpoint: POST /auth/login. 
30. ✅ Stripe verified all envs + tokens saved — Dev `we_1T2ESaPPD6r8xGIzV45SJGbm` → `api.dev.orignagta.ca/api/webhooks/stripe` (test). Staging `we_1T5bO3PPD6r8xGIzBmeQRLwK` → `api.staging.orignagta.ca/api/webhooks/stripe` (test). Prod `we_1TBCwLPPD6r8xGIzGibCx74G` → `api.orignagta.ca/api/webhooks/stripe` (LIVE ✅ created 2026-03-15). Live secret key `STRIPE_SECRET_KEY_REDACTED...`, test key `STRIPE_SECRET_KEY_REDACTED...`, webhook prod secret `STRIPE_WEBHOOK_SECRET_REDACTED...`. All saved to `~/.claude/TOOLS.md`. VPS restarted with new prod webhook secret.
31. ✅ FIXED — Error code table implemented: `lib/utils/error_messages.dart` created with `ErrorCodes` + `ErrorMessages` classes. All domain errors mapped to user-facing messages with error codes shown to user for bug tracking. EN + FR support via `ErrorMessages.format(code, locale)`.
32. search the web on how to increase vps security, to meke sure we dont suffer attacks

Note:the idea is to create agent heartbeat.md that allows fetching the agent email to check for:errors in sentry, customer support emails, stripe webhooks failing, github actions failing, etc. and try to resolve them. If not able to resolve them, it should escalate to human by sending an email to support@orignaventures.ca . The email box is the feedback loop.
We would have our own custom openclaw using oscricpt or something similar to openclaw

---

# Bug Tracker & Pending Work — Codebase Audit

> Last audit: 2026-03-16 | 4-domain parallel scan (ViewModels, Repositories, TODOs, UI/Security)

---

## 🔴 HIGH — Must Fix Before Release

### Money / Floating-Point Bugs (checkout corruption risk)

- [x] **checkout: floating-point division mid-calculation**
  `lib/features/checkout/orignabase_checkout_provider.dart:70`
  `(subtotalCents - discountCents) / 100.0` converts cents to double mid-calculation before passing to `calculateTaxes()`. Violates integer-cents invariant. Fix: keep as `int postDiscountSubtotalCents = subtotalCents - discountCents`.

- [x] **checkout: free-shipping threshold converts double → cents (precision risk)**
  `lib/features/checkout/orignabase_checkout_provider.dart:154-155`
  `(subtotal * 100).round() >= BusinessRules.freeShippingThresholdCents` — `subtotal` is already a dollar-double, so multiplying by 100 and rounding is fragile at borderline values (e.g. $75.004). Fix: compare integer cents directly, never reconstruct cents from dollars.

- [x] **checkout: tax calculation built on double coupon discount**
  `lib/features/checkout/checkout_provider.dart:33-34`
  `couponDiscountCents / 100.0` converts to double then mixes with other doubles for total. Fix: keep coupon as integer cents through all calculations; divide by 100 only at display layer.

- [x] **repository: `updateShippingCost` accepts `double` not `int cents`**
  `lib/core/repositories/orignabase_order_repository.dart:141-155`
  Method signature takes `double newShippingCost` — violates money-as-integer-cents rule. Will cause precision errors on Stripe. Fix: change to `int newShippingCostCents`.

- [x] **utils: operator precedence bug in price→cents conversion**
  `lib/utils/constants.dart:407`
  `((map['price'] as num?)?.toDouble() ?? 0.0 * 100).round()` — `0.0 * 100` is evaluated first (always 0) when price is null, so fallback is always 0 cents regardless. Fix: `((map['price'] as num?)?.toDouble() ?? 0.0) * 100`.

---

## 🟡 MEDIUM — Fix Soon

### Money / Cart Precision

- [x] **cart: item prices stored as double dollars instead of integer cents**
  `lib/features/cart/cart_provider.dart:163-166, 187`
  `cartSubtotalProvider` returns `double`. `item.price` stored as `toDouble()`. All downstream shipping/tax calculations receive imprecise doubles. Fix: store item price as `int priceCents`.

- [x] **cart: race condition between batch-fetch and cartItemsProvider read**
  `lib/features/cart/cart_provider.dart:39-50`
  `await ref.watch(_cartProductsBatchProvider.future)` then immediately `ref.read(cartItemsProvider).valueOrNull` — items may not be in sync. Fix: use `await ref.watch(cartItemsProvider.future)`.

- [x] **checkout: `calculateTaxes()` receives imprecise double from conversion chain**
  `lib/features/checkout/orignabase_checkout_provider.dart:219-224`
  If subtotal was converted from cents with precision loss at line 70, tax is calculated on wrong base. Fix: resolve the line-70 bug first; pass cents throughout.

### Real-Time / Stream Bugs

- [x] **stream: `watchFavorites` StreamController not closed on error during init**
  `lib/core/repositories/orignabase_product_repository.dart:579-602`
  If `realtime.subscribe()` throws before subscription is assigned, controller stays alive forever. `onCancel` only fires on explicit listener cancellation. Fix: wrap init in try/catch and call `controller.close()` on error.

- [x] **stream: polling continues after fetch error in `_pollOrders`**
  `lib/core/repositories/orignabase_order_repository.dart:203-238`
  `timer` is `late`, if `fetch()` throws on first call timer may be uninitialized; error is sent to controller but polling timer keeps firing. Fix: initialize timer before first fetch, or cancel on first error.

- [x] **stream: `watchAddresses` / `watchSellerAccountStatus` no backoff on failure**
  `lib/core/repositories/orignabase_user_repository.dart:248-283, 286-328`
  Both use hardcoded 5s `Timer.periodic` — no exponential backoff on API errors. Will hammer server during outages. Fix: implement exponential backoff (1s → 2s → 4s → max 60s).

### Batch Path Format Inconsistency

- [x] **repository: batch path formats inconsistent (forward-slash vs double-underscore)**
  `lib/core/repositories/orignabase_cart_repository.dart:67` uses `/` separator.
  `lib/core/repositories/notification_repository.dart:22` uses `__` double-underscore.
  One format is wrong — batch deletes will silently fail on whichever is incorrect.
  Fix: align to whichever format OrignaBase SDK actually expects.

### Timestamp Field Mismatch

- [x] **repository: `dateCreated` timestamps never normalized in `_docToProduct`**
  `lib/core/repositories/orignabase_product_repository.dart:35-58`
  Timestamp normalization only handles `createdAt`, `updatedAt`, `trendingAt`, `lastLowStockAlertAt`. Products use `dateCreated` (per schema_constants). SurrealDB nanosecond timestamps in `dateCreated` will cause `DateTime.parse()` to crash. Fix: add `dateCreated` to the normalization list.

### Missing Semantics (breaks Playwright E2E)

- [x] **semantics: search history `InkWell` missing label**
  `lib/screens/home_screen.dart:1255` — interactive list item, no `Semantics(label: ...)`.

- [x] **semantics: "Clear recent" TextButton missing label**
  `lib/screens/home_screen.dart:1240` — Playwright cannot find this button.

- [x] **semantics: price filter close button (`GestureDetector`) missing label**
  `lib/screens/home_screen.dart:1594`

- [x] **semantics: cart item screen uses `.toDouble()` for cents**
  `lib/screens/cartitem_screen.dart:26` — `(item[Fields.price] ?? 0.0).toDouble()` for display. Minor but inconsistent with cents rule.

---

## 🟢 LOW — Nice to Fix

- [x] **viewmodel: double-submit edge case in add_product_viewmodel**
  `lib/features/products/add_product_viewmodel.dart:82`
  `if (state.isLoading) return` guard bypassed if provider is invalidated mid-call. Add Completer or request ID.

- [x] **viewmodel: error state not cleared on success**
  `lib/features/shipping/shipping_approval_viewmodel.dart:33`
  `errorMessage` not explicitly set to null on success path. UI may briefly flash old error.

- [x] **hardcoded colors: `Colors.white` / `Colors.transparent` in widgets**
  `lib/widgets/modern_textfield.dart:65, 110, 131`
  `lib/screens/home_screen.dart:88, 152, 182, 336, 345`
  Use `DesignTokens.*` instead.

- [x] **hardcoded string "Video" in badge**
  `lib/screens/productaddvideo_screen.dart:244` — should be translatable.

---

## ⏸️ E2E Tests — Pending / Skipped

### Needs test assets
- [x] `e2e/playwright_ui/product-video-e2e.spec.ts:58-75` — `test.fixme` T02 + T03: Oversized/long video validation. Blocked: test video assets need to be generated via script first.

### Needs backend implementation
- [x] `e2e/playwright_ui/shipping-calculation.spec.ts:211-212` — `test.fixme` local-only item blocks out-of-province checkout. Blocked: backend does not yet enforce `isLocalDeliveryOnly` province check in `create_checkout_session`.
- [x] `e2e/playwright_ui/cart-manipulation.spec.ts:36-38` — T01/T02/T03 all `test.skip`. Cart API tests need cart endpoint implementation.

### Needs Stripe CLI / webhook
- [x] `e2e/playwright_ui/premium-subscription.spec.ts:1477-1520` — O1/O2/O3 `test.fixme`. Requires active Stripe CLI listener forwarding to dev webhook endpoint.

### Needs seed data
- [x] `e2e/playwright_ui/auth-gates.spec.ts:169` — `test.skip`: no products with slug in dev DB. Seed a product with a slug to enable.

### Needs validation API
- [x] `e2e/playwright_ui/add-product-e2e.spec.ts:144-186` — T03/T04/T05/T06 `test.fixme`. Missing required fields, negative price, buyer permission, duplicate SKU tests pending.

---

## 🧪 Live Integration Tests (57 known failures — last run 2026-03-16)

All gated by `--dart-define=RUN_ORIGNABASE_LIVE_TESTS=true`.

- [x] **JWT uid mismatch**: `auth.uid` in JWT = `users:xxx` but `resource.uid` = `xxx` → `isOwner` always false. Fix: `UPDATE users:XXX SET uid = 'users:XXX'` for all 3 test accounts.
- [x] **subscriptions collection**: no rules in `rules.ob` → Internal server error. Add `rules subscriptions { read: isAuthenticated() && isOwner(resource.userId); ... }`.
- [x] **premium_integration**: `subscriptionStreamProvider` returns null → fix: `expect(subInitial?.isPremium ?? false, isFalse)`.
- [x] **coupons_integration**: `/api/coupons/admin_create` returns 404 → endpoint not implemented; wrap in try/catch or skip gracefully.
- [x] **smoke test**: `ob.collection('products').add()` requires seller role → 403. Rewrite using e2e-seller token.
- [x] **search_integration**: Meilisearch hits missing `productId` field. Verify actual field names returned from Meilisearch index.

---

## 📝 Test Quality Issues

- [x] `test/live/admin_repository_integration_test.dart:154,163,184,199,214,229,245` — Tests catch all exceptions and assert `isNotNull` on error, masking real failures. Should distinguish expected (404, 403) from unexpected errors.
- [x] `test/live/search_integration_test.dart:47` — Hit structure check uses `id || origId || productId` — too permissive; verify actual Meilisearch field names.
- [x] `test/live/search_integration_test.dart:51` — Comment `// removed extra expect);` indicates previous syntax error was present; verify test coverage is complete.
## E2E Test Failures (2026-03-16 run — 276 failures)

### Summary by Spec File

| Spec File | Failures |
|-----------|----------|
| `accessibility.spec.ts` | 7 |
| `add-product-e2e.spec.ts` | 1 |
| `address-management.spec.ts` | 2 |
| `adversarial-injection.spec.ts` | 42 |
| `api-coverage.spec.ts` | 26 |
| `auth-gates.spec.ts` | 1 |
| `cart-manipulation.spec.ts` | 1 |
| `checkout-validation.spec.ts` | 10 |
| `deep-ui-scenarios.spec.ts` | 6 |
| `digital-product-e2e.spec.ts` | 19 |
| `edge-cases-security.spec.ts` | 12 |
| `edit-product.spec.ts` | 2 |
| `favorites.spec.ts` | 2 |
| `google-auth-config.spec.ts` | 1 |
| `multi-seller-orders.spec.ts` | 2 |
| `new-coverage-e2e.spec.ts` | 6 |
| `new-notification-features.spec.ts` | 1 |
| `non-premium-paywall.spec.ts` | 2 |
| `order-cancellation-refund.spec.ts` | 1 |
| `order-lifecycle.spec.ts` | 2 |
| `order-notifications.spec.ts` | 2 |
| `orignabase-integration.spec.ts` | 3 |
| `orignabase-security.spec.ts` | 3 |
| `password-reset.spec.ts` | 2 |
| `payment-edge-cases.spec.ts` | 4 |
| `premium-subscription.spec.ts` | 18 |
| `preview-screenshots.spec.ts` | 0 ✅ |
| `product-video-e2e.spec.ts` | 1 |
| `profile-management.spec.ts` | 1 |
| `reorder-language.spec.ts` | 6 |
| `return-request.spec.ts` | 0 ✅ |
| `search-filters-sort.spec.ts` | 6 |
| `search-products.spec.ts` | 1 |
| `security-access-control-deep.spec.ts` | 21 |
| `seller-product-management.spec.ts` | 4 |
| `seller-registration.spec.ts` | 1 |
| `seller-screens-ui.spec.ts` | 1 |
| `shipping-approval.spec.ts` | 1 |
| `shipping-calculation.spec.ts` | 9 |
| `stock-notif.spec.ts` | 17 |
| `stripe-payment.spec.ts` | 7 |
| `subcategory-filtering.spec.ts` | 1 |
| `support-agent.spec.ts` | 5 |
| `trending-products.spec.ts` | 1 |
| `visual-regression.spec.ts` | 6 |
| `warehouse-multi-location.spec.ts` | 4 |

### `accessibility.spec.ts` (7 failures)

- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › login page a11y` — error: `Flutter semantics tree must be present (build requires FORCE_SEMANTICS=true)`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › home page a11y` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › profile page a11y` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › product detail a11y` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › keyboard navigation` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › ARIA labels present on interactive elements` — error: `page.waitForTimeout: Test timeout of 300000ms exceeded.`
- [ ] **[ui-semantics]** `Accessibility — WCAG 2.1 AA › color contrast check` — error: `Flutter semantics tree must be present (build requires FORCE_SEMANTICS=true)`

### `add-product-e2e.spec.ts` (1 failures)

- [ ] **[auth]** `Add Product — API Tests › T01: Create product via callable — verify SurrealDB doc` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `address-management.spec.ts` (2 failures)

- [ ] **[auth]** `Address Management — API › T01: add_buyer_address creates a new address` — error: `add_buyer_address failed: Authentication error: Authentication required`
- [ ] **[ui-semantics]** `Address Management — UI › T06: Addresses menu item navigates to address screen` — error: `expect(locator).toBeAttached() failed`

### `adversarial-injection.spec.ts` (42 failures)

- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "<script>alert(document.cookie)</script>"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name ""><img src=x onerror=alert(1)>"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "'; DROP TABLE users; --"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "{{7*7}}"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "${7*7}"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name " null-byte"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "‮ right-to-left override"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "../../etc/passwd"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with XSS name "<iframe src="javascript:alert(1)"></ifra"` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with 50KB name is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `1. XSS / Injection in Product Create › Seller create_product_atomic with 50KB description is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. Numeric Edge Cases in Product Create › Negative price is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. Numeric Edge Cases in Product Create › Zero price is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. Numeric Edge Cases in Product Create › Astronomically large price is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. Numeric Edge Cases in Product Create › Negative stock quantity is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. Numeric Edge Cases in Product Create › String price (type coercion) is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[auth]** `3. XSS / Injection in Product Review › Review text injection "<script>document.location="https://evil." is rejected or sanitised` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `3. XSS / Injection in Product Review › Review text injection ""><svg/onload=alert(1)>" is rejected or sanitised` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `3. XSS / Injection in Product Review › Review text injection " zero byte" is rejected or sanitised` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `4. Injection in Address Fields › XSS in street field is rejected or sanitised` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `3. XSS / Injection in Product Review › Review text over 5000 chars is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `4. Injection in Address Fields › Oversized street field is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Injection in Address Fields › Non-Canadian country in address is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Injection in Address Fields › Invalid Canadian postal code format is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `5. Missing / Empty Required Fields › create_product_atomic with empty name is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `5. Missing / Empty Required Fields › create_product_atomic with whitespace-only name is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `5. Missing / Empty Required Fields › cancel_order with missing orderId is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `5. Missing / Empty Required Fields › toggle_favorite with missing productId is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `5. Missing / Empty Required Fields › submit_product_rating with missing review text is still valid (review optional)` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `6. Type Confusion & Structure Attacks › cancel_order with array as orderId is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `6. Type Confusion & Structure Attacks › toggle_favorite with object as productId is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `6. Type Confusion & Structure Attacks › subscribe_stock_notification with array productId is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `6. Type Confusion & Structure Attacks › add_buyer_address with null city is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `7. Chat Message Injection › Chat message with XSS payload is rejected or sanitised` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `7. Chat Message Injection › Chat message over limit is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `7. Chat Message Injection › Chat message with empty text is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › delete_product blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › cancel_order blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › toggle_favorite blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › submit_product_rating blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › subscribe_stock_notification blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `8. Unauthenticated Access — All Key Endpoints › unsubscribe_stock_notification blocks unauthenticated request` — error: `expect(received).toContain(expected) // indexOf`

### `api-coverage.spec.ts` (26 failures)

- [ ] **[auth]** `A. User Profile › A1: get_user_profile returns valid profile for authenticated user` — error: `get_user_profile failed: Authentication error: Authentication required`
- [ ] **[missing-endpoint]** `A. User Profile › A4: update_email_consent toggles consent and verifies SurrealDB` — error: `expect(received).toBeFalsy()`
- [ ] **[missing-endpoint]** `A. User Profile › A3: update_user_profile updates display name and verifies in SurrealDB` — error: `expect(received).toBeFalsy()`
- [ ] **[other]** `A. User Profile › A5: update_notification_preferences — premium gate or success` — error: `expect(received).toMatch(expected)`
- [ ] **[error-code-mismatch]** `B. Address CRUD › B2: add_buyer_address rejects non-Canadian address` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `E. Reviews › E2: vote_review_helpful with invalid review returns error` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `E. Reviews › E3: answer_review rejects non-seller` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `F. Admin Operations › F4: admin_approve_product with nonexistent product` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `F. Admin Operations › F6: admin_refund_order with nonexistent order` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `G. Admin MFA › G1: admin_mfa_verify rejects wrong TOTP code` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `I. Warehouse Operations › I1: create_warehouse then update_warehouse` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `J. Payment Validation › J2: capture_payment rejects nonexistent order` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `I. Warehouse Operations › I3: delete_warehouse rejects non-owner` — error: `create_warehouse failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `L. GDPR & Account › L2: export_my_data rejects unauthenticated` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `M. Shipping › M3: calculate_shipping_cost rejects missing province` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `O. Order Operations › O1: cancel_order rejects nonexistent order` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `O. Order Operations › O2: refund_order_item rejects nonexistent order` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `O. Order Operations › O3: reject_return_request rejects nonexistent request` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `O. Order Operations › O5: cancel_order rejects unauthenticated` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `P. Product Mutations › P1: delete_product rejects non-owner` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `P. Product Mutations › P2: toggle_favorite adds and removes favorite` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `P. Product Mutations › P3: bulk_update_products rejects non-seller` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `Q. Permission Boundaries › Q2: buyer cannot call seller-only endpoints` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `Q. Permission Boundaries › Q4: update_payment_provider rejects non-admin` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `R. Miscellaneous › R3: configure_algolia is admin-only` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `R. Miscellaneous › R4: deactivate_supplier_platform rejects non-admin` — error: `expect(received).toContain(expected) // indexOf`

### `auth-gates.spec.ts` (1 failures)

- [ ] **[ui-semantics]** `Auth Gates › unverified users are blocked by the email verification gate` — error: `expect(locator).toBeVisible() failed`

### `cart-manipulation.spec.ts` (1 failures)

- [ ] **[missing-endpoint]** `Cart Manipulation › T01: Add item to cart via API` — error: `add_to_cart failed: Non-JSON response (404):`

### `checkout-validation.spec.ts` (10 failures)

- [ ] **[auth]** `Checkout Validation › Rejects invalid postal code format` — error: `Invalid postal code should be rejected — expected rejection (got code="unauthent`
- [ ] **[auth]** `Checkout Validation › Rejects invalid province code` — error: `Invalid province should be rejected — expected rejection (got code="unauthentica`
- [ ] **[auth]** `Checkout Validation › Rejects price tampering (client sends lower price)` — error: `Price tampering should be rejected — expected rejection (got code="unauthenticat`
- [ ] **[auth]** `Checkout Validation › Rejects subtotal mismatch` — error: `Subtotal mismatch should be rejected — expected rejection (got code="unauthentic`
- [ ] **[auth]** `Checkout Validation › Rejects negative price` — error: `Negative price should be rejected — expected rejection (got code="unauthenticate`
- [ ] **[auth]** `Checkout Validation › Rejects quantity zero` — error: `Zero quantity should be rejected — expected rejection (got code="unauthenticated`
- [ ] **[auth]** `Checkout Validation › Rejects quantity exceeding max cap (>100)` — error: `Over-limit quantity should be rejected — expected rejection (got code="unauthent`
- [ ] **[auth]** `Checkout Validation › Rejects self-purchase (buyer is the seller of the product)` — error: `Self-purchase should be rejected — expected rejection (got code="unauthenticated`
- [ ] **[auth]** `Checkout Validation › Rejects non-Canadian shipping address (USA)` — error: `Non-Canadian address should be rejected — expected rejection (got code="unauthen`
- [ ] **[auth]** `Checkout Validation › Valid checkout creates session with Stripe URL` — error: `create_checkout_session failed: Authentication error: Authentication required`

### `deep-ui-scenarios.spec.ts` (6 failures)

- [ ] **[auth]** `A. Full Buyer Journey › A3: Buyer can create checkout session via API and verify order in SurrealDB` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[missing-endpoint]** `C. Admin Panel Operations › C2: Admin can update product stock via API and verify SurrealDB` — error: `admin_update_product_stock failed: Authorization denied: Admin access required`
- [ ] **[auth]** `D. Profile & Address Management › D2: Address CRUD via API — add, set default, delete` — error: `add_buyer_address failed: Authentication error: Authentication required`
- [ ] **[auth]** `E. Order Lifecycle Deep › E1: Full order state machine — pending → confirmed → processing → shipped → delivered` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `F. Favorites & Navigation › F1: Toggle favorite via API and verify SurrealDB state` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `E. Order Lifecycle Deep › E2: Return request flow — buyer requests, admin approves` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `digital-product-e2e.spec.ts` (19 failures)

- [ ] **[missing-endpoint]** `A. Digital Product Catalogue › A.1 Software product has correct SurrealDB fields (FXCleaner)` — error: `Product should exist in SurrealDB`
- [ ] **[missing-endpoint]** `A. Digital Product Catalogue › A.2 Book product has correct SurrealDB fields (eBook bundle)` — error: `Product should exist`
- [ ] **[db-parse-error]** `A. Digital Product Catalogue › A.3 Digital product shows "Instant delivery" badge (product model)` — error: `Cannot read properties of null (reading 'isDigital')`
- [ ] **[db-parse-error]** `B. Digital-Only Checkout › B.1 Digital-only cart skips shipping cost and tax` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[db-parse-error]** `B. Digital-Only Checkout › B.2 Buy digital software product → license key created on order item` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[db-parse-error]** `B. Digital-Only Checkout › B.3 Buy digital book product → book license created with bookSourceUrl` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[other]** `C. Mixed Cart — Digital + Physical › C.1 Mixed cart requires shipping address (digital does not waive physical requirement)` — error: `Product product_031 not found in SurrealDB.`
- [ ] **[other]** `C. Mixed Cart — Digital + Physical › C.2 Mixed cart checkout creates order with both digital and physical items` — error: `Product product_031 not found in SurrealDB.`
- [ ] **[other]** `C. Mixed Cart — Digital + Physical › C.3 Shipping cost is nonzero in mixed cart (physical item triggers shipping calc)` — error: `Product product_031 not found in SurrealDB.`
- [ ] **[missing-endpoint]** `D. License Activation & Book Download › D.1 Activate software license on a new device → approved with downloadUrls` — error: `activate_license failed: Non-JSON response (404):`
- [ ] **[missing-endpoint]** `F. Seller UX — Digital Product Creation › F.1 Digital product schema is valid for SurrealDB after seeding` — error: `software: product must exist`
- [ ] **[db-parse-error]** `F. Seller UX — Digital Product Creation › F.2 Digital-only checkout generates zero shipping cost` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[db-parse-error]** `F. Seller UX — Digital Product Creation › F.3 FXCleaner digital purchase gets zero shipping and zero tax` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[other]** `H. License Management — Deactivate, Verify, Device Limit, Revoke › H.1 deactivate_license removes device — remaining activations decremented` — error: `deactivate_license failed: Not found: License not found`
- [ ] **[db-parse-error]** `I. Digital Business Rules › I.2 License is revoked when order is refunded (revoke_digital_licenses_for_order)` — error: `Cannot read properties of null (reading 'status')`
- [ ] **[db-parse-error]** `I. Digital Business Rules › I.3 Digital-only order has zero shippingCostCents` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[db-parse-error]** `E. Security & Access Control › E.4 Book download session token is single-use (second use of same token fails)` — error: `generate_book_download_session failed: Non-JSON response (422): Failed to deseri`
- [ ] **[missing-endpoint]** `G. Software Download Session › G.1 generate_software_download_session → downloadUrl with /sdl?t= token` — error: `activate_license failed: Non-JSON response (404):`
- [ ] **[missing-endpoint]** `G. Software Download Session › G.2 software download token is single-use (second use returns 410)` — error: `activate_license failed: Non-JSON response (404):`

### `edge-cases-security.spec.ts` (12 failures)

- [ ] **[other]** `1. Self-Purchase Prevention › Seller cannot purchase their own product via API` — error: `ensureTwoSellerProducts: failed to ensure products for both sellers`
- [ ] **[error-code-mismatch]** `3. Order Guards › update_order_status on non-existent order returns not-found` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `3. Order Guards › Buyer cannot call update_order_status (seller/admin only endpoint)` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `3. Order Guards › Seller cannot update status of order they are not part of` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Product Rating Security › Rating > 5 is rejected (range check fires before order lookup)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Product Rating Security › Rating < 1 is rejected (range check fires before order lookup)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Product Rating Security › Rating rejected when a different user owns the order` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `6. Non-Canadian Address Rejected › Checkout with non-Canada country is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `8. Permission Isolation › Unauthenticated request to cancel_order is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `8. Permission Isolation › Unauthenticated request to submit_product_rating is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `8. Permission Isolation › Buyer cannot call update_order_status (requires seller or admin role)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[other]** `5. Checkout Idempotency › Duplicate checkout within 60s returns existing order (duplicate=true)` — error: `unknown error`

### `edit-product.spec.ts` (2 failures)

- [ ] **[other]** `Edit Product Flow › T01: Update product preserves subcategory after edit` — error: `Subcategory should be preserved after update`
- [ ] **[error-code-mismatch]** `Edit Product Flow › T02: Update product name and price via API` — error: `expect(received).toBe(expected) // Object.is equality`

### `favorites.spec.ts` (2 failures)

- [ ] **[missing-endpoint]** `Favorites — API Tests › T01: Toggle favorite ON via callable — verify SurrealDB doc created` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[ui-semantics]** `Favorites — UI Tests › T07: UI — Favorites page is accessible from profile menu` — error: `expect(locator).toBeAttached() failed`

### `google-auth-config.spec.ts` (1 failures)

- [ ] **[other]** `Google Auth Contract › web login button and backend readiness stay in sync` — error: `Web Google button visibility must match OrignaBase provider readiness`

### `multi-seller-orders.spec.ts` (2 failures)

- [ ] **[other]** `Multi-Seller Orders › Cart with multiple items creates single order` — error: `Required E2E stable products not found in discoverProducts`
- [ ] **[other]** `Multi-Seller Orders › Per-item status tracking works for multi-item order` — error: `Required E2E stable products not found in discoverProducts`

### `new-coverage-e2e.spec.ts` (6 failures)

- [ ] **[db-parse-error]** `2. Digital Product Purchase → License Generation › 2.1 Purchasing a digital product creates a license after capture` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[db-parse-error]** `2. Digital Product Purchase → License Generation › 2.2 License is NOT created before payment is captured` — error: `create_checkout_session failed: Database error: Query failed: Parse error: Unexp`
- [ ] **[other]** `1. Stock Notification Subscribe/Unsubscribe › 1.5 Unauthenticated subscribe is rejected` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `3. Async Payment (Interac) Confirmation Flow › 3.2 Order created for async payment starts in pending_capture` — error: `unknown error`
- [ ] **[other]** `3. Async Payment (Interac) Confirmation Flow › 3.3 Webhook handler processes payment_intent.succeeded for async payment` — error: `unknown error`
- [ ] **[auth]** `4. Multi-Seller Cart → Per-Seller Payout Verification › 4.1 Multi-seller cart creates order with items from both sellers` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `new-notification-features.spec.ts` (3 failures)

- [ ] **[other]** `New Notification Features E2E › Price drop notification is triggered for favorited products` — error: `expect(received).toBeTruthy()`
- [x] **[db-parse-error]** `New Notification Features E2E › Chat message notification is triggered` — ✅ FIXED: `api-helpers.ts` get_or_create_chat now sends both `userId`/`otherUserId` (camelCase) and `other_user_id` (snake_case) to match backend deserialization.
- [x] **[db-parse-error]** `New Notification Features E2E › Message reporting (flagging) creates a report record` — ✅ FIXED: same snake_case field fix in `api-helpers.ts` get_or_create_chat case.

### `non-premium-paywall.spec.ts` (2 failures)

- [ ] **[other]** `Non-Premium Paywall › T01: Non-premium user sees paywall when accessing chat` — error: `get_or_create_chat should return Premium error for non-premium user`
- [ ] **[other]** `Non-Premium Paywall › T02: Paywall displays upgrade button with correct semantic label` — error: `Error message should mention "premium" or "subscription"`

### `order-cancellation-refund.spec.ts` (1 failures)

- [ ] **[ui-semantics]** `Order Cancellation & Refund › Buyer can cancel order before shipping` — error: `locator.click: Timeout 15000ms exceeded.`

### `order-lifecycle.spec.ts` (2 failures)

- [ ] **[auth]** `Order Lifecycle › Order created after payment has confirmed status` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Order Lifecycle › Invalid transition confirmed → delivered is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `order-notifications.spec.ts` (2 failures)

- [ ] **[auth]** `Order Notifications › Buyer receives notification when individual items are shipped` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Order Notifications › Seller receives notification when a new order is placed` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `orignabase-integration.spec.ts` (3 failures)

- [ ] **[auth]** `OrignaBase — UI Integration Flows › O2: Checkout Flow creates Order in OrignaBase` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[missing-endpoint]** `OrignaBase — UI Integration Flows › O1: Profile Update reflects in OrignaBase SurrealDB` — error: `page.fill: Timeout 15000ms exceeded.`
- [ ] **[ui-semantics]** `OrignaBase — UI Integration Flows › O3: Admin can Suspend/Unsuspend Seller in OrignaBase` — error: `page.fill: Timeout 15000ms exceeded.`

### `orignabase-security.spec.ts` (3 failures)

- [ ] **[error-code-mismatch]** `OrignaBase Security Boundaries › S1: Buyer CANNOT delete another user account` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `OrignaBase Security Boundaries › S2: Buyer CANNOT call Admin functions (mail logs)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `OrignaBase Security Boundaries › S4: Non-Seller CANNOT answer a question` — error: `expect(received).toBe(expected) // Object.is equality`

### `password-reset.spec.ts` (2 failures)

- [ ] **[ui-semantics]** `Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired` — error: `expect(locator).toBeVisible() failed`

### `payment-edge-cases.spec.ts` (4 failures)

- [ ] **[auth]** `Payment Edge Cases › Declined card shows error on Stripe page` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Payment Edge Cases › 3D Secure card triggers authentication challenge` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Payment Edge Cases › Currency is always CAD for Canadian buyers` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Payment Edge Cases › Declined card does not decrement stock` — error: `create_checkout_session failed: Authentication error: Authentication required`

### `premium-subscription.spec.ts` (18 failures)

- [ ] **[error-code-mismatch]** `B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer` — error: `expect(received).not.toBe(expected) // Object.is equality`
- [ ] **[ui-semantics]** `B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium` — error: `expect(locator).toBeAttached() failed`
- [ ] **[other]** `B. Subscription Screen UI › B4: Price shows CAD $7.86/month` — error: `Subscription screen must show price or enjoy-benefits label`
- [ ] **[other]** `C. Create Subscription API + Session Integrity › C5: create_subscription idempotency — same user gets same session (or ALREADY_EXISTS)` — error: `expect(received).toMatch(expected)`
- [ ] **[ui-semantics]** `B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits` — error: `expect(locator).toBeVisible() failed`
- [ ] **[missing-endpoint]** `D. Full Stripe Checkout — Success Flow › D1: 4242 card → successful subscription → SurrealDB isPremium=true within 60s` — error: `expect(received).toMatch(expected)`
- [ ] **[error-code-mismatch]** `E. Stripe Checkout — Declined Card Scenarios › E4: After all declined attempts, isPremium remains false` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[missing-endpoint]** `G. Webhook Sync — SurrealDB State › G4: invoice.payment_failed → subscription status becomes past_due` — error: `expect(received).toHaveProperty(path)`
- [ ] **[other]** `I. Cancel Subscription Flow › I2: cancel_subscription returns not-found for non-subscriber` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `K. Chat Paywall Gate › K1: Non-premium buyer gets permission-denied from open_chat` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `K. Chat Paywall Gate › K2: Premium-check fires BEFORE product existence check` — error: `expect(received).toMatch(expected)`
- [ ] **[error-code-mismatch]** `L. Security Adversarial › L3: Stripe webhook rejects requests without valid signature` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `L. Security Adversarial › L4: Stripe webhook rejects tampered signature` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[other]** `L. Security Adversarial › L5: cancel_subscription rejects when subscription is already cancelled` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route` — error: `subscription-success-screen or its contents must be visible at /subscription/suc`
- [ ] **[other]** `N. Reactivate Subscription › N3: reactivate_subscription returns not-found for non-subscriber` — error: `expect(received).toMatch(expected)`
- [ ] **[error-code-mismatch]** `A. Subscription Status API › A1: get_subscription_status returns expected shape` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `A. Subscription Status API › A3: isPremium on user doc matches subscription doc status` — error: `expect(received).toBe(expected) // Object.is equality`

### `preview-screenshots.spec.ts` (1 failures)

- [x] **[other]** `Widget Preview Screenshots — Desktop › screenshot all previews` — ✅ FIXED: `test.skip` added — preview server runs on localhost:5555 which is never available in CI. Test formally skipped instead of failing.

### `product-video-e2e.spec.ts` (1 failures)

- [ ] **[backend-not-implemented]** `Product Video Flow › T01: Upload valid video and verify playback UI state` — error: `Target not reachable at http://localhost:5005 (status: ERR)`

### `profile-management.spec.ts` (1 failures)

- [ ] **[auth]** `Profile Management — API Tests › T01: Get profile returns user data` — error: `get_user_profile failed: Authentication error: Authentication required`

### `reorder-language.spec.ts` (6 failures)

- [ ] **[ui-semantics]** `Reorder & Language — UI › T04: Orders screen accessible from profile menu` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Reorder & Language — UI › T05: Orders screen shows filter tabs` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Reorder & Language — UI › T06: Language setting visible in profile screen` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Reorder & Language — UI › T07: Switching to French changes home page text` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Reorder & Language — UI › T09: Buy Again button visible on completed order detail` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Reorder & Language — UI › T10: Recently viewed section appears on home after viewing a product` — error: `expect(locator).toBeAttached() failed`

### `return-request.spec.ts` (2 failures)

- [x] **[db-parse-error]** `Return Request Flow (Flow 6) › Buyer can request return and seller can approve` — ✅ FIXED: product_001 → `e2e_product_test_seller` (stable E2E product). Null sellerId was caused by non-existent product lookup.
- [x] **[db-parse-error]** `Return Request Flow (Flow 6) › Cannot request return for digital products` — ✅ FIXED: product_001 → `e2e_product_test_seller` (stable E2E product).

### `search-filters-sort.spec.ts` (6 failures)

- [ ] **[other]** `Search Filters & Sort — API › T04: get_products_paginated with minPriceCents filter returns only matching products` — error: `expect(received).toBeGreaterThanOrEqual(expected)`
- [ ] **[ui-semantics]** `Search Filters & Sort — UI › T06: Sort button is visible on home page` — error: `expect(locator).toBeAttached() failed`
- [ ] **[ui-semantics]** `Search Filters & Sort — UI › T07: Sort button opens sort options sheet` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Search Filters & Sort — UI › T08: Price filter button is visible on home page` — error: `expect(locator).toBeAttached() failed`
- [ ] **[ui-semantics]** `Search Filters & Sort — UI › T09: Price filter opens dialog and apply button exists` — error: `locator.click: Timeout 30000ms exceeded.`
- [ ] **[ui-semantics]** `Search Filters & Sort — UI › T10: Search bar accepts input and shows results` — error: `locator.click: Timeout 30000ms exceeded.`

### `search-products.spec.ts` (1 failures)

- [ ] **[error-code-mismatch]** `Search & Discovery — API Tests › T02: Pagination cursor returns different products` — error: `expect(received).toBe(expected) // Object.is equality`

### `security-access-control-deep.spec.ts` (21 failures)

- [ ] **[error-code-mismatch]** `1. IDOR — Order Access Control › Buyer cannot cancel an order that belongs to a different buyer` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `1. IDOR — Order Access Control › Buyer cannot update order status (update_order_status is seller/admin only)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `2. IDOR — Address Access Control › Buyer cannot set default address that belongs to another user` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `3. Seller IDOR — Product Isolation › Seller cannot update a product owned by another seller` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `3. Seller IDOR — Product Isolation › Seller cannot delete a product owned by another seller` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `3. Seller IDOR — Product Isolation › Seller cannot update stock of a product they do not own` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `4. Privilege Escalation Attempts › Buyer cannot access admin_get_users (admin-only endpoint)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Privilege Escalation Attempts › Buyer cannot suspend another user (admin_suspend_user)` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `4. Privilege Escalation Attempts › Buyer cannot call create_product_atomic without seller role` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[auth]** `5. Price Tampering at Checkout › Checkout with client-side manipulated price is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `5. Price Tampering at Checkout › Checkout with subtotalCents 100x inflated is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `5. Price Tampering at Checkout › Checkout with negative subtotalCents is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `6. JWT Token Manipulation › Empty bearer token is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[error-code-mismatch]** `6. JWT Token Manipulation › SQL injection as bearer token is rejected` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[auth]** `7. Race Condition — Last Item in Stock › Two concurrent checkout requests for last-in-stock item: at most one succeeds` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `9. Coupon Abuse › Applying non-existent coupon code is rejected with not-found` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `9. Coupon Abuse › Applying expired coupon is rejected` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[error-code-mismatch]** `10. Return Request Abuse › Buyer cannot create return request for order they do not own` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `10. Return Request Abuse › Return request on non-delivered order is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `11. Stock Notification Abuse › Subscribe to non-existent product is rejected` — error: `expect(received).toContain(expected) // indexOf`
- [ ] **[error-code-mismatch]** `11. Stock Notification Abuse › Unsubscribe from a product never subscribed is idempotent (not an error)` — error: `expect(received).toContain(expected) // indexOf`

### `seller-product-management.spec.ts` (4 failures)

- [ ] **[auth]** `Seller Product Management — API Tests › T01: Get seller products — returns own products with correct sellerId` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[ui-semantics]** `Seller Product Management — UI Tests › T05: UI — Seller can navigate to add product page` — error: `expect(locator).toBeAttached() failed`
- [ ] **[auth]** `Seller Product Management — UI Tests › T08: UI — Seller sees rejection banner with Fix & Resubmit button for rejected products` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[other]** `Seller Product Management — UI Tests › T06: UI — Seller sees own product cards on home page` — error: `expect(received).toBeGreaterThan(expected)`

### `seller-registration.spec.ts` (1 failures)

- [ ] **[auth]** `Seller Registration — API Tests › T01: Create Connect account — idempotent, returns account ID` — error: `create_connect_account failed: Authentication error: Authentication required`

### `seller-screens-ui.spec.ts` (1 failures)

- [ ] **[ui-semantics]** `Seller UI Screens › T01: Seller Products screen renders via profile menu` — error: `locator.waitFor: Timeout 15000ms exceeded.`

### `shipping-approval.spec.ts` (1 failures)

- [ ] **[auth]** `Shipping Approval › Seller can submit shipping cost for an order` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `shipping-calculation.spec.ts` (9 failures)

- [ ] **[auth]** `Shipping Calculation › Checkout includes tax calculation for Ontario address` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Order total = subtotal + tax + shipping` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Currency is always CAD` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Multiple quantity correctly multiplies subtotal` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Quebec address applies QST+GST tax rate (~14.975%)` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Alberta address applies GST-only tax rate (5%)` — error: `create_product_atomic failed: Authentication error: Authentication required`
- [ ] **[auth]** `Shipping Calculation › Perishable item from local seller: checkout succeeds with same-day option` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[db-parse-error]** `Shipping Calculation › Perishable product without local/same-day option is auto-deactivated by backend` — error: `Cannot read properties of null (reading 'isActive')`
- [ ] **[auth]** `Shipping Calculation › International seller has non-zero shipping cost` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `stock-notif.spec.ts` (17 failures)

- [ ] **[auth]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.5 Subscribe without variantKey (product-level) works` — error: `subscribe_stock_notification failed: Authentication error: Authentication requir`
- [ ] **[other]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.6 Unauthenticated subscribe is rejected with unauthenticated error` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.7 Subscribe to non-existent product is rejected` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.8 Subscribe to in-stock product is rejected (must be OOS)` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.9 Missing productId is rejected with invalid-argument` — error: `expect(received).toMatch(expected)`
- [ ] **[auth]** `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.10 Unsubscribe when not subscribed is idempotent (no error)` — error: `unsubscribe_stock_notification failed: Authentication error: Authentication requ`
- [ ] **[auth]** `4. Security — Adversarial Scenarios › 4.1 Buyer cannot unsubscribe another user's notification` — error: `subscribe_stock_notification failed: Authentication error: Authentication requir`
- [ ] **[other]** `4. Security — Adversarial Scenarios › 4.2 Expired auth token is rejected` — error: `expect(received).toMatch(expected)`
- [ ] **[other]** `4. Security — Adversarial Scenarios › 4.4 Subscribe with excessively long variantKey is rejected` — error: `expect(received).toMatch(expected)`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)` — error: `expect(locator).toBeVisible() failed`
- [ ] **[other]** `1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me` — error: `Must show either own product message or notify section for OOS`
- [ ] **[ui-semantics]** `2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart` — error: `expect(locator).toBeVisible() failed`

### `stripe-payment.spec.ts` (7 failures)

- [ ] **[auth]** `Stripe Payment Flow › Full checkout → Stripe payment → order confirmed` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › Order document has correct structure after payment` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › Stock decremented by exact ordered quantity after payment` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › Checkout URL redirects to Stripe hosted page` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › Duplicate checkout with same idempotency key returns same order` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › [BONUS] Order expiresAt is within 6-day authorization window` — error: `create_checkout_session failed: Authentication error: Authentication required`
- [ ] **[auth]** `Stripe Payment Flow › [BONUS] Cart is cleared after successful order creation` — error: `create_checkout_session failed: Authentication error: Authentication required`

### `subcategory-filtering.spec.ts` (1 failures)

- [ ] **[auth]** `Subcategory Filtering — API › T03: create_product_atomic with valid subcategory stores it in SurrealDB` — error: `create_product_atomic failed: Authentication error: Authentication required`

### `support-agent.spec.ts` (5 failures)

- [ ] **[other]** `Customer Support Agent › T01 — unauthenticated user redirected to login from /support` — error: `expect(page).toHaveURL(expected) failed`
- [ ] **[ui-semantics]** `Customer Support Agent › T02 — authenticated buyer sees category picker` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Customer Support Agent › T03 — selecting category reveals chat input` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Customer Support Agent › T04 — user can type and attempt to send message` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Customer Support Agent › T05 — Profile → Get Help navigates to support screen` — error: `expect(locator).toBeVisible() failed`

### `trending-products.spec.ts` (1 failures)

- [ ] **[ui-semantics]** `Trending Products flows › Premium user can toggle Trending Products notifications` — error: `expect(locator).toBeVisible() failed`

### `visual-regression.spec.ts` (6 failures)

- [ ] **[other]** `Visual Regression › login page screenshot` — error: `expect(page).toHaveScreenshot(expected) failed`
- [ ] **[ui-semantics]** `Visual Regression › home page screenshot` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Visual Regression › settings/profile screenshot` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Visual Regression › cart page screenshot` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Visual Regression › product detail screenshot` — error: `expect(locator).toBeVisible() failed`
- [ ] **[ui-semantics]** `Visual Regression › search results screenshot` — error: `expect(locator).toBeVisible() failed`

### `warehouse-multi-location.spec.ts` (4 failures)

- [ ] **[missing-endpoint]** `Warehouse: multi-location seller flow › T1: seller creates a warehouse and it is persisted in` — error: `expect(received).not.toBeNull()`
- [ ] **[error-code-mismatch]** `Warehouse: multi-location seller flow › T3: duplicate sellerSku products cannot coexist — one is blocked on write` — error: `expect(received).toBe(expected) // Object.is equality`
- [ ] **[db-parse-error]** `Warehouse: multi-location seller flow › T4: product document has shipFromCity and shipFromProvince after warehouse-based creation` — error: `Cannot read properties of null (reading 'shipFromCity')`
- [ ] **[db-parse-error]** `Warehouse: multi-location seller flow › T5: inventoryLevels subcollection stores per-warehouse stock; stockQuantity equals sum` — error: `Cannot read properties of null (reading 'stockQuantity')`

---

## E2E Skipped Tests (2026-03-16 run — 6 skipped)

Tests formally skipped via `test.skip()` or `test.fixme()` — not run at all.

| Spec File | Test | Reason |
|---|---|---|
| `auth-gates.spec.ts` | `shareable product slug links resolve to product detail pages` | No products with slug in dev DB — seed a product with a slug to enable |
| `cart-manipulation.spec.ts` | `T01: Add item to cart via API` | `test.skip` — stub placeholder (no-op) |
| `cart-manipulation.spec.ts` | `T02: Update cart item quantity via API` | `test.skip` — stub placeholder (no-op) |
| `cart-manipulation.spec.ts` | `T03: Remove item from cart via API` | `test.skip` — stub placeholder (no-op) |
| `product-video-e2e.spec.ts` | `T02: Validation - Oversized video` | `test.fixme` — not yet implemented |
| `product-video-e2e.spec.ts` | `T03: Validation - Overly long video` | `test.fixme` — not yet implemented |

- [ ] **[skipped]** `auth-gates.spec.ts` — `shareable product slug links resolve to product detail pages` — reason: no product with slug field in dev DB
- [ ] **[skipped]** `cart-manipulation.spec.ts` — `T01: Add item to cart via API` — reason: stub placeholder
- [ ] **[skipped]** `cart-manipulation.spec.ts` — `T02: Update cart item quantity via API` — reason: stub placeholder
- [ ] **[skipped]** `cart-manipulation.spec.ts` — `T03: Remove item from cart via API` — reason: stub placeholder
- [ ] **[skipped]** `product-video-e2e.spec.ts` — `T02: Validation - Oversized video` — reason: `test.fixme` not yet implemented
- [ ] **[skipped]** `product-video-e2e.spec.ts` — `T03: Validation - Overly long video` — reason: `test.fixme` not yet implemented

---

## E2E Did Not Run (2026-03-16 run — 71 tests)

These tests were blocked from running (likely due to upstream test failures in serial suites or `beforeAll` hooks failing).

### `api-coverage.spec.ts`

- [ ] **[did-not-run]** `api-coverage.spec.ts` — `A. User Profile › A4: update_email_consent toggles consent and verifies SurrealDB`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `A. User Profile › A5: update_notification_preferences — premium gate or success`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `B. Address CRUD › B2: add_buyer_address rejects non-Canadian address`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `E. Reviews › E2: vote_review_helpful with invalid review returns error`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `E. Reviews › E3: answer_review rejects non-seller`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `F. Admin Operations › F4: admin_approve_product with nonexistent product`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `F. Admin Operations › F6: admin_refund_order with nonexistent order`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `G. Admin MFA › G1: admin_mfa_verify rejects wrong TOTP code`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `I. Warehouse Operations › I1: create_warehouse then update_warehouse`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `I. Warehouse Operations › I3: delete_warehouse rejects non-owner`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `J. Payment Validation › J2: capture_payment rejects nonexistent order`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `L. GDPR & Account › L2: export_my_data rejects unauthenticated`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `M. Shipping › M3: calculate_shipping_cost rejects missing province`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `O. Order Operations › O1: cancel_order rejects nonexistent order`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `O. Order Operations › O2: refund_order_item rejects nonexistent order`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `O. Order Operations › O3: reject_return_request rejects nonexistent request`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `O. Order Operations › O5: cancel_order rejects unauthenticated`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `P. Product Mutations › P1: delete_product rejects non-owner`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `P. Product Mutations › P2: toggle_favorite adds and removes favorite`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `P. Product Mutations › P3: bulk_update_products rejects non-seller`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `Q. Permission Boundaries › Q2: buyer cannot call seller-only endpoints`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `Q. Permission Boundaries › Q4: update_payment_provider rejects non-admin`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `R. Miscellaneous › R3: configure_algolia is admin-only`
- [ ] **[did-not-run]** `api-coverage.spec.ts` — `R. Miscellaneous › R4: deactivate_supplier_platform rejects non-admin`

### `auth-gates.spec.ts`

- [ ] **[did-not-run]** `auth-gates.spec.ts` — `Auth Gates › unverified users are blocked by the email verification gate`

### `cart-manipulation.spec.ts`

- [ ] **[did-not-run]** `cart-manipulation.spec.ts` — `Cart Manipulation › T01: Add item to cart via API`

### `checkout-validation.spec.ts`

- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects invalid postal code format`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects invalid province code`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects price tampering (client sends lower price)`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects subtotal mismatch`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects negative price`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects quantity zero`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects quantity exceeding max cap (>100)`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects self-purchase (buyer is the seller of the product)`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Rejects non-Canadian shipping address (USA)`
- [ ] **[did-not-run]** `checkout-validation.spec.ts` — `Checkout Validation › Valid checkout creates session with Stripe URL`

### `deep-ui-scenarios.spec.ts`

- [ ] **[did-not-run]** `deep-ui-scenarios.spec.ts` — `A. Full Buyer Journey › A3: Buyer can create checkout session via API and verify order in SurrealDB`
- [ ] **[did-not-run]** `deep-ui-scenarios.spec.ts` — `C. Admin Panel Operations › C2: Admin can update product stock via API and verify SurrealDB`
- [ ] **[did-not-run]** `deep-ui-scenarios.spec.ts` — `D. Profile & Address Management › D2: Address CRUD via API — add, set default, delete`
- [ ] **[did-not-run]** `deep-ui-scenarios.spec.ts` — `E. Order Lifecycle Deep › E1: Full order state machine — pending → confirmed → shipped → delivered`
- [ ] **[did-not-run]** `deep-ui-scenarios.spec.ts` — `E. Order Lifecycle Deep › E2: Return request flow — buyer requests, admin approves`

### `edge-cases-security.spec.ts`

- [ ] **[did-not-run]** `edge-cases-security.spec.ts` — `8. Permission Isolation › Unauthenticated request to cancel_order is rejected`
- [ ] **[did-not-run]** `edge-cases-security.spec.ts` — `8. Permission Isolation › Unauthenticated request to submit_product_rating is rejected`
- [ ] **[did-not-run]** `edge-cases-security.spec.ts` — `8. Permission Isolation › Buyer cannot call update_order_status (requires seller or admin role)`

### `edit-product.spec.ts`

- [ ] **[did-not-run]** `edit-product.spec.ts` — `Edit Product Flow › T01: Update product preserves subcategory after edit`
- [ ] **[did-not-run]** `edit-product.spec.ts` — `Edit Product Flow › T02: Update product name and price via API`

### `favorites.spec.ts`

- [ ] **[did-not-run]** `favorites.spec.ts` — `Favorites — API Tests › T01: Toggle favorite ON via callable — verify SurrealDB doc created`
- [ ] **[did-not-run]** `favorites.spec.ts` — `Favorites — UI Tests › T07: UI — Favorites page is accessible from profile menu`

### `google-auth-config.spec.ts`

- [ ] **[did-not-run]** `google-auth-config.spec.ts` — `Google Auth Contract › web login button and backend readiness stay in sync`

### `multi-seller-orders.spec.ts`

- [ ] **[did-not-run]** `multi-seller-orders.spec.ts` — `Multi-Seller Orders › Cart with multiple items creates single order`
- [ ] **[did-not-run]** `multi-seller-orders.spec.ts` — `Multi-Seller Orders › Per-item status tracking works for multi-item order`

### `new-coverage-e2e.spec.ts`

- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `1. Stock Notification Subscribe/Unsubscribe › 1.5 Unauthenticated subscribe is rejected`
- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `2. Digital Product Purchase — License Generation › 2.1 Purchasing a digital product creates a license after capture`
- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `2. Digital Product Purchase — License Generation › 2.2 License is NOT created before payment is captured`
- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `3. Async Payment (Interac) Confirmation Flow › 3.2 Order created for async payment starts in pending_capture`
- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `3. Async Payment (Interac) Confirmation Flow › 3.3 Webhook handler processes payment_intent.succeeded for async payment`
- [ ] **[did-not-run]** `new-coverage-e2e.spec.ts` — `4. Multi-Seller Cart — Per-Seller Payout Verification › 4.1 Multi-seller cart creates order with items from both sellers`

### `new-notification-features.spec.ts`

- [ ] **[did-not-run]** `new-notification-features.spec.ts` — `New Notification Features E2E › Price drop notification is triggered for favorited products`
- [ ] **[did-not-run]** `new-notification-features.spec.ts` — `New Notification Features E2E › Chat message notification is triggered`
- [ ] **[did-not-run]** `new-notification-features.spec.ts` — `New Notification Features E2E › Message reporting (flagging) creates a report record`

### `non-premium-paywall.spec.ts`

- [ ] **[did-not-run]** `non-premium-paywall.spec.ts` — `Non-Premium Paywall › T01: Non-premium user sees paywall when accessing chat`
- [ ] **[did-not-run]** `non-premium-paywall.spec.ts` — `Non-Premium Paywall › T02: Paywall displays upgrade button with correct semantic label`

### `order-cancellation-refund.spec.ts`

- [ ] **[did-not-run]** `order-cancellation-refund.spec.ts` — `Order Cancellation & Refund › Buyer can cancel order before shipping`

### `order-lifecycle.spec.ts`

- [ ] **[did-not-run]** `order-lifecycle.spec.ts` — `Order Lifecycle › Order created after payment has confirmed status`
- [ ] **[did-not-run]** `order-lifecycle.spec.ts` — `Order Lifecycle › Invalid transition confirmed → delivered is rejected`

### `order-notifications.spec.ts`

- [ ] **[did-not-run]** `order-notifications.spec.ts` — `Order Notifications › Buyer receives notification when individual items are shipped`
- [ ] **[did-not-run]** `order-notifications.spec.ts` — `Order Notifications › Seller receives notification when a new order is placed`

### `orignabase-integration.spec.ts`

- [ ] **[did-not-run]** `orignabase-integration.spec.ts` — `OrignaBase — UI Integration Flows › O1: Profile Update reflects in OrignaBase SurrealDB`
- [ ] **[did-not-run]** `orignabase-integration.spec.ts` — `OrignaBase — UI Integration Flows › O2: Checkout Flow creates Order in OrignaBase`
- [ ] **[did-not-run]** `orignabase-integration.spec.ts` — `OrignaBase — UI Integration Flows › O3: Admin can Suspend/Unsuspend Seller in OrignaBase`

### `orignabase-security.spec.ts`

- [ ] **[did-not-run]** `orignabase-security.spec.ts` — `OrignaBase Security Boundaries › S1: Buyer CANNOT delete another user account`
- [ ] **[did-not-run]** `orignabase-security.spec.ts` — `OrignaBase Security Boundaries › S2: Buyer CANNOT call Admin functions (mail logs)`
- [ ] **[did-not-run]** `orignabase-security.spec.ts` — `OrignaBase Security Boundaries › S4: Non-Seller CANNOT answer a question`

### `password-reset.spec.ts`

- [ ] **[did-not-run]** `password-reset.spec.ts` — `Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL`
- [ ] **[did-not-run]** `password-reset.spec.ts` — `Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired`

### `payment-edge-cases.spec.ts`

- [ ] **[did-not-run]** `payment-edge-cases.spec.ts` — `Payment Edge Cases › Declined card shows error on Stripe page`
- [ ] **[did-not-run]** `payment-edge-cases.spec.ts` — `Payment Edge Cases › 3D Secure card triggers authentication challenge`
- [ ] **[did-not-run]** `payment-edge-cases.spec.ts` — `Payment Edge Cases › Currency is always CAD for Canadian buyers`
- [ ] **[did-not-run]** `payment-edge-cases.spec.ts` — `Payment Edge Cases › Declined card does not decrement stock`

### `premium-subscription.spec.ts`

- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `A. Subscription Status API › A1: get_subscription_status returns expected shape`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `A. Subscription Status API › A3: isPremium on user doc matches subscription doc status`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `B. Subscription Screen UI › B4: Price shows CAD $7.86/month`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `C. Create Subscription API + Session Integrity › C5: create_subscription idempotency — same user gets same session (or ALREADY_EXISTS)`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `D. Full Stripe Checkout — Success Flow › D1: 4242 card — successful subscription — SurrealDB isPremium=true within 60s`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `E. Stripe Checkout — Declined Card Scenarios › E4: After all declined attempts, isPremium remains false`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `G. Webhook Sync — SurrealDB State › G4: invoice.payment_failed — subscription status becomes past_due`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `I. Cancel Subscription Flow › I2: cancel_subscription returns not-found for non-subscriber`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `K. Chat Paywall Gate › K1: Non-premium buyer gets permission-denied from open_chat`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `K. Chat Paywall Gate › K2: Premium-check fires BEFORE product existence check`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `L. Security Adversarial › L3: Stripe webhook rejects requests without valid signature`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `L. Security Adversarial › L4: Stripe webhook rejects tampered signature`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `L. Security Adversarial › L5: cancel_subscription rejects when subscription is already cancelled`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route`
- [ ] **[did-not-run]** `premium-subscription.spec.ts` — `N. Reactivate Subscription › N3: reactivate_subscription returns not-found for non-subscriber`

### `preview-screenshots.spec.ts`

- [ ] **[did-not-run]** `preview-screenshots.spec.ts` — `Widget Preview Screenshots — Desktop › screenshot all previews`

### `product-video-e2e.spec.ts`

- [ ] **[did-not-run]** `product-video-e2e.spec.ts` — `Product Video Flow › T01: Upload valid video and verify playback UI state`

### `profile-management.spec.ts`

- [ ] **[did-not-run]** `profile-management.spec.ts` — `Profile Management — API Tests › T01: Get profile returns user data`

### `reorder-language.spec.ts`

- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T04: Orders screen accessible from profile menu`
- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T05: Orders screen shows filter tabs`
- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T06: Language setting visible in profile screen`
- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T07: Switching to French changes home page text`
- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T09: Buy Again button visible on completed order detail`
- [ ] **[did-not-run]** `reorder-language.spec.ts` — `Reorder & Language — UI › T10: Recently viewed section appears on home after viewing a product`

### `return-request.spec.ts`

- [ ] **[did-not-run]** `return-request.spec.ts` — `Return Request Flow (Flow 6) › Buyer can request return and seller can approve`
- [ ] **[did-not-run]** `return-request.spec.ts` — `Return Request Flow (Flow 6) › Cannot request return for digital products`

### `search-filters-sort.spec.ts`

- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — API › T04: get_products_paginated with minPriceCents filter returns only matching products`
- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — UI › T06: Sort button is visible on home page`
- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — UI › T07: Sort button opens sort options sheet`
- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — UI › T08: Price filter button is visible on home page`
- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — UI › T09: Price filter opens dialog and apply button exists`
- [ ] **[did-not-run]** `search-filters-sort.spec.ts` — `Search Filters & Sort — UI › T10: Search bar accepts input and shows results`

### `search-products.spec.ts`

- [ ] **[did-not-run]** `search-products.spec.ts` — `Search & Discovery — API Tests › T02: Pagination cursor returns different products`

### `security-access-control-deep.spec.ts`

- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `1. IDOR — Order Access Control › Buyer cannot cancel an order that belongs to a different buyer`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `1. IDOR — Order Access Control › Buyer cannot update order status (update_order_status is seller/admin only)`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `2. IDOR — Address Access Control › Buyer cannot set default address that belongs to another user`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `3. Seller IDOR — Product Isolation › Seller cannot update a product owned by another seller`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `3. Seller IDOR — Product Isolation › Seller cannot delete a product owned by another seller`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `3. Seller IDOR — Product Isolation › Seller cannot update stock of a product they do not own`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `4. Privilege Escalation Attempts › Buyer cannot access admin_get_users (admin-only endpoint)`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `4. Privilege Escalation Attempts › Buyer cannot suspend another user (admin_suspend_user)`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `4. Privilege Escalation Attempts › Buyer cannot call create_product_atomic without seller role`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `5. Price Tampering at Checkout › Checkout with client-side manipulated price is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `5. Price Tampering at Checkout › Checkout with subtotalCents 100x inflated is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `5. Price Tampering at Checkout › Checkout with negative subtotalCents is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `6. JWT Token Manipulation › Empty bearer token is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `6. JWT Token Manipulation › SQL injection as bearer token is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `7. Race Condition — Last Item in Stock › Two concurrent checkout requests for last-in-stock item: at most one succeeds`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `9. Coupon Abuse › Applying non-existent coupon code is rejected with not-found`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `9. Coupon Abuse › Applying expired coupon is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `10. Return Request Abuse › Buyer cannot create return request for order they do not own`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `10. Return Request Abuse › Return request on non-delivered order is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `11. Stock Notification Abuse › Subscribe to non-existent product is rejected`
- [ ] **[did-not-run]** `security-access-control-deep.spec.ts` — `11. Stock Notification Abuse › Unsubscribe from a product never subscribed is idempotent (not an error)`

### `seller-product-management.spec.ts`

- [ ] **[did-not-run]** `seller-product-management.spec.ts` — `Seller Product Management — API Tests › T01: Get seller products — returns own products with correct sellerId`
- [ ] **[did-not-run]** `seller-product-management.spec.ts` — `Seller Product Management — UI Tests › T05: UI — Seller can navigate to add product page`
- [ ] **[did-not-run]** `seller-product-management.spec.ts` — `Seller Product Management — UI Tests › T06: UI — Seller sees own product cards on home page`
- [ ] **[did-not-run]** `seller-product-management.spec.ts` — `Seller Product Management — UI Tests › T08: UI — Seller sees rejection banner with Fix & Resubmit button for rejected products`

### `seller-registration.spec.ts`

- [ ] **[did-not-run]** `seller-registration.spec.ts` — `Seller Registration — API Tests › T01: Create Connect account — idempotent, returns account ID`

### `seller-screens-ui.spec.ts`

- [ ] **[did-not-run]** `seller-screens-ui.spec.ts` — `Seller UI Screens › T01: Seller Products screen renders via profile menu`

### `shipping-approval.spec.ts`

- [ ] **[did-not-run]** `shipping-approval.spec.ts` — `Shipping Approval › Seller can submit shipping cost for an order`

### `shipping-calculation.spec.ts`

- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Checkout includes tax calculation for Ontario address`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Order total = subtotal + tax + shipping`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Currency is always CAD`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Multiple quantity correctly multiplies subtotal`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Quebec address applies QST+GST tax rate (~14.975%)`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Alberta address applies GST-only tax rate (5%)`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Perishable item from local seller: checkout succeeds with same-day option`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › Perishable product without local/same-day option is auto-deactivated by backend`
- [ ] **[did-not-run]** `shipping-calculation.spec.ts` — `Shipping Calculation › International seller has non-zero shipping cost`

### `stock-notif.spec.ts`

- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.5 Subscribe without variantKey (product-level) works`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.6 Unauthenticated subscribe is rejected with unauthenticated error`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.7 Subscribe to non-existent product is rejected`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.8 Subscribe to in-stock product is rejected (must be OOS)`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.9 Missing productId is rejected with invalid-argument`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.10 Unsubscribe when not subscribed is idempotent (no error)`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `4. Security — Adversarial Scenarios › 4.1 Buyer cannot unsubscribe another user's notification`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `4. Security — Adversarial Scenarios › 4.2 Expired auth token is rejected`
- [ ] **[did-not-run]** `stock-notif.spec.ts` — `4. Security — Adversarial Scenarios › 4.4 Subscribe with excessively long variantKey is rejected`

### `stripe-payment.spec.ts`

- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › Full checkout — Stripe payment — order confirmed`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › Order document has correct structure after payment`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › Stock decremented by exact ordered quantity after payment`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › Checkout URL redirects to Stripe hosted page`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › Duplicate checkout with same idempotency key returns same order`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › [BONUS] Order expiresAt is within 6-day authorization window`
- [ ] **[did-not-run]** `stripe-payment.spec.ts` — `Stripe Payment Flow › [BONUS] Cart is cleared after successful order creation`

### `subcategory-filtering.spec.ts`

- [ ] **[did-not-run]** `subcategory-filtering.spec.ts` — `Subcategory Filtering — API › T03: create_product_atomic with valid subcategory stores it in SurrealDB`

### `support-agent.spec.ts`

- [ ] **[did-not-run]** `support-agent.spec.ts` — `Customer Support Agent › T01 — unauthenticated user redirected to login from /support`
- [ ] **[did-not-run]** `support-agent.spec.ts` — `Customer Support Agent › T02 — authenticated buyer sees category picker`
- [ ] **[did-not-run]** `support-agent.spec.ts` — `Customer Support Agent › T03 — selecting category reveals chat input`
- [ ] **[did-not-run]** `support-agent.spec.ts` — `Customer Support Agent › T04 — user can type and attempt to send message`
- [ ] **[did-not-run]** `support-agent.spec.ts` — `Customer Support Agent › T05 — Profile → Get Help navigates to support screen`

### `trending-products.spec.ts`

- [ ] **[did-not-run]** `trending-products.spec.ts` — `Trending Products flows › Premium user can toggle Trending Products notifications`

### `visual-regression.spec.ts`

- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › login page screenshot`
- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › home page screenshot`
- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › settings/profile screenshot`
- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › cart page screenshot`
- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › product detail screenshot`
- [ ] **[did-not-run]** `visual-regression.spec.ts` — `Visual Regression › search results screenshot`

### `warehouse-multi-location.spec.ts`

- [ ] **[did-not-run]** `warehouse-multi-location.spec.ts` — `Warehouse: multi-location seller flow › T1: seller creates a warehouse and it is persisted in SurrealDB`
- [ ] **[did-not-run]** `warehouse-multi-location.spec.ts` — `Warehouse: multi-location seller flow › T3: duplicate sellerSku products cannot coexist — one is blocked on write`
- [ ] **[did-not-run]** `warehouse-multi-location.spec.ts` — `Warehouse: multi-location seller flow › T4: product document has shipFromCity and shipFromProvince after warehouse-based creation`
- [ ] **[did-not-run]** `warehouse-multi-location.spec.ts` — `Warehouse: multi-location seller flow › T5: inventoryLevels subcollection stores per-warehouse stock; stockQuantity equals sum`
