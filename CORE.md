@~/CLAUDE.md

# CORE.md — OrignaGTA Workboard

Single source of truth for active work.

Rules:
- Only mark `[x]` after real verification.
- Move completed one-off items to `STATE.md`; do not leave stale history here.
- Keep items updated in place; do not duplicate the same task in multiple sections.
- Save command output to `/tmp/...` for long runs.
- Prefer focused, reproducible verification before broad sweeps.

## Definition of done
- [ ] Code/config updated if needed.
- [ ] Relevant tests or live checks passed.
- [ ] Regressions covered when the bug is repeatable/high-value.
- [ ] `STATE.md` updated with evidence and impact.
- [ ] Item removed from this file once truly complete.

## P0 — Close current verified-but-open delivery blockers

### 1) Cuba parity closeout
- [x] Update the store to support Cuba in every aspect similarly to Canada.
- Current verified state: **COMPLETED** - frontend country/province/address validation, Cuba maritime shipping logic, zero-tax handling, backend Canada/Cuba province validation, and the dedicated Cuba address widget flow are present and re-verified.
- Verified evidence already on record:
  - `cd origna_gta && flutter test test/unit/schema_constants_test.dart` → `24 passed`
  - `cd orignabase && cargo test -p ob-handlers test_canada_and_cuba_provinces_are_valid -- --nocapture` → `1 passed`
  - `cd origna_gta && flutter test test/unit/utils_comprehensive_test.dart test/unit/utils_coverage_boost_test.dart` → passed
- Still required before close:
  - full end-to-end Cuba checkout/live UX audit
  - proof that real Cuba-specific address, shipping, tax, and checkout UX all behave correctly end-to-end

### 2) Spanish audit closeout
- [ ] Audit Spanish translations across the app.
- Current verified state: **IN PROGRESS** - high-signal buyer/seller/auth/subscription strings were translated on 2026-04-22, but the app is still not fully audited end-to-end.
- Verified evidence already on record:
  - `STATE.md` items `76` and `77`
  - untranslated-value count dropped from `2307` to `1723`
  - current largest remaining buckets: `checkout` (`239`), `product` (`218`), `admin` (`213`), `specs` (`131`), `orders` (`114`), `seller_integration` (`81`)
- Still required before close:
  - screen-by-screen Spanish QA across the remaining high-count modules
  - regression coverage for any newly translated high-risk checkout/order/auth flows

### 3) Payment system closeout
- [ ] Test all payment-related views and features in OrignaVentures and OrignaGTA, including backend flows.
  - Current verified state:
    - Ventures checkout-session idempotency regression fixed and redeployed
    - webhook-security `500` regression fixed and redeployed
    - `origna_ventures/backend/tests/test_payments_api.py` passes at `19 passed`
    - live no-email checkout probes for `origna_code`, `origna_launch`, `origna_team` return `200`
    - `origna-ventures-tax-live.spec.ts` is green
    - webhook-security block in `origna-ventures-live.spec.ts` is green again
    - `origna-ventures-mobile-pricing-live.spec.ts` passes (`2/0`)
    - receipt-email backend path now generates PDF attachments in tests
  - Still required before close:
    - full repo-wide payment audit across OrignaGTA + OrignaVentures
    - close the flaky mixed mobile live suite behavior
    - complete fresh end-to-end payment verification for the remaining surfaces
    - re-verify OrignaGTA order email / receipt / status flow with current seeded data instead of relying on older passing slices alone

### 4) Receipt/invoice closeout
- [ ] Send invoice receipt to clients after buying tiers, attached PDF included similar to OrignaGTA; email should be in English or French depending on user language or both.
- Current verified state:
  - Ventures backend generates a PDF receipt attachment for tier purchase receipt emails
  - attachment is included only on the client receipt email, not on the internal support copy
  - backend tests cover the behavior
  - backend was redeployed live
  - PDF now includes business legal name, business number (BN), invoice number (INV-{session_id}), developer count for OrignaTeam, full EN/FR/ES locale labels
  - `generate_receipt_pdf()` enhanced with `developer_count` param, business details, Spanish labels
- Verified evidence already on record:
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed`
  - `test_generate_receipt_pdf_contains_business_details`, `test_generate_receipt_pdf_french_labels`, `test_generate_receipt_pdf_spanish_labels` all pass
  - `cd origna_ventures && ./deploy.sh --backend-only`
- Still required before close:
  - live paid purchase proving real inbox delivery with the attached PDF
  - final locale decision/proof for English/French behavior

### 5) Ventures backend concurrency/reliability closeout
- [ ] Make sure backend supports concurrency for OrignaVentures when sending emails and paying. Find other gaps apart from concurrency to make sure backend is solid.
- Current verified state:
  - payment webhook commits DB state before dispatching emails
  - contact-form support/confirmation emails use the shared concurrent email-job helper
  - duplicate webhooks are idempotent
  - real Stripe CLI signed deliveries for `checkout.session.expired` and `invoice.payment_failed` returned `200` locally
  - email queue with SQLite persistence: `email_queue` table, `enqueue_email_job()`, `enqueue_email_jobs()`, retry (3 attempts), dead letter storage
  - `_email_queue_sync_mode` flag for test determinism
  - webhook price validation: cross-checks `amount_subtotal` against expected catalog price × quantity
  - subscription lifecycle email notifications (deleted, payment_failed, updated) with EN/FR/ES locales
  - `OperationalError` handling returns 503 on DB lock
  - SQLite concurrency fixes: `BEGIN IMMEDIATE` locking, connection leak fix, TOCTOU race fixes, webhook email enqueue isolation
  - all backend magic strings replaced with module-level constants
- Verified evidence already on record:
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed` (12 new regression tests)
- Still required before close:
  - broader SQLite write/load/concurrency stress testing under real concurrent load
  - remaining Stripe-doc alignment across repo
  - fresh live confirmation that the contact form still sends both support and client-facing emails

### 6) Payment hardening follow-up audits
- [ ] Audit payment system in entire repo as per latest Stripe docs.
- [ ] Audit magic strings in app; replace high-risk runtime strings with shared constants/enums where needed.
- Current verified state:
  - stale Ventures Stripe/tier docs were rewritten to match the live public Checkout Session flow and active tier catalog
  - Ventures backend magic strings fully remediated: all service codes, payment statuses, subscription statuses, webhook event types, and email queue statuses now use module-level constants
- Verified evidence already on record:
  - `origna_ventures/docs/TIER_REFACTOR.md`
  - `origna_ventures/docs/stripe_research.md`
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed`
- Still required:
  - OrignaGTA Flutter frontend magic string audit (schema_constants.dart coverage gaps)
  - full repo-wide payment audit across OrignaGTA + OrignaVentures

### 7) Search + auth recovery closeout
- [ ] Restore current dev/runtime search and auth paths before broader polish work.
- Current verified state: **IN PROGRESS** — dev catalog still has active products in all 21 storefront categories, but two items stay explicitly open until re-verified live:
  - Google web auth is intentionally marked disabled until a real Google OAuth web client ID (`*.apps.googleusercontent.com`) is installed on the server.
  - home cart badge/add-to-cart immediate refresh remains a red live-audit item until the optimistic badge update is re-verified.
- Still required before full close:
  - re-verify dev search/category click flow after the latest backend query fix
  - install real Google web OAuth server config, then re-enable and verify Google sign-in/up
  - close the home cart badge/add-to-cart immediate refresh live audit
  - broader staging/production parity verification is still pending

### 7B) Error observability hardening
- [x] Add an internal error-event path that links user-facing codes to support/debug context.
- Current verified state: **COMPLETED** — `AppError.log()` now writes to self-hosted GlitchTip and best-effort persists structured internal events to OrignaBase `error_events` with `SE-YYYYMMDD-XXXXXX` support IDs, `ORIGNA-*` user-facing code, stack trace, environment, user context, and metadata.

### 8) Delivery messaging closeout
- [x] Replace stale shopper delivery messaging and re-verify country coverage.
- Current verified state: **COMPLETED** — `DeliveryRegion` enum centralizes Canada/Cuba/international detection; `_buildEstimatedDelivery()` shows "4-8 weeks or longer" for international/28+ days; `_buildSellerPackage()` shows Cuba flag + "Delivery to Canada & Cuba"; order-success screen uses policy copy for non-local physical orders.
- Verified evidence: `flutter test test/unit/delivery_region_test.dart test/widget/ordersuccess_screen_test.dart` → passed; `flutter analyze` → passed on affected files.

## P1 — Product, design, and release work

### Design / UX
- [ ] Make the splash theme and OrignaVentures theme feel aligned; push toward a more expensive investor-ready direction, then re-test payment features after the pass.
- [ ] Continue OrignaVentures visual polish after the 2026-04-21 hero/proof-panel pass if more improvement is still needed.

### Content / assets
- [ ] Use realistic test seeded products from AliExpress, upload images to Cloudflare, and research Cloudflare best practices first for `dev.orignagta.ca`.
- [ ] Add the first products to production from `/Users/yuniorrodriguezosorio/Downloads/Quote` and `/Users/yuniorrodriguezosorio/Downloads/Quote for split phase AC120V 10KW Hybrid Solar System  --2026.pdf`.
  - Advanced state: extracted/improved solar images already in repo were wired into the live solar product via production static asset URLs; broader production catalog import is still pending.
- [x] Insert the solar module product into production with full home delivery + installation and make sure it is sold by Origna Ventures using the company Stripe config.
  - Verified on 2026-04-22: `e2e/specs/phase4-product-flows/prod-solar-product-live.spec.ts` passes (2/0), confirming live product at `https://orignagta.ca/product/207123c5-a5ee-4a8e-8f3b-434664110bc0` with expected title, description, seller (`OrignaVentures`), price (13,000 CAD), and solar assets. Remaining manual step: full order/payment verification on the company Stripe path.

### Release / delivery
- [ ] Deploy the latest version of OrignaGTA and OrignaVentures.
  - Advanced state: OrignaGTA production was redeployed again as release `20260422113324`; latest OrignaVentures frontend/docs were already redeployed earlier; a final both-apps pass is still pending.
- [x] Commit and push all changes to GitHub.
- Verified on 2026-04-22: Latest commits pushed:
  - `c3efdb61` docs: Mark Cuba support as verified in CORE.md
  - `619c60be` docs: Correct Spanish translation status in CORE.md and STATE.md  
  - `95c9fecf` feat: Spanish translations, Ventures payment hardening, solar product live
- [ ] Build the iOS app.
  - Current verified state on 2026-04-25:
    - connected iPhone was initially visible as `00008120-000174923ADB401E` on iOS `26.4.1`, but later disappeared from `idevice_id`, `ios-deploy`, and Xcode/CoreDevice in this shell.
    - Flutter SDK sandbox blocker was bypassed with a writable `/tmp/origna-flutter-root`.
    - iOS CocoaPods lock drift was fixed in `origna_gta/ios/Podfile.lock` (`connectivity_plus`, `sentry_flutter 9.15.0`, `Sentry/HybridSDK 8.58.0`; removed stale `passkeys_ios` / `ua_client_hints`).
    - Pods can be built for `iphoneos26.4` when Sentry preview macros are excluded via `SWIFT_ACTIVE_COMPILATION_CONDITIONS=COCOAPODS`.
    - a temporary no-code-sign Runner build was proven after excluding Interface Builder / asset catalog compilation, but that resource-stripping workaround was not retained in the repo.
  - Active machine blockers:
    - `security find-identity -v -p codesigning` reports `0 valid identities found`.
    - provisioning profile `c64dffd1-c8fe-4d0b-832a-cd757caec3a4` is present for `ca.orignagta.app`, team `98KN6NA6DU`, and includes device `00008120-000174923ADB401E`, but Xcode reports the local copied profiles as malformed/missing UUID and there is no matching private-key signing identity.
    - Xcode's CoreSimulator service is unavailable from this shell; `actool` / `ibtool` fail with `iOS 26.4 Platform Not Installed` / no simulator runtimes despite `xcodebuild -showsdks` listing iOS 26.4 SDKs.
    - CoreDevice service is unavailable from this shell; `xcrun devicectl list devices` times out and Xcode cannot see the iPhone destination.
  - Required next gate:
    - reconnect/trust the iPhone, refresh Xcode account credentials, create/download an Apple Development certificate private key for team `98KN6NA6DU`, fix local Xcode CoreDevice/CoreSimulator services, then rerun `flutter run --debug --dart-define=ENVIRONMENT=dev -d 00008120-000174923ADB401E`.

## P2 — Manual QA / human-required checkpoints
- [ ] Final production OrignaGTA live checkout/payment verification for `https://orignagta.ca/product/207123c5-a5ee-4a8e-8f3b-434664110bc0`.
  - Automated coverage already verifies description, seller, price, assets, and product-page fetch.
  - Remaining manual step: approved live buyer/payment path because production login and checkout are Turnstile-gated.

## P3 — Growth / business backlog
- [ ] Add `orignaventures.ca` to Yelp.
- [ ] Launch campaign to find clients for solar panels/modules.
- [ ] Advertising campaign to sell our services.

## Notes
- Completed one-off items live in `STATE.md`.
- Historical proofs should not be re-added here once moved to `STATE.md`.
