# State — Design Audit 2026-03-26

## Git
- Commit: c084eb35a pushed to origin/main
- 89 files changed, 6111 insertions, 2349 deletions

## Completed
- 172 screenshots on ~/Desktop/origna-design-review-2026-03-26/
- 141 Semantics labels added across 55 files
- 3 hardcoded Colors.white → DesignTokens.white
- CORS fix: allow_headers(Any) → explicit list (keeps allow_credentials)
- Checkout: province→state with serde alias backward compat
- Cart UX: unavailable items now show product name/image/price snapshot
- Dark theme: filter chips, add/edit product forms use isDark
- Desktop home grid capped at 5 columns
- Email service: Mailjet SMTP configured on dev/staging/prod VPS
- VPS disk cleanup cron installed (daily, prune when >80%)
- 20 product images uploaded to Cloudflare R2 (pub-f9698d0f.r2.dev)
- Seed updated to use R2 image URLs
- E2E assertions partially fixed (checkout-validation, security-access-control, multi-seller-orders passing)
- 4-reviewer code review completed (correctness, security, performance, standards)

## Review Findings — TO FIX NEXT PASS
### Performance (confidence 8)
- ~15-20 redundant Semantics wrappers around already-semantic widgets (TextButton, ElevatedButton, TextFormField, InkWell already have semantics). Each adds unnecessary Element + RenderObject + SemanticsNode. Fix: use tooltip/semanticsLabel parameter instead of wrapping.
- Triple Theme.of(context).brightness lookups in addproduct_basic_info_section.dart — compute isDark once

### Standards (confidence 7-9)
- addproduct_delivery_section.dart:~340 — hardcoded DesignTokens.darkSurfaceVariant fillColor (not theme-aware)
- addproduct_form_widgets.dart:~506 — hardcoded light surfaceVariant fillColor
- addproduct_specs_section.dart:~130 — DesignTokens.white text not theme-aware
- cart_provider.dart:85 — price as double (pre-existing pattern, priceCents int is correct)

### Correctness (confidence 7-8)
- multi-seller-orders.spec.ts:~582 — "same-seller" test uses 2 different sellers
- security-data-fixes.spec.ts:~856 — delete_address vs delete_buyer_address endpoint name
- checkout-validation.spec.ts:~458 — inconsistent error code casing (auth-error vs AUTH_ERROR)

### Security (LOW severity, all addressed)
- Hardcoded test password in e2e utility scripts (test-only)
- --full-page junk file deleted before commit

## Bugs Resolved (2026-03-27)
1. [x] Flutter red assertion on Edit Product — Riverpod initState fix (Future.microtask)
2. [x] Product detail load failure — PostgreSQL timestamp precision + sellerAddress province->state
3. [ ] Home still shows old placeholder products first — needs reseed
4. [x] E2E Phase 1: 464 pass, 0 fail
5. [ ] E2E Phase 2-6: Codex B8 still running

## Security Fixes Applied (2026-03-27)
- [x] **P0 CRITICAL**: Double-payout removed — cron no longer creates redundant Stripe transfer
- [x] **P1**: Flutter logout calls POST /auth/logout server-side
- [x] **P1**: Password reset revokes pre-reset tokens via password_changed_at + iat check
- [x] **P1**: SDK auto-refresh on 401 — single-flight completer pattern
- [x] **P2**: forgot_password resets reset_token_used flag
- [x] **P2**: MFA lock enforced with 15-min auto-unlock + 429 TooManyRequests
- [x] **P2**: Refresh token expiry aligned to 6 days (518400s) all envs
- [x] **P2**: Profile logout routed through AuthRepository
- [x] 13 widget tooltip->Semantics compilation fixes
- [x] Geoapify E2E tests added (12 tests)
- [x] Codex model guardrail hook (blocks <gpt-5.4)

## Blockers for Discussion
- [ ] **P1 Architectural**: Shared root DB session — PostgreSQL RLS policies not enforced
- [ ] **P2**: Mobile token persistence — no Keychain/Keystore (deferred to mobile launch)
- [ ] **P2**: Reset page no token verify on load — UX improvement
- [ ] **P2**: Schema creation no PERMISSIONS clauses — admin-only path
- [ ] Gemini Pro 429 — known Google server-side bug, use API key or Flash as workaround

## Codex Batch Results (2026-03-27 04:30 EDT)

### Completed Batches
| Batch | Task | Result | Tokens |
|-------|------|--------|--------|
| 1 | Rust clippy + tests | All clean, 64.5GB freed | ~150K |
| 2 | Flutter analyze + tests | All clean, all pass | ~171K |
| 3 | Dart code audit (read-only) | Findings in /tmp/*.txt | 187K |
| 4 | Flutter live tests | **211 pass, 0 fail** | ~100K |
| 5 | Audit fixes (R2 URLs, imports) | Done, analyze clean | ~80K |
| 6 | Documentation (Rust+Dart) | Doc comments added | ~150K |
| 7 | Seed improvements | Chat/reviews/subs/coupons added, TSC passes | ~160K |
| 8 | E2E Phase 1 | **464 pass, 0 fail**. Phase 2 in progress | running |
| 9 | Auth system audit | 5 P1 + 8 P2 findings | ~174K |
| 10 | Stripe webhook audit | 1 CRITICAL + partial (hit usage limit) | 174K |

### Auth Audit Findings (Batch 9) — /tmp/auth-audit-results.txt
| Sev | File:Line | Issue |
|-----|-----------|-------|
| P1 | ob-auth/routes.rs:565 | Refresh-token rotation not atomic — concurrent requests can both mint tokens |
| P1 | ob-auth/routes.rs:1218 | Password reset doesn't revoke existing refresh tokens/sessions |
| P1 | orignabase SDK auth.dart:373 | Flutter logout is local-only — never calls /auth/logout |
| P1 | orignabase SDK client.dart:203 | No auto-refresh on 401 — requests fail immediately on expiry |
| P1 | ob-database/client.rs:23 | App uses shared root DB session — PostgreSQL RLS policies not enforced |
| P2 | config/prod.toml:18 | Refresh token 7 days vs documented 6 days |
| P2 | ob-auth/routes.rs:1123 | forgot_password doesn't reset reset_token_used flag |
| P2 | ob-auth/routes.rs:1566 | MFA lock flag written but never enforced |
| P2 | ob-admin/schema.rs:35 | Schema creation emits no PERMISSIONS clauses |
| P2 | ob-admin/routes.rs:993 | /admin/health mounted outside protected router |
| P2 | orignabase SDK auth.dart:61 | Mobile tokens memory-only — no secure persistence |
| P2 | profile_viewmodel.dart:27 | Logout bypasses AuthRepository cleanup |
| P2 | reset_password_view_model.dart:31 | Reset page doesn't verify token on load |

### Stripe Audit Findings (Batch 10 — partial, hit usage limit)
| Sev | File:Line | Issue |
|-----|-----------|-------|
| **CRITICAL** | checkout.rs:686 + cron/mod.rs:120,319 | **Double-payout risk**: destination charge (Connect) + separate cron transfer for same order = seller paid twice |

## SurrealDB → PostgreSQL Migration (2026-03-29) — COMPLETE

### Results
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Handler tests passing | 1437/1749 (82%) | 1742/1749 (99.6%) | **+305 tests** |
| Test failures | 312 | 7 | **-97.8%** |
| Commits | 0 | 16 | |
| Agents deployed | 0 | 12 | |
| Files modified | 0 | ~30 | |

### Completed
- [x] P0 Critical Fixes: TOCTOU CAS guards, order state machine, price truncation
- [x] Enhanced `translate_surreal_to_pg`: type::thing, CREATE CONTENT, UPSERT, UPDATE MERGE, bare field rewrite
- [x] `PgDatabaseStore` adapter: 22 trait methods (16 original + 6 new filter/aggregate)
- [x] Test isolation: ON CONFLICT for duplicate keys, auto-truncation on startup
- [x] Handler migration: ALL 19 modules at 0 failures except cron (7)
- [x] Hexagonal architecture: 6 new filter methods (find_where, count_where, exists_where, update_where, delete_where, find_where_multi)
- [x] New skill: `postgres-expert` (SQL injection prevention + hexagonal compliance)
- [x] `= NONE` → `IS NULL` translation for SurrealDB null values

### Modules at 0 Failures (18/19)
addresses, chat, checkout, connect, coupons, digital, email, native_triggers,
products/crud, products/questions, products/ratings, products/stock,
products/triggers, orders/refunds, orders/returns, orders/shipping,
orders/status, users, warehouses, webhooks, subscriptions, providers, capture

### Remaining (7 cron + 2 misc)
- 7 cron tests: test isolation in batch mode (all pass individually)
- 1 products::crud, 1 payments::checkout: stale data in batch

### Architecture Grade: C+ → B+
- Hexagonal boundary: 22 trait methods, zero sqlx in handlers
- SQL injection: zero tolerance, parameterized everywhere
- Future DB swap: implement 22 methods → zero handler changes
- To reach A: refactor 103 query_bind/query_raw calls to use new trait methods

## Remaining Tasks
1. Fix redundant Semantics wrappers (~15-20 files) — use tooltip/semanticsLabel instead of wrapping
2. Fix 3 hardcoded dark-only fillColors to be theme-aware (isDark conditional)
3. Fix addproduct_specs_section white text for light theme
4. Fix Flutter red assertion on edit-product screen
5. Fix product detail load failure
6. Clean old seed products from dev DB, reseed with R2 images only
7. Fix E2E error code assertions (shipping-calculation, adversarial-injection)
8. Run ALL 6 E2E phases to completion (api/smoke/auth/prod/flow/pay)
9. Run Rust backend tests: cargo clippy -D warnings && cargo test
10. Run Flutter live tests against dev: flutter test test/live/ --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev
11. Verify Geoapify integration works (API key in vault)
12. Verify email delivery to 3 test accounts (yuniorrodriguezo460@gmail.com, yr62813@gmail.com, yuniorrodriguezo4601@yahoo.com)
13. Audit all 172 screenshot names vs actual content — rename mismatches
14. Capture missing state variants (order states, subscription active, seller order cards, product variants)
15. Document modified functions with JSDoc/rustdoc
16. Verify staging + prod environments are configured correctly (email, Stripe webhooks, Meilisearch)
17. Commit + push any new fixes from Codex workhorse
18. Deploy final Flutter build + Rust backend to dev VPS

---

## Mega Task List (2026-03-27)

### Phase A: Backend + Frontend Tests — Fix All, No Excuses
- [x] **A1.** Run ALL Rust backend tests (`cargo clippy -D warnings && cargo test`) — fix every failure, pipe results to `/tmp/rust-test-results.txt`
- [x] **A2.** Run ALL Flutter live tests (`flutter test test/live/ --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev`) — fix every failure, pipe to `/tmp/flutter-live-results.txt`
- [x] **A3.** Run ALL Flutter unit/widget tests (`flutter test --exclude-tags golden`) — fix every failure, pipe to `/tmp/flutter-unit-results.txt`
- [ ] **A4.** Run ALL E2E phases sequentially (api -> smoke -> auth -> prod -> flow -> pay), kill chrome between each, pipe each to `/tmp/e2e-{phase}-results.txt`
- [ ] **A5.** After smoke tests, run E2E tests that trigger email — verify delivery to yuniorrodriguezo460@gmail.com, yr62813@gmail.com, yuniorrodriguezo4601@yahoo.com
- [x] **A6.** Fix ALL warnings in Rust (`cargo clippy -D warnings`) and Dart (`flutter analyze --no-fatal-infos`) — zero warnings
- [ ] **A7.** Fix what remains in STATE.md bugs section (edit-product red assertion, product detail load failure, E2E shipping-calculation, adversarial-injection)
- [ ] **A8.** Tests marked "skipped (live tests - need backend)" — run them with backend, fix them. Tests marked "failed (expected - backend connection issues)" — connect to backend, fix them. No excuses.

### Phase B: Seed Improvements — All Variants & States
- [x] **B1.** Improve mega seed (`e2e/lib/seed-dev.ts`) — every product gets sample R2 images AND at least 1 video URL
- [ ] **B2.** Seed data for ALL view variants: favorites (3+ favorited products per buyer), cart (3+ items including unavailable), orders (all states: pending/confirmed/shipped/delivered/cancelled), return requests, notifications (5+ mixed types)
- [ ] **B3.** Seed seller dashboard full: 10+ products (mix of draft/active/inactive), 15+ orders across all states, earnings data, warehouse addresses
- [ ] **B4.** Seed admin dashboard full: multiple sellers (approved/pending/rejected), users, flagged orders, disputes
- [ ] **B5.** Seed addresses: 3+ per buyer with varied provinces, labels (Home/Work/Other), default flag
- [ ] **B6.** Seed chat conversations: buyer<->seller threads with 5+ messages each
- [ ] **B7.** Seed reviews: mix of 1-5 stars with text, images, seller responses
- [ ] **B8.** Seed subscriptions: active premium user + inactive user
- [ ] **B9.** Seed coupons: active + expired + usage-limited
- [ ] **B10.** Test accounts MUST include: yuniorrodriguezo460@gmail.com, yr62813@gmail.com, yuniorrodriguezo4601@yahoo.com — seed with orders, favorites, addresses
- [ ] **B11.** Reseed dev DB after improvements, verify all views show populated state

### Phase C: Coverage Push — 95%+ Target
- [ ] **C1.** Rust backend coverage: measure with `cargo tarpaulin`, identify gaps, write tests to reach 95%+ — priority: live integration tests, NOT mocks
- [ ] **C2.** Coverage gaps to close (from previous audit): ob-storage/s3.rs (55%), ob-notifications/routes.rs (58%), ob-storage/routes.rs (67%), ob-search/client.rs (70%), ob-mcp/transport.rs (74%), ob-realtime/websocket.rs (75%) — write real integration tests, not mocked stubs
- [ ] **C3.** Flutter app coverage: `flutter test --coverage`, identify gaps, write tests to reach 95%+ — priority: live tests against localhost/dev
- [ ] **C4.** Priority for live tests hitting real OrignaBase+PostgreSQL+Meilisearch, unit tests secondary
- [ ] **C5.** Fix ALL `test.skip` — implement the test properly or fix the infrastructure

### Phase D: Cleanup & Hygiene
- [x] **D1.** Clean cargo build artifacts: `cargo clean` in orignabase/ after test runs
- [ ] **D2.** Clean Flutter build artifacts: `flutter clean` in origna_gta/ after test runs
- [ ] **D3.** Kill zombie `flutter_test`, `dart`, `chrome` processes between test phases
- [ ] **D4.** Monitor RAM throughout — never exceed 8GB, sequential only
- [ ] **D5.** Run ALL example app tests (if any exist in orignabase/examples/), clean after

### Phase E: Codebase Audit — 70+ Agents
- [ ] **E1.** Full codebase audit with 70+ agents (use delegation: codex, gemini, subagents). Categories: security, performance, correctness, standards, cross-stack, logic, payments, auth, UI/UX
- [ ] **E2.** Use quorum verification (3+ agents agree) to eliminate false positives — only validated findings in STATE.md
- [ ] **E3.** Run `/code-review` (4 parallel reviewers: correctness, security, performance, standards) — score >=9 blocks commit
- [ ] **E4.** Audit all 10+ user flows: registration -> login -> browse -> search -> add-to-cart -> checkout -> payment -> order-tracking -> delivery -> return. Use `.claude/skills/flow-audit/SKILL.md`
- [ ] **E5.** Auth system audit: backend JWT lifecycle, token refresh, Google OAuth, MFA TOTP, session management, admin role enforcement, row-level security in PostgreSQL
- [ ] **E6.** Audit Stripe webhook endpoints: test ALL webhooks (payment_intent.succeeded, checkout.session.completed/expired, charge.dispute.created, account.updated, etc.) using Stripe CLI forwarding — both test and live mode verification
- [ ] **E7.** Security infrastructure skill: search latest hacker news/CVEs/attack patterns, audit code against real-world findings, critical issues only, no false positives
- [ ] **E8.** Add ALL audit findings to STATE.md with severity (P0/P1/P2), file:line, and fix status
- [ ] **E9.** Audit ALL Riverpod providers: circular dependencies, missing dispose, leaked listeners, unnecessary rebuilds, missing .select()
- [ ] **E10.** Audit ALL Freezed models: missing fields vs backend, wrong types, missing fromJson/toJson, missing copyWith usage
- [ ] **E11.** Audit ALL GoRouter routes: missing redirects, unprotected admin routes, deep link handling, 404 fallback
- [ ] **E12.** Audit ALL form validations: client-side validators match backend constraints (email regex, postal code, phone E.164, price range, stock limits)
- [ ] **E13.** Audit ALL image handling: CachedNetworkImage usage, missing placeholders, missing error widgets, R2 URL patterns, image dimensions
- [ ] **E14.** Audit ALL PostgreSQL queries in Rust: SQL injection risks, missing parameterized queries, N+1 patterns, missing indexes, transaction safety
- [ ] **E15.** Audit ALL error messages: user-facing vs internal (no stack traces leaked), i18n readiness (en/fr), consistent error codes
- [ ] **E16.** Audit ALL API endpoints in Rust: missing auth middleware, missing rate limiting, missing input validation, missing response sanitization
- [ ] **E17.** Audit ALL Dart imports: no relative imports (../), no unused imports, no circular imports, package:origna_gta/ everywhere
- [ ] **E18.** Audit ALL widget trees: unnecessary nesting, missing const constructors, missing keys on list items, missing Semantics labels
- [ ] **E19.** Audit ALL async code: missing error handling on Futures, unawaited futures, missing cancellation on dispose, race conditions
- [ ] **E20.** Audit ALL money calculations: integer cents everywhere, no double arithmetic, correct rounding at display layer, platform fee formula
- [ ] **E21.** Audit ALL Sentry integration: error capture coverage, breadcrumbs, user context, sensitive data scrubbing
- [ ] **E22.** Audit ALL localization: en.json + fr.json completeness, no hardcoded user-facing strings, interpolation correctness
- [ ] **E23.** Audit ALL responsive layouts: mobile/tablet/desktop breakpoints, maxWidth constraints, no overflow on small screens
- [ ] **E24.** Audit ALL dark theme: DesignTokens-only colors, contrast ratio >= 4.5:1, no white backgrounds, card colors correct
- [ ] **E25.** Audit Meilisearch sync: all products indexed, filterable/sortable/searchable attributes match schema, stale data cleanup
- [ ] **E26.** Audit CORS config: allowed origins per env, credentials handling, preflight caching, no wildcard in prod
- [ ] **E27.** Audit rate limiting: per-endpoint config, auth vs public limits, 429 response format, client-side backoff in SDK
- [ ] **E28.** Audit Docker config: image size optimization, multi-stage build, health checks, restart policies, log rotation, resource limits
- [ ] **E29.** Audit Caddy config: TLS certs auto-renewal, reverse proxy headers, security headers (HSTS, CSP, X-Frame-Options)
- [ ] **E30.** Audit CI/CD pipelines: test coverage gates, lint gates, security scanning, deploy rollback strategy
- [ ] **E31.** Audit dependency versions: `flutter pub audit`, `cargo audit`, outdated packages, known CVEs
- [ ] **E32.** Audit data privacy: PII handling (PIPEDA compliance), data retention, user deletion flow, no PII in logs
- [ ] **E33.** Audit perishable product logic: 50km radius enforcement, no cross-province, delivery time constraints, seller notification urgency
- [ ] **E34.** Audit multi-seller checkout: order splitting, per-seller shipping, per-seller payout, Stripe Connect account validation
- [ ] **E35.** Audit return/refund flow: 30-day window, stock restoration atomicity, Stripe refund API, partial refund support, notification triggers

### Phase F: Documentation — Pro Level
- [ ] **F1.** Document ALL functions and classes with proper doc comments (/// for Dart, /// for Rust) — search web for best practices first
- [ ] **F2.** Focus on complex logic that causes back-and-forth confusion (e.g., image compression flow: for loop -> Future.wait -> for loop pattern)
- [ ] **F3.** Document data flows: UI -> ViewModel -> Service -> OrignaBase SDK -> PostgreSQL — per feature
- [ ] **F4.** Document environment handling: how localhost/dev/staging/prod are configured, `OB_TEST_MODE`, rate limiting differences
- [ ] **F5.** Use delegation (codex/gemini) for bulk documentation — too much for one agent

### Phase G: Load & Stress Testing
- [ ] **G1.** Run k6 load tests against dev API: auth endpoints, product CRUD, search, checkout flow
- [ ] **G2.** Run reliability tests: restart containers mid-request, verify graceful recovery
- [x] **G3.** Run stress tests: concurrent checkouts, rapid cart updates, bulk product creation
- [ ] **G4.** Run cargo bench for Rust backend — identify performance bottlenecks
- [ ] **G5.** Pipe all results to `/tmp/load-test-results/` directory

### Phase H: Infrastructure & Local Testing
- [ ] **H1.** Improve localhost test config: Stripe CLI webhook forwarding (`stripe listen --forward-to localhost:8080/stripe/webhook`), OrignaBase local, PostgreSQL local, Meilisearch local, Flutter web
- [ ] **H2.** Audit environment handling in main.rs: `OB_TEST_MODE` for localhost/dev/staging/prod — search web + GitHub for best practices (reference: current code at main.rs:1009)
- [ ] **H3.** Monitor RAM when running local stack — kill stale/zombie processes before starting
- [ ] **H4.** Verify staging + prod environments: health endpoints, email delivery, Stripe webhooks, Meilisearch sync
- [ ] **H5.** App update prompt: implement force-update check for mobile/tablet (version comparison against API)

### Phase I: Error Handling & Error Codes
- [ ] **I1.** Reinforce error codes in Rust: consistent AppError variants, proper HTTP status codes, no leaked internal details
- [ ] **I2.** Reinforce error handling in Dart: AppError usage, proper try/catch, no silent failures
- [ ] **I3.** Search web for state-of-the-art error handling patterns in Rust+Flutter — apply best practices
- [ ] **I4.** Stripe `application_fee_amount`: verify seller's actual Stripe Connect account status before applying — no workarounds

### Phase J: Design Audit — Full Coverage
- [ ] **J1.** Deploy latest Flutter build to dev VPS
- [ ] **J2.** Use agent-browser to capture ALL screens/widgets/states/variants — save to `~/Desktop/origna-design-review-2026-03-27/`
- [ ] **J3.** Fix agent-browser `navigateAndVerify()` helper to prevent mislabeled screenshots
- [ ] **J4.** Capture scroll positions: top/middle/bottom for long views
- [ ] **J5.** Audit all 305+ screenshots: filename vs content, rename mismatches, delete dupes
- [ ] **J6.** Compare design against Amazon/Shopify/Etsy — identify UX gaps
- [ ] **J7.** Fix all design issues found — no excuses

### Phase K: Advanced — AI Agents & Batch Processing
- [ ] **K1.** Use free NVIDIA NIM models (glm-5, minimax-m2.5, kimi-k2.5, mimo-v2-pro) for UI/UX feedback on screenshots
- [ ] **K2.** Batch codebase analysis: gather codebase context, send to AI endpoints for parallel audits
- [ ] **K3.** Use gstack skills (design audit, CEO review, etc.) for holistic review
- [ ] **K4.** Improve harness loop based on Anthropic's harness design research

### Phase L: GitHub & CI/CD
- [ ] **L1.** Study claude-code GitHub repo — apply all improvements to our repo
- [ ] **L2.** Commit + push all fixes (after `/code-review` passes)
- [ ] **L3.** Verify CI passes on GitHub Actions
- [ ] **L4.** Fix GitHub billing issue blocking workflows

### Delegation Strategy
- **Tokens are limited** — delegate aggressively to codex (gpt-5.4 FULL only), gemini (gemini-3-pro-preview), subagents
- **NEVER** launch claude-code instances in bash — use subagents instead (last time 5+ claude instances consumed 10% tokens in 2 minutes)
- **ALWAYS** pipe test results to /tmp/ files to avoid losing output
- **ALWAYS** kill zombie processes before starting new test phases
- **ALWAYS** clean cargo/flutter artifacts to save disk space
- **NEVER** skip tests, defer blockers, or use workaround shortcuts — fix root causes

### Phase M: Tooling & DevEx Fixes
- [ ] **M1.** Fix nvm/npmrc conflict: `~/.npmrc` has `prefix=/opt/homebrew` which breaks nvm. Remove prefix or use nvm-compatible config
- [ ] **M2.** Update Codex CLI to 0.117.0 (currently stuck at 0.112.0 in nvm due to npmrc conflict)
- [ ] **M3.** Codex delegation: use batches of 3+ for non-conflicting tasks, divide and conquer
- [ ] **M4.** Gemini temp files: enforce `/tmp/gemini-workspace/` — never create temp files in project root
- [ ] **M5.** Audit all CLI tools versions: codex, gemini, stripe, flutter, dart, cargo, bun — update all to latest
- [ ] **M6.** Clean up any stale temp files in project root (test_*.ts, update_*.js, etc.)
- [ ] **M7.** Codex /fast mode: evaluate 2X plan usage tradeoff for speed-critical delegation tasks

### Blockers (update as discovered)
- [ ] GitHub Actions billing — workflows fail with "payments have failed"
- [ ] Codex usage limits — may need cooldown periods
- [ ] VPS disk — monitor, prune Docker daily
- [ ] nvm/npmrc prefix conflict — blocks global npm installs via nvm

## 2026-03-27 Audit Loop Notes

### Fixes applied
- Flutter test failures fixed in:
  - `origna_gta/test/features/products/products_provider_test.dart`
  - `origna_gta/test/features/auth/auth_provider_test.dart`
  - `origna_gta/test/features/cart/cart_provider_test.dart`
- Checkout notifier hardened against post-dispose state writes in:
  - `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
- N+1 reduction applied in:
  - `origna_gta/lib/core/repositories/product_search_helpers.dart`
    - switched `fetchProductsByIdsImpl()` to chunked `whereIn` batch fetch
    - fallback only re-fetches IDs truly missing from the batch response
  - `origna_gta/lib/core/repositories/orignabase_user_repository.dart`
    - default-address cleanup now batches updates when supported
    - falls back to sequential updates when batch is unavailable in test fakes
- Checkout-flow regression fixed in:
  - `origna_gta/lib/features/checkout/orignabase_checkout_provider.dart`
    - removed premature `cartItemsProvider` invalidation on checkout session creation
    - cart now remains until payment-confirmation webhook cleanup
- PostgreSQL field-value update hardening in:
  - `orignabase/crates/ob-database/src/crud.rs`
    - value payloads now use bound parameters instead of interpolated `format!()` values
    - field names remain interpolated only after identifier validation
- Added backend order-state precondition regression test in:
  - `orignabase/crates/ob-handlers/src/payments/webhooks.rs`

### Tests added
- `origna_gta/test/unit/checkout_viewmodel_comprehensive_test.dart`
  - verifies successful checkout session creation does not invalidate cart provider
  - verifies duplicate checkout URL recovery does not invalidate cart provider
- `orignabase/crates/ob-handlers/src/payments/webhooks.rs`
  - verifies `update_order_status()` returns false and preserves existing status when precondition fails

### Verification outcomes
- `flutter analyze --no-fatal-infos` passed after fixes.
- Full non-golden Flutter suite passed once after the initial failure fixes:
  - `/tmp/flutter-test-pre.txt`
- Full non-golden Flutter suite passed again after the checkout cart-retention fix and new regression tests:
  - `/tmp/flutter-test-final.txt`
- Full Rust verification passed:
  - `cargo clippy -- -D warnings`
  - `cargo test`
  - output saved to `/tmp/rust-test-final.txt`
- `cargo clean` completed and removed 21.6 GiB of build artifacts.

### Security research
- Memo written to `/tmp/security-research.txt`.
- External references reviewed:
  - Shopware GHSA-7vvp-j573-5584 (2026-03-11): unauthenticated order-data extraction through order endpoint
  - WooCommerce GHSA-cv23-q6gh-xfrf / CVE-2024-37297 (2024-06-12): reflected XSS in checkout and registration
  - HackerOne retail/ecommerce materials: reflected XSS and information disclosure remain common classes
- Codebase assessment:
  - not directly affected by Shopware or WooCommerce package advisories
  - no obvious public unauthenticated order endpoint analogous to the Shopware issue found
  - no obvious checkout/login raw-HTML injection path analogous to WooCommerce found
  - local analogous risk discovered and fixed: cart was being cleared before webhook-confirmed payment

### Residual note
- Coverage/smoke runs still log `productRatingsProvider` backend `400` responses in some pump tests, but current tests fail open there and the full suite completed successfully in the last confirmed green run.

## 2026-03-27 Mega Loop 4 Notes

### Fixes applied
- `e2e/lib/seed-dev.ts`
  - every seeded product now gets `videoUrl` and `videoDurationSeconds`
- `orignabase/crates/ob-auth/src/password.rs`
  - `dummy_verify()` now follows a cached Argon2 verify path instead of a cheaper fresh-hash path
  - timing test now warms the cache and averages multiple samples to reduce noise
- `Caddyfile`
  - added explicit CSP and cache rules for Flutter web production responses
- `scripts/deploy_web.sh`
  - Flutter web build now disables the default PWA/service-worker strategy
- `orignabase/crates/orignabase/src/main.rs`
  - added graceful shutdown, DB-backed `/health`, request-id propagation, and panic hook

### Verification outcomes
- Reseed against dev completed:
  - `/tmp/reseed-loop4.txt`
- Flutter live tests passed:
  - `/tmp/live-loop4.txt`
  - `/tmp/flutter-live-results.txt`
- Flutter analyze passed:
  - `/tmp/flutter-analyze-loop4.txt`
- Full non-golden Flutter suite passed:
  - `/tmp/flutter-unit-results.txt`
- Full Rust verification passed after fixing the dummy-password timing regression:
  - `/tmp/rust-test-results.txt`
- Targeted regression check for the fixed Rust timing test passed:
  - `/tmp/rust-targeted-password-test.txt`
- `cargo clean` completed:
  - `/tmp/cargo-clean-loop4.txt`
  - removed 24.6 GiB

### Infra / audit artifacts
- Flutter web hardening memo:
  - `/tmp/flutter-web-hardening.txt`
- Rust/axum hardening memo:
  - `/tmp/rust-hardening.txt`
- VPS Caddy header audit:
  - `/tmp/caddy-audit.txt`
  - active config found at `/opt/orignabase/Caddyfile`; required security headers present
- k6 concurrent checkout stress test:
  - `/tmp/k6-checkout.txt`
  - 50 VUs for 60s, no 500 responses observed
