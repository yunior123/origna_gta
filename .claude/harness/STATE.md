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

## Bugs Still Open (Codex workhorse working on these)
1. Flutter red assertion screen on Edit Product (screenshots 105-108)
2. Product detail fails to load ("Impossible de charger le produit")
3. Home still shows old placeholder products first
4. E2E shipping-calculation + adversarial-injection still failing
5. E2E smoke/auth/prod/flow/pay phases not fully run yet

## Codex Workhorse Status
- Running since 21:21 EDT, PID active
- 50K+ lines output, working on bugs + E2E + Rust tests

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
